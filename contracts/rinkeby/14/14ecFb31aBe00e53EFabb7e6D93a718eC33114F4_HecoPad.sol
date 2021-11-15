pragma solidity >=0.5.0 <0.9.0;
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Counters.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
pragma experimental ABIEncoderV2;

import './IHecoPad.sol';
contract HecoPad is IHecoPad, Ownable{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Project indexes
    Counters.Counter private _projectsIds;

    // Exchange fee
    uint256 public EXCHANGE_FEE = 1;//1%

    //List of projects
    mapping(uint => HecoProject) public projects;

    // List of allowed participants
    mapping (uint => mapping (address => uint256)) public whitelists;
    // List of allocated amounts
    mapping (uint => mapping (address => uint256)) public allocatedAmounts;
    // List of claimed amounts
    mapping (uint => mapping (address => uint256)) public claimedAmounts;
    // current sell amount
    mapping (uint =>  uint256) public capProgress;

    /**
     */
    constructor() public{

      
    }

    function setExchangeFee(uint256 newFee) public onlyOwner returns (uint){
        EXCHANGE_FEE = newFee;
        return newFee;
    } 
    /**
    * @dev create a new project for IDO
    * @param start_allocation start first round
    : start project date
    * @param end: end project date
    * @param owner: address of the project's owner
    * @param swap_from_token: the token user to swap owner token(Ex: BUSD)
    * @param swap_to_token: the project's token
    * @param swap_rate: the swap rate
    * @param cap: the total amount in sell
     */
    function setUpProject(
            uint project_id,
            uint256 start_allocation, 
			uint256 end_allocation, //during end_allocation ~ start_fcfs, is just FCFS - Prepare
			uint256 start_fcfs, 
            uint256 end, 
            address owner, 
            address swap_from_token,
            address swap_to_token, 
            uint256 swap_rate,
            uint256 cap
    ) public onlyOwner returns (uint){
        HecoProject memory hecoProject = HecoProject(
            start_allocation, 
			end_allocation, //during end_allocation ~ start_fcfs, is just FCFS - Prepare
			start_fcfs, 
            end,
            owner,
            swap_from_token,
            swap_to_token,
            swap_rate,
            cap
        );
        projects[project_id] = hecoProject;
        emit SetUpProject(project_id, start_allocation, end_allocation, start_fcfs, end, owner, swap_from_token, swap_to_token, swap_rate, cap);
        return project_id;
    }

    /**
    * @dev set a whitelist addresses and related amount for a project
    * @param project_id: the projet index 
    * @param addresses: the whitelist's addresses
    * @param amounts: the whitelist's amounts
     */
    function addWhiteList(uint project_id, address[] memory addresses, uint[] memory amounts) public onlyOwner{
        require(addresses.length == amounts.length, "HecoPad: addresses & amounts must have the same size");
        for (uint i = 0; i < addresses.length; i++) {
            whitelists[project_id][addresses[i]] =  amounts[i];
        }
        emit AddWhiteList(project_id, addresses, amounts);
    }

    /**
    * @dev buy tokens in IDO
    * @param project_id: the projet index 
    * @param amount: the amount to buy
    */
    function buyAllocatedTokens(uint256 project_id, uint256 amount) public{
        require(whitelists[project_id][_msgSender()] > 0, "HecoPad: user not allowed!");
        HecoProject storage hecoProject = projects[project_id];
        require(hecoProject.start_allocation >= now  && now <= hecoProject.end_allocation , "HecoPad: Allocation not started yet or ended!");
        uint256 s_balance = IBEP20(hecoProject.swap_from_token).balanceOf(_msgSender());
        require(s_balance > 0, 'HecoPad: balance must be upper to 0');
        uint256 fee = amount.mul(EXCHANGE_FEE.div(100));
        amount = amount.sub(fee);
        uint256 swap_to_amount = amount.mul(hecoProject.swap_rate);
        IBEP20(hecoProject.swap_from_token).transferFrom(_msgSender(), owner(), fee);
        _exchangeTokens(project_id, amount, swap_to_amount);
        _deceaseParticipantAllowedAmount(project_id, swap_to_amount);
        allocatedAmounts[project_id][_msgSender()] =   allocatedAmounts[project_id][_msgSender()].add(swap_to_amount);
        emit BuyIDOAlloc(project_id, _msgSender(), hecoProject.swap_to_token, amount, capProgress[project_id]);
    } 
    /**
    * @dev buy tokens in IDO
    * @param project_id: the projet index
    * @param amount: the amount to buy
    */
    function buyFCFSTokens(uint256 project_id, uint256 amount) public{
       
        HecoProject storage hecoProject = projects[project_id];
        uint256 s_balance = IBEP20(hecoProject.swap_from_token).balanceOf(_msgSender());
        require(hecoProject.end >= now , "HecoPad: Sell ended!");
        require(hecoProject.start_fcfs >= now  && now <= hecoProject.end , "HecoPad: FCFS not started yet or ended!");
        require(s_balance > 0, 'HecoPad: balance must be upper to 0');
        uint256 fee = amount.mul(EXCHANGE_FEE).div(100);
        amount = amount.sub(fee);
        uint256 swap_to_amount = amount.mul(hecoProject.swap_rate);
        IBEP20(hecoProject.swap_from_token).transferFrom(_msgSender(), owner(), fee);
        _exchangeTokens(project_id, amount, swap_to_amount);
        claimedAmounts[project_id][_msgSender()] =   claimedAmounts[project_id][_msgSender()].add(swap_to_amount);
        emit BuyFCFS(project_id, _msgSender(), hecoProject.swap_to_token, amount, capProgress[project_id]);
    } 

    /**
    * @dev swap ido and project tokens
    * @param amount: the swap from token's amount
    * @param swap_to_amount: the swap to token's amount
     */  
    function _exchangeTokens(uint256 project_id, uint256 amount, uint256 swap_to_amount) public{
        HecoProject storage hecoProject = projects[project_id];
        uint256 user_balance = IBEP20(hecoProject.swap_from_token).balanceOf(_msgSender());
        uint256 owner_balance = IBEP20(hecoProject.swap_from_token).balanceOf(_msgSender());
        require(amount > 0, 'HecoPad: swap_from_amount must be upper to 0');
        require(swap_to_amount > 0, 'HecoPad: swap_to_amount must be upper to 0');
        require(user_balance >= amount, 'HecoPad: buyer non-sufficient funds ');
        require(owner_balance >= swap_to_amount, 'HecoPad: owner non-sufficient funds');
        require(capProgress[project_id].add(amount) <= hecoProject.cap,"hecoPad: Cap market achieved Sells ended");
        IBEP20(hecoProject.swap_from_token).transferFrom(_msgSender(), hecoProject.owner, amount);
        IBEP20(hecoProject.swap_to_token).transferFrom(hecoProject.owner, _msgSender(), swap_to_amount);
        capProgress[project_id] = capProgress[project_id].add(amount);

    }

    /**
    * @dev decrease token's amount in sell
    * @param hecoProject: the project object
    * @param amount: the amount to decease
     */
    function _decreaseCap(HecoProject storage hecoProject,uint256 amount) internal{
        hecoProject.cap = hecoProject.cap.sub(amount);
    }

    /**
    * @dev decrease participant allowed amount
    * @param amount: the amount to decease
    * @param project_id: the project index
     */
    function _deceaseParticipantAllowedAmount(uint256  project_id, uint256 amount) internal{
        whitelists[project_id][_msgSender()] =  whitelists[project_id][_msgSender()].sub(amount);
    }
    /**
    * @dev get exchange fee 
     */
    function exchangeFee() public view returns(uint256){
        return EXCHANGE_FEE;
    } 
}

pragma solidity >=0.5.0 <0.9.0;

interface IHecoPad{
    struct HecoProject{
        uint256 start_allocation;
		uint256 end_allocation;
		uint256 start_fcfs; 
        uint256 end;
        address owner;
        address swap_from_token;
        address swap_to_token;
        uint256 swap_rate;
        uint256 cap;
    }
    struct Whitelist{
        uint project;
        address[] addresses;
        uint[] amounts;
    }
    event SetUpProject(
        uint project_id, 
        uint256 start_allocation, 
        uint256 end_allocation, 
        uint256 start_fcfs,
        uint256 end, 
        address owner, 
        address swap_from_token, 
        address swap_to_token, 
        uint256 swap_rate, 
        uint256 cap
    );
    event AddWhiteList(uint project_id, address[] addresses, uint[] amounts);
    event BuyIDOAlloc(uint project_id, address buyer, address ido, uint256 amount,uint256 capProgress);
    event BuyFCFS(uint project_id, address buyer, address ido, uint256 amount,uint256 capProgress);

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

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

