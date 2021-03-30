//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./FlashbotsCheckAndSend.sol";
import "./IWETH.sol";

import "./Counters.sol";
import "./ECDSA.sol";
import "./EIP712.sol";

/*
  Copyright 2021 Kendrick Tan ([email protected]).

  This contract is an extension of flashbot's FlashbotsCheckAndSend.sol
  This contract takes in WETH instead of ETH so that transactions can be signed via a browser.
  But needs to be approved beforehand.
*/

contract MEVBriber is FlashbotsCheckAndSend, EIP712 {
  using Counters for Counters.Counter;

  constructor() EIP712("MEVBriber", "1") {}

  IWETH public constant WETH =
    IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  event Bribed(address indexed briber, address indexed miner, uint256 amount);

  bytes32 public constant PERMIT_TYPEHASH =
    keccak256(
      "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

  mapping(address => Counters.Counter) private _nonces;

  receive() external payable {}

  function check32BytesAndSendWETH(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    address _target,
    bytes memory _payload,
    bytes32 _resultMatch
  ) external {
    briberPermitted(_owner, _spender, _value, _deadline, _v, _r, _s);
    _check32Bytes(_target, _payload, _resultMatch);
    WETH.transferFrom(_owner, address(this), _value);
    WETH.withdraw(_value);
    block.coinbase.transfer(_value);

    emit Bribed(_owner, block.coinbase, _value);
  }

  function check32BytesAndSendMultiWETH(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    address[] memory _targets,
    bytes[] memory _payloads,
    bytes32[] memory _resultMatches
  ) external {
    require(_targets.length == _payloads.length);
    require(_targets.length == _resultMatches.length);
    briberPermitted(_owner, _spender, _value, _deadline, _v, _r, _s);
    for (uint256 i = 0; i < _targets.length; i++) {
      _check32Bytes(_targets[i], _payloads[i], _resultMatches[i]);
    }
    WETH.transferFrom(_owner, address(this), _value);
    WETH.withdraw(_value);
    block.coinbase.transfer(_value);

    emit Bribed(_owner, block.coinbase, _value);
  }

  function checkBytesAndSendWETH(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    address _target,
    bytes memory _payload,
    bytes memory _resultMatch
  ) external {
    briberPermitted(_owner, _spender, _value, _deadline, _v, _r, _s);
    _checkBytes(_target, _payload, _resultMatch);
    WETH.transferFrom(_owner, address(this), _value);
    WETH.withdraw(_value);
    block.coinbase.transfer(_value);

    emit Bribed(_owner, block.coinbase, _value);
  }

  function checkBytesAndSendMultiWETH(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    address[] memory _targets,
    bytes[] memory _payloads,
    bytes[] memory _resultMatches
  ) external {
    require(_targets.length == _payloads.length);
    require(_targets.length == _resultMatches.length);
    briberPermitted(_owner, _spender, _value, _deadline, _v, _r, _s);
    for (uint256 i = 0; i < _targets.length; i++) {
      _checkBytes(_targets[i], _payloads[i], _resultMatches[i]);
    }
    WETH.transferFrom(_owner, address(this), _value);
    WETH.withdraw(_value);
    block.coinbase.transfer(_value);

    emit Bribed(_owner, block.coinbase, _value);
  }

  // Briber permit functionality
  function briberPermitted(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

    bytes32 structHash =
      keccak256(
        abi.encode(
          PERMIT_TYPEHASH,
          owner,
          spender,
          value,
          _nonces[owner].current(),
          deadline
        )
      );

    bytes32 hash = _hashTypedDataV4(structHash);

    address signer = ECDSA.recover(hash, v, r, s);
    require(signer == owner, "ERC20Permit: invalid signature");
    require(spender == address(this), "ERC20Permit: invalid signature");

    _nonces[owner].increment();
  }

  // **** Helpers ****

  function nonces(address owner) public view virtual returns (uint256) {
    return _nonces[owner].current();
  }
}