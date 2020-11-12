pragma solidity 0.6.9;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    // function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    //     require(b != 0, "SafeMath: modulo by zero");
    //     return a % b;
    // }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address own) internal {
        _owner = own;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}


interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function decimals() external view returns (uint8);
}

interface IUniswapV2Pair {
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function token0() external view returns (address);
  function token1() external view returns (address);
}

contract SDCPStaking is Ownable {

    using SafeMath for uint;

    address private immutable sdcpToken;
    address private immutable v2Pair;

    uint8 private immutable sdcpDec;

    uint constant BASE_EP = 5;

    uint constant DAY =  60 * 60 * 24;

    uint constant RATE = 1660000;  // 
    uint constant LEAST = 500;

    constructor(address sdcp , address v2) Ownable(msg.sender) public {
      sdcpToken = sdcp;
      sdcpDec = IERC20(sdcp).decimals();
      v2Pair = v2;
      require(IUniswapV2Pair(v2).token0() == sdcp || IUniswapV2Pair(v2).token1() == sdcp, "E/no sdcp");
    }

    struct Staking {
      uint128 amount;
      uint32 stakeTime;
      uint32 earnTime;
      uint64 stype;   
    }

    mapping(address => Staking) V2Stakings;

    mapping(uint => uint) dayPrices;

    mapping(uint => uint) public earnPercent;

    function myV2Staking() external view returns (uint128, uint32, uint32, uint64, uint) {
      return (V2Stakings[msg.sender].amount,
              V2Stakings[msg.sender].stakeTime,
              V2Stakings[msg.sender].earnTime,
              V2Stakings[msg.sender].stype,
              myV2Earn());
    }

    function stakingV2(uint amount, uint64 stype) external {
      require(V2Stakings[msg.sender].amount == 0, "E/aleady staking");
      require(stype <= 2, "E/type error");
      require(IERC20(v2Pair).transferFrom(msg.sender, address(this), amount), "E/transfer error");
      V2Stakings[msg.sender] = Staking(uint128(amount), uint32(now), uint32(now), stype);
    }

    function wdV2(uint amount) external {
      Staking memory s = V2Stakings[msg.sender];
      uint stakingToal = s.amount;
      uint stakingTime = s.stakeTime;

      require(stakingToal >= amount, "E/not enough");
      if(s.stype == 1) {
        require(now >= stakingTime + DAY, "E/locked"); 
      } else {
        require(now >= stakingTime + 30 * DAY, "E/12 locked"); 
      } 


      wdV2Earn() ;

      IERC20(v2Pair).transfer(msg.sender, amount);

      if(stakingToal - amount > 0) {
        V2Stakings[msg.sender] = Staking(uint128(stakingToal - amount), uint32(now), uint32(now), s.stype);
      } else {
        delete V2Stakings[msg.sender];
      }
    }

    function myV2Earn() internal view returns (uint) {
      Staking memory s = V2Stakings[msg.sender];
      if(s.amount == 0) {
        return 0;
      }

      uint endDay = getDay(now);
      uint startDay = getDay(s.earnTime);
      if(endDay > startDay) {
        uint earnDays = endDay - startDay;
        uint earnPs = earnDays * BASE_EP;

        while(endDay > startDay) {
          if(earnPercent[startDay] > 0) {
            earnPs += earnPercent[startDay];
          }
          startDay += 1;
        }

        uint earns = 0;
        if(earnPs > 0) {
          earns = uint(s.amount).mul(earnPs).mul(RATE).div(1000).div(10 ** (uint(18).sub(sdcpDec)));
        }
        if(s.stype == 2) {
          return earns * 2;
        } else {
          return earns;
        }
      } 
      return 0;
    }

    function wdV2Earn() public {
      uint earnsTotal = myV2Earn();

      IERC20(sdcpToken).transfer(msg.sender, earnsTotal);
      V2Stakings[msg.sender].earnTime = uint32(now);
    }


    // get 1 sdcp  =  x eth
    function fetchPrice() internal view returns (uint) {
      (uint reserve0, uint reserve1,) = IUniswapV2Pair(v2Pair).getReserves();
      require(reserve0 > 0 && reserve1 > 0, 'E/INSUFFICIENT_LIQUIDITY');
      uint oneSdcp = 10 ** uint(sdcpDec);  

      if(IUniswapV2Pair(v2Pair).token0() == sdcpToken) {
        return oneSdcp.mul(reserve1) / reserve0;
      } else {
        return oneSdcp.mul(reserve0) / reserve1;
      }
    }

    function getDay(uint ts) internal pure returns (uint) {   
      return ts / DAY;
    }

    function updatePrice() external {
      uint d = getDay(now);
      uint p = fetchPrice();

      dayPrices[d] = p;
      uint lastPrice = dayPrices[d-1];
      
      if(lastPrice > 0 && p > lastPrice) {
        
        uint ep = BASE_EP;
        uint t = (p - lastPrice) / (lastPrice / 10); 
        earnPercent[d] = ep * t;
      }
    }

    function withdrawSDCP(uint amount) external onlyOwner {
      IERC20(sdcpToken).transfer(msg.sender, amount);
    }

}