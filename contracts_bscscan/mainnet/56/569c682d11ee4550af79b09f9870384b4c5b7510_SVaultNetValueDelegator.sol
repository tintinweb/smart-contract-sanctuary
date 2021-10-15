/**
 *Submitted for verification at BscScan.com on 2021-10-15
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

// File: contracts/SVaultNetValueDelegator.sol

pragma solidity ^0.6.12;


contract SVaultNetValueDelegator is SVaultNetValueStorage {
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor(
        address _controller,
        address _priceView,
        address _implementation
    ) public {
        admin = msg.sender;
        delegateTo(
            _implementation,
            abi.encodeWithSignature(
                "initialize(address,address)",
                _controller,
                _priceView              
            )
        );
        _setImplementation(_implementation);
    }

    function _setImplementation(address implementation_) public {
        require(msg.sender == admin, "UNAUTHORIZED");

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation);
    }

    function _setAdmin(address newAdmin) public {
        require(msg.sender == admin, "UNAUTHORIZED");

        address oldAdmin = admin;

        admin = newAdmin;

        emit NewAdmin(oldAdmin, newAdmin);
    }

    function delegateTo(address callee, bytes memory data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    receive() external payable {}

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
    //  */
    fallback() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);
        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())
            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize())
            }
            default {
                return(free_mem_ptr, returndatasize())
            }
        }
    }
}