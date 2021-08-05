/**
 *Submitted for verification at Etherscan.io on 2020-07-08
*/

pragma solidity ^0.6.0;


/**
 * 
 * Adapted from UniPower's Liquidity Vault for European Coin Alliance ECA 
 * http://www.ecacoin.net
 * 
 * Simple smart contract to decentralize the uniswap liquidity, providing proof of liquidity for a minimum of 180 days.
 * For more info visit: https://unipower.network
 * 
 */
contract ECAVault {
   //dual Vault
   
    //eca token. this vault holds team and excess supply. Starts with 300K and releases 1% per week for a minimum of 6 months 
    ERC20 constant ecaToken = ERC20(0xfab25D4469444f28023075Db5932497D70094601);
	//uniswap
    ERC20 constant liquidityToken = ERC20(0x240c7C1E5bB1F9BD9DEE988BB1611E56872dc7d9);
    
    //address blobby = msg.sender; thank you mr blobby :)
    
    address owner = msg.sender;
    //uniswap
    uint256 public lastTradingFeeDistribution;
    uint256 public sixMonthLock;
    address public tokenRecipient;
    
    
 
    function distributeWeekly(address recipient) external {
        //liquidityBalance
        uint256 liquidityBalance = liquidityToken.balanceOf(address(this));
        //ecaBalance
        uint256 ecaBalance = ecaToken.balanceOf(address(this));
		
        require(lastTradingFeeDistribution + 7 days < now); // Max once a week
        require(msg.sender == owner);
        //1% of liquidity
        liquidityToken.transfer(recipient, (liquidityBalance / 100));
        //1% of eca
        ecaToken.transfer(recipient, (ecaBalance / 100));
        
        lastTradingFeeDistribution = now;
    } 
    
    
 
 //start the lock for six months minimum
    function startLiquiditySixMonthLock(address recipient) external {
        require(msg.sender == owner);
        //lock for 6 months, only 1% withdrawal per week
        sixMonthLock = now + 180 days;
        tokenRecipient = recipient;
    }
    
    
    //six months passed? can withdraw remaining balances 
    function sendRemainingTokensIfSixMonthsPassed() external {
        require(msg.sender == owner);
        require(tokenRecipient != address(0));
        require(now > sixMonthLock);
        
        //liquidity
        uint256 liquidityBalance = liquidityToken.balanceOf(address(this));
        liquidityToken.transfer(tokenRecipient, liquidityBalance);
        
        //eca
        uint256 ecaBalance = ecaToken.balanceOf(address(this));
        ecaToken.transfer(tokenRecipient, ecaBalance);
        
    }
    
    
    
    function getOwner() public view returns (address){
        return owner;
    }
    function getLiquidityBalance() public view returns (uint256){
        return liquidityToken.balanceOf(address(this));
    }
    function getEcaBalance() public view returns (uint256){
        return ecaToken.balanceOf(address(this));
    }
    
}

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}