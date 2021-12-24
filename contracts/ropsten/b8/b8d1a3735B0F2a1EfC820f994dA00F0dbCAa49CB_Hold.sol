/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.0;

interface INRTInterface{
    function balanceOf(address) view external returns (uint);
    function transfer(address to, uint tokens) external returns (bool);
    function transferFrom(address from, address to, uint tokens) external returns (bool);
    function allowance(address tokenOwner, address spender) external view returns (uint);
}

contract Hold {
    /*struct Info{
        uint amount;
        uint depositedOn;
    }*/
    address admin;
    INRTInterface token = INRTInterface(0xa6436EeC87f690Be1668AF91C535C1e2F7E43B76);
    mapping(address => uint) public heldAmount;
    uint public maturity;
    /*mapping(address => Info) public holdersInfo;
    address[] holders;
    function getHoldersInfo() external returns (){
        return holdersInfo;
    }*/
    constructor(){
        admin = msg.sender;
        maturity = block.timestamp + 60;
    }
    function isMatured() public view returns (bool){
        return block.timestamp>=maturity;
    
    }
    function deposit(uint _tokens) external payable returns (bool){
        require(token.allowance(msg.sender,address(this))>=_tokens);
        heldAmount[msg.sender] = _tokens;
        return token.transferFrom(msg.sender,address(this),_tokens);
    }
    function withdraw() external returns (bool) {
        require(heldAmount[msg.sender]>0, 'Insufficient balance');
        require(block.timestamp>=maturity,'Too early to withdraw');
        bool status = token.transfer(msg.sender,heldAmount[msg.sender]);
        heldAmount[msg.sender] = 0;
        return status;
    }
    modifier onlyAdmin(){
        require(msg.sender==admin,'Admins only');
        _;
    }
    function updateMaturity(uint _seconds) onlyAdmin external{
        maturity = block.timestamp + _seconds;
    }
    function getBalance(address _a) view external returns (uint){
        return token.balanceOf(_a);
    }    
    fallback() external {
        revert();
    }
    receive() external payable{
        heldAmount[msg.sender] = msg.value;
        // holdersInfo[msg.sender] = Info(msg.value,block.timestamp);
        // holders.push(msg.sender);
    }
}