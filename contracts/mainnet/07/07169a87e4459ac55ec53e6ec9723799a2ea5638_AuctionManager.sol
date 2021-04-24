/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

pragma solidity 0.6.6;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IToken {

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function intervalLength() external returns (uint256);
  
  function owner() external view returns (address);
  
  function burn(uint256 _amount) external;
  
  function renounceMinter() external;
  
  function mint(address account, uint256 amount) external returns (bool);

  function lock(
    address recipient,
    uint256 amount,
    uint256 blocks,
    bool deposit
  ) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);
  
  function transfer(address to, uint256 amount) external returns (bool success);

}

interface IDutchAuction {
  function auctionEnded() external view returns (bool);

  function finaliseAuction() external;
}


interface IDutchSwapFactory {
  function deployDutchAuction(
    address _token,
    uint256 _tokenSupply,
    uint256 _startDate,
    uint256 _endDate,
    address _paymentCurrency,
    uint256 _startPrice,
    uint256 _minimumPrice,
    address _wallet
  ) external returns (address dutchAuction);
}

interface IPriceOracle {

  function consult(uint256 amountIn) external view returns (uint256 amountOut);

  function update() external;
}

contract AuctionManager {
  using SafeMath for uint256;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  // used as factor when dealing with %
  uint256 constant ACCURACY = 1e4;
  // when 95% at market price, start selling
  uint256 public sellThreshold;
  // cap auctions at certain amount of $TRDL minted
  uint256 public dilutionBound;
  // stop selling when volume small
  // uint256 public dustThreshold; set at dilutionBound / 52
  // % start_price above estimate, and % min_price below estimate
  uint256 public priceSpan;
  // auction duration
  uint256 public auctionDuration;

  IToken private strudel;
  IToken private vBtc;
  IToken private gStrudel;
  IPriceOracle private btcPriceOracle;
  IPriceOracle private vBtcPriceOracle;
  IPriceOracle private strudelPriceOracle;
  IDutchSwapFactory private auctionFactory;

  IDutchAuction public currentAuction;
  mapping(address => uint256) public lockTimeForAuction;

  constructor(
    address _strudelAddr,
    address _gStrudel,
    address _vBtcAddr,
    address _btcPriceOracle,
    address _vBtcPriceOracle,
    address _strudelPriceOracle,
    address _auctionFactory
  ) public {
    strudel = IToken(_strudelAddr);
    gStrudel = IToken(_gStrudel);
    vBtc = IToken(_vBtcAddr);
    btcPriceOracle = IPriceOracle(_btcPriceOracle);
    vBtcPriceOracle = IPriceOracle(_vBtcPriceOracle);
    strudelPriceOracle = IPriceOracle(_strudelPriceOracle);
    auctionFactory = IDutchSwapFactory(_auctionFactory);
    sellThreshold = 9500; // vBTC @ 95% of BTC price or above
    dilutionBound = 70; // 0.7% of $TRDL total supply
    priceSpan = 2500; // 25%
    auctionDuration = 84600; // ~23,5h
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function _getDiff(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a > b) {
      return a - b;
    }
    return b - a;
  }

  function decimals() public view returns (uint8) {
      return gStrudel.decimals();
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view returns (uint256) {
      return gStrudel.totalSupply();
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view returns (uint256) {
      return gStrudel.balanceOf(account);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(strudel.owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function updateOracles() public {
    try btcPriceOracle.update() {
      // do nothing
    } catch Error(string memory) {
      // do nothing
    } catch (bytes memory) {
      // do nothing
    }
    try vBtcPriceOracle.update() {
      // do nothing
    } catch Error(string memory) {
      // do nothing
    } catch (bytes memory) {
      // do nothing
    }
    try strudelPriceOracle.update() {
      // do nothing
    } catch Error(string memory) {
      // do nothing
    } catch (bytes memory) {
      // do nothing
    }
  }

  function rotateAuctions() external {
    if (address(currentAuction) != address(0)) {
      require(currentAuction.auctionEnded(), "previous auction hasn't ended");
      try currentAuction.finaliseAuction() {
        // do nothing
      } catch Error(string memory) {
        // do nothing
      } catch (bytes memory) {
        // do nothing
      }
      uint256 studelReserves = strudel.balanceOf(address(this));
      if (studelReserves > 0) {
        strudel.burn(studelReserves);
      }
    }

    updateOracles();

    // get prices
    uint256 btcPriceInEth = btcPriceOracle.consult(1e18);
    uint256 vBtcPriceInEth = vBtcPriceOracle.consult(1e18);
    uint256 strudelPriceInEth = strudelPriceOracle.consult(1e18);

    // measure outstanding supply
    uint256 vBtcOutstandingSupply = vBtc.totalSupply();
    uint256 strudelSupply = strudel.totalSupply();
    uint256 vBtcAmount = vBtc.balanceOf(address(this));
    vBtcOutstandingSupply -= vBtcAmount;

    // calculate vBTC supply imbalance in ETH
    uint256 imbalance = _getDiff(btcPriceInEth, vBtcPriceInEth).mul(vBtcOutstandingSupply);

    uint256 cap = strudelSupply.mul(dilutionBound).mul(strudelPriceInEth).div(ACCURACY);
    // cap by dillution bound
    imbalance = min(
      cap,
      imbalance
    );

    // pause if imbalance below dust threshold
    if (imbalance.div(strudelPriceInEth) < strudelSupply.mul(dilutionBound).div(52).div(ACCURACY)) {
      // pause auctions
      currentAuction = IDutchAuction(address(0));
      return;
    }

    // determine what kind of auction we want
    uint256 priceRelation = btcPriceInEth.mul(ACCURACY).div(vBtcPriceInEth);
    if (priceRelation < ACCURACY.mul(ACCURACY).div(sellThreshold)) {
      // cap vBtcAmount by imbalance in vBTC
      vBtcAmount = min(vBtcAmount, imbalance.div(vBtcPriceInEth));
      // calculate vBTC price
      imbalance = vBtcPriceInEth.mul(1e18).div(strudelPriceInEth);
      // auction off some vBTC
      vBtc.approve(address(auctionFactory), vBtcAmount);
      currentAuction = IDutchAuction(
        auctionFactory.deployDutchAuction(
          address(vBtc),
          vBtcAmount,
          now,
          now + auctionDuration,
          address(strudel),
          imbalance.mul(ACCURACY.add(priceSpan)).div(ACCURACY), // startPrice
          imbalance.mul(ACCURACY.sub(priceSpan)).div(ACCURACY), // minPrice
          address(this)
        )
      );
    } else {

      // calculate price in vBTC
      vBtcAmount = strudelPriceInEth.mul(1e18).div(vBtcPriceInEth);
      // auction off some $TRDL
      currentAuction = IDutchAuction(
        auctionFactory.deployDutchAuction(
          address(this),
          imbalance.div(strudelPriceInEth), // calculate imbalance in $TRDL
          now,
          now + auctionDuration,
          address(vBtc),
          vBtcAmount.mul(ACCURACY.add(priceSpan)).div(ACCURACY), // startPrice
          vBtcAmount.mul(ACCURACY.sub(priceSpan)).div(ACCURACY), // minPrice
          address(this)
        )
      );

      // if imbalance >= dillution bound, use max lock (52 weeks)
      // if imbalance < dillution bound, lock shorter
      lockTimeForAuction[address(currentAuction)] = gStrudel.intervalLength().mul(52).mul(imbalance).div(cap);
    }
  }

  function setSellThreshold(uint256 _threshold) external onlyOwner {
    require(_threshold >= 6000, "threshold below 60% minimum");
    require(_threshold <= 12000, "threshold above 120% maximum");
    sellThreshold = _threshold;
  }

  function setDulutionBound(uint256 _dilutionBound) external onlyOwner {
    require(_dilutionBound <= 1000, "dilution bound above 10% max value");
    dilutionBound = _dilutionBound;
  }

  function setPriceSpan(uint256 _priceSpan) external onlyOwner {
    require(_priceSpan > 1000, "price span should have at least 10%");
    require(_priceSpan < ACCURACY, "price span larger accuracy");
    priceSpan = _priceSpan;
  }

  function setAuctionDuration(uint256 _auctionDuration) external onlyOwner {
    require(_auctionDuration >= 3600, "auctions should run at laest for 1 hour");
    require(_auctionDuration <= 604800, "auction duration should be less than week");
    auctionDuration = _auctionDuration;
  }

  function renounceMinter() external onlyOwner {
    strudel.renounceMinter();
  }

  function swipe(address tokenAddr) external onlyOwner {
    IToken token = IToken(tokenAddr);
    token.transfer(strudel.owner(), token.balanceOf(address(this)));
  }

  // In deployDutchAuction, approve and transferFrom are called
  // In initDutchAuction, transferFrom is called again
  // In DutchAuction, transfer is called to either payout, or return money to AuctionManager

  function transferFrom(address, address, uint256) public pure returns (bool) {
    return true;
  }

  function approve(address, uint256) public pure returns (bool) {
    return true;
  }

  function transfer(address to, uint256 amount) public returns (bool success) {
    // require sender is our Auction
    address auction = msg.sender;
    require(lockTimeForAuction[auction] > 0, "Caller is not our auction");

    // if recipient is AuctionManager, it means we are doing a refund -> do nothing
    if (to == address(this)) return true;

    uint256 blocks = lockTimeForAuction[auction];
    strudel.mint(address(this), amount);
    strudel.approve(address(gStrudel), amount);
    gStrudel.lock(to, amount, blocks, false);
    return true;
  }
}