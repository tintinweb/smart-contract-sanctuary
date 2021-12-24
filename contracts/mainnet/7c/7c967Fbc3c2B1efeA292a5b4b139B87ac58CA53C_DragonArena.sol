// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./structs/DragonInfo.sol";
import "./structs/FightInfo.sol";
import "./utils/Random.sol";
import "./LockableReceiver.sol";
import "./DragonToken.sol";

contract DragonArena is LockableReceiver { 

    using SafeMath for uint;
    using Address for address payable;

    mapping(uint => uint) private _fights;
    mapping(uint => uint) private _dragonFights;
    mapping(uint => uint) private _attackers;

    uint private _fightPrice;

    event JoinFight(address indexed originator, uint fightId, uint dragonId);
    event FightFinished(address indexed operator, uint fightId, uint winnerId, bool technicalDefeat);
    event FightCancelled(address indexed operator, uint fightId);

    constructor(address accessControl, address dragonToken, uint weiFightPrice) 
    LockableReceiver(accessControl, dragonToken) {
        _fightPrice = weiFightPrice;
    }

    function price() external view returns(uint) {
        return _fightPrice;
    }

    function attackerFight(uint attackerId) public view returns (uint) {
        return _attackers[attackerId];
    }

    function fightOf(uint dragonId) public view returns (uint) {
        return _dragonFights[dragonId];
    }

    function setPrice(uint newPrice) external onlyRole(CFO_ROLE) {
        uint previousPrice = _fightPrice;
        _fightPrice = newPrice;
        emit ValueChanged("fightPrice", previousPrice, newPrice);
    }

    function getFightId(bytes calldata fightToken) public pure returns (uint) {
        return uint(keccak256(fightToken));
    }

    function fightInfo(uint fightId) external view returns (FightInfo.Details memory) {
        return FightInfo.getDetails(_fights[fightId]);
    }

    function joinFight(uint dragonId, bytes calldata fightToken) 
    external payable
    onlyHolder(dragonId) {
        require(fightOf(dragonId) == 0, "DragonArena: a dragon with the given id has already joined another fight");
        (uint value, FightInfo.Details memory fight) = FightInfo.readDetailsFromToken(fightToken);
        require(fight.dragon1Id > 0 && fight.dragon2Id > 0 
            && fight.dragon1Id != fight.dragon2Id 
            && ((fight.fightType == FightInfo.Types.Regular && fight.betAmount == 0)
                || (fight.fightType == FightInfo.Types.Money && fight.betAmount > 0)), "DragonArena: bad fight token");
        require(dragonId == fight.dragon1Id || dragonId == fight.dragon2Id, 
            "DragonArena: a dragon with the given id is not associated with this fight");
        require(msg.value >= (_fightPrice + fight.betAmount), "DragonArena: incorrect amount sent to the contract");

        uint fightId = getFightId(fightToken);
        // if it's an attacker dragon and a dragon-defender hasn't joined the fight yet then revert the transaction
        if (dragonId == fight.dragon1Id && fightOf(fight.dragon2Id) != fightId) { 
            revert("DragonArena: the dragon-defender must accept the fight first");
        }
        // if there is another record with the same dragon-attacker
        if (dragonId == fight.dragon2Id && attackerFight(fight.dragon1Id) > 0) { 
            revert("DragonArena: there is another fight with the same dragon-attacker");
        }
        
        if (_fights[fightId] == 0) {
            _fights[fightId] = value;
        }
        _attackers[fight.dragon1Id] = fightId;
        _dragonFights[dragonId] = fightId;

        emit JoinFight(_msgSender(), fightId, dragonId);
    }

    function startFight(uint fightId) external onlyRole(COO_ROLE) {
        uint fightValue = _fights[fightId];
        require(fightValue > 0, "DragonArena: a fight with the given id doesn't exist");
        FightInfo.Details memory fight = FightInfo.getDetails(fightValue);

        require(isLocked(fight.dragon1Id) && isLocked(fight.dragon2Id), 
            "DragonArena: both the dragons must be locked on the contract before starting a fight");
        
        DragonToken dragonToken = DragonToken(tokenContract());

        //init the strengths before fighting
        dragonToken.setStrength(fight.dragon1Id);
        dragonToken.setStrength(fight.dragon2Id);

        (uint winnerId, uint loserId, bool technicalDefeat) = _checkTechnicalDefeat(fight);

        if (!technicalDefeat) {
            DragonInfo.Details memory dd1 = dragonToken.dragonInfo(fight.dragon1Id);
            DragonInfo.Details memory dd2 = dragonToken.dragonInfo(fight.dragon2Id);
            (winnerId, loserId) = 
                _randomFightResult(fight.dragon1Id, dd1.strength, fight.dragon2Id, dd2.strength, fightId);
        }

        _transferTrophy(winnerId, loserId, fight, technicalDefeat);
        
        delete _attackers[fight.dragon1Id];
        delete _dragonFights[fight.dragon1Id];
        delete _dragonFights[fight.dragon2Id];
        delete _fights[fightId];

        emit FightFinished(_msgSender(), fightId, winnerId, technicalDefeat);
    }

    function cancelFight(uint fightId) external onlyRole(COO_ROLE) {
        uint fightValue = _fights[fightId];
        require(fightValue > 0, "DragonArena: a fight with the given id doesn't exist");
        FightInfo.Details memory fight = FightInfo.getDetails(fightValue);
        
        delete _attackers[fight.dragon1Id];
        delete _dragonFights[fight.dragon1Id];
        delete _dragonFights[fight.dragon2Id];
        delete _fights[fightId];

        emit FightCancelled(_msgSender(), fightId);
    }

    function withdraw(uint tokenId) public override virtual  {
        require(fightOf(tokenId) == 0 && attackerFight(tokenId) == 0, "DragonArena: unable to withdraw");
        super.withdraw(tokenId);
    }

    function _checkTechnicalDefeat(FightInfo.Details memory fight) internal view returns (uint, uint, bool) {
        uint f1 = _dragonFights[fight.dragon1Id];
        uint f2 = _dragonFights[fight.dragon2Id];
        require(f1 > 0 || f2 > 0, "DragonArena: none of the dragons has joined the fight");
        return  (f1 == 0) ? (fight.dragon2Id, fight.dragon1Id, true) : 
                (f2 == 0) ? (fight.dragon1Id, fight.dragon2Id, true) : 
                (0, 0, false);
    }

    function _transferTrophy(uint winnerId, uint loserId, FightInfo.Details memory fight, bool technicalDefeat) internal {
        if (fight.fightType == FightInfo.Types.Regular || technicalDefeat) {
            _lock(loserId, holderOf(winnerId));
            _transferTokenToHolder(loserId);
        }
        else if (fight.fightType == FightInfo.Types.Money) {
            payable(holderOf(winnerId)).sendValue(fight.betAmount*2);
        }
    }

    function _randomFightResult(uint dragon1Id, uint dragon1Strength, uint dragon2Id, uint dragon2Strength, uint salt)
    internal view returns (uint, uint) {

        uint totalStrength = dragon1Strength + dragon2Strength;
        uint result = Random.rand(salt ^ block.difficulty).mod(totalStrength);

        uint minId;
        uint maxId;
        uint minStrength;

        if (dragon1Strength < dragon2Strength) {
            minId = dragon1Id;
            minStrength = dragon1Strength;
            maxId = dragon2Id;
        } else {
            minId = dragon2Id;
            minStrength = dragon2Strength;
            maxId = dragon1Id;
        }

        if (result < minStrength) {
            return (minId, maxId);
        }
        else {
            return (maxId, minId);
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
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library DragonInfo {
    
    uint constant MASK = 0xF000000000000000000000000;

    enum Types { 
        Unknown,
        Common, 
        Rare16, 
        Rare17, 
        Rare18, 
        Rare19,
        Epic20, 
        Epic21,
        Epic22,
        Epic23,
        Epic24, 
        Legendary
    }

    struct Details { 
        uint genes;
        uint eggId;
        uint parent1Id;
        uint parent2Id;
        uint generation;
        uint strength;
        Types dragonType;
    }

    function getDetails(uint value) internal pure returns (Details memory) {
        return Details (
            {
                genes: uint256(uint104(value)),
                parent1Id: uint256(uint32(value >> 104)),
                parent2Id: uint256(uint32(value >> 136)),
                generation: uint256(uint16(value >> 168)),
                strength: uint256(uint16(value >> 184)),
                dragonType: Types(uint16(value >> 200)),
                eggId: uint256(uint32(value >> 216))
            }
        );
    }

    function getValue(Details memory details) internal pure returns (uint) {
        uint result = uint(details.genes);
        result |= details.parent1Id << 104;
        result |= details.parent2Id << 136;
        result |= details.generation << 168;
        result |= details.strength << 184;
        result |= uint(details.dragonType) << 200;
        result |= details.eggId << 216;
        return result;
    }

    function calcType(uint genes) internal pure returns (Types) {
        uint mask = MASK;
        uint numRare = 0;
        uint numEpic = 0;
        for (uint i = 0; i < 10; i++) { //just Rare and Epic genes are important to check
            if (genes & mask > 0) {
                if (i < 5) { //Epic-range
                    numEpic++;
                }
                else { //Rare-range
                    numRare++;
                }
            }
            mask = mask >> 4;
        }
        Types result = Types.Unknown;
        if (numEpic == 5 && numRare == 5) {
            result = Types.Legendary;
        }
        else if (numEpic < 5 && numRare == 5) {
            result = Types(6 + numEpic);
        }
        else if (numEpic == 0 && numRare < 5) {
            result = Types(1 + numRare);
        }
        else if (numEpic == 0 && numRare == 0) {
            result = Types.Common;
        }

        return result;
    }

    function calcStrength(uint genes) internal pure returns (uint) {
        uint mask = MASK;
        uint strength = 0;
        for (uint i = 0; i < 25; i++) { 
            uint gLevel = (genes & mask) >> ((24 - i) * 4);
            if (i < 6) { //Epic
                strength += 3 * (25 - i) * gLevel;
            } 
            else if (i < 10) { //Rare 
                strength += 2 * (25 - i) * gLevel;
            }
            else { //Common-range
                if (gLevel > 0) {
                    strength += (25 - i) * gLevel;
                }
                else {
                    strength += (25 - i);
                }
            }
            mask = mask >> 4;
        }
        return strength;
    }

    function calcGeneration(uint g1, uint g2) internal pure returns (uint) {
        return (g1 >= g2 ? g1 : g2) + 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../utils/BytesLib.sol";

library FightInfo {
    enum Types { Regular, Money }

    struct Details {
        uint dragon1Id;
        uint dragon2Id;
        Types fightType;
        uint betAmount;
    }

    function getValue(Details calldata info) internal pure returns (uint) {
        uint result = uint(info.dragon1Id);
        result |= info.dragon2Id << 32;
        result |= uint(info.fightType) << 64;
        result |= info.betAmount << 72;
        return result;
    }

    function readDetailsFromToken(bytes calldata fightToken) internal pure returns (uint, Details memory) {
        uint value = BytesLib.toUint256(fightToken, 0);
        return (value, getDetails(value));
    }

    function getDetails(uint value) internal pure returns (Details memory) {
        return Details (
            {
                dragon1Id: uint256(uint32(value)),
                dragon2Id: uint256(uint32(value >> 32)),
                fightType: Types(uint8(value >> 64)),
                betAmount: uint256(uint184(value >> 72))
            }
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library Random {
    function rand(uint salt) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, salt)));
    }

    function randFrom(uint[] memory array, uint from, uint to, uint randomValue)
    internal pure returns (uint) {
        uint count = to - from;
        return array[from + randomValue % count];
    }

    function shuffle(uint[] memory array, uint randomValue) internal pure returns (uint[] memory) {
        for (uint i = 0; i < array.length; i++) {
            uint n = i + randomValue % (array.length - i);
            uint temp = array[n];
            array[n] = array[i];
            array[i] = temp;
        }
        return array;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./access/BaseAccessControl.sol";

abstract contract LockableReceiver is BaseAccessControl, IERC721Receiver {
    
    using Address for address payable;

    address private _tokenContractAddress;
    mapping(uint => address) private _lockedTokens;

    event TokenLocked(uint tokenId, address indexed holder);
    event TokenWithdrawn(uint tokenId, address indexed holder);
    event EthersWithdrawn(address indexed operator, address indexed to, uint amount);

    constructor (address accessControl, address tokenContractAddress) 
    BaseAccessControl(accessControl) {
        _tokenContractAddress = tokenContractAddress;
    }

    modifier whenLocked(uint tokenId) {
        require(isLocked(tokenId), "LockableReceiver: token must be locked");
        _;
    }

    modifier onlyHolder(uint tokenId) {
        require(holderOf(tokenId) == _msgSender(), "LockableReceiver: caller is not the token holder");
        _;
    }

    function onERC721Received(address operator, address /*from*/, uint /*tokenId*/, bytes calldata /*data*/) 
        external virtual override returns (bytes4) {
        require(operator == address(this), "LockableReceiver: the caller is not a valid operator");
        return this.onERC721Received.selector;
    }

    function receiveApproval(address sender, uint tokenId, address _tokenContract, bytes calldata data) external virtual {
        require(tokenContract() == _msgSender(), "LockableReceiver: not enough privileges to call the method");
        require(_tokenContract == tokenContract(), "LockableReceiver: unable to receive the given token");
    
        IERC721(tokenContract()).safeTransferFrom(sender, address(this), tokenId, data);
        
        _lock(tokenId, sender);
        processERC721(sender, tokenId, data);
    }

    function processERC721(address from, uint tokenId, bytes calldata data) internal virtual {
    }

    function _lock(uint tokenId, address holder) internal {
        _lockedTokens[tokenId] = holder;
        emit TokenLocked(tokenId, holder);
    }

    function _unlock(uint tokenId) internal {
        delete _lockedTokens[tokenId];
    }

    function tokenContract() public view returns (address) {
        return _tokenContractAddress;
    }

    function setTokenContract(address newAddress) external onlyRole(CEO_ROLE) {
        address previousAddress = _tokenContractAddress;
        _tokenContractAddress = newAddress;
        emit AddressChanged("tokenContract", previousAddress, newAddress);
    }

    function isLocked(uint tokenId) public view returns (bool) {
        return _lockedTokens[tokenId] != address(0);
    }

    function holderOf(uint tokenId) public view returns (address) {
        return _lockedTokens[tokenId];
    }

    function withdrawEthers(uint amount, address payable to) external virtual onlyRole(CFO_ROLE) {
        to.sendValue(amount);
        emit EthersWithdrawn(_msgSender(), to, amount);
    }

    function withdraw(uint tokenId) public virtual onlyHolder(tokenId) {
        _transferTokenToHolder(tokenId);
        emit TokenWithdrawn(tokenId, _msgSender());
    }

    function _transferTokenToHolder(uint tokenId) internal virtual {
        address holder = holderOf(tokenId);
        if (holder != address(0)) {
            IERC721(tokenContract()).safeTransferFrom(address(this), holder, tokenId);
            _unlock(tokenId);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./access/BaseAccessControl.sol";
import "./structs/DragonInfo.sol";

contract DragonToken is ERC721, BaseAccessControl {

    using Address for address;
    using Counters for Counters.Counter;
    
    Counters.Counter private _dragonIds;

    // Mapping token id to dragon details
    mapping(uint => uint) private _info;
    // Mapping token id to cid
    mapping(uint => string) private _cids;

    string private _defaultMetadataCid;
    address private _dragonCreator;

    constructor(string memory defaultCid, address accessControl) 
    ERC721("CryptoDragons", "CD")
    BaseAccessControl(accessControl) {        
        _defaultMetadataCid = defaultCid;
    }

    function approveAndCall(address spender, uint256 tokenId, bytes calldata extraData) external returns (bool success) {
        _approve(spender, tokenId);
        (bool _success, ) = 
            spender.call(
                abi.encodeWithSignature("receiveApproval(address,uint256,address,bytes)", 
                _msgSender(), 
                tokenId, 
                address(this), 
                extraData) 
            );
        if(!_success) { 
            revert("DragonToken: spender internal error"); 
        }
        return true;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        string memory cid = _cids[tokenId];
        return string(abi.encodePacked("ipfs://", (bytes(cid).length > 0) ? cid : defaultMetadataCid()));
    }

    function dragonCreatorAddress() public view returns(address) {
        return _dragonCreator;
    }

    function setDragonCreatorAddress(address newAddress) external onlyRole(CEO_ROLE) {
        address previousAddress = _dragonCreator;
        _dragonCreator = newAddress;
        emit AddressChanged("dragonCreator", previousAddress, newAddress);
    }

    function hasMetadataCid(uint tokenId) public view returns(bool) {
        return bytes(_cids[tokenId]).length > 0;
    }

    function setMetadataCid(uint tokenId, string calldata cid) external onlyRole(COO_ROLE) {
        require(bytes(cid).length >= 46, "DragonToken: bad CID");
        require(!hasMetadataCid(tokenId), "DragonToken: CID is already set");
        _cids[tokenId] = cid;
    }

    function defaultMetadataCid() public view returns (string memory){
        return _defaultMetadataCid;
    }

    function setDefaultMetadataCid(string calldata newDefaultCid) external onlyRole(COO_ROLE) {
        _defaultMetadataCid = newDefaultCid;
    }

    function dragonInfo(uint dragonId) public view returns (DragonInfo.Details memory) {
        return DragonInfo.getDetails(_info[dragonId]);
    }

    function strengthOf(uint dragonId) external view returns (uint) {
        DragonInfo.Details memory details = dragonInfo(dragonId);
        return details.strength > 0 ? details.strength : DragonInfo.calcStrength(details.genes);
    }

    function isSiblings(uint dragon1Id, uint dragon2Id) external view returns (bool) {
        DragonInfo.Details memory info1 = dragonInfo(dragon1Id);
        DragonInfo.Details memory info2 = dragonInfo(dragon2Id);
        return 
            (info1.generation > 1 && info2.generation > 1) && //the 1st generation of dragons doesn't have siblings
            (info1.parent1Id == info2.parent1Id || info1.parent1Id == info2.parent2Id || 
            info1.parent2Id == info2.parent1Id || info1.parent2Id == info2.parent2Id);
    }

    function isParent(uint dragon1Id, uint dragon2Id) external view returns (bool) {
        DragonInfo.Details memory info = dragonInfo(dragon1Id);
        return info.parent1Id == dragon2Id || info.parent2Id == dragon2Id;
    }

    function mint(address to, DragonInfo.Details calldata info) external returns (uint) {
        require(_msgSender() == dragonCreatorAddress(), "DragonToken: not enough privileges to call the method");
        
        _dragonIds.increment();
        uint newDragonId = uint(_dragonIds.current());
        
        _info[newDragonId] = DragonInfo.getValue(info);
        _mint(to, newDragonId);

        return newDragonId;
    }

    function setStrength(uint dragonId) external returns (uint) {
        DragonInfo.Details memory details = dragonInfo(dragonId);
        if (details.strength == 0) {
            details.strength = DragonInfo.calcStrength(details.genes);
            _info[dragonId] = DragonInfo.getValue(details);
        }
        return details.strength;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }
    
    function toUint256(bytes memory _bytes, uint _start) internal pure returns (uint) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toTuple128(bytes memory _bytes, uint256 _start) internal pure returns (uint, uint) {
        require(_bytes.length >= _start + 32, "toTuple16_outOfBounds");
        uint tempUint;
        uint n1;
        uint n2;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
            n1 := and(shr(0x80, tempUint), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            n2 := and(tempUint, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }

        return (n1, n2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IChangeableVariables.sol";

abstract contract BaseAccessControl is Context, IChangeableVariables {

    bytes32 public constant CEO_ROLE = keccak256("CEO");
    bytes32 public constant CFO_ROLE = keccak256("CFO");
    bytes32 public constant COO_ROLE = keccak256("COO");

    address private _accessControl;

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    constructor (address accessControl) Context() {
        _accessControl = accessControl;
    }

    function accessControlAddress() public view returns (address) {
        return _accessControl;
    }

    function setAccessControlAddress(address newAddress) external onlyRole(CEO_ROLE) {
        address previousAddress = _accessControl;
        _accessControl = newAddress;
        emit AddressChanged("accessControl", previousAddress, newAddress);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return IAccessControl(accessControlAddress()).hasRole(role, account);
    }

    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }
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

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IChangeableVariables {
    event AddressChanged(string fieldName, address previousAddress, address newAddress);
    event ValueChanged(string fieldName, uint previousValue, uint newValue);
    event BoolValueChanged(string fieldName, bool previousValue, bool newValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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