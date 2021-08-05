//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

// Eeee! Welcome Dolphins! 
//
//////////////////////////////////////////////////////////////////////
//                                       __                         //
//                                   _.-~  )    ____ eeee ____      //
//                        _..--~~~~,'   ,-/     _                   //
//                     .-'. . . .'   ,-','    ,' )                  //
//                   ,'. . . _   ,--~,-'__..-'  ,'                  //
//                 ,'. . .  (@)' ---~~~~      ,'                    //
//                /. . . . '~~             ,-'                      //
//               /. . . . .             ,-'                         //
//              ; . . . .  - .        ,'                            //
//             : . . . .       _     /                              //
//            . . . . .          `-.:                               //
//           . . . ./  - .          )                               //
//          .  . . |  _____..---.._/ ____ dolphins.wtf ____         //
//~---~~~~-~~---~~~~----~~~~-~~~~-~~---~~~~----~~~~~~---~~~~-~~---~~//
//                                                                  //
//////////////////////////////////////////////////////////////////////
//
// This code has not been audited, but has been reviewed. Hopefully it's bug free... 
// If you do find bugs, remember those were features and part of the game... Don't hate the player.
//
// Also, this token is a worthless game token. Don't buy it. Just farm it, and then play games. It will be fun. 
//
// Eeee! Let the games begin!

// eeee, hardcap set on deployment with minting to dev for subsequent deployment into DolphinPods (2x) & snatchFeeder
contract eeee is ERC20Capped, Ownable {
    using SafeMath for uint256;

    bool public _isGameActive;
    uint256 public _lastUpdated;
    uint256 public _coolDownTime;
    uint256 public _snatchRate;
    uint256 public _snatchPool;
    uint256 public _devFoodBucket;
    bool public _devCanEat;
    bool public _isAnarchy;
    uint256 public _orca;
	uint256 public _river;
	uint256 public _bottlenose;
	uint256 public _flipper = 42069e17;
	uint256 public _peter = 210345e17;
	address public _owner;
	address public _UniLP;
	uint256 public _lpMin;
	uint256 public _feeLevel1;
	uint256 public _feeLevel2;
    
    event Snatched(address indexed user, uint256 amount);

    constructor() public
        ERC20("dolphins.wtf", "EEEE")
        ERC20Capped(42069e18)
    {
        _isGameActive = false;
        _coolDownTime = 3600;
        _devCanEat = false;
        _isAnarchy = false;
        _snatchRate = 1;
        _orca = 69e18;
		_river = 42069e16;
		_bottlenose = 210345e16;
		_lpMin = 1;
		_UniLP = address(0);
		_feeLevel1 = 1e18;
		_feeLevel2 = 5e18;
		_owner = msg.sender;
        mint(msg.sender, 42069e18);
    }

    // levels: checks caller's balance to determine if they can access a function

    function uniLPBalance() public view returns (uint256) {
		IERC20 lpToken = IERC20(_UniLP);
        return lpToken.balanceOf(msg.sender);
	}
	
    function amILP() public view returns(bool) {
        require(_UniLP != address(0), "Eeee! The LP contract has not been set");
        return uniLPBalance() > _lpMin;
    } 

    function amIOrca() public view returns(bool) {
        return balanceOf(msg.sender) >= _orca || amILP();
    } 

    //  Orcas (are you even a dolphin?) - 69 (0.00164%); Can: Snatch tax base
    modifier onlyOrca() {
        require(amIOrca(), "Eeee! You're not even an orca");
        _;
    }

    function amIRiver() public view returns(bool) {
        return balanceOf(msg.sender) >= _river;
    } 

    // River Dolphin (what is wrong with your nose?) - 420.69 (1%); Can: turn game on/off
    modifier onlyRiver() {
        require(amIRiver(), "You're not even a river dolphin");
        _;
    }

    function amIBottlenose() public view returns(bool) {
        return balanceOf(msg.sender) >= _bottlenose;
    } 

    // Bottlenose Dolphin  (now that's a dolphin) - 2103.45 (5%); Can: Change tax rate (up to 2.5%); Devs can eat (allows dev to withdraw from the dev food bucket)
    modifier onlyBottlenose() {
        require(amIBottlenose(), "You're not even a bottlenose dolphin");
        _;
    }

    function amIFlipper() public view returns(bool) {
        return balanceOf(msg.sender) >= _flipper;
    } 

    // Flipper (A based dolphin) - 4206.9 (10%); Can: Change levels thresholds (except Flipper and Peter); Change tax rate (up to 10%); Change cooldown time
    modifier onlyFlipper() {
        require(amIFlipper(), "You're not flipper");
        _;
    }

    function amIPeter() public view returns(bool) {
        return balanceOf(msg.sender) >= _peter;
    } 

    // Peter the Dolphin (ask Margaret Howe Lovatt) - 21034.5 (50%); Can: Burn the key and hand the world over to the dolphins, and stops feeding the devs
    modifier onlyPeter() {
        require(amIPeter(), "You're not peter the dolphin");
        _;
    }

    // Are you the dev?
    modifier onlyDev() {
        require(address(msg.sender) == _owner, "You're not the dev, get out of here");
        _;
    }

    modifier cooledDown() {
        require(now > _lastUpdated.add(_coolDownTime));
        _;
    }
    
    // snatch - grab from snatch pool, requires min 0.01 EEEE in snatchpool -- always free
    function snatchFood() public onlyOrca cooledDown {
        require(_snatchPool >= 1 * 1e16, "snatchpool: min snatch amount (0.01 EEEE) not reached.");
        // check that the balance left in the contract is not less than the amount in the snatchPool, in case of rounding errors
        uint256 effectiveSnatched = balanceOf(address(this)) < _snatchPool ? balanceOf(address(this)) : _snatchPool;

        this.transfer(msg.sender, effectiveSnatched);

        _snatchPool = 0;
        emit Snatched(msg.sender, effectiveSnatched);
    }
    
    // Add directly to the snatchpool, if the caller is not the dev then set to cooldown
    function depositToSnatchPool(uint256 EEEEtoSnatchPool) public {
        transfer(address(this), EEEEtoSnatchPool);
        _snatchPool = _snatchPool.add(EEEEtoSnatchPool);
        if (address(msg.sender) != _owner) {
            _lastUpdated = now;
        }
        
    }

    function depositToDevFood(uint256 EEEEtoDevFood) public {
        transfer(address(this), EEEEtoDevFood);
        _devFoodBucket = _devFoodBucket.add(EEEEtoDevFood);
    }

    // startGame -- call fee level 1
    function startGame() public onlyRiver cooledDown {
        require(!_isGameActive, "Eeee! The game has already started");
        transfer(address(this), _feeLevel1);
        // because the game doesn't turn on until after this call completes we need to manually add to snatch
        callsAlwaysPaySnatch(_feeLevel1);
        _isGameActive = true;
        _lastUpdated = now;
    }

    // pauseGame -- call fee level 1
    function pauseGame() public onlyRiver cooledDown {
        require(_isGameActive, "Eeee! The game has already been paused");
		transfer(address(this), _feeLevel1);
        _isGameActive = false;
        _lastUpdated = now;
    }

    // all payed function calls should pay snatch, even if the game is off
    function callsAlwaysPaySnatch (uint256 amount) internal {
        if (!_isGameActive) {
            _snatch(amount);
        }
    }

    // allowDevToEat - can only be turned on once  -- call fee level 1
    function allowDevToEat() public onlyBottlenose {
        require(!_devCanEat, "Eeee! Too late sucker, dev's eating tonight");
		transfer(address(this), _feeLevel1);
        callsAlwaysPaySnatch(_feeLevel1);
        _devCanEat = true;
		_lastUpdated = now;
    }

    // changeSnatchRate - with max of 3% if Bottlenose; with max of 10% if Flipper -- call fee level 2
    function changeSnatchRate(uint256 newSnatchRate) public onlyBottlenose cooledDown {
        if (amIFlipper()) {
            require(newSnatchRate >= 1 && newSnatchRate <= 10, "Eeee! Minimum snatchRate is 1%, maximum is 10%.");
        } else {
            require(newSnatchRate >= 1 && newSnatchRate <= 3, "Eeee! Minimum snatchRate is 1%, maximum 10% for Flipper");
        }
        transfer(address(this), _feeLevel2);
		callsAlwaysPaySnatch(_feeLevel2);
        _snatchRate = newSnatchRate;
		_lastUpdated = now;
    }

    // changeCoolDownTime - make the game go faster or slower, cooldown to be set in hours (min 1; max 24) -- call fee level 2
    function updateCoolDown(uint256 newCoolDown) public onlyFlipper cooledDown {
        require(_isGameActive, "Eeee! You need to wait for the game to start first");
        require(newCoolDown <= 24 && newCoolDown >= 1, "Eeee! Minimum cooldown is 1 hour, maximum is 24 hours");
        transfer(address(this), _feeLevel2);
		callsAlwaysPaySnatch(_feeLevel2);
        _coolDownTime = newCoolDown * 1 hours;
        _lastUpdated = now;
    }

    // functions to change levels, caller should ensure to calculate this on 1e18 basis -- call fee level 1 * sought change
    function getSizeChangeFee(uint256 currentThreshold, uint256 newThreshold) private pure returns (uint256) {
        require (currentThreshold != newThreshold, 'this is already the threshold');
        return currentThreshold > newThreshold ? currentThreshold.sub(newThreshold) : newThreshold.sub(currentThreshold);
    }
    
    function updateOrca(uint256 updatedThreshold) public onlyFlipper {
        uint256 changeFee = getSizeChangeFee(_orca, updatedThreshold);
        require(balanceOf(msg.sender) >= changeFee, "Eeee! You don't have enough EEEE to make this change.");
		require(updatedThreshold >= 1e18 && updatedThreshold <= 99e18, "Threshold for Orcas must be 1 to 99 EEEE");
        require(updatedThreshold < _river, "Threshold for Orcas must be less than River Dolphins");
        _orca = updatedThreshold;
        transfer(address(this), changeFee);
		callsAlwaysPaySnatch(changeFee);
        _lastUpdated = now;
    }
    
    function updateRiver(uint256 updatedThreshold) public onlyFlipper {
        uint256 changeFee = getSizeChangeFee(_river, updatedThreshold);
        require(balanceOf(msg.sender) >= changeFee, "Eeee! You don't have enough EEEE to make this change.");
		require(updatedThreshold >= 1e18 && updatedThreshold <= 210345e16, "Threshold for River Dolphins must be 1 to 2103.45 EEEE");
        require(updatedThreshold > _orca && updatedThreshold < _bottlenose, "Threshold for River Dolphins must great than River Dolphins *and* less than Bottlenose Dolphins");
        _river = updatedThreshold;
		transfer(address(this), changeFee);
		callsAlwaysPaySnatch(changeFee);
        _lastUpdated = now;
    }
    
    function updateBottlenose(uint256 updatedThreshold) public onlyFlipper {
        uint256 changeFee = getSizeChangeFee(_bottlenose, updatedThreshold);
        require(balanceOf(msg.sender) >= changeFee, "Eeee! You don't have enough EEEE to make this change.");
		require(updatedThreshold >= 1e18 && updatedThreshold <= 42069e17, "Threshold for Bottlenose Dolphins must be 1 to 4206.9 EEEE");
        require(updatedThreshold > _river, "Threshold for Bottlenose Dolphins must great than River Dolphins");
        _bottlenose = updatedThreshold;
		transfer(address(this), changeFee);
		callsAlwaysPaySnatch(changeFee);
        _lastUpdated = now;
    }

    // dolphinAnarchy - transfer owner permissions to 0xNull & stops feeding dev. CAREFUL: this cannot be undone and once you do it the dolphins swim alone.  -- call fee level 2
    function activateAnarchy() public onlyPeter {
        //Return anything in dev pool to snatchpool
        transfer(address(this), _feeLevel2);
		callsAlwaysPaySnatch(_feeLevel2);
        _snatchPool = _snatchPool.add(_devFoodBucket);
        _devFoodBucket = 0;
        _isAnarchy = true; // ends dev feeding
        _owner = address(0);
        _lastUpdated = now;
    }


    // transfers tokens to snatchSupply and fees paid to dev (5%) only when we have not descended into Dolphin BASED anarchy
    function _snatch(uint256 amount) internal {
        // check that the amount is at least 5e-18 eeee, otherwise throw it all in the snatchpool
        if (amount >= 5) {
        uint256 devFood;
            devFood = _isAnarchy ? 0 : amount.mul(5).div(100); // 5% put in a food bucket for the contract creator if we've not descended into dolphin anarchy
            uint256 snatchedFood = amount.sub(devFood);
            _snatchPool = _snatchPool.add(snatchedFood);
            _devFoodBucket = _devFoodBucket.add(devFood);
        } else {
            _snatchPool = _snatchPool.add(amount);
        }
    }

    function _calcSnatchAmount (uint256 amount) internal view returns (uint256) {
        if (_isGameActive) {
            // calculate the snatched amount to be transfered if the game is active
            return (amount.mul(_snatchRate).div(100));
        } else {
            return 0;
        }
    }

    // Need the _transfer function to break at _beforeTokenTransfer to do a second transfer to this contract for SnatchPool & DevFood, but if 
    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
        super._beforeTokenTransfer(sender, recipient, amount);

        // This function should only do anything if the game is active, otherwise it should allow normal transfers
        if (_isGameActive) {
            // TO DO, make sure that transfers from Uniswap LP pool adhere to this
            // Don't snatch transfers from the Uniswap LP pool (if set)
            if (_UniLP != address(sender)) {
                // A first call to _transfer (where the recipient isn't this contract will create a second transfer to this contract
                if (recipient != address(this)) {
                    //calculate snatchAmount
                    uint256 amountToSnatch = _calcSnatchAmount(amount);
                    // This function checks that the account sending funds has enough funds (transfer amount + snatch amount), otherwise reverts
                    require(balanceOf(sender).sub(amount).sub(amountToSnatch) >= 0, "ERC20: transfer amount with snatch cost exceeds balance, send less");
                    // allocate amountToSnatch to snatchPool and devFoodBucket
                    _snatch(amountToSnatch);
                    // make transfer from sender to this address
                    _transfer(sender, address(this), amountToSnatch);
                } 
            }
            // After this, the normal function continues, and makes amount transfer to intended recipient
        }
    }
    
    // feedDev - allows owner to withdraw 5% thrown into dev food buck. Must only be called by the Dev.
    function feedDev() public onlyDev {
        require(_devCanEat, "sorry dev, no scraps for you");
        // check that the balance left in the contract is not less than the amount in the DevFoodBucket, in case of rounding errors
        if (balanceOf(address(this)) < _devFoodBucket) {
            transfer(msg.sender, balanceOf(address(this)));
        } else {
            transfer(msg.sender, _devFoodBucket);
        }
        _devFoodBucket = 0;
    }
	
	// change fees for function calls, can only be triggered by Dev, and then enters cooldown
	function changeFunctionFees(uint256 newFeeLevel1, uint256 newFeeLevel2) public onlyDev {
		_feeLevel1 = newFeeLevel1;
		_feeLevel2 = newFeeLevel2;
		_lastUpdated = now;
	}
	
	function setLP(address addrUniV2LP, uint256 lpMin) public onlyDev {
		_UniLP = addrUniV2LP;
		_lpMin = lpMin;
	}

    function mint(address _to, uint256 amount) public onlyDev {
        _mint(_to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap) public {
        require(cap > 0, "ERC20Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
        }
    }
}

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

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "": {}
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}