pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ExchangeFromEthereum is IERC721Receiver, ReentrancyGuard {
    //NftTokenInfo[] allNFT;
    address payable private backend;
    uint256 private gasUnlock;

    constructor(address payable _back) public {
        require(_back != address(0), "Wrong address");
        backend = _back;
        gasUnlock = 44800;
    }

    modifier onlyBackend {
        require(msg.sender == backend, "Only backend can call this function.");
        _;
    }

    struct NftTokenInfo {
        address tokenAddress;
        uint256 id;
        bool sent;
        bool locked;
    }

    /*mapping(address => NftTokenInfo[]) public deposits;
    mapping(address => NftTokenInfo[]) public activeDeposits;*/
    mapping(address => NftTokenInfo[]) public deposits;

    event DepositNFT(address owner, address nftAddress, uint256 nftId);
    event WithdrawNFT(address nftAddress, uint256 nftId, address to);
    event Log(uint256 fee);

    function depositNft(address nftAddress, uint256 nftId) external payable nonReentrant{
        //uint256 gasBeg = gasleft();
        uint256 gasPrice = tx.gasprice;
        uint256 fee = gasUnlock * gasPrice;
        require(nftAddress != address(0), "Wrong NFT contract address");
        require(msg.value >= fee);
        NftTokenInfo memory token = NftTokenInfo(nftAddress, nftId, false, true);
        IERC721(nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            nftId
        );
        backend.transfer(msg.value);
        deposits[msg.sender].push(token);
        //deposits[msg.sender].push(nft);
        //activeDeposits[msg.sender].push(nft);
        emit DepositNFT(msg.sender, nftAddress, nftId);
        emit Log(fee);
        //uint256 gasEnd = gasleft();
        //uint256 gas = gasBeg - gasEnd;
        //require(msg.value >= 2 * gas * tx.gasprice);
    }

    function withdrawNft(address nftAddress, uint256 nftId, address to) external nonReentrant {
        require(nftAddress != address(0));
        uint256 index = deposits[msg.sender].length;
        for(uint256 i=0; i<deposits[msg.sender].length; i++){
            if(deposits[msg.sender][i].tokenAddress == nftAddress && deposits[msg.sender][i].id == nftId){
                index = i;
            }
        }
        require(index != deposits[msg.sender].length, "Wrong initial values");
        /*require(
            index >= 0 && index < deposits[msg.sender].length,
            "Wrong index"
        );*/
        //address nftAddress = deposits[msg.sender][index].tokenAddress;
        //uint256 nftId = deposits[msg.sender][index].id;
        //require(nftAddress != address(0));
        require(!deposits[msg.sender][index].locked, "Unable to withdraw. Deposit all BEP20 tokens on the contract in Binance Smaert Chain");
        require(!deposits[msg.sender][index].sent, "Deposit has already withdrawn");
        IERC721(nftAddress).safeTransferFrom(
            address(this),
            to,
            nftId
        );
        deposits[msg.sender][index].sent = true;
        /*uint256 actLeng = activeDeposits[msg.sender].length;
        if (index < actLeng  - 1)
            activeDeposits[msg.sender][index] = activeDeposits[msg.sender][actLeng - 1];
        activeDeposits[msg.sender].pop();*/
        emit WithdrawNFT(nftAddress, nftId, msg.sender);
    }

    function unlock (address owner, address nftAddress, uint256 nftId) external onlyBackend {
        require(nftAddress != address(0));
        uint256 index = deposits[owner].length;
        for(uint256 i=0; i<deposits[owner].length; i++){
            if(deposits[owner][i].tokenAddress == nftAddress && deposits[owner][i].id == nftId){
                index = i;
            }
        }
        require(index != deposits[owner].length, "Wrong initial values");
        deposits[owner][index].locked = false;
    }

    function changeBackAddress(address payable _back) external onlyBackend {
        require(_back != address(0));
        backend = _back;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    )
    external 
    override 
    returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable { }
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}