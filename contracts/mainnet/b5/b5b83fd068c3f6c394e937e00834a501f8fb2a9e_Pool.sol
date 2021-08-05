/**
 *Submitted for verification at Etherscan.io on 2020-12-15
*/

abstract contract TokenManager {
    
    address constant COMPOUND_DEPOSIT_ADDRESS = 0xeB21209ae4C2c9FF2a86ACA31E123764A3B6Bc06;
    address constant Y_DEPOSIT_ADDRESS      = 0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3;
    address constant BUSD_DEPOSIT_ADDRESS   = 0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB;
    address constant PAX_DEPOSIT_ADDRESS    = 0xA50cCc70b6a011CffDdf45057E39679379187287;
    address constant REN_DEPOSIT_ADDRESS    = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
    address constant SBTC_DEPOSIT_ADDRESS   = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;
    address constant HBTC_DEPOSIT_ADDRESS   = 0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F;
    
    address constant SWERVE_DEPOSIT_ADDRESS     = 0x329239599afB305DA0A2eC69c58F8a6697F9F88d;


    address constant COMPOUND_TOKEN_ADDRESS     = 0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2;
    address constant Y_TOKEN_ADDRESS        = 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8;
    address constant BUSD_TOKEN_ADDRESS         = 0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;
    address constant PAX_TOKEN_ADDRESS      = 0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8;
    address constant REN_TOKEN_ADDRESS      = 0x49849C98ae39Fff122806C06791Fa73784FB3675;
    address constant SBTC_TOKEN_ADDRESS         = 0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
    address constant HBTC_TOKEN_ADDRESS         = 0xb19059ebb43466C323583928285a49f558E572Fd;
    address constant SRW_TOKEN_ADDRESS      = 0x77C6E4a580c0dCE4E5c7a17d0bc077188a83A059;
    

    address constant COMPOUND_GAUGE_ADDRESS     = 0x7ca5b0a2910B33e9759DC7dDB0413949071D7575;
    address constant Y_GAUGE_ADDRESS        = 0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1;
    address constant BUSD_GAUGE_ADDRESS         = 0x69Fb7c45726cfE2baDeE8317005d3F94bE838840;
    address constant PAX_GAUGE_ADDRESS      = 0x64E3C23bfc40722d3B649844055F1D51c1ac041d;
    address constant REN_GAUGE_ADDRESS      = 0xB1F2cdeC61db658F091671F5f199635aEF202CAC;
    address constant SBTC_GAUGE_ADDRESS         = 0x705350c4BcD35c9441419DdD5d2f097d7a55410F;
    address constant SWERVE_GAUGE_ADDRESS   = 0xb4d0C929cD3A1FbDc6d57E7D3315cF0C4d6B4bFa;
    address constant HBTC_GAUGE_ADDRESS         = 0x4c18E409Dc8619bFb6a1cB56D114C3f592E0aE79;

    address constant CRV_TOKEN_MINTER_ADDRESS   = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    address constant SWERVE_TOKEN_MINTER_ADDRESS = 0x2c988c3974AD7E604E276AE0294a7228DEf67974;
    
    address constant CRV_TOKEN_ADDRESS      = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address constant SWERVE_TOKEN_ADDRESS   = 0xB8BAa0e4287890a5F79863aB62b7F175ceCbD433;
    

    address constant VOTING_ESCROW          = 0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2;
    
    address constant EXCHANGE_CONTRACT  = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
    address constant ETH_ADDRESS        = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant DAI_ADDRESS        = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant WBTC_ADDRESS        = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    
    address constant USDC_ADDRESS        = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT_ADDRESS        = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant TUSD_ADDRESS        = 0x0000000000085d4780B73119b644AE5ecd22b376;
    
    mapping(address => address[]) public supportAddresses;
    
    function getSupportAddresses(address _depositAddress) public view returns(address[] memory){
        return supportAddresses[_depositAddress];
    }
    
    
    constructor() public {
        
        supportAddresses[COMPOUND_DEPOSIT_ADDRESS].push(COMPOUND_TOKEN_ADDRESS);
        supportAddresses[COMPOUND_DEPOSIT_ADDRESS].push(COMPOUND_GAUGE_ADDRESS);
        
        supportAddresses[Y_DEPOSIT_ADDRESS].push(Y_TOKEN_ADDRESS);
        supportAddresses[Y_DEPOSIT_ADDRESS].push(Y_GAUGE_ADDRESS);
        
        supportAddresses[BUSD_DEPOSIT_ADDRESS].push(BUSD_TOKEN_ADDRESS);
        supportAddresses[BUSD_DEPOSIT_ADDRESS].push(BUSD_GAUGE_ADDRESS);
        
        supportAddresses[PAX_DEPOSIT_ADDRESS].push(PAX_TOKEN_ADDRESS);
        supportAddresses[PAX_DEPOSIT_ADDRESS].push(PAX_GAUGE_ADDRESS);
        
        supportAddresses[REN_DEPOSIT_ADDRESS].push(REN_TOKEN_ADDRESS);
        supportAddresses[REN_DEPOSIT_ADDRESS].push(REN_GAUGE_ADDRESS);
        
        supportAddresses[SBTC_DEPOSIT_ADDRESS].push(SBTC_TOKEN_ADDRESS);
        supportAddresses[SBTC_DEPOSIT_ADDRESS].push(SBTC_GAUGE_ADDRESS);
        
        supportAddresses[HBTC_DEPOSIT_ADDRESS].push(HBTC_TOKEN_ADDRESS);
        supportAddresses[HBTC_DEPOSIT_ADDRESS].push(HBTC_GAUGE_ADDRESS);
        
        supportAddresses[SWERVE_DEPOSIT_ADDRESS].push(SRW_TOKEN_ADDRESS);
        supportAddresses[SWERVE_DEPOSIT_ADDRESS].push(SWERVE_GAUGE_ADDRESS);
        
    }
}

pragma solidity ^0.6.0;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    constructor (string memory name, string memory symbol) public {
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
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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
        require(account != address(0), "ERC20: mint to the zero address");

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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract PoolToken is ERC20 {
    address public owner;
    address public poolManager;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public ERC20("PRJ Token BTC", "PRJ BTC") {
        owner = msg.sender;
    }
    
    function setPoolManager(address _newManagerAddress) public onlyOwner {
        poolManager = _newManagerAddress;
    }
    
    function mint(address account, uint amount) public {
        require(msg.sender == poolManager);
        _mint(account, amount);
    }
    
    function burn(address account, uint256 amount) public {
        require(msg.sender == poolManager);
         _burn(account, amount);
    }
}

abstract contract IOneSplitView {
    // disableFlags = FLAG_DISABLE_UNISWAP + FLAG_DISABLE_KYBER + ...
    uint256 public constant FLAG_DISABLE_UNISWAP = 0x01;
    uint256 public constant FLAG_DISABLE_KYBER = 0x02;
    uint256 public constant FLAG_ENABLE_KYBER_UNISWAP_RESERVE = 0x100000000; // Turned off by default
    uint256 public constant FLAG_ENABLE_KYBER_OASIS_RESERVE = 0x200000000; // Turned off by default
    uint256 public constant FLAG_ENABLE_KYBER_BANCOR_RESERVE = 0x400000000; // Turned off by default
    uint256 public constant FLAG_DISABLE_BANCOR = 0x04;
    uint256 public constant FLAG_DISABLE_OASIS = 0x08;
    uint256 public constant FLAG_DISABLE_COMPOUND = 0x10;
    uint256 public constant FLAG_DISABLE_FULCRUM = 0x20;
    uint256 public constant FLAG_DISABLE_CHAI = 0x40;
    uint256 public constant FLAG_DISABLE_AAVE = 0x80;
    uint256 public constant FLAG_DISABLE_SMART_TOKEN = 0x100;
    uint256 public constant FLAG_ENABLE_MULTI_PATH_ETH = 0x200; // Turned off by default
    uint256 public constant FLAG_DISABLE_BDAI = 0x400;
    uint256 public constant FLAG_DISABLE_IEARN = 0x800;
    uint256 public constant FLAG_DISABLE_CURVE_COMPOUND = 0x1000;
    uint256 public constant FLAG_DISABLE_CURVE_USDT = 0x2000;
    uint256 public constant FLAG_DISABLE_CURVE_Y = 0x4000;
    uint256 public constant FLAG_DISABLE_CURVE_BINANCE = 0x8000;
    uint256 public constant FLAG_ENABLE_MULTI_PATH_DAI = 0x10000; // Turned off by default
    uint256 public constant FLAG_ENABLE_MULTI_PATH_USDC = 0x20000; // Turned off by default
    uint256 public constant FLAG_DISABLE_CURVE_SYNTHETIX = 0x40000;
    uint256 public constant FLAG_DISABLE_WETH = 0x80000;
    uint256 public constant FLAG_ENABLE_UNISWAP_COMPOUND = 0x100000; // Works only with FLAG_ENABLE_MULTI_PATH_ETH

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        virtual
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );
}


abstract contract IOneSplit is IOneSplitView {
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 disableFlags
    ) virtual public payable;
}

contract PoolFactoryProxy is TokenManager {
    address public owner;
    address public implementation;
    
    address public poolTokenAddress;
    address public poolTokenBTCAddress;
    address public poolProxy;
    
    mapping (address => address) public usersStablePools;
    mapping (address => address) public usersBTCPools;
    uint public totalBalance;
    
    mapping(bool => address) public bestBoost;
    
    
    constructor(address _poolProxyAddress, address _poolTokenAddress, address _poolTokenBTCAddress, address _impl) public {
        implementation = _impl;
        poolProxy = _poolProxyAddress;
        poolTokenAddress = _poolTokenAddress;
        poolTokenBTCAddress = _poolTokenBTCAddress;
        owner = msg.sender;
    }

    function setImplementation(address _newImpl) public {
        require(msg.sender == owner);

        implementation = _newImpl;
    }
   
    fallback() virtual external {
        address impl = implementation;
        assembly {
            let ptr := mload(0x40)
 
            // (1) copy incoming call data
            calldatacopy(ptr, 0, calldatasize())
 
             // (2) forward call to logic contract
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
 
            // (3) retrieve return data
            returndatacopy(ptr, 0, size)
 
            // (4) forward return data back to caller
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }   
    }
}

contract PoolFactory is TokenManager {
    
    address public owner;
    address public implementation;
    
    address public poolTokenAddress;
    address public poolTokenBTCAddress;
    address public poolProxy;
    
    mapping (address => address) public usersStablePools;
    mapping (address => address) public usersBTCPools;
    uint public totalBalance;
    
    mapping(bool => address) public bestBoost;
    
    event NewPool(address indexed poolAddress, address indexed sender, bool isBTC);

    modifier poolOnly(address userAddress) {
        require(msg.sender == usersStablePools[userAddress] || msg.sender == usersBTCPools[userAddress]);
        _;
    }
    
    
    function setPoolProxyAddress(address _newProxy) public {
        require(msg.sender == owner);
        poolProxy = _newProxy;
    }
    
    function newStablePool() public {
        require(usersStablePools[msg.sender] == address(0), "pool already created");
        PoolProxy pool = new PoolProxy(msg.sender, false);
        usersStablePools[msg.sender] = address(pool);
        
        emit NewPool(address(pool), msg.sender, false);
    }
    
    function newBTCPool() public {
        require(usersBTCPools[msg.sender] == address(0), "pool already created");
        PoolProxy pool = new PoolProxy(msg.sender, true);
        usersBTCPools[msg.sender] = address(pool);
        
        emit NewPool(address(pool), msg.sender, true);
    }

    function setBestBoost(address _newBestBoost, address _newBestBoostBTC) public {
        require(msg.sender == owner);
        bestBoost[false] = _newBestBoost;
        bestBoost[true] = _newBestBoostBTC;
    }
    
    function mint(address to, uint amount, bool isBTCPool) public poolOnly(to) {
        if(isBTCPool) {
            PoolToken(poolTokenBTCAddress).mint(to, amount);
        } else {
            PoolToken(poolTokenAddress).mint(to, amount);
        }
        
    }
    
    function burn(address from, uint amount, bool isBTCPool) public poolOnly(from) {
        if(isBTCPool) {
            if (PoolToken(poolTokenBTCAddress).balanceOf(from) > amount) {
                PoolToken(poolTokenBTCAddress).burn(from, amount);
            } else {
                PoolToken(poolTokenBTCAddress).burn(from, PoolToken(poolTokenBTCAddress).balanceOf(from));
            }
            
        } else {
            if (PoolToken(poolTokenAddress).balanceOf(from) > amount) {
                PoolToken(poolTokenAddress).burn(from, amount);
            } else {
               PoolToken(poolTokenAddress).burn(from, PoolToken(poolTokenAddress).balanceOf(from));
            }
            
        }
    }
}

contract Deposit2Tokens {
    function add_liquidity(uint256[2] memory uamounts, uint256 min_mint_amount) public{}
    
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_uamount, bool donate_dust) public{}
    uint[100000000000000000000000000000] public period_timestamp;
}

contract Deposit3Tokens {
    function add_liquidity(uint256[3] memory uamounts, uint256 min_mint_amount) public{}
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_uamount) public{}
    uint[100000000000000000000000000000] public period_timestamp;
}

abstract contract Deposit4Tokens {
    function add_liquidity(uint[4] memory uamounts, uint256 min_mint_amount) virtual public;
    function remove_liquidity(uint256 _amount, uint256[4] memory min_amounts) public{}
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_uamount, bool donate_dust) virtual public;
    uint[100000000000000000000000000000] public period_timestamp;
}

abstract contract IGauge {
  function deposit(uint256 _value) virtual public;
  function withdraw(uint256 _value) virtual public;

  mapping(address => uint) public balanceOf;
}


abstract contract TokenMinter {
    function mint(address gauge_addr) virtual public;
}

contract PoolProxy is TokenManager {
    
    address public owner;
    address public poolFactoryAddress;
    bool public isBTCPool;

    constructor(address _owner, bool _isBTCPool) public {
        poolFactoryAddress = msg.sender;
        owner = _owner;
        isBTCPool = _isBTCPool;
    }

    fallback() external payable {
        address impl = implementation();
        assembly {
            let ptr := mload(0x40)
 
            // (1) copy incoming call data
            calldatacopy(ptr, 0, calldatasize())
 
             // (2) forward call to logic contract
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
 
            // (3) retrieve return data
            returndatacopy(ptr, 0, size)
 
            // (4) forward return data back to caller
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }   
    }

    function implementation() public view returns(address) {
        return PoolFactory(poolFactoryAddress).poolProxy();
    }
}

contract Pool is TokenManager {
    
    address public owner;
    address public poolFactoryAddress;
    bool public isBTCPool;
    
    modifier onlyOwner() {
        require (msg.sender == owner); 
        _; 
    }

    function deposit(address tokenAddress, uint amount) public payable {
        
        address poolAddress = PoolFactory(poolFactoryAddress).bestBoost(isBTCPool);
       
        if (isBTCPool) {
            _btcDeposit(poolAddress, tokenAddress, amount);
            return;
        }
        
        
        if (msg.value > 0) {
            _ethDeposit(poolAddress);
            return;
        }
        
        uint _amount = amount;
        uint[] memory _distribution;

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        if (tokenAddress != DAI_ADDRESS) {
            IERC20(tokenAddress).approve(EXCHANGE_CONTRACT, amount);
            (_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(tokenAddress), IERC20(DAI_ADDRESS), amount, 100, 0);
            IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(tokenAddress), IERC20(DAI_ADDRESS), amount, _amount, _distribution, 0);
        }

        
        (address lpTokenAddress, address gaugeAddress) = _deposit(poolAddress, _amount);
        
        PoolFactory(poolFactoryAddress).mint(msg.sender, IERC20(lpTokenAddress).balanceOf(address(this)), isBTCPool);

        depositLPTokens(lpTokenAddress, gaugeAddress, IERC20(lpTokenAddress).balanceOf(address(this)));
        
        
    }
    
    function _btcDeposit(address poolAddress, address tokenAddress, uint amount) internal {
        uint _amount = amount;
        uint[] memory _distribution;
            
        if (msg.value > 0) {
            (_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(ETH_ADDRESS), IERC20(WBTC_ADDRESS), msg.value, 100, 0);
            IOneSplit(EXCHANGE_CONTRACT).swap.value(msg.value)(IERC20(ETH_ADDRESS), IERC20(WBTC_ADDRESS), msg.value, _amount, _distribution, 0);

            uint wBTCamount = IERC20(WBTC_ADDRESS).balanceOf(address(this));
            
            (address lpTokenAddress, address gaugeAddress) = _deposit(poolAddress, _amount);
            
            uint lpAmount = IERC20(lpTokenAddress).balanceOf(address(this));
            
            
            PoolFactory(poolFactoryAddress).mint(msg.sender, IERC20(lpTokenAddress).balanceOf(address(this)), isBTCPool);
            depositLPTokens(lpTokenAddress, gaugeAddress, IERC20(lpTokenAddress).balanceOf(address(this)));
            return;
        }
        
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        if (tokenAddress != WBTC_ADDRESS) {
            IERC20(tokenAddress).approve(EXCHANGE_CONTRACT, amount);
            (_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(tokenAddress), IERC20(WBTC_ADDRESS), amount, 100, 0);
            IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(tokenAddress), IERC20(WBTC_ADDRESS), amount, _amount, _distribution, 0);
        }

        (address lpTokenAddress, address gaugeAddress) = _deposit(poolAddress, _amount);
        
        
        PoolFactory(poolFactoryAddress).mint(msg.sender, IERC20(lpTokenAddress).balanceOf(address(this)), isBTCPool);
        depositLPTokens(lpTokenAddress, gaugeAddress, IERC20(lpTokenAddress).balanceOf(address(this)));
    }

    function claimReward(address _depositAddress, bool isHarvest) public onlyOwner {
        
        address[] memory supAddresses = getSupportAddresses(_depositAddress); 
        if (supAddresses[1] == SWERVE_GAUGE_ADDRESS) {
            TokenMinter(SWERVE_TOKEN_MINTER_ADDRESS).mint(supAddresses[1]);
        } else {
            TokenMinter(CRV_TOKEN_MINTER_ADDRESS).mint(supAddresses[1]);
        }
        
        
        uint swerveTokenBalance = IERC20(SWERVE_TOKEN_ADDRESS).balanceOf(address(this));
        uint crvTokenBalance = IERC20(CRV_TOKEN_ADDRESS).balanceOf(address(this));
        
        if (isHarvest) {
            uint _amount;
            uint[] memory _distribution;
            
            if (swerveTokenBalance > 0) {
                IERC20(SWERVE_TOKEN_ADDRESS).approve(EXCHANGE_CONTRACT, swerveTokenBalance);
                (_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(SWERVE_TOKEN_ADDRESS), IERC20(DAI_ADDRESS), swerveTokenBalance, 100, 0);
                IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(SWERVE_TOKEN_ADDRESS), IERC20(DAI_ADDRESS), swerveTokenBalance, _amount, _distribution, 0);
            }
            
            if (crvTokenBalance > 0) {
                IERC20(CRV_TOKEN_ADDRESS).approve(EXCHANGE_CONTRACT, crvTokenBalance);
                (_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(CRV_TOKEN_ADDRESS), IERC20(DAI_ADDRESS), crvTokenBalance, 100, 0);
                IOneSplit(EXCHANGE_CONTRACT).swap(IERC20(CRV_TOKEN_ADDRESS), IERC20(DAI_ADDRESS), crvTokenBalance, _amount, _distribution, 0);
            }
            
            uint daiBalance = IERC20(DAI_ADDRESS).balanceOf(address(this));
            
            if(daiBalance > 0) {
                IERC20(DAI_ADDRESS).transfer(msg.sender, daiBalance);
            }
            
            return;
        }
        
        
        if(swerveTokenBalance > 0) {
            IERC20(SWERVE_TOKEN_ADDRESS).transfer(msg.sender, swerveTokenBalance);
        }
        
        if(crvTokenBalance > 0) {
            IERC20(CRV_TOKEN_ADDRESS).transfer(msg.sender, crvTokenBalance);
        }
    }

    function exit(address _depositAddress, uint value) public onlyOwner {
        claimReward(_depositAddress, false);
       
            
        address[] memory supAddresses = getSupportAddresses(_depositAddress);
          
        require(IGauge(supAddresses[1]).balanceOf(address(this)) > 0);
        
        IGauge(supAddresses[1]).withdraw(IGauge(supAddresses[1]).balanceOf(address(this)));
        
        uint bal = IERC20(supAddresses[0]).balanceOf(address(this));
        
        require(bal > 0);
        
        PoolFactory(poolFactoryAddress).burn(msg.sender, bal, isBTCPool);
            
        IERC20(supAddresses[0]).approve(_depositAddress, bal);
        if (!isBTCPool) {
          if (_depositAddress == SWERVE_DEPOSIT_ADDRESS) {
              uint[4] memory buf;
              Deposit4Tokens(_depositAddress).remove_liquidity(bal, buf);
          } else {
                Deposit2Tokens(_depositAddress).remove_liquidity_one_coin(bal, 0, 1, true);
          }
        } else {
            Deposit3Tokens(_depositAddress).remove_liquidity_one_coin(bal, 1, 1);
           
        }
        
        if (!isBTCPool) {
            if(IERC20(DAI_ADDRESS).balanceOf(address(this)) > 0) {
                IERC20(DAI_ADDRESS).transfer(msg.sender, IERC20(DAI_ADDRESS).balanceOf(address(this)));
            }
            
            if(IERC20(USDC_ADDRESS).balanceOf(address(this)) > 0) {
                IERC20(USDC_ADDRESS).transfer(msg.sender, IERC20(USDC_ADDRESS).balanceOf(address(this)));
            }
            
            // if(IERC20(USDT_ADDRESS).balanceOf(address(this)) > 0) {
            //     IERC20(USDT_ADDRESS).transfer(msg.sender, IERC20(USDT_ADDRESS).balanceOf(address(this)));
            // }
            
            if(IERC20(TUSD_ADDRESS).balanceOf(address(this)) > 0) {
                IERC20(TUSD_ADDRESS).transfer(msg.sender, IERC20(TUSD_ADDRESS).balanceOf(address(this)));
            }
        } else {
            IERC20(WBTC_ADDRESS).transfer(msg.sender, IERC20(WBTC_ADDRESS).balanceOf(address(this)));
        }
        
    }

    function withdrawTokenFromContract(address tokenAddress, uint amount) public onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }
    
    function _ethDeposit(address poolAddress) private {
        uint _amount;
        uint[] memory _distribution;

        (_amount, _distribution) = IOneSplit(EXCHANGE_CONTRACT).getExpectedReturn(IERC20(ETH_ADDRESS), IERC20(DAI_ADDRESS), msg.value, 100, 0);
        IOneSplit(EXCHANGE_CONTRACT).swap.value(msg.value)(IERC20(ETH_ADDRESS), IERC20(DAI_ADDRESS), msg.value, _amount, _distribution, 0);

        (address lpTokenAddress, address gaugeAddress) = _deposit(poolAddress, _amount);
        
        
        PoolFactory(poolFactoryAddress).mint(msg.sender, IERC20(lpTokenAddress).balanceOf(address(this)), isBTCPool);
        depositLPTokens(lpTokenAddress, gaugeAddress, IERC20(lpTokenAddress).balanceOf(address(this)));
    }
    
    function depositLPTokens(address lpTokenAddress, address gaugeAddress, uint value) internal {
        IERC20(lpTokenAddress).approve(gaugeAddress, value);
        IGauge(gaugeAddress).deposit(value);
    }

    function _deposit(address _depositPool, uint amount) internal returns(address, address) {
        IERC20(DAI_ADDRESS).approve(_depositPool, amount);

        if(_depositPool == COMPOUND_DEPOSIT_ADDRESS) {
            uint[2] memory uamounts;
            uamounts[0] = amount;
            Deposit2Tokens(_depositPool).add_liquidity(uamounts, 0);
            return (COMPOUND_TOKEN_ADDRESS, COMPOUND_GAUGE_ADDRESS);
        }
        
        if(_depositPool == Y_DEPOSIT_ADDRESS) {
            uint[4] memory uamounts;
            uamounts[0] = amount;
            Deposit4Tokens(_depositPool).add_liquidity(uamounts, 0);
            return (Y_TOKEN_ADDRESS, Y_GAUGE_ADDRESS);
        }

        if(_depositPool == BUSD_DEPOSIT_ADDRESS) {
            uint[4] memory uamounts;
            uamounts[0] = amount;
            Deposit4Tokens(_depositPool).add_liquidity(uamounts, 0);
            return (BUSD_TOKEN_ADDRESS, BUSD_GAUGE_ADDRESS);
        }

        if(_depositPool == PAX_DEPOSIT_ADDRESS) {
            uint[4] memory uamounts;
            uamounts[0] = amount;
            Deposit4Tokens(_depositPool).add_liquidity(uamounts, 0);
            return (PAX_TOKEN_ADDRESS, PAX_GAUGE_ADDRESS);
        } 

        if(_depositPool == REN_DEPOSIT_ADDRESS) {
            IERC20(WBTC_ADDRESS).approve(_depositPool, amount);
            uint[2] memory uamounts;
            uamounts[1] = amount;
            Deposit2Tokens(_depositPool).add_liquidity(uamounts, 0);
            return (REN_TOKEN_ADDRESS, REN_GAUGE_ADDRESS);
        } 

        if(_depositPool == SBTC_DEPOSIT_ADDRESS) {
            IERC20(WBTC_ADDRESS).approve(_depositPool, amount);
            uint[3] memory uamounts;
            uamounts[1] = amount;
            Deposit3Tokens(_depositPool).add_liquidity(uamounts, 0);
            return (SBTC_TOKEN_ADDRESS, SBTC_GAUGE_ADDRESS);
        }
        
        if(_depositPool == HBTC_DEPOSIT_ADDRESS) {
            IERC20(WBTC_ADDRESS).approve(_depositPool, amount);
            uint[2] memory uamounts;
            uamounts[1] = amount;
            Deposit2Tokens(_depositPool).add_liquidity(uamounts, 0);
            return (HBTC_TOKEN_ADDRESS, HBTC_GAUGE_ADDRESS);
        }

        if(_depositPool == SWERVE_DEPOSIT_ADDRESS) {
            uint[4] memory uamounts;
            uamounts[0] = amount;
            Deposit4Tokens(_depositPool).add_liquidity(uamounts, 0);
            return (SRW_TOKEN_ADDRESS, SWERVE_GAUGE_ADDRESS);
        }
    }
}