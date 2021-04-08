/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: MIT
// by William Hilton (https://github.com/wmhilton)
// written using remix.ethereum.org
pragma solidity >=0.8.3 <0.9.0;

/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver {
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/**
 * @title NFT
 * @dev A simple 1 of 1 NFT implementation
 */
contract ERC721Token {
    /**
     * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
     * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
     * number of NFTs may be created and assigned without emitting Transfer. At the time of any
     * transfer, the approved address for that NFT (if any) is reset to none.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  
    /**
     * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
     * address indicates there is no approved address. When a Transfer event emits, this also
     * indicates that the approved address for that NFT (if any) is reset to none.
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
     * all NFTs of the owner.
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    uint256 internal count = 0;
    uint256 internal burned = 0;
    mapping (uint256 => address) internal owners;
    mapping (uint256 => string) internal tokenURIs;
    mapping (uint256 => address) internal approveds;
    mapping (address => mapping (address => bool)) internal operators;
    
    // This is pretty useless but necessary to be spec compliant
    mapping (address => uint256) internal balances;
    
    // This keeps users from accidentally uploading the same NFT twice
    mapping (string => bool) internal usedTokenURIs;
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {}
    
    function mint(string calldata _tokenURI) public returns (uint256) {
        uint256 oldCount = count;
        count++;
        require(count > oldCount && bytes(_tokenURI).length > 0 && usedTokenURIs[_tokenURI] != true);

        owners[count] = msg.sender;
        balances[msg.sender]++;
        tokenURIs[count] = _tokenURI;
        usedTokenURIs[_tokenURI] = true;
        emit Transfer(address(0), msg.sender, count);
        return count;
    }
    
    function burn(uint256 _tokenId) public {
        address _owner = owners[_tokenId];
        require(
            _owner != address(0) && 
            (msg.sender == _owner || operators[_owner][msg.sender] || msg.sender == approveds[_tokenId])
        );
        owners[_tokenId] = address(0);
        balances[_owner]--;
        approveds[_tokenId] = address(0);
        burned++;
        emit Transfer(_owner, address(0), _tokenId);
    }

    function name() public pure returns (string memory) {
        return "NFTs 4 All";
    }

    function symbol() public pure returns (string memory) {
        return "";
    }
    
    function decimals() public pure returns (uint8) {
        return 0;
    }
    
    function totalSupply() public view returns (uint256) {
        return count - burned;
    }

    /**
     * @dev Returns a distinct Uniform Resource Identifier (URI) for a given asset. It Throws if
     * `_tokenId` is not a valid NFT. URIs are defined in RFC3986. The URI may point to a JSON file
     * that conforms to the "ERC721 Metadata JSON Schema".
     * @return URI of _tokenId.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        string memory _tokenURI = tokenURIs[_tokenId];
        require(bytes(_tokenURI).length != 0);
        return _tokenURI;
    }

    /**
     * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
     * considered invalid, and this function throws for queries about the zero address.
     * @param _owner Address for whom to query the balance.
     * @return Balance of _owner.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return balances[_owner];
    }

    /**
     * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
     * considered invalid, and queries about them do throw.
     * @param _tokenId The identifier for an NFT.
     * @return Address of _tokenId owner.
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address _owner = owners[_tokenId];
        require(_owner != address(0));
        return _owner;
    }

    /**
     * @dev Set or reaffirm the approved address for an NFT.
     * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
     * the current NFT owner, or an authorized operator of the current owner.
     * @param _approved The new approved NFT controller.
     * @param _tokenId The NFT to approve.
     */
    function approve(address _approved, uint256 _tokenId) public {
        address _owner = owners[_tokenId];
        require(_owner != address(0) && (msg.sender == _owner || operators[_owner][msg.sender]));
        approveds[_tokenId] = _approved;
        emit Approval(_owner, _approved, _tokenId);
    }
    
    /**
     * @dev Get the approved address for a single NFT.
     * @notice Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for.
     * @return Address that _tokenId is approved for.
     */
    function getApproved(uint256 _tokenId) public view returns (address) {
        address _owner = owners[_tokenId];
        require(_owner != address(0));
        address _approved = approveds[_tokenId];
        return _approved;
    }

    /**
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
     * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
     * address. Throws if `_tokenId` is not a valid NFT.
     * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
     * they may be permanently lost.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        address _owner = owners[_tokenId];
        require(
            _owner != address(0) && 
            (msg.sender == _owner || operators[_owner][msg.sender] || msg.sender == approveds[_tokenId]) &&
            _from == _owner && 
            _to != address(0)
        );
        owners[_tokenId] = _to;
        balances[_from]--;
        balances[_to]++;
        approveds[_tokenId] = address(0);
        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Transfers the ownership of an NFT from one address to another address.
     * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
     * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
     * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
     * function checks if `_to` is a smart contract (code size > 0). If so, it calls
     * `onERC721Received` on `_to` and throws if the return value is not
     * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     * @param _data Additional data with no specified format, sent in call to `_to`.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) public {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }
    
    /**
    * @dev Transfers the ownership of an NFT from one address to another address.
    * @notice This works identically to the other function with an extra data parameter, except this
    * function just sets data to ""
    * @param _from The current owner of the NFT.
    * @param _to The new owner.
    * @param _tokenId The NFT to transfer.
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) private {
        transferFrom(_from, _to, _tokenId);
        
        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            // Return value of a smart contract that can receive NFT.
            // Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
            require(retval == 0x150b7a02);
        }
    }

    /**
     * @dev Enables or disables approval for a third party ("operator") to manage all of
     * `msg.sender`'s assets. It also emits the ApprovalForAll event.
     * @notice The contract MUST allow multiple operators per owner.
     * @param _operator Address to add to the set of authorized operators.
     * @param _approved True if the operators is approved, false to revoke approval.
     */
    function setApprovalForAll(address _operator, bool _approved) public {
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    /**
     * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
     * @param _owner The address that owns the NFTs.
     * @param _operator The address that acts on behalf of the owner.
     * @return True if approved for all, false otherwise.
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operators[_owner][_operator];
    }
    
    /**
     * @dev Function to check which interfaces are suported by this contract.
     * @param _interfaceID Id of the interface.
     * @return True if _interfaceID is supported, false otherwise.
     */
    function supportsInterface(bytes4 _interfaceID) public pure returns (bool) {
        // 0x80ac58cd is ERC721 (the Non-Fungible Token Standard)
        // 0x01ffc9a7 is ERC165 (the Standard Interface Detection)
        return _interfaceID == 0x80ac58cd || _interfaceID == 0x01ffc9a7;
    }
    
    /**
    * @dev Returns whether the target address is a contract.
    * @param _addr Address to check.
    * @return addressCheck True if _addr is a contract, false if not.
    */
    function isContract(address _addr) private view returns (bool addressCheck) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(_addr) } // solhint-disable-line
        addressCheck = (codehash != 0x0 && codehash != accountHash);
    }

}

//transaction cost 1098930
//execution cost 784430