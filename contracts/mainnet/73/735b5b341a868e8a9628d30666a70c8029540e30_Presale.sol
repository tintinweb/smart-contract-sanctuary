/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// File: contracts/INFTHG.sol

pragma solidity ^0.6.2;

interface INFTHG {
    function mint(address to,uint8 picId,uint256 lockAmount) external;
    function tokenData(uint256 tokenId) external view returns (uint8,uint256);
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/IUNIRouter.sol

pragma solidity ^0.6.2;

interface IUNIRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    //0x3472a5a71965499acd81997a54bba8d852c6e53d -> 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599 -> 0x798d1be841a82a273720ce31c822c61a67a601c3
    //decimals 9
}

// File: contracts/Presale.sol

pragma solidity ^0.6.2;





contract Presale {
    using SafeMath for uint256;
    IERC20 public badger = IERC20(0x3472A5A71965499acd81997a54BBA8D852C6E53d);
    address public wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    IERC20 public digg = IERC20(0x798D1bE841a82a273720CE31c822C61a67a601C3);
    INFTHG public hgNFT = INFTHG(0xd608D64D2D9DA1320742d6df06D7323848e35248);
    IUNIRouter public router = IUNIRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public teamAddr = address(0x316C0837F85383bDc10dD0DA3DcC178DC13fcb11);
    address public owner;
    mapping(uint8 => uint256) public salePrice;
    mapping(uint8 => uint256) public saleAmount;
    mapping(uint8 => bool) public saleType; //false:digg true:badger
    constructor() public {
        owner = msg.sender;
        
        //digg
        salePrice[1]=800000;
        saleAmount[1]=5000;
        
        salePrice[2]=2000000;
        saleAmount[2]=3000;
        
        salePrice[3]=5000000;
        saleAmount[3]=1000;
        
        salePrice[4]=10000000;
        saleAmount[4]=500;
        
        salePrice[5]=100000000;
        saleAmount[5]=20;
        
        
        //badger
        salePrice[6]=10000000000000000;
        saleAmount[6]=10000;
        saleType[6]=true;
        
         salePrice[7]=100000000000000000000;
        saleAmount[7]=2;
        saleType[7]=true;
        
         salePrice[8]=1000000000000000000;
        saleAmount[8]=20;
        saleType[8]=true;
        
         salePrice[9]=50000000000000000000;
        saleAmount[9]=5;
        saleType[9]=true;
        
         salePrice[10]=2000000000000000000;
        saleAmount[10]=10;
        saleType[10]=true;
        
        
    }
    modifier onlyOwner{
        require(msg.sender == owner,'not owner');
        _;
    }

    function AddSale(uint8 level, uint256 price, uint256 amount, bool isBadger) public onlyOwner {
        require(salePrice[level] == 0 && price > 0 && amount > 0,'para error');
        salePrice[level] = price;
        saleAmount[level] = amount;
        saleType[level] = isBadger;
    }

    function BuyCardUseDigg(uint8 level, uint256 count) public {
        require(count > 0 && saleAmount[level] >= count && !saleType[level],'para error');
        uint256 totalAmount = salePrice[level].mul(count);
        uint256 forLq = totalAmount.mul(5).div(100);
        digg.transferFrom(msg.sender, teamAddr, forLq);
        digg.transferFrom(msg.sender, address(this), totalAmount.sub(forLq));
        //mint nft
        hgNFT.mint(msg.sender, level, totalAmount.sub(forLq));
        saleAmount[level] = saleAmount[level].sub(count);
    }

    function BuyCardUseBadger(uint8 level, uint256 count) public {
        require(count > 0 && saleAmount[level] >= count && saleType[level],'para error');
        uint256 totalAmount = salePrice[level].mul(count);
        uint256 forLqAndUser = totalAmount.mul(40).div(100);
        badger.transferFrom(msg.sender, teamAddr, forLqAndUser);
        uint256 amountIn = totalAmount.sub(forLqAndUser);
        badger.transferFrom(msg.sender, address(this), amountIn);
        saleAmount[level] = saleAmount[level].sub(count);
        //swap badger to digg from uniswap
        address[] memory path = new address[](3);
        //badger
        path[0] = address(badger);
        //wbtc
        path[1] = address(wbtc);
        //digg
        path[2] = address(digg);
        uint[] memory amountsOut = router.getAmountsOut(amountIn, path);
        uint amountOutMin = amountsOut[2];
        //approve
        badger.approve(address(router), uint(- 1));
        uint[] memory amounts = router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), now.add(60));
        uint output = amounts[2];
        //mint nft
        hgNFT.mint(msg.sender, level, output);
    }

    function Burn(uint256 tokenId) public {
        address ownerAddr = hgNFT.ownerOf(tokenId);
        require(ownerAddr == msg.sender,'not owner');
        (uint8 level,uint256 amount) = hgNFT.tokenData(tokenId);
        hgNFT.burn(tokenId);
        digg.transfer(msg.sender, amount);
    }
}