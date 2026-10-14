#!/usr/bin/env python3
"""Switch an AIC 88M80 dongle (1111:1111) from driver-disk mode to WiFi mode.

Replays the two vendor SCSI commands the Windows tool Usb_Driver.dll sends:
  GetHippo  : CDB FD 00..00 F3, reads 5 bytes (device query)
  Set_CS1_0 : CDB FD 00..00 F2, no data      (mode switch)
Usage: aic8800-switch.py /dev/sdX
"""
import ctypes
import fcntl
import os
import struct
import sys

SG_IO = 0x2285
SG_DXFER_NONE = -1
SG_DXFER_FROM_DEV = -3
# struct sg_io_hdr (linux/include/scsi/sg.h), native alignment
SG_IO_HDR = "@iiBBHIPPPIIiPBBBBHHiII4x"  # 4x = trailing pad to the kernel's 88 bytes


def cdb(last):
    return bytes([0xFD] + [0] * 14 + [last])


def send(fd, command, data_len):
    cmd = ctypes.create_string_buffer(command, len(command))
    data = ctypes.create_string_buffer(max(data_len, 1))
    sense = ctypes.create_string_buffer(32)
    hdr = bytearray(struct.pack(
        SG_IO_HDR, ord("S"), SG_DXFER_FROM_DEV if data_len else SG_DXFER_NONE,
        len(command), len(sense), 0, data_len,
        ctypes.addressof(data) if data_len else 0, ctypes.addressof(cmd), ctypes.addressof(sense),
        20000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    fcntl.ioctl(fd, SG_IO, hdr)
    f = struct.unpack(SG_IO_HDR, hdr)
    status, host, driver = f[13], f[17], f[18]
    return status, host, driver, data.raw[:data_len]


def main():
    dev = sys.argv[1]
    fd = os.open(dev, os.O_RDONLY | os.O_NONBLOCK)
    try:
        st, host, drv, data = send(fd, cdb(0xF3), 5)
        print(f"GetHippo : status={st} host={host} driver={drv} data={data.hex()}")
        try:
            st, host, drv, _ = send(fd, cdb(0xF2), 0)
            print(f"Set_CS1_0: status={st} host={host} driver={drv}")
        except OSError as e:  # device dropping off the bus mid-command is the expected success path
            print(f"Set_CS1_0: device disconnected ({e})")
    finally:
        os.close(fd)


if __name__ == "__main__":
    main()
