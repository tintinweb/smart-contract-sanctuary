// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Worker.sol";
import './TransferHelper.sol';
import './IAlpacaVault.sol';
import './IPancakeRouter01.sol';
import './IFairLaunch.sol';
import './IShareToken.sol';

contract AlpacaWorker is Worker, ReentrancyGuard
{
    address public VaultAddress;
    address public PancakeswapRouter;
    address public FairLaunch;
    uint private PoolId=3;
    event VaultAddressUpdated(address indexed previousVaultAddress, address indexed newVaultAddress);
    
    function OpenPosition(uint256 amountToken) public
    onlyOperator
    nonReentrant
    {
        address tokenAddress = IAlpacaVault(VaultAddress).token();
        TransferHelper.safeApprove(tokenAddress, VaultAddress,  type(uint256).max);
        IAlpacaVault(VaultAddress).deposit(amountToken);
        TransferHelper.safeApprove(tokenAddress, VaultAddress, uint256(0));
        TransferHelper.safeApprove(VaultAddress, FairLaunch,  type(uint256).max);
        uint256 balance = IShareToken(VaultAddress).balanceOf(address(this));
        IFairLaunchV1(FairLaunch).deposit(address(this),PoolId,balance);
        TransferHelper.safeApprove(VaultAddress, FairLaunch,  0);
    }
    function ClosePosition(uint256 amountShare) public 
    onlyOperator
    nonReentrant
    {
        IFairLaunchV1(FairLaunch).withdraw(address(this),PoolId,amountShare);
        IAlpacaVault(VaultAddress).withdraw(amountShare);
    }
    function TestWork(uint256 id, address worker, uint256 principalAmount, uint256 borrowAmount, uint256 maxReturn, bytes calldata data)
    public
    onlyOperator
    nonReentrant
    {
        IAlpacaVault(VaultAddress).work(id, worker, principalAmount, borrowAmount, maxReturn, data);
    }
    
    function ApproveToken(address token, uint256 value) public onlyOperator
    {
        TransferHelper.safeApprove(token, VaultAddress, value);
    }
    function SwapEthForToken(uint ethAmount,uint amountOut, address[] calldata path, uint deadline) public 
    onlyOperator 
    nonReentrant
    returns (uint[] memory amounts)
    {
        return IPancakeRouter01(PancakeswapRouter).swapETHForExactTokens{value:ethAmount}(amountOut,path,address(this),deadline);
    }
    function SwapTokenForToken(uint amountIn,uint amountOut, address[] calldata path, uint deadline) public 
    onlyOperator 
    nonReentrant
    returns (uint[] memory amounts)
    {
        TransferHelper.safeApprove(path[0], PancakeswapRouter,  type(uint256).max);
        uint[] memory res = IPancakeRouter01(PancakeswapRouter).swapExactTokensForTokens(amountIn, amountOut,path,address(this),deadline);
        TransferHelper.safeApprove(path[0], PancakeswapRouter,  uint256(0));
        return res;
    }
    function Harvest(uint256 poolId) public onlyOperator
    {
       IFairLaunchV1(FairLaunch).harvest(poolId);    
    }
    function PendingAlpaca(uint256 poolId) public view onlyOperator returns (uint256)
    {
        return IFairLaunchV1(FairLaunch).pendingAlpaca(poolId, address(this));
    }
    function UserInfo(uint256 poolId) public view onlyOperator returns (IFairLaunchV1.UserInfo memory)
    {
        return IFairLaunchV1(FairLaunch).userInfo(poolId, address(this));
    }
    function SetVaultAddress(address newVaultAddress) public onlyOperator 
    {
        require(newVaultAddress != address(0), "Operatorable: new VaultAddress is the zero address");
        _updateVaultAddress(newVaultAddress);
    }
    function SetRouterAddress(address newRouterAddress) public onlyOperator 
    {
        require(newRouterAddress != address(0), "Operatorable: new RouterAddress is the zero address");
        _updateRouterAddress(newRouterAddress);
    }
    function SetFairLaunchAddress(address newFairLaunchAddress) public onlyOperator 
    {
        require(newFairLaunchAddress != address(0), "Operatorable: new FairLaunchAddress is the zero address");
        _updateFairLaunchAddress(newFairLaunchAddress);
    }
    /**
     * @dev this is only for internal use
    */
    function _updateVaultAddress(address newVaultAddress) internal
    {
        address previousVaultAddress = VaultAddress;
        VaultAddress = newVaultAddress;
        emit VaultAddressUpdated(previousVaultAddress, VaultAddress);
    }
    function _updateRouterAddress(address newRouterAddress) internal
    {
        PancakeswapRouter = newRouterAddress;
    }
    function _updateFairLaunchAddress(address newFairLaunchAddress) internal
    {
        FairLaunch = newFairLaunchAddress;
    }
    receive() external payable nonReentrant
    {
        
        
    }
    fallback() external payable nonReentrant
    {
        // you can reject the funds (assert/require/revert) under certain conditions...
    }
}