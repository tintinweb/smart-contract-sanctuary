// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./TokenHolderRegister.sol";
import "./Olympia.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenClaimer is Ownable {
    TokenHolderRegister public _tokenHolderRegister;
    Olympia public _olympia;

    constructor(TokenHolderRegister tokenHolderRegister, Olympia olympia) {
        _tokenHolderRegister = tokenHolderRegister;
        _olympia = olympia;
    }

    function claimV2Tokens(address holder) public {
        uint256 amount = _tokenHolderRegister.getTokens(holder);
        require(amount > 0, 'TokenClaimer: Should transfer some tokens');

        _claimV2TokensByChunck(holder, amount);
    }

    function collectV2Tokens() public onlyOwner() {
        _olympia.transfer(owner(), _olympia.balanceOf(address(this)));
    }
    
    function _claimV2TokensByChunck(address holder, uint256 amount) private {
        uint256 remainingAmount = amount;
        uint256 maxTxAmount = _olympia._maxTxAmount();
        while (remainingAmount > 0) {
            uint256 amountToClaim = remainingAmount > maxTxAmount ? maxTxAmount : remainingAmount;
            if (_olympia.transfer(holder, amountToClaim)) {
                _tokenHolderRegister.removeTokens(holder);
            }
            remainingAmount -= amountToClaim;
        }
    }

    function tokenHolderRegisterAddress() public view returns (address) {
        return address(_tokenHolderRegister);
    }

    function olympiaAddress() public view returns (address) {
        return address(_olympia);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Allowable.sol";

contract TokenHolderRegister is Allowable {
    mapping (address => uint256) private _tokenholders;
    uint256 private _totalTokens;

    function addTokens(address holder, uint256 amount) public onlyAllowed() {
        require(amount > 0, 'TokenHolderRegister: Holder should have some tokens');
        _tokenholders[holder] += amount;
        _totalTokens += amount;
    }

    function removeTokens(address holder) public onlyAllowed() {
        require(_tokenholders[holder] > 0, 'TokenHolderRegister: Holder should have some tokens');
        _totalTokens -= _tokenholders[holder];
        delete _tokenholders[holder];
    }

    function getTokens(address holder) public view returns(uint256) {
        return _tokenholders[holder];
    }

    function getTotalTokens() public view returns(uint256) {
        return _totalTokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./libraries/SafeMath.sol";
import "./DividendTracker.sol";

contract Olympia is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public _uniswapV2Router02;
    address public _uniswapV2Pair;

    bool private _swapping;

    struct BuySellFee{
        uint256 reflectFee;
        uint256 marketFee;
        uint256 liquidFee;
    }
    
    BuySellFee _buyFees;
    BuySellFee _sellFees;

    DividendTracker public _dividendTracker;

    address public _deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 public _swapTokensAtAmount = 2000000 * 10 ** 18;

    mapping (address => bool) public _isBlacklisted;
    mapping (address => bool) public _isTxLimitExempt;
    mapping (address => bool) public _isExcludedFromAntiWhale;

    uint256 public _bnbRewardsFee = 3;
    uint256 public _liquidityFee = 2;
    uint256 public _marketingFee = 7;
    uint256 public _totalFees = _bnbRewardsFee.add(_liquidityFee).add(_marketingFee);

    uint256 private _totalSupply = 100_000_000_000 * 10 ** 18;
    uint256 public _maxTxAmount = _totalSupply.div(500); // 0.2%
    uint256 public _maxTokensPerAddress = _totalSupply.mul(6).div(1000);

    address public _marketingWallet = 0x5B556447f1ba310F87885489D405Ba1bf2e331c9;
    address public _teamWallet = 0x4BEb2021bdD32ac2E41C4005510a894b408fB93a;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public _gasForProcessing = 300_000;

     // exclude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public _automatedMarketMakerPairs;
    
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);

    constructor() ERC20("Olympia", "OLP") {
        _mint(owner(), 100_000_000_000 * 10 ** 18);
    }

    function init(DividendTracker dividendTracker, address uniswapV2Router02) public onlyOwner {
    	_dividendTracker = dividendTracker;
        _uniswapV2Router02 = IUniswapV2Router02(uniswapV2Router02);

        // Create a uniswap pair for this new token
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router02.factory()).createPair(address(this), _uniswapV2Router02.WETH());

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        _dividendTracker.excludeFromDividends(address(_dividendTracker), true);
        _dividendTracker.excludeFromDividends(address(this), true);
        _dividendTracker.excludeFromDividends(owner(), true);
        _dividendTracker.excludeFromDividends(_deadWallet, true);
        _dividendTracker.excludeFromDividends(address(_uniswapV2Router02), true);

        _isExcludedFromAntiWhale[_uniswapV2Pair] = true;
        _isExcludedFromAntiWhale[owner()] = true;
        _isExcludedFromAntiWhale[_deadWallet] = true;
        _isExcludedFromAntiWhale[address(this)] = true;
        _isExcludedFromAntiWhale[_marketingWallet] = true;
        _isExcludedFromAntiWhale[_teamWallet] = true;
        _isExcludedFromAntiWhale[address(_uniswapV2Router02)] = true;

        _isTxLimitExempt[owner()] = true;
        _isTxLimitExempt[address(this)] = true;
        
        _buyFees.reflectFee = 3;
        _buyFees.marketFee = 7;
        _buyFees.liquidFee = 2;

        _sellFees.reflectFee = 3;
        _sellFees.marketFee = 9;
        _sellFees.liquidFee = 2;

        // exclude from paying fees or having max transaction amount
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[_marketingWallet] = true;
        _isExcludedFromFees[_teamWallet] = true;
        _isExcludedFromFees[address(this)] = true;
    }

    receive() external payable {
  	}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(_dividendTracker), "Olympia: The dividend tracker already has that address");

        DividendTracker newDividendTracker = DividendTracker(payable(newAddress));

        newDividendTracker.excludeFromDividends(address(newDividendTracker), true);
        newDividendTracker.excludeFromDividends(address(this), true);
        newDividendTracker.excludeFromDividends(owner(), true);
        newDividendTracker.excludeFromDividends(_deadWallet, true);
        newDividendTracker.excludeFromDividends(address(_uniswapV2Router02), true);

        emit UpdateDividendTracker(newAddress, address(_dividendTracker));

        _dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(_uniswapV2Router02), "Olympia: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(_uniswapV2Router02));
        _uniswapV2Router02 = IUniswapV2Router02(newAddress);
        address uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router02.factory()).createPair(address(this), _uniswapV2Router02.WETH());
        _uniswapV2Pair = uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Olympia: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] memory accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner {
        _marketingWallet = wallet;
    }

    function setTeamWallet(address payable wallet) external onlyOwner {
        _teamWallet = wallet;
    }

    function setBnbRewardsFee(uint256 value) external onlyOwner {
        _bnbRewardsFee = value;
        _totalFees = _bnbRewardsFee.add(_liquidityFee).add(_marketingFee);
    }

    function setLiquiditFee(uint256 value) external onlyOwner {
        _liquidityFee = value;
        _totalFees = _bnbRewardsFee.add(_liquidityFee).add(_marketingFee);
    }

    function setMarketingFee(uint256 value) external onlyOwner {
        _marketingFee = value;
        _totalFees = _bnbRewardsFee.add(_liquidityFee).add(_marketingFee);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != _uniswapV2Pair, "Olympia: The PancakeSwap pair cannot be removed from _automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(_automatedMarketMakerPairs[pair] != value, "Olympia: Automated market maker pair is already set to that value");
        _automatedMarketMakerPairs[pair] = value;

        if (value) {
            _dividendTracker.excludeFromDividends(pair, true);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "Olympia: _gasForProcessing must be between 200,000 and 500,000");
        require(newValue != _gasForProcessing, "Olympia: Cannot update _gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, _gasForProcessing);
        _gasForProcessing = newValue;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setMaxTransactionPercentage(uint256 percentage) external onlyOwner {
        _maxTxAmount = _totalSupply.mul(percentage).div(1000);
    }

    function setMaxTokensPerAddressPercentage(uint256 percentage) external onlyOwner {
        _maxTokensPerAddress = _totalSupply.mul(percentage).div(1000);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        _isTxLimitExempt[holder] = exempt;
    }

    function setIsExcludedFromAntiWhale(address account, bool excluded) public onlyOwner {
        _isExcludedFromAntiWhale[account] = excluded;
    }

    function setBuyFees(uint256 reflectFee, uint256 marketFee, uint256 liquidFee) public onlyOwner {
        _buyFees.reflectFee = reflectFee;
        _buyFees.marketFee = marketFee;
        _buyFees.liquidFee = liquidFee;
    }

    function setSellFees(uint256 reflectFee, uint256 marketFee, uint256 liquidFee) public onlyOwner {
        _sellFees.reflectFee = reflectFee;
        _sellFees.marketFee = marketFee;
        _sellFees.liquidFee = liquidFee;
    }

    function setFeeOnBuy() private {
        _bnbRewardsFee = _buyFees.reflectFee;
        _marketingFee = _buyFees.marketFee;
        _liquidityFee = _buyFees.liquidFee;
        _totalFees = _bnbRewardsFee.add(_liquidityFee).add(_marketingFee);
    }

    function setFeeOnSell() private {
        _bnbRewardsFee = _sellFees.reflectFee;
        _marketingFee = _sellFees.marketFee;
        _liquidityFee = _sellFees.liquidFee;
        _totalFees = _bnbRewardsFee.add(_liquidityFee).add(_marketingFee);
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = _dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		_dividendTracker.processAccount(payable(msg.sender), false);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount <= _maxTxAmount || _isTxLimitExempt[from], "Transfer amount limit exceeded");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');
        require(_isExcludedFromAntiWhale[to] || balanceOf(to) + amount <= _maxTokensPerAddress, "Max tokens limit for this account exceeded. Or try lower amount");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

        if (canSwap && !_swapping && !_automatedMarketMakerPairs[from] && from != owner() && to != owner()) {
            _swapping = true;

            uint256 marketingTokens = contractTokenBalance.mul(_marketingFee).div(_totalFees);
            swapAndSendToFee(marketingTokens);

            uint256 swapTokens = contractTokenBalance.mul(_liquidityFee).div(_totalFees);
            swapAndLiquify(swapTokens);

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            _swapping = false;
        }

        bool takeFee = !_swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            
            if (!_automatedMarketMakerPairs[from]) {
                setFeeOnSell();
            }
            else {
                setFeeOnBuy();
            }

        	uint256 fees = amount.mul(_totalFees).div(100);
        	
        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try _dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try _dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!_swapping) {
	    	uint256 gas = _gasForProcessing;

	    	try _dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
    }

    function swapAndSendToFee(uint256 tokens) private  {
        uint256 initialBNBBalance = address(this).balance;

        swapTokensForEth(tokens);
        uint256 newBalance = (address(this).balance).sub(initialBNBBalance);
        payable(_marketingWallet).transfer(newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router02.WETH();

        _approve(address(this), address(_uniswapV2Router02), tokenAmount);

        // make the swap
        _uniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router02), tokenAmount);

        // add the liquidity
        _uniswapV2Router02.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapAndSendDividends(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 dividends = (address(this).balance).sub(initialBalance);
        (bool success,) = address(_dividendTracker).call{value: dividends}("");
 
        if (success) {
   	 		emit SendDividends(tokens, dividends);
        }
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
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

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
    	_claimWait = 43200;
        _minimumTokenBalanceForDividends = 100000000 * 10 ** 18;
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
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "DividendTracker: _claimWait must be updated to between 1 and 24 hours");
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
        _minimumTokenBalanceForDividends = balance * (10**18);
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

    		if(gasLeft > newGasLeft) {
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
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

interface IDividendPayingTokenInterface {
    function dividendOf(address owner) external view returns (uint256);
    function distributeDividends() external payable;
    function withdrawDividend() external;
    
    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address owner) external view returns (uint256);
    function withdrawnDividendOf(address owner) external view returns (uint256);
    function accumulativeDividendOf(address owner) external view returns (uint256);
}