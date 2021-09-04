// SPDX-License-Identifier: MIT

// This contract, DWClient, is a demonstration of one way to interface with the DogWalker contract.
// You can use this code as an example for building a token that gives DrunkDoge rewards.
//
// There are three aspects of interfacing with DogWalker that we demonstrate here:
//
// 1) DogWalker must be informed whenever the balance of any DWClient holder changes.  See the uses
//    of "clientMint" and "clientBurn" below.
//
// 2) We don't want to pay DrunkDoge rewards to every holder of this contract.  In particular,
//    we don't want to pay rewards to the liqudity pool (which holds a bunch of DWClient tokens),
//    or to the owner of DWToken itself.  To manage this, we create a second contract, called
//    DividendTracker below.  DividendTracker balances are identical to the main DWClient contract,
//    except that we don't give DividendTracker tokens to DWClient holders that we don't want to
//    earn DrunkDoge rewards.  This pattern is typical for dividend-paying tokens.
//
//    IMPORTANT: Because DividendTracker actually does the interfacing with DogWalker, it is the
//    contract that must be authorized for DogWalker - not the main DWClient contract.
//
// 3) For DWClient, we choose to automatically pay holders their DrunkDoge rewards.  You could
//    alternatively make holders claim those rewards explicitly through a DApp.  These automatic
//    payouts occur every time there is a transfer of DWClient tokens, using the "process"
//    function in DividendTracker.
//
// There are some things that dividend paying tokens often do that we don't bother to demonstrate
// here, for simplicity.  For example:
// - We don't have minimum number of DWClient tokens that you need to hold to earn DrunkDoge
//   rewards.  That feature could be implemented by only giving DividendTracker tokens to
//   holders that have the minimum number of DWClient tokens.
// - DWClient sends the DrunkDoge rewards fee to DogWalker for distribution on every transaction.
//   A real client might want to accumulate the fee and only distribute it when a certain threshhold
//   is reached, to minimize transaction costs / gas fees.
// - We don't have a cooldown for how often DrunkDoge rewards are distributed.

pragma solidity ^0.6.2;

import "./SafeMath.sol";
import "./SafeMathInt.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./DogWalkerInterface.sol";


contract DWClient is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;

    DividendTracker public dividendTracker;
    
    DogWalkerInterface public DW = DogWalkerInterface(0xe3687A5C8e1e95D249C4136A890bD04f0ba782A9); // TODO

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    
    uint256 public sellFee = 5;

    // use by default 200,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 200000;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;


    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    
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


    constructor() public ERC20("DWClient", "DWClient") {

    	dividendTracker = new DividendTracker(DW);

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
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
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000000 * (10**18));
    }

    receive() external payable {

  	}

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "SIMPLE: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "SIMPLE: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "SIMPLE: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function getTotalDividendsDistributed() external view returns (uint256) {
        return DW.dividendsDistributed(dividendTracker);
    }
    

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return DW.withdrawableDividendOf(dividendTracker,account);
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
            uint256) {
        return dividendTracker.getAccount(account);
    }
    
    function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
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

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if( !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            swapAndSendDividends(balanceOf(address(this)));

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 totalFeeTokens = amount.mul(sellFee).div(100);
            super._transfer(from, address(this), totalFeeTokens);
        	amount = amount.sub(totalFeeTokens);
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
    
    function swapAndSendDividends(uint256 tokens) private{
        if(tokens > 0) {
            swapTokensForEth(tokens);
            uint256 totalEth = address(this).balance;
            dividendTracker.distributeDividends{value:totalEth}();
            emit SendDividends(tokens, totalEth);
        }
    }

}

contract DividendTracker is Ownable, ERC20 {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
    
    DogWalkerInterface DW;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    event ExcludeFromDividends(address indexed account);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor(DogWalkerInterface dw) public ERC20("Dividend_Tracker", "Dividend_Tracker") {
        DW = dw;
    }

    // We don't allow transfers of this DividendTracker token - only DWClient can
    // manipulate balances of DividendTracker
    function _transfer(address, address, uint256) internal override {
        require(false, "Dividend_Tracker: No transfers allowed");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	require(!excludedFromDividends[account]);
    	excludedFromDividends[account] = true;

        uint256 amount = super.balanceOf(account);
        if(amount > 0) {
            super._burn(account,amount);
            DW.clientBurn(account,amount);
        }
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }
    
    function distributeDividends() external payable {
        uint256 amount = msg.value;
        DW.distributeDividends{value : amount}();
    }

    // We use this rather than a "transfer" operation to capture all balance changes.
    // This is necessary because balances in this contract aren't always the same as
    // balances in the main contract (for accounts that are excluded from dividends).
    // When a transfer occurs from one of those accounts, it doesn't really make 
    // sense here.
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
    		return;
    	}

        uint256 oldBalance = super.balanceOf(account);
        
        if(newBalance > oldBalance) {
            uint256 mintAmount = newBalance.sub(oldBalance);
            super._mint(account,mintAmount);
            DW.clientMint(account,mintAmount);
        } else if (newBalance < oldBalance) {
            uint256 burnAmount = oldBalance.sub(newBalance);
            super._burn(account,burnAmount);
            DW.clientBurn(account,burnAmount);
        }
        tokenHoldersMap.set(account,newBalance);

    	processAccount(account, true);
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = DW.withdrawableDividendOf(this,account);
        totalDividends = DW.accumulativeDividendOf(this,account);
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(processAccount(payable(account), true)) {
    			claims++;
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = DW.withdrawDividend(this,account);

    	if(amount > 0) {
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}