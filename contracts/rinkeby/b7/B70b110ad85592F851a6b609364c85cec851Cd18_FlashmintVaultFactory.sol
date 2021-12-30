/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/FlashmintVaultFactory.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0 >=0.8.6 <0.9.0;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/proxy/Clones.sol

/* pragma solidity ^0.8.0; */

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

////// lib/openzeppelin-contracts/contracts/security/Pausable.sol

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol

/* pragma solidity ^0.8.0; */

/* import "../../utils/introspection/IERC165.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol

/* pragma solidity ^0.8.0; */

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

////// src/Flashmint.sol
/* pragma solidity ^0.8.6; */

/* import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; */
/* import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; */
/* import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; */

contract Flashmint is IERC721Receiver, ReentrancyGuard {

    /// -------------------------
    /// === TOKEN INFORMATION ===
    /// -------------------------

    /// @notice the ERC721 token address of this vault's token
    address public token;
    
    /// @notice the erc721 token ID of this vault's token
    uint256 public id;
    
    /// -------------------------
    /// === VAULT INFORMATION ===
    /// -------------------------

    /// @notice the user who initially deposited the NFT
    address public depositor;

    /// @notice the price a lender must pay to loan the NFT. in ether, ie 18 decimals (10**18 = 1)
    uint256 public fee;

    enum State { NOT_ACTIVE, ACTIVE, FINISHED } 
    State public vaultState;
    
    /// -------------------------
    /// === MINT INFORMATION ===
    /// -------------------------

    enum FlightStatus {
        READY,
        INFLIGHT,
        LANDED
    }
    struct MintRequest {
        FlightStatus flightStatus;
        address expectedNFTContractAddress;
        uint256 newid; // @notice this is only defined if flightStatus != READY
    }
    /// @notice state variable is needed to track a mint request because 
    /// we're reliant on the ERC721Receiver callback to get id
    MintRequest private req;

    /// -------------------------
    /// ======== EVENTS ========
    /// -------------------------

    /// @notice Emitted when `minter` borrows this NFT to mint `minted`
    event Flashminted(address indexed minter, address indexed minted, uint256 tokenId, uint256 fee);
    
    /// @notice Emitted when initial depositor reclaims their NFT and ends this contract.
    event Closed(address depositor);

    /// @notice Emitted when the claimer cashes out their fees
    event Cash(address depositor, uint256 amount);

    /// @notice Emitted when the cost is updated
    event FeeUpdated(uint256 amount);

    constructor () {
        vaultState = State.NOT_ACTIVE;
    }

    /// ---------------------------
    /// === LIFECYCLE FUNCTIONS ===
    /// ---------------------------

    function initializeWithNFT(address _token, uint256 _id, address _depositor, uint256 _fee) external {
        require(vaultState == State.NOT_ACTIVE, "already active");
        token = _token;
        id = _id;
        vaultState = State.ACTIVE;
        depositor = _depositor;
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    /// @notice allow the depositor to reclaim their NFT, ending this flashmint
    function withdrawNFT() external nonReentrant {
        require(msg.sender == depositor, "Not authorized");
        vaultState = State.FINISHED;

        IERC721(token).safeTransferFrom(address(this), msg.sender, id);

        emit Closed(msg.sender);
    }

    /// @notice allow anyone to forward payments to the depositor
    function withdrawEth() external nonReentrant {
        require(vaultState != State.NOT_ACTIVE);
        uint256 amount = address(this).balance;
        (bool sent, ) = payable(depositor).call{value: amount}("");
        require(sent, "send call failed");

        emit Cash(depositor, amount);
    }

    /// @notice allow the depositor to update their fee
    function updateFee(uint256 _fee) external nonReentrant {
        require(msg.sender == depositor, "not depositor");
        
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    /// ---------------------------
    /// === FLASHMINT FUNCTIONS ===
    /// ---------------------------

    /// @notice mint a derivative NFT and send it to the caller
    /// @notice derivative must use `_safeMint` because need onERC721Received callback
    /// @param _derivativeNFT the NFT user would like to mint
    /// @param _mintData data for the mint function ie abi.encodeWithSignature(...)
    function lendToMint (
        address _derivativeNFT, 
        bytes calldata _mintData
    ) external payable nonReentrant {
        require(vaultState == State.ACTIVE, "vault not active");
        require(msg.value >= fee, "didn't send enough eth");

        require(_derivativeNFT != address(this), "must call another contract");
        require(_derivativeNFT != token, "must call another contract");
        require(_derivativeNFT != depositor, "must call another contract");

        // request data is updated by nested functions, ie onERC721Received
        req = MintRequest({
            flightStatus: FlightStatus.INFLIGHT,
            expectedNFTContractAddress: _derivativeNFT,
            newid: 0
        });

        // mint the derivative and make sure we got it
        (bool success, ) = _derivativeNFT.call{value: msg.value - fee}(_mintData);
        require(success, "call to mint from derivative failed");
        require(req.flightStatus == FlightStatus.LANDED, "Haven't gotten onERC721 callback. Contract might not use safeTransfer");

        // Note: also asserts token _exists() and that we own it.
        IERC721(_derivativeNFT).safeTransferFrom(address(this), msg.sender, req.newid);

        // reset state variable for next calls.
        req = MintRequest({
            flightStatus: FlightStatus.READY,
            expectedNFTContractAddress: address(0),
            newid: 0
        });
        require(IERC721(token).ownerOf(id) == address(this), "attempted steal");
    }

    function onERC721Received(
        address, 
        address, 
        uint256 _id, 
        bytes calldata
    ) external virtual override returns (bytes4) {
        if (req.flightStatus == FlightStatus.INFLIGHT
            && msg.sender == req.expectedNFTContractAddress
        ){
            // we're receiving the expected derivative
            req.flightStatus = FlightStatus.LANDED;
            req.newid   = _id;
        }

        // Note: can still receive other NFTs
        return this.onERC721Received.selector;
    }

    receive() external payable{}
}

////// src/FlashmintVaultFactory.sol
/* pragma solidity ^0.8.6; */

/* import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; */
/* import "@openzeppelin/contracts/access/Ownable.sol"; */
/* import "@openzeppelin/contracts/security/Pausable.sol"; */
/* import "@openzeppelin/contracts/proxy/Clones.sol"; */
/* import "./Flashmint.sol"; */

contract FlashmintVaultFactory is Ownable, Pausable {
    uint256 public vaultCount;
    mapping (uint256 => address) public vaults;
    address public logic;

    constructor() {
        logic = address(new Flashmint());
    }

    // todo replace msg.sender with something more sophisticated?
    function makeFlashmint(address token, uint256 id) external whenNotPaused returns (uint256) {
        //Flashmint flashmint = new Flashmint();
        Flashmint flashmint = Flashmint(payable(Clones.clone(logic)));
        flashmint.initializeWithNFT(token, id, msg.sender, 0);
        
        IERC721(token).safeTransferFrom(msg.sender, address(flashmint), id);

        vaults[vaultCount++] = address(flashmint);
        return vaultCount - 1;
    }

    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }
}