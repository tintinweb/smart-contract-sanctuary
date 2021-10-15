// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../ProxyClones/OwnableForClones.sol";
import "./AggregatorV3Interface.sol";

/**

    ✩░▒▓▆▅▃▂▁𝐌𝐞𝐭𝐚𝐆𝐚𝐦𝐞𝐇𝐮𝐛▁▂▃▅▆▓▒░✩

*/


contract MGHPublicOffering is OwnableForClones {

  // chainlink impl. to get any kind of pricefeed
  AggregatorV3Interface internal priceFeed;

  // The LP token used
  IERC20 public lpToken;

  // The offering token
  IERC20 public offeringToken;

  // The block number when IFO starts
  uint256 public startBlock;

  // The block number when IFO ends
  uint256 public endBlock;

  //after this block harvesting is possible
  uint256 private harvestBlock;

  // maps the user-address to the deposited amount in that Pool
  mapping(address => uint256) private amount;

  // amount of tokens offered for the pool (in offeringTokens)
  uint256 private offeringAmount;

  // price in MGH/USDT => for 1 MGH/USDT price would be 10**12; 10MGH/USDT would be 10**13
  uint256 private _price;

  // total amount deposited in the Pool (in LP tokens); resets when new Start and EndBlock are set
  uint256 private totalAmount;

  // Admin withdraw event
  event AdminWithdraw(uint256 amountLP, uint256 amountOfferingToken, uint256 amountWei);

  // Admin recovers token
  event AdminTokenRecovery(address tokenAddress, uint256 amountTokens);

  // Deposit event
  event Deposit(address indexed user, uint256 amount);

  // Harvest event
  event Harvest(address indexed user, uint256 offeringAmount);

  // Event for new start & end blocks
  event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);

  // parameters are set for the pool
  event PoolParametersSet(uint256 offeringAmount, uint256 price);

  // timeLock ensures that users have enough time to harvest before Admin withdraws tokens,
  // sets new Start and EndBlocks or changes Pool specifications
  modifier timeLock() {
    require(block.number > harvestBlock + 10000, "admin must wait before calling this function");
    _;
  }

  /**
    * @dev It can only be called once.
    * @param _lpToken the LP token used
    * @param _offeringToken the token that is offered for the IFO
    * @param _offeringAmount amount without decimals
    * @param __price the price in OfferingToken/LPToken adjusted already by 6 decimal places
    * @param _startBlock start of sale time
    * @param _endBlock end of sale time
    * @param _harvestBlock start of harvest time
    * @param _adminAddress the admin address
  */
  function initialize(
    address _lpToken,
    address _offeringToken,
    address _priceFeed,
    address _adminAddress,
    uint256 _offeringAmount,
    uint256 __price,
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _harvestBlock
    )
    external initializer
    {
    __Ownable_init();
    lpToken = IERC20(_lpToken);
    offeringToken = IERC20(_offeringToken);
    priceFeed = AggregatorV3Interface(_priceFeed);
    setPool(_offeringAmount*10**18, __price*10**6);
    updateStartAndEndBlocks(_startBlock, _endBlock, _harvestBlock);
    transferOwnership(_adminAddress);
  }

  /**
    * @notice It allows users to deposit LP tokens opr ether to pool
    * @param _amount: the number of LP token used (6 decimals)
  */
  function deposit(uint256 _amount) external payable {

    // Checks whether the block number is not too early
    require(block.number > startBlock && block.number < endBlock, "Not sale time");

    // Transfers funds to this contract
    if (_amount > 0) {
      require(lpToken.transferFrom(address(msg.sender), address(this), _amount));
  	}
    // Updates the totalAmount for pool
    if (msg.value > 0) {
      _amount += uint256(getLatestEthPrice()) * msg.value / 1e20;
    }
    totalAmount += _amount;

    // if its pool1, check if new total amount will be smaller or equal to OfferingAmount / price
    require(
      offeringAmount >= totalAmount * _price,
      "not enough tokens left"
    );

    // Update the user status
    amount[msg.sender] += _amount;

    emit Deposit(msg.sender, _amount);
  }

  /**
    * @notice It allows users to harvest from pool
    * @notice if user is not whitelisted and the whitelist is active, the user is refunded in lpTokens
  */
  function harvest() external {
    // buffer time between end of deposit and start of harvest for admin to whitelist (~7 hours)
    require(block.number > harvestBlock, "Too early to harvest");

    // Checks whether the user has participated
    require(amount[msg.sender] > 0, "already harvested");

    // Initialize the variables for offering and refunding user amounts
    uint256 offeringTokenAmount = _calculateOfferingAmount(msg.sender);

    amount[msg.sender] = 0;

    require(offeringToken.transfer(address(msg.sender), offeringTokenAmount));

    emit Harvest(msg.sender, offeringTokenAmount);
  }


  /**
    * @notice It allows the admin to withdraw funds
    * @notice the offering token can only be withdrawn 10000 blocks after harvesting
    * @param _lpAmount: the number of LP token to withdraw (18 decimals)
    * @param _offerAmount: the number of offering amount to withdraw
    * @param _weiAmount: the amount of Wei to withdraw
    * @dev This function is only callable by admin.
  */
  function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount, uint256 _weiAmount) external  onlyOwner {

    if (_lpAmount > 0) {
      lpToken.transfer(address(msg.sender), _lpAmount);
    }

    if (_offerAmount > 0) {
      require(block.number > harvestBlock + 10000, "too early to withdraw offering token");
      offeringToken.transfer(address(msg.sender), _offerAmount);
    }

    if (_weiAmount > 0) {
      payable(address(msg.sender)).transfer(_weiAmount);
    }

    emit AdminWithdraw(_lpAmount, _offerAmount, _weiAmount);
  }

  /**
    * @notice It allows the admin to recover wrong tokens sent to the contract
    * @param _tokenAddress: the address of the token to withdraw (18 decimals)
    * @param _tokenAmount: the number of token amount to withdraw
    * @dev This function is only callable by admin.
  */
  function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
    require(_tokenAddress != address(lpToken), "Cannot be LP token");
    require(_tokenAddress != address(offeringToken), "Cannot be offering token");

    IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);

    emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
  }

  /**
    * @notice timeLock
    * @notice It sets parameters for pool
    * @param _offeringAmount offering amount with all decimals
    * @dev This function is only callable by admin
  */
  function setPool(
    uint256 _offeringAmount,
    uint256 __price
   ) public onlyOwner timeLock
   {
    offeringAmount = _offeringAmount;
    _price = __price;
    emit PoolParametersSet(_offeringAmount, _price);
  }

  /**
    * @notice It allows the admin to update start and end blocks
    * @notice automatically resets the totalAmount in the Pool to 0, but not userAmounts
    * @notice timeLock
    * @param _startBlock: the new start block
    * @param _endBlock: the new end block
  */
  function updateStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock, uint256 _harvestBlock) public onlyOwner timeLock {
    require(_startBlock < _endBlock, "New startBlock must be lower than new endBlock");
    require(block.number < _startBlock, "New startBlock must be higher than current block");
    totalAmount = 0;
    startBlock = _startBlock;
    endBlock = _endBlock;
    harvestBlock = _harvestBlock;

    emit NewStartAndEndBlocks(_startBlock, _endBlock);
  }

  /**
    * @notice It returns the pool information
    * @return offeringAmountPool: amount of tokens offered for the pool (in offeringTokens)
    * @return _price the price in OfferingToken/LPToken, 10**12 means 1:1 because of different decimal places
    * @return totalAmountPool: total amount pool deposited (in LP tokens)
  */
  function viewPoolInformation()
    external
    view
    returns(
      uint256,
      uint256,
      uint256
    )
    {
    return (
      offeringAmount,
      _price,
      totalAmount
    );
  }

  /**
    * @notice External view function to see user amount in pool
    * @param _user: user address
  */
  function viewUserAmount(address _user)
    external
    view
    returns(uint256)
  {
    return (amount[_user]);
  }

  /**
    * @notice External view function to see user offering amounts
    * @param _user: user address
  */
  function viewUserOfferingAmount(address _user)
    external
    view
    returns(uint256)
  {
    return _calculateOfferingAmount(_user);
  }

  /**
    * @notice It calculates the offering amount for a user and the number of LP tokens to transfer back.
    * @param _user: user address
    * @return the amount of OfferingTokens _user receives as of now
  */
  function _calculateOfferingAmount(address _user)
    internal
    view
    returns(uint256)
  {
    return amount[_user] * _price;
  }

  function setToken(address _lpToken, address _offering) public onlyOwner timeLock {
    lpToken = IERC20(_lpToken);
    offeringToken = IERC20(_offering);
  }

  /**
    * @return returns the price from the AggregatorV3 contract specified in initialization 
  */
  function getLatestEthPrice() public view returns(int) {
    (
      uint80 roundID,
      int price,
      uint startedAt,
      uint timeStamp,
      uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    return price;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ContextForClones.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableForClones is ContextForClones {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextForClones is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}