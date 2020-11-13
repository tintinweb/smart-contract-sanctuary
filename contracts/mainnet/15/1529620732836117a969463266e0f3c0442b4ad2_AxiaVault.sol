pragma solidity ^0.6.0;

interface ERC20Interface {
    
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


contract AxiaVault {
    
    address public AXIA;
    address public SwapLiquidity;
    address public OracleLiquidty;
    address public DefiLiquidity;
    
    address owner = msg.sender;
    uint256 public lastTradingFeeDistributionAxia;
    uint256 public lastTradingFeeDistributionSwap;
    uint256 public lastTradingFeeDistributionOracle;
    uint256 public lastTradingFeeDistributionDefi;
    
    uint256 public migrationLock;
    address public migrationRecipient;
    
    
// Has a hardcap of 1% per trading fees distribution in one week.

    function distributeAXIA(address recipient, uint256 amount) external {
        uint256 TokenBalance = ERC20Interface(AXIA).balanceOf(address(this));
        require(amount <= (TokenBalance / 100), "Amount is higher than 1% of AXIA vault balance"); // Max 1%
        require(lastTradingFeeDistributionAxia + 168 hours < now, "Time is less than assigned time for distribution of Axia"); // Max once a week 
        require(msg.sender == owner, "No Authorization");
               ERC20Interface(AXIA).transfer(recipient, amount);
        lastTradingFeeDistributionAxia = now;
    } 
    
    function distributeSWAP(address recipient, uint256 amount) external {
        uint256 TokenBalance = ERC20Interface(SwapLiquidity).balanceOf(address(this));
        require(amount <= (TokenBalance / 100), "Amount is higher than 1% of SwapLiquidity vault balance"); // Max 1%
        require(lastTradingFeeDistributionSwap + 168 hours < now, "Time is less than assigned time for distribution of SwapLiquidity"); // Max once a week 
        require(msg.sender == owner, "No Authorization");
               ERC20Interface(SwapLiquidity).transfer(recipient, amount);
        lastTradingFeeDistributionSwap = now;
    } 
    
    function distributeORACLE(address recipient, uint256 amount) external {
        uint256 TokenBalance = ERC20Interface(OracleLiquidty).balanceOf(address(this));
        require(amount <= (TokenBalance / 100), "Amount is higher than 1% of OracleLiquidty vault balance"); // Max 1%
        require(lastTradingFeeDistributionOracle + 168 hours < now, "Time is less than assigned time for distribution of OracleLiquidty"); // Max once a week 
        require(msg.sender == owner, "No Authorization");
               ERC20Interface(OracleLiquidty).transfer(recipient, amount);
        lastTradingFeeDistributionOracle = now;
    } 
    
    function distributeDEFI(address recipient, uint256 amount) external {
        uint256 TokenBalance = ERC20Interface(DefiLiquidity).balanceOf(address(this));
        require(amount <= (TokenBalance / 100), "Amount is higher than 1% of DefiLiquidity vault balance"); // Max 1%
        require(lastTradingFeeDistributionDefi + 168 hours < now, "Time is less than assigned time for distribution of DefiLiquidity"); // Max once a week 
        require(msg.sender == owner, "No Authorization");
               ERC20Interface(DefiLiquidity).transfer(recipient, amount);
        lastTradingFeeDistributionDefi = now;
    } 
    

// Function allows liquidity to be migrated, after 3 months lockup - preventing abuse.


    function startLiquidityMigration(address recipient) external {
        require(msg.sender == owner, "No Authorization");
        migrationLock = now + 2160 hours;
        migrationRecipient = recipient;
    }
    
    
// Migrates liquidity to new location, assuming the 3 months lockup has passed -preventing abuse.

    function processMigration() external {
        
        require(msg.sender == owner, "No Authorization");
        require(migrationRecipient != address(0));
        require(now > migrationLock);
        
        uint256 TokenBalance = ERC20Interface(AXIA).balanceOf(address(this));
        uint256 TokenBalanceSwap = ERC20Interface(SwapLiquidity).balanceOf(address(this));
        uint256 TokenBalanceOracle = ERC20Interface(OracleLiquidty).balanceOf(address(this));
        uint256 TokenBalanceDefi = ERC20Interface(DefiLiquidity).balanceOf(address(this));
        
        ERC20Interface(AXIA).transfer(migrationRecipient, TokenBalance);
        ERC20Interface(SwapLiquidity).transfer(migrationRecipient, TokenBalanceSwap);
        ERC20Interface(OracleLiquidty).transfer(migrationRecipient, TokenBalanceOracle);
        ERC20Interface(DefiLiquidity).transfer(migrationRecipient, TokenBalanceDefi);
        
    }  
    
    
    // Setting the interracting tokens
    
    function startToken(address _AXIAaddress, address _SwapLiquidity, address _OracleLiquidity, address _DefiLiquidity) external {
        require(msg.sender == owner);
        AXIA = _AXIAaddress;
        SwapLiquidity = _SwapLiquidity;
        OracleLiquidty = _OracleLiquidity;
        DefiLiquidity = _DefiLiquidity;
    }
    
    
}