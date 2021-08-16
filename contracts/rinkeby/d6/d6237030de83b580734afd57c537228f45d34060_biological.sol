/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract biological {
    uint public time;
    function getDate() internal returns(uint){
        time = block.timestamp;
        return(time);
    }
    struct bird_data{
        string name;
        string descript;
        string photo;
        uint lon;
        uint lat;
        uint time;
        uint createtime;
    }
    struct Money_History{
        address from_addr;
        address to_addr;
        string from_name;
        string to_name;
        uint money;
        uint time;
    }
    // struct aquatic_organisms{
    //     string location;
    // }
    // struct water_quality{
    //     string location;
    // }
    // struct bottom_quality{
    //     string location;
    // }
    struct User{
        string name;
        uint money;
    }
    
    mapping (address => bool) public is_admin;
    mapping (address => bool) public is_user;
    mapping (address => User) public user;
    mapping (string => address) public name_to_user;
    mapping (address => Money_History[]) public money_history;
    bird_data[] bird_data_list;
    
    constructor(){
        is_admin[msg.sender] = true;
        address addr = 0xf04c6a55F0fdc0A5490d83Be69A7A675912A5AB3;
        is_admin[addr] = true;
    }
    modifier onlyAdmin() {
        require(is_admin[msg.sender], "Only admins can use this function!");
        _;
    }
    modifier onlyUser() {
        require(is_admin[msg.sender] || is_user[msg.sender], "Only user can use this function!");
        _;
    }
    
    function addAdmin(address addr) onlyAdmin()  public {
        is_admin[addr] = true;
    }
    
    function addUser(address addr, string memory name) onlyAdmin()  public {
        is_user[addr] = true;
        user[addr].name = name;
        user[addr].money = 0;
        name_to_user[name] = addr;
    }
    
    function destroy() onlyAdmin() public{
        selfdestruct(msg.sender);
    } 
    
    function query_money(string memory name) view public returns(uint){
        return user[name_to_user[name]].money;
    }
    
    function send_money(string memory name, uint money) onlyUser() public{
        require(user[msg.sender].money > money, "You do not have enough money");
        user[msg.sender].money -= money;
        user[name_to_user[name]].money += money;
        Money_History memory now_history;
        now_history.from_addr = msg.sender;
        now_history.from_name = user[msg.sender].name;
        now_history.to_addr = name_to_user[name];
        now_history.to_name = name;
        now_history.money = money;
        now_history.time = getDate();
        money_history[msg.sender].push(now_history);
        money_history[name_to_user[name]].push(now_history);
    }
    
    function set_money(string memory name, uint money) onlyAdmin() public {
        user[name_to_user[name]].money = money;
    }
    
    function query_money_history(string memory name) view public  returns(Money_History[] memory){
        return money_history[name_to_user[name]];
    }
    
    function bird_data_update(string memory name, string memory descript, string memory photo, uint lon, uint lat, uint createtime) onlyUser() public{
        bird_data memory Now;
        Now.name = name;
        Now.descript = descript;
        Now.photo = photo;
        Now.lon = lon;
        Now.lat = lat;
        Now.createtime = createtime;
        Now.time = getDate();
        bird_data_list.push(Now);
    }
    function bird_data_list_length() view public returns(uint){
        return bird_data_list.length;
    }
    function bird_data_list_all() view public returns(bird_data[] memory){
        return bird_data_list;
    }
    function get_bird_data_list(uint num) view public returns(bird_data memory){
        return bird_data_list[num];
    }
}