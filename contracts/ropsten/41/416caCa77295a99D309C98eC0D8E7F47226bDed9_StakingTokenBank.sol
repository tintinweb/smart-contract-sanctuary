pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./tokens/ERC20.sol";
import "./models/staking/StakeData.sol";

contract StakingTokenBank is Ownable, ReentrancyGuard{
    using SafeMath for uint;

    //Token that can be staked(GIVE)
    IERC20 public StakingToken;
    //mapping containing stake data for address
    mapping(address => StakeData) public StakeDatas;
    
    //total staked tokens over all pools
    uint256 public TotalStakedTokens;
    // total staked tokens per pool based on stakingPoolId
    mapping(string => uint256) public TotalStakedPoolTokens;
    
    //Emitted when a stake was successful
    event Staked(address staker, string stakingPoolId, uint256 amount, uint256 entryId);
    //Emitted when a unstake was successful
    event Unstaked(address staker, string stakingPoolId, uint256 amount, uint256 entryId);

    constructor(address stakingToken){
        StakingToken = IERC20(stakingToken);
    }

    /**
     * @dev Stake the given amount in the given staking pool
     * @param stakingPoolId the id of the staking pool
     * @param amount the amount to be staked
     * @param charities percentage setting for charity distribution
    */
    function Stake(string memory stakingPoolId, uint256 amount, StakingPoolEntryCharity[] memory charities) nonReentrant external{
        RequireCharityCheck(charities);
        require(amount > 0, "Cannot stake 0");
        require(StakingToken.allowance(_msgSender(), address(this)) >= amount , "Allowance not set");
        //update all totals
        StakeDatas[_msgSender()].TotalStaked += amount;
        StakeDatas[_msgSender()].StakingPoolDatas[stakingPoolId].TotalStaked += amount;
        TotalStakedPoolTokens[stakingPoolId] += amount;
        TotalStakedTokens += amount;
        //create entry
        uint256 entryId =  StakeDatas[_msgSender()].StakingPoolDatas[stakingPoolId].EntriesIndexer.length.add(1);
        StakeDatas[_msgSender()].StakingPoolDatas[stakingPoolId].EntriesIndexer.push(entryId);
        StakeDatas[_msgSender()].StakingPoolDatas[stakingPoolId].Entries[entryId].EntryDate = block.timestamp;
        StakeDatas[_msgSender()].StakingPoolDatas[stakingPoolId].Entries[entryId].Amount += amount;
        for(uint i=0; i<charities.length; i++)
        {
            StakingPoolEntryCharity memory entryCharity = charities[i];
            StakeDatas[_msgSender()].StakingPoolDatas[stakingPoolId].Entries[entryId].StakingPoolEntryCharities.push(entryCharity);
        }
        StakingToken.transferFrom(_msgSender(), address(this), amount);
        emit Staked(_msgSender(), stakingPoolId, amount, entryId);
    }

    /**
     * @dev Unstake the given amount in the given staking pool
     * @param stakingPoolId the id of the staking pool
     * @param entryId the id of the entry to unstake
    */
    function UnStake(string memory stakingPoolId, uint256 entryId) nonReentrant external{
        require(StakeDatas[_msgSender()].StakingPoolDatas[stakingPoolId].Entries[entryId].EntryDate != 0, "Staking entry does not exist");
        require(StakeDatas[_msgSender()].StakingPoolDatas[stakingPoolId].Entries[entryId].ExitDate == 0, "Already unstaked");
        uint256 amount = StakeDatas[_msgSender()].StakingPoolDatas[stakingPoolId].Entries[entryId].Amount;
        StakeDatas[_msgSender()].StakingPoolDatas[stakingPoolId].Entries[entryId].ExitDate = block.timestamp;
        StakeDatas[_msgSender()].TotalStaked -= amount;
        StakeDatas[_msgSender()].StakingPoolDatas[stakingPoolId].TotalStaked -= amount;
        TotalStakedPoolTokens[stakingPoolId] -= amount;
        TotalStakedTokens -= amount;
        StakingToken.transfer(_msgSender(), amount);
        emit Unstaked(_msgSender(), stakingPoolId, amount, entryId);
    }

    /**
     * @dev Return total amount of tokens staked for address
     * @param staker the address of the staker 
    */
    function GetTotalStakedForAddress(address staker) public view returns(uint256){
        return StakeDatas[staker].TotalStaked;
    }

    /**
     * @dev Returns the total amount of tokens staked for the given address in the given pool
     * @param staker the address of the staker 
     * @param stakingPoolId the id of the staking pool
    */
    function GetTotalStakedInPoolForAddress(address staker, string memory stakingPoolId) public view returns(uint256){
        return StakeDatas[staker].StakingPoolDatas[stakingPoolId].TotalStaked;
    }

    /**
     * @dev returns the stakingpool entries indexer for a given staking pool (this is a list of id's for staking entries in the pool)
     * @param staker the address of the staker 
     * @param stakingPoolId the id of the staking pool
     */
    function GetStakingPoolEntriesIndexer(address staker, string memory stakingPoolId)public view returns(uint256[] memory){
        uint256[] memory result = new uint256[](StakeDatas[staker].StakingPoolDatas[stakingPoolId].EntriesIndexer.length);
        for(uint i=0; i< StakeDatas[staker].StakingPoolDatas[stakingPoolId].EntriesIndexer.length; i++)
        {
            uint256 entryIndex = StakeDatas[staker].StakingPoolDatas[stakingPoolId].EntriesIndexer[i];
            result[i] = entryIndex;
        }
        return result;
    }
    
    /**
     * @dev returns the stakingpool entry for given entry id
     * @param staker the address of the staker 
     * @param stakingPoolId the id of the staking pool
     * @param entryId the id of the staking pool entry
     */
    function GetStakingPoolEntry(address staker, string memory stakingPoolId, uint256 entryId) public view returns(StakingPoolEntry memory){
        return StakeDatas[staker].StakingPoolDatas[stakingPoolId].Entries[entryId];
    }

    /**
     * @dev returns the charity settings for given entry id
     * @param staker the address of the staker 
     * @param stakingPoolId the id of the staking pool
     * @param entryId the id of the staking pool entry
     */
    function GetStakingPoolEntryCharities(address staker, string memory stakingPoolId, uint256 entryId)public view returns(StakingPoolEntryCharity[] memory){
        StakingPoolEntryCharity[] memory result = new StakingPoolEntryCharity[](StakeDatas[staker].StakingPoolDatas[stakingPoolId].Entries[entryId].StakingPoolEntryCharities.length);
        for(uint i=0; i< StakeDatas[staker].StakingPoolDatas[stakingPoolId].Entries[entryId].StakingPoolEntryCharities.length; i++)
        {
            StakingPoolEntryCharity storage charity = StakeDatas[staker].StakingPoolDatas[stakingPoolId].Entries[entryId].StakingPoolEntryCharities[i];
            result[i] = charity;
        }
        return result;
    }

    /**
     * @dev check to see if given charity percentages add up to 100%
     * @param charities give charities 
     */
    function RequireCharityCheck(StakingPoolEntryCharity[] memory charities) private{
        uint256 percentage = 0;
        for(uint i=0; i< charities.length; i++)
        {
            percentage += charities[i].Percentage;
        }
        require(percentage == 100, "Charity percentages do not total 100");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../oracles/EthPrice.sol";

contract ERC20 is EthPrice, Ownable, IERC20 {
    using SafeMath for uint;

    // Token balance
    mapping(address => uint256) private _balances;
    // ETH balance of contract
    mapping(address => uint256) public _ethBalance;
    // Fiat balance of contract
    mapping(address => uint256) public _fiatBalance;
    mapping(address => mapping(address => uint256)) private _allowed;

    // TODO Remove this string ^^
    string private _authToken = "8=Y&vp32c7=U=235B/fEK?Q(p6T<B/dzA:";

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address public contractAddress;

    constructor(string memory tokenName, string memory tokenSymbol, uint256 tokenTotalSupply) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = 18;

        contractAddress = address(this);

        _totalSupply = _totalSupply.add(tokenTotalSupply * 10**_decimals);
        _balances[contractAddress] = _balances[contractAddress].add(_totalSupply); //_msgSender() is now address(this)
        emit Transfer(address(0x0), contractAddress, _totalSupply);
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function tokenPrice() public view returns(uint) {
        // return ethBalance / tokenBalance;
        // in frontend we'll multiply it with current ETH price
        // to get right tokenPrice
        uint256 ethBalance = balanceOfEth();
        uint256 tokenBalance = balanceOf(contractAddress);
        uint256 priceInWei = ethBalance / tokenBalance;

        return priceInWei;
    }

    /**
    * @dev Total number of GIVE tokens in existence
    */
    function totalSupply() public override view returns(uint256) {
        return _totalSupply;
    }

    /**
    * @dev Set AuthToken
    */
    function setAuthToken(string memory authToken) onlyOwner public virtual {
        _authToken = authToken;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view override returns(uint256) {
        return _balances[owner];
    }

    /**
     * @dev Gets the balance of the contract address.
     * @return An uint representing the amount of ETH inside the contract.
    */
    function balanceOfEth() public view returns(uint) {
        return _ethBalance[contractAddress];
    }

    /**
     * @dev Gets the balance of the _msgSender().
     * @return An uint256 representing the fiat amount owned by the _msgSender.
    */
    function fiatBalanceOf() public view returns(uint256) {
        return _fiatBalance[_msgSender()];
    }

    /**
     * @dev Gets the balance of the _msgSender().
     * @return An uint256 representing the amount owned by the passed address.
    */
    function addFiatBalance(uint amount, string memory authToken) public virtual returns(uint256) {
        // TODO Make this call secure
        require(keccak256(abi.encodePacked(_authToken)) == keccak256(abi.encodePacked(authToken)), "Auth token does not match");
        _fiatBalance[_msgSender()] = _fiatBalance[_msgSender()].add(amount);
        return fiatBalanceOf();
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address owner, address spender) public view virtual override returns(uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token for a specified address
     * @param recipient The address to transfer to.
     * @param amount The amount to be transferred.
    */
    function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of _msgSender().
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
    */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param sender address The address which you want to send tokens from
     * @param recipient address The address which you want to transfer to
     * @param amount uint256 the amount of tokens to be transferred
    */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowed[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
    */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowed[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowed[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

pragma solidity ^0.8.3;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract EthPrice {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     * Live: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor() public {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
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

pragma solidity 0.8.4;

struct StakingPoolSettings{
    uint256 PJPercentage;
}

pragma solidity 0.8.4;

struct StakingPoolEntryCharity{
    uint256 CharityId;
    uint256 Percentage;
}

pragma solidity 0.8.4;
import "./StakingPoolEntryCharity.sol";

struct StakingPoolEntry{
    uint256 EntryDate;
    uint256 ExitDate;
    uint256 Amount;
    StakingPoolEntryCharity[] StakingPoolEntryCharities;
}

pragma solidity 0.8.4;
import "./StakingPoolEntry.sol";
import "./StakingPoolSettings.sol";

struct StakingPoolData{
    uint256 TotalStaked;

    uint256[] EntriesIndexer;
    mapping(uint256 => StakingPoolEntry) Entries;
    StakingPoolSettings Settings; 
}

pragma solidity ^0.8.4;

import "./StakingPoolData.sol";

struct StakeData{
    uint256 TotalStaked;
    mapping(string => StakingPoolData) StakingPoolDatas;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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