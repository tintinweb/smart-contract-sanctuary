/**
 *Submitted for verification at snowtrace.io on 2022-01-25
*/

// File: contracts/Interfaces/IFactory.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IFactory {
    function getSupply() 
        external 
        view 
        returns(uint256);

    function getTokenPrice()
        external
        view
        returns(uint256);

    function getPriceTo(address _buyercollector) 
        external 
        view 
        returns(uint256);

    function setPriceTo(address _buyercollector, uint256 _price)
        external;

    function getCounter() 
        external 
        view 
        returns(uint256);
        
    function mintTo(address _to) 
        external 
        returns(uint256);

    function getBalanceOf(address _collector) 
        external 
        view 
        returns(uint256);

    function getOwnerOf(uint256 token_id) 
        external 
        view 
        returns(address);
        
    function collectionOf(address _collector) 
        external
        view 
        returns(uint256[] memory);

    function getVestingPeriodEndOf(uint256 token_id)
        external
        view
        returns(uint256);

    function isVestingPeriodCompletedAt(uint256 token_id)
        external 
        view
        returns(bool);

    function getAmountOwedAt(uint256 token_id)
        external
        view
        returns(uint256);

    function validatePayoutAt(uint256 token_id)
        external
        returns(bool);
}
// File: contracts/Interfaces/IRewards_token.sol


pragma solidity >=0.8.0;

interface IRewardsToken {
    function mint(address _to, uint _amount) 
        external;

    function unstake(address _stakeholder, uint _amount) 
        external
        returns(bool);

    function setLittleFaithFor(address _user)
        external;

    function setThemEatCakeFor(address _user)
        external;
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: contracts/Interfaces/IStaking_token.sol


pragma solidity >=0.8.0;


interface IStakingToken is IERC20{
    function calculateRewards(address _stakeholder)
        external
        view
        returns(uint256);
        
    function setStakingMultiplierOf(address _stakeholder, uint256 _level) 
        external;

    function mintPayable(address _to, uint _amount)
        external;

    function setRewardsPeriodStart(address _stakeholder) 
        external;

    function createStakeTo(address _stakeholder, uint256 _amount)
        external;
        
    function multiplierOf(address _stakeholder)
        external
        view
        returns(uint256);

    function getBalanceOf(address _account)
        external
        view
        returns(uint256);
}
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/Treasury.sol


pragma solidity >=0.8.0;






contract Treasury is Ownable {
    using SafeMath for uint256;

    string public name = "Magnus DAO Treasury";

    event onFactory(uint256 _mintcode, address buyer, uint256 token_id);

    /**
    * @notice The address of the staking token contract instance.
    */
    address public stakingTokenAddr;

    /**
    * @notice A method to set stakingTokenAddr.
    * @param _address The address that stakingTokenAddr will be set to.
    */
    function setStakingTokenAddress(address _address)
        external
        onlyOwner
    {
        stakingTokenAddr = _address;
    }

    /**
    * @notice The address of the rewards token contract instance.
    */
    address public rewardsTokenAddr;

    /**
    * @notice A method to set rewardsTokenAddr.
    * @param _address The address that rewardsTokenAddr will be set to.
    */
    function setRewardsTokenAddress(address _address)
        external
        onlyOwner
    {
        rewardsTokenAddr = _address;
    }

    /**
    * @notice The address of each factory contract instance.
    */
    mapping(uint256 => address) public factories;

    /**
    * @notice A [RESTRICTED] method to store the address of a factory contract instance.
    * @param _mintcode The factory to store the contract instance address for.
    * @param _address  The address that will be stored.
    */
    function setFactoryAddress(uint256 _mintcode, address _address)
        external
        onlyOwner
    {
        factories[_mintcode] = _address;
    }

    /**
    * @notice A method to get the address of a factory contract instance.
    * @param _mintcode The factory to get the contract instance address for.
    */
    function factoryAddressOf(uint256 _mintcode)
        public
        view
        returns(address)
    {
        return factories[_mintcode];
    }

    /**
    * @notice The locked/unlocked state of the special ability for each mintcode for each user.
    */
    mapping(address => mapping(uint256 => bool)) public abilities;

    /**
    * @notice A method to check if a user has a specific ability.
    * @param _user The user to query.
    * @param _ability The ability/mintcode to query.
    * @return bool Whether the user has the ability.
    */
    function hasAbilityOf(address _user, uint256 _ability)
        public
        view
        returns(bool)
    {
        return abilities[_user][_ability];
    }

    /**
    * @notice A method to set the locked/unlocked state of a special ability for a mintcode for a user.
    * @param _user The user to query.
    * @param _ability The ability/mintcode to query.
    * @param _isUnlocked The state the ability/mintcode key will be set to.
    */
    function setAbilityOf(address _user, uint256 _ability, bool _isUnlocked)
        private
    {
        abilities[_user][_ability] = _isUnlocked;
    }

    /**
    * @notice The current game number.
    */
    uint256 public gameNumber;

    /**
    * @notice A [RESTRICTED] method to set the current game number.
    * @param _number The new game number that will be set.
    */
    function setGameNumber(uint256 _number)
        external
        onlyOwner
    {
        gameNumber = _number;
    }

    /**
    * @notice The constructor for the Treasury.
    */
    constructor()
    {

    }

    /**
    * @notice A method to process buy orders by type.
    * @param _mintcode The mintcode for which type of token to buy (Pawn is 0, Knight is 1, Bishop is 2...).
    * @return uint256  The token id of the newly minted token.
    */
    function delegateCall(uint256 _mintcode) 
        payable 
        external 
        returns(uint256)
    {
        address buyer = msg.sender;
        uint256 paid  = msg.value;

        return buyerFor(_mintcode, buyer, paid);
    }

    function buyerFor(uint256 _mintcode, address _buyer, uint256 _paid)
        private
        returns(uint256)
    {
        require(validate(_mintcode), "mintcode is not valid.");
        require(IFactory(factoryAddressOf(_mintcode)).getCounter() < IFactory(factoryAddressOf(_mintcode)).getSupply(), "Sold out.");
        require(IFactory(factoryAddressOf(_mintcode)).getBalanceOf(_buyer) < 10, "Max 10 per buyer.");
        require(IFactory(factoryAddressOf(_mintcode)).getPriceTo(_buyer) == _paid, "Paid the wrong amount.");

        uint256 id = IFactory(factoryAddressOf(_mintcode)).mintTo(_buyer);

        applyAbilitiesOf(_mintcode, _buyer);

        emit   onFactory(_mintcode, _buyer, id);
        return id;
    }

    function addGlobalMintDiscountFor(address _staker, uint256 _stakingLevel)
        external
    {
        require(msg.sender == rewardsTokenAddr || msg.sender == stakingTokenAddr, "addGlobalMintDiscountFor: Not authorized.");

        uint256 mul = 100;
        if(_stakingLevel == 2) mul = 95;
        if(_stakingLevel == 3) mul = 75;
        if(_stakingLevel == 4) mul = 50;
        if(_stakingLevel == 5) mul = 25;

        for (uint256 i = 1; i < 7; i++) {
            //cast discount against base price (disregards any previously applied mint discounts)
            uint256 newPrice = (IFactory(factoryAddressOf(i)).getTokenPrice().div(100)).mul(mul);

            IFactory(factoryAddressOf(i)).setPriceTo(_staker, newPrice);
        }

        //reapply previously applied mint discounts

        //"Pawn Promotion"
        if(hasAbilityOf(_staker, 1)) {
            if(gameNumber > 6) {
                uint256 newprice = (IFactory(factoryAddressOf(5)).getPriceTo(_staker).div(100)).mul(25);
                IFactory(factoryAddressOf(5)).setPriceTo(_staker, newprice);
            }
        }
        //"The Knight Fork"
        if(hasAbilityOf(_staker, 2)) {
            uint256 newpriceBishop = (IFactory(factoryAddressOf(3)).getPriceTo(_staker).div(100)).mul(70);
            uint256 newpriceRook   = (IFactory(factoryAddressOf(4)).getPriceTo(_staker).div(100)).mul(70);

            IFactory(factoryAddressOf(3)).setPriceTo(_staker, newpriceBishop);
            IFactory(factoryAddressOf(4)).setPriceTo(_staker, newpriceRook);
        }
        //"Castling"
        if(hasAbilityOf(_staker, 4)) {
            if(gameNumber > 2) {
                uint256 newprice = (IFactory(factoryAddressOf(6)).getPriceTo(_staker).div(100)).mul(85);
                IFactory(factoryAddressOf(6)).setPriceTo(_staker, newprice);
            }
        }
        //"Accross the Board"
        if(hasAbilityOf(_staker, 5)) {
            for (uint256 i = 1; i < 7; i++) {
                uint256 newPrice = (IFactory(factoryAddressOf(i)).getPriceTo(_staker).div(100)).mul(75);

                IFactory(factoryAddressOf(i)).setPriceTo(_staker, newPrice);
            }
        }
    }

    function applyAbilitiesOf(uint256 _mintcode, address _buyer)
        private
    {
        if(!hasAbilityOf(_buyer, _mintcode)) {
            //activates "The Knight Fork"
            if(_mintcode == 2) {
                uint256 newpriceBishop = (IFactory(factoryAddressOf(3)).getPriceTo(_buyer).div(100)).mul(70);
                uint256 newpriceRook   = (IFactory(factoryAddressOf(4)).getPriceTo(_buyer).div(100)).mul(70);

                IFactory(factoryAddressOf(3)).setPriceTo(_buyer, newpriceBishop);
                IFactory(factoryAddressOf(4)).setPriceTo(_buyer, newpriceRook);

                setAbilityOf(_buyer, _mintcode, true);
            }
            //activates "O Ye of Little Faith"
            if(_mintcode == 3) {
                IRewardsToken(rewardsTokenAddr).setLittleFaithFor(_buyer);

                setAbilityOf(_buyer, _mintcode, true);
            }
            //activates "Accross the Board"
            if(_mintcode == 5) {
                for (uint256 i = 1; i < 7; i++) {
                     uint256 newPrice = (IFactory(factoryAddressOf(i)).getPriceTo(_buyer).div(100)).mul(75);

                     IFactory(factoryAddressOf(i)).setPriceTo(_buyer, newPrice);
                }
                setAbilityOf(_buyer, _mintcode, true);
            }
            //activates "Let Them Eat Cake"
            if(_mintcode == 6) {
                IRewardsToken(rewardsTokenAddr).setThemEatCakeFor(_buyer);

                setAbilityOf(_buyer, _mintcode, true);
            }
        }
    }

    function activateAbilitiesOf(uint256 _mintcode, uint256 token_id)
        external
    {
        require(validate(_mintcode), "mintcode is not valid.");
        require(IFactory(factoryAddressOf(_mintcode)).getOwnerOf(token_id) == msg.sender, "Not the owner.");

        //activates "Pawn Promotion"
        if(_mintcode == 1) {
            require(!hasAbilityOf(msg.sender, _mintcode), "Ability is already active.");
            require(gameNumber > 6,  "Ability cannot be activated until after Game 6.");

            uint256 newprice = (IFactory(factoryAddressOf(5)).getPriceTo(msg.sender).div(100)).mul(25);
            IFactory(factoryAddressOf(5)).setPriceTo(msg.sender, newprice);

            setAbilityOf(msg.sender, _mintcode, true);
        }
        //activates "Castling"
        if(_mintcode == 4) {
            require(!hasAbilityOf(msg.sender, _mintcode), "Ability is already active.");
            require(gameNumber > 2,  "Ability cannot be activated until after Game 2.");

            uint256 newprice = (IFactory(factoryAddressOf(6)).getPriceTo(msg.sender).div(100)).mul(85);
            IFactory(factoryAddressOf(6)).setPriceTo(msg.sender, newprice);

            setAbilityOf(msg.sender, _mintcode, true);
        }
    }

    function executePayoutFor(uint256 _mintcode, uint256 token_id)
        external
    {
        require(validate(_mintcode), "mintcode is not valid.");
        require(IFactory(factoryAddressOf(_mintcode)).getOwnerOf(token_id) == msg.sender, "Not the owner.");
        require(IFactory(factoryAddressOf(_mintcode)).isVestingPeriodCompletedAt(token_id), "Vesting period not completed.");

        uint256 amount = IFactory(factoryAddressOf(_mintcode)).getAmountOwedAt(token_id);
        require(amount > 0, "Debt is 0.");

        //clear debt at token id
        require(IFactory(factoryAddressOf(_mintcode)).validatePayoutAt(token_id), "Payout validation failed.");

        //pay 
        IRewardsToken(rewardsTokenAddr).mint(msg.sender, amount);
    }

    function balanceOf(uint256 _mintcode, address _collector)
        external
        view
        returns(uint256)
    {
        require(validate(_mintcode), "mintcode is not valid.");
        return IFactory(factoryAddressOf(_mintcode)).getBalanceOf(_collector);
    }

    function collectionOf(uint256 _mintcode, address _collector)
        public
        view
        returns(uint256[] memory)
    {
        require(validate(_mintcode), "mintcode is not valid.");
        return IFactory(factoryAddressOf(_mintcode)).collectionOf(_collector);
    }

    function vestingPeriodEndOf(uint256 _mintcode, uint256 token_id)
        public
        view
        returns(uint256)
    {
        require(validate(_mintcode), "mintcode is not valid.");
        return IFactory(factoryAddressOf(_mintcode)).getVestingPeriodEndOf(token_id);
    }

    function isVestingCompleted(uint256 _mintcode, uint256 token_id)
        public
        view
        returns(bool)
    {
        require(validate(_mintcode), "mintcode is not valid.");
        return IFactory(factoryAddressOf(_mintcode)).isVestingPeriodCompletedAt(token_id);
    }

    function getPriceFor(uint256 _mintcode)
        external
        view
        returns(uint256)
    {
        require(validate(_mintcode), "mintcode is not valid.");
        return IFactory(factoryAddressOf(_mintcode)).getPriceTo(msg.sender);
    }

    function multiplierOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return IStakingToken(stakingTokenAddr).multiplierOf(_stakeholder);
    }

    function validate(uint256 _mintcode)
        public
        view
        returns(bool)
    {
        return factories[_mintcode] != address(0x0);
    }

    /**
    * @notice A [RESTRICTED] method to withdraw native.
    * @param _amount The amount of native to withdraw.
    */
    function withdraw(uint256 _amount)
        external
        onlyOwner
    {
        require(_amount <= address(this).balance);

        address payable to = payable(msg.sender);        
        to.transfer(_amount);                                        
    }
}