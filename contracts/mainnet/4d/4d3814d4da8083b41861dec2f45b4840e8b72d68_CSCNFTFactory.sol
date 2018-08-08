pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * Utility library of inline functions on addresses
 */
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

/* Controls state and access rights for contract functions
 * @title Operational Control
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 * Inspired and adapted from contract created by OpenZeppelin
 * Ref: https://github.com/OpenZeppelin/zeppelin-solidity/
 */
contract OperationalControl {
    // Facilitates access & control for the game.
    // Roles:
    //  -The Managers (Primary/Secondary): Has universal control of all elements (No ability to withdraw)
    //  -The Banker: The Bank can withdraw funds and adjust fees / prices.
    //  -otherManagers: Contracts that need access to functions for gameplay

    /// @dev Emited when contract is upgraded
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public managerPrimary;
    address public managerSecondary;
    address public bankManager;

    // Contracts that require access for gameplay
    mapping(address => uint8) public otherManagers;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    // @dev Keeps track whether the contract erroredOut. When that is true, most actions are blocked & refund can be claimed
    bool public error = false;

    /// @dev Operation modifiers for limiting access
    modifier onlyManager() {
        require(msg.sender == managerPrimary || msg.sender == managerSecondary);
        _;
    }

    modifier onlyBanker() {
        require(msg.sender == bankManager);
        _;
    }

    modifier onlyOtherManagers() {
        require(otherManagers[msg.sender] == 1);
        _;
    }


    modifier anyOperator() {
        require(
            msg.sender == managerPrimary ||
            msg.sender == managerSecondary ||
            msg.sender == bankManager ||
            otherManagers[msg.sender] == 1
        );
        _;
    }

    /// @dev Assigns a new address to act as the Other Manager. (State = 1 is active, 0 is disabled)
    function setOtherManager(address _newOp, uint8 _state) external onlyManager {
        require(_newOp != address(0));

        otherManagers[_newOp] = _state;
    }

    /// @dev Assigns a new address to act as the Primary Manager.
    function setPrimaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerPrimary = _newGM;
    }

    /// @dev Assigns a new address to act as the Secondary Manager.
    function setSecondaryManager(address _newGM) external onlyManager {
        require(_newGM != address(0));

        managerSecondary = _newGM;
    }

    /// @dev Assigns a new address to act as the Banker.
    function setBanker(address _newBK) external onlyManager {
        require(_newBK != address(0));

        bankManager = _newBK;
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

    /// @dev Modifier to allow actions only when the contract has Error
    modifier whenError {
        require(error);
        _;
    }

    /// @dev Called by any Operator role to pause the contract.
    /// Used only if a bug or exploit is discovered (Here to limit losses / damage)
    function pause() external onlyManager whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function unpause() public onlyManager whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function hasError() public onlyManager whenPaused {
        error = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the Game Master
    /// @notice This is public rather than external so it can be called by derived contracts. 
    function noError() public onlyManager whenPaused {
        error = false;
    }
}

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId)
        public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator)
        public view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        public
        view
        returns (uint256 _tokenId);

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
    function isApprovedForAll(
        address _owner,
        address _operator
    )
        public
        view
        returns (bool)
    {
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
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
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
        // solium-disable-next-line arg-overflow
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
        // solium-disable-next-line arg-overflow
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

    /**
    * @dev Returns whether the given spender can transfer a given token ID
    * @param _spender address of the spender to query
    * @param _tokenId uint256 ID of the token to be transferred
    * @return bool whether the msg.sender is approved for the given token ID,
    *  is an operator of the owner, or is the owner of the token
    */
    function isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    )
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(_tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (
        _spender == owner ||
        getApproved(_tokenId) == _spender ||
        isApprovedForAll(owner, _spender)
        );
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
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(
        _from, _tokenId, _data);
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
    function onERC721Received(
        address _from,
        uint256 _tokenId,
        bytes _data
    )
        public
        returns(bytes4);
}
contract ERC721Holder is ERC721Receiver {
    function onERC721Received(address, uint256, bytes) public returns(bytes4) {
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
    string internal name_;

    // Token symbol
    string internal symbol_;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) internal ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] internal allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal allTokensIndex;

    // Base Server Address for Token MetaData URI
    string internal tokenURIBase;

    /**
    * @dev Returns an URI for a given token ID. Only returns the based location, you will have to appending a token ID to this
    * @dev Throws if the token ID does not exist. May return an empty string.
    * @param _tokenId uint256 ID of the token to query
    */
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return tokenURIBase;
    }

    /**
    * @dev Gets the token ID at a given index of the tokens list of the requested owner
    * @param _owner address owning the tokens list to be accessed
    * @param _index uint256 representing the index to be accessed of the requested tokens list
    * @return uint256 token ID at the given index of the tokens list owned by the requested address
    */
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        public
        view
        returns (uint256)
    {
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
    * @dev Internal function to set the token URI for a given token
    * @dev Reverts if the token ID does not exist
    * @param _uri string URI to assign
    */
    function _setTokenURIBase(string _uri) internal {
        tokenURIBase = _uri;
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
    bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));
    */

    bytes4 constant InterfaceSignature_ERC721Enumerable = 0x780e9d63;
    /*
    bytes4(keccak256(&#39;totalSupply()&#39;)) ^
    bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;));
    */

    bytes4 constant InterfaceSignature_ERC721Metadata = 0x5b5e139f;
    /*
    bytes4(keccak256(&#39;name()&#39;)) ^
    bytes4(keccak256(&#39;symbol()&#39;)) ^
    bytes4(keccak256(&#39;tokenURI(uint256)&#39;));
    */

    bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;
    /*
    bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
    bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
    bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
    bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
    bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
    bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;));
    */

    bytes4 public constant InterfaceSignature_ERC721Optional =- 0x4f558e79;
    /*
    bytes4(keccak256(&#39;exists(uint256)&#39;));
    */

    /**
    * @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    * @dev Returns true for any standardized interfaces implemented by this contract.
    * @param _interfaceID bytes4 the interface to check for
    * @return true for any standardized interfaces implemented by this contract.
    */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
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

contract CSCNFTFactory is ERC721Token, OperationalControl {

    /*** EVENTS ***/
    /// @dev The Created event is fired whenever a new asset comes into existence.
    event AssetCreated(address owner, uint256 assetId, uint256 assetType, uint256 sequenceId, uint256 creationTime);

    event DetachRequest(address owner, uint256 assetId, uint256 timestamp);

    event NFTDetached(address requester, uint256 assetId);

    event NFTAttached(address requester, uint256 assetId);

    // Mapping from assetId to uint encoded data for NFT
    mapping(uint256 => uint256) internal nftDataA;
    mapping(uint256 => uint128) internal nftDataB;

    // Mapping from Asset Types to count of that type in exsistance
    mapping(uint32 => uint64) internal assetTypeTotalCount;

    mapping(uint32 => uint64) internal assetTypeBurnedCount;
  
    // Mapping from index of a Asset Type to get AssetID
    mapping(uint256 => mapping(uint32 => uint64) ) internal sequenceIDToTypeForID;

     // Mapping from Asset Type to string name of type
    mapping(uint256 => string) internal assetTypeName;

    // Mapping from assetType to creation limit
    mapping(uint256 => uint32) internal assetTypeCreationLimit;

    // Indicates if attached system is Active (Transfers will be blocked if attached and active)
    bool public attachedSystemActive;

    // Is Asset Burning Active
    bool public canBurn;

    // Time LS Oracle has to respond to detach requests
    uint32 public detachmentTime = 300;

    /**
    * @dev Constructor function
    */
    constructor() public {
        require(msg.sender != address(0));
        paused = true;
        error = false;
        canBurn = false;
        managerPrimary = msg.sender;
        managerSecondary = msg.sender;
        bankManager = msg.sender;

        name_ = "CSCNFTFactory";
        symbol_ = "CSCNFT";
    }

    /**
    * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
    * @param _tokenId uint256 ID of the token to validate
    */
    modifier canTransfer(uint256 _tokenId) {
        uint256 isAttached = getIsNFTAttached(_tokenId);
        if(isAttached == 2) {
            //One-Time Auth for Physical Card Transfers
            require(msg.sender == managerPrimary ||
                msg.sender == managerSecondary ||
                msg.sender == bankManager ||
                otherManagers[msg.sender] == 1
            );
            updateIsAttached(_tokenId, 1);
        } else if(attachedSystemActive == true && isAttached >= 1) {
            require(msg.sender == managerPrimary ||
                msg.sender == managerSecondary ||
                msg.sender == bankManager ||
                otherManagers[msg.sender] == 1
            );
        }
        else {
            require(isApprovedOrOwner(msg.sender, _tokenId));
        }
        
    _;
    }

    /** Public Functions */

    // Returns the AssetID for the Nth assetID for a specific type
    function getAssetIDForTypeSequenceID(uint256 _seqId, uint256 _type) public view returns (uint256 _assetID) {
        return sequenceIDToTypeForID[_seqId][uint32(_type)];
    }

    function getAssetDetails(uint256 _assetId) public view returns(
        uint256 assetId,
        uint256 ownersIndex,
        uint256 assetTypeSeqId,
        uint256 assetType,
        uint256 createdTimestamp,
        uint256 isAttached,
        address creator,
        address owner
    ) {
        require(exists(_assetId));

        uint256 nftData = nftDataA[_assetId];
        uint256 nftDataBLocal = nftDataB[_assetId];

        assetId = _assetId;
        ownersIndex = ownedTokensIndex[_assetId];
        createdTimestamp = uint256(uint48(nftData>>160));
        assetType = uint256(uint32(nftData>>208));
        assetTypeSeqId = uint256(uint64(nftDataBLocal));
        isAttached = uint256(uint48(nftDataBLocal>>64));
        creator = address(nftData);
        owner = ownerOf(_assetId);
    }

    function totalSupplyOfType(uint256 _type) public view returns (uint256 _totalOfType) {
        return assetTypeTotalCount[uint32(_type)] - assetTypeBurnedCount[uint32(_type)];
    }

    function totalCreatedOfType(uint256 _type) public view returns (uint256 _totalOfType) {
        return assetTypeTotalCount[uint32(_type)];
    }

    function totalBurnedOfType(uint256 _type) public view returns (uint256 _totalOfType) {
        return assetTypeBurnedCount[uint32(_type)];
    }

    function getAssetRawMeta(uint256 _assetId) public view returns(
        uint256 dataA,
        uint128 dataB
    ) {
        require(exists(_assetId));

        dataA = nftDataA[_assetId];
        dataB = nftDataB[_assetId];
    }

    function getAssetIdItemType(uint256 _assetId) public view returns(
        uint256 assetType
    ) {
        require(exists(_assetId));
        uint256 dataA = nftDataA[_assetId];
        assetType = uint256(uint32(dataA>>208));
    }

    function getAssetIdTypeSequenceId(uint256 _assetId) public view returns(
        uint256 assetTypeSequenceId
    ) {
        require(exists(_assetId));
        uint256 dataB = nftDataB[_assetId];
        assetTypeSequenceId = uint256(uint64(dataB));
    }
    
    function getIsNFTAttached( uint256 _assetId) 
    public view returns(
        uint256 isAttached
    ) {
        uint256 nftData = nftDataB[_assetId];
        isAttached = uint256(uint48(nftData>>64));
    }

    function getAssetIdCreator(uint256 _assetId) public view returns(
        address creator
    ) {
        require(exists(_assetId));
        uint256 dataA = nftDataA[_assetId];
        creator = address(dataA);
    }

    function isAssetIdOwnerOrApproved(address requesterAddress, uint256 _assetId) public view returns(
        bool
    ) {
        return isApprovedOrOwner(requesterAddress, _assetId);
    }

    function getAssetIdOwner(uint256 _assetId) public view returns(
        address owner
    ) {
        require(exists(_assetId));

        owner = ownerOf(_assetId);
    }

    function getAssetIdOwnerIndex(uint256 _assetId) public view returns(
        uint256 ownerIndex
    ) {
        require(exists(_assetId));
        ownerIndex = ownedTokensIndex[_assetId];
    }

    /// @param _owner The owner whose ships tokens we are interested in.
    /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
    ///  expensive (it walks the entire NFT owners array looking for NFT belonging to owner),
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;

            // We count on the fact that all Asset have IDs starting at 0 and increasing
            // sequentially up to the total count.
            uint256 _itemIndex;

            for (_itemIndex = 0; _itemIndex < tokenCount; _itemIndex++) {
                result[resultIndex] = tokenOfOwnerByIndex(_owner,_itemIndex);
                resultIndex++;
            }

            return result;
        }
    }

    // Get the name of the Asset type
    function getTypeName (uint32 _type) public returns(string) {
        return assetTypeName[_type];
    }


    /**
    * @dev Transfers the ownership of a given token ID to another address, modified to prevent transfer if attached and system is active
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }
    

    
    function multiBatchTransferFrom(
        uint256[] _assetIds, 
        address[] _fromB, 
        address[] _toB) 
        public
    {
        uint256 _id;
        address _to;
        address _from;
        
        for (uint256 i = 0; i < _assetIds.length; ++i) {
            _id = _assetIds[i];
            _to = _toB[i];
            _from = _fromB[i];

            require(isApprovedOrOwner(msg.sender, _id));

            require(_from != address(0));
            require(_to != address(0));
    
            clearApproval(_from, _id);
            removeTokenFrom(_from, _id);
            addTokenTo(_to, _id);
    
            emit Transfer(_from, _to, _id);
        }
        
    }
    
    function batchTransferFrom(uint256[] _assetIds, address _from, address _to) 
        public
    {
        uint256 _id;
        
        for (uint256 i = 0; i < _assetIds.length; ++i) {
            _id = _assetIds[i];

            require(isApprovedOrOwner(msg.sender, _id));

            require(_from != address(0));
            require(_to != address(0));
    
            clearApproval(_from, _id);
            removeTokenFrom(_from, _id);
            addTokenTo(_to, _id);
    
            emit Transfer(_from, _to, _id);
        }
    }
    
    function multiBatchSafeTransferFrom(
        uint256[] _assetIds, 
        address[] _fromB, 
        address[] _toB
        )
        public
    {
        uint256 _id;
        address _to;
        address _from;
        
        for (uint256 i = 0; i < _assetIds.length; ++i) {
            _id = _assetIds[i];
            _to  = _toB[i];
            _from  = _fromB[i];

            safeTransferFrom(_from, _to, _id);
        }
    }

    function batchSafeTransferFrom(
        uint256[] _assetIds, 
        address _from, 
        address _to
        )
        public
    {
        uint256 _id;
        for (uint256 i = 0; i < _assetIds.length; ++i) {
            _id = _assetIds[i];
            safeTransferFrom(_from, _to, _id);
        }
    }


    function batchApprove(
        uint256[] _assetIds, 
        address _spender
        )
        public
    {
        uint256 _id;
        for (uint256 i = 0; i < _assetIds.length; ++i) {
            _id = _assetIds[i];
            approve(_spender, _id);
        }
        
    }


    function batchSetApprovalForAll(
        address[] _spenders,
        bool _approved
        )
        public
    {
        address _spender;
        for (uint256 i = 0; i < _spenders.length; ++i) {
            _spender = _spenders[i];
            setApprovalForAll(_spender, _approved);
        }
    }  
    
    function requestDetachment(
        uint256 _tokenId
    )
        public
    {
        //Request can only be made by owner or approved address
        require(isApprovedOrOwner(msg.sender, _tokenId));

        uint256 isAttached = getIsNFTAttached(_tokenId);

        require(isAttached >= 1);

        if(attachedSystemActive == true) {
            //Checks to see if request was made and if time elapsed
            if(isAttached > 1 && block.timestamp - isAttached > detachmentTime) {
                isAttached = 0;
            } else if(isAttached > 1) {
                //Fail if time is already set for attachment
                require(isAttached == 1);
            } else {
                //Is attached, set detachment time and make request to detach
                emit DetachRequest(msg.sender, _tokenId, block.timestamp);
                isAttached = block.timestamp;
            }           
        } else {
            isAttached = 0;
        } 

        if(isAttached == 0) {
            emit NFTDetached(msg.sender, _tokenId);
        }

        updateIsAttached(_tokenId, isAttached);
    }

    function attachAsset(
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
        uint256 isAttached = getIsNFTAttached(_tokenId);

        require(isAttached == 0);
        isAttached = 1;

        updateIsAttached(_tokenId, isAttached);

        emit NFTAttached(msg.sender, _tokenId);
    }

    function batchAttachAssets(uint256[] _ids) public {
        for(uint i = 0; i < _ids.length; i++) {
            attachAsset(_ids[i]);
        }
    }

    function batchDetachAssets(uint256[] _ids) public {
        for(uint i = 0; i < _ids.length; i++) {
            requestDetachment(_ids[i]);
        }
    }

    function requestDetachmentOnPause (uint256 _tokenId) public 
    whenPaused {
        //Request can only be made by owner or approved address
        require(isApprovedOrOwner(msg.sender, _tokenId));

        updateIsAttached(_tokenId, 0);
    }

    function batchBurnAssets(uint256[] _assetIDs) public {
        uint256 _id;
        for(uint i = 0; i < _assetIDs.length; i++) {
            _id = _assetIDs[i];
            burnAsset(_id);
        }
    }

    function burnAsset(uint256 _assetID) public {
        // Is Burn Enabled
        require(canBurn == true);

        // Deny Action if Attached
        require(getIsNFTAttached(_assetID) == 0);

        require(isApprovedOrOwner(msg.sender, _assetID) == true);
        
        //Updates Type Total Count
        uint256 _assetType = getAssetIdItemType(_assetID);
        assetTypeBurnedCount[uint32(_assetType)] += 1;
        
        _burn(msg.sender, _assetID);
    }


    /** Dev Functions */

    function setTokenURIBase (string _tokenURI) public onlyManager {
        _setTokenURIBase(_tokenURI);
    }

    function setPermanentLimitForType (uint32 _type, uint256 _limit) public onlyManager {
        //Only allows Limit to be set once
        require(assetTypeCreationLimit[_type] == 0);

        assetTypeCreationLimit[_type] = uint32(_limit);
    }

    function setTypeName (uint32 _type, string _name) public anyOperator {
        assetTypeName[_type] = _name;
    }

    // Minting Function
    function batchSpawnAsset(address _to, uint256[] _assetTypes, uint256[] _assetIds, uint256 _isAttached) public anyOperator {
        uint256 _id;
        uint256 _assetType;
        for(uint i = 0; i < _assetIds.length; i++) {
            _id = _assetIds[i];
            _assetType = _assetTypes[i];
            _createAsset(_to, _assetType, _id, _isAttached, address(0));
        }
    }

    function batchSpawnAsset(address[] _toB, uint256[] _assetTypes, uint256[] _assetIds, uint256 _isAttached) public anyOperator {
        address _to;
        uint256 _id;
        uint256 _assetType;
        for(uint i = 0; i < _assetIds.length; i++) {
            _to = _toB[i];
            _id = _assetIds[i];
            _assetType = _assetTypes[i];
            _createAsset(_to, _assetType, _id, _isAttached, address(0));
        }
    }

    function batchSpawnAssetWithCreator(address[] _toB, uint256[] _assetTypes, uint256[] _assetIds, uint256[] _isAttacheds, address[] _creators) public anyOperator {
        address _to;
        address _creator;
        uint256 _id;
        uint256 _assetType;
        uint256 _isAttached;
        for(uint i = 0; i < _assetIds.length; i++) {
            _to = _toB[i];
            _id = _assetIds[i];
            _assetType = _assetTypes[i];
            _creator = _creators[i];
            _isAttached = _isAttacheds[i];
            _createAsset(_to, _assetType, _id, _isAttached, _creator);
        }
    }

    function spawnAsset(address _to, uint256 _assetType, uint256 _assetID, uint256 _isAttached) public anyOperator {
        _createAsset(_to, _assetType, _assetID, _isAttached, address(0));
    }

    function spawnAssetWithCreator(address _to, uint256 _assetType, uint256 _assetID, uint256 _isAttached, address _creator) public anyOperator {
        _createAsset(_to, _assetType, _assetID, _isAttached, _creator);
    }

    /// @dev Remove all Ether from the contract, shouldn&#39;t have any but just incase.
    function withdrawBalance() public onlyBanker {
        // We are using this boolean method to make sure that even if one fails it will still work
        bankManager.transfer(address(this).balance);
    }

    // Burn Functions

    function setCanBurn(bool _state) public onlyManager {
        canBurn = _state;
    }

    function burnAssetOperator(uint256 _assetID) public anyOperator {
        
        require(getIsNFTAttached(_assetID) > 0);

        //Updates Type Total Count
        uint256 _assetType = getAssetIdItemType(_assetID);
        assetTypeBurnedCount[uint32(_assetType)] += 1;
        
        _burn(ownerOf(_assetID), _assetID);
    }

    function toggleAttachedEnforement (bool _state) public onlyManager {
        attachedSystemActive = _state;
    }

    function setDetachmentTime (uint256 _time) public onlyManager {
        //Detactment Time can not be set greater than 2 weeks.
        require(_time <= 1209600);
        detachmentTime = uint32(_time);
    }

    function setNFTDetached(uint256 _assetID) public anyOperator {
        require(getIsNFTAttached(_assetID) > 0);

        updateIsAttached(_assetID, 0);
        emit NFTDetached(msg.sender, _assetID);
    }

    function setBatchDetachCollectibles(uint256[] _assetIds) public anyOperator {
        uint256 _id;
        for(uint i = 0; i < _assetIds.length; i++) {
            _id = _assetIds[i];
            setNFTDetached(_id);
        }
    }



    /** Internal Functions */

    // @dev For creating NFT Collectible
    function _createAsset(address _to, uint256 _assetType, uint256 _assetID, uint256 _attachState, address _creator) internal returns(uint256) {
        
        uint256 _sequenceId = uint256(assetTypeTotalCount[uint32(_assetType)]) + 1;

        //Will not allow creation if over limit
        require(assetTypeCreationLimit[uint32(_assetType)] == 0 || assetTypeCreationLimit[uint32(_assetType)] > _sequenceId);
        
        // These requires are not strictly necessary, our calling code should make
        // sure that these conditions are never broken.
        require(_sequenceId == uint256(uint64(_sequenceId)));

        //Creates NFT
        _mint(_to, _assetID);

        uint256 nftData = uint256(_creator); // 160 bit address of creator
        nftData |= now<<160; // 48 bit creation timestamp
        nftData |= _assetType<<208; // 32 bit item type 

        uint256 nftDataContinued = uint256(_sequenceId); // 64 bit sequence id of item
        nftDataContinued |= _attachState<<64; // 48 bit state and/or timestamp for detachment

        nftDataA[_assetID] = nftData;
        nftDataB[_assetID] = uint128(nftDataContinued);

        assetTypeTotalCount[uint32(_assetType)] += 1;
        sequenceIDToTypeForID[_sequenceId][uint32(_assetType)] = uint64(_assetID);

        // emit Created event
        emit AssetCreated(_to, _assetID, _assetType, _sequenceId, now);

        return _assetID;
    }

    function updateIsAttached(uint256 _assetID, uint256 _isAttached) 
    internal
    {
        uint256 nftData = nftDataB[_assetID];

        uint256 assetTypeSeqId = uint256(uint64(nftData));

        uint256 nftDataContinued = uint256(assetTypeSeqId); // 64 bit sequence id of item
        nftDataContinued |= _isAttached<<64; // 48 bit state and/or timestamp for detachment

        nftDataB[_assetID] = uint128(nftDataContinued);
    }



}