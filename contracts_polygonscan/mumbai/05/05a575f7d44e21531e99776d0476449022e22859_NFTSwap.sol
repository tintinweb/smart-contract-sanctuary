/**
 *Submitted for verification at polygonscan.com on 2022-01-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract NFTSwap is IERC721Receiver {
    // Variables
    // NFTs that allowed to be exchanged by this contract
    mapping (address => bool) private _allowed_to_exchange;
    
    // contract allowed operators
    mapping (address => bool) private _privilleged_operators;
    // contract owner
    address public owner;
    
    // Interface to halt all auctions.
    bool public IsHalted;
    
    // Account Balance
    mapping (address => uint256) public balance;

    // NFTs ownership information
    mapping (address => mapping (uint256 => address)) private _ownership; 
    
    // NFTs auctions status
    mapping (address => mapping (uint256 => bool)) public onAuction;
    mapping (address => mapping (uint256 => uint256)) public current_auction_price;
    mapping (address => mapping (uint256 => address)) public current_bidder;
    mapping (address => mapping (uint256 => uint256)) public bid_end_time;
    
    // Events
    // Change Operators
    event OperatorCh(address operator, bool chType);
    // Ownership transfer
    event Owner(address newOwner);
    // Admin withdrawal
    event AdminWithDrawal(uint256 amount);
    // Pause and resume
    event Pause();
    event Resume();
    // New Bidding Event
    event NewBid(address NFTContract, uint256 NFTId, uint256 price, address bidder);
    // Auction Finish Event
    event AuctionMade(address NFTContract, uint256 NFTId, address bidder);
    // Force bid removal event
    event ForceRemoval(address Operator, address NFTContract, uint256 NFTId, address bidder);
    
    // Management interfaces:
    // constructor
    constructor() {
        owner = msg.sender;
        _privilleged_operators[msg.sender] = true;
    }
    
    // Add _privilleged_operators
    function addOperator(address operator) public {
        require(msg.sender == owner, "Only contract creator is allowed to do this.");
        _privilleged_operators[operator] = true;
        emit OperatorCh(operator, true);
    }
    
    // Remove someone from operators
    function removeOperator(address operator) public {
        require(msg.sender == owner, "Only contract creator is allowed to do this.");
        _privilleged_operators[operator] = false;
        emit OperatorCh(operator, false);
    }
    
    // Transfer contract ownership, please be extremly careful while using this
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Only contract creator is allowed to do this.");
        owner = newOwner;
        emit Owner(newOwner);
    }
    
    // Halt transactions
    function halt() public {
        require(_privilleged_operators[msg.sender] == true, "Operator only");
        IsHalted = true;
        emit Pause();
    }
    
    // Resume transactions
    function resume() public {
        require(_privilleged_operators[msg.sender] == true, "Operator only");
        IsHalted = false;
        emit Resume();
    }
    
    // Force cancel bid, to prevent DDoS by bidding from contract.
    function force_remove_bid(address NFTContract, uint256 NFTId) public {
        require(_privilleged_operators[msg.sender] == true, "Operator only");
        // Remove bid and disable the nft's auction.
        onAuction[NFTContract][NFTId] == false;
        bid_end_time[NFTContract][NFTId] == 2**256 - 1;
        balance[current_bidder[NFTContract][NFTId]] += current_auction_price[NFTContract][NFTId];
        emit ForceRemoval(msg.sender, NFTContract, NFTId, current_bidder[NFTContract][NFTId]);
    }

    // Allow to auction specified token
    function allow(address NFTContract) public {
        require(_privilleged_operators[msg.sender], "Denied");
        _allowed_to_exchange[NFTContract] = true;
    }

    function disallow(address NFTContract) public {
        require(_privilleged_operators[msg.sender], "Denied");
        _allowed_to_exchange[NFTContract] = false;
    }
    
    // Withdrawal methods
    function withDrawEther(uint256 amount) public {
        require(balance[msg.sender] >= amount, "Balance not sufficient.");
        balance[msg.sender] -= amount;
        address payable out = payable(msg.sender);
        out.transfer(amount);
    }

    function withDrawERC721(address NFTContract, uint256 NFTId) public payable {
        require(onAuction[NFTContract][NFTId] == false, "The nft is still on auction, pls claim it or wait for finish");
        require(_ownership[NFTContract][NFTId] == msg.sender, "You must be the token's owner");
        _ownership[NFTContract][NFTId] = address(0);
        ERC721(NFTContract).safeTransferFrom(address(this), msg.sender, NFTId);
        // Currently we do not support using approval mechinesm or paid transfer. This will be added later
    }

    function ownerWithdrawal(uint256 amount) public {
        require(msg.sender == owner);
        payable(msg.sender).transfer(amount);
        emit AdminWithDrawal(amount);
    }

    // Auction Ops

    function startAuction(address NFTContract, uint256 NFTId, uint256 lowest_price) public {
        require(msg.sender == _ownership[NFTContract][NFTId], "Permission denied");
        // 1. Set lowest bid
        current_auction_price[NFTContract][NFTId] = lowest_price;
        current_bidder[NFTContract][NFTId] = msg.sender;
        // 2. Enable Auction
        onAuction[NFTContract][NFTId] = true;
        // 3. Set timestamp
        bid_end_time[NFTContract][NFTId] = block.number + 5760;
    }

    function bid(address NFTContract, uint256 NFTId) public payable {
        require(msg.value > current_auction_price[NFTContract][NFTId], "Must bid higher");
        require(onAuction[NFTContract][NFTId], "Not for Auction");
        // 0. Refund previous guy
        balance[current_bidder[NFTContract][NFTId]] += current_auction_price[NFTContract][NFTId];
        // 1. Change price
        current_auction_price[NFTContract][NFTId] = msg.value;
        // 2. Change bidder
        current_bidder[NFTContract][NFTId] = msg.sender;
        // 3. Set timestamp
        bid_end_time[NFTContract][NFTId] = block.number + 5760;
    }

    function claimAuction(address NFTContract, uint256 NFTId) public {
        require(block.number > bid_end_time[NFTContract][NFTId], "Auction still active.");
        require(msg.sender == _ownership[NFTContract][NFTId] 
        || msg.sender == current_bidder[NFTContract][NFTId],
         "You are not allowed to do this.");
        // 1. Disable the auction
        onAuction[NFTContract][NFTId] = false;
        // 2. Transfer the value
        balance[_ownership[NFTContract][NFTId]] += current_auction_price[NFTContract][NFTId];
        // 3. Transfer the ownership
        _ownership[NFTContract][NFTId] = current_bidder[NFTContract][NFTId];
        emit AuctionMade(NFTContract, NFTId, current_bidder[NFTContract][NFTId]);
    }
    
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        // Check if the contract is approved for receiving
        require(_allowed_to_exchange[msg.sender], "Token not approved for auction");
        // Set token ownership
        _ownership[msg.sender][tokenId] = from;
        return bytes4(this.onERC721Received.selector);
    }
}