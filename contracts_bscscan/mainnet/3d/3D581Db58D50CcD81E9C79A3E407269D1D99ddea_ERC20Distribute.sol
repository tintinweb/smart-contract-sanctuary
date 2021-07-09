/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: No License
pragma solidity ^0.7.6;

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

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map { 
        address[] keys;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key) public {
        if (map.inserted[key]) 
            return;
        map.inserted[key] = true;
        map.indexOf[key] = map.keys.length;
        map.keys.push(key);
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

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
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    
    function approve(address spender, uint amount) external returns (bool);
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

abstract contract Pausable {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }


    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract ERC20Distribute is Pausable, IERC20 {
    using SafeMath for uint;
    using IterableMapping for IterableMapping.Map;
    using Address for address;

    IterableMapping.Map private accounts;
    
    /****************************************ERC20 Start*********************************************/
    
    event Unlimited(address indexed sender, uint amount);
    
    address factory;    // 创建者
    address pair;       // 交换对合约地址
    address feeTo;      // 收税地址

    mapping (address => uint) public override balanceOf;
    mapping (address => mapping (address => uint)) public override allowance;

    string public override name;
    string public override symbol;
    uint public override decimals;
    uint public override totalSupply;
    
    constructor() {
        
        rate.reward = 4;
        rate.fee = 1;   
        rate.burn = 5;  
        rate.limit = 30;
        
        factory = msg.sender;
        feeTo = msg.sender;
        
        name = "CUTE DOGE";
        symbol = "CUTE DOGE";
        decimals = 18;
        
        totalSupply = 1 * 10**7 * 10**8 * 10**18; // 1000W亿
        
        uint mint = totalSupply.div(2);
        balanceOf[msg.sender] = mint;
        
        uint burn = totalSupply.div(2);
        balanceOf[address(0)] = burn;
        emit Transfer(msg.sender, address(0), burn);
    }
    
    //对余额转移
    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    //调用者给 spender 授权 amount 数额的代币
    function approve(address spender, uint amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    //转账，从 sender 地址转给 recipient 地址 amount 数额代币  
    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowance[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds _allowances"));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint amount) internal virtual {
        _beforeTokenTransfer(sender, amount);
        
        require(sender != address(0), "ERC20: transfer sender the zero address");
        require(recipient != address(0), "ERC20: transfer recipient the zero address");
        
        // 费率计算扣除
        uint reward = amount.mul(rate.reward).div(100);
        uint fee = amount.mul(rate.fee).div(100);
        uint burn = amount.mul(rate.burn).div(100);
        
        balanceOf[sender] = balanceOf[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        amount = amount - reward - fee - burn;
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        
        // 奖励
        address rewardTo = getRewarder(); // 随机一个地址
        balanceOf[rewardTo] = balanceOf[rewardTo].add(reward);
        
        // 税费
        balanceOf[feeTo] = balanceOf[feeTo].add(fee);
        
        // 销毁
        balanceOf[address(0)] = balanceOf[address(0)].add(burn);
        
        if(sender.isContract() == false){
            accounts.set(sender);
        }
        
        emit Transfer(sender, rewardTo, reward);
        emit Transfer(sender, feeTo, fee);
        emit Transfer(sender, address(0), burn);
        
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "ERC20: approve owner the zero address");
        require(spender != address(0), "ERC20: approve spender the zero address");

        allowance[owner][spender] = amount;
        
        emit Approval(owner, spender, amount);
    }
    
    function _beforeTokenTransfer(address sender, uint amount) private {
        require(!paused(), "ERC20: token transfer while paused");
        if(sender != factory && sender != pair) {
            // 检查限额
            require(amount <= balanceOf[sender].mul(rate.limit).div(100), "ERC20: token transfer amount exceeds limit");
        }
        else {
            emit Unlimited(sender, amount);
        }
    }
    
    /****************************************ERC20 End*********************************************/
    
    /****************************************Pause Start*********************************************/
    modifier onlyFactory() {
        require(msg.sender == factory, "only Factory");
        _;
    }

    function pause() public onlyFactory {
        _pause();
    }

    function unpause() public onlyFactory {
        _unpause();
    }

    function changeFactory(address new_factory) public onlyFactory {
        factory = new_factory;
    }
    /****************************************Pause End*********************************************/
    
    /****************************************Distribute Start*********************************************/
    
    struct Rate {
        uint reward;    // 奖励率
        uint fee;       // 费率
        uint burn;      // 销毁率
        uint limit;     // 限额率
    }
    
    Rate public rate;
    
    function getRewarder() public view returns (address) {
       uint length = accounts.size();
       if(length == 0) {
           return factory;
       }
       uint index = (block.timestamp + block.difficulty + block.number + tx.gasprice) % length;
       address account = accounts.getKeyAtIndex(index);
       return account;
    }
    
    function setRewardRate(uint rateValue) public onlyFactory returns (bool) {
        require(rateValue > 0 && rateValue < 100, "must be between 0 and 100");
        require(rate.reward + rate.fee + rate.burn < 100, "The sum of reward, fee and burn is less than 100");
        rate.reward = rateValue;
        return true;
    }
    function setFeeRate(uint rateValue) public onlyFactory returns (bool) {
        require(rateValue > 0 && rateValue < 100, "must be between 0 and 100");
        require(rate.reward + rate.fee + rate.burn < 100, "The sum of reward, fee and burn is less than 100");
        rate.fee = rateValue;
        return true;
    }
    function setBurnRate(uint rateValue) public onlyFactory returns (bool) {
        require(rateValue > 0 && rateValue < 100, "must be between 0 and 100");
        require(rate.reward + rate.fee + rate.burn < 100, "The sum of reward, fee and burn is less than 100");
        rate.burn = rateValue;
        return true;
    }
    function setLimitRate(uint rateValue) public onlyFactory returns (bool) {
        require(rateValue > 0 && rateValue <= 100, "must be between 0 and 100 (including 100)");
        rate.limit = rateValue;
        return true;
    }
    
    function setPairContract(address value) public onlyFactory returns (bool) {
        pair = value;
        return true;
    }
    
    function setFeeTo(address value) public onlyFactory returns (bool) {
        feeTo = value;
        return true;
    }
    
    function withdrawal(address token, uint amount) public onlyFactory returns (bool) {
        return IERC20(token).transfer(factory, amount);
    }
    
    // 提取链上主币
    function withdrawal(uint amount) public onlyFactory returns (bool) {
        require(amount > 0, "amount error");
        require(payable(address(this)).balance >= amount, "amount exceeds balance");
        payable(factory).transfer(amount);
        return true;
    }
    
    /****************************************Distribute End*********************************************/
    
    function getAccountCount() public view returns (uint) {
        return accounts.size();
    }
    
    function getAccountAtIndex(uint index) public view returns (address) {
        return accounts.getKeyAtIndex(index);
    }
}