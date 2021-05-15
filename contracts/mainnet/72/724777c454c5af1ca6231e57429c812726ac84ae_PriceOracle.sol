/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ILinkOracle {
  function latestAnswer() external view returns(uint);
  function decimals() external view returns(int256);
}

contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract PriceOracle is Ownable {

  mapping(address => ILinkOracle) public linkOracles;
  mapping(address => uint) private tokenPrices;

  function addLinkOracle(address _token, ILinkOracle _linkOracle) public onlyOwner {
    require(_linkOracle.decimals() == 8, "PriceOracle: non-usd pairs not allowed");
    linkOracles[_token] = _linkOracle;
  }

  function setTokenPrice(address _token, uint _value) public onlyOwner {
    tokenPrices[_token] = _value;
  }

  // _token price in USD with 18 decimals
  function tokenPrice(address _token) public view returns(uint) {

    if (address(linkOracles[_token]) != address(0)) {
      return linkOracles[_token].latestAnswer() * 1e10;

    } else if (tokenPrices[_token] != 0) {
      return tokenPrices[_token];

    } else {
      revert("PriceOracle: token not supported");
    }
  }

  function tokenSupported(address _token) public view returns(bool) {
    return (
      address(linkOracles[_token]) != address(0) ||
      tokenPrices[_token] != 0
    );
  }
}