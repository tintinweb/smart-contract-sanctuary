pragma solidity 0.8.2;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IController.sol";
import "./interfaces/INeuronPool.sol";
import "./interfaces/INeuronPoolConverter.sol";
import "./interfaces/IOneSplitAudit.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IConverter.sol";

// Deployed once (in contrast with nPools - those are created individually for each strategy).
// Then new nPools are added via setNPool function
contract Controller {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant burn = 0x000000000000000000000000000000000000dEaD;
    address public onesplit = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;

    address public governance;
    address public strategist;
    address public devfund;
    address public treasury;
    address public timelock;

    // Convenience fee 0.1%
    uint256 public convenienceFee = 100;
    uint256 public constant convenienceFeeMax = 100000;

    mapping(address => address) public nPools;
    mapping(address => address) public strategies;
    mapping(address => mapping(address => address)) public converters;
    mapping(address => mapping(address => bool)) public approvedStrategies;
    mapping(address => bool) public approvedNPoolConverters;

    uint256 public split = 500;
    uint256 public constant max = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _timelock,
        address _devfund,
        address _treasury
    ) {
        governance = _governance;
        strategist = _strategist;
        timelock = _timelock;
        devfund = _devfund;
        treasury = _treasury;
    }

    function setDevFund(address _devfund) public {
        require(msg.sender == governance, "!governance");
        devfund = _devfund;
    }

    function setTreasury(address _treasury) public {
        require(msg.sender == governance, "!governance");
        treasury = _treasury;
    }

    function setStrategist(address _strategist) public {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setSplit(uint256 _split) public {
        require(msg.sender == governance, "!governance");
        require(_split <= max, "numerator cannot be greater than denominator");
        split = _split;
    }

    function setOneSplit(address _onesplit) public {
        require(msg.sender == governance, "!governance");
        onesplit = _onesplit;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) public {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setNPool(address _token, address _nPool) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        require(nPools[_token] == address(0), "nPool");
        nPools[_token] = _nPool;
    }

    function approveNPoolConverter(address _converter) public {
        require(msg.sender == governance, "!governance");
        approvedNPoolConverters[_converter] = true;
    }

    function revokeNPoolConverter(address _converter) public {
        require(msg.sender == governance, "!governance");
        approvedNPoolConverters[_converter] = false;
    }

    // Called before adding strategy to controller, turns the strategy 'on-off'
    // We're in need of an additional array for strategies' on-off states (are we?)
    // Called when deploying
    function approveStrategy(address _token, address _strategy) public {
        require(msg.sender == timelock, "!timelock");
        approvedStrategies[_token][_strategy] = true;
    }

    // Turns off/revokes strategy
    function revokeStrategy(address _token, address _strategy) public {
        require(msg.sender == governance, "!governance");
        require(
            strategies[_token] != _strategy,
            "cannot revoke active strategy"
        );
        approvedStrategies[_token][_strategy] = false;
    }

    function setConvenienceFee(uint256 _convenienceFee) external {
        require(msg.sender == timelock, "!timelock");
        convenienceFee = _convenienceFee;
    }

    // Adding or updating a strategy
    function setStrategy(address _token, address _strategy) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        require(approvedStrategies[_token][_strategy] == true, "!approved");

        address _current = strategies[_token];
        if (_current != address(0)) {
            IStrategy(_current).withdrawAll();
        }
        strategies[_token] = _strategy;
    }

    // Depositing token to a pool
    function earn(address _token, uint256 _amount) public {
        address _strategy = strategies[_token];
        // Token needed for strategy
        address _want = IStrategy(_strategy).want();
        if (_want != _token) {
            // Convert if token other than wanted deposited
            address converter = converters[_token][_want];
            IERC20(_token).safeTransfer(converter, _amount);
            _amount = IConverter(converter).convert(_strategy);
            IERC20(_want).safeTransfer(_strategy, _amount);
        } else {
            // Transferring to the strategy address
            IERC20(_token).safeTransfer(_strategy, _amount);
        }
        // Calling deposit @ strategy
        IStrategy(_strategy).deposit();
    }

    function balanceOf(address _token) external view returns (uint256) {
        return IStrategy(strategies[_token]).balanceOf();
    }

    function withdrawAll(address _token) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        IStrategy(strategies[_token]).withdrawAll();
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!governance"
        );
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function inCaseStrategyTokenGetStuck(address _strategy, address _token)
        public
    {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!governance"
        );
        IStrategy(_strategy).withdraw(_token);
    }

    function getExpectedReturn(
        address _strategy,
        address _token,
        uint256 parts
    ) public view returns (uint256 expected) {
        uint256 _balance = IERC20(_token).balanceOf(_strategy);
        address _want = IStrategy(_strategy).want();
        (expected, ) = IOneSplitAudit(onesplit).getExpectedReturn(
            _token,
            _want,
            _balance,
            parts,
            0
        );
    }

    // Only allows to withdraw non-core strategy tokens and send to treasury ~ this is over and above normal yield
    function yearn(
        address _strategy,
        address _token,
        uint256 parts
    ) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!governance"
        );
        // This contract should never have value in it, but just incase since this is a public call
        uint256 _before = IERC20(_token).balanceOf(address(this));
        IStrategy(_strategy).withdraw(_token);
        uint256 _after = IERC20(_token).balanceOf(address(this));
        if (_after > _before) {
            uint256 _amount = _after.sub(_before);
            address _want = IStrategy(_strategy).want();
            uint256[] memory _distribution;
            uint256 _expected;
            _before = IERC20(_want).balanceOf(address(this));
            IERC20(_token).safeApprove(onesplit, 0);
            IERC20(_token).safeApprove(onesplit, _amount);
            (_expected, _distribution) = IOneSplitAudit(onesplit)
            .getExpectedReturn(_token, _want, _amount, parts, 0);
            IOneSplitAudit(onesplit).swap(
                _token,
                _want,
                _amount,
                _expected,
                _distribution,
                0
            );
            _after = IERC20(_want).balanceOf(address(this));
            if (_after > _before) {
                _amount = _after.sub(_before);
                uint256 _treasury = _amount.mul(split).div(max);
                earn(_want, _amount.sub(_treasury));
                IERC20(_want).safeTransfer(treasury, _treasury);
            }
        }
    }

    function withdraw(address _token, uint256 _amount) public {
        require(msg.sender == nPools[_token], "!nPool");
        IStrategy(strategies[_token]).withdraw(_amount);
    }

    // Function to swap between nPools
    // Seems to be called when a new version of NPool is created
    // With NPool functioning, unwanted tokens are sometimes landing here; this function helps transfer them to another pool
    // A transaction example https://etherscan.io/tx/0xc6f15e55f8520bc22a0bb9ac15b6f3fd80a0295e5c40b0e255eb7f3be34733f2
    // https://etherscan.io/txs?a=0x6847259b2B3A4c17e7c43C54409810aF48bA5210&ps=100&p=3 - Pickle's transaction calls
    // Last called ~140 days ago
    // Seems to be the culprit of recent Pickle's attack https://twitter.com/n2ckchong/status/1330244058669850624?lang=en
    // Googling the function returns some hack explanations https://halborn.com/category/explained-hacks/
    // >The problem with this function is that it doesn’t check the validity of the nPools presented to it
    function swapExactNPoolForNPool(
        address _fromNPool, // From which NPool
        address _toNPool, // To which NPool
        uint256 _fromNPoolAmount, // How much nPool tokens to swap
        uint256 _toNPoolMinAmount, // How much nPool tokens you'd like at a minimum
        address payable[] calldata _targets, // targets - converters' contract addresses
        bytes[] calldata _data
    ) external returns (uint256) {
        require(_targets.length == _data.length, "!length");

        // Only return last response
        for (uint256 i = 0; i < _targets.length; i++) {
            require(_targets[i] != address(0), "!converter");
            require(approvedNPoolConverters[_targets[i]], "!converter");
        }

        address _fromNPoolToken = INeuronPool(_fromNPool).token();
        address _toNPoolToken = INeuronPool(_toNPool).token();

        // Get pTokens from msg.sender
        IERC20(_fromNPool).safeTransferFrom(
            msg.sender,
            address(this),
            _fromNPoolAmount
        );

        // Calculate how much underlying
        // is the amount of pTokens worth
        uint256 _fromNPoolUnderlyingAmount = _fromNPoolAmount
        .mul(INeuronPool(_fromNPool).getRatio())
        .div(10**uint256(INeuronPool(_fromNPool).decimals()));

        // Call 'withdrawForSwap' on NPool's current strategy if NPool
        // doesn't have enough initial capital.
        // This has moves the funds from the strategy to the NPool's
        // 'earnable' amount. Enabling 'free' withdrawals
        uint256 _fromNPoolAvailUnderlying = IERC20(_fromNPoolToken).balanceOf(
            _fromNPool
        );
        if (_fromNPoolAvailUnderlying < _fromNPoolUnderlyingAmount) {
            IStrategy(strategies[_fromNPoolToken]).withdrawForSwap(
                _fromNPoolUnderlyingAmount.sub(_fromNPoolAvailUnderlying)
            );
        }

        // Withdraw from NPool
        // Note: this is free since its still within the "earnable" amount
        //       as we transferred the access
        IERC20(_fromNPool).safeApprove(_fromNPool, 0);
        IERC20(_fromNPool).safeApprove(_fromNPool, _fromNPoolAmount);
        INeuronPool(_fromNPool).withdraw(_fromNPoolAmount);

        // Calculate fee
        uint256 _fromUnderlyingBalance = IERC20(_fromNPoolToken).balanceOf(
            address(this)
        );
        uint256 _convenienceFee = _fromUnderlyingBalance
        .mul(convenienceFee)
        .div(convenienceFeeMax);

        if (_convenienceFee > 1) {
            IERC20(_fromNPoolToken).safeTransfer(
                devfund,
                _convenienceFee.div(2)
            );
            IERC20(_fromNPoolToken).safeTransfer(
                treasury,
                _convenienceFee.div(2)
            );
        }

        // Executes sequence of logic
        for (uint256 i = 0; i < _targets.length; i++) {
            _execute(_targets[i], _data[i]);
        }

        // Deposit into new NPool
        uint256 _toBal = IERC20(_toNPoolToken).balanceOf(address(this));
        IERC20(_toNPoolToken).safeApprove(_toNPool, 0);
        IERC20(_toNPoolToken).safeApprove(_toNPool, _toBal);
        INeuronPool(_toNPool).deposit(_toBal);

        // Send NPool Tokens to user
        uint256 _toNPoolBal = INeuronPool(_toNPool).balanceOf(address(this));
        if (_toNPoolBal < _toNPoolMinAmount) {
            revert("!min-nPool-amount");
        }

        INeuronPool(_toNPool).transfer(msg.sender, _toNPoolBal);

        return _toNPoolBal;
    }

    function _execute(address _target, bytes memory _data)
        internal
        returns (bytes memory response)
    {
        require(_target != address(0), "!target");

        // Call contract in current context
        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity 0.8.2;

interface IController {
    function nPools(address) external view returns (address);

    function rewards() external view returns (address);

    function devfund() external view returns (address);

    function treasury() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function withdraw(address, uint256) external;

    function earn(address, uint256) external;
}

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface INeuronPool is IERC20 {
    function token() external view returns (address);

    function claimInsurance() external; // NOTE: Only yDelegatedVault implements this

    function getRatio() external view returns (uint256);

    function depositAll() external;

    function deposit(uint256) external;

    function withdrawAll() external;

    function withdraw(uint256) external;

    function earn() external;

    function decimals() external view returns (uint8);
}

pragma solidity 0.8.2;

interface INeuronPoolConverter {
    function convert(
        address _refundExcess, // address to send the excess amount when adding liquidity
        uint256 _amount, // UNI LP Amount
        bytes calldata _data
    ) external returns (uint256);
}

pragma solidity 0.8.2;

interface IOneSplitAudit {
    function getExpectedReturn(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 parts,
        uint256 featureFlags
    )
        external
        view
        returns (uint256 returnAmount, uint256[] memory distribution);

    function swap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 featureFlags
    ) external payable;
}

pragma solidity 0.8.2;

interface IStrategy {
    function rewards() external view returns (address);

    function gauge() external view returns (address);

    function want() external view returns (address);

    function timelock() external view returns (address);

    function deposit() external;

    function withdrawForSwap(uint256) external returns (uint256);

    function withdraw(address) external;

    function withdraw(uint256) external;

    function skim() external;

    function withdrawAll() external returns (uint256);

    function balanceOf() external view returns (uint256);

    function harvest() external;

    function setTimelock(address) external;

    function setController(address _controller) external;

    function execute(address _target, bytes calldata _data)
        external
        payable
        returns (bytes memory response);

    function execute(bytes calldata _data)
        external
        payable
        returns (bytes memory response);
}

pragma solidity 0.8.2;

interface IConverter {
    function convert(address) external returns (uint256);
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

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/INeuronPool.sol";
import "../interfaces/IStEth.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/ICurve.sol";
import "../interfaces/IUniswapRouterV2.sol";
import "../interfaces/IController.sol";

import "./StrategyBase.sol";

contract StrategyCurveSteCrv is StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Curve
    IStEth public constant stEth = IStEth(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84); // lido stEth
    IERC20 public constant steCRV = IERC20(0x06325440D014e39736583c165C2963BA99fAf14E); // ETH-stETH curve lp

    // Curve DAO
    ICurveGauge public gauge =
        ICurveGauge(0x182B723a58739a9c974cFDB385ceaDb237453c28); // stEthGauge
    ICurveFi public curve =
        ICurveFi(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022); // stEthSwap
    address public mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    // Tokens we're farming
    IERC20 public constant crv =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 public constant ldo =
        IERC20(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32);

    // How much CRV tokens to keep
    uint256 public keepCRV = 500;
    uint256 public keepCRVMax = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyBase(
            address(steCRV),
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        steCRV.approve(address(gauge), type(uint256).max);
        stEth.approve(address(curve), type(uint256).max);
        ldo.safeApprove(address(univ2Router2), type(uint256).max);
        crv.approve(address(univ2Router2), type(uint256).max);
    }

    // Swap for ETH
    receive() external payable {}

    // **** Getters ****

    function balanceOfPool() public view override returns (uint256) {
        return gauge.balanceOf(address(this));
    }

    function getName() external pure override returns (string memory) {
        return "StrategyCurveStETH";
    }

    function getHarvestable() external view returns (uint256) {
        return gauge.claimable_reward(address(this), address(crv));
    }

    function getHarvestableEth() external view returns (uint256) {
        uint256 claimableLdo = gauge.claimable_reward(
            address(this),
            address(ldo)
        );
        uint256 claimableCrv = gauge.claimable_reward(
            address(this),
            address(crv)
        );

        return
            _estimateSell(address(crv), claimableCrv).add(
                _estimateSell(address(ldo), claimableLdo)
            );
    }

    function _estimateSell(address currency, uint256 amount)
        internal
        view
        returns (uint256 outAmount)
    {
        address[] memory path = new address[](2);
        path[0] = currency;
        path[1] = weth;
        uint256[] memory amounts = IUniswapRouterV2(univ2Router2).getAmountsOut(
            amount,
            path
        );
        outAmount = amounts[amounts.length - 1];

        return outAmount;
    }

    // **** Setters ****

    function setKeepCRV(uint256 _keepCRV) external {
        require(msg.sender == governance, "!governance");
        keepCRV = _keepCRV;
    }

    // **** State Mutations ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            gauge.deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        gauge.withdraw(_amount);
        return _amount;
    }

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun / sandwiched
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned/sandwiched?
        //      if so, a new strategy will be deployed.

        gauge.claim_rewards();
        ICurveMintr(mintr).mint(address(gauge));

        uint256 _ldo = ldo.balanceOf(address(this));
        uint256 _crv = crv.balanceOf(address(this));

        if (_crv > 0) {
            _swapToNeurAndDistributePerformanceFees(address(crv), sushiRouter);
        }

        if (_ldo > 0) {
            _swapToNeurAndDistributePerformanceFees(address(ldo), sushiRouter);
        }

        _ldo = ldo.balanceOf(address(this));
        _crv = crv.balanceOf(address(this));

        if (_crv > 0) {
            // How much CRV to keep to restake?
            uint256 _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);
            // IERC20(crv).safeTransfer(address(crvLocker), _keepCRV);
            if (_keepCRV > 0) {
                IERC20(crv).safeTransfer(
                    IController(controller).treasury(),
                    _keepCRV
                );
            }

            // How much CRV to swap?
            _crv = _crv.sub(_keepCRV);
            _swapUniswap(address(crv), weth, _crv);
        }
        if (_ldo > 0) {
            _swapUniswap(address(ldo), weth, _ldo);
        }
        IWETH(weth).withdraw(IWETH(weth).balanceOf(address(this)));

        uint256 _eth = address(this).balance;
        stEth.submit{value: _eth / 2}(strategist);
        _eth = address(this).balance;
        uint256 _stEth = stEth.balanceOf(address(this));

        uint256[2] memory liquidity;
        liquidity[0] = _eth;
        liquidity[1] = _stEth;

        curve.add_liquidity{value: _eth}(liquidity, 0);

        // We want to get back sCRV
        deposit();
    }
}

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IStEth is IERC20 {
    function submit(address) external payable returns (uint256);
}

pragma solidity 0.8.2;

interface IWETH {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);
}

pragma solidity 0.8.2;

interface ICurveFi {
    function add_liquidity(
        // stETH pool
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function balances(int128) external view returns (uint256);
}

interface ICurveFi_2 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts)
        external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(int128) external view returns (uint256);
}

interface ICurveFi_3 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external;

    function remove_liquidity_imbalance(
        uint256[3] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts)
        external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(uint256) external view returns (uint256);
}

interface ICurveFi_4 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external
        payable;

    function remove_liquidity_imbalance(
        uint256[4] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts)
        external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(int128) external view returns (uint256);
}

interface ICurveZap_4 {
    function add_liquidity(
        uint256[4] calldata uamounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata min_uamounts)
        external;

    function remove_liquidity_imbalance(
        uint256[4] calldata uamounts,
        uint256 max_burn_amount
    ) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount,
        bool donate_dust
    ) external;

    function withdraw_donated_dust() external;

    function coins(int128 arg0) external returns (address);

    function underlying_coins(int128 arg0) external returns (address);

    function curve() external returns (address);

    function token() external returns (address);
}

interface ICurveZap {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_uamount
    ) external;
}

// Interface to manage Crv strategies' interactions
interface ICurveGauge {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address addr) external;

    function balanceOf(address arg0) external view returns (uint256);

    function withdraw(uint256 _value) external;

    function withdraw(uint256 _value, bool claim_rewards) external;

    function claim_rewards() external;

    function claim_rewards(address addr) external;

    function claimable_tokens(address addr) external returns (uint256);

    function claimable_reward(address addr) external view returns (uint256);

    function claimable_reward(address, address) external view returns (uint256);

    function integrate_fraction(address arg0) external view returns (uint256);
}

interface ICurveMintr {
    function mint(address) external;

    function minted(address arg0, address arg1) external view returns (uint256);
}

interface ICurveVotingEscrow {
    function locked(address arg0)
        external
        view
        returns (int128 amount, uint256 end);

    function locked__end(address _addr) external view returns (uint256);

    function create_lock(uint256, uint256) external;

    function increase_amount(uint256) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function withdraw() external;

    function smart_wallet_checker() external returns (address);
}

interface ICurveSmartContractChecker {
    function wallets(address) external returns (bool);

    function approveWallet(address _wallet) external;
}

interface ICurveFi_Polygon_3 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_imbalance(
        uint256[3] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts)
        external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function balances(uint256) external view returns (uint256);
}

interface ICurveFi_Polygon_2 {
    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function dynamic_fee(int128 i, int128 j) external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[2] calldata _amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount)
        external
        returns (uint256);

    function add_liquidity(
        uint256[2] calldata _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts)
        external
        returns (uint256[2] calldata);

    function remove_liquidity(
        uint256 _amount,
        uint256[2] calldata _min_amounts,
        bool _use_underlying
    ) external returns (uint256[2] calldata);

    function remove_liquidity_imbalance(
        uint256[2] calldata _amounts,
        uint256 _max_burn_amount
    ) external returns (uint256);

    function remove_liquidity_imbalance(
        uint256[2] calldata _amounts,
        uint256 _max_burn_amount,
        bool _use_underlying
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount,
        bool _use_underlying
    ) external returns (uint256);

    function ramp_A(uint256 _future_A, uint256 _future_time) external;

    function stop_ramp_A() external;

    function commit_new_fee(
        uint256 new_fee,
        uint256 new_admin_fee,
        uint256 new_offpeg_fee_multiplier
    ) external;

    function apply_new_fee() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function withdraw_admin_fees() external;

    function donate_admin_fees() external;

    function kill_me() external;

    function unkill_me() external;

    function set_aave_referral(uint256 referral_code) external;

    function set_reward_receiver(address _reward_receiver) external;

    function set_admin_fee_receiver(address _admin_fee_receiver) external;

    function coins(uint256 arg0) external view returns (address);

    function underlying_coins(uint256 arg0) external view returns (address);

    function admin_balances(uint256 arg0) external view returns (uint256);

    function fee() external view returns (uint256);

    function offpeg_fee_multiplier() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function owner() external view returns (address);

    function lp_token() external view returns (address);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    function admin_actions_deadline() external view returns (uint256);

    function transfer_ownership_deadline() external view returns (uint256);

    function future_fee() external view returns (uint256);

    function future_admin_fee() external view returns (uint256);

    function future_offpeg_fee_multiplier() external view returns (uint256);

    function future_owner() external view returns (address);

    function reward_receiver() external view returns (address);

    function admin_fee_receiver() external view returns (address);
}

pragma solidity 0.8.2;

interface IUniswapRouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/INeuronPool.sol";
import "../interfaces/IStakingRewards.sol";
import "../interfaces/IUniswapRouterV2.sol";
import "../interfaces/IController.sol";

// Strategy Contract Basics

abstract contract StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Perfomance fees - start with 30%
    uint256 public performanceTreasuryFee = 3000;
    uint256 public constant performanceTreasuryMax = 10000;

    // Withdrawal fee 0%
    // - 0% to treasury
    // - 0% to dev fund
    uint256 public withdrawalTreasuryFee = 0;
    uint256 public constant withdrawalTreasuryMax = 100000;

    uint256 public withdrawalDevFundFee = 0;
    uint256 public constant withdrawalDevFundMax = 100000;

    // Tokens
    // Input token accepted by the contract
    address public immutable neuronTokenAddress;
    address public immutable want;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // User accounts
    address public governance;
    address public controller;
    address public strategist;
    address public timelock;

    // Dex
    address public constant univ2Router2 =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant sushiRouter =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    mapping(address => bool) public harvesters;

    constructor(
        // Input token accepted by the contract
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    ) {
        require(_want != address(0));
        require(_governance != address(0));
        require(_strategist != address(0));
        require(_controller != address(0));
        require(_neuronTokenAddress != address(0));
        require(_timelock != address(0));

        want = _want;
        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        neuronTokenAddress = _neuronTokenAddress;
        timelock = _timelock;
    }

    // **** Modifiers **** //

    modifier onlyBenevolent() {
        require(
            harvesters[msg.sender] ||
                msg.sender == governance ||
                msg.sender == strategist
        );
        _;
    }

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view virtual returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function getName() external pure virtual returns (string memory);

    // **** Setters **** //

    function whitelistHarvester(address _harvester) external {
        require(
            msg.sender == governance || msg.sender == strategist,
            "not authorized"
        );
        harvesters[_harvester] = true;
    }

    function revokeHarvester(address _harvester) external {
        require(
            msg.sender == governance || msg.sender == strategist,
            "not authorized"
        );
        harvesters[_harvester] = false;
    }

    function setWithdrawalDevFundFee(uint256 _withdrawalDevFundFee) external {
        require(msg.sender == timelock, "!timelock");
        withdrawalDevFundFee = _withdrawalDevFundFee;
    }

    function setWithdrawalTreasuryFee(uint256 _withdrawalTreasuryFee) external {
        require(msg.sender == timelock, "!timelock");
        withdrawalTreasuryFee = _withdrawalTreasuryFee;
    }

    function setPerformanceTreasuryFee(uint256 _performanceTreasuryFee)
        external
    {
        require(msg.sender == timelock, "!timelock");
        performanceTreasuryFee = _performanceTreasuryFee;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) external {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setController(address _controller) external {
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a pool withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        uint256 _feeDev = _amount.mul(withdrawalDevFundFee).div(
            withdrawalDevFundMax
        );
        IERC20(want).safeTransfer(IController(controller).devfund(), _feeDev);

        uint256 _feeTreasury = _amount.mul(withdrawalTreasuryFee).div(
            withdrawalTreasuryMax
        );
        IERC20(want).safeTransfer(
            IController(controller).treasury(),
            _feeTreasury
        );

        address _nPool = IController(controller).nPools(address(want));
        require(_nPool != address(0), "!nPool"); // additional protection so we don't burn the funds

        IERC20(want).safeTransfer(
            _nPool,
            _amount.sub(_feeDev).sub(_feeTreasury)
        );
    }

    // Withdraw funds, used to swap between strategies
    function withdrawForSwap(uint256 _amount)
        external
        returns (uint256 balance)
    {
        require(msg.sender == controller, "!controller");
        _withdrawSome(_amount);

        balance = IERC20(want).balanceOf(address(this));

        address _nPool = IController(controller).nPools(address(want));
        require(_nPool != address(0), "!nPool");
        IERC20(want).safeTransfer(_nPool, balance);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        address _nPool = IController(controller).nPools(address(want));
        require(_nPool != address(0), "!nPool"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_nPool, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    function harvest() public virtual;

    // **** Emergency functions ****

    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes memory response)
    {
        require(msg.sender == timelock, "!timelock");
        require(_target != address(0), "!target");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    // **** Internal functions ****
    function _swapUniswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        IUniswapRouterV2(univ2Router2).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }

    function _swapUniswapWithPath(address[] memory path, uint256 _amount)
        internal
    {
        require(path[1] != address(0));

        IUniswapRouterV2(univ2Router2).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }

    function _swapSushiswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        IUniswapRouterV2(sushiRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }

    function _swapWithUniLikeRouter(
        address routerAddress,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        require(_to != address(0));
        require(
            routerAddress != address(0),
            "_swapWithUniLikeRouter routerAddress cant be zero"
        );

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        try
            IUniswapRouterV2(routerAddress).swapExactTokensForTokens(
                _amount,
                0,
                path,
                address(this),
                block.timestamp.add(60)
            )
        {
            return true;
        } catch {
            return false;
        }
    }

    function _swapSushiswapWithPath(address[] memory path, uint256 _amount)
        internal
    {
        require(path[1] != address(0));

        IUniswapRouterV2(sushiRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }

    function _swapToNeurAndDistributePerformanceFees(
        address swapToken,
        address swapRouterAddress
    ) internal {
        uint256 swapTokenBalance = IERC20(swapToken).balanceOf(address(this));

        if (swapTokenBalance > 0 && performanceTreasuryFee > 0) {
            uint256 performanceTreasuryFeeAmount = swapTokenBalance
                .mul(performanceTreasuryFee)
                .div(performanceTreasuryMax);
            uint256 totalFeeAmout = performanceTreasuryFeeAmount;

            _swapAmountToNeurAndDistributePerformanceFees(
                swapToken,
                totalFeeAmout,
                swapRouterAddress
            );
        }
    }

    function _swapAmountToNeurAndDistributePerformanceFees(
        address swapToken,
        uint256 amount,
        address swapRouterAddress
    ) internal {
        uint256 swapTokenBalance = IERC20(swapToken).balanceOf(address(this));

        require(
            swapTokenBalance >= amount,
            "Amount is bigger than token balance"
        );

        IERC20(swapToken).safeApprove(swapRouterAddress, 0);
        IERC20(weth).safeApprove(swapRouterAddress, 0);
        IERC20(swapToken).safeApprove(swapRouterAddress, amount);
        IERC20(weth).safeApprove(swapRouterAddress, type(uint256).max);
        bool isSuccesfullSwap = _swapWithUniLikeRouter(
            swapRouterAddress,
            swapToken,
            neuronTokenAddress,
            amount
        );

        if (isSuccesfullSwap) {
            uint256 neuronTokenBalance = IERC20(neuronTokenAddress).balanceOf(
                address(this)
            );

            if (neuronTokenBalance > 0) {
                // Treasury fees
                // Sending strategy's tokens to treasury. Initially @ 30% (set by performanceTreasuryFee constant) of strategy's assets
                IERC20(neuronTokenAddress).safeTransfer(
                    IController(controller).treasury(),
                    neuronTokenBalance
                );
            }
        } else {
            // If failed swap to Neuron just transfer swap token to treasury
            IERC20(swapToken).safeApprove(IController(controller).treasury(), 0);
            IERC20(swapToken).safeApprove(IController(controller).treasury(), amount);
            IERC20(swapToken).safeTransfer(
                IController(controller).treasury(),
                amount
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IStakingRewards {
    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function exit() external;

    function getReward() external;

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function notifyRewardAmount(uint256 reward) external;

    function periodFinish() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewards(address) external view returns (uint256);

    function rewardsDistribution() external view returns (address);

    function rewardsDuration() external view returns (uint256);

    function rewardsToken() external view returns (address);

    function stake(uint256 amount) external;

    function stakeWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function withdraw(uint256 amount) external;
}

interface IStakingRewardsFactory {
    function deploy(address stakingToken, uint256 rewardAmount) external;

    function isOwner() external view returns (bool);

    function notifyRewardAmount(address stakingToken) external;

    function notifyRewardAmounts() external;

    function owner() external view returns (address);

    function renounceOwnership() external;

    function rewardsToken() external view returns (address);

    function stakingRewardsGenesis() external view returns (uint256);

    function stakingRewardsInfoByStakingToken(address)
        external
        view
        returns (address stakingRewards, uint256 rewardAmount);

    function stakingTokens(uint256) external view returns (address);

    function transferOwnership(address newOwner) external;
}

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./StrategyBase.sol";
import "../interfaces/ISushiChef.sol";

abstract contract StrategySushiFarmBaseCustomHarvest is StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Token addresses
    address public constant sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public constant masterChef =
        0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;

    // WETH/<token1> pair
    address public token1;

    // How much SUSHI tokens to keep?
    uint256 public keepSUSHI = 0;
    uint256 public constant keepSUSHIMax = 10000;

    uint256 public poolId;

    constructor(
        address _token1,
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyBase(
            _lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        poolId = _poolId;
        token1 = _token1;
        IERC20(sushi).safeApprove(sushiRouter, type(uint256).max);
        IERC20(weth).safeApprove(sushiRouter, type(uint256).max);
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = ISushiChef(masterChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return ISushiChef(masterChef).pendingSushi(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterChef, 0);
            IERC20(want).safeApprove(masterChef, _want);
            ISushiChef(masterChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ISushiChef(masterChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** Setters ****

    function setKeepSUSHI(uint256 _keepSUSHI) external {
        require(msg.sender == timelock, "!timelock");
        keepSUSHI = _keepSUSHI;
    }
}

pragma solidity 0.8.2;

// interface for Sushiswap MasterChef contract
interface ISushiChef {
    function BONUS_MULTIPLIER() external view returns (uint256);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        bool _withUpdate
    ) external;

    function bonusEndBlock() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function dev(address _devaddr) external;

    function devFundDivRate() external view returns (uint256);

    function devaddr() external view returns (address);

    function emergencyWithdraw(uint256 _pid) external;

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    function massUpdatePools() external;

    function owner() external view returns (address);

    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function sushi() external view returns (address);

    function sushiPerBlock() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accsushiPerShare
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setBonusEndBlock(uint256 _bonusEndBlock) external;

    function setDevFundDivRate(uint256 _devFundDivRate) external;

    function setsushiPerBlock(uint256 _sushiPerBlock) external;

    function startBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;
}

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./StrategyBase.sol";
import "../interfaces/ISushiChef.sol";

abstract contract StrategySushiFarmBase is StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Token addresses
    address public constant sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public constant masterChef =
        0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;

    // WETH/<token1> pair
    address public token1;

    // How much SUSHI tokens to keep?
    uint256 public keepSUSHI = 0;
    uint256 public constant keepSUSHIMax = 10000;

    uint256 public poolId;

    constructor(
        address _token1,
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyBase(
            _lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        poolId = _poolId;
        token1 = _token1;
        IERC20(sushi).safeApprove(sushiRouter, type(uint256).max);
        IERC20(weth).safeApprove(sushiRouter, type(uint256).max);
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = ISushiChef(masterChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256) {
        return ISushiChef(masterChef).pendingSushi(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterChef, 0);
            IERC20(want).safeApprove(masterChef, _want);
            ISushiChef(masterChef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ISushiChef(masterChef).withdraw(poolId, _amount);
        return _amount;
    }

    // **** Setters ****

    function setKeepSUSHI(uint256 _keepSUSHI) external {
        require(msg.sender == timelock, "!timelock");
        keepSUSHI = _keepSUSHI;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects SUSHI tokens
        ISushiChef(masterChef).deposit(poolId, 0);
        uint256 _sushi = IERC20(sushi).balanceOf(address(this));

        if (_sushi > 0) {
            _swapToNeurAndDistributePerformanceFees(sushi, sushiRouter);
        }

        _sushi = IERC20(sushi).balanceOf(address(this));

        if (_sushi > 0) {
            // 10% is locked up for future gov
            uint256 _keepSUSHI = _sushi.mul(keepSUSHI).div(keepSUSHIMax);
            IERC20(sushi).safeTransfer(
                IController(controller).treasury(),
                _keepSUSHI
            );
            uint256 _swap = _sushi.sub(_keepSUSHI);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _swap);
            _swapSushiswap(sushi, weth, _swap);
        }

        // Swap half WETH for token1
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            _swapSushiswap(weth, token1, _weth.div(2));
        }

        // Adds in liquidity for ETH/token1
        _weth = IERC20(weth).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_weth > 0 && _token1 > 0) {
            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            IUniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                token1,
                _weth,
                _token1,
                0,
                0,
                address(this),
                block.timestamp + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        deposit();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiFarmBase.sol";

contract StrategySushiEthWbtcLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public constant sushi_wbtc_poolId = 21;
    // Token addresses
    address public constant sushi_eth_wbtc_lp = 0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58;
    address public constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiFarmBase(
            wbtc,
            sushi_wbtc_poolId,
            sushi_eth_wbtc_lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthWbtcLp";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiFarmBase.sol";

contract StrategySushiEthUsdcLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public constant sushi_usdc_poolId = 1;
    // Token addresses
    address public constant sushi_eth_usdc_lp =
        0x397FF1542f962076d0BFE58eA045FfA2d347ACa0;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiFarmBase(
            usdc,
            sushi_usdc_poolId,
            sushi_eth_usdc_lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthUsdcLp";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./StrategyFeiFarmBase.sol";

contract StrategyFeiTribeLp is StrategyFeiFarmBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Token addresses
    address public constant fei_rewards = 0x18305DaAe09Ea2F4D51fAa33318be5978D251aBd;
    address public constant uni_fei_tribe_lp =
        0x9928e4046d7c6513326cCeA028cD3e7a91c7590A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyFeiFarmBase(
            fei_rewards,
            uni_fei_tribe_lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyFeiTribeLp";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategyStakingRewardsBase.sol";

abstract contract StrategyFeiFarmBase is StrategyStakingRewardsBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Token addresses
    address public constant fei = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;
    address public constant tribe = 0xc7283b66Eb1EB5FB86327f08e1B5816b0720212B;

    // How much TRIBE tokens to keep?
    uint256 public keepTRIBE = 0;
    uint256 public constant keepTRIBEMax = 10000;

    // Uniswap swap paths
    address[] public tribe_fei_path;

    constructor(
        address _rewards,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyStakingRewardsBase(
            _rewards,
            _lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        tribe_fei_path = new address[](2);
        tribe_fei_path[0] = tribe;
        tribe_fei_path[1] = fei;

        IERC20(fei).approve(univ2Router2, type(uint256).max);
        IERC20(tribe).approve(univ2Router2, type(uint256).max);
    }

    // **** Setters ****

    function setKeepTRIBE(uint256 _keepTRIBE) external {
        require(msg.sender == timelock, "!timelock");
        keepTRIBE = _keepTRIBE;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects TRIBE tokens
        IStakingRewards(rewards).getReward();
        uint256 _tribe = IERC20(tribe).balanceOf(address(this));
        uint256 _fei = IERC20(fei).balanceOf(address(this));

        if (_tribe > 0 && performanceTreasuryFee > 0) {
            uint256 tribePerfomanceFeeAmount = _tribe
                .mul(performanceTreasuryFee)
                .div(performanceTreasuryMax);
            _swapUniswapWithPath(tribe_fei_path, tribePerfomanceFeeAmount);
            _fei = IERC20(fei).balanceOf(address(this));
            _swapAmountToNeurAndDistributePerformanceFees(
                fei,
                _fei,
                sushiRouter
            );
        }

        _tribe = IERC20(tribe).balanceOf(address(this));

        if (_tribe > 0 && performanceTreasuryFee > 0) {
            // 10% is locked up for future gov
            uint256 _keepTRIBE = _tribe.mul(keepTRIBE).div(keepTRIBEMax);
            IERC20(tribe).safeTransfer(
                IController(controller).treasury(),
                _keepTRIBE
            );
            _tribe = _tribe.sub(_keepTRIBE);

            _swapUniswapWithPath(tribe_fei_path, _tribe.div(2));
        }

        // Adds in liquidity for FEI/TRIBE
        _fei = IERC20(fei).balanceOf(address(this));
        _tribe = IERC20(tribe).balanceOf(address(this));
        if (_fei > 0 && _tribe > 0) {
            IUniswapRouterV2(univ2Router2).addLiquidity(
                fei,
                tribe,
                _fei,
                _tribe,
                0,
                0,
                address(this),
                block.timestamp + 60
            );

            // Donates DUST
            IERC20(fei).safeTransfer(
                IController(controller).treasury(),
                IERC20(fei).balanceOf(address(this))
            );
            IERC20(tribe).safeTransfer(
                IController(controller).treasury(),
                IERC20(tribe).balanceOf(address(this))
            );
        }

        // We want to get back FEI-TRIBE LP tokens
        deposit();
    }
}

pragma solidity 0.8.2;

import "./StrategyBase.sol";

// Base contract for SNX Staking rewards contract interfaces

abstract contract StrategyStakingRewardsBase is StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public rewards;

    // **** Getters ****
    constructor(
        address _rewards,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    ) StrategyBase(_want, _governance, _strategist, _controller, _neuronTokenAddress, _timelock) {
        rewards = _rewards;
    }

    function balanceOfPool() public view override returns (uint256) {
        return IStakingRewards(rewards).balanceOf(address(this));
    }

    function getHarvestable() external view returns (uint256) {
        return IStakingRewards(rewards).earned(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).safeApprove(rewards, _want);
            IStakingRewards(rewards).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStakingRewards(rewards).withdraw(_amount);
        return _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./StrategySushiFarmBaseCustomHarvest.sol";

contract StrategySushiEthSushiLp is StrategySushiFarmBaseCustomHarvest {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Token/ETH pool id in MasterChef contract
    uint256 public constant sushi_eth_poolId = 12;
    // Token addresses
    address public constant sushi_eth_sushi_lp =
        0x795065dCc9f64b5614C407a6EFDC400DA6221FB0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiFarmBaseCustomHarvest(
            sushi,
            sushi_eth_poolId,
            sushi_eth_sushi_lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthSushiLp";
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects SUSHI tokens
        ISushiChef(masterChef).deposit(poolId, 0);
        uint256 _sushi = IERC20(sushi).balanceOf(address(this));

        if (_sushi > 0) {
            _swapToNeurAndDistributePerformanceFees(sushi, sushiRouter);
        }

        _sushi = IERC20(sushi).balanceOf(address(this));

        if (_sushi > 0) {
            // 10% is locked up for future gov
            uint256 _keepSUSHI = _sushi.mul(keepSUSHI).div(keepSUSHIMax);
            IERC20(sushi).safeTransfer(
                IController(controller).treasury(),
                _keepSUSHI
            );
            uint256 _swap = _sushi.sub(_keepSUSHI);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _swap);

            // swap only half of sushi cause since it's used in lp itself
            _swapSushiswap(sushi, weth, _swap.div(2));
        }

        // Swap entire WETH for token1
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        // Adds in liquidity for ETH/sushi
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_weth > 0 && _token1 > 0) {
            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            IUniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                token1,
                _weth,
                _token1,
                0,
                0,
                address(this),
                block.timestamp + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        deposit();
    }
}

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/YearnAffiliateWrapper.sol";
import "../interfaces/IController.sol";

contract StrategyYearnAffiliate is YearnAffiliateWrapper {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // User accounts
    address public governance;
    address public controller;
    address public strategist;
    address public timelock;

    address public want;

    string public name;

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }

    // **** Getters ****
    constructor(
        address _want,
        address _yearnRegistry,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) YearnAffiliateWrapper(_want, _yearnRegistry) {
        require(_want != address(0));
        require(_governance != address(0));
        require(_strategist != address(0));
        require(_controller != address(0));
        require(_timelock != address(0));

        want = _want;
        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        timelock = _timelock;

        name = string(
            abi.encodePacked("y", ERC20(_want).symbol(), " Affiliate Strategy")
        );
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOf() public view returns (uint256) {
        return totalVaultBalance(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        return balanceOf();
    }

    function getName() external view returns (string memory) {
        return name;
    }

    // **** Setters ****

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    function deposit() public {
        require(msg.sender == controller, "!controller");
        uint256 _want = IERC20(want).balanceOf(address(this));
        _deposit(address(this), address(this), _want, false);
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a pool withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");

        _withdrawSome(_amount);

        uint256 _balance = IERC20(want).balanceOf(address(this));

        address _pool = IController(controller).nPools(address(want));
        require(_pool != address(0), "!pool"); // additional protection so we don't burn the funds

        IERC20(want).safeTransfer(_pool, _balance);
    }

    // Withdraw funds, used to swap between strategies
    function withdrawForSwap(uint256 _amount)
        external
        returns (uint256 balance)
    {
        require(msg.sender == controller, "!controller");
        _withdrawSome(_amount);

        balance = IERC20(want).balanceOf(address(this));

        address _pool = IController(controller).nPools(address(want));
        require(_pool != address(0), "!pool");
        IERC20(want).safeTransfer(_pool, balance);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawSome(balanceOf());

        balance = IERC20(want).balanceOf(address(this));

        address _pool = IController(controller).nPools(address(want));
        require(_pool != address(0), "!pool"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_pool, balance);
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        return _withdraw(address(this), address(this), _amount, true); // `true` = withdraw from `bestVault`
    }

    // **** Emergency functions ****

    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes memory response)
    {
        require(msg.sender == timelock, "!timelock");
        require(_target != address(0), "!target");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    function migrate() external onlyGovernance returns (uint256) {
        return _migrate(address(this));
    }

    function migrate(uint256 amount) external onlyGovernance returns (uint256) {
        return _migrate(address(this), amount);
    }

    function migrate(uint256 amount, uint256 maxMigrationLoss)
        external
        onlyGovernance
        returns (uint256)
    {
        return _migrate(address(this), amount, maxMigrationLoss);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface RegistryAPI {
    function governance() external view returns (address);

    function latestVault(address token) external view returns (address);

    function numVaults(address token) external view returns (uint256);

    function vaults(address token, uint256 deploymentId) external view returns (address);
}

interface VaultAPI is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient) external returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function token() external view returns (address);

    // function strategies(address _strategy) external view returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}

abstract contract YearnAffiliateWrapper {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;

    // Reduce number of external calls (SLOADs stay the same)
    VaultAPI[] private _cachedVaults;

    RegistryAPI public registry;

    // ERC20 Unlimited Approvals (short-circuits VaultAPI.transferFrom)
    uint256 constant UNLIMITED_APPROVAL = type(uint256).max;
    // Sentinal values used to save gas on deposit/withdraw/migrate
    // NOTE: DEPOSIT_EVERYTHING == WITHDRAW_EVERYTHING == MIGRATE_EVERYTHING
    uint256 constant DEPOSIT_EVERYTHING = type(uint256).max;
    uint256 constant WITHDRAW_EVERYTHING = type(uint256).max;
    uint256 constant MIGRATE_EVERYTHING = type(uint256).max;
    // VaultsAPI.depositLimit is unlimited
    uint256 constant UNCAPPED_DEPOSITS = type(uint256).max;

    constructor(address _token, address _registry) {
        // Recommended to use a token with a `Registry.latestVault(_token) != address(0)`
        token = IERC20(_token);
        // Recommended to use `v2.registry.ychad.eth`
        registry = RegistryAPI(_registry);
    }

    /**
     * @notice
     *  Used to update the yearn registry.
     * @param _registry The new _registry address.
     */
    function setRegistry(address _registry) external {
        require(msg.sender == registry.governance());
        // In case you want to override the registry instead of re-deploying
        registry = RegistryAPI(_registry);
        // Make sure there's no change in governance
        // NOTE: Also avoid bricking the wrapper from setting a bad registry
        require(msg.sender == registry.governance());
    }

    /**
     * @notice
     *  Used to get the most revent vault for the token using the registry.
     * @return An instance of a VaultAPI
     */
    function bestVault() public virtual view returns (VaultAPI) {
        return VaultAPI(registry.latestVault(address(token)));
    }

    /**
     * @notice
     *  Used to get all vaults from the registery for the token
     * @return An array containing instances of VaultAPI
     */
    function allVaults() public virtual view returns (VaultAPI[] memory) {
        uint256 cache_length = _cachedVaults.length;
        uint256 num_vaults = registry.numVaults(address(token));

        // Use cached
        if (cache_length == num_vaults) {
            return _cachedVaults;
        }

        VaultAPI[] memory vaults = new VaultAPI[](num_vaults);

        for (uint256 vault_id = 0; vault_id < cache_length; vault_id++) {
            vaults[vault_id] = _cachedVaults[vault_id];
        }

        for (uint256 vault_id = cache_length; vault_id < num_vaults; vault_id++) {
            vaults[vault_id] = VaultAPI(registry.vaults(address(token), vault_id));
        }

        return vaults;
    }

    function _updateVaultCache(VaultAPI[] memory vaults) internal {
        // NOTE: even though `registry` is update-able by Yearn, the intended behavior
        //       is that any future upgrades to the registry will replay the version
        //       history so that this cached value does not get out of date.
        if (vaults.length > _cachedVaults.length) {
            _cachedVaults = vaults;
        }
    }

    /**
     * @notice
     *  Used to get the balance of an account accross all the vaults for a token.
     *  @dev will be used to get the wrapper balance using totalVaultBalance(address(this)).
     *  @param account The address of the account.
     *  @return balance of token for the account accross all the vaults.
     */
    function totalVaultBalance(address account) public view returns (uint256 balance) {
        VaultAPI[] memory vaults = allVaults();

        for (uint256 id = 0; id < vaults.length; id++) {
            balance = balance.add(vaults[id].balanceOf(account).mul(vaults[id].pricePerShare()).div(10**uint256(vaults[id].decimals())));
        }
    }

    /**
     * @notice
     *  Used to get the TVL on the underlying vaults.
     *  @return assets the sum of all the assets managed by the underlying vaults.
     */
    function totalAssets() public view returns (uint256 assets) {
        VaultAPI[] memory vaults = allVaults();

        for (uint256 id = 0; id < vaults.length; id++) {
            assets = assets.add(vaults[id].totalAssets());
        }
    }

    function _deposit(
        address depositor,
        address receiver,
        uint256 amount, // if `MAX_UINT256`, just deposit everything
        bool pullFunds // If true, funds need to be pulled from `depositor` via `transferFrom`
    ) internal returns (uint256 deposited) {
        VaultAPI _bestVault = bestVault();

        if (pullFunds) {
            if (amount != DEPOSIT_EVERYTHING) {
                token.safeTransferFrom(depositor, address(this), amount);
            } else {
                token.safeTransferFrom(depositor, address(this), token.balanceOf(depositor));
            }
        }

        if (token.allowance(address(this), address(_bestVault)) < amount) {
            token.safeApprove(address(_bestVault), 0); // Avoid issues with some tokens requiring 0
            token.safeApprove(address(_bestVault), UNLIMITED_APPROVAL); // Vaults are trusted
        }

        // Depositing returns number of shares deposited
        // NOTE: Shortcut here is assuming the number of tokens deposited is equal to the
        //       number of shares credited, which helps avoid an occasional multiplication
        //       overflow if trying to adjust the number of shares by the share price.
        uint256 beforeBal = token.balanceOf(address(this));
        if (receiver != address(this)) {
            _bestVault.deposit(amount, receiver);
        } else if (amount != DEPOSIT_EVERYTHING) {
            _bestVault.deposit(amount);
        } else {
            _bestVault.deposit();
        }

        uint256 afterBal = token.balanceOf(address(this));
        deposited = beforeBal.sub(afterBal);
        // `receiver` now has shares of `_bestVault` as balance, converted to `token` here
        // Issue a refund if not everything was deposited
        if (depositor != address(this) && afterBal > 0) token.safeTransfer(depositor, afterBal);
    }

    function _withdraw(
        address sender,
        address receiver,
        uint256 amount, // if `MAX_UINT256`, just withdraw everything
        bool withdrawFromBest // If true, also withdraw from `_bestVault`
    ) internal returns (uint256 withdrawn) {
        VaultAPI _bestVault = bestVault();

        VaultAPI[] memory vaults = allVaults();
        _updateVaultCache(vaults);

        // NOTE: This loop will attempt to withdraw from each Vault in `allVaults` that `sender`
        //       is deposited in, up to `amount` tokens. The withdraw action can be expensive,
        //       so it if there is a denial of service issue in withdrawing, the downstream usage
        //       of this wrapper contract must give an alternative method of withdrawing using
        //       this function so that `amount` is less than the full amount requested to withdraw
        //       (e.g. "piece-wise withdrawals"), leading to less loop iterations such that the
        //       DoS issue is mitigated (at a tradeoff of requiring more txns from the end user).
        for (uint256 id = 0; id < vaults.length; id++) {
            if (!withdrawFromBest && vaults[id] == _bestVault) {
                continue; // Don't withdraw from the best
            }

            // Start with the total shares that `sender` has
            uint256 availableShares = vaults[id].balanceOf(sender);

            // Restrict by the allowance that `sender` has to this contract
            // NOTE: No need for allowance check if `sender` is this contract
            if (sender != address(this)) {
                availableShares = Math.min(availableShares, vaults[id].allowance(sender, address(this)));
            }

            // Limit by maximum withdrawal size from each vault
            availableShares = Math.min(availableShares, vaults[id].maxAvailableShares());

            if (availableShares > 0) {
                // Intermediate step to move shares to this contract before withdrawing
                // NOTE: No need for share transfer if this contract is `sender`
                if (sender != address(this)) vaults[id].transferFrom(sender, address(this), availableShares);

                if (amount != WITHDRAW_EVERYTHING) {
                    // Compute amount to withdraw fully to satisfy the request
                    uint256 estimatedShares = amount
                        .sub(withdrawn) // NOTE: Changes every iteration
                        .mul(10**uint256(vaults[id].decimals()))
                        .div(vaults[id].pricePerShare()); // NOTE: Every Vault is different

                    // Limit amount to withdraw to the maximum made available to this contract
                    // NOTE: Avoid corner case where `estimatedShares` isn't precise enough
                    // NOTE: If `0 < estimatedShares < 1` but `availableShares > 1`, this will withdraw more than necessary
                    if (estimatedShares > 0 && estimatedShares < availableShares) {
                        withdrawn = withdrawn.add(vaults[id].withdraw(estimatedShares));
                    } else {
                        withdrawn = withdrawn.add(vaults[id].withdraw(availableShares));
                    }
                } else {
                    withdrawn = withdrawn.add(vaults[id].withdraw());
                }

                // Check if we have fully satisfied the request
                // NOTE: use `amount = WITHDRAW_EVERYTHING` for withdrawing everything
                if (amount <= withdrawn) break; // withdrawn as much as we needed
            }
        }

        // If we have extra, deposit back into `_bestVault` for `sender`
        // NOTE: Invariant is `withdrawn <= amount`
        if (withdrawn > amount) {
            // Don't forget to approve the deposit
            if (token.allowance(address(this), address(_bestVault)) < withdrawn.sub(amount)) {
                token.safeApprove(address(_bestVault), UNLIMITED_APPROVAL); // Vaults are trusted
            }

            _bestVault.deposit(withdrawn.sub(amount), sender);
            withdrawn = amount;
        }

        // `receiver` now has `withdrawn` tokens as balance
        if (receiver != address(this)) token.safeTransfer(receiver, withdrawn);
    }

    function _migrate(address account) internal returns (uint256) {
        return _migrate(account, MIGRATE_EVERYTHING);
    }

    function _migrate(address account, uint256 amount) internal returns (uint256) {
        // NOTE: In practice, it was discovered that <50 was the maximum we've see for this variance
        return _migrate(account, amount, 0);
    }

    function _migrate(
        address account,
        uint256 amount,
        uint256 maxMigrationLoss
    ) internal returns (uint256 migrated) {
        VaultAPI _bestVault = bestVault();

        // NOTE: Only override if we aren't migrating everything
        uint256 _depositLimit = _bestVault.depositLimit();
        uint256 _totalAssets = _bestVault.totalAssets();
        if (_depositLimit <= _totalAssets) return 0; // Nothing to migrate (not a failure)

        uint256 _amount = amount;
        if (_depositLimit < UNCAPPED_DEPOSITS && _amount < WITHDRAW_EVERYTHING) {
            // Can only deposit up to this amount
            uint256 _depositLeft = _depositLimit.sub(_totalAssets);
            if (_amount > _depositLeft) _amount = _depositLeft;
        }

        if (_amount > 0) {
            // NOTE: `false` = don't withdraw from `_bestVault`
            uint256 withdrawn = _withdraw(account, address(this), _amount, false);
            if (withdrawn == 0) return 0; // Nothing to migrate (not a failure)

            // NOTE: `false` = don't do `transferFrom` because it's already local
            migrated = _deposit(address(this), account, withdrawn, false);
            // NOTE: Due to the precision loss of certain calculations, there is a small inefficency
            //       on how migrations are calculated, and this could lead to a DoS issue. Hence, this
            //       value is made to be configurable to allow the user to specify how much is acceptable
            require(withdrawn.sub(migrated) <= maxMigrationLoss);
        } // else: nothing to migrate! (not a failure)
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategyYearnAffiliate.sol";

contract StrategyYearnUsdcV2 is StrategyYearnAffiliate {
    // Token addresses
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant yearn_registry = 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        StrategyYearnAffiliate(
            usdc,
            yearn_registry,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategyYearnAffiliate.sol";

contract StrategyYearnCrvSteth is StrategyYearnAffiliate {
    // Token addresses
    address public constant crv_steth_lp = 0x06325440D014e39736583c165C2963BA99fAf14E;
    address public constant yearn_registry = 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        StrategyYearnAffiliate(
            crv_steth_lp,
            yearn_registry,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategyYearnAffiliate.sol";

contract StrategyYearnCrvLusd is StrategyYearnAffiliate {
    // Token addresses
    address public constant crv_lusd_lp = 0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address public constant yearn_registry = 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        StrategyYearnAffiliate(
            crv_lusd_lp,
            yearn_registry,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategyYearnAffiliate.sol";

contract StrategyYearnCrvFrax is StrategyYearnAffiliate {
    // Token addresses
    address public constant crv_frax_lp = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address public constant yearn_registry = 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        StrategyYearnAffiliate(
            crv_frax_lp,
            yearn_registry,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}
}

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/INeuronPool.sol";
import "../interfaces/ICurve.sol";
import "../interfaces/IUniswapRouterV2.sol";
import "../interfaces/IController.sol";

import "./StrategyCurveBase.sol";

contract StrategyCurveRenCrv is StrategyCurveBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // https://www.curve.fi/ren
    // Curve stuff
    address public constant ren_pool = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
    address public constant ren_gauge = 0xB1F2cdeC61db658F091671F5f199635aEF202CAC;
    address public constant ren_crv = 0x49849C98ae39Fff122806C06791Fa73784FB3675;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyCurveBase(
            ren_pool,
            ren_gauge,
            ren_crv,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        IERC20(crv).approve(univ2Router2, type(uint256).max);
    }

    // **** Views ****

    function getMostPremium() public view override returns (address, uint256) {
        // Both 8 decimals
        uint256[] memory balances = new uint256[](3);
        balances[0] = ICurveFi_2(curve).balances(0); // RENBTC
        balances[1] = ICurveFi_2(curve).balances(1); // WBTC

        // renBTC
        if (balances[0] < balances[1]) {
            return (renbtc, 0);
        }

        // WBTC
        if (balances[1] < balances[0]) {
            return (wbtc, 1);
        }

        // If they're somehow equal, we just want RENBTC
        return (renbtc, 0);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyCurveRenCrv";
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // stablecoin we want to convert to
        (address to, uint256 toIndex) = getMostPremium();

        // Collects crv tokens
        // Don't bother voting in v1
        ICurveMintr(mintr).mint(gauge);

        uint256 _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            _swapToNeurAndDistributePerformanceFees(crv, sushiRouter);
        }

        _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            // x% is sent back to the rewards holder
            // to be used to lock up in as veCRV in a future date
            uint256 _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);
            if (_keepCRV > 0) {
                IERC20(crv).safeTransfer(
                    IController(controller).treasury(),
                    _keepCRV
                );
            }
            _crv = _crv.sub(_keepCRV);
            _swapUniswap(crv, to, _crv);
        }

        // Adds liquidity to curve.fi's pool
        // to get back want (scrv)
        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            IERC20(to).safeApprove(curve, 0);
            IERC20(to).safeApprove(curve, _to);
            uint256[2] memory liquidity;
            liquidity[toIndex] = _to;
            ICurveFi_2(curve).add_liquidity(liquidity, 0);
        }

        deposit();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./StrategyBase.sol";
import "../interfaces/ICurve.sol";

// Base contract for Curve based staking contract interfaces

abstract contract StrategyCurveBase is StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Curve DAO
    // Pool's gauge => all the interactions are held through this address, ICurveGauge interface
    address public gauge;
    // Curve's contract address => depositing here
    address public curve;
    address public constant mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    // stablecoins
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant susd = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;

    // bitcoins
    address public constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant renbtc = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;

    // rewards
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    // How much CRV tokens to keep
    uint256 public keepCRV = 500;
    uint256 public keepCRVMax = 10000;

    constructor(
        // Curve's contract address => depositing here
        address _curve,
        address _gauge,
        // Token accepted by the contract
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyBase(
            _want,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        curve = _curve;
        gauge = _gauge;
    }

    // **** Getters ****

    function balanceOfPool() public view override returns (uint256) {
        return ICurveGauge(gauge).balanceOf(address(this));
    }

    function getHarvestable() external returns (uint256) {
        return ICurveGauge(gauge).claimable_tokens(address(this));
    }

    function getMostPremium() public view virtual returns (address, uint256);

    // **** Setters ****

    function setKeepCRV(uint256 _keepCRV) external {
        require(msg.sender == governance, "!governance");
        keepCRV = _keepCRV;
    }

    // **** State Mutation functions ****

    function deposit() public override {
        // Checking our contract's wanted/accepted token balance
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(gauge, 0);
            IERC20(want).safeApprove(gauge, _want);
            ICurveGauge(gauge).deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ICurveGauge(gauge).withdraw(_amount);
        return _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/INeuronPool.sol";
import "../interfaces/ICurve.sol";
import "../interfaces/IUniswapRouterV2.sol";
import "../interfaces/IController.sol";

import "./StrategyCurveBase.sol";

contract StrategyCurve3Crv is StrategyCurveBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Curve stuff
    // Pool to deposit to. In this case it's 3CRV, accepting DAI + USDC + USDT
    address public constant three_pool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    // Pool's Gauge - interactions are mediated through ICurveGauge interface @ this address
    address public constant three_gauge = 0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A;

    // Curve 3Crv token contract address.
    // https://etherscan.io/address/0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490
    // Etherscan states this contract manages 3Crv and USDC
    // The starting deposit is made with this token ^^^
    address public constant three_crv = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyCurveBase(
            three_pool,
            three_gauge,
            three_crv,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        IERC20(crv).approve(univ2Router2, type(uint256).max);
    }

    // **** Views ****

    function getMostPremium() public view override returns (address, uint256) {
        uint256[] memory balances = new uint256[](3);
        balances[0] = ICurveFi_3(curve).balances(0); // DAI
        balances[1] = ICurveFi_3(curve).balances(1).mul(10**12); // USDC
        balances[2] = ICurveFi_3(curve).balances(2).mul(10**12); // USDT

        // DAI
        if (balances[0] < balances[1] && balances[0] < balances[2]) {
            return (dai, 0);
        }

        // USDC
        if (balances[1] < balances[0] && balances[1] < balances[2]) {
            return (usdc, 1);
        }

        // USDT
        if (balances[2] < balances[0] && balances[2] < balances[1]) {
            return (usdt, 2);
        }

        // If they're somehow equal, we just want DAI
        return (dai, 0);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyCurve3Crv";
    }

    // **** State Mutations ****
    // Function to harvest pool rewards, convert to stablecoins and reinvest to pool
    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // stablecoin we want to convert to
        (address to, uint256 toIndex) = getMostPremium();

        // Collects Crv tokens
        // Don't bother voting in v1
        // Creates CRV and transfers to strategy's address (?)
        ICurveMintr(mintr).mint(gauge);
        uint256 _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            _swapToNeurAndDistributePerformanceFees(crv, sushiRouter);
        }

        _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            // x% is sent back to the rewards holder
            // to be used to lock up in as veCRV in a future date
            // Some tokens are accumulated in "treasury" and controller. The % is always subject to discussion.
            uint256 _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);
            if (_keepCRV > 0) {
                IERC20(crv).safeTransfer(
                    IController(controller).treasury(),
                    _keepCRV
                );
            }
            _crv = _crv.sub(_keepCRV);
            // Converts CRV to stablecoins
            _swapUniswap(crv, to, _crv);
        }

        // Adds liquidity to curve.fi's pool
        // to get back want (scrv)
        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            IERC20(to).safeApprove(curve, 0);
            IERC20(to).safeApprove(curve, _to);
            uint256[3] memory liquidity;
            liquidity[toIndex] = _to;
            // Transferring stablecoins back to Curve
            ICurveFi_3(curve).add_liquidity(liquidity, 0);
        }

        deposit();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/INeuronPool.sol";
import "../interfaces/ICurve.sol";
import "../interfaces/IUniswapRouterV2.sol";
import "../interfaces/IController.sol";

import "./PolygonStrategyCurveBase.sol";

contract PolygonStrategyCurveRenBtc is PolygonStrategyCurveBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Curve stuff
    // Pool to deposit to. In this case it's renBTC, accepting wBTC + renBTC
    // https://polygon.curve.fi/ren
    address public constant curve_renBTC_pool =
        0xC2d95EEF97Ec6C17551d45e77B590dc1F9117C67;
    // Pool's Gauge - interactions are mediated through ICurveGauge interface @ this address
    address public constant curve_renBTC_gauge =
        0xffbACcE0CC7C19d46132f1258FC16CF6871D153c;
    // Curve.fi amWBTC/renBTC (btcCRV) token contract address.
    // The starting deposit is made with this token ^^^
    address public constant curve_renBTC_lp = 0xf8a57c1d3b9629b77b6726a042ca48990A84Fb49;
    address public constant wbtc = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address public constant renBTC = 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyCurveBase(
            curve_renBTC_pool,
            curve_renBTC_gauge,
            curve_renBTC_lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        IERC20(crv).approve(quickswapRouter, type(uint256).max);
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyCurveRenBtc";
    }

    function getMostPremium() pure public override returns (address, uint256) {
        // Always return wbtc because there is no liquidity for renBTC tokens
        return (wbtc, 0);
    }

    // **** State Mutations ****
    // Function to harvest pool rewards, convert to stablecoins and reinvest to pool
    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // stablecoin we want to convert to
        (address to, uint256 toIndex) = getMostPremium();

        ICurveGauge(gauge).claim_rewards(address(this));

        uint256 _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            _swapToNeurAndDistributePerformanceFees(crv, quickswapRouter);
        }

        uint256 _wmatic = IERC20(wmatic).balanceOf(address(this));

        if (_wmatic > 0) {
            _swapToNeurAndDistributePerformanceFees(wmatic, quickswapRouter);
        }

        _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            IERC20(crv).safeApprove(quickswapRouter, 0);
            IERC20(crv).safeApprove(quickswapRouter, _crv);
            _swapQuickswap(crv, to, _crv);
        }

        _wmatic = IERC20(wmatic).balanceOf(address(this));
        if (_wmatic > 0) {
            IERC20(wmatic).safeApprove(quickswapRouter, 0);
            IERC20(wmatic).safeApprove(quickswapRouter, _wmatic);
            _swapQuickswap(wmatic, to, _wmatic);
        }

        // Adds liquidity to curve.fi's pool
        // to get back want (scrv)
        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            IERC20(to).safeApprove(curve, 0);
            IERC20(to).safeApprove(curve, _to);
            uint256[3] memory liquidity;
            liquidity[toIndex] = _to;
            // Transferring stablecoins back to Curve
            ICurveFi_Polygon_3(curve).add_liquidity(liquidity, 0, true);
        }

        deposit();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./PolygonStrategyBase.sol";
import "../interfaces/ICurve.sol";

// Base contract for Curve based staking contract interfaces

abstract contract PolygonStrategyCurveBase is PolygonStrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Curve DAO
    // Pool's gauge => all the interactions are held through this address, ICurveGauge interface
    address public immutable gauge;
    // Curve's contract address => depositing here
    address public immutable curve;

    // stablecoins
    address public constant dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    // rewards
    address public constant crv = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;

    // How much CRV tokens to keep
    uint256 public keepCRV = 500;
    uint256 public keepCRVMax = 10000;

    constructor(
        address _curve,
        address _gauge,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyBase(
            _want,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        curve = _curve;
        gauge = _gauge;
    }

    // **** Getters ****

    function balanceOfPool() public view override returns (uint256) {
        return ICurveGauge(gauge).balanceOf(address(this));
    }

    function getHarvestable() external returns (uint256) {
        return ICurveGauge(gauge).claimable_tokens(address(this));
    }

    function getMostPremium() public view virtual returns (address, uint256);

    // **** Setters ****

    function setKeepCRV(uint256 _keepCRV) external {
        require(msg.sender == governance, "!governance");
        keepCRV = _keepCRV;
    }

    // **** State Mutation functions ****

    function deposit() public override {
        // Checking our contract's wanted/accepted token balance
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(gauge, 0);
            IERC20(want).safeApprove(gauge, _want);
            ICurveGauge(gauge).deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ICurveGauge(gauge).withdraw(_amount);
        return _amount;
    }
}

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/INeuronPool.sol";
import "../interfaces/IStakingRewards.sol";
import "../interfaces/IUniswapRouterV2.sol";
import "../interfaces/IController.sol";

// Strategy Contract Basics

abstract contract PolygonStrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Perfomance fees - start with 30%
    uint256 public performanceTreasuryFee = 3000;
    uint256 public constant performanceTreasuryMax = 10000;

    // Withdrawal fee 0%
    // - 0% to treasury
    // - 0% to dev fund
    uint256 public withdrawalTreasuryFee = 0;
    uint256 public constant withdrawalTreasuryMax = 100000;

    uint256 public withdrawalDevFundFee = 0;
    uint256 public constant withdrawalDevFundMax = 100000;

    // Tokens
    // Input token accepted by the contract
    address public immutable neuronTokenAddress;
    address public immutable want;
    address public constant weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address public constant wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    // User accounts
    address public governance;
    address public controller;
    address public strategist;
    address public timelock;

    // Dex - quickswap
    address public quickswapRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address public sushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    mapping(address => bool) public harvesters;

    constructor(
        // Input token accepted by the contract
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    ) {
        require(_want != address(0));
        require(_governance != address(0));
        require(_strategist != address(0));
        require(_controller != address(0));
        require(_neuronTokenAddress != address(0));
        require(_timelock != address(0));

        want = _want;
        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        neuronTokenAddress = _neuronTokenAddress;
        timelock = _timelock;
    }

    // **** Modifiers **** //

    modifier onlyBenevolent() {
        require(
            harvesters[msg.sender] ||
                msg.sender == governance ||
                msg.sender == strategist
        );
        _;
    }

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view virtual returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function getName() external pure virtual returns (string memory);

    // **** Setters **** //

    function whitelistHarvester(address _harvester) external {
        require(
            msg.sender == governance || msg.sender == strategist,
            "not authorized"
        );
        harvesters[_harvester] = true;
    }

    function revokeHarvester(address _harvester) external {
        require(
            msg.sender == governance || msg.sender == strategist,
            "not authorized"
        );
        harvesters[_harvester] = false;
    }

    function setWithdrawalDevFundFee(uint256 _withdrawalDevFundFee) external {
        require(msg.sender == timelock, "!timelock");
        withdrawalDevFundFee = _withdrawalDevFundFee;
    }

    function setWithdrawalTreasuryFee(uint256 _withdrawalTreasuryFee) external {
        require(msg.sender == timelock, "!timelock");
        withdrawalTreasuryFee = _withdrawalTreasuryFee;
    }

    function setPerformanceTreasuryFee(uint256 _performanceTreasuryFee)
        external
    {
        require(msg.sender == timelock, "!timelock");
        performanceTreasuryFee = _performanceTreasuryFee;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) external {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setController(address _controller) external {
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Withdraw partial funds, normally used with a pool withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        uint256 _feeDev = _amount.mul(withdrawalDevFundFee).div(
            withdrawalDevFundMax
        );
        IERC20(want).safeTransfer(IController(controller).devfund(), _feeDev);

        uint256 _feeTreasury = _amount.mul(withdrawalTreasuryFee).div(
            withdrawalTreasuryMax
        );
        IERC20(want).safeTransfer(
            IController(controller).treasury(),
            _feeTreasury
        );

        address _nPool = IController(controller).nPools(address(want));
        require(_nPool != address(0), "!nPool"); // additional protection so we don't burn the funds

        IERC20(want).safeTransfer(
            _nPool,
            _amount.sub(_feeDev).sub(_feeTreasury)
        );
    }

    // Withdraw funds, used to swap between strategies
    function withdrawForSwap(uint256 _amount)
        external
        returns (uint256 balance)
    {
        require(msg.sender == controller, "!controller");
        _withdrawSome(_amount);

        balance = IERC20(want).balanceOf(address(this));

        address _nPool = IController(controller).nPools(address(want));
        require(_nPool != address(0), "!nPool");
        IERC20(want).safeTransfer(_nPool, balance);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        address _nPool = IController(controller).nPools(address(want));
        require(_nPool != address(0), "!nPool"); // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_nPool, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    function harvest() public virtual;

    // **** Emergency functions ****

    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes memory response)
    {
        require(msg.sender == timelock, "!timelock");
        require(_target != address(0), "!target");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    // **** Internal functions ****
    function _swapQuickswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        IUniswapRouterV2(quickswapRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }

    function _swapQuickswapWithPath(address[] memory path, uint256 _amount)
        internal
    {
        require(path[1] != address(0));

        IUniswapRouterV2(quickswapRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }

    function _swapSushiswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        IUniswapRouterV2(sushiRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }

    function _swapSushiswapWithPath(address[] memory path, uint256 _amount)
        internal
    {
        require(path[1] != address(0));

        IUniswapRouterV2(sushiRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }

    function _swapWithUniLikeRouter(
        address routerAddress,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        require(_to != address(0));
        require(
            routerAddress != address(0),
            "_swapWithUniLikeRouter routerAddress cant be zero"
        );

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        try
            IUniswapRouterV2(routerAddress).swapExactTokensForTokens(
                _amount,
                0,
                path,
                address(this),
                block.timestamp.add(60)
            )
        {
            return true;
        } catch {
            return false;
        }
    }

    function _swapToNeurAndDistributePerformanceFees(
        address swapToken,
        address swapRouterAddress
    ) internal {
        uint256 swapTokenBalance = IERC20(swapToken).balanceOf(address(this));

        if (swapTokenBalance > 0 && performanceTreasuryFee > 0) {
            uint256 performanceTreasuryFeeAmount = swapTokenBalance
                .mul(performanceTreasuryFee)
                .div(performanceTreasuryMax);
            uint256 totalFeeAmout = performanceTreasuryFeeAmount;

            _swapAmountToNeurAndDistributePerformanceFees(
                swapToken,
                totalFeeAmout,
                swapRouterAddress
            );
        }
    }

    function _swapAmountToNeurAndDistributePerformanceFees(
        address swapToken,
        uint256 amount,
        address swapRouterAddress
    ) internal {
        uint256 swapTokenBalance = IERC20(swapToken).balanceOf(address(this));

        require(
            swapTokenBalance >= amount,
            "Amount is bigger than token balance"
        );

        IERC20(swapToken).safeApprove(swapRouterAddress, 0);
        IERC20(weth).safeApprove(swapRouterAddress, 0);
        IERC20(swapToken).safeApprove(swapRouterAddress, amount);
        IERC20(weth).safeApprove(swapRouterAddress, type(uint256).max);
        bool isSuccesfullSwap = _swapWithUniLikeRouter(
            swapRouterAddress,
            swapToken,
            neuronTokenAddress,
            amount
        );

        if (isSuccesfullSwap) {
            uint256 neuronTokenBalance = IERC20(neuronTokenAddress).balanceOf(
                address(this)
            );

            if (neuronTokenBalance > 0) {
                // Treasury fees
                // Sending strategy's tokens to treasury. Initially @ 30% (set by performanceTreasuryFee constant) of strategy's assets
                IERC20(neuronTokenAddress).safeTransfer(
                    IController(controller).treasury(),
                    neuronTokenBalance
                );
            }
        } else {
            // If failed swap to Neuron just transfer swap token to treasury
            IERC20(swapToken).safeApprove(
                IController(controller).treasury(),
                0
            );
            IERC20(swapToken).safeApprove(
                IController(controller).treasury(),
                amount
            );
            IERC20(swapToken).safeTransfer(
                IController(controller).treasury(),
                amount
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PolygonStrategyBase.sol";
import "../interfaces/IPolygonSushiMiniChef.sol";
import "../interfaces/IPolygonSushiRewarder.sol";

abstract contract PolygonStrategySushiDoubleRewardBase is PolygonStrategyBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Token addresses
    address public constant sushi = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;
    address public constant rewardToken = wmatic;

    address public constant sushiMiniChef =
        0x0769fd68dFb93167989C6f7254cd0D766Fb2841F;

    uint256 public immutable poolId;
    address public immutable token0;
    address public immutable token1;

    // How much Reward tokens to keep
    uint256 public keepRewardToken = 500;
    uint256 public keepRewardTokenMax = 10000;

    constructor(
        address _token0,
        address _token1,
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyBase(
            _lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        poolId = _poolId;
        token0 = _token0;
        token1 = _token1;
    }

    function setKeepRewardToken(uint256 _keepRewardToken) external {
        require(msg.sender == governance, "!governance");
        keepRewardToken = _keepRewardToken;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IPolygonSushiMiniChef(sushiMiniChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256, uint256) {
        uint256 _pendingSushi = IPolygonSushiMiniChef(sushiMiniChef)
            .pendingSushi(poolId, address(this));
        IPolygonSushiRewarder rewarder = IPolygonSushiRewarder(
            IPolygonSushiMiniChef(sushiMiniChef).rewarder(poolId)
        );
        (, uint256[] memory _rewardAmounts) = rewarder.pendingTokens(
            poolId,
            address(this),
            0
        );

        uint256 _pendingRewardToken;
        if (_rewardAmounts.length > 0) {
            _pendingRewardToken = _rewardAmounts[0];
        }
        return (_pendingSushi, _pendingRewardToken);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(sushiMiniChef, 0);
            IERC20(want).safeApprove(sushiMiniChef, _want);
            IPolygonSushiMiniChef(sushiMiniChef).deposit(
                poolId,
                _want,
                address(this)
            );
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IPolygonSushiMiniChef(sushiMiniChef).withdraw(
            poolId,
            _amount,
            address(this)
        );
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Sushi and Reward tokens
        IPolygonSushiMiniChef(sushiMiniChef).harvest(poolId, address(this));

        uint256 _rewardToken = IERC20(rewardToken).balanceOf(address(this));
        uint256 _sushi = IERC20(sushi).balanceOf(address(this));

        if (_rewardToken > 0) {
            _swapToNeurAndDistributePerformanceFees(rewardToken, sushiRouter);
            uint256 _keepRewardToken = _rewardToken.mul(keepRewardToken).div(
                keepRewardTokenMax
            );
            if (_keepRewardToken > 0) {
                IERC20(rewardToken).safeTransfer(
                    IController(controller).treasury(),
                    _keepRewardToken
                );
            }
            _rewardToken = IERC20(rewardToken).balanceOf(address(this));
        }

        if (_sushi > 0) {
            _swapToNeurAndDistributePerformanceFees(sushi, sushiRouter);
            _sushi = IERC20(sushi).balanceOf(address(this));
        }

        if (_rewardToken > 0) {
            IERC20(rewardToken).safeApprove(sushiRouter, 0);
            IERC20(rewardToken).safeApprove(sushiRouter, _rewardToken);
            _swapSushiswap(rewardToken, weth, _rewardToken);
        }

        if (_sushi > 0) {
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _sushi);
        }

        // Swap half WETH for token0
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0 && token0 != weth) {
            _swapSushiswap(weth, token0, _weth.div(2));
        }

        // Swap half WETH for token1
        if (_weth > 0 && token1 != weth) {
            _swapSushiswap(weth, token1, _weth.div(2));
        }

        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            IERC20(token0).safeApprove(sushiRouter, 0);
            IERC20(token0).safeApprove(sushiRouter, _token0);
            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            IUniswapRouterV2(sushiRouter).addLiquidity(
                token0,
                token1,
                _token0,
                _token1,
                0,
                0,
                address(this),
                block.timestamp + 60
            );

            // Donates DUST
            IERC20(token0).transfer(
                IController(controller).treasury(),
                IERC20(token0).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        deposit();
    }
}

pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

interface IPolygonSushiMiniChef {
    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(
        uint256 indexed pid,
        uint256 allocPoint,
        address indexed lpToken,
        address indexed rewarder
    );
    event LogSetPool(
        uint256 indexed pid,
        uint256 allocPoint,
        address indexed rewarder,
        bool overwrite
    );
    event LogSushiPerSecond(uint256 sushiPerSecond);
    event LogUpdatePool(
        uint256 indexed pid,
        uint64 lastRewardTime,
        uint256 lpSupply,
        uint256 accSushiPerShare
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );

    function SUSHI() external view returns (address);

    function add(
        uint256 allocPoint,
        address _lpToken,
        address _rewarder
    ) external;

    function batch(bytes[] memory calls, bool revertOnFail)
        external
        payable
        returns (bool[] memory successes, bytes[] memory results);

    function claimOwnership() external;

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function emergencyWithdraw(uint256 pid, address to) external;

    function harvest(uint256 pid, address to) external;

    function lpToken(uint256) external view returns (address);

    function massUpdatePools(uint256[] memory pids) external;

    function migrate(uint256 _pid) external;

    function migrator() external view returns (address);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending);

    function permitToken(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function poolInfo(uint256)
        external
        view
        returns (
            uint128 accSushiPerShare,
            uint64 lastRewardTime,
            uint64 allocPoint
        );

    function poolLength() external view returns (uint256 pools);

    function rewarder(uint256) external view returns (address);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        address _rewarder,
        bool overwrite
    ) external;

    function setMigrator(address _migrator) external;

    function setSushiPerSecond(uint256 _sushiPerSecond) external;

    function sushiPerSecond() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function updatePool(uint256 pid)
        external
        returns (MiniChefV2.PoolInfo memory pool);

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, int256 rewardDebt);

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) external;
}

interface MiniChefV2 {
    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }
}

pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

interface IPolygonSushiRewarder {
    event LogInit();
    event LogOnReward(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        address indexed to
    );
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint);
    event LogRewardPerSecond(uint256 rewardPerSecond);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(
        uint256 indexed pid,
        uint64 lastRewardTime,
        uint256 lpSupply,
        uint256 accSushiPerShare
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function add(uint256 allocPoint, uint256 _pid) external;

    function claimOwnership() external;

    function massUpdatePools(uint256[] memory pids) external;

    function onSushiReward(
        uint256 pid,
        address _user,
        address to,
        uint256,
        uint256 lpToken
    ) external;

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingToken(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending);

    function pendingTokens(
        uint256 pid,
        address user,
        uint256
    )
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory rewardAmounts);

    function poolIds(uint256) external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            uint128 accSushiPerShare,
            uint64 lastRewardTime,
            uint64 allocPoint
        );

    function poolLength() external view returns (uint256 pools);

    function rewardPerSecond() external view returns (uint256);

    function set(uint256 _pid, uint256 _allocPoint) external;

    function setRewardPerSecond(uint256 _rewardPerSecond) external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function updatePool(uint256 pid)
        external
        returns (ComplexRewarderTime.PoolInfo memory pool);

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);
}

interface ComplexRewarderTime {
    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PolygonStrategyBase.sol";
import "../interfaces/IPolygonSushiMiniChef.sol";
import "../interfaces/IPolygonSushiRewarder.sol";
import "./PolygonStrategyStakingRewardsBase.sol";

abstract contract PolygonStrategyQuickswapBase is
    PolygonStrategyStakingRewardsBase
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Token addresses
    address public constant quick = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address public constant rewardToken = quick;


    address public token0;
    address public token1;

    // How much Reward tokens to keep
    uint256 public keepRewardToken = 0;
    uint256 public keepRewardTokenMax = 10000;

    constructor(
        address _token0,
        address _token1,
        address _staking_rewards,
        address _lp_token,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyStakingRewardsBase(
            _staking_rewards,
            _lp_token,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        token0 = _token0;
        token1 = _token1;

        IERC20(token0).approve(quickswapRouter, type(uint256).max);
        IERC20(token1).approve(quickswapRouter, type(uint256).max);
    }

    function setKeepRewardToken(uint256 _keepRewardToken) external {
        require(msg.sender == governance, "!governance");
        keepRewardToken = _keepRewardToken;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Quick tokens
        IStakingRewards(rewards).getReward();

        uint256 _rewardToken = IERC20(rewardToken).balanceOf(address(this));

        if (_rewardToken > 0 && performanceTreasuryFee > 0) {
            _swapToNeurAndDistributePerformanceFees(rewardToken, quickswapRouter);
            uint256 _keepRewardToken = _rewardToken.mul(keepRewardToken).div(
                keepRewardTokenMax
            );
            if (_keepRewardToken > 0) {
                IERC20(rewardToken).safeTransfer(
                    IController(controller).treasury(),
                    _keepRewardToken
                );
            }
            _rewardToken = IERC20(rewardToken).balanceOf(address(this));
        }

        if (_rewardToken > 0) {
            IERC20(rewardToken).safeApprove(sushiRouter, 0);
            IERC20(rewardToken).safeApprove(sushiRouter, _rewardToken);
            _swapQuickswap(rewardToken, weth, _rewardToken);
        }

        // Swap half WETH for token0
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0 && token0 != weth) {
            _swapQuickswap(weth, token0, _weth.div(2));
        }

        // Swap half WETH for token1
        if (_weth > 0 && token1 != weth) {
            _swapQuickswap(weth, token1, _weth.div(2));
        }

        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            IERC20(token0).safeApprove(quickswapRouter, 0);
            IERC20(token0).safeApprove(quickswapRouter, _token0);
            IERC20(token1).safeApprove(quickswapRouter, 0);
            IERC20(token1).safeApprove(quickswapRouter, _token1);

            IUniswapRouterV2(quickswapRouter).addLiquidity(
                token0,
                token1,
                _token0,
                _token1,
                0,
                0,
                address(this),
                block.timestamp + 60
            );

            // Donates DUST
            IERC20(token0).transfer(
                IController(controller).treasury(),
                IERC20(token0).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        deposit();
    }
}

pragma solidity 0.8.2;

import "./PolygonStrategyBase.sol";

abstract contract PolygonStrategyStakingRewardsBase is PolygonStrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public rewards;

    // **** Getters ****
    constructor(
        address _rewards,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyBase(
            _want,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        rewards = _rewards;
    }

    function balanceOfPool() public view override returns (uint256) {
        return IStakingRewards(rewards).balanceOf(address(this));
    }

    function getHarvestable() external view returns (uint256) {
        return IStakingRewards(rewards).earned(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).safeApprove(rewards, _want);
            IStakingRewards(rewards).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStakingRewards(rewards).withdraw(_amount);
        return _amount;
    }
}

pragma solidity 0.8.2;

import {PolygonStrategyQuickswapBase} from "./PolygonStrategyQuickswapBase.sol";

contract PolygonStrategyQuickswapWmaticEthLp is PolygonStrategyQuickswapBase {
    address public constant wmaticEthLpToken =
        0xadbF1854e5883eB8aa7BAf50705338739e558E5b;
    address public constant wmaticEthRewards =
        0x8FF56b5325446aAe6EfBf006a4C1D88e4935a914;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyQuickswapBase(
            wmatic,
            weth,
            wmaticEthRewards,
            wmaticEthLpToken,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyQuickswapWmaticEthLp";
    }
}

pragma solidity 0.8.2;

import {PolygonStrategyQuickswapBase} from "./PolygonStrategyQuickswapBase.sol";

contract PolygonStrategyQuickswapWbtcEthLp is PolygonStrategyQuickswapBase {
    // token0
    address public constant wbtc = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address public constant wbtcWethLpToken =
        0xdC9232E2Df177d7a12FdFf6EcBAb114E2231198D;

    address public constant wbtcWethRewards =
        0x070D182EB7E9C3972664C959CE58C5fC6219A7ad;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyQuickswapBase(
            wbtc,
            weth,
            wbtcWethRewards,
            wbtcWethLpToken,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyQuickswapWbtcEthLp";
    }
}

pragma solidity 0.8.2;

import {PolygonStrategyQuickswapBase} from "./PolygonStrategyQuickswapBase.sol";

contract PolygonStrategyQuickswapUsdcUsdtLp is PolygonStrategyQuickswapBase {
    // token0
    address public constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    // token1
    address public constant usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public constant usdcUsdtLpToken =
        0x2cF7252e74036d1Da831d11089D326296e64a728;
    address public constant usdcUsdtRewards =
        0x251d9837a13F38F3Fe629ce2304fa00710176222;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyQuickswapBase(
            usdc,
            usdt,
            usdcUsdtRewards,
            usdcUsdtLpToken,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyQuickswapUsdcUsdtLp";
    }
}

pragma solidity 0.8.2;

import {PolygonStrategyQuickswapBase} from "./PolygonStrategyQuickswapBase.sol";

contract PolygonStrategyQuickswapMimaticUsdcLp is PolygonStrategyQuickswapBase {
    // token0
    address public constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    // token1
    address public constant miMatic =
        0xa3Fa99A148fA48D14Ed51d610c367C61876997F1;
    address public constant miMaticUsdcLpToken =
        0x160532D2536175d65C03B97b0630A9802c274daD;
    address public constant miMaticUsdcRewards =
        0x1fdDd7F3A4c1f0e7494aa8B637B8003a64fdE21A;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyQuickswapBase(
            usdc,
            miMatic,
            miMaticUsdcRewards,
            miMaticUsdcLpToken,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyQuickswapMimaticUsdcLp";
    }
}

pragma solidity 0.8.2;

import {PolygonStrategyQuickswapBase} from "./PolygonStrategyQuickswapBase.sol";

contract PolygonStrategyQuickswapDaiUsdtLp is PolygonStrategyQuickswapBase {
    // token0
    address public constant dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    // token1
    address public constant usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public constant daiUsdtLpToken =
        0x59153f27eeFE07E5eCE4f9304EBBa1DA6F53CA88;
    address public constant daiUsdtRewards =
        0x97Efe8470727FeE250D7158e6f8F63bb4327c8A2;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyQuickswapBase(
            usdt,
            dai,
            daiUsdtRewards,
            daiUsdtLpToken,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyQuickswapDaiUsdtLp";
    }
}

pragma solidity 0.8.2;

import {PolygonStrategyQuickswapBase} from "./PolygonStrategyQuickswapBase.sol";

contract PolygonStrategyQuickswapDaiUsdcLp is PolygonStrategyQuickswapBase {
    // token0
    address public constant dai =0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    // token1
    address public constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant daiUsdcLpToken =
        0xf04adBF75cDFc5eD26eeA4bbbb991DB002036Bdd;
    address public constant daiUsdcRewards =
        0xEd8413eCEC87c3d4664975743c02DB3b574012a7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyQuickswapBase(
            usdc,
            dai,
            daiUsdcRewards,
            daiUsdcLpToken,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyQuickswapDaiUsdcLp";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./StrategyBase.sol";
import "../interfaces/ISushiMasterchefV2.sol";
import "../interfaces/ISushiRewarder.sol";

abstract contract StrategySushiEthFarmDoubleRewardBase is StrategyBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Token addresses
    address public constant sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public immutable rewardToken;

    address public constant sushiMasterChef =
        0xEF0881eC094552b2e128Cf945EF17a6752B4Ec5d;

    uint256 public poolId;

    // How much Reward tokens to keep
    uint256 public keepRewardToken = 500;
    uint256 public keepRewardTokenMax = 10000;

    constructor(
        uint256 _poolId,
        address _lp,
        address _rewardToken,
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategyBase(
            _lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        poolId = _poolId;
        rewardToken = _rewardToken;
    }

    function setKeepRewardToken(uint256 _keepRewardToken) external {
        require(msg.sender == governance, "!governance");
        keepRewardToken = _keepRewardToken;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = ISushiMasterchefV2(sushiMasterChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestableSushi() public view returns (uint256) {
        return
            ISushiMasterchefV2(sushiMasterChef).pendingSushi(
                poolId,
                address(this)
            );
    }

    function getHarvestableRewardToken() public view returns (uint256) {
        address rewarder = ISushiMasterchefV2(sushiMasterChef).rewarder(poolId);
        return ISushiRewarder(rewarder).pendingToken(poolId, address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(sushiMasterChef, 0);
            IERC20(want).safeApprove(sushiMasterChef, _want);
            ISushiMasterchefV2(sushiMasterChef).deposit(
                poolId,
                _want,
                address(this)
            );
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        ISushiMasterchefV2(sushiMasterChef).withdraw(
            poolId,
            _amount,
            address(this)
        );
        return _amount;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Sushi and Reward tokens
        ISushiMasterchefV2(sushiMasterChef).harvest(poolId, address(this));

        uint256 _rewardToken = IERC20(rewardToken).balanceOf(address(this));
        uint256 _sushi = IERC20(sushi).balanceOf(address(this));

        if (_rewardToken > 0) {
            _swapToNeurAndDistributePerformanceFees(rewardToken, sushiRouter);
            uint256 _keepRewardToken = _rewardToken.mul(keepRewardToken).div(
                keepRewardTokenMax
            );
            if (_keepRewardToken > 0) {
                IERC20(rewardToken).safeTransfer(
                    IController(controller).treasury(),
                    _keepRewardToken
                );
            }
            _rewardToken = IERC20(rewardToken).balanceOf(address(this));
        }

        if (_sushi > 0) {
            _swapToNeurAndDistributePerformanceFees(sushi, sushiRouter);
            _sushi = IERC20(sushi).balanceOf(address(this));
        }

        if (_rewardToken > 0) {
            uint256 _amount = _rewardToken.div(2);
            IERC20(rewardToken).safeApprove(sushiRouter, 0);
            IERC20(rewardToken).safeApprove(sushiRouter, _amount);
            _swapSushiswap(rewardToken, weth, _amount);
        }

        if (_sushi > 0) {
            uint256 _amount = _sushi.div(2);
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _amount);
            _swapSushiswap(sushi, rewardToken, _amount);
        }

        // Adds in liquidity for WETH/rewardToken
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        _rewardToken = IERC20(rewardToken).balanceOf(address(this));

        if (_weth > 0 && _rewardToken > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(rewardToken).safeApprove(sushiRouter, 0);
            IERC20(rewardToken).safeApprove(sushiRouter, _rewardToken);

            IUniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                rewardToken,
                _weth,
                _rewardToken,
                0,
                0,
                address(this),
                block.timestamp + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(rewardToken).safeTransfer(
                IController(controller).treasury(),
                IERC20(rewardToken).balanceOf(address(this))
            );
        }

        deposit();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

// interface for Sushiswap MasterChef contract
interface ISushiMasterchefV2 {
    function MASTER_PID() external view returns (uint256);

    function MASTER_CHEF() external view returns (address);

    function rewarder(uint256 pid) external view returns (address);

    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder
    ) external;

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function sushiPerBlock() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            uint256 lastRewardBlock,
            uint256 accsushiPerShare,
            uint256 allocPoint
        );

    function poolLength() external view returns (uint256);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        address _rewarder,
        bool overwrite
    ) external;

    function harvestFromMasterChef() external;

    function harvest(uint256 pid, address to) external;

    function totalAllocPoint() external view returns (uint256);

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    function withdrawAndHarvest(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

// interface for Sushiswap MasterChef contract
interface ISushiRewarder {
    function pendingToken(uint256 pid, address user)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiEthFarmDoubleRewardBase.sol";

contract StrategySushiDoubleEthRulerLp is StrategySushiEthFarmDoubleRewardBase {
    uint256 public constant sushi_ruler_poolId = 7;

    address public constant sushi_eth_ruler_lp =
        0xb1EECFea192907fC4bF9c4CE99aC07186075FC51;
    address public constant ruler = 0x2aECCB42482cc64E087b6D2e5Da39f5A7A7001f8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiEthFarmDoubleRewardBase(
            sushi_ruler_poolId,
            sushi_eth_ruler_lp,
            ruler,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiDoubleEthRulerLp";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiEthFarmDoubleRewardBase.sol";

contract StrategySushiDoubleEthPickleLp is StrategySushiEthFarmDoubleRewardBase {
    uint256 public constant sushi_pickle_poolId = 3;

    address public constant sushi_eth_pickle_lp =
        0x269Db91Fc3c7fCC275C2E6f22e5552504512811c;
    address public constant pickle = 0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiEthFarmDoubleRewardBase(
            sushi_pickle_poolId,
            sushi_eth_pickle_lp,
            pickle,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiDoubleEthPickleLp";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiEthFarmDoubleRewardBase.sol";

contract StrategySushiDoubleEthCvxLp is StrategySushiEthFarmDoubleRewardBase {
    uint256 public constant sushi_cvx_poolId = 1;

    address public constant sushi_eth_cvx_lp =
        0x05767d9EF41dC40689678fFca0608878fb3dE906;
    address public constant cvx = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiEthFarmDoubleRewardBase(
            sushi_cvx_poolId,
            sushi_eth_cvx_lp,
            cvx,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiDoubleEthCvxLp";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiEthFarmDoubleRewardBase.sol";

contract StrategySushiDoubleEthAlcxLp is StrategySushiEthFarmDoubleRewardBase {
    uint256 public constant sushi_alcx_poolId = 0;

    address public constant sushi_eth_alcx_lp =
        0xC3f279090a47e80990Fe3a9c30d24Cb117EF91a8;
    address public constant alcx = 0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiEthFarmDoubleRewardBase(
            sushi_alcx_poolId,
            sushi_eth_alcx_lp,
            alcx,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiDoubleEthAlcxLp";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PolygonStrategySushiDoubleRewardBase.sol";

contract PolygonStrategySushiDoubleDaiPickleLp is PolygonStrategyBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Token addresses
    address public constant sushi = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;
    address public constant rewardToken = wmatic;

    address public constant sushiMiniChef =
        0x0769fd68dFb93167989C6f7254cd0D766Fb2841F;

    // How much Reward tokens to keep
    uint256 public keepRewardToken = 500;
    uint256 public keepRewardTokenMax = 10000;

    address public constant sushi_dai_pickle_lp =
        0x57602582eB5e82a197baE4E8b6B80E39abFC94EB;
    uint256 public constant sushi_dai_pickle_poolId = 37;
    // Token0
    address public constant pickle_token =
        0x2b88aD57897A8b496595925F43048301C37615Da;
    // Token1
    address public constant dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant token0 = pickle_token;
    address public constant token1 = dai;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyBase(
            sushi_dai_pickle_lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "PolygonStrategySushiDoubleDaiPickleLp";
    }

    function setKeepRewardToken(uint256 _keepRewardToken) external {
        require(msg.sender == governance, "!governance");
        keepRewardToken = _keepRewardToken;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IPolygonSushiMiniChef(sushiMiniChef).userInfo(
            sushi_dai_pickle_poolId,
            address(this)
        );
        return amount;
    }

    function getHarvestable() external view returns (uint256, uint256) {
        uint256 _pendingSushi = IPolygonSushiMiniChef(sushiMiniChef)
            .pendingSushi(sushi_dai_pickle_poolId, address(this));
        IPolygonSushiRewarder rewarder = IPolygonSushiRewarder(
            IPolygonSushiMiniChef(sushiMiniChef).rewarder(
                sushi_dai_pickle_poolId
            )
        );
        (, uint256[] memory _rewardAmounts) = rewarder.pendingTokens(
            sushi_dai_pickle_poolId,
            address(this),
            0
        );

        uint256 _pendingRewardToken;
        if (_rewardAmounts.length > 0) {
            _pendingRewardToken = _rewardAmounts[0];
        }
        return (_pendingSushi, _pendingRewardToken);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(sushiMiniChef, 0);
            IERC20(want).safeApprove(sushiMiniChef, _want);
            IPolygonSushiMiniChef(sushiMiniChef).deposit(
                sushi_dai_pickle_poolId,
                _want,
                address(this)
            );
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IPolygonSushiMiniChef(sushiMiniChef).withdraw(
            sushi_dai_pickle_poolId,
            _amount,
            address(this)
        );
        return _amount;
    }

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Sushi and Reward tokens
        IPolygonSushiMiniChef(sushiMiniChef).harvest(
            sushi_dai_pickle_poolId,
            address(this)
        );

        uint256 _rewardToken = IERC20(rewardToken).balanceOf(address(this));
        uint256 _sushi = IERC20(sushi).balanceOf(address(this));

        if (_rewardToken > 0) {
            _swapToNeurAndDistributePerformanceFees(rewardToken, sushiRouter);
            uint256 _keepRewardToken = _rewardToken.mul(keepRewardToken).div(
                keepRewardTokenMax
            );
            if (_keepRewardToken > 0) {
                IERC20(rewardToken).safeTransfer(
                    IController(controller).treasury(),
                    _keepRewardToken
                );
            }
            _rewardToken = IERC20(rewardToken).balanceOf(address(this));
        }

        if (_sushi > 0) {
            _swapToNeurAndDistributePerformanceFees(sushi, sushiRouter);
            _sushi = IERC20(sushi).balanceOf(address(this));
        }

        if (_rewardToken > 0) {
            IERC20(rewardToken).safeApprove(sushiRouter, 0);
            IERC20(rewardToken).safeApprove(sushiRouter, _rewardToken);
            _swapSushiswap(rewardToken, weth, _rewardToken);
        }

        if (_sushi > 0) {
            IERC20(sushi).safeApprove(sushiRouter, 0);
            IERC20(sushi).safeApprove(sushiRouter, _sushi);

            _swapSushiswap(sushi, weth, _sushi);
        }

        // Swap all WETH for DAI first
        uint256 _weth = IERC20(weth).balanceOf(address(this));

        if (_weth > 0) {
            _swapSushiswap(weth, dai, _weth);
        }

        uint256 _dai = IERC20(dai).balanceOf(address(this));
        // Swap half DAI for pickle
        if (_dai > 0) {
            IERC20(dai).safeApprove(sushiRouter, 0);
            IERC20(dai).safeApprove(sushiRouter, _dai.div(2));
            _swapSushiswap(dai, pickle_token, _dai.div(2));
        }

        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_token0 > 0 && _token1 > 0) {
            IERC20(token0).safeApprove(sushiRouter, 0);
            IERC20(token0).safeApprove(sushiRouter, _token0);
            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            IUniswapRouterV2(sushiRouter).addLiquidity(
                token0,
                token1,
                _token0,
                _token1,
                0,
                0,
                address(this),
                block.timestamp + 60
            );

            // Donates DUST
            IERC20(token0).transfer(
                IController(controller).treasury(),
                IERC20(token0).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        deposit();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/INeuronPool.sol";
import "../interfaces/ICurve.sol";
import "../interfaces/IUniswapRouterV2.sol";
import "../interfaces/IController.sol";

import "./PolygonStrategyCurveBase.sol";

contract PolygonStrategyCurveAm3Crv is PolygonStrategyCurveBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Curve stuff
    // Pool to deposit to. In this case it's 3CRV, accepting DAI + USDC + USDT
    address public three_pool = 0x445FE580eF8d70FF569aB36e80c647af338db351;
    // Pool's Gauge - interactions are mediated through ICurveGauge interface @ this address
    address public three_gauge = 0x19793B454D3AfC7b454F206Ffe95aDE26cA6912c;
    // Curve 3Crv token contract address.
    // https://etherscan.io/address/0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490
    // Etherscan states this contract manages 3Crv and USDC
    // The starting deposit is made with this token ^^^
    address public three_crv = 0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        PolygonStrategyCurveBase(
            three_pool,
            three_gauge,
            three_crv,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {
        IERC20(crv).approve(quickswapRouter, type(uint256).max);
    }

    // **** Views ****

    function getMostPremium() public view override returns (address, uint256) {
        uint256[] memory balances = new uint256[](3);
        balances[0] = ICurveFi_Polygon_3(curve).balances(0); // DAI
        balances[1] = ICurveFi_Polygon_3(curve).balances(1).mul(10**12); // USDC
        balances[2] = ICurveFi_Polygon_3(curve).balances(2).mul(10**12); // USDT

        // DAI
        if (balances[0] < balances[1] && balances[0] < balances[2]) {
            return (dai, 0);
        }

        // USDC
        if (balances[1] < balances[0] && balances[1] < balances[2]) {
            return (usdc, 1);
        }

        // USDT
        if (balances[2] < balances[0] && balances[2] < balances[1]) {
            return (usdt, 2);
        }

        // If they're somehow equal, we just want DAI
        return (dai, 0);
    }

    function getName() external pure override returns (string memory) {
        return "PolygonStrategyCurveAm3Crv";
    }

    // **** State Mutations ****
    // Function to harvest pool rewards, convert to stablecoins and reinvest to pool
    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        // if so, a new strategy will be deployed.

        // stablecoin we want to convert to
        (address to, uint256 toIndex) = getMostPremium();

        ICurveGauge(gauge).claim_rewards(address(this));

        uint256 _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            _swapToNeurAndDistributePerformanceFees(crv, quickswapRouter);
        }

        uint256 _wmatic = IERC20(wmatic).balanceOf(address(this));

        if (_wmatic > 0) {
            _swapToNeurAndDistributePerformanceFees(wmatic, quickswapRouter);
        }

        _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            IERC20(crv).safeApprove(quickswapRouter, 0);
            IERC20(crv).safeApprove(quickswapRouter, _crv);
            _swapQuickswap(crv, to, _crv);
        }

        _wmatic = IERC20(wmatic).balanceOf(address(this));
        if (_wmatic > 0) {
            IERC20(wmatic).safeApprove(quickswapRouter, 0);
            IERC20(wmatic).safeApprove(quickswapRouter, _wmatic);
            _swapQuickswap(wmatic, to, _wmatic);
        }

        // Adds liquidity to curve.fi's pool
        // to get back want (scrv)
        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            IERC20(to).safeApprove(curve, 0);
            IERC20(to).safeApprove(curve, _to);
            uint256[3] memory liquidity;
            liquidity[toIndex] = _to;
            // Transferring stablecoins back to Curve
            ICurveFi_Polygon_3(curve).add_liquidity(liquidity, 0, true);
        }

        deposit();
    }
}

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IController.sol";

import {GaugesDistributor} from "./GaugesDistributor.sol";
import {Gauge} from "./Gauge.sol";

contract NeuronPool is ERC20 {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Token accepted by the contract. E.g. 3Crv for 3poolCrv pool
    // Usually want/_want in strategies
    IERC20 public token;

    uint256 public min = 9500;
    uint256 public constant max = 10000;

    uint8 public immutable _decimals;

    address public governance;
    address public timelock;
    address public controller;
    address public masterchef;
    GaugesDistributor public gaugesDistributor;

    constructor(
        // Token accepted by the contract. E.g. 3Crv for 3poolCrv pool
        // Usually want/_want in strategies
        address _token,
        address _governance,
        address _timelock,
        address _controller,
        address _masterchef,
        address _gaugesDistributor
    )
        ERC20(
            string(abi.encodePacked("neuroned", ERC20(_token).name())),
            string(abi.encodePacked("neur", ERC20(_token).symbol()))
        )
    {
        _decimals = ERC20(_token).decimals();
        token = IERC20(_token);
        governance = _governance;
        timelock = _timelock;
        controller = _controller;
        masterchef = _masterchef;
        gaugesDistributor = GaugesDistributor(_gaugesDistributor);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // Balance = pool's balance + pool's token controller contract balance
    function balance() public view returns (uint256) {
        return
            token.balanceOf(address(this)).add(
                IController(controller).balanceOf(address(token))
            );
    }

    function setMin(uint256 _min) external {
        require(msg.sender == governance, "!governance");
        require(_min <= max, "numerator cannot be greater than denominator");
        min = _min;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) public {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setController(address _controller) public {
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    // Returns tokens available for deposit into the pool
    // Custom logic in here for how much the pools allows to be borrowed
    function available() public view returns (uint256) {
        return token.balanceOf(address(this)).mul(min).div(max);
    }

    // Depositing tokens into pool
    // Usually called manually in tests
    function earn() public {
        uint256 _bal = available();
        token.safeTransfer(controller, _bal);
        IController(controller).earn(address(token), _bal);
    }

    function depositAll() external {
        deposit(token.balanceOf(msg.sender));
    }

    // User's entry point; called on pressing Deposit in Neuron's UI
    function deposit(uint256 _amount) public {
        // Pool's + controller balances
        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        // totalSupply - total supply of pToken, given in exchange for depositing to a pool, eg p3CRV for 3Crv
        if (totalSupply() == 0) {
            // Tokens user will get in exchange for deposit. First user receives tokens equal to deposit.
            shares = _amount;
        } else {
            // For subsequent users: (tokens_stacked * exist_pTokens) / total_tokens_stacked. total_tokesn_stacked - not considering first users
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
    }

    function depositAndFarm(uint256 _amount) public {
        // Pool's + controller balances
        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        // totalSupply - total supply of pToken, given in exchange for depositing to a pool, eg p3CRV for 3Crv
        if (totalSupply() == 0) {
            // Tokens user will get in exchange for deposit. First user receives tokens equal to deposit.
            shares = _amount;
        } else {
            // For subsequent users: (tokens_stacked * exist_pTokens) / total_tokens_stacked. total_tokesn_stacked - not considering first users
            shares = (_amount.mul(totalSupply())).div(_pool);
        }

        Gauge gauge = Gauge(gaugesDistributor.getGauge(address(this)));
        _mint(address(gauge), shares);
        gauge.depositStateUpdateByPool(msg.sender, shares);
    }

    function withdrawAll() external {
        withdrawFor(msg.sender, balanceOf(msg.sender), msg.sender);
    }

    function withdraw(uint256 _shares) external {
        withdrawFor(msg.sender, _shares, msg.sender);
    }

    // Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
    function harvest(address reserve, uint256 amount) external {
        require(msg.sender == controller, "!controller");
        require(reserve != address(token), "token");
        IERC20(reserve).safeTransfer(controller, amount);
    }

    // No rebalance implementation for lower fees and faster swaps
    function withdrawFor(
        address holder,
        uint256 _shares,
        address burnFrom
    ) internal {
        // _shares - tokens user wants to withdraw
        uint256 r = (balance().mul(_shares)).div(totalSupply());
        _burn(burnFrom, _shares);

        // Check balance
        uint256 b = token.balanceOf(address(this));
        // If pool balance's not enough, we're withdrawing the controller's tokens
        if (b < r) {
            uint256 _withdraw = r.sub(b);
            IController(controller).withdraw(address(token), _withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        token.safeTransfer(holder, r);
    }

    function withdrawAllRightFromFarm() external {
        Gauge gauge = Gauge(gaugesDistributor.getGauge(address(this)));
        uint256 shares = gauge.withdrawAllStateUpdateByPool(msg.sender);
        withdrawFor(msg.sender, shares, address(gauge));
    }

    function getRatio() public view returns (uint256) {
        uint256 currentTotalSupply = totalSupply();
        if (currentTotalSupply == 0) {
            return 0;
        }
        return balance().mul(1e18).div(currentTotalSupply);
    }
}

pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./Gauge.sol";

interface IMinter {
    function collect() external;
}

contract GaugesDistributor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable NEURON;
    IERC20 public immutable AXON;
    address public governance;
    address public admin;

    uint256 public pid;
    uint256 public totalWeight;
    IMinter public minter;
    bool public isManualWeights = true;

    address[] internal _tokens;
    mapping(address => address) public gauges; // token => gauge
    mapping(address => uint256) public weights; // token => weight
    mapping(address => mapping(address => uint256)) public votes; // msg.sender => votes
    mapping(address => address[]) public tokenVote; // msg.sender => token
    mapping(address => uint256) public usedWeights; // msg.sender => total voting weight of user

    constructor(
        address _minter,
        address _neuronToken,
        address _axon,
        address _governance,
        address _admin
    ) {
        minter = IMinter(_minter);
        NEURON = IERC20(_neuronToken);
        AXON = IERC20(_axon);
        governance = _governance;
        admin = _admin;
    }

    function setMinter(address _minter) public {
        require(
            msg.sender == governance,
            "!admin and !governance"
        );
        minter = IMinter(_minter);
    }

    function tokens() external view returns (address[] memory) {
        return _tokens;
    }

    function getGauge(address _token) external view returns (address) {
        return gauges[_token];
    }

    // Reset votes to 0
    function reset() external {
        _reset(msg.sender);
    }

    // Reset votes to 0
    function _reset(address _owner) internal {
        address[] storage _tokenVote = tokenVote[_owner];
        uint256 _tokenVoteCnt = _tokenVote.length;

        for (uint256 i = 0; i < _tokenVoteCnt; i++) {
            address _token = _tokenVote[i];
            uint256 _votes = votes[_owner][_token];

            if (_votes > 0) {
                totalWeight = totalWeight.sub(_votes);
                weights[_token] = weights[_token].sub(_votes);

                votes[_owner][_token] = 0;
            }
        }

        delete tokenVote[_owner];
    }

    // Adjusts _owner's votes according to latest _owner's AXON balance
    function poke(address _owner) public {
        address[] memory _tokenVote = tokenVote[_owner];
        uint256 _tokenCnt = _tokenVote.length;
        uint256[] memory _weights = new uint256[](_tokenCnt);

        uint256 _prevUsedWeight = usedWeights[_owner];
        uint256 _weight = AXON.balanceOf(_owner);

        for (uint256 i = 0; i < _tokenCnt; i++) {
            uint256 _prevWeight = votes[_owner][_tokenVote[i]];
            _weights[i] = _prevWeight.mul(_weight).div(_prevUsedWeight);
        }

        _vote(_owner, _tokenVote, _weights);
    }

    function _vote(
        address _owner,
        address[] memory _tokenVote,
        uint256[] memory _weights
    ) internal {
        _reset(_owner);
        uint256 _tokenCnt = _tokenVote.length;
        uint256 _weight = AXON.balanceOf(_owner);
        uint256 _totalVoteWeight = 0;
        uint256 _usedWeight = 0;

        for (uint256 i = 0; i < _tokenCnt; i++) {
            _totalVoteWeight = _totalVoteWeight.add(_weights[i]);
        }

        for (uint256 i = 0; i < _tokenCnt; i++) {
            address _token = _tokenVote[i];
            address _gauge = gauges[_token];
            uint256 _tokenWeight = _weights[i].mul(_weight).div(
                _totalVoteWeight
            );

            if (_gauge != address(0x0)) {
                _usedWeight = _usedWeight.add(_tokenWeight);
                totalWeight = totalWeight.add(_tokenWeight);
                weights[_token] = weights[_token].add(_tokenWeight);
                tokenVote[_owner].push(_token);
                votes[_owner][_token] = _tokenWeight;
            }
        }

        usedWeights[_owner] = _usedWeight;
    }

    function setWeights(
        address[] memory _tokensToVote,
        uint256[] memory _weights
    ) external {
        require(
            msg.sender == admin || msg.sender == governance,
            "Set weights function can only be executed by admin or governance"
        );
        require(isManualWeights, "Manual weights mode is off");

        require(
            _tokensToVote.length == _weights.length,
            "Number Tokens to vote should be the same as weights number"
        );

        uint256 _tokensCnt = _tokensToVote.length;
        uint256 _totalWeight = 0;
        for (uint256 i = 0; i < _tokensCnt; i++) {
            address _token = _tokensToVote[i];
            address _gauge = gauges[_token];
            uint256 _tokenWeight = _weights[i];

            if (_gauge != address(0x0)) {
                _totalWeight = _totalWeight.add(_tokenWeight);
                weights[_token] = _tokenWeight;
            }
        }
        totalWeight = _totalWeight;
    }

    function setIsManualWeights(bool _isManualWeights) external {
        require(msg.sender == governance, "!governance");

        isManualWeights = _isManualWeights;
    }

    // Vote with AXON on a gauge
    function vote(address[] calldata _tokenVote, uint256[] calldata _weights)
        external
    {
        require(_tokenVote.length == _weights.length);
        require(!isManualWeights, "isManualWeights should be false");
        _vote(msg.sender, _tokenVote, _weights);
    }

    function addGauge(address _token) external {
        require(msg.sender == governance, "!governance");
        require(gauges[_token] == address(0x0), "exists");
        gauges[_token] = address(
            new Gauge(_token, address(NEURON), address(AXON))
        );
        _tokens.push(_token);
    }

    // Fetches Neurons
    function collect() internal {
        minter.collect();
    }

    function length() external view returns (uint256) {
        return _tokens.length;
    }

    function distribute() external {
        require(
            msg.sender == admin || msg.sender == governance,
            "Distribute function can only be executed by admin or governance"
        );
        collect();
        uint256 _balance = NEURON.balanceOf(address(this));
        if (_balance > 0 && totalWeight > 0) {
            for (uint256 i = 0; i < _tokens.length; i++) {
                address _token = _tokens[i];
                address _gauge = gauges[_token];
                uint256 _reward = _balance.mul(weights[_token]).div(
                    totalWeight
                );
                if (_reward > 0) {
                    NEURON.safeApprove(_gauge, 0);
                    NEURON.safeApprove(_gauge, _reward);
                    Gauge(_gauge).notifyRewardAmount(_reward);
                }
            }
        }
    }

    function setAdmin(address _admin) external {
        require(
            msg.sender == admin || msg.sender == governance,
            "Only governance or admin can set admin"
        );

        admin = _admin;
    }
}

pragma solidity 0.8.2;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IAxon} from "./interfaces/IAxon.sol";

contract Gauge is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable NEURON;
    IAxon public immutable AXON;

    IERC20 public immutable TOKEN;
    address public immutable DISTRIBUTION;
    uint256 public constant DURATION = 7 days;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    modifier onlyDistribution() {
        require(
            msg.sender == DISTRIBUTION,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public _totalSupply;
    uint256 public derivedSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public derivedBalances;
    mapping(address => uint256) private _base;

    constructor(
        address _token,
        address _neuron,
        address _axon
    ) {
        NEURON = IERC20(_neuron);
        AXON = IAxon(_axon);
        TOKEN = IERC20(_token);
        DISTRIBUTION = msg.sender;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(derivedSupply)
            );
    }

    function derivedBalance(address account) public view returns (uint256) {
        uint256 _balance = _balances[account];
        uint256 _derived = _balance.mul(40).div(100);
        uint256 axonMultiplier = 0;
        uint256 axonTotalSupply = AXON.totalSupply();
        if (axonTotalSupply != 0) {
            axonMultiplier = AXON.balanceOf(account).div(AXON.totalSupply());
        }
        uint256 _adjusted = (_totalSupply.mul(axonMultiplier)).mul(60).div(100);
        return Math.min(_derived.add(_adjusted), _balance);
    }

    function kick(address account) public {
        uint256 _derivedBalance = derivedBalances[account];
        derivedSupply = derivedSupply.sub(_derivedBalance);
        _derivedBalance = derivedBalance(account);
        derivedBalances[account] = _derivedBalance;
        derivedSupply = derivedSupply.add(_derivedBalance);
    }

    function earned(address account) public view returns (uint256) {
        return
            derivedBalances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(DURATION);
    }

    function depositAll() external {
        _deposit(TOKEN.balanceOf(msg.sender), msg.sender, msg.sender);
    }

    function deposit(uint256 amount) external {
        _deposit(amount, msg.sender, msg.sender);
    }

    function depositFor(uint256 amount, address account) external {
        _deposit(amount, account, account);
    }

    function depositFromSenderFor(uint256 amount, address account) external {
        _deposit(amount, msg.sender, account);
    }

    function depositStateUpdate(address holder, uint256 amount)
        internal
        updateReward(holder)
    {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[holder] = _balances[holder].add(amount);
        emit Staked(holder, amount);
    }

    function depositStateUpdateByPool(address holder, uint256 amount) external {
        require(
            msg.sender == address(TOKEN),
            "State update without transfer can only be called by pool"
        );
        depositStateUpdate(holder, amount);
    }

    function _deposit(
        uint256 amount,
        address spender,
        address recipient
    ) internal nonReentrant {
        depositStateUpdate(recipient, amount);
        TOKEN.safeTransferFrom(spender, address(this), amount);
    }

    function withdrawAll() external {
        _withdraw(_balances[msg.sender]);
    }

    function withdraw(uint256 amount) external {
        _withdraw(amount);
    }

    function _withdraw(uint256 amount)
        internal
        nonReentrant
    {
        withdrawStateUpdate(msg.sender, amount);
        TOKEN.safeTransfer(msg.sender, amount);
    }

    function withdrawStateUpdate(address holder, uint256 amount) internal updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[holder] = _balances[holder].sub(amount);
        emit Withdrawn(holder, amount);
    }

    // We use this function when withdraw right from pool. No transfer because after that we burn this amount from contract.
    function withdrawAllStateUpdateByPool(address holder)
        external
        nonReentrant
        returns (uint256)
    {
        require(
            msg.sender == address(TOKEN),
            "Only corresponding pool can withdraw tokens for someone"
        );
        uint256 amount = _balances[holder];
        withdrawStateUpdate(holder, amount);
        return amount;
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            NEURON.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        _withdraw(_balances[msg.sender]);
        getReward();
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyDistribution
        updateReward(address(0))
    {
        NEURON.safeTransferFrom(DISTRIBUTION, address(this), reward);
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = NEURON.balanceOf(address(this));
        require(
            rewardRate <= balance.div(DURATION),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
        if (account != address(0)) {
            kick(account);
        }
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
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

pragma solidity 0.8.2;

interface IAxon {
    function balanceOf(address addr, uint256 _t) external view returns (uint256);

    function balanceOf(address addr) external view returns (uint256);

    function balanceOfAt(address addr, uint256 _block)
        external
        view
        returns (uint256);

    function totalSupply(uint256 t) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

pragma solidity 0.8.2;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GaugePolygon is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable NEURON;

    IERC20 public immutable TOKEN;
    address public immutable DISTRIBUTION;
    uint256 public constant DURATION = 7 days;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    modifier onlyDistribution() {
        require(
            msg.sender == DISTRIBUTION,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _base;

    constructor(address _token, address _neuron) {
        NEURON = IERC20(_neuron);
        TOKEN = IERC20(_token);
        DISTRIBUTION = msg.sender;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(DURATION);
    }

    function depositAll() external {
        _deposit(TOKEN.balanceOf(msg.sender), msg.sender, msg.sender);
    }

    function deposit(uint256 amount) external {
        _deposit(amount, msg.sender, msg.sender);
    }

    function depositFor(uint256 amount, address account) external {
        _deposit(amount, account, account);
    }

    function depositFromSenderFor(uint256 amount, address account) external {
        _deposit(amount, msg.sender, account);
    }

    function depositStateUpdate(address holder, uint256 amount)
        internal
        updateReward(holder)
    {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[holder] = _balances[holder].add(amount);
        emit Staked(holder, amount);
    }

    function depositStateUpdateByPool(address holder, uint256 amount) external {
        require(
            msg.sender == address(TOKEN),
            "State update without transfer can only be called by pool"
        );
        depositStateUpdate(holder, amount);
    }

    function _deposit(
        uint256 amount,
        address spender,
        address recipient
    ) internal nonReentrant {
        depositStateUpdate(recipient, amount);
        TOKEN.safeTransferFrom(spender, address(this), amount);
    }

    function withdrawAll() external {
        _withdraw(_balances[msg.sender]);
    }

    function withdraw(uint256 amount) external {
        _withdraw(amount);
    }

    function _withdraw(uint256 amount) internal nonReentrant {
        withdrawStateUpdate(msg.sender, amount);
        TOKEN.safeTransfer(msg.sender, amount);
    }

    function withdrawStateUpdate(address holder, uint256 amount)
        internal
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[holder] = _balances[holder].sub(amount);
        emit Withdrawn(holder, amount);
    }

    // We use this function when withdraw right from pool. No transfer because after that we burn this amount from contract.
    function withdrawAllStateUpdateByPool(address holder)
        external
        nonReentrant
        returns (uint256)
    {
        require(
            msg.sender == address(TOKEN),
            "Only corresponding pool can withdraw tokens for someone"
        );
        uint256 amount = _balances[holder];
        withdrawStateUpdate(holder, amount);
        return amount;
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            NEURON.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        _withdraw(_balances[msg.sender]);
        getReward();
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyDistribution
        updateReward(address(0))
    {
        NEURON.safeTransferFrom(DISTRIBUTION, address(this), reward);
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = NEURON.balanceOf(address(this));
        require(
            rewardRate <= balance.div(DURATION),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    // BEFORE_DEPLOY gauges shouldn't be empty at the moment of first users staking. Set rewardPerTokenStored
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./GaugePolygon.sol";

interface IMinter {
    function collect() external;
}

contract GaugesDistributorPolygon {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable NEURON;
    address public governance;
    address public admin;

    uint256 public pid;
    uint256 public totalWeight;
    IMinter public minter;

    address[] internal _tokens;
    mapping(address => address) public gauges; // token => gauge
    mapping(address => uint256) public weights; // token => weight
    mapping(address => mapping(address => uint256)) public votes; // msg.sender => votes

    constructor(
        address _minter,
        address _neuronToken,
        address _governance,
        address _admin
    ) {
        minter = IMinter(_minter);
        NEURON = IERC20(_neuronToken);
        governance = _governance;
        admin = _admin;
    }

    function setMinter(address _minter) public {
        require(msg.sender == governance, "!admin and !governance");
        minter = IMinter(_minter);
    }

    function tokens() external view returns (address[] memory) {
        return _tokens;
    }

    function getGauge(address _token) external view returns (address) {
        return gauges[_token];
    }

    function setWeights(
        address[] memory _tokensToVote,
        uint256[] memory _weights
    ) external {
        require(
            msg.sender == admin || msg.sender == governance,
            "Set weights function can only be executed by admin or governance"
        );
        require(
            _tokensToVote.length == _weights.length,
            "Number Tokens to vote should be the same as weights number"
        );

        uint256 _tokensCnt = _tokensToVote.length;
        uint256 _totalWeight = 0;
        for (uint256 i = 0; i < _tokensCnt; i++) {
            address _token = _tokensToVote[i];
            address _gauge = gauges[_token];
            uint256 _tokenWeight = _weights[i];

            if (_gauge != address(0x0)) {
                _totalWeight = _totalWeight.add(_tokenWeight);
                weights[_token] = _tokenWeight;
            }
        }
        totalWeight = _totalWeight;
    }

    function addGauge(address _token) external {
        require(msg.sender == governance, "!governance");
        require(gauges[_token] == address(0x0), "exists");
        gauges[_token] = address(new GaugePolygon(_token, address(NEURON)));
        _tokens.push(_token);
    }

    // Fetches Neurons
    function collect() internal {
        minter.collect();
    }

    function length() external view returns (uint256) {
        return _tokens.length;
    }

    function distribute() external {
        require(
            msg.sender == admin || msg.sender == governance,
            "Distribute function can only be executed by admin or governance"
        );
        collect();
        uint256 _balance = NEURON.balanceOf(address(this));
        if (_balance > 0 && totalWeight > 0) {
            for (uint256 i = 0; i < _tokens.length; i++) {
                address _token = _tokens[i];
                address _gauge = gauges[_token];
                uint256 _reward = _balance.mul(weights[_token]).div(
                    totalWeight
                );
                if (_reward > 0) {
                    NEURON.safeApprove(_gauge, 0);
                    NEURON.safeApprove(_gauge, _reward);
                    GaugePolygon(_gauge).notifyRewardAmount(_reward);
                }
            }
        }
    }

    function setAdmin(address _admin) external {
        require(
            msg.sender == admin || msg.sender == governance,
            "Only governance or admin can set admin"
        );

        admin = _admin;
    }
}

pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {AnyswapV5ERC20} from "./lib/AnyswapV5ERC20.sol";

contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The NEURON TOKEN
    AnyswapV5ERC20 public neuronToken;
    // Dev fund (10%, initially)
    uint256 public devFundPercentage = 10;
    // Treasury (10%, initially)
    uint256 public treasuryPercentage = 10;
    address public governance;
    // Dev address.
    address public devaddr;
    address public treasuryAddress;
    // Block number when bonus NEURON period ends.
    uint256 public bonusEndBlock;
    // NEURON tokens created per block.
    uint256 public neuronTokenPerBlock;
    // Bonus muliplier for early nueron makers.
    uint256 public constant BONUS_MULTIPLIER = 10;

    // The block number when NEURON mining starts.
    uint256 public startBlock;

    address public distributor;
    uint256 public distributorLastRewardBlock;

    // Events
    event Recovered(address token, uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    modifier onlyGovernance() {
        require(
            governance == _msgSender(),
            "Governance: caller is not the governance"
        );
        _;
    }

    constructor(
        address _neuronToken,
        address _governance,
        address _devaddr,
        address _treasuryAddress,
        uint256 _neuronTokenPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) {
        neuronToken = AnyswapV5ERC20(_neuronToken);
        governance = _governance;
        devaddr = _devaddr;
        treasuryAddress = _treasuryAddress;

        distributorLastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;

        neuronTokenPerBlock = _neuronTokenPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    function collect() external {
        require(msg.sender == distributor, "Only distributor can collect");
        uint256 multiplier = getMultiplier(
            distributorLastRewardBlock,
            block.number
        );
        distributorLastRewardBlock = block.number;
        uint256 neuronTokenReward = multiplier.mul(neuronTokenPerBlock);
        neuronToken.mint(devaddr, neuronTokenReward.div(100).mul(devFundPercentage));
        neuronToken.mint(treasuryAddress, neuronTokenReward.div(100).mul(treasuryPercentage));
        neuronToken.mint(distributor, neuronTokenReward);
    }

    // Safe neuronToken transfer function, just in case if rounding error causes pool to not have enough NEURs.
    function safeNeuronTokenTransfer(address _to, uint256 _amount) internal {
        uint256 neuronTokenBalance = neuronToken.balanceOf(address(this));
        if (_amount > neuronTokenBalance) {
            neuronToken.transfer(_to, neuronTokenBalance);
        } else {
            neuronToken.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function setDevAddr(address _devaddr) external {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    // **** Additional functions separate from the original masterchef contract ****

    function setNeuronTokenPerBlock(uint256 _neuronTokenPerBlock)
        external
        onlyGovernance
    {
        require(_neuronTokenPerBlock > 0, "!neuronTokenPerBlock-0");

        neuronTokenPerBlock = _neuronTokenPerBlock;
    }

    function setBonusEndBlock(uint256 _bonusEndBlock) external onlyGovernance {
        bonusEndBlock = _bonusEndBlock;
    }

    function setDevFundPercentage(uint256 _devFundPercentage)
        external
        onlyGovernance
    {
        require(_devFundPercentage > 0, "!devFundPercentage-0");
        devFundPercentage = _devFundPercentage;
    }

    function setTreasuryPercentage(uint256 _treasuryPercentage)
        external
        onlyGovernance
    {
        require(_treasuryPercentage > 0, "!treasuryPercentage-0");
        treasuryPercentage = _treasuryPercentage;
    }

    function setDistributor(address _distributor) external onlyGovernance {
        distributor = _distributor;
        distributorLastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address target,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferWithPermit(
        address target,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

/// @dev Wrapped ERC-20 v10 (AnyswapV3ERC20) is an ERC-20 ERC-20 wrapper. You can `deposit` ERC-20 and obtain an AnyswapV3ERC20 balance which can then be operated as an ERC-20 token. You can
/// `withdraw` ERC-20 from AnyswapV3ERC20, which will then burn AnyswapV3ERC20 token in your wallet. The amount of AnyswapV3ERC20 token in any wallet is always identical to the
/// balance of ERC-20 deposited minus the ERC-20 withdrawn with that specific wallet.
interface IAnyswapV3ERC20 is IERC20, IERC2612 {
    /// @dev Sets `value` as allowance of `spender` account over caller account's AnyswapV3ERC20 token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on approveAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(
        address spender,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    /// @dev Moves `value` AnyswapV3ERC20 token from caller's account to account (`to`),
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ERC-20 withdraw matching the sent AnyswapV3ERC20 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` AnyswapV3ERC20 token.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool);
}

interface ITransferReceiver {
    function onTokenTransfer(
        address,
        uint256,
        bytes calldata
    ) external returns (bool);
}

interface IApprovalReceiver {
    function onTokenApproval(
        address,
        uint256,
        bytes calldata
    ) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;

            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract AnyswapV5ERC20 is IAnyswapV3ERC20 {
    using SafeERC20 for IERC20;
    string public name;
    string public symbol;
    uint8 public immutable override decimals;

    address public immutable underlying;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    bytes32 public constant TRANSFER_TYPEHASH =
        keccak256(
            "Transfer(address owner,address to,uint256 value,uint256 nonce,uint256 deadline)"
        );
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @dev Records amount of AnyswapV3ERC20 token owned by account.
    mapping(address => uint256) public override balanceOf;
    uint256 private _totalSupply;

    // init flag for setting immediate vault, needed for CREATE2 support
    bool private _init;

    // flag to enable/disable swapout vs vault.burn so multiple events are triggered
    bool private _vaultOnly;

    // configurable delay for timelock functions
    // BEFORE_DEPLOY discuss delay. 2 days (default value) maybe too much. Now set to 0 for testing
    // uint256 public delay = 2 * 24 * 3600;
    uint256 public delay = 0;

    // set of minters, can be this bridge or other bridges
    mapping(address => bool) public isMinter;
    address[] public minters;

    // primary controller of the token contract
    address public vault;

    address public pendingMinter;
    uint256 public delayMinter;

    address public pendingVault;
    uint256 public delayVault;

    uint256 public pendingDelay;
    uint256 public delayDelay;

    modifier onlyAuth() {
        require(isMinter[msg.sender], "AnyswapV4ERC20: FORBIDDEN");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == mpc(), "AnyswapV3ERC20: FORBIDDEN");
        _;
    }

    function owner() public view returns (address) {
        return mpc();
    }

    function mpc() public view returns (address) {
        if (block.timestamp >= delayVault) {
            return pendingVault;
        }
        return vault;
    }

    function setVaultOnly(bool enabled) external onlyVault {
        _vaultOnly = enabled;
    }

    function initVault(address _vault) external onlyVault {
        require(_init);
        vault = _vault;
        pendingVault = _vault;
        isMinter[_vault] = true;
        minters.push(_vault);
        delayVault = block.timestamp;
        _init = false;
    }

    function setMinter(address _auth) external onlyVault {
        pendingMinter = _auth;
        delayMinter = block.timestamp + delay;
    }

    function setVault(address _vault) external onlyVault {
        pendingVault = _vault;
        delayVault = block.timestamp + delay;
    }

    function applyVault() external onlyVault {
        require(block.timestamp >= delayVault);
        vault = pendingVault;
    }

    function applyMinter() external onlyVault {
        require(block.timestamp >= delayMinter);
        isMinter[pendingMinter] = true;
        minters.push(pendingMinter);
    }

    // No time delay revoke minter emergency function
    function revokeMinter(address _auth) external onlyVault {
        isMinter[_auth] = false;
    }

    function getAllMinters() external view returns (address[] memory) {
        return minters;
    }

    function changeVault(address newVault) external onlyVault returns (bool) {
        require(newVault != address(0), "AnyswapV3ERC20: address(0x0)");
        pendingVault = newVault;
        delayVault = block.timestamp + delay;
        emit LogChangeVault(vault, pendingVault, delayVault);
        return true;
    }

    function changeMPCOwner(address newVault) public onlyVault returns (bool) {
        require(newVault != address(0), "AnyswapV3ERC20: address(0x0)");
        pendingVault = newVault;
        delayVault = block.timestamp + delay;
        emit LogChangeMPCOwner(vault, pendingVault, delayVault);
        return true;
    }

    function mint(address to, uint256 amount) external onlyAuth returns (bool) {
        _mint(to, amount);
        return true;
    }

    function burn(address from, uint256 amount)
        external
        onlyAuth
        returns (bool)
    {
        require(from != address(0), "AnyswapV3ERC20: address(0x0)");
        _burn(from, amount);
        return true;
    }

    function Swapin(
        bytes32 txhash,
        address account,
        uint256 amount
    ) public onlyAuth returns (bool) {
        _mint(account, amount);
        emit LogSwapin(txhash, account, amount);
        return true;
    }

    function Swapout(uint256 amount, address bindaddr) public returns (bool) {
        require(!_vaultOnly, "AnyswapV4ERC20: onlyAuth");
        require(bindaddr != address(0), "AnyswapV3ERC20: address(0x0)");
        _burn(msg.sender, amount);
        emit LogSwapout(msg.sender, bindaddr, amount);
        return true;
    }

    /// @dev Records current ERC2612 nonce for account. This value must be included whenever signature is generated for {permit}.
    /// Every successful call to {permit} increases account's nonce by one. This prevents signature from being used multiple times.
    mapping(address => uint256) public override nonces;

    /// @dev Records number of AnyswapV3ERC20 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}.
    mapping(address => mapping(address => uint256)) public override allowance;

    event LogChangeVault(
        address indexed oldVault,
        address indexed newVault,
        uint256 indexed effectiveTime
    );
    event LogChangeMPCOwner(
        address indexed oldOwner,
        address indexed newOwner,
        uint256 indexed effectiveHeight
    );
    event LogSwapin(
        bytes32 indexed txhash,
        address indexed account,
        uint256 amount
    );
    event LogSwapout(
        address indexed account,
        address indexed bindaddr,
        uint256 amount
    );
    event LogAddAuth(address indexed auth, uint256 timestamp);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _underlying,
        address _vault
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        underlying = _underlying;
        if (_underlying != address(0x0)) {
            require(_decimals == IERC20(_underlying).decimals());
        }

        // Use init to allow for CREATE2 accross all chains
        _init = true;

        // Disable/Enable swapout for v1 tokens vs mint/burn for v3 tokens
        _vaultOnly = false;

        vault = _vault;
        pendingVault = _vault;
        delayVault = block.timestamp;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Returns the total supply of AnyswapV3ERC20 token as the ETH held in this contract.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function depositWithPermit(
        address target,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address to
    ) external returns (uint256) {
        IERC20(underlying).permit(
            target,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        IERC20(underlying).safeTransferFrom(target, address(this), value);
        return _deposit(value, to);
    }

    function depositWithTransferPermit(
        address target,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address to
    ) external returns (uint256) {
        IERC20(underlying).transferWithPermit(
            target,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        return _deposit(value, to);
    }

    function deposit() external returns (uint256) {
        uint256 _amount = IERC20(underlying).balanceOf(msg.sender);
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), _amount);
        return _deposit(_amount, msg.sender);
    }

    function deposit(uint256 amount) external returns (uint256) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount, msg.sender);
    }

    function deposit(uint256 amount, address to) external returns (uint256) {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount, to);
    }

    function depositVault(uint256 amount, address to)
        external
        onlyVault
        returns (uint256)
    {
        return _deposit(amount, to);
    }

    function _deposit(uint256 amount, address to) internal returns (uint256) {
        require(underlying != address(0x0) && underlying != address(this));
        _mint(to, amount);
        return amount;
    }

    function withdraw() external returns (uint256) {
        return _withdraw(msg.sender, balanceOf[msg.sender], msg.sender);
    }

    function withdraw(uint256 amount) external returns (uint256) {
        return _withdraw(msg.sender, amount, msg.sender);
    }

    function withdraw(uint256 amount, address to) external returns (uint256) {
        return _withdraw(msg.sender, amount, to);
    }

    function withdrawVault(
        address from,
        uint256 amount,
        address to
    ) external onlyVault returns (uint256) {
        return _withdraw(from, amount, to);
    }

    function _withdraw(
        address from,
        uint256 amount,
        address to
    ) internal returns (uint256) {
        _burn(from, amount);
        IERC20(underlying).safeTransfer(to, amount);
        return amount;
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
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        balanceOf[account] += amount;
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
        require(account != address(0), "ERC20: burn from the zero address");

        balanceOf[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's AnyswapV3ERC20 token.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        // _approve(msg.sender, spender, value);
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    /// @dev Sets `value` as allowance of `spender` account over caller account's AnyswapV3ERC20 token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on approveAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(
        address spender,
        uint256 value,
        bytes calldata data
    ) external override returns (bool) {
        // _approve(msg.sender, spender, value);
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return
            IApprovalReceiver(spender).onTokenApproval(msg.sender, value, data);
    }

    /// @dev Sets `value` as allowance of `spender` account over `owner` account's AnyswapV3ERC20 token, given `owner` account's signed approval.
    /// Emits {Approval} event.
    /// Requirements:
    ///   - `deadline` must be timestamp in future.
    ///   - `v`, `r` and `s` must be valid `secp256k1` signature from `owner` account over EIP712-formatted function arguments.
    ///   - the signature must use `owner` account's current nonce (see {nonces}).
    ///   - the signer cannot be zero address and must be `owner` account.
    /// For more information on signature format, see https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP section].
    /// AnyswapV3ERC20 token implementation adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol.
    function permit(
        address target,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(block.timestamp <= deadline, "AnyswapV3ERC20: Expired permit");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                target,
                spender,
                value,
                nonces[target]++,
                deadline
            )
        );

        require(
            verifyEIP712(target, hashStruct, v, r, s) ||
                verifyPersonalSign(target, hashStruct, v, r, s)
        );

        // _approve(owner, spender, value);
        allowance[target][spender] = value;
        emit Approval(target, spender, value);
    }

    function transferWithPermit(
        address target,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (bool) {
        require(block.timestamp <= deadline, "AnyswapV3ERC20: Expired permit");

        bytes32 hashStruct = keccak256(
            abi.encode(
                TRANSFER_TYPEHASH,
                target,
                to,
                value,
                nonces[target]++,
                deadline
            )
        );

        require(
            verifyEIP712(target, hashStruct, v, r, s) ||
                verifyPersonalSign(target, hashStruct, v, r, s)
        );

        require(to != address(0) || to != address(this));

        uint256 balance = balanceOf[target];
        require(
            balance >= value,
            "AnyswapV3ERC20: transfer amount exceeds balance"
        );

        balanceOf[target] = balance - value;
        balanceOf[to] += value;
        emit Transfer(target, to, value);

        return true;
    }

    function verifyEIP712(
        address target,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct)
        );
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == target);
    }

    function verifyPersonalSign(
        address target,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 hash = prefixed(hashStruct);
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == target);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    DOMAIN_SEPARATOR,
                    hash
                )
            );
    }

    /// @dev Moves `value` AnyswapV3ERC20 token from caller's account to account (`to`).
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent AnyswapV3ERC20 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` AnyswapV3ERC20 token.
    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        require(to != address(0) || to != address(this));
        uint256 balance = balanceOf[msg.sender];
        require(
            balance >= value,
            "AnyswapV3ERC20: transfer amount exceeds balance"
        );

        balanceOf[msg.sender] = balance - value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);

        return true;
    }

    /// @dev Moves `value` AnyswapV3ERC20 token from account (`from`) to account (`to`) using allowance mechanism.
    /// `value` is then deducted from caller account's allowance, unless set to `type(uint256).max`.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent AnyswapV3ERC20 token in favor of caller.
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - `from` account must have at least `value` balance of AnyswapV3ERC20 token.
    ///   - `from` account must have approved caller to spend at least `value` of AnyswapV3ERC20 token, unless `from` and caller are the same account.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        require(to != address(0) || to != address(this));
        if (from != msg.sender) {
            // _decreaseAllowance(from, msg.sender, value);
            uint256 allowed = allowance[from][msg.sender];
            if (allowed != type(uint256).max) {
                require(
                    allowed >= value,
                    "AnyswapV3ERC20: request exceeds allowance"
                );
                uint256 reduced = allowed - value;
                allowance[from][msg.sender] = reduced;
                emit Approval(from, msg.sender, reduced);
            }
        }

        uint256 balance = balanceOf[from];
        require(
            balance >= value,
            "AnyswapV3ERC20: transfer amount exceeds balance"
        );

        balanceOf[from] = balance - value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);

        return true;
    }

    /// @dev Moves `value` AnyswapV3ERC20 token from caller's account to account (`to`),
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent AnyswapV3ERC20 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` AnyswapV3ERC20 token.
    /// For more information on transferAndCall format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external override returns (bool) {
        require(to != address(0) || to != address(this));

        uint256 balance = balanceOf[msg.sender];
        require(
            balance >= value,
            "AnyswapV3ERC20: transfer amount exceeds balance"
        );

        balanceOf[msg.sender] = balance - value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);

        return ITransferReceiver(to).onTokenTransfer(msg.sender, value, data);
    }
}

pragma solidity 0.8.2;

import {AnyswapV5ERC20} from "./lib/AnyswapV5ERC20.sol";

// SPDX-License-Identifier: ISC

contract NeuronToken is AnyswapV5ERC20 {
    constructor(address _governance) AnyswapV5ERC20("NeuronToken", "NEUR", 18, address(0x0), _governance) {
        // governance will become admin who can add and revoke roles
    }
}

pragma solidity 0.8.2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardsDistributionRecipient {
    function notifyRewardAmount(uint256 reward) external;
    function getRewardToken() external view returns (IERC20);
}

pragma solidity 0.8.2;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title   StableMath
 * @author  Stability Labs Pty. Ltd.
 *   A library providing safe mathematical operations to multiply and
 *          divide with standardised precision.
 * @dev     Derives from OpenZeppelin's SafeMath lib and uses generic system
 *          wide variables for managing precision.
 */
library StableMath {
    using SafeMath for uint256;

    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;
    uint256 private constant RATIO_SCALE = 1e8;

    /**
     * @dev Provides an interface to the scaling unit
     * @return Scaling unit (1e18 or 1 * 10**18)
     */
    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }

    /**
     * @dev Provides an interface to the ratio unit
     * @return Ratio scale unit (1e8 or 1 * 10**8)
     */
    function getRatioScale() internal pure returns (uint256) {
        return RATIO_SCALE;
    }

    /**
     * @dev Scales a given integer to the power of the full scale.
     * @param x   Simple uint256 to scale
     * @return    Scaled value a to an exact number
     */
    function scaleInteger(uint256 x) internal pure returns (uint256) {
        return x.mul(FULL_SCALE);
    }

    /***************************************
              PRECISE ARITHMETIC
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @param scale Scale unit
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        uint256 z = x.mul(y);
        // return 9e38 / 1e18 = 9e18
        return z.div(scale);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x.mul(y);
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled.add(FULL_SCALE.sub(1));
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil.div(FULL_SCALE);
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x     Left hand input to division
     * @param y     Right hand input to division
     * @return      Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e18 * 1e18 = 8e36
        uint256 z = x.mul(FULL_SCALE);
        // e.g. 8e36 / 10e18 = 8e17
        return z.div(y);
    }

    /***************************************
                  RATIO FUNCS
    ****************************************/
    function mulRatioTruncate(uint256 x, uint256 ratio)
        internal
        pure
        returns (uint256 c)
    {
        return mulTruncateScale(x, ratio, RATIO_SCALE);
    }

    /**
     * @dev Multiplies and truncates a token ratio, rounding up the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand input to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              ratio scale, rounded up to the closest base unit.
     */
    function mulRatioTruncateCeil(uint256 x, uint256 ratio)
        internal
        pure
        returns (uint256)
    {
        // e.g. How much mAsset should I burn for this bAsset (x)?
        // 1e18 * 1e8 = 1e26
        uint256 scaled = x.mul(ratio);
        // 1e26 + 9.99e7 = 100..00.999e8
        uint256 ceil = scaled.add(RATIO_SCALE.sub(1));
        // return 100..00.999e8 / 1e8 = 1e18
        return ceil.div(RATIO_SCALE);
    }
    function divRatioPrecisely(uint256 x, uint256 ratio)
        internal
        pure
        returns (uint256 c)
    {
        // e.g. 1e14 * 1e8 = 1e22
        uint256 y = x.mul(RATIO_SCALE);
        // return 1e22 / 1e12 = 1e10
        return y.div(ratio);
    }

    /***************************************
                    HELPERS
    ****************************************/

    /**
     * @dev Calculates minimum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Minimum of the two inputs
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    /**
     * @dev Calculated maximum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Maximum of the two inputs
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @dev Clamps a value to an upper bound
     * @param x           Left hand input
     * @param upperBound  Maximum possible value to return
     * @return            Input x clamped to a maximum value, upperBound
     */
    function clamp(uint256 x, uint256 upperBound)
        internal
        pure
        returns (uint256)
    {
        return x > upperBound ? upperBound : x;
    }
}

pragma solidity 0.8.2;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Root {

    using SafeMath for uint256;

    /**
     * @dev Returns the square root of a given number
     * @param x Input
     * @return y Square root of Input
     */
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x.add(1)).div(2);
        y = x;
        while (z < y) {
            y = z;
            z = (x.div(z).add(z)).div(2);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategySushiFarmBase.sol";

contract StrategySushiEthDaiLp is StrategySushiFarmBase {
    // Token/ETH pool id in MasterChef contract
    uint256 public constant sushi_dai_poolId = 2;
    // Token addresses
    address public constant sushi_eth_dai_lp =
        0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f;
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _neuronTokenAddress,
        address _timelock
    )
        StrategySushiFarmBase(
            dai,
            sushi_dai_poolId,
            sushi_eth_dai_lp,
            _governance,
            _strategist,
            _controller,
            _neuronTokenAddress,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySushiEthDaiLp";
    }
}

