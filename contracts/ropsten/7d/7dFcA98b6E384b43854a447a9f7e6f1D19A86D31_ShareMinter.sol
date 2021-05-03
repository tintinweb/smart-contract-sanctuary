// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./libraries/FullMath.sol";
import "./interfaces/IHEX.sol";
import "./MinterReceiver.sol";

/// @title HEX Share Minter
/// @author Sam Presnal - Staker
/// @dev Mint shares to any receiving contract that implements the
/// MinterReceiver abstract contract
/// @notice Minter rewards are claimable by ANY caller
/// if the 10 day grace period has expired
contract ShareMinter {
    IHEX public hexContract;

    uint256 private constant GRACE_PERIOD_DAYS = 10;
    uint256 private constant FEE_SCALE = 1000;

    struct Stake {
        uint16 shareRatePremium;
        uint24 unlockDay;
        address minter;
        MinterReceiver receiver;
    }
    mapping(uint40 => Stake) public stakes;

    mapping(address => uint256) public minterHeartsOwed;

    event MintShares(
        uint40 indexed stakeId,
        MinterReceiver indexed receiver,
        uint256 data0 //total shares | staked hearts << 72
    );
    event MintEarnings(uint40 indexed stakeId, MinterReceiver indexed receiver, uint72 hearts);
    event MinterWithdraw(address indexed minter, uint256 heartsWithdrawn);

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(IHEX _hex) {
        hexContract = _hex;
    }

    /// @notice Starts stake and mints shares to the specified receiver
    /// @param shareRatePremium Applies premium to share price between 0.0-99.9%
    /// @param receiver The contract to receive the newly minted shares
    /// @param supplier The reimbursement address for the supplier
    /// @param newStakedHearts Hearts to stake to the HEX contract
    /// @param newStakedDays Days in length of the stake
    function mintShares(
        uint16 shareRatePremium,
        MinterReceiver receiver,
        address supplier,
        uint256 newStakedHearts,
        uint256 newStakedDays
    ) external lock {
        require(shareRatePremium < FEE_SCALE, "PREMIUM_TOO_HIGH");
        require(
            ERC165Checker.supportsInterface(address(receiver), type(MinterReceiver).interfaceId),
            "UNSUPPORTED_RECEIVER"
        );

        //Transfer HEX to contract
        hexContract.transferFrom(msg.sender, address(this), newStakedHearts);

        //Start stake
        (uint40 stakeId, uint72 stakedHearts, uint72 stakeShares, uint24 unlockDay) =
            _startStake(newStakedHearts, newStakedDays);

        //Calculate minterShares and marketShares
        uint256 minterShares = FullMath.mulDiv(shareRatePremium, stakeShares, FEE_SCALE);
        uint256 marketShares = stakeShares - minterShares;

        //Mint shares to the market and store stake info for later
        receiver.onSharesMinted(stakeId, supplier, stakedHearts, uint72(marketShares));
        stakes[stakeId] = Stake(shareRatePremium, unlockDay, msg.sender, receiver);

        emit MintShares(stakeId, receiver, uint256(uint72(stakeShares)) | (uint256(uint72(stakedHearts)) << 72));
    }

    function _startStake(uint256 newStakedHearts, uint256 newStakedDays)
        internal
        returns (
            uint40 stakeId,
            uint72 stakedHearts,
            uint72 stakeShares,
            uint24 unlockDay
        )
    {
        hexContract.stakeStart(newStakedHearts, newStakedDays);
        uint256 stakeCount = hexContract.stakeCount(address(this));
        (uint40 _stakeId, uint72 _stakedHearts, uint72 _stakeShares, uint16 _lockedDay, uint16 _stakedDays, , ) =
            hexContract.stakeLists(address(this), stakeCount - 1);
        return (_stakeId, _stakedHearts, _stakeShares, _lockedDay + _stakedDays);
    }

    /// @notice Ends stake, transfers hearts, and calls receiver onEarningsMinted
    /// @dev The stake must be mature in order to mint earnings
    /// @param stakeIndex Index of the stake to be ended
    /// @param stakeId StakeId of the stake to be ended
    function mintEarnings(uint256 stakeIndex, uint40 stakeId) external lock {
        //Ensure the stake has matured
        Stake memory stake = stakes[stakeId];
        uint256 currentDay = hexContract.currentDay();
        require(currentDay >= stake.unlockDay, "STAKE_NOT_MATURE");

        //Calculate minter earnings and market earnings
        uint256 heartsEarned = _endStake(stakeIndex, stakeId);
        uint256 minterEarnings = FullMath.mulDiv(stake.shareRatePremium, heartsEarned, FEE_SCALE);
        uint256 marketEarnings = heartsEarned - minterEarnings;

        //Transfer market earnings to receiver contract and notify
        MinterReceiver receiver = stake.receiver;
        hexContract.transfer(address(receiver), marketEarnings);
        receiver.onEarningsMinted(stakeId, uint72(marketEarnings));

        //Pay minter or record payment for claiming later
        _payMinterEarnings(currentDay, stake.unlockDay, stake.minter, minterEarnings);

        emit MintEarnings(stakeId, receiver, uint72(heartsEarned));

        delete stakes[stakeId];
    }

    function _endStake(uint256 stakeIndex, uint40 stakeId) internal returns (uint256 heartsEarned) {
        uint256 prevHearts = hexContract.balanceOf(address(this));
        hexContract.stakeEnd(stakeIndex, stakeId);
        uint256 newHearts = hexContract.balanceOf(address(this));
        heartsEarned = newHearts - prevHearts;
    }

    /// @notice The minter earnings are claimable by any caller
    /// if the grace period has expired. If the grace period has
    /// not expired and the minter is not the caller, then record
    /// the minter earnings. If the minter is the caller,
    /// they will get the earnings sent immediately.
    function _payMinterEarnings(
        uint256 currentDay,
        uint256 unlockDay,
        address minter,
        uint256 minterEarnings
    ) internal {
        uint256 lateDays = currentDay - unlockDay;
        if (msg.sender != minter && lateDays < GRACE_PERIOD_DAYS) {
            minterHeartsOwed[minter] += minterEarnings;
        } else {
            hexContract.transfer(msg.sender, minterEarnings);
        }
    }

    /// @notice Allow minter to withdraw earnings if applicable
    /// @dev Only applies when a non-minter ends a stake before
    /// the grace period has expired
    function minterWithdraw() external lock {
        uint256 heartsOwed = minterHeartsOwed[msg.sender];
        require(heartsOwed != 0, "NO_HEARTS_OWED");

        minterHeartsOwed[msg.sender] = 0;
        hexContract.transfer(msg.sender, heartsOwed);

        emit MinterWithdraw(msg.sender, heartsOwed);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

interface IHEX {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function currentDay() external view returns (uint256);

    function stakeCount(address stakerAddr) external view returns (uint256);

    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external;

    function stakeLists(address, uint256)
        external
        view
        returns (
            uint40 stakeId,
            uint72 stakedHearts,
            uint72 stakeShares,
            uint16 lockedDay,
            uint16 stakedDays,
            uint16 unlockedDay,
            bool isAutoStake
        );

    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title HEX Minter Receiver
/// @author Sam Presnal - Staker
/// @dev Receives shares and hearts earned from the ShareMinter
abstract contract MinterReceiver is ERC165 {
    /// @notice ERC165 ensures the minter receiver supports the interface
    /// @param interfaceId The MinterReceiver interface id
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(MinterReceiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Receives newly started stake properties
    /// @param stakeId The HEX stakeId
    /// @param supplier The reimbursement address for the supplier
    /// @param stakedHearts Hearts staked
    /// @param stakeShares Shares available
    function onSharesMinted(
        uint40 stakeId,
        address supplier,
        uint72 stakedHearts,
        uint72 stakeShares
    ) external virtual;

    /// @notice Receives newly ended stake properties
    /// @param stakeId The HEX stakeId
    /// @param heartsEarned Hearts earned from the stake
    function onEarningsMinted(uint40 stakeId, uint72 heartsEarned) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}