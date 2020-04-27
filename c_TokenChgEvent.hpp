// Copyright 2009-2020 NTESS. Under the terms
// of Contract DE-NA0003525 with NTESS, the U.S.
// Government retains certain rights in this software.
//
// Copyright (c) 2009-2020, NTESS
// All rights reserved.
//
// Portions are copyright of other developers:
// See the file CONTRIBUTORS.TXT in the top level directory
// the distribution for more information.
//
// This file is part of the SST software package. For license
// information, see the LICENSE file in the top level directory of the
// distribution.

/*
 * c_TokenChgEvent.hpp
 *
 *  Created on: May 18, 2016
 *      Author: tkarkha
 */

// Copyright 2015 IBM Corporation
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//   http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#ifndef C_TOKENCHGEVENT_HPP_
#define C_TOKENCHGEVENT_HPP_

namespace SST {
namespace CramSim {
// This event passes between components the change in tokens for a resource
class c_TokenChgEvent : public SST::Event {
public:
  int m_payload; // m_payload is the change in tokens at a certain resource
  c_TokenChgEvent() : SST::Event() {}

  void serialize_order(SST::Core::Serialization::serializer &ser) override {
    Event::serialize_order(ser);
    ser &m_payload;
  }

  ImplementSerializable(SST::CramSim::c_TokenChgEvent);
};

} // namespace CramSim
} // namespace SST

#endif /* C_TOKENCHGEVENT_HPP_ */
