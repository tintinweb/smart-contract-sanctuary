// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OracleReq {

	uint256 constant private CHAIN_ID = 80001;
  uint256 constant private ARGS_VERSION = 1;
  uint256 public nonce;


  mapping(bytes32 => bytes32) public commitments;

  event OracleRequest(
    bytes32 indexed specId,
    address requester,
    bytes32 requestId,
    uint256 payment,
    address callbackAddr,
    bytes4 callbackFunctionId,
    uint256 cancelExpiration,
    uint256 dataVersion,
    bytes data
  );
  function oracleRequest(
    bytes32 _specId,
    address _sender,
    uint256 _payment,
    address _callbackAddress,
    bytes4 _callbackFunctionId,
    bytes memory _data
  )
    private
  {
    bytes32 requestId = keccak256(abi.encodePacked(msg.sender, nonce));
    uint256 expiration = block.timestamp + 5 minutes;
    nonce += 1;

    require(commitments[requestId] == 0, "Must use a unique ID");
    commitments[requestId] = keccak256(_data);

    emit OracleRequest(
      _specId,
      _sender,
      requestId,
      _payment,
      _callbackAddress,
      _callbackFunctionId,
      expiration,
      ARGS_VERSION,
      _data);
  }
  function synTransaction(bytes32 _specId, uint256 _synChainId, uint256 _txIndex) external {
    bytes memory data = abi.encode(_synChainId, CHAIN_ID, _txIndex);
    oracleRequest(_specId, msg.sender, 0,  address(this), this.fulfill.selector, data);
  }
    function fulfill(bytes32 _requestId, bytes4 _callbackFunctionId, bytes calldata _data) external {

  }
}