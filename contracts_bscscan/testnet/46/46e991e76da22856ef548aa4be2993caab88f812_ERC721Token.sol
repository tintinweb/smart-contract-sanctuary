/**
 *Submitted for verification at BscScan.com on 2021-11-03
*/

pragma solidity ^0.4.23;

library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }
}

library AddressUtils {

    /**
    * Returns whether the target address is a contract
    * @dev This function will return false if invoked during the constructor of a contract,
    *  as the code is not actually created until after the constructor finishes.
    * @param addr address to check
    * @return whether the target address is a contract
    */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}

contract ERC721Basic {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId) public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) public view returns (uint256);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function tokenURI(uint256 _tokenId) public view returns (string);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic {
    using SafeMath for uint256;
    using AddressUtils for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) internal tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => uint256) internal ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal operatorApprovals;

    /**
    * @dev Guarantees msg.sender is owner of the given token
    * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
    */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require (ownerOf(_tokenId) == msg.sender);
        _;
    }

    /**
    * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
    * @param _tokenId uint256 ID of the token to validate
    */
    modifier canTransfer(uint256 _tokenId) {
        require (isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

    /**
    * @dev Gets the balance of the specified address
    * @param _owner address to query the balance of
    * @return uint256 representing the amount owned by the passed address
    */
    function balanceOf(address _owner) public view returns (uint256) {
        require (_owner != address(0));
        return ownedTokensCount[_owner];
    }

    /**
    * @dev Gets the owner of the specified token ID
    * @param _tokenId uint256 ID of the token to query the owner of
    * @return owner address currently marked as the owner of the given token ID
    */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    function isOwnerOf(address _owner, uint256 _tokenId) public view returns (bool) {
        address owner = ownerOf(_tokenId);
        return owner == _owner;
    }

    /**
    * @dev Returns whether the specified token exists
    * @param _tokenId uint256 ID of the token to query the existence of
    * @return whether the token exists
    */
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

    /**
    * @dev Approves another address to transfer the given token ID
    * @dev The zero address indicates there is no approved address.
    * @dev There can only be one approved address per token at a given time.
    * @dev Can only be called by the token owner or an approved operator.
    * @param _to address to be approved for the given token ID
    * @param _tokenId uint256 ID of the token to be approved
    */
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require (_to != owner);
        require (msg.sender == owner || isApprovedForAll(owner, msg.sender));

        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

    /**
    * @dev Gets the approved address for a token ID, or zero if no address set
    * @param _tokenId uint256 ID of the token to query the approval of
    * @return address currently approved for the given token ID
    */
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    /**
    * @dev Sets or unsets the approval of a given operator
    * @dev An operator is allowed to transfer all tokens of the sender on their behalf
    * @param _to operator address to set the approval
    * @param _approved representing the status of the approval to be set
    */
    function setApprovalForAll(address _to, bool _approved) public {
        require (_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    /**
    * @dev Tells whether an operator is approved by a given owner
    * @param _owner owner address which you want to query the approval of
    * @param _operator operator address which you want to query the approval of
    * @return bool whether the given operator is approved by the given owner
    */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    /**
    * @dev Transfers the ownership of a given token ID to another address
    * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
    * @dev Requires the msg sender to be the owner, approved, or operator
    * @param _from current owner of the token
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require (_from != address(0));
        require (_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    /**
    * @dev Safely transfers the ownership of a given token ID to another address
    * @dev If the target address is a contract, it must implement `onERC721Received`,
    *  which is called upon a safe transfer, and return the magic value
    *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
    *  the transfer is reverted.
    * @dev Requires the msg sender to be the owner, approved, or operator
    * @param _from current owner of the token
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
    * @dev Safely transfers the ownership of a given token ID to another address
    * @dev If the target address is a contract, it must implement `onERC721Received`,
    *  which is called upon a safe transfer, and return the magic value
    *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
    *  the transfer is reverted.
    * @dev Requires the msg sender to be the owner, approved, or operator
    * @param _from current owner of the token
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    * @param _data bytes data to send along with a safe transfer check
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public canTransfer(_tokenId) {
        transferFrom(_from, _to, _tokenId);
        // solium-disable-next-line arg-overflow
        require (checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

    /**
    * @dev Returns whether the given spender can transfer a given token ID
    * @param _spender address of the spender to query
    * @param _tokenId uint256 ID of the token to be transferred
    * @return bool whether the msg.sender is approved for the given token ID,
    *  is an operator of the owner, or is the owner of the token
    */
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }

    /**
    * @dev Internal function to mint a new token
    * @dev Reverts if the given token ID already exists
    * @param _to The address that will own the minted token
    * @param _tokenId uint256 ID of the token to be minted by the msg.sender
    */
    function _mint(address _to, uint256 _tokenId) internal {
        //require (_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

    /**
    * @dev Internal function to burn a specific token
    * @dev Reverts if the token does not exist
    * @param _tokenId uint256 ID of the token being burned by the msg.sender
    */
    function _burn(address _owner, uint256 _tokenId) internal {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);
    }

    /**
    * @dev Internal function to clear current approval of a given token ID
    * @dev Reverts if the given address is not indeed the owner of the token
    * @param _owner owner of the token
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require (ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
        }
    }

    /**
    * @dev Internal function to add a token ID to the list of a given address
    * @param _to address representing the new owner of the given token ID
    * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
    */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        //        require (tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    /**
    * @dev Internal function to remove a token ID from the list of a given address
    * @param _from address representing the previous owner of the given token ID
    * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require (ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    /**
    * @dev Internal function to invoke `onERC721Received` on a target address
    * @dev The call is not executed if the target address is not a contract
    * @param _from address representing the previous owner of the given token ID
    * @param _to target address that will receive the tokens
    * @param _tokenId uint256 ID of the token to be transferred
    * @param _data bytes optional data to send along with the call
    * @return whether the call correctly returned the expected magic value
    */
    function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal returns (bool) {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
contract ERC721Receiver {
    /**
    * @dev Magic value to be returned upon successful reception of an NFT
    *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
    *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    */
    bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

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
    * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

contract ERC721Holder is ERC721Receiver {
    function onERC721Received(address, address, uint256, bytes) public returns(bytes4) {
        return ERC721_RECEIVED;
    }
}

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is ERC721, ERC721BasicToken {

    // Token name
    string internal name_ = "CryptoFlowers";

    // Token symbol
    string internal symbol_ = "CF";

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) internal ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] internal allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal allTokensIndex;

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];

        return string(bab);
    }

    /**
    * @dev Returns an URI for a given token ID
    * @dev Throws if the token ID does not exist. May return an empty string.
    * @notice The user/developper needs to add the tokenID, in the end of URL, to
    * use the URI and get all details. Ex. www.<apiURL>.com/token/<tokenID>
    * @param _tokenId uint256 ID of the token to query
    */
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        string memory infoUrl;
        infoUrl = strConcat('https://cryptoflowers.io/v/', uint2str(_tokenId));
        return infoUrl;
    }

    /**
    * @dev Gets the token ID at a given index of the tokens list of the requested owner
    * @param _owner address owning the tokens list to be accessed
    * @param _index uint256 representing the index to be accessed of the requested tokens list
    * @return uint256 token ID at the given index of the tokens list owned by the requested address
    */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require (_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

    /**
    * @dev Gets the total amount of tokens stored by the contract
    * @return uint256 representing the total amount of tokens
    */
    function totalSupply() public view returns (uint256) {
        return allTokens.length - 1;
    }

    /**
    * @dev Gets the token ID at a given index of all the tokens in this contract
    * @dev Reverts if the index is greater or equal to the total number of tokens
    * @param _index uint256 representing the index to be accessed of the tokens list
    * @return uint256 token ID at the given index of the tokens list
    */
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require (_index <= totalSupply());
        return allTokens[_index];
    }


    /**
    * @dev Internal function to add a token ID to the list of a given address
    * @param _to address representing the new owner of the given token ID
    * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
    */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }

    /**
    * @dev Internal function to remove a token ID from the list of a given address
    * @param _from address representing the previous owner of the given token ID
    * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);

        // To prevent a gap in the array, we store the last token in the index of the token to delete, and
        // then delete the last slot.
        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        // This also deletes the contents at the last position of the array
        ownedTokens[_from].length--;

        // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
        // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
        // the lastToken to the first position, and then dropping the element placed in the last position of the list

        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }

    /**
    * @dev Gets the token name
    * @return string representing the token name
    */
    function name() public view returns (string) {
        return name_;
    }

    /**
    * @dev Gets the token symbol
    * @return string representing the token symbol
    */
    function symbol() public view returns (string) {
        return symbol_;
    }

    /**
    * @dev Internal function to mint a new token
    * @dev Reverts if the given token ID already exists
    * @param _to address the beneficiary that will own the minted token
    * @param _tokenId uint256 ID of the token to be minted by the msg.sender
    */
    function _mint(address _to, uint256 _tokenId) internal {
        super._mint(_to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

    /**
    * @dev Internal function to burn a specific token
    * @dev Reverts if the token does not exist
    * @param _owner owner of the token to burn
    * @param _tokenId uint256 ID of the token being burned by the msg.sender
    */
    function _burn(address _owner, uint256 _tokenId) internal {
        super._burn(_owner, _tokenId);

        // Reorg all tokens array
        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.length--;
        allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;
    }

    bytes4 constant InterfaceSignature_ERC165 = 0x01ffc9a7;
    /*
    bytes4(keccak256('supportsInterface(bytes4)'));
    */

    bytes4 constant InterfaceSignature_ERC721Enumerable = 0x780e9d63;
    /*
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
    bytes4(keccak256('tokenByIndex(uint256)'));
    */

    bytes4 constant InterfaceSignature_ERC721Metadata = 0x5b5e139f;
    /*
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('tokenURI(uint256)'));
    */

    bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;
    /*
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('getApproved(uint256)')) ^
    bytes4(keccak256('setApprovalForAll(address,bool)')) ^
    bytes4(keccak256('isApprovedForAll(address,address)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
    bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'));
    */

    bytes4 public constant InterfaceSignature_ERC721Optional =- 0x4f558e79;
    /*
    bytes4(keccak256('exists(uint256)'));
    */

    /**
    * @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    * @dev Returns true for any standardized interfaces implemented by this contract.
    * @param _interfaceID bytes4 the interface to check for
    * @return true for any standardized interfaces implemented by this contract.
    */
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165)
        || (_interfaceID == InterfaceSignature_ERC721)
        || (_interfaceID == InterfaceSignature_ERC721Enumerable)
        || (_interfaceID == InterfaceSignature_ERC721Metadata));
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

}

contract GenomeInterface {
    function isGenome() public pure returns (bool);
    function mixGenes(uint256 genes1, uint256 genes2) public returns (uint256);
}

contract FlowerAdminAccess {
    address public rootAddress;
    address public adminAddress;

    event ContractUpgrade(address newContract);

    address public gen0SellerAddress;
    address public giftHolderAddress;

    bool public stopped = false;

    modifier onlyRoot() {
        require(msg.sender == rootAddress);
        _;
    }

    modifier onlyAdmin()  {
        require(msg.sender == adminAddress);
        _;
    }

    modifier onlyAdministrator() {
        require(msg.sender == rootAddress || msg.sender == adminAddress);
        _;
    }

    function setRoot(address _newRoot) external onlyAdministrator {
        require(_newRoot != address(0));
        rootAddress = _newRoot;
    }

    function setAdmin(address _newAdmin) external onlyRoot {
        require(_newAdmin != address(0));
        adminAddress = _newAdmin;
    }

    modifier whenNotStopped() {
        require(!stopped);
        _;
    }

    modifier whenStopped {
        require(stopped);
        _;
    }

    function setStop() public onlyAdministrator whenNotStopped {
        stopped = true;
    }

    function setStart() public onlyAdministrator whenStopped {
        stopped = false;
    }
}

contract FlowerBase is ERC721Token {

    struct Flower {
        uint256 genes;
        uint64 birthTime;
        uint64 cooldownEndBlock;
        uint32 matronId;
        uint32 sireId;
        uint16 cooldownIndex;
        uint16 generation;
    }

    Flower[] flowers;

    mapping (uint256 => uint256) genomeFlowerIds;

    // Сooldown duration
    uint32[14] public cooldowns = [
    uint32(1 minutes),
    uint32(2 minutes),
    uint32(5 minutes),
    uint32(10 minutes),
    uint32(30 minutes),
    uint32(1 hours),
    uint32(2 hours),
    uint32(4 hours),
    uint32(8 hours),
    uint32(16 hours),
    uint32(1 days),
    uint32(2 days),
    uint32(4 days),
    uint32(7 days)
    ];

    event Birth(address owner, uint256 flowerId, uint256 matronId, uint256 sireId, uint256 genes);
    event Transfer(address from, address to, uint256 tokenId);
    event Money(address from, string actionType, uint256 sum, uint256 cut, uint256 tokenId, uint256 blockNumber);

    function _createFlower(uint256 _matronId, uint256 _sireId, uint256 _generation, uint256 _genes, address _owner) internal returns (uint) {
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));
        require(checkUnique(_genes));

        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        Flower memory _flower = Flower({
            genes: _genes,
            birthTime: uint64(now),
            cooldownEndBlock: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation)
            });

        uint256 newFlowerId = flowers.push(_flower) - 1;

        require(newFlowerId == uint256(uint32(newFlowerId)));

        genomeFlowerIds[_genes] = newFlowerId;

        emit Birth(_owner, newFlowerId, uint256(_flower.matronId), uint256(_flower.sireId), _flower.genes);

        _mint(_owner, newFlowerId);

        return newFlowerId;
    }

    function checkUnique(uint256 _genome) public view returns (bool) {
        uint256 _flowerId = uint256(genomeFlowerIds[_genome]);
        return !(_flowerId > 0);
    }
}

contract FlowerOwnership is FlowerBase, FlowerAdminAccess {
    SaleClockAuction public saleAuction;
    BreedingClockAuction public breedingAuction;

    uint256 public secondsPerBlock = 15;

    function setSecondsPerBlock(uint256 secs) external onlyAdministrator {
        require(secs < cooldowns[0]);
        secondsPerBlock = secs;
    }
}

contract ClockAuctionBase {

    struct Auction {
        address seller;
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
        uint64 startedAt;
    }

    ERC721Token public nonFungibleContract;

    uint256 public ownerCut;

    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);
    event Money(address from, string actionType, uint256 sum, uint256 cut, uint256 tokenId, uint256 blockNumber);

    function isOwnerOf(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    function _transfer(address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.transferFrom(this, _receiver, _tokenId);
    }

    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(uint256(_tokenId), uint256(_auction.startingPrice), uint256(_auction.endingPrice), uint256(_auction.duration));
    }

    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    function _bid(uint256 _tokenId, uint256 _bidAmount, address _sender) internal returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId];

        require(_isOnAuction(auction));

        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

        address seller = auction.seller;

        _removeAuction(_tokenId);

        if (price > 0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;
            seller.transfer(sellerProceeds);

            emit Money(_sender, "AuctionSuccessful", price, auctioneerCut, _tokenId, block.number);
        }

        uint256 bidExcess = _bidAmount - price;

        _sender.transfer(bidExcess);

        emit AuctionSuccessful(_tokenId, price, _sender);

        return price;
    }

    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0 && _auction.startedAt < now);
    }

    function _currentPrice(Auction storage _auction) internal view returns (uint256) {
        uint256 secondsPassed = 0;

        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(_auction.startingPrice, _auction.endingPrice, _auction.duration, secondsPassed);
    }

    function _computeCurrentPrice(uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, uint256 _secondsPassed) internal pure returns (uint256) {
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    function _computeCut(uint256 _price) internal view returns (uint256) {
        return uint256(_price * ownerCut / 10000);
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

contract ClockAuction is Pausable, ClockAuctionBase {
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721Token candidateContract = ERC721Token(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));
        nonFungibleContract = candidateContract;
    }

    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);
        require(msg.sender == owner || msg.sender == nftAddress);
        owner.transfer(address(this).balance);
    }

    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _seller, uint64 _startAt) external whenNotPaused {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));
        require(isOwnerOf(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        uint64 startAt = _startAt;
        if (_startAt == 0) {
            startAt = uint64(now);
        }
        Auction memory auction = Auction(
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(startAt)
        );
        _addAuction(_tokenId, auction);
    }

    function bid(uint256 _tokenId, address _sender) external payable whenNotPaused {
        _bid(_tokenId, msg.value, _sender);
        _transfer(_sender, _tokenId);
    }

    function cancelAuction(uint256 _tokenId) external {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    function cancelAuctionByAdmin(uint256 _tokenId) onlyOwner external {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    function getAuction(uint256 _tokenId) external view returns (address seller, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 startedAt) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (auction.seller, auction.startingPrice, auction.endingPrice, auction.duration, auction.startedAt);
    }

    function getCurrentPrice(uint256 _tokenId) external view returns (uint256){
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

    // TMP
    function getContractBalance() onlyOwner external view returns (uint256) {
        return address(this).balance;
    }
}

contract BreedingClockAuction is ClockAuction {

    bool public isBreedingClockAuction = true;

    constructor(address _nftAddr, uint256 _cut) public ClockAuction(_nftAddr, _cut) {}

    function bid(uint256 _tokenId, address _sender) external payable {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        _bid(_tokenId, msg.value, _sender);
        _transfer(seller, _tokenId);
    }

    function getCurrentPrice(uint256 _tokenId) external view returns (uint256) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _seller, uint64 _startAt) external {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        uint64 startAt = _startAt;
        if (_startAt == 0) {
            startAt = uint64(now);
        }
        Auction memory auction = Auction(_seller, uint128(_startingPrice), uint128(_endingPrice), uint64(_duration), uint64(startAt));
        _addAuction(_tokenId, auction);
    }
}





contract SaleClockAuction is ClockAuction {

    bool public isSaleClockAuction = true;

    uint256 public gen0SaleCount;
    uint256[5] public lastGen0SalePrices;

    constructor(address _nftAddr, uint256 _cut) public ClockAuction(_nftAddr, _cut) {}

    address public gen0SellerAddress;
    function setGen0SellerAddress(address _newAddress) external {
        require(msg.sender == address(nonFungibleContract));
        gen0SellerAddress = _newAddress;
    }

    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _seller, uint64 _startAt) external {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        uint64 startAt = _startAt;
        if (_startAt == 0) {
            startAt = uint64(now);
        }
        Auction memory auction = Auction(_seller, uint128(_startingPrice), uint128(_endingPrice), uint64(_duration), uint64(startAt));
        _addAuction(_tokenId, auction);
    }

    function bid(uint256 _tokenId) external payable {
        // _bid verifies token ID size
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value, msg.sender);
        _transfer(msg.sender, _tokenId);

        // If not a gen0 auction, exit
        if (seller == address(gen0SellerAddress)) {
            // Track gen0 sale prices
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    function bidGift(uint256 _tokenId, address _to) external payable {
        // _bid verifies token ID size
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value, msg.sender);
        _transfer(_to, _tokenId);

        // If not a gen0 auction, exit
        if (seller == address(gen0SellerAddress)) {
            // Track gen0 sale prices
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum += lastGen0SalePrices[i];
        }
        return sum / 5;
    }

    function computeCut(uint256 _price) public view returns (uint256) {
        return _computeCut(_price);
    }

    function getSeller(uint256 _tokenId) public view returns (address) {
        return address(tokenIdToAuction[_tokenId].seller);
    }
}

// Flowers crossing
contract FlowerBreeding is FlowerOwnership {

    // Fee for breeding
    uint256 public autoBirthFee = 2 finney;
    uint256 public giftFee = 2 finney;

    GenomeInterface public geneScience;

    // Set Genome contract address
    function setGenomeContractAddress(address _address) external onlyAdministrator {
        geneScience = GenomeInterface(_address);
    }

    function _isReadyToAction(Flower _flower) internal view returns (bool) {
        return _flower.cooldownEndBlock <= uint64(block.number);
    }

    function isReadyToAction(uint256 _flowerId) public view returns (bool) {
        require(_flowerId > 0);
        Flower storage flower = flowers[_flowerId];
        return _isReadyToAction(flower);
    }

    function _setCooldown(Flower storage _flower) internal {
        _flower.cooldownEndBlock = uint64((cooldowns[_flower.cooldownIndex]/secondsPerBlock) + block.number);

        if (_flower.cooldownIndex < 13) {
            _flower.cooldownIndex += 1;
        }
    }

    function setAutoBirthFee(uint256 val) external onlyAdministrator {
        autoBirthFee = val;
    }

    function setGiftFee(uint256 _fee) external onlyAdministrator {
        giftFee = _fee;
    }

    // Check if a given sire and matron are a valid crossing pair
    function _isValidPair(Flower storage _matron, uint256 _matronId, Flower storage _sire, uint256 _sireId) private view returns(bool) {
        if (_matronId == _sireId) {
            return false;
        }

        // Generation zero can crossing
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

        // Do not crossing with it parrents
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        // Can't crossing with brothers and sisters
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

        return true;
    }

    function canBreedWith(uint256 _matronId, uint256 _sireId) external view returns (bool) {
        return _canBreedWith(_matronId, _sireId);
    }

    function _canBreedWith(uint256 _matronId, uint256 _sireId) internal view returns (bool) {
        require(_matronId > 0);
        require(_sireId > 0);
        Flower storage matron = flowers[_matronId];
        Flower storage sire = flowers[_sireId];
        return _isValidPair(matron, _matronId, sire, _sireId);
    }

    function _born(uint256 _matronId, uint256 _sireId) internal {
        Flower storage sire = flowers[_sireId];
        Flower storage matron = flowers[_matronId];

        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes);
        address owner = ownerOf(_matronId);
        uint256 flowerId = _createFlower(_matronId, _sireId, parentGen + 1, childGenes, owner);

        Flower storage child = flowers[flowerId];

        _setCooldown(sire);
        _setCooldown(matron);
        _setCooldown(child);
    }

    // Crossing two of owner flowers
    function breedOwn(uint256 _matronId, uint256 _sireId) external payable whenNotStopped {
        require(msg.value >= autoBirthFee);
        require(isOwnerOf(msg.sender, _matronId));
        require(isOwnerOf(msg.sender, _sireId));

        Flower storage matron = flowers[_matronId];
        require(_isReadyToAction(matron));

        Flower storage sire = flowers[_sireId];
        require(_isReadyToAction(sire));

        require(_isValidPair(matron, _matronId, sire, _sireId));

        _born(_matronId, _sireId);

        gen0SellerAddress.transfer(autoBirthFee);

        emit Money(msg.sender, "BirthFee-own", autoBirthFee, autoBirthFee, _sireId, block.number);
    }
}

// Handles creating auctions for sale and siring
contract FlowerAuction is FlowerBreeding {

    // Set sale auction contract address
    function setSaleAuctionAddress(address _address) external onlyAdministrator {
        SaleClockAuction candidateContract = SaleClockAuction(_address);
        require(candidateContract.isSaleClockAuction());
        saleAuction = candidateContract;
    }

    // Set siring auction contract address
    function setBreedingAuctionAddress(address _address) external onlyAdministrator {
        BreedingClockAuction candidateContract = BreedingClockAuction(_address);
        require(candidateContract.isBreedingClockAuction());
        breedingAuction = candidateContract;
    }

    // Flower sale auction
    function createSaleAuction(uint256 _flowerId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external whenNotStopped {
        require(isOwnerOf(msg.sender, _flowerId));
        require(isReadyToAction(_flowerId));
        approve(saleAuction, _flowerId);
        saleAuction.createAuction(_flowerId, _startingPrice, _endingPrice, _duration, msg.sender, 0);
    }

    // Create siring auction
    function createBreedingAuction(uint256 _flowerId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external whenNotStopped {
        require(isOwnerOf(msg.sender, _flowerId));
        require(isReadyToAction(_flowerId));
        approve(breedingAuction, _flowerId);
        breedingAuction.createAuction(_flowerId, _startingPrice, _endingPrice, _duration, msg.sender, 0);
    }

    // Siring auction complete
    function bidOnBreedingAuction(uint256 _sireId, uint256 _matronId) external payable whenNotStopped {
        require(isOwnerOf(msg.sender, _matronId));
        require(isReadyToAction(_matronId));
        require(isReadyToAction(_sireId));
        require(_canBreedWith(_matronId, _sireId));

        uint256 currentPrice = breedingAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);

        // Siring auction will throw if the bid fails.
        breedingAuction.bid.value(msg.value - autoBirthFee)(_sireId, msg.sender);
        _born(uint32(_matronId), uint32(_sireId));
        gen0SellerAddress.transfer(autoBirthFee);
        emit Money(msg.sender, "BirthFee-bid", autoBirthFee, autoBirthFee, _sireId, block.number);
    }

    // Transfers the balance of the sale auction contract to the Core contract
    function withdrawAuctionBalances() external onlyAdministrator {
        saleAuction.withdrawBalance();
        breedingAuction.withdrawBalance();
    }

    function sendGift(uint256 _flowerId, address _to) external payable whenNotStopped {
        require(isOwnerOf(msg.sender, _flowerId));
        require(isReadyToAction(_flowerId));

        transferFrom(msg.sender, _to, _flowerId);
    }

    function makeGift(uint256 _flowerId) external payable whenNotStopped {
        require(isOwnerOf(msg.sender, _flowerId));
        require(isReadyToAction(_flowerId));
        require(msg.value >= giftFee);

        transferFrom(msg.sender, giftHolderAddress, _flowerId);
        giftHolderAddress.transfer(msg.value);

        emit Money(msg.sender, "MakeGift", msg.value, msg.value, _flowerId, block.number);
    }
}

contract FlowerMinting is FlowerAuction {
    // Constants for gen0 auctions.
    uint256 public constant GEN0_STARTING_PRICE = 10 finney;
    uint256 public constant GEN0_AUCTION_DURATION = 1 days;
    // Counts the number of cats the contract owner has created
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    // Create promo flower
    function createPromoFlower(uint256 _genes, address _owner) external onlyAdministrator {
        address flowerOwner = _owner;
        if (flowerOwner == address(0)) {
            flowerOwner = adminAddress;
        }
        promoCreatedCount++;
        gen0CreatedCount++;
        _createFlower(0, 0, 0, _genes, flowerOwner);
    }

    function createGen0Auction(uint256 _genes, uint64 _auctionStartAt) external onlyAdministrator {
        uint256 flowerId = _createFlower(0, 0, 0, _genes, address(gen0SellerAddress));
        tokenApprovals[flowerId] = saleAuction;
        //approve(saleAuction, flowerId);

        gen0CreatedCount++;

        saleAuction.createAuction(flowerId, _computeNextGen0Price(), 0, GEN0_AUCTION_DURATION, address(gen0SellerAddress), _auctionStartAt);
    }

    // Computes the next gen0 auction starting price, given the average of the past 5 prices + 50%.
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

        // Sanity check to ensure we don't overflow arithmetic
        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice + (avePrice / 2);

        // We never auction for less than starting price
        if (nextPrice < GEN0_STARTING_PRICE) {
            nextPrice = GEN0_STARTING_PRICE;
        }

        return nextPrice;
    }

    function setGen0SellerAddress(address _newAddress) external onlyAdministrator {
        gen0SellerAddress = _newAddress;
        saleAuction.setGen0SellerAddress(_newAddress);
    }

    function setGiftHolderAddress(address _newAddress) external onlyAdministrator {
        giftHolderAddress = _newAddress;
    }
}

contract FlowerCore is FlowerMinting {

    constructor() public {
        stopped = true;
        rootAddress = msg.sender;
        adminAddress = msg.sender;
        _createFlower(0, 0, 0, uint256(-1), address(0));
    }

    // Get flower information
    function getFlower(uint256 _id) external view returns (bool isReady, uint256 cooldownIndex, uint256 nextActionAt, uint256 birthTime, uint256 matronId, uint256 sireId, uint256 generation, uint256 genes) {
        Flower storage flower = flowers[_id];
        isReady = (flower.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(flower.cooldownIndex);
        nextActionAt = uint256(flower.cooldownEndBlock);
        birthTime = uint256(flower.birthTime);
        matronId = uint256(flower.matronId);
        sireId = uint256(flower.sireId);
        generation = uint256(flower.generation);
        genes = flower.genes;
    }

    // Start the game
    function unstop() public onlyAdministrator whenStopped {
        require(geneScience != address(0));

        super.setStart();
    }

    function withdrawBalance() external onlyAdministrator {
        rootAddress.transfer(address(this).balance);
    }
}