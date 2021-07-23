// SPDX-License-Identifier: UNLICENSED"

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&%#####%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@%(((((((((((((((((((((((((((&@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@%(((((((((((((#%&@@@@@&%#(((((((((((((&@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@&((((((/((&@@@@@@@@@@@@@@@@@@@@@@@@@%(((((((((@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@&(((((((#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@((((((((@@@@@@@@@@@@@@
//@@@@@@@@@@@@(/////(@@@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%//////%@@@@@@@@@@@
//@@@@@@@@@@(/////(@@@@@/(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////#@@@@@@@@@
//@@@@@@@@%/////%@@@@@@@/&@@@@@@@@@@@@@@@#/(@@@@@@@@@@@@@@@@@@@@@@@@//////@@@@@@@@
//@@@@@@@//////@@@@@@@&/&@@@@@@@@@@@@@/////////&@@@@@@@@@@@@@@@@@@@@@&//////@@@@@@
//@@@@@@/////@@@@@@&//&@@@@@@@@@@@/////////////////@@@@@@@@@@@@@@@@@/(@#/////@@@@@
//@@@@@/////@@@@@@@@@@@@@@@@@@#////////@@@@@@@////////#@@@@@@@@@@@@#/@@@&/////@@@@
//@@@@/////@@@@@@@@@@@@@@@@////////#@@@@@@@@@@@@@&////////&@@@@@@@@@/(@@@%/////@@@
//@@@%////#@@@@@@@@@@@@/////////@@@@@@@@@@ @@@@@@@@@@(////////@@@@@@@&//#@/////@@@
//@@@*****@@@@@@@@@@@@@*****@@@@@@@@@@@@    %@@@@@@@@@@@@/****@@@@@@@@@@@@@****/@@
//@@@*****@@@@@@@@@@@@@*****@@@@@@@@@@@@     @@@@@@@@@@@@*****@@@@@@@@@@@@@*****@@
//@@@*****@@@@@@@@@@@@@%****#@@@@@@@@@@@     @@@@@@@@@@@&****(@@@@@@@@@@@@@*****@@
//@@@*******@@@@@@@@@@@@*****@@@@@@@@@@@     @@@@@@@@@@@*****@@@@@@@@@@@@@@*****@@
//@@@*****@*&@@@@@@@@@@@@*****@@@@@@@           @@@@@@@*****@@@@@@@@@@@@@@@*****@@
//@@@@*****@@@@@@@@@@@@@@@*****@@@@@@@@@((((%@@@@@@@@@*****@@@@@&(/(//@@@@*****@@@
//@@@@*****#@@@@@@@@@@@@@@@******@@@@@@@@@*@@@@@@@@@******@@@@@@*@@@@**@@/****/@@@
//@@@@@*,****@@@@@@@@@@@@@@@&******@@@@@@@@@@@@@@@******%@@@@@@@@,,,,#@@/*****@@@@
//@@@@@@(,,,,,@@@@@@@@@@@@@@@@&,,,,,,*@@@@@@@@@*,,,,,,#@@@@@@@@@@@@@@@@,,,,,,@@@@@
//@@@@@@@@,,,,,,&@@@@@@@@@@@@@@@@*,(@@@@@@@*,,,,,,,,@@@@@@@@@@@@@@@@@%,,,,,/@@@@@@
//@@@@@@@@@@,,,,,,,/@@@@@@@@@@@@@@@@@#,,,,,,,,,,/@@@@@@@@@@@@@@@@@@&,,,,,,@@@@@@@@
//@@@@@@@@@@@@&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&@@@@@@@@@@@@@@@@@@@@,,,,,,,#@@@@@@@@@
//@@@@@@@@@@@@@@@@%,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,%@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/,,,,,,,,,@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@,*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@,,,,.,,(%@@@@@@@@@@@&#*,,,,,,,,,,,,,,.,&@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#((///(#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// Welcome to BabySafemoon !
// Get free safemoon tokens by simply holding !

// Tokenomics : 7% Rewards to holders as Safemoon - 5 % to Liquidity Pool - 3 % to Marketing

pragma solidity ^0.6.2;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./BabySafemoonDividendTracker.sol";

contract BabySafemoon is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;

    BabySafemoonDividendTracker public dividendTracker;

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    address public Safemoon = address(0x8076C74C5e3F5852037F31Ff0093Eeb8c8ADd8D3); //Safemoon

    uint256 public swapTokensAtAmount = 2000000 * (10**18);
    
    //Anti-Whale System
    uint256 public maxWalletTokens =  1500000000 * (10**18);
    
    mapping(address => bool) public _isBlacklisted;

    uint256 public SafemoonRewardsFee = 7;
    uint256 public liquidityFee = 5;
    uint256 public marketingFee = 3;
    uint256 public totalFees = SafemoonRewardsFee.add(liquidityFee).add(marketingFee);

    address public _marketingWalletAddress = 0x0Dd3b3ad07cdb5640cf3aBAa94f3c35E449AEC15;


    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;


    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() public ERC20("Baby Safemoon", "BabySafemoon") {

    	dividendTracker = new BabySafemoonDividendTracker();


    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(deadWallet);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        //excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000000 * (10**18));
    }

    receive() external payable {

  	}

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "BabySafemoon: The dividend tracker already has that address");

        BabySafemoonDividendTracker newDividendTracker = BabySafemoonDividendTracker(payable(newAddress));

        require(newDividendTracker.owner() == address(this), "BabySafemoon: The new dividend tracker must be owned by the BabySafemoon token contract");

        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "BabySafemoon: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "BabySafemoon: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] memory accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner{
        _marketingWalletAddress = wallet;
    }

    function setSafemoonRewardsFee(uint256 value) external onlyOwner{
        SafemoonRewardsFee = value;
        totalFees = SafemoonRewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setLiquiditFee(uint256 value) external onlyOwner{
        liquidityFee = value;
        totalFees = SafemoonRewardsFee.add(liquidityFee).add(marketingFee);
    }

    function setMarketingFee(uint256 value) external onlyOwner{
        marketingFee = value;
        totalFees = SafemoonRewardsFee.add(liquidityFee).add(marketingFee);

    }


    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "BabySafemoon: The PanSafemoonSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function blacklistAddress(address account, bool value) external onlyOwner{
        _isBlacklisted[account] = value;
    }

    function removeMaxWallet() public onlyOwner {
         maxWalletTokens = 100000000000 * 10**18;
    }

    

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "BabySafemoon: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "BabySafemoon: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "BabySafemoon: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.balanceOf(account);
	}

	function excludeFromDividends(address account) external onlyOwner{
	    dividendTracker.excludeFromDividends(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function claim() external {
		dividendTracker.processAccount(msg.sender, false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], 'Blacklisted address');
        
        if (
            from != owner() &&
            to != owner() &&
            to != address(0xdead) &&
            to != uniswapV2Pair
        ) {
            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= maxWalletTokens, "Exceeds maximum wallet token amount.");
        }
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            uint256 marketingTokens = contractTokenBalance.mul(marketingFee).div(totalFees);
            swapAndSendToFee(marketingTokens);

            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
        	uint256 fees = amount.mul(totalFees).div(100);
        	if(automatedMarketMakerPairs[to]){
        	    fees += amount.mul(1).div(100);
        	}
        	amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {

	    	}
        }
    }

    function swapAndSendToFee(uint256 tokens) private  {

        uint256 initialSafemoonBalance = IERC20(Safemoon).balanceOf(address(this));

        swapTokensForSafemoon(tokens);
        uint256 newBalance = (IERC20(Safemoon).balanceOf(address(this))).sub(initialSafemoonBalance);
        IERC20(Safemoon).transfer(_marketingWalletAddress, newBalance);
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

    function swapTokensForSafemoon(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = Safemoon;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );

    }

    function swapAndSendDividends(uint256 tokens) private{
        swapTokensForSafemoon(tokens);
        uint256 dividends = IERC20(Safemoon).balanceOf(address(this));
        bool success = IERC20(Safemoon).transfer(address(dividendTracker), dividends);

        if (success) {
            dividendTracker.distributeSafemoonDividends(dividends);
            emit SendDividends(tokens, dividends);
        }
    }
}