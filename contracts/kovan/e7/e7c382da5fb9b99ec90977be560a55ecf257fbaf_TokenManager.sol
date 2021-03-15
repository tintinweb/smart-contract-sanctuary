//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "../libraries/UniswapLibrary.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/ITokenManager.sol";
import "../interfaces/IBondManager.sol";
import "../interfaces/IEmissionManager.sol";
import "../SyntheticToken.sol";
import "../access/Operatable.sol";
import "../access/Migratable.sol";

/// TokenManager manages all tokens and their price data
contract TokenManager is ITokenManager, Operatable, Migratable {
    struct TokenData {
        SyntheticToken syntheticToken;
        ERC20 underlyingToken;
        IUniswapV2Pair pair;
        IOracle oracle;
    }

    /// Token data (key is synthetic token address)
    mapping(address => TokenData) public tokenIndex;
    /// A set of managed synthetic token addresses
    address[] public tokens;
    /// Addresses of contracts allowed to mint / burn synthetic tokens
    address[] tokenAdmins;
    /// Uniswap factory address
    address public immutable uniswapFactory;

    IBondManager public bondManager;
    IEmissionManager public emissionManager;

    // ------- Constructor ----------

    /// Creates a new Token Manager
    /// @param _uniswapFactory The address of the Uniswap Factory
    constructor(address _uniswapFactory) public {
        uniswapFactory = _uniswapFactory;
    }

    // ------- Modifiers ----------

    /// Fails if a token is not currently managed by Token Manager
    /// @param syntheticTokenAddress The address of the synthetic token
    modifier managedToken(address syntheticTokenAddress) {
        require(
            isManagedToken(syntheticTokenAddress),
            "TokenManager: Token is not managed"
        );
        _;
    }

    modifier initialized() {
        require(
            isInitialized(),
            "TokenManager: BondManager or EmissionManager is not initialized"
        );
        _;
    }

    modifier tokenAdmin() {
        require(
            isTokenAdmin(msg.sender),
            "TokenManager: Must be called by token admin"
        );
        _;
    }

    // ------- View ----------

    /// A set of synthetic tokens under management
    /// @dev Deleted tokens are still present in the array but with address(0)
    function allTokens() public view override returns (address[] memory) {
        return tokens;
    }

    /// Checks if the token is managed by Token Manager
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return True if token is managed
    function isManagedToken(address syntheticTokenAddress)
        public
        view
        override
        returns (bool)
    {
        return
            address(tokenIndex[syntheticTokenAddress].syntheticToken) !=
            address(0);
    }

    /// Checks if token ownerships are valid
    /// @return True if ownerships are valid
    function validTokenPermissions() public view returns (bool) {
        for (uint32 i = 0; i < tokens.length; i++) {
            SyntheticToken token = SyntheticToken(tokens[i]);
            if (address(token) != address(0)) {
                if (token.operator() != address(this)) {
                    return false;
                }
                if (token.owner() != address(this)) {
                    return false;
                }
            }
        }
        return true;
    }

    /// Checks if prerequisites for starting using TokenManager are fulfilled
    function isInitialized() public view returns (bool) {
        return
            (address(bondManager) != address(0)) &&
            (address(emissionManager) != address(0));
    }

    /// All token admins allowed to mint / burn
    function allTokenAdmins() public view returns (address[] memory) {
        return tokenAdmins;
    }

    /// Check if address is token admin
    /// @param admin - address to check
    function isTokenAdmin(address admin) public view override returns (bool) {
        for (uint256 i = 0; i < tokenAdmins.length; i++) {
            if (tokenAdmins[i] == admin) {
                return true;
            }
        }
        return false;
    }

    /// Address of the underlying token
    /// @param syntheticTokenAddress The address of the synthetic token
    function underlyingToken(address syntheticTokenAddress)
        public
        view
        override
        managedToken(syntheticTokenAddress)
        returns (address)
    {
        return address(tokenIndex[syntheticTokenAddress].underlyingToken);
    }

    /// Average price of the synthetic token according to price oracle
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param syntheticTokenAmount The amount to be priced
    /// @return The equivalent amount of the underlying token required to buy syntheticTokenAmount (average)
    /// @dev Fails if the token is not managed
    function averagePrice(
        address syntheticTokenAddress,
        uint256 syntheticTokenAmount
    )
        public
        view
        override
        managedToken(syntheticTokenAddress)
        returns (uint256)
    {
        IOracle oracle = tokenIndex[syntheticTokenAddress].oracle;
        return oracle.consult(syntheticTokenAddress, syntheticTokenAmount);
    }

    /// Current price of the synthetic token according to Uniswap
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param syntheticTokenAmount The amount to be priced
    /// @return The equivalent amount of the underlying token required to buy syntheticTokenAmount
    /// @dev Fails if the token is not managed
    function currentPrice(
        address syntheticTokenAddress,
        uint256 syntheticTokenAmount
    )
        public
        view
        override
        managedToken(syntheticTokenAddress)
        returns (uint256)
    {
        address underlyingTokenAddress =
            address(tokenIndex[syntheticTokenAddress].underlyingToken);
        (uint256 syntheticReserve, uint256 undelyingReserve) =
            UniswapLibrary.getReserves(
                uniswapFactory,
                syntheticTokenAddress,
                underlyingTokenAddress
            );
        return
            UniswapLibrary.quote(
                syntheticTokenAmount,
                syntheticReserve,
                undelyingReserve
            );
    }

    /// Get one synthetic unit
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return one unit of the synthetic asset
    function oneSyntheticUnit(address syntheticTokenAddress)
        public
        view
        override
        managedToken(syntheticTokenAddress)
        returns (uint256)
    {
        SyntheticToken synToken =
            SyntheticToken(tokenIndex[syntheticTokenAddress].syntheticToken);
        return uint256(10)**synToken.decimals();
    }

    /// Get one underlying unit
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return one unit of the underlying asset
    function oneUnderlyingUnit(address syntheticTokenAddress)
        public
        view
        override
        managedToken(syntheticTokenAddress)
        returns (uint256)
    {
        ERC20 undToken = tokenIndex[syntheticTokenAddress].underlyingToken;
        return uint256(10)**undToken.decimals();
    }

    // ------- External --------------------

    /// Update oracle price
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @dev This modifier must always come with managedToken and oncePerBlock
    function updateOracle(address syntheticTokenAddress)
        public
        override
        managedToken(syntheticTokenAddress)
    {
        IOracle oracle = tokenIndex[syntheticTokenAddress].oracle;
        try oracle.update() {} catch {}
    }

    // ------- External, Owner ----------

    function addTokenAdmin(address admin) public onlyOwner {
        _addTokenAdmin(admin);
    }

    function deleteTokenAdmin(address admin) public onlyOwner {
        _deleteTokenAdmin(admin);
    }

    // ------- External, Operator ----------

    /// Adds token to managed tokens
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param bondTokenAddress The address of the bond token
    /// @param underlyingTokenAddress The address of the underlying token
    /// @param oracleAddress The address of the price oracle for the pair
    /// @dev Requires the operator and the owner of the synthetic token to be set to TokenManager address before calling
    function addToken(
        address syntheticTokenAddress,
        address bondTokenAddress,
        address underlyingTokenAddress,
        address oracleAddress
    ) external onlyOperator initialized {
        require(
            syntheticTokenAddress != underlyingTokenAddress,
            "TokenManager: Synthetic token and Underlying tokens must be different"
        );
        require(
            !isManagedToken(syntheticTokenAddress),
            "TokenManager: Token is already managed"
        );
        SyntheticToken syntheticToken = SyntheticToken(syntheticTokenAddress);
        SyntheticToken bondToken = SyntheticToken(bondTokenAddress);
        ERC20 underlyingTkn = ERC20(underlyingTokenAddress);
        IOracle oracle = IOracle(oracleAddress);
        IUniswapV2Pair pair =
            IUniswapV2Pair(
                UniswapLibrary.pairFor(
                    uniswapFactory,
                    syntheticTokenAddress,
                    underlyingTokenAddress
                )
            );
        require(
            syntheticToken.decimals() == bondToken.decimals(),
            "TokenManager: Synthetic and Bond tokens must have the same number of decimals"
        );

        require(
            address(oracle.pair()) == address(pair),
            "TokenManager: Tokens and Oracle tokens are different"
        );
        TokenData memory tokenData =
            TokenData(syntheticToken, underlyingTkn, pair, oracle);
        tokenIndex[syntheticTokenAddress] = tokenData;
        tokens.push(syntheticTokenAddress);
        bondManager.addBondToken(syntheticTokenAddress, bondTokenAddress);
        emit TokenAdded(
            syntheticTokenAddress,
            underlyingTokenAddress,
            address(oracle),
            address(pair)
        );
    }

    /// Removes token from managed, transfers its operator and owner to target address
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param newOperator The operator and owner of the token will be transferred to this address.
    /// @dev Fails if the token is not managed
    function deleteToken(address syntheticTokenAddress, address newOperator)
        external
        managedToken(syntheticTokenAddress)
        onlyOperator
        initialized
    {
        bondManager.deleteBondToken(syntheticTokenAddress, newOperator);
        uint256 pos;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == syntheticTokenAddress) {
                pos = i;
            }
        }
        TokenData memory data = tokenIndex[tokens[pos]];
        data.syntheticToken.transferOperator(newOperator);
        data.syntheticToken.transferOwnership(newOperator);
        delete tokenIndex[syntheticTokenAddress];
        delete tokens[pos];
        emit TokenDeleted(
            syntheticTokenAddress,
            address(data.underlyingToken),
            address(data.oracle),
            address(data.pair)
        );
    }

    /// Burns synthetic token from the owner
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param owner Owner of the tokens to burn
    /// @param amount Amount to burn
    function burnSyntheticFrom(
        address syntheticTokenAddress,
        address owner,
        uint256 amount
    )
        public
        override
        managedToken(syntheticTokenAddress)
        initialized
        tokenAdmin
    {
        SyntheticToken token = tokenIndex[syntheticTokenAddress].syntheticToken;
        token.burnFrom(owner, amount);
    }

    /// Mints synthetic token
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param receiver Address to receive minted token
    /// @param amount Amount to mint
    function mintSynthetic(
        address syntheticTokenAddress,
        address receiver,
        uint256 amount
    )
        public
        override
        managedToken(syntheticTokenAddress)
        initialized
        tokenAdmin
    {
        SyntheticToken token = tokenIndex[syntheticTokenAddress].syntheticToken;
        token.mint(receiver, amount);
    }

    // --------- Operator -----------

    /// Updates bond manager address
    /// @param _bondManager new bond manager
    function setBondManager(address _bondManager) public onlyOperator {
        require(
            address(bondManager) != _bondManager,
            "TokenManager: bondManager with this address already set"
        );
        deleteTokenAdmin(address(bondManager));
        addTokenAdmin(_bondManager);
        bondManager = IBondManager(_bondManager);
        emit BondManagerChanged(msg.sender, _bondManager);
    }

    /// Updates emission manager address
    /// @param _emissionManager new emission manager
    function setEmissionManager(address _emissionManager) public onlyOperator {
        require(
            address(emissionManager) != _emissionManager,
            "TokenManager: emissionManager with this address already set"
        );
        deleteTokenAdmin(address(emissionManager));
        addTokenAdmin(_emissionManager);
        emissionManager = IEmissionManager(_emissionManager);
        emit EmissionManagerChanged(msg.sender, _emissionManager);
    }

    /// Updates oracle for synthetic token address
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param oracleAddress new oracle address
    function setOracle(address syntheticTokenAddress, address oracleAddress)
        public
        onlyOperator
        managedToken(syntheticTokenAddress)
    {
        IOracle oracle = IOracle(oracleAddress);
        require(
            oracle.pair() == tokenIndex[syntheticTokenAddress].pair,
            "TokenManager: Tokens and Oracle tokens are different"
        );
        tokenIndex[syntheticTokenAddress].oracle = oracle;
        emit OracleUpdated(msg.sender, syntheticTokenAddress, oracleAddress);
    }

    // ------- Internal ----------

    function _addTokenAdmin(address admin) internal {
        if (isTokenAdmin(admin)) {
            return;
        }
        tokenAdmins.push(admin);
        emit TokenAdminAdded(msg.sender, admin);
    }

    function _deleteTokenAdmin(address admin) internal {
        for (uint256 i = 0; i < tokenAdmins.length; i++) {
            if (tokenAdmins[i] == admin) {
                delete tokenAdmins[i];
                emit TokenAdminDeleted(msg.sender, admin);
            }
        }
    }

    // ------- Events ----------

    /// Emitted each time the token becomes managed
    event TokenAdded(
        address indexed syntheticTokenAddress,
        address indexed underlyingTokenAddress,
        address oracleAddress,
        address pairAddress
    );
    /// Emitted each time the token becomes unmanaged
    event TokenDeleted(
        address indexed syntheticTokenAddress,
        address indexed underlyingTokenAddress,
        address oracleAddress,
        address pairAddress
    );
    /// Emitted each time Oracle is updated
    event OracleUpdated(
        address indexed operator,
        address indexed syntheticTokenAddress,
        address oracleAddress
    );
    /// Emitted each time BondManager is updated
    event BondManagerChanged(address indexed operator, address newManager);
    /// Emitted each time EmissionManager is updated
    event EmissionManagerChanged(address indexed operator, address newManager);
    /// Emitted when migrated
    event Migrated(address indexed operator, address target);
    event TokenAdminAdded(address indexed operator, address admin);
    event TokenAdminDeleted(address indexed operator, address admin);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/// Created as a separate unit because the `uniswap` lib has conflicting imports of `SafeMath` with `openzeppelin`
library UniswapLibrary {
    using SafeMath for uint256;

    /// Calculates the CREATE2 address for a pair without making any external calls
    /// @param factory Uniswap factory address
    /// @param tokenA One token in the pair
    /// @param tokenB The other token in the pair
    /// @return pair Address of the Uniswap pair
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return token0 token1 Sorted asc addresses of tokens
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    /// Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    /// @param amountA The amount of tokenA
    /// @param reserveA The reserver of token A
    /// @param reserveB The reserver of token B
    /// @return amountB Equivalent amount of token B
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    /// Fetches and sorts the reserves for a pair
    /// @param factory Uniswap factory address
    /// @param tokenA One token in the pair
    /// @param tokenB The other token in the pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) =
            IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/// Fixed window oracle that recomputes the average price for the entire period once every period
interface IOracle {
    /// Updates oracle price
    /// @dev Works only once in a period, other times reverts
    function update() external;

    /// Get the price of token.
    /// @param token The address of one of two tokens (the one to get the price for)
    /// @param amountIn The amount of token to estimate
    /// @return amountOut The amount of other token equivalent
    /// @dev This will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);

    function pair() external view returns (IUniswapV2Pair);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "./ISmelter.sol";

/// Token manager as seen by other managers
interface ITokenManager is ISmelter {
    /// A set of synthetic tokens under management
    /// @dev Deleted tokens are still present in the array but with address(0)
    function allTokens() external view returns (address[] memory);

    /// Checks if the token is managed by Token Manager
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return True if token is managed
    function isManagedToken(address syntheticTokenAddress)
        external
        view
        returns (bool);

    /// Address of the underlying token
    /// @param syntheticTokenAddress The address of the synthetic token
    function underlyingToken(address syntheticTokenAddress)
        external
        view
        returns (address);

    /// Average price of the synthetic token according to price oracle
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param syntheticTokenAmount The amount to be priced
    /// @return The equivalent amount of the underlying token required to buy syntheticTokenAmount (average)
    /// @dev Fails if the token is not managed
    function averagePrice(
        address syntheticTokenAddress,
        uint256 syntheticTokenAmount
    ) external view returns (uint256);

    /// Current price of the synthetic token according to Uniswap
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param syntheticTokenAmount The amount to be priced
    /// @return The equivalent amount of the underlying token required to buy syntheticTokenAmount
    /// @dev Fails if the token is not managed
    function currentPrice(
        address syntheticTokenAddress,
        uint256 syntheticTokenAmount
    ) external view returns (uint256);

    /// Updates Oracle for the synthetic asset
    /// @param syntheticTokenAddress The address of the synthetic token
    function updateOracle(address syntheticTokenAddress) external;

    /// Get one synthetic unit
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return one unit of the synthetic asset
    function oneSyntheticUnit(address syntheticTokenAddress)
        external
        view
        returns (uint256);

    /// Get one underlying unit
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @return one unit of the underlying asset
    function oneUnderlyingUnit(address syntheticTokenAddress)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/// Bond manager as seen by other managers
interface IBondManager {
    /// Called when new token is added in TokenManager
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param bondTokenAddress The address of the bond token
    function addBondToken(
        address syntheticTokenAddress,
        address bondTokenAddress
    ) external;

    /// Called when token is deleted in TokenManager
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param newOperator New operator for the bond token
    function deleteBondToken(address syntheticTokenAddress, address newOperator)
        external;

    function bondIndex(address syntheticTokenAddress)
        external
        returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

/// Emission manager as seen by other managers
interface IEmissionManager {

}

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "./access/Operatable.sol";

/// @title Synthetic token for the Klondike platform
contract SyntheticToken is ERC20Burnable, Operatable {
    /// Creates a new synthetic token
    /// @param _name Name of the token
    /// @param _symbol Ticker for the token
    /// @param _decimals Number of decimals
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
    }

    ///  Mints tokens to the recepient
    ///  @param recipient The address of recipient
    ///  @param amount The amount of tokens to mint
    function mint(address recipient, uint256 amount)
        public
        onlyOperator
        returns (bool)
    {
        _mint(recipient, amount);
    }

    ///  Burns token from the caller
    ///  @param amount The amount of tokens to burn
    function burn(uint256 amount) public override onlyOperator {
        super.burn(amount);
    }

    ///  Burns token from address
    ///  @param account The account to burn from
    ///  @param amount The amount of tokens to burn
    ///  @dev The allowance for sender in address account must be
    ///  strictly >= amount. Otherwise the function call will fail.
    function burnFrom(address account, uint256 amount)
        public
        override
        onlyOperator
    {
        super.burnFrom(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";

/// Introduces `Operator` role that can be changed only by Owner.
abstract contract Operatable is Ownable {
    address public operator;

    constructor() internal {
        operator = msg.sender;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator can call this method");
        _;
    }

    /// Set new operator
    /// @param newOperator New operator to be set
    /// @dev Only owner is allowed to call this method.
    function transferOperator(address newOperator) public onlyOwner {
        emit OperatorTransferred(operator, newOperator);
        operator = newOperator;
    }

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );
}

// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MigratableOwnership.sol";

contract Migratable is MigratableOwnership {
    /// Migrate balances of a set of tokens
    /// @param tokens a set of tokens to transfer balances to target
    /// @param target new owner of contract balances
    function migrateBalances(address[] memory tokens, address target)
        public
        onlyOwner
        nonReentrant
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                token.transfer(target, balance);
                emit MigratedBalance(
                    msg.sender,
                    address(token),
                    target,
                    balance
                );
            }
        }
    }

    event MigratedBalance(
        address indexed owner,
        address indexed token,
        address target,
        uint256 value
    );
}

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

/// Smelter can mint and burn tokens
interface ISmelter {
    /// Burn SyntheticToken
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param owner Owner of the tokens to burn
    /// @param amount Amount to burn
    function burnSyntheticFrom(
        address syntheticTokenAddress,
        address owner,
        uint256 amount
    ) external;

    /// Mints synthetic token
    /// @param syntheticTokenAddress The address of the synthetic token
    /// @param receiver Address to receive minted token
    /// @param amount Amount to mint
    function mintSynthetic(
        address syntheticTokenAddress,
        address receiver,
        uint256 amount
    ) external;

    /// Check if address is token admin
    /// @param admin - address to check
    function isTokenAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Operatable.sol";

contract MigratableOwnership is Ownable, ReentrancyGuard {
    /// Migrate ownership and operator of a set of tokens
    /// @param tokens a set of tokens to transfer ownership and operator to target
    /// @param target new owner and operator of the token
    function migrateOwnership(address[] memory tokens, address target)
        public
        onlyOwner
        nonReentrant
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            Operatable token = Operatable(tokens[i]);
            if (token.owner() == address(this)) {
                token.transferOperator(target);
                token.transferOwnership(target);
                emit MigratedOwnership(msg.sender, address(token), target);
            }
        }
    }

    event MigratedOwnership(
        address indexed owner,
        address indexed token,
        address target
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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