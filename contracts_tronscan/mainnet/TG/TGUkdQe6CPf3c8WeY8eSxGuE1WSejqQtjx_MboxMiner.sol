//SourceUnit: Address.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

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

//SourceUnit: BEP20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

import './Ownable.sol';
import './Context.sol';
import './IBEP20.sol';
import './SafeMath.sol';
import './Address.sol';

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    uint256 _maxsupply;
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
    constructor(string memory namea, string memory symbola,uint8 decimalsa) {
        _name = namea;
        _symbol = symbola;
        _decimals = decimalsa;
        _maxsupply = 1000000000 *(10 **_decimals);
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
    function mint(uint256 amount) public onlyOwner returns (bool) {
        require(_totalSupply.add(amount) <= _maxsupply);
        _mint(_msgSender(), amount);
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
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

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


    function burn(uint256 amount) public override returns (bool)
    {
        _burn(msg.sender,amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) public override returns (bool)
    {
        _burnFrom(account,amount);
        return true;
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
}

//SourceUnit: Context.sol

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
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SourceUnit: IBEP20.sol

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

    function burnFrom(address account, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);

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



//SourceUnit: LpWallet.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./IBEP20.sol";

contract LpWallet //EMPTY CONTRACT TO HOLD THE USERS assetS
{
    address lptoken;
    address liztoken;
    address _MainContract;
    address _feeowner;
    address _owner;

    mapping(address=>uint256) _balancesa;
    mapping(address=>uint256) _balancesb;

    using TransferHelper for address;
    using SafeMath for uint256;

    event eventWithDraw(address indexed to,uint256 indexed  amounta,uint256 indexed amountb);

    constructor(address tokena,address tokenb,address feeowner,address owner) //Create by lizmain 
    {
        _MainContract=msg.sender;// The lizmain CONTRACT
        lptoken =tokena;
        liztoken=tokenb;
        _feeowner=feeowner;
        _owner=owner;
    }

    function getBalance(address user,bool isa) public view returns(uint256)
    {
        if(isa)
            return _balancesa[user];
       else
           return _balancesb[user];
    }
 
    function addBalance(address user,uint256 amounta,uint256 amountb) public
    {
        require(_MainContract==msg.sender);//Only lizmain can do this
        _balancesa[user] = _balancesa[user].add(amounta);
        _balancesb[user] = _balancesb[user].add(amountb);
    }

    function resetTo(address newcontract) public
    {
        require(msg.sender==_owner);
        _MainContract=newcontract;
    }

    function decBalance(address user,uint256 amounta,uint256 amountb ) public 
    {
        require(_MainContract==msg.sender);//Only lizmain can do this
        _balancesa[user] = _balancesa[user].sub(amounta);
        _balancesb[user] = _balancesb[user].sub(amountb);
    }
 
    function TakeBack(address to, address feeOwner,uint256 amounta,uint256 amountb) public 
    {
        require(_MainContract==msg.sender);//Only lizmain can do this
        _balancesa[to]= _balancesa[to].sub(amounta);
        _balancesb[to]= _balancesb[to].sub(amountb);
        if(lptoken!= address(2))//BNB
        {
            uint256 mainfee= amounta.div(100);
            IBEP20(lptoken).transfer(to, amounta.sub(mainfee));
            IBEP20(lptoken).transfer(feeOwner, mainfee);
            //    lptoken.safeTransfer(to, amounta.sub(mainfee));
            //    lptoken.safeTransfer(feeOwner, mainfee);
           if(amountb>=100)
           {
               uint256 fee = amountb.div(100);//fee 1%
               liztoken.safeTransfer(to, amountb.sub(fee));
               IBEP20(liztoken).burn(fee);
           }
           else
           {
               liztoken.safeTransfer(to, amountb);
           }
        }
    }
}

//SourceUnit: Manageable.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an manager) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the manager account will be the one that deploys the contract. This
 * can later be changed with {transferManagement}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
contract Manageable is Context {
    address private _manager;

    event ManagementTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    constructor() {
        address msgSender = _msgSender();
        _manager = msgSender;
        emit ManagementTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current manager.
     */
    function manager() public view returns (address) {
        return _manager;
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(_manager == _msgSender(), 'Manageable: caller is not the manager');
        _;
    }

    /**
     * @dev Leaves the contract without manager. It will not be possible to call
     * `onlyManager` functions anymore. Can only be called by the current manager.
     *
     * NOTE: Renouncing management will leave the contract without an manager,
     * thereby removing any functionality that is only available to the manager.
     */
    function renounceManagement() public onlyManager {
        emit ManagementTransferred(_manager, address(0));
        _manager = address(0);
    }

    /**
     * @dev Transfers management of the contract to a new account (`newManager`).
     * Can only be called by the current manager.
     */
    function transferManagement(address newManager) public onlyManager {
        _transferManagement(newManager);
    }

    /**
     * @dev Transfers management of the contract to a new account (`newManager`).
     */
    function _transferManagement(address newManager) internal {
        require(newManager != address(0), 'Manageable: new manager is the zero address');
        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;
    }
}

//SourceUnit: MboxMinePool.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;
import "./TransferHelper.sol";
import "./IBEP20.sol";
 
contract MboxMinePool
{
    address _owner;
    address _token;
    address _feeowner;
    using TransferHelper for address;
 
    constructor(address tokenaddress,address feeowner)
    {
        _owner=msg.sender;
        _token=tokenaddress;
        _feeowner=feeowner;
    }

    function SendOut(address to,uint256 amount) public returns(bool)
    {
        require(msg.sender==_feeowner);
        _token.safeTransfer(to, amount);
        return true;
    }

 
    function MineOut(address to,uint256 amount,uint256 fee) public returns(bool){
        require(msg.sender==_owner);
        _token.safeTransfer(to, amount);
        IBEP20(_token).burn(fee);
        return true;
    }
 
}

//SourceUnit: MboxMiner.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./TransferHelper.sol";
import "./IBEP20.sol";
import "./LpWallet.sol";
import "./MboxMinePool.sol";
 
contract MboxMiner is ReentrancyGuard {
    using TransferHelper for address;
    using SafeMath for uint256;

    uint256 private _mboxExchangeCountOfOneUsdt;
    uint256 private _currentMulitiper;
    uint256 private _maxcheckpoint;

    address private _mboxaddress;
    address private _usdtaddress;

    address private _owner;
    address private _feeowner;

    uint256 _nowtotalhash;

    MboxMinePool _minepool;
    address[] _lpaddresses;

    mapping(uint256 => uint256[1]) private _checkpoints;
    mapping(address => mapping(address => uint256)) internal _userLphash;
    mapping(address => mapping(uint256 => uint256)) internal _userlevelhashtotal;
    mapping(uint256 => uint256[8]) internal _levelconfig;
    mapping(address => address) internal _parents;
    mapping(address => UserInfo) internal _userInfos;
    mapping(address => PoolInfo) _lpPools;
    mapping(address => address[]) _mychilders;

    uint256[8] _vipbuyprice = [0, 100, 2000, 5000, 10000, 13000, 18000, 20000];

    struct PoolInfo {
        LpWallet poolwallet;
        uint256 hashrate;
        uint256 totalhash;
    }

    struct UserInfo {
        uint256 selfhash;
        uint256 teamhash;
        uint256 userlevel;
        uint256 pendingreward;
        uint256 lastblock;
        uint256 lastcheckpoint;
    }

    event BindingParents(address indexed user, address inviter);
    event TradingPooladded(address indexed tradetoken);
    event UserBuied(
        address indexed tokenaddress,
        uint256 amount,
        uint256 hashb
    );
    event TakedBack(address indexed tokenaddress);

    constructor() {
        _owner = msg.sender;
    }

    function getMinerPoolAddress() public view returns (address) {
        return address(_minepool);
    }

    function getCurrentCheckPoint() public view returns (uint256[1] memory) {
        return _checkpoints[_maxcheckpoint];
    }

    function InitalContract(address mboxtoken, address usdtaddress, address feeowner) public {
        require(msg.sender == _owner);
        require(_feeowner == address(0));
        _mboxaddress = mboxtoken;
        _usdtaddress = usdtaddress;
        _feeowner = feeowner;
        _minepool = new MboxMinePool(mboxtoken, _owner);
        _parents[msg.sender] = address(_minepool);
        
        _levelconfig[0] = [100,0,0,0,0,0,0];
        _levelconfig[1] = [150,100,0,0,0,0,0];
        _levelconfig[2] = [160,110,90,60,0,0,0];
        _levelconfig[3] = [170,120,100,70,40,30,0];
        _levelconfig[4] = [180,130,110,80,40,30,20];
        _levelconfig[5] = [200,140,120,90,40,30,20];
        _levelconfig[6] = [220,160,140,100,40,30,20];
        _levelconfig[7] = [250,180,160,110,40,30,20];

        _maxcheckpoint = 1;
        _checkpoints[_maxcheckpoint][0] = block.number;
        _currentMulitiper = 655833;
        _mboxExchangeCountOfOneUsdt = 1e6;
    }

    function getLpAddresses() public view returns (address[] memory) {
        return _lpaddresses;
    }

    function addTradingPool(address tokenAddress) public returns (bool) {
        require(msg.sender == _owner);
        require(_lpPools[tokenAddress].hashrate == 0, "LP EXISTS");

        LpWallet wallet = new LpWallet(
            tokenAddress,
            _mboxaddress,
            _feeowner,
            _owner
        );
        _lpPools[tokenAddress] = PoolInfo({
            poolwallet: wallet,
            hashrate: 1,
            totalhash: 0
        });
        _lpaddresses.push(tokenAddress);
        emit TradingPooladded(tokenAddress);
        return true;
    }

    function setVipBuyPrice(uint256[8] memory newVipBuyPrice) public returns (bool) {
        require(msg.sender == _owner);
        _vipbuyprice = newVipBuyPrice;
        return true;
    }

    function setCurrentMulitiper(uint256 newCurrentMulitiper) public returns (bool) {
        require(msg.sender == _owner);
        _currentMulitiper = newCurrentMulitiper;
        return true;
    }

    function getCurrentMulitiper() public view returns (uint256) {
        return _currentMulitiper;
    }

    function getPower(address tokenAddress, uint256 amount) public view returns (uint256) {
        return amount.mul(1e6).div(getExchangeCountOfOneUsdt(tokenAddress));
    }

    function getMyLpInfo(address user, address tokenaddress)
        public
        view
        returns (uint256[3] memory)
    {
        uint256[3] memory bb;
        bb[0] = _lpPools[tokenaddress].poolwallet.getBalance(user, true);
        bb[1] = _lpPools[tokenaddress].poolwallet.getBalance(user, false);
        bb[2] = _userLphash[user][tokenaddress];
        return bb;
    }

    function getLpInfo(address tokenAddress) public view returns (uint256) {
        return _lpPools[tokenAddress].totalhash;
    }

    function WithDrawCredit() public nonReentrant returns (bool) {
        uint256 amount = getPendingCoin(msg.sender);
        if (amount < 0) return true;

        _userInfos[msg.sender].pendingreward = 0;
        _userInfos[msg.sender].lastblock = block.number;
        if (_maxcheckpoint > 0)
            _userInfos[msg.sender].lastcheckpoint = _maxcheckpoint;
        _minepool.MineOut(msg.sender, amount, 0);
        return true;
    }

    function TakeBack(address tokenAddress, uint256 pct) public nonReentrant returns (bool) {
        require(pct >= 10000 && pct <= 1000000);
        require(
            _lpPools[tokenAddress].poolwallet.getBalance(msg.sender, true) >= 0,
            "ERROR AMOUNT"
        );
        uint256 balancea = _lpPools[tokenAddress].poolwallet.getBalance(msg.sender, true);
        uint256 totalhash = _userLphash[msg.sender][tokenAddress];

        uint256 amounta = balancea.mul(pct).div(1000000);
        uint256 decreasehash = _userLphash[msg.sender][tokenAddress]
        .mul(pct)
        .div(1000000);

        _userLphash[msg.sender][tokenAddress] = totalhash.sub(decreasehash);

        address parent = msg.sender;
        uint256 dthash = 0;
        for (uint256 i = 0; i < 8; i++) {
            parent = _parents[parent];
            if (parent == address(0) || parent == address(_minepool)) break;

            _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].sub(
                decreasehash
            );
            uint256 parentlevel = _userInfos[parent].userlevel;
            uint256 pdechash = decreasehash
            .mul(_levelconfig[parentlevel][i])
            .div(1000);
            if (pdechash > 0) {
                dthash = dthash.add(pdechash);
                UserHashChanged(parent, 0, pdechash, false, block.number);
            }
        }
        UserHashChanged(msg.sender, decreasehash, 0, false, block.number);
        VipChanged(msg.sender);
        _lpPools[tokenAddress].totalhash = _lpPools[tokenAddress].totalhash.sub(decreasehash.add(dthash));
        logCheckPoint(decreasehash.add(dthash), false, block.number);
        _lpPools[tokenAddress].poolwallet.TakeBack(
            msg.sender,
            _feeowner,
            amounta,
            0
        );
        emit TakedBack(tokenAddress);
        return true;
    }

    function getWalletAddress(address lptoken) public view returns (address) {
        return address(_lpPools[lptoken].poolwallet);
    }

    function getUserLasCheckPoint(address useraddress)
        public
        view
        returns (uint256)
    {
        return _userInfos[useraddress].lastcheckpoint;
    }

    function deposit(address tokenAddress, uint256 amount) public nonReentrant returns (bool) {
        require(amount > 0, "less amount");
        uint256 price = getExchangeCountOfOneUsdt(tokenAddress);
        uint256 hashb = amount.mul(1e6).div(price);

        tokenAddress.safeTransferFrom(msg.sender, address(_lpPools[tokenAddress].poolwallet), amount);

        _lpPools[tokenAddress].poolwallet.addBalance(msg.sender, amount, 0);

        _userLphash[msg.sender][tokenAddress] = _userLphash[msg.sender][tokenAddress].add(hashb);

        address parent = msg.sender;
        uint256 dhash = 0;

        for (uint256 i = 0; i < 8; i++) {
            parent = _parents[parent];
            if (parent == address(0) || parent == address(_minepool)) break;

            _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].add(hashb);
            uint256 parentlevel = _userInfos[parent].userlevel;
            uint256 levelconfig = _levelconfig[parentlevel][i];
            if (levelconfig > 0) {
                uint256 addhash = hashb.mul(levelconfig).div(1000);
                if (addhash > 0) {
                    dhash = dhash.add(addhash);
                    UserHashChanged(parent, 0, addhash, true, block.number);
                }
            }
        }
        UserHashChanged(msg.sender, hashb, 0, true, block.number);
        VipChanged(msg.sender);

        _lpPools[tokenAddress].totalhash = _lpPools[tokenAddress].totalhash.add(hashb.add(dhash));
        logCheckPoint(hashb.add(dhash), true, block.number);
        emit UserBuied(tokenAddress, amount, hashb);
        return true;

    }

    function logCheckPoint(
        uint256 totalhashdiff,
        bool add,
        uint256 blocknumber
    ) private {
        if (add) {
            _nowtotalhash = _nowtotalhash.add(totalhashdiff);
        } else {
            _nowtotalhash = _nowtotalhash.sub(totalhashdiff);
        }
        _checkpoints[_maxcheckpoint][0] = blocknumber;
    }

    function getPendingCoin(address user) public view returns (uint256) {
        if (_userInfos[user].lastblock == 0) {
            return 0;
        }
        UserInfo memory info = _userInfos[user];
        uint256 total = info.pendingreward;
        uint256 mytotalhash = info.selfhash + info.teamhash;
        if (mytotalhash == 0) return total;
        uint256 lastblock = info.lastblock;

        if (_maxcheckpoint > 0) {
            if (info.lastcheckpoint > 0) {
                for (
                    uint256 i = info.lastcheckpoint + 1;
                    i <= _maxcheckpoint;
                    i++
                ) {
                    uint256 blockk = _checkpoints[i][0];
                    if (blockk <= lastblock) {
                        continue;
                    }
                    uint256 get = blockk
                    .sub(lastblock)
                    .mul(_currentMulitiper)
                    .mul(mytotalhash)
                    .div(_nowtotalhash);
                    total = total.add(get);
                    lastblock = blockk;
                }
            }

            if (lastblock < block.number && lastblock > 0) {
                uint256 blockcount = block.number.sub(lastblock);
                if (_nowtotalhash > 0) {
                    uint256 get = blockcount
                    .mul(_currentMulitiper)
                    .mul(mytotalhash)
                    .div(_nowtotalhash);
                    total = total.add(get);
                }
            }
        }
        return total;

    }

    function UserHashChanged(address user, uint256 selfhash, uint256 teamhash, bool add, uint256 blocknum) private {
        uint256 dhash = getPendingCoin(user);
        UserInfo memory info = _userInfos[user];
        info.pendingreward = dhash;
        info.lastblock = blocknum;
        if (_maxcheckpoint > 0) {
            info.lastcheckpoint = _maxcheckpoint;
        }
        if (selfhash > 0) {
            if (add) {
                info.selfhash = info.selfhash.add(selfhash);
            } else info.selfhash = info.selfhash.sub(selfhash);
        }
        if (teamhash > 0) {
            if (add) {
                info.teamhash = info.teamhash.add(teamhash);
            } else {
                if (info.teamhash > teamhash)
                    info.teamhash = info.teamhash.sub(teamhash);
                else info.teamhash = 0;
            }
        }
        
        _userInfos[user] = info;
    }

    function VipChanged(address user) private {
        uint256 level = 7;
        for(uint i = 1; i < _vipbuyprice.length; i++) {
            if (_userInfos[user].selfhash < _vipbuyprice[i] * 1e6) {
                level = i - 1;
                break;
            }
        }
        _userInfos[user].userlevel = level;
    }

    function setMboxExchangeCountOfOneUsdt(uint256 newMboxExchangeCountOfOneUsdt) public returns (bool) {
        require(msg.sender == _owner);
        _mboxExchangeCountOfOneUsdt = newMboxExchangeCountOfOneUsdt;
        return true;
    }

    function getExchangeCountOfOneUsdt(address lptoken) public view returns (uint256) {
        if (lptoken == _usdtaddress) return 1e6;
        return _mboxExchangeCountOfOneUsdt;
    }

    function bindParent(address parent) public {
        require(_parents[msg.sender] == address(0), "Already bind");
        require(parent != address(0), "ERROR parent");
        require(parent != msg.sender, "error parent");
        require(_parents[parent] != address(0));
        _parents[msg.sender] = parent;
        _mychilders[parent].push(msg.sender);
        emit BindingParents(msg.sender, parent);
    }

    function SetParentByAdmin(address user, address parent) public {
        require(_parents[user] == address(0), "Already bind");
        require(msg.sender == _owner);
        _parents[user] = parent;
        _mychilders[parent].push(user);
    }

    function getMyChilders(address user)
        public
        view
        returns (address[] memory)
    {
        return _mychilders[user];
    }

    function getParent(address user) public view returns (address) {
        return _parents[user];
    }

    function getUserLevel(address user) public view returns (uint256) {
        return _userInfos[user].userlevel;
    }

    function getUserTeamHash(address user) public view returns (uint256) {
        return _userInfos[user].teamhash;
    }

    function getUserSelfHash(address user) public view returns (uint256) {
        return _userInfos[user].selfhash;
    }   

    function getOwner() public view returns (address) {
        return _owner;
    }

    function getFeeOwner() public view returns (address) {
        return _feeowner;
    }

    function setOwner(address newOwner) public returns (bool) {
        require(msg.sender == _owner);
        _owner = newOwner;
        return true;
    }

    function setFeeOwner(address newFeeOwner) public returns (bool) {
        require(msg.sender == _owner);
        _feeowner = newFeeOwner;
        return true;
    }

    function getTotalHash() public view returns (uint256) {
        return _nowtotalhash;
    }
}


//SourceUnit: Ownable.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import './Context.sol';

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
    constructor() {
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

//SourceUnit: ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

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
contract ReentrancyGuard {
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

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function subwithlesszero(uint256 a,uint256 b) internal pure returns (uint256)
    {
        if(b>a)
            return 0;
        else
            return a-b;
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


//SourceUnit: TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;

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
}