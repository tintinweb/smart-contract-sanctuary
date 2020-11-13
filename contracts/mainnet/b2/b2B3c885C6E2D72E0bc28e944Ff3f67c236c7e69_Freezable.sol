/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
pragma solidity ^0.5.2;

import "LibConstants.sol";
import "MFreezable.sol";
import "MGovernance.sol";
import "MainStorage.sol";

/*
  Implements MFreezable.
*/
contract Freezable is MainStorage, LibConstants, MGovernance, MFreezable {
    event LogFrozen();
    event LogUnFrozen();

    modifier notFrozen()
    {
        require(!stateFrozen, "STATE_IS_FROZEN");
        _;
    }

    modifier onlyFrozen()
    {
        require(stateFrozen, "STATE_NOT_FROZEN");
        _;
    }

    function isFrozen()
        external view
        returns (bool frozen) {
        frozen = stateFrozen;
    }

    function freeze()
        internal
        notFrozen()
    {
        // solium-disable-next-line security/no-block-members
        unFreezeTime = now + UNFREEZE_DELAY;

        // Update state.
        stateFrozen = true;

        // Log event.
        emit LogFrozen();
    }

    function unFreeze()
        external
        onlyFrozen()
        onlyGovernance()
    {
        // solium-disable-next-line security/no-block-members
        require(now >= unFreezeTime, "UNFREEZE_NOT_ALLOWED_YET");  // NOLINT: timestamp.

        // Update state.
        stateFrozen = false;

        // Increment roots to invalidate them, w/o losing information.
        vaultRoot += 1;
        orderRoot += 1;

        // Log event.
        emit LogUnFrozen();
    }

}
