pragma solidity ^0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}



/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4a2e2f3e2f0a2b32232527302f24642925">[email&#160;protected]</a>> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    
    // Optional methods used by ServiceStation contract
    function tuneLambo(uint256 _newattributes, uint256 _tokenId) external;
    function getLamboAttributes(uint256 _id) external view returns (uint256 attributes);
    function getLamboModel(uint256 _tokenId) external view returns (uint64 _model);
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



/// @title A facet of EtherLamboCore that manages special access privileges.
/// @author Axiom Zen (https://www.axiomzen.co) adapted by Kenny Bania
/// @dev ...
contract EtherLambosAccessControl {
    // This facet controls access control for Etherlambos. There are four roles managed here:
    //
    //     - The CEO: The CEO can reassign other roles and change the addresses of our dependent smart
    //         contracts. It is also the only role that can unpause the smart contract. It is initially
    //         set to the address that created the smart contract in the EtherLamboCore constructor.
    //
    //     - The CFO: The CFO can withdraw funds from EtherLamboCore and its auction contracts.
    //
    //     - The COO: The COO can release new models for sale.
    //
    // It should be noted that these roles are distinct without overlap in their access abilities, the
    // abilities listed for each role above are exhaustive. In particular, while the CEO can assign any
    // address to any role, the CEO address itself doesn&#39;t have the ability to act in those roles. This
    // restriction is intentional so that we aren&#39;t tempted to use the CEO address frequently out of
    // convenience. The less we use an address, the less likely it is that we somehow compromise the
    // account.

    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
}



/// @title Base contract for EtherLambos. Holds all common structs, events and base variables.
/// @author Axiom Zen (https://www.axiomzen.co) adapted by Kenny Bania
/// @dev ...
contract EtherLambosBase is EtherLambosAccessControl {
    /*** EVENTS ***/

    /// @dev The Build event is fired whenever a new car model is build by the COO
    event Build(address owner, uint256 lamboId, uint256 attributes);

    /// @dev Transfer event as defined in current draft of ERC721. Emitted every time a car
    ///  ownership is assigned, including builds.
    event Transfer(address from, address to, uint256 tokenId);

    event Tune(uint256 _newattributes, uint256 _tokenId);
    
    /*** DATA TYPES ***/

    /// @dev The main EtherLambos struct. Every car in EtherLambos is represented by a copy
    ///  of this structure, so great care was taken to ensure that it fits neatly into
    ///  exactly two 256-bit words. Note that the order of the members in this structure
    ///  is important because of the byte-packing rules used by Ethereum.
    ///  Ref: http://solidity.readthedocs.io/en/develop/miscellaneous.html
    struct Lambo {
        // sports-car attributes like max speed, weight etc. are stored here.
        // These attributes can be changed due to tuning/upgrades
        uint256 attributes;

        // The timestamp from the block when this car came was constructed.
        uint64 buildTime;
        
        // the Lambo model identifier
        uint64 model;

    }


    // An approximation of currently how many seconds are in between blocks.
    uint256 public secondsPerBlock = 15;

    /*** STORAGE ***/

    /// @dev An array containing the Lambo struct for all Lambos in existence. The ID
    ///  of each car is actually an index into this array. Note that 0 is invalid index.
    Lambo[] lambos;

    /// @dev A mapping from car IDs to the address that owns them. All cars have
    ///  some valid owner address.
    mapping (uint256 => address) public lamboIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    /// @dev A mapping from LamboIDs to an address that has been approved to call
    ///  transferFrom(). Each Lambo can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public lamboIndexToApproved;

    /// @dev The address of the MarketPlace contract that handles sales of Lambos. This
    ///  same contract handles both peer-to-peer sales as well as new model sales. 
    MarketPlace public marketPlace;
    ServiceStation public serviceStation;
    /// @dev Assigns ownership of a specific Lambo to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Since the number of lambos is capped to 2^32 we can&#39;t overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        lamboIndexToOwner[_tokenId] = _to;
        // When creating new lambos _from is 0x0, but we can&#39;t account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete lamboIndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    /// @dev An internal method that creates a new lambo and stores it. This
    ///  method doesn&#39;t do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Build event
    ///  and a Transfer event.
    /// @param _attributes The lambo&#39;s attributes.
    /// @param _owner The inital owner of this car, must be non-zero
    function _createLambo(
        uint256 _attributes,
        address _owner,
        uint64  _model
    )
        internal
        returns (uint)
    {

        
        Lambo memory _lambo = Lambo({
            attributes: _attributes,
            buildTime: uint64(now),
            model:_model
        });
        uint256 newLamboId = lambos.push(_lambo) - 1;

        // It&#39;s probably never going to happen, 4 billion cars is A LOT, but
        // let&#39;s just be 100% sure we never let this happen.
        require(newLamboId == uint256(uint32(newLamboId)));

        // emit the build event
        Build(
            _owner,
            newLamboId,
            _lambo.attributes
        );

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newLamboId);

        return newLamboId;
    }
     /// @dev An internal method that tunes an existing lambo. This
    ///  method doesn&#39;t do any checking and should only be called when the
    ///  input data is known to be valid. Will generate a Tune event
    /// @param _newattributes The lambo&#39;s new attributes.
    /// @param _tokenId The car to be tuned.
    function _tuneLambo(
        uint256 _newattributes,
        uint256 _tokenId
    )
        internal
    {
        lambos[_tokenId].attributes=_newattributes;
     
        // emit the tune event
        Tune(
            _tokenId,
            _newattributes
        );

    }
    // Any C-level can fix how many seconds per blocks are currently observed.
    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
        //require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}

/// @title The external contract that is responsible for generating metadata for the cars,
///  it has one function that will return the data as bytes.
contract ERC721Metadata {
    /// @dev Given a token Id, returns a byte array that is supposed to be converted into string.
    function getMetadata(uint256 _tokenId, string) public view returns (bytes32[4] buffer, uint256 count) {
        if (_tokenId == 1) {
            buffer[0] = "Hello World! :D";
            count = 15;
        } else if (_tokenId == 2) {
            buffer[0] = "I would definitely choose a medi";
            buffer[1] = "um length string.";
            count = 49;
        } else if (_tokenId == 3) {
            buffer[0] = "Lorem ipsum dolor sit amet, mi e";
            buffer[1] = "st accumsan dapibus augue lorem,";
            buffer[2] = " tristique vestibulum id, libero";
            buffer[3] = " suscipit varius sapien aliquam.";
            count = 128;
        }
    }
}

/// @title The facet of the EtherLambosCore contract that manages ownership, ERC-721 (draft) compliant.
/// @author Axiom Zen (https://www.axiomzen.co) adapted by Cryptoknights
/// @dev Ref: https://github.com/ethereum/EIPs/issues/721

contract EtherLambosOwnership is EtherLambosBase, ERC721 {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant name = "EtherLambos";
    string public constant symbol = "EL";

    // The contract that will return lambo metadata
    ERC721Metadata public erc721Metadata;

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

    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    /// @dev Set the address of the sibling contract that tracks metadata.
    ///  CEO only.
    function setMetadataAddress(address _contractAddress) public onlyCEO {
        erc721Metadata = ERC721Metadata(_contractAddress);
    }

    // Internal utility functions: These functions all assume that their input arguments
    // are valid. We leave it to public methods to sanitize their inputs and follow
    // the required logic.

    /// @dev Checks if a given address is the current owner of a particular Lambo.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId kitten id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return lamboIndexToOwner[_tokenId] == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Lambo.
    /// @param _claimant the address we are confirming Lambo is approved for.
    /// @param _tokenId lambo id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return lamboIndexToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transferFrom() are used together for putting Lambos on sale, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        lamboIndexToApproved[_tokenId] = _approved;
    }

    /// @notice Returns the number of Lambos owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// @notice Transfers a Lambo to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 (or
    ///  EtherLambos specifically) or your Lambo may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the Lambo to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any lambos.
        require(_to != address(this));
        // Disallow transfers to the auction contracts to prevent accidental
        // misuse. Marketplace contracts should only take ownership of Lambos
        // through the allow + transferFrom flow.
        require(_to != address(marketPlace));

        // You can only send your own car.
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific Lambo via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the Lambo that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a Lambo owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the Lambo to be transfered.
    /// @param _to The address that should take ownership of the Lambo. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the Lambo to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any lambos.
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of Lambos currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return lambos.length - 1;
    }

    /// @notice Returns the address currently assigned ownership of a given Lambo.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = lamboIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    /// @notice Returns a list of all Lambo IDs assigned to an address.
    /// @param _owner The owner whose Lambo we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
    ///  expensive (it walks the entire Lambo array looking for cars belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCars = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all cars have IDs starting at 1 and increasing
            // sequentially up to the totalCat count.
            uint256 carId;

            for (carId = 1; carId <= totalCars; carId++) {
                if (lamboIndexToOwner[carId] == _owner) {
                    result[resultIndex] = carId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// @dev Adapted from memcpy() by @arachnid (Nick Johnson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="accddecdcfc4c2c5c8ecc2c3d8c8c3d882c2c9d8">[email&#160;protected]</a>>)
    ///  This method is licenced under the Apache License.
    ///  Ref: https://github.com/Arachnid/solidity-stringutils/blob/2f6ca9accb48ae14c66f1437ec50ed19a0616f78/strings.sol
    function _memcpy(uint _dest, uint _src, uint _len) private view {
        // Copy word-length chunks while possible
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(_dest, mload(_src))
            }
            _dest += 32;
            _src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256 ** (32 - _len) - 1;
        assembly {
            let srcpart := and(mload(_src), not(mask))
            let destpart := and(mload(_dest), mask)
            mstore(_dest, or(destpart, srcpart))
        }
    }

    /// @dev Adapted from toString(slice) by @arachnid (Nick Johnson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e7869586848f898e83a7898893838893c9898293">[email&#160;protected]</a>>)
    ///  This method is licenced under the Apache License.
    ///  Ref: https://github.com/Arachnid/solidity-stringutils/blob/2f6ca9accb48ae14c66f1437ec50ed19a0616f78/strings.sol
    function _toString(bytes32[4] _rawBytes, uint256 _stringLength) private view returns (string) {
        var outputString = new string(_stringLength);
        uint256 outputPtr;
        uint256 bytesPtr;

        assembly {
            outputPtr := add(outputString, 32)
            bytesPtr := _rawBytes
        }

        _memcpy(outputPtr, bytesPtr, _stringLength);

        return outputString;
    }

    /// @notice Returns a URI pointing to a metadata package for this token conforming to
    ///  ERC-721 (https://github.com/ethereum/EIPs/issues/721)
    /// @param _tokenId The ID number of the Lambos whose metadata should be returned.
    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        require(erc721Metadata != address(0));
        bytes32[4] memory buffer;
        uint256 count;
        (buffer, count) = erc721Metadata.getMetadata(_tokenId, _preferredTransport);

        return _toString(buffer, count);
    }
}


/// @title MarketPlace core
/// @dev Contains models, variables, and internal methods for the marketplace.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract MarketPlaceBase is Ownable {

    // Represents an sale on an NFT
    struct Sale {
        // Current owner of NFT
        address seller;
        // Price (in wei) 
        uint128 price;
        // Time when sale started
        // NOTE: 0 if this sale has been concluded
        uint64 startedAt;
    }
    
    struct Affiliates {
        address affiliate_address;
        uint64 commission;
        uint64 pricecut;
    }
    
    //Affiliates[] affiliates;
    // Reference to contract tracking NFT ownership
    ERC721 public nonFungibleContract;

    // Cut owner takes on each sale, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    uint256 public ownerCut;

    //map the Affiliate Code to the Affiliate
    mapping (uint256 => Affiliates) codeToAffiliate;

    // Map from token ID to their corresponding sale.
    mapping (uint256 => Sale) tokenIdToSale;

    event SaleCreated(uint256 tokenId, uint256 price);
    event SaleSuccessful(uint256 tokenId, uint256 price, address buyer);
    event SaleCancelled(uint256 tokenId);

    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(address _owner, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(address _receiver, uint256 _tokenId) internal {
        // it will throw if transfer fails
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    /// @dev Adds an sale to the list of open sales. Also fires the
    ///  SaleCreated event.
    /// @param _tokenId The ID of the token to be put on sale.
    /// @param _sale Sale to add.
    function _addSale(uint256 _tokenId, Sale _sale) internal {
        

        tokenIdToSale[_tokenId] = _sale;

        SaleCreated(
            uint256(_tokenId),
            uint256(_sale.price)
        );
    }

    /// @dev Cancels a sale unconditionally.
    function _cancelSale(uint256 _tokenId, address _seller) internal {
        _removeSale(_tokenId);
        _transfer(_seller, _tokenId);
        SaleCancelled(_tokenId);
    }

    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        // Get a reference to the sale struct
        Sale storage sale = tokenIdToSale[_tokenId];

        // Explicitly check that this sale is currently live.
        // (Because of how Ethereum mappings work, we can&#39;t just count
        // on the lookup above failing. An invalid _tokenId will just
        // return a sale object that is all zeros.)
        require(_isOnSale(sale));

        // Check that the bid is greater than or equal to the current price
        uint256 price = sale.price;
        require(_bidAmount >= price);

        // Grab a reference to the seller before the sale struct
        // gets deleted.
        address seller = sale.seller;

        // The bid is good! Remove the sale before sending the fees
        // to the sender so we can&#39;t have a reentrancy attack.
        _removeSale(_tokenId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            // Calculate the Marketplace&#39;s cut.
            // (NOTE: _computeCut() is guaranteed to return a
            // value <= price, so this subtraction can&#39;t go negative.)
            uint256 marketplaceCut = _computeCut(price);
            uint256 sellerProceeds = price - marketplaceCut;

            // NOTE: Doing a transfer() in the middle of a complex
            // method like this is generally discouraged because of
            // reentrancy attacks and DoS attacks if the seller is
            // a contract with an invalid fallback function. We explicitly
            // guard against reentrancy attacks by removing the auction
            // before calling transfer(), and the only thing the seller
            // can DoS is the sale of their own asset! (And if it&#39;s an
            // accident, they can call cancelAuction(). )
            seller.transfer(sellerProceeds);
        }

        // Calculate any excess funds included with the bid. If the excess
        // is anything worth worrying about, transfer it back to bidder.
        // NOTE: We checked above that the bid amount is greater than or
        // equal to the price so this cannot underflow.
        uint256 bidExcess = _bidAmount - price;

        // Return the funds. Similar to the previous transfer, this is
        // not susceptible to a re-entry attack because the auction is
        // removed before any transfers occur.
        msg.sender.transfer(bidExcess);

        // Tell the world!
        SaleSuccessful(_tokenId, price, msg.sender);

        return price;
    }

    /// @dev Removes a sale from the list of open sales.
    /// @param _tokenId - ID of NFT on sale.
    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToSale[_tokenId];
    }

    /// @dev Returns true if the NFT is on sale.
    /// @param _sale - Sale to check.
    function _isOnSale(Sale storage _sale) internal view returns (bool) {
        return (_sale.startedAt > 0);
    }


    /// @dev Computes owner&#39;s cut of a sale.
    /// @param _price - Sale price of NFT.
    function _computeCut(uint256 _price) internal view returns (uint256) {
        // NOTE: We don&#39;t use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the Marketplace constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return _price * ownerCut / 10000;
    }
    function _computeAffiliateCut(uint256 _price,Affiliates affiliate) internal view returns (uint256) {
        // NOTE: We don&#39;t use SafeMath (or similar) in this function because
        //  all of our entry functions carefully cap the maximum values for
        //  currency (at 128-bits), and ownerCut <= 10000 (see the require()
        //  statement in the Marketplace constructor). The result of this
        //  function is always guaranteed to be <= _price.
        return _price * affiliate.commission / 10000;
    }
    /// @dev Adds an affiliate to the list.
    /// @param _code The referall code of the affiliate.
    /// @param _affiliate Affiliate to add.
    function _addAffiliate(uint256 _code, Affiliates _affiliate) internal {
        codeToAffiliate[_code] = _affiliate;
   
    }
    
    /// @dev Removes a affiliate from the list.
    /// @param _code - The referall code of the affiliate.
    function _removeAffiliate(uint256 _code) internal {
        delete codeToAffiliate[_code];
    }
    
    
    //_bidReferral(_tokenId, msg.value);
    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _bidReferral(uint256 _tokenId, uint256 _bidAmount,Affiliates _affiliate)
        internal
        returns (uint256)
    {
        
        // Get a reference to the sale struct
        Sale storage sale = tokenIdToSale[_tokenId];

        //Only Owner of Contract can sell referrals
        require(sale.seller==owner);

        // Explicitly check that this sale is currently live.
        // (Because of how Ethereum mappings work, we can&#39;t just count
        // on the lookup above failing. An invalid _tokenId will just
        // return a sale object that is all zeros.)
        require(_isOnSale(sale));
        // Check that the bid is greater than or equal to the current price
        
        uint256 price = sale.price;
        
        //deduce the affiliate pricecut
        price=price * _affiliate.pricecut / 10000;  
        require(_bidAmount >= price);

        // Grab a reference to the seller before the sale struct
        // gets deleted.
        address seller = sale.seller;
        address affiliate_address = _affiliate.affiliate_address;
        
        // The bid is good! Remove the sale before sending the fees
        // to the sender so we can&#39;t have a reentrancy attack.
        _removeSale(_tokenId);

        // Transfer proceeds to seller (if there are any!)
        if (price > 0) {
            // Calculate the Marketplace&#39;s cut.
            // (NOTE: _computeCut() is guaranteed to return a
            // value <= price, so this subtraction can&#39;t go negative.)
            uint256 affiliateCut = _computeAffiliateCut(price,_affiliate);
            uint256 sellerProceeds = price - affiliateCut;

            // NOTE: Doing a transfer() in the middle of a complex
            // method like this is generally discouraged because of
            // reentrancy attacks and DoS attacks if the seller is
            // a contract with an invalid fallback function. We explicitly
            // guard against reentrancy attacks by removing the auction
            // before calling transfer(), and the only thing the seller
            // can DoS is the sale of their own asset! (And if it&#39;s an
            // accident, they can call cancelAuction(). )
            seller.transfer(sellerProceeds);
            affiliate_address.transfer(affiliateCut);
        }

        // Calculate any excess funds included with the bid. If the excess
        // is anything worth worrying about, transfer it back to bidder.
        // NOTE: We checked above that the bid amount is greater than or
        // equal to the price so this cannot underflow.
        uint256 bidExcess = _bidAmount - price;

        // Return the funds. Similar to the previous transfer, this is
        // not susceptible to a re-entry attack because the auction is
        // removed before any transfers occur.
        msg.sender.transfer(bidExcess);

        // Tell the world!
        SaleSuccessful(_tokenId, price, msg.sender);

        return price;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

/// @title MarketPlace for non-fungible tokens.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract MarketPlace is Pausable, MarketPlaceBase {

	// @dev Sanity check that allows us to ensure that we are pointing to the
    //  right auction in our setSaleMarketplaceAddress() call.
    bool public isMarketplace = true;
	
    /// @dev The ERC-165 interface signature for ERC-721.
    ///  Ref: https://github.com/ethereum/EIPs/issues/165
    ///  Ref: https://github.com/ethereum/EIPs/issues/721
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    /// @param _cut - percent cut the owner takes on each sale, must be
    ///  between 0-10,000.
    function MarketPlace(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721 candidateContract = ERC721(_nftAddress);
        //require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }
    function setNFTAddress(address _nftAddress, uint256 _cut) external onlyOwner {
        require(_cut <= 10000);
        ownerCut = _cut;
        ERC721 candidateContract = ERC721(_nftAddress);
        //require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }
    /// @dev Remove all Ether from the contract, which is the owner&#39;s cuts
    ///  as well as any Ether sent directly to the contract address.
    ///  Always transfers to the NFT contract, but can be called either by
    ///  the owner or the NFT contract.
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        // We are using this boolean method to make sure that even if one fails it will still work
        bool res = nftAddress.send(this.balance);
    }

    /// @dev Creates and begins a new sale.
    /// @param _tokenId - ID of token to sale, sender must be owner.
    /// @param _price - Price of item (in wei)
    /// @param _seller - Seller, if not the message sender
    function createSale(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    )
        external
        whenNotPaused
    {
        // Sanity check that no inputs overflow how many bits we&#39;ve allocated
        // to store them in the auction struct.
        require(_price == uint256(uint128(_price)));
        
        //require(_owns(msg.sender, _tokenId));
        //_escrow(msg.sender, _tokenId);
        
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        
        Sale memory sale = Sale(
            _seller,
            uint128(_price),
            uint64(now)
        );
        _addSale(_tokenId, sale);
    }


    

    /// @dev Bids on a sale, completing the sale and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bid(uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
        // _bid will throw if the bid or funds transfer fails
       _bid(_tokenId, msg.value); 
       _transfer(msg.sender, _tokenId);
      
    }

    /// @dev Bids on a sale, completing the sale and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param _tokenId - ID of token to bid on.
    function bidReferral(uint256 _tokenId,uint256 _code)
        external
        payable
        whenNotPaused
    {
        // _bid will throw if the bid or funds transfer fails
        Affiliates storage affiliate = codeToAffiliate[_code];
        
        require(affiliate.affiliate_address!=0&&_code>0);
        _bidReferral(_tokenId, msg.value,affiliate);
        _transfer(msg.sender, _tokenId);

       
    }
    
    /// @dev Cancels an sale that hasn&#39;t been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param _tokenId - ID of token on sale
    function cancelSale(uint256 _tokenId)
        external
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        address seller = sale.seller;
        require(msg.sender == seller);
        _cancelSale(_tokenId, seller);
    }

    /// @dev Cancels a sale when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _tokenId - ID of the NFT on sale to cancel.
    function cancelSaleWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        external
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        _cancelSale(_tokenId, sale.seller);
    }

    /// @dev Returns sale info for an NFT on sale.
    /// @param _tokenId - ID of NFT on sale.
    function getSale(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 price,
        uint256 startedAt
    ) {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return (
            sale.seller,
            sale.price,
            sale.startedAt
        );
    }

    /// @dev Returns the current price of a sale.
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Sale storage sale = tokenIdToSale[_tokenId];
        require(_isOnSale(sale));
        return sale.price;
    }


    /// @dev Creates and begins a new sale.
    /// @param _code - ID of token to sale, sender must be owner.
    /// @param _commission - percentage of commission for affiliate
    /// @param _pricecut - percentage of sell price cut for buyer
    /// @param _affiliate_address - affiliate address 
    function createAffiliate(
        uint256 _code,
        uint64  _commission,
        uint64  _pricecut,
        address _affiliate_address
    )
        external
        onlyOwner
    {

        Affiliates memory affiliate = Affiliates(
            address(_affiliate_address),
            uint64(_commission),
            uint64(_pricecut)
        );
        _addAffiliate(_code, affiliate);
    }
    
    /// @dev Returns affiliate info for an affiliate code.
    /// @param _code - code for an affiliate.
    function getAffiliate(uint256 _code)
        external
        view
        onlyOwner
        returns
    (
         address affiliate_address,
         uint64 commission,
         uint64 pricecut
    ) {
        Affiliates storage affiliate = codeToAffiliate[_code];
        
        return (
            affiliate.affiliate_address,
            affiliate.commission,
            affiliate.pricecut
        );
    }
     /// @dev Removes affiliate.
    ///  Only the owner may do this
    /// @param _code - code for an affiliate.
    function removeAffiliate(uint256 _code)
        onlyOwner
        external
    {
        _removeAffiliate(_code); 
        
    }
}


/// @title ServiceStationBase core
/// @dev Contains models, variables, and internal methods for the ServiceStation.
contract ServiceStationBase {

    // Reference to contract tracking NFT ownership
    ERC721 public nonFungibleContract;

    struct Tune{
        uint256 startChange;
        uint256 rangeChange;
        uint256 attChange;
        bool plusMinus;
        bool replace;
        uint128 price;
        bool active;
        uint64 model;
    }
    Tune[] options;
    
   
    
    /// @dev Returns true if the claimant owns the token.
    /// @param _claimant - Address claiming to own the token.
    /// @param _tokenId - ID of token whose ownership to verify.
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }
  
    /// @dev Calls the NFT Contract with the tuned attributes 
    function _tune(uint256 _newattributes, uint256 _tokenId) internal {
    nonFungibleContract.tuneLambo(_newattributes, _tokenId);
    }
    
    function _changeAttributes(uint256 _tokenId,uint256 _optionIndex) internal {
    
    //Get model from token
    uint64 model = nonFungibleContract.getLamboModel(_tokenId);
    //throw if tune option is not made for model
    require(options[_optionIndex].model==model);
    
    //Get original attributes
    uint256 attributes = nonFungibleContract.getLamboAttributes(_tokenId);
    uint256 part=0;
    
    //Dissect for options
    part=(attributes/(10 ** options[_optionIndex].startChange)) % (10 ** options[_optionIndex].rangeChange);
    //part=1544;
    //Change attributes & verify
    //Should attChange be added,subtracted or replaced?
    if(options[_optionIndex].replace == false)
        {
            
            //change should be added
            if(options[_optionIndex].plusMinus == false)
            {
                //e.g. if range = 4 then value can not be higher then 9999 - overflow check
                require((part+options[_optionIndex].attChange)<(10**options[_optionIndex].rangeChange));
                //add to attributes
                attributes=attributes+options[_optionIndex].attChange*(10 ** options[_optionIndex].startChange);
            }
            else{
                //do some subtraction
                //e.g. value must be greater then 0
                require(part>options[_optionIndex].attChange);
                //substract from attributes 
                attributes-=options[_optionIndex].attChange*(10 ** options[_optionIndex].startChange);
            }
        }
    else
        {
            //do some replacing
            attributes=attributes-part*(10 ** options[_optionIndex].startChange);
            attributes+=options[_optionIndex].attChange*(10 ** options[_optionIndex].startChange);
        }
    
  
   
    //Tune Lambo in NFT contract
    _tune(uint256(attributes), _tokenId);
       
        
    }
    
    
}


/// @title ServiceStation for non-fungible tokens.
contract ServiceStation is Pausable, ServiceStationBase {

	// @dev Sanity check that allows us to ensure that we are pointing to the right call.
    bool public isServicestation = true;
	
    /// @dev The ERC-165 interface signature for ERC-721.
    ///  Ref: https://github.com/ethereum/EIPs/issues/165
    ///  Ref: https://github.com/ethereum/EIPs/issues/721
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

    uint256 public optionCount;
    mapping (uint64 => uint256) public modelIndexToOptionCount;
    /// @dev Constructor creates a reference to the NFT ownership contract
    ///  and verifies the owner cut is in the valid range.
    /// @param _nftAddress - address of a deployed contract implementing
    ///  the Nonfungible Interface.
    function ServiceStation(address _nftAddress) public {

        ERC721 candidateContract = ERC721(_nftAddress);
        //require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
        _newTuneOption(0,0,0,false,false,0,0);
        
    }
    function setNFTAddress(address _nftAddress) external onlyOwner {
        
        ERC721 candidateContract = ERC721(_nftAddress);
        //require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }
    
    function newTuneOption(
        uint32 _startChange,
        uint32 _rangeChange,
        uint256 _attChange,
        bool _plusMinus,
        bool _replace,
        uint128 _price,
        uint64 _model
        )
        external
        {
           //Only allow owner to add new options
           require(msg.sender == owner ); 
           optionCount++;
           modelIndexToOptionCount[_model]++;
           _newTuneOption(_startChange,_rangeChange,_attChange,_plusMinus, _replace,_price,_model);
       
        }
    function changeTuneOption(
        uint32 _startChange,
        uint32 _rangeChange,
        uint256 _attChange,
        bool _plusMinus,
        bool _replace,
        uint128 _price,
        bool _isactive,
        uint64 _model,
        uint256 _optionIndex
        )
        external
        {
           //Only allow owner to add new options
           require(msg.sender == owner ); 
           
           
           _changeTuneOption(_startChange,_rangeChange,_attChange,_plusMinus, _replace,_price,_isactive,_model,_optionIndex);
       
        }
        
    function _newTuneOption( uint32 _startChange,
        uint32 _rangeChange,
        uint256 _attChange,
        bool _plusMinus,
        bool _replace,
        uint128 _price,
        uint64 _model
        ) 
        internal
        {
        
           Tune memory _option = Tune({
            startChange: _startChange,
            rangeChange: _rangeChange,
            attChange: _attChange,
            plusMinus: _plusMinus,
            replace: _replace,
            price: _price,
            active: true,
            model: _model
            });
        
        options.push(_option);
    }
    
    function _changeTuneOption( uint32 _startChange,
        uint32 _rangeChange,
        uint256 _attChange,
        bool _plusMinus,
        bool _replace,
        uint128 _price,
        bool _isactive,
        uint64 _model,
        uint256 _optionIndex
        ) 
        internal
        {
        
           Tune memory _option = Tune({
            startChange: _startChange,
            rangeChange: _rangeChange,
            attChange: _attChange,
            plusMinus: _plusMinus,
            replace: _replace,
            price: _price,
            active: _isactive,
            model: _model
            });
        
        options[_optionIndex]=_option;
    }
    
    function disableTuneOption(uint256 index) external
    {
        require(msg.sender == owner ); 
        options[index].active=false;
    }
    
    function enableTuneOption(uint256 index) external
    {
        require(msg.sender == owner ); 
        options[index].active=true;
    }
    function getOption(uint256 _index) 
    external view
    returns (
        uint256 _startChange,
        uint256 _rangeChange,
        uint256 _attChange,
        bool _plusMinus,
        uint128 _price,
        bool active,
        uint64 model
    ) 
    {
      
        //require(options[_index].active);
        return (
            options[_index].startChange,
            options[_index].rangeChange,
            options[_index].attChange,
            options[_index].plusMinus,
            options[_index].price,
            options[_index].active,
            options[_index].model
        );  
    }
    
    function getOptionCount() external view returns (uint256 _optionCount)
        {
        return optionCount;    
        }
    
    function tuneLambo(uint256 _tokenId,uint256 _optionIndex) external payable
    {
       //Caller needs to own Lambo
       require(_owns(msg.sender, _tokenId)); 
       //Tuning Option needs to be enabled
       require(options[_optionIndex].active);
       //Enough money for tuning to spend?
       require(msg.value>=options[_optionIndex].price);
       
       _changeAttributes(_tokenId,_optionIndex);
    }
    /// @dev Remove all Ether from the contract, which is the owner&#39;s cuts
    ///  as well as any Ether sent directly to the contract address.
    ///  Always transfers to the NFT contract, but can be called either by
    ///  the owner or the NFT contract.
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        // We are using this boolean method to make sure that even if one fails it will still work
        bool res = owner.send(this.balance);
    }

    function getOptionsForModel(uint64 _model) external view returns(uint256[] _optionsModel) {
        //uint256 tokenCount = balanceOf(_owner);

        //if (tokenCount == 0) {
            // Return an empty array
        //    return new uint256[](0);
        //} else {
            uint256[] memory result = new uint256[](modelIndexToOptionCount[_model]);
            //uint256 totalCars = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all cars have IDs starting at 0 and increasing
            // sequentially up to the optionCount count.
            uint256 optionId;

            for (optionId = 1; optionId <= optionCount; optionId++) {
                if (options[optionId].model == _model && options[optionId].active == true) {
                    result[resultIndex] = optionId;
                    resultIndex++;
                }
            }

            return result;
       // }
    }

}



////No SiringClockAuction needed for Lambos
////No separate modification for SaleContract needed

/// @title Handles creating sales for sale of lambos.
///  This wrapper of ReverseSale exists only so that users can create
///  sales with only one transaction.
contract EtherLambosSale is EtherLambosOwnership {

    // @notice The sale contract variables are defined in EtherLambosBase to allow
    //  us to refer to them in EtherLambosOwnership to prevent accidental transfers.
    // `saleMarketplace` refers to the auction for p2p sale of cars.
   

    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setMarketplaceAddress(address _address) external onlyCEO {
        MarketPlace candidateContract = MarketPlace(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isMarketplace());

        // Set the new contract address
        marketPlace = candidateContract;
    }


    /// @dev Put a lambo up for sale.
    ///  Does some ownership trickery to create auctions in one tx.
    function createLamboSale(
        uint256 _carId,
        uint256 _price
    )
        external
        whenNotPaused
    {
        // Sale contract checks input sizes
        // If lambo is already on any sale, this will throw
        // because it will be owned by the sale contract.
        require(_owns(msg.sender, _carId));
        
        _approve(_carId, marketPlace);
        // Sale throws if inputs are invalid and clears
        // transfer after escrowing the lambo.
        marketPlace.createSale(
            _carId,
            _price,
            msg.sender
        );
    }
    
    
    function bulkCreateLamboSale(
        uint256 _price,
        uint256 _tokenIdStart,
        uint256 _tokenCount
    )
        external
        onlyCOO
    {
        // Sale contract checks input sizes
        // If lambo is already on any sale, this will throw
        // because it will be owned by the sale contract.
        for(uint256 i=0;i<_tokenCount;i++)
            {
            require(_owns(msg.sender, _tokenIdStart+i));
        
            _approve(_tokenIdStart+i, marketPlace);
            // Sale throws if inputs are invalid and clears
            // transfer after escrowing the lambo.
            marketPlace.createSale(
                _tokenIdStart+i,
                _price,
             msg.sender
            );
        }
    }
    /// @dev Transfers the balance of the marketPlace contract
    /// to the EtherLambosCore contract. We use two-step withdrawal to
    /// prevent two transfer calls in the auction bid function.
    function withdrawSaleBalances() external onlyCLevel {
        marketPlace.withdrawBalance();
        
    }
}

/// @title all functions related to creating lambos
contract EtherLambosBuilding is EtherLambosSale {

    // Limits the number of cars the contract owner can ever create.
    //uint256 public constant PROMO_CREATION_LIMIT = 5000;
    //uint256 public constant GEN0_CREATION_LIMIT = 45000;


    // Counts the number of cars the contract owner has created.
    uint256 public lambosBuildCount;


    /// @dev we can build lambos. Only callable by COO
    /// @param _attributes the encoded attributes of the lambo to be created, any value is accepted
    /// @param _owner the future owner of the created lambo. Default to contract COO
    /// @param _model the model of the created lambo. 
    function createLambo(uint256 _attributes, address _owner, uint64 _model) external onlyCOO {
        address lamboOwner = _owner;
        if (lamboOwner == address(0)) {
             lamboOwner = cooAddress;
        }
        //require(promoCreatedCount < PROMO_CREATION_LIMIT);

        lambosBuildCount++;
        _createLambo(_attributes, lamboOwner, _model);
    }

    function bulkCreateLambo(uint256 _attributes, address _owner, uint64 _model,uint256 count, uint256 startNo) external onlyCOO {
        address lamboOwner = _owner;
        uint256 att=_attributes;
        if (lamboOwner == address(0)) {
             lamboOwner = cooAddress;
        }
        
        //do some replacing
            //_attributes=_attributes-part*(10 ** 66);
        
        
        //require(promoCreatedCount < PROMO_CREATION_LIMIT);
        for(uint256 i=0;i<count;i++)
            {
            lambosBuildCount++;
            att=_attributes+(startNo+i)*(10 ** 66);
            _createLambo(att, lamboOwner, _model);
            }
    }
}

/// @title all functions related to tuning lambos
contract EtherLambosTuning is EtherLambosBuilding {

    // Counts the number of tunings have been done.
    uint256 public lambosTuneCount;

    function setServicestationAddress(address _address) external onlyCEO {
        ServiceStation candidateContract = ServiceStation(_address);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isServicestation());

        // Set the new contract address
        serviceStation = candidateContract;
    }
    /// @dev we can tune lambos. Only callable by ServiceStation contract
    /// @param _newattributes the new encoded attributes of the lambo to be updated
    /// @param _tokenId the lambo to be tuned.
    function tuneLambo(uint256 _newattributes, uint256 _tokenId) external {
        
        //Tuning can only be done by the ServiceStation Contract. 
        require(
            msg.sender == address(serviceStation)
        );
        
        
        lambosTuneCount++;
        _tuneLambo(_newattributes, _tokenId);
    }
    function withdrawTuneBalances() external onlyCLevel {
        serviceStation.withdrawBalance();
        
    }

}

/// @title EtherLambos: Collectible, tuneable, and super stylish lambos on the Ethereum blockchain.
/// @author Cryptoknights code adapted from Axiom Zen (https://www.axiomzen.co)
/// @dev The main EtherLambos contract, keeps track of lambos.
contract EtherLambosCore is EtherLambosTuning {

    // This is the main EtherLambos contract. In order to keep our code seperated into logical sections,
    // we&#39;ve broken it up in two ways. First, we have several seperately-instantiated sibling contracts
    // that handle sales. The sales are
    // seperate since their logic is somewhat complex and there&#39;s always a risk of subtle bugs. By keeping
    // them in their own contracts, we can upgrade them without disrupting the main contract that tracks
    // lambo ownership. 
    //
    // Secondly, we break the core contract into multiple files using inheritence, one for each major
    // facet of functionality of EtherLambos. This allows us to keep related code bundled together while still
    // avoiding a single giant file with everything in it. The breakdown is as follows:
    //
    //      - EtherLambosBase: This is where we define the most fundamental code shared throughout the core
    //             functionality. This includes our main data storage, constants and data types, plus
    //             internal functions for managing these items.
    //
    //      - EtherLambosAccessControl: This contract manages the various addresses and constraints for operations
    //             that can be executed only by specific roles. Namely CEO, CFO and COO.
    //
    //      - EtherLambosOwnership: This provides the methods required for basic non-fungible token
    //             transactions, following the draft ERC-721 spec (https://github.com/ethereum/EIPs/issues/721).
    //
    //      - EtherLambosSale: Here we have the public methods for sales. 
    //
    //      - EtherLambosBuilding: This final facet contains the functionality we use for creating new cars.
    //             

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    /// @notice Creates the main EtherLambos smart contract instance.
    function EtherLambosCore() public {
        // Starts paused.
        paused = true;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;

        // start with the car 0 
        _createLambo(uint256(-1), address(0),0);
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It&#39;s up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
        // See README.md for updgrade plan
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

    /// @notice No tipping!
    /// @dev Reject all Ether from being sent here, unless it&#39;s from the marketPlace contract.
    /// (Hopefully, we can prevent user accidents.)
    function() external payable {
        require(
            msg.sender == address(marketPlace)
        );
    }

    /// @notice Returns all the relevant information about a specific lambo.
    /// @param _id The ID of the lambo of interest.
    function getLambo(uint256 _id)
        external
        view
        returns (
        uint256 buildTime,
        uint256 attributes
    ) {
        Lambo storage kit = lambos[_id];

        buildTime = uint256(kit.buildTime);
        attributes = kit.attributes;
    }
    /// @notice Returns all the relevant information about a specific lambo.
    /// @param _id The ID of the lambo of interest.
    function getLamboAttributes(uint256 _id)
        external
        view
        returns (
        uint256 attributes
    ) {
        Lambo storage kit = lambos[_id];
        attributes = kit.attributes;
        return attributes;
    }
    
    /// @notice Returns all the relevant information about a specific lambo.
    /// @param _id The ID of the lambo of interest.
    function getLamboModel(uint256 _id)
        external
        view
        returns (
        uint64 model
    ) {
        Lambo storage kit = lambos[_id];
        model = kit.model;
        return model;
    }
    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can&#39;t have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpause() public onlyCEO whenPaused {
        require(marketPlace != address(0));
        require(serviceStation != address(0));
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.unpause();
    }

    // @dev Allows the CFO to capture the balance available to the contract.
    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
        cfoAddress.send(balance);
     
    }
}