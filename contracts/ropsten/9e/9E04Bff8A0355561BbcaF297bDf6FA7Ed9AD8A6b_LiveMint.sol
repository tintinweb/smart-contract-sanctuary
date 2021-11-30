// SPDX-License-Identifier: MIT
// Developer: @Brougkr
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './IArtBlocks.sol';

contract LiveMint is Ownable, Pausable
{   
    address public _ERC721_GoldenTokenAddress = 0x48BaF803830ab470C1EA812f82B03107DB0C9786;     //Golden Token Address               { 0xd43529990F3FbA41Affd66C4A8Ab6C1b7292D9Dc }                                                  
    address public _ERC20_BRT_TokenAddress = 0xadd07987aC1A529EE5C97eFbe847628831a01e90;        //Bright Moments BRT Minting Address {  }                                               
    address public _BrightMomentsMultisig = 0xB96E81f80b3AEEf65CB6d0E280b15FD5DBE71937;         //Bright Moments Multisig Address    { 0xB96E81f80b3AEEf65CB6d0E280b15FD5DBE71937 }                                         
    address public _ArtBlocksTokenAddress = 0x296FF13607C80b550dd136435983734c889Ccca4;         //ArtBlocks Address                  { 0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270 }
    address public _ArtBlocksDeployerAddress = address(0);                                      //Artblocks Deployer                 { address of ArtBlocks project contract creator }
    address private _ApproverAddress = address(0);                                              //Bright Moments Approver
    uint public _ArtBlocksProjectID = 0;                                                        //ArtBlocks Project ID
    address[] private _GoldenTokensSent;                                                        //Array of Addresses who Sent Golden Tokens to Multisig

    mapping(uint => address) public tokensSent;         //Mapping of tokenIDs to OG senders
    mapping(uint => bool) public whitelist;             //Token ID Whitelist
    mapping(uint => bool) public checkedIn;             //Checked In To Bright Moments
    mapping(uint => bytes32) private ticketHashMap;     //Ticket Hashes

    //Phase 0 - VALIDATE
    function _validateApproval() public
    {
        require(msg.sender == tx.origin, "No External Contracts");

        //Approves Golden Token For Sending to Multisig
        IERC721(_ERC721_GoldenTokenAddress).setApprovalForAll(address(this), true);

        //Approves BRT For Purchasing on ArtBlocks
        IERC20(_ERC20_BRT_TokenAddress).approve(_ArtBlocksTokenAddress, 10000000000000000000);
    }

    //Phase 1 - CHECK-IN
    function _checkIn(uint ticketTokenId) public
    {
        require(msg.sender == tx.origin, "No External Contracts");
        require(validRecipient(msg.sender, ticketTokenId), "User Does Not Own Ticket");
        require(whitelist[ticketTokenId] == true, "Golden Ticket Not Whitelisted");
        IERC721(_ERC721_GoldenTokenAddress).safeTransferFrom(msg.sender, _BrightMomentsMultisig, ticketTokenId);
        tokensSent[ticketTokenId] = msg.sender;
        _GoldenTokensSent.push(msg.sender);
        checkedIn[ticketTokenId] = true;
    }

    //Phase 2 - IRL MINT
    function _irlMint(uint ticketTokenId, bytes32 hashPassword) public
    {
        require(msg.sender == tx.origin, "No External Contracts");
        require(ticketHashMap[ticketTokenId] == hashPassword, "Hash Password Provided Is Incorrect");
        require(checkedIn[ticketTokenId] == true, "User Not Checked In");
        require(whitelist[ticketTokenId] == true, "Golden Ticket Not Whitelisted");
        IArtblocks(_ArtBlocksTokenAddress).mint(msg.sender, _ArtBlocksProjectID, _ArtBlocksDeployerAddress);
        whitelist[ticketTokenId] = false; 
    }

    //All-in-one function to perform validation, check-in, and mint
    function _wrapped(uint ticketTokenId, bytes32 hashPassword) public onlyOwner
    {
        _validateApproval();
        _checkIn(ticketTokenId);
        _irlMint(ticketTokenId, hashPassword);
    }
    
    //Sets Hash Passwords
    function change_HashPasswords(uint[] calldata tokenIDs, bytes[] memory hashPasswords) public onlyOwner
    {
        for(uint i = 0; i < tokenIDs.length; i++) 
        { 
            ticketHashMap[tokenIDs[i]] = keccak256(hashPasswords[i]);
        }
    }

    function viewGoldenTicketsSenderWallets() public view onlyOwner returns(address[] memory) { return _GoldenTokensSent; }

    function whitelistTokenID(uint tokenID) public onlyOwner { whitelist[tokenID] = true; }

    function blacklistTokenID(uint tokenID) public onlyOwner { whitelist[tokenID] = false; }

    function viewTicketHashMap(uint tokenID) public onlyOwner view returns(bytes32) { return(ticketHashMap[tokenID]); }

    function validRecipient(address to, uint ticketTokenId) public view returns (bool) { return(IERC721(_ERC721_GoldenTokenAddress).ownerOf(ticketTokenId) == to); }

    function isApprovedGT(address to) public view returns (bool) { return IERC721(_ERC721_GoldenTokenAddress).isApprovedForAll(to, address(this)); }

    function approveBRT(address to) public returns (bool) { return IERC20(_ERC20_BRT_TokenAddress).approve(to, 10000000000000000000); }

    function change_ApproverAddress(address approver) public onlyOwner { _ApproverAddress = approver; }

    function change_HashPassword(uint tokenID, bytes32 hashPassword) public onlyOwner { ticketHashMap[tokenID] = hashPassword; }

    function change_MultisigAddress(address BrightMomentsMultisig) public onlyOwner { _BrightMomentsMultisig = BrightMomentsMultisig; }

    function change_ERC721Address(address ERC721_GoldenTokenAddress) public onlyOwner { _ERC721_GoldenTokenAddress = ERC721_GoldenTokenAddress; }

    function change_ERC20Address(address ERC20_BRT_TokenAddress) public onlyOwner { _ERC20_BRT_TokenAddress = ERC20_BRT_TokenAddress; }

    function change_ArtBlocksProjectID(uint ArtBlocksProjectID) public onlyOwner { _ArtBlocksProjectID = ArtBlocksProjectID; }

    function change_ArtBlocksDeployerAddress(address ArtBlocksDeployerAddress) public onlyOwner { _ArtBlocksDeployerAddress = ArtBlocksDeployerAddress; }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//Contract Address for ArtBlocks: { 0xa7d8d9ef8D8Ce8992Df33D8b8CF4Aebabd5bD270 }
interface IArtblocks 
{    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function mint(address _to, uint256 _projectId, address _by) external returns (uint256 _tokenId);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function setApprovalForAll(address operator, bool _approved) external;
    function approve(address to, uint256 tokenId) external;
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