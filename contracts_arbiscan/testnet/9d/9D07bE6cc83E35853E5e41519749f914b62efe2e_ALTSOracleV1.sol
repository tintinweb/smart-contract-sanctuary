/**
 *Submitted for verification at arbiscan.io on 2021-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface CustomOracleV1 {
  function updatePrice(uint256 _price) external;

  function getLatestAnswer() external view returns (uint256);
}

contract ALTSOracleV1 is CustomOracleV1, Ownable {
  address public devAddress;
  
  uint256 public price;

  event PriceUpdated(address indexed updater, uint256 newPrice);

  constructor() {
    devAddress = msg.sender;
  }

  function updatePrice(uint256 _price) external override {
    require(msg.sender == devAddress, "ALTSOracleV1::updatePrice: not allowed to update the price");
    price  = _price;

    emit PriceUpdated(msg.sender, _price);
  }

  function getLatestAnswer() public override view returns (uint256) {
    return price;
  }
}