/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

//

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

//

pragma solidity ^0.8.0;

/*
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

//

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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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


// File contracts/utils/ERC1404.sol

pragma solidity 0.8.9;

abstract contract ERC1404 is ERC20 {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    /// @dev Overwrite with your custom transfer restriction logic
    function detectTransferRestriction (address from, address to, uint256 value) public virtual view returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    /// @dev Overwrite with your custom message and restrictionCode handling
    function messageForTransferRestriction (uint8 restrictionCode) public virtual view returns (string memory);
}


// File @openzeppelin/contracts/access/[email protected]

//

pragma solidity ^0.8.0;

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


// File contracts/SecurityToken.sol


pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;


/// @title Contract that implements the Security Token to manage the Bonding Curve
/// @dev This Token is being bonded in the Bonding Curve to gain Coordination Token
///      which is being used in the games. Security Token is strictly managed and
///      only whitelisted stakeholders are allowed to own it.
///      Reference implementation of ERC1404 can be found here:
///      https://github.com/simple-restricted-token/reference-implementation/blob/master/contracts/token/ERC1404/ERC1404ReferenceImpl.sol
///      https://github.com/simple-restricted-token/simple-restricted-token/blob/master/contracts/token/ERC1404/SimpleRestrictedToken.sol
contract SecurityToken is ERC1404, Ownable {

    uint8 constant private SUCCESS_CODE = 0;
    uint8 constant private ERR_RECIPIENT_CODE = 1;
    uint8 constant private ERR_BONDING_CURVE_CODE = 2;
    uint8 constant private ERR_NOT_WHITELISTED_CODE = 3;
    string constant private SUCCESS_MESSAGE = "SecurityToken: SUCCESS";
    string constant private ERR_RECIPIENT_MESSAGE = "SecurityToken: RECIPIENT SHOULD BE IN THE WHITELIST";
    string constant private ERR_BONDING_CURVE_MESSAGE = "SecurityToken: CAN TRANSFER ONLY TO BONDING CURVE";
    string constant private ERR_NOT_WHITELISTED_MESSAGE = "SecurityToken: ONLY WHITELISTED USERS CAN TRANSFER TOKEN";


    struct Role {
        bool awo;
        bool sco;
    }

    mapping(address => Role) private operators;
    mapping(address => bool) private whitelist;
    address private bondingCurve;


    event NewSCO(address operator);
    event RemovedSCO(address operator);
    event NewAWO(address operator);
    event RemovedAWO(address operator);

    /// @dev Reverts if the caller is not a Securities Control Operator or an owner
    modifier onlySCOperator() {
        require(owner() == msg.sender || operators[msg.sender].sco == true,
            "SecurityToken: Only SC operators are allowed to mint/burn token");
        _;
    }

    /// @dev Reverts if the caller is not an Accreditation Whitelist Operator or an owner
    modifier onlyAWOperator() {
        require(owner() == msg.sender || operators[msg.sender].awo == true,
            "SecurityToken: Only AW operators are allowed to change whitelist");
        _;
    }

    /// @dev Checks if transfer of 'value' amount of tokens from 'from' to 'to' is allowed
    /// @param from address of token sender
    /// @param to address of token receiver
    /// @param value amount of tokens to transfer
    modifier notRestricted (address from, address to, uint256 value) {
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        require(restrictionCode == SUCCESS_CODE, messageForTransferRestriction(restrictionCode));
        _;
    }

    /// @notice Constructor function of the token
    /// @param name Name of the token as it will be in the ledger
    /// @param symbol Symbol that will represent the token
    constructor(string memory name, string memory symbol)  ERC20(name, symbol) {}

    /// @notice Function to add AWO
    /// @dev Only owner can add AWO
    /// @param operator Address of the AWO
    function addAWOperator(address operator) external onlyOwner{
        operators[operator].awo = true;
        emit NewAWO(operator);
    }

    /// @notice Function to add SCO
    /// @dev Only owner can add SCO
    /// @param operator Address of the SCO
    function addSCOperator(address operator) external onlyOwner{
        operators[operator].sco = true;
        emit NewSCO(operator);
    }

    /// @notice Function to remove AWO
    /// @dev Only owner can remove AWO
    /// @param operator Address of the AWO
    function removeAWOperator(address operator) external onlyOwner{
        require(operators[operator].awo == true,
            "SecurityToken.removeAWOperator: There is no such operator");
        operators[operator].awo = false;
        emit RemovedAWO(operator);
    }

    /// @notice Function to remove SCO
    /// @dev Only owner can remove SCO
    /// @param operator Address of the SCO
    function removeSCOperator(address operator) external onlyOwner{
        require(operators[operator].sco == true,
            "SecurityToken.removeSCOperator: There is no such operator");
        operators[operator].sco = false;
        emit RemovedSCO(operator);
    }

    /// @notice Function to mint SecurityToken
    /// @dev Only SCO can mint tokens to the whitelisted addresses
    /// @param account Address of the token receiver
    /// @param amount Amount of minted tokens
    function mint(address account, uint256 amount) external onlySCOperator{
        require(whitelist[account] == true,
            "SecurityToken.mint: Only whitelisted users can own tokens");
        _mint(account, amount);
    }

    /// @notice Function to burn SecurityToken
    /// @dev Only SCO can burn tokens from addresses
    /// @param account Address from which tokens will be burned
    /// @param amount Amount of burned tokens
    function burn(address account, uint256 amount) external onlySCOperator{
        _burn(account, amount);
    }

    /// @notice Function to add address to Whitelist
    /// @dev Only AWO can add address to Whitelist
    /// @param account Address to add to the Whitelist
    function addToWhitelist(address account) public onlyAWOperator{
        whitelist[account] = true;
    }

    /// @notice Function to remove address from Whitelist
    /// @dev Only AWO can remove address from Whitelist on removal from the list user loses all of the tokens
    /// @param account Address to remove from the Whitelist
    function removeFromWhitelist(address account) external onlyAWOperator{
        require(whitelist[account] == true,
            "SecurityToken.removeFromWhitelist: User is not on the Whitelist");
        require(account != bondingCurve,
            "SecurityToken.removeFromWhitelist: Can't remove bondingCurve");
        whitelist[account] = false;
    }

    /// @notice Function to check the restriction for token transfer
    /// @param from address of sender
    /// @param to address of receiver
    /// @param value amount of tokens to transfer
    /// @return restrictionCode code of restriction for specific transfer
    function detectTransferRestriction (address from, address to, uint256 value)
        public
        view
        override
        returns (uint8 restrictionCode)
    {
        require(value > 0, "SecurityToken: need to transfer more then 0.");
        if(from == bondingCurve){
            if(whitelist[to] == true){
                restrictionCode = SUCCESS_CODE;
            } else {
                restrictionCode = ERR_RECIPIENT_CODE;
            }
        } else if (whitelist[from]){
            if(to == bondingCurve){
                restrictionCode = SUCCESS_CODE;
            } else {
                restrictionCode = ERR_BONDING_CURVE_CODE;
            }
        } else{
            restrictionCode = ERR_NOT_WHITELISTED_CODE;
        }
    }


    /// @notice Function to return restriction message based on the code
    /// @param restrictionCode code of restriction
    /// @return message message of restriction for specific code
    function messageForTransferRestriction (uint8 restrictionCode)
        public
        pure
        override
        returns (string memory message)
    {
        if (restrictionCode == SUCCESS_CODE) {
            message = SUCCESS_MESSAGE;
        } else if (restrictionCode == ERR_RECIPIENT_CODE) {
            message = ERR_RECIPIENT_MESSAGE;
        } else if (restrictionCode == ERR_BONDING_CURVE_CODE) {
            message = ERR_BONDING_CURVE_MESSAGE;
        } else {
            message = ERR_NOT_WHITELISTED_MESSAGE;
        }
    }


    /// @notice Function to transfer tokens between whitelisted users
    /// @param to Address to which tokens are sent
    /// @param value Amount of tokens to send
    function transfer(address to, uint256 value)
        public
        override
        notRestricted(msg.sender, to, value)
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    /// @notice Function to approve tokens usage from some other address
    /// @dev Only Whitelisted addresses can use tokens and give right to use tokens
    /// @param spender Address that will receive the right to use tokens
    /// @param amount Amount of tokens that may be spent
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool) {
        require(whitelist[spender] == true,
            "SecurityToken.approve: Only a whitelisted user can be approved");
        require(whitelist[msg.sender] == true,
            "SecurityToken.approve: Only a whitelisted user can approve");
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @notice Function to transfer tokens from some another address(used after approve)
    /// @dev Only Whitelisted addresses that have the approval can send or receive tokens
    /// @param sender Address that will be used to send tokens from
    /// @param recipient Address that will receive tokens
    /// @param amount Amount of tokens that may be sent
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        override
        notRestricted(sender, recipient, amount)
        returns (bool) {
        require(whitelist[msg.sender] == true,
            "SecurityToken.transferFrom: Only whitelisted user can transfer");
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, msg.sender);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /// @notice Function to set BondingCurve address for the contract
    /// @param curve address of the BondingCurve
    function setupBondingCurve(address curve) external onlyOwner {
        bondingCurve = curve;
        addToWhitelist(bondingCurve);
    }

    /// @notice Function to get bondingCurve contract address
    /// @return BondingCurve address
    function getBondingCurve() external view returns (address) {
        return bondingCurve;
    }

    /// @notice Function to check if user is an operator
    /// @param operator Address to check
    /// @return If address has AWO or SCO rights
    function getOperator(address operator) external view returns (bool, bool) {
        return (operators[operator].awo, operators[operator].sco);
    }

    /// @notice Function to check if user is in a whitelist
    /// @param user Address to check
    /// @return If address is in a whitelist
    function isInWhitelist(address user) external view returns (bool) {
        return whitelist[user];
    }
}