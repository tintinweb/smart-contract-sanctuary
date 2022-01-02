// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./libraries/SafeMath.sol";
import "./DividendTracker.sol";

contract Olympia is ERC20, Ownable {
    using SafeMath for uint256;

    struct Fees {
        uint256 liquidityFeesPerThousand;
        uint256 marketingFeesPerThousand;
        uint256 teamFeesPerThousand;
        uint256 providerFeesPerThousand;
        uint256 reflectionFeesPerThousand;
    }
    
    address public _router;
    address public _pair;
    address public _dividendTracker;

    mapping (address => bool) public _automatedMarketMakerPairs;
    mapping (address => bool) public _isBlacklisted;
    mapping (address => bool) public _isExcludedFromFees;
    
    Fees private _buyFees;
    Fees private _sellFees;

    uint256 private _totalSupply = 100_000_000_000 * 10 ** 18;

    address public _deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public _marketingWallet = 0x5B556447f1ba310F87885489D405Ba1bf2e331c9;
    address public _teamWallet = 0x4BEb2021bdD32ac2E41C4005510a894b408fB93a;
    address public _providerWallet = 0x4BEb2021bdD32ac2E41C4005510a894b408fB93a;

    uint256 public _swapTokensAtAmount = 2_000_000 * 10 ** 18;

    uint256 public _gasForProcessing = 300_000;

    bool private _swapping;

    event UpdateDividendTracker(address indexed previousAddress, address indexed newAddress);
    event UpdateUniswapV2Router(address indexed previousAddress, address indexed newAddress);
    event UpdateMarketingWallet(address indexed previousWallet, address indexed newWallet);
    event UpdateTeamWallet(address indexed previousWallet, address indexed newWallet);
    event UpdateProviderWallet(address indexed previousWallet, address indexed newWallet);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed oldValue, uint256 indexed newValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);

    constructor() ERC20("Olympia", "OLP") {
        _mint(owner(), 100_000_000_000 * 10 ** 18);
    }

    function init(address dividendTracker, address uniswapV2Router02) external onlyOwner {
    	_dividendTracker = dividendTracker;
        _router = uniswapV2Router02;

        // Create a uniswap pair for this new token
        IUniswapV2Router02 router = IUniswapV2Router02(_router);
        _pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        _setAutomatedMarketMakerPair(_pair, true);

        // exclude from receiving dividends
        DividendTracker tracker = DividendTracker(payable(_dividendTracker));
        tracker.excludeFromDividends(_dividendTracker, true);
        tracker.excludeFromDividends(address(this), true);
        tracker.excludeFromDividends(owner(), true);
        tracker.excludeFromDividends(_deadWallet, true);
        tracker.excludeFromDividends(_router, true);

        // Buy fees
        _buyFees.reflectionFeesPerThousand = 3;
        _buyFees.marketingFeesPerThousand = 3;
        _buyFees.teamFeesPerThousand = 2;
        _buyFees.providerFeesPerThousand = 2;
        _buyFees.liquidityFeesPerThousand = 2;

        // Sell fees
        _sellFees.reflectionFeesPerThousand = 3;
        _sellFees.marketingFeesPerThousand = 5;
        _sellFees.teamFeesPerThousand = 2;
        _sellFees.providerFeesPerThousand = 2;
        _sellFees.liquidityFeesPerThousand = 2;

        // exclude from paying fees or having max transaction amount
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[_marketingWallet] = true;
        _isExcludedFromFees[_teamWallet] = true;
        _isExcludedFromFees[_providerWallet] = true;
        _isExcludedFromFees[address(this)] = true;
    }

    receive() external payable {
  	}

    function updateDividendTracker(address newTracker) external onlyOwner {
        require(newTracker != _dividendTracker, "Olympia: The dividend tracker already has that address");

        address previousTracker = _dividendTracker;
        DividendTracker newDividendTracker = DividendTracker(payable(newTracker));
        newDividendTracker.excludeFromDividends(address(newDividendTracker), true);
        newDividendTracker.excludeFromDividends(address(this), true);
        newDividendTracker.excludeFromDividends(owner(), true);
        newDividendTracker.excludeFromDividends(_deadWallet, true);
        newDividendTracker.excludeFromDividends(_router, true);
        _dividendTracker = newTracker;
        DividendTracker previousDividendTracker = DividendTracker(payable(previousTracker));
        previousDividendTracker.excludeFromDividends(address(previousDividendTracker), false);
        previousDividendTracker.excludeFromDividends(address(this), false);
        previousDividendTracker.excludeFromDividends(owner(), false);
        previousDividendTracker.excludeFromDividends(_deadWallet, false);
        previousDividendTracker.excludeFromDividends(_router, false);

        emit UpdateDividendTracker(previousTracker, newTracker);
    }

    function updateUniswapV2Router(address newRouter) external onlyOwner {
        require(newRouter != _router, "Olympia: The router already has that address");

        address previousRouter = _router;
        address previousPair = _pair;
        IUniswapV2Router02 router = IUniswapV2Router02(newRouter);
        address newPair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        _setAutomatedMarketMakerPair(newPair, true);
        _router = newRouter;
        _pair = newPair;
        _setAutomatedMarketMakerPair(previousPair, false);
        
        emit UpdateUniswapV2Router(previousRouter, newRouter);
    }

    function updateMarketingWallet(address payable newWallet) external onlyOwner {
        require(newWallet != _marketingWallet, "Olympia: The marketing wallet already has that address");

        address previousWallet = _marketingWallet;
        _isExcludedFromFees[newWallet] = true;
        _marketingWallet = newWallet;
        _isExcludedFromFees[previousWallet] = false;

        emit UpdateMarketingWallet(previousWallet, newWallet);
    }

    function updateTeamWallet(address payable newWallet) external onlyOwner {
        require(newWallet != _teamWallet, "Olympia: The team wallet already has that address");

        address previousWallet = _teamWallet;
        _isExcludedFromFees[newWallet] = true;
        _teamWallet = newWallet;
        _isExcludedFromFees[previousWallet] = false;

        emit UpdateTeamWallet(previousWallet, newWallet);
    }

    function updateProviderWallet(address payable newWallet) external onlyOwner {
        require(newWallet != _providerWallet, "Olympia: The provider wallet already has that address");

        address previousWallet = _providerWallet;
        _isExcludedFromFees[newWallet] = true;
        _providerWallet = newWallet;
        _isExcludedFromFees[previousWallet] = false;

        emit UpdateProviderWallet(previousWallet, newWallet);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != _pair, "Olympia: The PancakeSwap pair cannot be removed");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Olympia: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200_000 && newValue <= 500_000, "Olympia: _gasForProcessing must be between 200,000 and 500,000");
        require(newValue != _gasForProcessing, "Olympia: Cannot update _gasForProcessing to same value");
        emit GasForProcessingUpdated(_gasForProcessing, newValue);
        _gasForProcessing = newValue;
    }

    function setBuyFees(uint256 reflectionFeesPerThousand, uint256 marketingFeesPerThousand, uint256 liquidityFeesPerThousand) external onlyOwner {
        _buyFees.reflectionFeesPerThousand = reflectionFeesPerThousand;
        _buyFees.marketingFeesPerThousand = marketingFeesPerThousand;
        _buyFees.liquidityFeesPerThousand = liquidityFeesPerThousand;
    }

    function setSellFees(uint256 reflectionFeesPerThousand, uint256 marketingFeesPerThousand, uint256 liquidityFeesPerThousand) external onlyOwner {
        _sellFees.reflectionFeesPerThousand = reflectionFeesPerThousand;
        _sellFees.marketingFeesPerThousand = marketingFeesPerThousand;
        _sellFees.liquidityFeesPerThousand = liquidityFeesPerThousand;
    }

    function getBuyFees() public view returns
    (
        uint256 reflectionFeesPerThousand,
        uint256 liquidityFeesPerThousand,
        uint256 marketingFeesPerThousand,
        uint256 totalFeePerThousand
    ) {
        return (
            _buyFees.reflectionFeesPerThousand,
            _buyFees.liquidityFeesPerThousand,
            _buyFees.marketingFeesPerThousand,
            _buyFees.reflectionFeesPerThousand
                .add(_buyFees.liquidityFeesPerThousand)
                .add(_buyFees.marketingFeesPerThousand)
        );
    }

    function getSellFees() public view returns 
    (
        uint256 reflectionFeesPerThousand,
        uint256 liquidityFeesPerThousand,
        uint256 marketingFeesPerThousand,
        uint256 totalFeePerThousand
    ) {
        return (
            _sellFees.reflectionFeesPerThousand,
            _sellFees.liquidityFeesPerThousand,
            _sellFees.marketingFeesPerThousand,
            _sellFees.reflectionFeesPerThousand
                .add(_sellFees.liquidityFeesPerThousand)
                .add(_sellFees.marketingFeesPerThousand)
        );
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "Olympia: Transfer from the zero address");
        require(recipient != address(0), "Olympia: Transfer to the zero address");
        require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], 'Olympia: Blacklisted address');

        if (amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        bool isBuying = _automatedMarketMakerPairs[sender];
        (, uint256 liquidityFeesPerThousand, uint256 marketingFeesPerThousand, uint256 totalFeesPerThousand) = _getFees(isBuying);

		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

        if (canSwap && !_swapping && !_automatedMarketMakerPairs[sender] && sender != owner() && recipient != owner()) {
            _swapping = true;

            if (marketingFeesPerThousand > 0) {
                uint256 marketingTokens = contractTokenBalance.mul(marketingFeesPerThousand).div(totalFeesPerThousand);
                _swapAndSendToFee(marketingTokens);
            }

            if (liquidityFeesPerThousand > 0) {
                uint256 liquidityTokens = contractTokenBalance.mul(liquidityFeesPerThousand).div(totalFeesPerThousand);
                _swapAndLiquify(liquidityTokens);
            }

            uint256 sellTokens = balanceOf(address(this));
            _swapAndSendDividends(sellTokens);

            _swapping = false;
        }

        bool takeFees = !_swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFees = false;
        }

        if (takeFees) {
        	uint256 fees = amount.mul(totalFeesPerThousand).div(100);
        	amount = amount.sub(fees);

            super._transfer(sender, address(this), fees);
        }

        super._transfer(sender, recipient, amount);

        DividendTracker tracker = DividendTracker(payable(_dividendTracker));
        try tracker.setBalance(payable(sender), balanceOf(sender)) {} catch {}
        try tracker.setBalance(payable(recipient), balanceOf(recipient)) {} catch {}

        if (!_swapping) {
	    	uint256 gas = _gasForProcessing;

	    	try tracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} catch {}
        }
    }
    
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(_automatedMarketMakerPairs[pair] != value, "Olympia: Automated market maker pair is already set to that value");
        _automatedMarketMakerPairs[pair] = value;

        if (value) {
            DividendTracker tracker = DividendTracker(payable(_dividendTracker));
            tracker.excludeFromDividends(pair, true);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _getFees(bool isBuying) private view returns (uint256, uint256, uint256, uint256) {
        return isBuying ? getBuyFees() : getSellFees();
    }

    function _swapAndSendToFee(uint256 tokens) private {
        uint256 initialBNBBalance = address(this).balance;

        _swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialBNBBalance);
        payable(_marketingWallet).transfer(newBalance);
    }

    function _swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;
        _swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), _router, tokenAmount);

        IUniswapV2Router02 router = IUniswapV2Router02(_router);
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _swapAndSendDividends(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        _swapTokensForEth(tokens);
        uint256 dividends = (address(this).balance).sub(initialBalance);
        (bool success,) = _dividendTracker.call{value: dividends}("");
 
        if (success) {
   	 		emit SendDividends(tokens, dividends);
        }
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        IUniswapV2Router02 router = IUniswapV2Router02(_router);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), _router, tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Allowable.sol";
import "./DividendPayingToken.sol";
import "./libraries/IterableMapping.sol";

contract DividendTracker is Allowable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private _tokenHoldersMap;
    uint256 public _lastProcessedIndex;

    mapping (address => bool) public _excludedFromDividends;
    mapping (address => uint256) public _lastClaimTimes;

    uint256 public _claimWait;
    uint256 public _minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("Dividend_Tracker", "Olympia_Dividend_Tracker") {
    	_claimWait = 43_200;
        _minimumTokenBalanceForDividends = 100_000_000 * 10 ** 18;
    }

    function _transfer(address, address, uint256) internal override pure {
        require(false, "DividendTracker: No transfers allowed");
    }

    function withdrawDividend() public override pure {
        require(false, "DividendTracker: WithdrawDividend disabled. Use the 'claim' function on the main OLP contract.");
    }

    function excludeFromDividends(address account, bool enabled) external onlyAllowed {
    	require(_excludedFromDividends[account] != enabled, "DividendTracker: Account is already the value of 'enabled'");
    	_excludedFromDividends[account] = enabled;

    	_setBalance(account, 0);
    	_tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3_600 && newClaimWait <= 86_400, "DividendTracker: _claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != _claimWait, "DividendTracker: Cannot update _claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, _claimWait);
        _claimWait = newClaimWait;
    }

    function getClaimWait() external view returns(uint256) {
        return _claimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return _lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return _tokenHoldersMap.keys.length;
    }
    
    function setMinimumTokenBalanceForDividends(uint256 balance) external onlyOwner {
        _minimumTokenBalanceForDividends = balance * 10 ** 18;
    }

    function getAccount(address _account) public view returns (address account, int256 index, int256 iterationsUntilProcessed, uint256 withdrawableDividends, uint256 totalDividends, uint256 lastClaimTime, uint256 nextClaimTime, uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = _tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > _lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(_lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = _tokenHoldersMap.keys.length > _lastProcessedIndex ? _tokenHoldersMap.keys.length.sub(_lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = _lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(_claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function getAccountAtIndex(uint256 index) public view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
    	if (index >= _tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = _tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if (lastClaimTime > block.timestamp) {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= _claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyAllowed {
    	if (_excludedFromDividends[account]) {
    		return;
    	}

    	if (newBalance >= _minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		_tokenHoldersMap.set(account, newBalance);
    	} else {
            _setBalance(account, 0);
    		_tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = _tokenHoldersMap.keys.length;

    	if (numberOfTokenHolders == 0) {
    		return (0, 0, _lastProcessedIndex);
    	}

    	uint256 lastProcessedIndex = _lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while (gasUsed < gas && iterations < numberOfTokenHolders) {
    		lastProcessedIndex++;

    		if (lastProcessedIndex >= _tokenHoldersMap.keys.length) {
    			lastProcessedIndex = 0;
    		}

    		address account = _tokenHoldersMap.keys[lastProcessedIndex];

    		if (canAutoClaim(_lastClaimTimes[account])) {
    			if (processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if (gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	_lastProcessedIndex = lastProcessedIndex;

    	return (iterations, claims, _lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyAllowed returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if (amount > 0) {
    		_lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Allowable is Ownable {
    mapping (address => bool) private _allowables;

    event AllowableChanged(address indexed allowable, bool enabled);

    constructor() {
        _allow(_msgSender(), true);
    }

    modifier onlyAllowed() {
        require(_allowables[_msgSender()], "Allowable: caller is not allowed");
        _;
    }

    function allow(address allowable, bool enabled) public onlyAllowed {
        _allow(allowable, enabled);
    }

    function isAllowed(address allowable) public view returns (bool) {
        return _allowables[allowable];
    }

    function _allow(address allowable, bool enabled) internal {
        _allowables[allowable] = enabled;
        emit AllowableChanged(allowable, enabled);
    }

    function _transferOwnership(address newOwner) internal override {
        _allow(_msgSender(), false);
        super._transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeMathUint.sol";
import "./libraries/SafeMathInt.sol";
import "./interfaces/IDividendPayingTokenInterface.sol";
import "./interfaces/IDividendPayingTokenOptionalInterface.sol";

contract DividendPayingToken is ERC20, IDividendPayingTokenInterface, IDividendPayingTokenOptionalInterface {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 constant internal _magnitude = 2 ** 128;

    uint256 internal _magnifiedDividendPerShare;

    mapping(address => int256) internal _magnifiedDividendCorrections;
    mapping(address => uint256) internal _withdrawnDividends;

    uint256 public _totalDividendsDistributed;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    }

    receive() external payable {
        distributeDividends();
    }

    function distributeDividends() public override payable {
        require(totalSupply() > 0, "DividendPayingToken: Total supply should not be empty");

        if (msg.value > 0) {
            _magnifiedDividendPerShare = _magnifiedDividendPerShare.add((msg.value).mul(_magnitude) / totalSupply());
            emit DividendsDistributed(msg.sender, msg.value);

            _totalDividendsDistributed = _totalDividendsDistributed.add(msg.value);
        }
    }

    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            _withdrawnDividends[user] = _withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            (bool success,) = user.call{value: _withdrawableDividend, gas: 3000}("");

            if (!success) {
                _withdrawnDividends[user] = _withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return _totalDividendsDistributed;
    }

    function dividendOf(address owner) public view override returns(uint256) {
        return withdrawableDividendOf(owner);
    }

    function withdrawableDividendOf(address owner) public view override returns(uint256) {
        return accumulativeDividendOf(owner).sub(_withdrawnDividends[owner]);
    }

    function withdrawnDividendOf(address owner) public view override returns(uint256) {
        return _withdrawnDividends[owner];
    }

    function accumulativeDividendOf(address owner) public view override returns(uint256) {
        return _magnifiedDividendPerShare.mul(balanceOf(owner)).toInt256Safe()
            .add(_magnifiedDividendCorrections[owner]).toUint256Safe() / _magnitude;
    }

    function _transfer(address from, address to, uint256 value) internal virtual override {
        require(false, "DividendPayingToken: Should not perform any transfer");

        int256 _magCorrection = _magnifiedDividendPerShare.mul(value).toInt256Safe();
        _magnifiedDividendCorrections[from] = _magnifiedDividendCorrections[from].add(_magCorrection);
        _magnifiedDividendCorrections[to] = _magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        _magnifiedDividendCorrections[account] = _magnifiedDividendCorrections[account]
            .sub( (_magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        _magnifiedDividendCorrections[account] = _magnifiedDividendCorrections[account]
            .add( (_magnifiedDividendPerShare.mul(value)).toInt256Safe() );
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if (!map.inserted[key]) {
            return -1;
        }

        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IDividendPayingTokenInterface {
    function dividendOf(address owner) external view returns (uint256);
    function distributeDividends() external payable;
    function withdrawDividend() external;
    
    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IDividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address owner) external view returns (uint256);
    function withdrawnDividendOf(address owner) external view returns (uint256);
    function accumulativeDividendOf(address owner) external view returns (uint256);
}