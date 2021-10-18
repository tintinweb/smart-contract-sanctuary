/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/IFundPool.sol

pragma solidity ^0.6.12;

abstract contract IFundPool {
    function token() external view virtual returns (address);

    function takeToken(uint256 amount) external virtual;

    function getTotalTokensByProfitRate()
        external
        view
        virtual
        returns (
            address,
            uint256,
            uint256
        );

    function profitRatePerBlock() external view virtual returns (uint256);

    function getTokenBalance() external view virtual returns (address, uint256);

    function getTotalTokenSupply()
        external
        view
        virtual
        returns (address, uint256);

    function returnToken(uint256 amount) external virtual;

    function deposit(uint256 amount, string memory channel) external virtual;
    
    function totalShares() external view virtual returns (uint256);
}

// File: contracts/interfaces/IStrategy.sol

pragma solidity ^0.6.12;

abstract contract IStrategy {
    function earn(address[] memory tokens, uint256[] memory amounts, address[] memory earnTokens, uint256[] memory amountLimits) external virtual;
    function withdraw(address token) external virtual returns (uint256);
    function withdraw(uint256 amount) external virtual returns (address[] memory tokens, uint256[] memory amounts);
    function withdraw(address[] memory tokens, uint256 amount) external virtual returns (uint256, address[] memory, uint256[] memory);
    function withdrawProfit(address token, uint256 amount) external virtual returns (uint256, address[] memory, uint256[] memory);
    function reinvestment(address[] memory pools, address[] memory tokens, uint256[] memory amounts) external virtual;
    function getTokenAmounts() external view virtual returns (address[] memory tokens, uint256[] memory amounts);
    function getTokens() external view virtual returns (address[] memory tokens);
    function getProfitTokens() external view virtual returns (address[] memory tokens);
    function getProfitAmount() view external virtual returns (address[] memory tokens, uint256[] memory amounts, uint256[] memory pendingAmounts);
    function isStrategy() external view virtual returns (bool);
}

// File: contracts/interfaces/IFactory.sol

pragma solidity >=0.5.0;

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// File: contracts/interfaces/IPair.sol

pragma solidity >=0.5.0;

interface IPair {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
}

// File: contracts/PriceView.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;




interface IToken{
    function decimals() view external returns (uint256);
}

contract PriceView {
    using SafeMath for uint256;
    address public admin;
    address public owner;
    address[] public factorys;
    address public anchorToken;
    address public usdt;
    uint256 constant private one = 1e8;
    struct PairInfo{
        address pair;
        address token0;
    }
    mapping(bytes32 => address[]) public pathsMap;
    mapping(bytes32 => PairInfo) public pairMap;
    event NewPathsKey(bytes32 keyHash);
    event NewPairKey(bytes32 keyHash);

    constructor(address _anchorToken, address _usdt, address[] memory _factorys) public {
        admin = msg.sender;
        owner = msg.sender;
        anchorToken = _anchorToken;
        usdt = _usdt;
        for(uint256 i = 0; i < _factorys.length; i++){
            factorys.push(_factorys[i]);
        }
    }

    function setAdmin(address _admin) external{
        require(msg.sender == admin, "!admin");
        admin = _admin;
    }

    function setOwner(address _owner) external{
        require(msg.sender == owner, "!owner");
        owner = _owner;
    }

    function setPathsMap(address token, address factory, address[] memory paths) external{
        require(msg.sender == admin, "!admin");
        require(paths[0] == token && paths[paths.length-1] == anchorToken, "Invalid paths");
        bytes32 keyHash = keccak256((abi.encodePacked(token,factory)));
        delete pathsMap[keyHash];
        for(uint256 i = 0; i < paths.length; i++){
            pathsMap[keyHash].push(paths[i]);
        }
        emit NewPathsKey(keyHash);
    }

    function syncTokenPair(address token) external{
        require(msg.sender == owner, "!owner");
        if(token == anchorToken) return;
        for(uint256 i=0;i < factorys.length;i++){
            address[] memory paths = getTokenPaths(token, factorys[i]);
            for(uint256 j = 0; j < paths.length.sub(1); j++){
                syncPairInfo(paths[j],paths[j+1],factorys[i]);
            }
        }
    }

    function getPrice(address token) view external returns (uint256){
        if(token == anchorToken) return one;
        (uint256 tokenReserve,uint256 anchorTokenReserve) = getReserves(token);
        return one.mul(anchorTokenReserve).div(tokenReserve);
    }

    function getPriceInUSDT(address token) view external returns (uint256){
        uint256 decimals = IToken(token).decimals();
        if(token == usdt) return 10 ** decimals;
        decimals = IToken(anchorToken).decimals();
        uint256 price = 10 ** decimals;
        if(token != anchorToken){
            decimals = IToken(token).decimals();
            (uint256 tokenReserve, uint256 anchorTokenReserve) = getReserves(token);
            price = (10 ** decimals).mul(anchorTokenReserve).div(tokenReserve);
        }
        if(anchorToken != usdt){
            (uint256 usdtReserve, uint256 anchorTokenReserve) = getReserves(usdt);
            price = price.mul(usdtReserve).div(anchorTokenReserve);
        }
        return price;
    }

    function getReserves(address token) view private returns(uint256 tokenReserve, uint256 anchorTokenReserve){
        for(uint256 i=0;i < factorys.length;i++){
            address[] memory paths = getTokenPaths(token, factorys[i]);
            (uint256 reserveA,uint256 reserveB)= getReservesWithPaths(paths,factorys[i]);
            tokenReserve = tokenReserve.add(reserveA);
            anchorTokenReserve = anchorTokenReserve.add(reserveB);
        }
    }

    function getReservesWithPaths(address[] memory paths, address factory) view private returns(uint256 reserveA, uint256 reserveB){
        (reserveA, reserveB) = getReserves(paths[0],paths[1],factory);
        for(uint256 i = 1; i < paths.length.sub(1); i++){
            (uint256 reserve0,uint256 reserve1) = getReserves(paths[i],paths[i+1],factory);
            reserveB = reserveB.mul(reserve1).div(reserve0);
        }
    }

    function getReserves(address tokenA, address tokenB, address factory) view private returns(uint256 reserveA, uint256 reserveB){
        bytes32 keyHash = keccak256((abi.encodePacked(tokenA,tokenB,factory)));
        PairInfo memory pairInfo = pairMap[keyHash];
        if(pairInfo.pair == address(0)) return (0, 0);
        (uint256 reserve0, uint256 reserve1,) = IPair(pairInfo.pair).getReserves();
        (reserveA, reserveB) = tokenA == pairInfo.token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getTokenPaths(address token, address factory) view private returns(address[] memory){
        bytes32 keyHash = keccak256((abi.encodePacked(token,factory)));
        address[] memory paths = pathsMap[keyHash];
        if(paths.length == 0){
            paths = new address[](2);
            paths[0] = token;
            paths[1] = anchorToken;
        } 
        return paths;
    }

    function syncPairInfo(address tokenA, address tokenB, address factory) private{
        bytes32 keyHash = keccak256((abi.encodePacked(tokenA,tokenB,factory)));
        PairInfo memory pairInfo = pairMap[keyHash];
        if(pairInfo.pair != address(0)) return;
        pairInfo.pair = IFactory(factory).getPair(tokenA, tokenB);
        if(pairInfo.pair == address(0)) return;
        pairInfo.token0 = IPair(pairInfo.pair).token0();
        pairMap[keyHash] = pairInfo;
        emit NewPairKey(keyHash);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/SVaultNetValueStorage.sol

pragma solidity ^0.6.12;



contract AdminStorage is Ownable {
    address public admin;

    address public implementation;
}

contract CommissionPoolStorage is AdminStorage {
    mapping(address => CommissionRate[]) public commissionRatePositive;
    mapping(address => CommissionRate[]) public commissionRateNegative;
    struct CommissionRate {
        uint256 apyScale; //scale by 1e6
        uint256 rate; //scale by 1e6
        bool isAllowance;
    }
    uint256 public commissionAmountInPools;
    mapping(address => uint256) public netValuePershareLast; //scale by 1e18
    uint256 public blockTimestampLast;
    bool public isCommissionPaused;
    uint256 public excessLimitInAmout;
    uint256 public excessLimitInRatio;
}

contract SVaultNetValueStorage is CommissionPoolStorage {
    address public controller;
    PriceView public priceView;
    mapping(address => uint256) public poolWeight;
    uint256 public tokenCount = 1;
    uint256 public poolWeightLimit;
    struct PoolInfo {
        address pool;
        address token;
        uint256 amountInUSD;
        uint256 weight;
        uint256 profitWeight;
        uint256 allocatedProfitInUSD;
        uint256 price;
    }
    struct NetValue {
        address pool;
        address token;
        uint256 amount;
        uint256 amountInUSD;
        uint256 totalTokens;
        uint256 totalTokensInUSD;
    }
    struct TokenPrice {
        address token;
        uint256 price;
    }
}

// File: contracts/interfaces/IController.sol

pragma solidity ^0.6.12;


interface IController {
    struct TokenAmount{
        address token;
        uint256 amount;
    }
    function withdraw(uint256 _amount, uint256 _profitAmount) external returns (TokenAmount[] memory);
    function accrueProfit() external returns (SVaultNetValueStorage.NetValue[] memory netValues);
    function getStrategies() view external returns(address[] memory);
    function getFixedPools() view external returns(address[] memory);
    function getFlexiblePools() view external returns(address[] memory);
    function allocatedProfit(address _pool) view external returns(uint256);
    function acceptedPools(address token, address pool) view external returns(bool);
    function getFixedPoolsLength()view external returns (uint256);
    function getFlexiblePoolsLength() view external returns (uint256);
    function withdrawCommssionProfit(address[] memory withdrawTokens, uint256[] memory withdrawAmounts,address fundManager)external;
}

// File: contracts/SVaultNetValue.sol

pragma solidity ^0.6.12;





contract SVaultNetValue is SVaultNetValueStorage {
    using SafeMath for uint256;
   //@notice  The number of seconds in a year
    uint256 public constant SECONDS_YEAR = 31536000;
    uint256 public constant MAX_UINT256 = 2**256-1;
    event PoolWeight(address pool, uint256 weight);
    event CommissionFloat(address pool, bool isAllowance,uint256 commission);
    event CommissionTaken(address taker,uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "!admin");
        _;
    }

    function initialize(address _controller, address _priceView) public {
        require(msg.sender == admin, "unautherized");
        require(controller == address(0), "already initialized");
        controller = _controller;
        priceView = PriceView(_priceView);
        isCommissionPaused = true;
    }

    function setPoolWeightLimit (uint256 _poolWeightLimit) public onlyOwner{
        poolWeightLimit = _poolWeightLimit;
    }

    function setPoolWeight(address[] memory pools, uint256[] memory weights) external onlyOwner{
        require(pools.length == weights.length, "Invalid input");
        IController(controller).accrueProfit();
        address[] memory flexiblePools = IController(controller).getFlexiblePools();
        for(uint256 i = 0; i < pools.length; i++){
            require(hasItem(flexiblePools,pools[i]),"Invalid pool");
            require(weights[i] > 0, "Invalid weight");
            poolWeight[pools[i]] = weights[i];        
            emit PoolWeight(pools[i], weights[i]);
        }
        uint256 totalWeight;
        for(uint256 i = 0; i < flexiblePools.length; i++){
            totalWeight = totalWeight.add(poolWeight[flexiblePools[i]]);
        }
        require(totalWeight < poolWeightLimit,"overflow");
    }

    function removePoolWeight(address pool) external onlyOwner{
        IController(controller).accrueProfit();
        delete poolWeight[pool];
        emit PoolWeight(pool, 0);
    }

    function setTokenCount(uint256 count) external onlyOwner{
        require(count > 0, "Invalid input");
        tokenCount = count;
    }



    function getNetValue(address pool) view external returns(NetValue memory,NetValue memory,uint256,uint256){
        (NetValue[] memory netValues,NetValue[] memory netValuesNew) = getNetValuesInView();
        for(uint256 i = 0; i < netValues.length; i++){
            if(netValues[i].pool == pool) return (netValues[i],netValuesNew[i],block.timestamp,block.number);
        }
    }

    function getNetValues() public returns(NetValue[] memory netValues){
       require(msg.sender == controller, "forbidden");
       uint256 newCommission;
       (netValues, newCommission) = getNetValuesInAction();
       if(!isCommissionPaused){
          updateCommission(netValues,newCommission);
       }
       
    } 
    function updateCommission(NetValue[] memory netValues,uint256 newCommission) internal{
        uint256 fixedPoolsLength = IController(controller).getFixedPoolsLength();
        uint256 flexiblePoolsLength = IController(controller).getFlexiblePoolsLength();
    
        for(uint256 i = 0; i < flexiblePoolsLength; i++){
            SVaultNetValue.NetValue memory netValue = netValues[fixedPoolsLength+i];
            uint256 share = IFundPool(netValue.pool).totalShares();
            netValuePershareLast[netValue.pool] = share == 0 ? 1e12 : netValue.totalTokens.mul(1e12).div(share);
        }
        blockTimestampLast = block.timestamp;
        commissionAmountInPools = newCommission;
    }

    function getNetValuesInView() view public returns(NetValue[] memory netValues,NetValue[] memory netValuesNew){
        address[] memory fixedPools = IController(controller).getFixedPools();
        address[] memory flexiblePools = IController(controller).getFlexiblePools();         
        TokenPrice[] memory tokenPrices = new TokenPrice[](tokenCount);
        // get all tokens in pool and strategy
        uint256 allTokensInUSD = getAllTokensInUSD(fixedPools, flexiblePools, tokenPrices);
        netValues = new NetValue[](fixedPools.length.add(flexiblePools.length));
        uint256 totalFixedPoolUSD = 0;
        for(uint256 i = 0; i < fixedPools.length; i++){
            netValues[i].pool = fixedPools[i];
            (netValues[i].token, netValues[i].amount, netValues[i].totalTokens) = IFundPool(fixedPools[i]).getTotalTokensByProfitRate();
            uint256 price = getTokenPrice(tokenPrices, netValues[i].token);
            netValues[i].amountInUSD = price.mul(netValues[i].amount);
            netValues[i].totalTokensInUSD = price.mul(netValues[i].totalTokens);
            totalFixedPoolUSD = totalFixedPoolUSD.add(netValues[i].totalTokensInUSD);
        }
        if(allTokensInUSD < totalFixedPoolUSD) return (netValues,netValues);
        allTokensInUSD = allTokensInUSD.sub(totalFixedPoolUSD);
        if(allTokensInUSD > commissionAmountInPools) allTokensInUSD = allTokensInUSD.sub(commissionAmountInPools);
        (PoolInfo[] memory poolInfos, uint256 totalWeight, uint256 totalProfitWeight, uint256 totalAmountInUSD, uint256 totalAllocatedProfitInUSD) = getPoolInfos(flexiblePools, tokenPrices);
        uint256 totalProfitAmountInUSD = 0;
        allTokensInUSD = allTokensInUSD.sub(totalAllocatedProfitInUSD);
        if(allTokensInUSD < totalAmountInUSD){
            totalAmountInUSD = allTokensInUSD;
        }else{
            totalProfitAmountInUSD = allTokensInUSD.sub(totalAmountInUSD);
        }

        for(uint256 i = 0; i < poolInfos.length; i++){
            NetValue memory netValue = netValues[fixedPools.length+i];
            netValue.pool = poolInfos[i].pool;
            netValue.token = poolInfos[i].token;
            netValue.amountInUSD = totalWeight == 0 ? 0 : totalAmountInUSD.mul(poolInfos[i].weight).div(totalWeight);
            uint256 allocatedProfitInUSD = poolInfos[i].allocatedProfitInUSD;
             if(netValue.amountInUSD < poolInfos[i].amountInUSD){
                uint256 lossAmountInUSD = poolInfos[i].amountInUSD.sub(netValue.amountInUSD);
                lossAmountInUSD = lossAmountInUSD > allocatedProfitInUSD ? allocatedProfitInUSD : lossAmountInUSD;
                netValue.amountInUSD = netValue.amountInUSD.add(lossAmountInUSD);
                allocatedProfitInUSD = allocatedProfitInUSD.sub(lossAmountInUSD);
            }
            netValue.totalTokensInUSD = netValue.amountInUSD.add(totalProfitWeight == 0 ? 0 : totalProfitAmountInUSD.mul(poolInfos[i].profitWeight).div(totalProfitWeight)).add(allocatedProfitInUSD);
            netValue.amount =netValue.amountInUSD.div(poolInfos[i].price);
            netValue.totalTokens = netValue.totalTokensInUSD.div(poolInfos[i].price);
        }
       //  commision calculalte 
        if(!isCommissionPaused) 
        (netValuesNew) = commissionFixedInView(fixedPools.length,poolInfos,netValues);
          else
          netValuesNew = netValues;
        return (netValues,netValuesNew);
                 
    }

    function commissionFixedInView(uint256 fixedPoolLength,PoolInfo[] memory poolInfos,NetValue[] memory netValues)internal view returns(NetValue[] memory){
        (bool[] memory isPositive,address[] memory pools,uint256[] memory commissions,) = calculalteCommission(netValues,fixedPoolLength,poolInfos.length);
        NetValue[] memory netValuesNew= new NetValue[](netValues.length);
            for(uint256 i = 0; i < poolInfos.length; i++){
                for(uint256 j = 0; j < pools.length; j++)
                {
                if( netValues[fixedPoolLength+i].pool == pools[j]){
                    if(isPositive[j]){                      
                        netValuesNew[fixedPoolLength+i].totalTokensInUSD=netValues[fixedPoolLength+i].totalTokensInUSD.add(commissions[j]);
                        netValuesNew[fixedPoolLength+i].totalTokens =  netValuesNew[fixedPoolLength+i].totalTokensInUSD.div(poolInfos[i].price);
                    }else{
                        netValuesNew[fixedPoolLength+i].totalTokensInUSD=netValues[fixedPoolLength+i].totalTokensInUSD.sub(commissions[j]);
                        netValuesNew[fixedPoolLength+i].totalTokens =   netValuesNew[fixedPoolLength+i].totalTokensInUSD.div(poolInfos[i].price);
                    }
                    } 
                }
            }
            return (netValuesNew);
    }


    function getNetValuesInAction() internal returns(NetValue[] memory netValues, uint256 newCommission){
        address[] memory fixedPools = IController(controller).getFixedPools();
        address[] memory flexiblePools = IController(controller).getFlexiblePools();         
        TokenPrice[] memory tokenPrices = new TokenPrice[](tokenCount);
        // get all tokens in pool and strategy
        uint256 allTokensInUSD = getAllTokensInUSD(fixedPools, flexiblePools, tokenPrices);
        netValues = new NetValue[](fixedPools.length.add(flexiblePools.length));
        uint256 totalFixedPoolUSD = 0;
        for(uint256 i = 0; i < fixedPools.length; i++){
            netValues[i].pool = fixedPools[i];
            (netValues[i].token, netValues[i].amount, netValues[i].totalTokens) = IFundPool(fixedPools[i]).getTotalTokensByProfitRate();
            uint256 price = getTokenPrice(tokenPrices, netValues[i].token);
            netValues[i].amountInUSD = price.mul(netValues[i].amount);
            netValues[i].totalTokensInUSD = price.mul(netValues[i].totalTokens);
            totalFixedPoolUSD = totalFixedPoolUSD.add(netValues[i].totalTokensInUSD);
        }
        if(allTokensInUSD < totalFixedPoolUSD) return (netValues,commissionAmountInPools);
        allTokensInUSD = allTokensInUSD.sub(totalFixedPoolUSD);
        if(allTokensInUSD > commissionAmountInPools) allTokensInUSD = allTokensInUSD.sub(commissionAmountInPools);
        (PoolInfo[] memory poolInfos, uint256 totalWeight, uint256 totalProfitWeight, uint256 totalAmountInUSD, uint256 totalAllocatedProfitInUSD) = getPoolInfos(flexiblePools, tokenPrices);
        uint256 totalProfitAmountInUSD = 0;
        allTokensInUSD = allTokensInUSD.sub(totalAllocatedProfitInUSD);
        if(allTokensInUSD < totalAmountInUSD){
            totalAmountInUSD = allTokensInUSD;
        }else{
            totalProfitAmountInUSD = allTokensInUSD.sub(totalAmountInUSD);
        }

        for(uint256 i = 0; i < poolInfos.length; i++){
            NetValue memory netValue = netValues[fixedPools.length+i];
            netValue.pool = poolInfos[i].pool;
            netValue.token = poolInfos[i].token;
            netValue.amountInUSD = totalWeight == 0 ? 0 : totalAmountInUSD.mul(poolInfos[i].weight).div(totalWeight);
            uint256 allocatedProfitInUSD = poolInfos[i].allocatedProfitInUSD;
             if(netValue.amountInUSD < poolInfos[i].amountInUSD){
                uint256 lossAmountInUSD = poolInfos[i].amountInUSD.sub(netValue.amountInUSD);
                lossAmountInUSD = lossAmountInUSD > allocatedProfitInUSD ? allocatedProfitInUSD : lossAmountInUSD;
                netValue.amountInUSD = netValue.amountInUSD.add(lossAmountInUSD);
                allocatedProfitInUSD = allocatedProfitInUSD.sub(lossAmountInUSD);
            }
            netValue.totalTokensInUSD = netValue.amountInUSD.add(totalProfitWeight == 0 ? 0 : totalProfitAmountInUSD.mul(poolInfos[i].profitWeight).div(totalProfitWeight)).add(allocatedProfitInUSD);
            netValue.amount =netValue.amountInUSD.div(poolInfos[i].price);
            netValue.totalTokens = netValue.totalTokensInUSD.div(poolInfos[i].price);
        }
       //  commision calculalte 
        if(!isCommissionPaused) 
       
        (netValues,newCommission) = commissionFixed(fixedPools.length,poolInfos,netValues);
        else newCommission = commissionAmountInPools;
        return (netValues,newCommission);
                 
    }

    function commissionFixed(uint256 fixedPoolLength,PoolInfo[] memory poolInfos,NetValue[] memory netValues)internal  returns(NetValue[] memory,uint256){
        (bool[] memory isPositive,address[] memory pools,uint256[] memory commissions,uint256 newCommission) = calculalteCommission(netValues,fixedPoolLength,poolInfos.length);
            for(uint256 i = 0; i < poolInfos.length; i++){
                NetValue memory netValue = netValues[fixedPoolLength+i];
                for(uint256 j = 0; j < pools.length; j++)
                {
                if( netValue.pool == pools[j]){
                    uint256 tokenInUSDBefore = netValue.totalTokensInUSD;
                    uint256 tokenBefore = netValue.totalTokens;
                    if(isPositive[j]){
                        netValue.totalTokensInUSD=netValue.totalTokensInUSD.add(commissions[j]);
                        netValue.totalTokens = netValue.totalTokensInUSD.div(poolInfos[i].price);
                    }else{
                        netValue.totalTokensInUSD=netValue.totalTokensInUSD.sub(commissions[j]);
                        netValue.totalTokens = netValue.totalTokensInUSD.div(poolInfos[i].price);
                    }
                    emit CommissionFloat(pools[j],isPositive[j],commissions[j]);
                    } 
                }
            }
            return (netValues,newCommission);
    }

    //get flexible pool weight
    function getPoolInfos(address[] memory flexiblePools, TokenPrice[] memory tokenPrices) view internal returns (PoolInfo[] memory, uint256, uint256, uint256, uint256){
        PoolInfo[] memory poolWeights = new PoolInfo[](flexiblePools.length);
        uint256 totalProfitWeight = 0;
        uint256 totalAmountInUSD = 0;
        uint256 totalAllocatedProfitInUSD = 0;
        uint256 amount = 0;
        for(uint256 i = 0; i < flexiblePools.length; i++){
            poolWeights[i].pool = flexiblePools[i];
            (poolWeights[i].token, amount) = IFundPool(flexiblePools[i]).getTotalTokenSupply();
            poolWeights[i].price = getTokenPrice(tokenPrices, poolWeights[i].token);
            poolWeights[i].amountInUSD = poolWeights[i].price.mul(amount);
            poolWeights[i].weight = poolWeights[i].amountInUSD;
            uint256 profitWeight = poolWeight[poolWeights[i].pool];
            poolWeights[i].profitWeight = poolWeights[i].weight.mul(profitWeight);
            poolWeights[i].allocatedProfitInUSD = IController(controller).allocatedProfit(poolWeights[i].pool).mul(poolWeights[i].price);
            totalAmountInUSD = totalAmountInUSD.add(poolWeights[i].amountInUSD);
            totalProfitWeight = totalProfitWeight.add(poolWeights[i].profitWeight);
            totalAllocatedProfitInUSD = totalAllocatedProfitInUSD.add(poolWeights[i].allocatedProfitInUSD);
        }
        
        return (poolWeights,totalAmountInUSD,totalProfitWeight,totalAmountInUSD,totalAllocatedProfitInUSD);
    }

    function getAllTokensInUSD(address[] memory fixedPools, address[] memory flexiblePools, TokenPrice[] memory tokenPrices) view internal returns(uint256){
        uint256 allTokensInUSD = 0;
        for(uint256 i = 0; i < fixedPools.length; i++){
            (address token, uint256 tokenBalance) = IFundPool(fixedPools[i]).getTokenBalance();
            if(tokenBalance == 0) continue;
            allTokensInUSD = allTokensInUSD.add(getTokenPrice(tokenPrices, token).mul(tokenBalance));
        }
        for(uint256 i = 0; i < flexiblePools.length; i++){
            (address token, uint256 tokenBalance) = IFundPool(flexiblePools[i]).getTokenBalance();
            if(tokenBalance == 0) continue;
            allTokensInUSD = allTokensInUSD.add(getTokenPrice(tokenPrices, token).mul(tokenBalance));
        }
        address[] memory strategies = IController(controller).getStrategies();
        for(uint256 i = 0; i < strategies.length; i++) {
            (address[] memory tokens, uint256[] memory amounts) = IStrategy(strategies[i]).getTokenAmounts();
            for(uint256 j = 0; j < tokens.length; j++){
                if(amounts[j] == 0) continue;
                allTokensInUSD = allTokensInUSD.add(getTokenPrice(tokenPrices, tokens[j]).mul(amounts[j]));
            }
        }
        return allTokensInUSD;
    }

    function getTokenPrice(TokenPrice[] memory tokenPrices, address token) view internal returns (uint256){
        for(uint256 j = 0; j < tokenPrices.length; j++){
            if(tokenPrices[j].token == address(0)){
                tokenPrices[j].token = token;
                tokenPrices[j].price = priceView.getPrice(token);
                return tokenPrices[j].price;
            }else if(token == tokenPrices[j].token){
                return tokenPrices[j].price;
            }
        }
        return priceView.getPrice(token);
    }

    function hasItem(address[] memory _array, address _item) internal pure returns (bool){
        for(uint256 i = 0; i < _array.length; i++){
            if(_array[i] == _item) return true;
        }
        return false;
    }

 
    // commision pool function
    
    function setCommissionPause(bool _isPaused) external onlyOwner{       
            require(isCommissionPaused!= _isPaused, "forbidden");
            address[] memory flexiblePools = IController(controller).getFlexiblePools();
            if(!_isPaused){
               for(uint256 i = 0; i < flexiblePools.length; i++){
               require(commissionRatePositive[flexiblePools[i]].length > 0 && commissionRateNegative[flexiblePools[i]].length > 0, "commissionRate unset");
               }
            }
             SVaultNetValue.NetValue[] memory netValues = IController(
                controller
            ).accrueProfit();
            isCommissionPaused = _isPaused; 
            if(!_isPaused) updateCommission(netValues, commissionAmountInPools);   
    }

    function getApys(SVaultNetValue.NetValue[] memory netValues,uint256 fixedPoolsLength,uint256 flexiblePoolsLength) internal view returns( bool[] memory isPositive,address[] memory pools,uint256[] memory apys,uint256[] memory amountInUSD){        
        uint256 timeElapsed = block.timestamp.sub(blockTimestampLast);
        isPositive = new bool[](flexiblePoolsLength);
        pools = new address[](flexiblePoolsLength);
        apys = new uint256[](flexiblePoolsLength);
        amountInUSD = new uint256[](flexiblePoolsLength);
        for(uint256 i = 0; i < flexiblePoolsLength; i++){        
             SVaultNetValue.NetValue memory netValue = netValues[fixedPoolsLength+i];
             pools[i]= netValue.pool;
             if(netValuePershareLast[netValue.pool]==0) continue;
              uint256 share = IFundPool(netValue.pool).totalShares();
              uint256 netValuePershare = share==0?1e12:netValue.totalTokens.mul(1e12).div(share);
              uint256 netValuePershareLast = share==0?1e12:netValuePershareLast[netValue.pool];
              amountInUSD[i]= netValue.amountInUSD;
            if (timeElapsed == 0) continue;
            if(netValuePershare >= netValuePershareLast){
                 uint256 apy = netValuePershare.sub(netValuePershareLast).mul(1e6).mul(SECONDS_YEAR).div(timeElapsed).div(netValuePershareLast);  
                 isPositive[i] = true; 
                 apys[i] = apy;            
            }
            else {
                 uint256 apy = netValuePershareLast.sub(netValuePershare).mul(1e6).mul(SECONDS_YEAR).div(timeElapsed).div(netValuePershareLast);      
                 isPositive[i] = false; 
                 apys[i] = apy;
            }  
        }
        return(isPositive,pools,apys,amountInUSD);
    }
    function setCommissionRate( address pool,
        CommissionRate[] memory _commissionRatePositive,
        CommissionRate[] memory _commissionRateNegative
    ) public onlyOwner {
        IController(controller).accrueProfit();
        delete commissionRatePositive[pool];     
        for (uint256 i = 0; i < _commissionRatePositive.length; i++) {
            CommissionRate memory c = _commissionRatePositive[i];
            require(c.rate <= 1e6, "positive rate:input overflow"); 
            if(i < _commissionRatePositive.length-1) {
                CommissionRate memory c_next = _commissionRatePositive[i+1];
                require(c_next.apyScale < c.apyScale, "positive rate:apyScale input invalid");
                if(c.isAllowance)
                require(c_next.isAllowance, "positive rate:should be set to allowance");
            }
            commissionRatePositive[pool].push(c);         
        }
        delete commissionRateNegative[pool];
        for (uint256 i = 0; i < _commissionRateNegative.length; i++) {
            CommissionRate memory c = _commissionRateNegative[i];
            require(c.rate <= 1e6, "negative rate:input overflow"); 
            require(c.isAllowance, "negative rate:should be set to allowance");
            if(i < _commissionRateNegative.length-1) {
                CommissionRate memory c_next = _commissionRateNegative[i+1];
                require(c_next.apyScale < c.apyScale, "negative rate:apyScale input invalid");
            }
            commissionRateNegative[pool].push(c);
        }
    }
    
    function calculalteCommission(SVaultNetValue.NetValue[] memory netValues,uint256 fixedPoolsLength,uint256 flexiblePoolsLength) internal view 
             returns(bool[] memory, address[] memory, uint256[] memory commissions, uint256 newCommission){
      (bool[] memory isPositive,address[] memory pools,uint256[] memory apys,uint256[] memory amountInUSD) = getApys(netValues,fixedPoolsLength,flexiblePoolsLength);   
      uint256 totalProfit;
      uint256 totalAllowance; 
      commissions = new uint256[](pools.length);
      for(uint256 i = 0; i < pools.length; i++){
        if(apys[i] == 0) continue;
        (bool isAllowance, uint256 accCommision) = culculate(apys[i],isPositive[i],commissionRatePositive[pools[i]],commissionRateNegative[pools[i]],amountInUSD[i]);
        commissions[i] = accCommision;
        isPositive[i] = isAllowance;
        if(isAllowance) 
                     totalAllowance = totalAllowance.add(accCommision);
                else totalProfit = totalProfit.add(accCommision);
       }
       uint256 availableAllowance = totalProfit.add(commissionAmountInPools);
       if (totalAllowance > availableAllowance) {
           for(uint256 i = 0; i < isPositive.length; i++){          
             if(isPositive[i]){
               commissions[i] = commissions[i].mul(availableAllowance).div(totalAllowance);
               }
            }
            totalAllowance = availableAllowance;
        }
       newCommission = commissionAmountInPools.add(totalProfit).sub(totalAllowance);
       return (isPositive, pools, commissions, newCommission);
    }


    function culculate(uint256 apy,bool isPositive,CommissionRate[] storage cp,CommissionRate[] storage cn,uint256 amountInUSD) internal view returns (bool,uint256){ 
                uint256 setRatelength = isPositive? cp.length:cn.length;
                if(setRatelength == 0) return(isPositive,0);     
            uint256 accCommision;
            (bool isAllowance,uint256 gear) = sort(cp,cn,apy,isPositive);
            
            if(isPositive){
                    for(uint256 j = gear; j < cp.length; j++){   
                        uint256 commision;   
                        if(isAllowance == cp[j].isAllowance){
                        uint256 minuendApy = j == gear ? apy : cp[j-1].apyScale;
                        uint256 apyScale = minuendApy.sub(cp[j].apyScale);
                        commision= _culculate(amountInUSD,apyScale,cp[j].rate);
                        accCommision = accCommision.add(commision);  
                        }    
                    }   
                }                  
                else{
                    for(uint256 j = gear; j < cn.length; j++){
                        uint256 commision;            
                        uint256 minuendApy = j == gear ? apy : cn[j-1].apyScale;
                        uint256 apyScale = minuendApy.sub(cn[j].apyScale);
                        commision= _culculate(amountInUSD,apyScale,cn[j].rate);
                        accCommision = accCommision.add(commision);             
                    }
                }         
            return(isAllowance,accCommision);


    }

    function _culculate(uint256 amountInUSD,uint256 apyScale,uint256 rate)internal view returns(uint256){ 
        uint256 timeElapsed = block.timestamp.sub(blockTimestampLast);
        uint256 commision = amountInUSD.mul(apyScale).mul(rate).mul(timeElapsed).div(SECONDS_YEAR).div(1e12);
        return commision;
    }


    function sort(CommissionRate[] storage cp,CommissionRate[] storage cn,uint256 apy,bool isPositive)internal view returns(bool isAllowance, uint256 gear){
        if(isPositive){
            for(uint256 j = 0; j < cp.length; j++){
             if(apy > cp[j].apyScale){
               isAllowance = cp[j].isAllowance;
               gear = j; 
               break;
               }
            }
        }
        else {
            for(uint256 j = 0; j < cn.length; j++){
             if(apy > cn[j].apyScale){
               isAllowance = cn[j].isAllowance;
               gear = j; 
               break;
               }
            }
        }    
    }

    function getCommissionRateNegative(address pool) public view returns(CommissionRate[] memory _commissionRateNegative){
        if (commissionRateNegative[pool].length == 0) {
            CommissionRate[] memory commissionRate = new CommissionRate[](1);
            return commissionRate;
        }
        return commissionRateNegative[pool];
    }
   
    function getCommissionRatePositive(address pool) public view returns(CommissionRate[] memory _commissionRatePositive){
        if (commissionRatePositive[pool].length == 0) {
            CommissionRate[] memory commissionRate = new CommissionRate[](1);
            return commissionRate;
        }
        return commissionRatePositive[pool];
    }

   //excess commission transfer
   function getProfit()view public returns(uint256 totalProfitAmountInUSD){
        NetValue[] memory netValues;
        address[] memory fixedPools = IController(controller).getFixedPools();
        address[] memory flexiblePools = IController(controller).getFlexiblePools();
        uint256 count = fixedPools.length.add(flexiblePools.length);
        TokenPrice[] memory tokenPrices = new TokenPrice[](tokenCount);
        // get all tokens in pool and strategy
        uint256 allTokensInUSD = getAllTokensInUSD(fixedPools, flexiblePools, tokenPrices);
        netValues = new NetValue[](count);
        uint256 totalFixedPoolUSD = 0;
        for(uint256 i = 0; i < fixedPools.length; i++){
            netValues[i].pool = fixedPools[i];
            (netValues[i].token, netValues[i].amount, netValues[i].totalTokens) = IFundPool(fixedPools[i]).getTotalTokensByProfitRate();
            uint256 price = getTokenPrice(tokenPrices, netValues[i].token);
            netValues[i].amountInUSD = price.mul(netValues[i].amount);
            netValues[i].totalTokensInUSD = price.mul(netValues[i].totalTokens);
            totalFixedPoolUSD = totalFixedPoolUSD.add(netValues[i].totalTokensInUSD);
        }
        if(allTokensInUSD < totalFixedPoolUSD) return 0;
        allTokensInUSD = allTokensInUSD.sub(totalFixedPoolUSD);
        if(allTokensInUSD > commissionAmountInPools) allTokensInUSD = allTokensInUSD.sub(commissionAmountInPools);
        (PoolInfo[] memory poolInfos, uint256 totalWeight, uint256 totalProfitWeight, uint256 totalAmountInUSD, uint256 totalAllocatedProfitInUSD) = getPoolInfos(flexiblePools, tokenPrices);
        // allTokensInUSD = allTokensInUSD.sub(totalAllocatedProfitInUSD);
        if(allTokensInUSD >= totalAmountInUSD){
            totalProfitAmountInUSD = allTokensInUSD.sub(totalAmountInUSD);
        }
    }

    function setExcessLimitInRatio(uint256 _excessLimitInRatio) public onlyAdmin{
        require(_excessLimitInRatio <= 1e6, "invalid input");
        excessLimitInRatio = _excessLimitInRatio;
    }
    
    function getAvailableTakeCommision() public view returns(uint256){
         uint256 totalProfit = getProfit();  
         uint256 excessLimit = totalProfit.mul(excessLimitInRatio).div(1e6);
         uint256 availableProfit = totalProfit.sub(excessLimit);
         uint256 maxAmount =  availableProfit >= commissionAmountInPools ? commissionAmountInPools : availableProfit;
         return maxAmount;
    }
    function takeAllowed(uint256 excessCommission) public view returns(bool,uint256){
         uint256 maxAmount = getAvailableTakeCommision();
         if(excessCommission == MAX_UINT256)
            return (true,maxAmount);
         else if(excessCommission <= maxAmount)
            return (true,excessCommission);           
         return (false,0); 
    }
    function takeCommission(uint256 excessCommission) public{
         require(msg.sender == admin, "!admin");
         (bool allowed,uint256 amount) = takeAllowed(excessCommission);
         require(allowed, "invalid input");
         withdrawCommision(amount); 
         commissionAmountInPools = commissionAmountInPools.sub(amount);
         emit CommissionTaken(admin,amount);
    }
       
    function withdrawCommision(uint256 amountInUSD) internal {
        address[] memory strategies = IController(controller).getStrategies();
        uint256[] memory weights = new uint256[](strategies.length);
        address[] memory withdrawTokens = new address[](strategies.length);
        uint256[] memory withdrawAmounts = new uint256[](strategies.length);
        TokenPrice[] memory tokenPrices = new TokenPrice[](tokenCount);
        uint256 allWeight;

        for(uint256 i = 0; i < strategies.length; i++) {
            (address[] memory tokens, uint256[] memory amounts, uint256[] memory pendingAmounts) = IStrategy(strategies[i]).getProfitAmount();
            uint256 allTokensInUSD;
            for(uint256 j = 0; j < tokens.length; j++){
                //if(amounts[j] == 0) continue;  
                uint256 amount = getTokenPrice(tokenPrices, tokens[j]).mul(amounts[j].add(pendingAmounts[j]));               
                allTokensInUSD = allTokensInUSD.add(amount);
            }
            weights[i]= allTokensInUSD;
            allWeight = allWeight.add(allTokensInUSD);
            withdrawTokens[i] = tokens[0];
        }
         for(uint256 i = 0; i < strategies.length; i++) {
             uint256 withdrawAmount = weights[i].mul(amountInUSD).div(allWeight);
             withdrawAmounts[i] = withdrawAmount.div(getTokenPrice(tokenPrices, withdrawTokens[i]));
         }

         IController(controller).withdrawCommssionProfit(withdrawTokens,withdrawAmounts,admin);
    }
   
}