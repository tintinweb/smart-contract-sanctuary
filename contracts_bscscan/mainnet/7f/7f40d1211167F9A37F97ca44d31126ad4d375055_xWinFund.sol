/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0-or-later

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

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

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

library xWinLib {
   
    // Info of each pool.
    struct PoolInfo {
        address lpToken;           
        uint256 rewardperblock;       
        uint256 multiplier;       
    }
    
    struct UserInfo {
        uint256 amount;     
        uint256 blockstart; 
    }

    struct TradeParams {
      address xFundAddress;
      uint256 amount;
      uint256 priceImpactTolerance;
      uint256 deadline;
      bool returnInBase;
      address referral;
    }  
   
    struct transferData {
      
      address[] targetNamesAddress;
      uint256 totalTrfAmt;
      uint256 totalUnderlying;
      uint256 qtyToTrfAToken;
    }
    
    struct xWinReward {
      uint256 blockstart;
      uint256 accBasetoken;
      uint256 accMinttoken;
      uint256 previousRealizedQty;
    }
    
    struct xWinReferral {
      address referral;
    }
    
    struct UnderWeightData {
      uint256 activeWeight;
      uint256 fundWeight;
      bool overweight;
      address token;
    }
    
    struct DeletedNames {
      address token;
      uint256 targetWeight;
    }
    
    struct PancakePriceToken {
        string tokenname;
        address addressToken;     
    }

}


interface xWinDefiInterface {
    
    function getPlatformFee() view external returns (uint256);
    function getPlatformAddress() view external returns (address);
    function gexWinBenefitPool() view external returns (address) ;
}

contract BEP20 is Context, IBEP20, Ownable {
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
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    
    /*function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }*/

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
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
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
        require(account != address(0), 'BEP20: mint to the zero address');

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
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
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

interface xWinMaster {
    
    function getTokenName(address _tokenaddress) external view returns (string memory tokenname);
    function getPriceByAddress(address _targetAdd, string memory _toTokenName) external view returns (uint);
    function getPriceFromBand(string memory _fromToken, string memory _toToken) external view returns (uint);
    function getPancakeRouter() external view returns (IPancakeRouter02 pancakeRouter);
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// helper methods for interacting with BEP20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract xWinFund is IBEP20, BEP20 {
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    xWinMaster private _xWinMaster;

    address private protocolOwner;
    address private masterOwner;
    address[] private targetNamesAddress;
    address[] public nonBMNamesAddress;
    mapping(address => bool) public nonBMNamesMapping;
    mapping(address => bool) public useSupportingFeeOnTransferTokens;
    
    address private managerOwner;
    uint256 private managerFeeBps;
    mapping(address => uint256) public TargetWeight;
    uint256 private rebalanceCycle = 876000; // will change back to 876000 in mainnet;
    uint256 public platformFee = 50;
    address public platformWallet = address(0x62691eF999C7F07BC1653416df0eC4f3CDDBb0c7);
    
    uint256 public nextRebalance;
    address public BaseToken = address(0x0000000000000000000000000000000000000000);
    string public BaseTokenName = "BNB";
    xWinDefiInterface xwinProtocol;
    address public WETH = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    bool public pause = false;
    event Received(address, uint);
    event _ManagerFeeUpdate(uint256 fromFee, uint256 toFee, uint txnTime);
    event _ManagerOwnerUpdate(address fromAddress, address toAddress, uint txnTime);
    event _RebalanceCycleUpdate(uint fromCycle, uint toCycle, uint txnTime);

    modifier onlyxWinProtocol {
        require(
            msg.sender == protocolOwner,
            "Only xWinProtocol can call this function."
        );
        _;
    }
    modifier onlyManager {
        require(
            msg.sender == managerOwner,
            "Only managerOwner can call this function."
        );
        _;
    }
    
     constructor (
            string memory name,
            string memory symbol,
            address _protocolOwner,
            address _managerOwner,
            uint256 _managerFeeBps,
            address _masterOwner
        ) public BEP20(name, symbol) {
            protocolOwner = _protocolOwner;
            masterOwner = _masterOwner;
            managerOwner = _managerOwner;
            managerFeeBps = _managerFeeBps;
            _xWinMaster = xWinMaster(masterOwner);
            xwinProtocol = xWinDefiInterface(_protocolOwner);
            nextRebalance = block.number.add(rebalanceCycle);
        }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    /// @dev owner to pause for depositing
    function setPause(bool _pause) public onlyOwner {
        pause = _pause;
    }
    
    function mint(address to, uint256 amount) internal onlyxWinProtocol {
        _mint(to, amount);
    }
    
    function _swapBNBToTokens(
            address toDest,
            uint amountIn, 
            uint deadline,
            address destAddress,
            uint priceImpactTolerance 
            )
    internal {
            
            if(toDest == WETH){
                IWETH(WETH).deposit{value: amountIn}();
            }else{
                
                IPancakeRouter02 router = _xWinMaster.getPancakeRouter();
                address[] memory path = new address[](2);
                path[0] = router.WETH();
                path[1] = toDest;
                
                uint256[] memory amounts = router.getAmountsOut(amountIn, path);
                uint256 amountOut = amounts[amounts.length.sub(1)];
                router.swapExactETHForTokens{value: amountIn}(amountOut.sub(amountOut.mul(priceImpactTolerance).div(10000)), path, destAddress, deadline);
            }
        }

    function _swapTokenToBNB(
            address token,
            uint amountIn, 
            uint deadline,
            address destAddress,
            uint priceImpactTolerance
            )
    internal {
            
            if(token == WETH){
                IWETH(WETH).withdraw(amountIn);
            }else{
                
                IPancakeRouter02 router = _xWinMaster.getPancakeRouter();
                address[] memory path = new address[](2);
                path[0] = token;
                path[1] = router.WETH();
                
                TransferHelper.safeApprove(token, address(router), amountIn); 
                
                uint256[] memory amounts = router.getAmountsOut(amountIn, path);
                uint256 amountOut = amounts[amounts.length.sub(1)];
                
                if(useSupportingFeeOnTransferTokens[token]){
                    router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, amountOut.sub(amountOut.mul(priceImpactTolerance).div(10000)), path, destAddress, deadline);
                }else{
                    router.swapExactTokensForETH(amountIn, amountOut.sub(amountOut.mul(priceImpactTolerance).div(10000)), path, destAddress, deadline);
                }
            }
        }
        
    /// Get All the fund data needed for client
    function GetFundDataAll() external view returns (
          IBEP20 _baseToken,
          address[] memory _targetNamesAddress,
          address _managerOwner,
          uint256 totalUnitB4,
          uint256 baseBalance,
          uint256 unitprice,
          uint256 fundvalue,
          string memory fundName,
          string memory symbolName,
          uint256 managerFee,
          uint256 unitpriceInUSD
        ){
            return (
                IBEP20(BaseToken), 
                targetNamesAddress, 
                managerOwner, 
                totalSupply(), 
                address(this).balance, 
                _getUnitPrice(), 
                _getFundValues(),
                name(),
                symbol(),
                managerFeeBps,
                _getUnitPriceInUSD()
            );
    }
   
   function getTargetNamesAddress() external view returns (address[] memory _targetNamesAddress){
        return targetNamesAddress;
   }

    /// @dev Get token balance
    function getBalance(address fromAdd) external view returns (uint256){
        return _getBalance(fromAdd);
    }

    /// @dev return target amount based on weight of each token in the fund
    function getTargetWeightQty(address targetAdd, uint256 srcQty) internal view returns (uint256){
        return TargetWeight[targetAdd].mul(srcQty).div(10000);
    }
    
    /// @dev return weight of each token in the fund
    function getTargetWeight(address addr) external view returns (uint256){
        return TargetWeight[addr];
    }
 
    /// @dev return number of target names
    function CreateTargetNames(
        address[] calldata _toAddresses, 
        uint256[] calldata _targetWeight
    ) external onlyxWinProtocol payable {

        _createTargetNames(_toAddresses, _targetWeight);
    }

    /// @dev update rebalanceCycle
    function updateRebalancePeriod(uint newCycle) external onlyOwner payable {
        
        emit _RebalanceCycleUpdate(rebalanceCycle, newCycle, block.timestamp);
        rebalanceCycle = newCycle;
    }

    /// @dev update platform fee and wallet
    function updatePlatformProperty(address newPlatformWallet, uint newPlatformFee) public onlyOwner {
        
        platformWallet = newPlatformWallet;
        platformFee = newPlatformFee;
    }
    
    /// @dev update manager fee and wallet
    function updateManagerProperty(address newManager, uint newFeebps) external onlyOwner payable {
        
        emit _ManagerOwnerUpdate(managerOwner, newManager, block.timestamp);
        emit _ManagerFeeUpdate(managerFeeBps, newFeebps, block.timestamp);
        managerFeeBps = newFeebps;
        managerOwner = newManager;
    }
    
    /// @dev update protocol owner
    function updateProtocol(address _newProtocol) external onlyOwner {
        protocolOwner = _newProtocol;
        xwinProtocol = xWinDefiInterface(_newProtocol);
    }
    
    /// @dev update xwin master contract
    function updateXwinMaster(address _masterOwner) external onlyOwner {
        _xWinMaster = xWinMaster(_masterOwner);
    }
    
    /// @dev update WETH just in case
    function updateWETH(address _WETH) public onlyOwner {
        WETH = address(_WETH);
    }
    
    function updateUseSupportingFeeOnTransferTokens(
        address[] calldata _tokenaddress,
        bool[] calldata _useSupportingFeeOnTransferTokens
    ) public onlyOwner {

        for (uint i = 0; i < _tokenaddress.length; i++) {
            useSupportingFeeOnTransferTokens[_tokenaddress[i]] = _useSupportingFeeOnTransferTokens[i];
        }
    }
    
    function updateNonBMNames(
        address[] calldata _nonBMaddress,
        bool[] calldata _nonBM
    ) public onlyManager {


        if(nonBMNamesAddress.length > 0){
            for (uint i = 0; i < nonBMNamesAddress.length; i++) {
                nonBMNamesMapping[nonBMNamesAddress[i]] = false;
            }
            delete nonBMNamesAddress;
        }
        
        for (uint i = 0; i < _nonBMaddress.length; i++) {
            
            //make sure it is not in bm target
            require(TargetWeight[_nonBMaddress[i]] == 0, "update bm name first");
            nonBMNamesMapping[_nonBMaddress[i]] = _nonBM[i];
            nonBMNamesAddress.push(_nonBMaddress[i]);
        }
    }
    
    
    /// @dev return target address
    function getWhoIsManager() external view returns(address){
        return managerOwner;
    }
    
    /// @dev return target address
    function getManagerFee() external view returns(uint256){
        return managerFeeBps;
    }

    /// @dev return unit price
    function getUnitPrice()
        external view returns(uint256){
        return _getUnitPrice();
    }
    
    /// @dev return unit price in USDT
    function getUnitPriceInUSD()
        external view returns(uint256){
        return _getUnitPriceInUSD();
    }
    
    /**
     * Returns the latest price
     */
    function getLatestPrice(address _targetAdd) external view returns (uint256) {
        return _getLatestPrice(_targetAdd);
    }
    
    /// @dev return fund total value in BNB
    function getFundValues() external view returns (uint256){
        return _getFundValues();
    }
    
    /// @dev return token value in the vault in BNB
    function getTokenValues(address tokenaddress) external view returns (uint256){
        return _getTokenValues(tokenaddress);
    }
    
    /// @dev perform rebalance with new weight and reset next rebalance period
    function Rebalance(
        address[] calldata _toAddresses, 
        uint256[] calldata _targetWeight,
        uint256 deadline,
        uint256 priceImpactTolerance
        ) external onlyxWinProtocol payable returns (uint256 baseccyBal) {
        
        //get delete names
        xWinLib.DeletedNames[] memory deletedNames = _getDeleteNames(_toAddresses);
        
        // move to base balance
        for (uint x = 0; x < deletedNames.length; x++){
            if(deletedNames[x].token != address(0)){
                  _moveNonIndexNameToBase(deletedNames[x].token, deadline, priceImpactTolerance); 
            }
        }
        // update new target
        _createTargetNames(_toAddresses, _targetWeight);
        
        //rebalance
        baseccyBal = _rebalance(deadline, priceImpactTolerance);
        return baseccyBal;
    }
    
    /// @dev perform subscription based on ratio setup
    function Subscribe(
        xWinLib.TradeParams memory _tradeParams,
        address _investorAddress
    ) external onlyxWinProtocol payable returns (uint256) {
        
        require(pause == false, "temporariy pause");
        require(targetNamesAddress.length > 0, "no target setup");
        
        (uint256 mintQty, uint256 fundvalue) = _getMintQty(_tradeParams.amount);
        mint(_investorAddress, mintQty);
        
        // if hit rebalance period, do rebalance after minting qty
        if(nextRebalance < block.number){
            _rebalance(_tradeParams.deadline, _tradeParams.priceImpactTolerance);
        }else{
            uint256 totalSubs = address(this).balance;
            if(!_isSmallSubs(fundvalue, totalSubs)){
                for (uint i = 0; i < targetNamesAddress.length; i++) {
                    uint256 proposalQty = getTargetWeightQty(targetNamesAddress[i], totalSubs);
                    if(proposalQty > 0){
                        _swapBNBToTokens(targetNamesAddress[i], proposalQty, _tradeParams.deadline, address(this), _tradeParams.priceImpactTolerance);
                    }
                }
            }
        }
        return mintQty;
    }
    
    /// @dev perform redemption based on unit redeem
    function Redeem(
        xWinLib.TradeParams memory _tradeParams,
        address _investorAddress
    ) external onlyxWinProtocol payable returns (uint256){
        
        uint256 redeemratio = _tradeParams.amount.mul(1e18).div(totalSupply());
        require(redeemratio > 0, "redeem ratio is zero");
        
        _burn(msg.sender, _tradeParams.amount);
        
	    uint totalBaseBal = address(this).balance;
        uint entitledBNB = redeemratio.mul(totalBaseBal).div(1e18);
        uint remainedBNB = totalBaseBal.sub(entitledBNB);
        
        //start to transfer back to investor based on the targets
        for (uint i = 0; i < targetNamesAddress.length; i++) {
            xWinLib.transferData memory _transferData = _getTransferAmt(targetNamesAddress[i], redeemratio);
            if(_transferData.totalTrfAmt > 0){
                _swapTokenToBNB(targetNamesAddress[i], _transferData.totalTrfAmt, _tradeParams.deadline, address(this), _tradeParams.priceImpactTolerance);
            }
        }
        uint newTotalBaseBal = address(this).balance;
        uint totalOutput = newTotalBaseBal.sub(remainedBNB);
        uint finalSwapOutput = _handleFeeTransfer(totalOutput);
        TransferHelper.safeTransferBNB(_investorAddress, finalSwapOutput);
        _transferNonBM(redeemratio, _investorAddress);
        return redeemratio;
    }
    
    /// @dev fund owner move any name back to BNB
    function MoveNonIndexNameToBase(
        address _tokenaddress,
        uint256 deadline,
        uint256 priceImpactTolerance
        ) external onlyxWinProtocol returns (uint256 balanceToken, uint256 swapOutput) {
            
            (balanceToken, swapOutput) = _moveNonIndexNameToBase(_tokenaddress, deadline, priceImpactTolerance);
            return (balanceToken, swapOutput);
        }
        
        
    /// @dev get the proportional token without swapping it in emergency case
    function emergencyRedeem(uint256 redeemUnit, address _investorAddress) external onlyxWinProtocol payable {
            
        uint256 redeemratio = redeemUnit.mul(1e18).div(totalSupply());
        require(redeemratio > 0, "redeem ratio is zero");
        _burn(msg.sender, redeemUnit);
        uint256 totalBaseBal = address(this).balance;
        uint256 totalOutput = redeemratio.mul(totalBaseBal).div(1e18);
        TransferHelper.safeTransferBNB(_investorAddress, totalOutput);
        
        for (uint i = 0; i < targetNamesAddress.length; i++) {
            xWinLib.transferData memory _transferData = _getTransferAmt(targetNamesAddress[i], redeemratio);
            if(_transferData.totalTrfAmt > 0){
                TransferHelper.safeTransfer(targetNamesAddress[i], _investorAddress, _transferData.totalTrfAmt);
            }
        }
    }
        
    /// @dev Calc return balance during redemption
    function _getTransferAmt(address underyingAdd, uint256 redeemratio) 
        internal view returns (xWinLib.transferData memory transData) {
       
        xWinLib.transferData memory _transferData;
        _transferData.totalUnderlying = _getBalance(underyingAdd); 
        uint256 qtyToTrf = redeemratio.mul(_transferData.totalUnderlying).div(1e18);
        _transferData.totalTrfAmt = qtyToTrf;
        return _transferData;
    }
    
    /// @dev Calc qty to issue during subscription 
    function _getMintQty(uint256 srcQty) internal view returns (uint256 mintQty, uint256 totalFundB4)  {
        
        uint256 totalFundAfter = _getFundValues();
        totalFundB4 = totalFundAfter.sub(srcQty);
        mintQty = _getNewFundUnits(totalFundB4, totalFundAfter, totalSupply());
        return (mintQty, totalFundB4);
    }
    
    function _getActiveOverWeight(address destAddress, uint256 totalfundvalue) 
        internal view returns (uint256 destRebQty, uint256 destActiveWeight, bool overweight, uint256 fundWeight) {
        
        destRebQty = 0;
        uint256 destTargetWeight = TargetWeight[destAddress];
        uint256 destValue = _getTokenValues(destAddress);
        fundWeight = destValue.mul(10000).div(totalfundvalue);
        overweight = fundWeight > destTargetWeight;
        destActiveWeight = overweight ? fundWeight.sub(destTargetWeight): destTargetWeight.sub(fundWeight);
        if(overweight){
            uint price = _getLatestPrice(destAddress);
            destRebQty = destActiveWeight.mul(totalfundvalue).mul(1e18).div(price).div(10000);
        }
        return (destRebQty, destActiveWeight, overweight, fundWeight);
    }
    
    function _rebalance(uint256 deadline, uint256 priceImpactTolerance) 
        internal returns (uint256 baseccyBal) {
        
        //sell overweight names first
        (xWinLib.UnderWeightData[] memory underweightNames, uint256 totalunderActiveweight) = _sellOverWeightNames (deadline, priceImpactTolerance);
        //get total proceeds in BNB after seling overweight names and buy underweight names
        baseccyBal = _buyUnderWeightNames(deadline, priceImpactTolerance, underweightNames, totalunderActiveweight); 
        nextRebalance = block.number.add(rebalanceCycle);
        return baseccyBal;
    }
    
    function _sellOverWeightNames (uint256 deadline, uint256 priceImpactTolerance) 
        internal returns (xWinLib.UnderWeightData[] memory underweightNames, uint256 totalunderActiveweight) {
        
        uint256 totalfundvaluebefore = _getFundValues();
        totalunderActiveweight = 0;
        
        underweightNames = new xWinLib.UnderWeightData[](targetNamesAddress.length);

        //get overweight name
        for (uint i = 0; i < targetNamesAddress.length; i++) {
            (uint256 rebalQty, uint256 destActiveWeight, bool overweight, uint256 fundWeight) = _getActiveOverWeight(targetNamesAddress[i], totalfundvaluebefore);
            if(overweight) //sell token to BNB
            {
                _swapTokenToBNB(targetNamesAddress[i], rebalQty, deadline, address(this), priceImpactTolerance);
            }else{
                //collect the total fund weight for underweight names
                if(destActiveWeight > 0){
                    xWinLib.UnderWeightData memory _underWeightData;
                    _underWeightData.token = targetNamesAddress[i];
                    _underWeightData.fundWeight = fundWeight;
                    _underWeightData.activeWeight = destActiveWeight;
                    _underWeightData.overweight = false;
                    underweightNames[i] = _underWeightData;
    
                    totalunderActiveweight = totalunderActiveweight.add(destActiveWeight);
                }
            }
        }
        
        return (underweightNames, totalunderActiveweight);
    }
    
    function _buyUnderWeightNames (
        uint256 deadline, 
        uint256 priceImpactTolerance, 
        xWinLib.UnderWeightData[] memory underweightNames,
        uint256 totalunderActiveweight
        ) 
        internal returns (uint256 baseccyBal) {
        
        //get total proceeds in BNB after seling overweight names
        baseccyBal = address(this).balance;
        for (uint i = 0; i < underweightNames.length; i++) {
            
            if(underweightNames[i].token != address(0)){
                uint256 rebaseActiveWgt = underweightNames[i].activeWeight.mul(10000).div(totalunderActiveweight);
                uint256 rebBuyQty = rebaseActiveWgt.mul(baseccyBal).div(10000);
                if(rebBuyQty > 0 && rebBuyQty <= address(this).balance){
                    _swapBNBToTokens(underweightNames[i].token, rebBuyQty, deadline, address(this), priceImpactTolerance);
                }
            }
        }
        return baseccyBal;
    }
    
    function _getLatestPrice(address _targetAdd) internal view returns (uint256) {
        
        if(_targetAdd == WETH) return 1e18;
        return _xWinMaster.getPriceByAddress(_targetAdd, BaseTokenName);
    }
    
    function _getFundValues() internal view returns (uint256){
        
        //get BNB value first if any
        uint256 totalValue = address(this).balance;
        for (uint i = 0; i < targetNamesAddress.length; i++) {
            totalValue = totalValue.add(_getTokenValues(targetNamesAddress[i]));
        }
        
        for (uint i = 0; i < nonBMNamesAddress.length; i++) {
            if(nonBMNamesMapping[nonBMNamesAddress[i]] == true){
                totalValue = totalValue.add(_getTokenValues(nonBMNamesAddress[i]));
            }
        }
        
        return totalValue; 
    }
    
    function getNonBMLength() public view returns (uint256){
        return nonBMNamesAddress.length;
    }
    
    function getNonBMValues() public view returns (uint256){
        
        uint256 totalValue = 0;
        for (uint i = 0; i < nonBMNamesAddress.length; i++) {
            if(nonBMNamesMapping[nonBMNamesAddress[i]] == true){
                totalValue = totalValue.add(_getTokenValues(nonBMNamesAddress[i]));
            }
        }
        return totalValue; 
    }
    
    
    function _getUnitPrice() internal view returns(uint256){
        
        uint256 totalValueB4 = _getFundValues();
        if(totalValueB4 == 0) return 0;
        uint256 totalUnitB4 = totalSupply();
    	if(totalUnitB4 == 0) return 0;
        return totalValueB4.mul(1e18).div(totalUnitB4);
    }

    function _getTokenValues(address tokenaddress) internal view returns (uint256){
        
        uint256 tokenBalance = _getBalance(tokenaddress);
        uint256 price = _getLatestPrice(tokenaddress); //price from token to BNB
        return tokenBalance.mul(uint256(price)).div(1e18);
    }

    function _getBalance(address fromAdd) internal view returns (uint256){
        
        if(IBEP20(fromAdd) == IBEP20(BaseToken)) return address(this).balance;
        return IBEP20(fromAdd).balanceOf(address(this));
    }
    
    function _getUnitPriceInUSD() internal view returns(uint256){
        
        uint256 totalValue = _getUnitPrice();
        uint256 toBasePrice = _xWinMaster.getPriceFromBand(BaseTokenName, "USDT"); 
        return totalValue.mul(toBasePrice).div(1e18);
    }
    
    function _moveNonIndexNameToBase(
        address _tokenaddress,
        uint256 deadline,
        uint256 priceImpactTolerance
        ) internal returns (uint256 balanceToken, uint256 swapOutput) {
            
            balanceToken = _getBalance(_tokenaddress);
            _swapTokenToBNB(_tokenaddress, balanceToken, deadline, address(this), priceImpactTolerance);
            return (balanceToken, 0);
    }

    function _createTargetNames(
        address[] calldata _toAddresses, 
        uint256[] calldata _targetWeight
    ) internal {

        if(targetNamesAddress.length > 0){
            for (uint i = 0; i < targetNamesAddress.length; i++) {
                TargetWeight[targetNamesAddress[i]] = 0;
            }
            delete targetNamesAddress;
        }
        
        for (uint i = 0; i < _toAddresses.length; i++) {
            TargetWeight[_toAddresses[i]] = _targetWeight[i];
            targetNamesAddress.push(_toAddresses[i]);
            //reset nonBM mapping if it is bm target name 
            nonBMNamesMapping[_toAddresses[i]] = false;
        }
    }
    
    
    function _getDeleteNames(
            address[] calldata _toAddresses
        ) internal view returns (xWinLib.DeletedNames[] memory deletedNames){
        
        deletedNames = new xWinLib.DeletedNames[](targetNamesAddress.length);

        // identitfy deleted name
        for (uint i = 0; i < targetNamesAddress.length; i++) {
            uint matchtotal = 1;
            for (uint x = 0; x < _toAddresses.length; x++){
                if(targetNamesAddress[i] == _toAddresses[x]){
                    break;
                }else if(targetNamesAddress[i] != _toAddresses[x] && _toAddresses.length == matchtotal){
                    deletedNames[i].token = targetNamesAddress[i]; 
                }
                matchtotal++;
            }
        }
        return deletedNames;
     }

    function _handleFeeTransfer(
        uint swapOutput
        ) internal returns (uint finalSwapOutput){
        
        
        uint platformUnit = swapOutput.mul(platformFee).div(10000);
        
        if(platformUnit > 0){
            TransferHelper.safeTransferBNB(platformWallet, platformUnit);
        }
        uint managerUnit = swapOutput.mul(managerFeeBps).div(10000);
        
        if(managerUnit > 0){
            TransferHelper.safeTransferBNB(managerOwner, managerUnit);
        }
        
        finalSwapOutput = swapOutput.sub(platformUnit).sub(managerUnit);
        
        return (finalSwapOutput);

    }
    
    function _isSmallSubs(uint256 fundvalue, uint256 subsAmt) 
        internal pure returns (bool)  {
        
        if(fundvalue == 0) return false;
        uint256 percentage = subsAmt.mul(10000).div(fundvalue);
        
        //if more than 1% to the fund, consider not small
        if(percentage > 100) return false;
        
        return true;
    }
    
    function _transferNonBM(uint redeemratio, address _investorAddress) 
        internal {
        
        if(nonBMNamesAddress.length == 0) return;
        
        for (uint i = 0; i < nonBMNamesAddress.length; i++) {
            //make sure it is not in bm target
            if(TargetWeight[nonBMNamesAddress[i]] == 0){
                uint256 tokenBalance = _getBalance(nonBMNamesAddress[i]);
                uint256 trfOutput = redeemratio.mul(tokenBalance).div(1e18);
                if(trfOutput > 0){
                    TransferHelper.safeTransfer(nonBMNamesAddress[i], _investorAddress, trfOutput);
                }
            }
        }
    }
    
    /// @dev Mint unit back to investor
    function _getNewFundUnits(uint256 totalFundB4, uint256 totalValueAfter, uint256 totalSupply) 
        internal pure returns (uint256){
          
        if(totalValueAfter == 0) return 0;
        if(totalFundB4 == 0) return totalValueAfter; 

        uint256 totalUnitAfter = totalValueAfter.mul(totalSupply).div(totalFundB4);
        uint256 mintUnit = totalUnitAfter.sub(totalSupply);
        
        return mintUnit;
    }
}