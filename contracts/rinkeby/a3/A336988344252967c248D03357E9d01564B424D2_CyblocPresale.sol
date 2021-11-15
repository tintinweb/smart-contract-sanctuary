pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";


contract CyblocPresale {
  using SafeMath for uint256;

  struct Proof {
      uint8 v;
      bytes32 r;
      bytes32 s;
      uint256 deadline;
  }

  // No Cyblocs pack can be adopted after this end date: Friday, March 16, 2018 11:59:59 PM GMT.
  uint256 constant public PRESALE_END_TIMESTAMP = 1521244799;
  uint256 constant public PRESALE_START_TIMESTAMP = 1521244799;

  uint8 constant public PACK_NORMAL_TYPE = 0;
  uint8 constant public PACK_NORMAL_QUANTITY = 100;
  uint256 constant public PACK_NORMAL_PRICE = 0.1 ether; // 0.1 Ether
  uint8 constant public PACK_RARE_TYPE = 1;  
  uint8 constant public PACK_RARE_QUANTITY = 50;
  uint256 constant public PACK_RARE_PRICE = 0.4 ether; // 0.4 Ether
  uint8 constant public PACK_EPIC_TYPE = 2;  
  uint8 constant public PACK_EPIC_QUANTITY = 10;
  uint256 constant public PACK_EPIC_PRICE = 6 ether; // 6 Ether

  uint8 NUM_CYBLOC_PER_BOX = 3;

  mapping (uint8 => uint256) public totalPacksAdopted;
  mapping (address => mapping (uint8 => uint256)) public packsAdopted;

  address public signer;

  event CyblocPackAdopted(
    address indexed adopter,
    uint8 indexed clazz,
    uint256 quantity
  );

  event AdoptedCyblocsRedeemed(address indexed receiver, uint8 indexed clazz, uint256 quantity);
  event RewardedCyblocsRedeemed(address indexed receiver, uint256 quantity);


  function getChainID() public view returns (uint256) {
      uint256 id;
      assembly {
          id := chainid()
      }
      return id;
  }  

  function verifyProof(bytes memory encode, Proof memory _proof) private view returns (bool) {
      if (signer == address(0x0)) {
          return true;
      }
      bytes32 digest = keccak256(abi.encodePacked(getChainID(), address(this), _proof.deadline, encode));
      address signatory = ecrecover(digest, _proof.v, _proof.r, _proof.s);
      return signatory == signer && _proof.deadline >= block.timestamp;
  }  

  function cyblocPackPrice(
    uint256 normalQuantity,
    uint256 rareQuantity,
    uint256 epicQuantity
  )
    public
    view
    returns (uint256 totalPrice)
  {

    totalPrice = totalPrice.add(_cyblocPackPrice(PACK_NORMAL_PRICE, normalQuantity));

    totalPrice = totalPrice.add(_cyblocPackPrice(PACK_RARE_PRICE, rareQuantity));

    totalPrice = totalPrice.add(_cyblocPackPrice(PACK_EPIC_PRICE, epicQuantity));
  }

  function adoptCyblocsPacks(
    uint256 normalQuantity,
    uint256 rareQuantity,
    uint256 epicQuantity
  )
    public
    payable
  {
    require(block.timestamp <= PRESALE_END_TIMESTAMP, "SALE SHOULD BE OPENED");
    require(block.timestamp >= PRESALE_START_TIMESTAMP, "SALE SHOULD BE OPENED");

    uint256 totalPrice = cyblocPackPrice(normalQuantity,
                                        rareQuantity,
                                        epicQuantity);
    require(msg.value >= totalPrice, "INVALID MSG.VALUE");

    uint256 value = msg.value;

    if (normalQuantity > 0) {
      packsAdopted[msg.sender][PACK_NORMAL_TYPE] = packsAdopted[msg.sender][PACK_NORMAL_TYPE].add(normalQuantity);
      totalPacksAdopted[PACK_NORMAL_TYPE] = totalPacksAdopted[PACK_NORMAL_TYPE].add(normalQuantity);
      emit CyblocPackAdopted(
              msg.sender,
              PACK_NORMAL_TYPE,
              normalQuantity
            );
    }

    if (rareQuantity > 0) {
      packsAdopted[msg.sender][PACK_RARE_TYPE] = packsAdopted[msg.sender][PACK_RARE_TYPE].add(rareQuantity);
      totalPacksAdopted[PACK_RARE_TYPE] = totalPacksAdopted[PACK_RARE_TYPE].add(rareQuantity);
      emit CyblocPackAdopted(
              msg.sender,
              PACK_RARE_TYPE,
              rareQuantity
            );
    }

    if (epicQuantity > 0) {
      packsAdopted[msg.sender][PACK_EPIC_TYPE] = packsAdopted[msg.sender][PACK_EPIC_TYPE].add(epicQuantity);
      totalPacksAdopted[PACK_EPIC_TYPE] = totalPacksAdopted[PACK_EPIC_TYPE].add(epicQuantity);
      emit CyblocPackAdopted(
              msg.sender,
              PACK_EPIC_TYPE,
              epicQuantity
            );
    }

    // msg.sender.transfer(value);
  }

  function _cyblocPackPrice(
    uint256 packPrice,
    uint256 quantity
  )
    private
    view
    returns (uint256 totalPrice)
  {
    totalPrice = 0;
    for (uint256 i = 0; i < quantity; i++) {
      totalPrice = totalPrice.add(packPrice);
    }
  }
}

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

