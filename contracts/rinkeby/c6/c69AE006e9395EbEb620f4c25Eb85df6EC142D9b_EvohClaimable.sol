/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.3;



// Part: ERC721TokenReceiver

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///         unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

// Part: EvohERC721

contract EvohERC721 {

    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(bytes4 => bool) public supportsInterface;

    struct UserData {
        uint256 balance;
        uint256[4] ownership;
    }
    mapping(address => UserData) userData;

    address[1024] tokenOwners;
    address[1024] tokenApprovals;
    mapping(uint256 => string) tokenURIs;

    mapping (address => mapping (address => bool)) private operatorApprovals;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        supportsInterface[_INTERFACE_ID_ERC165] = true;
        supportsInterface[_INTERFACE_ID_ERC721] = true;
        supportsInterface[_INTERFACE_ID_ERC721_METADATA] = true;
        supportsInterface[_INTERFACE_ID_ERC721_ENUMERABLE] = true;
    }

    /// @notice Count all NFTs assigned to an owner
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "Query for zero address");
        return userData[_owner].balance;
    }

    /// @notice Find the owner of an NFT
    function ownerOf(uint256 tokenId) public view returns (address) {
        if (tokenId < 1024) {
            address owner = tokenOwners[tokenId];
            if (owner != address(0)) return owner;
        }
        revert("Query for nonexistent tokenId");
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(_from != address(0));
        require(_to != address(0));
        address owner = ownerOf(_tokenId);
        if (
            msg.sender == owner ||
            getApproved(_tokenId) == msg.sender ||
            isApprovedForAll(owner, msg.sender)
        ) {
            delete tokenApprovals[_tokenId];
            removeOwnership(_from, _tokenId);
            addOwnership(_to, _tokenId);
            emit Transfer(_from, _to, _tokenId);
            return;
        }
        revert("Caller is not owner nor approved");
    }

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
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
        _transfer(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "Transfer to non ERC721 receiver");
    }

    function removeOwnership(address _owner, uint256 _tokenId) internal {
        UserData storage data = userData[_owner];
        data.balance -= 1;
        uint256 idx = _tokenId / 256;
        uint256 bitfield = data.ownership[idx];
        data.ownership[idx] = bitfield & ~(uint256(1) << (_tokenId % 256));
    }

    function addOwnership(address _owner, uint256 _tokenId) internal {
        tokenOwners[_tokenId] = _owner;
        UserData storage data = userData[_owner];
        data.balance += 1;
        uint256 idx = _tokenId / 256;
        uint256 bitfield = data.ownership[idx];
        data.ownership[idx] = bitfield | uint256(1) << (_tokenId % 256);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from, _to, _tokenId, bytes(""));
    }

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
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        _transfer(_from, _to, _tokenId);
    }

        /// @notice Change or reaffirm the approved address for an NFT
    function approve(address approved, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Not owner nor approved for all"
        );
        tokenApprovals[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }

    /// @notice Get the approved address for a single NFT
    function getApproved(uint256 tokenId) public view returns (address) {
        ownerOf(tokenId);
        return tokenApprovals[tokenId];
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///         all of `msg.sender`'s assets
    function setApprovalForAll(address operator, bool approved) external {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Query if an address is an authorized operator for another address
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    /// @notice Concatenates tokenId to baseURI and returns the string.
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        ownerOf(tokenId);
        return tokenURIs[tokenId];
    }

    /// @notice Enumerate valid NFTs
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < totalSupply, "Index out of bounds");
        return _index;
    }

    /// @notice Enumerate NFTs assigned to an owner
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        UserData storage data = userData[_owner];
        require (_index < data.balance, "Index out of bounds");
        uint256 bitfield;
        uint256 count;
        for (uint256 i = 0; i < 1024; i++) {
            uint256 key = i % 256;
            if (key == 0) {
                bitfield = data.ownership[i / 256];
            }
            if ((bitfield >> key) & uint256(1) == 1) {
                if (count == _index) {
                    return i;
                }
                count++;
            }
        }
        revert();
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    )
        private
        returns (bool)
    {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(to) }
        if (size == 0) {
            return true;
        }

        (bool success, bytes memory returnData) = to.call{ value: 0 }(
            abi.encodeWithSelector(
                ERC721TokenReceiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                _data
            )
        );
        require(success, "Transfer to non ERC721 receiver");
        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return (returnValue == _ERC721_RECEIVED);
    }

}

// File: Claimable.sol

contract EvohClaimable is EvohERC721 {

    uint256 public maxTotalSupply;
    bytes32 public hashRoot;
    address public owner;

    struct ClaimData {
        bytes32 root;
        uint256 count;
        uint256 limit;
        mapping(address => bool) claimed;
    }

    ClaimData[] public claimData;

    constructor(
        string memory _name,
        string memory _symbol,
        bytes32 _hashRoot,
        uint256 _maxTotalSupply
    )
        EvohERC721(_name, _symbol)
    {
        owner = msg.sender;
        hashRoot = _hashRoot;
        maxTotalSupply = _maxTotalSupply;
    }

    function addClaimRoots(bytes32[] calldata _merkleRoots, uint256[] calldata _claimLimits) external {
        require(msg.sender == owner);
        for (uint256 i = 0; i < _merkleRoots.length; i++) {
            ClaimData storage data = claimData.push();
            data.root = _merkleRoots[i];
            data.limit = _claimLimits[i];
        }
    }

    function isClaimed(uint256 _claimIndex, address _account) public view returns (bool) {
        return claimData[_claimIndex].claimed[_account];
    }

    /**
        @notice Claim an NFT using an eligible account
        @dev Claiming requires two proofs. The "claim proof" validates that the calling
             address is eligible to claim the airdrop. The "hash proof" valides that the
             given IPFS hash for the airdropped NFT is valid, and comes next within the
             sequence of claimable hashes.
        @param _claimIndex Index of the claim hash to validate `_claimProof` against
        @param _hashIndex Index of the hash proof being used. Hash proofs must be
                          provided sequentially in order to be valid.
        @param _hash IPFS hash of the NFT being claimed
        @param _claimProof Proof to validate against the claim root
        @param _hashProof Proof to validate against the hash root
     */
    function claim(
        uint256 _claimIndex,
        uint256 _hashIndex,
        string calldata _hash,
        bytes32[] calldata _claimProof,
        bytes32[] calldata _hashProof
    )
        external
    {
        uint256 claimed = totalSupply;
        require(maxTotalSupply > claimed, "All NFTs claimed");

        // Verify the NFT hash
        bytes32 node = keccak256(abi.encodePacked(_hashIndex, _hash));
        require(_hashIndex == claimed, "Incorrect hash index");
        require(verify(_hashProof, hashRoot, node), "Invalid hash proof");

        // Verify the claim
        node = keccak256(abi.encodePacked(msg.sender));
        ClaimData storage data = claimData[_claimIndex];

        require(_claimIndex < claimData.length, "Invalid merkleIndex");
        require(data.count < data.limit, "All NFTs claimed in this airdrop");
        require(!data.claimed[msg.sender], "User has claimed in this airdrop");
        require(verify(_claimProof, data.root, node), "Invalid claim proof");

        // Mark as claimed, write the hash and send the token.
        data.count++;
        data.claimed[msg.sender] = true;
        tokenURIs[claimed] = _hash;

        addOwnership(msg.sender, claimed);
        emit Transfer(address(0), msg.sender, claimed);
        totalSupply = claimed + 1;
    }

    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    )
        internal
        pure
        returns (bool)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }


}