/**
 *Submitted for verification at polygonscan.com on 2021-10-11
*/

// File: contracts/PhoenixModules/modules/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    uint256 constant internal calDecimal = 1e18; 
    function mulPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(mul(mul(prices[1],value),calDecimal),prices[0]) :
            div(mul(mul(prices[0],value),calDecimal),prices[1]);
    }
    function divPrice(uint256 value,uint256[2] memory prices,uint8 id)internal pure returns(uint256){
        return id == 0 ? div(div(mul(prices[0],value),calDecimal),prices[1]) :
            div(div(mul(prices[1],value),calDecimal),prices[0]);
    }
}

// File: contracts/PhoenixModules/multiSignature/multiSignatureClient.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */
interface IMultiSignature{
    function getValidSignature(bytes32 msghash,uint256 lastIndex) external view returns(uint256);
}
contract multiSignatureClient{
    uint256 private constant multiSignaturePositon = uint256(keccak256("org.Phoenix.multiSignature.storage"));
    constructor(address multiSignature) public {
        require(multiSignature != address(0),"multiSignatureClient : Multiple signature contract address is zero!");
        saveValue(multiSignaturePositon,uint256(multiSignature));
    }    
    function getMultiSignatureAddress()public view returns (address){
        return address(getValue(multiSignaturePositon));
    }
    modifier validCall(){
        checkMultiSignature();
        _;
    }
    function checkMultiSignature() internal {
        uint256 value;
        assembly {
            value := callvalue()
        }
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, address(this),value,msg.data));
        address multiSign = getMultiSignatureAddress();
        uint256 index = getValue(uint256(msgHash));
        uint256 newIndex = IMultiSignature(multiSign).getValidSignature(msgHash,index);
        require(newIndex > index, "multiSignatureClient : This tx is not aprroved");
        saveValue(uint256(msgHash),newIndex);
    }
    function saveValue(uint256 position,uint256 value) internal 
    {
        assembly {
            sstore(position, value)
        }
    }
    function getValue(uint256 position) internal view returns (uint256 value) {
        assembly {
            value := sload(position)
        }
    }
}

// File: contracts/PhoenixModules/proxyModules/proxyOwner.sol

pragma solidity =0.5.16;

/**
 * @title  proxyOwner Contract

 */

contract proxyOwner is multiSignatureClient{
    bytes32 private constant ownerExpiredPosition = keccak256("org.Phoenix.ownerExpired.storage");
    bytes32 private constant versionPositon = keccak256("org.Phoenix.version.storage");
    bytes32 private constant proxyOwnerPosition  = keccak256("org.Phoenix.Owner.storage");
    bytes32 private constant proxyOriginPosition  = keccak256("org.Phoenix.Origin.storage");
    uint256 private constant oncePosition  = uint256(keccak256("org.Phoenix.Once.storage"));
    uint256 private constant ownerExpired =  90 days;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OriginTransferred(address indexed previousOrigin, address indexed newOrigin);
    constructor(address multiSignature) multiSignatureClient(multiSignature) public{
        _setProxyOwner(msg.sender);
        _setProxyOrigin(tx.origin);
    }
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */

    function transferOwnership(address _newOwner) public onlyOwner
    {
        _setProxyOwner(_newOwner);
    }
    function _setProxyOwner(address _newOwner) internal 
    {
        emit OwnershipTransferred(owner(),_newOwner);
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newOwner)
        }
        position = ownerExpiredPosition;
        uint256 expired = now+ownerExpired;
        assembly {
            sstore(position, expired)
        }
    }
    function owner() public view returns (address _owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            _owner := sload(position)
        }
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require (isOwner(),"proxyOwner: caller must be the proxy owner and a contract and not expired");
        _;
    }
    function transferOrigin(address _newOrigin) public onlyOrigin
    {
        _setProxyOrigin(_newOrigin);
    }
    function _setProxyOrigin(address _newOrigin) internal 
    {
        emit OriginTransferred(txOrigin(),_newOrigin);
        bytes32 position = proxyOriginPosition;
        assembly {
            sstore(position, _newOrigin)
        }
    }
    function txOrigin() public view returns (address _origin) {
        bytes32 position = proxyOriginPosition;
        assembly {
            _origin := sload(position)
        }
    }
    function ownerExpiredTime() public view returns (uint256 _expired) {
        bytes32 position = ownerExpiredPosition;
        assembly {
            _expired := sload(position)
        }
    }
    modifier originOnce() {
        require (msg.sender == txOrigin(),"proxyOwner: caller is not the tx origin!");
        uint256 key = oncePosition+uint32(msg.sig);
        require (getValue(key)==0, "proxyOwner : This function must be invoked only once!");
        saveValue(key,1);
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == owner() && isContract(msg.sender);
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOrigin() {
        require (msg.sender == txOrigin(),"proxyOwner: caller is not the tx origin!");
        checkMultiSignature();
        _;
    }
    modifier OwnerOrOrigin(){
        if (isOwner()){
        }else if(msg.sender == txOrigin()){
            checkMultiSignature();
        }else{
            require(false,"proxyOwner: caller is not owner or origin");
        }
        _;
    }
    function _setVersion(uint256 version_) internal 
    {
        bytes32 position = versionPositon;
        assembly {
            sstore(position, version_)
        }
    }
    function version() public view returns(uint256 version_){
        bytes32 position = versionPositon;
        assembly {
            version_ := sload(position)
        }
    }
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: contracts/PhoenixModules/proxyModules/initializable.sol

pragma solidity =0.5.16;
/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract initializable {

    /**
    * @dev Indicates that the contract has been initialized.
    */
    bool private initialized;

    /**
    * @dev Indicates that the contract is in the process of being initialized.
    */
    bool private initializing;

    /**
    * @dev Modifier to use in the initializer function of a contract.
    */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool wasInitializing = initializing;
        initializing = true;
        initialized = true;

        _;
        initializing = wasInitializing;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        assembly { cs := extcodesize(address) }
        return cs == 0;
    }

}

// File: contracts/PhoenixModules/proxyModules/versionUpdater.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */


contract versionUpdater is proxyOwner,initializable {
    function implementationVersion() public pure returns (uint256);
    function initialize() public initializer versionUpdate {

    }
    modifier versionUpdate(){
        require(implementationVersion() > version() &&  ownerExpiredTime()>now,"New version implementation is already updated!");
        _;
    }
}

// File: contracts/LeveragedManager/ILeverageFactory.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */

interface ILeverageFactory{
    function getLeveragePool(address tokenA,address tokenB,uint256 leverageRatio)external 
        view returns (address _stakePoolA,address _stakePoolB,address _leveragePool);
    function getStakePool(address token)external view returns (address _stakePool);
    function getAllStakePool()external view returns (address payable[] memory);
    function getAllLeveragePool()external view returns (address payable[] memory);
}

// File: contracts/LeveragedManager/leverageDashboardData.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */



/**
 * @title leverage contract Router.
 * @dev A smart-contract which manage leverage smart-contract's and peripheries.
 *
 */
contract leverageDashboardData is versionUpdater {
    uint256 constant internal currentVersion = 1;
    function implementationVersion() public pure returns (uint256) 
    {
        return currentVersion;
    }
    ILeverageFactory public factory;
    uint256 constant internal feeDecimal = 1e8; 
    uint256 constant internal calDecimal = 1e18; 
}

// File: contracts/LeveragedPool/ILeveragedPool.sol

pragma solidity =0.5.16;
interface ILeveragedPool {
    function leverageTokens() external view returns (address,address);
    function setUniswapAddress(address _uniswap)external;
    function setOracleAddress(address oracle)external;
    function setFeeAddress(address payable addrFee) external;
    function setLeverageFee(uint256 _buyFee,uint256 _sellFee,uint256 _rebalanceFee) external;
    function setLeveragePoolInfo(address payable _feeAddress,address leveragePool,address hedgePool,
            address oracle,address swapRouter,address swaplib,address rebaseTokenA,address rebaseTokenB,
            uint256 fees,uint256 _threshold,uint256 rebaseWorth)external;
    function rebalance() external;
    function getLeverageInfo() external view returns (address,address,address,uint256,uint256);
    function getHedgeInfo() external view returns (address,address,address,uint256,uint256);
    function buyPrices() external view returns(uint256,uint256);
    function getUnderlyingPriceView() external view returns(uint256[2]memory);
    function getTokenNetworths() external view returns(uint256,uint256);
    function swapRouter() external view returns(address);
    function sellFee() external view returns(uint256);
    function getSwapRoutingPath(address token0,address token1) external view returns (address[] memory);
}

// File: contracts/stakePool/IStakePool.sol

pragma solidity =0.5.16;
interface IStakePool {
    function modifyPermission(address addAddress,uint256 permission)external;
    function poolToken()external view returns (address);
    function loan(address account) external view returns(uint256);
    function PPTCoin()external view returns (address);
    function interestRate()external view returns (uint64);
    function setInterestRate(uint64 interestrate)external;
    function interestInflation(uint64 inflation)external;
    function poolBalance() external view returns (uint256);
    function borrowLimit(address account)external view returns (uint256);
    function borrow(uint256 amount) external returns(uint256);
    function borrowAndInterest(uint256 amount) external;
    function repay(uint256 amount,bool bAll) external payable;
    function repayAndInterest(uint256 amount) external payable;
    function setPoolInfo(address PPTToken,address stakeToken,uint64 interestrate) external;
}

// File: contracts/uniswap/IUniswapV2Router02.sol

pragma solidity =0.5.16;


interface IUniswapV2Router02 {
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

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/LeveragedManager/leverageDashboard.sol

pragma solidity =0.5.16;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Phoenix
 * Copyright (C) 2020 Phoenix Options Protocol
 */





/**
 * @title leverage contract Router.
 * @dev A smart-contract which manage leverage smart-contract's and peripheries.
 *
 */
contract leverageDashboard is leverageDashboardData{
    using SafeMath for uint256;
    constructor (address multiSignature) proxyOwner(multiSignature) public{
    }

    function setLeverageFactory(address leverageFactory) external originOnce{
        factory = ILeverageFactory(leverageFactory);
    }
    function buyPricesUSD(address leveragedPool) public view returns(uint256,uint256){
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        uint256[2]memory prices = pool.getUnderlyingPriceView();
        (uint256 leveragePrice,uint256 hedgePrice) = pool.buyPrices();
        return (leveragePrice*prices[0],hedgePrice*prices[1]);
    }
    function getLeveragePurchasableAmount(address leveragedPool) public view returns(uint256){
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        (,address stakePool,,uint256 leverageRate,) = pool.getLeverageInfo();
        (uint256 leveragePrice,) = pool.buyPrices();
        return getPurchasableAmount_sub(stakePool,leverageRate,leveragePrice);
    }
    function getHedgePurchasableAmount(address leveragedPool) public view returns(uint256){
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        (,address stakePool,,uint256 leverageRate,) = pool.getHedgeInfo();
        (,uint256 hedgePrice) = pool.buyPrices();
        return getPurchasableAmount_sub(stakePool,leverageRate,hedgePrice);
    }
    function getLeveragePurchasableUSD(address leveragedPool) external view returns(uint256){
        uint256 amount = getLeveragePurchasableAmount(leveragedPool);
        (uint256 leveragePrice,) = buyPricesUSD(leveragedPool);
        return amount.mul(leveragePrice);
    }
    function getHedgePurchasableUSD(address leveragedPool) external view returns(uint256){
        uint256 amount = getHedgePurchasableAmount(leveragedPool);
        (,uint256 hedgePrice) = buyPricesUSD(leveragedPool);
        return amount.mul(hedgePrice);
    }
    function getPurchasableAmount_sub(address stakePool, uint256 leverageRate,uint256 price) 
        internal view returns(uint256){
        uint256 _loan = IStakePool(stakePool).poolBalance();
        uint256 amountLimit = _loan.mul(feeDecimal)/(leverageRate-feeDecimal);
        return amountLimit.mul(calDecimal)/price;
    }
    function buyLeverageAmountsOut(address leveragedPool,address token, uint256 amount)external view returns(uint256){
        uint256 amountLimit = getLeveragePurchasableAmount(leveragedPool);
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        uint256[2]memory prices = pool.getUnderlyingPriceView();
        (uint256 leveragePrice,) = pool.buyPrices(); 
        (address token0,,,,) = pool.getLeverageInfo();
        (address token1,,,,) = pool.getHedgeInfo();
        if (token == token0){
            amount = amount.mul(calDecimal)/leveragePrice;
        }else if(token == token1){
            amount = amount.mulPrice(prices,0)/leveragePrice;
        }else{
            require(false,"Input token is illegal");
        }
        require(amount<=amountLimit,"Stake pool loan is insufficient!");
        return amount;
    }
    function buyHedgeAmountsOut(address leveragedPool,address token, uint256 amount)external view returns(uint256){
        uint256 amountLimit = getHedgePurchasableAmount(leveragedPool);
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        uint256[2]memory prices = pool.getUnderlyingPriceView();
        (,uint256 hedgePrice) = pool.buyPrices(); 
        (address token0,,,,) = pool.getLeverageInfo();
        (address token1,,,,) = pool.getHedgeInfo();

        if (token == token1){
            amount = amount.mul(calDecimal)/hedgePrice;
        }else if(token == token0){
            amount = amount.mulPrice(prices,1)/hedgePrice;
        }else{
            require(false,"Input token is illegal");
        }
        require(amount<=amountLimit,"Stake pool loan is insufficient!");
        return amount;
    }
    function sellLeverageAmountsOut(address leveragedPool, uint256 amount,address outToken)external view returns(uint256,uint256,uint256,uint256){ 
        return sellAmountsOut(leveragedPool,0,amount,outToken);
    }
    function sellHedgeAmountsOut(address leveragedPool, uint256 amount,address outToken)external view returns(uint256,uint256,uint256,uint256){ 
        return sellAmountsOut(leveragedPool,1,amount,outToken);
    }
    function sellAmountsOut(address leveragedPool,uint8 id, uint256 amount,address outToken)internal view returns(uint256,uint256,uint256,uint256){
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        (address token0,address token1,uint256 userLoan,uint256 userPayback) = getPoolInfo(pool,id,amount);
        if (outToken == token1){
            return getSellAmountsIn(pool,id,token0,token1,userLoan,userPayback);
        }else{
            return getSellAmountsOut(pool,id,token0,token1,userLoan,userPayback);
        }
    }
    function getPoolInfo(ILeveragedPool pool,uint8 id, uint256 amount)internal view returns(address,address,uint256,uint256){
                address token0;address token1;
        uint256 networth;uint256 leverageRate;uint256 rebalanceWorth;
        if (id == 0){
            (token0,,,leverageRate,rebalanceWorth) = pool.getLeverageInfo();
            (token1,,,,) = pool.getHedgeInfo();
            (networth,) = pool.getTokenNetworths();
        }else{
            (token0,,,leverageRate,rebalanceWorth) = pool.getHedgeInfo();
            (token1,,,,) = pool.getLeverageInfo();
            (,networth) = pool.getTokenNetworths();
        }
        uint256 userLoan = (amount.mul(rebalanceWorth)/feeDecimal).mul(leverageRate-feeDecimal);
        uint256 userPayback =  amount.mul(networth);
        return (token0,token1,userLoan,userPayback);
    }
    function getSellAmountsIn(ILeveragedPool pool,uint8 id,address token0,address token1,uint256 userLoan,uint256 userPayback) internal view
        returns(uint256,uint256,uint256,uint256) {
        uint256[2]memory prices = pool.getUnderlyingPriceView();
        uint256 sellAmount = userLoan.divPrice(prices,id);
        uint256 amountOut = userLoan/calDecimal;
        uint256 amountIn = getSwapAmountsIn(pool,token0,token1,amountOut);
        uint256 swapRate = amountIn.mul(feeDecimal)/sellAmount;
        sellAmount = userLoan.add(userPayback).divPrice(prices,id);
        userPayback = sellAmount - amountIn;
        uint256 sellFee = pool.sellFee();
        userPayback = userPayback.mul(feeDecimal-sellFee)/feeDecimal; 
        return (userPayback,amountIn,amountOut,swapRate);
    }
    function getSellAmountsOut(ILeveragedPool pool,uint8 id,address token0,address token1,uint256 userLoan,uint256 userPayback) internal view
        returns(uint256,uint256,uint256,uint256) {
        uint256[2]memory prices = pool.getUnderlyingPriceView();
        uint256 amountIn = userLoan.add(userPayback).divPrice(prices,id);
        uint256 amountOut = getSwapAmountsOut(pool,token0,token1,amountIn);
        uint256 swapRate = amountOut.mul(feeDecimal)/(userLoan.add(userPayback)/calDecimal);
        userPayback = amountOut-userLoan/calDecimal;
        uint256 sellFee = pool.sellFee();
        userPayback = userPayback.mul(feeDecimal-sellFee)/feeDecimal; 
        return (userPayback,amountIn,amountOut,swapRate);
    }
    function getSwapAmountsIn(ILeveragedPool pool,address token0,address token1,uint256 amountOut)internal view returns (uint256){
        address router = pool.swapRouter();
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(router);
        address[] memory path = getSwapPath(pool,router,token0,token1);
        uint[] memory amounts = IUniswap.getAmountsIn(amountOut, path);
        return amounts[0];
    }
    function getSwapAmountsOut(ILeveragedPool pool,address token0,address token1,uint256 amountIn)internal view returns (uint256){
        address router = pool.swapRouter();
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(router);
        address[] memory path = getSwapPath(pool,router,token0,token1);
        uint[] memory amounts = IUniswap.getAmountsOut(amountIn, path);
        return amounts[amounts.length-1];
    }
    function getSwapPath(ILeveragedPool pool,address swapRouter,address token0,address token1) internal view returns (address[] memory path){
        path = pool.getSwapRoutingPath(token0,token1);
        if(path.length>0){
            return path;
        }
        IUniswapV2Router02 IUniswap = IUniswapV2Router02(swapRouter);
        path = new address[](2);
        path[0] = token0 == address(0) ? IUniswap.WETH() : token0;
        path[1] = token1 == address(0) ? IUniswap.WETH() : token1;
    }
}