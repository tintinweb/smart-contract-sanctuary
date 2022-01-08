/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
contract PaymentContract{

    address public DespositAccount;
    address public Owner;
    uint public ask_rate ;
    address public Moderator1;
    address public Moderator2;
    address public Moderator3;
    address public Moderator4;
    
    event recieved_payment(uint value);

    constructor()
    {
        DespositAccount = 0x947aC0251131Bab36C71886DBB9a429db63eE79E;
        Owner = 0x9F9b67Fd872b435c1D9262736F3F4A36D601F1DB;
        Moderator1 = msg.sender;
        Moderator2 = 0x54C00F83B97B8be05A51f5b99b8A4Bc9460772Eb;
        Moderator3 = 0xb4FD3eC734435CD3DE2D874886ff4eF0bBfa40db;
        Moderator4 = 0xBb5426916000B28809AD6bFc9a0f8dB0cb723F0b;
        ask_rate = 500000000000000000;
    }

    modifier onlyOwner(){
        require(Owner==msg.sender,"You are not the owner");
        _;
    }
    modifier onlyModerator(){
        require(Moderator1==msg.sender || Moderator2==msg.sender || Moderator3==msg.sender || Moderator4==msg.sender || Owner == msg.sender,"You are not from listed moderators");
        _;
    }
    function change_ask_rate(uint new_ask_rate) public onlyModerator
        {
            ask_rate = new_ask_rate;
        }
    function change_moderator(uint ModeratorNo, address new_add) public onlyOwner{
            if(ModeratorNo == 1){
                Moderator1 = new_add;
            }
            else if(ModeratorNo == 2){
                Moderator2 == new_add;
            }
            else if(ModeratorNo == 3){
                Moderator3 == new_add;
            }
            else if(ModeratorNo == 4){
                Moderator4 == new_add;
            }
    }
    function withdraw() public onlyModerator{
        payable(DespositAccount).transfer(address(this).balance);
    }
    
    function mint_balance(uint ask) public payable 
            {   
                uint payment = ask*ask_rate;
                require(msg.value >= payment, "You have transferred less than ask"); //Checks if ether send with the transaction is more than minting price
                emit recieved_payment(payment);                                                      
            }
}