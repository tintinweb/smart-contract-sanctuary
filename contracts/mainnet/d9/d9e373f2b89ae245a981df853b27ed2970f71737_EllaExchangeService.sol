// File: contracts\SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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

// File: contracts\IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external  returns (bool);
    
    function burnFrom(address account, uint256 amount) external;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
}

// File: contracts\SafeDecimalMath.sol

pragma solidity >= 0.4.0 < 0.7.0;

// Libraries



// https://docs.synthetix.io/contracts/SafeDecimalMath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

// File: contracts\IEllaExchange.sol

pragma solidity >= 0.4.0 < 0.7.0;


// Libraries


/*
 * @author Ella Finance
 * @website https://ella.finance
 * @email support@ella.finance
 * Date: 18 Sept 2020
 */

interface IEllaExchange {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    event Saved(uint _amount, bool _isMarket, address _contract,  uint _time, address _owner, uint _duration);
    event Withdrew(uint _amount, address _owner, address _to, address _contract, bool _isMarket, uint _time);
    event Bought(uint _price, uint _amount, uint _value, address _market, bool isMarket, uint time);
        event Rewarded(
        address provider, 
        uint share, 
        bool _isMarket, 
        uint time
        );
    event PriceFeedChange(address _newAddress, address _exchange);
    function save(uint _amount, bool _isMarket, uint _duration) external;
    function save1(bool _isMarket, uint _duration) payable external;
     
    function withdraw(uint _amount,  address _to, bool _isMarket) external;
    function withdraw1(address payable _to, uint _amount, bool _isMarket) external;
     
    function accountBalance(address _owner) external view returns (uint _market, uint _token, uint _ethers);
     
    
    function swap(uint _amount) external;
    function swapBase(uint _amount) external;
    function swapBase2(uint _amount) external;
    function swap1(uint _amount) external;
    function swapBase1() payable external;
    function swap2() payable external;
    
}

// File: contracts\IPriceConsumer.sol

pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: contracts\TradingFees.sol

pragma solidity >=0.6.0;
interface FEES {
      function getFees() external view returns (uint);
      function getSystemCut() external view returns (uint);
      function getFeesAddress() external view returns (address payable);
}

// File: contracts\EllaExchange.sol

pragma solidity >= 0.4.0 < 0.7.0;




/*
 * @author Ella Finance
 * @website https://ella.finance
 * @email support@ella.finance
 * Date: 18 Sept 2020
 */

contract EllaExchange is IEllaExchange {
   IERC20 MarketAddress;
   IERC20 TokenAddress;
   FEES  TradingFees;
   bool private isEthereum;
   mapping (bool => mapping(address => bool)) alreadyAProvider;
    struct Providers{
      address payable provider;
    }
    
   Providers[] providers;
   mapping(bool => Providers[]) listOfProviders;
   
   mapping(bool => mapping(address => uint)) savings;
   mapping(address => uint) etherSavings;
   mapping(bool => uint) pool;
   uint etherpool;
   address secretary;
   uint baseFees_generated;
   uint fees_generated;
   
   mapping(address => mapping(bool => uint)) userWithdrawalDate;
   mapping(address => mapping(bool => uint)) withdrawalDate;
   AggregatorV3Interface internal priceFeed;
    constructor(address _marketAddress, address _tokenAddress, bool _isEthereum,  address _priceAddress, address _fees) public {
     MarketAddress = IERC20(_marketAddress);  
     TokenAddress  = IERC20(_tokenAddress);
     TradingFees = FEES(_fees);
     isEthereum = _isEthereum;
     priceFeed = AggregatorV3Interface(_priceAddress);
     secretary = msg.sender;
    }

    function description() external view returns (string memory){
    return priceFeed.description();
    }
    
    function decimals() external view returns (uint8){
     return priceFeed.decimals();
    }
    
  
  function version() external view returns (uint256){
    return priceFeed.version();
  }
  
  function tokenPrice() public view returns(uint){
        (
        uint80 roundId, 
        int256 answer, 
        uint256 startedAt, 
        uint256 updatedAt, 
        uint80 answeredInRound
      ) = priceFeed.latestRoundData();
     uint multiplier = 10**uint(SafeMath.sub(18, priceFeed.decimals()));
     uint _price = uint(uint(answer).mul(multiplier));
     return _price;
  }
  
     /**
     * Restrict access to Secretary role
     */
    modifier onlySecretary() {
        require(secretary == msg.sender, "Address is not Secretary of this exchange!");
        _;
    }
    
    
    function changePriceFeedAddress(address _new_address) public onlySecretary {
       priceFeed = AggregatorV3Interface(_new_address);
       
       emit PriceFeedChange(_new_address, address(this));
    }
    
    
    function save(uint _amount, bool _isMarket, uint _duration) public override{
        require(_amount > 0, "Invalid amount");
        require(_duration > 0, "Invalid duration");
        require(setDuration(_duration, _isMarket) > 0, "Invalid duration");
        IERC20 iERC20 = (_isMarket ? MarketAddress : TokenAddress);
        require(iERC20.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance!");
        iERC20.transferFrom(msg.sender, address(this), _amount);
        savings[_isMarket][msg.sender] = savings[_isMarket][msg.sender].add(_amount);
        pool[_isMarket] = pool[_isMarket].add(_amount);
          if(alreadyAProvider[_isMarket][msg.sender] == false){
              alreadyAProvider[_isMarket][msg.sender] = true;
                listOfProviders[_isMarket].push(Providers(msg.sender));
            }
        emit Saved(_amount, _isMarket, address(this), now, msg.sender, setDuration(_duration, _isMarket));
    }
    
    function withdraw(uint _percentage, address _to, bool _isMarket) public override{
        require(_percentage > 0, "Invalid amount");
        require(isDue(_isMarket, msg.sender), "Lock period is not over yet!");
        IERC20 iERC20 = (_isMarket ? MarketAddress : TokenAddress);
        uint _withdrawable = withdrawable(_percentage, msg.sender, _isMarket, false);
        uint _deduct = _percentage.multiplyDecimalRound(savings[_isMarket][msg.sender]);
        savings[_isMarket][msg.sender] = _deduct >= savings[_isMarket][msg.sender] ? 0 : savings[_isMarket][msg.sender].sub(_deduct);
        pool[_isMarket] = _withdrawable >= pool[_isMarket] ? 0 : pool[_isMarket].sub(_withdrawable);
        require(iERC20.transfer(_to, _withdrawable), "Withdrawal faild");
        emit Withdrew(_withdrawable,msg.sender, _to, address(this),_isMarket, now);
    }
    
    function withdrawable(uint _percentage, address _user, bool _isMarket, bool _isForEther) public view returns(uint){
        uint pool_balance = _isForEther ? etherpool : pool[_isMarket];
        uint contract_balance = _isForEther ? address(this).balance : (_isMarket ? MarketAddress.balanceOf(address(this)) : TokenAddress.balanceOf(address(this)));
        uint get_user_pool_share = _isForEther ? etherSavings[_user].divideDecimalRound(pool_balance) : savings[_isMarket][_user].divideDecimalRound(pool_balance);
        uint user_due = get_user_pool_share.multiplyDecimalRound(contract_balance);
        uint _widthdrawable = _percentage.multiplyDecimalRound(user_due);
        
        return _widthdrawable;
    }
    
    function save1(bool _isMarket, uint _duration) payable public override{
        require(msg.value > 0, "Invalid amount");
        require(_duration > 0, "Invalid duration");
        require(setDuration(_duration, _isMarket) > 0, "Invalid duration");
        require(isEthereum, "Can't save Ethereum in this contract");
        etherSavings[msg.sender] = etherSavings[msg.sender].add(msg.value);
        etherpool = etherpool.add(msg.value);
         if(alreadyAProvider[_isMarket][msg.sender] == false){
              alreadyAProvider[_isMarket][msg.sender] = true;
                listOfProviders[_isMarket].push(Providers(msg.sender));
            }
        emit Saved(msg.value, _isMarket, address(this), now, msg.sender, setDuration(_duration, _isMarket));
    }
    
    function withdraw1(address payable _to, uint _percentage, bool _isMarket) public override{
        require(_percentage > 0, "Invalid amount");
        require(isDue(_isMarket, msg.sender), "Lock period is not over yet!");
        uint _withdrawable = withdrawable(_percentage, msg.sender, _isMarket, true);
        _to.transfer(_withdrawable);
        uint _deduct = _percentage.multiplyDecimalRound(etherSavings[msg.sender]);
        etherSavings[msg.sender] = _deduct >= etherSavings[msg.sender] ? 0 : etherSavings[msg.sender].sub(_deduct);
        etherpool = _withdrawable >= etherpool ? 0 : etherpool.sub(_withdrawable);
        emit Withdrew(_withdrawable,msg.sender, _to, address(this), _isMarket, now);
    }
    
    function accountBalance(address _owner) public override view returns (uint _market, uint _token, uint _ethers){
        return(savings[true][_owner], savings[false][_owner], etherSavings[_owner]);
    }
    
    
    
    function swapBase(uint _amount) public override{
        require(!isEthereum, "Can't transact!");
        require(_amount > 0, "Zero value provided!");
        require(MarketAddress.allowance(msg.sender, address(this)) >= _amount, "Non-sufficient funds");
        require(MarketAddress.transferFrom(msg.sender, address(this), _amount), "Fail to tranfer fund");
        uint _price = tokenPrice();
        uint _amountDue = _amount.divideDecimal(_price);
        uint _finalAmount = _amountDue.multiplyDecimal(10 ** 18);
        require(TokenAddress.balanceOf(address(this)) >= _finalAmount, "No fund to execute the trade");
        uint fee = TradingFees.getFees().multiplyDecimal(_finalAmount);
        uint systemCut = TradingFees.getSystemCut().multiplyDecimal(fee);
        fees_generated = fees_generated.add(fee.sub(systemCut));
        require(TokenAddress.transfer(msg.sender, _finalAmount.sub(fee)), "Fail to tranfer fund");
        require(TokenAddress.transfer(TradingFees.getFeesAddress(), systemCut), "Fail to tranfer fund");
      
        emit Bought(_price, _finalAmount, _amount, address(this), true, now);
       
    }
    
    function swapBase2(uint _amount) public override{
        require(isEthereum, "Can not transact!");
        require(_amount > 0, "Zero value provided!");
        require(MarketAddress.allowance(msg.sender, address(this)) >= _amount, "Non-sufficient funds");
        require(MarketAddress.transferFrom(msg.sender, address(this), _amount), "Fail to tranfer fund");
        address payable _reciever = msg.sender;
        address payable _reciever2 = TradingFees.getFeesAddress();
        uint _price = tokenPrice();
        uint _amountDue = _amount.divideDecimal(_price);
        uint _finalAmount = _amountDue.multiplyDecimal(10 ** 18);
        
        require(address(this).balance >= _finalAmount, "No fund to execute the trade");
        uint fee = TradingFees.getFees().multiplyDecimal(_finalAmount);
        uint systemCut = TradingFees.getSystemCut().multiplyDecimal(fee);
        fees_generated = fees_generated.add(fee.sub(systemCut));
        
        _reciever.transfer(_finalAmount.sub(fee));
        _reciever2.transfer(systemCut);
        emit Bought(_price, _finalAmount, _amount, address(this), true, now);
       
    }
    
    
     // swap base(eth) for token
     function swapBase1() payable public override{
        require(isEthereum, "Can't transact!");
        require(msg.value > 0, "Zero value provided!");
        uint _price = tokenPrice();
        uint _amount = msg.value;
        uint _amountDue = _amount.divideDecimal(_price);
        uint _finalAmount = _amountDue.multiplyDecimal(10 ** 18);
        require(TokenAddress.balanceOf(address(this)) >= _finalAmount, "No fund to execute the trade");
        uint fee = TradingFees.getFees().multiplyDecimal(_finalAmount);
        uint systemCut = TradingFees.getSystemCut().multiplyDecimal(fee);
        fees_generated = fees_generated.add(fee.sub(systemCut));
        require(TokenAddress.transfer(msg.sender, _finalAmount.sub(fee)), "Fail to tranfer fund");
        require(TokenAddress.transfer(TradingFees.getFeesAddress(), systemCut), "Fail to tranfer fund");
        emit Bought(_price, _finalAmount, _amount, address(this), true, now);
        
    }
    
    // (swap your token to base)
    function swap(uint _amount) public override{
        require(!isEthereum, "Can't transact!");
        require(_amount > 0, "Zero value provided!");
        require(TokenAddress.allowance(msg.sender, address(this)) >= _amount, "Non-sufficient funds");
        require(TokenAddress.transferFrom(msg.sender, address(this), _amount), "Fail to tranfer fund");
        uint _price = tokenPrice();
        uint _amountDue = _amount.multiplyDecimal(_price);
        uint _finalAmount = _amountDue.divideDecimal(10 ** 18);
        require(MarketAddress.balanceOf(address(this)) >= _finalAmount, "No fund to execute the trade");
        uint fee = TradingFees.getFees().multiplyDecimal(_finalAmount);
        uint systemCut = TradingFees.getSystemCut().multiplyDecimal(fee);
        baseFees_generated = baseFees_generated.add(fee.sub(systemCut));
        require(MarketAddress.transfer(msg.sender, _finalAmount.sub(fee)), "Fail to tranfer fund");
        require(MarketAddress.transfer(TradingFees.getFeesAddress(), systemCut), "Fail to tranfer fund");
        emit Bought(_price, _finalAmount, _amount, address(this), false, now);
    }
    
    //only call if eth is the base (swap your token to base)
    function swap1(uint _amount) public override{
        require(isEthereum, "Can't transact!");
        require(_amount > 0, "Zero value");
        require(TokenAddress.allowance(msg.sender, address(this)) >= _amount, "Non-sufficient funds");
        require(TokenAddress.transferFrom(msg.sender, address(this), _amount), "Fail to tranfer fund");
        address payable _reciever = msg.sender;
        address payable _reciever2 = TradingFees.getFeesAddress();
        uint _price = tokenPrice();
        uint _amountDue = _price.multiplyDecimal(_amount);
        uint _finalAmount = _amountDue.divideDecimal(10 ** 18);
        require(address(this).balance >= _finalAmount, "No fund to execute the trade");
        uint fee = TradingFees.getFees().multiplyDecimal(_finalAmount);
         uint systemCut = TradingFees.getSystemCut().multiplyDecimal(fee);
        baseFees_generated = baseFees_generated.add(fee.sub(systemCut));
        _reciever.transfer(_finalAmount.sub(fee));
        _reciever2.transfer(systemCut);
        emit Bought(_price, _finalAmount, _amount, address(this), false, now);
    }
    
      // When eth is the token
      function swap2() payable public override{
        require(isEthereum, "Can't transact!");
        require(msg.value > 0, "Zero value provided!");
        uint _price = tokenPrice();
        uint _amount = msg.value;
        uint _amountDue = _price.multiplyDecimal(_amount);
        uint _finalAmount = _amountDue.divideDecimal(10 ** 18);
        require(MarketAddress.balanceOf(address(this)) >= _finalAmount, "No fund to execute the trade");
        uint fee = TradingFees.getFees().multiplyDecimal(_finalAmount);
        uint systemCut = TradingFees.getSystemCut().multiplyDecimal(fee);
        baseFees_generated = baseFees_generated.add(fee.sub(systemCut));
        require(MarketAddress.transfer(msg.sender, _finalAmount.sub(fee)), "Fail to tranfer fund");
        require(MarketAddress.transfer(TradingFees.getFeesAddress(), systemCut), "Fail to tranfer fund");
        emit Bought(_price, _finalAmount, _amount, address(this), false, now);
      }
      
      function setDuration(uint _duration, bool _isbase) internal returns(uint){
          userWithdrawalDate[msg.sender][_isbase] == 0 ?  userWithdrawalDate[msg.sender][_isbase] = _duration : userWithdrawalDate[msg.sender][_isbase];
          if(_duration == 30){
              withdrawalDate[msg.sender][_isbase] = block.timestamp.add(30 days);
              return block.timestamp.add(30 days);
          }else if(_duration == 60){
              withdrawalDate[msg.sender][_isbase] = block.timestamp.add(60 days);
              return block.timestamp.add(60 days);
          }else if(_duration == 90){
              withdrawalDate[msg.sender][_isbase] = block.timestamp.add(90 days);
              return block.timestamp.add(90 days);
          }else if(_duration == 365){
              withdrawalDate[msg.sender][_isbase] = block.timestamp.add(365 days);
              return block.timestamp.add(365 days);
          }else if(_duration == 140000){
              withdrawalDate[msg.sender][_isbase] = block.timestamp.add(140000 days);
              return block.timestamp.add(140000 days);
          }else{
             return 0;
          }
      }
    function isDue(bool _isbase, address _user) public view returns (bool) {
        if (block.timestamp >= withdrawalDate[_user][_isbase])
            return true;
        else
            return false;
    }

    function shareFees(bool _isEth, bool _isMarket) public {
           uint feesShared;
           for (uint256 i = 0; i < listOfProviders[_isMarket].length; i++) {
            address payable _provider = listOfProviders[_isMarket][i].provider;
            uint userSavings =  _isEth ? etherSavings[_provider] : savings[_isMarket][_provider];
            uint _pool = _isEth ? etherpool : pool[_isMarket];
            uint total_fees_generated = _isMarket ? baseFees_generated : fees_generated;
            uint share = userSavings.divideDecimal(_pool);
            uint due = share.multiplyDecimal(total_fees_generated);
            feesShared = feesShared.add(due);
            require(total_fees_generated >= due, "No fees left for distribution");
            _isEth ? _provider.transfer(due) : _isMarket  ? require(MarketAddress.transfer(_provider, due), "Fail to tranfer fund") : require(TokenAddress.transfer(_provider, due), "Fail to tranfer fund"); 
           
           
            emit Rewarded(_provider, due, _isMarket, now);
           } 
           
            _isMarket ? baseFees_generated = baseFees_generated.sub(feesShared) : fees_generated = fees_generated.sub(feesShared);
        
    }
    
    
}

// File: contracts\IEllaExchangeService.sol

pragma solidity >= 0.4.0 < 0.7.0;




/*
 * @author Ella Finance
 * @website https://ella.finance
 * @email support@ella.finance
 * Date: 18 Sept 2020
 */

interface IEllaExchangeService {
    using SafeMath for uint;
      event RequestCreated(
      address _creator,
      uint _requestType,
      uint _changeTo,
      string _reason,
      uint _positiveVote,
      uint _negativeVote,
      uint _powerUsed,
      bool _stale,
      uint _votingPeriod,
      uint _requestID
      );
    event ExchangeCreated(address _exchange, string _market, address _base_address, address _token_address );
    function createRequest(uint _requestType, uint _changeTo, string calldata _reason) external;
    function createExchange(address _marketAddress, address _tokenAddress, bool _isEthereum, address _priceAddress, string calldata _market) external returns (address _exchange);
      event VotedForRequest(
        address _voter,
        uint _requestID,
        uint _positiveVote,
        uint _negativeVote,
        bool _accept
    );
    
      event Refunded(uint amount, address voterAddress, uint _loanID, uint time);
      event ApproveRequest(uint _requestID, bool _state, address _initiator);  
      function validateRequest(uint _requestID) external;
      function governanceVote(uint _requestType, uint _requestID, uint _votePower, bool _accept) external;
    
}

// File: contracts\EllaExchangeService.sol

pragma solidity >=0.4.0 <0.7.0;




/*
 * @author Ella Finance
 * @website https://ella.finance
 * @email support@ella.finance
 * Date: 18 Sept 2020
 */

contract EllaExchangeService is IEllaExchangeService {
    mapping(bytes => bool) isListed;
     struct Requests{
      address payable creator;
      uint requestType;
      uint changeTo;
      string reason;
      uint positiveVote;
      uint negativeVote;
      uint powerUsed;
      
      bool stale;
      uint votingPeriod;
    }
      struct Votters{
      address payable voter;
    }
     Votters[] voters;
    
    Requests[] requests;
    mapping(uint => Requests[]) listOfrequests;
    mapping(uint => mapping(address => uint)) requestPower;
    mapping(uint => bool) activeRequest;
    uint private requestCreationPower;
    mapping(uint => mapping(address => bool)) manageRequestVoters;
    mapping(uint => Votters[]) activeRequestVoters;
    uint trading_fee;
    address payable trading_fee_address;
    uint system_cut;
    IERC20 ELLA;
     /**
     * Construct a new exchange Service
     * @param _ELLA address of the ELLA ERC20 token
     */
constructor(address _ELLA, uint _initial_fees, address payable _trading_fee_address, uint _system_cut, uint _requestCreationPower) public {
    ELLA = IERC20(_ELLA);
    trading_fee = _initial_fees;
    trading_fee_address = _trading_fee_address;
    system_cut = _system_cut;
    requestCreationPower = _requestCreationPower;
    }


function createExchange(
        address _marketAddress, 
        address _tokenAddress, 
        bool _isEthereum,
        address _priceAddress,
        string memory _market
        
    ) public override returns (address _exchange) {
      bytes memory market = bytes(_toLower(_market));
      require(!isListed[market], "Market already listed");
      EllaExchange exchange = new EllaExchange(address(_marketAddress), address(_tokenAddress), _isEthereum, address(_priceAddress), address(this));
      _exchange = address(exchange);
      isListed[market] = true;
      emit ExchangeCreated(_exchange, _market, _marketAddress, _tokenAddress);
    }
    
    
function getFees() public view returns(uint) {
    return trading_fee;
}

function getSystemCut() public view returns(uint) {
    return system_cut;
}

function getFeesAddress() public view returns(address) {
    return trading_fee_address;
}



/// Request
function createRequest(uint _requestType, uint _changeTo, string memory _reason) public override{
    require(_requestType == 0 || _requestType == 1 || _requestType == 2,  "Invalid request type!");
    require(!activeRequest[_requestType], "Another request is still active");
   
    require(ELLA.allowance(msg.sender, address(this)) >= requestCreationPower, "Insufficient ELLA allowance for vote!");
    ELLA.transferFrom(msg.sender, address(this), requestCreationPower);
    Requests memory _request = Requests({
      creator: msg.sender,
      requestType: _requestType,
      changeTo: _changeTo,
      reason: _reason,
      positiveVote: 0,
      negativeVote: 0,
      powerUsed: requestCreationPower,
      
      stale: false,
      votingPeriod: block.timestamp.add(4 days)
    });
    
    requests.push(_request);
    uint256 newRequestID = requests.length - 1;
     Requests memory request = requests[newRequestID];
    emit RequestCreated(
      request.creator,
      request.requestType,
      request.changeTo,
      request.reason,
      request.positiveVote,
      request.negativeVote,
      request.powerUsed,
      request.stale,
      request.votingPeriod,
      newRequestID
      );
}


function governanceVote(uint _requestType, uint _requestID, uint _votePower, bool _accept) public override{
    Requests storage request = requests[_requestID];
    require(request.votingPeriod >= block.timestamp, "Voting period ended");
    require(_votePower > 0, "Power must be greater than zero!");
    require(_requestType == 0 || _requestType == 1 || _requestType == 2,  "Invalid request type!");
   
    require(ELLA.allowance(msg.sender, address(this)) >= _votePower, "Insufficient ELLA allowance for vote!");
    ELLA.transferFrom(msg.sender, address(this), _votePower);
    requestPower[_requestType][msg.sender] = requestPower[_requestType][msg.sender].add(_votePower);
     
     
       if(_accept){
            request.positiveVote = request.positiveVote.add(_votePower);
        }else{
            request.negativeVote = request.negativeVote.add(_votePower);  
        }
      
           
            if(manageRequestVoters[_requestID][msg.sender] == false){
                manageRequestVoters[_requestID][msg.sender] = true;
                activeRequestVoters[_requestID].push(Votters(msg.sender));
            }
       
          
    
    emit VotedForRequest(msg.sender, _requestID, request.positiveVote, request.negativeVote, _accept);
    
}

function validateRequest(uint _requestID) public override{
    Requests storage request = requests[_requestID];
    //require(block.timestamp >= request.votingPeriod, "Voting period still active");
    require(!request.stale, "This has already been validated");
   
   
    if(request.requestType == 0){
        if(request.positiveVote >= request.negativeVote){
            trading_fee = request.changeTo;
           
            
        }
        
    }else if(request.requestType == 1){
        if(request.positiveVote >= request.negativeVote){
            requestCreationPower = request.changeTo;
           
            
            
        }
        
    }else if(request.requestType == 2){
        if(request.positiveVote >= request.negativeVote){
            system_cut = request.changeTo;
            
            
            
        }
        
    }
    else if(request.requestType == 3){
        if(request.positiveVote >= request.negativeVote){
            trading_fee_address = request.creator;
            
            
            
        }
        
    }
   
    request.stale = true;
    
   
    
    for (uint256 i = 0; i < activeRequestVoters[_requestID].length; i++) {
           address voterAddress = activeRequestVoters[_requestID][i].voter;
           uint amount = requestPower[request.requestType][voterAddress];
           require(ELLA.transfer(voterAddress, amount), "Fail to refund voter");
           requestPower[request.requestType][voterAddress] = 0;
           emit Refunded(amount, voterAddress, _requestID, now);
    }
    
     require(ELLA.transfer(request.creator, request.powerUsed), "Fail to transfer fund");
    emit ApproveRequest(_requestID, request.positiveVote >= request.negativeVote, msg.sender);
}


function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    

 }