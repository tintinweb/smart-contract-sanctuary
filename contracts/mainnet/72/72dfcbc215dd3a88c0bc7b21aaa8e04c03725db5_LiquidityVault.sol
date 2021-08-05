/**
 *Submitted for verification at Etherscan.io on 2020-08-05
*/

pragma solidity ^0.6.0;


/**
 * 
 * UniPower's Liquidity Vault
 * 
 * Simple smart contract to decentralize the uniswap liquidity, providing proof of liquidity indefinitely.
 * For more info visit: https://unipower.network 
 * 
 */
contract LiquidityVault {
    
    ERC20 constant AludraNetwork = ERC20(0xb339FcA531367067e98d7c4f9303Ffeadff7B881);
    ERC20 constant liquidityToken = ERC20(0x9076a5277eD7D8A89496B7132c0Bf4503a9A9F93);
    
    address cash = msg.sender;
    uint256 public lastTradingFeeDistribution;
    uint256 public migrationLock;
    address public migrationRecipient;
    
 
    function distributeWeekly(address recipient) external {
        uint256 liquidityBalance = liquidityToken.balanceOf(address(this));
        require(lastTradingFeeDistribution + 7 days < now); // Max once a day
        require(msg.sender == cash);
        liquidityToken.transfer(recipient, (liquidityBalance / 100));
        lastTradingFeeDistribution = now;
    } 
    
    
    function startLiquidityMigration(address recipient) external {
        require(msg.sender == cash);
        migrationLock = now + 100 days;
        migrationRecipient = recipient;
    }
    
    
    function processMigration() external {
        require(msg.sender == cash);
        require(migrationRecipient != address(0));
        require(now > migrationLock);
        
        uint256 liquidityBalance = liquidityToken.balanceOf(address(this));
        liquidityToken.transfer(migrationRecipient, liquidityBalance);
    }
    
    
    
    function getcash() public view returns (address){
        return cash;
    }
    function getLiquidityBalance() public view returns (uint256){
        return liquidityToken.balanceOf(address(this));
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