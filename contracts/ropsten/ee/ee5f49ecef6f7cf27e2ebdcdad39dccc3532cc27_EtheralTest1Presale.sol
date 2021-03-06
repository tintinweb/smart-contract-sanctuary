/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

pragma solidity 0.4.19;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address public owner;
    function Ownable() public {owner = msg.sender;}
    modifier onlyOwner() {require(msg.sender == owner);_;}
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

interface ERC20 {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external  view returns (uint256);
    function transfer(address to, uint value) external  returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
    function approve(address spender, uint value) external returns (bool success);
}

contract EtheralTest1Presale is Ownable {
    using SafeMath for uint256;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event ChangeRate(uint256 _value);
    event WithdrawToken(address indexed _from, address indexed _to, uint256 _value);
    mapping(address => uint256) balances;
    
    bool public closed;
    
    uint public rate = 1000; //1 ETH = 1000 ETHAL
    uint public startDate = now;
    uint public constant EthMin = 0.01 ether; //Minimum purchase
    uint public constant EthMax = 50 ether; //Maximum purchase

    function () public payable {
        uint amount;
        owner.transfer(msg.value);
        amount = msg.value * rate;
        balances[msg.sender] += amount;
        balances[address(this)] = balances[address(this)] - balances[msg.sender];
        require(now >= startDate);
        require(!closed);
        require(msg.value >= EthMin && msg.value <= EthMax);
        require(amount <= balances[address(this)]);
        Transfer(address(this), msg.sender, amount);
    }
    
    function TokenWithdraw(uint value) public  onlyOwner {
        balances[address(this)] = balances[address(this)].sub(value);
        balances[owner] = balances[owner].add(value);
        Transfer(address(this), owner, value);
    }
    
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }
    
    function changeRate(uint256 _rate) public {
        require(msg.sender == owner); rate = _rate;
        ChangeRate(rate);
    }
}