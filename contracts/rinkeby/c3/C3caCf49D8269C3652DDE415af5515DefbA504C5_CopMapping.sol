// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./../Interfaces/Cop/IUUNNRegistry.sol";
import "./../Interfaces/Cop/IOCProtectionStorage.sol";
import "./../Interfaces/Cop/IPool.sol";
import "./../Interfaces/CopMappingInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CopMapping is Ownable, CopMappingInterface{
   
    address private _copRegistryAddress;

    constructor(address copRegistryAddress) public{
        _copRegistryAddress = copRegistryAddress;
    }

    function _setCopRegistry(address copRegistryAddress) public onlyOwner {
        _copRegistryAddress = copRegistryAddress;
    }

    function copRegistry() public view returns (IUUNNRegistry){
        return IUUNNRegistry(_copRegistryAddress);
    }

    function getTokenAddress() override public view returns (address){
        return _copRegistryAddress;
    }

    function getProtectionData(uint256 underlyingTokenId) override public view returns (address, uint256, uint256, uint256, uint, uint){
        return IOCProtections(copRegistry().protectionContract(underlyingTokenId)).getProtectionData(underlyingTokenId);
    }

    function getUnderlyingAsset(uint256 underlyingTokenId) override public view returns (address){
        (address pool, , , , , ) = getProtectionData(underlyingTokenId);
        return IAssetPool(pool).getAssetToken();
    }

    function getUnderlyingAmount(uint256 underlyingTokenId) override public view returns (uint256){
        ( , uint256 amount, , , , ) = getProtectionData(underlyingTokenId);
        return amount;
    }

    function getUnderlyingStrikePrice(uint256 underlyingTokenId) override public view returns (uint){
        ( , , uint256 strike, , , ) = getProtectionData(underlyingTokenId);
        return strike * 1e10; 
    }

    function getUnderlyingDeadline(uint256 underlyingTokenId) override public view returns (uint){
        ( , , , , , uint deadline) = getProtectionData(underlyingTokenId);
        return deadline;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721EnumerableUpgradeable.sol";

interface IUUNNRegistry is IERC721EnumerableUpgradeable{
    function mint(uint256 tokenId, address protectionContract, address to) external;
    function burn(uint256 tokenId) external;
    function protectionContract(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

interface IOCProtectionStorage{
    function getProtectionData(uint256 id) external view returns (address, uint256, uint256, uint256, uint, uint);
    function withdrawPremium(uint256 _id, uint256 _premium) external;
}

interface IOCProtections{
    function getProtectionData(uint256 id) external view returns (address, uint256, uint256, uint256, uint, uint);
    function withdrawPremium(uint256 _id, uint256 _premium) external;
    function create(address pool, uint256 validTo, uint256 amount, uint256 strike, uint256 deadline, uint256[11] memory data, bytes memory signature) external returns (address);
    function createTo(address pool, uint256 validTo, uint256 amount, uint256 strike, uint256 deadline, uint256[11] memory data, bytes memory signature, address erc721Receiver) external returns (address);
    function exercise(uint256 _id, uint256 _amount) external;
    function version() external view returns (uint32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

interface IPool{
    function unlockPremium(uint256[] calldata _ids) external;
    function getBasimToken() external view returns (address);
    function getBasimTokenDecimals() external view returns (uint256);
    function getPoolStat() external view returns (uint256, uint256, uint256,uint256, uint256, uint64, uint256);
    function version() external view returns (uint32);
}

interface IAssetPool is IPool{
    function onPayoutCoverage(uint256 _id, uint256 _premiumToUnlock, uint256 _coverageToPay, address _beneficiary) external returns (bool);
    function onProtectionPremium(address buyer,  uint256[7] memory data)  external; 
    function getLatestPrice() external view returns (uint256);
    function getPriceDecimals() external view returns (uint256);
    function getAssetToken() external view returns(address);
    function getAssetTokenDecimals() external view returns (uint256);
    function getWriterDataExtended(address _writer) external view returns (uint256, uint256, uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface CopMappingInterface {
    function getTokenAddress() external view returns (address);
    function getProtectionData(uint256 underlyingTokenId) external view returns (address, uint256, uint256, uint256, uint, uint);
    function getUnderlyingAsset(uint256 underlyingTokenId) external view returns (address);
    function getUnderlyingAmount(uint256 underlyingTokenId) external view returns (uint256);
    function getUnderlyingStrikePrice(uint256 underlyingTokenId) external view returns (uint);
    function getUnderlyingDeadline(uint256 underlyingTokenId) external view returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}