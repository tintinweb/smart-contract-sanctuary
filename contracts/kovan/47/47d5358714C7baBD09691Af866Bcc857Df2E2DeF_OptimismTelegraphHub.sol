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

//SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.7.0;

import { OVM_CrossDomainEnabled } from "@eth-optimism/contracts/libraries/bridge/OVM_CrossDomainEnabled.sol";
import "./TelegraphHub.sol";

contract OptimismTelegraphHub is TelegraphHub, OVM_CrossDomainEnabled {
  address public immutable l2Receiver;

  uint32 public DEFAULT_FINALIZE_DEPOSIT_L2_GAS = 4000000;

  constructor(address _l2Receiver, address _inbox, address l1Messenger)
    OVM_CrossDomainEnabled(l1Messenger)
  {
    l2Receiver = _l2Receiver;
  }

  function sendUpdate(
    address[] memory tokens,
    uint256[] memory prices,
    bytes memory /*bridgeData*/
  ) internal override {
    bytes memory data = abi.encodeWithSignature("updatePrices(address[],uint256[])", tokens, prices);

    sendCrossDomainMessage(l2Receiver, data, DEFAULT_FINALIZE_DEPOSIT_L2_GAS);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract TelegraphHub {
  address public owner;

  struct AddressAndSelector {
    address contractAddress;
    bytes4 selector;
  }

  mapping(address => AddressAndSelector) private tokenToAddress;
  mapping(address => bytes) private tokenToData;

  constructor() {
    // owner = tx.origin;
  }

  modifier onlyOwner {
    // require(msg.sender == owner, "Not Owner");
    _;
  }

  function getTokenCall(address token) public view returns (address contractAddress, bytes memory data) {
    AddressAndSelector memory _address = tokenToAddress[token];
    require(_address.contractAddress != address(0), 'Not set');
    contractAddress = _address.contractAddress;
    data = _address.selector == bytes4(0) ? tokenToData[token] : abi.encodePacked(_address.selector);
  }

  function currentPrice(address token) public view returns (uint256 price) {
    (address contractAddress, bytes memory data) = getTokenCall(token);
    (bool success, bytes memory response) = contractAddress.staticcall(data);
    require(success, string(response));
    (price) = abi.decode(response, (uint256)); 
  }

  function setTokenExchangeSource(
    address token,
    address source,
    bytes4 selector,
    bytes calldata data
  ) external onlyOwner {
    if (data.length == 0) {
      tokenToAddress[token] = AddressAndSelector(source, selector);
    } else {
      tokenToAddress[token] = AddressAndSelector(source, bytes4(0));
      tokenToData[token] = abi.encodePacked(selector, data);
    }
    // Emit an event
  }

  function updateTokens(address[] calldata tokens, bytes calldata bridgeData) external payable {
    uint256[] memory prices = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i += 1) {
      uint256 price = currentPrice(tokens[i]);
      prices[i] = price;
    }
    sendUpdate(tokens, prices, bridgeData);
  }

  function sendUpdate(address[] memory tokens, uint256[] memory prices, bytes memory bridgeData) internal virtual {}
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 2000
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}