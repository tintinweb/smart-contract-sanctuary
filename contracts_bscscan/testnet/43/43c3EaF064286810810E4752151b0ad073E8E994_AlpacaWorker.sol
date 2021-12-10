// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Worker.sol";
import './TransferHelper.sol';
import './IAlpacaVault.sol';
import './IPancakeRouter01.sol';
import './IFairLaunch.sol';
import './IShareToken.sol';
import './IPancakeWorker.sol';
import './IPancakePair.sol';
import "./SafeMath.sol";
import "./ReentrancyGuardUpgradeSafe.sol";

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract AlpacaWorker is Worker, ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    using SafeMath for uint112;
    address public VaultAddress;
    address public UsdVaultAddress;
    address public PancakeswapRouter;
    address public FairLaunch;
    address public UsdAddress;
    address public LpAddress;
    address public AlpacaRemoveStrategyAddress;
    address public AlpacaWorkerAddress;
    address[] public BalanceTokens;
    address public _WETH;
    uint[] private array;
    mapping(uint256 => uint256) private positionIdDict;
    event Log(uint256);
    uint private length = 1;

    function initialize(address weth) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    array.push(type(uint256).max);
     _WETH = weth;
     }
    function Deposit(uint256 amountToken) public
    onlyOperatorOrManager()
    nonReentrant
    {
        TransferHelper.safeApprove(UsdAddress, VaultAddress,  type(uint256).max);
        IAlpacaVault(VaultAddress).deposit(amountToken);
        TransferHelper.safeApprove(UsdAddress, VaultAddress,  uint256(0));
    }
    function Withdraw(uint256 amountShare) public 
    onlyOperatorOrManager()
    nonReentrant
    {
        IAlpacaVault(VaultAddress).withdraw(amountShare);
    }
    function Work(uint256 id, address worker, uint256 principalAmount, 
    uint256 borrowAmount, uint256 maxReturn, bytes memory data)
    public
    onlyOperatorOrManager()
    nonReentrant
    {
        if (id == 0) {
            TransferHelper.safeApprove(UsdAddress, VaultAddress,  type(uint256).max);
            uint256 positionId = IAlpacaVault(VaultAddress).nextPositionID();
            IAlpacaVault(VaultAddress).work(id, worker, principalAmount, borrowAmount, maxReturn, data);
            TransferHelper.safeApprove(UsdAddress, VaultAddress,  uint256(0));
            add(positionId);
        }
        else{
            IAlpacaVault(VaultAddress).work(id, worker, principalAmount, borrowAmount, maxReturn, data);
            remove(id);
        }
    }
    function ClosePosition(uint256 id, uint slippage)
    public onlyOwner returns (uint256)
    {
        uint256 ethBalance = address(this).balance;
        uint256 usdBalance = IShareToken(UsdAddress).balanceOf(address(this));
        uint256 principalAmount = PrincipalVal(id).mul(slippage).div(100);
        emit Log(usdBalance);
        emit Log(ethBalance);
        emit Log(principalAmount);

        bytes memory leftAmount = abi.encode(principalAmount);
        bytes memory stratData = abi.encode(AlpacaRemoveStrategyAddress,leftAmount);
        Work(id,AlpacaWorkerAddress,0,0,type(uint256).max,stratData);
        uint256 swapbnb = address(this).balance - ethBalance;
        if(swapbnb > 0){
            address[] memory path =  new address[](2);
            path[0] = _WETH;
            path[1] = UsdAddress;
            uint256 minSwap = IPancakeRouter01(PancakeswapRouter).getAmountsOut(swapbnb, path)[1];
            SwapEthForToken(ethBalance, minSwap.mul(99).div(100),path,block.timestamp);
        }
        
        return IShareToken(UsdAddress).balanceOf(address(this)) - usdBalance;
    }
    function ForcedClose(uint256 amount)
    public onlyOwner returns (uint256)
    {
        uint256 returnAmount = IShareToken(UsdAddress).balanceOf(address(this));
        if(returnAmount >= amount){
            return amount;
        }
        IAlpacaVault vault = IAlpacaVault(UsdVaultAddress);
        returnAmount = returnAmount + vault.balanceOf(address(this))
        .mul(vault.totalToken()).div(vault.totalSupply());
        if(returnAmount >= amount){
            return amount;
        }
        for(uint i = 1; i < length; i++){
            returnAmount = returnAmount + ClosePosition(array[i], 99);
            if(returnAmount >= amount){
                break;
            }
        }
        return returnAmount >= amount ? amount : returnAmount;

    }
    function TotalVal() 
    public view
    returns(uint256)
    {
        uint256 positionVal = 0;
        IPancakeRouter01 router = IPancakeRouter01(PancakeswapRouter);
        IAlpacaVault vault = IAlpacaVault(VaultAddress);
        for(uint i = 1; i < length; i++){
            positionVal = positionVal.add(PositionVal(array[i]));
        }
        for(uint i = 0; i < BalanceTokens.length; i++){
            address[] memory path =  new address[](2);
            path[0] = BalanceTokens[i];
            path[1] = UsdAddress;
            if(path[0] == _WETH && address(this).balance > 0){
                positionVal = positionVal.add(router.getAmountsOut(
                address(this).balance, path)[1]);
            }
            uint256 tokenBalance = IShareToken(BalanceTokens[i]).balanceOf(address(this));
            if(tokenBalance > 0){
                positionVal = positionVal.add(router.getAmountsOut(tokenBalance, path)[1]);
            }
        }
        positionVal = positionVal.add(IShareToken(UsdAddress).balanceOf(address(this)));
        positionVal = positionVal.add(vault.balanceOf(address(this)).mul(vault.totalToken()).div(vault.totalSupply()));
        return positionVal;
    }
    function PositionVal(uint positionId) public view returns (uint256)
    {
        IAlpacaVault vault = IAlpacaVault(VaultAddress);
        IAlpacaVault.Position memory positions = vault.positions(positionId);
        if(positions.debtShare == 0){
            return 0;
        }
        uint256 debtVal = vault.debtShareToVal(positions.debtShare);
        IPancakeWorker worker = IPancakeWorker(positions.worker);
        uint256 balance = worker.shareToBalance(worker.shares(positionId));
        IPancakePair pair = IPancakePair(LpAddress);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        uint256 token0 = reserve0.mul(balance).div(totalSupply);
        uint256 token1 = reserve1.mul(balance).div(totalSupply).sub(debtVal);
        return token0.add(token1.mul(reserve0).div(reserve1));

    }
    function PrincipalVal(uint positionId) public view returns (uint256)
    {
        IAlpacaVault vault = IAlpacaVault(VaultAddress);
        IAlpacaVault.Position memory positions = vault.positions(positionId);
        if(positions.debtShare == 0){
            return 0;
        }
        uint256 debtVal = vault.debtShareToVal(positions.debtShare);
        IPancakeWorker worker = IPancakeWorker(positions.worker);
        uint256 balance = worker.shareToBalance(worker.shares(positionId));
        IPancakePair pair = IPancakePair(LpAddress);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        uint256 token0 = reserve0.mul(balance).div(totalSupply);
        uint256 token1 = reserve1.mul(balance).div(totalSupply).sub(debtVal);
        return token0.sub(token1.mul(reserve0).div(reserve1));

    }
    function SwapEthForToken(uint ethAmount,uint amountOut, address[] memory path, uint deadline) public 
    onlyOperatorOrManager
    nonReentrant
    returns (uint[] memory amounts)
    {
        require(path[0] == _WETH, "SwapEthForToken: INVALID REQUEST.");
        require(address(this).balance > ethAmount, "SwapEthForToken: INSUFFICIENT FUNDS.");
        IWETH(path[0]).deposit{value: ethAmount}();
        TransferHelper.safeApprove(path[0], PancakeswapRouter,  type(uint256).max);
        uint[] memory res = IPancakeRouter01(PancakeswapRouter).swapExactTokensForTokens(ethAmount, amountOut,path,address(this),deadline);
        TransferHelper.safeApprove(path[0], PancakeswapRouter,  uint256(0));
        return res;
    }
    function SwapTokenForToken(uint amountIn,uint amountOut, address[] calldata path, uint deadline) public 
    onlyOperatorOrManager
    nonReentrant
    returns (uint[] memory amounts)
    {
        TransferHelper.safeApprove(path[0], PancakeswapRouter,  type(uint256).max);
        uint[] memory res = IPancakeRouter01(PancakeswapRouter).swapExactTokensForTokens(amountIn, amountOut,path,address(this),deadline);
        TransferHelper.safeApprove(path[0], PancakeswapRouter,  uint256(0));
        return res;
    }
    function Harvest(uint256 poolId) public onlyManager
    {
       IFairLaunchV1(FairLaunch).harvest(poolId);    
    }
    function PendingAlpaca(uint256 poolId) public view returns (uint256)
    {
        return IFairLaunchV1(FairLaunch).pendingAlpaca(poolId, address(this));
    }
    function UserInfo(uint256 poolId) public view returns (IFairLaunchV1.UserInfo memory)
    {
        return IFairLaunchV1(FairLaunch).userInfo(poolId, address(this));
    }
    function SetVaultAddress(address newVaultAddress) public onlyOperator 
    {
        require(newVaultAddress != address(0), "Operatorable: new VaultAddress is the zero address");
        VaultAddress = newVaultAddress;
    }
    function SetRouterAddress(address newRouterAddress) public onlyOperator 
    {
        require(newRouterAddress != address(0), "Operatorable: new RouterAddress is the zero address");
        PancakeswapRouter = newRouterAddress;
    }
    function SetFairLaunchAddress(address newFairLaunchAddress) public onlyOperator 
    {
        require(newFairLaunchAddress != address(0), "Operatorable: new FairLaunchAddress is the zero address");
        FairLaunch = newFairLaunchAddress;
    }
    function SetLpToken(address newLpAddress) public onlyOperator 
    {
        require(newLpAddress != address(0), "Operatorable: new LpToken is the zero address");
        LpAddress = newLpAddress;
    }
    function SetUsdAddress(address newUsdAddress) public onlyOperator 
    {
        require(newUsdAddress != address(0), "Operatorable: new UsdAddress is the zero address");
        UsdAddress = newUsdAddress;
    }
    function SetUsdVaultAddress(address newUsdVaultAddress) public onlyOperator 
    {
        require(newUsdVaultAddress != address(0), "Operatorable: new UsdAddress is the zero address");
        UsdVaultAddress = newUsdVaultAddress;
    }
    function SetBalaceTokenAddress(address[] calldata balanceTokens) public onlyOperator
    {
        BalanceTokens = balanceTokens;
    }
    function SetAlpacaRemoveStrategyAddress(address removeStrategyAddress) public onlyOperator
    {
        AlpacaRemoveStrategyAddress = removeStrategyAddress;
    }
    function SetAlpacaWorkerAddress(address workerAddress) public onlyOperator
    {
        AlpacaWorkerAddress = workerAddress;
    }

    /**
     * @dev this is only for internal use
    */
    
    function add(uint posId) public
    onlyOperator
    {
        uint idx = positionIdDict[posId];
        require(idx == 0, "positionId alreadt exist");
        if(length >= array.length){
            array.push(posId);
        }
        else{
            array[length] = posId;
        }
        positionIdDict[posId] = length;
        length += 1;
    }
    function remove(uint posId) public
    onlyOperator
    {
        uint idx = positionIdDict[posId];
        require(idx != 0, "positionId doesn't exist");
        
        array[idx] = array[length -1];
        positionIdDict[posId] = 0;
        delete array[length -1];
        length -= 1;
    }
    function ActivePositions() public 
    onlyOperatorOrManager 
    view 
    returns(uint[] memory){
        return array;
    }
    receive() external payable nonReentrant
    {
        
        
    }
    fallback() external payable nonReentrant
    {
        // you can reject the funds (assert/require/revert) under certain conditions...
    }
}