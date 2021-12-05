// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICryptoFoxesOrigins.sol";
import "./interfaces/ICryptoFoxesStakingV2.sol";
import "./interfaces/ICryptoFoxesCalculationOrigin.sol";
import "./interfaces/ICryptoFoxesCalculationV2.sol";
import "./interfaces/ICryptoFoxesStakingStruct.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./CryptoFoxesUtility.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// @author: miinded.com

contract CryptoFoxesCalculationV2 is Ownable, ICryptoFoxesCalculationV2, ICryptoFoxesStakingStruct, ICryptoFoxesCalculationOrigin, CryptoFoxesUtility, ReentrancyGuard {
    uint256 public constant BASE_RATE_ORIGIN = 6 * 10**18;
    uint256 public constant BASE_RATE_V2 = 1 * 10**18;
    uint256 public BONUS_MAX_OWNED = 2; // 0.2

    address private cryptoFoxesOrigin;
    address private cryptoFoxesStakingV2;

    function setCryptoFoxesOrigin(address _contract) public onlyOwner{
        if(cryptoFoxesOrigin != address(0)) {
            setAllowedContract(cryptoFoxesOrigin, false);
        }
        setAllowedContract(_contract, true);
        cryptoFoxesOrigin = _contract;
    }

    function setCryptoFoxesStakingV2(address _contract) public onlyOwner{
        if(cryptoFoxesStakingV2 != address(0)) {
            setAllowedContract(cryptoFoxesStakingV2, false);
        }
        setAllowedContract(_contract, true);
        cryptoFoxesStakingV2 = _contract;
    }

    function calculationRewards(address _contract, uint256[] memory _tokenIds, uint256 _currentTimestamp) public override view returns(uint256){

        if(_tokenIds.length <= 0){ return 0; }

        address ownerOrigin = IERC721(_contract).ownerOf(_tokenIds[0]);
        uint256 _currentTime = ICryptoFoxesOrigins(_contract)._currentTime(_currentTimestamp);

        uint256 totalRewards = 0;

        for (uint8 i = 0; i < _tokenIds.length; i++) {
            if(_tokenIds[i] > 1000) continue;

            for (uint8 j = 0; j < i; j++) {
                require(_tokenIds[j] != _tokenIds[i], "Duplicate id");
            }

            uint256 stackTime = ICryptoFoxesOrigins(_contract).getStackingToken(_tokenIds[i]);
            stackTime = stackTime == 0 ? block.timestamp - 5 days : stackTime;
            if (_currentTime > stackTime) {
                totalRewards += (_currentTime - stackTime) * BASE_RATE_ORIGIN;
            }

            // calcul des V2
            uint8 maxSlotsOrigin = ICryptoFoxesStakingV2(cryptoFoxesStakingV2).getOriginMaxSlot(uint16(_tokenIds[i]));
            Staking[] memory foxesV2 = ICryptoFoxesStakingV2(cryptoFoxesStakingV2).getV2ByOrigin(uint16(_tokenIds[i]));
            uint256 numberTokensOwner = 0;
            uint256 calculation = 0;
            for(uint8 k = 0; k < foxesV2.length; k++){
                // calcul
                calculation += (_currentTime - max(stackTime, foxesV2[k].timestampV2) ) * BASE_RATE_V2;

                if(ownerOrigin == foxesV2[k].owner){
                    numberTokensOwner += 1;
                }
            }

            totalRewards += calculation;

            if(numberTokensOwner == foxesV2.length && numberTokensOwner == maxSlotsOrigin){
                totalRewards += calculation * BONUS_MAX_OWNED / 10;
            }
        }

        return totalRewards / 86400;
    }

    function claimRewards(address _contract, uint256[] memory _tokenIds, address _owner) public override isFoxContract nonReentrant {
        require(!isPaused(), "Contract paused");

        uint256 reward = calculationRewards(_contract, _tokenIds, block.timestamp);

        _addRewards(_owner, reward);
        _withdrawRewards(_owner);
    }

    function calculationRewardsV2(address _contract, uint16[] memory _tokenIds, uint256 _currentTimestamp) public override view returns(uint256){
        uint256 _currentTime = ICryptoFoxesStakingV2(_contract)._currentTime(_currentTimestamp);
        uint256 totalSeconds = 0;
        for (uint8 i = 0; i < _tokenIds.length; i++) {

            for (uint16 j = 0; j < i; j++) {
                require(_tokenIds[j] != _tokenIds[i], "Duplicate id");
            }

            uint256 stackTime = ICryptoFoxesStakingV2(_contract).getStakingTokenV2(_tokenIds[i]);

            if (_currentTime > stackTime) {
                totalSeconds += _currentTime - stackTime;
            }
        }

        return (BASE_RATE_V2 * totalSeconds) / 86400;
    }

    function claimRewardsV2(address _contract, uint16[] memory _tokenIds, address _owner) public override isFoxContract nonReentrant {
        require(!isPaused(), "Contract paused");

        uint256 rewardV2 = 0;
        uint256 _currentTime = ICryptoFoxesStakingV2(_contract)._currentTime(block.timestamp);

        for (uint8 i = 0; i < _tokenIds.length; i++) {

            uint256 stackTimeV2 = ICryptoFoxesStakingV2(_contract).getStakingTokenV2(_tokenIds[i]);

            uint16 origin = ICryptoFoxesStakingV2(_contract).getOriginByV2( _tokenIds[i] );
            uint256 stackTimeOrigin = ICryptoFoxesOrigins(cryptoFoxesOrigin).getStackingToken(origin);
            address ownerOrigin = IERC721(cryptoFoxesOrigin).ownerOf( origin );

            if (_currentTime > stackTimeV2) {
                rewardV2 += (BASE_RATE_V2 * (_currentTime - stackTimeV2)) / 86400;
                _addRewards(ownerOrigin, (BASE_RATE_V2 * (_currentTime - max(stackTimeOrigin, stackTimeV2) )) / 86400);
            }
        }

        _addRewards(_owner, rewardV2);
        _withdrawRewards(_owner);
    }

    function claimMoveRewardsOrigin(address _contract, uint16 _tokenId, address _ownerOrigin) public override isFoxContract nonReentrant {
        uint256 _currentTime = ICryptoFoxesStakingV2(_contract)._currentTime(block.timestamp);

        uint16 origin = ICryptoFoxesStakingV2(_contract).getOriginByV2( _tokenId );
        uint256 stackTimeOrigin = ICryptoFoxesOrigins(cryptoFoxesOrigin).getStackingToken(origin);
        uint256 stackTimeV2 = ICryptoFoxesStakingV2(_contract).getStakingTokenV2(_tokenId);

        _addRewards(_ownerOrigin, (BASE_RATE_V2 * (_currentTime - max(stackTimeOrigin, stackTimeV2) )) / 86400);
    }

    function calculationOriginDay(uint16 _tokenId, bool _withOwnedV2) public view returns(uint256){

        address ownerOrigin = IERC721(cryptoFoxesOrigin).ownerOf(uint256(_tokenId));
        uint8 maxSlotsOrigin = ICryptoFoxesStakingV2(cryptoFoxesStakingV2).getOriginMaxSlot(uint16(_tokenId));
        Staking[] memory foxesV2 = ICryptoFoxesStakingV2(cryptoFoxesStakingV2).getV2ByOrigin(uint16(_tokenId));

        uint256 numberTokensOwner = 0;
        uint256 calculationV2 = 0;

        for(uint8 k = 0; k < foxesV2.length; k++){

            calculationV2 += BASE_RATE_V2;

            if(ownerOrigin == foxesV2[k].owner){
                numberTokensOwner += 1;
            }
        }
        if(numberTokensOwner == foxesV2.length && numberTokensOwner == maxSlotsOrigin){
            calculationV2 += calculationV2 * BONUS_MAX_OWNED / 10;
        }

        return BASE_RATE_ORIGIN + calculationV2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesSteak {
    function addRewards(address _to, uint256 _amount) external;
    function withdrawRewards(address _to) external;
    function isPaused() external view returns(bool);
    function dateEndRewards() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com
import "./ICryptoFoxesStakingStruct.sol";

interface ICryptoFoxesStakingV2 is ICryptoFoxesStakingStruct  {
    function getOriginMaxSlot(uint16 _tokenIdOrigin) external view returns(uint8);
    function getStakingTokenV2(uint16 _tokenId) external view returns(uint256);
    function getV2ByOrigin(uint16 _tokenIdOrigin) external view returns(Staking[] memory);
    function getOriginByV2(uint16 _tokenId) external view returns(uint16);
    function unlockSlot(uint16 _tokenId, uint8 _count) external;
    function _currentTime(uint256 _currentTimestamp) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesStakingStruct {

    struct Staking {
        uint8 slotIndex;
        uint16 tokenId;
        uint16 origin;
        uint64 timestampV2;
        address owner;
    }

    struct Origin{
        uint8 maxSlots;
        uint16[] stacked;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesOrigins {
    function getStackingToken(uint256 tokenId) external view returns(uint256);
    function _currentTime(uint256 _currentTimestamp) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesCalculationV2 {
    function calculationRewardsV2(address _contract, uint16[] calldata _tokenIds, uint256 _currentTimestamp) external view returns(uint256);
    function claimRewardsV2(address _contract, uint16[] calldata _tokenIds, address _owner) external;
    function claimMoveRewardsOrigin(address _contract, uint16 _tokenId, address _ownerOrigin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesCalculationOrigin {
    function calculationRewards(address _contract, uint256[] calldata _tokenIds, uint256 _currentTimestamp) external view returns(uint256);
    function claimRewards(address _contract, uint256[] calldata _tokenIds, address _owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICryptoFoxesSteak.sol";
import "./CryptoFoxesAllowed.sol";

// @author: miinded.com

abstract contract CryptoFoxesUtility is Ownable,CryptoFoxesAllowed, ICryptoFoxesSteak {
    using SafeMath for uint256;

    uint256 public endRewards = 0;
    ICryptoFoxesSteak public cryptofoxesSteak;
    bool public disablePublicFunctions = false;

    function setCryptoFoxesSteak(address _contract) public onlyOwner {
        cryptofoxesSteak = ICryptoFoxesSteak(_contract);
        setAllowedContract(_contract, true);
        synchroEndRewards();
    }
    function _addRewards(address _to, uint256 _amount) internal {
        cryptofoxesSteak.addRewards(_to, _amount);
    }
    function addRewards(address _to, uint256 _amount) public override isFoxContract  {
        _addRewards(_to, _amount);
    }
    function withdrawRewards(address _to) public override isFoxContract {
        cryptofoxesSteak.withdrawRewards(_to);
    }
    function _withdrawRewards(address _to) internal {
        cryptofoxesSteak.withdrawRewards(_to);
    }
    function isPaused() public view override returns(bool){
        return cryptofoxesSteak.isPaused();
    }
    function synchroEndRewards() public {
        endRewards = cryptofoxesSteak.dateEndRewards();
    }
    function dateEndRewards() public view override returns(uint256){
        require(endRewards > 0, "End Rewards error");
        return endRewards;
    }
    function _currentTime(uint256 _currentTimestamp) public view virtual returns (uint256) {
        return min(_currentTimestamp, dateEndRewards());
    }
    function min(uint256 a, uint256 b) public pure returns (uint256){
        return a > b ? b : a;
    }
    function max(uint256 a, uint256 b) public pure returns (uint256){
        return a > b ? a : b;
    }
    function setDisablePublicFunctions(bool _toggle) public isFoxContractOrOwner{
        disablePublicFunctions = _toggle;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICryptoFoxesSteak.sol";

// @author: miinded.com

abstract contract CryptoFoxesAllowed is Ownable {

    mapping (address => bool) public allowedContracts;

    modifier isFoxContract() {
        require(allowedContracts[_msgSender()] == true, "Not allowed");
        _;
    }
    
    modifier isFoxContractOrOwner() {
        require(allowedContracts[_msgSender()] == true || _msgSender() == owner(), "Not allowed");
        _;
    }

    function setAllowedContract(address _contract, bool _allowed) public onlyOwner {
        allowedContracts[_contract] = _allowed;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}