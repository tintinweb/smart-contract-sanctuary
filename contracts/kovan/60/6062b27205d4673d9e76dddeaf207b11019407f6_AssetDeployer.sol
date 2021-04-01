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



contract AssetDeployer is Ownable {

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
     * @dev Deploys BreakerAsset contract
     * @param _assetId An asset identifier
     * @param _projectIds An array of ids of the project (each project corresponds to a token and fund contract
     * addresses)
     * @param _fractions An array of fractions of the Ethers to be received among fund contracts (greater the
     * fraction - more the fund contract will receive)
     */
    function deployAsset(
        uint _assetId,
        uint[] memory _projectIds,
        uint[] memory _fractions
    ) public onlyOwner {
        require(ITokitRegistry(registry).lookupAsset(_assetId) == address(0), "Asset id exists");
        BreakerAsset asset = new BreakerAsset(_assetId, _projectIds, _fractions, address(registry), coin, owner());
        ITokitRegistry(registry).registerAsset(_assetId, address(asset));
        emit DeployedAsset(_assetId, address(asset));
    }

}