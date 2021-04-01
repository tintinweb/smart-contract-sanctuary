/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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

interface ITokitRegistry {

    /**
     * @dev Add a project to the registry
     * @param _customer A customer address
     * @param _projectId A project identifier
     * @param _token A token address
     * @param _fund A fund address
     */
    function register(address _customer, uint _projectId, address _token, address _fund) external;

    /**
     * @dev Add an asset to the registry
     * @param _assetId An asset identifier
     * @param _asset An asset address
     */
    function registerAsset(uint _assetId, address _asset) external;

    /**
     * @dev Lookup a token and fund addresses by a proect id
     * @param _projectId An project identifier (a search key)
     * @return Token and fund addresses
     */
    function lookupByProject(uint _projectId) external view returns (address, address);

    /**
     * @dev Lookup an asset address by asset id
     * @param _assetId An asset id
     * @return An asset address
     */
    function lookupAsset(uint _assetId) external view returns(address);
}
interface IBreakerFund {

    /**
     * @dev Deposits reward in Ethers
     */
    function depositReward() external payable;

    /**
     * @dev Deposits reward (in ERC20 tokens - stablecoins that could be USDC)
     * @param _asset An address of the asset to make a transferFrom call
     * @param _amount Amount of transferred tokens
     */
    function depositCoinReward(address _asset, uint _amount) external;

    /**
     * @dev Credits a reward (in wei) to an owed balance
     * @param _for User's address
     * @return The reward (in wei)
     */
    function freezeReward(address _for) external returns(uint);

    /**
     * @dev Credits a reward (in ERC20 tokens - stablecoins that could be USDC)
     * to an owed balance
     * @param _for User's address
     * @return The reward tokens
     */
    function freezeCoinReward(address _for) external returns(uint);

}

/**
 * @title Asset contract - implements reward distribution among BreakerFund contracts
 */
contract BreakerAsset {

  using SafeMath for uint;

  address public registry;
  address public coin; // ERC20 token (stablecoin; could be USDC)
  address public owner;

  uint[] private projectIds;
  uint[] private fractions;
  uint public assetId;
  uint public constant SUM_OF_FRACTIONS = 1000;

  /**
   * @dev Throws if passed address is a zero address
   */
  modifier nonZeroAddress(address _addr) {
    require(address(_addr) != address(0), "The address can't be zero");
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner
   */
  modifier onlyOwner() {
      require(owner == msg.sender, "Caller is not the owner");
      _;
  }

  /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
  function transferOwnership(address newOwner) public onlyOwner {
      require(newOwner != address(0), "Zero address");
      owner = newOwner;
  }

  /**
   * @dev Constructor for an upgradeable contract that sets the values for {assetId}, {projectIds}, {fractions},
   * {registry}, and {coin}
   * @param _assetId An asset identifier
   * @param _projectIds An array of ids of the project (each project corresponds to a token and fund contract
   * addresses)
   * @param _fractions An array of fractions of the Ethers to be received among fund contracts (greater the fraction - 
   * more the fund contract will receive)
   * @param _registry Address of a registry contract to lookup a fund contracts addresses that are bound with
   * {projectId}
   * @param _coin Address of ERC20 token in which users could pay. It could also be a stablecoin such as USDC
   * @param _owner Contract owner address
   */
  constructor(
    uint _assetId,
    uint[] memory _projectIds,
    uint[] memory _fractions,
    address _registry,
    address _coin,
    address _owner
  ) public nonZeroAddress(_registry) nonZeroAddress(_coin) {
    require(_projectIds.length == _fractions.length && _projectIds.length != 0, "Incorrect number of projects");

    uint _totalFractions = 0;
    for (uint i = 0; i < _projectIds.length; i++) {
      require(_fractions[i] != 0, "A fraction can't be zero");
      projectIds.push(_projectIds[i]);
      fractions.push(_fractions[i]);
      _totalFractions += _fractions[i];
    }
    require(_totalFractions == SUM_OF_FRACTIONS, "Incorrect sum of fractions");

    owner = _owner;

    assetId = _assetId;
    registry = _registry;
    coin = _coin;
  }

  /**
   * @dev Returns the fraction that corresponds to the {_projectId}
   * @param _projectId Unique project ID
   */
  function getFraction(uint _projectId) public view returns(uint) {
    for (uint i = 0; i < projectIds.length; i++) {
      if (projectIds[i] == _projectId) {
        return fractions[i];
      }
    }
    return 0;
  }

  /**
   * @dev A payable function to receive Ether that calls a function to distribute Ethers among fund contracts
   */
  receive() external virtual payable {
    _distributeEthers(msg.value);
  }

  /**
   * @dev A function to be called from backend when some ERC20 tokens (possible USDC) are sent to this contract's
   * address
   */
  function distributeCoins() public virtual onlyOwner {
    uint _coinBalance = IERC20(coin).balanceOf(address(this));
    _distributeCoins(_coinBalance);
  }

  /**
   * @dev Destroys a contract and sends everything (both Ethers and ERC20 tokens) to {_receiver} address
   * @param _receiver A receiver's address of all Ethers and ERC20 tokens (possible USDC) that belongs to the contract
   */
  function destroy(address payable _receiver) public onlyOwner nonZeroAddress(_receiver) {
    uint _coinBalance = IERC20(coin).balanceOf(address(this));
    IERC20(coin).transfer(_receiver, _coinBalance);
    selfdestruct(_receiver);
  }

  /**
   * @dev Distributes a {_totalAmount} of wei among fund contracts according to the corresponding fractions
   * @param _totalAmount Amount to be distributed (in wei)
   */
  function _distributeEthers(uint _totalAmount) internal {
    require(_totalAmount != 0, "Total amount is zero");

    for (uint i = 0; i < projectIds.length; i++) {
      (,address fundAddr) = ITokitRegistry(registry).lookupByProject(projectIds[i]);
      require(fundAddr != address(0), "No such project in registry");

      IBreakerFund fund = IBreakerFund(payable(fundAddr));
      uint amount = _totalAmount.mul(fractions[i]).div(SUM_OF_FRACTIONS);

      fund.depositReward{ value: amount }();
    }
  }

  /**
   * @dev Distributes a {_totalAmount} of coins (ERC20 tokens that could be USDC) among fund contracts according to the
   * corresponding fractions
   * @param _totalAmount Amount to be distributed (in ERC20 tokens)
   */
  function _distributeCoins(uint _totalAmount) internal {
    require(_totalAmount != 0, "Total amount is zero");

    for (uint i = 0; i < projectIds.length; i++) {
      (,address fundAddr) = ITokitRegistry(registry).lookupByProject(projectIds[i]);
      require(fundAddr != address(0), "No such project in registry");

      IBreakerFund fund = IBreakerFund(payable(fundAddr));
      uint amount = _totalAmount.mul(fractions[i]).div(SUM_OF_FRACTIONS);

      // Deposit coins
      IERC20(coin).approve(address(fund), amount);
      fund.depositCoinReward(address(this), amount);
    }
  }

}


struct FractionInvestor {
  address payable recepient;
  uint32 fraction; // max value: SUM_OF_INVESTOR_FRACTIONS
}

struct AmountInvestor {
  address payable recepient;
  uint amountToBePaid;
}

struct SalesAgent {
  address payable recepient;
  uint ethThreshold;
  uint coinThreshold;
  uint32 fraction; // max value: SUM_OF_INVESTOR_FRACTIONS
}

enum Currency {
  ETH, COIN
}

enum InvestorType {
  NONE, FRACTION, THRESHOLD_COIN, THRESHOLD_ETH, THRESHOLD_BOTH
}

contract BreakerAssetWithInvestor is BreakerAsset {
  uint public constant SUM_OF_INVESTOR_FRACTIONS = 10000;

  event AssetInvestorAdded(
    uint indexed _assetid,
    address indexed _recepient,
    uint32 _fraction,
    uint _amount,
    uint _coinAmount
  );

  event AssetInvestorRemoved(
    uint indexed _assetid,
    address indexed _recepient
  );

  FractionInvestor[] public fractionInvestors;
  AmountInvestor[] public ethAmountInvestors;
  AmountInvestor[] public coinAmountInvestors;
  SalesAgent public salesAgent;
  mapping(address => InvestorType) public investorExists;


  modifier nonSalesAgent(address _recepient) {
    require(salesAgent.recepient != _recepient, "This address is salesAgent");
    _;
  }

  modifier nonZero(address _recepient) {
    require(_recepient != address(0), "Zero address");
    _;
  }

  constructor(
    uint _assetId,
    uint[] memory _projectIds,
    uint[] memory _fractions,
    address _registry,
    address _coin,
    address _owner
  ) BreakerAsset(_assetId,
    _projectIds,
    _fractions,
    _registry,
    _coin,
    _owner
  ) public {}

  //region Public methods

  /**
   * @dev A payable function to receive Ether that calls a function to distribute Ethers among investors
   */
  receive() external override payable {
    _distributeCurrency(msg.value, Currency.ETH);
  }

  /**
   * @dev A function to be called from backend when some ERC20 tokens (possible USDC) are sent to this contract's
   * address
   */
  function distributeCoins() public override onlyOwner {
    uint coinBalance = IERC20(coin).balanceOf(address(this));
    _distributeCurrency(coinBalance, Currency.COIN);
  }

  function addThresholdInvestor(address payable _recepient, uint _ethAmount, uint _coinAmount) public onlyOwner nonZero(_recepient) nonSalesAgent(_recepient) {
    require(_ethAmount > 0 || _coinAmount > 0, "Zero amount");

    InvestorType invType = investorExists[_recepient];

    if (_ethAmount > 0) {
      require(invType == InvestorType.NONE || invType == InvestorType.THRESHOLD_COIN, "Threshold investor exists");
      ethAmountInvestors.push(AmountInvestor({
        recepient: payable(_recepient),
        amountToBePaid: _ethAmount
      }));
      if (invType == InvestorType.NONE)
        invType = InvestorType.THRESHOLD_ETH;
      else
        invType = InvestorType.THRESHOLD_BOTH;
    }

    if (_coinAmount > 0) {
      require(invType == InvestorType.NONE || invType == InvestorType.THRESHOLD_ETH, "Threshold investor exists");
      coinAmountInvestors.push(AmountInvestor({
        recepient: payable(_recepient),
        amountToBePaid: _coinAmount
      }));
      if (invType == InvestorType.NONE)
        invType = InvestorType.THRESHOLD_COIN;
      else
        invType = InvestorType.THRESHOLD_BOTH;
    }

    investorExists[_recepient] = invType;

    emit AssetInvestorAdded({
      _assetid: assetId,
      _recepient: _recepient,
      _fraction: 0,
      _amount: _ethAmount,
      _coinAmount: _coinAmount
    });
  }

  function addFractionInvestor(address payable _recepient, uint32 _fraction) public onlyOwner nonZero(_recepient) nonSalesAgent(_recepient) {
    require(_fraction > 0, "Zero fraction");
    InvestorType invType = investorExists[_recepient];

    require(invType == InvestorType.NONE, "Investor exists");

    uint fractionSum = _fraction;
    for (uint i = 0; i < fractionInvestors.length; i++) {
      fractionSum = fractionSum.add(fractionInvestors[i].fraction);
    }
    require(fractionSum <= SUM_OF_INVESTOR_FRACTIONS, "Fractions sum exceeds max");

    investorExists[_recepient] = InvestorType.FRACTION;

    fractionInvestors.push(FractionInvestor({
      recepient: _recepient,
      fraction: _fraction
    }));

    emit AssetInvestorAdded({
      _assetid: assetId,
      _recepient: _recepient,
      _fraction: _fraction,
      _amount: 0,
      _coinAmount: 0
     });
  }

  function setSalesAgent(address payable _recepient, uint _ethThreshold, uint _coinThreshold, uint32 _fraction) public onlyOwner {
    if (_recepient == address(0)) {
      // reset salesAgent to zero
      salesAgent = SalesAgent({
        recepient: address(0),
        ethThreshold: 0,
        coinThreshold: 0,
        fraction: 0
      });
    } else {
      require(salesAgent.recepient == address(0), "salesAgent already exists");

      uint fractionSum = _fraction;
      for (uint i = 0; i < fractionInvestors.length; i++) {
        fractionSum = fractionSum.add(fractionInvestors[i].fraction);
      }
      require(fractionSum <= SUM_OF_INVESTOR_FRACTIONS, "Fractions sum exceeds max");

      InvestorType invType = investorExists[_recepient];
      require(invType == InvestorType.NONE, "Investor exists");

      salesAgent = SalesAgent({
        recepient: _recepient,
        ethThreshold: _ethThreshold,
        coinThreshold: _coinThreshold,
        fraction: _fraction
      });
    }
  }

  function increaseInvestorEthThreshold(address _recepient, uint _ethThreshold) public onlyOwner {
    if (_recepient == salesAgent.recepient) {
      require(salesAgent.ethThreshold < _ethThreshold, "Incorrect value");
      salesAgent.ethThreshold = _ethThreshold;
      return;
    }

    InvestorType invType = investorExists[_recepient];
    require(invType == InvestorType.THRESHOLD_ETH || invType == InvestorType.THRESHOLD_BOTH, "Investor does not exists");

    for (uint i = 0; i < ethAmountInvestors.length; ++i) {
      if (ethAmountInvestors[i].recepient == _recepient) {
        require(ethAmountInvestors[i].amountToBePaid < _ethThreshold, "Incorrect value");
        ethAmountInvestors[i].amountToBePaid = _ethThreshold;
        break;
      }
    }
  }

  function increaseInvestorCoinThreshold(address _recepient, uint _coinThreshold) public onlyOwner {
    if (_recepient == salesAgent.recepient) {
      require(salesAgent.coinThreshold < _coinThreshold, "Incorrect value");
      salesAgent.coinThreshold = _coinThreshold;
      return;
    }

    InvestorType invType = investorExists[_recepient];
    require(invType == InvestorType.THRESHOLD_COIN || invType == InvestorType.THRESHOLD_BOTH, "Investor does not exists");

    for (uint i = 0; i < coinAmountInvestors.length; ++i) {
      if (coinAmountInvestors[i].recepient == _recepient) {
        require(coinAmountInvestors[i].amountToBePaid < _coinThreshold, "Incorrect value");
        coinAmountInvestors[i].amountToBePaid = _coinThreshold;
        break;
      }
    }
  }

  function removeInvestor(address _recepient) public onlyOwner {
    InvestorType invType = investorExists[_recepient];
    require(invType != InvestorType.NONE, "Investor does not exist");

    if (_recepient == salesAgent.recepient) {
      salesAgent = SalesAgent({
        recepient: address(0),
        ethThreshold: 0,
        coinThreshold: 0,
        fraction: 0
      });
    }
    else if (invType ==InvestorType.FRACTION) {
      _removeFractionInvestor(_recepient);
    }
    else {
      if (invType == InvestorType.THRESHOLD_ETH || invType == InvestorType.THRESHOLD_BOTH) {
        _removeThresholdInvestor(_recepient, ethAmountInvestors);
      }
      if (invType == InvestorType.THRESHOLD_COIN || invType == InvestorType.THRESHOLD_BOTH) {
        _removeThresholdInvestor(_recepient, coinAmountInvestors);
      }
    }
    investorExists[_recepient] = InvestorType.NONE;

    emit AssetInvestorRemoved({
      _assetid: assetId,
      _recepient: _recepient
    });
  }

  //endregion

  //region utils for adding/removing investors from queues
  function _removeFractionInvestor(address _recepient) private {
    uint i = 0;
    for ( ; i < fractionInvestors.length; ++i) {
      if (fractionInvestors[i].recepient == _recepient) {
        break;
      }
    }

    for (uint j = i + 1; j < fractionInvestors.length; ++j) {
      fractionInvestors[j - 1] = fractionInvestors[j];
    }
    fractionInvestors.pop();
  }

  function _removeThresholdInvestor(address _recepient, AmountInvestor[] storage investors) private {
    uint i = 0;
    for ( ; i < investors.length; ++i) {
      if (investors[i].recepient == _recepient) {
        break;
      }
    }
    for (uint j = i + 1; j < investors.length; ++j) {
      investors[j - 1] = investors[j];
    }
    investors.pop();
  }

  function _deletePaidInvestorsIfNeeded(AmountInvestor[] storage investors) private {
    uint firstPaidIndex = 0;
    for ( ; firstPaidIndex < investors.length; ++firstPaidIndex)
      if (investors[firstPaidIndex].amountToBePaid != 0)
        break;
    if (firstPaidIndex == 0)
      return;
    for (uint i = firstPaidIndex; i < investors.length; ++i)
      investors[i - firstPaidIndex] = investors[i];
    for (uint i = 0; i < firstPaidIndex; ++i)
      investors.pop();
  }

  //endregion

  //region utils for payment distribution

  function _payCurrency(address _recepient, uint _amount, Currency _currency) private {
    if (_currency == Currency.ETH) {
      payable(_recepient).transfer(_amount);
    } else {
      IERC20(coin).transfer(_recepient, _amount);
    }
  }

  function _distributeFractionInvestors(uint _amountToDistribute, Currency currency) private returns (uint) {
    uint amountLeft = _amountToDistribute;
    for (uint i = 0; i < fractionInvestors.length; ++i) {
      uint amount = _amountToDistribute.mul(fractionInvestors[i].fraction).div(SUM_OF_INVESTOR_FRACTIONS);
      if (amount > 0) {
        _payCurrency(fractionInvestors[i].recepient, amount, currency);
        amountLeft = amountLeft.sub(amount);
      }
    }
    return amountLeft;
  }

  function _distributeSalesAgent(uint _amount, Currency _currency) private returns (uint) {
    uint amountLeft = _amount;

    if (salesAgent.recepient != address(0)) {
      uint fractionAmount = _amount.mul(salesAgent.fraction).div(SUM_OF_INVESTOR_FRACTIONS);

      amountLeft = amountLeft.sub(fractionAmount);

      uint currentThreshold = _currency == Currency.ETH
        ? salesAgent.ethThreshold
        : salesAgent.coinThreshold;
      
      uint thresholdAmount = currentThreshold < amountLeft
        ? currentThreshold
        : amountLeft;

      amountLeft = amountLeft.sub(thresholdAmount);

      _payCurrency(salesAgent.recepient, fractionAmount.add(thresholdAmount), _currency);
    }

    return amountLeft;
  }

  function _distributeCurrency(uint _amount, Currency _currency) private {
    require(_amount > 0, "Total amount is zero");

    uint amountLeft = _amount;

    amountLeft = _distributeSalesAgent(amountLeft, _currency);
    if (amountLeft == 0) return;

    amountLeft = _distributeFractionInvestors(amountLeft, _currency);
    if (amountLeft == 0) return;

    amountLeft = _distributeAmountInvestors(amountLeft, _currency);
    if (amountLeft == 0) return;

    if (_currency == Currency.ETH) {
      _distributeEthers(amountLeft);
    } else {
      _distributeCoins(amountLeft);
    }
  }

  function _distributeAmountInvestors(uint _initialAmount, Currency _currency) private returns (uint) {
    // select investors array to work on: eth or coin
    AmountInvestor[] storage investors;
    if (_currency == Currency.ETH) {
      investors = ethAmountInvestors;
    } else {
      investors = coinAmountInvestors;
    }

    uint amount = _initialAmount;
    for (uint i = 0; i < investors.length; ++i) {
      if (amount == 0) break;
      uint amountToBePaid = investors[i].amountToBePaid;
      if (amountToBePaid >= amount) {
        // we have less money than we need to send to this investor
        // so we send everything
        _payCurrency(investors[i].recepient, amount, _currency);
        // subtract the amount we sent him, so we owe him less.
        investors[i].amountToBePaid -= amount;
        // we sent him all money, so we have zero
        amount = 0;
      } else {
        // we have enough to pay him all he asks for
        _payCurrency(investors[i].recepient, amountToBePaid, _currency);
        // we sent him everything we owe, so set to 0
        investors[i].amountToBePaid = 0;
        amount -= amountToBePaid;
      }
    }
    _deletePaidInvestorsIfNeeded(investors);
    return amount;
  }

  //endregion
}


/**
 * @title A contract to deploy BreakerAsset contract
 */
contract AssetDeployerWithManyInvestors is Ownable {
    address public registry;
    address public coin; // ERC20 token (stablecoin; could be USDC)

    /**
     * @dev Throws if passed address is a zero address
     */
    modifier nonZeroAddress(address _addr) {
        require(address(_addr) != address(0), "The address can't be zero");
        _;
    }

    event DeployedAsset(uint indexed assetId, address assetAddress);

    /**
     * @dev Sets an owner, registry and coin addresses (ERC20 tokens –
     * stablecoins that could be USDC)
     * @param _registry A registry contract address
     * @param _coin An address of ERC20 token (in which users could pay)
     */
    constructor(address _registry, address _coin)
        public nonZeroAddress(_registry) nonZeroAddress(_coin) 
    {
        registry = _registry;
        coin = _coin;
    }

    /**
     * @dev Deploys BreakerAssetWithInvestor contract
     * @param _assetId An asset identifier
     * @param _projectIds An array of ids of the project (each project corresponds to a token and fund contract
     * addresses)
     * @param _fractions An array of fractions of the Ethers to be received among fund contracts (greater the
     * fraction - more the fund contract will receive)
     * @param _investors Array of addresses of investors which will receive moneuy
     * @param _ethAmounts Array of total amounts of ether the investor[i] will receive
     * @param _coinAmounts Array of total amounts of coin the investor[i] will receive
     */
    function deployAssetWithManyThresholdInvestors(
        uint _assetId,
        uint[] memory _projectIds,
        uint[] memory _fractions,
        address[] memory _investors,
        uint[] memory _ethAmounts,
        uint[] memory _coinAmounts,
        address payable _salesAgent,
        uint _saEthThreshold,
        uint _saCoinThreshold,
        uint32 _saFraction
    ) public onlyOwner {
        require(ITokitRegistry(registry).lookupAsset(_assetId) == address(0), "Asset id exists");
        require(_investors.length == _ethAmounts.length, "Array parameters have different length");
        require(_investors.length == _coinAmounts.length, "Array parameters have different length");

        // deploy Asset with this contract as owner 
        BreakerAssetWithInvestor asset 
            = new BreakerAssetWithInvestor(_assetId, _projectIds, _fractions, address(registry), coin, address(this));
        ITokitRegistry(registry).registerAsset(_assetId, address(asset));

        for (uint i = 0; i < _investors.length; ++i) {
            asset.addThresholdInvestor(payable(_investors[i]), _ethAmounts[i], _coinAmounts[i]);
        }

        if (_salesAgent != address(0)) {
            asset.setSalesAgent(_salesAgent, _saEthThreshold, _saCoinThreshold, _saFraction);
        }


        // set Asset owner to the correct one
        asset.transferOwnership(owner());
        emit DeployedAsset(_assetId, address(asset));
    }
}