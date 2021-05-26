/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IPriceOracle {
  function tokenPrice(address _token) external view returns(uint);
  function tokenSupported(address _token) external view returns(bool);
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

contract OracleAggregator is Ownable {

  IPriceOracle public linkOracle;
  IPriceOracle public uniOracle;

  event LinkOracleUpdated(address indexed oracle);
  event UniOracleUpdated(address indexed oracle);

  constructor(IPriceOracle _linkOracle, IPriceOracle _uniOracle) {
    linkOracle = _linkOracle;
    uniOracle  = _uniOracle;
  }

  function setLinkOracle(IPriceOracle _value) public onlyOwner {
    linkOracle = _value;
    emit LinkOracleUpdated(address(_value));
  }

  function setUniOracle(IPriceOracle _value) public onlyOwner {
    uniOracle = _value;
    emit UniOracleUpdated(address(_value));
  }

  function tokenPrice(address _token) public view returns(uint) {
    if (linkOracle.tokenSupported(_token)) { return linkOracle.tokenPrice(_token); }
    if (uniOracle.tokenSupported(_token)) { return uniOracle.tokenPrice(_token); }
    revert("OracleAggregator: token not supported");
  }

  function tokenSupported(address _token) public view returns(bool) {
    return linkOracle.tokenSupported(_token) || uniOracle.tokenSupported(_token);
  }
}