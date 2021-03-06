/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

pragma solidity 0.6.0;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
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

interface ERC20 {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external  view returns (uint256);
    function transfer(address to, uint value) external  returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
    function approve(address spender, uint value) external returns (bool success);
}

contract EtheralTestTokenSale {
    using SafeMath for uint256;
    uint256 public totalSold;
    ERC20 public EtheralTest0Token;
    address payable public owner;
    uint256 public collectedETH;
    uint256 public startDate = now;
  
    bool public closed;

    mapping(address => uint256) internal _contributions;
    mapping(address => uint256) internal _numberOfContributions;

    constructor(address _wallet) public {
        owner = msg.sender; EtheralTest0Token = ERC20(_wallet);
    }

    uint256 amount;
    uint256 rate = 1000;
 
    receive () external payable {
        require(now >= startDate);
        require(!closed);
        require(EtheralTest0Token.balanceOf(address(this)) > 0);
        require(msg.value >= 0.1 ether && msg.value <= 50 ether);
        require(amount <= EtheralTest0Token.balanceOf(address(this)));
        amount = msg.value * rate;
        totalSold = totalSold.add(amount);
        collectedETH = collectedETH.add(msg.value);
        EtheralTest0Token.transfer(msg.sender, amount);
        _contributions[msg.sender] = _contributions[msg.sender].add(amount);
        _numberOfContributions[msg.sender] = _numberOfContributions[msg.sender].add(1);
    }

    function contribute() external payable {
        require(now >= startDate);
        require(EtheralTest0Token.balanceOf(address(this)) > 0);
        require(msg.value >= 0.1 ether && msg.value <= 50 ether);
        require(amount <= EtheralTest0Token.balanceOf(address(this)));
        amount = msg.value * rate;
        totalSold = totalSold.add(amount);
        collectedETH = collectedETH.add(msg.value);
        EtheralTest0Token.transfer(msg.sender, amount);
        _contributions[msg.sender] = _contributions[msg.sender].add(amount);
        _numberOfContributions[msg.sender] = _numberOfContributions[msg.sender].add(1);
    }

    function numberOfContributions(address from) public view returns(uint256) {
        return _numberOfContributions[address(from)]; 
    }

    function contributions(address from) public view returns(uint256) {
        return _contributions[address(from)];
    }
  
    function withdrawETH() public {
        require(msg.sender == owner);
        uint256 withdrawAmount = collectedETH;
        collectedETH = 0;
        owner.transfer(withdrawAmount);
    }
  
    function withdrawEtheralTestToken() public {
        require(msg.sender == owner);
        EtheralTest0Token.transfer(owner, EtheralTest0Token.balanceOf(address(this)));
    }

    function startSale() public {
        require(msg.sender == owner && startDate == now);
        startDate = now;
    }
  
    function closeSale() public {
        require(msg.sender == owner); require(!closed);
        closed = true;
    }
  
  function availableEtheralTest0Token() public view returns(uint256) {
        return EtheralTest0Token.balanceOf(address(this));
  }
}