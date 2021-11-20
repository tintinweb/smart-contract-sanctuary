/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: ADSL
pragma solidity 0.8.7;
contract Contract{

    struct User{
        string FIO;
        uint balance;
        string login;
    }

    mapping(string => address) public logins;
    mapping(address => User) public users;
    address payable root = payable(msg.sender);
    
    function create_user(string memory login, string memory FIO) public{
        require(logins[login] == address(0x00000000000000000000000000000000000000), "This login is already exist");
        require(bytes(users[msg.sender].FIO).length == 0, "This ETH address is already registered");
        logins[login] = msg.sender;
        users[msg.sender] = User(FIO, msg.sender.balance, login);
    }

    function get_balance(address user_address) public view returns(uint){
        return(users[user_address].balance);
    }

    function send_money(address payable adr_to) public payable{
        adr_to.transfer(msg.value);
    }
    
    struct Donation{
        uint donate_id;
        string name;
        address payable user;
        uint amount;
        uint deadline;
        address payable[] sender;
        uint[] value;
        bool status;
        string info;
    }

    Donation[] donation;

    function ask_to_donate(string memory name, uint amount, uint deadline, string memory info) public {
        address payable[] memory sender;
        uint[] memory value;
        donation.push(Donation(donation.length, name, payable(msg.sender), amount, deadline, sender, value, false, info));
    }
 
    function participate(uint donation_id) public payable{
        require(donation[donation_id].status == false);
        require(msg.value > 0);
        donation[donation_id].sender.push(payable(msg.sender));
        donation[donation_id].value.push(msg.value);
    }
 
    function get_donation(uint donation_id) public view returns(uint, string memory, address payable, uint, uint, bool){
        return(donation_id, donation[donation_id].name, donation[donation_id].user, donation[donation_id].amount, donation[donation_id].deadline, donation[donation_id].status);
    }
    function get_donation_2(uint donation_id) public view returns(address payable[] memory, uint[] memory, string memory) {
        return(donation[donation_id].sender, donation[donation_id].value, donation[donation_id].info);
    }
    
    function get_donation_number() public view returns(uint) {
        return donation.length;
    }
 
    function get_total(uint donation_id) public view returns(uint){
        uint total = 0;
        for (uint i = 0; i < donation[donation_id].value.length; i++) {
            total += donation[donation_id].value[i]; 
        }
        return total;
    } 
    
    function finish(uint donation_id) public{
        require(msg.sender != donation[donation_id].user);
        require(donation[donation_id].status == false);
        uint total = get_total(donation_id);
        if (total ** 2 >= donation[donation_id].amount){
            donation[donation_id].user.transfer(total);
        }
        else{
            for (uint i = 0; i < donation[donation_id].value.length; i++){
                donation[donation_id].sender[i+1].transfer(donation[donation_id].value[i]);
            }
        }
        donation[donation_id].user.transfer(total);
        donation[donation_id].status = true;
    }
}