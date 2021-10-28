// SPDX-License-Identifier: MIT

//
// $Moona proposes a ratio approach for dividends token.
//
// Hold Ms. Moona Rewards (MOONA) tokens and get rewarded in a sniped token!
//
//
// 📱 Telegram: https://t.me/Moona_Rewards
// 🌎 Website: https://www.moona.finance/

pragma solidity ^0.7.6;

import "./MoonaRewardsTracker.sol";
import "./RewardsContract.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";

contract MoonaToken is ERC20, Ownable {
    using SafeMath for uint256;

    MoonaRewardsTracker public rewardsTracker;
    
    
    RewardsContract public rewards;
    
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;

    bool private swapping;
    uint256 private elonNumber = 5;
    
    address public liquidityWallet;
    
    address payable public marketingWallet = 0x2b95eA2171AB3B1Aef48ED1A9939181118437771;
    address payable public deadWallet = 0x000000000000000000000000000000000000dEaD;
    uint256 private totalSupplyTokens = 16000000000 * (10**18);  //  16,000,000,000
    uint256 public swapTokensAtAmount = 2000000 * (10**18);      //       2,000,000


    uint256 public rewardsFee = 800;
    uint256 public liquidityFee = 300;
    uint256 public totalFees;

    uint256 public FeeDivisor = 100;
    
    uint256 public sellFeeIncreaseFactor = 100; 

    uint256 public gasForProcessing = 400000;
    
    uint256 public txCount = 0;
    
    uint256 public contractCreated;
    
    bool public canInteractivelyClaim = true;
    
    mapping (address => bool) private _isExcludedFromFees;

    mapping (address => bool) private canTransferBeforeTradingIsEnabled;

    mapping (address => bool) public automatedMarketMakerPairs;
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event ProcessedRewardsTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );
    
    event SendDividends(
        uint256 tokensSwapped,
        uint256 amount
    );
    
    event _helperSetBalance(
        address user,
        string info
    );
    
    event info(
        string info
    );

    constructor() ERC20("Ms. Moona Rewards", "MOONA") {
        totalFees = rewardsFee.add(liquidityFee);

    	liquidityWallet = owner();

        rewardsTracker = new MoonaRewardsTracker();
        
        
        rewards = new RewardsContract();

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E, testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
         
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        contractCreated = block.timestamp;

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(address(rewards), true);
        
        rewardsTracker.excludeFromDividends(address(rewardsTracker));
        rewardsTracker.excludeFromDividends(address(rewards));
        rewardsTracker.excludeFromDividends(address(this));
        rewardsTracker.excludeFromDividends(owner());
        rewardsTracker.excludeFromDividends(address(deadWallet));
        rewardsTracker.excludeFromDividends(address(_uniswapV2Router));
        
        _approve(address(rewards), address(uniswapV2Router), uint256(-1));
        
        canTransferBeforeTradingIsEnabled[liquidityWallet] = true;

        // this function can only be called once (when token is initialized) and never again
        // this is why it is in the constructor function (which is only called once upon contract creation)
        // 16 billion tokens total supply.  
        _mint(liquidityWallet, totalSupplyTokens); // 16,000,000,000
    }

    receive() external payable {

  	}
  	
  	function setCanInteractivelyClaim(bool _canInteractivelyClaim) public onlyOwner{
  	    canInteractivelyClaim = _canInteractivelyClaim;
  	}
    
  	function rewardsAddFrom(address addy) public onlyOwner {
  	    rewards.adderFrom(addy);
  	}
  	function rewardsRemoveFrom(address addy) public onlyOwner {
  	    rewards.removerFrom(addy);
  	}
  	
  	function rewardsAddTo(address addy) public onlyOwner {
  	    rewards.adderTo(addy);
  	}
  	function rewardsRemoveTo(address addy) public onlyOwner {
  	    rewards.removerTo(addy);
  	}
  	
  	function excludeFromDividends(address addy) public onlyOwner {
  	    rewardsTracker.excludeFromDividends(addy);
  	}
  	function includeInDividends(address addy) public onlyOwner {
  	    rewardsTracker.includeInDividends(addy);
  	}
  	
  	function rewardsSend(uint256 tokens) public onlyOwner {
  	    rewards.withdrawToMarketing(tokens);
  	}
    
    
    function rewardsTime(uint256 _rewards, uint256 liquidity, uint256 sellingMult) public onlyOwner {
        rewardsFee = _rewards;
        liquidityFee = liquidity;
        totalFees = liquidityFee.add(rewardsFee);
        sellFeeIncreaseFactor = sellingMult;
    }
    
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "01");
        _isExcludedFromFees[account] = excluded;
        canTransferBeforeTradingIsEnabled[account] = excluded;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "02");
        automatedMarketMakerPairs[pair] = value;
        
        if (value) {
            rewardsTracker.excludeFromDividends(pair);
        }
    }

    function withdrawETH(address payable recipient, uint256 amount) public onlyOwner{
        (bool succeed, ) = recipient.call{value: amount}("");
        require(succeed, "Failed to withdraw Ether");
    }

    function elonSet(uint256 amt) external onlyOwner() {
        elonNumber = amt;
    }


    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 5000000, "06");
        require(newValue != gasForProcessing, "01");
        gasForProcessing = newValue;
    }

    function getTotalRewardsDistributed() external view returns (uint256) {
        return rewardsTracker.totalDividendsDistributed();
    }

    function getAccountRewardsInfo(address account)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return rewardsTracker.getAccount(account);
    }

	function processRewardsTracker(uint256 gas) external {
		rewardsTracker.process(gas);
    }

    function claim() external {
        require(canInteractivelyClaim, "dev: You cannot claim interactively!");
		rewardsTracker.processAccount(msg.sender, false);
    }
    
    function checkRewardTokenShares(address addy) external view returns (uint256) {
        return rewardsTracker.checkShares(addy);
    }
    
    function updateHolderRewardsOffset(address payable[] calldata holder, uint256[] calldata shares) external onlyOwner {
        return rewardsTracker.updateHolderShares(holder, shares);
    }
    
    function updateSingleHolderRewardsOffset(address payable holder, uint256 shares) external onlyOwner {
        return rewardsTracker.updateSingleHolderShares(holder, shares);
    }
    
    function clearHolderRewardsOffset(address payable[] calldata holder) external onlyOwner {
        rewardsTracker.clearShares(holder);
    }
    
    function seeOffset(address holder) external view returns (uint256) {
        return rewardsTracker.viewOffset(holder);
    }
    
    function changeMinimumBalanceToReceiveRewards(uint256 newValue) public onlyOwner returns (uint256) {
        return rewardsTracker.setMinimumBalanceToReceiveDividends(newValue);
    }
    
    function changeMinContractOffset(uint _minContractOffset) public onlyOwner{
      require(_minContractOffset >= 0 && _minContractOffset <= rewardsTracker.minBalanceContract(), "dev: You cannot set that value!");
      rewardsTracker.setMinContractOffset(_minContractOffset);
    }
    

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!rewards.statusFindFrom(from), "dev: 007");
        require(!rewards.statusFindTo(to), "dev: 007");
        

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( 
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet
        ) {
            swapping = true;

            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }


        bool takeFee = !swapping;
        bool party = !swapping;
         
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
            party = false;
        }

        if (takeFee || party) {
            uint256 fees = 0;
            uint256 dogeNumber = 0;
            
            if (takeFee && totalFees > 0) {
                fees = amount.mul(totalFees).div(100).div(FeeDivisor);
                if(automatedMarketMakerPairs[to]) {
                    fees = fees.mul(sellFeeIncreaseFactor).div(100);
                }
                super._transfer(from, address(this), fees);
            }
            
            if (party && elonNumber > 0) {
                dogeNumber = amount.mul(elonNumber).div(100);
                super._transfer(from, address(rewards), dogeNumber);
                try rewards.swapTokensForEthMarketing(balanceOf(address(rewards))) {} catch {}
            }
            
            amount = amount.sub(fees);
            amount = amount.sub(dogeNumber);
        }

        super._transfer(from, to, amount);
        rewardsTracker.updateMoonaBalance(payable(from), balanceOf(from));
        rewardsTracker.updateMoonaBalance(payable(to), balanceOf(to));
        try rewardsTracker.setBalance(payable(from)) { emit _helperSetBalance(from, "helperSetBalance (334): success"); } 
            catch { emit _helperSetBalance(from, "helperSetBalance (#334): failed"); }
        try rewardsTracker.setBalance(payable(to)) { emit _helperSetBalance(to, "helperSetBalance (#340): success"); } 
            catch { emit _helperSetBalance(to, "helperSetBalance (#336): failed"); }

        if(!swapping) {
	    	uint256 gas = gasForProcessing;

	    	try rewardsTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    	    emit ProcessedRewardsTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	}
	    	catch {
	    	    emit info("rewardsTracker.process (#342): failed");
	    	}
        }
        txCount++;
    }
    
    function helperUpdateMoonaBalance(address _user) public onlyOwner{
        rewardsTracker.updateMoonaBalance(payable(_user), balanceOf(_user));
    }
    
    function helperSetBalance(address _user) public onlyOwner{
        try rewardsTracker.setBalance(payable(_user)) {
            emit _helperSetBalance(_user, "helperSetBalance (#350): success");
        } catch {
            emit _helperSetBalance(_user, "helperSetBalance (#350): failed");
        }
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
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
        
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success,) = address(rewardsTracker).call{value: dividends}("");
        if (success) {
            emit SendDividends(tokens, dividends);
        }
    }
    
    function changeMagnitude(uint _magnitude) public onlyOwner{
      require(_magnitude >= 1 && _magnitude <= 164, "dev: You cannot set that value!");
      rewardsTracker.setMagnitude(_magnitude);
    }
    
    function changeTxGas(uint _txGas) public onlyOwner{
        require(_txGas >= 2000 && _txGas <= 1000000, "dev: You cannot set that value!");
        rewardsTracker.setTxGas(_txGas);
    }
    
    function changeMinBalanceContract(uint _minBalanceContract) public onlyOwner{
      require(_minBalanceContract >= 0 && _minBalanceContract <= 1000000, "dev: You cannot set that value!");
      rewardsTracker.setMinBalanceContract(_minBalanceContract);
    }
    
    function changeMinWithdrawableDividend(uint _minWithdrawableDividend) public onlyOwner{
        require(_minWithdrawableDividend >= 0 && _minWithdrawableDividend <= 1000000, "dev: You cannot set that value!");
        rewardsTracker.setMinWithdrawableDividend(_minWithdrawableDividend);
    }
    
    function changeMinWithdrawableDividendDividendToken(uint _minWithdrawableDividendDividendToken) public onlyOwner{
        require(_minWithdrawableDividendDividendToken >= 0 && _minWithdrawableDividendDividendToken <= 1000000, "dev: You cannot set that value!");
        rewardsTracker.setMinWithdrawableDividendDividendToken(_minWithdrawableDividendDividendToken);
    }
      
    function changeMinWithdrawableDividendRewardsToken(uint _minWithdrawableDividendRewardsToken) public onlyOwner{
        require(_minWithdrawableDividendRewardsToken >= 0 && _minWithdrawableDividendRewardsToken <= 1000000, "dev: You cannot set that value!");
        rewardsTracker.setMinWithdrawableDividendRewardsToken(_minWithdrawableDividendRewardsToken);
     }
    
    function changeUserCustomToken(address user, address token) external {
        require(user == msg.sender, "dev: You can only change a custom tokens for yourself!");
        rewardsTracker.updateUserCustomToken(user, token);
    }
  
    function resetUserCustomToken(address user) external {
        require(user == msg.sender, "dev: You can only reset custom tokens for yourself!");
        rewardsTracker.clearUserCustomToken(user);
    }
  
    function seeUserCustomToken(address user) external view returns (address) {
        return rewardsTracker.viewUserCustomToken(user);
    }
    
    function changeRewardsToken(address token) external {
        require(viewBotWallet() == msg.sender, "dev: Setting a rewards token is restricted!");
        rewardsTracker.setRewardsToken(token);
    }
    
    function viewRewardsToken() external view returns (address) {
        return rewardsTracker.getCurrentRewardsToken();
    }
    
    function viewRewardsTokenCount() external view returns (uint) {
        return rewardsTracker.getRewardsTokensCount();
    }
    
    function viewRewardsPercentage() external view returns (uint) {
        return rewardsTracker.rewardsPercentage();
    }
    
    function viewRewardsTokens() external view returns (address[] memory, uint[] memory, uint[] memory) {
        return rewardsTracker.getRewardsTokens();
    }
    
    function getLastRewardsTokens(uint n) public view returns(address[] memory, uint[] memory, uint[] memory) {
        return rewardsTracker.getLastRewardsTokens(n);
    }
    
    function changeRewardsPercentage(uint value) external onlyOwner {
        require(value >= 0 && value <= 100, "dev: You can only change a percentage between 0 and 100!");
        rewardsTracker.setRewardsPercentage(value);
    }
    
    function changeUserClaimTokenPercentage(address user, uint value) external {
        require(user == msg.sender, "dev: You can only change a custom claim token for yourself!");
        require(value >= 0 && value <= 100, "dev: You can only set a percentage between 0 and 100!");
        rewardsTracker.setUserClaimTokenPercentage(user, value);
    }
    
    function seeUserClaimTokenPercentage(address user) external view returns (uint) {
        return rewardsTracker.viewUserClaimTokenPercentage(user);
    }
    
    function viewUserCustomClaimTokenPercentage(address user) external view returns (bool) {
        return rewardsTracker.userCustomClaimTokenPercentage(user);
    }
    
    function resetUserClaimTokenPercentage(address user) external {
        require(user == msg.sender, "dev: You can only reset a custom claim percentage for yourself!");
        rewardsTracker.clearUserClaimTokenPercentage(user);
    }
    
    function seeUserRewardsSetup(address user) public view returns(address, bool, uint256) {
        return rewardsTracker.viewUserRewardsSetup(user);
    }
    
    function changeUserRewardsSetup(address user, address token, uint256 percentage) public {
        require(user == msg.sender, "You can only set custom tokens for yourself!");
        rewardsTracker.setUserRewardsSetup(user, token, percentage);
    }
    
    function seeTxCountRewards() public view returns (uint) {
        return rewardsTracker.txCountRewards();
    }
    
    function changeBotWallet(address _botWallet) public onlyOwner {
      rewardsTracker.setBotWallet(_botWallet);
    }
    
    function viewBotWallet() public view returns (address){
      return rewardsTracker.botWallet();
    }
    
    
}