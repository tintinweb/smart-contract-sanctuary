//SourceUnit: ITRC20.sol

pragma solidity ^0.5.10;

/**
 * @title TRC20 interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    function decimals() external view returns (uint8);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//SourceUnit: PreSaleMatch.sol

pragma solidity ^0.5.10;

import "./SafeMath.sol";
import "./ITRC20.sol";



contract Owner {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    
}


contract PreSaleMatch is Owner{

  using SafeMath for uint256;

  

  address payable  public providerAddress ; 
  uint256 public startTime = 1608433200;

  //mapping (address => uint256) public users; 

  uint256 public endTime = 1609642800;

  uint256 public totalBought = 0;
  uint256 constant public MATCH_PRICE= 5 trx;
  uint256 constant public MIN_INVEST = 500 trx; 

  address payable private ownerPrivate;
  mapping (address => uint256) internal bought;

  event Bought(address indexed user, uint256 trxAmount, uint256 matchAmount);
  
  ITRC20 private trc20;
  address matchContract = address(0x41e8558dd6776df8f635fc0b566b1c3074a2d07a25);

  constructor(address payable _providerAddress) public {
    require(!isContract(_providerAddress));

    providerAddress = _providerAddress;
    trc20 = ITRC20(matchContract);
  }

  function isStarted() view public returns (bool){
    return block.timestamp >= startTime && block.timestamp <= endTime;
  }
  function buy() payable public returns(uint256) {
    require(isStarted(),"You can only buy MATCH token during pre sale event");
    require(msg.value >= MIN_INVEST,"Min Invest 500TRX"); 
    uint256 _match = msg.value * (10 ** uint256(trc20.decimals()));
      _match = _match.div(MATCH_PRICE);
    require(trc20.balanceOf(address(this)) >= _match,"Insufficient Supply Token");
    providerAddress.transfer(msg.value);
    trc20.transfer(msg.sender,_match);

    totalBought+=_match;
    emit Bought(msg.sender,msg.value,_match );

    return _match;
  }
 

  function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
  }

  function flush() public onlyOwner {
      require(block.timestamp>=endTime,"This can only be executed after pre sale");
        uint bal = address(this).balance;
        trc20.transfer(providerAddress,trc20.balanceOf(address(this)));
        msg.sender.transfer(bal);
  }

}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;

library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

}