// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "contracts/access/Worker.sol";
import 'contracts/interfaces/IAlpacaVault.sol';
import 'contracts/interfaces/IPancakeRouter01.sol';
import 'contracts/interfaces/IFairLaunch.sol';
import 'contracts/interfaces/IShareToken.sol';
import 'contracts/interfaces/IPancakeWorker.sol';
import 'contracts/interfaces/IPancakePair.sol';



interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract AlpacaWorker is Worker, ReentrancyGuard
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

    constructor(address weth) {
        array.push(type(uint256).max);
        _WETH = weth;
    }
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }
    function Deposit(uint256 amountToken) public
    onlyOperatorOrManager()
    onlyEOA()
    nonReentrant
    {
        TransferHelper.safeApprove(UsdAddress, UsdVaultAddress,  type(uint256).max);
        IAlpacaVault(UsdVaultAddress).deposit(amountToken);
        TransferHelper.safeApprove(UsdAddress, UsdVaultAddress,  uint256(0));
    }
    function Withdraw(uint256 amountShare) public
    onlyOperatorOrManager()
    onlyEOA()
    nonReentrant
    {
        IAlpacaVault(UsdVaultAddress).withdraw(amountShare);
    }
    function _work(uint256 id, address worker, uint256 principalAmount,
    uint256 borrowAmount, uint256 maxReturn, bytes memory data) private
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
    function Work(uint256 id, address worker, uint256 principalAmount,
    uint256 borrowAmount, uint256 maxReturn, bytes memory data)
    public
    onlyOperatorOrManager()
    onlyEOA()
    nonReentrant
    {
        _work(id, worker, principalAmount, borrowAmount, maxReturn, data);

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
        _work(id,AlpacaWorkerAddress,0,0,type(uint256).max,stratData);
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
        vault.withdraw(withdrawAmount);
        returnAmount = IShareToken(UsdAddress).balanceOf(address(this));
        if(returnAmount >= amount){
            return;
        }
        for(uint i = 1; i < length; i++){
            ClosePosition(array[i], 99);
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
                SwapTokenForToken(tokenBalance, minSwap.mul(99).div(100),path,block.timestamp);
                returnAmount = IShareToken(UsdAddress).balanceOf(address(this));
                if(returnAmount >= amount){
                    break;
                }
            }
        }
        return;
    }
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
            return busdBalance.sub((debtVal.sub(bnbBalance)).mul(busdBalance).div(bnbBalance));
        }
        else{
            return busdBalance;
        }
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
    function SwapTokenForToken(uint amountIn,uint amountOut, address[] memory path, uint deadline) public
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Operatable.sol";

contract Worker is Operatable
{
    modifier onlyManager() 
    {
        require(manager() == _msgSender(), "Ownable: caller is not the manager");
        _;
    }
    modifier onlyOperatorOrManager() 
    {
        require(manager() == _msgSender() || operator() == _msgSender(),
         "Ownable: caller is not the operator or the manager");
        _;
    }
    address private Manager;
    address public ShareTokenAddress;
    event TokenAddressUpdated(address indexed previousTokenAddress, address indexed newTokenAddress);
    event ManagerUpdated(address indexed previousManager, address indexed newManager);
    function manager() public view returns(address) 
    {
        return Manager;
    }
    function ApproveToken(address token, address spender, uint256 value) public onlyOwner
    {
        TransferHelper.safeApprove(token, spender, value);
    }
    function SetShareTokenAddress(address newTokenAddress) public onlyOperator {
        require(newTokenAddress != address(0), "Operatorable: new tokenAddress is the zero address");
        _updateTokenAddress(newTokenAddress);
    }
    function SetManagerAddress(address newManagerAddress) public onlyOperator {
        require(newManagerAddress != address(0), "Operatorable: new tokenAddress is the zero address");
        _updateManager(newManagerAddress);
    }
    
    /**
     * @dev Update operator of the contract
     * Internal function without access restriction.
     */
    function _updateTokenAddress(address newTokenAddress) internal{

        address previousTokenAddress = ShareTokenAddress;
        ShareTokenAddress = newTokenAddress;
        emit TokenAddressUpdated(previousTokenAddress, ShareTokenAddress);
    }
    function _updateManager(address newManager) internal{
        address previousManager = Manager;
        Manager = newManager;
        emit ManagerUpdated(previousManager, Manager);
        
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IAlpacaVault {
  struct Position {
        address worker;
        address owner;
        uint256 debtShare;
    }    
  function nextPositionID() external view returns (uint256);
  /// @dev Return the total ERC20 entitled to the token holders. Be careful of unaccrued interests.
  function totalToken() external view returns (uint256);
  function totalSupply()external view returns (uint256);
  /// @dev Add more ERC20 to the bank. Hope to get some good returns.
  function deposit(uint256 amountToken) external payable;

  /// @dev Withdraw ERC20 from the bank by burning the share tokens.
  function withdraw(uint256 share) external;
  
  function token() external view returns (address);
  
  function work(uint256 id, address worker, uint256 principalAmount, uint256 borrowAmount, uint256 maxReturn, bytes calldata data) external payable;
  function positions(uint256 id) external view returns (Position memory);
  function debtShareToVal(uint256 share) external view returns (uint256);
  function balanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IFairLaunchV1 {
  // Data structure
  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
    uint256 bonusDebt;
    address fundedBy;
  }
  struct PoolInfo {
    address stakeToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accAlpacaPerShare;
    uint256 accAlpacaPerShareTilBonusEnd;
  }

  // Information query functions
  function alpacaPerBlock() external view returns (uint256);
  function totalAllocPoint() external view returns (uint256);
  function poolInfo(uint256 pid) external view returns (IFairLaunchV1.PoolInfo memory);
  function userInfo(uint256 pid, address user) external view returns (IFairLaunchV1.UserInfo memory);
  function poolLength() external view returns (uint256);

  // OnlyOwner functions
  function setAlpacaPerBlock(uint256 _alpacaPerBlock) external;
  function setBonus(uint256 _bonusMultiplier, uint256 _bonusEndBlock, uint256 _bonusLockUpBps) external;
  function manualMint(address _to, uint256 _amount) external;
  function addPool(uint256 _allocPoint, address _stakeToken, bool _withUpdate) external;
  function setPool(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;

  // User's interaction functions
  function pendingAlpaca(uint256 _pid, address _user) external view returns (uint256);
  function updatePool(uint256 _pid) external;
  function deposit(address _for, uint256 _pid, uint256 _amount) external;
  function withdraw(address _for, uint256 _pid, uint256 _amount) external;
  function withdrawAll(address _for, uint256 _pid) external;
  function harvest(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IShareToken {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
  function mint(address account, uint256 amount) external;
  function burn(address account, uint256 amount) external;
  function updateShareVal(uint val) external;
  function ShareToAmount(uint256 share) external view returns (uint256);
  function AmountToShare(uint256 amount) external view returns (uint256);
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeWorker
{
    function shares(uint256 id) external view returns (uint256);
    function ApproveToken(address token, address to, uint256 value) external;
    function shareToBalance(uint256 share) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operatable is Ownable {
    address private Operator;
    
    event OperatorUpdated(address indexed previousOperator, address indexed newOperator);
    function operator() public view returns(address) 
    {
        return Operator;
    }
    modifier onlyOperator() 
    {
        require(operator() == _msgSender(), "Ownable: caller is not the operator");
        _;
    }
    function updateOperator(address newOperator) public onlyOwner 
    {
        require(newOperator != address(0), "Ownable: new operator is the zero address");
        _updateOperator(newOperator);
    }

    function emergencyWithdraw(address token, address to,  uint256 value) public onlyOwner 
    {
        TransferHelper.safeTransfer(token, to , value);
    }
    /**
     * @dev Update operator of the contract
     * Internal function without access restriction.
     */
    function _updateOperator(address newOperator) internal {
        address previousOperator = Operator;
        Operator = newOperator;
        emit OperatorUpdated(previousOperator, Operator);
    }
    
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}