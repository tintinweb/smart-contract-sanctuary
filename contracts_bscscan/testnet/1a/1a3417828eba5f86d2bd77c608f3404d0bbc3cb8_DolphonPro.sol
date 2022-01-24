/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

abstract contract Context {
    //this funcation is to create the owner 
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        //this funcation is to get the data of the owner 
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// this contract is inherited the context contract 
contract Ownable is Context {
    address private _owner;
    // this event is to give a msg in the log that the owner is changed 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        //this will call the funcation _msgsender from the contract context when deployed 
        address msgSender = _msgSender();
        // and than add it to the state variable
        _owner = msgSender;
        //this will show the deployer that the transfer is done 
        emit OwnershipTransferred(address(0), msgSender);
    }
        //this funcation will show the owner adress
    function owner() public view returns (address) {
        return _owner;
    }
    //accsess modifire is for the funcations that only the owner will exicute 
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    // ownership transfering   only owner can run this 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    // transfering the ownership
    function transferOwnership(address newOwner) public virtual onlyOwner {
        //error handeling 
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract LockToken is Ownable 
{

    address public poolAddress = address(0); //will be set after adding liquidity.
    
    function setPoolAddress(address _address) external onlyOwner
    {
        poolAddress = _address;
    }

    mapping(address => bool) private _whiteList;
    modifier open(address from, address to) 
    {
        //require(to != poolAddress || _whiteList[from] || _whiteList[to]);
        _;
    }

    constructor() 
    {
        _whiteList[msg.sender] = true;
    }

    function includeToWhiteList(address account, bool _enabled) external onlyOwner 
    {
            _whiteList[account] = _enabled;
    }

}

contract DolphonPro is LockToken {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100_000_000_000 * 10 ** 9;
    string public name = "Dolphin Pro2";
    string public symbol = "DOLPHIN2";
    uint public decimals = 9;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[owner()] = totalSupply;
    }

    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }

    function transfer(address to, uint value) public open(msg.sender, to) returns(bool) 
    {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public open(from, to) returns(bool) 
    {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

}