pragma solidity ^0.4.11;


/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5d393829381d3c25343230273833733e32">[email&#160;protected]</a>> (https://github.com/dete)
contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}



contract CryptsyBase {

    event Transfer(address from, address to, uint256 tokenId);

    /*** DATA TYPES ***/

    /// @dev The Cryptsy struct.
    struct Cryptsy {
        uint32 conceptionTime;
        uint32 creativity;
        uint32 intuition;
        uint32 experience;
    }

    /*** CONSTANTS ***/
    /*** STORAGE ***/

    /// @dev An array containing the Cryptsy struct for all Cryptsys
    Cryptsy[] cryptsys;

    /// @dev A mapping from cryptrsy IDs to the address that owns them. 
    mapping (uint256 => address) public cryptsyIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    mapping (address => uint256) ownershipTokenCount;

    /// @dev A mapping from cryptsyIDs to an address that has been approved to call
    ///  transferFrom(). Each cryptsy can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public cryptsyIndexToApproved;

    /// @dev The address of the ClockAuction contract that handles sales of Cryptsys. 
    // SaleClockAuction public saleAuction;

    /// @dev Assigns ownership of a specific Cryptsy to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Since the number of cryptsys is capped to 2^32 we can&#39;t overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        cryptsyIndexToOwner[_tokenId] = _to;
        // When creating new cryptsys _from is 0x0, but we can&#39;t account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // once the cryptsy is transferred also clear sire allowances
            // delete sireAllowedToAddress[_tokenId];
            // clear any previously approved ownership exchange
            delete cryptsyIndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev An internal method that creates a new cryptsy and stores it. This
    ///  method doesn&#39;t do any checking and should only be called when the
    ///  input data is known to be valid. 
    function _createCryptsy(
        uint32 _creativity,
        uint32 _intuition,
        uint32 _experience,
        address _owner
    )
        internal
        returns (uint)
    {

        Cryptsy memory _cryptsy = Cryptsy({
            conceptionTime: uint32(now),
            creativity: uint32(_creativity),
            intuition: uint32(_intuition),
            experience: uint32(_experience)
        });
        uint256 newCryptsyId = cryptsys.push(_cryptsy) - 1;

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newCryptsyId);

        return newCryptsyId;
    }
}


contract CryptsyToken is CryptsyBase, ERC721 {
    string public name = "Cryptsy";
    string public symbol = "CPTSY";

    function implementsERC721() public pure returns (bool)
    {
        return true;
    }
    
    // Internal utility functions: These functions all assume that their input arguments
    // are valid. We leave it to public methods to sanitize their inputs and follow
    // the required logic.

    /// @dev Checks if a given address is the current owner of a particular Cryptsy.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId cryptsy id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return cryptsyIndexToOwner[_tokenId] == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular Cryptsy.
    /// @param _claimant the address we are confirming cryptsy is approved for.
    /// @param _tokenId cryptsy id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return cryptsyIndexToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. 
    function _approve(uint256 _tokenId, address _approved) internal {
        cryptsyIndexToApproved[_tokenId] = _approved;
    }

    /// @notice Returns the number of Cryptsys owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// @notice Transfers a Cryptsy to another address.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        public
        // whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // You can only send your own cat.
        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific Cryptsy
    function approve(
        address _to,
        uint256 _tokenId
    )
        public
        // whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _tokenId);
    }

    /// @notice Transfer a Cryptsy owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        // whenNotPaused
    {
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of Cryptsys currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return cryptsys.length - 1;
    }

    /// @notice Returns the address currently assigned ownership of a given Cryptsy.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId) public view returns (address owner)
    {
        owner = cryptsyIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    /// @notice Returns the nth Cryptsy assigned to an address, with n specified by the
    ///  _index argument.
    /// @dev Exists only to allow off-chain queries of ownership.
    ///  Optional method for ERC-721.
    function tokensOfOwnerByIndex(address _owner, uint256 _index) public view 
        returns (uint256 tokenId)
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (cryptsyIndexToOwner[i] == _owner) {
                if (count == _index) {
                    return i;
                } else {
                    count++;
                }
            }
        }
        revert();
    }

    function generateCryptsyToken(uint32 creativity, uint32 intuition, uint32 experience) public
        returns (uint256 newCptsy) 
    {
        Cryptsy memory _cryptsy = Cryptsy({
            conceptionTime: uint32(now),
            creativity: creativity,
            intuition: intuition,
            experience: experience
        });
        uint256 newCryptsyId = cryptsys.push(_cryptsy) - 1;

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, msg.sender, newCryptsyId);
        return newCryptsyId;
    }
}