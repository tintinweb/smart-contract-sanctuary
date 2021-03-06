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

    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

interface ERC20 {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external  view returns (uint256);
    function transfer(address to, uint value) external  returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
    function approve(address spender, uint value) external returns (bool success);
}

contract EtheralTest0Presale is Ownable {
    using SafeMath for uint256;
    
    uint256 public totalSold;
    uint256 public startDate = now;
    uint256 public constant ETHMin = 0.1 ether; //Minimum
    uint256 public constant ETHMax = 50 ether; //Maximum
    
    ERC20 public EtheralTest0;
    bool public closed;

    mapping(address => uint256) _contributions;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event ChangeRate(uint256 _value);

    
    uint256 rate = 1000; // 1 ETH = 1000
 
    function () external payable {
        uint256 amount; amount = msg.value * rate;
        require((now >= startDate) && (startDate > 0));
        require(!closed);
        require(EtheralTest0.balanceOf(address(this)) > 0);
        require(msg.value >= ETHMin && msg.value <= ETHMax);
        require(amount <= EtheralTest0.balanceOf(address(this)));
        totalSold = totalSold.add(amount);
        owner.transfer(msg.value);
        _contributions[msg.sender] = _contributions[msg.sender].add(amount);
        Transfer(address(this), msg.sender, amount);
    }
    
    function withdrawEtheralTest0() public onlyOwner {
        EtheralTest0.transfer(owner, EtheralTest0.balanceOf(address(this)));
    }
    
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }
    
    function changeRate(uint256 _rate) public {
        require(msg.sender == owner); rate = _rate;
        ChangeRate(rate);
    }
    //Function to query the supply of YFMS in the contract
    function availableEtheralTest0() public view returns(uint256) {
        return EtheralTest0.balanceOf(address(this));
    }

    function contributions(address from) public view returns(uint256) {
        return _contributions[address(from)];
    }
}