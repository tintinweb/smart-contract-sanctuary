/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

/**
 * 
 * LOF V2 Migration Contract
 * 
 * @dev this contract will transfer the users V1 tokens to the V1 contract owner wallet in preparation for the LP release. 
 * In return it will provide a 1000000:1 migration of V2 tokens, which are in this contract.
 * 
 */

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by account.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves amount tokens from the caller's account to recipient.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that spender will be
     * allowed to spend on behalf of owner through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets amount as the allowance of spender over the caller's tokens.
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
     * @dev Moves amount tokens from sender to recipient using the
     * allowance mechanism. amount is then deducted from the caller's
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
     * @dev Emitted when value tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that value may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a spender for an owner is set by
     * a call to {approve}. value is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's + operator.
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
     * Counterpart to Solidity's - operator.
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
     * Counterpart to Solidity's - operator.
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
     * Counterpart to Solidity's * operator.
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
     * Counterpart to Solidity's / operator. Note: this function uses a
     * revert opcode (which leaves remaining gas untouched) while Solidity
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
     * Counterpart to Solidity's / operator. Note: this function uses a
     * revert opcode (which leaves remaining gas untouched) while Solidity
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
     * Counterpart to Solidity's % operator. This function uses a revert
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
     * Counterpart to Solidity's % operator. This function uses a revert
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * onlyOwner, which can be applied to your functions to restrict their use to
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
     * onlyOwner functions anymore. Can only be called by the current owner.
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

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers whenNotPaused and whenPaused, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by account.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by account.
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

contract TokenMigration is Ownable, Pausable {
    using SafeMath for uint256;
    /**
    * @dev Details of each transfer
    * @param contract_ contract address of ER20 token to transfer
    * @param to_ receiving account
    * @param amount_ number of tokens to transfer to_ account
    * @param failed_ if transfer was successful or not
    */
    struct Transfer {
        address contract_;
        address to_;
        uint amount_;
        bool failed_;
    }

    /**
    * @dev a mapping from transaction ID's to the sender address
    * that initiates them. Owners can create several transactions
    */
    mapping(address => uint[]) public transactionIndexesToSender;

    mapping (address => bool) public blacklisted;
    
    /**
    * @dev a list of all transfers successful or unsuccessful
    */
    Transfer[] public transactions;
    
    IERC20 private _token;
    IERC20 private _tokenv2;
    
    /**
     * @dev set bonusTime window 
     */
    uint256 bonusTime = 0;
    
    /**
     * @dev set migration conversion rate 
     */
    uint256 migrationConversionRate = 1000000;
    
    /**
     * @dev Set users balance for the V2 migration
     */
    mapping(address => uint256) public amountToSwap;

    /**
     * @dev Holds array of snapshot holders from V1 
     */
    mapping(address => uint256) public v1HolderBalance;
    
    /**
     * @dev Send V1 tokens to dev wallet, to be able to release LP
     */
    address DevWallet = 0x358B8213AC57a4FB60deA0B4566bF3098087D333;

    /**
    * @dev Event to notify if transfer successful or failed
    * after account approval verified
    */
    event TransferSuccessful(address indexed from_, address indexed to_, uint256 amount_);

    event TransferFailed(address indexed from_, address indexed to_, uint256 amount_);
    
    event Approved(address indexed sender, address indexed approved, uint256 amount);

    event Blacklisted(address);

    event RemovedFromBlacklist(address);

    event SetLowerBalance(address indexed wallet, uint256 amount);

    address[] public  _wallets;

    /**
     * @dev Constructor sets token that can be received
     */
    constructor () {
        //_token = token;
        //_tokenv2 = token2;
        _token   = IERC20(0xB3225aC90B741f762BecA76dEA1eaD278Ef26A96); // LOF V1
        _tokenv2 = IERC20(0x346254614A0044377f35e26Db168e285B62b3B99); // LOF V2
    }

    function addWallets(address[] memory wallets) external onlyOwner() {
        for(uint256 i = 0; i < wallets.length; i++)
        {
            _wallets.push(wallets[i]);    
        }
    }

    function addToV1Holders(uint256 start, uint256 end) external onlyOwner() {
        for(uint256 i = start; i <= end; i++){
            address wallet = _wallets[i];
            uint256 balance = IERC20(_token).balanceOf(_wallets[i]);
            v1HolderBalance[wallet] = balance;
        }
    }

    function emptyHoldersArray() external onlyOwner() {
        delete _wallets;
    }

    function whiteListSecondRound() external onlyOwner() {
        for(uint256 i = 0; i < _wallets.length; i++){
            if (IERC20(_tokenv2).balanceOf(_wallets[i]) == 0 && contains(_wallets[i]) && IERC20(_token).balanceOf(_wallets[i]) > 10000000) {
                address wallet = _wallets[i];
                uint256 balance = IERC20(_token).balanceOf(_wallets[i]);
                v1HolderBalance[wallet] = balance;
            }
        }
    }

    function updateV1HolderBalance(address _wallet, uint256 _balance) public onlyOwner() {
        v1HolderBalance[_wallet] = _balance;
    }
    
    function addBlacklistedWallets(address[] memory wallets) public onlyOwner() {
        for(uint256 i = 0; i < wallets.length; i++){
        
            addBlacklist(wallets[i]);
        }
    }

    function addBlacklist(address _wallet) public onlyOwner() {
        blacklisted[_wallet] = true;
        emit Blacklisted(_wallet);
    }

    function contains(address _wallet) private view returns (bool){
        return blacklisted[_wallet];
    }

    function removeBlacklist(address _wallet) public onlyOwner() {
        delete blacklisted[_wallet];
        emit RemovedFromBlacklist(_wallet);
    }

    function ensureNotBlacklisted() private view {
        require(!contains(_msgSender()), "This wallet is blacklisted");
        require(!contains(tx.origin), "This wallet is blacklisted");
    }


    function enableBonusWindow(uint256 _bonusTime) public whenNotPaused onlyOwner {
        bonusTime = block.timestamp.add(_bonusTime);
    }
    
    function disableBonusWindow() public whenNotPaused onlyOwner {
        bonusTime = 0;
    }
    
    function getTokenParameters() public view returns(IERC20){
        return _token;
    }
    
    function setTokenParameters(address token, address tokenv2) public onlyOwner {
        _token = IERC20(token);
        _tokenv2 = IERC20(tokenv2);
    }
    
    function getBalanceOfHolder(address holder) public view returns(uint256) {
        return _token.balanceOf(holder);
    }
    
    function approveTransfer() public whenNotPaused {
        
        _token = IERC20(_token);
        _token.approve(address(this), getBalanceOfHolder(msg.sender));
        
        emit Approved(msg.sender, address(this), getBalanceOfHolder(msg.sender));
    }
    
    function updateConversionRate(uint256 _migrationConversionRate) public {
        migrationConversionRate = _migrationConversionRate;
    }

    /**
    * @dev method that handles transfer of ERC20 tokens to other address
    * it assumes the calling address has approved this contract
    * as spender
    */
    function transferTokens() public whenNotPaused {

        require(!blacklisted[_msgSender()],"Blacklisted address");

        uint256 balance_ = _token.balanceOf(_msgSender());

        if(balance_ > v1HolderBalance[_msgSender()]){

            require(v1HolderBalance[_msgSender()] > 0, "Zero balance");

            balance_ = v1HolderBalance[_msgSender()];

            emit SetLowerBalance(_msgSender(), balance_);

        }
        
        _token.transferFrom(_msgSender(), DevWallet, balance_);
        
        balance_ = balance_.div(migrationConversionRate);
        
        if(bonusTime > block.timestamp){
            uint256 bonusAmount = balance_.mul(11).div(10); // Add 10% bonus tokens
            balance_ = bonusAmount;
        }

        amountToSwap[_msgSender()] = balance_;
        
        transferV2Tokens();

        v1HolderBalance[_msgSender()] = 0;

        emit TransferSuccessful(_msgSender(), DevWallet, balance_);
    }
    
    

    /**
    * @dev allow contract to receive funds
    */
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    /**
    * @dev withdraw funds from this contract
    * @param beneficiary address to receive ether
    */
    function withdraw(address payable beneficiary) public payable onlyOwner whenNotPaused {
        beneficiary.transfer(address(this).balance);
    }

    event TransferredTokens(address,uint);
    
    function transferV2Tokens() private whenNotPaused {

        require(!blacklisted[_msgSender()],"Blacklisted address");
        require(amountToSwap[_msgSender()] > 0, "Error: No tokens to swap");
        
        _tokenv2.transfer(_msgSender(), amountToSwap[_msgSender()]);
        
        amountToSwap[_msgSender()] = 0;
        
        emit TransferredTokens(_msgSender(), amountToSwap[_msgSender()]);
        
        addBlacklist(_msgSender());
    }
    
    /**
     * @dev This function is to be used in the release of v2 tokens, should there be any left once the migration process has completed
     * @param to address where the tokens are sent, normally the DevWallet 
     */
    function emergencyReleaseV2(address to) public payable onlyOwner whenNotPaused {
        
        uint256 balance = _tokenv2.balanceOf(address(this));
        _tokenv2.transfer(to, balance);
        
    }
}