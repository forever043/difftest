# DiffTest

DiffTest (差分测试): a modern co-simulation framework for RISC-V processors.

## Generate Example Verilog

DiffTest interfaces are provided in Chisel bundles and expected to be integrated
into Chisel designs with auto-generated C++ interfaces.
However, we also provide examples of the generated Verilog modules.

```bash
make difftest_verilog NOOP_HOME=$(pwd)
```

## Example Usage

1. Add this submodule to your design.

In your Git project:
```bash
git submodule add https://github.com/OpenXiangShan/difftest.git
```

In Mill `build.sc`:
```scala
import $file.difftest.build

// We recommend using a fixed Chisel version.
object difftest extends millbuild.difftest.build.CommonDiffTest {
  def crossValue: String = "3.6.0"

  override def millSourcePath = os.pwd / "difftest"
}

// This is for advanced users only.
// All supported Chisel versions are listed in `build.sc`.
// To pass a cross value to difftest:
object difftest extends Cross[millbuild.difftest.build.CommonDiffTest](chiselVersions) {
  override def millSourcePath = os.pwd / "difftest"
}
```

In `Makefile`:
```Makefile
emu: sim-verilog
	@$(MAKE) -C difftest emu WITH_CHISELDB=0 WITH_CONSTANTIN=0
```

2. Add difftest modules (in Chisel or Verilog) to your design.
All modules have been listed in the [APIs](#apis) chapter. Some of them are optional.

```scala
import difftest._

val difftest = DifftestModule(new DiffInstrCommit, delay = 1, dontCare = true)
difftest.valid  := io.in.valid
difftest.pc     := SignExt(io.in.bits.decode.cf.pc, AddrBits)
difftest.instr  := io.in.bits.decode.cf.instr
difftest.skip   := io.in.bits.isMMIO
difftest.isRVC  := io.in.bits.decode.cf.instr(1, 0)=/="b11".U
difftest.rfwen  := io.wb.rfWen && io.wb.rfDest =/= 0.U
difftest.wdest  := io.wb.rfDest
difftest.wpdest := io.wb.rfDest
```

3. Call `val difftesst = DifftestModule.finish(cpu: String)` at the top module whose module name should be `SimTop`. The variable name `difftest` must be used to ensure DiffTest could capture the input signals.

An optional UART input/output can be connected to DiffTest. DiffTest will automatically DontCare it internally.

```scala
val difftest = DifftestModule.finish("Demo")

// Optional UART connections. Remove this line if UART is not needed.
difftest.uart <> mmio.io.uart
```

4. Generate verilog files for simulation.

5. `make emu` and start simulating & debugging!

We provide example designs, including:
- [XiangShan](https://github.com/OpenXiangShan/XiangShan)
- [NutShell](https://github.com/OSCPU/NutShell/tree/dev-difftest)
- [Rocket](https://github.com/OpenXiangShan/rocket-chip/tree/dev-difftest)

If you encountered any issues when integrating DiffTest to your own design, feel free to let us know with necessary information on how you have modified your design. We will try our best to assist you.

## APIs

Currently we are supporting the RISC-V base ISA as well as some extensions,
including Float/Double, Debug, and Vector. We also support checking the cache
coherence via RefillTest.

| Probe Name | Descriptions | Mandatory |
| ---------- | ------------ | --------- |
| `DiffArchEvent` | Exceptions and interrupts | Yes |
| `DiffInstrCommit` | Executed instructions | Yes |
| `DiffTrapEvent` | Simulation environment call | Yes |
| `DiffArchIntRegState` | General-purpose registers | Yes |
| `DiffArchFpRegState` | Floating-point registers | No |
| `DiffArchVecRegState` | Vector registers | No |
| `DiffCSRState` | Control and status registers (CSRs) | Yes |
| `DiffVecCSRState` | CSRs for the Vector extension | No |
| `DiffHCSRState` | CSRs for the Hypervisor extension | No |
| `DiffDebugMode` | Debug mode registers | No |
| `DiffIntWriteback` | General-purpose writeback operations | No |
| `DiffFpWriteback` | Floating-point writeback operations | No |
| `DiffArchIntDelayedUpdate` | Delayed general-purpose writeback | No |
| `DiffArchFpDelayedUpdate` | Delayed floating-point writeback | No |
| `DiffStoreEvent` | Store operations | No |
| `DiffSbufferEvent` | Store buffer operations | No |
| `DiffLoadEvent` | Load operations | No |
| `DiffAtomicEvent` | Atomic operations | No |
| `DiffL1TLBEvent` | L1 TLB operations | No |
| `DiffL2TLBEvent` | L2 TLB operations | No |
| `DiffRefillEvent` | Cache refill operations | No |
| `DiffLrScEvent` | Executed LR/SC instructions | No |

The DiffTest framework comes with a simulation framework with some top-level IOs.
They will be automatically created when calling `DifftestModule.finish(cpu: String)`.

* `LogCtrlIO`
* `PerfCtrlIO`
* `UARTIO`

These IOs can be used along with the controller wrapper at `src/main/scala/common/LogPerfControl.scala`.

For compatibility on different platforms, the CPU should access a C++ memory via
DPI-C interfaces. This memory will be initialized in C++.

You may also use macro `DISABLE_DIFFTEST_RAM_DPIC` to remove memory DPI-Cs and use Verilog arrays instead.

```scala
val mem = DifftestMem(memByte, 8)
when (wen) {
    mem.write(
    addr = wIdx,
    data = in.w.bits.data.asTypeOf(Vec(DataBytes, UInt(8.W))),
    mask = in.w.bits.strb.asBools
    )
}
val rdata = mem.readAndHold(rIdx, ren).asUInt
```

To use DiffTest, please include all necessary modules and top-level IOs in your design.
It's worth noting the Chisel Bundles may have arguments with default values.
Please set the correct parameters for the interfaces.

# References

* Theories of DiffTest / DiffTest 的基本原理
  * [一生一芯计划讲义](https://ysyx.oscc.cc/slides/2205/12.html)
* Advanced theories of DiffTest / DiffTest 原理的进阶问题讨论
  * [Paper 1](https://ieeexplore.ieee.org/document/9923860), [Paper 2](https://jcst.ict.ac.cn/en/article/doi/10.1007/s11390-023-3285-8)
  * SMP-DiffTest 支持多处理器的差分测试方法: [PPT](https://github.com/OpenXiangShan/XiangShan-doc/blob/main/slides/20210624-RVWC-SMP-Difftest%20%E6%94%AF%E6%8C%81%E5%A4%9A%E5%A4%84%E7%90%86%E5%99%A8%E7%9A%84%E5%B7%AE%E5%88%86%E6%B5%8B%E8%AF%95%E6%96%B9%E6%B3%95.pdf), [视频](https://www.bilibili.com/video/BV1NM4y1T7Hz/)
* Next-generation DiffTest / DiffTest 的下一步演进
  * DiffTest on Cadence Palladium: to be released soon
