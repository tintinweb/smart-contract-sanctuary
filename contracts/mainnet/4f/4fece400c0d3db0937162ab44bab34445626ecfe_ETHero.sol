pragma solidity ^0.4.21;

// The contract uses code from zeppelin-solidity library
// licensed under MIT license
// https://github.com/OpenZeppelin/zeppelin-solidity

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
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
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
contract ERC721Receiver {
    /**
     * @dev Magic value to be returned upon successful reception of an NFT
     *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
     *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
     */
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

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
    function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic {
    using SafeMath for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

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
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    /**
    * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
    * @param _tokenId uint256 ID of the token to validate
    */
    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

    /**
    * @dev Gets the balance of the specified address
    * @param _owner address to query the balance of
    * @return uint256 representing the amount owned by the passed address
    */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
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

    /**
    * @dev Returns whether the specified token exists
    * @param _tokenId uint256 ID of the token to query the existance of
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
        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        if (getApproved(_tokenId) != address(0) || _to != address(0)) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * @param _tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for a the given token ID
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
        require(_to != msg.sender);
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
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    /**
    * @dev Safely transfers the ownership of a given token ID to another address
    * @dev If the target address is a contract, it must implement `onERC721Received`,
    *  which is called upon a safe transfer, and return the magic value
    *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
    *  the transfer is reverted.
    * @dev Requires the msg sender to be the owner, approved, or operator
    * @param _from current owner of the token
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
    * @dev Safely transfers the ownership of a given token ID to another address
    * @dev If the target address is a contract, it must implement `onERC721Received`,
    *  which is called upon a safe transfer, and return the magic value
    *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
    *  the transfer is reverted.
    * @dev Requires the msg sender to be the owner, approved, or operator
    * @param _from current owner of the token
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    * @param _data bytes data to send along with a safe transfer check
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public
        canTransfer(_tokenId)
    {
        transferFrom(_from, _to, _tokenId);
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
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
        return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
    }

    /**
    * @dev Internal function to mint a new token
    * @dev Reverts if the given token ID already exists
    * @param _to The address that will own the minted token
    * @param _tokenId uint256 ID of the token to be minted by the msg.sender
    */
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
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
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }

    /**
    * @dev Internal function to add a token ID to the list of a given address
    * @param _to address representing the new owner of the given token ID
    * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
    */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    /**
    * @dev Internal function to remove a token ID from the list of a given address
    * @param _from address representing the previous owner of the given token ID
    * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     *  as the code is not actually created until after the constructor finishes.
     * @param _user address to check
     * @return whether the target address is a contract
     */
    function _isContract(address _user) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_user) }
        return size > 0;
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
    function checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        internal
        returns (bool)
    {
        if (!_isContract(_to)) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }

}

contract Owned {
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /// @dev Contract constructor
    function Owned() public {
        owner = msg.sender;
    }
}

contract HeroLogicInterface {
    function isTransferAllowed(address _from, address _to, uint256 _tokenId) public view returns (bool);
}

contract ETHero is Owned, ERC721, ERC721BasicToken {

    struct HeroData {
        uint16 fieldA;
        uint16 fieldB;
        uint32 fieldC;
        uint32 fieldD;
        uint32 fieldE;
        uint64 fieldF;
        uint64 fieldG;
    }

    // Token name
    string internal name_;

    // Token symbol
    string internal symbol_;

    // Mapping from owner to list of owned token IDs
    mapping (address => uint256[]) internal ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] internal allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal allTokensIndex;

    // Prefix for token URIs
    string public tokenUriPrefix = "https://eth.town/hero-image/";

    // Interchangeable logic contract
    address public logicContract;

    // Incremental uniqueness index for the genome
    uint32 public uniquenessIndex = 0;
    // Last token ID
    uint256 public lastTokenId = 0;

    // Users&#39; active heroes
    mapping(address => uint256) public activeHero;

    // Hero data
    mapping(uint256 => HeroData) public heroData;

    // Genomes
    mapping(uint256 => uint256) public genome;

    event ActiveHeroChanged(address indexed _from, uint256 _tokenId);

    modifier onlyLogicContract {
        require(msg.sender == logicContract || msg.sender == owner);
        _;
    }

    /**
    * @dev Constructor function
    */
    function ETHero() public {
        name_ = "ETH.TOWN Hero";
        symbol_ = "HERO";
    }

    /**
    * @dev Sets the token&#39;s interchangeable logic contract
    */
    function setLogicContract(address _logicContract) external onlyOwner {
        logicContract = _logicContract;
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
    * @dev Internal function to check if transferring a specific token is allowed
    * @param _from transfer from
    * @param _to transfer to
    * @param _tokenId token to transfer
    */
    function _isTransferAllowed(address _from, address _to, uint256 _tokenId) internal view returns (bool) {
        if (logicContract == address(0)) {
            return true;
        }

        HeroLogicInterface logic = HeroLogicInterface(logicContract);
        return logic.isTransferAllowed(_from, _to, _tokenId);
    }

    /**
    * @dev Appends uint (in decimal) to a string
    * @param _str The prefix string
    * @param _value The uint to append
    * @return resulting string
    */
    function _appendUintToString(string _str, uint _value) internal pure returns (string) {
        uint maxLength = 100;
        bytes memory reversed = new bytes(maxLength);
        uint i = 0;
        while (_value != 0) {
            uint remainder = _value % 10;
            _value = _value / 10;
            reversed[i++] = byte(48 + remainder);
        }
        i--;

        bytes memory inStrB = bytes(_str);
        bytes memory s = new bytes(inStrB.length + i + 1);
        uint j;
        for (j = 0; j < inStrB.length; j++) {
            s[j] = inStrB[j];
        }
        for (j = 0; j <= i; j++) {
            s[j + inStrB.length] = reversed[i - j];
        }
        return string(s);
    }

    /**
    * @dev Returns an URI for a given token ID
    * @dev Throws if the token ID does not exist
    * @param _tokenId uint256 ID of the token to query
    */
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return _appendUintToString(tokenUriPrefix, genome[_tokenId]);
    }

    /**
    * @dev Gets the token ID at a given index of the tokens list of the requested owner
    * @param _owner address owning the tokens list to be accessed
    * @param _index uint256 representing the index to be accessed of the requested tokens list
    * @return uint256 token ID at the given index of the tokens list owned by the requested address
    */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

    /**
    * @dev Gets the total amount of tokens stored by the contract
    * @return uint256 representing the total amount of tokens
    */
    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }

    /**
    * @dev Gets the token ID at a given index of all the tokens in this contract
    * @dev Reverts if the index is greater or equal to the total number of tokens
    * @param _index uint256 representing the index to be accessed of the tokens list
    * @return uint256 token ID at the given index of the tokens list
    */
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
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

        if (activeHero[_to] == 0) {
            activeHero[_to] = _tokenId;
            emit ActiveHeroChanged(_to, _tokenId);
        }
    }

    /**
    * @dev Internal function to remove a token ID from the list of a given address
    * @param _from address representing the previous owner of the given token ID
    * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);

        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
        // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
        // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
        // the lastToken to the first position, and then dropping the element placed in the last position of the list

        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;

        // If a hero is removed from its owner, it no longer can be their active hero
        if (activeHero[_from] == _tokenId) {
            activeHero[_from] = 0;
            emit ActiveHeroChanged(_from, 0);
        }
    }

    /**
    * @dev Internal function to mint a new token
    * @dev Reverts if the given token ID already exists
    * @param _to address the beneficiary that will own the minted token
    * @param _tokenId uint256 ID of the token to be minted by the msg.sender
    */
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

    /**
    * @dev External function to mint a new token
    * @dev Reverts if the given token ID already exists
    * @param _to address the beneficiary that will own the minted token
    * @param _tokenId uint256 ID of the token to be minted by the msg.sender
    */
    function mint(address _to, uint256 _tokenId) external onlyLogicContract {
        _mint(_to, _tokenId);
    }

    /**
    * @dev Internal function to burn a specific token
    * @dev Reverts if the token does not exist
    * @param _owner owner of the token to burn
    * @param _tokenId uint256 ID of the token being burned by the msg.sender
    */
    function _burn(address _owner, uint256 _tokenId) internal {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);

        // Reorg all tokens array
        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.length--;
        allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;

        // Clear genome data
        if (genome[_tokenId] != 0) {
            genome[_tokenId] = 0;
        }
    }

    /**
    * @dev External function to burn a specific token
    * @dev Reverts if the token does not exist
    * @param _owner owner of the token to burn
    * @param _tokenId uint256 ID of the token being burned by the msg.sender
    */
    function burn(address _owner, uint256 _tokenId) external onlyLogicContract {
        _burn(_owner, _tokenId);
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
        require(_isTransferAllowed(_from, _to, _tokenId));
        super.transferFrom(_from, _to, _tokenId);
    }

    /**
    * @dev Safely transfers the ownership of a given token ID to another address
    * @dev If the target address is a contract, it must implement `onERC721Received`,
    *  which is called upon a safe transfer, and return the magic value
    *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
    *  the transfer is reverted.
    * @dev Requires the msg sender to be the owner, approved, or operator
    * @param _from current owner of the token
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId)
        public
        canTransfer(_tokenId)
    {
        require(_isTransferAllowed(_from, _to, _tokenId));
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    /**
    * @dev Safely transfers the ownership of a given token ID to another address
    * @dev If the target address is a contract, it must implement `onERC721Received`,
    *  which is called upon a safe transfer, and return the magic value
    *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
    *  the transfer is reverted.
    * @dev Requires the msg sender to be the owner, approved, or operator
    * @param _from current owner of the token
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    * @param _data bytes data to send along with a safe transfer check
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data)
        public
        canTransfer(_tokenId)
    {
        require(_isTransferAllowed(_from, _to, _tokenId));
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
    * @dev Allows to transfer a token to another owner
    * @param _to transfer to
    * @param _tokenId token to transfer
    */
    function transfer(address _to, uint256 _tokenId) external onlyOwnerOf(_tokenId) {
        require(_isTransferAllowed(msg.sender, _to, _tokenId));
        require(_to != address(0));

        clearApproval(msg.sender, _tokenId);
        removeTokenFrom(msg.sender, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(msg.sender, _to, _tokenId);
    }

    /**
    * @dev Sets the specified token as user&#39;s active Hero
    * @param _tokenId the hero token to set as active
    */
    function setActiveHero(uint256 _tokenId) external onlyOwnerOf(_tokenId) {
        activeHero[msg.sender] = _tokenId;
        emit ActiveHeroChanged(msg.sender, _tokenId);
    }

    /**
    * @dev Queries list of tokens owned by a specific address
    * @param _owner the address to get tokens of
    */
    function tokensOfOwner(address _owner) external view returns (uint256[]) {
        return ownedTokens[_owner];
    }

    /**
    * @dev Gets the genome of the active hero
    * @param _owner the address to get hero of
    */
    function activeHeroGenome(address _owner) public view returns (uint256) {
        uint256 tokenId = activeHero[_owner];
        if (tokenId == 0) {
            return 0;
        }

        return genome[tokenId];
    }

    /**
    * @dev Increments uniqueness index. Overflow intentionally allowed.
    */
    function incrementUniquenessIndex() external onlyLogicContract {
        uniquenessIndex ++;
    }

    /**
    * @dev Increments lastTokenId
    */
    function incrementLastTokenId() external onlyLogicContract {
        lastTokenId ++;
    }

    /**
    * @dev Allows (re-)setting the uniqueness index
    * @param _uniquenessIndex new value
    */
    function setUniquenessIndex(uint32 _uniquenessIndex) external onlyOwner {
        uniquenessIndex = _uniquenessIndex;
    }

    /**
    * @dev Allows (re-)setting lastTokenId
    * @param _lastTokenId new value
    */
    function setLastTokenId(uint256 _lastTokenId) external onlyOwner {
        lastTokenId = _lastTokenId;
    }

    /**
    * @dev Allows setting hero data for a hero
    * @param _tokenId hero to set data for
    * @param _fieldA data to set
    * @param _fieldB data to set
    * @param _fieldC data to set
    * @param _fieldD data to set
    * @param _fieldE data to set
    * @param _fieldF data to set
    * @param _fieldG data to set
    */
    function setHeroData(
        uint256 _tokenId,
        uint16 _fieldA,
        uint16 _fieldB,
        uint32 _fieldC,
        uint32 _fieldD,
        uint32 _fieldE,
        uint64 _fieldF,
        uint64 _fieldG
    ) external onlyLogicContract {
        heroData[_tokenId] = HeroData(
            _fieldA,
            _fieldB,
            _fieldC,
            _fieldD,
            _fieldE,
            _fieldF,
            _fieldG
        );
    }

    /**
    * @dev Allows setting hero genome
    * @param _tokenId token to set data for
    * @param _genome genome data to set
    */
    function setGenome(uint256 _tokenId, uint256 _genome) external onlyLogicContract {
        genome[_tokenId] = _genome;
    }

    /**
    * @dev Allows the admin to forcefully transfer a token from one address to another
    * @param _from transfer from
    * @param _to transfer to
    * @param _tokenId token to transfer
    */
    function forceTransfer(address _from, address _to, uint256 _tokenId) external onlyLogicContract {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    /**
    * @dev External function to set the token URI prefix for all tokens
    * @param _uriPrefix prefix string to assign
    */
    function setTokenUriPrefix(string _uriPrefix) external onlyOwner {
        tokenUriPrefix = _uriPrefix;
    }


}