/*

  Copyright 2018 Dexdex.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.4.21;


/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */

contract Ownable {
    address public owner;

    function Ownable()
        public
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

library SafeMath {
    function safeMul(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

contract Members is Ownable {

  mapping(address => bool) public members; // Mappings of addresses of allowed addresses

  modifier onlyMembers() {
    require(isValidMember(msg.sender));
    _;
  }

  /// @dev Check if an address is a valid member.
  function isValidMember(address _member) public view returns(bool) {
    return members[_member];
  }

  /// @dev Add a valid member address. Only owner.
  function addMember(address _member) public onlyOwner {
    members[_member] = true;
  }

  /// @dev Remove a member address. Only owner.
  function removeMember(address _member) public onlyOwner {
    delete members[_member];
  }
}

contract IFeeWallet {

  function getFee(
    uint amount) public view returns(uint);

  function collect(
    address _affiliate) public payable;
}

contract FeeWallet is IFeeWallet, Ownable, Members {

  address public serviceAccount; // Address of service account
  uint public servicePercentage; // Percentage times (1 ether)
  uint public affiliatePercentage; // Percentage times (1 ether)

  mapping (address => uint) public pendingWithdrawals; // Balances

  function FeeWallet(
    address _serviceAccount,
    uint _servicePercentage,
    uint _affiliatePercentage) public
  {
    serviceAccount = _serviceAccount;
    servicePercentage = _servicePercentage;
    affiliatePercentage = _affiliatePercentage;
  }

  /// @dev Set the new service account. Only owner.
  function changeServiceAccount(address _serviceAccount) public onlyOwner {
    serviceAccount = _serviceAccount;
  }

  /// @dev Set the service percentage. Only owner.
  function changeServicePercentage(uint _servicePercentage) public onlyOwner {
    servicePercentage = _servicePercentage;
  }

  /// @dev Set the affiliate percentage. Only owner.
  function changeAffiliatePercentage(uint _affiliatePercentage) public onlyOwner {
    affiliatePercentage = _affiliatePercentage;
  }

  /// @dev Calculates the service fee for a specific amount. Only owner.
  function getFee(uint amount) public view returns(uint)  {
    return SafeMath.safeMul(amount, servicePercentage) / (1 ether);
  }

  /// @dev Calculates the affiliate amount for a specific amount. Only owner.
  function getAffiliateAmount(uint amount) public view returns(uint)  {
    return SafeMath.safeMul(amount, affiliatePercentage) / (1 ether);
  }

  /// @dev Collects fees according to last payment receivedi. Only valid smart contracts.
  function collect(
    address _affiliate) public payable onlyMembers
  {
    if(_affiliate == address(0))
      pendingWithdrawals[serviceAccount] += msg.value;
    else {
      uint affiliateAmount = getAffiliateAmount(msg.value);
      pendingWithdrawals[_affiliate] += affiliateAmount;
      pendingWithdrawals[serviceAccount] += SafeMath.safeSub(msg.value, affiliateAmount);
    }
  }

  /// @dev Withdraw.
  function withdraw() public {
    uint amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    msg.sender.transfer(amount);
  }
}