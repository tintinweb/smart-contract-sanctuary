/**
 *Submitted for verification at polygonscan.com on 2021-09-02
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts/FeedPiggyMain.sol

pragma solidity ^0.8.0;



interface FeedPiggyTokenInterface is IERC20Metadata {
  function mint(address _account, uint256 _amount) external;
}

interface ILendingPool {
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);
  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
}

interface IAaveIncentivesController {
  function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);
}

// @author T_
contract FeedPiggyMain is Ownable {
  // Define piggy's attributes
  struct Piggy {
    uint32 level; // current level
    uint totalAmountDeposited; // total amount deposited
    uint readyTime; // when piggy is ready to be fed again
    uint created; // when piggy was created
    uint lastDepositTime; // when was the last deposit made
    uint amountOfAccruedTokens;
  }

  // Define drip attributes
  struct Drip {
    uint rate; // how many tokens per second per dollar dripped
    uint startDate;
  }

  // How many drips have been created
  uint public currentDripIndex = 0;

  mapping (uint => Drip) public drips;

  // Address has a piggy. One at the time at this time.
  mapping (address => Piggy) public piggy;

  uint public totalPiggies = 0;

  // Price for each level
  uint[] public prices;

  uint public totalAmountDepositedInTheWholeGame = 0;

  // Cooldown for each level
  uint[] public cooldowns;

  FeedPiggyTokenInterface public usdcContract;
  FeedPiggyTokenInterface public tokenContract;

  ILendingPool public lendingPool; // aave lending pool
  IAaveIncentivesController public incentivesController;

  bool public lendingPoolEnabled = false;

  constructor(
    uint[] memory _prices,
    uint[] memory _cooldowns,
    address _usdcAddress,
    address _tokenAddress, // feedpiggy token address
    uint _dripRate,
    address _lendingPoolAddress,
    address _incentivesControllerlAddress
  ) {
    prices = _prices;
    cooldowns = _cooldowns;
    usdcContract = FeedPiggyTokenInterface(_usdcAddress);
    tokenContract = FeedPiggyTokenInterface(_tokenAddress);
    drips[0] = Drip(_dripRate, block.timestamp);
    lendingPool = ILendingPool(_lendingPoolAddress);
    incentivesController = IAaveIncentivesController(_incentivesControllerlAddress);
  }

  // Events
  event LevelUp(address indexed _addressThatLeveledUp, uint32 _currentLevel, uint _readyTime);

  // Level up. Update cooldown. It will be done by feeding a piggy.
  function feed(uint amount) external {
    // Make sure amount is appropriate for the level
    require(currentFeedPrice() == amount, "Piggy wants something else");

    // Make sure feeding doesn't happen before time expires
    require(_getUserReadyTime() < block.timestamp, "Piggy's on a treadmill, he'll eat later");

    // Transfer usdc from msg.sender to the contract
    bool success = usdcContract.transferFrom(msg.sender, address(this), amount);
    require(success, "Buy failed");

    // Accrued tokens
    piggy[msg.sender].amountOfAccruedTokens = calculateAccruedTokens(msg.sender, block.timestamp);
    piggy[msg.sender].lastDepositTime = block.timestamp;

    // Update total deposited amount
    piggy[msg.sender].totalAmountDeposited += amount;

    // Update cooldown
    piggy[msg.sender].readyTime = block.timestamp + cooldowns[_getUserLevel()];

    if (piggy[msg.sender].level == 0) totalPiggies++;

    // Increase the level
    piggy[msg.sender].level++;

    // Deposit into aave
    if (lendingPoolEnabled) {
      require(
        usdcContract.approve(address(lendingPool), amount),
        "Approval of lending pool to spend contract's USDc failed"
      );
      lendingPool.deposit(address(usdcContract), amount, address(this), 0);
    }

    totalAmountDepositedInTheWholeGame += amount;

    // Emit LevelUp
    emit LevelUp(msg.sender, _getUserLevel(), _getUserReadyTime());
  }

  // Kill the piggy. Return money and tokens to the msg.sender
  function killThePiggy() external returns(bool) {
    uint totalAmountPiggyDeposited = piggy[msg.sender].totalAmountDeposited;
    require(piggy[msg.sender].totalAmountDeposited > 0, "Don't kill a newborn piggy!");

    uint piggyAccruedTokens = calculateAccruedTokens(msg.sender, block.timestamp);

    // Reset
    piggy[msg.sender] = Piggy(0, 0, 0, 0, 0, 0);

    totalPiggies--;

    totalAmountDepositedInTheWholeGame -= totalAmountPiggyDeposited;

    // Withdraw all funds + interest from aave, so contract can earn interest
    if (lendingPoolEnabled)
      lendingPool.withdraw(address(usdcContract), type(uint256).max, address(this));

    // Mint accrued tokens, send to the user
    tokenContract.mint(msg.sender, piggyAccruedTokens);

    // Transfer usdc back to the user
    require(
      usdcContract.transfer(msg.sender, totalAmountPiggyDeposited),
      "Killing the piggy failed"
    );

    // Deposit back to aave
    if (lendingPoolEnabled && totalAmountDepositedInTheWholeGame > 0) {
      require(
        usdcContract.approve(address(lendingPool), totalAmountDepositedInTheWholeGame),
        "Approval of lending pool to spend contract's USDc failed"
      );
      lendingPool.deposit(address(usdcContract), totalAmountDepositedInTheWholeGame, address(this), 0);
    }

    return true;
  }

  // Calculate user's accrued amount of tokens
  // We have list of drips. Each drip has a starting date and the rate.
  // Iterate through drips starting at the last one. Check if piggyLastDepositTime is larger
  // than drip's startDate or not. If it is, subtract lastDate from piggyLastDepositTime and multiply
  // by rate and deposit amount, and break the loop.
  // If it is not, subtract lastDate from current drip start date and multiply by rate and
  // @param _address User's address we want to calculate accrued token
  // @param lastDate Starts as seconds from the epoch. Becomes drip's startDate during iteration
  // deposit amount and keep iterating.
  function calculateAccruedTokens(address _address, uint lastDate) public view returns(uint) {
    uint piggyLastDepositTime = piggy[_address].lastDepositTime;
    // No deposits made, no accrued tokens
    if (piggyLastDepositTime < 1) return 0;

    uint accruedAmount = 0;
    uint piggyTotalDeposits = piggy[_address].totalAmountDeposited;

    // Start the magic. Jesus Christ help us.
    for (uint i = currentDripIndex; i >= 0; i--) {
      // Last drip or last deposit was after the current drip's start date, so stop here
      if (i == 0 || drips[i].startDate <= piggyLastDepositTime) {
        accruedAmount += (lastDate - piggyLastDepositTime) *
          (piggyTotalDeposits / 10**usdcContract.decimals()) * drips[i].rate;
        break;
      }

      accruedAmount += (lastDate - drips[i].startDate) *
        (piggyTotalDeposits / 10**usdcContract.decimals()) * drips[i].rate;

      lastDate = drips[i].startDate;
    }

    return piggy[_address].amountOfAccruedTokens + accruedAmount;
  }

  // Current user level
  function _getUserLevel() internal view returns(uint32) {
    return piggy[msg.sender].level;
  }

  // Current user readyTime
  function _getUserReadyTime() internal view returns(uint) {
    return piggy[msg.sender].readyTime;
  }

  // Current amount msg.sender has to pay for feeding
  function currentFeedPrice() public view returns(uint) {
    return prices[_getUserLevel()];
  }

  // Withdraw the balance of the contract. Note: it is only withdrawing interest earned by the protocol,
  // deposits are in aave and cannot be withdrawn by anyone but users
  function withdraw() external onlyOwner {
    usdcContract.transfer(msg.sender, usdcContract.balanceOf(address(this)));
  }

  // Withdraw rewards from aave
  function withdrawIncentives(address aToken) external onlyOwner {
    address[] memory assets = new address[](1);
    assets[0] = aToken;
    incentivesController.claimRewards(assets, type(uint256).max, msg.sender);
  }

  // Setters
  function setPrices(uint[] memory _prices) external onlyOwner {
    prices = _prices;
  }

  function setCooldowns(uint[] memory _cooldowns) external onlyOwner {
    cooldowns = _cooldowns;
  }

  function setUsdcContract(address _usdcAddress) external onlyOwner {
    usdcContract = FeedPiggyTokenInterface(_usdcAddress);
  }

  function setTokenContract(address _tokenAddress) external onlyOwner {
    tokenContract = FeedPiggyTokenInterface(_tokenAddress);
  }

  function setDrip(uint _rate) external onlyOwner {
    currentDripIndex++;
    drips[currentDripIndex] = Drip(_rate, block.timestamp);
  }

  function setIncentivesController(address _addr) external onlyOwner {
    incentivesController = IAaveIncentivesController(_addr);
  }

  function setLendingPool(address _addr) external onlyOwner {
    lendingPool = ILendingPool(_addr);
  }

  function setLendingPoolEnabled(bool enabled) external onlyOwner {
    lendingPoolEnabled = enabled;
  }


  // Getters
  function getPrices() external view returns(uint[] memory) {
    return prices;
  }

  function getCooldowns() external view returns(uint[] memory) {
    return cooldowns;
  }
}