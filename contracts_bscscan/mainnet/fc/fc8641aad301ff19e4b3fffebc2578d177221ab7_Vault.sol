// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./PiRewardToken.sol";
import "../libraries/helpers/Errors.sol";
import "../interfaces/IAddressesProvider.sol";
import "../interfaces/INFTList.sol";

/**
 * @title Vault contract
 * @dev The Vault of Market Market
 * - Holds fees are earned from transactions of the Market
 * - Owned by PiProtocol
 * @author PiProtocol
 **/

contract Vault is Initializable, ReentrancyGuard {
    uint256 public constant SAFE_NUMBER = 1e12;

    IAddressesProvider public addressesProvider;
    INFTList public nftList;

    // PiProtocol tokens balance
    // token address => fund
    mapping(address => uint256) internal _piFund;

    // Royalty of NFT Contract, will be paid to owner of NFT Contract
    // nftAddress => token address => amount royalty
    mapping(address => mapping(address => uint256)) internal _nftToRoyalty;
    mapping(address => address) internal _beneficiary;

    // RewardToken corresponding to each Token
    // token addres => rewardToken address
    mapping(address => address) internal _tokenToRewardToken;

    // User's reward token balance
    // user address => rewardToken address => balance
    mapping(address => mapping(address => uint256)) internal _rewardTokenBalance;

    // Duration of a halving cycle of a reward event
    uint256 internal _periodOfCycle;
    // The maximum number of halving of the reward event
    uint256 internal _numberOfCycle;
    // Reward event start time
    uint256 internal _startTime;
    // Reward rate of the first cycle of the reward event
    uint256 internal _firstRate;
    // Reward event is available
    bool internal _rewardIsActive;

    // Royalty numerator
    uint256 internal _royaltyNumerator;
    // Royalty denominator
    uint256 internal _royaltyDenominator;

    event Initialized(
        address indexed provider,
        uint256 numerator,
        uint256 denominator,
        string nativeToken
    );
    event RoyaltyUpdated(uint256 numerator, uint256 denominator);
    event WithdrawFund(address indexed token, uint256 amount, address indexed receiver);
    event Deposit(
        address indexed nftAddress,
        address indexed seller,
        address indexed buyer,
        uint256 amount,
        address token
    );
    event ClaimRoyalty(
        address indexed nftAddress,
        address indexed token,
        uint256 amount,
        address indexed receiver
    );
    event SetupRewardParameters(
        uint256 periodOfCycle,
        uint256 numberOfCycle,
        uint256 startTime,
        uint256 firstRate
    );

    event WithdrawRewardToken(
        address indexed user,
        address indexed rewardToken,
        uint256 amount,
        address indexed receiver
    );

    modifier onlyMarketAdmin() {
        require(addressesProvider.getAdmin() == msg.sender, Errors.CALLER_NOT_MARKET_ADMIN);
        _;
    }

    modifier onlyMarket() {
        require(addressesProvider.getMarket() == msg.sender, Errors.CALLER_NOT_MARKET);
        _;
    }

    /**
     * @dev Function is invoked by the proxy contract when the Vault contract is added to the
     * AddressesProvider of the market.
     * - Caching the address of the AddressesProvider in order to reduce gas consumption
     *   on subsequent operations
     * @param provider The address of the AddressesProvider
     * @param numerator The royalty numerator
     * @param denominator The royalty denominator
     **/
    function initialize(
        address provider,
        uint256 numerator,
        uint256 denominator,
        string memory nativeToken
    ) external initializer {
        require(denominator >= numerator, Errors.DEMONINATOR_NOT_GREATER_THAN_NUMERATOR);

        _royaltyNumerator = numerator;
        _royaltyDenominator = denominator;
        addressesProvider = IAddressesProvider(provider);
        nftList = INFTList(addressesProvider.getNFTList());

        string memory name = string(abi.encodePacked("rPI for: ", nativeToken));
        string memory symbol = string(abi.encodePacked("rPI_", nativeToken));

        PiRewardToken rewardTokenForNativeToken = new PiRewardToken(name, symbol);
        _tokenToRewardToken[address(0)] = address(rewardTokenForNativeToken);

        emit Initialized(provider, numerator, denominator, nativeToken);
    }

    function setupRewardToken(address token) external onlyMarket {
        if (_tokenToRewardToken[token] == address(0)) {
            string memory name = string(abi.encodePacked("rPI for ", ERC20(token).name()));
            string memory symbol = string(abi.encodePacked("rPI_", ERC20(token).symbol()));
            PiRewardToken newReward = new PiRewardToken(name, symbol);
            _tokenToRewardToken[token] = address(newReward);
        }
    }

    function setBeneficiary(address nftAddress, address beneficiary) external onlyMarketAdmin {
        _beneficiary[nftAddress] = beneficiary;
    }

    /**
     * @dev Deposit fee that Market receives the transaction of the user
     * - Can only be called by Market
     * @param nftAddress The address of nft
     * @param seller The address of seller
     * @param buyer The address of buyer
     * @param amount The amount that Market deposit
     * @param token The token that Market deposit
     */
    function deposit(
        address nftAddress,
        address seller,
        address buyer,
        address token,
        uint256 amount
    ) external payable onlyMarket {
        require(amount > 0, Errors.AMOUNT_IS_ZERO);
        if (token == address(0)) {
            require(amount == msg.value, Errors.NOT_ENOUGH_MONEY);
        } else {
            ERC20(token).transferFrom(msg.sender, address(this), amount);
        }

        uint256 forRoyalty = _calculateRoyalty(amount);

        if (forRoyalty > 0) {
            _nftToRoyalty[nftAddress][token] = _nftToRoyalty[nftAddress][token] + forRoyalty;
        }

        _piFund[token] = _piFund[token] + (amount - forRoyalty);

        if (_rewardIsActive == true) {
            uint256 currentRate = getCurrentRate();
            uint256 rewardTokenAmount = (amount * currentRate) / 1e18;
            if (rewardTokenAmount > 0) {
                address rewardToken = _tokenToRewardToken[token];
                _rewardTokenBalance[seller][rewardToken] =
                    _rewardTokenBalance[rewardToken][seller] +
                    rewardTokenAmount;
                _rewardTokenBalance[buyer][rewardToken] =
                    _rewardTokenBalance[rewardToken][seller] +
                    rewardTokenAmount;
            }
        }

        emit Deposit(nftAddress, seller, buyer, amount, token);
    }

    /**
     * @dev Withdraw PiProtocol Fund
     * - Can only be called by market admin]
     * @param token The token that admin wants to withdraw
     * @param amount The amount that admin wants to withdraw
     * @param receiver The address of receiver
     */
    function withdrawFund(
        address token,
        uint256 amount,
        address payable receiver
    ) external onlyMarketAdmin nonReentrant {
        require(amount <= _piFund[token], Errors.INSUFFICIENT_BALANCE);

        _piFund[token] = _piFund[token] - amount;

        if (token == address(0)) {
            receiver.transfer(amount);
        } else {
            ERC20(token).transfer(receiver, amount);
        }

        emit WithdrawFund(token, amount, receiver);
    }

    /**
     * @dev Claim royalty
     * - Can only be called by owner of nft contract
     * @param nftAddress The address of nft
     * @param token The token that contract owner wants to withdraw
     * @param amount The amount that contract owner to withdraw
     * @param receiver The address of receiver
     */
    function claimRoyalty(
        address nftAddress,
        address token,
        uint256 amount,
        address payable receiver
    ) external nonReentrant {
        require(_nftToRoyalty[nftAddress][token] >= amount, Errors.INSUFFICIENT_BALANCE);

        if (_beneficiary[nftAddress] != address(0)) {
            require(_beneficiary[nftAddress] == msg.sender, Errors.INVALID_BENEFICIARY);
        } else {
            NFTInfoType.NFTInfo memory info = nftList.getNFTInfo(nftAddress);
            require(info.registrant == msg.sender, Errors.INVALID_BENEFICIARY);
        }

        _nftToRoyalty[nftAddress][token] = _nftToRoyalty[nftAddress][token] - amount;

        if (token == address(0)) {
            receiver.transfer(amount);
        } else {
            ERC20(token).transfer(receiver, amount);
        }

        emit ClaimRoyalty(nftAddress, token, amount, receiver);
    }

    /**
     * @dev Withdraw reward token
     * - Can only be called by anyone
     * @param rewardToken The token that user wants to withdraw
     * @param amount The amount that user wants to withdraw
     * @param receiver The address of receiver
     */
    function withrawRewardToken(
        address rewardToken,
        uint256 amount,
        address receiver
    ) external nonReentrant {
        require(
            _rewardTokenBalance[msg.sender][rewardToken] >= amount && amount >= 0,
            Errors.INSUFFICIENT_BALANCE
        );

        _rewardTokenBalance[msg.sender][rewardToken] =
            _rewardTokenBalance[msg.sender][rewardToken] -
            amount;

        PiRewardToken(rewardToken).mint(receiver, amount);

        emit WithdrawRewardToken(msg.sender, rewardToken, amount, receiver);
    }

    function setupRewardParameters(
        uint256 periodOfCycle,
        uint256 numberOfCycle,
        uint256 startTime,
        uint256 firstRate
    ) external onlyMarketAdmin {
        require(periodOfCycle > 0, Errors.PERIOD_MUST_BE_GREATER_THAN_ZERO);
        require(block.timestamp <= startTime, Errors.INVALID_START_TIME);
        require(numberOfCycle > 0, Errors.NUMBER_OF_CYCLE_MUST_BE_GREATER_THAN_ZERO);
        require(firstRate > 0, Errors.FIRST_RATE_MUST_BE_GREATER_THAN_ZERO);

        _periodOfCycle = periodOfCycle;
        _numberOfCycle = numberOfCycle;
        _startTime = startTime;
        _firstRate = firstRate;
        _rewardIsActive = true;

        emit SetupRewardParameters(periodOfCycle, numberOfCycle, startTime, firstRate);
    }

    function updateRoyaltyParameters(uint256 numerator, uint256 denominator)
        external
        onlyMarketAdmin
    {
        require(denominator >= numerator, Errors.DEMONINATOR_NOT_GREATER_THAN_NUMERATOR);

        _royaltyNumerator = numerator;
        _royaltyDenominator = denominator;

        emit RoyaltyUpdated(numerator, denominator);
    }

    function getCurrentRate() public view returns (uint256) {
        uint256 currentPeriod = getCurrentPeriod();

        if (currentPeriod == 0) {
            return _firstRate;
        } else if (2**currentPeriod > _firstRate || currentPeriod > _numberOfCycle) {
            return 0;
        } else {
            return _firstRate / (2**currentPeriod);
        }
    }

    function getCurrentPeriod() public view returns (uint256) {
        return (block.timestamp - _startTime) / _periodOfCycle;
    }

    function getRewardToken(address token) external view returns (address) {
        return _tokenToRewardToken[token];
    }

    function getRoyalty(address nftAddress, address token) external view returns (uint256) {
        return _nftToRoyalty[nftAddress][token];
    }

    function getRewardTokenBalance(address user, address rewardToken)
        external
        view
        returns (uint256)
    {
        return _rewardTokenBalance[user][rewardToken];
    }

    function getPiFund(address token) external view returns (uint256) {
        return _piFund[token];
    }

    function getRoyaltyParameters() external view returns (uint256, uint256) {
        return (_royaltyNumerator, _royaltyDenominator);
    }

    function checkRewardIsActive() external view returns (bool) {
        if (_rewardIsActive == false) {
            return _rewardIsActive;
        } else {
            return (getCurrentRate() >= 0);
        }
    }

    function _calculateRoyalty(uint256 amount) internal view returns (uint256) {
        uint256 royaltyAmount = ((amount * SAFE_NUMBER * _royaltyNumerator) / _royaltyDenominator) /
            SAFE_NUMBER;
        return royaltyAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../libraries/helpers/Errors.sol";

contract PiRewardToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1e26;

    modifier supplyIsAvailable(uint256 amount) {
        require(totalSupply() + amount <= MAX_SUPPLY, Errors.SUPPLY_IS_NOT_AVAILABLE);
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address account, uint256 amount) external onlyOwner supplyIsAvailable(amount) {
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Errors {
    // common errors
    string public constant CALLER_NOT_MARKET_ADMIN = "Caller is not the market admin"; // 'The caller must be the market admin'
    string public constant CALLER_NOT_MARKET = "Caller is not the market"; // 'The caller must be Market'
    string public constant CALLER_NOT_NFT_OWNER = "Caller is not nft owner"; // 'The caller must be the owner of nft'
    string public constant CALLER_NOT_SELLER = "Caller is not seller"; // 'The caller must be the seller'
    string public constant CALLER_IS_SELLER = "Caller is seller"; // 'The caller must be not the seller'
    string public constant CALLER_NOT_CONTRACT_OWNER = "Caller is not contract owner"; // 'The caller must be contract owner'

    string public constant CALLER_NOT_CREATIVE_STUDIO = "Caller is not creative studio"; // 'The caller must be creative studio'

    string public constant REWARD_TOKEN_BE_NOT_SET = "Reward token be not set"; // 'The caller must be contract owner'
    string public constant REWARD_ALREADY_SET = "Reward already set"; // 'The caller must be contract owner'

    string public constant INVALID_START_TIME = "Invalid start time"; // 'Invalid start time'
    string public constant PERIOD_MUST_BE_GREATER_THAN_ZERO = "Period must be greater than zero"; // 'Period must be greater than zero"'
    string public constant NUMBER_OF_CYCLE_MUST_BE_GREATER_THAN_ZERO =
        "Number of cycle must be greater than zero"; // 'Number of cycle must be greater than zero'
    string public constant FIRST_RATE_MUST_BE_GREATER_THAN_ZERO =
        "First rate must be greater than zero"; // 'First rate must be greater than zero'

    string public constant SUPPLY_IS_NOT_AVAILABLE = "Supply is not available"; // 'Invalid start time'

    string public constant NFT_NOT_CONTRACT = "NFT address is not contract"; // 'The address must be contract address'
    string public constant NFT_ALREADY_REGISTERED = "NFT already registered"; // 'The nft already registered'
    string public constant NFT_NOT_REGISTERED = "NFT is not registered"; // 'The nft not registered'
    string public constant NFT_ALREADY_ACCEPTED = "NFT already accepted"; // 'The nft not registered'
    string public constant NFT_NOT_ACCEPTED = "NFT is not accepted"; // 'The nft address muse be accepted'
    string public constant NFT_NOT_APPROVED_FOR_MARKET = "NFT is not approved for Market"; // 'The nft must be approved for Market'

    string public constant SELL_ORDER_NOT_ACTIVE = "Sell order is not active"; // 'The sell order must be active'
    string public constant SELL_ORDER_DUPLICATE = "Sell order is duplicate"; // 'The sell order must be unique'

    string public constant NOT_ENOUGH_MONEY = "Send not enough token"; // 'The msg.value must be equal amount'
    string public constant VALUE_NOT_EQUAL_PRICE = "Msg.value not equal price"; // 'The msg.value must equal price'
    string public constant DEMONINATOR_NOT_GREATER_THAN_NUMERATOR =
        "Demoninator not greater than numerator"; // 'The fee denominator must be greater than fee numerator'

    string public constant RANGE_IS_INVALID = "Range is invalid"; // 'The range must be valid'

    string public constant PRICE_NOT_CHANGE = "Price is not change"; // 'The new price must be not equal price'
    string public constant INSUFFICIENT_BALANCE = "Insufficient balance"; // 'The fund must be equal or greater than amount to withdraw'

    string public constant PARAMETERS_NOT_MATCH = "The parameters are not match"; // 'The parameters must be match'
    string public constant EXCHANGE_ORDER_DUPLICATE = "Exchange order is duplicate"; // 'The exchange order must be unique'
    string public constant PRICE_IS_ZERO = "Price is zero"; // 'The new price must be greater than zero'
    string public constant TOKEN_ALREADY_ACCEPTED = "Token already accepted"; // 'Token already accepted'
    string public constant TOKEN_ALREADY_REVOKED = "Token already revoked"; // 'Token must be accepted'
    string public constant TOKEN_NOT_ACCEPTED = "Token is not accepted"; // 'Token is not accepted'
    string public constant AMOUNT_IS_ZERO = "Amount is zero"; // 'Amount must be accepted'
    string public constant AMOUNT_IS_NOT_ENOUGH = "Amount is not enough"; // 'Amount is not enough'
    string public constant AMOUNT_IS_NOT_EQUAL_ONE = "Amount is not equal 1"; // 'Amount must equal 1'
    string public constant INVALID_CALLDATA = "Invalid call data"; // 'Invalid call data'
    string public constant INVALID_DESTINATION = "Invalid destination"; // 'Invalid destination id'
    string public constant INVALID_BENEFICIARY = "Invalid beneficiary";
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title Interface of AddressesProvider contract
 * - Owned by the PiProtocol
 * @author PiProtocol
 **/
interface IAddressesProvider {
    function setAddress(
        bytes32 id,
        address newAddress,
        bytes memory params
    ) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function setAddress(bytes32 id, address newAddress) external;

    function getNFTList() external view returns (address);

    function setNFTListImpl(address ercList, bytes memory params) external;

    function getMarket() external view returns (address);

    function setMarketImpl(address market, bytes memory params) external;

    function getSellOrderList() external view returns (address);

    function setSellOrderListImpl(address sellOrderList, bytes memory params) external;

    function getExchangeOrderList() external view returns (address);

    function setExchangeOrderListImpl(address exchangeOrderList, bytes memory params) external;

    function getVault() external view returns (address);

    function setVaultImpl(address vault, bytes memory params) external;

    function getCreativeStudio() external view returns (address);

    function setCreativeStudioImpl(address creativeStudio, bytes memory params) external;

    function getAdmin() external view returns (address);

    function setAdmin(address admin) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../libraries/types/NFTInfoType.sol";

/**
 * @title Interface of NFTList contract
 * - Owned by the PiProtocol
 * @author PiProtocol
 **/
interface INFTList {
    function registerNFT(address nftAddress, bool isErc1155) external;

    function acceptNFT(address nftAddress) external;

    function revokeNFT(address nftAddress) external;

    function isERC1155(address nftAddress) external view returns (bool);

    function addNFTDirectly(
        address nftAddress,
        bool isErc1155,
        address registrant
    ) external;

    function getNFTInfo(address nftAddress) external view returns (NFTInfoType.NFTInfo memory);

    function getNFTCount() external view returns (uint256);

    function getAcceptedNFTs() external view returns (address[] memory);

    function isAcceptedNFT(address nftAddress) external view returns (bool);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library NFTInfoType {
    struct NFTInfo {
        // the id of the nft in array
        uint256 id;
        // nft address
        address nftAddress;
        // is ERC1155
        bool isERC1155;
        // is registered
        bool isRegistered;
        // is accepted by admin
        bool isAccepted;
        // registrant
        address registrant;
    }
}