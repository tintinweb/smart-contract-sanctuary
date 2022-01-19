// SPDX-License-Identifier: MIT

// 0xRektora

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './FUSD.sol';

interface IReserveOracle {
    function getExchangeRate(uint256 amount) external view returns (uint256);
}

/// @title King contract. Mint/Burn $FUSD against chosen assets
/// @author 0xRektora (https://github.com/0xRektora)
/// @notice Crown has the ability to add and disable reserve, which can be any ERC20 (stable/LP) given an oracle
/// that compute the exchange rates between $FUSD and the latter.
/// @dev Potential flaw of this tokenomics:
/// - Ability for the crown to change freely reserve parameters. (suggestion: immutable reserve/reserve parameter)
/// - Ability to withdraw assets and break the burning mechanism.
/// (suggestion: if reserve not immutable, compute a max amount withdrawable delta for a given reserve)
contract King {
    struct Reserve {
        uint128 mintingInterestRate; // In Bps
        uint128 burningTaxRate; // In Bps
        uint256 vestingPeriod;
        IReserveOracle reserveOracle;
        bool disabled;
        bool isReproveWhitelisted;
        uint256 sWagmeTaxRate; // In Bps
    }

    struct Vesting {
        uint256 unlockPeriod; // In block
        uint256 amount; // In FUSD
    }

    address public crown;
    FUSD public fusd;
    address public sWagmeKingdom;

    address[] public reserveAddresses;
    address[] public reserveReproveWhitelistAddresses; // Array of whitelisted reserve accepted in reprove()
    mapping(address => Reserve) public reserves;
    mapping(address => Vesting[]) public vestings;

    mapping(address => uint256) public freeReserves; // In FUSD

    event RegisteredReserve(
        address indexed reserve,
        uint256 index,
        uint256 blockNumber,
        uint128 mintingInterestRate,
        uint128 burningTaxRate,
        uint256 vestingPeriod,
        address reserveOracle,
        bool disabled,
        bool isReproveWhitelisted, // If this reserve can be used by users to reprove()
        uint256 sWagmeTaxRate
    );
    event Praise(address indexed reserve, address indexed to, uint256 amount, Vesting vesting);
    event Reprove(address indexed reserve, address indexed from, uint256 amount);
    event VestingRedeem(address indexed to, uint256 amount);
    event WithdrawReserve(address indexed reserve, address indexed to, uint256 amount);
    event UpdateReserveReproveWhitelistAddresses(address indexed reserve, bool newVal, bool created);

    modifier onlyCrown() {
        require(msg.sender == crown, 'King: Only crown can execute');
        _;
    }

    modifier reserveExists(address _reserve) {
        Reserve storage reserve = reserves[_reserve];
        require(address(reserve.reserveOracle) != address(0), "King: reserve doesn't exists");
        require(!reserve.disabled, 'King: reserve disabled');
        _;
    }

    constructor(address _fusd, address _sWagmeKingdom) {
        crown = msg.sender;
        fusd = FUSD(_fusd);
        sWagmeKingdom = _sWagmeKingdom;
    }

    /// @notice Returns the total number of reserves
    /// @return Length of [[reserveAddresses]]
    function reserveAddressesLength() external view returns (uint256) {
        return reserveAddresses.length;
    }

    /// @notice Returns the total number of whitelisted reserves for [[reprove()]]
    /// @return Length of [[reserveReproveWhitelistAddresses]]
    function reserveReproveWhitelistAddressesLength() external view returns (uint256) {
        return reserveReproveWhitelistAddresses.length;
    }

    /// @notice Use this function to create/change parameters of a given reserve
    /// @dev We inline assign each state to save gas instead of using Struct constructor
    /// @dev Potential flaw of this tokenomics:
    /// - Ability for the crown to change freely reserve parameters. (suggestion: immutable reserve/reserve parameter)
    /// @param _reserve the address of the asset to be used (ERC20 compliant)
    /// @param _mintingInterestRate The interest rate to be vested at mint
    /// @param _burningTaxRate The Burning tax rate that will go to sWagme holders
    /// @param _vestingPeriod The period where the interests will unlock
    /// @param _reserveOracle The oracle that is used for the exchange rate
    /// @param _disabled Controls the ability to be able to mint or not with the given asset
    function bless(
        address _reserve,
        uint128 _mintingInterestRate,
        uint128 _burningTaxRate,
        uint256 _vestingPeriod,
        address _reserveOracle,
        bool _disabled,
        bool _isReproveWhitelisted,
        uint256 _sWagmeTaxRate
    ) external onlyCrown {
        require(_reserveOracle != address(0), 'King: Invalid oracle');

        // Add or remove the reserve if needed from reserveReproveWhitelistAddresses

        Reserve storage reserve = reserves[_reserve];
        _updateReserveReproveWhitelistAddresses(reserve, _reserve, _isReproveWhitelisted);
        reserve.mintingInterestRate = _mintingInterestRate;
        reserve.burningTaxRate = _burningTaxRate;
        reserve.vestingPeriod = _vestingPeriod;
        reserve.reserveOracle = IReserveOracle(_reserveOracle);
        reserve.disabled = _disabled;
        reserve.isReproveWhitelisted = _isReproveWhitelisted;
        reserve.sWagmeTaxRate = _sWagmeTaxRate;

        // !\ Careful of gas cost /!\
        if (!doesReserveExists(_reserve)) {
            reserveAddresses.push(_reserve);
        }

        emit RegisteredReserve(
            _reserve,
            reserveAddresses.length - 1,
            block.number,
            _mintingInterestRate,
            _burningTaxRate,
            _vestingPeriod,
            _reserveOracle,
            _disabled,
            _isReproveWhitelisted,
            _sWagmeTaxRate
        );
    }

    /// @notice Mint a given [[_amount]] of $FUSD using [[_reserve]] asset to an [[_account]]
    /// @dev Compute and send to the King the amount of [[_reserve]] in exchange of $FUSD.
    /// @param _reserve The asset to be used (ERC20)
    /// @param _account The receiver of $FUSD
    /// @param _amount The amount of $FUSD minted
    /// @return totalMinted True amount of $FUSD minted
    function praise(
        address _reserve,
        address _account,
        uint256 _amount
    ) external reserveExists(_reserve) returns (uint256 totalMinted) {
        Reserve storage reserve = reserves[_reserve];
        totalMinted += _amount;

        uint256 toExchange = reserve.reserveOracle.getExchangeRate(_amount);

        IERC20(_reserve).transferFrom(msg.sender, address(this), toExchange);

        freeReserves[_reserve] += (_amount * reserve.burningTaxRate) / 10000;

        Vesting[] storage accountVestings = vestings[_account];
        Vesting memory vesting;
        vesting.unlockPeriod = block.number + reserve.vestingPeriod;
        vesting.amount = (_amount * reserve.mintingInterestRate) / 10000;
        accountVestings.push(vesting);

        totalMinted -= vesting.amount;

        fusd.mint(_account, totalMinted);
        emit Praise(_reserve, _account, totalMinted, vesting);

        return totalMinted;
    }

    /// @notice Burn $FUSD in exchange of the desired reserve. A certain amount could be taxed and sent to sWagme
    /// @param _reserve The reserve to exchange with
    /// @param _amount The amount of $FUSD to reprove
    /// @return toExchange The amount of chosen reserve exchanged
    function reprove(address _reserve, uint256 _amount) external reserveExists(_reserve) returns (uint256 toExchange) {
        Reserve storage reserve = reserves[_reserve];
        require(reserve.isReproveWhitelisted, 'King: reserve not whitelisted for reproval');
        uint256 sWagmeTax = (_amount * reserve.sWagmeTaxRate) / 10000;
        toExchange = IReserveOracle(reserve.reserveOracle).getExchangeRate(_amount - sWagmeTax);

        // Send to WAGME
        fusd.burnFrom(msg.sender, _amount - sWagmeTax);
        fusd.transferFrom(msg.sender, sWagmeKingdom, sWagmeTax);

        // Send underlyings to sender
        IERC20(_reserve).transfer(msg.sender, toExchange);

        emit Reprove(_reserve, msg.sender, _amount);
    }

    /// @notice View function to return info about an account vestings
    /// @param _account The account to check for
    /// @return redeemable The amount of $FUSD that can be redeemed
    /// @return numOfVestings The number of vestings of [[_account]]
    function getVestingInfos(address _account) external view returns (uint256 redeemable, uint256 numOfVestings) {
        Vesting[] memory accountVestings = vestings[_account];
        uint256 arrLength = accountVestings.length;
        numOfVestings = arrLength;
        for (uint256 i; i < arrLength; i++) {
            uint256 tmp = _computeRedeemableVestings(accountVestings, i);
            redeemable += tmp;
            if (tmp > 0) {
                arrLength--;
            }
            if (arrLength > 0 && i == arrLength - 1) {
                redeemable += tmp;
            }
        }
    }

    /// @dev Used by [[getVestingInfos()]]
    /// @param _accountVestings A memory copy of [[vestings]]
    /// @param _i The element of array to deal with (must be withing bounds, no checks are made)
    /// @return redeemed The total redeemed, if > 0 array size is lower
    function _computeRedeemableVestings(Vesting[] memory _accountVestings, uint256 _i)
        internal
        view
        returns (uint256 redeemed)
    {
        if (block.number >= _accountVestings[_i].unlockPeriod) {
            redeemed += _accountVestings[_i].amount;
            // We remove the vesting when redeemed
            _accountVestings[_i] = _accountVestings[_accountVestings.length - 1];
        }
    }

    /// @notice Redeem any ongoing vesting for a given account
    /// @dev Mint $FUSD and remove vestings that has been redeemed from [[vestings[_account]]]
    /// @param _account The vesting account
    /// @return redeemed The amount of $FUSD redeemed
    function redeemVestings(address _account) external returns (uint256 redeemed) {
        Vesting[] storage accountVestings = vestings[_account];
        for (uint256 i; i < accountVestings.length; i++) {
            redeemed += _redeemVesting(accountVestings, i);
            if (accountVestings.length > 0 && i == accountVestings.length - 1) {
                redeemed += _redeemVesting(accountVestings, i);
            }
        }
        if (redeemed > 0) {
            fusd.mint(_account, redeemed);
            emit VestingRedeem(_account, redeemed);
        }
    }

    /// @dev May remove element from the passed array of [[_accountVestings]]
    /// @param _accountVestings The storage of [[vestings]]
    /// @param _i The element of array to deal with (must be withing bounds, no checks are made)
    /// @return redeemed The total redeemed, if > 0 array size is lower
    function _redeemVesting(Vesting[] storage _accountVestings, uint256 _i) internal returns (uint256 redeemed) {
        if (block.number >= _accountVestings[_i].unlockPeriod) {
            redeemed += _accountVestings[_i].amount;
            // We remove the vesting when redeemed
            _accountVestings[_i] = _accountVestings[_accountVestings.length - 1];
            _accountVestings.pop();
        }
    }

    /// @notice Useful for frontend. Get an estimate exchange of $FUSD vs desired reserve.
    /// @param _reserve The asset to be used (ERC20)
    /// @param _amount The amount of $FUSD to mint
    /// @return toExchange Amount of reserve to exchange,
    /// @return amount True amount of $FUSD to be exchanged
    /// @return vested Any vesting created
    function getPraiseEstimates(address _reserve, uint256 _amount)
        external
        view
        reserveExists(_reserve)
        returns (
            uint256 toExchange,
            uint256 amount,
            uint256 vested
        )
    {
        Reserve storage reserve = reserves[_reserve];

        toExchange = reserve.reserveOracle.getExchangeRate(_amount);
        vested = (_amount * reserve.mintingInterestRate) / 10000;
        amount = _amount - vested;
    }

    /// @notice Check if a reserve was created
    /// @dev /!\ Careful of gas cost /!\
    /// @param _reserve The reserve to check
    /// @return exists A boolean of its existence
    function doesReserveExists(address _reserve) public view returns (bool exists) {
        for (uint256 i = 0; i < reserveAddresses.length; i++) {
            if (reserveAddresses[i] == _reserve) {
                exists = true;
                break;
            }
        }
    }

    /// @notice Get the conversion of $FUSD -> [[_reserve]]
    /// @param _reserve The output valuation
    /// @param _amount The amount of $FUSD to value
    /// @return The [[_reserve]] valuation for the given $FUSD
    function conversionRateFUSDToReserve(address _reserve, uint256 _amount)
        external
        view
        reserveExists(_reserve)
        returns (uint256)
    {
        return reserves[_reserve].reserveOracle.getExchangeRate(_amount);
    }

    /// @notice Get the conversion of [[_reserve]] -> $FUSD
    /// @param _reserve The input valuation
    /// @param _amount The amount of [[_reserve]] to value
    /// @return The $FUSD valuation for the given [[_reserve]]
    function conversionRateReserveToFUSD(address _reserve, uint256 _amount)
        external
        view
        reserveExists(_reserve)
        returns (uint256)
    {
        return (_amount * 10) / reserves[_reserve].reserveOracle.getExchangeRate(10);
    }

    /// @notice Withdraw [[_to]] a given [[_amount]] of [[_reserve]] and reset its freeReserves
    /// @dev Potential flaw of this tokenomics:
    /// - Ability to withdraw assets and break the burning mechanism.
    /// (suggestion: if reserve not immutable, compute a max amount withdrawable delta for a given reserve)
    /// @param _reserve The asset to be used (ERC20)
    /// @param _to The receiver
    /// @param _amount The amount to withdrawn
    function withdrawReserve(
        address _reserve,
        address _to,
        uint256 _amount
    ) external onlyCrown {
        require(address(reserves[_reserve].reserveOracle) != address(0), "King: reserve doesn't exists");
        IERC20(_reserve).transfer(_to, _amount);
        // Based on specs, reset behavior is wanted
        freeReserves[_reserve] = 0; // Reset freeReserve
        emit WithdrawReserve(_reserve, _to, _amount);
    }

    /// @notice Drain every reserve [[_to]] and reset all freeReserves
    /// @dev /!\ Careful of gas cost /!\
    /// @dev Potential flaw of this tokenomics:
    /// - Ability to withdraw assets and break the burning mechanism.
    /// (suggestion: if reserve not immutable, compute a max amount withdrawable delta for a given reserve)
    /// @param _to The receiver
    function withdrawAll(address _to) external onlyCrown {
        for (uint256 i = 0; i < reserveAddresses.length; i++) {
            IERC20 reserveERC20 = IERC20(reserveAddresses[i]);
            uint256 amount = reserveERC20.balanceOf(address(this));
            reserveERC20.transfer(_to, amount);
            freeReserves[reserveAddresses[i]] = 0; // Reset freeReserve
            emit WithdrawReserve(address(reserveERC20), _to, amount);
        }
    }

    /// @notice Withdraw a chosen amount of free reserve in the chosen reserve
    /// @param _reserve The asset to be used (ERC20)
    /// @param _to The receiver
    /// @param _amount The amount to withdrawn (in FUSD)
    /// @return assetWithdrawn The amount of asset withdrawn after the exchange rate
    function withdrawFreeReserve(
        address _reserve,
        address _to,
        uint256 _amount
    ) public onlyCrown returns (uint256 assetWithdrawn) {
        require(_amount <= freeReserves[_reserve], 'King: max amount exceeded');
        Reserve storage reserve = reserves[_reserve];
        assetWithdrawn = reserve.reserveOracle.getExchangeRate(_amount);
        freeReserves[_reserve] -= _amount;
        IERC20(_reserve).transfer(_to, assetWithdrawn);
    }

    function withdrawAllFreeReserve(address _reserve, address _to) external onlyCrown returns (uint256 assetWithdrawn) {
        assetWithdrawn = withdrawFreeReserve(_reserve, _to, freeReserves[_reserve]);
    }

    /// @notice Update the sWagmeKingdom address
    /// @param _sWagmeKingdom The new address
    function updateSWagmeKingdom(address _sWagmeKingdom) external onlyCrown {
        sWagmeKingdom = _sWagmeKingdom;
    }

    /// @notice Update the owner
    /// @param _newKing of the new owner
    function crownKing(address _newKing) external onlyCrown {
        crown = _newKing;
    }

    /// @notice Transfer an ERC20 to the king
    /// @param _erc20 The address of the token to transfer
    /// @param _to The address of the receiver
    /// @param _amount The amount to transfer
    function salvage(
        address _erc20,
        address _to,
        uint256 _amount
    ) external onlyCrown {
        IERC20(_erc20).transfer(_to, _amount);
    }

    /// @notice Withdraw the native currency to the king
    /// @param _to The address of the receiver
    /// @param _amount The amount to be withdrawn
    function withdrawNative(address payable _to, uint256 _amount) external onlyCrown {
        _to.transfer(_amount);
    }

    /// @notice Return the current list of reserves
    /// @return Return [[reserveAddresses]]
    function getReserveAddresses() external view returns (address[] memory) {
        return reserveAddresses;
    }

    /// @notice Return the current list of whitelisted reserve to be reproved
    /// @return Return [[reserveReproveWhitelistAddresses]]
    function getReserveReproveWhitelistAddresses() external view returns (address[] memory) {
        return reserveReproveWhitelistAddresses;
    }

    /// @dev Updated [[reserveReproveWhitelistAddresses]] when a reserve is updated or appended.
    /// Changes occurs only if needed. It is designed to be called only at the begining of a blessing [[bless()]]
    /// @param _reserve The reserve being utilized
    /// @param _reserveAddress The address of the reserve
    /// @param _isReproveWhitelisted The most updated version of reserve.isReproveWhitelisted
    function _updateReserveReproveWhitelistAddresses(
        Reserve memory _reserve,
        address _reserveAddress,
        bool _isReproveWhitelisted
    ) internal {
        // Check if it exists
        if (address(_reserve.reserveOracle) != address(0)) {
            // We'll act only if there was changes
            if (_reserve.isReproveWhitelisted != _isReproveWhitelisted) {
                // We'll add or remove it from reserveReproveWhitelistAddresses based on the previous param
                if (_isReproveWhitelisted) {
                    // Added to the whitelist
                    reserveReproveWhitelistAddresses.push(_reserveAddress);
                    emit UpdateReserveReproveWhitelistAddresses(_reserveAddress, true, false);
                } else {
                    // Remove it from the whitelist
                    // /!\ Gas cost /!\
                    for (uint256 i = 0; i < reserveReproveWhitelistAddresses.length; i++) {
                        if (reserveReproveWhitelistAddresses[i] == _reserveAddress) {
                            // Get the last element in the removed element
                            reserveReproveWhitelistAddresses[i] = reserveReproveWhitelistAddresses[
                                reserveReproveWhitelistAddresses.length - 1
                            ];
                            reserveReproveWhitelistAddresses.pop();
                            emit UpdateReserveReproveWhitelistAddresses(_reserveAddress, false, false);
                        }
                    }
                }
            }
        } else {
            // If the reserve is new, we'll add it to the whitelist only if it's whitelisted
            if (_isReproveWhitelisted) {
                reserveReproveWhitelistAddresses.push(_reserveAddress);
                emit UpdateReserveReproveWhitelistAddresses(_reserveAddress, true, true);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// 0xRektora

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

contract FUSD is ERC20Burnable {
    address public king;

    constructor(address _king) ERC20('Frog USD', 'FUSD') {
        king = _king;
    }

    modifier onlyKing() {
        require(msg.sender == king, 'FUSD: Only king is authorized');
        _;
    }

    function mint(address _account, uint256 _amount) public onlyKing {
        _mint(_account, _amount);
    }

    function claimCrown(address _newKing) external onlyKing {
        king = _newKing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
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
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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