/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico
// Copyright (C) 2021 Dai Foundation
// Copyright (C) 2021 Servo Farms, LLC

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

pragma solidity 0.6.12;

interface MKRToken {
  function totalSupply() external view returns (uint supply);
  function balanceOf( address who ) external view returns (uint value);
  function allowance( address owner, address spender ) external view returns (uint _allowance);

  function transfer( address to, uint value) external returns (bool ok);
  function transferFrom( address from, address to, uint value) external returns (bool ok);
  function approve( address spender, uint value ) external returns (bool ok);
}

contract Breaker {

  // --- ERC20 Data ---
  string   public constant name     = "Breaker Token";
  string   public constant symbol   = "BKR";
  string   public constant version  = "1";
  uint8    public constant decimals = 18;
  MKRToken public constant MKR      = MKRToken(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
  uint256  public totalSupply;

  mapping (address => uint256)                      public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;
  mapping (address => uint256)                      public nonces;

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Rely(address indexed usr);
  event Deny(address indexed usr);

  // --- Math ---
  function _add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x);
  }
  function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x);
  }
  function _mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x);
  }

  // --- EIP712 niceties ---
  uint256 public  immutable deploymentChainId;
  bytes32 private immutable _DOMAIN_SEPARATOR;
  bytes32 public  constant  PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  constructor() public {
    uint256 chainId;
    assembly {chainId := chainid()}
    deploymentChainId = chainId;
    _DOMAIN_SEPARATOR = _calculateDomainSeparator(chainId);
  }

  function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
    return keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        chainId,
        address(this)
      )
    );
  }
  function DOMAIN_SEPARATOR() external view returns (bytes32) {
    uint256 chainId;
    assembly {chainId := chainid()}
    return chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
  }

  // --- ERC20 Mutations ---
  function transfer(address to, uint256 value) external returns (bool) {
    require(to != address(0) && to != address(this), "Breaker/invalid-address");
    uint256 balance = balanceOf[msg.sender];
    require(balance >= value, "Breaker/insufficient-balance");

    balanceOf[msg.sender] = balance - value;
    balanceOf[to] += value;

    emit Transfer(msg.sender, to, value);

    return true;
  }
  function transferFrom(address from, address to, uint256 value) external returns (bool) {
    require(to != address(0) && to != address(this), "Breaker/invalid-address");
    uint256 balance = balanceOf[from];
    require(balance >= value, "Breaker/insufficient-balance");

    if (from != msg.sender) {
      uint256 allowed = allowance[from][msg.sender];
      if (allowed != type(uint256).max) {
        require(allowed >= value, "Breaker/insufficient-allowance");

        allowance[from][msg.sender] = allowed - value;
      }
    }

    balanceOf[from] = balance - value;
    balanceOf[to] += value;

    emit Transfer(from, to, value);

    return true;
  }
  function approve(address spender, uint256 value) external returns (bool) {
    allowance[msg.sender][spender] = value;

    emit Approval(msg.sender, spender, value);

    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
    uint256 newValue = _add(allowance[msg.sender][spender], addedValue);
    allowance[msg.sender][spender] = newValue;

    emit Approval(msg.sender, spender, newValue);

    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    uint256 allowed = allowance[msg.sender][spender];
    require(allowed >= subtractedValue, "Breaker/insufficient-allowance");
    allowed = allowed - subtractedValue;
    allowance[msg.sender][spender] = allowed;

    emit Approval(msg.sender, spender, allowed);

    return true;
  }

  // --- Approve by signature ---
  function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
    require(block.timestamp <= deadline, "Breaker/permit-expired");

    uint256 chainId;
    assembly {chainId := chainid()}

    bytes32 digest =
      keccak256(abi.encodePacked(
          "\x19\x01",
          chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId),
          keccak256(abi.encode(
            PERMIT_TYPEHASH,
            owner,
            spender,
            value,
            nonces[owner]++,
            deadline
          ))
      ));

    require(owner != address(0) && owner == ecrecover(digest, v, r, s), "Breaker/invalid-permit");

    allowance[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function mkrToBkr(uint256 mkr) public pure returns (uint256 bkr) {
    return _mul(mkr, 10**9);
  }

  function bkrToMkr(uint256 bkr) public pure returns (uint256 mkr) {
    return bkr / 10**9;
  }

  /**
  * @dev   Make Maker into Breaker
  *        (user must approve() this contract on MKR)
  * @param mkr  amount of MKR tokens to be wrapped
  */
  function breaker(uint256 mkr) public returns (uint256 bkr) {
    MKR.transferFrom(
        msg.sender,
        address(this),
        mkr
    );
    bkr = mkrToBkr(mkr);
    balanceOf[msg.sender] = _add(balanceOf[msg.sender], bkr);
    totalSupply   = _add(totalSupply, bkr);
    emit Transfer(address(0), msg.sender, bkr);
  }

  /**
  * @dev   Make Breaker into Maker
  * @param bkr  amount of tokens to be unwrapped (amount will be rounded to Conti units)
  */
  function maker(uint256 bkr) public returns (uint256 mkr) {
    mkr = bkrToMkr(bkr);
    bkr = mkrToBkr(mkr);

    uint256 balance = balanceOf[msg.sender];
    require(balance >= bkr, "Breaker/insufficient-balance");
    balanceOf[msg.sender] = balance - bkr;
    totalSupply     = _sub(totalSupply, bkr);

    MKR.transfer(msg.sender, mkr);

    emit Transfer(msg.sender, address(0), bkr);
  }
}