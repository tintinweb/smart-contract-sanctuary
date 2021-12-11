/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
contract Payment
    {
        address public creator; //Address of Creator1 is stored in this variable with type "address"
        uint ask_rate;
        
    constructor()
        {
            creator = 0xD537F936c98831f8E7a80461fbe13f468a549f13; //creator1's address is set to this address
            ask_rate = 10000000000000000;
        }
    //this function can be called only called from blexing's ID to withdraw revenue collected
    function withdraw() public
        {
            require(msg.sender == creator, "You are not calling from blexings address");
            payable(msg.sender).transfer(address(this).balance); //Revenue will be transfered to Blexing's Address
        }

    function change_ask_rate(uint new_ask_rate) public
        {
            require(msg.sender == creator, "You are not calling from blexings address");
            ask_rate= new_ask_rate;
        }
    //this function is called by only creator account to change it default address
    function change_creator(address new_creator_addr) public
            {
            require(msg.sender == creator, "You are not calling from blexings address");
            creator = new_creator_addr;
            }
    function mint_balance(uint ask) public payable returns(uint)
            {   
                require(msg.value >= ask*ask_rate, "You have transferred less than ask"); //Checks if ether send with the transaction is more than minting price
                return ask;
            }
}