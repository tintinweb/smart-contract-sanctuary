pragma solidity ^0.4.24;
contract BeatProfitMembership{
    address owner= 0x6A3CACAbaA5958A0cA73bd3908445d81852F3A7E;
    uint256 [] priceOfPeriod = [10000000000000000, 30000000000000000,300000000000000000,2000000000000000000, 5000000000000000000];
    uint256 [] TimeInSec = [3600, 86400,2592000,31536000];
    
    mapping (address => uint256) public DueTime;
    mapping (address => bool) public Premium;

    constructor() public {
        DueTime[owner] = 4689878400;
        DueTime[0x491cFe3e5eF0C093971DaDdaBce7747EA69A991E] = 4689878400;
        DueTime[0x2ECc452E01f748183d697be4cb1db0531cc8F38F] = 4689878400;
        DueTime[0x353507473A89184e28E8F13e156Dc8055fD62A2C] = 4689878400;
        
        Premium[0x491cFe3e5eF0C093971DaDdaBce7747EA69A991E] = true;
        Premium[0x2ECc452E01f748183d697be4cb1db0531cc8F38F] = true;
        Premium[0x353507473A89184e28E8F13e156Dc8055fD62A2C] = true;
    }

    function extendMembership(uint256 _type) public payable{
    // Type:[0]:hour, [1]:day, [2]:month, [3]:year, [4]:premium
    
        require(msg.value >= priceOfPeriod[_type], "Payment Amount Wrong.");
        if(_type==4){
            // Premium Membership
            Premium[msg.sender] = true;
            DueTime[msg.sender] = 4689878400;
        }
        else if(DueTime[msg.sender]>now){
            DueTime[msg.sender] += mul(div(msg.value, priceOfPeriod[_type]), TimeInSec[_type]);
        }
        else{
            DueTime[msg.sender] = now + mul(div(msg.value, priceOfPeriod[_type]), TimeInSec[_type]);
        }
        
        owner.transfer(msg.value);
    }

    function setPrice(uint256 [] new_prices) public{
        require(msg.sender == owner, "Only Available to BeatProfit Core Team");
        priceOfPeriod[0] = new_prices[0];
        priceOfPeriod[1] = new_prices[1];
        priceOfPeriod[2] = new_prices[2];
        priceOfPeriod[3] = new_prices[3];
        priceOfPeriod[4] = new_prices[4];
    }

    function setMemberShip(address user, uint256 _timestamp) public {
        require(msg.sender==owner);
        DueTime[user]=_timestamp;
    }

  //   Safe Math Functions
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a); return a - b;}
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}