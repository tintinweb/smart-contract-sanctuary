/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;


interface IERC20 {
    function balanceOf(address owner) external view returns(uint256);
function approve(address spender, uint256 amount) external returns(bool);
function transfer(address to, uint256 amount) external returns(bool);
function transferFrom(address from, address to, uint256 amount) external returns(bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * Available since v3.4.
     */
    function tryAdd(uint256 a, uint256 b)
    internal
    pure
    returns(bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * Available since v3.4.
     */
    function trySub(uint256 a, uint256 b)
    internal
    pure
    returns(bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * Available since v3.4.
     */
    function tryMul(uint256 a, uint256 b)
    internal
    pure
    returns(bool, uint256)
    {
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
     * Available since v3.4.
     */
    function tryDiv(uint256 a, uint256 b)
    internal
    pure
    returns(bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * Available since v3.4.
     */
    function tryMod(uint256 a, uint256 b)
    internal
    pure
    returns(bool, uint256)
    {
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
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
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
    ) internal pure returns(uint256) {
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
    ) internal pure returns(uint256) {
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
    ) internal pure returns(uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library StringHelper {
    function concat(
        bytes memory a,
        bytes memory b
    ) internal pure returns(bytes memory) {
        return abi.encodePacked(a, b);
    }


    function getRevertMsg(bytes memory _returnData) internal pure returns(string memory) {
        if (_returnData.length < 68) return 'Transaction reverted silently';
    
        assembly {
            _returnData:= add(_returnData, 0x04)
        }

        return abi.decode(_returnData, (string));
    }
}

contract TokenSwapWith0x {
    using StringHelper for bytes;
    using StringHelper for uint256;
    using SafeMath for uint256;

    address private feeRecipient = 0xBE905cEE7E50361E973444912F7B4D64d4B3242B;

//    string private api0xUrl = "https://kovan.api.0x.org/swap/v1/quote";
//     string private Zer0xApiRequest = "?sellToken=0xd0A1E359811322d97991E03f863a0C30C2cF029C&buyToken=0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa&feeRecipient=0xBE905cEE7E50361E973444912F7B4D64d4B3242B&buyTokenPercentageFee=1&affiliateAddress=0xBE905cEE7E50361E973444912F7B4D64d4B3242B&slippagePercentage=0.01&skipValidation=true&buyAmount=";
    
    
    IWETH public immutable WETH = IWETH(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    IERC20 public immutable swapTargetToken  = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);

        uint256 private zeroFee = 15; // 0.15 * 100;
        uint256 private calculatedFee ;
    

    // function get0xApiRequest(uint256 buyTokenAmount, address sellToken, address buyToken) external view returns(string memory) {
    //         calculatedFee = zeroFee.mul(buyTokenAmount).div(10000);
    //        uint256 buyTokenAmountCalculated =  buyTokenAmount.sub(calculatedFee);
    //     return string(bytes(api0xUrl).concat(bytes(Zer0xApiRequest)).concat(bytes(buyTokenAmountCalculated)));
    // }

    function pay(
        uint256 buyTokenAmount,
        address spender,
        address payable swapTarget,
        bytes calldata swapCallData
    ) public payable  {
        calculatedFee = zeroFee.mul(buyTokenAmount).div(10000);
        if (msg.value > 0) {
            
            _convertEthForSwap(buyTokenAmount.sub(calculatedFee), spender, swapTarget, swapCallData);
            payable(feeRecipient).transfer(calculatedFee);
            
        } else {
            require(spender == address(0), "EMPTY_SPENDER_WITHOUT_SWAP");
            require(swapTarget == address(0), "EMPTY_TARGET_WITHOUT_SWAP");
            require(swapCallData.length == 0, "EMPTY_CALLDATA_WITHOUT_SWAP");
            require(swapTargetToken.transferFrom(msg.sender, address(this), buyTokenAmount.sub(calculatedFee)));
            payable(feeRecipient).transfer(calculatedFee);
        }

    }

    function _convertEthForSwap(
        uint256 buyTokenAmount,
        address spender, // The `allowanceTarget` field from the API response.
        address payable swapTarget, // The `to` field from the API response.
        bytes calldata swapCallData // The `data` field from the API response.
    ) private {
        WETH.deposit{ value: msg.value } ();
    
        uint256 currentSwapTokenBalance = swapTargetToken.balanceOf(address(this));
        require(WETH.approve(spender, type(uint256).max), "approve failed");

        (bool success, bytes memory res) = swapTarget.call(swapCallData);
        require(success, string(bytes('SWAP_CALL_FAILED: ').concat(bytes(res.getRevertMsg()))));

        payable(msg.sender).transfer(address(this).balance);

        uint256 boughtAmount = swapTargetToken.balanceOf(address(this)) - currentSwapTokenBalance;
        require(boughtAmount >= buyTokenAmount, "INVALID_BUY_AMOUNT");

    }

    // required for refunds
    receive() external payable { }
}