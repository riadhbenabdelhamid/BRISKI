# BRISKI
BRISKI ( Barrel RISC-V for Kilo-core Implementations ) is a fast and compact RISC-V barrel processor core that emphasize high throughput and compute density to increase the amount of cores in many-core design without sacrificing performance.

BRISKI (with the 16-stage/16-thread configuration) operates at BlockRAM speed limit (737 MHz) on the VU9P FPGA (VCU118) with speed grade -2 while only using ~650 LUTs.

A manycore demo running fractals with a vga display on nexys-a7 fpga board uses 64 BRISKI cores and is available in this link:
https://github.com/riadhbenabdelhamid/Fractaski

If you like BRISKI please take a look at our related publications :

1) R. B. Abdelhamid and D. Koch, "BRISKI: A RISC-V barrel processor approach for higher throughput with less resource tax," 2024 IEEE 17th International Symposium on Embedded Multicore/Many-core Systems-on-Chip (MCSoC), Kuala Lumpur, Malaysia, 2024, pp. 532-539, doi: 10.1109/MCSoC64144.2024.00092.

2) R. B. Abdelhamid, V. Valek and D. Koch, "SPARKLE: A 1,024-Core/16,384-Thread Single FPGA Many-Core RISC-V Barrel Processor Overlay," 2024 IEEE 35th International Conference on Application-specific Systems, Architectures and Processors (ASAP), Hong Kong, Hong Kong, 2024, pp. 118-119, doi: 10.1109/ASAP61560.2024.00032.

3) R. B. Abdelhamid, V. Valek and D. Koch, "SPARKLE: 400 RISC-V GIPS with 1,024 Barrel Processors on a single Datacenter FPGA Card," 2024 IEEE 17th International Symposium on Embedded Multicore/Many-core Systems-on-Chip (MCSoC), Kuala Lumpur, Malaysia, 2024, pp. 524-531, doi: 10.1109/MCSoC64144.2024.00091.


