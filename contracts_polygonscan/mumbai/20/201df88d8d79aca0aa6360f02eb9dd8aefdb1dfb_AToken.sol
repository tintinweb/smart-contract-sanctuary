/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

/**
 *Submitted for verification at Etherscan.io on 2020-01-10
*/

pragma solidity ^0.5.17;

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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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


/**
* @title WadRayMath library
* @author Aave
* @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
**/

library WadRayMath {
    using SafeMath for uint256;

    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
    * @return one ray, 1e27
    **/
    function ray() internal pure returns (uint256) {
        return RAY;
    }

    /**
    * @return one wad, 1e18
    **/

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    /**
    * @return half ray, 1e27/2
    **/
    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    /**
    * @return half ray, 1e18/2
    **/
    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    /**
    * @dev multiplies two wad, rounding half up to the nearest wad
    * @param a wad
    * @param b wad
    * @return the result of a*b, in wad
    **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfWAD.add(a.mul(b)).div(WAD);
    }

    /**
    * @dev divides two wad, rounding half up to the nearest wad
    * @param a wad
    * @param b wad
    * @return the result of a/b, in wad
    **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(WAD)).div(b);
    }

    /**
    * @dev multiplies two ray, rounding half up to the nearest ray
    * @param a ray
    * @param b ray
    * @return the result of a*b, in ray
    **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfRAY.add(a.mul(b)).div(RAY);
    }

    /**
    * @dev divides two ray, rounding half up to the nearest ray
    * @param a ray
    * @param b ray
    * @return the result of a/b, in ray
    **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(RAY)).div(b);
    }

    /**
    * @dev casts ray down to wad
    * @param a ray
    * @return a casted to wad, rounded half up to the nearest wad
    **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;

        return halfRatio.add(a).div(WAD_RAY_RATIO);
    }

    /**
    * @dev convert wad up to ray
    * @param a wad
    * @return a converted in ray
    **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        return a.mul(WAD_RAY_RATIO);
    }

    /**
    * @dev calculates base^exp. The code uses the ModExp precompile
    * @return base^exp, in ray
    */
    //solium-disable-next-line
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }

}


/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
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
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
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
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
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
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
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
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
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
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
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
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
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
     * Emits a `Transfer` event with `from` set to the zero address.
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
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
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
     * Emits an `Approval` event.
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
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


/**
 * @title Aave ERC20 AToken
 *
 * @dev Implementation of the interest bearing token for the DLP protocol.
 * @author Aave
 */
contract AToken is ERC20, ERC20Detailed {
    using WadRayMath for uint256;

    uint256 public constant UINT_MAX_VALUE = uint256(-1);

    /**
    * @dev emitted during the transfer action
    * @param _from the address from which the tokens are being transferred
    * @param _to the adress of the destination
    * @param _value the amount to be minted
    * @param _fromBalanceIncrease the cumulated balance since the last update of the user
    * @param _toBalanceIncrease the cumulated balance since the last update of the destination
    * @param _fromIndex the last index of the user
    * @param _toIndex the last index of the liquidator
    **/
    event BalanceTransfer(
        address indexed _from,
        address indexed _to,
        uint256 _value,
        uint256 _fromBalanceIncrease,
        uint256 _toBalanceIncrease,
        uint256 _fromIndex,
        uint256 _toIndex
    );

    /**
    * @dev emitted when the accumulation of the interest
    * by an user is redirected to another user
    * @param _from the address from which the interest is being redirected
    * @param _to the adress of the destination
    * @param _fromBalanceIncrease the cumulated balance since the last update of the user
    * @param _fromIndex the last index of the user
    **/
    event InterestStreamRedirected(
        address indexed _from,
        address indexed _to,
        uint256 _redirectedBalance,
        uint256 _fromBalanceIncrease,
        uint256 _fromIndex
    );

    /**
    * @dev emitted when the redirected balance of an user is being updated
    * @param _targetAddress the address of which the balance is being updated
    * @param _targetBalanceIncrease the cumulated balance since the last update of the target
    * @param _targetIndex the last index of the user
    * @param _redirectedBalanceAdded the redirected balance being added
    * @param _redirectedBalanceRemoved the redirected balance being removed
    **/
    event RedirectedBalanceUpdated(
        address indexed _targetAddress,
        uint256 _targetBalanceIncrease,
        uint256 _targetIndex,
        uint256 _redirectedBalanceAdded,
        uint256 _redirectedBalanceRemoved
    );

    event InterestRedirectionAllowanceChanged(
        address indexed _from,
        address indexed _to
    );

    address public underlyingAssetAddress;

    mapping (address => uint256) private userIndexes;
    mapping (address => address) private interestRedirectionAddresses;
    mapping (address => uint256) private redirectedBalances;
    mapping (address => address) private interestRedirectionAllowances;       

    address childChainManager;

    modifier whenTransferAllowed(address _from, uint256 _amount) {
        require(isTransferAllowed(_from, _amount), "Transfer cannot be allowed.");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _childChainManager
    ) public ERC20Detailed(_name, _symbol, 18) {       
        childChainManager = _childChainManager;
    }

    function mint() external {
        mint(msg.sender, 25e18);
    }

    function mint(address _account, uint _amount) public {
        //cumulates the balance of the user
        (,
        ,
        uint256 balanceIncrease,
        ) = cumulateBalanceInternal(_account);

        
         //if the user is redirecting his interest towards someone else,
        //we update the redirected balance of the redirection address by adding the accrued interest
        //and the amount deposited
        updateRedirectedBalanceOfRedirectionAddressInternal(_account, balanceIncrease.add(_amount), 0);

        _mint(_account, _amount);        
    }

        /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData)
        external                
    {
        require(msg.sender == childChainManager, "AToken: Only childChainManager can deposit");
        uint256 amount = abi.decode(depositData, (uint256));
        mint(user, amount);
    }

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @notice ERC20 implementation internal function backing transfer() and transferFrom()
     * @dev validates the transfer before allowing it. NOTE: This is not standard ERC20 behavior
     **/
    function _transfer(address _from, address _to, uint256 _amount) internal whenTransferAllowed(_from, _amount) {

        executeTransferInternal(_from, _to, _amount);
    }


    /**
    * @dev redirects the interest generated to a target address.
    * when the interest is redirected, the user balance is added to
    * the recepient redirected balance.
    * @param _to the address to which the interest will be redirected
    **/
    function redirectInterestStream(address _to) external {
        redirectInterestStreamInternal(msg.sender, _to);
    }

    /**
    * @dev redirects the interest generated by _from to a target address.
    * when the interest is redirected, the user balance is added to
    * the recepient redirected balance. The caller needs to have allowance on
    * the interest redirection to be able to execute the function.
    * @param _from the address of the user whom interest is being redirected
    * @param _to the address to which the interest will be redirected
    **/
    function redirectInterestStreamOf(address _from, address _to) external {
        require(
            msg.sender == interestRedirectionAllowances[_from],
            "Caller is not allowed to redirect the interest of the user"
        );
        redirectInterestStreamInternal(_from,_to);
    }

    /**
    * @dev gives allowance to an address to execute the interest redirection
    * on behalf of the caller.
    * @param _to the address to which the interest will be redirected. Pass address(0) to reset
    * the allowance.
    **/
    function allowInterestRedirectionTo(address _to) external {
        require(_to != msg.sender, "User cannot give allowance to himself");
        interestRedirectionAllowances[msg.sender] = _to;
        emit InterestRedirectionAllowanceChanged(
            msg.sender,
            _to
        );
    }

    /**
    * @dev calculates the balance of the user, which is the
    * principal balance + interest generated by the principal balance + interest generated by the redirected balance
    * @param _user the user for which the balance is being calculated
    * @return the total balance of the user
    **/
    function balanceOf(address _user) public view returns(uint256) {

        //current principal balance of the user
        uint256 currentPrincipalBalance = super.balanceOf(_user);
        //balance redirected by other users to _user for interest rate accrual
        uint256 redirectedBalance = redirectedBalances[_user];

        if(currentPrincipalBalance == 0 && redirectedBalance == 0){
            return 0;
        }
        //if the _user is not redirecting the interest to anybody, accrues
        //the interest for himself

        if(interestRedirectionAddresses[_user] == address(0)){

            //accruing for himself means that both the principal balance and
            //the redirected balance partecipate in the interest
            return calculateCumulatedBalanceInternal(
                _user,
                currentPrincipalBalance.add(redirectedBalance)
                )
                .sub(redirectedBalance);
        }
        else {
            //if the user redirected the interest, then only the redirected
            //balance generates interest. In that case, the interest generated
            //by the redirected balance is added to the current principal balance.
            return currentPrincipalBalance.add(
                calculateCumulatedBalanceInternal(
                    _user,
                    redirectedBalance
                )
                .sub(redirectedBalance)
            );
        }
    }

    /**
    * @dev returns the principal balance of the user. The principal balance is the last
    * updated stored balance, which does not consider the perpetually accruing interest.
    * @param _user the address of the user
    * @return the principal balance of the user
    **/
    function principalBalanceOf(address _user) external view returns(uint256) {
        return super.balanceOf(_user);
    }

    function getReserveNormalizedIncome() internal pure returns (uint income) {
        income = 1051466485973488491189067599;
    }

    /**
    * @dev calculates the total supply of the specific aToken
    * since the balance of every single user increases over time, the total supply
    * does that too.
    * @return the current total supply
    **/
    function totalSupply() public view returns(uint256) {

        uint256 currentSupplyPrincipal = super.totalSupply();

        if(currentSupplyPrincipal == 0){
            return 0;
        }

        return currentSupplyPrincipal
            .wadToRay()
            .rayMul(getReserveNormalizedIncome())
            .rayToWad();
    }


    /**
     * @dev Used to validate transfers before actually executing them.
     * @param _user address of the user to check
     * @param _amount the amount to check
     * @return true if the _user can transfer _amount, false otherwise
     **/
    function isTransferAllowed(address _user, uint256 _amount) public view returns (bool) {
        //return dataProvider.balanceDecreaseAllowed(underlyingAssetAddress, _user, _amount);
        return true;
    }

    /**
    * @dev returns the last index of the user, used to calculate the balance of the user
    * @param _user address of the user
    * @return the last user index
    **/
    function getUserIndex(address _user) external view returns(uint256) {
        return userIndexes[_user];
    }


    /**
    * @dev returns the address to which the interest is redirected
    * @param _user address of the user
    * @return 0 if there is no redirection, an address otherwise
    **/
    function getInterestRedirectionAddress(address _user) external view returns(address) {
        return interestRedirectionAddresses[_user];
    }

    /**
    * @dev returns the redirected balance of the user. The redirected balance is the balance
    * redirected by other accounts to the user, that is accrueing interest for him.
    * @param _user address of the user
    * @return the total redirected balance
    **/
    function getRedirectedBalance(address _user) external view returns(uint256) {
        return redirectedBalances[_user];
    }

    /**
    * @dev accumulates the accrued interest of the user to the principal balance
    * @param _user the address of the user for which the interest is being accumulated
    * @return the previous principal balance, the new principal balance, the balance increase
    * and the new user index
    **/
    function cumulateBalanceInternal(address _user)
        internal
        returns(uint256, uint256, uint256, uint256) {

        uint256 previousPrincipalBalance = super.balanceOf(_user);

        //calculate the accrued interest since the last accumulation
        uint256 balanceIncrease = balanceOf(_user).sub(previousPrincipalBalance);
        //mints an amount of tokens equivalent to the amount accumulated
        _mint(_user, balanceIncrease);
        //updates the user index
        uint256 index = userIndexes[_user] = getReserveNormalizedIncome();
        return (
            previousPrincipalBalance,
            previousPrincipalBalance.add(balanceIncrease),
            balanceIncrease,
            index
        );
    }

    /**
    * @dev updates the redirected balance of the user. If the user is not redirecting his
    * interest, nothing is executed.
    * @param _user the address of the user for which the interest is being accumulated
    * @param _balanceToAdd the amount to add to the redirected balance
    * @param _balanceToRemove the amount to remove from the redirected balance
    **/
    function updateRedirectedBalanceOfRedirectionAddressInternal(
        address _user,
        uint256 _balanceToAdd,
        uint256 _balanceToRemove
    ) internal {

        address redirectionAddress = interestRedirectionAddresses[_user];
        //if there isn't any redirection, nothing to be done
        if(redirectionAddress == address(0)){
            return;
        }

        //compound balances of the redirected address
        (,,uint256 balanceIncrease, uint256 index) = cumulateBalanceInternal(redirectionAddress);

        //updating the redirected balance
        redirectedBalances[redirectionAddress] = redirectedBalances[redirectionAddress]
            .add(_balanceToAdd)
            .sub(_balanceToRemove);

        //if the interest of redirectionAddress is also being redirected, we need to update
        //the redirected balance of the redirection target by adding the balance increase
        address targetOfRedirectionAddress = interestRedirectionAddresses[redirectionAddress];

        if(targetOfRedirectionAddress != address(0)){
            redirectedBalances[targetOfRedirectionAddress] = redirectedBalances[targetOfRedirectionAddress].add(balanceIncrease);
        }

        emit RedirectedBalanceUpdated(
            redirectionAddress,
            balanceIncrease,
            index,
            _balanceToAdd,
            _balanceToRemove
        );
    }

    /**
    * @dev calculate the interest accrued by _user on a specific balance
    * @param _user the address of the user for which the interest is being accumulated
    * @param _balance the balance on which the interest is calculated
    * @return the interest rate accrued
    **/
    function calculateCumulatedBalanceInternal(
        address _user,
        uint256 _balance
    ) internal view returns (uint256) {
        return _balance
            .wadToRay()
            .rayMul(getReserveNormalizedIncome())
            .rayDiv(userIndexes[_user])
            .rayToWad();
    }

    /**
    * @dev executes the transfer of aTokens, invoked by both _transfer() and
    *      transferOnLiquidation()
    * @param _from the address from which transfer the aTokens
    * @param _to the destination address
    * @param _value the amount to transfer
    **/
    function executeTransferInternal(
        address _from,
        address _to,
        uint256 _value
    ) internal {

        require(_value > 0, "Transferred amount needs to be greater than zero");

        //cumulate the balance of the sender
        (,
        uint256 fromBalance,
        uint256 fromBalanceIncrease,
        uint256 fromIndex
        ) = cumulateBalanceInternal(_from);

        //cumulate the balance of the receiver
        (,
        ,
        uint256 toBalanceIncrease,
        uint256 toIndex
        ) = cumulateBalanceInternal(_to);

        //if the sender is redirecting his interest towards someone else,
        //adds to the redirected balance the accrued interest and removes the amount
        //being transferred
        updateRedirectedBalanceOfRedirectionAddressInternal(_from, fromBalanceIncrease, _value);

        //if the receiver is redirecting his interest towards someone else,
        //adds to the redirected balance the accrued interest and the amount
        //being transferred
        updateRedirectedBalanceOfRedirectionAddressInternal(_to, toBalanceIncrease.add(_value), 0);

        //performs the transfer
        super._transfer(_from, _to, _value);

        bool fromIndexReset = false;
        //reset the user data if the remaining balance is 0
        if(fromBalance.sub(_value) == 0){
            fromIndexReset = resetDataOnZeroBalanceInternal(_from);
        }

        emit BalanceTransfer(
            _from,
            _to,
            _value,
            fromBalanceIncrease,
            toBalanceIncrease,
            fromIndexReset ? 0 : fromIndex,
            toIndex
        );
    }

    /**
    * @dev executes the redirection of the interest from one address to another.
    * immediately after redirection, the destination address will start to accrue interest.
    * @param _from the address from which transfer the aTokens
    * @param _to the destination address
    **/
    function redirectInterestStreamInternal(
        address _from,
        address _to
    ) internal {

        address currentRedirectionAddress = interestRedirectionAddresses[_from];

        require(_to != currentRedirectionAddress, "Interest is already redirected to the user");

        //accumulates the accrued interest to the principal
        (uint256 previousPrincipalBalance,
        uint256 fromBalance,
        uint256 balanceIncrease,
        uint256 fromIndex) = cumulateBalanceInternal(_from);

        require(fromBalance > 0, "Interest stream can only be redirected if there is a valid balance");

        //if the user is already redirecting the interest to someone, before changing
        //the redirection address we substract the redirected balance of the previous
        //recipient
        if(currentRedirectionAddress != address(0)){
            updateRedirectedBalanceOfRedirectionAddressInternal(_from,0, previousPrincipalBalance);
        }

        //if the user is redirecting the interest back to himself,
        //we simply set to 0 the interest redirection address
        if(_to == _from) {
            interestRedirectionAddresses[_from] = address(0);
            emit InterestStreamRedirected(
                _from,
                address(0),
                fromBalance,
                balanceIncrease,
                fromIndex
            );
            return;
        }

        //first set the redirection address to the new recipient
        interestRedirectionAddresses[_from] = _to;

        //adds the user balance to the redirected balance of the destination
        updateRedirectedBalanceOfRedirectionAddressInternal(_from,fromBalance,0);

        emit InterestStreamRedirected(
            _from,
            _to,
            fromBalance,
            balanceIncrease,
            fromIndex
        );
    }

    /**
    * @dev function to reset the interest stream redirection and the user index, if the
    * user has no balance left.
    * @param _user the address of the user
    * @return true if the user index has also been reset, false otherwise. useful to emit the proper user index value
    **/
    function resetDataOnZeroBalanceInternal(address _user) internal returns(bool) {

        //if the user has 0 principal balance, the interest stream redirection gets reset
        interestRedirectionAddresses[_user] = address(0);

        //emits a InterestStreamRedirected event to notify that the redirection has been reset
        emit InterestStreamRedirected(_user, address(0),0,0,0);

        //if the redirected balance is also 0, we clear up the user index
        if(redirectedBalances[_user] == 0){
            userIndexes[_user] = 0;
            return true;
        }
        else{
            return false;
        }
    }
}