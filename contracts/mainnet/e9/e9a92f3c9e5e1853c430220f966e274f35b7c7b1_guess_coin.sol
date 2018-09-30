pragma solidity ^0.4.23;

contract guess_coin{
    super_rand public rand_addr;
    uint256 win;
    address public owner;
    
    constructor(address _addr) public {
        rand_addr = super_rand(_addr);
        win = 200;
        owner = msg.sender;
    }
    
    //if rand%2 == true pay 2*value
    function() public payable {
        if( rand_addr.s_rand( msg.sender, msg.value) ){
            msg.sender.transfer(msg.value * win/100);
        }
    }
    function set_rand_addr(address _addr, uint256 _win) public {
        require( msg.sender == owner);
        rand_addr = super_rand(_addr);
        win = _win;
    }
    function get_eth() public {
        require( msg.sender == owner);
        owner.transfer(address(this).balance);
    }
}

contract super_rand{
    function s_rand( address p_addr, uint256 _thisbalance) public returns( bool);
}