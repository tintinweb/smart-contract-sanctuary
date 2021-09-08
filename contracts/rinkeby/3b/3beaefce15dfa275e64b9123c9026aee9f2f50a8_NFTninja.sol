/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract Ownable {
  address public _owner;

  modifier onlyOwner {
    require(msg.sender == _owner, "Ownable: caller is not the owner");
    _;
  }

  constructor ()  {
    _owner = msg.sender;
  }
}

contract NFTninja is Ownable {
    uint256 private _feeTrader;
    mapping (address => bool) private _isTrader;
    uint256 private _feeNinja;
    mapping (address => bool) private _isNinja;

    constructor() {
        _feeTrader = 0.10 ether;
        _feeNinja = 1 ether;
        _isTrader[msg.sender] = true;
        _isNinja[msg.sender] = true;
    }

    function getFeeTrader() external view returns(uint256) {
        return(_feeTrader);
    }
    function isTrader(address account) external view returns(bool) {
        return(_isTrader[account]);
    }
    function getFeeNinja() external view returns(uint256) {
        return(_feeNinja);
    }
    function isNinja(address account) external view returns(bool) {
        return(_isNinja[account]);
    }
    function getOwner() external view returns(address) {
        return(_owner);
    }

    function setFeeTrader(uint256 feeTrader) external onlyOwner {
        _feeTrader = feeTrader;
    }
    function setFeeNinja(uint256 feeNinja) external onlyOwner {
        _feeNinja = feeNinja;
    }

    function addTrader() public payable {
        require(!_isTrader[msg.sender], "User is already a trader");
        require(msg.value >= _feeTrader, "ETH amount insufficient");
        _isTrader[msg.sender] = true;
    }
    function ownerAddTrader(address account) external onlyOwner {
        require(!_isTrader[account], "User is already a trader");
        _isTrader[account] = true;
    }

    function addNinja() public payable {
        require(!_isNinja[msg.sender], "User is already a ninja");
        require(msg.value >= _feeNinja, "ETH amount insufficient");
        if(!_isTrader[msg.sender]){
          _isTrader[msg.sender] = true;
        }
        _isNinja[msg.sender] = true;
    }
    function ownerAddNinja(address account) external onlyOwner {
        require(!_isNinja[account], "User is already a ninja");
        if(!_isTrader[account]){
          _isTrader[account] = true;
        }
        _isNinja[account] = true;
    }

    function transferOwner(address owner) external onlyOwner {
        _owner = owner;
    }

    function withdraw(uint256 amount, address receiver) external onlyOwner {
        payable(receiver).transfer(amount);
    }

    receive() external payable {
    }
}