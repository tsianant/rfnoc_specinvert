//
// Copyright 2025 <author>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//

// Include our own header:
#include <rfnoc/specinvert/specinvert_block_control.hpp>

// These two includes are the minimum required to implement a block:
#include <uhd/rfnoc/defaults.hpp>
#include <uhd/rfnoc/registry.hpp>
#include <uhd/utils/log.hpp>

using namespace rfnoc::specinvert;
using namespace uhd::rfnoc;

// Define register addresses here:
const uint32_t specinvert_block_control::REG_INVERT_CONTROL      = 0x00;
const uint32_t specinvert_block_control::REG_INVERT_STATUS       = 0x04;
const uint32_t specinvert_block_control::REG_DETECTION_THRESHOLD = 0x08;
const uint32_t specinvert_block_control::REG_DETECTION_WINDOW    = 0x0C;

class specinvert_block_control_impl : public specinvert_block_control
{
public:
    RFNOC_BLOCK_CONSTRUCTOR(specinvert_block_control)
    {
        // Set default values
        _invert_enabled = true;
        _auto_detect = false;
        _detection_threshold = 0x1000;
        _detection_window = 1024;
        
        // Initialize the block
        _init_block();
    }
    
private:
    void _init_block()
    {
        UHD_LOG_DEBUG("SPECINVERT", "Initializing specinvert block");
        
        // Write initial configuration
        uint32_t reg_value = (_auto_detect << 1) | (_invert_enabled ? 1 : 0);
        this->regs().poke32(REG_INVERT_CONTROL, reg_value);
        this->regs().poke32(REG_DETECTION_THRESHOLD, _detection_threshold);
        this->regs().poke32(REG_DETECTION_WINDOW, _detection_window);
    }
    
    // Internal state
    bool _invert_enabled;
    bool _auto_detect;
    uint32_t _detection_threshold;
    uint32_t _detection_window;
};

// Register the block - use the NOC_ID from your YAML file (0x51EC1000)
UHD_RFNOC_BLOCK_REGISTER_DIRECT(
    specinvert_block_control, 0x51EC1000, "specinvert", CLOCK_KEY_GRAPH, "bus_clk");