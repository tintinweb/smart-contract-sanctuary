/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

pragma solidity =0.6.6;
/**
 * Four super nodes contracts of galaxy
 */
/**
 * Math operations with safety checks
 */
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

interface ERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external;
}


contract SuperNodes {
    using SafeMath for uint;

    ERC20 public bcoin;
    mapping(address => uint) public accountLevelMap;
    mapping(address => uint) public accountDateMap;
    mapping(address => uint) public accountWithdrawMap;

    uint[] public incomes = [0,50000 ether,100000 ether,200000 ether,1000000 ether];

    event BuyNode(address indexed addr, uint level);
    event Withdraw(address indexed to, uint256 value);

    constructor(address _bcoin)public {
        bcoin = ERC20(_bcoin);
    }

    function buyNode( uint level) public {
        require(level != 0, "!0 level");
        require(level < 5, "!level");
        require(accountLevelMap[msg.sender] == 0 );
        uint cost = incomes[level];
        uint allowed = bcoin.allowance(msg.sender,address(this));
        uint balanced = bcoin.balanceOf(msg.sender);
        require(allowed >= cost, "!allowed");
        require(balanced >= cost, "!balanced");
        bcoin.transferFrom( msg.sender,address(this), cost);

        accountLevelMap[msg.sender] = level;
        accountDateMap[msg.sender] = block.timestamp;

        emit BuyNode(msg.sender,level);
    }

    function withdraw(uint value) public {
        uint max = withdrawAble(msg.sender);
        require(value <= max);
        accountWithdrawMap[msg.sender] = accountWithdrawMap[msg.sender].add(value);
        bcoin.transfer( msg.sender, value);
        emit Withdraw(msg.sender, value);
    }

    function withdrawAble(address addr) public view returns (uint){
        uint round = getCurrentRound(addr);
        if(round == 0){
            return 0;
        }
        round = round -1;
        uint level = accountLevelMap[addr];
        uint income = incomes[level];
        uint released = income.div(10).mul(round);
        return released.sub(accountWithdrawMap[addr]);
    }

    // 获取当前所处的轮数
    function getCurrentRound(address addr) public view returns (uint){
        uint inDate = accountDateMap[addr];
        if(inDate == 0){
            return 0;
        }
        uint begin =  inDate + 90 days;
        if(begin >= block.timestamp){
            return 1;
        }
        for(uint i = 1;i<=10;i++){
            uint next = begin + (30 days)*i;
            if(next >= block.timestamp){
                return i+1;
            }
        }
        return 12;
    }

    function nextTime(address addr) public view returns (uint){
        uint inDate = accountDateMap[addr];
        if(inDate == 0){
            return 0;
        }
        uint begin =  inDate + 90 days;
        if(begin >= block.timestamp){
            return begin;
        }
        for(uint i = 1;i<=10;i++){
            uint next = begin + (30 days)*i;
            if(next >= block.timestamp){
                return next;
            }
        }
        return 0;
    }

}