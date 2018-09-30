pragma solidity ^0.4.24;

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f
interface ERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string);
}


/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd
interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

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
    ///  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
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

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`&#39;s assets.
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
contract ERC721Receiver {
    /**
    * @notice Handle the receipt of an NFT
    * @dev The ERC721 smart contract calls this function on the recipient
    *  after a `safetransfer`. This function MAY throw to revert and reject the
    *  transfer. This function MUST use 50,000 gas or less. Return of other
    *  than the magic value MUST result in the transaction being reverted.
    *  Note: the contract address is always the message sender.
    * @param _from The sending address
    * @param _tokenId The NFT identifier which is being transfered
    * @param _data Additional data with no specified format
    * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    */
    function onERC721Received(address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

/**
 * Owned contract
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    /**
     * Constructor
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Only the owner of contract
     */ 
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    /**
     * @dev transfer the ownership to other
     *      - Only the owner can operate
     */ 
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    /** 
     * @dev Accept the ownership from last owner
     */ 
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract TRNData is Owned {
    TripioRoomNightData dataSource;
    /**
     * Only the valid vendor and the vendor is valid
     */ 
    modifier onlyVendor {
        uint256 vendorId = dataSource.vendorIds(msg.sender);
        require(vendorId > 0);
        (,,,bool valid) = dataSource.getVendor(vendorId);
        require(valid);
        _;
    }

    /**
     * The vendor is valid
     */
    modifier vendorValid(address _vendor) {
        uint256 vendorId = dataSource.vendorIds(_vendor);
        require(vendorId > 0);
        (,,,bool valid) = dataSource.getVendor(vendorId);
        require(valid);
        _;
    }

    /**
     * The vendorId is valid
     */
    modifier vendorIdValid(uint256 _vendorId) {
        (,,,bool valid) = dataSource.getVendor(_vendorId);
        require(valid);
        _;
    }

    /**
     * Rate plan exist.
     */
    modifier ratePlanExist(uint256 _vendorId, uint256 _rpid) {
        (,,,bool valid) = dataSource.getVendor(_vendorId);
        require(valid);
        require(dataSource.ratePlanIsExist(_vendorId, _rpid));
        _;
    }
    
    /**
     * Token is valid
     */
    modifier validToken(uint256 _tokenId) {
        require(_tokenId > 0);
        require(dataSource.roomNightIndexToOwner(_tokenId) != address(0));
        _;
    }

    /**
     * Tokens are valid
     */
    modifier validTokenInBatch(uint256[] _tokenIds) {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] > 0);
            require(dataSource.roomNightIndexToOwner(_tokenIds[i]) != address(0));
        }
        _;
    }

    /**
     * Whether the `_tokenId` can be transfered
     */
    modifier canTransfer(uint256 _tokenId) {
        address owner = dataSource.roomNightIndexToOwner(_tokenId);
        bool isOwner = (msg.sender == owner);
        bool isApproval = (msg.sender == dataSource.roomNightApprovals(_tokenId));
        bool isOperator = (dataSource.operatorApprovals(owner, msg.sender));
        require(isOwner || isApproval || isOperator);
        _;
    }

    /**
     * Whether the `_tokenIds` can be transfered
     */
    modifier canTransferInBatch(uint256[] _tokenIds) {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            address owner = dataSource.roomNightIndexToOwner(_tokenIds[i]);
            bool isOwner = (msg.sender == owner);
            bool isApproval = (msg.sender == dataSource.roomNightApprovals(_tokenIds[i]));
            bool isOperator = (dataSource.operatorApprovals(owner, msg.sender));
            require(isOwner || isApproval || isOperator);
        }
        _;
    }


    /**
     * Whether the `_tokenId` can be operated by `msg.sender`
     */
    modifier canOperate(uint256 _tokenId) {
        address owner = dataSource.roomNightIndexToOwner(_tokenId);
        bool isOwner = (msg.sender == owner);
        bool isOperator = (dataSource.operatorApprovals(owner, msg.sender));
        require(isOwner || isOperator);
        _;
    }

    /**
     * Whether the `_date` is valid(no hours, no seconds)
     */
    modifier validDate(uint256 _date) {
        require(_date > 0);
        require(dateIsLegal(_date));
        _;
    }

    /**
     * Whether the `_dates` are valid(no hours, no seconds)
     */
    modifier validDates(uint256[] _dates) {
        for(uint256 i = 0;i < _dates.length; i++) {
            require(_dates[i] > 0);
            require(dateIsLegal(_dates[i]));
        }
        _;
    }

    function dateIsLegal(uint256 _date) pure private returns(bool) {
        uint256 year = _date / 10000;
        uint256 mon = _date / 100 - year * 100;
        uint256 day = _date - mon * 100 - year * 10000;
        
        if(year < 1970 || mon <= 0 || mon > 12 || day <= 0 || day > 31)
            return false;

        if(4 == mon || 6 == mon || 9 == mon || 11 == mon){
            if (day == 31) {
                return false;
            }
        }
        if(((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0)) {
            if(2 == mon && day > 29) {
                return false;
            }
        }else {
            if(2 == mon && day > 28){
                return false;
            }
        }
        return true;
    }
    /**
     * Constructor
     */
    constructor() public {

    }
}

contract TRNOwners is TRNData {
    /**
     * Constructor
     */
    constructor() public {

    }

    /**
     * Add room night token to `_owner`&#39;s account(from the header)
     */
    function _pushRoomNight(address _owner, uint256 _rnid, bool _isVendor) internal {
        require(_owner != address(0));
        require(_rnid != 0);
        if (_isVendor) {
            dataSource.pushOrderOfVendor(_owner, _rnid, false);
        } else {
            dataSource.pushOrderOfOwner(_owner, _rnid, false);
        }
    }

    /**
     * Remove room night token from `_owner`&#39;s account
     */
    function _removeRoomNight(address _owner, uint256 _rnid) internal {
        dataSource.removeOrderOfOwner(_owner, _rnid);
    }

    /**
     * @dev Returns all the room nights of the `msg.sender`(Customer)
     * @param _from The begin of room nights Id
     * @param _limit The total room nights 
     * @param _isVendor Is Vendor
     * @return Room nights of the `msg.sender` and the next vernier
     */
    function roomNightsOfOwner(uint256 _from, uint256 _limit, bool _isVendor) 
        external
        view 
        returns(uint256[], uint256) {
        if(_isVendor) {
            return dataSource.getOrdersOfVendor(msg.sender, _from, _limit, true);
        }else {
            return dataSource.getOrdersOfOwner(msg.sender, _from, _limit, true);
        }
    }

    /**
     * @dev Returns the room night infomation in detail
     * @param _rnid Room night id
     * @return Room night infomation in detail
     */
    function roomNight(uint256 _rnid) 
        external 
        view 
        returns(uint256 _vendorId,uint256 _rpid,uint256 _token,uint256 _price,uint256 _timestamp,uint256 _date,bytes32 _ipfs, string _name) {
        (_vendorId, _rpid, _token, _price, _timestamp, _date, _ipfs) = dataSource.roomnights(_rnid);
        (_name,,) = dataSource.getRatePlan(_vendorId, _rpid);
    }
}

library IPFSLib {
    bytes constant ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
    bytes constant HEX = "0123456789abcdef";

    /**
     * @dev Base58 encoding
     * @param _source Bytes data
     * @return Encoded bytes data
     */
    function base58Address(bytes _source) internal pure returns (bytes) {
        uint8[] memory digits = new uint8[](_source.length * 136/100 + 1);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint i = 0; i < _source.length; ++i) {
            uint carry = uint8(_source[i]);
            for (uint j = 0; j<digitlength; ++j) {
                carry += uint(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }
            
            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        return toAlphabet(reverse(truncate(digits, digitlength)));
    }

    /**
     * @dev Hex encoding, convert bytes32 data to hex string
     * @param _source Bytes32 data
     * @return hex string bytes
     */
    function hexAddress(bytes32 _source) internal pure returns(bytes) {
        uint256 value = uint256(_source);
        bytes memory result = "0000000000000000000000000000000000000000000000000000000000000000";
        uint8 index = 0;
        while(value > 0) {
            result[index] = HEX[value & 0xf];
            index++;
            value = value>>4;
        }
        bytes memory ipfsBytes = reverseBytes(result);
        return ipfsBytes;
    }

    /**
     * @dev Truncate `_array` by `_length`
     * @param _array The source array
     * @param _length The target length of the `_array`
     * @return The truncated array 
     */
    function truncate(uint8[] _array, uint8 _length) internal pure returns (uint8[]) {
        uint8[] memory output = new uint8[](_length);
        for (uint i = 0; i < _length; i++) {
            output[i] = _array[i];
        }
        return output;
    }
    
    /**
     * @dev Reverse `_input` array 
     * @param _input The source array 
     * @return The reversed array 
     */
    function reverse(uint8[] _input) internal pure returns (uint8[]) {
        uint8[] memory output = new uint8[](_input.length);
        for (uint i = 0; i < _input.length; i++) {
            output[i] = _input[_input.length - 1 - i];
        }
        return output;
    }

    /**
     * @dev Reverse `_input` bytes
     * @param _input The source bytes
     * @return The reversed bytes
     */
    function reverseBytes(bytes _input) private pure returns (bytes) {
        bytes memory output = new bytes(_input.length);
        for (uint8 i = 0; i < _input.length; i++) {
            output[i] = _input[_input.length-1-i];
        }
        return output;
    }
    
    /**
     * @dev Convert the indices to alphabet
     * @param _indices The indices of alphabet
     * @return The alphabets
     */
    function toAlphabet(uint8[] _indices) internal pure returns (bytes) {
        bytes memory output = new bytes(_indices.length);
        for (uint i = 0; i < _indices.length; i++) {
            output[i] = ALPHABET[_indices[i]];
        }
        return output;
    }

    /**
     * @dev Convert bytes32 to bytes
     * @param _input The source bytes32
     * @return The bytes
     */
    function toBytes(bytes32 _input) internal pure returns (bytes) {
        bytes memory output = new bytes(32);
        for (uint8 i = 0; i < 32; i++) {
            output[i] = _input[i];
        }
        return output;
    }

    /**
     * @dev Concat two bytes to one
     * @param _byteArray The first bytes
     * @param _byteArray2 The second bytes
     * @return The concated bytes
     */
    function concat(bytes _byteArray, bytes _byteArray2) internal pure returns (bytes) {
        bytes memory returnArray = new bytes(_byteArray.length + _byteArray2.length);
        for (uint16 i = 0; i < _byteArray.length; i++) {
            returnArray[i] = _byteArray[i];
        }
        for (i; i < (_byteArray.length + _byteArray2.length); i++) {
            returnArray[i] = _byteArray2[i - _byteArray.length];
        }
        return returnArray;
    }
}

contract TRNAsset is TRNData, ERC721Metadata {
    using IPFSLib for bytes;
    using IPFSLib for bytes32;

    /**
     * Constructor
     */
    constructor() public {
        
    }

    /**
     * @dev Descriptive name for Tripio&#39;s Room Night Token in this contract
     * @return The name of the contract
     */
    function name() external pure returns (string _name) {
        return "Tripio Room Night";
    }

    /**
     * @dev Abbreviated name for Tripio&#39;s Room Night Token in this contract
     * @return The simple name of the contract
     */
    function symbol() external pure returns (string _symbol) {
        return "TRN";
    }

    /**
     * @dev If `_tokenId` is not valid trows an exception otherwise return a URI which point to a JSON file like:
     *      {
     *       "name": "Identifies the asset to which this NFT represents",
     *       "description": "Describes the asset to which this NFT represents",
     *       "image": "A URI pointing to a resource with mime type image/* representing the asset to which this NFT represents. Consider making any images at a width between 320 and 1080 pixels and aspect ratio between 1.91:1 and 4:5 inclusive."
     *      }
     * @param _tokenId The RoomNight digital token
     * @return The digital token asset uri
     */
    function tokenURI(uint256 _tokenId) 
        external 
        view 
        validToken(_tokenId) 
        returns (string) { 
        bytes memory prefix = new bytes(2);
        prefix[0] = 0x12;
        prefix[1] = 0x20;
        (,,,,,,bytes32 ipfs) = dataSource.roomnights(_tokenId);
        bytes memory value = prefix.concat(ipfs.toBytes());
        bytes memory ipfsBytes = value.base58Address();
        bytes memory tokenBaseURIBytes = bytes(dataSource.tokenBaseURI());
        return string(tokenBaseURIBytes.concat(ipfsBytes));
    }
}

contract TRNOwnership is TRNOwners, ERC721 {
    /**
     * Constructor
     */
    constructor() public {

    }

    /**
     * This emits when ownership of any TRN changes by any mechanism.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    /**
     * This emits when the approved address for an RTN is changed or reaffirmed.
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    /**
     * This emits when an operator is enabled or disabled for an owner.
     * The operator can manage all RTNs of the owner.
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @dev Transfer the `_tokenId` to `_to` directly
     * @param _tokenId The room night token
     * @param _to The target owner
     */
    function _transfer(uint256 _tokenId, address _to) private {
        // Find the FROM address
        address from = dataSource.roomNightIndexToOwner(_tokenId);

        // Remove room night from the `from`
        _removeRoomNight(from, _tokenId);

        // Add room night to the `_to`
        _pushRoomNight(_to, _tokenId, false);

        // Change the owner of `_tokenId`
        // Remove approval of `_tokenId`
        dataSource.transferTokenTo(_tokenId, _to);

        // Emit Transfer event
        emit Transfer(from, _to, _tokenId);
    }

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data)
        private
        validToken(_tokenId)
        canTransfer(_tokenId) {
        // The token&#39;s owner is equal to `_from`
        address owner = dataSource.roomNightIndexToOwner(_tokenId);
        require(owner == _from);

        // Avoid `_to` is equal to address(0)
        require(_to != address(0));

        _transfer(_tokenId, _to);

        uint256 codeSize;
        assembly { codeSize := extcodesize(_to) }
        if (codeSize == 0) {
            return;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
        require (retval == dataSource.ERC721_RECEIVED());
    }

    /**
     * @dev Count all TRNs assigned to an owner.
     *      Throw when `_owner` is equal to address(0)
     * @param _owner An address for whom to query the balance.
     * @return The number of TRNs owned by `_owner`.
     */
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return dataSource.balanceOf(_owner);
    }

    /**
     * @dev Find the owner of an TRN
     *      Throw unless `_tokenId` more than zero
     * @param _tokenId The identifier for an TRN
     * @return The address of the owner of the TRN
     */
    function ownerOf(uint256 _tokenId) external view returns (address) {
        require(_tokenId > 0);
        return dataSource.roomNightIndexToOwner(_tokenId);
    }

    /**
     * @dev Transfers the ownership of an TRN from one address to another address.
     *      Throws unless `msg.sender` is the current owner or an approved address for this TRN.
     *      Throws if `_tokenId` is not a valid TRN. When transfer is complete, this function checks if 
     *      `_to` is a smart contract (code size > 0). If so, it calls `onERC721Received` on `_to` and 
     * throws if the return value is not `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
     * @param _from The current owner of the TRN
     * @param _to The new owner
     * @param _tokenId The TRN to transfer
     * @param _data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external payable {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Same like safeTransferFrom with an extra data parameter, except this function just sets data to ""(empty)
     * @param _from The current owner of the TRN
     * @param _to The new owner
     * @param _tokenId The TRN to transfer
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev Transfers the ownership of an TRN from one address to another address.
     *      Throws unless `msg.sender` is the current owner or an approved address for this TRN.
     *      Throws if `_tokenId` is not a valid TRN.
     * @param _from The current owner of the TRN
     * @param _to The new owner
     * @param _tokenId The TRN to transfer
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) 
        external 
        payable
        validToken(_tokenId)
        canTransfer(_tokenId) {
        // The token&#39;s owner is equal to `_from`
        address owner = dataSource.roomNightIndexToOwner(_tokenId);
        require(owner == _from);

        // Avoid `_to` is equal to address(0)
        require(_to != address(0));

        _transfer(_tokenId, _to);
    }

    /**
     * @dev Transfers the ownership of TRNs from one address to another address.
     *      Throws unless `msg.sender` is the current owner or an approved address for this TRN.
     *      Throws if `_tokenIds` are not valid TRNs.
     * @param _from The current owner of the TRN
     * @param _to The new owner
     * @param _tokenIds The TRNs to transfer
     */
    function transferFromInBatch(address _from, address _to, uint256[] _tokenIds) 
        external
        payable
        validTokenInBatch(_tokenIds)
        canTransferInBatch(_tokenIds) {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            // The token&#39;s owner is equal to `_from`
            address owner = dataSource.roomNightIndexToOwner(_tokenIds[i]);
            require(owner == _from);

            // Avoid `_to` is equal to address(0)
            require(_to != address(0));

            _transfer(_tokenIds[i], _to);
        }
    }

    /**
     * @dev Set or reaffirm the approved address for an TRN.
     *      Throws unless `msg.sender` is the current TRN owner, or an authorized
     * @param _approved The new approved TRN controller
     * @param _tokenId The TRN to approve
     */
    function approve(address _approved, uint256 _tokenId) 
        external 
        payable 
        validToken(_tokenId)
        canOperate(_tokenId) {
        address owner = dataSource.roomNightIndexToOwner(_tokenId);
        
        dataSource.approveTokenTo(_tokenId, _approved);
        emit Approval(owner, _approved, _tokenId);
    }

    /**
     * @dev Enable or disable approval for a third party ("operator") to manage 
     *      all of `msg.sender`&#39;s assets.
     *      Emits the ApprovalForAll event. 
     * @param _operator Address to add to the set of authorized operators.
     * @param _approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != address(0));
        dataSource.approveOperatorTo(_operator, msg.sender, _approved);
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Get the approved address for a single TRN.
     *      Throws if `_tokenId` is not a valid TRN.
     * @param _tokenId The TRN to find the approved address for
     * @return The approved address for this TRN, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId) 
        external 
        view 
        validToken(_tokenId)
        returns (address) {
        return dataSource.roomNightApprovals(_tokenId);
    }

    /**
     * @dev Query if an address is an authorized operator for another address.
     * @param _owner The address that owns The TRNs
     * @param _operator The address that acts on behalf of the owner
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return dataSource.operatorApprovals(_owner, _operator);
    }
}


contract TRNSupportsInterface is TRNData, ERC165 {
    /**
     * Constructor
     */
    constructor() public {

    }

    /**
     * @dev Query if a contract implements an interface
     * @param interfaceID The interface identifier, as specified in ERC-165
     * @return true if the contract implements `interfaceID` 
     * and `interfaceID` is not 0xffffffff, false otherwise
     */
    function supportsInterface(bytes4 interfaceID) 
        external 
        view 
        returns (bool) {
        return ((interfaceID == dataSource.interfaceSignature_ERC165()) ||
        (interfaceID == dataSource.interfaceSignature_ERC721Metadata()) ||
        (interfaceID == dataSource.interfaceSignature_ERC721())) &&
        (interfaceID != 0xffffffff);
    }
}
/**
 * This utility library was forked from https://github.com/o0ragman0o/LibCLL
 */
library LinkedListLib {

    uint256 constant NULL = 0;
    uint256 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;

    struct LinkedList {
        mapping (uint256 => mapping (bool => uint256)) list;
        uint256 length;
        uint256 index;
    }

    /**
     * @dev returns true if the list exists
     * @param self stored linked list from contract
     */
    function listExists(LinkedList storage self)
        internal
        view returns (bool) {
        return self.length > 0;
    }

    /**
     * @dev returns true if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     */
    function nodeExists(LinkedList storage self, uint256 _node)
        internal
        view returns (bool) {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     */ 
    function sizeOf(LinkedList storage self) 
        internal 
        view 
        returns (uint256 numElements) {
        return self.length;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     */
    function getNode(LinkedList storage self, uint256 _node)
        public 
        view 
        returns (bool, uint256, uint256) {
        if (!nodeExists(self,_node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     */
    function getAdjacent(LinkedList storage self, uint256 _node, bool _direction)
        public 
        view 
        returns (bool, uint256) {
        if (!nodeExists(self,_node)) {
            return (false,0);
        } else {
            return (true,self.list[_node][_direction]);
        }
    }

    /**
     * @dev Can be used before `insert` to build an ordered list
     * @param self stored linked list from contract
     * @param _node an existing node to search from, e.g. HEAD.
     * @param _value value to seek
     * @param _direction direction to seek in
     * @return next first node beyond &#39;_node&#39; in direction `_direction`
     */
    function getSortedSpot(LinkedList storage self, uint256 _node, uint256 _value, bool _direction)
        public 
        view 
        returns (uint256) {
        if (sizeOf(self) == 0) { 
            return 0; 
        }
        require((_node == 0) || nodeExists(self,_node));
        bool exists;
        uint256 next;
        (exists,next) = getAdjacent(self, _node, _direction);
        while  ((next != 0) && (_value != next) && ((_value < next) != _direction)) next = self.list[next][_direction];
        return next;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node first node for linking
     * @param _link  node to link to in the _direction
     */
    function createLink(LinkedList storage self, uint256 _node, uint256 _link, bool _direction) 
        private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     */
    function insert(LinkedList storage self, uint256 _node, uint256 _new, bool _direction) 
        internal 
        returns (bool) {
        if(!nodeExists(self,_new) && nodeExists(self,_node)) {
            uint256 c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);
            self.length++;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     */
    function remove(LinkedList storage self, uint256 _node) 
        internal 
        returns (uint256) {
        if ((_node == NULL) || (!nodeExists(self,_node))) { 
            return 0; 
        }
        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        self.length--;
        return _node;
    }

    /**
     * @dev pushes an enrty to the head of the linked list
     * @param self stored linked list from contract
     * @param _index The node Id
     * @param _direction push to the head (NEXT) or tail (PREV)
     */
    function add(LinkedList storage self, uint256 _index, bool _direction) 
        internal 
        returns (uint256) {
        insert(self, HEAD, _index, _direction);
        return self.index;
    }

    /**
     * @dev pushes an enrty to the head of the linked list
     * @param self stored linked list from contract
     * @param _direction push to the head (NEXT) or tail (PREV)
     */
    function push(LinkedList storage self, bool _direction) 
        internal 
        returns (uint256) {
        self.index++;
        insert(self, HEAD, self.index, _direction);
        return self.index;
    }

    /**
     * @dev pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (NEXT) or the tail (PREV)
     */
    function pop(LinkedList storage self, bool _direction) 
        internal 
        returns (uint256) {
        bool exists;
        uint256 adj;
        (exists,adj) = getAdjacent(self, HEAD, _direction);
        return remove(self, adj);
    }
}

contract TripioToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    function transfer(address _to, uint256 _value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
}

contract TripioRoomNightData is Owned {
    using LinkedListLib for LinkedListLib.LinkedList;
    // Interface signature of erc165.
    // bytes4(keccak256("supportsInterface(bytes4)"))
    bytes4 constant public interfaceSignature_ERC165 = 0x01ffc9a7;

    // Interface signature of erc721 metadata.
    // bytes4(keccak256("name()")) ^ bytes4(keccak256("symbol()")) ^ bytes4(keccak256("tokenURI(uint256)"));
    bytes4 constant public interfaceSignature_ERC721Metadata = 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd;
        
    // Interface signature of erc721.
    // bytes4(keccak256("balanceOf(address)")) ^
    // bytes4(keccak256("ownerOf(uint256)")) ^
    // bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)")) ^
    // bytes4(keccak256("safeTransferFrom(address,address,uint256)")) ^
    // bytes4(keccak256("transferFrom(address,address,uint256)")) ^
    // bytes4(keccak256("approve(address,uint256)")) ^
    // bytes4(keccak256("setApprovalForAll(address,bool)")) ^
    // bytes4(keccak256("getApproved(uint256)")) ^
    // bytes4(keccak256("isApprovedForAll(address,address)"));
    bytes4 constant public interfaceSignature_ERC721 = 0x70a08231 ^ 0x6352211e ^ 0xb88d4fde ^ 0x42842e0e ^ 0x23b872dd ^ 0x095ea7b3 ^ 0xa22cb465 ^ 0x081812fc ^ 0xe985e9c5;

    // Base URI of token asset
    string public tokenBaseURI;

    // Authorized contracts
    struct AuthorizedContract {
        string name;
        address acontract;
    }
    mapping (address=>uint256) public authorizedContractIds;
    mapping (uint256 => AuthorizedContract) public authorizedContracts;
    LinkedListLib.LinkedList public authorizedContractList = LinkedListLib.LinkedList(0, 0);

    // Rate plan prices
    struct Price {
        uint16 inventory;       // Rate plan inventory
        bool init;              // Whether the price is initied
        mapping (uint256 => uint256) tokens;
    }

    // Vendor hotel RPs
    struct RatePlan {
        string name;            // Name of rate plan.
        uint256 timestamp;      // Create timestamp.
        bytes32 ipfs;           // The address of rate plan detail on IPFS.
        Price basePrice;        // The base price of rate plan
        mapping (uint256 => Price) prices;   // date -> Price
    }

    // Vendors
    struct Vendor {
        string name;            // Name of vendor.
        address vendor;         // Address of vendor.
        uint256 timestamp;      // Create timestamp.
        bool valid;             // Whether the vendor is valid(default is true)
        LinkedListLib.LinkedList ratePlanList;
        mapping (uint256=>RatePlan) ratePlans;
    }
    mapping (address => uint256) public vendorIds;
    mapping (uint256 => Vendor) vendors;
    LinkedListLib.LinkedList public vendorList = LinkedListLib.LinkedList(0, 0);

    // Supported digital currencies
    mapping (uint256 => address) public tokenIndexToAddress;
    LinkedListLib.LinkedList public tokenList = LinkedListLib.LinkedList(0, 0);

    // RoomNight tokens
    struct RoomNight {
        uint256 vendorId;
        uint256 rpid;
        uint256 token;          // The digital currency token 
        uint256 price;          // The digital currency price
        uint256 timestamp;      // Create timestamp.
        uint256 date;           // The checkin date
        bytes32 ipfs;           // The address of rate plan detail on IPFS.
    }
    RoomNight[] public roomnights;
    // rnid -> owner
    mapping (uint256 => address) public roomNightIndexToOwner;

    // Owner Account
    mapping (address => LinkedListLib.LinkedList) public roomNightOwners;

    // Vendor Account
    mapping (address => LinkedListLib.LinkedList) public roomNightVendors;

    // The authorized address for each TRN
    mapping (uint256 => address) public roomNightApprovals;

    // The authorized operators for each address
    mapping (address => mapping (address => bool)) public operatorApprovals;

    // The applications of room night redund
    mapping (address => mapping (uint256 => bool)) public refundApplications;

    // The signature of `onERC721Received(address,uint256,bytes)`
    // bytes4(keccak256("onERC721Received(address,uint256,bytes)"));
    bytes4 constant public ERC721_RECEIVED = 0xf0b9e5ba;

    /**
     * This emits when contract authorized
     */
    event ContractAuthorized(address _contract);

    /**
     * This emits when contract deauthorized
     */
    event ContractDeauthorized(address _contract);

    /**
     * The contract is valid
     */
    modifier authorizedContractValid(address _contract) {
        require(authorizedContractIds[_contract] > 0);
        _;
    }

    /**
     * The contract is valid
     */
    modifier authorizedContractIdValid(uint256 _cid) {
        require(authorizedContractList.nodeExists(_cid));
        _;
    }

    /**
     * Only the owner or authorized contract is valid
     */
    modifier onlyOwnerOrAuthorizedContract {
        require(msg.sender == owner || authorizedContractIds[msg.sender] > 0);
        _;
    }

    /**
     * Constructor
     */
    constructor() public {
        // Add one invalid RoomNight, avoid subscript 0
        roomnights.push(RoomNight(0, 0, 0, 0, 0, 0, 0));
    }

    /**
     * @dev Returns the node list and next node as a tuple
     * @param self stored linked list from contract
     * @param _node the begin id of the node to get
     * @param _limit the total nodes of one page
     * @param _direction direction to step in
     */
    function getNodes(LinkedListLib.LinkedList storage self, uint256 _node, uint256 _limit, bool _direction) 
        private
        view 
        returns (uint256[], uint256) {
        bool exists;
        uint256 i = 0;
        uint256 ei = 0;
        uint256 index = 0;
        uint256 count = _limit;
        if(count > self.length) {
            count = self.length;
        }
        (exists, i) = self.getAdjacent(_node, _direction);
        if(!exists || count == 0) {
            return (new uint256[](0), 0);
        }else {
            uint256[] memory temp = new uint256[](count);
            if(_node != 0) {
                index++;
                temp[0] = _node;
            }
            while (i != 0 && index < count) {
                temp[index] = i;
                (exists,i) = self.getAdjacent(i, _direction);
                index++;
            }
            ei = i;
            if(index < count) {
                uint256[] memory result = new uint256[](index);
                for(i = 0; i < index; i++) {
                    result[i] = temp[i];
                }
                return (result, ei);
            }else {
                return (temp, ei);
            }
        }
    }

    /**
     * @dev Authorize `_contract` to execute this contract&#39;s funs
     * @param _contract The contract address
     * @param _name The contract name
     */
    function authorizeContract(address _contract, string _name) 
        public 
        onlyOwner 
        returns(bool) {
        uint256 codeSize;
        assembly { codeSize := extcodesize(_contract) }
        require(codeSize != 0);
        // Not exists
        require(authorizedContractIds[_contract] == 0);

        // Add
        uint256 id = authorizedContractList.push(false);
        authorizedContractIds[_contract] = id;
        authorizedContracts[id] = AuthorizedContract(_name, _contract);

        // Event
        emit ContractAuthorized(_contract);
        return true;
    }

    /**
     * @dev Deauthorized `_contract` by address
     * @param _contract The contract address
     */
    function deauthorizeContract(address _contract) 
        public 
        onlyOwner
        authorizedContractValid(_contract)
        returns(bool) {
        uint256 id = authorizedContractIds[_contract];
        authorizedContractList.remove(id);
        authorizedContractIds[_contract] = 0;
        delete authorizedContracts[id];
        
        // Event 
        emit ContractDeauthorized(_contract);
        return true;
    }

    /**
     * @dev Deauthorized `_contract` by contract id
     * @param _cid The contract id
     */
    function deauthorizeContractById(uint256 _cid) 
        public
        onlyOwner
        authorizedContractIdValid(_cid)
        returns(bool) {
        address acontract = authorizedContracts[_cid].acontract;
        authorizedContractList.remove(_cid);
        authorizedContractIds[acontract] = 0;
        delete authorizedContracts[_cid];

        // Event 
        emit ContractDeauthorized(acontract);
        return true;
    }

    /**
     * @dev Get authorize contract ids by page
     * @param _from The begin authorize contract id
     * @param _limit How many authorize contract ids one page
     * @return The authorize contract ids and the next authorize contract id as tuple, the next page not exists when next eq 0
     */
    function getAuthorizeContractIds(uint256 _from, uint256 _limit) 
        external 
        view 
        returns(uint256[], uint256){
        return getNodes(authorizedContractList, _from, _limit, true);
    }

    /**
     * @dev Get authorize contract by id
     * @param _cid Then authorize contract id
     * @return The authorize contract info(_name, _acontract)
     */
    function getAuthorizeContract(uint256 _cid) 
        external 
        view 
        returns(string _name, address _acontract) {
        AuthorizedContract memory acontract = authorizedContracts[_cid]; 
        _name = acontract.name;
        _acontract = acontract.acontract;
    }

    /*************************************** GET ***************************************/

    /**
     * @dev Get the rate plan by `_vendorId` and `_rpid`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     */
    function getRatePlan(uint256 _vendorId, uint256 _rpid) 
        public 
        view 
        returns (string _name, uint256 _timestamp, bytes32 _ipfs) {
        _name = vendors[_vendorId].ratePlans[_rpid].name;
        _timestamp = vendors[_vendorId].ratePlans[_rpid].timestamp;
        _ipfs = vendors[_vendorId].ratePlans[_rpid].ipfs;
    }

    /**
     * @dev Get the rate plan price by `_vendorId`, `_rpid`, `_date` and `_tokenId`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _tokenId The digital token id
     * @return The price info(inventory, init, price)
     */
    function getPrice(uint256 _vendorId, uint256 _rpid, uint256 _date, uint256 _tokenId) 
        public
        view 
        returns(uint16 _inventory, bool _init, uint256 _price) {
        _inventory = vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory;
        _init = vendors[_vendorId].ratePlans[_rpid].prices[_date].init;
        _price = vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId];
        if(!_init) {
            // Get the base price
            _inventory = vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
            _price = vendors[_vendorId].ratePlans[_rpid].basePrice.tokens[_tokenId];
            _init = vendors[_vendorId].ratePlans[_rpid].basePrice.init;
        }
    }

    /**
     * @dev Get the rate plan prices by `_vendorId`, `_rpid`, `_dates` and `_tokenId`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _dates The dates desc ([20180723,20180724,20180725])
     * @param _tokenId The digital token id
     * @return The price info(inventory, init, price)
     */
    function getPrices(uint256 _vendorId, uint256 _rpid, uint256[] _dates, uint256 _tokenId) 
        public
        view 
        returns(uint16[] _inventories, uint256[] _prices) {
        uint16[] memory inventories = new uint16[](_dates.length);
        uint256[] memory prices = new uint256[](_dates.length);
        uint256 date;
        for(uint256 i = 0; i < _dates.length; i++) {
            date = _dates[i];
            uint16 inventory = vendors[_vendorId].ratePlans[_rpid].prices[date].inventory;
            bool init = vendors[_vendorId].ratePlans[_rpid].prices[date].init;
            uint256 price = vendors[_vendorId].ratePlans[_rpid].prices[date].tokens[_tokenId];
            if(!init) {
                // Get the base price
                inventory = vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
                price = vendors[_vendorId].ratePlans[_rpid].basePrice.tokens[_tokenId];
                init = vendors[_vendorId].ratePlans[_rpid].basePrice.init;
            }
            inventories[i] = inventory;
            prices[i] = price;
        }
        return (inventories, prices);
    }

    /**
     * @dev Get the inventory by  by `_vendorId`, `_rpid` and `_date`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @return The inventory info(inventory, init)
     */
    function getInventory(uint256 _vendorId, uint256 _rpid, uint256 _date) 
        public
        view 
        returns(uint16 _inventory, bool _init) {
        _inventory = vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory;
        _init = vendors[_vendorId].ratePlans[_rpid].prices[_date].init;
        if(!_init) {
            // Get the base price
            _inventory = vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
        }
    }

    /**
     * @dev Whether the rate plan is exist
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @return If the rate plan of the vendor is exist returns true otherwise return false
     */
    function ratePlanIsExist(uint256 _vendorId, uint256 _rpid) 
        public 
        view 
        returns (bool) {
        return vendors[_vendorId].ratePlanList.nodeExists(_rpid);
    }

    /**
     * @dev Get orders of owner by page
     * @param _owner The owner address
     * @param _from The begin id of the node to get
     * @param _limit The total nodes of one page
     * @param _direction Direction to step in
     * @return The order ids and the next id
     */
    function getOrdersOfOwner(address _owner, uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns (uint256[], uint256) {
        return getNodes(roomNightOwners[_owner], _from, _limit, _direction);
    }

    /**
     * @dev Get orders of vendor by page
     * @param _owner The vendor address
     * @param _from The begin id of the node to get
     * @param _limit The total nodes of on page
     * @param _direction Direction to step in 
     * @return The order ids and the next id
     */
    function getOrdersOfVendor(address _owner, uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns (uint256[], uint256) {
        return getNodes(roomNightVendors[_owner], _from, _limit, _direction);
    }

    /**
     * @dev Get the token count of somebody 
     * @param _owner The owner of token
     * @return The token count of `_owner`
     */
    function balanceOf(address _owner) 
        public 
        view 
        returns(uint256) {
        return roomNightOwners[_owner].length;
    }

    /**
     * @dev Get rate plan ids of `_vendorId`
     * @param _from The begin id of the node to get
     * @param _limit The total nodes of on page
     * @param _direction Direction to step in 
     * @return The rate plan ids and the next id
     */
    function getRatePlansOfVendor(uint256 _vendorId, uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns(uint256[], uint256) {
        return getNodes(vendors[_vendorId].ratePlanList, _from, _limit, _direction);
    }

    /**
     * @dev Get token ids
     * @param _from The begin id of the node to get
     * @param _limit The total nodes of on page
     * @param _direction Direction to step in 
     * @return The token ids and the next id
     */
    function getTokens(uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns(uint256[], uint256) {
        return getNodes(tokenList, _from, _limit, _direction);
    }

    /**
     * @dev Get token Info
     * @param _tokenId The token id
     * @return The token info(symbol, name, decimals)
     */
    function getToken(uint256 _tokenId)
        public 
        view 
        returns(string _symbol, string _name, uint8 _decimals, address _token) {
        _token = tokenIndexToAddress[_tokenId];
        TripioToken tripio = TripioToken(_token);
        _symbol = tripio.symbol();
        _name = tripio.name();
        _decimals = tripio.decimals();
    }

    /**
     * @dev Get vendor ids
     * @param _from The begin id of the node to get
     * @param _limit The total nodes of on page
     * @param _direction Direction to step in 
     * @return The vendor ids and the next id
     */
    function getVendors(uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns(uint256[], uint256) {
        return getNodes(vendorList, _from, _limit, _direction);
    }

    /**
     * @dev Get the vendor infomation by vendorId
     * @param _vendorId The vendor id
     * @return The vendor infomation(name, vendor, timestamp, valid)
     */
    function getVendor(uint256 _vendorId) 
        public 
        view 
        returns(string _name, address _vendor,uint256 _timestamp, bool _valid) {
        _name = vendors[_vendorId].name;
        _vendor = vendors[_vendorId].vendor;
        _timestamp = vendors[_vendorId].timestamp;
        _valid = vendors[_vendorId].valid;
    }

    /*************************************** SET ***************************************/
    /**
     * @dev Update base uri of token metadata
     * @param _tokenBaseURI The base uri
     */
    function updateTokenBaseURI(string _tokenBaseURI) 
        public 
        onlyOwnerOrAuthorizedContract {
        tokenBaseURI = _tokenBaseURI;
    }

    /**
     * @dev Push order to user&#39;s order list
     * @param _owner The buyer address
     * @param _rnid The room night order id
     * @param _direction direction to step in
     */
    function pushOrderOfOwner(address _owner, uint256 _rnid, bool _direction) 
        public 
        onlyOwnerOrAuthorizedContract {
        if(!roomNightOwners[_owner].listExists()) {
            roomNightOwners[_owner] = LinkedListLib.LinkedList(0, 0);
        }
        roomNightOwners[_owner].add(_rnid, _direction);
    }

    /**
     * @dev Remove order from owner&#39;s order list
     * @param _owner The owner address
     * @param _rnid The room night order id
     */
    function removeOrderOfOwner(address _owner, uint _rnid) 
        public 
        onlyOwnerOrAuthorizedContract {
        require(roomNightOwners[_owner].nodeExists(_rnid));
        roomNightOwners[_owner].remove(_rnid);
    }

    /**
     * @dev Push order to the vendor&#39;s order list
     * @param _vendor The vendor address
     * @param _rnid The room night order id
     * @param _direction direction to step in
     */
    function pushOrderOfVendor(address _vendor, uint256 _rnid, bool _direction) 
        public 
        onlyOwnerOrAuthorizedContract {
        if(!roomNightVendors[_vendor].listExists()) {
            roomNightVendors[_vendor] = LinkedListLib.LinkedList(0, 0);
        }
        roomNightVendors[_vendor].add(_rnid, _direction);
    }

    /**
     * @dev Remove order from vendor&#39;s order list
     * @param _vendor The vendor address
     * @param _rnid The room night order id
     */
    function removeOrderOfVendor(address _vendor, uint256 _rnid) 
        public 
        onlyOwnerOrAuthorizedContract {
        require(roomNightVendors[_vendor].nodeExists(_rnid));
        roomNightVendors[_vendor].remove(_rnid);
    }

    /**
     * @dev Transfer token to somebody
     * @param _tokenId The token id 
     * @param _to The target owner of the token
     */
    function transferTokenTo(uint256 _tokenId, address _to) 
        public 
        onlyOwnerOrAuthorizedContract {
        roomNightIndexToOwner[_tokenId] = _to;
        roomNightApprovals[_tokenId] = address(0);
    }

    /**
     * @dev Approve `_to` to operate the `_tokenId`
     * @param _tokenId The token id
     * @param _to Somebody to be approved
     */
    function approveTokenTo(uint256 _tokenId, address _to) 
        public 
        onlyOwnerOrAuthorizedContract {
        roomNightApprovals[_tokenId] = _to;
    }

    /**
     * @dev Approve `_operator` to operate all the Token of `_to`
     * @param _operator The operator to be approved
     * @param _to The owner of tokens to be operate
     * @param _approved Approved or not
     */
    function approveOperatorTo(address _operator, address _to, bool _approved) 
        public 
        onlyOwnerOrAuthorizedContract {
        operatorApprovals[_to][_operator] = _approved;
    } 

    /**
     * @dev Update base price of rate plan
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _tokenId The digital token id
     * @param _price The price to be updated
     */
    function updateBasePrice(uint256 _vendorId, uint256 _rpid, uint256 _tokenId, uint256 _price)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].ratePlans[_rpid].basePrice.init = true;
        vendors[_vendorId].ratePlans[_rpid].basePrice.tokens[_tokenId] = _price;
    }

    /**
     * @dev Update base inventory of rate plan 
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _inventory The inventory to be updated
     */
    function updateBaseInventory(uint256 _vendorId, uint256 _rpid, uint16 _inventory)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].ratePlans[_rpid].basePrice.inventory = _inventory;
    }

    /**
     * @dev Update price by `_vendorId`, `_rpid`, `_date`, `_tokenId` and `_price`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _tokenId The digital token id
     * @param _price The price to be updated
     */
    function updatePrice(uint256 _vendorId, uint256 _rpid, uint256 _date, uint256 _tokenId, uint256 _price)
        public
        onlyOwnerOrAuthorizedContract {
        if (vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId] = _price;
        } else {
            vendors[_vendorId].ratePlans[_rpid].prices[_date] = Price(0, true);
            vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId] = _price;
        }
    }

    /**
     * @dev Update inventory by `_vendorId`, `_rpid`, `_date`, `_inventory`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _inventory The inventory to be updated
     */
    function updateInventories(uint256 _vendorId, uint256 _rpid, uint256 _date, uint16 _inventory)
        public 
        onlyOwnerOrAuthorizedContract {
        if (vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory = _inventory;
        } else {
            vendors[_vendorId].ratePlans[_rpid].prices[_date] = Price(_inventory, true);
        }
    }

    /**
     * @dev Reduce inventories
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _inventory The amount to be reduced
     */
    function reduceInventories(uint256 _vendorId, uint256 _rpid, uint256 _date, uint16 _inventory) 
        public  
        onlyOwnerOrAuthorizedContract {
        uint16 a = 0;
        if(vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            a = vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory;
            require(_inventory <= a);
            vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory = a - _inventory;
        }else if(vendors[_vendorId].ratePlans[_rpid].basePrice.init){
            a = vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
            require(_inventory <= a);
            vendors[_vendorId].ratePlans[_rpid].basePrice.inventory = a - _inventory;
        }
    }

    /**
     * @dev Add inventories
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _inventory The amount to be add
     */
    function addInventories(uint256 _vendorId, uint256 _rpid, uint256 _date, uint16 _inventory) 
        public  
        onlyOwnerOrAuthorizedContract {
        uint16 c = 0;
        if(vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            c = _inventory + vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory;
            require(c >= _inventory);
            vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory = c;
        }else if(vendors[_vendorId].ratePlans[_rpid].basePrice.init) {
            c = _inventory + vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
            require(c >= _inventory);
            vendors[_vendorId].ratePlans[_rpid].basePrice.inventory = c;
        }
    }

    /**
     * @dev Update inventory and price by `_vendorId`, `_rpid`, `_date`, `_tokenId`, `_price` and `_inventory`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _tokenId The digital token id
     * @param _price The price to be updated
     * @param _inventory The inventory to be updated
     */
    function updatePriceAndInventories(uint256 _vendorId, uint256 _rpid, uint256 _date, uint256 _tokenId, uint256 _price, uint16 _inventory)
        public 
        onlyOwnerOrAuthorizedContract {
        if (vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory = _inventory;
            vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId] = _price;
        } else {
            vendors[_vendorId].ratePlans[_rpid].prices[_date] = Price(_inventory, true);
            vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId] = _price;
        }
    }

    /**
     * @dev Push rate plan to `_vendorId`&#39;s rate plan list
     * @param _vendorId The vendor id
     * @param _name The name of rate plan
     * @param _ipfs The rate plan IPFS address
     * @param _direction direction to step in
     */
    function pushRatePlan(uint256 _vendorId, string _name, bytes32 _ipfs, bool _direction) 
        public 
        onlyOwnerOrAuthorizedContract
        returns(uint256) {
        RatePlan memory rp = RatePlan(_name, uint256(now), _ipfs, Price(0, false));
        
        uint256 id = vendors[_vendorId].ratePlanList.push(_direction);
        vendors[_vendorId].ratePlans[id] = rp;
        return id;
    }

    /**
     * @dev Remove rate plan of `_vendorId` by `_rpid`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     */
    function removeRatePlan(uint256 _vendorId, uint256 _rpid) 
        public 
        onlyOwnerOrAuthorizedContract {
        delete vendors[_vendorId].ratePlans[_rpid];
        vendors[_vendorId].ratePlanList.remove(_rpid);
    }

    /**
     * @dev Update `_rpid` of `_vendorId` by `_name` and `_ipfs`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _name The rate plan name
     * @param _ipfs The rate plan IPFS address
     */
    function updateRatePlan(uint256 _vendorId, uint256 _rpid, string _name, bytes32 _ipfs)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].ratePlans[_rpid].ipfs = _ipfs;
        vendors[_vendorId].ratePlans[_rpid].name = _name;
    }
    
    /**
     * @dev Push token contract to the token list
     * @param _direction direction to step in
     */
    function pushToken(address _contract, bool _direction)
        public 
        onlyOwnerOrAuthorizedContract 
        returns(uint256) {
        uint256 id = tokenList.push(_direction);
        tokenIndexToAddress[id] = _contract;
        return id;
    }

    /**
     * @dev Remove token by `_tokenId`
     * @param _tokenId The digital token id
     */
    function removeToken(uint256 _tokenId) 
        public 
        onlyOwnerOrAuthorizedContract {
        delete tokenIndexToAddress[_tokenId];
        tokenList.remove(_tokenId);
    }

    /**
     * @dev Generate room night token
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _token The token id
     * @param _price The token price
     * @param _ipfs The rate plan IPFS address
     */
    function generateRoomNightToken(uint256 _vendorId, uint256 _rpid, uint256 _date, uint256 _token, uint256 _price, bytes32 _ipfs)
        public 
        onlyOwnerOrAuthorizedContract 
        returns(uint256) {
        roomnights.push(RoomNight(_vendorId, _rpid, _token, _price, now, _date, _ipfs));

        // Give the token to `_customer`
        uint256 rnid = uint256(roomnights.length - 1);
        return rnid;
    }

    /**
     * @dev Update refund applications
     * @param _buyer The room night token holder
     * @param _rnid The room night token id
     * @param _isRefund Is redund or not
     */
    function updateRefundApplications(address _buyer, uint256 _rnid, bool _isRefund) 
        public 
        onlyOwnerOrAuthorizedContract {
        refundApplications[_buyer][_rnid] = _isRefund;
    }

    /**
     * @dev Push vendor info to the vendor list
     * @param _name The name of vendor
     * @param _vendor The vendor address
     * @param _direction direction to step in
     */
    function pushVendor(string _name, address _vendor, bool _direction)
        public 
        onlyOwnerOrAuthorizedContract 
        returns(uint256) {
        uint256 id = vendorList.push(_direction);
        vendorIds[_vendor] = id;
        vendors[id] = Vendor(_name, _vendor, uint256(now), true, LinkedListLib.LinkedList(0, 0));
        return id;
    }

    /**
     * @dev Remove vendor from vendor list
     * @param _vendorId The vendor id
     */
    function removeVendor(uint256 _vendorId) 
        public 
        onlyOwnerOrAuthorizedContract {
        vendorList.remove(_vendorId);
        address vendor = vendors[_vendorId].vendor;
        vendorIds[vendor] = 0;
        delete vendors[_vendorId];
    }

    /**
     * @dev Make vendor valid or invalid
     * @param _vendorId The vendor id
     * @param _valid The vendor is valid or not
     */
    function updateVendorValid(uint256 _vendorId, bool _valid)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].valid = _valid;
    }

    /**
     * @dev Modify vendor&#39;s name
     * @param _vendorId The vendor id
     * @param _name Then vendor name
     */
    function updateVendorName(uint256 _vendorId, string _name)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].name = _name;
    }
}



contract TRNTransactions is TRNOwners {
    /**
     * Constructor
     */
    constructor() public {

    }

    /**
     * This emits when rate plan is bought in batch
     */
    event BuyInBatch(address indexed _customer, address indexed _vendor, uint256 indexed _rpid, uint256[] _dates, uint256 _token);

    /**
     * This emits when token refund is applied 
     */
    event ApplyRefund(address _customer, uint256 indexed _rnid, bool _isRefund);

    /**
     * This emits when refunded
     */
    event Refund(address _vendor, uint256 _rnid);

    /**
     * @dev Complete the buy transaction,
     *      The inventory minus one and the room night token transfer to customer
     * @param _vendorId The vendor account
     * @param _rpid The vendor&#39;s rate plan id
     * @param _date The booking date
     * @param _customer The customer account
     * @param _token The token Id
     */
    function _buy(uint256 _vendorId, uint256 _rpid, uint256 _date, address _customer, uint256 _token) private {
        // Product room night token
        (,,uint256 _price) = dataSource.getPrice(_vendorId, _rpid, _date, _token);
        (,,bytes32 _ipfs) = dataSource.getRatePlan(_vendorId, _rpid);
        uint256 rnid = dataSource.generateRoomNightToken(_vendorId, _rpid, _date, _token, _price, _ipfs);

        // Give the token to `_customer`
        dataSource.transferTokenTo(rnid, _customer);

        // Record the token to `_customer` account
        _pushRoomNight(_customer, rnid, false);

        // Record the token to `_vendor` account
        (,address vendor,,) = dataSource.getVendor(_vendorId);
        _pushRoomNight(vendor, rnid, true);

        // The inventory minus one
        dataSource.reduceInventories(_vendorId, _rpid, _date, 1);
    }

    /**
     * @dev Complete the buy transaction in batch,
     *      The inventory minus one and the room night token transfer to customer
     * @param _vendorId The vendor account
     * @param _vendor Then vendor address
     * @param _rpid The vendor&#39;s rate plan id
     * @param _dates The booking date
     * @param _token The token Id
     */
    function _buyInBatch(uint256 _vendorId, address _vendor, uint256 _rpid, uint256[] _dates, uint256 _token) private returns(bool) {
        (uint16[] memory inventories, uint256[] memory values) = dataSource.getPrices(_vendorId, _rpid, _dates, _token);
        uint256 totalValues = 0;
        for(uint256 i = 0; i < _dates.length; i++) {
            if(inventories[i] == 0 || values[i] == 0) {
                return false;
            }
            totalValues += values[i];
            // Transfer the room night to `msg.sender`
            _buy(_vendorId, _rpid, _dates[i], msg.sender, _token);
        }
        
        if (_token == 0) {
            // By through ETH
            require(msg.value == totalValues);

            // Transfer the ETH to `_vendor`
            _vendor.transfer(totalValues);
        } else {
            // By through other digital token
            address tokenAddress = dataSource.tokenIndexToAddress(_token);
            require(tokenAddress != address(0));

            // This contract transfer `price.trio` from `msg.sender` account
            TripioToken tripio = TripioToken(tokenAddress);
            tripio.transferFrom(msg.sender, _vendor, totalValues);
        }
        return true;
    }

    /**
     * Complete the refund transaction
     * Remove the `_rnid` from the owner account and the inventory plus one
     */
    function _refund(uint256 _rnid, uint256 _vendorId, uint256 _rpid, uint256 _date) private {
        // Remove the `_rnid` from the owner
        _removeRoomNight(dataSource.roomNightIndexToOwner(_rnid), _rnid);

        // The inventory plus one
        dataSource.addInventories(_vendorId, _rpid, _date, 1);

        // Change the owner of `_rnid`
        dataSource.transferTokenTo(_rnid, address(0));
    }

    /**
     * @dev By room nigth in batch through ETH(`_token` == 0) or other digital token(`_token != 0`)
     *      Throw when `_rpid` not exist
     *      Throw unless each inventory more than zero
     *      Throw unless `msg.value` equal to `price.eth`
     *      This method is payable, can accept ETH transfer
     * @param _vendorId The vendor Id
     * @param _rpid The _vendor&#39;s rate plan id
     * @param _dates The booking dates
     * @param _token The digital currency token 
     */
    function buyInBatch(uint256 _vendorId, uint256 _rpid, uint256[] _dates, uint256 _token) 
        external
        payable
        ratePlanExist(_vendorId, _rpid)
        validDates(_dates)
        returns(bool) {
        
        (,address vendor,,) = dataSource.getVendor(_vendorId);
        
        bool result = _buyInBatch(_vendorId, vendor, _rpid, _dates, _token);
        
        require(result);

        // Event
        emit BuyInBatch(msg.sender, vendor, _rpid, _dates, _token);
        return true;
    }

    /**
     * @dev Apply room night refund
     *      Throw unless `_rnid` is valid
     *      Throw unless `_rnid` can transfer
     * @param _rnid room night identifier
     * @param _isRefund if `true` the `_rnid` can transfer else not
     */
    function applyRefund(uint256 _rnid, bool _isRefund) 
        external
        validToken(_rnid)
        canTransfer(_rnid)
        returns(bool) {
        dataSource.updateRefundApplications(msg.sender, _rnid, _isRefund);

        // Event
        emit ApplyRefund(msg.sender, _rnid, _isRefund);
        return true;
    }

    /**
     * @dev Whether the `_rnid` is in refund applications
     * @param _rnid room night identifier
     */
    function isRefundApplied(uint256 _rnid) 
        external
        view
        validToken(_rnid) returns(bool) {
        return dataSource.refundApplications(dataSource.roomNightIndexToOwner(_rnid), _rnid);
    }

    /**
     * @dev Refund through ETH or other digital token, give the room night ETH/TOKEN to customer and take back inventory
     *      Throw unless `_rnid` is valid
     *      Throw unless `msg.sender` is vendor
     *      Throw unless the refund application is true
     *      Throw unless the `msg.value` is equal to `roomnight.eth`
     * @param _rnid room night identifier
     */
    function refund(uint256 _rnid) 
        external
        payable
        validToken(_rnid) 
        returns(bool) {
        // Refund application is true
        require(dataSource.refundApplications(dataSource.roomNightIndexToOwner(_rnid), _rnid));

        // The `msg.sender` is the vendor of the room night.
        (uint256 vendorId,uint256 rpid,uint256 token,uint256 price,,uint256 date,) = dataSource.roomnights(_rnid);
        (,address vendor,,) = dataSource.getVendor(vendorId);
        require(msg.sender == vendor);

        address ownerAddress = dataSource.roomNightIndexToOwner(_rnid);

        if (token == 0) {
            // Refund by ETH

            // The `msg.sender` is equal to `roomnight.eth`
            uint256 value = price;
            require(msg.value >= value);

            // Transfer the ETH to roomnight&#39;s owner
            ownerAddress.transfer(value);
        } else {
            // Refund  by TRIO

            // The `roomnight.trio` is more than zero
            require(price > 0);

            // This contract transfer `price.trio` from `msg.sender` account
            TripioToken tripio = TripioToken(dataSource.tokenIndexToAddress(token));
            tripio.transferFrom(msg.sender, ownerAddress, price);
        }
        // Refund
        _refund(_rnid, vendorId, rpid, date);

        // Event 
        emit Refund(msg.sender, _rnid);
        return true;
    }
}

contract TripioRoomNightCustomer is TRNAsset, TRNSupportsInterface, TRNOwnership, TRNTransactions {
    /**
     * Constructor
     */
    constructor(address _dataSource) public {
        // Init the data source
        dataSource = TripioRoomNightData(_dataSource);
    }

    /**
     * @dev Withdraw ETH balance from contract account, the balance will transfer to the contract owner
     */
    function withdrawBalance() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    /**
     * @dev Withdraw other TOKEN balance from contract account, the balance will transfer to the contract owner
     * @param _token The TOKEN id
     */
    function withdrawTokenId(uint _token) external onlyOwner {
        TripioToken tripio = TripioToken(dataSource.tokenIndexToAddress(_token));
        uint256 tokens = tripio.balanceOf(address(this));
        tripio.transfer(owner, tokens);
    }

    /**
     * @dev Withdraw other TOKEN balance from contract account, the balance will transfer to the contract owner
     * @param _tokenAddress The TOKEN address
     */
    function withdrawToken(address _tokenAddress) external onlyOwner {
        TripioToken tripio = TripioToken(_tokenAddress);
        uint256 tokens = tripio.balanceOf(address(this));
        tripio.transfer(owner, tokens);
    }

    /**
     * @dev Destory the contract
     */
    function destroy() external onlyOwner {
        selfdestruct(owner);
    }

    function() external payable {

    }
}