//SourceUnit: ERC20.sol

pragma solidity >=0.5.4 <0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
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
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
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
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}


//SourceUnit: IERC20.sol

pragma solidity >=0.5.4 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

//SourceUnit: SafeMath.sol

pragma solidity >=0.5.4 <0.8.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

//SourceUnit: Treasury.sol

pragma solidity >=0.5.4 <0.8.0;

import "./ERC20.sol";

contract Treasury {
    uint private _totalHolders;
    address private owner;
    mapping (address => bool ) private holderExists;
    mapping (uint => address ) private holders;
    mapping (address => bool) private blockUser;
    mapping (address => bool) private referrerable;
    mapping (address => User) private users;
    mapping (address => address[]) private childs;
    mapping (address => uint) private childCount;
    mapping (address => uint) private accumulation;
    
    uint private lockTime = 60 * 60 * 24;
    ERC20 private usdt = ERC20(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c);
    uint[] levelStep = [100000000000, 500000000000];
    uint[] selfCommision = [8, 10, 12];
    uint[] refCommision = [100, 50, 30, 10, 10];
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event UserDeposit(address indexed user, uint256 indexed hash, uint256 amount, uint indexed timestamp);
    event AutoWithdrawal(address indexed user, uint256 indexed hash, uint256 amount, uint interest);
    event ReferralBonus(address indexed fromAddress, address indexed toAddress, uint level, uint amount);
    event UserUpgradeLevel(address indexed user, uint indexed level);
    
    struct User { 
        TXRecord[] txs;
        address referrer;
        uint level;
    }
    
    struct TXRecord {
        uint256 hash;
        uint256 amount;
        uint timestamp;
        bool withdrawaled;
    }
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor (uint lockTimeDuration) public {
        lockTime = lockTimeDuration;
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }
    
    function deposit(address userAddress, uint256 hash, uint256 amount) public returns (bool) {
        require(msg.sender == owner, "Caller is not owner");
        emit UserDeposit(userAddress, hash, amount, block.timestamp);
        checkUser(userAddress);
        TXRecord memory txr = TXRecord(hash, amount , block.timestamp, false);
        User storage user = users[userAddress];
        user.txs.push(txr);
        accumulation[userAddress] += amount;

        uint sum = accumulation[userAddress];
        address[] memory childList = childs[userAddress];
        for(uint i=0;i<childList.length;i++) {
            address childAddress = childList[i];
            sum += accumulation[childAddress];
        }
        
        if(sum >= levelStep[1] && user.level < 3) {
            user.level = 3;
            emit UserUpgradeLevel(msg.sender, 3);
        } else if(sum >= levelStep[0] && user.level < 2) {
            user.level = 2;
            emit UserUpgradeLevel(msg.sender, 2);
        }
        
        address referrerAddress = user.referrer;
        User storage referrerUser = users[referrerAddress];
        sum = accumulation[referrerAddress];
        address[] memory referrerChildList = childs[referrerAddress];
        for(uint i=0;i<referrerChildList.length;i++) {
            address childAddress = referrerChildList[i];
            sum += accumulation[childAddress];
        }
        
        if(sum >= levelStep[1] && referrerUser.level < 3) {
            referrerUser.level = 3;
            emit UserUpgradeLevel(referrerAddress, 3);
        } else if(sum >= levelStep[0] && referrerUser.level < 2) {
            referrerUser.level = 2;
            emit UserUpgradeLevel(referrerAddress, 2);
        }

        return true;
    }
    
    function withdrawal() public returns (bool) {
        require(msg.sender == owner, "Caller is not owner");
        for(uint i=0;i<_totalHolders;i++) {
            address userAddress = holders[i];
            if(!blockUser[userAddress]) {
                User storage user = users[userAddress];
                TXRecord[] storage txs = user.txs;
                for(uint j=0;j<txs.length;j++) {
                    TXRecord storage utx = txs[j];
                    if(!utx.withdrawaled) { 
                        if(block.timestamp - utx.timestamp >= lockTime) { 
                            uint commission = selfCommision[0];
                            if (user.level == 2) {
                                commission = selfCommision[1];
                            } else if (user.level == 3) {
                                commission = selfCommision[2];
                            }
                            uint afterCommission = utx.amount * commission / 1000;
                            uint totalWithdrawal = utx.amount + afterCommission;
                            require(
                                totalWithdrawal <= usdt.balanceOf(address(this)), "Inventory shortage"
                                );
                            emit AutoWithdrawal(userAddress, utx.hash, utx.amount, afterCommission);
                            utx.withdrawaled = true;
                            usdt.transfer(userAddress, totalWithdrawal); 
                            address tmpAddr = userAddress;
                            for(uint k=1;k<=5;k++) {
                                if(referrerable[tmpAddr]) { 
                                    uint cm2 = refCommision[4];
                                    if(k == 1) {
                                        cm2 = refCommision[0];
                                    } else if(k == 2) {
                                        cm2 = refCommision[1];
                                    } else if(k == 3) {
                                        cm2 = refCommision[2];
                                    } else if(k == 4) {
                                        cm2 = refCommision[3];
                                    } else if(k == 5) {
                                        cm2 = refCommision[4];
                                    }
                                    uint bonus = afterCommission * cm2 / 1000;
                                    require(
                                        bonus <= usdt.balanceOf(address(this)), "Inventory shortage"
                                    );
                                    emit ReferralBonus(userAddress, user.referrer, k, bonus);
                                    usdt.transfer(user.referrer, bonus); 
                                    tmpAddr = user.referrer;
                                    user = users[user.referrer];
                                } else {
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        return true;
    }
    
    function setLockDuration(uint lockTimeDuration) public returns (bool) {
        require(msg.sender == owner, "Caller is not owner");
        lockTime = lockTimeDuration;
        return true;
    }
    
    function withdrawalCountdown(address userAddress) public view returns (uint) {
        uint countDown = 9999999999;
        if(!blockUser[userAddress]) {
            User storage user = users[userAddress];
            TXRecord[] storage txs = user.txs;
            for(uint j=0;j<txs.length;j++) {
                TXRecord storage utx = txs[j];
                if(!utx.withdrawaled) {
                    if(block.timestamp - utx.timestamp >= lockTime) { 
                        return 0;
                    } else {
                        uint remainTime = lockTime - (block.timestamp - utx.timestamp);
                        if(remainTime < countDown) {
                            countDown = remainTime;
                        }
                    }
                }
            }
        }
        return countDown;
    }
    
    function checkUser(address userAddress) private {
        if(!holderExists[userAddress]) {
            holderExists[userAddress] = true;
            holders[_totalHolders] = userAddress;
            accumulation[userAddress] = 0;
            childCount[userAddress] = 0;
            _totalHolders++;
        }
    }
    
    function setReferrer(address userAddress, address referrerAddress) public returns (bool) {
        require(msg.sender == owner, "Caller is not owner");
        require(
            referrerAddress != userAddress, "Referrer Can Not Asign To Self"
        );
        
        checkUser(referrerAddress);
        User storage user = users[userAddress];
        require(
            !referrerable[userAddress], "Referrer Already Set"
        );
        if(user.level < 1) {
            user.level = 1;
            user.referrer = referrerAddress;
            childs[referrerAddress].push(userAddress);
            childCount[referrerAddress]++;
            referrerable[userAddress] = true;
            emit UserUpgradeLevel(userAddress, 1);
        }
        return true;
    }
    
    function balanceOf(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        TXRecord[] memory txs = user.txs;
        uint sum = 0;
        for(uint i = 0; i<txs.length;i++) {
            TXRecord memory txr = txs[i];
            if(txr.withdrawaled == false) {
                sum += txr.amount;
            }
        }
        return sum;
    }
    
    function levelOf(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        if(user.level < 1)
            return 1;
        else
            return user.level;
    }

    function accumulationOf(address userAddress) public view returns (uint) {
        return accumulation[userAddress];
    }
    
    function referrerOf(address userAddress) public view returns (address) {
        User storage user = users[userAddress];
        return user.referrer;
    }
    
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function withdrawable() external view returns (bool) {
        for(uint i=0;i<_totalHolders;i++) {
            address userAddress = holders[i];
            if(!blockUser[userAddress]) {
                User storage user = users[userAddress];
                TXRecord[] storage txs = user.txs;
                for(uint j=0;j<txs.length;j++) {
                    TXRecord storage utx = txs[j];
                    if(!utx.withdrawaled) { 
                        if(block.timestamp - utx.timestamp >= lockTime) { 
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    function blockUserAddress(address blockAddress) public returns (bool) {
        require(msg.sender == owner, "Caller is not owner");
        blockUser[blockAddress] = true;
        return true;
    }
    
    function unblockUserAddress(address unblockAddress) public returns (bool) {
        require(msg.sender == owner, "Caller is not owner");
        blockUser[unblockAddress] = false;
        return true;
    }
    
    function blockTimeDuration() external view returns (uint) {
        return lockTime;
    }
    
    function totalBalance() external view returns (uint256) {
        return (usdt.balanceOf(address(this)));
    }
    
    function getOwner() external view returns (address) {
        return owner;
    }

    function childsOf(address userAddress) external view returns (address[] memory) {
        address[] memory tmp = childs[userAddress]; 
        return tmp;
    }

    function levelSteps() external view returns (uint[] memory) {
        return levelStep;
    }

    function selfCommisions() external view returns (uint[] memory) {
        return selfCommision;
    }

    function refCommisions() external view returns (uint[] memory) {
        return refCommision;
    }
}