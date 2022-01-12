// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './TransferHelper.sol';
import "./SafeMath.sol";
import "./Math.sol";
import "./Worker.sol";
import './IAlpacaVault.sol';
import './IPancakeRouter01.sol';
import './IFairLaunch.sol';
import './IShareToken.sol';
import './IPancakeWorker.sol';
import './IPancakePair.sol';



interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract AlpacaWorker is Worker, ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeMath for uint112;
    address public VaultAddress;        //the address of ibVault
    address public UsdVaultAddress;     //the address of ibBUSD
    address public PancakeswapRouter;   //the address of PancakeswapRouterV2
    address public FairLaunch;          //the address of Alpaca FairLaunch
    address public UsdAddress;          //the address of BUSD token
    address public LpAddress;           //the address of PancakePair
    address public AlpacaRemoveStrategyAddress; //the address of ClosingWithMinimizedTradingStrategy
    address public AlpacaWorkerAddress;         //the address of Pancakeswap Worker
    address[] public BalanceTokens;         //including WBNB & ALPACA & tokens and be evaluate
    address public _WETH;               
    uint[] private array;               //the active positions array.
    mapping(uint256 => uint256) private positionIdDict; //the dict for positionId => arrayId
    uint private length = 1;

    constructor(address weth) {
        array.push(type(uint256).max);
        _WETH = weth;
    }
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }
    //This function is for depositing remaining BUSD into ibBUSD pool.
    function Deposit(uint256 amountToken) public
    onlyOperatorOrManager()
    onlyEOA()
    nonReentrant
    {
        TransferHelper.safeApprove(UsdAddress, UsdVaultAddress,  type(uint256).max);
        IAlpacaVault(UsdVaultAddress).deposit(amountToken);
        TransferHelper.safeApprove(UsdAddress, UsdVaultAddress,  uint256(0));
    }
    //This function is for withdrawing BUSD from ibBUSD pool.
    function Withdraw(uint256 amountShare) public
    onlyOperatorOrManager()
    onlyEOA()
    nonReentrant
    {
        IAlpacaVault(UsdVaultAddress).withdraw(amountShare);
    }
    //This function is for perform Open/Close leverage farming positions.
    //Notice that this should be called only by EOA to avoid flash loan attack.
    function _work(uint256 id, address worker, uint256 principalAmount,
    uint256 borrowAmount, uint256 maxReturn, bytes memory data) private
    {
        if (id == 0) {
            TransferHelper.safeApprove(UsdAddress, VaultAddress,  type(uint256).max);
            uint256 positionId = IAlpacaVault(VaultAddress).nextPositionID();
            IAlpacaVault(VaultAddress).work(id, worker, principalAmount, borrowAmount, maxReturn, data);
            TransferHelper.safeApprove(UsdAddress, VaultAddress,  uint256(0));
            _add(positionId);
        }
        else{
            IAlpacaVault(VaultAddress).work(id, worker, principalAmount, borrowAmount, maxReturn, data);
            _remove(id);
        }

    }
    function Work(uint256 id, address worker, uint256 principalAmount,
    uint256 borrowAmount, uint256 maxReturn, bytes memory data)
    public
    onlyOperatorOrManager()
    onlyEOA()
    nonReentrant
    {
        _work(id, worker, principalAmount, borrowAmount, maxReturn, data);

    }
    //This function is used to close a position by id.
    //Notice that this should on called by owner.

    function ClosePosition(uint256 id, uint slippage)
    public onlyOwner returns (uint256)
    {
        uint256 ethBalance = address(this).balance;
        uint256 usdBalance = IShareToken(UsdAddress).balanceOf(address(this));
        uint256 principalAmount = PrincipalVal(id).mul(slippage).div(100);
        bytes memory leftAmount = abi.encode(principalAmount);
        bytes memory stratData = abi.encode(AlpacaRemoveStrategyAddress,leftAmount);
        _work(id,AlpacaWorkerAddress,0,0,type(uint256).max,stratData);
        uint256 swapbnb = address(this).balance - ethBalance;
        if(swapbnb > 0){
            address[] memory path =  new address[](2);
            path[0] = _WETH;
            path[1] = UsdAddress;
            uint256 minSwap = IPancakeRouter01(PancakeswapRouter).getAmountsOut(swapbnb, path)[1];
            _swapEthForToken(swapbnb, minSwap.mul(99).div(100),path,block.timestamp);
        }

        return IShareToken(UsdAddress).balanceOf(address(this)) - usdBalance;
    }
    //This function is used to withdraw money & close positions until return enough cash.
    //Notice that this should on called by owner.
    function ForcedClose(uint256 amount)
    public onlyOwner
    {
        uint256 returnAmount = IShareToken(UsdAddress).balanceOf(address(this));
        if(returnAmount >= amount){
            return;
        }
        IAlpacaVault vault = IAlpacaVault(UsdVaultAddress);
        uint256 withdrawAmount = Math.min(
            vault.balanceOf(address(this)),
            (amount - returnAmount).mul(vault.totalSupply()).div(vault.totalToken()));
        if(withdrawAmount > 0){
          vault.withdraw(withdrawAmount);
          returnAmount = IShareToken(UsdAddress).balanceOf(address(this));
          if(returnAmount >= amount){
              return;
          }
        }
        while(length > 1)
        {
          ClosePosition(array[1], 99);
          returnAmount = IShareToken(UsdAddress).balanceOf(address(this));
          if(returnAmount >= amount){
              break;
          }
        }
        if(returnAmount >= amount){
            return;
        }
        for(uint i = 0; i < BalanceTokens.length; i++){
            uint256 tokenBalance = IShareToken(BalanceTokens[i]).balanceOf(address(this));
            if(tokenBalance > 0){
                address[] memory path =  new address[](2);
                path[0] = BalanceTokens[i];
                path[1] = UsdAddress;
                uint256 minSwap = IPancakeRouter01(PancakeswapRouter).getAmountsOut(tokenBalance, path)[1];
                _swapTokenForToken(tokenBalance, minSwap.mul(99).div(100),path,block.timestamp);
                returnAmount = IShareToken(UsdAddress).balanceOf(address(this));
                if(returnAmount >= amount){
                    break;
                }
            }
        }
        return;
    }
    //This function evaluates the totalVal of the contract.

    function TotalVal()
    public view
    returns(uint256)
    {
        uint256 positionVal = 0;
        IPancakeRouter01 router = IPancakeRouter01(PancakeswapRouter);
        IAlpacaVault vault = IAlpacaVault(UsdVaultAddress);
        for(uint i = 1; i < length; i++){
            positionVal = positionVal.add(PositionVal(array[i]));
        }
        for(uint i = 0; i < BalanceTokens.length; i++){
            address[] memory path =  new address[](2);
            path[0] = BalanceTokens[i];
            path[1] = UsdAddress;
            uint256 tokenBalance = IShareToken(BalanceTokens[i]).balanceOf(address(this));
            if(tokenBalance > 0){
                positionVal = positionVal.add(router.getAmountsOut(tokenBalance, path)[1]);
            }
        }
        positionVal = positionVal.add(IShareToken(UsdAddress).balanceOf(address(this)));
        positionVal = positionVal.add(vault.balanceOf(address(this)).mul(vault.totalToken()).div(vault.totalSupply()));
        return positionVal;
    }
    //This function evaluates the positionVal of a leverage farming position.
    function PositionVal(uint positionId) public view returns (uint256)
    {
        uint256 debtVal;
        uint256 balance;
        //To avoid stack too deep
        {
            IAlpacaVault vault = IAlpacaVault(VaultAddress);
            IAlpacaVault.Position memory positions = vault.positions(positionId);
            if(positions.debtShare == 0){
                return 0;
            }
            debtVal = vault.debtShareToVal(positions.debtShare);
            IPancakeWorker worker = IPancakeWorker(positions.worker);
            balance = worker.shareToBalance(worker.shares(positionId));
        }
        uint256 bnbReserve;
        uint256 busdReserve;
        uint256 totalSupply;

        {
            IPancakePair pair = IPancakePair(LpAddress);
            address token0 = pair.token0();
            (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
            bnbReserve = token0 == _WETH ? reserve0 : reserve1;
            busdReserve = token0 == _WETH ? reserve1 : reserve0;
            totalSupply = pair.totalSupply();
        }
        uint256 bnbBalance = bnbReserve.mul(balance).div(totalSupply);
        uint256 busdBalance = busdReserve.mul(balance).div(totalSupply);
        if(bnbBalance < debtVal){
            return busdBalance.sub((debtVal.sub(bnbBalance)).mul(busdBalance).div(bnbBalance));
        }
        else{
            return busdBalance.add((bnbBalance.sub(debtVal)).mul(busdReserve).div(bnbReserve));
        }
    }
    //This function evaluates the base token val of a position.
    //Mainly used as parameters for closing position.
    //In this case, it's goint to be the BUSD value minus BNB debt.
    function PrincipalVal(uint positionId) public view returns (uint256)
    {
        uint256 debtVal;
        uint256 balance;
        //To avoid stack too deep
        {
            IAlpacaVault vault = IAlpacaVault(VaultAddress);
            IAlpacaVault.Position memory positions = vault.positions(positionId);
            if(positions.debtShare == 0){
                return 0;
            }
            debtVal = vault.debtShareToVal(positions.debtShare);
            IPancakeWorker worker = IPancakeWorker(positions.worker);
            balance = worker.shareToBalance(worker.shares(positionId));
        }
        uint256 bnbReserve;
        uint256 busdReserve;
        uint256 totalSupply;
        //To avoid stack too deep
        {
            IPancakePair pair = IPancakePair(LpAddress);
            address token0 = pair.token0();
            (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
            bnbReserve = token0 == _WETH ? reserve0 : reserve1;
            busdReserve = token0 == _WETH ? reserve1 : reserve0;
            totalSupply = pair.totalSupply();
        }
        uint256 bnbBalance = bnbReserve.mul(balance).div(totalSupply);
        uint256 busdBalance = busdReserve.mul(balance).div(totalSupply);
        if(bnbBalance < debtVal){
            // when debt is bigger than actual BNB in position, return BUSD - ((debt - BNB) * BNBPrice)
            return busdBalance.sub((debtVal.sub(bnbBalance)).mul(busdBalance).div(bnbBalance));
        }
        else{
            return busdBalance;
        }
    }
    function _swapEthForToken(uint ethAmount,uint amountOut, address[] memory path, uint deadline) private returns (uint[] memory amounts){
      require(path[0] == _WETH, "SwapEthForToken: INVALID REQUEST.");
      require(address(this).balance >= ethAmount, "SwapEthForToken: INSUFFICIENT FUNDS.");
      IWETH(path[0]).deposit{value: ethAmount}();
      TransferHelper.safeApprove(path[0], PancakeswapRouter,  type(uint256).max);
      uint[] memory res = IPancakeRouter01(PancakeswapRouter).swapExactTokensForTokens(ethAmount, amountOut,path,address(this),deadline);
      TransferHelper.safeApprove(path[0], PancakeswapRouter,  uint256(0));
      return res;

    }
    //This function swap BNB to other tokens.
    //This is mainly used when BNB returned after position closed.
    function SwapEthForToken(uint ethAmount,uint amountOut, address[] memory path, uint deadline) public
    onlyOperatorOrManager
    nonReentrant
    returns (uint[] memory amounts)
    {
       return _swapEthForToken(ethAmount,amountOut,path,deadline);
    }
    function _swapTokenForToken(uint amountIn,uint amountOut, address[] memory path, uint deadline) private returns (uint[] memory amounts)

    {
        TransferHelper.safeApprove(path[0], PancakeswapRouter,  type(uint256).max);
        uint[] memory res = IPancakeRouter01(PancakeswapRouter).swapExactTokensForTokens(amountIn, amountOut,path,address(this),deadline);
        TransferHelper.safeApprove(path[0], PancakeswapRouter,  uint256(0));
        return res;
    }
    //This function swap token to other tokens.
    //This is mainly used when ALPACA to BUSD when harvest.
    function SwapTokenForToken(uint amountIn,uint amountOut, address[] memory path, uint deadline) public
    onlyOperatorOrManager
    nonReentrant
    returns (uint[] memory amounts)
    {
      return _swapTokenForToken(amountIn, amountOut, path, deadline);

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
    function _add(uint posId) private{
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
    function AddPosition(uint posId) public
    onlyOperator
    {
      _add(posId);
    }
    function _remove(uint posId) private{
      require(length > 1, "cannot perform remove on empty array");
      uint idx = positionIdDict[posId];
      require(idx != 0, "positionId doesn't exist");
      array[idx] = array[length -1];
      positionIdDict[posId] = 0;
      positionIdDict[array[length -1]] = idx;
      delete array[length -1];
      length -= 1;
    }
    function RemovePosition(uint posId) public
    onlyOperator
    {
      _remove(posId);

    }
    function ActivePositions() public
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