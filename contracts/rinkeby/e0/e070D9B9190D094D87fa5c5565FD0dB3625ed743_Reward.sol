// contracts/Reward.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Reward is Ownable {
    using SafeMath for uint256;

    // Mapping from token ID to accumulated ETH balance
    mapping(uint256 => uint256) private _tBalance;
    // The accumulated ETH balance reserved to the contract owner
    uint256 private                     _oBalance;

    // the associated IERC721 contract
    IERC721Enumerable private _nft;
    // total supply of the ERC721 contract
    uint256 private _totalSupply;
    // token starting index (i.e., generally or 0 or 1)
    uint256 private _startIndex;
    // the integer ratio donated to the token hodlers in the range of [0, 100]
    uint256 private _ratio;

    bool private _enableClaimAll;
    bool private _enableClaimToken;
    bool private _enableClaimOwner;

    // Event signaling a deposit to this contract has been made
    event DepositReceived(address wallet, uint256 amout);
    // Event signaling a token claim has been made
    event ClaimedToken(address wallet, uint256 tokenId, uint256 amout);
    // Event signaling a full claim has been made
    event ClaimedAll(address wallet, uint256 amout);
    // Event signaling a owner claim has been made
    event ClaimedOwner(uint256 amout);

    /**
     * @dev fallback function where reward is distributed
     */
    fallback() external payable {
        require(msg.data.length == 0);

        //FIXME use OZ math library here
        uint256 tValue = ((msg.value * _ratio)  / 100) / _totalSupply;
        uint256 oValue = msg.value - (_totalSupply * tValue);

        _oBalance += oValue;

        for (uint i = 0; i < _totalSupply; i++) {
            _tBalance[i + _startIndex] += tValue;
        }

        emit DepositReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Constructor
     * The parameters are:
     * nftAddress - address of the ERC721 contract
     * totalSupply - total supply of the ERC721 contract
     * startIndex - the token starting index (i.e., generally or 0 or 1)
     * ratio - the integer ratio donated to the token hodlers in the range of [0, 100]
     */
    constructor (
        address nftAddress,
        uint256 totalSupply,
        uint256 startIndex,
        uint256 ratio
    ) {
        require(nftAddress != address(0), "nftAddress not valid");
        require(ratio < 100, "ratio not valid");

        _nft = IERC721Enumerable(nftAddress);
        _totalSupply = totalSupply;
        _startIndex = startIndex;
        _ratio = ratio;
        _oBalance = 0;

        for (uint i = 0; i < _totalSupply; i++) {
            _tBalance[i + startIndex] = 0;
        }

        _enableClaimAll   = true;
        _enableClaimToken = true;
        _enableClaimOwner = true;
    }

    /**
     * @dev Claim the accumulated balance for the tokenId.
     * Returns true in case of success, false in case of failure
     */
    function claimToken(uint256 tokenId) public returns (bool) {
        require(_enableClaimToken, "function temporarily disabled");
        require(_msgSender() == _nft.ownerOf(tokenId), "Caller is not the token owner");

        uint256 amount = _tBalance[tokenId];

        if (amount > 0) {

            _tBalance[tokenId] -= amount;

            (bool success, ) = _msgSender().call{value:amount}("");
            if (!success) {
                // no need to call throw here, just reset the amount owing
                // the sum is required since payout are coming async
                _tBalance[tokenId] += amount;

                return false;
            }
        }

        emit ClaimedToken(_msgSender(), tokenId, amount);

        return true;
    }

    /**
    * @dev Claim the accumulated balance for the tokenId.
    * Returns true in case of success, false in case of failure
    */
    function claimAll() public returns (bool) {
        require(_enableClaimAll, "function temporarily disabled");

        uint256 totalAmount = 0;
        uint256 numTokens   = _nft.balanceOf(_msgSender());

        if (numTokens > 0) {

            uint256[] memory tokens  = new uint256[](numTokens);
            uint256[] memory amounts = new uint256[](numTokens);

            for (uint256 i = 0; i < numTokens; i++) {
                uint256 id     = _nft.tokenOfOwnerByIndex(_msgSender(), i);
                uint256 amount = _tBalance[id];

                tokens[i]      = id;
                amounts[i]     = amount;
                _tBalance[id] -= amount;
                totalAmount   += amount;
            }

            if (totalAmount > 0) {
                (bool success, ) = _msgSender().call{value:totalAmount}("");
                if (!success) {
                    // no need to call throw here, just reset all the amount owing
                    // the sum is required since payout are coming async
                    for (uint i = 0; i < numTokens; i++) {
                        _tBalance[tokens[i]] += amounts[i];
                    }
                    return false;
                }
            }

            emit ClaimedAll(_msgSender(), totalAmount);
        }

        return true;
    }

    /**
     * @dev Claim the owner balance.
     * Returns true in case of success, false in case of failure
     */
    function claimOwner() public onlyOwner() returns (bool) {
        require(_enableClaimOwner, "function temporarily disabled");

        uint256 amount = _oBalance;

        if (amount > 0) {

            _oBalance -= _oBalance;

            (bool success, ) = _msgSender().call{value:amount}("");
            if (!success) {
                // no need to call throw here, just reset all the amount owing
                // the sum is required since payout are coming async
                _oBalance += amount;
                return false;
            }
        }

        emit ClaimedOwner(amount);

        return true;
    }

    /**
     * @dev Returns the ratio value
     */
    function getRatio() public view returns (uint256) {
        return _ratio;
    }

    /**
     * @dev Set a new ratio value in the range of [0, 100]
     */
    function setRatio(uint256 ratio) public onlyOwner() {
        require(ratio > 100, "ratio not valid");
        _ratio = ratio;
    }


    /**
    * @dev Returns the caller accumulated balance on its NFT tokens
    */
    function balance() public view returns (uint256) {
        uint256 totalAmount = 0;
        uint256 numTokens   = _nft.balanceOf(_msgSender());

        for (uint256 i = 0; i < numTokens; i++) {
            totalAmount += _tBalance[_nft.tokenOfOwnerByIndex(_msgSender(), i)];
        }

        return totalAmount;
    }

    /**
     * @dev Returns the accumulated balance for the tokenId
     */
    function balanceOf(uint256 tokenId) public view returns (uint256) {
        return _tBalance[tokenId];
    }

    /**
    * @dev Returns the owner balance
    */
    function ownerBalance() public onlyOwner() view returns (uint256) {
        return _oBalance;
    }

    /**
    * @dev Enable or disable the claimAll() function
    */
    function setEnableClaimAll(bool flag) public onlyOwner() {
        _enableClaimAll = flag;
    }

    /**
    * @dev Enable or disable the claimToken() function
    */
    function setEnableClaimToken(bool flag) public onlyOwner() {
        _enableClaimToken = flag;
    }

    /**
    * @dev Enable or disable the claimOwner() function
    */
    function setEnableClaimOwner(bool flag) public onlyOwner() {
        _enableClaimOwner = flag;
    }

    /**
    * @dev Enable or disable the claim[*]() functions
    */
    function setEnableClaimFunctions(bool flag) public onlyOwner() {
        _enableClaimAll   = flag;
        _enableClaimToken = flag;
        _enableClaimOwner = flag;
    }

    /**
    * @dev Returns the activation status of claimAll(), claimToken() and claimOwner() functions, respectively
    */
    function getClaimStatus() public view returns (bool claimAllFlag, bool claimTokenFlag, bool claimOwnerFlag) {
        return (_enableClaimAll, _enableClaimToken, _enableClaimOwner);
    }



}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}