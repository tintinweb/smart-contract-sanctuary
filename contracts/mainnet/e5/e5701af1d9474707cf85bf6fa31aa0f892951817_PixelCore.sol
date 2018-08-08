// PixelCoins Source code
pragma solidity ^0.4.11;

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3054554455705148595f5d4a555e1e535f">[email&#160;protected]</a>> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


/// @title A facet of PixelCore that manages special access privileges.
/// @author Oliver Schneider <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c7aea9a1a887b7aebfa2aba4a8aea9b4e9aea8">[email&#160;protected]</a>> (https://pixelcoins.io)
contract PixelAuthority {

    /// @dev Emited when contract is upgraded
    event ContractUpgrade(address newContract);

    address public authorityAddress;
    uint public authorityBalance = 0;

    /// @dev Access modifier for authority-only functionality
    modifier onlyAuthority() {
        require(msg.sender == authorityAddress);
        _;
    }

    /// @dev Assigns a new address to act as the authority. Only available to the current authority.
    /// @param _newAuthority The address of the new authority
    function setAuthority(address _newAuthority) external onlyAuthority {
        require(_newAuthority != address(0));
        authorityAddress = _newAuthority;
    }

}


/// @title Base contract for PixelCoins. Holds all common structs, events and base variables.
/// @author Oliver Schneider <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="056c6b636a45756c7d6069666a6c6b762b6c6a">[email&#160;protected]</a>> (https://pixelcoins.io)
/// @dev See the PixelCore contract documentation to understand how the various contract facets are arranged.
contract PixelBase is PixelAuthority {
    /*** EVENTS ***/

    /// @dev Transfer event as defined in current draft of ERC721. Emitted every time a Pixel
    ///  ownership is assigned.
    event Transfer(address from, address to, uint256 tokenId);

    /*** CONSTANTS ***/
    uint32 public WIDTH = 1000;
    uint32 public HEIGHT = 1000;

    /*** STORAGE ***/
    /// @dev A mapping from pixel ids to the address that owns them. A pixel address of 0 means,
    /// that the pixel can still be bought.
    mapping (uint256 => address) public pixelIndexToOwner;
    /// Address that is approved to change ownship
    mapping (uint256 => address) public pixelIndexToApproved;
    /// Stores the color of an pixel, indexed by pixelid
    mapping (uint256 => uint32) public colors;
    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    // Internal utility functions: These functions all assume that their input arguments
    // are valid. We leave it to public methods to sanitize their inputs and follow
    // the required logic.

    /// @dev Assigns ownership of a specific Pixel to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Can no overflowe since the number of Pixels is capped.
        // transfer ownership
        ownershipTokenCount[_to]++;
        pixelIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete pixelIndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    /// @dev Checks if a given address is the current owner of a particular Pixel.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId Pixel id
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return pixelIndexToOwner[_tokenId] == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Pixel.
    /// @param _claimant the address we are confirming pixel is approved for.
    /// @param _tokenId pixel id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return pixelIndexToApproved[_tokenId] == _claimant;
    }
}


/// @title The facet of the PixelCoins core contract that manages ownership, ERC-721 (draft) compliant.
/// @author Oliver Schneider <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d7beb9b1b897a7beafb2bbb4b8beb9a4f9beb8">[email&#160;protected]</a>> (https://pixelcoins.io), based on Axiom Zen (https://www.axiomzen.co)
/// @dev Ref: https://github.com/ethereum/EIPs/issues/721
///  See the PixelCore contract documentation to understand how the various contract facets are arranged.
contract PixelOwnership is PixelBase, ERC721 {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "PixelCoins";
    string public constant symbol = "PXL";


    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256(&#39;name()&#39;)) ^
        bytes4(keccak256(&#39;symbol()&#39;)) ^
        bytes4(keccak256(&#39;totalSupply()&#39;)) ^
        bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
        bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
        bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;transfer(address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
        bytes4(keccak256(&#39;tokensOfOwner(address)&#39;)) ^
        bytes4(keccak256(&#39;tokenMetadata(uint256,string)&#39;));


    string public metaBaseUrl = "https://pixelcoins.io/meta/";


    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    /// @notice Returns the number ofd Pixels owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// @notice Transfers a Pixel to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  PixelCoins specifically) or your Pixel may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Pixel to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any pixel (except very briefly
        // after a gen0 cat is created and before it goes on auction).
        require(_to != address(this));

        // You can only send your own pixel.
        require(_owns(msg.sender, _tokenId));
        // address is not currently managed by the contract (it is in an auction)
        require(pixelIndexToApproved[_tokenId] != address(this));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific pixel via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the pixel that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));
        // address is not currently managed by the contract (it is in an auction)
        require(pixelIndexToApproved[_tokenId] != address(this));

        // Register the approval (replacing any previous approval).
        pixelIndexToApproved[_tokenId] = _to;

        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a Pixel owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the pixel to be transfered.
    /// @param _to The address that should take ownership of the Pixel. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the Pixel to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own anyd Pixels (except very briefly
        // after a gen0 cat is created and before it goes on auction).
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of pixels currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return WIDTH * HEIGHT;
    }

    /// @notice Returns the address currently assigned ownership of a given Pixel.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = pixelIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    /// @notice Returns the addresses currently assigned ownership of the given pixel area.
    function ownersOfArea(uint256 x, uint256 y, uint256 x2, uint256 y2) external view returns (address[] result) {
        require(x2 > x && y2 > y);
        require(x2 <= WIDTH && y2 <= HEIGHT);
        result = new address[]((y2 - y) * (x2 - x));

        uint256 r = 0;
        for (uint256 i = y; i < y2; i++) {
            uint256 tokenId = i * WIDTH;
            for (uint256 j = x; j < x2; j++) {
                result[r] = pixelIndexToOwner[tokenId + j];
                r++;
            }
        }
    }

    /// @notice Returns a list of all Pixel IDs assigned to an address.
    /// @param _owner The owner whosed Pixels we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
    ///  expensive (it walks the entire Pixel array looking for pixels belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalPixels = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all pixels have IDs starting at 0 and increasing
            // sequentially up to the totalCat count.
            uint256 pixelId;

            for (pixelId = 0; pixelId <= totalPixels; pixelId++) {
                if (pixelIndexToOwner[pixelId] == _owner) {
                    result[resultIndex] = pixelId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    // Taken from https://ethereum.stackexchange.com/a/10929
    function uintToString(uint v) constant returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    // Taken from https://ethereum.stackexchange.com/a/10929
    function appendUintToString(string inStr, uint v) constant returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    function setMetaBaseUrl(string _metaBaseUrl) external onlyAuthority {
        metaBaseUrl = _metaBaseUrl;
    }

    /// @notice Returns a URI pointing to a metadata package for this token conforming to
    ///  ERC-721 (https://github.com/ethereum/EIPs/issues/721)
    /// @param _tokenId The ID number of the Pixel whose metadata should be returned.
    function tokenMetadata(uint256 _tokenId) external view returns (string infoUrl) {
        return appendUintToString(metaBaseUrl, _tokenId);
    }
}

contract PixelPainting is PixelOwnership {

    event Paint(uint256 tokenId, uint32 color);

    // Sets the color of an individual pixel
    function setPixelColor(uint256 _tokenId, uint32 _color) external {
        // check that the token id is in the range
        require(_tokenId < HEIGHT * WIDTH);
        // check that the sender is owner of the pixel
        require(_owns(msg.sender, _tokenId));
        colors[_tokenId] = _color;
    }

    // Sets the color of the pixels in an area, left to right and then top to bottom
    function setPixelAreaColor(uint256 x, uint256 y, uint256 x2, uint256 y2, uint32[] _colors) external {
        require(x2 > x && y2 > y);
        require(x2 <= WIDTH && y2 <= HEIGHT);
        require(_colors.length == (y2 - y) * (x2 - x));
        uint256 r = 0;
        for (uint256 i = y; i < y2; i++) {
            uint256 tokenId = i * WIDTH;
            for (uint256 j = x; j < x2; j++) {
                if (_owns(msg.sender, tokenId + j)) {
                    uint32 color = _colors[r];
                    colors[tokenId + j] = color;
                    Paint(tokenId + j, color);
                }
                r++;
            }
        }
    }

    // Returns the color of a given pixel
    function getPixelColor(uint256 _tokenId) external view returns (uint32 color) {
        require(_tokenId < HEIGHT * WIDTH);
        color = colors[_tokenId];
    }

    // Returns the colors of the pixels in an area, left to right and then top to bottom
    function getPixelAreaColor(uint256 x, uint256 y, uint256 x2, uint256 y2) external view returns (uint32[] result) {
        require(x2 > x && y2 > y);
        require(x2 <= WIDTH && y2 <= HEIGHT);
        result = new uint32[]((y2 - y) * (x2 - x));
        uint256 r = 0;
        for (uint256 i = y; i < y2; i++) {
            uint256 tokenId = i * WIDTH;
            for (uint256 j = x; j < x2; j++) {
                result[r] = colors[tokenId + j];
                r++;
            }
        }
    }
}


/// @title all functions for buying empty pixels
contract PixelMinting is PixelPainting {

    uint public pixelPrice = 3030 szabo;

    // Set the price for a pixel
    function setNewPixelPrice(uint _pixelPrice) external onlyAuthority {
        pixelPrice = _pixelPrice;
    }
    
    // buy en empty pixel
    function buyEmptyPixel(uint256 _tokenId) external payable {
        require(msg.value == pixelPrice);
        require(_tokenId < HEIGHT * WIDTH);
        require(pixelIndexToOwner[_tokenId] == address(0));
        // increase authority balance
        authorityBalance += msg.value;
        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, msg.sender, _tokenId);
    }

    // buy an area of pixels, left to right, top to bottom
    function buyEmptyPixelArea(uint256 x, uint256 y, uint256 x2, uint256 y2) external payable {
        require(x2 > x && y2 > y);
        require(x2 <= WIDTH && y2 <= HEIGHT);
        require(msg.value == pixelPrice * (x2-x) * (y2-y));
        
        uint256 i;
        uint256 tokenId;
        uint256 j;
        // check that all pixels to buy are available
        for (i = y; i < y2; i++) {
            tokenId = i * WIDTH;
            for (j = x; j < x2; j++) {
                require(pixelIndexToOwner[tokenId + j] == address(0));
            }
        }

        authorityBalance += msg.value;

        // Do the actual transfer
        for (i = y; i < y2; i++) {
            tokenId = i * WIDTH;
            for (j = x; j < x2; j++) {
                _transfer(0, msg.sender, tokenId + j);
            }
        }
    }

}

/// @title all functions for managing pixel auctions
contract PixelAuction is PixelMinting {

    // Represents an auction on an NFT
    struct Auction {
         // Current state of the auction.
        address highestBidder;
        uint highestBid;
        uint256 endTime;
        bool live;
    }

    // Map from token ID to their corresponding auction.
    mapping (uint256 => Auction) tokenIdToAuction;
    // Allowed withdrawals of previous bids
    mapping (address => uint) pendingReturns;

    // Duration of an auction
    uint256 public duration = 60 * 60 * 24 * 4;
    // Auctions will be enabled later
    bool public auctionsEnabled = false;

    // Change the duration for new auctions
    function setDuration(uint _duration) external onlyAuthority {
        duration = _duration;
    }

    // Enable or disable auctions
    function setAuctionsEnabled(bool _auctionsEnabled) external onlyAuthority {
        auctionsEnabled = _auctionsEnabled;
    }

    // create a new auctions for a given pixel, only owner or authority can do this
    // The authority will only do this if pixels are misused or lost
    function createAuction(
        uint256 _tokenId
    )
        external payable
    {
        // only authority or owner can start auction
        require(auctionsEnabled);
        require(_owns(msg.sender, _tokenId) || msg.sender == authorityAddress);
        // No auction is currently running
        require(!tokenIdToAuction[_tokenId].live);

        uint startPrice = pixelPrice;
        if (msg.sender == authorityAddress) {
            startPrice = 0;
        }

        require(msg.value == startPrice);
        // this prevents transfers during the auction
        pixelIndexToApproved[_tokenId] = address(this);

        tokenIdToAuction[_tokenId] = Auction(
            msg.sender,
            startPrice,
            block.timestamp + duration,
            true
        );
        AuctionStarted(_tokenId);
    }

    // bid for an pixel auction
    function bid(uint256 _tokenId) external payable {
        // No arguments are necessary, all
        // information is already part of
        // the transaction. The keyword payable
        // is required for the function to
        // be able to receive Ether.
        Auction storage auction = tokenIdToAuction[_tokenId];

        // Revert the call if the bidding
        // period is over.
        require(auction.live);
        require(auction.endTime > block.timestamp);

        // If the bid is not higher, send the
        // money back.
        require(msg.value > auction.highestBid);

        if (auction.highestBidder != 0) {
            // Sending back the money by simply using
            // highestBidder.send(highestBid) is a security risk
            // because it could execute an untrusted contract.
            // It is always safer to let the recipients
            // withdraw their money themselves.
            pendingReturns[auction.highestBidder] += auction.highestBid;
        }
        
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        HighestBidIncreased(_tokenId, msg.sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // /// End the auction and send the highest bid
    // /// to the beneficiary.
    function endAuction(uint256 _tokenId) external {
        // It is a good guideline to structure functions that interact
        // with other contracts (i.e. they call functions or send Ether)
        // into three phases:
        // 1. checking conditions
        // 2. performing actions (potentially changing conditions)
        // 3. interacting with other contracts
        // If these phases are mixed up, the other contract could call
        // back into the current contract and modify the state or cause
        // effects (ether payout) to be performed multiple times.
        // If functions called internally include interaction with external
        // contracts, they also have to be considered interaction with
        // external contracts.

        Auction storage auction = tokenIdToAuction[_tokenId];

        // 1. Conditions
        require(auction.endTime < block.timestamp);
        require(auction.live); // this function has already been called

        // 2. Effects
        auction.live = false;
        AuctionEnded(_tokenId, auction.highestBidder, auction.highestBid);

        // 3. Interaction
        address owner = pixelIndexToOwner[_tokenId];
        // transfer money without 
        uint amount = auction.highestBid * 9 / 10;
        pendingReturns[owner] += amount;
        authorityBalance += (auction.highestBid - amount);
        // transfer token
        _transfer(owner, auction.highestBidder, _tokenId);

       
    }

    // // Events that will be fired on changes.
    event AuctionStarted(uint256 _tokenId);
    event HighestBidIncreased(uint256 _tokenId, address bidder, uint amount);
    event AuctionEnded(uint256 _tokenId, address winner, uint amount);


    /// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address highestBidder,
        uint highestBid,
        uint endTime,
        bool live
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        return (
            auction.highestBidder,
            auction.highestBid,
            auction.endTime,
            auction.live
        );
    }

    /// @dev Returns the current price of an auction.
    /// @param _tokenId - ID of the token price we are checking.
    function getHighestBid(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        return auction.highestBid;
    }
}


/// @title PixelCore: Pixels in the blockchain
/// @author Oliver Schneider <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="9bf2f5fdf4dbebf2e3fef7f8f4f2f5e8b5f2f4">[email&#160;protected]</a>> (https://pixelcoins.io), based on Axiom Zen (https://www.axiomzen.co)
/// @dev The main PixelCoins contract
contract PixelCore is PixelAuction {

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    /// @notice Creates the main PixelCore smart contract instance.
    function PixelCore() public {
        // the creator of the contract is the initial authority
        authorityAddress = msg.sender;
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It&#39;s up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address) external onlyAuthority {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

    // @dev Allows the authority to capture the balance available to the contract.
    function withdrawBalance() external onlyAuthority returns (bool) {
        uint amount = authorityBalance;
        if (amount > 0) {
            authorityBalance = 0;
            if (!authorityAddress.send(amount)) {
                authorityBalance = amount;
                return false;
            }
        }
        return true;
    }
}