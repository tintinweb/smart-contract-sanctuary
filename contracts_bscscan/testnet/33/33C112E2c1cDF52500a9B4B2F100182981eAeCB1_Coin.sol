/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function burn(address addr_, uint amount_) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract Coin {
    address private minter;
    string private _symbol;
    uint public decimals = 18;
    mapping(address =>uint) public _balance;
    mapping(address => mapping(address => uint)) public _allBan;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor(){
        minter=msg.sender;
        _symbol ='KT';
    }
    function symbol() public view returns(string memory){
        return _symbol;
    }
    function balanceOf(address addr_)public view returns(uint ba){
        ba=_balance[addr_];
    }
    function mint(address receiver_, uint amount_) public returns(bool){
        require(msg.sender == minter,"00" );
        _balance[receiver_] += amount_;
        return true ;
    }
    function send(address receiver,uint amount) public{
        require(amount <=_balance[msg.sender],"Insufficient balance.");
        _balance[msg.sender] -=amount;
        _balance[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
    }
}