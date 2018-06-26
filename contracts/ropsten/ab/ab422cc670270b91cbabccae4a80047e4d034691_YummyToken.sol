pragma solidity ^0.4.23;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

    /**
     * Returns whether there is code in the target address
     * @dev This function will return false if invoked during the constructor of a contract,
     *  as the code is not actually created until after the constructor finishes.
     * @param addr address address to check
     * @return whether there is code in the target address
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
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
     *  Equals to `bytes4(keccak256(&quot;onERC721Received(address,uint256,bytes)&quot;))`,
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
     * @return `bytes4(keccak256(&quot;onERC721Received(address,uint256,bytes)&quot;))`
     */
    function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}


/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic, Pausable {
    using SafeMath for uint256;
    using AddressUtils for address;

    // Equals to `bytes4(keccak256(&quot;onERC721Received(address,uint256,bytes)&quot;))`
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
        // require(_from != address(0)); // when creating new tokens, _from address is 0
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
    *  `bytes4(keccak256(&quot;onERC721Received(address,uint256,bytes)&quot;))`; otherwise,
    *  the transfer is reverted.
    * @dev Requires the msg sender to be the owner, approved, or operator
    * @param _from current owner of the token
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        safeTransferFrom(_from, _to, _tokenId, &quot;&quot;);
    }

    /**
    * @dev Safely transfers the ownership of a given token ID to another address
    * @dev If the target address is a contract, it must implement `onERC721Received`,
    *  which is called upon a safe transfer, and return the magic value
    *  `bytes4(keccak256(&quot;onERC721Received(address,uint256,bytes)&quot;))`; otherwise,
    *  the transfer is reverted.
    * @dev Requires the msg sender to be the owner, approved, or operator
    * @param _from current owner of the token
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    * @param _data bytes data to send along with a safe transfer check
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public canTransfer(_tokenId) {
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
//    function _burn(address _owner, uint256 _tokenId) internal {
//        clearApproval(_owner, _tokenId);
//        removeTokenFrom(_owner, _tokenId);
//        emit Transfer(_owner, address(0), _tokenId);
//    }

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
    function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal returns (bool) {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}

contract YummyBase is ERC721BasicToken {

    constructor() public {
        createGen0Token(0);
        pause();
    }

    // Token name
    string internal name_ = &quot;TestToken&quot;;

    // Token symbol
    string internal symbol_ = &quot;TT&quot;;

    /**
    * @dev Gets the token name
    * @return string representing the token name
    * @dev optional ERC721 function
    */
    function name() public view returns (string) {
        return name_;
    }

    /**
    * @dev Gets the token symbol
    * @return string representing the token symbol
    * @dev optional ERC721 function
    */
    function symbol() public view returns (string) {
        return symbol_;
    }

    // DNA digits
    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;

    // Token creation event
    event TokenCreation(address owner, uint256 tokenId, uint256 motherId, uint256 fatherId, uint256 dna, uint8 species);

    /**
    * @dev Token data structure
    */
    struct Token {

        // DNA of this token, stored in a 256-bit integer
        uint256 dna;

        // Token creation block timestamp
        uint64 creationTime;

        // Block number of end of cooldown
        // Used as pregnancy timer and breeding cooldown
        uint64 cooldownEndBlock;

        // Mother&#39;s token ID
        uint32 motherId;

        // Father&#39;s token ID
        uint32 fatherId;

        // ID of the father for tokens that are pregnant
        uint32 breedingWithId;

        // Generation number
        uint16 generation;

        // Index of the cooldown in the cooldown array
        uint16 cooldownIndex;

        // Token species
        uint8 species;

    }

    /**
     * @dev Array of all tokens
     */
    Token[] tokens;

    /**
     * @dev Mapping from a tokenId to an address that has been approved to breed via breedWith()
     */
    mapping (uint256 => address) public breedingAllowedToAddress;

    /**
     * @dev Lookup table of all cooldown durations
     */
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

    /**
     * @dev Approximation of current block time
     * Used to compute cooldown end blocks
     */
    uint256 public secondsPerBlock = 15;

    /**
    * @dev Returns the total supply of tokens
    * Required for token interface compliance
    * @dev optional ERC721 function
    */
    function totalSupply() public view returns (uint) {
        return tokens.length;
    }

    /**
     * @dev Creates a new token and assigns it to _owner
     * @param _generation The generation of this token, must be computed by the caller
     */
    function _createToken(
        uint256 _motherId,
        uint256 _fatherId,
        uint256 _generation,
        uint256 _dna,
        uint256 _species,
        address _owner
    )
        internal
        returns (uint)
    {
        // New token starts with the same cooldown as parent gen/2
        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        Token memory _token = Token({
            dna: _dna,
            creationTime: uint64(now),
            cooldownEndBlock: 0,
            motherId: uint32(_motherId),
            fatherId: uint32(_fatherId),
            breedingWithId: 0,
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation),
            species: uint8(_species)
        });

        uint256 newTokenId = tokens.push(_token).sub(1);

        emit TokenCreation(_owner, newTokenId, _fatherId, _motherId, _dna, uint8(_species));

        _mint(_owner, newTokenId);

        return newTokenId;
    }

    /**
     * @dev Generates a token&#39;s dna
     */
    function _generateRandomDna() internal view returns (uint256) {
        return uint256(keccak256(now));
    }

    /**
    * @dev Create a new gen0 token, only callable by the contract owner
    */
    function createGen0Token(uint8 _species) public onlyOwner {
        uint dna = _generateRandomDna();
        _createToken(0, 0, 0, dna, _species, owner);
    }

    /**
    * @dev Returns all relevant information about a specific token
    */
    function getToken(uint256 _tokenId)
        external
        view
        returns (
            bool isPregnant,
            bool isReady,
            uint256 dna,
            uint256 creationTime,
            uint256 cooldownEndBlock,
            uint32 motherId,
            uint32 fatherId,
            uint32 breedingWithId,
            uint16 generation,
            uint8 species
        )
    {
        Token storage token = tokens[_tokenId];

        isPregnant = (token.breedingWithId != 0);
        isReady = (token.cooldownEndBlock <= block.number);
        dna = token.dna;
        creationTime = uint256(token.creationTime);
        cooldownEndBlock = uint256(token.cooldownEndBlock);
        motherId = uint32(token.motherId);
        fatherId = uint32(token.fatherId);
        breedingWithId = uint32(token.breedingWithId);
        generation = uint16(token.generation);
        species = uint8(token.species);
    }

}

/**
* @title YummyBreeding
* @dev Contains the breeding logic
* Adapted from the CryptoKitties contract
*/
contract YummyBreeding is YummyBase {

    /**
    * @dev The Pregnant event is fired when two Yummies successfully combine to create a new Yummy
    * Starts the timer for the mother
    */
    event Pregnant(address owner, uint256 motherId, uint256 fatherId, uint256 cooldownEndBlock);

    /**
    * @dev The minimum payment required to use autoBreed
    * The fee goes towards the gas cost used to call giveBirth()
    */
    uint256 public autoBirthFee = 2 finney;

    /**
    * @dev Number of pregnant tokens
    */
    uint256 public pregnantTokens;

    /**
    * @todo GeneScienceInterface + setter
    */

    /**
    * @dev Number of pregnant tokens
    */
    function _isReadyToBreed(Token _token) internal view returns (bool) {
        return (_token.breedingWithId == 0) && (_token.cooldownEndBlock <= uint64(block.number));
    }

    /**
    * @dev Check if a father has authorized breeding with this mother
    * True if owner of mother and father are the same address or if father has been given breeding permission
    */
    function _isBreedingPermitted(uint256 _fatherId, uint256 _motherId) internal view returns (bool) {
        address motherOwner = tokenOwner[_motherId];
        address fatherOwner = tokenOwner[_fatherId];

        return (motherOwner == fatherOwner || breedingAllowedToAddress[_fatherId] == motherOwner);
    }

    /**
    * @dev Set the cooldown end block for the token, based on it&#39;s current cooldownIndex
    * Increment cooldownIndex if it hasn&#39;t hit the cap
    */
    function _triggerCooldown(Token storage _token) internal {
        _token.cooldownEndBlock = uint64((cooldowns[_token.cooldownIndex] / secondsPerBlock) + block.number);
        if (_token.cooldownIndex < 13) {
            _token.cooldownIndex += 1;
        }
    }

    /**
    * @dev Grant approval for breeding to another user with one of your tokens
    */
    function approveBreeding(address _addr, uint256 _fatherId) external whenNotPaused {
        require(_owns(msg.sender, _fatherId));
        breedingAllowedToAddress[_fatherId] = _addr;
    }

    /**
    * @dev Updates the minimum payment required for calling giveBirthAuto()
    * This fee is used to offset the gas cost incurred by the autobirth daemon
    */
    function setAutoBirthFee(uint256 val) external onlyOwner {
        autoBirthFee = val;
    }

    /**
    * @dev Checks if a given token is pregnant and if the pregnancy is over
    */
    function _isReadyToGiveBirth(Token _mother) private view returns (bool) {
        return (_mother.breedingWithId != 0) && (_mother.cooldownEndBlock <= uint64(block.number));
    }

    /**
    * @dev Checks if a given token is able to breed (not pregnant and not under cooldown)
    */
    function isReadyToBreed(uint256 _tokenId) public view returns (bool) {
        require(_tokenId > 0); // genesis token cannot breed ?
        Token storage token = tokens[_tokenId];
        return _isReadyToBreed(token);
    }

    /**
    * @dev Check if a token is pregnant
    */
    function isPregnant(uint256 _tokenId) public view returns (bool) {
        require(_tokenId > 0);
        return tokens[_tokenId].breedingWithId != 0;
    }

    /**
    * @dev Checks if a fiven father-mother pair is valid
    * @notice WARNING : Does not check ownership permissions (this is up to caller)
    */
    function _isValidBreedingPair(
        Token storage _mother,
        uint256 _motherId,
        Token storage _father,
        uint256 _fatherId
    )
        private
        view
        returns (bool)
    {
        // No self-breeding
        if (_motherId == _fatherId) { return false; }

        // No breeding token&#39;s father
        if (_mother.motherId == _fatherId || _mother.fatherId == _fatherId) {
            return false;
        }

        // No breeding token&#39;s mother
        if (_father.motherId == _motherId || _mother.fatherId == _motherId) {
            return false;
        }

        // Shortcut the sibling check for gen0 tokens
        if (_father.motherId == 0 || _mother.motherId == 0) { return true; }

        // No breeding with siblings
        if (_father.motherId == _mother.motherId || _father.motherId == _mother.fatherId) {
            return false;
        }
        if (_father.fatherId == _mother.motherId || _father.fatherId == _mother.fatherId) {
            return false;
        }

        return true;
    }

    /**
    * @dev Internal check if a given mother and father are a valid pair for auction breeding
    * @notice Skips ownership and breeding approval checks
    */
    function _canBreedViaAuction(uint256 _motherId, uint256 _fatherId)
        internal
        view
        returns (bool)
    {
        Token storage mother = tokens[_motherId];
        Token storage father = tokens[_fatherId];
        return _isValidBreedingPair(mother, _motherId, father, _fatherId);
    }

    /**
     * @dev Checks ownership and approval for breeding
     * @notice Does NOT check breeding cooldown and pregnancy
     */
    function canBreedWith(uint256 _motherId, uint256 _fatherId)
        external
        view
        returns (bool)
    {
        require(_motherId > 0);
        require(_fatherId > 0);
        Token storage mother = tokens[_motherId];
        Token storage father = tokens[_fatherId];
        return _isValidBreedingPair(mother, _motherId, father, _fatherId) &&
            _isBreedingPermitted(_fatherId, _motherId);
    }

    /**
     * @dev Internal breeding function
     * @notice Assumes all breeding requirements are done
     */
    function _breedWith(uint256 _motherId, uint256 _fatherId) internal {
        // Get a reference to tokens from storage
        Token storage mother = tokens[_motherId];
        Token storage father = tokens[_fatherId];

        // Set the mother as pregnant and keep track of father
        mother.breedingWithId = uint32(_fatherId);

        // Trigger cooldown for both parents
        _triggerCooldown(father);
        _triggerCooldown(mother);

        // count pregnancies
        pregnantTokens++;

        // emit Pregnant event
        emit Pregnant(tokenOwner[_motherId], _motherId, _fatherId, mother.cooldownEndBlock);
    }

    /**
     * @dev Breed tokens. Will either make the mother pregnant, or fail completely
     * @notice Requires a prepayment of the fee given out to the first caller of giveBirth()
     * If successful, mother becomes pregnant and father&#39;s cooldown begins
     */
    function breedWithAuto(uint256 _motherId, uint256 _fatherId)
        external
        payable
        whenNotPaused
    {
        // Check payment
        require(msg.value >= autoBirthFee);
        // Caller must own the mother
        require(_owns(msg.sender, _motherId));
        // Check that mother and father are owned or breeding-approved for the caller
        require(_isBreedingPermitted(_fatherId, _motherId));

        // Check that tokens are not pregnant or under cooldown
        Token storage mother = tokens[_motherId];
        require(_isReadyToBreed(mother));
        Token storage father = tokens[_fatherId];
        require(_isReadyToBreed(father));

        // Test validity of the couple
        require(_isValidBreedingPair(mother, _motherId, father, _fatherId));

        // Make a baby
        _breedWith(_motherId, _fatherId);

    }

    /**
     * @dev A pregnant token gives birth
     */
    function giveBirth(uint256 _motherId)
        external
        whenNotPaused
        returns (uint256)
    {
        // Get storage reference to mother token
        Token storage mother = tokens[_motherId];

        // Check validity and breeding readiness of mother
        require(mother.creationTime != 0);
        require(_isReadyToGiveBirth(mother));

        uint256 fatherId = mother.breedingWithId;
        Token storage father = tokens[fatherId];

        // Get higher generation number of parents
        uint16 parentGeneration = mother.generation;
        if (father.generation > mother.generation) {
            parentGeneration = father.generation;
        }

        // Compute the new token&#39;s DNA
        // @todo plug in geneMixer function here
        uint256 dna = _generateRandomDna();
        uint8 species = 1;

        // Create the new token
        address owner = tokenOwner[_motherId];
        uint256 tokenId = _createToken(_motherId, fatherId, parentGeneration + 1, dna, species, owner);

        // Clear reference to father
        delete mother.breedingWithId;

        pregnantTokens--;

        // Send the balance fee to the person who made birth happen
        msg.sender.transfer(autoBirthFee);

        // Return the new token&#39;s ID
        return tokenId;
    }

    /**
    * @dev Internal utility functions (assumes input is valid)
    */

    /**
    * @dev Check if an address is the current owner of a token
    */
    function _owns(address _addr, uint256 _tokenId) internal view returns (bool) {
        return tokenOwner[_tokenId] == _addr;
    }
}

contract YummyToken is YummyBreeding {

    function purchaseGen0Token(uint _species) public payable returns (uint) {
        // check value
        require(msg.value >= 30000000000000000);

        // create new token
        uint dna = _generateRandomDna();
        uint newTokenId = _createToken(0, 0, 0, dna, _species, msg.sender);

        // return new token id
        return newTokenId;
    }

}