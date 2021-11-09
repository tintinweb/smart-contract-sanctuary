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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./core/OwnerPausable.sol";

contract BSCPlayGroundPresale is Ownable, OwnerPausable
{
    using SafeMath for uint256;

    struct Beneficiary
    {
        uint256 deposited;
        uint256 claimed;
    }

    uint256 public tokensAmount = 3000000 * 10**18; // 3 000 000 
    uint256 public hardCap = 40 * 10**18; // 40 bnb
    uint256 public minContribution = 1 * 10**17; // 0.1 bnb
    uint256 public maxContribution = 2 * 10**18;  // 2 bnb
    
    uint256 public tokensPerBNB; 
    uint256 public receivedAmount;

    uint256 constant public vestingPeriod = 3 minutes; 
    uint8 constant public vestingUnlockProcent = 20; // 20%
    uint8 constant public listingUnlockProcent = 20; // 20%

    bool public whiteListEnabled = true;
    bool public finilized = false;

    uint256 private _finilizedTime;
    
    bool private notPurchasedTokenClaimed = false;

    mapping(address => bool) private whiteList;
    mapping(address => Beneficiary) private _beneficiary;

    IERC20 public token;

    event StartPresale();
    event Finilized();
    event Claimed(uint256 amount, address indexed sender );
    event Deposited(uint256 amount, uint256 deposited, address indexed sender); 

    constructor( address token_)
    {
        if(token_ != address(0))
            token = IERC20(token_);
       
        tokensPerBNB = tokensAmount.div(hardCap);
        _pause();
    }

    function depositedFrom(address owner) external view returns(uint256){
        return _beneficiary[owner].deposited;
    }

    function availableToClaim(address owner) external view returns(bool){
        Beneficiary storage beneficiary = _beneficiary[owner];
        uint256 tokens = calculateWithdrawTokens(owner);
        return tokens.sub(beneficiary.claimed) > 0;
    }

    function nextUnlockTime() external view returns(uint256){
        require(saleFinilized(), 'Sale should be finilized.');
        
        uint8 procent = listingUnlockProcent;
        uint256 nextUnlock = _finilizedTime;

         while(procent < 100) 
        {
            nextUnlock = nextUnlock.add(vestingPeriod);
            if(block.timestamp < nextUnlock)
                break;

            procent += vestingUnlockProcent;
        }

        return nextUnlock;
    }

    function saleStarted() public view returns(bool){
        return !paused() && !finilized;
    }

     function saleFinilized() public view returns(bool){
        return paused() && finilized;
    }

    // PRESALE DETAILS
    function startPresale() external onlyOwner{
        require(!saleStarted());
        _unpause();
        emit StartPresale();
    }

    function updateTokenContract(address contract_) external onlyOwner{
        require(!saleFinilized());
        require(address(token) != contract_);
        token = IERC20(contract_);
    }

    function updateTokensAmount(uint256 value) external onlyOwner{
        require(!saleFinilized());
        require(value > 0);
        require(tokensAmount != value);
        
        tokensAmount = value;
        updateTokenPerBNB();
    }

    function updateMaxContribution(uint256 value) external onlyOwner{
        require(!saleFinilized());
        require(value > 0);
        require(receivedAmount == 0);
        require(maxContribution != value);
        
        maxContribution = value;
    }

    function updateMinContribution(uint256 value) external onlyOwner{
        require(!saleFinilized());
        require(value > 0);
        require(receivedAmount == 0);
        require(minContribution != value);
        
        minContribution = value;
    }

    function updateHardCap(uint256 value) external onlyOwner{
        require(!saleFinilized());
        require(value > 0);
        require(value > receivedAmount);
        require(hardCap != value);

        hardCap = value;
        updateTokenPerBNB();
    }

    function updateTokenPerBNB() private {
        tokensPerBNB = tokensAmount.div(hardCap);
    }
  
    // WHITE LIST FUNCTIONS
    function changeWhiteListState(bool state) external onlyOwner{
        require(whiteListEnabled != state);
        whiteListEnabled = state;
    }

    function addToWhiteList(address[] memory addresses) external onlyOwner{
        require(whiteListEnabled, 'Whitelist is not enabled.');
        require(addresses.length > 0);
        for(uint index = 0; index < addresses.length; index++){
            whiteList[addresses[index]] = true;
        }
    }

    function removeFromWhiteList(address addresses) external onlyOwner{
        require(whiteList[addresses]);
        whiteList[addresses] = false;
    }

    function whitelistedAddress(address owner) public view returns(bool isWhitelisted){
        return whiteList[owner];
    }


    // PRESALE FUNCTIONS
    function deposit() external payable returns(bool success){
        require(saleStarted());
        require(!saleFinilized());
        require(msg.value > 0);
        require(receivedAmount < hardCap, 'Hard Cap is already received.');
        require(receivedAmount.add( msg.value ) <= hardCap, 'Received Amount cannot be greater then Hard Cap.');

        if(whiteListEnabled) 
            require(whitelistedAddress(msg.sender), 'Whitelist hasn`t this address. ');

        address sender = msg.sender;
        uint256 value = msg.value;

        Beneficiary storage beneficiary = _beneficiary[sender];
        uint256 amount = beneficiary.deposited.add(value);
        
        require(amount >= minContribution && amount <= maxContribution, 'The contribution must be greater than minContribution and less then maxContribution.');

        beneficiary.deposited = amount;
        receivedAmount = receivedAmount.add(value);

        emit Deposited(receivedAmount, value, sender);
        return true;
    }

    function finilize() external onlyOwner{
        require(saleStarted());
        require(!saleFinilized(), 'Already finilized');
        
        finilized = true;
        _finilizedTime = block.timestamp;
        _pause();
        
        emit Finilized();
    }

    function reclaimTokens() external returns(bool success){
        require(saleFinilized(), 'Private sale is not finilaze');

        address sender = msg.sender;
        Beneficiary storage beneficiary = _beneficiary[sender];
        require(beneficiary.deposited > 0 ,'This address did not feel in the presale.');

        uint256 tokens = calculateWithdrawTokens(sender);
        tokens = tokens.sub(beneficiary.claimed);
        require(tokens > 0, "No Tokens Available.");

        beneficiary.claimed = beneficiary.claimed.add(tokens);
        token.transfer(sender, tokens);
        
        emit Claimed(tokens, sender);
        return true;
    }

    function calculateWithdrawTokens(address sender) private view returns (uint256)
    {
        if(!saleFinilized())
            return 0;

        Beneficiary storage beneficiary = _beneficiary[sender];
        if(beneficiary.deposited == 0)
            return 0;

        uint256 allTokens = tokensPerBNB.mul(beneficiary.deposited); // All tokens for beneficiary
        uint256 withdraw = allTokens.mul(listingUnlockProcent).div(100); // TGE unlock tokens
        uint256 nextUnlock = _finilizedTime;
        uint8 procent = listingUnlockProcent;

        while(procent < 100) 
        {
            nextUnlock = nextUnlock.add(vestingPeriod);
            if(block.timestamp < nextUnlock)
                break; 

            withdraw = withdraw.add(allTokens.mul(vestingUnlockProcent).div(100));
            procent += vestingUnlockProcent;
        }

        return withdraw;
    }

    function reclaimNotPurchasedTokens() external onlyOwner{
        require(saleFinilized(), 'Private sale is not finilaze');
        require(receivedAmount < hardCap, 'All tokens purchased');
        require(!notPurchasedTokenClaimed, 'Tokens already claimed');

        uint256 leftBNB = hardCap.sub(receivedAmount);
        uint256 leftTokens = tokensPerBNB.mul(leftBNB);
            
        notPurchasedTokenClaimed = true;
        token.transfer(owner(), leftTokens);
    }

    function reclaimEther() external onlyOwner {
        assert( payable(owner()).send( address(this).balance ));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract OwnerPausable is Pausable, Ownable
{
    
    function _pause() internal override onlyOwner {
        super._pause();
    }

    function _unpause() internal override onlyOwner {
        super._unpause();
    }
}