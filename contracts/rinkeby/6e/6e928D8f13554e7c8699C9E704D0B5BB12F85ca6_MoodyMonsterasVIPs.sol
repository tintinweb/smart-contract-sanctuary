// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./OpenSeaSharedStorefrontIds.sol";
import "./OpenSeaSharedStorefrontInterface.sol";

library MoodyMonsterasVIPs {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  address public constant OS_ADDRESS = 0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656;
  //address public constant OS_ADDRESS = 0x495f947276749Ce646f68AC8c248420045cb7b5e;


  function isVipToken(uint _tokenId) public pure returns (bool) {
    uint256[50] memory allVIPIds = OpenSeaSharedStorefrontIds.vipIds();
    bool isInVIPIds = false;

    for (uint256 i = 0; i < allVIPIds.length; i++) {
      if (_tokenId == allVIPIds[i]) {
        isInVIPIds = true;
        break;
      }
    }

    return isInVIPIds;
  }


  function vipIdsOwned(address _address) public view returns (uint256[] memory) {

    OpenSeaSharedStorefrontInterface openSeaSharedStorefront = OpenSeaSharedStorefrontInterface(OS_ADDRESS);

    address[] memory senderAddressArray = new address[](50);
    uint256[] memory allVIPIdsArray = new uint256[](50);
    uint256[50] memory allVIPIds = OpenSeaSharedStorefrontIds.vipIds();

    for (uint256 i = 0; i < allVIPIds.length; i++) {
      senderAddressArray[i] = _address;
      allVIPIdsArray[i] = allVIPIds[i];
    }

    uint256[] memory balanceOfResult = openSeaSharedStorefront.balanceOfBatch(senderAddressArray, allVIPIdsArray);
    uint256[] memory ownedVIPIds = new uint256[](balanceOfResult.length);
    uint ownedVIPCounter = 0;

    for (uint256 i = 0; i < balanceOfResult.length; i++) {
      if (balanceOfResult[i] == 1) {
        ownedVIPIds[ownedVIPCounter] = allVIPIds[i];
        ownedVIPCounter += 1;
      }
    }

    uint256[] memory ownedVIPIdsTrimmed = new uint256[](ownedVIPCounter);

    for (uint256 i = 0; i < ownedVIPCounter; i++) {
      ownedVIPIdsTrimmed[i] = ownedVIPIds[i];
    }

    return ownedVIPIdsTrimmed;
  }


  function ownsToken(address _address, uint _tokenId) public view returns (bool) {

    OpenSeaSharedStorefrontInterface openSeaSharedStorefront = OpenSeaSharedStorefrontInterface(OS_ADDRESS);
    return (openSeaSharedStorefront.balanceOf(_address, _tokenId) == 1);
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

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OpenSeaSharedStorefrontIds {

  function vipIds() public pure returns(uint256[50] memory) {

  uint256[50] memory VIP_OS_R_IDS = [
    87368869677544583522671190548056816605929929487680250343076510543088019570689, // 1
    87368869677544583522671190548056816605929929487680250343076510544187531198465, // 2
    0, // 3
    0, // 4
    0, // 5
    0, // 6
    0, // 7
    0, // 8
    0, // 9
    0, // 10
    0, // 11
    0, // 12
    0, // 13
    0, // 14
    0, // 15
    0, // 16
    0, // 17
    0, // 18
    0, // 19
    0, // 20
    0, // 21
    0, // 22
    0, // 23
    0, // 24
    0, // 25
    0, // 26
    0, // 27
    0, // 28
    0, // 29
    0, // 30
    0, // 31
    0, // 32
    0, // 33
    0, // 34
    0, // 35
    0, // 36
    0, // 37
    0, // 38
    0, // 39
    0, // 40
    0, // 41
    0, // 42
    0, // 43
    0, // 44
    0, // 45
    0, // 46
    0, // 47
    0, // 48
    0, // 49
    0  // 50
  ];

  // uint256[50] memory VIP_OS_IDS = [
  //   78763235517899702300642317908544281341520076745003203023483945953226286694401, // 1
  //   78763235517899702300642317908544281341520076745003203023483945954325798322177, // 2
  //   78763235517899702300642317908544281341520076745003203023483945955425309949953, // 3
  //   78763235517899702300642317908544281341520076745003203023483945956524821577729, // 4
  //   78763235517899702300642317908544281341520076745003203023483945957624333205505, // 5
  //   78763235517899702300642317908544281341520076745003203023483945958723844833281, // 6
  //   78763235517899702300642317908544281341520076745003203023483945959823356461057, // 7
  //   78763235517899702300642317908544281341520076745003203023483945960922868088833, // 8
  //   78763235517899702300642317908544281341520076745003203023483945962022379716609, // 9
  //   78763235517899702300642317908544281341520076745003203023483945963121891344385, // 10
  //   78763235517899702300642317908544281341520076745003203023483945964221402972161, // 11
  //   78763235517899702300642317908544281341520076745003203023483945965320914599937, // 12
  //   78763235517899702300642317908544281341520076745003203023483945966420426227713, // 13
  //   78763235517899702300642317908544281341520076745003203023483945967519937855489, // 14
  //   78763235517899702300642317908544281341520076745003203023483945968619449483265, // 15
  //   78763235517899702300642317908544281341520076745003203023483945969718961111041, // 16
  //   78763235517899702300642317908544281341520076745003203023483945970818472738817, // 17
  //   78763235517899702300642317908544281341520076745003203023483945971917984366593, // 18
  //   78763235517899702300642317908544281341520076745003203023483945973017495994369, // 19
  //   78763235517899702300642317908544281341520076745003203023483945974117007622145, // 20
  //   78763235517899702300642317908544281341520076745003203023483945975216519249921, // 21
  //   78763235517899702300642317908544281341520076745003203023483945976316030877697, // 22
  //   78763235517899702300642317908544281341520076745003203023483945977415542505473, // 23
  //   78763235517899702300642317908544281341520076745003203023483945978515054133249, // 24
  //   78763235517899702300642317908544281341520076745003203023483945979614565761025, // 25
  //   78763235517899702300642317908544281341520076745003203023483945980714077388801, // 26
  //   78763235517899702300642317908544281341520076745003203023483945981813589016577, // 27
  //   78763235517899702300642317908544281341520076745003203023483945982913100644353, // 28
  //   78763235517899702300642317908544281341520076745003203023483945984012612272129, // 29
  //   78763235517899702300642317908544281341520076745003203023483945985112123899905, // 30
  //   78763235517899702300642317908544281341520076745003203023483945986211635527681, // 31
  //   78763235517899702300642317908544281341520076745003203023483945987311147155457, // 32
  //   78763235517899702300642317908544281341520076745003203023483945988410658783233, // 33
  //   78763235517899702300642317908544281341520076745003203023483945989510170411009, // 34
  //   78763235517899702300642317908544281341520076745003203023483945990609682038785, // 35
  //   78763235517899702300642317908544281341520076745003203023483945991709193666561, // 36
  //   78763235517899702300642317908544281341520076745003203023483945992808705294337, // 37
  //   78763235517899702300642317908544281341520076745003203023483945993908216922113, // 38
  //   78763235517899702300642317908544281341520076745003203023483945995007728549889, // 39
  //   78763235517899702300642317908544281341520076745003203023483945996107240177665, // 40
  //   78763235517899702300642317908544281341520076745003203023483945997206751805441, // 41
  //   78763235517899702300642317908544281341520076745003203023483945998306263433217, // 42
  //   78763235517899702300642317908544281341520076745003203023483945999405775060993, // 43
  //   78763235517899702300642317908544281341520076745003203023483946000505286688769, // 44
  //   78763235517899702300642317908544281341520076745003203023483946001604798316545, // 45
  //   78763235517899702300642317908544281341520076745003203023483946002704309944321, // 46
  //   78763235517899702300642317908544281341520076745003203023483946003803821572097, // 47
  //   78763235517899702300642317908544281341520076745003203023483946004903333199873, // 48
  //   78763235517899702300642317908544281341520076745003203023483946006002844827649, // 49
  //   78763235517899702300642317908544281341520076745003203023483946007102356455425  // 50
  // ];

  return VIP_OS_R_IDS;

  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OpenSeaSharedStorefrontInterface {
  function balanceOf(address _owner, uint256 _id) external view returns (uint256){}
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory){}
}