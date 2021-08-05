pragma solidity >=0.4.22 <0.7.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
contract DEFIX is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;
    
    event Burn(address indexed burner, uint256 value);

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    uint256 private _multiplier;
    uint256 private _startTime;
    uint256 private _burnTime;
    uint256 private _burnPercent;

    address private communityAddress = 0x74507C4973EcFc9126827Bf54AE3fb52E60499Ea;
    address private stakingAddress   = 0x6df03fF8AB9f31dCD41A6A0Eafc41d81Ac1e7641;
    address private marketingAddress = 0x161D2389FD4be1C2b91369FE9fE939D474EAF8da;
    address private preSaleAddress   = 0xB03096AfCF878fC4B2eE75a552F56a83cb33de2b;
    address private softStakeAddress = 0xFaf6BE82850373583151A19bF22C5a9C4deeFF0F;
    address private teamAddress      = 0xa7Abe1e71D7220154f7dcf5D8860C083D5095c37;
    address private uniswapAddress   = 0xCf12fe3Ca4d98449efbe048d4B29083606e0a516;

    struct vestingSchedule {
        uint256 allocatedAmount;             /* Percentage for vesting rate per duration. */
        uint256 releasedAmount;              /* Percentage for vesting rate per duration. */
        uint256 cliffDuration;               /* Duration of the cliff, with respect to the grant start day, in days. */
        uint256 duration;                    /* Duration of the vesting schedule, with respect to the grant start day, in days. */
        uint256 percentage;                  /* Percentage for vesting rate per duration. */
    }

    mapping (address => vestingSchedule) private _vestingSchedules;

    
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () public {
        _name = "Defix Network";
        _symbol = "DEFIX";
        _decimals = 18;
        _multiplier = uint256 (10 ** _decimals);
        _totalSupply = 100000000 * _multiplier;
        _startTime = block.timestamp;
        _burnTime = block.timestamp + 15 * 24 * 3600;
        _burnPercent = 6;

        _balances[communityAddress]   =                        0;
        _balances[stakingAddress]     =                        0;
        _balances[marketingAddress]   =    6000000 * _multiplier;
        _balances[preSaleAddress]     =   50000000 * _multiplier;
        _balances[softStakeAddress]   =                        0;
        _balances[teamAddress]        =                        0;
        _balances[uniswapAddress]     =   10000000 * _multiplier;

        _vestingSchedules[communityAddress] = vestingSchedule(
            4000000 * _multiplier,
            0,
            60,
            60,
            4
        );

        _vestingSchedules[stakingAddress] = vestingSchedule(
            12000000 * _multiplier,
            0,
            60,
            60,
            2
        );

        _vestingSchedules[softStakeAddress] = vestingSchedule(
            8000000 * _multiplier,
            0,
            90,
            120,
            4
        );

        _vestingSchedules[teamAddress] = vestingSchedule(
            10000000 * _multiplier,
            0,
            365,
            0,
            100
        );
        
        emit Transfer(address(0), marketingAddress, 6000000 * _multiplier);
        emit Transfer(address(0), preSaleAddress,  50000000 * _multiplier);
        emit Transfer(address(0), uniswapAddress,  10000000 * _multiplier);
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
    function decimals() public view returns (uint256) {
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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        
        

        if (_burnTime < block.timestamp && _totalSupply.sub(amount, "ERC20: transfer amount exceeds totalSupply") >= 25000000 * _multiplier) {
            _totalSupply = _totalSupply.sub(amount * _burnPercent / 100);
            _balances[recipient] = _balances[recipient].add(amount * (100 - _burnPercent) / 100);
            uint256 receivedAmount;
            uint256 burnAmount;
            receivedAmount = amount * (100 - _burnPercent) / 100;
            burnAmount = amount * _burnPercent / 100;
            emit Transfer(sender, recipient, receivedAmount);
            emit Transfer(sender, address(0), burnAmount);
            emit Burn(sender, burnAmount);
        } else {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
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
     * @notice Validate address.
     */
    function _validateAddress(address beneficiary) internal view returns (bool) {
        if(beneficiary == communityAddress || beneficiary == stakingAddress || beneficiary == softStakeAddress || beneficiary == teamAddress) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Calculate tokens held by timelock to beneficiary.
     */
    function _calculateToken(address beneficiary) internal {
        require(beneficiary != address(0), "ERC20: transfer to the zero address");
        require(_validateAddress(beneficiary) == true);

        if(block.timestamp.sub(_startTime) > _vestingSchedules[beneficiary].cliffDuration * 24 * 3600) {
            if(_vestingSchedules[beneficiary].releasedAmount < _vestingSchedules[beneficiary].allocatedAmount) {
                uint256 releaseAmount;
                uint256 times;
                uint256 newReleaseAmount;

                times = block.timestamp.sub(_startTime).sub(_vestingSchedules[beneficiary].cliffDuration * 24 * 3600).div(_vestingSchedules[beneficiary].duration * 24 * 3600);
                releaseAmount = _vestingSchedules[beneficiary].allocatedAmount.mul(times).mul(_vestingSchedules[beneficiary].percentage).div(100);

                require(releaseAmount <= _vestingSchedules[beneficiary].allocatedAmount);

                newReleaseAmount = releaseAmount.sub(_vestingSchedules[beneficiary].releasedAmount);
                _vestingSchedules[beneficiary].releasedAmount = releaseAmount;
                _balances[beneficiary] = _balances[beneficiary].add(newReleaseAmount);
                
                if(newReleaseAmount != 0) {
                    emit Transfer(address(0), beneficiary, newReleaseAmount);
                }
            }
        }
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function unlockToken(address beneficiary) public {
        require(beneficiary != address(0), "ERC20: approve from the zero address");
        _calculateToken(beneficiary);
    }
}
