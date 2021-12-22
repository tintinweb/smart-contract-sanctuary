/**
 *Submitted for verification at polygonscan.com on 2021-12-21
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.5;

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]

//  MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

//  MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File @openzeppelin/contracts/security/[email protected]

//  MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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


// File contracts/OpolisPay.sol

//  LGPLv3



/// @notice custom errors for revert statements

/// @dev requires privileged access
error NotPermitted();

/// @dev not a whitelisted token
error NotWhitelisted();

/// @dev payroll id equals zero
error InvalidPayroll();

/// @dev amount equals zero
error InvalidAmount();

/// @dev sender is not a member
error NotMember();

/// @dev stake must be a non zero amount of whitelisted token
/// or non zero amount of eth
error InvalidStake();

/// @dev setting one of the role to zero address
error ZeroAddress();

/// @dev whitelisting and empty list of tokens
error ZeroTokens();

/// @dev token has already been whitelisted
error AlreadyWhitelisted();

/// @dev sending eth directly to contract address
error DirectTransfer();

/// @title OpolisPay
/// @notice Minimalist Contract for Crypto Payroll Payments
contract OpolisPay {
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    address[] public supportedTokens; //Tokens that can be sent. 
    address public opolisAdmin; //Should be Opolis multi-sig for security
    address payable public destination; // Where funds are liquidated 
    address public opolisHelper; //Can be bot wallet for convenience 
    
    uint256[] public payrollIds; //List of payrollIds associated with payments
    uint256[] public stakes; //List of members who have staked
    
    event SetupComplete(address indexed destination, address indexed admin, address indexed helper, address[] tokens);
    event Staked(address indexed staker, address indexed token, uint256 amount, uint256 indexed memberId);
    event Paid(address indexed payor, address indexed token, uint256 indexed payrollId, uint256 amount); 
    event OpsPayrollWithdraw(address indexed token, uint256 indexed payrollId, uint256 amount);
    event OpsStakeWithdraw(address indexed token, uint256 indexed stakeId, uint256 amount);
    event Sweep(address indexed token, uint256 amount);
    event NewDestination(address indexed destination);
    event NewAdmin(address indexed opolisAdmin);
    event NewHelper(address indexed newHelper);
    event NewTokens(address[] newTokens);
    
    mapping (uint256 => bool) public payrollWithdrawn; //Tracks payroll withdrawals
    mapping (uint256 => bool) public stakeWithdrawn; //Tracks stake withdrawals
    mapping (address => bool) public whitelisted; //Tracks whitelisted tokens
    
    modifier onlyAdmin {
        if(msg.sender != opolisAdmin) revert NotPermitted();
        _;
    }
    
    modifier onlyOpolis {
        if (!(msg.sender == opolisAdmin || msg.sender == opolisHelper)) revert NotPermitted();
        _;
    }
    
    /// @notice launches contract with a destination as the Opolis wallet, the admins, and a token whitelist
    /// @param _destination the address where payroll and stakes will be sent when withdrawn 
    /// @param _opolisAdmin the multi-sig which is the ultimate admin 
    /// @param _opolisHelper meant to allow for a bot to handle less sensitive items 
    /// @param _tokenList initial whitelist of tokens for staking and payroll 
    
    constructor (
        address payable _destination,
        address _opolisAdmin,
        address _opolisHelper,
        address[] memory _tokenList
    ) {
        destination = _destination; 
        opolisAdmin = _opolisAdmin;
        opolisHelper = _opolisHelper;
        
        for (uint256 i = 0; i < _tokenList.length; i++) {
            _addToken(_tokenList[i]);
        }
        
        emit SetupComplete(destination, opolisAdmin, opolisHelper, _tokenList);

    }
    
    /********************************************************************************
                             CORE PAYROLL FUNCTIONS 
     *******************************************************************************/
     
     /// @notice core function for members to pay their payroll 
     /// @param token the token being used to pay for their payroll 
     /// @param amount the amount due for their payroll -- up to user / front-end to match 
     /// @param payrollId the way we'll associate payments with members' invoices 
     
    function payPayroll(address token, uint256 amount, uint256 payrollId) external {
        
        if (!whitelisted[token]) revert NotWhitelisted();
        if (payrollId == 0) revert InvalidPayroll();
        if (amount == 0) revert InvalidAmount();
        
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        payrollIds.push(payrollId);
        
        emit Paid(msg.sender, token, payrollId, amount); 
    }
    
    /// @notice staking function that allows for both ETH and whitelisted ERC20  
    /// @param token the token being used to stake 
    /// @param amount the amount due for staking -- up to user / front-end to match 
    /// @param memberId the way we'll associate the stake with a new member 
    
    function memberStake(address token, uint256 amount, uint256 memberId) public payable {
        if (
            !(
                (whitelisted[token] && amount !=0) || (token == address(0) && msg.value != 0)
            )
        ) revert InvalidStake();
        if (memberId == 0) revert NotMember();
        
        // @dev function for auto transfering out stakes 

        if (msg.value > 0 && token == address(0)){
            destination.transfer(msg.value);
            emit Staked(msg.sender, ETH, msg.value, memberId);
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }
        stakes.push(memberId);

        emit Staked(msg.sender, token, amount, memberId);
    }

    /// @notice withdraw function for admin or OpsBot to call   
    /// @param _payrollIds the paid payrolls we want to clear out 
    /// @param _payrollTokens the tokens the payrolls were paid in
    /// @param _payrollAmounts the amount that was paid
    /// @dev we iterate through payrolls and clear them out with the funds being sent to the destination address
    
    function withdrawPayrolls(
        uint256[] calldata _payrollIds,
        address[] calldata _payrollTokens,
        uint256[] calldata _payrollAmounts
    ) external onlyOpolis {
        uint256[] memory withdrawAmounts = new uint256[](supportedTokens.length);
        for (uint16 i = 0; i < _payrollIds.length; i++){
            uint256 id = _payrollIds[i];
            address token = _payrollTokens[i];
            uint256 amount = _payrollAmounts[i];
            
            if (!payrollWithdrawn[id]) {
                for (uint8 j = 0; j < supportedTokens.length; j++) {
                    if (supportedTokens[j] == token) {
                        withdrawAmounts[j] += amount;
                        break;
                    }
                }
                payrollWithdrawn[id] = true;
                
                emit OpsPayrollWithdraw(token, id, amount);
            }
        }

        for (uint16 i = 0; i < withdrawAmounts.length; i++){
            uint256 amount = withdrawAmounts[i];
            if (amount > 0) {
                _withdraw(supportedTokens[i], amount);
            }
        }
    }

    /// @notice withdraw function for admin or OpsBot to call   
    /// @param _stakeIds the paid stakes we want to clear out 
    /// @param _stakeTokens the tokens the stakes were paid in
    /// @param _stakeAmounts the amount that was paid
    /// @dev we iterate through stakes and clear them out with the funds being sent to the destination address
    function withdrawStakes(
        uint256[] calldata _stakeIds,
        address[] calldata _stakeTokens,
        uint256[] calldata _stakeAmounts
    ) external onlyOpolis {
        uint256[] memory withdrawAmounts = new uint256[](supportedTokens.length);
        for (uint16 i = 0; i < _stakeIds.length; i++){
            uint256 id = _stakeIds[i];
            address token = _stakeTokens[i];
            uint256 amount = _stakeAmounts[i];
            
            if (!stakeWithdrawn[id]) {
                for (uint8 j = 0; j < supportedTokens.length; j++) {
                    if (supportedTokens[j] == token) {
                        withdrawAmounts[j] += amount;
                        break;
                    }
                }
                stakeWithdrawn[id] = true;
                
                emit OpsStakeWithdraw(token, id, amount);
            }
        }

        for (uint16 i = 0; i < withdrawAmounts.length; i++){
            uint256 amount = withdrawAmounts[i];
            if (amount > 0) {
                _withdraw(supportedTokens[i], amount);
            }
        }
    }
    
    /// @notice clearBalance() is meant to be a safety function to be used for stuck funds or upgrades
    /// @dev will mark any non-withdrawn payrolls as withdrawn
    
    function clearBalance() public onlyAdmin {
        
        for (uint256 i = 0; i < supportedTokens.length; i++){
            address token = supportedTokens[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            
            if(balance > 0){
                _withdraw(token, balance); 
            }
            emit Sweep(token, balance);
        }

    }

    /// @notice fallback function to prevent accidental ether transfers
    /// @dev if someone tries to send ether directly to the contract the tx will fail

    receive() external payable {
        revert DirectTransfer();
    }
    
    
    /********************************************************************************
                             ADMIN FUNCTIONS 
     *******************************************************************************/

    /// @notice this function is used to adjust where member funds are sent by contract
    /// @param newDestination is the new address where funds are sent (assumes it's payable exchange address)
    /// @dev must be called by Opolis Admin multi-sig
    
    function updateDestination(address payable newDestination) external onlyAdmin returns (address){
        
        if (newDestination == address(0)) revert ZeroAddress();
        destination = newDestination;
        
        emit NewDestination(destination);
        return destination;
    }
    
    /// @notice this function is used to replace the admin multi-sig
    /// @param newAdmin is the new admin address
    /// @dev this should always be a mulit-sig 
    
    function updateAdmin(address newAdmin) external onlyAdmin returns (address){
        
        if (newAdmin == address(0)) revert ZeroAddress();
        opolisAdmin = newAdmin;
      
        emit NewAdmin(opolisAdmin);
        return opolisAdmin;
    }
    
    /// @notice this function is used to replace a bot 
    /// @param newHelper is the new bot address
    /// @dev this can be a hot wallet, since it has limited powers
    
    function updateHelper(address newHelper) external onlyAdmin returns (address){
        
        if (newHelper == address(0)) revert ZeroAddress();
        opolisHelper = newHelper;
      
        emit NewHelper(opolisHelper);
        return opolisHelper;
    }
    
    /// @notice this function is used to add new whitelisted tokens
    /// @param newTokens are the tokens to be whitelisted
    /// @dev restricted to admin b/c this is a business / compliance decision 
    
    function addTokens(address[] memory newTokens) external onlyAdmin {
        
        if (newTokens.length == 0) revert ZeroTokens();
        
        for (uint256 i = 0; i < newTokens.length; i ++){
            _addToken(newTokens[i]);
        }
        
         emit NewTokens(newTokens);  
    }
    
    /********************************************************************************
                             INTERNAL FUNCTIONS 
     *******************************************************************************/
    
    function _addToken(address token) internal {
        if (whitelisted[token]) revert AlreadyWhitelisted();
        if (token == address(0)) revert ZeroAddress();
        supportedTokens.push(token);
        whitelisted[token] = true;
        
    }

    function _withdraw(address token, uint256 amount) internal {
        IERC20(token).transfer(destination, amount);
    }
    
}


// File contracts/test/TestToken.sol

//  UNLICENSED

/**
 * Simple token contract for running tests
 */
contract TestToken is ERC20 {
    constructor() ERC20("TestToken", "TT") {
        mint(msg.sender, 100 ether);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}