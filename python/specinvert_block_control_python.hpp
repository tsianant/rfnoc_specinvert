//
// Copyright 2025 <author>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//

#pragma once

#include <uhd/rfnoc/block_controller_factory_python.hpp>
#include <rfnoc/specinvert/specinvert_block_control.hpp>

using namespace rfnoc::specinvert;

void export_specinvert_block_control(py::module& m)
{
    py::class_<specinvert_block_control, uhd::rfnoc::noc_block_base, specinvert_block_control::sptr>(
        m, "specinvert_block_control")
        .def(py::init(
            &uhd::rfnoc::block_controller_factory<specinvert_block_control>::make_from))

        ;
}
