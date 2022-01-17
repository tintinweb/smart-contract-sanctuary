// SPDX-License-Identifier: theFeniks.com

pragma solidity ^0.8.0;

import 'ERC20.sol';
import 'IERC20.sol';
import 'IUniswapV2Pair.sol';
import 'IUniswapV2Router01.sol';
import 'Address.sol';
import 'IUniswapV2Factory.sol';
import 'IUniswapV2Router02.sol';
import 'SafeMath.sol';
import 'Context.sol';
import 'Ownable.sol';
import 'Stakeable.sol';


contract SamkiToken is Context, ERC20, Ownable, Stakeable{

    using SafeMath for uint256;
    
    event addRole(address indexed account);
    event removeRole(address indexed account);

    mapping(address => bool) public roles;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isExcludedFromFee;
    
   // Foundation Settings
    uint8 public foundationFee = 2;
    address public foundationWallet;
    bool public isfoundationFee = false;
    uint256 private nonce;

    //Token General Settings
    string tokenName = "Samki";
    string tokenSymbol = "SMK"; 
    uint8 tokenDecimals = 9;
    uint8 public burnFee = 2;
    uint8 public liquidityFee = 4;
    uint256 tokenTotalSupply = 750  * 10**9 * 10**9;
  

    // Stake Settings
    uint256 public stakingPerRate = 100;
    uint8 stakingTimeValue = 4;
    uint256 constant maxTokenTotalSupply = 1 * 10**12 * 10**9;
    bool public isOnStake = false;
    address public lockStakingWallet;

    // PancakeSwap Settings
    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Router02 _uniswapV2Router;
    address public immutable uniswapV2Pair;
    uint256 public minTokensBeforeSwap = 100000 * 10**9; 
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    address uniswapV2RouterAd = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    // Wallet Informations
    address public teamWallet = 0xA3F750AF275E66f663A01C47EF01A40c6C83a5b9;
    address public homelessWallet = 0x8A3e98B1859ba265e238183d9E8a9c3BD5eA5547; 
    address public developmentWallet = 0xfF6EF458E9d897ca679c579156ef82d0B01a3A6f; 
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () ERC20(tokenName, tokenSymbol,tokenDecimals){
        nonce = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.timestamp)));
        lockStakingWallet = creatingWallet(nonce);
        _mint(msg.sender, tokenTotalSupply * 70/100);
        _mint(teamWallet, tokenTotalSupply * 10/100);
        _mint(homelessWallet, tokenTotalSupply * 5/100);
        _mint(developmentWallet, tokenTotalSupply * 15/100);


        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[lockStakingWallet] = true;
        isExcludedFromFee[foundationWallet] = true;
        isExcludedFromFee[teamWallet] = true;
        isExcludedFromFee[homelessWallet] = true;
        isExcludedFromFee[developmentWallet] = true;


        _uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAd); 

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
    }

    modifier onlyFoundation(){
        require(roles[msg.sender], "You are not authorized for this action");
        _;
    }


    function creatingWallet(uint256 nonce) private view returns(address){
        address randomish = address(uint160(uint(keccak256(abi.encodePacked(nonce, blockhash(block.number))))));
        return randomish;
    }
  
   /*
        override the internal _transfer function so that we can
        take the fee, and conditionally do the swap + liquditiy
    */

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!isBlacklisted[from] && !isBlacklisted[to], "This address is blacklisted!");
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;
         
        if (overMinTokenBalance && !inSwapAndLiquify && msg.sender != uniswapV2Pair && swapAndLiquifyEnabled) {
            swapAndLiquify(contractTokenBalance);
        }
        if (isfoundationFee){
            if (isExcludedFromFee[from] || isExcludedFromFee[to]) {    
                super._transfer(from, to, amount);
            } else {
                uint liquidityAmount = amount.mul(liquidityFee).div(10**2);
                uint foundationAmount = amount.mul(foundationFee).div(10**2);
                uint burnAmount = amount.mul(burnFee).div(10**2);
                uint tokensToTransfer = amount.sub(liquidityAmount + foundationAmount +burnAmount);                   
                super._transfer(from, address(this), liquidityAmount);
                burnToken(burnAmount);
                super._transfer(from, foundationWallet, foundationAmount);
                super._transfer(from, to, tokensToTransfer);
            }
        } else {
            if(isExcludedFromFee[from] || isExcludedFromFee[to]) {    
            super._transfer(from, to, amount);
            } else {
            uint liquidityAmount = amount.mul(liquidityFee).div(10**2);
            uint burnAmount = amount.mul(burnFee).div(10**2);
            uint tokensToTransfer = amount.sub(liquidityAmount + burnAmount);                   
            super._transfer(from, address(this), liquidityAmount);
            burnToken(burnAmount);
            super._transfer(from, to, tokensToTransfer);
            }  
        }  
    }

  // Foundation Authorization Add
    function addFoundation(address _account) public onlyOwner {
        roles[_account] = true;
        isExcludedFromFee[_account] = true;
        emit addRole(_account);
        roles[owner()] = false;
        emit removeRole(owner());  
    }
     // Foundation Authorization Delete
    function removeFoundation(address _account) public onlyOwner {
        roles[_account] = false;
        emit removeRole(_account);
        isExcludedFromFee[_account] = false;
        roles[owner()] = true;
        emit addRole(owner());
    }
 
    function createDonation() public onlyFoundation {
       changeWallet();
    }
    function changeFoundationFeeStatus() public onlyOwner{
        isfoundationFee = !isfoundationFee;
    }

    function withdrawDonation() public onlyFoundation {
        uint donationAmount = balanceOf(foundationWallet);
        _transfer(foundationWallet, msg.sender, donationAmount);
    }


    /**
    * Add functionality like burn to the _stake afunction
    *
     */
    function stake(uint256 _amount) public{
      require(isOnStake, "Staking is not active");
      uint256 wilBeMaxTokenTotalSupply = tokenTotalSupply + _amount *  1 / stakingPerRate;
      // Make sure staker actually is good for it
      require(_amount < balanceOf(msg.sender), "Cannot stake more than you own");
      require(wilBeMaxTokenTotalSupply <= maxTokenTotalSupply, "The amount of tokens has reached the maximum amount!");
      creatingStake(_amount);
      // Burn the amount of tokens on the sender
      _transfer(msg.sender, lockStakingWallet, _amount);
    }

    
     /**
    * @notice withdrawStake is used to withdraw stakes from the account holder
     */
    function withdrawStake(uint256 index) public {
        (uint256 _amount , uint256 _reward) = calculateStakeAward(msg.sender, index, stakingPerRate);
        _withdrawStake(msg.sender, index, stakingTimeValue, stakingPerRate);
       _mint(msg.sender, _reward);
       _transfer(lockStakingWallet, msg.sender, _amount);
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
    
    receive() external payable {}


    function burnToken(uint256 amount) public {
        tokenTotalSupply = tokenTotalSupply.sub(amount);
        _burn(msg.sender, amount);
    }

    // Stake set Values
    function changeStakeValue(uint8 _week) public onlyOwner {
        stakingTimeValue = _week;
    }
    function calculateStakingTime() public view returns(uint256){
        return (stakingTime * stakingTimeValue);
    }
    function changeRewardPerRate (uint256 _value) public onlyOwner {
        stakingPerRate = _value;
    }
    function changeStakeStatus () public onlyOwner {
        isOnStake = !isOnStake;
    }
 
    //liquidity set Values
    function setLiquidityFee(uint8 newFee) public onlyOwner{
        liquidityFee = newFee;
    }
    function updateSwapAndLiquifyEnabled() public onlyOwner {
        swapAndLiquifyEnabled = !swapAndLiquifyEnabled;
    }
    
    //Donation set Values
    function updateFoundationFee(uint8 _fee) public onlyOwner{
        foundationFee = _fee;
    }
    function changeWallet() private {
        nonce = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.timestamp)));
        foundationWallet = creatingWallet(nonce);
    }

    //General Settings

    function blacklistAddress(address account, bool value) public onlyOwner {
        isBlacklisted[account] = value;
    }
    function inExcludedFromFee(address _add) public onlyOwner{
        isExcludedFromFee[_add] = true;
    }
     function exExcludedFromFee(address _add) public onlyOwner{
        isExcludedFromFee[_add] = false;
    }

    function withdrawAnyToken(address _recipient, address _ERC20address, uint256 _amount) public onlyOwner returns(bool) {
        require(_ERC20address != uniswapV2Pair, "Can't transfer out LP tokens!");
        require(_ERC20address != address(this), "Can't transfer out contract tokens!");
        IERC20(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        return true;
    }

    function withdrawContractBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
}