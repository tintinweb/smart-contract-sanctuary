/**
 *Submitted for verification at BscScan.com on 2021-12-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

contract FTO is Ownable{

    address private token;
    uint256 private min; // min BSC in wei
    uint256 private max; // max BSC in wei
    uint256 private amount; // Amount of token per 1 Gwei

    constructor(address _token,uint256 _min, uint256 _max, uint256 _amount) {
        token = _token;
        min = _min;
        max = _max;
        amount = _amount;
    }

    function getBalance() public view returns (uint256 _token, uint256 _bsc){
        IERC20 _erc20 = IERC20(token);
        uint256 token_balance = _erc20.balanceOf(address(this));
        uint256 bsc_balance = address(this).balance;
        return (token_balance, bsc_balance);
    }
    
    function withdraw(address _address) public onlyOwner returns (bool){
        IERC20 _erc20 = IERC20(token);
        uint256 token_balance = _erc20.balanceOf(address(this));
        _erc20.transfer(_address, token_balance);
        uint256 bsc_balance = address(this).balance;
        (bool sent, bytes memory data) = _address.call{value: bsc_balance}("");
        require(sent, "Failed to send BSC");
        return true;
    }

    function buy() payable public {
        IERC20 _erc20 = IERC20(token);
        uint256 amountTobuy = msg.value;
        require(amountTobuy > 0, "You need to send some ether");
        require(amountTobuy <= max, "Maximum limit");
        require(amountTobuy >= min, "Minimum limit");
        uint256 token_balance = _erc20.balanceOf(address(this));
        // uint256 wei_to_gwei = amountTobuy / 1000000000;
        uint256 token_amount = amountTobuy * amount;
        require(token_amount <= token_balance, "Not enough tokens in the contract");
        require(token_amount > 0, "invalid transaction");
        _erc20.transfer(msg.sender, token_amount);
    }


    function setX(address _token,uint256 _min, uint256 _max, uint256 _amount) onlyOwner public {
        token = _token;
        min = _min;
        max = _max;
        amount = _amount;
    }

    function getX() public view returns(address _token, uint256 _min, uint256 _max, uint256 _amount){
        return (token,min,max,amount);
    }

}