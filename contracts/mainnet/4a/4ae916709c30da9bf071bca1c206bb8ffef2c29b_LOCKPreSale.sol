/**
 *Submitted for verification at Etherscan.io on 2020-09-06
*/

pragma solidity 0.7.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract LOCKPreSale  {
    using SafeMath for uint256;

    uint256 constant MIN_BUY = 1 * 10**18;
    uint256 constant MAX_BUY = 100 * 10**18;
    uint256 constant  PRICE = 116 * 10**13;
    uint256 public  HARD_CAP = 700 * 10**18 ;

    address payable  receiver ;
 
    uint256 public totalSold   = 0;
    uint256 public totalRaised = 0;

    event onBuy(address buyer , uint256 amount);

    mapping(address => uint256) public boughtOf;

    constructor() public {
      receiver = msg.sender;
    }

    function buyToken() public payable {
        require(msg.value >= MIN_BUY , "MINIMUM IS 1 ETH");
        require(msg.value <= MAX_BUY , "MAXIMUM IS 15 ETH");
        require(totalRaised + msg.value <= HARD_CAP , "HARD CAP REACHED");

        uint256 amount = (msg.value.div(PRICE)) * 10 ** 18;

        boughtOf[msg.sender] += amount;
        totalSold += amount;
        totalRaised += msg.value;
        
        receiver.transfer(msg.value);

        emit onBuy(msg.sender , amount);
    }

}