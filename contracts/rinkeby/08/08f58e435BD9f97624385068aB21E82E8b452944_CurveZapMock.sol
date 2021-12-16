// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/Curve/IZap.sol";
import "../../interfaces/Curve/ICurveRegistry.sol";

import "./Pool.sol";

/**
 * @notice Implicit implementation of ZAP interface of Curve contracts
 */

contract CurveZapMock is ICurveZap {
    uint256 public constant N_COINS = 2;
    uint256 public constant MAX_COIN = N_COINS - 1;
    uint256 public constant BASE_N_COINS = 3;
    uint256 public constant N_ALL_COINS = N_COINS + BASE_N_COINS - 1;

    address public basePoolAddr;
    address public baseLPToken;

    constructor(address _baseAddr, address _baseLPToken) {
        basePoolAddr = _baseAddr;
        baseLPToken = _baseLPToken;

        ERC20(_baseLPToken).approve(_baseAddr, type(uint256).max);
    }

    function setBaseAddr(address _newBaseAddr, address _newBaseLPToken) external {
        basePoolAddr = _newBaseAddr;
        baseLPToken = _newBaseLPToken;

        ERC20(_newBaseLPToken).approve(_newBaseAddr, type(uint256).max);
    }

    function add_liquidity(
        address _poolAddr,
        uint256[N_ALL_COINS] calldata _amounts,
        uint256 _min_mint_amount
    ) external override returns (uint256) {
        CurvePoolMock _pool = CurvePoolMock(_poolAddr);
        CurvePoolMock _3pool = CurvePoolMock(basePoolAddr);

        uint256[BASE_N_COINS] memory _3poolArray = [_amounts[1], _amounts[2], _amounts[3]];

        for (uint256 i = 1; i < _amounts.length; i++) {
            if (_amounts[i] > 0) {
                address _token = _3pool.coins(_toInt128(i - 1));
                uint256 _amount = _amounts[i];
                IERC20(_token).transferFrom(msg.sender, address(this), _amount);
                IERC20(_token).approve(address(_3pool), _amount);
            }
        }

        uint256 _3poolTokens = _3pool.add_liquidity(_3poolArray, 0);

        if (_amounts[0] > 0) {
            IERC20(_pool.coins(0)).transferFrom(msg.sender, address(this), _amounts[0]);
        }

        uint256[N_COINS] memory _array = [_amounts[0], _3poolTokens];

        IERC20(_pool.coins(0)).approve(address(_pool), _amounts[0]);
        IERC20(_pool.coins(1)).approve(address(_pool), _3poolTokens);

        uint256 _receivedLPAmount = _pool.add_liquidity(_array, _min_mint_amount);
        IERC20(_pool.lpToken()).transfer(msg.sender, _receivedLPAmount);

        return _receivedLPAmount;
    }

    function remove_liquidity_one_coin(
        address _poolAddr,
        uint256 _burn_amount,
        int128 i,
        uint256 _min_amount
    ) external override returns (uint256) {
        CurvePoolMock _pool = CurvePoolMock(_poolAddr);
        CurvePoolMock _3pool = CurvePoolMock(basePoolAddr);

        ERC20 _lpToken = ERC20(_pool.lpToken());

        _lpToken.transferFrom(msg.sender, address(this), _burn_amount);

        if (_lpToken.allowance(address(this), _poolAddr) == 0) {
            _lpToken.approve(_poolAddr, type(uint256).max);
        }

        uint256 _receivedAmount;

        if (i == 0) {
            _receivedAmount = _pool.remove_liquidity_one_coin(_burn_amount, i, _min_amount);
            ERC20(_pool.coins(i)).transfer(msg.sender, _receivedAmount);
        } else {
            _receivedAmount = _pool.remove_liquidity_one_coin(
                _burn_amount,
                _toInt128(MAX_COIN),
                0
            );
            _3pool.remove_liquidity_one_coin(
                _receivedAmount,
                i - _toInt128(MAX_COIN),
                _min_amount
            );

            ERC20 _coin = ERC20(_3pool.coins(i - _toInt128(MAX_COIN)));
            _receivedAmount = _coin.balanceOf(address(this));
            _coin.transfer(msg.sender, _receivedAmount);
        }

        return _receivedAmount;
    }

    function calc_withdraw_one_coin(
        address _poolAddr,
        uint256 _token_amount,
        int128 i
    ) external view override returns (uint256) {
        CurvePoolMock _pool = CurvePoolMock(_poolAddr);

        int128 _maxCoin = _toInt128(MAX_COIN);

        if (i < _maxCoin) {
            return _pool.calc_withdraw_one_coin(_token_amount, i);
        } else {
            uint256 _baseTokensAmount = _pool.calc_withdraw_one_coin(_token_amount, _maxCoin);
            return
                CurvePoolMock(basePoolAddr).calc_withdraw_one_coin(
                    _baseTokensAmount,
                    i - _maxCoin
                );
        }
    }

    function calc_token_amount(
        address _poolAddr,
        uint256[N_ALL_COINS] calldata _amounts,
        bool _is_deposit
    ) external view override returns (uint256) {
        CurvePoolMock _pool = CurvePoolMock(_poolAddr);
        CurvePoolMock _3pool = CurvePoolMock(basePoolAddr);

        uint256[N_COINS] memory _metaAmounts;
        uint256[BASE_N_COINS] memory _baseAmounts;

        _metaAmounts[0] = _amounts[0];
        for (uint256 i = 0; i < BASE_N_COINS; i++) {
            _baseAmounts[i] = _amounts[i + MAX_COIN];
        }

        _metaAmounts[MAX_COIN] = _3pool.calc_token_amount(_baseAmounts, _is_deposit);

        return _pool.calc_token_amount(_metaAmounts, _is_deposit);
    }

    function _toInt128(uint256 _number) internal pure returns (int128) {
        return int128(int256(_number));
    }
}

// SPDX-License-Identifier: MIT

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    uint8 private _decimals = 18;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mintArbitrary(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function setDecimals(uint8 _newDecimals) external {
        _decimals = _newDecimals;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mintArbitraryBatch(address[] memory _to, uint256[] memory _amounts) public {
        require(_to.length == _amounts.length, "MockERC20: Arrays must be the same length.");

        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i], _amounts[i]);
        }
    }

    function approveArbitraryBacth(
        address spender,
        address[] memory _owners,
        uint256[] memory _amounts
    ) public {
        require(_owners.length == _amounts.length, "MockERC20: Arrays must be the same length.");

        for (uint256 i = 0; i < _owners.length; i++) {
            _approve(_owners[i], spender, _amounts[i]);
        }
    }

    function burn(address _account, uint256 _amount) external {
        _burn(_account, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../interfaces/Curve/IPool.sol";

import "../../common/Globals.sol";
import "../../libraries/DecimalsConverter.sol";

import "../MockERC20.sol";

/**
 * @notice Implicit implementation of pool interface of Curve contracts
 */

contract CurvePoolMock is IMetaPool {
    using DecimalsConverter for uint256;

    address public lpToken;
    address public override base_pool;
    bool public isMeta;

    uint256 public numberOfCoins;
    uint256 public numberOfUnderlyingCoins;

    uint256 public exchangeRate = DECIMAL;

    mapping(int128 => address) public override coins;
    mapping(int128 => address) public underlyingCoins;

    constructor(
        bool _isMeta,
        address _lpTokenAddr,
        address[] memory _coins,
        address[] memory _underlyingCoins
    ) {
        isMeta = _isMeta;
        lpToken = _lpTokenAddr;

        uint256 _numberOfCoins = _coins.length;
        uint256 _numberOfUnderlyingCoins = _underlyingCoins.length;

        numberOfCoins = _numberOfCoins;
        numberOfUnderlyingCoins = _numberOfUnderlyingCoins;

        setCoins(0, _coins);
        setUnderlyingCoins(0, _underlyingCoins);
    }

    function setIsMeta(bool _newValue) external {
        isMeta = _newValue;
    }

    function setBasePool(address _newBasePool) external {
        base_pool = _newBasePool;
    }

    function setCoins(uint256 _startIndex, address[] memory _tokens) public {
        for (uint256 i = 0; i < _tokens.length; i++) {
            coins[_toInt128(_startIndex + i)] = _tokens[i];
        }
    }

    function setUnderlyingCoins(uint256 _startIndex, address[] memory _tokens) public {
        for (uint256 i = 0; i < _tokens.length; i++) {
            underlyingCoins[_toInt128(_startIndex + i)] = _tokens[i];
        }
    }

    function setExchangeRate(uint256 _newRate) external {
        exchangeRate = _newRate;
    }

    function setNumberOfCoins(uint256 _newNumberOfCoins) external {
        numberOfCoins = _newNumberOfCoins;
    }

    function setNumberOfUnderlyingCoins(uint256 _newNumberOfUnderlyingCoins) external {
        numberOfUnderlyingCoins = _newNumberOfUnderlyingCoins;
    }

    function add_liquidity(uint256[2] calldata _amounts, uint256 min_mint_amount)
        external
        override
        returns (uint256)
    {
        require(numberOfCoins == 2, "CurvePoolMock: Incorrect amounts length.");

        uint256[] memory _amountsArr = new uint256[](_amounts.length);

        for (uint256 i = 0; i < _amounts.length; i++) {
            _amountsArr[i] = _amounts[i];
        }

        return _addLiquidity(_amountsArr, min_mint_amount);
    }

    function add_liquidity(uint256[3] calldata _amounts, uint256 min_mint_amount)
        external
        override
        returns (uint256)
    {
        require(numberOfCoins == 3, "CurvePoolMock: Incorrect amounts length.");

        uint256[] memory _amountsArr = new uint256[](_amounts.length);

        for (uint256 i = 0; i < _amounts.length; i++) {
            _amountsArr[i] = _amounts[i];
        }

        return _addLiquidity(_amountsArr, min_mint_amount);
    }

    function remove_liquidity_one_coin(
        uint256 _token_mount,
        int128 i,
        uint256 _min_amount
    ) external override returns (uint256) {
        uint256 _currentBalance = ERC20(lpToken).balanceOf(msg.sender);

        require(
            _currentBalance >= _token_mount,
            "CurvePoolMock: Not enough LP tokens on account."
        );
        require(i < _toInt128(numberOfCoins), "CurvePoolMock: Token index out of bounds.");

        ERC20 _token = ERC20(coins[i]);

        uint256 _amountToTransferInUnderlying =
            _convertFromLP(_token_mount).convertFrom18(_token.decimals());

        require(
            _amountToTransferInUnderlying >= _min_amount,
            "CurvePoolMock: Received amount less than the minimal amount."
        );

        _token.transfer(msg.sender, _amountToTransferInUnderlying);

        MockERC20(lpToken).burn(msg.sender, _token_mount);

        return _amountToTransferInUnderlying;
    }

    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit)
        external
        view
        override
        returns (uint256)
    {
        _is_deposit;

        require(numberOfCoins == 2, "CurvePoolMock: Incorrect amounts length.");

        uint256[] memory _amountsArr = new uint256[](_amounts.length);

        for (uint256 i = 0; i < _amounts.length; i++) {
            _amountsArr[i] = _amounts[i];
        }

        return _calcTokenAmount(_amountsArr);
    }

    function calc_token_amount(uint256[3] calldata _amounts, bool _is_deposit)
        external
        view
        override
        returns (uint256)
    {
        _is_deposit;

        require(numberOfCoins == 3, "CurvePoolMock: Incorrect amounts length.");

        uint256[] memory _amountsArr = new uint256[](_amounts.length);

        for (uint256 i = 0; i < _amounts.length; i++) {
            _amountsArr[i] = _amounts[i];
        }

        return _calcTokenAmount(_amountsArr);
    }

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        override
        returns (uint256)
    {
        require(i < _toInt128(numberOfCoins), "CurvePoolMock: Token index out of bounds.");

        return _convertFromLP(_burn_amount).convertFrom18(ERC20(coins[i]).decimals());
    }

    function _calcTokenAmount(uint256[] memory _amounts) internal view returns (uint256) {
        uint256 _totalAmount;

        for (uint256 i = 0; i < _amounts.length; i++) {
            if (_amounts[i] > 0) {
                _totalAmount += _convertTo18(coins[_toInt128(i)], _amounts[i]);
            }
        }

        return _convertToLP(_totalAmount);
    }

    function _addLiquidity(uint256[] memory _amounts, uint256 _minMintAmount)
        internal
        returns (uint256)
    {
        uint256 _totalAmount;

        for (uint256 i = 0; i < _amounts.length; i++) {
            if (_amounts[i] > 0) {
                address _tokenAddr = coins[_toInt128(i)];

                _totalAmount += _convertTo18(_tokenAddr, _amounts[i]);

                ERC20(_tokenAddr).transferFrom(msg.sender, address(this), _amounts[i]);
            }
        }

        uint256 _amountToMint = _convertToLP(_totalAmount);
        address _lpTokenAddr = lpToken;

        require(
            _amountToMint >= _convertTo18(_lpTokenAddr, _minMintAmount),
            "CurvePoolMock: Amount to mint less than the minimal amount to mint."
        );

        uint256 _amountInLPToMint = _amountToMint.convertFrom18(ERC20(_lpTokenAddr).decimals());

        MockERC20(_lpTokenAddr).mintArbitrary(msg.sender, _amountInLPToMint);

        return _amountInLPToMint;
    }

    function _convertToLP(uint256 _amountToConvert) internal view returns (uint256) {
        return (_amountToConvert * DECIMAL) / exchangeRate;
    }

    function _convertFromLP(uint256 _amountToConvert) internal view returns (uint256) {
        return (_amountToConvert * exchangeRate) / DECIMAL;
    }

    function _convertTo18(address _tokenAddr, uint256 _amountToConvert)
        internal
        view
        returns (uint256)
    {
        return _amountToConvert.convertTo18(ERC20(_tokenAddr).decimals());
    }

    function _toInt128(uint256 _number) internal pure returns (int128) {
        return int128(int256(_number));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

/// @notice the intention of this library is to be able to easily convert
///     one amount of tokens with N decimal places
///     to another amount with M decimal places
library DecimalsConverter {
    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount / (10**(baseDecimals - destinationDecimals));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount * (10**(destinationDecimals - baseDecimals));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals) internal pure returns (uint256) {
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, 18, destinationDecimals);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface ICurveZap {
    function add_liquidity(
        address pool,
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function calc_withdraw_one_coin(
        address _poolAddr,
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);

    function calc_token_amount(
        address _pool,
        uint256[4] calldata _amounts,
        bool _is_deposit
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface IBasePool {
    function coins(int128 arg0) external view returns (address);

    function add_liquidity(uint256[2] calldata _amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function add_liquidity(uint256[3] calldata _amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_mount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[3] calldata _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        returns (uint256);
}

interface IMetaPool is IBasePool {
    function base_pool() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

interface ICurveRegistry {
    function get_n_coins(address _poolAddr) external view returns (uint256[2] calldata);

    function get_coins(address _poolAddr) external view returns (address[8] calldata);

    function get_underlying_coins(address _poolAddr) external view returns (address[8] calldata);

    function get_pool_from_lp_token(address _lpTokenAddr) external view returns (address);

    function is_meta(address) external view returns (bool);

    function pool_list(uint256 _index) external view returns (address);

    function pool_count() external view returns (uint256);

    function get_lp_token(address _poolAddr) external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.3;

uint256 constant ONE_PERCENT = 10**25;
uint256 constant DECIMAL = ONE_PERCENT * 100;

uint8 constant STANDARD_DECIMALS = 18;
uint256 constant ONE_TOKEN = 10**STANDARD_DECIMALS;

uint256 constant BLOCKS_PER_DAY = 6450;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint8 constant PRICE_DECIMALS = 8;