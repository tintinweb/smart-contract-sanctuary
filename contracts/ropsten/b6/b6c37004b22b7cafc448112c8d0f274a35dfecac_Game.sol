pragma solidity ^0.4.18;

contract Game {
    mapping(address => uint) public balances;
    mapping(address => uint) public redeem_time;
    uint public total;
    event Buy(address indexed player, uint amount, uint total);
    event Redeem(address indexed player, uint amount, uint total);

    constructor() public {
        total = 0;
    }
    
    function buy() public payable {
        require(msg.value > 0);
        require(balances[msg.sender] == 0);
        require(redeem_time[msg.sender] == 0);
        balances[msg.sender] = msg.value;
        redeem_time[msg.sender] = now + 30 days;
        total += msg.value;
        Buy(msg.sender, msg.value, total);
    }
    
    function redeem() public {
        require(balances[msg.sender] > 0);
        require(redeem_time[msg.sender] > 0);
        require(now >= redeem_time[msg.sender]);
        uint award = balances[msg.sender] + balances[msg.sender]/10;
        require(total >= award);
        total -= award;
        balances[msg.sender] = 0;
        redeem_time[msg.sender] = 0;
        Redeem(msg.sender, award, total);
        msg.sender.transfer(award);
    }
}