// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
// @unsupported: ovm
pragma solidity >=0.7.6;

import {OVM_CrossDomainEnabled} from "@eth-optimism/contracts/build/contracts/libraries/bridge/OVM_CrossDomainEnabled.sol";

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

  /**
   * @dev Forward a call to be repeated on L2.
   */
  function relay(address target, bytes calldata targetData, uint32 l2gas) external auth {
    // Construct calldata for L2GovernanceRelay.relay(target, targetData)
    bytes memory data = abi.encodeWithSelector(
      L2GovernanceRelay.relay.selector,
      target,
      targetData
    );

    // Send calldata into L2
    sendCrossDomainMessage(
      l2GovernanceRelay,
      data,
      l2gas
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
/* Interface Imports */
import { iAbs_BaseCrossDomainMessenger } from "../../iOVM/bridge/messaging/iAbs_BaseCrossDomainMessenger.sol";

/**
 * @title OVM_CrossDomainEnabled
 * @dev Helper contract for contracts performing cross-domain communications
 *
 * Compiler used: defined by inheriting contract
 * Runtime target: defined by inheriting contract
 */
contract OVM_CrossDomainEnabled {
    // Messenger contract used to send and recieve messages from the other domain.
    address public messenger;

    /***************
     * Constructor *
     ***************/    
    constructor(
        address _messenger
    ) {
        messenger = _messenger;
    }

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * @notice Enforces that the modified function is only callable by a specific cross-domain account.
     * @param _sourceDomainAccount The only account on the originating domain which is authenticated to call this function.
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
     * @notice Gets the messenger, usually from storage.  This function is exposed in case a child contract needs to override.
     * @return The address of the cross-domain messenger contract which should be used. 
     */
    function getCrossDomainMessenger()
        internal
        virtual
        returns(
            iAbs_BaseCrossDomainMessenger
        )
    {
        return iAbs_BaseCrossDomainMessenger(messenger);
    }

    /**
     * @notice Sends a message to an account on another domain
     * @param _crossDomainTarget The intended recipient on the destination domain
     * @param _data The data to send to the target (usually calldata to a function with `onlyFromCrossDomainAccount()`)
     * @param _gasLimit The gasLimit for the receipt of the message on the target domain.
     */
    function sendCrossDomainMessage(
        address _crossDomainTarget,
        bytes memory _data,
        uint32 _gasLimit
    ) internal {
        getCrossDomainMessenger().sendMessage(_crossDomainTarget, _data, _gasLimit);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.6;


import {OVM_CrossDomainEnabled} from "@eth-optimism/contracts/build/contracts/libraries/bridge/OVM_CrossDomainEnabled.sol";

// Receive xchain message from L1 counterpart and execute given spell

contract L2GovernanceRelay is OVM_CrossDomainEnabled {

  event Initialized(address l1GovernanceRelay);

  address public l1GovernanceRelay;

  constructor(
    address _l2CrossDomainMessenger
  )
    OVM_CrossDomainEnabled(_l2CrossDomainMessenger)
  {}

  function init(
    address _l1GovernanceRelay
  )
    public
  {
    require(address(l1GovernanceRelay) == address(0), "Contract has already been initialized");

    l1GovernanceRelay = _l1GovernanceRelay;
      
    emit Initialized(_l1GovernanceRelay);
  }

  modifier onlyInitialized() {
    require(address(l1GovernanceRelay) != address(0), "Contract has not yet been initialized");
    _;
  }

  /**
   * @dev Execute the call from L1.
   */
  function relay(address target, bytes calldata targetData)
    external
    onlyInitialized()
    onlyFromCrossDomainAccount(address(l1GovernanceRelay))
  {
    // Ensure no storage changes in the delegate call
    address _l1GovernanceRelay = l1GovernanceRelay;
    address _messenger = messenger;

    bool ok;
    (ok,) = target.delegatecall(targetData);
    require(ok, "L2GovernanceRelay/delegatecall-error");

    require(_l1GovernanceRelay == l1GovernanceRelay && _messenger == messenger, "L2GovernanceRelay/illegal-storage-change");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title iAbs_BaseCrossDomainMessenger
 */
interface iAbs_BaseCrossDomainMessenger {

    /**********
     * Events *
     **********/
    event SentMessage(bytes message);
    event RelayedMessage(bytes32 msgHash);

    /**********************
     * Contract Variables *
     **********************/
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

