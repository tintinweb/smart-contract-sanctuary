/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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


/**
 * Upgrade agent interface inspired by Lunyr.
 *
 * Upgrade agent transfers tokens to a new contract.
 * Upgrade agent itself can be the token contract, or just a middle man contract doing the heavy lifting.
 */
abstract contract IUpgradeAgent {
    function isUpgradeAgent() external virtual pure returns (bool);
    function upgradeFrom(address _from, uint256 _value) public virtual;
    function originalSupply() public virtual view returns (uint256);
    function originalToken() public virtual view returns (address);
}



contract MystToken is Context, IERC20, IUpgradeAgent {
    using SafeMath for uint256;
    using Address for address;

    address immutable _originalToken;                        // Address of MYSTv1 token
    uint256 immutable _originalSupply;                       // Token supply of MYSTv1 token

    // The original MYST token and the new MYST token have a decimal difference of 10.
    // As such, minted values as well as the total supply comparisons need to offset all values
    // by 10 zeros to properly compare them.
    uint256 constant private DECIMAL_OFFSET = 1e10;

    bool constant public override isUpgradeAgent = true;     // Upgradeability interface marker
    address private _upgradeMaster;                          // He can enable future token migration
    IUpgradeAgent private _upgradeAgent;                     // The next contract where the tokens will be migrated
    uint256 private _totalUpgraded;                          // How many tokens we have upgraded by now

    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    string constant public name = "Mysterium";
    string constant public symbol = "MYST";
    uint8 constant public decimals = 18;

    // EIP712
    bytes32 public DOMAIN_SEPARATOR;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    // The nonces mapping is given for replay protection in permit function.
    mapping(address => uint) public nonces;

    // ERC20-allowances
    mapping (address => mapping (address => uint256)) private _allowances;

    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    // State of token upgrade
    enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading, Completed}

    // Token upgrade events
    event Upgrade(address indexed from, address agent, uint256 _value);
    event UpgradeAgentSet(address agent);
    event UpgradeMasterSet(address master);

    constructor(address originalToken) public {
        // upgradability settings
        _originalToken  = originalToken;
        _originalSupply = IERC20(originalToken).totalSupply();

        // set upgrade master
        _upgradeMaster = _msgSender();

        // construct EIP712 domain separator
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                _chainID(),
                address(this)
            )
        );
    }

    function totalSupply() public view override(IERC20) returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenHolder) public view override(IERC20) returns (uint256) {
        return _balances[tokenHolder];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _move(_msgSender(), recipient, amount);
        return true;
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function allowance(address holder, address spender) public view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * ERC2612 `permit`: 712-signed token approvals
     */
    function permit(address holder, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'MYST: Permit expired');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, holder, spender, value, nonces[holder]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == holder, 'MYST: invalid signature');
        _approve(holder, spender, value);
    }

    /**
    * Note that we're not decreasing allowance of uint(-1). This makes it simple to ERC777 operator.
    */
    function transferFrom(address holder, address recipient, uint256 amount) public override returns (bool) {
        // require(recipient != address(0), "MYST: transfer to the zero address");
        require(holder != address(0), "MYST: transfer from the zero address");
        address spender = _msgSender();

        // Allowance for uint256(-1) means "always allowed" and is analog for erc777 operators but in erc20 semantics.
        if (holder != spender && _allowances[holder][spender] != uint256(-1)) {
            _approve(holder, spender, _allowances[holder][spender].sub(amount, "MYST: transfer amount exceeds allowance"));
        }

        _move(holder, recipient, amount);
        return true;
    }

    /**
     * Creates `amount` tokens and assigns them to `holder`, increasing
     * the total supply.
     */
    function _mint(address holder, uint256 amount) internal {
        require(holder != address(0), "MYST: mint to the zero address");

        // Update state variables
        _totalSupply = _totalSupply.add(amount);
        _balances[holder] = _balances[holder].add(amount);

        emit Minted(holder, amount);
        emit Transfer(address(0), holder, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "MYST: burn from the zero address");

        // Update state variables
        _balances[from] = _balances[from].sub(amount, "MYST: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(from, address(0), amount);
        emit Burned(from, amount);
    }

    function _move(address from, address to, uint256 amount) private {
        // Sending to zero address is equal burning
        if (to == address(0)) {
            _burn(from, amount);
            return;
        }

        _balances[from] = _balances[from].sub(amount, "MYST: transfer amount exceeds balance");
        _balances[to] = _balances[to].add(amount);

        emit Transfer(from, to, amount);
    }

    function _approve(address holder, address spender, uint256 value) internal {
        require(holder != address(0), "MYST: approve from the zero address");
        require(spender != address(0), "MYST: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    // -------------- UPGRADE FROM v1 TOKEN --------------

    function originalToken() public view override returns (address) {
        return _originalToken;
    }

    function originalSupply() public view override returns (uint256) {
        return _originalSupply;
    }

    function upgradeFrom(address _account, uint256 _value) public override {
        require(msg.sender == originalToken(), "only original token can call upgradeFrom");

        // Value is multiplied by 0e10 as old token had decimals = 8?
        _mint(_account, _value.mul(DECIMAL_OFFSET));

        require(totalSupply() <= originalSupply().mul(DECIMAL_OFFSET), "can not mint more tokens than in original contract");
    }


    // -------------- PREPARE FOR FUTURE UPGRADABILITY --------------

    function upgradeMaster() public view returns (address) {
        return _upgradeMaster;
    }

    function upgradeAgent() public view returns (address) {
        return address(_upgradeAgent);
    }

    function totalUpgraded() public view returns (uint256) {
        return _totalUpgraded;
    }

    /**
     * Tokens can be upgraded by calling this function.
     */
    function upgrade(uint256 amount) public {
        UpgradeState state = getUpgradeState();
        require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading, "MYST: token is not in upgrading state");

        require(amount != 0, "MYST: upgradable amount should be more than 0");

        address holder = _msgSender();

        // Burn tokens to be upgraded
        _burn(holder, amount);

        // Remember how many tokens we have upgraded
        _totalUpgraded = _totalUpgraded.add(amount);

        // Upgrade agent upgrades/reissues tokens
        _upgradeAgent.upgradeFrom(holder, amount);
        emit Upgrade(holder, upgradeAgent(), amount);
    }

    function setUpgradeMaster(address newUpgradeMaster) external {
        require(newUpgradeMaster != address(0x0), "MYST: upgrade master can't be zero address");
        require(_msgSender() == _upgradeMaster, "MYST: only upgrade master can set new one");
        _upgradeMaster = newUpgradeMaster;

        emit UpgradeMasterSet(upgradeMaster());
    }

    function setUpgradeAgent(address agent) external {
        require(_msgSender()== _upgradeMaster, "MYST: only a master can designate the next agent");
        require(agent != address(0x0), "MYST: upgrade agent can't be zero address");
        require(getUpgradeState() != UpgradeState.Upgrading, "MYST: upgrade has already begun");

        _upgradeAgent = IUpgradeAgent(agent);
        require(_upgradeAgent.isUpgradeAgent(), "MYST: agent should implement IUpgradeAgent interface");

        // Make sure that token supplies match in source and target
        require(_upgradeAgent.originalSupply() == totalSupply(), "MYST: upgrade agent should know token's total supply");

        emit UpgradeAgentSet(upgradeAgent());
    }

    function getUpgradeState() public view returns(UpgradeState) {
        if(address(_upgradeAgent) == address(0x00)) return UpgradeState.WaitingForAgent;
        else if(_totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
        else if(totalSupply() == 0) return UpgradeState.Completed;
        else return UpgradeState.Upgrading;
    }

    // -------------- FUNDS RECOVERY --------------

    address internal _fundsDestination;
    event FundsRecoveryDestinationChanged(address indexed previousDestination, address indexed newDestination);

    /**
     * Setting new destination of funds recovery.
     */
    function setFundsDestination(address newDestination) public {
        require(_msgSender()== _upgradeMaster, "MYST: only a master can set funds destination");
        require(newDestination != address(0), "MYST: funds destination can't be zero addreess");

        _fundsDestination = newDestination;
        emit FundsRecoveryDestinationChanged(_fundsDestination, newDestination);
    }
    /**
     * Getting funds destination address.
     */
    function getFundsDestination() public view returns (address) {
        return _fundsDestination;
    }

    /**
       Transfers selected tokens into `_fundsDestination` address.
    */
    function claimTokens(address token) public {
        require(_fundsDestination != address(0));
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(_fundsDestination, amount);
    }

    // -------------- HELPERS --------------

    function _chainID() private pure returns (uint256) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }
        return chainID;
    }

    // -------------- TESTNET ONLY FUNCTIONS --------------

    function mint(address _account, uint _amount) public {
        require(_msgSender()== _upgradeMaster, "MYST: only a master can mint");
        _mint(_account, _amount);
    }
}