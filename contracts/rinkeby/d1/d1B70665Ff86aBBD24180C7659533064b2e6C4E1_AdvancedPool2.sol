// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../storage/PoolStorage.sol";

contract AdvancedPool2 is PoolStorageV1 {
    
/****VARIABLES*****/
    using SafeMath for uint256;
   

/****MODIFIERS*****/
    
    modifier onlyOwner(){
        PoolStorage storage ps = poolStorage();
        require(ps.owner == msg.sender || ps.superOwner == msg.sender, "Only admin can call!!");
        _;
    }
    modifier onlySuperOwner(){
        PoolStorage storage ps = poolStorage();
        require(ps.superOwner == msg.sender, "Only super admin can call!!");
        _;
    }
    modifier notLocked {
        PoolStorage storage ps = poolStorage();
        require(!ps.locked, "contract is locked");
        _;
    }
  
/****EVENTS****/ 
    event userDeposits(address user, uint256 amount);
    event userWithdrawal(address user,uint256 amount);
    event poolDeposit(address user, address pool, uint256 amount);
    event poolWithdrawal(address user, address pool, uint256 amount);

/*****USERS FUNCTIONS****/

    function stake(uint256 amount) external notLocked() returns(uint256){
        require(amount > 0, 'Invalid Amount');

        PoolStorage storage ps = poolStorage();
        uint256 feeAmount = amount * ps.depositFees / ps.DENOMINATOR;
        ps.feesCollected = ps.feesCollected + feeAmount;
        uint256 mintAmount = calculatePoolTokens(amount - feeAmount);
        ps.poolBalance = ps.poolBalance.add(amount - feeAmount);
        ps.coin.transferFrom(msg.sender, address(this), amount);
        ps.poolToken.mint(msg.sender, mintAmount);
        emit userDeposits(msg.sender,amount);
        return mintAmount;
    }

    function unstake(uint256 amount) external notLocked() returns(uint256){
        PoolStorage storage ps = poolStorage();
        require(amount <= maxWithdrawal(), "Dont have enough fund, Please try later!!");
        require(amount <= ps.coin.balanceOf(address(this)), "Dont have enough fund, Please try later!!!");
        
        uint256 burnAmount = calculatePoolTokens(amount);
        require(burnAmount <= ps.poolToken.balanceOf(msg.sender), "You dont have enough pool token!!");

        uint256 feeAmount = amount * ps.withdrawFees/ ps.DENOMINATOR;
        ps.feesCollected = ps.feesCollected + feeAmount;
        ps.poolBalance = ps.poolBalance.sub(amount);

        ps.coin.transfer(msg.sender, amount - feeAmount);
        ps.poolToken.burn(msg.sender, burnAmount);  
        emit userWithdrawal(msg.sender, amount);
        return amount - feeAmount;
    }

/****ADMIN FUNCTIONS*****/

    function addToStrategy(uint256 minMintAmount) public notLocked() onlyOwner() returns(uint256){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        uint256 amount = amountToDeposit();
        require(amount > 0, "Nothing to deposit");
        ps.poolBalance = ps.poolBalance - amount;
        ps.coin.approve(address(ps.depositStrategy), 0);
        ps.coin.approve(address(ps.depositStrategy), amount);
        ps.depositStrategy.deposit(amount, minMintAmount);
        emit poolDeposit(msg.sender, address(ps.depositStrategy), amount);
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender);
        return amount;
    }
    
    function removeFromStrategy(uint256 maxBurnAmount) public notLocked() onlyOwner() returns(uint256){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        uint256 amount = amountToWithdraw();
        require(amount > 0 , "Nothing to withdraw");
        ps.poolBalance = ps.poolBalance + amount;
        ps.depositStrategy.withdraw(amount, maxBurnAmount);
        emit poolWithdrawal(msg.sender, address(ps.depositStrategy), amount);
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender); 
        return amount;
    }

    function removeAllFromStrategy(uint256 minAmount) public notLocked() onlySuperOwner(){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        require(strategyDeposit() > 0 , "Nothing to withdraw");
        uint256 oldBalance = ps.coin.balanceOf(address(this));
        ps.depositStrategy.withdrawAll(minAmount);
        uint256 newBalance = ps.coin.balanceOf(address(this));
        uint256 tokenReceived = newBalance - oldBalance;
        ps.poolBalance = ps.poolBalance + tokenReceived;
        emit poolWithdrawal(msg.sender, address(ps.depositStrategy), tokenReceived);
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender); 
    }
    
    function updateLiquidityParam(uint256 _minLiquidity, uint256 _maxLiquidity, uint256 _maxWithdrawalAllowed, uint256 maxBurnOrMinMint) external onlySuperOwner() returns(bool){
        require(_minLiquidity > 0 &&  _maxLiquidity > 0 && _maxWithdrawalAllowed > 0, 'Parameters cant be zero!!');
        require(_minLiquidity <  _maxLiquidity, 'Min liquidity cant be greater than max liquidity!!');
   
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);   
        ps.minLiquidity = _minLiquidity;
        ps.maxLiquidity = _maxLiquidity;
        ps.maxWithdrawalAllowed = _maxWithdrawalAllowed;
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender);
        if(amountToDeposit() > 0){
            addToStrategy(maxBurnOrMinMint);
        }else if(amountToWithdraw() > 0){
            removeFromStrategy(maxBurnOrMinMint);
        }
        return true;
    }
    
    function updateStrategy(DepositStrategy _newStrategy) public onlySuperOwner(){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        require(strategyDeposit() == 0, 'Withdraw all funds first');
        ps.depositStrategy = _newStrategy;
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender);
    }

/****OTHER FUNCTIONS****/

    function calculatePoolTokens(uint256 amountOfStableCoins) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (amountOfStableCoins * stableCoinPrice())/10**ps.coin.decimals() ;
    }

    function stableCoinPrice() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (ps.poolToken.totalSupply() == 0 || totalDeposit() == 0) ? 10**ps.coin.decimals() : ((10**ps.coin.decimals()) * ps.poolToken.totalSupply())/totalDeposit();
    }
    
    function calculateStableCoins(uint256 amountOfPoolToken) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        amountOfPoolToken = (amountOfPoolToken*poolTokenPrice())/(10**ps.poolToken.decimals());
        return amountOfPoolToken;
    }

    function poolTokenPrice() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (ps.poolToken.totalSupply() == 0 || ps.poolBalance == 0) ? 10**ps.poolToken.decimals() : ((10**ps.poolToken.decimals())*ps.poolBalance)/ps.poolToken.totalSupply();
    }
    
    function maxWithdrawal() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return minLiquidityToMaintainInPool()/2 < ps.maxWithdrawalAllowed ? minLiquidityToMaintainInPool()/2 : ps.maxWithdrawalAllowed;
    }

    function currentLiquidity() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalance;
    }
   
    function idealAmount() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (totalDeposit() * (ps.minLiquidity.add(ps.maxLiquidity))) / (2 * ps.DENOMINATOR);
    }
     
    function maxLiquidityAllowedInPool() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return totalDeposit() * ps.maxLiquidity / ps.DENOMINATOR;
    }

    function amountToDeposit() public view returns(uint256){
        return currentLiquidity() <= maxLiquidityAllowedInPool() ? 0 : currentLiquidity() - idealAmount();
    }
    
    function minLiquidityToMaintainInPool() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalance * ps.minLiquidity / ps.DENOMINATOR;
    }
   
    function amountToWithdraw() public view returns(uint256){
        return currentLiquidity() > minLiquidityToMaintainInPool() || strategyDeposit() == 0 || strategyDeposit() < idealAmount() - currentLiquidity() ? 0 : idealAmount() - currentLiquidity();
    }

    function totalDeposit() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalance + strategyDeposit();
    }

    function strategyDeposit() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.depositStrategy.depositedAmount();
    }

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;


interface Controller{
    function updateGasUsed(uint256 gasUsed, address adminAddress) external;
    function defaultGas() external returns(uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface DepositStrategy{
    function deposit(uint256 amount, uint256 minMintAmount) external;
    function withdraw(uint256 amount, uint256 maxBurnAmount) external;
    function withdrawAll(uint256 minAmount) external;
    function claimAndConvertCRV() external returns(uint256);
    function depositedAmount() external view returns(uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface  UniswapV2Router02  {
    function swapExactTokensForETH(uint, uint, address[] calldata, address, uint) external  returns (uint[] memory);
    function getAmountsOut(uint, address[] calldata) external view returns (uint[] memory);
    function WETH() external pure returns (address); 
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
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

    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
   
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6.0;
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol"; 
import "../interfaces/DepositStrategy.sol";
import "../interfaces/UniswapRouter.sol";
import "../interfaces/Controller.sol";

contract PoolStorageV1 {
    
    bytes32 constant ADVANCED_POOL_STORAGE_POSITION = keccak256("diamond.standard.advancedPool.storage");

    using SafeMath for uint256;
    struct PoolStorage {
        bool initialized;
    
        IERC20 coin;
        IERC20 poolToken;
        
        DepositStrategy depositStrategy;
        UniswapV2Router02 uniswapRouter;
        
        uint256 DENOMINATOR;

        uint256 depositFees;
        uint256 withdrawFees;
        uint256 minLiquidity;
        uint256 maxLiquidity;
        uint256 adminGasUsed;
        uint256 poolBalance; // coin Precision
        uint256 feesCollected;
        uint256 strategyDeposit;
        uint256 maxWithdrawalAllowed; //coin Precision
           
        bool  locked;
        address  owner;
        address superOwner;
        Controller controller;
    }

    function poolStorage() internal pure returns (PoolStorage storage ps) {
        bytes32 position = ADVANCED_POOL_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

}

