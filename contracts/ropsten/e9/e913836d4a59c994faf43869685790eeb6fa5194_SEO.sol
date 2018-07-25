pragma solidity ^0.4.21;

contract SEO{
    uint price;
    uint stop_time;
    uint balance;
    uint total_tickets;
    uint time=1 days;
    address winner;
    address owner=msg.sender;
    bool owner_flag=false;
    mapping(address=>uint) own_tickets;
    mapping(address=>bool) deposite_status;
    modifier game_over(){
        require(now>stop_time);
        _;
    }
    function SEO() public{
        price=0.1 ether;
        stop_time=now+time;
    }
    function buy() public payable{
        require(msg.value>=price);
        require(now<stop_time);
        own_tickets[msg.sender]++;
        balance+=msg.value;
        winner=msg.sender;
        stop_time=now+time;
        price+=0.1 ether;
        total_tickets++;
    }
    function deposite() public payable game_over(){
        require(!deposite_status[msg.sender]==true);
        uint tmp_value;
        if(msg.sender==winner){
            tmp_value=price-0.1 ether+(balance-price+0.1 ether)/20;
        }
        tmp_value+=(balance-(balance-price+0.1 ether)/10-price+0.1 ether)/total_tickets*own_tickets[msg.sender];
        msg.sender.transfer(tmp_value);
        deposite_status[msg.sender]=true;
    }
    function owner_withdraw() public payable game_over(){
        require(owner_flag==false);
        owner.transfer((balance-price+0.1 ether)/20);
        owner_flag=true;
    }
    function get_price() public view returns (uint){
        return price;
    }
    function get_time() public view returns (uint){
        return stop_time;
    }
    function get_balance() public view returns(uint){
        return balance;
    }
}