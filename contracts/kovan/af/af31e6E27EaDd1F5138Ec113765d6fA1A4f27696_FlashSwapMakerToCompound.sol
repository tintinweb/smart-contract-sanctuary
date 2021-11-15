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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.3;

import { IFlashSwapResolver } from "./interfaces/IFlashSwapResolver.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/**
Maker interfaces.
 */
interface IDSProxy{

    function execute(address _target, bytes calldata _data)
        external
        payable;

}

/**
Compound interfaces.
 */
interface ICErc20 {
    function mint(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);
}


interface ICEth {
    function mint() external payable;

    function borrow(uint256) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address) external returns (uint256);
}


interface IComptroller {
    function markets(address) external returns (bool, uint256);

    function enterMarkets(address[] calldata)
        external
        returns (uint256[] memory);

    function getAccountLiquidity(address)
        external
        view
        returns (uint256, uint256, uint256);
}


interface IPriceFeed {
    function getUnderlyingPrice(address cToken) external view returns (uint);
}

/**
WETH
*/
interface IWETH{
    function withdraw(uint wad) external;
    function deposit() external payable;
}

/**
Main contract.
 */
contract FlashSwapMakerToCompound is IFlashSwapResolver{

    using SafeMath for uint256;

    struct DecodedData{
        // address dsProxy;
        // address target;
        // address manager;
        // address joinEthA;
        // address joinDai;
        // uint256 cdpId;
        // uint256 ink;

        address cTokenToProvide;
        uint256 amountToProvide;
        address cTokenToBorrow;
        uint256 amountToBorrow;
        uint256 maxAmountBorrowRatio; // 6 decimals
        address cComptroller;
        uint256 uniswapAnchoredViewPrice;
        address WETH;
    }

    function mintCERC20(address cTokenToProvide, uint256 amountToProvide) internal{

        uint256 error = ICErc20(cTokenToProvide).mint(amountToProvide);

        require(error == 0, "FlashSwapMakerToCompound: CErc20.mint Error");

    }

    function compoundEnterMarket(address cComptroller, address cToken) internal{

        // Enter the market so you can borrow another type of asset
        address[] memory cTokens = new address[](1);
        cTokens[0] = cToken;
        uint256[] memory errors = IComptroller(cComptroller).enterMarkets(
            cTokens);
        if (errors[0] != 0) {
            revert("FlashSwapMakerToCompound: Comptroller.enterMarkets failed.");
        }
    
    }

    function compoundGetLiquidity(address cComptroller) internal view returns(uint256 liquidity){

        // Get my account's total liquidity value in Compound
        (uint256 error2, uint256 _liquidity, uint256 shortfall) = IComptroller(
            cComptroller).getAccountLiquidity(address(this));
        if (error2 != 0) {
            revert("FlashSwapMakerToCompound: Comptroller.getAccountLiquidity failed.");
        }
        require(shortfall == 0, "FlashSwapMakerToCompound: account underwater");
        require(_liquidity > 0, "FlashSwapMakerToCompound: account has excess collateral");

        liquidity = _liquidity;

    }
    
    function compoundCheckAmountToBorrow(address cComptroller,
        uint256 amountToBorrow, uint256 maxAmountBorrowRatio/*6 decimals*/, 
        uint256 uniswapAnchoredViewPrice/*6 decimals*/) internal view {

        uint256 liquidity = compoundGetLiquidity(cComptroller);
        
        require(
            amountToBorrow.mul(uniswapAnchoredViewPrice)/*.div(10^6)*/ 
            <= maxAmountBorrowRatio.mul(liquidity)/*.div(10^6)*/,
            "FlashSwapMakerToCompound: amount to borrow exeeds max borrow ratio"); 
    }

    function wipeAllAndFreeGem(bytes memory data) public {

        (
            address dsProxy, address target, address manager,
            address joinEthA, address joinDai, uint256 cdpId,
            uint256 ink
            ) = abi.decode(data, 
                (
                    address, address, address, address, address, uint256, uint256
                     ));

        IDSProxy(dsProxy).execute(
            target,
            abi.encodeWithSignature("wipeAllAndFreeGem(address,address,address,uint256,uint256)",
                manager, joinEthA, joinDai, cdpId, ink)
        );

    }

    function resolveUniswapV2Call(
        address sender,
        address tokenRequested,
        address tokenToReturn,
        uint256 amountRecived,
        uint256 amountToReturn,
        bytes calldata _data
        ) external payable override{


        (
            bytes memory decodedDataMaker,
            bytes memory decodedDataCompound
            ) = abi.decode(_data, 
                (
                    bytes, bytes
                     ));

        
        wipeAllAndFreeGem(decodedDataMaker);

        DecodedData memory decodedData;
        (
            decodedData.cTokenToProvide,
            decodedData.amountToProvide,
            decodedData.cTokenToBorrow,
            decodedData.amountToBorrow,
            decodedData.maxAmountBorrowRatio, // 6 decimals
            decodedData.cComptroller,
            decodedData.uniswapAnchoredViewPrice, // 6 decimals
            decodedData.WETH
            ) = abi.decode(decodedDataCompound, 
                (
                    address, uint256, address, uint256, uint256, address, uint256, address
                     ));

        IERC20(tokenRequested).approve(
            decodedData.cTokenToProvide, decodedData.amountToProvide);

        mintCERC20(decodedData.cTokenToProvide, decodedData.amountToProvide);

        compoundEnterMarket(decodedData.cComptroller, decodedData.cTokenToProvide);
        
        compoundCheckAmountToBorrow(decodedData.cComptroller,
            decodedData.amountToBorrow, decodedData.maxAmountBorrowRatio, 
            decodedData.uniswapAnchoredViewPrice);

        // Borrow, then check the underlying balance for this contract's address
        ICEth(decodedData.cTokenToBorrow).borrow(decodedData.amountToBorrow);

        if (tokenToReturn == decodedData.WETH){
            IWETH(decodedData.WETH).deposit{value: decodedData.amountToBorrow}();
        }

    }


}

pragma solidity >=0.6.0 <0.8.0;

interface IFlashSwapResolver{

    /**
    @param sender The address who calls IUniswapV2Pair.swap.
    @param tokenRequested The address of the token that was requested to IUniswapV2Pair.swap.
    @param tokenToReturn The address of the token that should be returned to IUniswapV2Pair(msg.sender).
    @param amountRecived The ammount recived of tokenRequested.
    @param amountToReturn The ammount recived of tokenRequested.
    @param _data dataForResolveUniswapV2Call: check FlashSwapProxy.uniswapV2Call documentation
     */
    function resolveUniswapV2Call(
            address sender,
            address tokenRequested,
            address tokenToReturn,
            uint256 amountRecived,
            uint256 amountToReturn,
            bytes calldata _data
            ) external payable;
}

