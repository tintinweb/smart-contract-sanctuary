/**
 *Submitted for verification at Etherscan.io on 2021-10-13
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
        anchorToken = _anchorToken;
        usdt = _usdt;
        for(uint256 i = 0; i < _factorys.length; i++){
            factorys.push(_factorys[i]);
        }
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
        require(msg.sender == admin, "!admin");
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