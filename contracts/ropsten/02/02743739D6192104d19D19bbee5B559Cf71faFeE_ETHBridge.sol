/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
interface  ERC20 {
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint _value) external returns (bool);
    function transferFrom(address _from, address _to, uint _value)  external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
}
contract ETHBridge {
    address private watcher;
    event ETHDeposit(address indexed to, uint value);
    event TokenDeposit(address indexed token, address indexed to, uint value);

    constructor (address _watcher){
        watcher = _watcher;
    }
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    /*ETH deposit to this contract
    @to the inside address
    msg.value the amount you want to deposit from ETH to this contract
    */
    function eth_deposit(address _to) public payable returns (bool) {
        require(!isContract(msg.sender) && msg.sender == tx.origin && msg.value > 0,"parameter error");
        uint msgValue = msg.value;
        emit ETHDeposit(_to, msgValue);
        return true;
    }
    /* ETH withdraw, only call by watcher
    @_to the withdraw address
    @value the withdraw amount of ETH
    */
    function eth_withdraw(address payable _to, uint256 _value) public returns (bool){
        require(msg.sender == watcher && _to != address(0),"parameter error");
        uint256 contractBalance = address(this).balance;
        require(_value > 0 && contractBalance >= _value,"balance not enough");
        _to.transfer(_value);
        return true;
    }
    /* ETH Token deposit to this contract
    @token the token address of ETH
    @to the inside address
    @value the deposit amount of Token
    */
    function token_deposit(address _token, address _to, uint _value) public returns (bool) {
        address to = address(this);
        //uint256 allowed = ERC20(_token).allowance(msg.sender,to);
        //require(_value > 0 && allowed >= _value,"allowance not enough");
       // uint256 balance = ERC20(_token).balanceOf(msg.sender);
       // require(balance >= _value,"balance not enough");
        ERC20(_token).transferFrom(msg.sender,to,_value);
        emit TokenDeposit(_token, _to, _value);
        return true;
    }
    /* ETH Token withdraw, only call by watcher
    @token the token address of ETH
    @to the withdraw address
    @value the withdraw amount of Token
    */
    function token_withdraw(address _token,address _to, uint _value) public returns (bool) {
        require(msg.sender == watcher && _to != address(0),"parameter error");
        uint256 balance = ERC20(_token).balanceOf(address(this));
        require(_value > 0 && balance >= _value,"balance not enough");
        ERC20(_token).transfer(_to,_value);
        return true;
    }

    function updateWatcher(address _watcher) public returns (bool){
        require(msg.sender == watcher && _watcher != address(0),"parameter error");
        watcher = _watcher;
        return true;
    }
}