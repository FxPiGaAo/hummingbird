//=====================================================================
//
// Designer   : Haocheng Xiao
//
// Description:
//  The ifu_buffer to buffer entire instruction fetch unit.
//
// ====================================================================
`include "e203_defines.v"

module ifu_buffer(
  output[`E203_PC_SIZE-1:0] inspect_pc,
  output ifu_active,
  //input  itcm_nohold,

  //input  [`E203_PC_SIZE-1:0] pc_rtvec,  
  `ifdef E203_HAS_ITCM //{
  //input  ifu2itcm_holdup,
  //input  ifu2itcm_replay,

  // The ITCM address region indication signal
  //input [`E203_ADDR_SIZE-1:0] itcm_region_indic,

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // Bus Interface to ITCM, internal protocol called ICB (Internal Chip Bus)
  //    * Bus cmd channel
  output ifu2itcm_icb_cmd_valid, // Handshake valid
  //input  ifu2itcm_icb_cmd_ready, // Handshake ready
            // Note: The data on rdata or wdata channel must be naturally
            //       aligned, this is in line with the AXI definition
  output [`E203_ITCM_ADDR_WIDTH-1:0]   ifu2itcm_icb_cmd_addr, // Bus transaction start addr 

  //    * Bus RSP channel
  //input  ifu2itcm_icb_rsp_valid, // Response valid 
  output ifu2itcm_icb_rsp_ready, // Response ready
  //input  ifu2itcm_icb_rsp_err,   // Response error
            // Note: the RSP rdata is inline with AXI definition
  //input  [`E203_ITCM_DATA_WIDTH-1:0] ifu2itcm_icb_rsp_rdata, 
  `endif//}

  `ifdef E203_HAS_MEM_ITF //{
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // Bus Interface to System Memory, internal protocol called ICB (Internal Chip Bus)
  //    * Bus cmd channel
  output ifu2biu_icb_cmd_valid, // Handshake valid
  //input  ifu2biu_icb_cmd_ready, // Handshake ready
            // Note: The data on rdata or wdata channel must be naturally
            //       aligned, this is in line with the AXI definition
  output [`E203_ADDR_SIZE-1:0]   ifu2biu_icb_cmd_addr, // Bus transaction start addr 

  //    * Bus RSP channel
  //input  ifu2biu_icb_rsp_valid, // Response valid 
  output ifu2biu_icb_rsp_ready, // Response ready
  //input  ifu2biu_icb_rsp_err,   // Response error
            // Note: the RSP rdata is inline with AXI definition
  //input  [`E203_SYSMEM_DATA_WIDTH-1:0] ifu2biu_icb_rsp_rdata, 

  //input  ifu2biu_replay,
  `endif//}

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The IR stage to EXU interface
  output [`E203_INSTR_SIZE-1:0] ifu_o_ir,// The instruction register
  output [`E203_PC_SIZE-1:0] ifu_o_pc,   // The PC register along with
  output ifu_o_pc_vld,
  output ifu_o_misalgn,                  // The fetch misalign 
  output ifu_o_buserr,                   // The fetch bus error
  output [`E203_RFIDX_WIDTH-1:0] ifu_o_rs1idx,
  output [`E203_RFIDX_WIDTH-1:0] ifu_o_rs2idx,
  output ifu_o_prdt_taken,               // The Bxx is predicted as taken
  output ifu_o_muldiv_b2b,               
  output ifu_o_valid, // Handshake signals with EXU stage
  //input  ifu_o_ready,

  output  pipe_flush_ack,
  //input   pipe_flush_req,
  //input   [`E203_PC_SIZE-1:0] pipe_flush_add_op1,  
  //input   [`E203_PC_SIZE-1:0] pipe_flush_add_op2,
  `ifdef E203_TIMING_BOOST//}
  //input   [`E203_PC_SIZE-1:0] pipe_flush_pc,  
  `endif//}

      
  // The halt request come from other commit stage
  //   If the ifu_halt_req is asserting, then IFU will stop fetching new 
  //     instructions and after the oustanding transactions are completed,
  //     asserting the ifu_halt_ack as the response.
  //   The IFU will resume fetching only after the ifu_halt_req is deasserted
  //input  ifu_halt_req,
  output ifu_halt_ack,

  //input  oitf_empty,
  //input  [`E203_XLEN-1:0] rf2ifu_x1,
  //input  [`E203_XLEN-1:0] rf2ifu_rs1,
  //input  dec2ifu_rden,
  //input  dec2ifu_rs1en,
  //input  [`E203_RFIDX_WIDTH-1:0] dec2ifu_rdidx,
  //input  dec2ifu_mulhsu,
  //input  dec2ifu_div   ,
  //input  dec2ifu_rem   ,
  //input  dec2ifu_divu  ,
  //input  dec2ifu_remu  ,

  input  clk,
  //input  rst_n
  
  
  input[`E203_PC_SIZE-1:0] in_inspect_pc,
  input in_ifu_active,

  `ifdef E203_HAS_ITCM //{


  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // Bus Interface to ITCM, internal protocol called ICB (Internal Chip Bus)
  //    * Bus cmd channel
  input in_ifu2itcm_icb_cmd_valid, // Handshake valid
  input [`E203_ITCM_ADDR_WIDTH-1:0]   in_ifu2itcm_icb_cmd_addr, // Bus transaction start addr 

  //    * Bus RSP channel
  input in_ifu2itcm_icb_rsp_ready, // Response ready
  `endif//}

  `ifdef E203_HAS_MEM_ITF //{
  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // Bus Interface to System Memory, internal protocol called ICB (Internal Chip Bus)
  //    * Bus cmd channel
  input in_ifu2biu_icb_cmd_valid, // Handshake valid
  input [`E203_ADDR_SIZE-1:0]   in_ifu2biu_icb_cmd_addr, // Bus transaction start addr 

  //    * Bus RSP channel
  input in_ifu2biu_icb_rsp_ready, // Response ready

  `endif//}

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  // The IR stage to EXU interface
  input [`E203_INSTR_SIZE-1:0] in_ifu_o_ir,// The instruction register
  input [`E203_PC_SIZE-1:0] in_ifu_o_pc,   // The PC register along with
  input in_ifu_o_pc_vld,
  input in_ifu_o_misalgn,                  // The fetch misalign 
  input in_ifu_o_buserr,                   // The fetch bus error
  input [`E203_RFIDX_WIDTH-1:0] in_ifu_o_rs1idx,
  input [`E203_RFIDX_WIDTH-1:0] in_ifu_o_rs2idx,
  input in_ifu_o_prdt_taken,               // The Bxx is predicted as taken
  input in_ifu_o_muldiv_b2b,               
  input in_ifu_o_valid, // Handshake signals with EXU stage

  input  in_pipe_flush_ack,
  `ifdef E203_TIMING_BOOST//}
  `endif//}

  input in_ifu_halt_ack
  );
  
endmodule

