// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
// @unsupported: ovm
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.7.6;

import {OVM_CrossDomainEnabled} from "@eth-optimism/contracts/libraries/bridge/OVM_CrossDomainEnabled.sol";

import "../l2/L2GovernanceRelay.sol";

// Relay a message from L1 to L2GovernanceRelay

contract L1GovernanceRelay is OVM_CrossDomainEnabled {
    
  // --- Auth ---
  mapping (address => uint256) public wards;
  function rely(address usr) external auth {
    wards[usr] = 1;
    emit Rely(usr);
  }
  function deny(address usr) external auth {
    wards[usr] = 0;
    emit Deny(usr);
  }
  modifier auth {
    require(wards[msg.sender] == 1, "L1GovernanceRelay/not-authorized");
    _;
  }

  address public immutable l2GovernanceRelay;

  event Rely(address indexed usr);
  event Deny(address indexed usr);

  constructor(
    address _l2GovernanceRelay,
    address _l1messenger 
  )
    OVM_CrossDomainEnabled(_l1messenger)
  {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);

    l2GovernanceRelay = _l2GovernanceRelay;
  }

  // Forward a call to be repeated on L2
  function relay(address target, bytes calldata targetData, uint32 l2gas) external auth {
    bytes memory data = abi.encodeWithSelector(
      L2GovernanceRelay.relay.selector,
      target,
      targetData
    );

    sendCrossDomainMessage(
      l2GovernanceRelay,
      l2gas,
      data
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Interface Imports */
import { iOVM_CrossDomainMessenger } from "../../iOVM/bridge/messaging/iOVM_CrossDomainMessenger.sol";

/**
 * @title OVM_CrossDomainEnabled
 * @dev Helper contract for contracts performing cross-domain communications
 *
 * Compiler used: defined by inheriting contract
 * Runtime target: defined by inheriting contract
 */
contract OVM_CrossDomainEnabled {

    /*************
     * Variables *
     *************/

    // Messenger contract used to send and recieve messages from the other domain.
    address public messenger;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _messenger Address of the CrossDomainMessenger on the current layer.
     */
    constructor(
        address _messenger
    ) {
        messenger = _messenger;
    }


    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Enforces that the modified function is only callable by a specific cross-domain account.
     * @param _sourceDomainAccount The only account on the originating domain which is
     *  authenticated to call this function.
     */
    modifier onlyFromCrossDomainAccount(
        address _sourceDomainAccount
    ) {
        require(
            msg.sender == address(getCrossDomainMessenger()),
            "OVM_XCHAIN: messenger contract unauthenticated"
        );

        require(
            getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount,
            "OVM_XCHAIN: wrong sender of cross-domain message"
        );

        _;
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Gets the messenger, usually from storage. This function is exposed in case a child contract
     * needs to override.
     * @return The address of the cross-domain messenger contract which should be used.
     */
    function getCrossDomainMessenger()
        internal
        virtual
        returns (
            iOVM_CrossDomainMessenger
        )
    {
        return iOVM_CrossDomainMessenger(messenger);
    }

    /**
     * Sends a message to an account on another domain
     * @param _crossDomainTarget The intended recipient on the destination domain
     * @param _message The data to send to the target (usually calldata to a function with
     *  `onlyFromCrossDomainAccount()`)
     * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
     */
    function sendCrossDomainMessage(
        address _crossDomainTarget,
        uint32 _gasLimit,
        bytes memory _message
    )
        internal
    {
        getCrossDomainMessenger().sendMessage(_crossDomainTarget, _message, _gasLimit);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.7.6;

import {OVM_CrossDomainEnabled} from "@eth-optimism/contracts/libraries/bridge/OVM_CrossDomainEnabled.sol";

// Receive xchain message from L1 counterpart and execute given spell

contract L2GovernanceRelay is OVM_CrossDomainEnabled {
  
  address public immutable l1GovernanceRelay;

  constructor(
    address _l2CrossDomainMessenger,
    address _l1GovernanceRelay
  )
    OVM_CrossDomainEnabled(_l2CrossDomainMessenger)
  {
    l1GovernanceRelay = _l1GovernanceRelay;
  }

  /**
   * @dev Execute the call from L1.
   */
  function relay(address target, bytes calldata targetData)
    external
    onlyFromCrossDomainAccount(l1GovernanceRelay)
  {
    // Ensure no storage changes in the delegate call
    // Target address is trusted so this is mostly to avoid a human error
    // Note: we don't check l1GovernanceRelay because it's immutable
    address _messenger = messenger;

    bool ok;
    (ok,) = target.delegatecall(targetData);
    require(ok, "L2GovernanceRelay/delegatecall-error");

    require(_messenger == messenger, "L2GovernanceRelay/illegal-storage-change");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title iOVM_CrossDomainMessenger
 */
interface iOVM_CrossDomainMessenger {

    /**********
     * Events *
     **********/

    event SentMessage(bytes message);
    event RelayedMessage(bytes32 msgHash);
    event FailedRelayedMessage(bytes32 msgHash);


    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);


    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}