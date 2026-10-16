# SPDX-FileCopyrightText: Copyright 2026 shadPS4 Emulator Project
# SPDX-License-Identifier: GPL-2.0-or-later

set(AACDEC_SRC
    fdk-aac/cpp/libAACdec/src/FDK_delay.cpp
    fdk-aac/cpp/libAACdec/src/aac_ram.cpp
    fdk-aac/cpp/libAACdec/src/aac_rom.cpp
    fdk-aac/cpp/libAACdec/src/aacdec_drc.cpp
    fdk-aac/cpp/libAACdec/src/aacdec_hcr.cpp
    fdk-aac/cpp/libAACdec/src/aacdec_hcr_bit.cpp
    fdk-aac/cpp/libAACdec/src/aacdec_hcrs.cpp
    fdk-aac/cpp/libAACdec/src/aacdec_pns.cpp
    fdk-aac/cpp/libAACdec/src/aacdec_tns.cpp
    fdk-aac/cpp/libAACdec/src/aacdecoder.cpp
    fdk-aac/cpp/libAACdec/src/aacdecoder_lib.cpp
    fdk-aac/cpp/libAACdec/src/block.cpp
    fdk-aac/cpp/libAACdec/src/channel.cpp
    fdk-aac/cpp/libAACdec/src/channelinfo.cpp
    fdk-aac/cpp/libAACdec/src/conceal.cpp
    fdk-aac/cpp/libAACdec/src/ldfiltbank.cpp
    fdk-aac/cpp/libAACdec/src/pulsedata.cpp
    fdk-aac/cpp/libAACdec/src/rvlc.cpp
    fdk-aac/cpp/libAACdec/src/rvlcbit.cpp
    fdk-aac/cpp/libAACdec/src/rvlcconceal.cpp
    fdk-aac/cpp/libAACdec/src/stereo.cpp
    fdk-aac/cpp/libAACdec/src/usacdec_ace_d4t64.cpp
    fdk-aac/cpp/libAACdec/src/usacdec_ace_ltp.cpp
    fdk-aac/cpp/libAACdec/src/usacdec_acelp.cpp
    fdk-aac/cpp/libAACdec/src/usacdec_fac.cpp
    fdk-aac/cpp/libAACdec/src/usacdec_lpc.cpp
    fdk-aac/cpp/libAACdec/src/usacdec_lpd.cpp
    fdk-aac/cpp/libAACdec/src/usacdec_rom.cpp
)

set(FDK_SRC
    fdk-aac/cpp/libFDK/src/FDK_bitbuffer.cpp
    fdk-aac/cpp/libFDK/src/FDK_core.cpp
    fdk-aac/cpp/libFDK/src/FDK_crc.cpp
    fdk-aac/cpp/libFDK/src/FDK_decorrelate.cpp
    fdk-aac/cpp/libFDK/src/FDK_hybrid.cpp
    fdk-aac/cpp/libFDK/src/FDK_lpc.cpp
    fdk-aac/cpp/libFDK/src/FDK_matrixCalloc.cpp
    fdk-aac/cpp/libFDK/src/FDK_qmf_domain.cpp
    fdk-aac/cpp/libFDK/src/FDK_tools_rom.cpp
    fdk-aac/cpp/libFDK/src/FDK_trigFcts.cpp
    fdk-aac/cpp/libFDK/src/autocorr2nd.cpp
    fdk-aac/cpp/libFDK/src/dct.cpp
    fdk-aac/cpp/libFDK/src/fft.cpp
    fdk-aac/cpp/libFDK/src/fft_rad2.cpp
    fdk-aac/cpp/libFDK/src/fixpoint_math.cpp
    fdk-aac/cpp/libFDK/src/huff_nodes.cpp
    fdk-aac/cpp/libFDK/src/mdct.cpp
    fdk-aac/cpp/libFDK/src/nlc_dec.cpp
    fdk-aac/cpp/libFDK/src/qmf.cpp
    fdk-aac/cpp/libFDK/src/scale.cpp
)

set(SYS_SRC
    fdk-aac/cpp/libSYS/src/genericStds.cpp
    fdk-aac/cpp/libSYS/src/syslib_channelMapDescr.cpp
)

set(ARITHCODING_SRC
    fdk-aac/cpp/libArithCoding/src/ac_arith_coder.cpp
)

set(MPEGTPDEC_SRC
    fdk-aac/cpp/libMpegTPDec/src/tpdec_adif.cpp
    fdk-aac/cpp/libMpegTPDec/src/tpdec_adts.cpp
    fdk-aac/cpp/libMpegTPDec/src/tpdec_asc.cpp
    fdk-aac/cpp/libMpegTPDec/src/tpdec_drm.cpp
    fdk-aac/cpp/libMpegTPDec/src/tpdec_latm.cpp
    fdk-aac/cpp/libMpegTPDec/src/tpdec_lib.cpp
)

set(SBRDEC_SRC
    fdk-aac/cpp/libSBRdec/src/HFgen_preFlat.cpp
    fdk-aac/cpp/libSBRdec/src/env_calc.cpp
    fdk-aac/cpp/libSBRdec/src/env_dec.cpp
    fdk-aac/cpp/libSBRdec/src/env_extr.cpp
    fdk-aac/cpp/libSBRdec/src/hbe.cpp
    fdk-aac/cpp/libSBRdec/src/huff_dec.cpp
    fdk-aac/cpp/libSBRdec/src/lpp_tran.cpp
    fdk-aac/cpp/libSBRdec/src/psbitdec.cpp
    fdk-aac/cpp/libSBRdec/src/psdec.cpp
    fdk-aac/cpp/libSBRdec/src/psdec_drm.cpp
    fdk-aac/cpp/libSBRdec/src/psdecrom_drm.cpp
    fdk-aac/cpp/libSBRdec/src/pvc_dec.cpp
    fdk-aac/cpp/libSBRdec/src/sbr_deb.cpp
    fdk-aac/cpp/libSBRdec/src/sbr_dec.cpp
    fdk-aac/cpp/libSBRdec/src/sbr_ram.cpp
    fdk-aac/cpp/libSBRdec/src/sbr_rom.cpp
    fdk-aac/cpp/libSBRdec/src/sbrdec_drc.cpp
    fdk-aac/cpp/libSBRdec/src/sbrdec_freq_sca.cpp
    fdk-aac/cpp/libSBRdec/src/sbrdecoder.cpp
)

set(PCMUTILS_SRC
  fdk-aac/cpp/libPCMutils/src/limiter.cpp
  fdk-aac/cpp/libPCMutils/src/pcm_utils.cpp
  fdk-aac/cpp/libPCMutils/src/pcmdmx_lib.cpp
)

set(DRCDEC_SRC
  fdk-aac/cpp/libDRCdec/src/FDK_drcDecLib.cpp
  fdk-aac/cpp/libDRCdec/src/drcDec_gainDecoder.cpp
  fdk-aac/cpp/libDRCdec/src/drcDec_reader.cpp
  fdk-aac/cpp/libDRCdec/src/drcDec_rom.cpp
  fdk-aac/cpp/libDRCdec/src/drcDec_selectionProcess.cpp
  fdk-aac/cpp/libDRCdec/src/drcDec_tools.cpp
  fdk-aac/cpp/libDRCdec/src/drcGainDec_init.cpp
  fdk-aac/cpp/libDRCdec/src/drcGainDec_preprocess.cpp
  fdk-aac/cpp/libDRCdec/src/drcGainDec_process.cpp
)

set(SACDEC_SRC
  fdk-aac/cpp/libSACdec/src/sac_bitdec.cpp
  fdk-aac/cpp/libSACdec/src/sac_calcM1andM2.cpp
  fdk-aac/cpp/libSACdec/src/sac_dec.cpp
  fdk-aac/cpp/libSACdec/src/sac_dec_conceal.cpp
  fdk-aac/cpp/libSACdec/src/sac_dec_lib.cpp
  fdk-aac/cpp/libSACdec/src/sac_process.cpp
  fdk-aac/cpp/libSACdec/src/sac_qmf.cpp
  fdk-aac/cpp/libSACdec/src/sac_reshapeBBEnv.cpp
  fdk-aac/cpp/libSACdec/src/sac_rom.cpp
  fdk-aac/cpp/libSACdec/src/sac_smoothing.cpp
  fdk-aac/cpp/libSACdec/src/sac_stp.cpp
  fdk-aac/cpp/libSACdec/src/sac_tsd.cpp
)

add_library(fdk-aac
  ${AACDEC_SRC}
  ${FDK_SRC}
  ${SYS_SRC}
  ${ARITHCODING_SRC}
  ${MPEGTPDEC_SRC}
  ${SBRDEC_SRC}
  ${PCMUTILS_SRC}
  ${DRCDEC_SRC}
  ${SACDEC_SRC}
)

if(MINGW)
  target_compile_definitions(fdk-aac PRIVATE __MINGW32__)
endif()

target_include_directories(fdk-aac
  PUBLIC
    fdk-aac/cpp/libAACdec/include
    fdk-aac/cpp/libFDK/include
    fdk-aac/cpp/libSYS/include
    fdk-aac/cpp/libArithCoding/include
    fdk-aac/cpp/libMpegTPDec/include
    fdk-aac/cpp/libSBRdec/include
    fdk-aac/cpp/libPCMutils/include
    fdk-aac/cpp/libDRCdec/include
    fdk-aac/cpp/libSACdec/include
)
