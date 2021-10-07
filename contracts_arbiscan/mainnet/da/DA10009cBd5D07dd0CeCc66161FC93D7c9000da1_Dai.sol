// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico
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

pragma solidity ^0.6.11;

// Improved Dai token

contract Dai {

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
    require(wards[msg.sender] == 1, "Dai/not-authorized");
    _;
  }

  // --- ERC20 Data ---
  string  public constant name     = "Dai Stablecoin";
  string  public constant symbol   = "DAI";
  string  public constant version  = "2";
  uint8   public constant decimals = 18;
  uint256 public totalSupply;

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

  // --- EIP712 niceties ---
  uint256 public immutable deploymentChainId;
  bytes32 private immutable _DOMAIN_SEPARATOR;
  bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  constructor() public {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);

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
    require(to != address(0) && to != address(this), "Dai/invalid-address");
    uint256 balance = balanceOf[msg.sender];
    require(balance >= value, "Dai/insufficient-balance");

    balanceOf[msg.sender] = balance - value;
    balanceOf[to] += value;

    emit Transfer(msg.sender, to, value);

    return true;
  }
  function transferFrom(address from, address to, uint256 value) external returns (bool) {
    require(to != address(0) && to != address(this), "Dai/invalid-address");
    uint256 balance = balanceOf[from];
    require(balance >= value, "Dai/insufficient-balance");

    if (from != msg.sender) {
      uint256 allowed = allowance[from][msg.sender];
      if (allowed != type(uint256).max) {
        require(allowed >= value, "Dai/insufficient-allowance");

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
    require(allowed >= subtractedValue, "Dai/insufficient-allowance");
    allowed = allowed - subtractedValue;
    allowance[msg.sender][spender] = allowed;

    emit Approval(msg.sender, spender, allowed);

    return true;
  }

  // --- Mint/Burn ---
  function mint(address to, uint256 value) external auth {
    require(to != address(0) && to != address(this), "Dai/invalid-address");
    balanceOf[to] = balanceOf[to] + value; // note: we don't need an overflow check here b/c balanceOf[to] <= totalSupply and there is an overflow check below
    totalSupply   = _add(totalSupply, value);

    emit Transfer(address(0), to, value);
  }
  function burn(address from, uint256 value) external {
    uint256 balance = balanceOf[from];
    require(balance >= value, "Dai/insufficient-balance");

    if (from != msg.sender && wards[msg.sender] != 1) {
      uint256 allowed = allowance[from][msg.sender];
      if (allowed != type(uint256).max) {
        require(allowed >= value, "Dai/insufficient-allowance");

        allowance[from][msg.sender] = allowed - value;
      }
    }

    balanceOf[from] = balance - value; // note: we don't need overflow checks b/c require(balance >= value) and balance <= totalSupply
    totalSupply     = totalSupply - value;

    emit Transfer(from, address(0), value);
  }

  // --- Approve by signature ---
  function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
    require(block.timestamp <= deadline, "Dai/permit-expired");

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

    require(owner != address(0) && owner == ecrecover(digest, v, r, s), "Dai/invalid-permit");

    allowance[owner][spender] = value;
    emit Approval(owner, spender, value);
  }
}