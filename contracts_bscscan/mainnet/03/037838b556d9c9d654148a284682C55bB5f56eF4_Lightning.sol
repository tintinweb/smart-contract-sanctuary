// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";


contract Lightning is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;

    address public stakingFeeToken = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); 

    uint256 public swapTokensAtAmount = 200 * (10**18);

    uint256 public lightRewardFee = 0;
    uint256 public liquidityFee = 0;
    uint256 public stakingFee = 10;
    uint256 public totalFees = lightRewardFee.add(liquidityFee).add(stakingFee);

    address payable public stakingContract = 0xcCeB8da6471c69e6ae2691422a253E4C326A8b69;
    
    address public liquidityRecipient;
    address public equalizer;

    bool public isBaseToken = true;

     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;


    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() public ERC20("Lightning", "LIGHT") {

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(stakingContract, true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again 
        */
        _mint(owner(), 100000000 * (10**18));
    }

    receive() external payable {

  	}

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "LIGHT: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "LIGHT: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setStakingContract(address payable _stakingContract) external onlyOwner{
        stakingContract = _stakingContract;
    }

    function setLightRewardFee(uint256 value) external onlyOwner{
        require(value >= 0 && value <= 15);
        require(value.add(liquidityFee).add(stakingFee) <= 15);
        lightRewardFee = value;
        totalFees = lightRewardFee.add(liquidityFee).add(stakingFee);
    }

    function setLiquidityFee(uint256 value) external onlyOwner{
        require(value >= 0 && value <= 15);
        require(value.add(lightRewardFee).add(stakingFee) <= 15);
        liquidityFee = value;
        totalFees = lightRewardFee.add(liquidityFee).add(stakingFee);
    }

    function setStakingFee(uint256 value) external onlyOwner{
        require(value >= 0 && value <= 15);
        require(value.add(lightRewardFee).add(liquidityFee) <= 15);
        stakingFee = value;
        totalFees = lightRewardFee.add(liquidityFee).add(stakingFee);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "LIGHT: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "LIGHT: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
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

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            // @dev fee functions should only be called if the fee is at least 1, as trades will fail otherwise if a fee is 0

            if (stakingFee > 0){
                if(isBaseToken){
                    uint256 stakingTokens = contractTokenBalance.mul(stakingFee).div(totalFees);
                    swapAndSendToStaking(stakingTokens);
                } else {
                    uint256 stakingTokens = contractTokenBalance.mul(stakingFee).div(totalFees);
                    swapForTokensAndSendToStaking(stakingTokens);
                }
                
            }

            if(liquidityFee > 0){
                uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
                swapAndLiquify(swapTokens);
            }
            
            if(lightRewardFee > 0) {
                uint256 tokenAmount = contractTokenBalance.mul(lightRewardFee).div(totalFees);
                sendLightToStaking(tokenAmount);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        // @dev if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {

            // @dev support feeless transfer between wallets, only take fee for trades
            if(automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from]){
                
        	    uint256 fees = amount.mul(totalFees).div(100);
        	    amount = amount.sub(fees);
                super._transfer(from, address(this), fees);
            
            }
        	
        }

        super._transfer(from, to, amount);

    }
    
    function swapForTokensAndSendToStaking(uint256 tokens) private  {
        swapTokensForStakingFeeToken(tokens);
        uint256 newBalance = (IERC20(stakingFeeToken).balanceOf(address(this)));
        IERC20(stakingFeeToken).transfer(stakingContract, newBalance);

    }

    function swapAndSendToStaking(uint256 tokens) private  {
        swapTokensForEth(tokens);
        uint256 newBalance = address(this).balance;
        stakingContract.transfer(newBalance);
    }
    
    function sendLightToStaking(uint256 tokens) private {
        super._transfer(address(this), equalizer, tokens);
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

    function swapTokensForStakingFeeToken(uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = stakingFeeToken;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            stakingContract,
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
            liquidityRecipient,
            block.timestamp
        );

    }

    function setStakingFeeBaseToken(bool _isBaseToken) external onlyOwner {
        isBaseToken = _isBaseToken;
    }

    function setStakingFeeToken(address _stakingFeeToken) external onlyOwner {
        stakingFeeToken = _stakingFeeToken;
    }
    
    function setLiquidityRecipient(address _liquidityRecipient) external onlyOwner {
        liquidityRecipient = _liquidityRecipient;
    }
    
    function setEqualizer(address _equalizer) external onlyOwner {
        equalizer = _equalizer;
    }
    
    function setSwapTokensAtAmount(uint256 _tokenAmount) external onlyOwner {
        swapTokensAtAmount = _tokenAmount;
    }

}