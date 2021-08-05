/**
 *Submitted for verification at Etherscan.io on 2020-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity ^0.6.2;

contract UOP_Vesting is Ownable {

    using SafeMath for uint256;
    address UOP_token_address = 0xE4AE84448DB5CFE1DaF1e6fb172b469c161CB85F; 
    uint256 constant START_VESTING_DATE = 1608076800; //2020-12-16T00:00:00+00:00
    uint256 constant ONE_DAY_IN_SECONDS = 60 * 60 * 24;
    uint256 constant AMOUNT_MULTIPLIER = 10 ** 21;

    mapping (address => uint256) earnedAmount;

    uint256 constant STAGE_1_DATE = START_VESTING_DATE + ONE_DAY_IN_SECONDS * 0; // IEO date
    uint256 constant STAGE_2_DATE = START_VESTING_DATE + ONE_DAY_IN_SECONDS * 60; // 60 days from start
    uint256 constant STAGE_3_DATE = START_VESTING_DATE + ONE_DAY_IN_SECONDS * 120; // 120 days from start
    uint256 constant STAGE_4_DATE = START_VESTING_DATE + ONE_DAY_IN_SECONDS * 180; // 180 days from start
    uint256 constant STAGE_5_DATE = START_VESTING_DATE + ONE_DAY_IN_SECONDS * 240; // 240 days from start
    uint256 constant STAGE_6_DATE = START_VESTING_DATE + ONE_DAY_IN_SECONDS * 360; // 360 days from start
    uint256 constant STAGE_7_DATE = START_VESTING_DATE + ONE_DAY_IN_SECONDS * 720; // 720 days from start
    uint256 constant STAGE_8_DATE = START_VESTING_DATE + ONE_DAY_IN_SECONDS * 1080; // 1080 days from start
    uint256 constant STAGE_9_DATE = START_VESTING_DATE + ONE_DAY_IN_SECONDS * 1800; // 1800 days from start
    
    address constant PUBLIC_SALE = 0xe33Ba03933ab0fcC064c03C9a2e4Da9d8e19B3d7; 
    address constant FOUND_ECOSYSTEM = 0xAb6EB3FF8BEc07A018c98E2A7Dc687F60bADaBDe; 
    address constant FOUND_TREASURY = 0xb2dE9aB64676CE1A5A0E821244a2b9edF401043c; 
    address constant AG_SHAREHOLDERS = 0x9e1605321664d13426F67D07f3bFc4fB28777f78; 
    address constant AG_TEAM = 0xE459e5bF1E872Ca5b02cfA24e622874A2AC1BB34; 
    
    uint8 constant allowedAddressesAmount = 5;
    uint8 constant stagesAmount = 9;
    address[allowedAddressesAmount] allowedAddresses = [PUBLIC_SALE, FOUND_ECOSYSTEM, FOUND_TREASURY, AG_SHAREHOLDERS, AG_TEAM];
    uint256[stagesAmount] private _stageDates;
    uint256[stagesAmount][allowedAddressesAmount] private _caps;

    constructor() public {
        _initStages();
        _initCaps();
        transferOwnership(0x08Ca29489282DF3daE9e6654A567daAfe2EF93a1);
    }
    
    
    function _initStages() private {
        _stageDates[0] = STAGE_1_DATE;
        _stageDates[1] = STAGE_2_DATE;
        _stageDates[2] = STAGE_3_DATE;
        _stageDates[3] = STAGE_4_DATE;
        _stageDates[4] = STAGE_5_DATE;
        _stageDates[5] = STAGE_6_DATE;
        _stageDates[6] = STAGE_7_DATE;
        _stageDates[7] = STAGE_8_DATE;
        _stageDates[8] = STAGE_9_DATE;
    }
    
    function _initCaps() private {
        // init PUBLIC_SALE caps
        uint8 addressIndex = getAddressIndex(PUBLIC_SALE);

        _caps[addressIndex][0] = 6250 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][1] = 12500 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][2] = 18750 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][3] = 25000 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][4] = 25000 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][5] = 25000 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][6] = 25000 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][7] = 25000 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][8] = 25000 * AMOUNT_MULTIPLIER;

        // init FOUND_ECOSYSTEM caps
        addressIndex = getAddressIndex(FOUND_ECOSYSTEM);

        _caps[addressIndex][0] = 625 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][1] = 1250 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][2] = 1875 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][3] = 2500 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][4] = 5000 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][5] = 10000 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][6] = 15000 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][7] = 22500 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][8] = 30000 * AMOUNT_MULTIPLIER;

        // init FOUND_TREASURY caps
        addressIndex = getAddressIndex(FOUND_TREASURY);

        _caps[addressIndex][5] = 2500 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][6] = 5000 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][7] = 7500 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][8] = 10000 * AMOUNT_MULTIPLIER;

        // init AG_SHAREHOLDERS caps
        addressIndex = getAddressIndex(AG_SHAREHOLDERS);

        _caps[addressIndex][3] = 625 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][4] = 3880 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][5] = 5500 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][6] = 10380 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][7] = 15250 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][8] = 25000 * AMOUNT_MULTIPLIER;

        // init AG_TEAM caps
        addressIndex = getAddressIndex(AG_TEAM);

        _caps[addressIndex][5] = 1250 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][6] = 2500 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][7] = 3750 * AMOUNT_MULTIPLIER;
        _caps[addressIndex][8] = 5000 * AMOUNT_MULTIPLIER;
    }

    function getAddressIndex(address element) public view returns (uint8) {
        for (uint8 i = 0; i < allowedAddresses.length; i++) {
            if (element == allowedAddresses[i])
                return i;
        }
        return allowedAddressesAmount;
    }
    
    function getStageIndexAt(uint256 timestamp) public view returns (uint8) {
        for (uint8 i = 0; i < _stageDates.length; i++) {
            if (_stageDates[i] > timestamp)
            {
                return --i;
            }
        }
        return stagesAmount - 1;
    }

    function getCurrentStageIndex() public view returns (uint8) {
        return getStageIndexAt(block.timestamp);
    }

    function retrieveTokens(uint256 amount) external returns (bool) {
        uint8 stageIndex = getCurrentStageIndex();
        uint8 addressIndex = getAddressIndex(msg.sender);
        require(addressIndex >= 0 && addressIndex < allowedAddressesAmount, "Address not allowed");
        require(earnedAmount[msg.sender].add(amount) <= _caps[addressIndex][stageIndex], "transfer amount exceeds balance");
        earnedAmount[msg.sender] = earnedAmount[msg.sender].add(amount);
        IERC20 uop_token = IERC20(UOP_token_address);
        return uop_token.transfer(msg.sender, amount);
    }

    function getUopBalance() external view returns (uint256) {
        IERC20 uop_token = IERC20(UOP_token_address);
        return uop_token.balanceOf(address(this));
    }

    function getCapSumAt(uint8 stageIndex) external view returns (uint256) {
        require(stageIndex >= 0 && stageIndex < stagesAmount, "Index out od bound");
        uint256 sum;
        for (uint8 i = 0; i < allowedAddressesAmount; i++) {
            sum += _caps[i][stageIndex];
        }
        return sum;
    }
    
    function getEarnedAmount(address recipient) external view returns (uint256) {
        return earnedAmount[recipient];
    }

    function getCap(address recipient, uint8 stageIndex) external view returns (uint256) {
        uint8 addrIndex = getAddressIndex(recipient);
        require(addrIndex >= 0 && addrIndex < allowedAddressesAmount);
        require(stageIndex >= 0 && stageIndex < stagesAmount, "Index out of bound");
        return _caps[addrIndex][stageIndex];
    }

    function setCap(address recipient, uint8 stageIndex, uint256 amount) external onlyOwner returns (bool) {
        uint8 addrIndex = getAddressIndex(recipient);
        require(addrIndex >= 0 && addrIndex < allowedAddressesAmount, "Address not allowed");
        require(stageIndex >= 0 && stageIndex < stagesAmount, "Index out of bound");
        _caps[addrIndex][stageIndex] = amount;
        return true;
    }

    function revoke(uint256 amount) external onlyOwner returns(bool) {
        IERC20 uop_token = IERC20(UOP_token_address);
        return uop_token.transfer(owner(), amount);
    }
    
    function getStageUnlockTime(uint8 stageIndex) external view returns (uint256) {
        require(stageIndex >= 0 && stageIndex < stagesAmount, "Index out of bound");
        return _stageDates[stageIndex];
    }
}