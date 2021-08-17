// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./VoldyMetaData.sol";

contract Voldy is Ownable, VoldyMetaData {
	event swapAndLiquify(
		uint256 tokensSwapped,
		uint256 ethReceived,
		uint256 tokensIntoLiqudity
	);
	event swapAndLiquifyStateUpdate(bool state);

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    address[] private _excluded;

	/**
	 *@dev Adds the Address library utility methods to the type {address}.
	 */
	using Address for address;

	/**
	 *@dev the maximum uint256 value in solidity, which is used to convert the total supply of tokens to reflections for the reward mechanism.
	 */
	uint256 private constant MAX_INT_VALUE = type(uint256).max;
	
	uint256 private _tokenSupply = 40000000000000 * 10**18;
	/**
	 *@dev Convert the total supply to reflections with perfect rouding using the maximum uint256 as the numerator.
	 */
	uint256 private _reflectionSupply = (MAX_INT_VALUE -
		(MAX_INT_VALUE % _tokenSupply));


	/**
	 *@dev The total amount of fees paid by the users.
	 */
	uint256 private _totalTokenFees;
	uint256 private _previousFees;

    // sells have higher fees
    uint256 public sellFeeIncreaseFactor = 120;
    
    address public presaleAddress = address(0);
    
    address public presaleRouter = address(0xdead);


	/**
	 *@dev The transaction fee users will incur upon selling the token. 2 percent of the principal.
	 */
	uint256 public taxFee = 5;
	/**
	 *@dev The wallet which holds the account balance in reflections.
	 */
	mapping(address => uint256) private _reflectionBalance;

	/**
	 *@dev Accounts which are excluded from paying txs fees.
	 */
	mapping(address => bool) public _isExcludedFromFees;
	
    mapping (address => bool) private _isExcluded;

	/**
	 *@dev Contains the allowances a parent account has provided to children accounts in reflections;
	 */
	mapping(address => mapping(address => uint256)) private _allowances;

	/**
	 *@dev A maximum amount that can be transfered at once. Which is equivalent to 0.1% of the total supply.
	 */
	uint256 public maxTxAmount = 40000000000 * 10**18;

	/**
	 *@dev Number of tokens needed to provide liquidity to the pool
	 */
	uint256 private _numberTokensSellToAddToLiquidity = 50000000000 * 10**18;

	/**
	 *@dev State indicating that we are in a liquefaction process to prevent stacking liquefaction events.
	 */
	bool swapAndLiquifyingInProgress;

	/**
	 *@dev Variable to allow the owner to enable or disable liquefaction  events
	 */
	bool public isSwapAndLiquifyingEnabled = false;

	bool public startTrading = false;

	bool public catchWhales = true;

	IUniswapV2Router02 public uniswapV2Router;
	address public uniswapV2WETHPair;

	address public Marketing;

	constructor(address routerAddress, address MarketingAddress) {
		/**
		 *@dev Gives all the reflection to the deplyer (the first owner) of the contract upon creation.
		 */
		_reflectionBalance[_msgSender()] = _reflectionSupply;

		// Tells solidity this address follows the IUniswapV2Router interface
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);


		// Creates a pair between our token and WETH and saves the address in a state variable
		uniswapV2WETHPair = IUniswapV2Factory(_uniswapV2Router.factory())
			.createPair(address(this), _uniswapV2Router.WETH());

		// Saves the UniswapV2Router in a state variable
		uniswapV2Router = _uniswapV2Router;

		Marketing = MarketingAddress;

		_isExcludedFromFees[owner()] = true;
		_isExcludedFromFees[address(this)] = true;
		_isExcludedFromFees[MarketingAddress] = true;
		_isExcludedFromFees[presaleAddress] = true;
		_isExcludedFromFees[presaleRouter] = true;
        _isExcluded[presaleAddress] = true;
		_isExcluded[presaleRouter] = true;


		emit Transfer(address(0), _msgSender(), _tokenSupply);
	}

	/**
	 *@dev Tell the contract we are swapping
	 */
	modifier lockTheSwap {
		swapAndLiquifyingInProgress = true;
		_;
		swapAndLiquifyingInProgress = false;
	}

	/**
	 *@dev returns the total supply of tokens.
	 */
	function totalSupply() external view override returns (uint256) {
		return _tokenSupply;
	}

	/**
	 *@dev Returns the rate betweenthe total reflections and the total tokens.
	 */
	function _getRate() private view returns (uint256) {
		return _reflectionSupply / _tokenSupply;
	}

	/**
	 *@dev Converts an amount of tokens to reflections using the current rate.
	 */
	function _reflectionFromToken(uint256 amount)
		private
		view
		returns (uint256)
	{
		require(
			_tokenSupply >= amount,
			"You cannot own more tokens than the total token supply"
		);
		return amount * _getRate();
	}

	/**
	 *@dev Converts an amount of reflections to tokens using the current rate.
	 */
	function _tokenFromReflection(uint256 reflectionAmount)
		private
		view
		returns (uint256)
	{
		require(
			_reflectionSupply >= reflectionAmount,
			"Cannot have a personal reflection amount larger than total reflection"
		);
		return reflectionAmount / _getRate();
	}
	    function excludeFromReward(address account) public onlyOwner() {
        require(account != 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F, 'We can not exclude Pancake router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = _tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }


	/**
	 *@dev returns the total tokens a user holds. It first finds the reflections and converts to tokens to reflect the rewards the user has accrued over time.
	 * if the account does not receive rewards. It returns the balance from the token balance.
	 */
	function balanceOf(address account) public view override returns (uint256) {
		return _tokenFromReflection(_reflectionBalance[account]);
	}

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
	function totalFees() external view returns (uint256) {
		return _totalTokenFees;
	}

	/**
	 *@dev It allows a non excluded account to airdrop to other users.
	 */
	function deliver(uint256 amount) external {
		address sender = _msgSender();
		uint256 reflectionAmount = _reflectionFromToken(amount);
		_reflectionBalance[sender] =
			_reflectionBalance[sender] -
			reflectionAmount;
		_reflectionSupply -= reflectionAmount;
		_totalTokenFees += amount;
	}
	/**
	 *@dev Removes all fees and saves them to be reinstated at a later date.
	 */
	function removeAllFees() private {
	    _previousFees = taxFee;
		if (taxFee == 0) return;

		taxFee = 0;
	}
	function sellFee() private {
	    _previousFees = taxFee;
	    
     taxFee = (taxFee * sellFeeIncreaseFactor) / 100;
	}
	
	/**
	 *@dev Restores the fees to their previous values.
	 */
	function restoreAllFees() private {
		taxFee = _previousFees;
	}
	
	function changeAllFees(uint256 amount) external onlyOwner {
	    require(amount >= 0 && amount <= 10, "VoldyToken: TaxFee must be updated to between 0 and 10 %");
		taxFee = amount;
		_previousFees = amount;
	}
	
	function changeSellFee(uint256 amount) external onlyOwner {
	    require(amount >= 100 && amount <= 150, "VoldyToken: SellFee must be updated to between 100 and 150.");
		sellFeeIncreaseFactor = amount;
	}

	/**
	 *@dev Gives the owner of the contract control if the logic to add liquidity to the pool is enabled or not.
	 */
	function enableSwapAndLiquifyingState() external onlyOwner() {
		isSwapAndLiquifyingEnabled = true;
		emit swapAndLiquifyStateUpdate(true);
	}

	/**
	 *@dev Calculates a fee final amount based on a ratio.
	 *important This funciton only works with values based on token supply and NOT reflection supply.
	 */
	function _calculateFee(uint256 amount, uint256 fee)
		private
		pure
		returns (uint256)
	{
		return (amount * fee) / 100;
	}

	/**
	 *@dev Returns the final amount for the tax.
	 *important This function only works with values based on token supply and NOT reflection supply.
	 */
	function _calculateTax(uint256 amount) private view returns (uint256) {
		return _calculateFee(amount, taxFee);
	}
	/**
	 *@dev Updates the value of the total fees paid and reduces the reflection supply to reward all holders.
	 */
	function _reflectFee(uint256 rfee, uint256 fee) private {
		_reflectionSupply -= rfee;
		_totalTokenFees += fee + fee + fee;
	}

	/**
	 *@dev Stores the liquidity fee in the contract's address
	 */
	function _takeLiquidity(uint256 amount) private {
		_reflectionBalance[address(this)] =
			_reflectionBalance[address(this)] +
			amount;
	}

	/**
	 *@dev This is used to recieve ETH from uniswapv2router when swaping.
	 */
	receive() external payable {}

  	function whitelistDxSale(address _presaleAddress, address _presaleRouter) public onlyOwner {
  	    presaleAddress = _presaleAddress;
  	    presaleRouter = _presaleRouter;
        _isExcludedFromFees[_presaleAddress] = true;
		_isExcludedFromFees[_presaleRouter] = true;
		_isExcluded[_presaleRouter] = true;
		_isExcluded[_presaleAddress] = true;
  	}
	/**
	 *@dev Allows a user to transfer his reflections to another user. It taxes the sender by the tax fee while inflating the all tokens value.
	 */
	function _transferToken(
		address sender,
		address recipient,
		uint256 amount,
		bool removeFees
	) private {
		// If this is a feeless transaction. Remove all fees and store them.
		if (removeFees) removeAllFees();
		if (recipient == uniswapV2WETHPair && sender != owner()) sellFee();
		uint256 rAmount = _reflectionFromToken(amount);
		if (
			catchWhales &&
			recipient != uniswapV2WETHPair &&
			sender != owner() &&
			recipient != owner() &&
			sender != presaleAddress &&
	    	sender != presaleRouter &&
	    	recipient != address(0xdead) &&
	    	recipient != address(0)
		) {
			require(
				amount < 600000000000 * 10**18,
				"No whales allowed"
			);
		}
        
		// Because this account comes from a excluded account to an excluded. We only to reduce it's reflections and tokens.
		_reflectionBalance[sender] = _reflectionBalance[sender] - rAmount;

		// Calculates transaction fee
		uint256 tax = _calculateTax(amount);
		uint256 rTax = _reflectionFromToken(tax);

		// Since the recipient is also  excluded. We need to update his reflections and tokens.
		_reflectionBalance[recipient] =
			_reflectionBalance[recipient] +
			rAmount -
			rTax -
			rTax -
			rTax;

		_reflectionBalance[Marketing] = _reflectionBalance[Marketing] + rTax;

		_takeLiquidity(rTax);
		_reflectFee(rTax, tax);

		emit Transfer(sender, recipient, amount - tax * 3);


		// Restores all fees if they were disabled.
		//if (recipient == uniswapV2WETHPair) restoreAllFees();
        if (recipient == uniswapV2WETHPair && sender != owner()) restoreAllFees();
		if (removeFees) restoreAllFees();

	}

	/**
	 *@dev buys ETH with tokens stored in this contract
	 */
	function _swapTokensForEth(uint256 tokenAmount) private {
		// generate the uniswap pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();


		_approve(address(this), address(uniswapV2Router), tokenAmount);

		// make the swap
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}
	
	/**
	 *@dev Adds equal amount of eth and tokens to the ETH liquidity pool
	 */
	function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
		// approve token transfer to cover all possible scenarios
		_approve(address(this), address(uniswapV2Router), tokenAmount);

		// add the liquidity
		uniswapV2Router.addLiquidityETH{ value: ethAmount }(
			address(this),
			tokenAmount,
			0, // slippage is unavoidable
			0, // slippage is unavoidable
			address(0),
			block.timestamp
		);
	}

	function _swapAndLiquify() private lockTheSwap {
		// split the contract token balance into halves
		uint256 half = _numberTokensSellToAddToLiquidity / 2;
		uint256 otherHalf = _numberTokensSellToAddToLiquidity - half;

		uint256 initialETHContractBalance = address(this).balance;

		// Buys ETH at current token price
		_swapTokensForEth(half);

		// This is to make sure we are only using ETH derived from the liquidity fee
		uint256 ethBought = address(this).balance - initialETHContractBalance;

		// Add liquidity to the pool
		_addLiquidity(otherHalf, ethBought);

		emit swapAndLiquify(half, ethBought, otherHalf);
	}

	/**
    @dev Function to enable trading
   */
	function enableTrading() external onlyOwner() {
		startTrading = true;
	}

	/**
	@dev Function to allow holders to have more than 1.5% of tokens
	 */
	function freeWhales(bool isEnabled) external onlyOwner() {
		catchWhales = isEnabled;
	}

	/**
	 *@dev This function first adds liquidity to the pool, then transfers tokens between accounts
	 */
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) private {
		require(
			sender != address(0),
			"ERC20: Sender cannot be the zero address"
		);
		require(
			recipient != address(0),
			"ERC20: Recipient cannot be the zero address"
		);
		require(amount > 0, "Transfer amount must be greater than zero");
		if (sender != owner() &&
		recipient != owner() &&
		sender != presaleAddress &&
		sender != presaleRouter &&
		recipient != address(0xdead) &&
		recipient != address(0)
) {
			require(
				amount <= maxTxAmount,
				"Transfer amount exceeds the maxTxAmount."
			);

			require(startTrading, "Trading is not enabled.");
		}
		// Condition 1: Make sure the contract has the enough tokens to liquify
		// Condition 2: We are not in a liquefication event
		// Condition 3: Liquification is enabled
		// Condition 4: It is not the uniswapPair that is sending tokens
        // only whitelisted addresses can make transfers after the fixed-sale has started
        // and before the public presale is over

		if (
			balanceOf(address(this)) >= _numberTokensSellToAddToLiquidity &&
			!swapAndLiquifyingInProgress &&
			isSwapAndLiquifyingEnabled &&
			sender != uniswapV2WETHPair
		) _swapAndLiquify();

		_transferToken(
			sender,
			recipient,
			amount,
			_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]
		);

		
	}

	/**
	 *@dev Gives allowance to an account
	 */
	function _approve(
		address owner,
		address beneficiary,
		uint256 amount
	) private {
		require(
			beneficiary != address(0),
			"The burn address is not allowed to receive approval for allowances."
		);
		require(
			owner != address(0),
			"The burn address is not allowed to approve allowances."
		);

		_allowances[owner][beneficiary] = amount;
		emit Approval(owner, beneficiary, amount);
	}

	function transfer(address recipient, uint256 amount)
		external
		override
		returns (bool)
	{
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function approve(address beneficiary, uint256 amount)
		external
		override
		returns (bool)
	{
		_approve(_msgSender(), beneficiary, amount);
		return true;
	}

	/**
	 *@dev It allows an account to transfer it's allowance to any other account;
	 */
	function transferFrom(
		address provider,
		address beneficiary,
		uint256 amount
	) external override returns (bool) {
		_transfer(provider, beneficiary, amount);
		_approve(
			provider,
			_msgSender(),
			_allowances[provider][_msgSender()] - amount
		);
		return true;
	}

	/**
	 *@dev Shows the allowance of a beneficiary in tokens.
	 */
	function allowance(address owner, address beneficiary)
		external
		view
		override
		returns (uint256)
	{
		return _allowances[owner][beneficiary];
	}

	/**
	 *@dev Increases the allowance of a beneficiary
	 */
	function increaseAllowance(address beneficiary, uint256 amount)
		external
		returns (bool)
	{
		_approve(
			_msgSender(),
			beneficiary,
			_allowances[_msgSender()][beneficiary] + amount
		);
		return true;
	}

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFees[account] = true;
    }
    
        function includeInFee(address account) public onlyOwner {
        _isExcludedFromFees[account] = false;
    }
    
        function ChangeRouterAddress(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2WETHPair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
    }
    
        function changeMarketingWallet(address newWalletMarketing) public onlyOwner() {
        Marketing = newWalletMarketing;
    }
    
	/**
	 *@dev Decreases the allowance of a beneficiary
	 */
	function decreaseAllowance(address beneficiary, uint256 amount)
		external
		returns (bool)
	{
		_approve(
			_msgSender(),
			beneficiary,
			_allowances[_msgSender()][beneficiary] - amount
		);
		return true;
	}
}