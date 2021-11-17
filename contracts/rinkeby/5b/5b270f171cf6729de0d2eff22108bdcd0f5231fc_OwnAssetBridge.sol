/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
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
     * Requirements:
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
     * Requirements:
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20Mintable is ERC20, Ownable {
    using SafeMath for uint;

    constructor (string memory name_, string memory symbol_, uint totalSupply_) 
        ERC20(name_, symbol_)
        public 
    {
        _mint(_msgSender(), totalSupply_);
    }

    function mint(address to, uint256 amount) 
        public
        onlyOwner
        returns(bool)
    {
        _mint(to, amount);
        return true;
    }
}

/**
 * @notice This contract is used to bridge WeOwn blockchain and any other blockchain running on EVM, primarily Ethereum. 
 * After establishing bridge between asset on WeOwn blockchain and ERC20 token, cross-chain transfers are enabled and
 * users can move their holding between the blockchains. 
 */
contract OwnAssetBridge is Ownable {
    using SafeMath for uint;
    enum RevertDirection{ FromNative, ToNative }

    event CrossChainTransfer(address indexed token, string recipientAccountHash, uint amount);
    event CrossChainTransfer(string txHash, address recipient);

    mapping (string => address) public erc20Tokens;
    mapping (address => string) public assetHashes;
    mapping (string => string) public accountsForAssets;
    mapping (string => address) public pendingCrossChainTransfers;
    mapping (string => string) public pendingSignedTxs;

    address public governor;
    uint public targetTransferFee;
    uint public nativeTransferFee;
    uint public bridgeFee;

    constructor(uint _bridgeFee, uint _targetTransferFee, uint _nativeTransferFee)
        public
    {
        bridgeFee = _bridgeFee;
        targetTransferFee = _targetTransferFee;
        nativeTransferFee = _nativeTransferFee;
        governor = _msgSender();
    }

    modifier onlyGovernor() {
        require(_msgSender() == governor, "Caller is not the governor");
        _;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Bridge management
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Function that establishes bridge between existing ERC20 token and newly created asset on WeOwn blockchain.
     * This function can only be called by the governor and all tokens should be circulating on target blockchain, while
     * total supply is locked on WeOwn blockchain.
     */
    /// @param _token Address of ERC20 token
    /// @param _assetHash Hash of WeOwn asset
    /// @param _accountHash Hash of WeOwn account that will hold all locked tokens on WeOwn blockchain
    function bridgeErc20Token(address _token, string calldata _assetHash, string calldata _accountHash)
        external
        onlyGovernor
        payable
    {
        require(erc20Tokens[_assetHash] == address(0));
        require(bytes(assetHashes[_token]).length == 0);
        require(bytes(accountsForAssets[_assetHash]).length == 0);
        require(IERC20(_token).balanceOf(address(this)) == 0);
        require(msg.value >= bridgeFee);

        erc20Tokens[_assetHash] = _token;
        assetHashes[_token] = _assetHash;
        accountsForAssets[_assetHash] = _accountHash;
    }

    /**
     * @notice Function that deploys new ERC20 token and establishes bridge between existing asset on WeOwn blockchain
     * and newly created ERC20 token. This function can only be called by the governor and all tokens should be 
     * circulating on WeOwn blockchain, while total supply is locked on target blockchain.
     */
    /// @param _assetHash Hash of WeOwn asset
    /// @param _accountHash Hash of WeOwn account that will hold all locked tokens on WeOwn blockchain
    /// @param _assetName Name of ERC20 token that will be deployed. Needs to correspond to the name of WeOwn asset
    /// @param _assetSymbol Symbol of ERC20 token that will be deployed. Needs to correspond to the symbol of WeOwn asset
    /// @param _totalSupply Total supply of ERC20 token that will be deployed. Needs to correspond to the total supply of WeOwn asset
    function bridgeAsset(
        string calldata _assetHash, 
        string calldata _accountHash, 
        string calldata _assetName, 
        string calldata _assetSymbol, 
        uint _totalSupply)
        external
        onlyGovernor
        payable
    {
        require(erc20Tokens[_assetHash] == address(0));
        require(bytes(accountsForAssets[_assetHash]).length == 0);
        require(msg.value >= bridgeFee);

        address token = address(new ERC20Mintable(_assetName, _assetSymbol, _totalSupply));

        erc20Tokens[_assetHash] = token;
        assetHashes[token] = _assetHash;
        accountsForAssets[_assetHash] = _accountHash;
    }

    /**
     * @notice Function that removes bridge between ERC20 token and asset on WeOwn blockchain. This function can only 
     * be called by the governor and all tokens should be circulating on target blockchain or on WeOwn blockchain.
     */
    /// @param _token Address of ERC20 token
    function removeBridge(address _token)
        external
        onlyGovernor
    {
        string memory assetHash = assetHashes[_token];

        require(bytes(assetHash).length != 0);
        require(erc20Tokens[assetHash] == _token);
        require(bytes(accountsForAssets[assetHash]).length != 0);

        uint bridgeBalance = IERC20(_token).balanceOf(address(this));
        require(bridgeBalance == 0 || bridgeBalance == IERC20(_token).totalSupply());

        delete erc20Tokens[assetHash];
        delete assetHashes[_token];
        delete accountsForAssets[assetHash];
    }

    /**
     * @notice Function that mints ERC20 token created by the bridge. This function can only 
     * be called by the governor in order to ensure consistency between WeOwn and target blockchains.
     */
    /// @param _token Address of ERC20 token
    /// @param _amount Amount of tokens that will be minted
    function mintErc20Token(address _token, uint _amount)
        external
        onlyGovernor
    {
        require(ERC20Mintable(_token).mint(address(this), _amount));
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Cross-chain transfers
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Function by which token holder on target blockchain can transfer tokens to WeOwn blockchain.
     * ERC20 token needs to be bridged to WeOwn asset and user should previously approve this contract as
     * spender of desired amount of tokens that should be cross-chain transferred.
     */
    /// @param _token Address of ERC20 token
    /// @param _recipientAccountHash Hash of WeOwn account that should receive tokens
    /// @param _amount Number of tokens that will be transferred
    function transferToNativeChain(address _token, string calldata _recipientAccountHash, uint _amount)
        external
        payable
    {
        require(msg.value >= nativeTransferFee, "Insufficient fee is paid");
        require(bytes(assetHashes[_token]).length != 0, "Token is not bridged");
        require(IERC20(_token).transferFrom(_msgSender(), address(this), _amount), "Transfer failed");

        emit CrossChainTransfer(_token, _recipientAccountHash, _amount);
    }

    /**
     * @notice Function by which asset holder on WeOwn blockchain can transfer tokens to target blockchain.
     * Asset needs to be bridged to ERC20 token and asset transfer should be done on WeOwn blockchain.
     */
    /// @param _txHash Hash of tx on WeOwn blockchain which contains asset transfer
    /// @param _signature Signature of tx hash, signed by WeOwn sender address
    /// @param _recipient Address on target blockchain that should receive tokens
    function transferFromNativeChain(string calldata _txHash, string calldata _signature, address _recipient)
        external
        payable
    {
        require(msg.value >= targetTransferFee, "Insufficient fee is paid");
        require(pendingCrossChainTransfers[_txHash] == address(0), "Recipient is already determined");
        require(bytes(pendingSignedTxs[_txHash]).length == 0, "Signature is already determined");

        pendingCrossChainTransfers[_txHash] = _recipient;
        pendingSignedTxs[_txHash] = _signature;

        emit CrossChainTransfer(_txHash, _recipient);
    }

    /**
     * @notice Function by which contract owner confirms cross-chain transfer from WeOwn blockchain. If the tx with
     * asset transfer on WeOwn blockchain is valid and correctly signed, tokens will be released to address on target blockchain.
     */
    /// @param _txHash Hash of tx on WeOwn blockchain which contains asset transfer
    /// @param _token Address of ERC20 token
    /// @param _amount Amount of tokens that will be released
    function confirmTransfer(string calldata _txHash, IERC20 _token, uint _amount)
        external
        onlyOwner
    {
        address recipient = pendingCrossChainTransfers[_txHash];
        require(recipient != address(0), "Recipient does not exist");

        delete pendingCrossChainTransfers[_txHash];
        delete pendingSignedTxs[_txHash];

        require(_token.transfer(recipient, _amount), "Transfer failed");
    }

    /**
     * @notice Function by which contract owner reverts cross-chain transfer from WeOwn blockchain. 
     */
    /// @param _txHash Hash of tx on WeOwn blockchain which contains asset transfer
    function revertTransferFromNativeChain(string calldata _txHash)
        external
        onlyOwner
    {
        require(pendingCrossChainTransfers[_txHash] != address(0), "Tx does not exist");

        delete pendingCrossChainTransfers[_txHash];
        delete pendingSignedTxs[_txHash];
    }

    /**
     * @notice Function by which contract owner reverts cross-chain transfer from target blockchain. 
     */
    /// @param _txHash Hash of tx on target blockchain that is reverted
    /// @param _token Address of ERC20 token
    /// @param _recipient Sender address to which tokens will be transferred back
    /// @param _amount Amount of tokens that will be transferred back to sender address
    function revertTransferToNativeChain(string calldata _txHash, IERC20 _token, address _recipient, uint _amount)
        external
        onlyOwner
    {
        require(_token.transfer(_recipient, _amount), "Transfer failed");
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Owner administration
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Function by which contract owner sets governor address - address that can perform bridging and unbridging
     * of ERC20 token and WeOwn asset. 
     */
    /// @param _governor New governor address
    function setGovernor(address _governor)
        external
        onlyOwner
    {
        governor = _governor;
    }

    /**
     * @notice Function by which contract owner sets fee that is paid for cross-chain transfer from WeOwn to target blockchain
     */
    /// @param _amount New fee amount
    function setTargetTransferFee(uint _amount)
        external
        onlyOwner
    {
        targetTransferFee = _amount;
    }

    /**
     * @notice Function by which contract owner sets fee that is paid for cross-chain transfer from target to WeOwn blockchain
     */
    /// @param _amount New fee amount
    function setNativeTransferFee(uint _amount)
        external
        onlyOwner
    {
        nativeTransferFee = _amount;
    }

    /**
     * @notice Function by which contract owner sets fee that is paid by governor when establishing bridge
     */
    /// @param _amount New fee amount
    function setBridgeFee(uint _amount)
        external
        onlyOwner
    {
        bridgeFee = _amount;
    }

    /**
     * @notice Function by which contract owner withdraws fee collected through bridging and cross-chain transfers
     */
    /// @param _amount Amount to be withdrawn
    function withdrawFee(uint _amount)
        external
        onlyOwner
        returns (bool)
    {
        payable(owner()).transfer(_amount);
        return true;
    }
}