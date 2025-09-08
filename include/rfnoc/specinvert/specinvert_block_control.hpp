//
// Copyright 2025 <author>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//

#pragma once

#include <rfnoc/specinvert/config.hpp>
#include <uhd/rfnoc/noc_block_base.hpp>
#include <cstdint>

namespace rfnoc { namespace specinvert {

//! Status structure for spectral inversion block
struct specinvert_status_t {
    bool inversion_active;      //!< Whether inversion is currently active
    uint32_t samples_processed;  //!< Number of samples processed
};

/*! Spectral Inversion Block Controller
 *
 * This block performs spectral inversion (complex conjugation) on incoming
 * samples to recover signals from higher Nyquist zones. When a signal is
 * undersampled (sampled below the Nyquist rate), it appears in higher
 * Nyquist zones with alternating spectral inversions. This block can
 * correct for that inversion.
 * 
 * Nyquist Zone Behavior:
 * - Zone 1 (0 to fs/2): Normal spectrum
 * - Zone 2 (fs/2 to fs): Inverted spectrum  
 * - Zone 3 (fs to 3fs/2): Normal spectrum
 * - Zone 4 (3fs/2 to 2fs): Inverted spectrum
 * - And so on...
 * 
 * The block performs complex conjugation: out = conj(in) = real(in) - j*imag(in)
 */
class RFNOC_SPECINVERT_API specinvert_block_control : public uhd::rfnoc::noc_block_base
{
public:
    RFNOC_DECLARE_BLOCK(specinvert_block_control)

    // Register addresses
    static const uint32_t REG_INVERT_CONTROL;       //!< Control register (bit 0: enable, bit 1: auto-detect)
    static const uint32_t REG_INVERT_STATUS;        //!< Status register
    static const uint32_t REG_DETECTION_THRESHOLD;  //!< Detection threshold for auto-mode
    static const uint32_t REG_DETECTION_WINDOW;     //!< Detection window size
};

}} // namespace rfnoc::specinvert