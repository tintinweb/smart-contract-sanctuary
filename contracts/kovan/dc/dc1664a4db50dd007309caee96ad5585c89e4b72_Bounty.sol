/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Verficiations {
  function addVerify(string memory twitterId) pure external;
}

interface ERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function symbol() external view  returns (string memory);
    
    function decimals() external view  returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

interface StorageVeficications {
     function addVerified(string memory name) external;
}

contract Bounty is  Ownable{
    
    ERC20 private _token;
    StorageVeficications private _storage;
    
    string public _name;
    bool private verified;
    uint256 public beginningTimer;
    uint256 public endingTimer;
    bytes32 private _asnwer;

    mapping(address => uint256) depositors;
    
    constructor(string memory name,uint16 day,ERC20 token,bytes32 answer,StorageVeficications stora){
        _name = name;
        _asnwer = answer;
        _token = token;
        _storage = stora;
        beginningTimer = block.timestamp;
        endingTimer = block.timestamp + day * 1 days;
    
    }
    
    function updateTimer(uint16 day) onlyOwner public{
        endingTimer = endingTimer + day * 1 days;
    }
    
    function confirmIdentity(string memory password) public{
          require(keccak256(abi.encodePacked(password)) == _asnwer,"wroge password");
          require(block.timestamp < endingTimer,"You lost the time to get boutu");
          require(verified != true,"Already been verified ");
          _token.transfer(msg.sender, totalRewards());
          verified = true;
          _storage.addVerified(_name);
          
    }
    
    function deposit (uint256 amount) public{
        require( _token.balanceOf(msg.sender) >= amount);
        require(block.timestamp < endingTimer,"I'ts possibel deposit after the endingTimer");
         _token.transferFrom(msg.sender, address(this), amount);
        depositors[msg.sender] += amount;
    }
    
    function withdraw() public{
        require(block.timestamp > endingTimer,"You need to wait boutyn end to withdraw");
        _token.transfer(msg.sender, depositors[msg.sender]);
        depositors[msg.sender] = 0;
    }
    
    function totalRewards() public view returns(uint256){
         return _token.balanceOf(address(this));
    }
    
    function isVerified() public view returns(bool){
        return verified;
    }
    
    function symbol() public view returns(string memory){
        return _token.symbol();
    }
    
    function decimals() public view returns(uint8){
        return _token.decimals();
    }
    
}