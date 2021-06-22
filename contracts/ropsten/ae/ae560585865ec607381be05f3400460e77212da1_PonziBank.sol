/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract PonziBank{
    
    event event_add_principal(address Players,uint256 Value);
    event event_withdraw(address Players, uint256 withdraw);
    event event_receive(address Donor,uint256 Value);
    
    string  public game_name;
    address payable  game_owner_address;

    struct Players{
        address payable players_address;
        uint256 principal;
        uint256 update_time;
    }
    
    constructor(string memory name){
        game_name = name;
        game_owner_address = payable(msg.sender);
    }
    
    modifier IsOwner(){
        require(payable(msg.sender) == game_owner_address, "You are not the owner!");
        _;
    }
    
    mapping(address=>Players) address_players;
    
    function Add_Principal (uint256 value) public returns(uint256){
        require(value > 0 , "Principal not enough");
        Withdraw_Interest();
        address_players[payable(msg.sender)].principal += value;
        emit event_add_principal(msg.sender,value);
        address_players[payable(msg.sender)].update_time = block.timestamp;
        return value;
    }

    function saved_days()public view returns(uint256){
        uint256 day = (block.timestamp-address_players[payable(msg.sender)].update_time) / 86400;
        return day;
    }

    function Withdraw_Interest() public returns(uint256) {
        if (block.timestamp  >= address_players[payable(msg.sender)].update_time + 1 days){
            uint256 money = address_players[payable(msg.sender)].principal;
            uint256 day = (block.timestamp-address_players[payable(msg.sender)].update_time) / 86400;
            money = money + money * day /10;
            address_players[payable(msg.sender)].principal = money;
            address_players[payable(msg.sender)].update_time = block.timestamp;
            return address_players[payable(msg.sender)].principal;
        }
        return address_players[payable(msg.sender)].principal;
    }
    
    
    function Check_MyBalance() external view returns(uint256) {
        Players memory s = address_players[msg.sender];
        return s.principal;
    }
    
    function Withdraw_Principal() external returns(uint256){
        address payable user = payable(msg.sender);
        Withdraw_Interest();
        uint balance = address_players[user].principal;
        require(balance > 0 , "Balance not enough");
        user.transfer(balance);
        address_players[user].principal = 0;
        emit event_withdraw(msg.sender,balance);
        address_players[payable(msg.sender)].update_time = block.timestamp;
        return balance;
    }
    
    
    fallback() external payable{
        
    }
    
    receive() external payable{
        emit event_receive(msg.sender,msg.value);
    }
    
    function Destroy() external IsOwner{
        selfdestruct(game_owner_address);
    }
}