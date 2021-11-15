//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// import "./IBridge.sol";
// import "./IMessageProvider.sol";

interface IInbox /*is IMessageProvider*/ {
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth(address destAddr) external payable returns (uint256);

    function depositEthRetryable(address destAddr, uint256 maxSubmissionCost, uint256 maxGas, uint256 maxGasPrice) external payable returns (uint256);

    function bridge() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/IInbox.sol";
import "./TelegraphHub.sol";

contract ArbitrumTelegraphHub is TelegraphHub {
  address public immutable l2Receiver;
  IInbox public immutable inbox;

  constructor(address _l2Receiver, address _inbox) {
    inbox = IInbox(_inbox);
    l2Receiver = _l2Receiver;
  }

  function sendUpdate(
    address[] memory tokens,
    uint256[] memory prices,
    bytes memory bridgeData
  ) internal override {
    (uint256 maxGas, uint256 gasPriceBid) = abi.decode(bridgeData, (uint256, uint256));
    // (uint256 maxSubmissionCost, uint256 maxGas, uint256 gasPriceBid) =
    //   abi.decode(bridgeData, (uint256, uint256, uint256));

    bytes memory data = abi.encodeWithSignature("updatePrices(address[],uint256[])", tokens, prices);
// 0x56fe4a4aeea889a54d652b67ed182df69be6cdc525647c86d3fa3a35c318d859
// 0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
// 0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    // inbox.createRetryableTicket{ value: msg.value }(
    //   l2Receiver,
    //   0,
    //   maxSubmissionCost,
    //   msg.sender,
    //   msg.sender,
    //   maxGas,
    //   gasPriceBid,
    //   data
    // );
    inbox.sendL1FundedContractTransaction{ value: msg.value }(
      maxGas,
      gasPriceBid,
      l2Receiver,
      data
    );
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
    owner = tx.origin;
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

