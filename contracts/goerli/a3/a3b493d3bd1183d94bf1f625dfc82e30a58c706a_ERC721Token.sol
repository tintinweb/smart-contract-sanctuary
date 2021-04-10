/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// SPDX-License-Identifier: MIT
// by William Hilton (https://github.com/wmhilton)
// written using remix.ethereum.org
// Changelog:
// v2 - reduce gas cost of minting even more
// v1 - initial release
pragma solidity >=0.8.3 <0.9.0;

/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver {
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/**
 * @title ERC721Token
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
    mapping (uint256 => uint256) internal tokenCIDs;
    mapping (uint256 => address) internal approveds;
    mapping (address => mapping (address => bool)) internal operators;
    
    
    string public name;
    string public symbol;

    /**
     * @dev Setup NFT name and symbol and optionally mint a batch
     */
    constructor(string memory _name, string memory _symbol, uint256[] memory _tokenCIDs) {
        name = _name;
        symbol = _symbol;
        
        for (uint256 i = 0; i < _tokenCIDs.length; i++) {
            mint(_tokenCIDs[i]);
        }
    }
    
    /**
     * @dev Mint a NFT
     * @param _tokenCID The IPFS CID, minus the first two bytes which for practical purposes
     * are the fixed values 0x12 0x20. (The tool that generates the IPFS CID should check that
     * the first two bytes are 0x12 0x20 and remove them before calling the mint function.)
     */
    function mint(uint256 _tokenCID) public {
        require(0 < ++count);

        owners[count] = msg.sender;
        tokenCIDs[count] = _tokenCID;
        emit Transfer(address(0), msg.sender, count);
    }
    
    /**
     * @dev Mint several NFTs at once
     * @param _tokenCIDs[] The IPFS CIDs
     */
    function mintMultiple(uint256[] calldata _tokenCIDs) public {
        for (uint256 i = 0; i < _tokenCIDs.length; i++) {
            mint(_tokenCIDs[i]);
        }
    }
    
    function burn(uint256 _tokenId) public {
        address _owner = owners[_tokenId];
        require(
            _owner != address(0) && 
            (msg.sender == _owner || operators[_owner][msg.sender] || msg.sender == approveds[_tokenId])
        );
        owners[_tokenId] = address(0);
        approveds[_tokenId] = address(0);
        tokenCIDs[_tokenId] = 0;
        burned++;
        emit Transfer(_owner, address(0), _tokenId);
    }
    
    /**
     * @dev For ERC-20 compatibility
     */
    function decimals() public pure returns (uint8) {
        return 0;
    }
    
    function totalSupply() public view returns (uint256) {
        return count - burned;
    }

    /**
     * @dev Returns a distinct Uniform Resource Identifier (URI) for a given asset. It Throws if
     * `_tokenId` is not a valid NFT.
     * @return URI of _tokenId.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        address _owner = owners[_tokenId];
        require(_owner != address(0));
        
        // Technically, the tokenURI CAN be bytes32 0x00... something probably hashes to that.
        uint256 _tokenCID = tokenCIDs[_tokenId];
        
        // Prepend 0x12 0x20, encode in base58, prepend the famous IPFS HTTPS Gateway
        return string(abi.encodePacked("https://ipfs.io/ipfs/", encode(abi.encodePacked(hex"1220", _tokenCID))));
    }

    /**
     * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
     * considered invalid, and this function throws for queries about the zero address.
     * @param _owner Address for whom to query the balance.
     * @return Balance of _owner.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        uint256 _balance = 0;
        for (uint256 _tokenId = count; _tokenId > 0; _tokenId--) {
            if (owners[_tokenId] == msg.sender) {
                _balance++;
            }
        }
        return _balance;
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
    
    /**
     * @dev Converts bytes to base58 encoded string. Used to compute the IPFS tokenURI on-the-fly.
     */
    bytes constant ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    function encode(bytes memory input) private pure returns (string memory) {
        // First we must count the leading zeros
        uint8 leading_zeros = 0;
        for (uint8 i = 0; i < input.length; i++) {
            if (input[i] == 0) {
                leading_zeros++;
            } else {
                break;
            }
        }
        
        // Allocate enough storage for the base58 digits.
        uint8 length = uint8((input.length - leading_zeros) * 138 / 100 + 1); // log(256) / log(58), rounded up.
        uint8[] memory b58_digits = new uint8[](length); 

        // Now we convert the base256 digits to base58 digits via long division
        b58_digits[0] = 0;
        uint8 digitlength = 1;
        for (uint8 i = leading_zeros; i < input.length; i++) {
            uint32 carry = uint8(input[i]);
            for (uint8 j = 0; j < digitlength; j++) {
                carry += uint32(b58_digits[j]) * 256;
                b58_digits[j] = uint8(carry % 58);
                carry /= 58;
            }
            
            while (carry > 0) {
                b58_digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry /= 58;
            }
        }
        
        // Handle an edge case: all zeros input
        if (digitlength == 1 && b58_digits[0] == 0) {
            digitlength = 0;
        }
        
        // Leading zero bytes are converted to '1';
        bytes memory b58_encoding = new bytes(leading_zeros + digitlength);
        for (uint8 i = 0; i < leading_zeros; i++) {
            b58_encoding[i] = '1';
        }
        // The rest of the digits are encoded using the base58 alphabet
        for (uint8 j = 0; j < digitlength; j++) {
            b58_encoding[j + leading_zeros] = ALPHABET[uint8(b58_digits[digitlength - j - 1])];
        }
        return string(b58_encoding);
    }

}

//transaction cost 1563822
//execution cost 1085490