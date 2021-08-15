/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

pragma solidity ^0.5.5;

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
contract ERC721 /* is ERC165 */ {
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
    function ownerOf(uint256 _tokenId) public view returns (address);

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
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable;

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
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable;

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


contract DeedIPFSToken is ERC721, ERC165 {

    using SafeMath for uint256;
    using Address for address;

    address payable public owner;
    mapping(bytes4 => bool) supportedInterfaces;

    mapping(uint256 => address) tokenOwners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) allowance;
    mapping(address => mapping(address => bool)) operators;

    mapping(uint256 => string) tokenURIs;


    struct asset {
        string ipfsHash;
    }

    asset[] public allTokens;

    //for enumeration
    uint256[] public allValidTokenIds; //same as allTokens but does't have invalid tokens
    mapping(uint256 => uint256) private allValidTokenIndex;


    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() public {
        owner = msg.sender;
        supportedInterfaces[0x01ffc9a7] = true; //ERC165
        supportedInterfaces[0x80ac58cd] = true; //ERC721
        supportedInterfaces[0x5b5e139f] = true; //ERC721Metadata

    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        return supportedInterfaces[interfaceID];
    }

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {

        address addr_owner = tokenOwners[_tokenId];
        require(
            addr_owner != address(0),
            "Token is invalid"
        );
        return addr_owner;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable {

        address addr_owner = ownerOf(_tokenId);

        require(
            addr_owner == _from,
            "_from is NOT the owner of the token"
        );

        require(
            _to != address(0),
            "Transfer _to address 0x0"
        );

        address addr_allowed = allowance[_tokenId];
        bool isOp = operators[addr_owner][msg.sender];

        require(
            addr_owner == msg.sender || addr_allowed == msg.sender || isOp,
            "msg.sender does not have transferable token"
        );


        //transfer : change the owner of the token
        tokenOwners[_tokenId] = _to;
        balances[_from] = balances[_from].sub(1);
        balances[_to] = balances[_to].add(1);

        //reset approved address
        if (allowance[_tokenId] != address(0)) {
            delete allowance[_tokenId];
        }

        emit Transfer(_from, _to, _tokenId);

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable {

        transferFrom(_from, _to, _tokenId);

        //check if _to is CA
        if (_to.isContract()) {
            bytes4 result = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);

            require(
                result == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),
                "receipt of token is NOT completed"
            );
        }

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }


    function approve(address _approved, uint256 _tokenId) external payable {

        address addr_owner = ownerOf(_tokenId);
        bool isOp = operators[addr_owner][msg.sender];

        require(
            addr_owner == msg.sender || isOp,
            "Not approved by owner"
        );

        allowance[_tokenId] = _approved;

        emit Approval(addr_owner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }


    function getApproved(uint256 _tokenId) external view returns (address) {
        return allowance[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operators[_owner][_operator];
    }


    //non-ERC721 standard
    //
    //
    function () external payable {}

    function mint(string calldata ipfsHash) external payable {

        asset memory newAsset = asset(ipfsHash);
        uint tokenId = allTokens.push(newAsset) - 1;
        //token id starts from 0, index of assets array
        tokenOwners[tokenId] = msg.sender;
        balances[msg.sender] = balances[msg.sender].add(1);

        //for enumeration
        allValidTokenIndex[tokenId] = allValidTokenIds.length;
        //index starts from 0
        allValidTokenIds.push(tokenId);

        //Token Metadata
        //tokenURIs[tokenId] = Strings.strConcat(baseTokenURI(), "QmdDW36bvr2W6ua4FxnT8bKysXhYEUo7QbLTbkGW4Foxr8");
        tokenURIs[tokenId] = Strings.strConcat(baseTokenURI(), ipfsHash);

        emit Transfer(address(0), msg.sender, tokenId);
    }


    function burn(uint _tokenId) external {

        address addr_owner = ownerOf(_tokenId);

        require(
            addr_owner == msg.sender,
            "msg.sender is NOT the owner of the token"
        );

        //reset approved address
        if (allowance[_tokenId] != address(0)) {
            delete allowance[_tokenId];
            // tokenId => 0
        }

        //transfer : change the owner of the token, but address(0)
        tokenOwners[_tokenId] = address(0);
        balances[msg.sender] = balances[msg.sender].sub(1);

        //for enumeration
        removeInvalidToken(_tokenId);

        //clear metadata if exists
        if (bytes(tokenURIs[_tokenId]).length != 0) {
            delete tokenURIs[_tokenId];
        }

        emit Transfer(addr_owner, address(0), _tokenId);
    }

    function removeInvalidToken(uint256 tokenIdToRemove) private {

        uint256 lastIndex = allValidTokenIds.length.sub(1);
        uint256 removeIndex = allValidTokenIndex[tokenIdToRemove];

        uint256 lastTokenId = allValidTokenIds[lastIndex];

        //swap
        allValidTokenIds[removeIndex] = lastTokenId;
        allValidTokenIndex[lastTokenId] = removeIndex;

        //delete
        //Arrays have a length member to hold their number of elements.
        //Dynamic arrays can be resized in storage (not in memory) by changing the .length member.
        allValidTokenIds.length = allValidTokenIds.length.sub(1);
        //allValidTokenIndex is private so can't access invalid token by index programmatically
        allValidTokenIndex[tokenIdToRemove] = 0;
    }

    function baseTokenURI() public pure returns (string memory) {
        return "https://gateway.ipfs.io/ipfs/";
    }




    //ERC721Enumerable
    function totalSupply() public view returns (uint) {
        return allValidTokenIds.length;
    }

    //ERC721Enumerable
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return allValidTokenIds[index];
    }

    //ERC721Metadata
    function name() external pure returns (string memory) {
        return "IPFS TOKEN";
    }

    //ERC721Metadata
    function symbol() external pure returns (string memory) {
        return "IPT";
    }

    //ERC721Metadata
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(tokenByIndex(allValidTokenIndex[_tokenId]) == _tokenId, "The token is invalid");
        return tokenURIs[_tokenId];
    }

    function kill() external onlyOwner {
        selfdestruct(owner);
    }


}

library Strings {
    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract ERC721TokenReceiver {

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public returns (bytes4);
}