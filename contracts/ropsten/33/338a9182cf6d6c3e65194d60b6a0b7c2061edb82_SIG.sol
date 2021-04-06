/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

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
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
        require(m != 0, "SafeMath: to ceil number shall not be zero");
        return (a + m - 1) / m * m;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only allowed by owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

interface IStaking{
    function disburse(uint256 amount) external;
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract SIG is IERC20, Owned {
    using SafeMath for uint256;
   
    string public symbol = "SIG";
    string public  name = "SIGMAX Platform";
    uint256 public decimals = 18;
    
    uint256 _totalSupply = 1000000 * 10 ** (decimals);
    
    uint256 transactionCost = 2; // 2%
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    mapping(address => locking) locked;

    struct locking{
        uint256 initial;
        uint256 locked;
        uint256 cliff;
        uint256 unlockAmt;
        uint256 unlockPeriod;
    }
    
    address projectDevFund = 0xE58A34f524eEBb396C124B28EE2f41Cf0b77E362;
    address DAOFund = 0xE2C707559f0cbB82Ca9bC078E5B6c7522FF1d314;
    address stakingAdd;
   
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        
        balances[owner] =  455000 * 10 ** (decimals); // 455000
        emit Transfer(address(0), owner, 455000 * 10 ** (decimals));
        
        balances[0x46D6933875c8f8937f8de644f4c75b879AC85abF] =   100000  * 10 ** (decimals); // 100,000
        emit Transfer(address(0), 0x46D6933875c8f8937f8de644f4c75b879AC85abF, 100000  * 10 ** (decimals));
        
        balances[0x401d6C6fFC28db4c43C0b52E7AF1F8A607576842] =   250000  * 10 ** (decimals); // 250,000
        emit Transfer(address(0), 0x401d6C6fFC28db4c43C0b52E7AF1F8A607576842, 250000  * 10 ** (decimals));
        
        balances[0x9020738c7F5D3d644f08126984ddE7C0E3316eb0] =   50000  * 10 ** (decimals); // 50,000
        emit Transfer(address(0), 0x9020738c7F5D3d644f08126984ddE7C0E3316eb0, 100000  * 10 ** (decimals));
        
        balances[0xE2C707559f0cbB82Ca9bC078E5B6c7522FF1d314] =   50000  * 10 ** (decimals); // 50,000
        emit Transfer(address(0), 0xE2C707559f0cbB82Ca9bC078E5B6c7522FF1d314, 100000  * 10 ** (decimals));
        
        balances[0x85d4dA3C43c7a6E55810478ad22f80a35f75f6e1] =   20000  * 10 ** (decimals); // 20,000
        emit Transfer(address(0), 0x85d4dA3C43c7a6E55810478ad22f80a35f75f6e1, 20000  * 10 ** (decimals));
        
        balances[0x64a1482Cc50d019C3372c4462fE81a0058Dd5198] =   50000  * 10 ** (decimals); // 50,000
        emit Transfer(address(0), 0x64a1482Cc50d019C3372c4462fE81a0058Dd5198, 100000  * 10 ** (decimals));
        
        balances[0x25cB34Ab2e3EA7d96B5Ca959A7A6275C40EC5430] =   25000  * 10 ** (decimals); // 25,000
        emit Transfer(address(0), 0x25cB34Ab2e3EA7d96B5Ca959A7A6275C40EC5430, 25000  * 10 ** (decimals));
        
        _setLocking();
        
    }
    
    function _setLocking() private{
        locked[0x46D6933875c8f8937f8de644f4c75b879AC85abF].initial = 100000 * 10 ** (decimals);
        locked[0x46D6933875c8f8937f8de644f4c75b879AC85abF].locked = 100000 * 10 ** (decimals);
        locked[0x46D6933875c8f8937f8de644f4c75b879AC85abF].cliff = block.timestamp.add(365 days);
        locked[0x46D6933875c8f8937f8de644f4c75b879AC85abF].unlockAmt = 2000 * 10 ** (decimals);
        locked[0x46D6933875c8f8937f8de644f4c75b879AC85abF].unlockPeriod = 1 days;
        
        // no vesting. 
        locked[0x401d6C6fFC28db4c43C0b52E7AF1F8A607576842].initial = 250000  * 10 ** (decimals); 
        locked[0x401d6C6fFC28db4c43C0b52E7AF1F8A607576842].locked = 250000  * 10 ** (decimals);
        locked[0x401d6C6fFC28db4c43C0b52E7AF1F8A607576842].cliff = block.timestamp.add(30 days);
        
        locked[0x9020738c7F5D3d644f08126984ddE7C0E3316eb0].initial = 50000 * 10 ** (decimals);
        locked[0x9020738c7F5D3d644f08126984ddE7C0E3316eb0].locked = 50000 * 10 ** (decimals);
        locked[0x9020738c7F5D3d644f08126984ddE7C0E3316eb0].cliff = block.timestamp.add(90 days);
        locked[0x9020738c7F5D3d644f08126984ddE7C0E3316eb0].unlockAmt = 500 * 10 ** (decimals);
        locked[0x46D6933875c8f8937f8de644f4c75b879AC85abF].unlockPeriod = 30 days;
        
        locked[0xE2C707559f0cbB82Ca9bC078E5B6c7522FF1d314].initial = 50000 * 10 ** (decimals);
        locked[0xE2C707559f0cbB82Ca9bC078E5B6c7522FF1d314].locked = 50000 * 10 ** (decimals);
        locked[0xE2C707559f0cbB82Ca9bC078E5B6c7522FF1d314].cliff = block.timestamp.add(30 days);
        locked[0xE2C707559f0cbB82Ca9bC078E5B6c7522FF1d314].unlockAmt = 80 * 10 ** (decimals);
        locked[0xE2C707559f0cbB82Ca9bC078E5B6c7522FF1d314].unlockPeriod = 1 days;
        
        locked[0x85d4dA3C43c7a6E55810478ad22f80a35f75f6e1].initial = 20000 * 10 ** (decimals);
        locked[0x85d4dA3C43c7a6E55810478ad22f80a35f75f6e1].locked = 20000 * 10 ** (decimals);
        locked[0x85d4dA3C43c7a6E55810478ad22f80a35f75f6e1].cliff = block.timestamp.add(30 days);
        locked[0x85d4dA3C43c7a6E55810478ad22f80a35f75f6e1].unlockAmt = 400 * 10 ** (decimals);
        locked[0x85d4dA3C43c7a6E55810478ad22f80a35f75f6e1].unlockPeriod = 30 days;
        
        // no vesting. 
        locked[0x64a1482Cc50d019C3372c4462fE81a0058Dd5198].initial = 50000  * 10 ** (decimals); 
        locked[0x64a1482Cc50d019C3372c4462fE81a0058Dd5198].locked = 50000  * 10 ** (decimals);
        locked[0x64a1482Cc50d019C3372c4462fE81a0058Dd5198].cliff = block.timestamp.add(730 days);
        
        locked[0x25cB34Ab2e3EA7d96B5Ca959A7A6275C40EC5430].initial = 25000 * 10 ** (decimals);
        locked[0x25cB34Ab2e3EA7d96B5Ca959A7A6275C40EC5430].locked = 25000 * 10 ** (decimals);
        locked[0x25cB34Ab2e3EA7d96B5Ca959A7A6275C40EC5430].cliff = block.timestamp.add(60 days);
        locked[0x25cB34Ab2e3EA7d96B5Ca959A7A6275C40EC5430].unlockAmt = 625 * 10 ** (decimals);
        locked[0x25cB34Ab2e3EA7d96B5Ca959A7A6275C40EC5430].unlockPeriod = 1 days;
    }
    
    function setStakingAddress(address _stakingAdd) external onlyOwner{
        require(_stakingAdd != address(0), "Invalid address");
        stakingAdd = _stakingAdd;
    }

   
    /** ERC20Interface function's implementation **/
   
    function totalSupply() external override view returns (uint256){
       return _totalSupply;
    }
   
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) external override view returns (uint256 balance) {
        return balances[tokenOwner];
    }
    
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) external override returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) external override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public override returns (bool success) {
        
        require(address(to) != address(0), "Invalid receiver address");
        require(balances[msg.sender] >= tokens, "Insufficient account balance");
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        
        _checkTransfer(tokens, msg.sender);
        uint256 deduction = deductionsToApply(tokens);
        applyDeductions(deduction);
        
        balances[to] = balances[to].add(tokens.sub(deduction));
        emit Transfer(msg.sender, to, tokens.sub(deduction));
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokens) external override returns (bool success){
        require(tokens <= allowed[from][msg.sender], "Insufficient allowance"); //check allowance
        require(balances[from] >= tokens, "Insufficient account balance");
        
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        
        _checkTransfer(tokens, from);
        
        uint256 deduction = deductionsToApply(tokens);
        
        applyDeductions(deduction);
       
        balances[to] = balances[to].add(tokens.sub(deduction));
        emit Transfer(from, to, tokens.sub(tokens));
        return true;
    }
    
    function applyDeductions(uint256 deduction) private {
         // distribute deductions
        balances[DAOFund] = balances[DAOFund].add(deduction.div(4));
        balances[projectDevFund] = balances[projectDevFund].add(deduction.div(4));
        balances[stakingAdd] = balances[stakingAdd].add(deduction.div(2));
        IStaking(stakingAdd).disburse(deduction.div(2));
    }
    
    // ------------------------------------------------------------------------
    // Calculates deductions to apply to each transaction
    // ------------------------------------------------------------------------
    function deductionsToApply(uint256 tokens) private view returns(uint256){
        uint256 deduction = onePercent(tokens).mul(transactionCost);
        return deduction;
    }
    
    // ------------------------------------------------------------------------
    // Calculates onePercent of the uint256 amount sent
    // ------------------------------------------------------------------------
    function _checkTransfer(uint256 _tokens, address _user) internal returns(bool){
        if(block.timestamp > locked[_user].cliff){
            if(locked[_user].unlockPeriod > 0){
                uint256 unLockedTokens = ((block.timestamp.sub(locked[_user].cliff)).div(locked[_user].unlockPeriod)).mul(locked[_user].unlockAmt);
                locked[_user].locked = locked[_user].initial.sub(unLockedTokens);
            } else{
                locked[_user].locked = 0;
            }
        }
        require((balances[_user].sub(locked[_user].locked)) >= _tokens, "tokens are locked");
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Calculates onePercent of the uint256 amount sent
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) internal pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
}