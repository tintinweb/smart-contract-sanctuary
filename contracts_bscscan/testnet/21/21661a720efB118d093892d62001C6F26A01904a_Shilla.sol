// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IShillaVault.sol";


interface IAutoStaker {
    function stake(address holder, uint256 latestBalance) external;
}

contract Shilla is IERC20, Ownable {
    using Address for address;
    using SafeMath for uint256;

    string private _name = "Shillaverse";
    string private _symbol = "SHILLA";
    uint8 private _decimals = 9;
    
    //1 billion
    uint256 private _totalSupply = 1000 * 10**6 * 10**9;
    uint256 public shillerWageTaxFee = 1;
    uint256 public shillerDiscountTaxFee = 3;
    uint256 public vaultTaxFee = 4;
    uint256 public totalFees = 8;

    uint256 public lastID;
    uint256 public maxSellPerDay = 5 * 10**6 * 10**9;//0.5% of the total supply
    
    bool public taxDisabled;
    bool public maxSellDisabled;
    
    IShillaVault public shillaVault;
    IAutoStaker public autoStaker;


    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _maxSellFromExcluded;
    mapping (address => bool) private _maxSellToExcluded;
    mapping (address => mapping (address => uint256)) private allowances;

    mapping (address => uint256) private _balanceOf;
    mapping (address => uint256) private lastSellDayOf;
    mapping (address => uint256) private todaySalesOf;
    mapping (address => uint256) private shillerWagesOf;

    mapping (address => uint256) public IDof;
    mapping (uint256 => address) public holderOfID;
    mapping (address => address) public shillerOf;
    mapping (address => uint256) public totalShillEarningsOf;
    mapping(address => uint256) public totalShilledToOf;
    
    event ShillWagePaid(address indexed shiller, address indexed referral, uint256 amount);
    event VaultDibursement(address indexed vault, uint256 amount);

    modifier onReceive(address holder) {
        _;
        if(address(autoStaker) != address(0)) {
            //Checks if holder has enabled automatic stake and stake the holder's balance if enabled
            autoStaker.stake(holder, _balanceOf[holder]);
        }
    }
    
    constructor () public {
        _balanceOf[owner()] = _totalSupply;
        lastID++;
        IDof[owner()] = lastID;
        holderOfID[lastID] = owner();
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        //exclude owner and this contract from maxSellPerDay
        _maxSellFromExcluded[owner()] = true;
        _maxSellToExcluded[owner()] = true;
        _maxSellFromExcluded[address(this)] = true;
        _maxSellToExcluded[address(this)] = true;
        
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private onReceive(to) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");  
        
        if(!maxSellDisabled && !_maxSellFromExcluded[from] && !_maxSellToExcluded[to]) {
            if(block.timestamp - lastSellDayOf[from] > (1 days)) {
                lastSellDayOf[from] = block.timestamp;
                todaySalesOf[from] = amount;

            } else {
                todaySalesOf[from] = todaySalesOf[from] + amount;
            }
            require(todaySalesOf[from] <= maxSellPerDay, "Transfer amount exceeds the maxSellPerDay.");
        }
        
        _balanceOf[from] = _balanceOf[from].sub(amount);
        _balanceOf[to] = _balanceOf[to] + _takeFees(from, to, amount);
        if(IDof[to] == 0) {
            lastID++;
            IDof[msg.sender] = lastID;
            holderOfID[lastID] = msg.sender;
        }

        emit Transfer(from, to, amount);
    }

    function _getFees(uint256 amount) internal view returns (
        uint256 shillerWage, 
        uint256 shillerDiscount, 
        uint256 vaultTax, 
        uint256 remainder) {
              shillerWage = (shillerWageTaxFee * amount) / 100;
              shillerDiscount = (shillerDiscountTaxFee * amount) / 100;
              vaultTax = (vaultTaxFee * amount) / 100;
              remainder = amount - (shillerWage + shillerDiscount + vaultTax);
    }
    
    function _takeFees(
        address from,
        address to,
        uint256 amount
    ) internal onReceive(shillerOf[to]) onReceive(shillerOf[from]) returns (uint256 rem) {
        rem = amount;
        if(!taxDisabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            (uint256 shillerWage, uint256 shillerDiscount, uint256 vaultTax, uint256 remainder) = _getFees(amount);
            uint256 thisBalanceUp = vaultTax;
            //If this receiver has a shiller
            if(shillerOf[to] != address(0)) {
                //Credit the shiller
                _balanceOf[shillerOf[to]] = _balanceOf[shillerOf[to]] + shillerWage;
                totalShillEarningsOf[shillerOf[to]] = totalShillEarningsOf[shillerOf[to]] + shillerWage;
                emit ShillWagePaid(shillerOf[to], to, shillerWage);
                
                //Increase the amount the recipient gets. this implies a reduction in tax for the sender/receiver
                remainder = remainder + shillerDiscount;
            } 
            //If the sender has a shiller instead
            else if(shillerOf[from] != address(0)) {
                //Credit the shiller
                _balanceOf[shillerOf[from]] = _balanceOf[shillerOf[from]] + shillerWage;
                totalShillEarningsOf[shillerOf[from]] = totalShillEarningsOf[shillerOf[from]] + shillerWage;
                emit ShillWagePaid(shillerOf[from], from, shillerWage);
                
                //Increase the amount the recipient gets. this implies a reduction in tax for the sender/receiver
                remainder = remainder + shillerDiscount;

            } //If the sender && recipient are contracts instead, that is wallets that cannot have a shiller, 
            //add the wage and discount to the vault
            else if(from.isContract() && to.isContract()) {
                vaultTax = vaultTax + shillerWage + shillerDiscount;
                thisBalanceUp = vaultTax;

            } //If the recipient is a normal wallet and not a contract
            else if(!to.isContract()) {
                shillerWagesOf[to] = shillerWagesOf[to] + shillerWage;
                vaultTax = vaultTax + shillerDiscount;
                thisBalanceUp = vaultTax + shillerWage;

            }  //If the sender is a normal wallet and not a contract
            else {
                shillerWagesOf[from] = shillerWagesOf[from] + shillerWage;
                vaultTax = vaultTax + shillerDiscount;
                thisBalanceUp = vaultTax + shillerWage;
            }

            _balanceOf[address(this)] = _balanceOf[address(this)] + thisBalanceUp;
            _approve(address(this), address(shillaVault), vaultTax);
            shillaVault.diburseProfits(vaultTax);

            rem = remainder;
        }
    }

    function exludedState(address account) public view returns(
        bool isExcludedFromFee, 
        bool maxSellFromExcluded, 
        bool maxSellToExcluded
    ) {
        isExcludedFromFee = _isExcludedFromFee[account];
        maxSellFromExcluded = _maxSellFromExcluded[account];
        maxSellToExcluded = _maxSellToExcluded[account];
    }

    function provideShiller(uint256 shillerID) external onReceive(holderOfID[shillerID]) {
        require(shillerOf[msg.sender] == address(0), 'shillerID already provided');
        require(shillerID > 0 && shillerID <= lastID, 'Invalid shilerID');
        require(holderOfID[shillerID] != msg.sender, "You can't be your own shiller");
        //prevent the provision of a shillerID that has not provided its own shillerID
        require(shillerID == 1 || shillerOf[holderOfID[shillerID]] != address(0), "Unactivated shillerId");
        require(IDof[msg.sender] > 0, 'You have no ID yet');

        shillerOf[msg.sender] = holderOfID[shillerID];
        totalShilledToOf[holderOfID[shillerID]] = totalShilledToOf[holderOfID[shillerID]] + 1;

        if(shillerWagesOf[msg.sender] > 0) {
            _balanceOf[address(this)] = _balanceOf[address(this)].sub(shillerWagesOf[msg.sender]);
            _balanceOf[holderOfID[shillerID]] = _balanceOf[holderOfID[shillerID]] + shillerWagesOf[msg.sender];
            totalShillEarningsOf[holderOfID[shillerID]] = totalShillEarningsOf[holderOfID[shillerID]]  + shillerWagesOf[msg.sender];
            emit ShillWagePaid(holderOfID[shillerID], msg.sender, shillerWagesOf[msg.sender]);
            shillerWagesOf[msg.sender] = 0;
        }
    }

    function getMaxSellPerDayOf(address holder) external view returns(uint256) {
        if(block.timestamp - lastSellDayOf[holder] > (1 days)) {
            return maxSellPerDay;

        } else if(maxSellPerDay > todaySalesOf[holder]) {
            return maxSellPerDay - todaySalesOf[holder];

        } else {
            return 0;
        }
    }

    function _setShillaVault(IShillaVault vault) external onlyOwner {
        _isExcludedFromFee[address(vault)] = true;
        _maxSellFromExcluded[address(vault)] = true;
        _maxSellToExcluded[address(vault)] = true;
        shillaVault = vault;
    }
    function _setAutoStaker(IAutoStaker _autoStaker) external onlyOwner {
        _isExcludedFromFee[address(_autoStaker)] = true;
        _maxSellFromExcluded[address(_autoStaker)] = true;
        _maxSellToExcluded[address(_autoStaker)] = true;
        autoStaker = _autoStaker;
    }

    function _excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function _includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function _excludeFromMaxFrom(address account) external onlyOwner {
        _maxSellFromExcluded[account] = true;
    }
    function _excludeFromMaxTo(address account) external onlyOwner {
        _maxSellToExcluded[account] = true;
    }
    
    function _includeInMaxFrom(address account) external onlyOwner {
        _maxSellFromExcluded[account] = false;
    }
    function _includeInMaxTo(address account) external onlyOwner {
        _maxSellToExcluded[account] = false;
    }

    function _setShillerWageFeePercent(uint256 taxFee) external onlyOwner() {
        shillerWageTaxFee = taxFee;
    }

    function _setShillerDisountFeePercent(uint256 taxFee) external onlyOwner() {
        shillerDiscountTaxFee = taxFee;
    }

    function _setVaultFeePercent(uint256 taxFee) external onlyOwner() {
        vaultTaxFee = taxFee;
    }

    function _setTaxDisabled(bool v) external onlyOwner() {
        taxDisabled = v;
    }

    function _setMaxSellDisabled(bool v) external onlyOwner() {
        maxSellDisabled = v;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShillaVault {
    function stake(address _withdrawer, uint256 _amount, uint256 _lockId) external returns (uint256 _id);
    function diburseProfits(uint256 amount) external;
    function onGameEnded(uint256 gameId, uint256 ownerFee) external;
    function onGameFunded(uint256 gameId) external;
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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