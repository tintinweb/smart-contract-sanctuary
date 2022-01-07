// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./IPancakeRouter.sol";
import "./TransferHelper.sol";

import "./KolLib.sol";
import "./FollowLib.sol";
import "./BalanceLib.sol";
import "./AddressesLib.sol";
import "./Event.sol";
import "./Error.sol";

contract CopyTrading is AccessControl, ReentrancyGuard {
    using AddressesLib for address[];
    using BalanceLib for Balances[];
    using FollowSettingLib for FollowSetting;
    using KolLib for KOL[];

    address public multiSigAccount;

    IPancakeRouter02 public pancakeRouter;
    uint256 public systemFeePerThousand;

    KOL[] public kolList;

    // kol => users
    mapping(address => address[]) private _followers;
    // user => kol list
    mapping(address => address[]) private _followings;
    // kol => user => token => balances
    mapping(address => mapping(address => Balances[])) private _balances;
    // kol => user => amount per tran
    mapping(address => mapping(address => uint256)) private _followSettings;

    uint256 public totalSystemFee;

    // 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    address public mainTokenAddress;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Error.ADMIN_ROLE_REQUIRED);
        _;
    }

    modifier onlyKOL() {
        require(kolList.checkActive(_msgSender()), Error.KOL_ROLE_REQUIRED);
        _;
    }

    constructor(address _multiSigAccount) {
        multiSigAccount = _multiSigAccount;
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _multiSigAccount);
    }

    function setPancakeRouter(address _pancakeRouterAddress) external nonReentrant onlyAdmin {
        pancakeRouter = IPancakeRouter02(_pancakeRouterAddress);
    }

    // only testnet
    function setMainTokenAddress(address _mainTokenAddress) external nonReentrant onlyAdmin {
        mainTokenAddress = _mainTokenAddress;
    }

    function setSystemFeePerThousand(uint256 _systemFeePerThousand) external nonReentrant onlyAdmin {
        systemFeePerThousand = _systemFeePerThousand;
    }

    function addKOL(address _kol, uint256 _commission) external nonReentrant onlyAdmin {
        require(!kolList.exists(_kol), Error.KOL_EXISTED);

        KOL memory kol = KOL(_kol, _commission, true);
        kolList.push(kol);

        emit Event.AddKOL(_kol, _commission);
    }

    function updateKOL(address _kol, uint256 _commission) external nonReentrant onlyAdmin {
        require(kolList.exists(_kol), Error.KOL_NOT_EXISTED);

        kolList.updateCommission(_kol, _commission);

        emit Event.UpdateKOL(_kol, _commission);
    }

    function setActiveKol(address _kol, bool _isActive) external nonReentrant onlyAdmin {
        require(kolList.exists(_kol), Error.KOL_NOT_EXISTED);

        kolList.setActive(_kol, _isActive);

        emit Event.SetActiveKOL(_kol, _isActive);
    }

    function getActiveKOL() external view returns (KOL[] memory) {
        return kolList.getActiveKOL();
    }

    function follow(
        address _kol,
        uint256 _totalAmount,
        uint256 _amountPerTran
    ) external nonReentrant {
        require(kolList.checkActive(_kol), Error.KOL_IS_DE_ACTIVE);
        require(!_followings[_msgSender()].exists(_kol), Error.KOL_FOLLOWED);
        require(_amountPerTran < _totalAmount, Error.AMOUNT_PER_TRAN_MUST_LESS_THAN_TOTAL_AMOUNT);

        require(
            IERC20(mainTokenAddress).transferFrom(_msgSender(), address(this), _totalAmount),
            Error.TRANSFER_FAILED
        );

        _followers[_kol].add(_msgSender());
        _followings[_msgSender()].add(_kol);
        _followSettings[_kol][_msgSender()] = _amountPerTran;
        _balances[_kol][_msgSender()].add(mainTokenAddress, _totalAmount);

        emit Event.Follow(_msgSender(), _kol, _totalAmount, _amountPerTran);
    }

    function unFollow(address _kol) external nonReentrant {
        require(_followings[_msgSender()].exists(_kol), Error.NOT_FOLLOW);

        _followers[_kol].remove(_msgSender());
        _followings[_msgSender()].remove(_kol);
        delete _followSettings[_kol][_msgSender()];

        Balances[] memory balances = _balances[_kol][_msgSender()];
        for (uint256 i = 0; i < balances.length; i++) {
            IERC20(balances[i].token).transfer(_msgSender(), balances[i].amount);
            emit Event.Withdrawn(_msgSender(), balances[i].token, balances[i].amount);
        }
        delete _balances[_kol][_msgSender()];

        emit Event.UnFollow(_msgSender(), _kol);
    }

    function getFollowers(address _kol) external view returns (address[] memory) {
        return _followers[_kol];
    }

    function getFollowings(address _user) external view returns (address[] memory) {
        return _followings[_user];
    }

    function updateFollowSetting(address _kol, uint256 _newAmountPerTran) external nonReentrant {
        require(_followings[_msgSender()].exists(_kol), Error.NOT_FOLLOW);

        _followSettings[_kol][_msgSender()] = _newAmountPerTran;
    }

    function getFollowSetting(address _kol, address _user) external view returns (FollowSetting memory) {
        require(_followings[_user].exists(_kol), Error.NOT_FOLLOW);

        return FollowSetting(_balances[_kol][_user].get(mainTokenAddress), _followSettings[_kol][_user]);
    }

    function getBalances(address _kol, address _user) external view returns (Balances[] memory) {
        return _balances[_kol][_user];
    }

    function buy(
        address _outputToken,
        uint256 _amount,
        uint256 _slipPage, // per thousand
        uint256 _delay // sec
    ) external nonReentrant onlyKOL {
        require(IERC20(mainTokenAddress).transferFrom(_msgSender(), address(this), _amount), Error.TRANSFER_FAILED);

        uint256 totalAmountIn = _amount;
        address[] memory followers = _followers[_msgSender()];
        uint256[] memory amountIns = new uint256[](followers.length);
        uint256[] memory fees = new uint256[](followers.length);
        for (uint256 i = 0; i < followers.length; i++) {
            if (
                _followSettings[_msgSender()][followers[i]] <=
                _balances[_msgSender()][followers[i]].get(mainTokenAddress)
            ) {
                uint256 fee = (_followSettings[_msgSender()][followers[i]] * systemFeePerThousand) / 1000;

                totalAmountIn += _followSettings[_msgSender()][followers[i]] - fee;
                amountIns[i] = _followSettings[_msgSender()][followers[i]] - fee;
                fees[i] = fee;

                totalSystemFee += fee;
            }
        }

        // Approve the router to spend input token.
        TransferHelper.safeApprove(mainTokenAddress, address(pancakeRouter), totalAmountIn);

        address[] memory path = new address[](2);
        path[0] = mainTokenAddress;
        path[1] = _outputToken;

        uint256[] memory outputExpect = pancakeRouter.getAmountsOut(totalAmountIn, path);

        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(
            totalAmountIn,
            (outputExpect[1] * _slipPage) / 1000,
            path,
            address(this),
            block.timestamp + _delay
        );

        uint256 totalAmountOut = amounts[1];

        // chia amount out cho KOL
        IERC20(_outputToken).transfer(_msgSender(), totalAmountOut * _amount / totalAmountIn);

        // chia số amount out cho user theo tỉ lệ
        for (uint256 i = 0; i < followers.length; i++) {
            if (amountIns[i] > 0) {
                uint256 amountOutForUser = totalAmountOut * amountIns[i] / totalAmountIn;
                _balances[_msgSender()][followers[i]].sub(mainTokenAddress, amountIns[i] + fees[i]);
                _balances[_msgSender()][followers[i]].add(_outputToken, amountOutForUser);
                emit Event.BuyToken(_msgSender(), _outputToken, amountIns[i], amountOutForUser);
            }
        }

        emit Event.CreateTransaction(_msgSender(), mainTokenAddress, totalAmountIn, _outputToken, totalAmountOut);
    }

    function sell(
        address _inputToken,
        uint256 _amount,
        uint256 _slipPage, // per thousand
        uint256 _delay // sec
    ) external nonReentrant onlyKOL {
        require(IERC20(_inputToken).transferFrom(_msgSender(), address(this), _amount), Error.TRANSFER_FAILED);

        // TODO: tính amount in theo số người follwers
        uint256 totalAmountIn = _amount;
        address[] memory followers = _followers[_msgSender()];
        uint256[] memory amountIns = new uint256[](followers.length);
        for (uint256 i = 0; i < followers.length; i++) {
            if (_balances[_msgSender()][followers[i]].get(_inputToken) > 0) {
                totalAmountIn += _balances[_msgSender()][followers[i]].get(_inputToken);
                amountIns[i] = _balances[_msgSender()][followers[i]].get(_inputToken);
            }
        }

        // Approve the router to spend input token.
        TransferHelper.safeApprove(_inputToken, address(pancakeRouter), totalAmountIn);

        address[] memory path = new address[](2);
        path[0] = _inputToken;
        path[1] = mainTokenAddress;

        uint256[] memory outputExpect = pancakeRouter.getAmountsOut(totalAmountIn, path);

        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(
            totalAmountIn,
            (outputExpect[1] * _slipPage) / 1000,
            path,
            address(this),
            block.timestamp + _delay
        );

        uint256 totalAmountOut = amounts[1];

        uint256 systemFee = (totalAmountOut * systemFeePerThousand) / 1000;
        totalSystemFee += systemFee;
        totalAmountOut -= systemFee;

        // chia amount out cho KOL
        IERC20(mainTokenAddress).transfer(_msgSender(), totalAmountOut * (_amount / totalAmountIn));

        // chia số amount out cho user theo tỉ lệ
        for (uint256 i = 0; i < followers.length; i++) {
            if (amountIns[i] > 0) {
                uint256 amountOutForUser = totalAmountOut * (amountIns[i] / totalAmountIn);
                _balances[_msgSender()][followers[i]].sub(_inputToken, amountIns[i]);
                _balances[_msgSender()][followers[i]].add(mainTokenAddress, amountOutForUser);
                emit Event.SellToken(_msgSender(), _inputToken, amountIns[i], amountOutForUser);
            }
        }

        emit Event.CreateTransaction(_msgSender(), _inputToken, totalAmountIn, mainTokenAddress, totalAmountOut);
    }

    function deposit(address _kol, uint256 _amount) external nonReentrant {
        require(_followings[_msgSender()].exists(_kol), Error.NOT_FOLLOW);
        require(kolList.checkActive(_kol), Error.KOL_IS_DE_ACTIVE);
        require(IERC20(mainTokenAddress).transferFrom(_msgSender(), address(this), _amount), Error.TRANSFER_FAILED);

        _balances[_kol][_msgSender()].add(mainTokenAddress, _amount);

        emit Event.Deposit(_msgSender(), mainTokenAddress, _amount);
    }

    function withdrawERC20(
        address _kol,
        address _token,
        uint256 _amount
    ) external nonReentrant {
        require(_balances[_kol][_msgSender()].exists(_token), Error.TRANSFER_AMOUNT_EXCEEDS_BALANCE);

        require(IERC20(_token).transfer(_msgSender(), _amount), Error.TRANSFER_FAILED);

        _balances[_kol][_msgSender()].sub(_token, _amount);

        emit Event.Withdrawn(_msgSender(), _token, _amount);
    }

    function withdrawTotalSystemFee() external nonReentrant onlyAdmin {
        require(IERC20(mainTokenAddress).transfer(_msgSender(), totalSystemFee), Error.TRANSFER_FAILED);
        totalSystemFee = 0;
    }

    function withdrawAnyToken(address _token) external nonReentrant onlyAdmin {
        // only for test
        require(IERC20(_token).transfer(_msgSender(), IERC20(_token).balanceOf(address(this))), Error.TRANSFER_FAILED);
    }
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

struct KOL {
    address addr;
    uint256 commission;
    bool isActive;
}

library KolLib {
    function exists(KOL[] storage self, address kol) internal view returns (bool) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].addr == kol) return true;
        }
        return false;
    }

    function updateCommission(
        KOL[] storage self,
        address kol,
        uint256 commission
    ) internal returns (bool) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].addr == kol) {
                self[i].commission = commission;
                return true;
            }
        }
        return false;
    }

    function setActive(
        KOL[] storage self,
        address kol,
        bool isActive
    ) internal returns (bool) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].addr == kol) {
                self[i].isActive = isActive;
                return true;
            }
        }
        return false;
    }

    function countActiveKOL(KOL[] storage self) internal view returns (uint256 count) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].isActive) {
                count++;
            }
        }
    }

    function getActiveKOL(KOL[] storage self) internal view returns (KOL[] memory) {
        uint256 numberOfActiveKOL = countActiveKOL(self);
        KOL[] memory activeKOL = new KOL[](numberOfActiveKOL);

        uint256 count = 0;
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].isActive) {
                activeKOL[count++] = self[i];
            }
        }

        return activeKOL;
    }

    function checkActive(KOL[] storage self, address kol) internal view returns (bool) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].addr == kol) {
                return self[i].isActive;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

struct FollowSetting {
    uint256 totalAmount;
    uint256 amountPerTran;
}

library FollowSettingLib {
    function update(
        FollowSetting storage self,
        uint256 totalAmount,
        uint256 amountPerTran
    ) internal {
        self.totalAmount = totalAmount;
        self.amountPerTran = amountPerTran;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

struct Balances {
    address token;
    uint256 amount;
}

library BalanceLib {
    function add(
        Balances[] storage self,
        address token,
        uint256 amount
    ) internal {
        if (!exists(self, token)) {
            self.push(Balances(token, amount));
        }
        else {
            for (uint256 i = 0; i < self.length; i++) {
                if (self[i].token == token) {
                    self[i].amount += amount;
                    break;
                }
            }
        }
    }

    function sub(
        Balances[] storage self,
        address token,
        uint256 amount
    ) internal {
        if (exists(self, token)) {
            for (uint256 i = 0; i < self.length; i++) {
                if (self[i].token == token) {
                    require(self[i].amount > amount, "Error: Sub balance amount");
                    self[i].amount -= amount;
                    break;
                }
            }
        }
    }

    function get(Balances[] storage self, address token) internal view returns (uint256) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].token == token) return self[i].amount;
        }

        return 0;
    }

    function exists(Balances[] storage self, address token) internal view returns (bool) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i].token == token) return true;
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

library AddressesLib {
    function add(address[] storage self, address element) internal {
        if (!exists(self, element)) self.push(element);
    }

    function remove(address[] storage self, address element) internal returns (bool) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i] == element) {
                self[i] = self[self.length - 1];
                self.pop();
                return true;
            }
        }
        return false;
    }

    function exists(address[] storage self, address element) internal view returns (bool) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i] == element) return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

library Event {
    event AddKOL(address kol, uint256 commission);
    event UpdateKOL(address kol, uint256 commission);

    event SetActiveKOL(address kol, bool isActive);

    event Follow(address user, address kol, uint256 totalAmount, uint256 amountPerTran);
    event UnFollow(address user, address kol);

    event Deposit(address user, address token, uint256 amount);

    event Withdrawn(address user, address token, uint256 amount);

    event BuyToken(address kol, address outputToken, uint256 amountIn, uint256 amountOut);
    event SellToken(address kol, address inputToken, uint256 amountIn, uint256 amountOut);

    event CreateTransaction(
        address kol,
        address inputToken,
        uint256 totalAmountIn,
        address outputToken,
        uint256 totalAmountOut
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

library Error {
    string public constant ADMIN_ROLE_REQUIRED = "Error: ADMIN role required";
    string public constant KOL_ROLE_REQUIRED = "Error: KOL role required";

    string public constant KOL_EXISTED = "Error: KOL existed";
    string public constant KOL_NOT_EXISTED = "Error: KOL not existed";
    string public constant KOL_IS_DE_ACTIVE = "Error: KOL is de active";

    string public constant NOT_FOLLOW = "Error: Not follow";

    string public constant TRANSFER_AMOUNT_EXCEEDS_BALANCE = "Error: Transfer amount exceeds balance";
    string public constant TRANSFER_FAILED = "Error: Transfer failed";

    string public constant KOL_FOLLOWED = "Error: Kol followed";

    string public constant AMOUNT_PER_TRAN_MUST_LESS_THAN_TOTAL_AMOUNT =
        "Error: Amount per tran must less than total amount";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}