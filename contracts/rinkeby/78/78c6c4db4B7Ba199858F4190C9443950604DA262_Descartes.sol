// Copyright (C) 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: GPL-3.0-only
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.

// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Note: This component currently has dependencies that are licensed under the GNU
// GPL, version 3, and so you should treat this component as a whole as being under
// the GPL version 3. But all Cartesi-written code in this component is licensed
// under the Apache License, version 2, or a compatible permissive license, and can
// be used independently under the Apache v2 license. After this component is
// rewritten, the entire component will be released under the Apache v2 license.

/// @title Interface for memory manager instantiator
pragma solidity ^0.7.0;

import "@cartesi/util/contracts/Instantiator.sol";

interface MMInterface is Instantiator {
    enum state {WaitingProofs, WaitingReplay, FinishedReplay}

    function getCurrentState(uint256 _index) external view returns (bytes32);

    function instantiate(
        address _owner,
        address _provider,
        bytes32 _initialHash
    ) external returns (uint256);

    function newHash(uint256 _index) external view returns (bytes32);

    function finishProofPhase(uint256 _index) external;

    function finishReplayPhase(uint256 _index) external;

    function getRWArrays(
        uint256 _index
    )
    external
    view
    returns (
        uint64[] memory,
        bytes8[] memory,
        bool[] memory
    );

    function stateIsWaitingProofs(uint256 _index) external view returns (bool);

    function stateIsWaitingReplay(uint256 _index) external view returns (bool);

    function stateIsFinishedReplay(uint256 _index) external view returns (bool);

    function getCurrentStateDeadline(
        uint256 _index,
        uint256 _roundDuration,
        uint256 _timeToStartMachine
    ) external view returns (uint256);

    function getMaxInstanceDuration(
        uint256 _roundDuration,
        uint256 _timeToStartMachine
    ) external view returns (uint256);
}

// Copyright (C) 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: GPL-3.0-only
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.

// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Note: This component currently has dependencies that are licensed under the GNU
// GPL, version 3, and so you should treat this component as a whole as being under
// the GPL version 3. But all Cartesi-written code in this component is licensed
// under the Apache License, version 2, or a compatible permissive license, and can
// be used independently under the Apache v2 license. After this component is
// rewritten, the entire component will be released under the Apache v2 license.


/// @title MachineInterface interface contract
pragma solidity ^0.7.0;


interface MachineInterface {
    event StepGiven(uint8 exitCode);

    function step(
        uint64[] memory _rwPositions,
        bytes8[] memory _rwValues,
        bool[] memory _isRead
    ) external returns (uint8, uint256);

    function getMemoryInteractor() external view returns (address);
}

// Copyright (C) 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: GPL-3.0-only
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.

// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Note: This component currently has dependencies that are licensed under the GNU
// GPL, version 3, and so you should treat this component as a whole as being under
// the GPL version 3. But all Cartesi-written code in this component is licensed
// under the Apache License, version 2, or a compatible permissive license, and can
// be used independently under the Apache v2 license. After this component is
// rewritten, the entire component will be released under the Apache v2 license.

/// @title Abstract interface for partition instantiator
pragma solidity ^0.7.0;

import "@cartesi/util/contracts/Instantiator.sol";

interface PartitionInterface is Instantiator {
    enum state {
        WaitingQuery,
        WaitingHashes,
        ChallengerWon,
        ClaimerWon,
        DivergenceFound
    }

    function getCurrentState(uint256 _index) external view returns (bytes32);

    function instantiate(
        address _challenger,
        address _claimer,
        bytes32 _initialHash,
        bytes32 _claimerFinalHash,
        uint256 _finalTime,
        uint256 _querySize,
        uint256 _roundDuration
    ) external returns (uint256);

    function timeHash(uint256 _index, uint256 key)
        external
        view
        returns (bytes32);

    function divergenceTime(uint256 _index) external view returns (uint256);

    function stateIsWaitingQuery(uint256 _index) external view returns (bool);

    function stateIsWaitingHashes(uint256 _index) external view returns (bool);

    function stateIsChallengerWon(uint256 _index) external view returns (bool);

    function stateIsClaimerWon(uint256 _index) external view returns (bool);

    function stateIsDivergenceFound(uint256 _index)
        external
        view
        returns (bool);

    function getPartitionGameIndex(uint256 _index)
        external
        view
        returns (uint256);

    function getQuerySize(uint256 _index) external view returns (uint256);

    function getCurrentStateDeadline(uint _index) external view returns (uint time);

    function getMaxInstanceDuration(
        uint256 _roundDuration,
        uint256 _timeToStartMachine,
        uint256 _partitionSize,
        uint256 _maxCycle,
        uint256 _picoSecondsToRunInsn
    ) external view returns (uint256);
}

// Copyright (C) 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: GPL-3.0-only
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.

// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Note: This component currently has dependencies that are licensed under the GNU
// GPL, version 3, and so you should treat this component as a whole as being under
// the GPL version 3. But all Cartesi-written code in this component is licensed
// under the Apache License, version 2, or a compatible permissive license, and can
// be used independently under the Apache v2 license. After this component is
// rewritten, the entire component will be released under the Apache v2 license.

// @title Verification game instantiator
pragma solidity ^0.7.0;

import "@cartesi/util/contracts/Decorated.sol";
import "@cartesi/util/contracts/Instantiator.sol";
import "./PartitionInterface.sol";
import "./MMInterface.sol";
import "./MachineInterface.sol";

interface VGInterface is Instantiator {
    enum state {
        WaitPartition,
        WaitMemoryProveValues,
        FinishedClaimerWon,
        FinishedChallengerWon
    }

    function instantiate(
        address _challenger,
        address _claimer,
        uint256 _roundDuration,
        address _machineAddress,
        bytes32 _initialHash,
        bytes32 _claimerFinalHash,
        uint256 _finalTime
    ) external returns (uint256);

    function getCurrentState(uint256 _index) external view returns (bytes32);

    function stateIsFinishedClaimerWon(uint256 _index)
        external
        view
        returns (bool);

    function stateIsFinishedChallengerWon(uint256 _index)
        external
        view
        returns (bool);

    function winByPartitionTimeout(uint256 _index) external;

    function startMachineRunChallenge(uint256 _index) external;

    function settleVerificationGame(uint256 _index) external;

    function claimVictoryByTime(uint256 _index) external;

    //function stateIsWaitPartition(uint256 _index) public view returns (bool);
    //function stateIsWaitMemoryProveValues(uint256 _index) public view
    //  returns (bool);
    //function clearInstance(uint256 _index) internal;
    //function challengerWins(uint256 _index) private;
    //function claimerWins(uint256 _index) private;

    function getPartitionQuerySize(uint256 _index)
        external
        view
        returns (uint256);

    function getPartitionGameIndex(uint256 _index)
        external
        view
        returns (uint256);

    function getMaxInstanceDuration(
        uint256 _roundDuration,
        uint256 _timeToStartMachine,
        uint256 _partitionSize,
        uint256 _maxCycle,
        uint256 _picoSecondsToRunInsn
    ) external view returns (uint256);
}

// Copyright (C) 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: GPL-3.0-only
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.

// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Note: This component currently has dependencies that are licensed under the GNU
// GPL, version 3, and so you should treat this component as a whole as being under
// the GPL version 3. But all Cartesi-written code in this component is licensed
// under the Apache License, version 2, or a compatible permissive license, and can
// be used independently under the Apache v2 license. After this component is
// rewritten, the entire component will be released under the Apache v2 license.


/// @title Interface for logger test instantiator
pragma solidity ^0.7.0;


interface LoggerInterface {
    function isLogAvailable(bytes32 _root, uint64 _log2Size) external view returns(bool);

    function calculateMerkleRootFromData(uint64 _log2Size, bytes8[] memory _data) external returns(bytes32);
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.7.0;


contract Decorated {
    // This contract defines several modifiers but does not use
    // them - they will be used in derived contracts.
    modifier onlyBy(address user) {
        require(msg.sender == user, "Cannot be called by user");
        _;
    }

    modifier onlyAfter(uint256 time) {
        require(block.timestamp > time, "Cannot be called now");
        _;
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


pragma solidity ^0.7.0;


interface Instantiator {

    modifier onlyInstantiated(uint256 _index) virtual;

    modifier onlyActive(uint256 _index) virtual;

    modifier increasesNonce(uint256 _index) virtual;

    function isActive(uint256 _index) external view returns (bool);

    function getNonce(uint256 _index) external view returns (uint256);

    function isConcerned(uint256 _index, address _user) external view returns (bool);

    function getSubInstances(uint256 _index, address) external view returns (address[] memory _addresses, uint256[] memory _indices);
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.7.0;

import "./Instantiator.sol";

abstract contract InstantiatorImpl is Instantiator {
    uint256 public currentIndex = 0;

    mapping(uint256 => bool) internal active;
    mapping(uint256 => uint256) internal nonce;

    modifier onlyInstantiated(uint256 _index) override {
        require(currentIndex > _index, "Index not instantiated");
        _;
    }

    modifier onlyActive(uint256 _index) override {
        require(currentIndex > _index, "Index not instantiated");
        require(isActive(_index), "Index inactive");
        _;
    }

    modifier increasesNonce(uint256 _index) override {
        nonce[_index]++;
        _;
    }

    function isActive(uint256 _index) public override view returns (bool) {
        return (active[_index]);
    }

    function getNonce(uint256 _index)
        public
        override
        view
        onlyActive(_index)
        returns (uint256 currentNonce)
    {
        return nonce[_index];
    }

    function deactivate(uint256 _index) internal {
        active[_index] = false;
        nonce[_index] = 0;
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


/// @title Library for Merkle proofs
pragma solidity ^0.7.0;


library Merkle {
    function getPristineHash(uint8 _log2Size) public pure returns (bytes32) {
        require(_log2Size >= 3, "Has to be at least one word");
        require(_log2Size <= 64, "Cannot be bigger than the machine itself");

        bytes8 value = 0;
        bytes32 runningHash = keccak256(abi.encodePacked(value));

        for (uint256 i = 3; i < _log2Size; i++) {
            runningHash = keccak256(abi.encodePacked(runningHash, runningHash));
        }

        return runningHash;
    }

    function getRoot(uint64 _position, bytes8 _value, bytes32[] memory proof) public pure returns (bytes32) {
        bytes32 runningHash = keccak256(abi.encodePacked(_value));

        return getRootWithDrive(
            _position,
            3,
            runningHash,
            proof
        );
    }

    function getRootWithDrive(
        uint64 _position,
        uint8 _logOfSize,
        bytes32 _drive,
        bytes32[] memory siblings
    ) public pure returns (bytes32)
    {
        require(_logOfSize >= 3, "Must be at least a word");
        require(_logOfSize <= 64, "Cannot be bigger than the machine itself");

        uint64 size = uint64(2) ** _logOfSize;

        require(((size - 1) & _position) == 0, "Position is not aligned");
        require(siblings.length == 64 - _logOfSize, "Proof length does not match");

        bytes32 drive = _drive;

        for (uint64 i = 0; i < siblings.length; i++) {
            if ((_position & (size << i)) == 0) {
                drive = keccak256(abi.encodePacked(drive, siblings[i]));
            } else {
                drive = keccak256(abi.encodePacked(siblings[i], drive));
            }
        }

        return drive;
    }

    function getLog2Floor(uint256 number) public pure returns (uint8) {

        uint8 result = 0;

        uint256 checkNumber = number;
        checkNumber = checkNumber >> 1;
        while (checkNumber > 0) {
            ++result;
            checkNumber = checkNumber >> 1;
        }

        return result;
    }

    function isPowerOf2(uint256 number) public pure returns (bool) {

        uint256 checkNumber = number;
        if (checkNumber == 0) {
            return false;
        }

        while ((checkNumber & 1) == 0) {
            checkNumber = checkNumber >> 1;
        }

        checkNumber = checkNumber >> 1;

        if (checkNumber == 0) {
            return true;
        }

        return false;
    }

    /// @notice Calculate the root of Merkle tree from an array of power of 2 elements
    /// @param hashes The array containing power of 2 elements
    /// @return byte32 the root hash being calculated
    function calculateRootFromPowerOfTwo(bytes32[] memory hashes) public pure returns (bytes32) {
        // revert when the input is not of power of 2
        require(isPowerOf2(hashes.length), "The input array must contain power of 2 elements");

        if (hashes.length == 1) {
            return hashes[0];
        }else {
            bytes32[] memory newHashes = new bytes32[](hashes.length >> 1);

            for (uint256 i = 0; i < hashes.length; i += 2) {
                newHashes[i >> 1] = keccak256(abi.encodePacked(hashes[i], hashes[i + 1]));
            }

            return calculateRootFromPowerOfTwo(newHashes);
        }
    }

}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: Apache-2.0
//                                  Apache License
//                            Version 2.0, January 2004
//                         http://www.apache.org/licenses/

//    TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

//    1. Definitions.

//       "License" shall mean the terms and conditions for use, reproduction,
//       and distribution as defined by Sections 1 through 9 of this document.

//       "Licensor" shall mean the copyright owner or entity authorized by
//       the copyright owner that is granting the License.

//       "Legal Entity" shall mean the union of the acting entity and all
//       other entities that control, are controlled by, or are under common
//       control with that entity. For the purposes of this definition,
//       "control" means (i) the power, direct or indirect, to cause the
//       direction or management of such entity, whether by contract or
//       otherwise, or (ii) ownership of fifty percent (50%) or more of the
//       outstanding shares, or (iii) beneficial ownership of such entity.

//       "You" (or "Your") shall mean an individual or Legal Entity
//       exercising permissions granted by this License.

//       "Source" form shall mean the preferred form for making modifications,
//       including but not limited to software source code, documentation
//       source, and configuration files.

//       "Object" form shall mean any form resulting from mechanical
//       transformation or translation of a Source form, including but
//       not limited to compiled object code, generated documentation,
//       and conversions to other media types.

//       "Work" shall mean the work of authorship, whether in Source or
//       Object form, made available under the License, as indicated by a
//       copyright notice that is included in or attached to the work
//       (an example is provided in the Appendix below).

//       "Derivative Works" shall mean any work, whether in Source or Object
//       form, that is based on (or derived from) the Work and for which the
//       editorial revisions, annotations, elaborations, or other modifications
//       represent, as a whole, an original work of authorship. For the purposes
//       of this License, Derivative Works shall not include works that remain
//       separable from, or merely link (or bind by name) to the interfaces of,
//       the Work and Derivative Works thereof.

//       "Contribution" shall mean any work of authorship, including
//       the original version of the Work and any modifications or additions
//       to that Work or Derivative Works thereof, that is intentionally
//       submitted to Licensor for inclusion in the Work by the copyright owner
//       or by an individual or Legal Entity authorized to submit on behalf of
//       the copyright owner. For the purposes of this definition, "submitted"
//       means any form of electronic, verbal, or written communication sent
//       to the Licensor or its representatives, including but not limited to
//       communication on electronic mailing lists, source code control systems,
//       and issue tracking systems that are managed by, or on behalf of, the
//       Licensor for the purpose of discussing and improving the Work, but
//       excluding communication that is conspicuously marked or otherwise
//       designated in writing by the copyright owner as "Not a Contribution."

//       "Contributor" shall mean Licensor and any individual or Legal Entity
//       on behalf of whom a Contribution has been received by Licensor and
//       subsequently incorporated within the Work.

//    2. Grant of Copyright License. Subject to the terms and conditions of
//       this License, each Contributor hereby grants to You a perpetual,
//       worldwide, non-exclusive, no-charge, royalty-free, irrevocable
//       copyright license to reproduce, prepare Derivative Works of,
//       publicly display, publicly perform, sublicense, and distribute the
//       Work and such Derivative Works in Source or Object form.

//    3. Grant of Patent License. Subject to the terms and conditions of
//       this License, each Contributor hereby grants to You a perpetual,
//       worldwide, non-exclusive, no-charge, royalty-free, irrevocable
//       (except as stated in this section) patent license to make, have made,
//       use, offer to sell, sell, import, and otherwise transfer the Work,
//       where such license applies only to those patent claims licensable
//       by such Contributor that are necessarily infringed by their
//       Contribution(s) alone or by combination of their Contribution(s)
//       with the Work to which such Contribution(s) was submitted. If You
//       institute patent litigation against any entity (including a
//       cross-claim or counterclaim in a lawsuit) alleging that the Work
//       or a Contribution incorporated within the Work constitutes direct
//       or contributory patent infringement, then any patent licenses
//       granted to You under this License for that Work shall terminate
//       as of the date such litigation is filed.

//    4. Redistribution. You may reproduce and distribute copies of the
//       Work or Derivative Works thereof in any medium, with or without
//       modifications, and in Source or Object form, provided that You
//       meet the following conditions:

//       (a) You must give any other recipients of the Work or
//           Derivative Works a copy of this License; and

//       (b) You must cause any modified files to carry prominent notices
//           stating that You changed the files; and

//       (c) You must retain, in the Source form of any Derivative Works
//           that You distribute, all copyright, patent, trademark, and
//           attribution notices from the Source form of the Work,
//           excluding those notices that do not pertain to any part of
//           the Derivative Works; and

//       (d) If the Work includes a "NOTICE" text file as part of its
//           distribution, then any Derivative Works that You distribute must
//           include a readable copy of the attribution notices contained
//           within such NOTICE file, excluding those notices that do not
//           pertain to any part of the Derivative Works, in at least one
//           of the following places: within a NOTICE text file distributed
//           as part of the Derivative Works; within the Source form or
//           documentation, if provided along with the Derivative Works; or,
//           within a display generated by the Derivative Works, if and
//           wherever such third-party notices normally appear. The contents
//           of the NOTICE file are for informational purposes only and
//           do not modify the License. You may add Your own attribution
//           notices within Derivative Works that You distribute, alongside
//           or as an addendum to the NOTICE text from the Work, provided
//           that such additional attribution notices cannot be construed
//           as modifying the License.

//       You may add Your own copyright statement to Your modifications and
//       may provide additional or different license terms and conditions
//       for use, reproduction, or distribution of Your modifications, or
//       for any such Derivative Works as a whole, provided Your use,
//       reproduction, and distribution of the Work otherwise complies with
//       the conditions stated in this License.

//    5. Submission of Contributions. Unless You explicitly state otherwise,
//       any Contribution intentionally submitted for inclusion in the Work
//       by You to the Licensor shall be under the terms and conditions of
//       this License, without any additional terms or conditions.
//       Notwithstanding the above, nothing herein shall supersede or modify
//       the terms of any separate license agreement you may have executed
//       with Licensor regarding such Contributions.

//    6. Trademarks. This License does not grant permission to use the trade
//       names, trademarks, service marks, or product names of the Licensor,
//       except as required for reasonable and customary use in describing the
//       origin of the Work and reproducing the content of the NOTICE file.

//    7. Disclaimer of Warranty. Unless required by applicable law or
//       agreed to in writing, Licensor provides the Work (and each
//       Contributor provides its Contributions) on an "AS IS" BASIS,
//       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
//       implied, including, without limitation, any warranties or conditions
//       of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
//       PARTICULAR PURPOSE. You are solely responsible for determining the
//       appropriateness of using or redistributing the Work and assume any
//       risks associated with Your exercise of permissions under this License.

//    8. Limitation of Liability. In no event and under no legal theory,
//       whether in tort (including negligence), contract, or otherwise,
//       unless required by applicable law (such as deliberate and grossly
//       negligent acts) or agreed to in writing, shall any Contributor be
//       liable to You for damages, including any direct, indirect, special,
//       incidental, or consequential damages of any character arising as a
//       result of this License or out of the use or inability to use the
//       Work (including but not limited to damages for loss of goodwill,
//       work stoppage, computer failure or malfunction, or any and all
//       other commercial damages or losses), even if such Contributor
//       has been advised of the possibility of such damages.

//    9. Accepting Warranty or Additional Liability. While redistributing
//       the Work or Derivative Works thereof, You may choose to offer,
//       and charge a fee for, acceptance of support, warranty, indemnity,
//       or other liability obligations and/or rights consistent with this
//       License. However, in accepting such obligations, You may act only
//       on Your own behalf and on Your sole responsibility, not on behalf
//       of any other Contributor, and only if You agree to indemnify,
//       defend, and hold each Contributor harmless for any liability
//       incurred by, or claims asserted against, such Contributor by reason
//       of your accepting any such warranty or additional liability.

//    END OF TERMS AND CONDITIONS

//    Copyright (C) 2020 Cartesi Pte. Ltd.

//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at

//        http://www.apache.org/licenses/LICENSE-2.0

//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

/// @title Descartes
/// @author Stephen Chen



import "@cartesi/util/contracts/Merkle.sol";
import "@cartesi/util/contracts/Decorated.sol";
import "@cartesi/util/contracts/InstantiatorImpl.sol";
import "@cartesi/logger/contracts/LoggerInterface.sol";
import "@cartesi/arbitration/contracts/VGInterface.sol";
import "./DescartesInterface.sol";

contract Descartes is InstantiatorImpl, Decorated, DescartesInterface {
    address machine; // machine which will run the challenge
    LoggerInterface li;
    VGInterface vg;

    struct DescartesCtx {
        address owner; // the one who has power to shutdown the instance
        uint256 revealDrivesPointer; // the pointer to the current reveal drive
        uint256 providerDrivesPointer; // the pointer to the current provider drive
        uint256 finalTime; // max number of machine cycle to run
        uint64 outputPosition; // memory position of machine output
        uint8 outputLog2Size; // log2 size of the output drive in the unit of bytes
        uint256 roundDuration; // time interval to interact with this contract
        uint256 timeOfLastMove; // last time someone made a move with deadline
        uint256 vgInstance;
        bytes32 templateHash; // pristine hash of machine
        bytes32 initialHash; // initial hash with all drives mounted
        bytes32 claimedFinalHash; // claimed final hash of the machine
        bytes claimedOutput; // claimed final machine output
        address[] partiesArray; // user can challenge claimer's output
        address[] confirmedParties; // parties that have confirmed the current claim
        uint64 claimer; // responsible for claiming the machine output
        uint64 currentChallenger; // it tracks who did the last challenge
        uint64 votesCounter; // helps manage end state
        mapping(address => Party) parties; // control structure for challengers
        State currentState;
        uint256[] revealDrives; // indices of the reveal drives
        uint256[] providerDrives; // indices of the provider drives
        bytes32[] driveHash; // root hash of the drives
        Drive[] inputDrives;
    }

    mapping(uint256 => DescartesCtx) internal instance;

    // These are the possible states and transitions of the contract.

    // +---+
    // |   |
    // +---+
    //   |
    //   | instantiate
    //   v
    // +------------------+    abortByDeadline    +------------------------+
    // | WaitingProviders |---------------------->| ProviderMissedDeadline |
    // +------------------+                       +------------------------+
    //   |
    //   | provideLoggerDrive
    //   | or
    //   | provideDirectDrive
    //   v
    // +----------------+   abortByDeadline    +------------------------+
    // | WaitingReveals |--------------------->| ProviderMissedDeadline |
    // +----------------+                      +------------------------+
    //   |
    //   | revealLoggerDrive
    //   v
    // +--------------+   abortByDeadline    +-----------------------+
    // | WaitingClaim |--------------------->| ClaimerMissedDeadline |
    // +--------------+                      +-----------------------+
    //   |
    //   |
    //   |
    //   | submitClaim
    //   v
    // +-----------------------------+             +-----------------+
    // | WaitingConfirmationDeadline |------------>| ConsensusResult |
    // +----------------------------+   deadline  +-----------------+
    //   |
    //   |
    //   | challenge
    //   v
    // +------------------------+    winByVG     +------------+  if there are challengers
    // | WaitingChallengeResult |--------------->| ClaimerWon |-----------------------> WaitingConfirmationDeadline
    // +-----------------------+                +------------+    left; go back to
    //   |
    //   |
    //   |                  winByVG        +---------------+  if there are challengers
    //   +-------------------------------->| ChallengerWon |------------------------> WaitingClaim
    //                                     +---------------+  left; go back to
    //

    event DescartesCreated(uint256 _index);
    event ClaimSubmitted(uint256 _index, bytes32 _claimedFinalHash);
    event ChallengeStarted(uint256 _index);
    event DescartesFinished(uint256 _index, bytes32 _state);
    event DriveInserted(uint256 _index, Drive _drive);
    event Confirmed(uint256 _index, address _confirmParty);

    constructor(
        address _liAddress,
        address _vgAddress,
        address _machineAddress
    ) {
        machine = _machineAddress;
        vg = VGInterface(_vgAddress);
        li = LoggerInterface(_liAddress);
    }

    /// @notice Instantiate a Descartes SDK instance.
    /// @param _finalTime max cycle of the machine for that computation
    /// @param _templateHash hash of the machine with all drives empty
    /// @param _outputPosition position of the output drive
    /// @param _roundDuration duration of the round (security param)
    /// @param _inputDrives an array of drive which assemble the machine
    /// @return uint256, Descartes index
    function instantiate(
        uint256 _finalTime,
        bytes32 _templateHash,
        uint64 _outputPosition,
        uint8 _outputLog2Size,
        uint256 _roundDuration,
        address[] memory parties,
        Drive[] memory _inputDrives
    ) public override returns (uint256) {
        require(
            _roundDuration >= 50,
            "round duration has to be at least 50 seconds"
        );
        DescartesCtx storage i = instance[currentIndex];

        for (uint64 j = 0; j < parties.length; j++) {
            require(
                i.parties[parties[j]].isParty == false,
                "Repetition of parties' addresses is not allowed"
            );
            i.parties[parties[j]].isParty = true;
            i.parties[parties[j]].arrayIdx = j;
            i.partiesArray.push(parties[j]);
        }

        bool needsProviderPhase = false;
        uint256 drivesLength = _inputDrives.length;
        i.driveHash = new bytes32[](drivesLength);
        for (uint256 j = 0; j < drivesLength; j++) {
            Drive memory drive = _inputDrives[j];

            if (!drive.needsLogger) {
                // direct drive
                require(
                    drive.driveLog2Size >= 3,
                    "directValue has to be at least one word"
                );

                if (!drive.waitsProvider) {
                    // direct drive provided at instantiation
                    require(
                        drive.directValue.length <= 2**drive.driveLog2Size,
                        "Input bytes length exceeds the claimed log2 size"
                    );

                    // pad zero to the directValue if it's not exact power of 2
                    bytes memory paddedDirectValue = drive.directValue;
                    if (drive.directValue.length < 2**drive.driveLog2Size) {
                        paddedDirectValue = abi.encodePacked(
                            drive.directValue,
                            new bytes(
                                2**drive.driveLog2Size -
                                    drive.directValue.length
                            )
                        );
                    }

                    bytes32[] memory data = getWordHashesFromBytes(
                        paddedDirectValue
                    );
                    i.driveHash[j] = Merkle.calculateRootFromPowerOfTwo(data);
                } else {
                    // direct drive provided in later ProviderPhase
                    needsProviderPhase = true;
                    i.providerDrives.push(j);
                }
            } else {
                // large drive
                if (!drive.waitsProvider) {
                    // large drive provided with logger hash at instantiation
                    i.driveHash[j] = drive.loggerRootHash;
                    if (
                        !li.isLogAvailable(
                            drive.loggerRootHash,
                            drive.driveLog2Size
                        ) && drive.provider != address(0)
                    ) {
                        // offchain drive has provider being address(0)
                        // cannot be revealed and challenged
                        i.revealDrives.push(j);
                    }
                } else {
                    // large drive provided with logger hash in later ProviderPhase
                    needsProviderPhase = true;
                    i.providerDrives.push(j);
                }
            }
            i.inputDrives.push(
                Drive(
                    drive.position,
                    drive.driveLog2Size,
                    drive.directValue,
                    drive.loggerIpfsPath,
                    drive.loggerRootHash,
                    drive.provider,
                    drive.waitsProvider,
                    drive.needsLogger
                )
            );
        }

        require(
            _outputLog2Size >= 3,
            "output drive has to be at least one word"
        );

        i.owner = msg.sender;
        // i.claimer = 0; parties[0]; // first on the list is selected to be claimer
        i.votesCounter = 1; // first vote is always a submitClaim, so we count it once here
        i.finalTime = _finalTime;
        i.templateHash = _templateHash;
        i.initialHash = _templateHash;
        i.outputPosition = _outputPosition;
        i.outputLog2Size = _outputLog2Size;
        i.roundDuration = _roundDuration;
        i.timeOfLastMove = block.timestamp;
        if (needsProviderPhase) {
            i.currentState = State.WaitingProviders;
        } else if (i.revealDrives.length > 0) {
            i.currentState = State.WaitingChallengeDrives;
        } else {
            i.currentState = State.WaitingClaim;
        }

        emit DescartesCreated(currentIndex);
        active[currentIndex] = true;
        return currentIndex++;
    }

    /// @notice Challenger disputes the claim, starting a verification game.
    /// @param _index index of Descartes instance which challenger is starting the VG.
    function challenge(uint256 _index)
        public
        onlyActive(_index)
        onlyByParty(_index)
        onlyNoVotes(_index)
        increasesNonce(_index)
    {
        DescartesCtx storage i = instance[_index];
        require(
            i.currentState == State.WaitingConfirmationDeadline,
            "State should be WaitingConfirmationDeadline"
        );

        i.vgInstance = vg.instantiate(
            msg.sender, // challenger
            i.partiesArray[i.claimer],
            i.roundDuration,
            machine,
            i.initialHash,
            i.claimedFinalHash,
            i.finalTime
        );
        i.currentState = State.WaitingChallengeResult;
        i.parties[msg.sender].hasVoted = true;
        i.currentChallenger = i.parties[msg.sender].arrayIdx;
        i.votesCounter++;
        i.timeOfLastMove = block.timestamp;

        // @dev should we update timeOfLastMove over here too?
        emit ChallengeStarted(_index);
    }

    /// @notice Party confirms the claim
    /// @param _index index of Descartes instance which claimer being confirmed
    function confirm(uint256 _index)
        public
        onlyActive(_index)
        onlyByParty(_index)
        onlyNoVotes(_index)
        increasesNonce(_index)
    {
        DescartesCtx storage i = instance[_index];
        require(
            i.currentState == State.WaitingConfirmationDeadline,
            "State should be WaitingConfirmationDeadline"
        );

        // record parties have confirmed current claim
        i.confirmedParties.push(msg.sender);
        i.parties[msg.sender].hasVoted = true;
        i.votesCounter++;
        // i.timeOfLastMove = block.timestamp;

        emit Confirmed(_index, msg.sender);

        if (i.votesCounter == i.partiesArray.length) {
            i.currentState = State.ConsensusResult;
            emit DescartesFinished(_index, getCurrentState(_index));
        }

        return;
    }

    /// @notice User requesting content of all drives to be revealed.
    /// @param _index index of Descartes instance which is requested for the drives
    function challengeDrives(uint256 _index)
        public
        onlyActive(_index)
        increasesNonce(_index)
    {
        DescartesCtx storage i = instance[_index];
        require(
            i.currentState == State.WaitingChallengeDrives,
            "State should be WaitingChallengeDrives"
        );
        require(
            i.parties[msg.sender].isParty,
            "Only concerned users can challengDrives"
        );

        i.currentState = State.WaitingReveals;
        i.timeOfLastMove = block.timestamp;
    }

    /// @notice Claimer claims the machine final hash and also validate the drives and initial hash of the machine.
    /// @param _claimedFinalHash is the final hash of the machine
    /// @param _drivesSiblings is an array of siblings of each drive (see below example)
    /// @param _output is the bytes32 value of the output position
    /// @param _outputSiblings is the siblings of the output drive
    /// @dev Example: consider 3 drives, the first drive's siblings should be a pristine machine.
    ///      The second drive's siblings should be the machine with drive 1 mounted.
    ///      The third drive's siblings should be the machine with drive 2 mounted.
    function submitClaim(
        uint256 _index,
        bytes32 _claimedFinalHash,
        bytes32[][] memory _drivesSiblings,
        bytes memory _output,
        bytes32[] memory _outputSiblings
    ) public onlyActive(_index) onlyByClaimer(_index) increasesNonce(_index) {
        DescartesCtx storage i = instance[_index];
        bool deadlinePassed = block.timestamp >
            i.timeOfLastMove + getMaxStateDuration(_index);
        require(
            i.currentState == State.WaitingClaim ||
                (i.currentState == State.WaitingChallengeDrives &&
                    deadlinePassed),
            "State should be WaitingClaim, or WaitingChallengeDrives with deadline passed"
        );
        require(
            i.inputDrives.length == _drivesSiblings.length,
            "Claimed drive number should match claimed siblings number"
        );
        require(
            _output.length == 2**i.outputLog2Size,
            "Output length doesn't match output log2 size"
        );

        bytes32[] memory data = getWordHashesFromBytes(_output);
        require(
            Merkle.getRootWithDrive(
                i.outputPosition,
                i.outputLog2Size,
                Merkle.calculateRootFromPowerOfTwo(data),
                _outputSiblings
            ) == _claimedFinalHash,
            "Output is not contained in the final hash"
        );

        uint256 drivesLength = i.inputDrives.length;
        for (uint256 j = 0; j < drivesLength; j++) {
            bytes32[] memory driveSiblings = _drivesSiblings[j];
            require(
                Merkle.getRootWithDrive(
                    i.inputDrives[j].position,
                    i.inputDrives[j].driveLog2Size,
                    Merkle.getPristineHash(
                        uint8(i.inputDrives[j].driveLog2Size)
                    ),
                    driveSiblings
                ) == i.initialHash,
                "Drive siblings must be compatible with previous initial hash for empty drive"
            );
            i.initialHash = Merkle.getRootWithDrive(
                i.inputDrives[j].position,
                i.inputDrives[j].driveLog2Size,
                i.driveHash[j],
                driveSiblings
            );
        }

        i.claimedFinalHash = _claimedFinalHash;
        i.currentState = State.WaitingConfirmationDeadline;
        i.claimedOutput = _output;
        i.parties[i.partiesArray[i.claimer]].hasVoted = true;
        i.timeOfLastMove = block.timestamp;

        emit ClaimSubmitted(_index, _claimedFinalHash);
    }

    /// @notice Is the given user concern about this instance.
    function isConcerned(uint256 _index, address _user)
        public
        view
        override
        onlyInstantiated(_index)
        returns (bool)
    {
        DescartesCtx storage i = instance[_index];
        return i.parties[_user].isParty;
    }

    function getPartyState(uint256 _index, address _p)
        public
        view
        onlyInstantiated(_index)
        returns (
            bool isParty,
            bool hasVoted,
            bool hasCheated
        )
    {
        Party storage party = instance[_index].parties[_p];
        isParty = party.isParty;
        hasVoted = party.hasVoted;
        hasCheated = party.hasCheated;
    }

    /// @notice Get state of the instance concerning given user.
    function getState(uint256 _index, address _user)
        public
        view
        onlyInstantiated(_index)
        returns (
            uint256[] memory,
            address[] memory,
            bytes32[] memory,
            bytes memory,
            Drive[] memory,
            Party memory user
        )
    {
        DescartesCtx storage i = instance[_index];

        user = i.parties[_user];

        uint256[] memory uintValues = new uint256[](4);
        uintValues[0] = i.finalTime;
        uintValues[1] = i.timeOfLastMove + getMaxStateDuration(_index);
        uintValues[2] = i.outputPosition;
        uintValues[3] = i.outputLog2Size;

        address[] memory addressValues = new address[](2);
        if (i.currentChallenger != 0)
            addressValues[0] = i.partiesArray[i.currentChallenger];
        addressValues[1] = i.partiesArray[i.claimer];

        bytes32[] memory bytes32Values = new bytes32[](4);
        bytes32Values[0] = i.templateHash;
        bytes32Values[1] = i.initialHash;
        bytes32Values[2] = i.claimedFinalHash;
        bytes32Values[3] = getCurrentState(_index);

        if (i.currentState == State.WaitingProviders) {
            Drive[] memory drives = new Drive[](1);
            drives[0] = i.inputDrives[
                i.providerDrives[i.providerDrivesPointer]
            ];
            return (
                uintValues,
                addressValues,
                bytes32Values,
                i.claimedOutput,
                drives,
                user
            );
        } else if (i.currentState == State.WaitingReveals) {
            Drive[] memory drives = new Drive[](1);
            drives[0] = i.inputDrives[i.revealDrives[i.revealDrivesPointer]];
            return (
                uintValues,
                addressValues,
                bytes32Values,
                i.claimedOutput,
                drives,
                user
            );
        } else if (i.currentState == State.ProviderMissedDeadline) {
            Drive[] memory drives = new Drive[](0);
            return (
                uintValues,
                addressValues,
                bytes32Values,
                i.claimedOutput,
                drives,
                user
            );
        } else {
            return (
                uintValues,
                addressValues,
                bytes32Values,
                i.claimedOutput,
                i.inputDrives,
                user
            );
        }
    }

    function getCurrentState(uint256 _index)
        public
        view
        onlyInstantiated(_index)
        returns (bytes32)
    {
        State currentState = instance[_index].currentState;
        if (currentState == State.WaitingProviders) {
            return "WaitingProviders";
        }
        if (currentState == State.WaitingReveals) {
            return "WaitingReveals";
        }
        if (currentState == State.WaitingChallengeDrives) {
            return "WaitingChallengeDrives";
        }
        if (currentState == State.ClaimerMissedDeadline) {
            return "ClaimerMissedDeadline";
        }
        if (currentState == State.ProviderMissedDeadline) {
            return "ProviderMissedDeadline";
        }
        if (currentState == State.WaitingClaim) {
            return "WaitingClaim";
        }
        if (currentState == State.WaitingConfirmationDeadline) {
            return "WaitingConfirmationDeadline";
        }
        if (currentState == State.WaitingChallengeResult) {
            return "WaitingChallengeResult";
        }
        if (currentState == State.ConsensusResult) {
            return "ConsensusResult";
        }
        if (currentState == State.ChallengerWon) {
            return "ChallengerWon";
        }
        if (currentState == State.ClaimerWon) {
            return "ClaimerWon";
        }

        revert("Unrecognized state");
    }

    /// @notice Get sub-instances of the instance.
    function getSubInstances(uint256 _index, address)
        public
        view
        override
        onlyInstantiated(_index)
        returns (address[] memory _addresses, uint256[] memory _indices)
    {
        address[] memory a;
        uint256[] memory i;

        if (instance[_index].currentState == State.WaitingChallengeResult) {
            a = new address[](1);
            i = new uint256[](1);
            a[0] = address(vg);
            i[0] = instance[_index].vgInstance;
        } else {
            a = new address[](0);
            i = new uint256[](0);
        }
        return (a, i);
    }

    /// @notice Provide the content of a direct drive (only drive provider can call it).
    /// @param _index index of Descartes instance the drive belongs to.
    /// @param _value bytes value of the direct drive
    function provideDirectDrive(uint256 _index, bytes memory _value)
        public
        onlyActive(_index)
        requirementsForProviderDrive(_index)
    {
        DescartesCtx storage i = instance[_index];
        uint256 driveIndex = i.providerDrives[i.providerDrivesPointer];
        Drive storage drive = i.inputDrives[driveIndex];

        require(!drive.needsLogger, "Invalid drive to claim for direct value");
        require(
            _value.length <= 2**drive.driveLog2Size,
            "Input bytes length exceeds the claimed log2 size"
        );

        // pad zero to the directValue if it's not exact power of 2
        bytes memory paddedDirectValue = _value;
        if (_value.length < 2**drive.driveLog2Size) {
            paddedDirectValue = abi.encodePacked(
                _value,
                new bytes(2**drive.driveLog2Size - _value.length)
            );
        }

        bytes32[] memory data = getWordHashesFromBytes(paddedDirectValue);
        bytes32 driveHash = Merkle.calculateRootFromPowerOfTwo(data);

        drive.directValue = _value;
        i.driveHash[driveIndex] = driveHash;
        i.providerDrivesPointer++;
        i.timeOfLastMove = block.timestamp;

        if (i.providerDrivesPointer == i.providerDrives.length) {
            if (i.revealDrives.length > 0) {
                i.currentState = State.WaitingChallengeDrives;
            } else {
                i.currentState = State.WaitingClaim;
            }
        }

        emit DriveInserted(_index, i.inputDrives[driveIndex]);
    }

    /// @notice Provide the root hash of a logger drive (only drive provider can call it).
    /// @param _index index of Descartes instance the drive belongs to
    /// @param _root root hash of the logger drive
    function provideLoggerDrive(uint256 _index, bytes32 _root)
        public
        onlyActive(_index)
        requirementsForProviderDrive(_index)
    {
        DescartesCtx storage i = instance[_index];
        uint256 driveIndex = i.providerDrives[i.providerDrivesPointer];
        Drive storage drive = i.inputDrives[driveIndex];

        require(drive.needsLogger, "Invalid drive to claim for logger");

        drive.loggerRootHash = _root;
        i.driveHash[driveIndex] = drive.loggerRootHash;
        i.providerDrivesPointer++;
        i.timeOfLastMove = block.timestamp;

        if (i.providerDrivesPointer == i.providerDrives.length) {
            if (i.revealDrives.length > 0) {
                i.currentState = State.WaitingChallengeDrives;
            } else {
                i.currentState = State.WaitingClaim;
            }
        }

        emit DriveInserted(_index, i.inputDrives[driveIndex]);
    }

    /// @notice Reveal the content of a logger drive (only drive provider can call it).
    /// @param _index index of Descartes instance the drive belongs to
    function revealLoggerDrive(uint256 _index) public onlyActive(_index) {
        DescartesCtx storage i = instance[_index];
        require(
            i.currentState == State.WaitingReveals,
            "The state is not WaitingReveals"
        );

        uint256 driveIndex = i.revealDrives[i.revealDrivesPointer];
        require(driveIndex < i.inputDrives.length, "Invalid driveIndex");

        Drive memory drive = i.inputDrives[driveIndex];

        require(drive.needsLogger, "needsLogger should be true");
        require(
            li.isLogAvailable(drive.loggerRootHash, drive.driveLog2Size),
            "Hash is not available on logger yet"
        );

        i.revealDrivesPointer++;
        i.timeOfLastMove = block.timestamp;

        if (i.revealDrivesPointer == i.revealDrives.length) {
            i.currentState = State.WaitingClaim;
        }
    }

    /// @notice In case one of the parties wins the verification game,
    ///         then he or she can call this function to claim victory in
    ///         this contract as well.
    /// @param _index index of Descartes instance to win
    function winByVG(uint256 _index)
        public
        onlyActive(_index)
        increasesNonce(_index)
    {
        DescartesCtx storage i = instance[_index];
        require(
            i.currentState == State.WaitingChallengeResult,
            "State is not WaitingChallengeResult, cannot winByVG"
        );
        i.timeOfLastMove = block.timestamp;
        uint256 vgIndex = i.vgInstance;

        if (vg.stateIsFinishedChallengerWon(vgIndex)) {
            i.parties[i.partiesArray[i.claimer]].hasCheated = true;
            // all parties have confirmed cheated claimer should be reset
            // this is a protection to avoid claimer losing dispute on purpose
            for (uint256 p = 0; p < i.confirmedParties.length; p++) {
                i.parties[i.confirmedParties[p]].hasVoted = false;
            }
            i.votesCounter -= uint64(i.confirmedParties.length);
            // reset confirmed parties
            delete i.confirmedParties;

            if (i.votesCounter == i.partiesArray.length) {
                i.currentState = State.ChallengerWon;
                emit DescartesFinished(_index, getCurrentState(_index));
                return;
            }
            i.currentState = State.WaitingClaim;
            i.claimer = i.currentChallenger;
            i.currentChallenger = 0;
            return;
        }

        if (vg.stateIsFinishedClaimerWon(vgIndex)) {
            i.parties[i.partiesArray[i.currentChallenger]].hasCheated = true;
            if (i.votesCounter == i.partiesArray.length) {
                i.currentState = State.ClaimerWon;
                emit DescartesFinished(_index, getCurrentState(_index));
                return;
            }
            i.currentState = State.WaitingConfirmationDeadline;
            i.currentChallenger = 0;
            return;
        }
        require(false, "State of VG is not final");
    }

    /// @notice Deactivate a Descartes SDK instance.
    /// @param _index index of Descartes instance to deactivate
    function destruct(uint256 _index)
        public
        override
        onlyActive(_index)
        onlyBy(instance[_index].owner)
    {
        DescartesCtx storage i = instance[_index];
        require(
            i.currentState == State.ProviderMissedDeadline ||
                i.currentState == State.ClaimerMissedDeadline ||
                i.currentState == State.ConsensusResult ||
                i.currentState == State.ChallengerWon ||
                i.currentState == State.ClaimerWon,
            "Cannot destruct instance at current state"
        );

        delete i.revealDrives;
        delete i.providerDrives;
        delete i.driveHash;
        delete i.inputDrives;
        deactivate(_index);
    }

    /// @notice Abort the instance by missing deadline.
    /// @param _index index of Descartes instance to abort
    function abortByDeadline(uint256 _index) public onlyActive(_index) {
        DescartesCtx storage i = instance[_index];
        bool afterDeadline = block.timestamp >
            (i.timeOfLastMove + getMaxStateDuration(_index));

        require(afterDeadline, "Deadline is not over for this specific state");

        if (i.currentState == State.WaitingProviders) {
            i.currentState = State.ProviderMissedDeadline;
            emit DescartesFinished(_index, getCurrentState(_index));
            return;
        }
        if (i.currentState == State.WaitingReveals) {
            i.currentState = State.ProviderMissedDeadline;
            emit DescartesFinished(_index, getCurrentState(_index));
            return;
        }
        if (i.currentState == State.WaitingClaim) {
            i.currentState = State.ClaimerMissedDeadline;
            emit DescartesFinished(_index, getCurrentState(_index));
            return;
        }
        if (i.currentState == State.WaitingConfirmationDeadline) {
            i.currentState = State.ConsensusResult;
            emit DescartesFinished(_index, getCurrentState(_index));
            return;
        }

        revert("Cannot abort current state");
    }

    /// @notice Get result of a finished instance.
    /// @param _index index of Descartes instance to get result
    /// @return bool, indicates the result is ready
    /// @return bool, indicates the sdk is still running
    /// @return address, the user to blame for the abnormal stop of the sdk
    /// @return bytes, the result of the sdk if available
    function getResult(uint256 _index)
        public
        view
        override
        onlyInstantiated(_index)
        returns (
            bool,
            bool,
            address,
            bytes memory
        )
    {
        DescartesCtx storage i = instance[_index];
        if (i.currentState == State.ConsensusResult) {
            return (true, false, address(0), i.claimedOutput);
        }
        if (
            i.currentState == State.WaitingProviders ||
            i.currentState == State.WaitingChallengeDrives ||
            i.currentState == State.WaitingClaim ||
            i.currentState == State.WaitingConfirmationDeadline ||
            i.currentState == State.WaitingChallengeResult ||
            i.currentState == State.WaitingReveals
        ) {
            return (false, true, address(0), "");
        }
        if (i.currentState == State.ProviderMissedDeadline) {
            address userToBlame = address(0);
            // check if resulted from the WaitingProviders phase
            if (
                instance[_index].providerDrivesPointer <
                instance[_index].providerDrives.length
            ) {
                userToBlame = i
                .inputDrives[i.providerDrives[i.providerDrivesPointer]]
                .provider;
                // check if resulted from the WaitingReveals phase
            } else if (
                instance[_index].revealDrivesPointer <
                instance[_index].revealDrives.length
            ) {
                userToBlame = i
                .inputDrives[i.revealDrives[i.revealDrivesPointer]]
                .provider;
            }
            return (false, false, userToBlame, "");
        }
        if (
            i.currentState == State.ClaimerMissedDeadline ||
            i.currentState == State.ChallengerWon
        ) {
            return (false, false, i.partiesArray[i.claimer], "");
        }
        if (i.currentState == State.ClaimerWon) {
            return (false, false, i.partiesArray[i.currentChallenger], "");
        }

        revert("Unrecognized state");
    }

    /// @notice Convert bytes32 into bytes8[] and calculate the hashes of them
    function getWordHashesFromBytes32(bytes32 _value)
        private
        pure
        returns (bytes32[] memory)
    {
        bytes32[] memory data = new bytes32[](4);
        for (uint256 i = 0; i < 4; i++) {
            bytes8 dataBytes8 = bytes8(
                (_value << (i * 64)) &
                    0xffffffffffffffff000000000000000000000000000000000000000000000000
            );
            data[i] = keccak256(abi.encodePacked(dataBytes8));
        }
        return data;
    }

    /// @notice Convert bytes into bytes8[] and calculate the hashes of them
    function getWordHashesFromBytes(bytes memory _value)
        private
        pure
        returns (bytes32[] memory)
    {
        uint256 hashesLength = _value.length / 8;
        bytes32[] memory data = new bytes32[](hashesLength);
        for (uint256 i = 0; i < hashesLength; i++) {
            bytes8 dataBytes8;
            for (uint256 j = 0; j < 8; j++) {
                bytes8 tempBytes8 = _value[i * 8 + j];
                tempBytes8 = tempBytes8 >> (j * 8);
                dataBytes8 = dataBytes8 | tempBytes8;
            }
            data[i] = keccak256(abi.encodePacked(dataBytes8));
        }
        return data;
    }

    /// @notice Get the worst case scenario duration for a specific state
    function getMaxStateDuration(uint256 _index)
        private
        view
        returns (uint256)
    {
        // TODO: make sure maxDuration calculations are reasonable
        uint256 partitionSize = 1;
        uint256 picoSecondsToRunInsn = 500; // 500 pico seconds to run a instruction
        uint256 timeToStartMachine = 40; // 40 seconds to start the machine for the first time

        if (instance[_index].currentState == State.WaitingProviders) {
            // time to react
            return instance[_index].roundDuration;
        }

        if (instance[_index].currentState == State.WaitingReveals) {
            // time to upload to logger + time to react
            uint256 maxLoggerUploadTime = 40 * 60;
            return maxLoggerUploadTime + instance[_index].roundDuration;
        }

        if (instance[_index].currentState == State.WaitingChallengeDrives) {
            // number of logger drives * time to react
            return
                instance[_index].revealDrives.length *
                2 *
                instance[_index].roundDuration;
        }

        if (instance[_index].currentState == State.WaitingClaim) {
            // time to run entire machine + time to react
            return
                timeToStartMachine +
                ((instance[_index].finalTime * picoSecondsToRunInsn) / 1e12) +
                instance[_index].roundDuration;
        }

        if (
            instance[_index].currentState == State.WaitingConfirmationDeadline
        ) {
            // time to run entire machine + time to react
            return
                timeToStartMachine +
                ((instance[_index].finalTime * picoSecondsToRunInsn) / 1e12) +
                instance[_index].roundDuration;
        }

        if (instance[_index].currentState == State.WaitingChallengeResult) {
            // time to run a verification game + time to react
            return
                vg.getMaxInstanceDuration(
                    instance[_index].roundDuration,
                    timeToStartMachine,
                    partitionSize,
                    instance[_index].finalTime,
                    picoSecondsToRunInsn
                ) + instance[_index].roundDuration;
        }

        if (
            instance[_index].currentState == State.ClaimerWon ||
            instance[_index].currentState == State.ChallengerWon ||
            instance[_index].currentState == State.ClaimerMissedDeadline ||
            instance[_index].currentState == State.ConsensusResult
        ) {
            return 0; // final state
        }
    }

    /// @notice several require statements for a drive
    modifier requirementsForProviderDrive(uint256 _index) {
        DescartesCtx storage i = instance[_index];
        require(
            i.currentState == State.WaitingProviders,
            "The state is not WaitingProviders"
        );
        require(
            i.providerDrivesPointer < i.providerDrives.length,
            "No available pending drives"
        );

        uint256 driveIndex = i.providerDrives[i.providerDrivesPointer];
        require(driveIndex < i.inputDrives.length, "Invalid drive index");

        Drive memory drive = i.inputDrives[driveIndex];
        require(
            i.driveHash[driveIndex] == bytes32(0),
            "The drive hash shouldn't be filled"
        );
        require(drive.waitsProvider, "waitProvider should be true");
        require(drive.provider == msg.sender, "The sender is not provider");

        _;
    }

    /// @notice checks whether or not it's a party to this instance
    modifier onlyByParty(uint256 _index) {
        DescartesCtx storage i = instance[_index];
        require(
            i.parties[msg.sender].isParty,
            "The sender is not party to this instance"
        );
        _;
    }

    modifier onlyByClaimer(uint256 _index) {
        DescartesCtx storage i = instance[_index];
        require(
            i.partiesArray[i.claimer] == msg.sender,
            "The sender is not Claimer at this instance"
        );
        _;
    }

    /// @notice checks whether or not it's a party to this instance
    modifier onlyNoVotes(uint256 _index) {
        DescartesCtx storage i = instance[_index];
        require(
            !i.parties[msg.sender].hasVoted,
            "Sender has already challenged or claimed"
        );
        _;
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: Apache-2.0
//                                  Apache License
//                            Version 2.0, January 2004
//                         http://www.apache.org/licenses/

//    TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

//    1. Definitions.

//       "License" shall mean the terms and conditions for use, reproduction,
//       and distribution as defined by Sections 1 through 9 of this document.

//       "Licensor" shall mean the copyright owner or entity authorized by
//       the copyright owner that is granting the License.

//       "Legal Entity" shall mean the union of the acting entity and all
//       other entities that control, are controlled by, or are under common
//       control with that entity. For the purposes of this definition,
//       "control" means (i) the power, direct or indirect, to cause the
//       direction or management of such entity, whether by contract or
//       otherwise, or (ii) ownership of fifty percent (50%) or more of the
//       outstanding shares, or (iii) beneficial ownership of such entity.

//       "You" (or "Your") shall mean an individual or Legal Entity
//       exercising permissions granted by this License.

//       "Source" form shall mean the preferred form for making modifications,
//       including but not limited to software source code, documentation
//       source, and configuration files.

//       "Object" form shall mean any form resulting from mechanical
//       transformation or translation of a Source form, including but
//       not limited to compiled object code, generated documentation,
//       and conversions to other media types.

//       "Work" shall mean the work of authorship, whether in Source or
//       Object form, made available under the License, as indicated by a
//       copyright notice that is included in or attached to the work
//       (an example is provided in the Appendix below).

//       "Derivative Works" shall mean any work, whether in Source or Object
//       form, that is based on (or derived from) the Work and for which the
//       editorial revisions, annotations, elaborations, or other modifications
//       represent, as a whole, an original work of authorship. For the purposes
//       of this License, Derivative Works shall not include works that remain
//       separable from, or merely link (or bind by name) to the interfaces of,
//       the Work and Derivative Works thereof.

//       "Contribution" shall mean any work of authorship, including
//       the original version of the Work and any modifications or additions
//       to that Work or Derivative Works thereof, that is intentionally
//       submitted to Licensor for inclusion in the Work by the copyright owner
//       or by an individual or Legal Entity authorized to submit on behalf of
//       the copyright owner. For the purposes of this definition, "submitted"
//       means any form of electronic, verbal, or written communication sent
//       to the Licensor or its representatives, including but not limited to
//       communication on electronic mailing lists, source code control systems,
//       and issue tracking systems that are managed by, or on behalf of, the
//       Licensor for the purpose of discussing and improving the Work, but
//       excluding communication that is conspicuously marked or otherwise
//       designated in writing by the copyright owner as "Not a Contribution."

//       "Contributor" shall mean Licensor and any individual or Legal Entity
//       on behalf of whom a Contribution has been received by Licensor and
//       subsequently incorporated within the Work.

//    2. Grant of Copyright License. Subject to the terms and conditions of
//       this License, each Contributor hereby grants to You a perpetual,
//       worldwide, non-exclusive, no-charge, royalty-free, irrevocable
//       copyright license to reproduce, prepare Derivative Works of,
//       publicly display, publicly perform, sublicense, and distribute the
//       Work and such Derivative Works in Source or Object form.

//    3. Grant of Patent License. Subject to the terms and conditions of
//       this License, each Contributor hereby grants to You a perpetual,
//       worldwide, non-exclusive, no-charge, royalty-free, irrevocable
//       (except as stated in this section) patent license to make, have made,
//       use, offer to sell, sell, import, and otherwise transfer the Work,
//       where such license applies only to those patent claims licensable
//       by such Contributor that are necessarily infringed by their
//       Contribution(s) alone or by combination of their Contribution(s)
//       with the Work to which such Contribution(s) was submitted. If You
//       institute patent litigation against any entity (including a
//       cross-claim or counterclaim in a lawsuit) alleging that the Work
//       or a Contribution incorporated within the Work constitutes direct
//       or contributory patent infringement, then any patent licenses
//       granted to You under this License for that Work shall terminate
//       as of the date such litigation is filed.

//    4. Redistribution. You may reproduce and distribute copies of the
//       Work or Derivative Works thereof in any medium, with or without
//       modifications, and in Source or Object form, provided that You
//       meet the following conditions:

//       (a) You must give any other recipients of the Work or
//           Derivative Works a copy of this License; and

//       (b) You must cause any modified files to carry prominent notices
//           stating that You changed the files; and

//       (c) You must retain, in the Source form of any Derivative Works
//           that You distribute, all copyright, patent, trademark, and
//           attribution notices from the Source form of the Work,
//           excluding those notices that do not pertain to any part of
//           the Derivative Works; and

//       (d) If the Work includes a "NOTICE" text file as part of its
//           distribution, then any Derivative Works that You distribute must
//           include a readable copy of the attribution notices contained
//           within such NOTICE file, excluding those notices that do not
//           pertain to any part of the Derivative Works, in at least one
//           of the following places: within a NOTICE text file distributed
//           as part of the Derivative Works; within the Source form or
//           documentation, if provided along with the Derivative Works; or,
//           within a display generated by the Derivative Works, if and
//           wherever such third-party notices normally appear. The contents
//           of the NOTICE file are for informational purposes only and
//           do not modify the License. You may add Your own attribution
//           notices within Derivative Works that You distribute, alongside
//           or as an addendum to the NOTICE text from the Work, provided
//           that such additional attribution notices cannot be construed
//           as modifying the License.

//       You may add Your own copyright statement to Your modifications and
//       may provide additional or different license terms and conditions
//       for use, reproduction, or distribution of Your modifications, or
//       for any such Derivative Works as a whole, provided Your use,
//       reproduction, and distribution of the Work otherwise complies with
//       the conditions stated in this License.

//    5. Submission of Contributions. Unless You explicitly state otherwise,
//       any Contribution intentionally submitted for inclusion in the Work
//       by You to the Licensor shall be under the terms and conditions of
//       this License, without any additional terms or conditions.
//       Notwithstanding the above, nothing herein shall supersede or modify
//       the terms of any separate license agreement you may have executed
//       with Licensor regarding such Contributions.

//    6. Trademarks. This License does not grant permission to use the trade
//       names, trademarks, service marks, or product names of the Licensor,
//       except as required for reasonable and customary use in describing the
//       origin of the Work and reproducing the content of the NOTICE file.

//    7. Disclaimer of Warranty. Unless required by applicable law or
//       agreed to in writing, Licensor provides the Work (and each
//       Contributor provides its Contributions) on an "AS IS" BASIS,
//       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
//       implied, including, without limitation, any warranties or conditions
//       of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
//       PARTICULAR PURPOSE. You are solely responsible for determining the
//       appropriateness of using or redistributing the Work and assume any
//       risks associated with Your exercise of permissions under this License.

//    8. Limitation of Liability. In no event and under no legal theory,
//       whether in tort (including negligence), contract, or otherwise,
//       unless required by applicable law (such as deliberate and grossly
//       negligent acts) or agreed to in writing, shall any Contributor be
//       liable to You for damages, including any direct, indirect, special,
//       incidental, or consequential damages of any character arising as a
//       result of this License or out of the use or inability to use the
//       Work (including but not limited to damages for loss of goodwill,
//       work stoppage, computer failure or malfunction, or any and all
//       other commercial damages or losses), even if such Contributor
//       has been advised of the possibility of such damages.

//    9. Accepting Warranty or Additional Liability. While redistributing
//       the Work or Derivative Works thereof, You may choose to offer,
//       and charge a fee for, acceptance of support, warranty, indemnity,
//       or other liability obligations and/or rights consistent with this
//       License. However, in accepting such obligations, You may act only
//       on Your own behalf and on Your sole responsibility, not on behalf
//       of any other Contributor, and only if You agree to indemnify,
//       defend, and hold each Contributor harmless for any liability
//       incurred by, or claims asserted against, such Contributor by reason
//       of your accepting any such warranty or additional liability.

//    END OF TERMS AND CONDITIONS

//    Copyright (C) 2020 Cartesi Pte. Ltd.

//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at

//        http://www.apache.org/licenses/LICENSE-2.0

//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

/// @title DescartesInterface
/// @author Stephen Chen



import "@cartesi/util/contracts/Instantiator.sol";


interface DescartesInterface is Instantiator {

    enum State {
        WaitingProviders,
        ProviderMissedDeadline,
        WaitingChallengeDrives,
        WaitingReveals,
        WaitingClaim,
        ClaimerMissedDeadline,
        WaitingConfirmationDeadline, // "Voting Phase"
        WaitingChallengeResult, // "Voting Phase"
        ChallengerWon,
        ClaimerWon,
        ConsensusResult
    }

    /*
    There are two types of drive, one is directDrive, and the other is loggerDrive.
    directDrive has content inserted to the directValue field with up to 1MB;
    loggerDrive has content submitted to the logger contract,
    which can be retrieved with driveLog2Size and loggerRootHash.
    The needsLogger field is set to true for loggerDrive, false for directDrive.

    The waitsProvider field is set to true meaning the drive is not ready,
    and needs to be filled during the WaitingProviders phase.
    The provider field is the user who is responsible for filling out the drive.
    I.e the directValue of directDrive, or the loggerRootHash of loggerDrive
    */
    struct Drive {
        // start position of the drive
        uint64 position;
        // log2 size of the drive in the unit of bytes
        uint8 driveLog2Size;
        // direct value inserted to the drive
        bytes directValue;
        // ipfs object path of the logger drive
        bytes loggerIpfsPath;
        // root hash of the drive submitted to the logger
        bytes32 loggerRootHash;
        // the user who's responsible for filling out the drive
        address provider;
        // indicates the drive needs to wait for the provider to provide content
        bool waitsProvider;
        // indicates the content of the drive must be retrieved from logger
        bool needsLogger;
    }

    struct Party {
        bool isParty;
        bool hasVoted;
        bool hasCheated;
        uint64 arrayIdx;
    }

    /// @notice Instantiate a Descartes SDK instance.
    /// @param _finalTime max cycle of the machine for that computation
    /// @param _templateHash hash of the machine with all drives empty
    /// @param _outputPosition position of the output drive
    /// @param _roundDuration duration of the round (security param)
    /// @param _inputDrives an array of drive which assemble the machine
    /// @return uint256, Descartes index
    function instantiate(
        uint256 _finalTime,
        bytes32 _templateHash,
        uint64 _outputPosition,
        uint8 _outputLog2Size,
        uint256 _roundDuration,
        address[] memory parties,
        Drive[] memory _inputDrives) external returns (uint256);

    /// @notice Get result of a finished instance.
    /// @param _index index of Descartes instance to get result
    /// @return bool, indicates the result is ready
    /// @return bool, indicates the sdk is still running
    /// @return address, the user to blame for the abnormal stop of the sdk
    /// @return bytes32, the result of the sdk if available
    function getResult(uint256 _index) external view returns (
        bool,
        bool,
        address,
        bytes memory);

    /// @notice Deactivate a Descartes SDK instance.
    /// @param _index index of Descartes instance to deactivate
    function destruct(uint256 _index) external;
}