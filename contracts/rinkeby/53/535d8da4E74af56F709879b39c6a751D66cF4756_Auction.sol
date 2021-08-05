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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract Auction {

    address public admin;

    uint public auctionId;

    uint public fee;

    address public feeAddress;

    bool locked;

    mapping(uint => tokens) public auctions;

    mapping(address => uint) public withdrawableBalance;

    mapping(address => accounts) public whiteListedAccounts;

    event newAccount(
        address account
    );

    event newAuction(
        address indexed tokenAddress,
        address indexed tokenOwner,
        uint indexed tokenId,
        uint auctionId,
        uint startTime,
        uint endTime
    );

    event deletedAccount(
        address account,
        uint[] deletedAuctions
    );

    event newBid(
        address indexed token,
        address indexed bidder,
        uint indexed tokenId,
        uint bid
    );
    
    event sold(
        address indexed token,
        address indexed buyer,
        uint highestBid,
        uint indexed tokenId
    );

    struct tokens {
        address tokenAddress;
        address tokenOwner;
        address highestBidder;
        uint tokenId;
        uint highestBid;
        uint startTime;
        uint endTime;
    }

    struct accounts {
        uint[] enableAuctions;
        uint totalSaledAuctions;
        uint totalEarn;
        bool whiteListed;
    }

    constructor(uint _fee){
        admin =msg.sender;
        feeAddress = msg.sender;
        fee = _fee;
    }

    function whitelistAccount(address accountAddress) external onlyAdmin {

        whiteListedAccounts[accountAddress].whiteListed = true;

        emit newAccount(accountAddress);
    }

    function deletewhitelistedAccount(address accountAddress) external onlyAdmin {

        deleteAuction(whiteListedAccounts[accountAddress].enableAuctions,true);

        emit deletedAccount(accountAddress, whiteListedAccounts[accountAddress].enableAuctions);

        delete whiteListedAccounts[accountAddress];
    }

    function addNewAuction(
        address tokenAddress,
        uint tokenId,
        uint startTime,
        uint duration
    ) external onlyWhitelisted {
        IERC721Metadata(tokenAddress).transferFrom(msg.sender, address(this), tokenId);

        auctions[auctionId] = tokens({
            tokenAddress:tokenAddress,
            tokenOwner:msg.sender,
            highestBidder:address(0),
            tokenId: tokenId,
            highestBid:0,
            startTime:startTime,
            endTime:startTime+duration
        });

        whiteListedAccounts[msg.sender].enableAuctions.push(auctionId);

        emit newAuction(
            tokenAddress,
            msg.sender,
            tokenId,
            auctionId,
            startTime,
            startTime+duration);
            
        auctionId++;
    }

    function bid(uint _auctionId,
    uint _addFromWithdrawbleBalance) external payable {       

        require(
            auctions[_auctionId].endTime >= block.timestamp &&
            auctions[_auctionId].startTime <= block.timestamp,
            "auction is not active"
            );

        require(_addFromWithdrawbleBalance <= withdrawableBalance[msg.sender],
            "more than withdrawable balance"
        );

        require(msg.value +_addFromWithdrawbleBalance > auctions[_auctionId].highestBid,
            "should be more than highest bid"
            );         
        
        withdrawableBalance[auctions[_auctionId].highestBidder] = auctions[_auctionId].highestBid; 

        auctions[_auctionId].highestBidder = msg.sender;

        auctions[_auctionId].highestBid = msg.value;

        emit newBid(
        auctions[_auctionId].tokenAddress,
        msg.sender,
        auctions[_auctionId].tokenId,
        msg.value
        );
        
    }

    function endAuction(uint _auctionId) external {

        tokens memory token = auctions[_auctionId];

            require(msg.sender == token.highestBidder ||
                    msg.sender == token.tokenOwner,
                  "only highestBidder or tokenOwner");

            require(block.timestamp >token.endTime,
            "auction is not finished");

            uint[] memory auction = new uint[](1);

            auction[0] = _auctionId;

            if(token.highestBid > 0){

            deleteAuction(auction,false);

        } else {

            deleteAuction(auction,true);
           }
    }



    function deleteAuction(uint[] memory _auctionIds,bool _deletedAccount) private {
        for(uint i = 0;i < _auctionIds.length;i++){

            tokens memory token = auctions[_auctionIds[i]];

            if(!_deletedAccount){

                IERC721Metadata(token.tokenAddress).approve(token.highestBidder,token.tokenId);

                uint feePrice = (token.highestBid / 10000) * fee;

                withdrawableBalance[token.tokenOwner] += token.highestBid - feePrice;

                withdrawableBalance[feeAddress] += feePrice;

                uint count = 0;
                accounts storage account = whiteListedAccounts[token.tokenOwner];

                uint auctionsLength = account.enableAuctions.length;

                while(count < auctionsLength){

                  if(account.enableAuctions[count] == _auctionIds[i]){

                    account.enableAuctions[count] = account.enableAuctions[auctionsLength - 1];

                    account.enableAuctions.pop();

                      break;
                  }
                  count++;
                }

                emit sold(
                token.tokenAddress,
                token.highestBidder,
                token.highestBid,
                token.tokenId

            );
            }
            else {
                IERC721Metadata(token.tokenAddress).approve(token.tokenOwner,token.tokenId);
            }            

            delete auctions[_auctionIds[i]];
        }
    }

    function withdraw(uint amount) external lock {
        require( amount <= withdrawableBalance[msg.sender],
                "more than current balance");

        withdrawableBalance[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value:amount}("");

        require(success,"transfer failed");
    }
    
    function changeAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }

    function changeFee(uint newFee) external onlyAdmin {
        require(newFee <= 500,"high fee rate");

        fee = newFee;
    }

    function URI(uint _auctionId) external view returns(string memory) {
        tokens memory token = auctions[_auctionId];

        return IERC721Metadata(token.tokenAddress).tokenURI(token.tokenId);
    }
    modifier lock(){
        require(!locked,"reentry");
        locked = true;
        _;
        locked = false;
    }
    modifier onlyWhitelisted() {
        require(whiteListedAccounts[msg.sender].whiteListed,
            "only whitelisted accounts");
        _;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin,"only Admin");
        _;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
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