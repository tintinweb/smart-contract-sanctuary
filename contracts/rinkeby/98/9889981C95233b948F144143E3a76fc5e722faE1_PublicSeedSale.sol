/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

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
        assembly {
            codehash := extcodehash(account)
        }
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public virtual override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
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
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
        );
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero')
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), 'ERC20: mint to the zero address');

        _beforeTokenTransfer(address(0), account, amount);

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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract Ownable {
    address public owner;
    constructor() public {
      owner = msg.sender;
      }

    modifier onlyOwner() {
      if (msg.sender != owner) {
        revert();
      }    
      _;
    }
} 


contract PublicSeedSale is Ownable{
    using SafeMath for uint256;

    ERC20 public tokenReward;

    uint256 public totalETHDeposit= 0;
    
    uint256 public dayUnblock = 1611964800;
    
    uint256 public percentMaxPayout= 40;
    
    struct User {
        uint256 totalETH;
        uint256 totalLUCKYDeposit;
        uint256 totalLUCKY;
        uint256 totalLUCKYBlock;
        uint256 totalREFBlock;
        uint256 totalREF;
        uint256 refLevel;
        address refParent;
    }
    struct Order {
        uint256 id;
        address userId;
        uint256 timestampCreated;
        uint256 amountETH;
        bool [4] times;
        uint256 rewarded;
        uint256 totalReward;
        address address_refer;
        uint256 timestampLastWithDraw;
    }


    mapping (address => uint256) public balanceOf;
    


    mapping(address => User) public users;
    mapping(uint256 => Order) public orders;
    uint256 public orderCount;
    address public dev_adress = 0x5fe7ebc23f13C04Bd8eB30C42B0542fB51FeBAB1;
    address public address_refer = 0x2c5feAa0724dE158D0C19b77C36Da5385C67C1Bd;
    address payable address_admin = 0x5fe7ebc23f13C04Bd8eB30C42B0542fB51FeBAB1;
    
    address default_adress = 0x0000000000000000000000000000000000000000;
    uint256 percent_withDraw = 500000000000000000;
    
    uint256 qtyReceive = 50000;
    uint256 public minTotalETH = 1e17;
    
    uint256 public maxAmountReward = 2*1e18;

    event Deposit(address indexed user, uint256 amount);
    event Transfer(address sender, address receiver, uint256 amount);
    mapping(address => address) public userIdsOrders;

    constructor(address _LUCKYToken) public {
        tokenReward = ERC20(_LUCKYToken);
    }

    function getName() public view returns (string memory) {
        return tokenReward.name();
    }

    function getTotalSupply() public view returns (uint256) {
        return tokenReward.totalSupply();
    }

    function getBalanceOf(address _owner) public view returns (uint256) {
        return tokenReward.balanceOf(_owner);
    }

    function getBalance() public view returns (uint256) {
        return tokenReward.balanceOf(address(this));
    }

    function sendTransferReward(address _to, uint256 _value) public {
        tokenReward.transfer(_to, _value);
    }

   function setTokenLUCKYReward(address _token) public onlyOwner {
        tokenReward = ERC20(_token);
    }
    
    function setQtyReceive(uint256 _qty) public onlyOwner {
        qtyReceive = _qty;
    }

    function setDevReward(address _dev) public onlyOwner {
        dev_adress = _dev;
    }
    
    function setReferReward(address _ref) public onlyOwner {
        address_refer = _ref;
    }

    function setDayUnblock(uint256 _dayUnblock) public onlyOwner {
        dayUnblock = _dayUnblock;
    }
    
    function setPercentMaxPayout(uint256 _percent) public onlyOwner {
        percentMaxPayout = _percent;
    }

    function setAddressAdmin(address payable _address_admin) public onlyOwner {
        address_admin = _address_admin;
    }

    function setAddressRefer(address  _address_refer) public onlyOwner {
        address_refer = _address_refer;
    }
    
    function setPercent_withDraw(uint256  _percent_withDraw) public onlyOwner {
        percent_withDraw = _percent_withDraw;
    }
    
    function setMinTotalETH(uint256  _minTotalETH) public onlyOwner {
        minTotalETH = _minTotalETH;
    }
    
    function setMaxAmountReward(uint256  _maxAmountReward) public onlyOwner {
        maxAmountReward = _maxAmountReward;
    }
    
    function checkLimitAndSentReward(
        address _refer,
        uint256 bonus
    ) private {
        User storage user = users[_refer];
        uint256 currentTotalLUCKY = user.totalREF.add(bonus);
        uint256 totalLUCKYonETHReward = user.totalLUCKYDeposit.mul(percentMaxPayout).div(100); //  percent on total ETH
        if (_refer == address_refer) {
            sendTransferReward(_refer, bonus);
        } else {
            if (currentTotalLUCKY <= totalLUCKYonETHReward) {
                user.totalREF = user.totalREF.add(bonus);
                sendTransferReward(_refer, bonus);
            }
        }
    }
    
    function getBonus(uint256 _amountETH, uint16 _level)  internal  returns (uint256) {
        uint16 [3] memory arrBonus = [1000,500,300];
        uint256 reward = 0;
        if(_amountETH >= maxAmountReward){
            reward =  maxAmountReward.mul(arrBonus[_level]).div(1e18);
        }else{
            reward = _amountETH.mul(arrBonus[_level]).div(1e18);
        }
        return reward.mul(1e18);
    }
    
    function calBonusRefer(
        address _refer,
        uint256 _amountETH
    ) private {
        User storage user = users[_refer];
        
        // if _refer is address dev then don'nt need check balance ETH
        if (_refer == address_refer) {
            sendTransferReward(_refer, getBonus(_amountETH,0));
        } else {
            if (user.totalETH >= minTotalETH) {
                checkLimitAndSentReward(_refer, getBonus(_amountETH,0));
            }

            User storage userLevel1 = users[user.refParent];
            if (user.refParent == address_refer || (userLevel1.totalETH >= minTotalETH && user.refParent != address_refer)) {
                checkLimitAndSentReward(user.refParent, getBonus(_amountETH,1));
            }

            User storage userLevel2 = users[userLevel1.refParent];
            if (
                userLevel1.refParent == address_refer || 
                (userLevel2.totalETH >= minTotalETH && userLevel1.refParent != address_refer)) {
                checkLimitAndSentReward(userLevel1.refParent, getBonus(_amountETH,2));
            }
        }
    }

    // Buy token LUCKY by deposit ETH
    function buyToken(
        uint256 _amountETH,
        address _refer,
        uint256 _referLevel
    ) payable  public {
        require(msg.value == _amountETH, 'Insufficient ETH balance');
        
        
        address userIdOrder = userIdsOrders[msg.sender];
        // insert or update amount for user

        User storage user = users[msg.sender];

        if (_refer == address_refer) {
            user.refLevel = 1;
        } else {
            user.refLevel = _referLevel;
        }

        user.refParent = _refer;
        uint256 _rate_token_reward = qtyReceive;

        // call bonus
        if (_refer != default_adress && userIdOrder == default_adress) {
            calBonusRefer(_refer, _amountETH);
        }

        // calculator reward
        uint256 reward = _amountETH.mul(_rate_token_reward);

        // create order
        userIdsOrders[msg.sender] = msg.sender;
        
        bool [4] memory times= [false,false,false,false];
        orders[orderCount] = Order(
            orderCount,
            msg.sender,
            block.timestamp,
            _amountETH,
            times,
            0,
            reward,
            _refer,
            block.timestamp
        );
        if(msg.value>0){
            // sent amount to wallet addmin
            sentTransferETH(address_admin);    
        }

        // update totalETH deposit
        user.totalETH = user.totalETH.add(_amountETH);
        user.totalLUCKYDeposit = user.totalLUCKYDeposit.add(reward);
        user.totalLUCKYBlock = user.totalLUCKYBlock.add(reward);
        totalETHDeposit = totalETHDeposit.add(_amountETH);
        orderCount++;
    }

    function withDrawToken(uint256 _orderId, uint256 _milestone) public {
        Order storage order = orders[_orderId];
        require(order.userId == msg.sender, 'Require created by sender');
        uint8 [4] memory arrmMilestone = [1,2,3,4];
        uint256 rewardPending = 0;
        bool isWithDraw = false;
        uint256 milestone = 0;
        if (order.times[0] != true  && _milestone == arrmMilestone[0]) {
            milestone = 20;
            isWithDraw = true;
            order.times[0] = true;
        }

        if (order.times[1] != true && _milestone == arrmMilestone[1]) {
            milestone = 25;
            isWithDraw = true;
            order.times[1] = true;
        }

        if (order.times[2] != true && _milestone == arrmMilestone[2]) {
            milestone = 25;
            isWithDraw = true;
            order.times[2]=true;
        }

        if (order.times[3] != true && _milestone == arrmMilestone[3]) {
            milestone = 30;
            isWithDraw = true;
            order.times[3]=true;
        }
    
        if (isWithDraw) {
            rewardPending = getRewardByPercent(_orderId, milestone);
            order.rewarded = order.rewarded.add(rewardPending);
            order.timestampLastWithDraw = block.timestamp;

            // sent transfer to sender
            sendTransferReward(msg.sender, rewardPending);

            User storage user = users[order.userId];
            user.totalLUCKY = user.totalLUCKY.add(rewardPending);
            if (rewardPending > 0) {
                user.totalLUCKYBlock = user.totalLUCKYBlock.sub(rewardPending);
            }
        }
    }

    function getRewardByPercent(uint256 _orderId, uint256 _milestone) public view returns (uint256) {
        Order memory order = orders[_orderId];
        uint256 rewardPending = 0;
        rewardPending = order.totalReward.mul(_milestone).div(100);
        return rewardPending;
    }

    function getOrder(uint256 _orderId) public view returns (Order memory) {
        return orders[_orderId];
    }

    function getUser(address _adr) public view returns (User memory) {
        return users[_adr];
    }

    function getOrders(address _user) public view returns (Order[] memory) {
        Order[] memory ordersTemp = new Order[](orderCount);
        uint256 count;
        for (uint256 i = 0; i < orderCount; i++) {
            if (orders[i].userId == _user) {
                ordersTemp[count] = orders[i];
                count += 1;
            }
        }
        Order[] memory filteredOrders = new Order[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredOrders[i] = ordersTemp[i];
        }
        return filteredOrders;
    }

    function sentTransferETH(address payable _to) private {
       _to.transfer(msg.value);
    }   
}