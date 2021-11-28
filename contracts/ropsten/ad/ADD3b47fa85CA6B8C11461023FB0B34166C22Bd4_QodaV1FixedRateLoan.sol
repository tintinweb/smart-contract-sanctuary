// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/token/IERC20.sol";
import "./libraries/SigVerify.sol";

contract QodaV1FixedRateLoan {

  using SafeMath for uint256;
  
  address public addressLoanToken;
  
  FixedRateLoan[] fixedRateLoans;
  
  struct FixedRateLoan {
    uint256 startBlock;
    uint256 endBlock;
    uint256 notional;
    uint256 fixedRatePerBlock;
    uint256 initCollateral;
    uint256 accruedInterest;
    address addressCollateralToken;
    address addressLender;
    address addressBorrower;
  }

  constructor(address _addressLoanToken) public {
    addressLoanToken = _addressLoanToken;
  }

  function borrow(
                  address addressLoanToken,
                  address addressLender,
                  uint256 quoteExpiryBlock,
                  uint256 endBlock,
                  uint256 notional,
                  uint256 fixedRatePerBlock,
                  uint256 nonce,
                  bytes memory signature,
                  address addressCollateralToken,
                  uint256 initCollateral
                  ) public {
    bool isQuoteValid = SigVerify.checkLenderSignature(
                                                       addressLoanToken,
                                                       addressLender,
                                                       quoteExpiryBlock,
                                                       endBlock,
                                                       notional,
                                                       fixedRatePerBlock,
                                                       nonce,
                                                       signature
                                                       );
    require(isQuoteValid, "signature doesn't match");
    createFixedRateLoan(
                        endBlock,
                        notional,
                        fixedRatePerBlock,
                        initCollateral,
                        addressCollateralToken,
                        addressLender,
                        msg.sender
                        );
  }
  
  function accrueInterest(uint256 i) public {
    require(i < fixedRateLoans.length, "index out of bounds");
    FixedRateLoan storage fixedRateLoan = fixedRateLoans[i];
    uint256 endBlock = block.number;
    if(endBlock > fixedRateLoan.endBlock) {
      endBlock = fixedRateLoan.endBlock;
    }
    uint256 periods = endBlock - fixedRateLoan.startBlock;
    uint256 accruedInterest = fixedRateLoan.notional;
    uint256 mantissa = 1e18; //fixedRatePerBlock 18 decimals by convention
    // TODO: is there a more efficient way to do this?
    for(uint j=0; j < periods; j++){
      accruedInterest = accruedInterest.mul(mantissa + fixedRateLoan.fixedRatePerBlock);
      accruedInterest = accruedInterest.div(mantissa);
    }
    accruedInterest = accruedInterest - fixedRateLoan.notional;
    fixedRateLoan.accruedInterest = accruedInterest;
  }

  //INTERNAL FUNCTIONS
  function createFixedRateLoan(
                               uint256 endBlock,
                               uint256 notional,
                               uint256 fixedRatePerBlock,
                               uint256 initCollateral,
                               address addressCollateralToken,
                               address addressLender,
                               address addressBorrower
                               ) private {
    require(notional > 0, "notional too small");
    require(endBlock > block.number, "endBlock must be in future");
    require(checkBalance(addressLender, addressLoanToken, notional), "lender balance too low");
    require(checkBalance(addressBorrower, addressCollateralToken, initCollateral), "borrow balance too low");
    require(checkApproval(addressLender, addressLoanToken, notional), "lender must approve contract spend");
    require(checkApproval(addressBorrower, addressCollateralToken, initCollateral), "borrower must approve contract spend");
    //TODO: Check initCollateral (converted to notional ccy) > than notionalAmt

    //Create FixedRateLoan
    FixedRateLoan memory fixedRateLoan = FixedRateLoan(
                                                       block.number,
                                                       endBlock,
                                                       notional,
                                                       fixedRatePerBlock,
                                                       initCollateral,
                                                       0,
                                                       addressCollateralToken,
                                                       addressLender,
                                                       addressBorrower
                                                       );
    fixedRateLoans.push(fixedRateLoan);

    // Transfer loan from lender to borrower
    IERC20 loanToken = IERC20(addressLoanToken);
    loanToken.transferFrom(addressLender, addressBorrower, notional);

    // Transfer collateral from borrower to smart contract as escrowe
    IERC20 collateralToken = IERC20(addressCollateralToken);
    collateralToken.transferFrom(addressBorrower, address(this), initCollateral);
  }

  function checkBalance(
                        address userAddress,
                        address tokenAddress,
                        uint256 amount
                        ) internal view returns(bool){
    if(IERC20(tokenAddress).balanceOf(userAddress) >= amount) {
      return true;
    }
    return false;
  }

  function checkApproval(
                         address userAddress,
                         address tokenAddress,
                         uint256 amount
                         ) internal view returns(bool) {
    if(IERC20(tokenAddress).allowance(userAddress, address(this)) > amount){
      return true;
    }
    return false;
  }


  
}

pragma solidity ^0.8.9;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library SigVerify {

  function checkLenderSignature(
                                address addressLoanToken,
                                address addressLender,
                                uint256 quoteExpiryBlock,
                                uint256 endBlock,
                                uint256 notional,
                                uint256 fixedRatePerBlock,
                                uint256 nonce,
                                bytes memory signature
                                ) internal pure returns(bool){
    bytes32 messageHash = getLenderMessageHash(
                                               addressLoanToken,
                                               addressLender,
                                               quoteExpiryBlock,
                                               endBlock,
                                               notional,
                                               fixedRatePerBlock,
                                               nonce
                                               );
    bytes32 prefixedMessageHash = getPrefixedMessageHash(messageHash);
    address signer = recoverSigner(prefixedMessageHash, signature);
    return signer == addressLender;
  }

  function getLenderMessageHash(
                                address addressLoanToken,
                                address addressLender,
                                uint256 quoteExpiryBlock,
                                uint256 endBlock,
                                uint256 notional,
                                uint256 fixedRatePerBlock,
                                uint256 nonce
                                ) internal pure returns(bytes32) {
    return keccak256(abi.encodePacked(
                                      addressLoanToken,
                                      addressLender,
                                      quoteExpiryBlock,
                                      endBlock,
                                      notional,
                                      fixedRatePerBlock,
                                      nonce
                                      ));
  }





  
  function getPrefixedMessageHash(bytes32 messageHash) internal pure returns(bytes32){
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
  }

  // This function returns the address of the signer of the prefixedMessageHash.
  // Compare this address versus the cleartext address given to verify the
  // message is indeed signed by the owner.
  function recoverSigner(
                         bytes32 prefixedMessageHash,
                         bytes memory signature
                         ) internal pure returns(address) {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
    
    //built-in solidity function to recover the signer address using
    // the prefixedMessageHash and signature
    return ecrecover(prefixedMessageHash, v, r, s);
  }
  
  function splitSignature(bytes memory signature) internal pure returns(
                                                                      bytes32 r,
                                                                      bytes32 s,
                                                                      uint8 v) {
    require(signature.length == 65, "invalid signature length");
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }
  }
}