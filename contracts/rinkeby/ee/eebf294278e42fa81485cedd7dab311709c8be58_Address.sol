/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

pragma solidity ^0.4.25;
//version: 19


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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the SafeMath
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title IERC165
 * @dev https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @title ERC165
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    /*
     * 0x01ffc9a7 ===
     *     bytes4(keccak256('supportsInterface(bytes4)'))
     */

    /**
     * @dev a mapping of interface id to whether or not it's supported
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev A contract implementing SupportsInterfaceWithLookup
     * implement ERC165 itself
     */
    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev implement supportsInterface(bytes4) using a lookup table
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev internal method for registering an interface
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    /*
     * 0x80ac58cd ===
     *     bytes4(keccak256('balanceOf(address)')) ^
     *     bytes4(keccak256('ownerOf(uint256)')) ^
     *     bytes4(keccak256('approve(address,uint256)')) ^
     *     bytes4(keccak256('getApproved(uint256)')) ^
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) ^
     *     bytes4(keccak256('isApprovedForAll(address,address)')) ^
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) ^
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
     */

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _tokenOwner[tokenId];
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to mint a new token.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address.
     * The call is not executed if the target address is not a contract.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }  
}

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    /*
     * 0x5b5e139f ===
     *     bytes4(keccak256('name()')) ^
     *     bytes4(keccak256('symbol()')) ^
     *     bytes4(keccak256('tokenURI(uint256)'))
     */

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

}

/**
 * @title KillFish contract
 */

contract KillFish is Ownable, ERC721Metadata {
    using SafeMath for uint256;
    using SafeMath for uint64;
    using Counters for Counters.Counter;
    
    /**
    * token structure
    */
    
    struct Fish {  
        uint64 genes;           //genes determine only the appearance 00 000 000 000-99 999 999 999
        string nickname;        //fish nickname
        uint256 parentId;       //parent fish id
        uint64 birthTime;       //birth time
        uint64 feedTime;        //last feeding time
        uint64 huntTime;        //last hunting time
        uint256 share;          //fish size (per share)
        uint256 feedValue;      //how much fish should eat (per eth)
        uint256 eatenValue;     //how much did the fish eat (per eth)
        uint256 profitValue;    //how much did the fish profit (per eth)
    }
    
    /**
    * storage
    */
    
    Fish[] fishes;

    Counters.Counter private _totalSupply;
    
    uint256 public totalShares;
    
    uint256 public balanceFishes;
    uint256 public balanceOwner;
    uint256 public balanceMarketing;
    
    string private _prefixURI;
    string private _postfixURI;
    
    /**
    * constants
    */
    
    uint256 public constant minPayment = 10000000000000000;   // 10000000 = 10 trx
    uint8 public constant percentFeeFishesInput = 10;
    uint8 public constant percentFeeFishesOutput = 5;
    uint8 public constant percentFeeFishesBite = 20;
    
    uint8 public constant percentFeeParentInputLevel1 = 5;
    uint8 public constant percentFeeParentInputLevel2 = 3;
    uint8 public constant percentFeeParentInputLevel3 = 2;
    
    uint8 public constant percentFeeMarketingInput = 10;
    uint8 public constant percentFeeAdminOutput = 5;
    uint8 public constant percentFeeAdminBite = 10;
    
    uint8 public constant percentFeed = 5;
    
    //!!! изменить
    //uint64 public constant pausePrey = 3 days;
    //uint64 public constant pauseHunter = 1 days;
    
    uint64 public constant pausePrey = 3 minutes;
    uint64 public constant pauseHunter = 1 minutes;
    
    /**
    * owner functions
    */
    
    event WithdrawalMarketing(
        address indexed to, 
        uint256 value
    );
    event WithdrawalOwner(
        address indexed to, 
        uint256 value
    );
    
    function withdrawalMarketing(address to, uint256 value) external onlyOwner {
        balanceMarketing=balanceMarketing.sub(value);
        emit WithdrawalMarketing(to, value);
        
        to.transfer(value);
    }
    
    function withdrawalOwner(address to, uint256 value) external onlyOwner {
        balanceOwner=balanceOwner.sub(value);
        emit WithdrawalOwner(to, value);
        
        to.transfer(value);
    }
    
    function updateURI(string memory prefix, string memory postfix) public onlyOwner {
        _prefixURI=prefix;
        _postfixURI=postfix;
    }
    
    //!!! изменить
    //constructor() public ERC721Metadata("Tron.KillFish.io", "FISH")  {
        
    constructor() public ERC721Metadata("KF", "F")  {
        
        //!!! изменить
        //updateURI("https://tron.killfish.io/token/", "/");
        
        updateURI("https://", "/");
        
        Fish memory newFish=Fish({
            genes: 0,
            nickname: "null",
            parentId: 0,
            birthTime: uint64(now),
            feedTime: uint64(now),
            huntTime: uint64(now), 
            share: 0,
            feedValue: 0,
            eatenValue: 0,
            profitValue: 0
        });
        fishes.push(newFish);
        
        _totalSupply.increment();
        _mint(address(0), 0);
        
        emit CreateFish(0, fishes[0].genes, fishes[0].nickname, fishes[0].parentId, fishes[0].share, fishes[0].feedValue, 0);
    }
    
    /**
    * ERC721 functions
    */
    
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return _strConcat(_prefixURI,_uint2str(tokenId),_postfixURI);
    }
    
    function implementsERC721() external pure returns (bool) {
        return true;
    }
    
    function totalSupply() public view returns (uint256 total) {
        return _totalSupply.current();
    }
    
    function transfer(address to, uint256 tokenId) external {
        transferFrom(ownerOf(tokenId), to, tokenId);
    }
    
    /**
     * fish functions
     */
    
    event CreateFish(
        uint256 indexed tokenId,
        uint64 genes,
        string nickname,
        uint256 parentId,
        uint256 share,
        uint256 feedValue,
        uint256 eatenValue
    );
    event FeedFish(
        uint256 indexed tokenId,
        uint256 share,
        uint256 feedValue,
        uint256 eatenValue
    );
    event FeedParentFish(
        uint256 indexed tokenId,
        uint256 indexed childId,
        uint8 level,
        uint256 share,
        uint256 feedValue,
        uint256 profitValue
    );
    event DestroyFish(
        uint256 indexed tokenId,
        uint256 share,
        uint256 withdrawal
    );    
    event BiteFish(
        uint256 indexed tokenId,
        uint256 indexed preyId,
        uint256 hunterShare,
        uint256 hunterFeedValue,
        uint256 preyShare,
        uint256 preyFeedValue,
        uint256 feeValue
    );
    event UpdateNickname(
        uint256 indexed tokenId,
        string nickname
    );    
    
    modifier onlyOwnerOf(uint256 tokenId) {
        require(msg.sender == ownerOf(tokenId), "not token owner");
        _;
    }
    
    function createFish(string nickname, uint256 parentId) external payable returns (uint256) {
        require(msg.value>=minPayment.mul(10), "msg.value < minPayment*10");
        require(parentId<totalSupply(), "bad parentId");
        
        uint256 localParentId=parentId;
        uint256 feeParentLevel1=0;
        uint256 feeParentLevel2=0;
        uint256 feeParentLevel3=0;
        uint256 feeMarketing=msg.value.mul(percentFeeMarketingInput).div(100);
        
        if (statusLive(localParentId)) {
            
            feeParentLevel1=msg.value.mul(percentFeeParentInputLevel1).div(100);
            _feedParentFish(localParentId, totalSupply(), 1, feeParentLevel1);
            localParentId=fishes[localParentId].parentId;
            
            if (statusLive(localParentId)) {
                
                feeParentLevel2=msg.value.mul(percentFeeParentInputLevel2).div(100);
                _feedParentFish(localParentId, totalSupply(), 2, feeParentLevel2);
                localParentId=fishes[localParentId].parentId;
                
                if (statusLive(localParentId)) {
                    
                    feeParentLevel3=msg.value.mul(percentFeeParentInputLevel3).div(100);
                    _feedParentFish(localParentId, totalSupply(), 3, feeParentLevel3);
                    
                }    
            }
            
            feeMarketing=feeMarketing.sub(feeParentLevel1).sub(feeParentLevel2).sub(feeParentLevel3);
        }
        
        uint256 feeFishes=msg.value.mul(percentFeeFishesInput).div(100);
        uint256 value=msg.value.sub(feeMarketing).sub(feeFishes).sub(feeParentLevel1).sub(feeParentLevel2).sub(feeParentLevel3);
        
        balanceFishes=balanceFishes.add(value).add(feeFishes);
        balanceMarketing=balanceMarketing.add(feeMarketing);
        
        uint256 share=_newShare(value);
        
        totalShares=totalShares.add(share);
        
        Fish memory newFish=Fish({
            genes: _newGenes(),
            nickname: nickname,
            parentId: parentId,
            birthTime: uint64(now),
            feedTime: uint64(now),
            huntTime: uint64(now), 
            share: share,
            feedValue: _newFeedValue(share),
            eatenValue: value,
            profitValue: 0
        });
        uint256 newTokenId = fishes.push(newFish).sub(1);
        
        _totalSupply.increment();
        _mint(msg.sender,newTokenId);
        
        emit CreateFish(newTokenId, fishes[newTokenId].genes, fishes[newTokenId].nickname, fishes[newTokenId].parentId, fishes[newTokenId].share, fishes[newTokenId].feedValue, value);
        
        return newTokenId;
    }
    
    function feedFish(uint256 tokenId) external payable returns (bool) {
        require(msg.value>=minPayment, "msg.value < minPayment");
        require(statusLive(tokenId), "fish dead");
        
        uint256 localParentId=fishes[tokenId].parentId;
        uint256 feeParentLevel1=0;
        uint256 feeParentLevel2=0;
        uint256 feeParentLevel3=0;
        uint256 feeMarketing=msg.value.mul(percentFeeMarketingInput).div(100);
        
        if (statusLive(localParentId)) {
            
            feeParentLevel1=msg.value.mul(percentFeeParentInputLevel1).div(100);
            _feedParentFish(localParentId, tokenId, 1, feeParentLevel1);
            localParentId=fishes[localParentId].parentId;
            
            if (statusLive(localParentId)) {
                
                feeParentLevel2=msg.value.mul(percentFeeParentInputLevel2).div(100);
                _feedParentFish(localParentId, tokenId, 2, feeParentLevel2);
                localParentId=fishes[localParentId].parentId;
                
                if (statusLive(localParentId)) {
                    
                    feeParentLevel3=msg.value.mul(percentFeeParentInputLevel3).div(100);
                    _feedParentFish(localParentId, tokenId, 3, feeParentLevel3);
                    
                }    
            }
            
            feeMarketing=feeMarketing.sub(feeParentLevel1).sub(feeParentLevel2).sub(feeParentLevel3);
        }
        
        uint256 feeFishes=msg.value.mul(percentFeeFishesInput).div(100);
        uint256 value=msg.value.sub(feeMarketing).sub(feeFishes).sub(feeParentLevel1).sub(feeParentLevel2).sub(feeParentLevel3);
        
        balanceFishes=balanceFishes.add(value).add(feeFishes);
        balanceMarketing=balanceMarketing.add(feeMarketing);
        
        uint256 share=_newShare(value);
        
        totalShares=totalShares.add(share);
        fishes[tokenId].share=fishes[tokenId].share.add(share);
        fishes[tokenId].eatenValue=fishes[tokenId].eatenValue.add(value);
        
        if (value<fishes[tokenId].feedValue) {
            fishes[tokenId].feedValue=fishes[tokenId].feedValue.sub(value);
        } else {
            fishes[tokenId].feedValue=_newFeedValue(fishes[tokenId].share);
            fishes[tokenId].feedTime=uint64(now);
            fishes[tokenId].huntTime=uint64(now);
        }
        
        emit FeedFish(tokenId, share, fishes[tokenId].feedValue, value);
        
        return true;
    }
    
    function _feedParentFish(uint256 tokenId, uint256 childId, uint8 level, uint256 value) private {
        
        balanceFishes=balanceFishes.add(value);
        
        uint256 share=_newShare(value);
        
        totalShares=totalShares.add(share);
        fishes[tokenId].share=fishes[tokenId].share.add(share);
        fishes[tokenId].profitValue=fishes[tokenId].profitValue.add(value);
        
        if (value<fishes[tokenId].feedValue) {
            fishes[tokenId].feedValue=fishes[tokenId].feedValue.sub(value);
        } else {
            fishes[tokenId].feedValue=_newFeedValue(fishes[tokenId].share);
            fishes[tokenId].feedTime=uint64(now);
            fishes[tokenId].huntTime=uint64(now);
        }
        
        emit FeedParentFish(tokenId, childId, level, share, fishes[tokenId].feedValue, value);
        
    }
    
    function destroyFish(uint256 tokenId) external onlyOwnerOf(tokenId) returns (bool) {
        
        address owner=ownerOf(tokenId);
        uint256 share=fishes[tokenId].share;
        uint256 withdrawal=shareToValue(share);
        uint256 feeFishes=withdrawal.mul(percentFeeFishesOutput).div(100);
        uint256 feeAdmin=withdrawal.mul(percentFeeAdminOutput).div(100);
        
        withdrawal=withdrawal.sub(feeFishes).sub(feeAdmin);
        
        totalShares=totalShares.sub(share);
        fishes[tokenId].share=0;
        fishes[tokenId].feedValue=0;
        fishes[tokenId].nickname="";
        fishes[tokenId].feedTime=uint64(now);
        
        _transferFrom(owner, address(0), tokenId);
        
        balanceOwner=balanceOwner.add(feeAdmin);
        balanceFishes=balanceFishes.sub(withdrawal).sub(feeAdmin);
        
        emit DestroyFish(tokenId, share, withdrawal);
        
        owner.transfer(withdrawal);
        
        return true;   
    }
    
    function biteFish(uint256 tokenId, uint256 preyId) external onlyOwnerOf(tokenId) returns (bool) {
        require(statusLive(preyId), "prey dead");
        require(statusPrey(preyId), "not prey");
        require(statusHunter(tokenId), "not hunter");
        require(fishes[preyId].share<fishes[tokenId].share, "too much prey");
        
        uint256 sharePrey;
        uint256 shareHunter;
        uint256 shareFishes;
        uint256 shareAdmin;
        uint256 value; 
        
        if (shareToValue(fishes[preyId].share)<minPayment.mul(2)) {
            sharePrey=fishes[preyId].share;
            
            _transferFrom(ownerOf(preyId), address(0), preyId);
            fishes[preyId].nickname="";
        } else {
            sharePrey=fishes[preyId].share.mul(percentFeed).div(100);
            
            if (shareToValue(sharePrey)<minPayment) {
                sharePrey=valueToShare(minPayment);
            }

        }
        
        shareFishes=sharePrey.mul(percentFeeFishesBite).div(100);
        shareAdmin=sharePrey.mul(percentFeeAdminBite).div(100);
        shareHunter=sharePrey.sub(shareFishes).sub(shareAdmin);
        
        fishes[preyId].share=fishes[preyId].share.sub(sharePrey);
        fishes[tokenId].share=fishes[tokenId].share.add(shareHunter);
        
        //update prey
        
        fishes[preyId].feedValue=_newFeedValue(fishes[preyId].share);
        fishes[preyId].feedTime=uint64(now);
        
        //update hunter
        
        value=shareToValue(shareHunter);
        
        if (value<fishes[tokenId].feedValue) {
            fishes[tokenId].feedValue=fishes[tokenId].feedValue.sub(value);
        } else {
            fishes[tokenId].feedValue=_newFeedValue(fishes[tokenId].share);
            fishes[tokenId].feedTime=uint64(now);
        }
        
        fishes[tokenId].profitValue=fishes[tokenId].profitValue.add(value);
        fishes[tokenId].huntTime=uint64(now);
        
        //update fee
        
        value=shareToValue(shareAdmin);
        
        totalShares=totalShares.sub(shareFishes).sub(shareAdmin);
        
        balanceOwner=balanceOwner.add(value);
        balanceFishes=balanceFishes.sub(value);

        emit BiteFish(tokenId, preyId, shareHunter, fishes[tokenId].feedValue, sharePrey, fishes[preyId].feedValue, value);

        return true;        
    }
    
    function updateNickname(uint256 tokenId, string nickname) external onlyOwnerOf(tokenId) returns (bool) {
        
        fishes[tokenId].nickname=nickname;
        
        emit UpdateNickname(tokenId, nickname);
        
        return true;
    }
    
    /**
     * utilities
     */
    
    function getFish(uint256 tokenId) public view
        returns (
        uint64 genes,
        string memory nickname,
        uint256 parentId,
        uint64 birthTime,
        uint64 feedTime,
        uint64 huntTime,
        uint256 share,
        uint256 feedValue,
        uint256 eatenValue,
        uint256 profitValue
    ) {
        Fish memory fish=fishes[tokenId];
        
        genes=fish.genes;
        nickname=fish.nickname;
        parentId=fish.parentId;
        birthTime=fish.birthTime;
        feedTime=fish.feedTime;
        huntTime=fish.huntTime;
        share=fish.share; 
        feedValue=fish.feedValue; 
        eatenValue=fish.eatenValue;
        profitValue=fish.profitValue;
    }

    function statusLive(uint256 tokenId) public view returns (bool) {
        if (fishes[tokenId].share==0) {return false;}
        return true;
    }
    
    function statusPrey(uint256 tokenId) public view returns (bool) {
        if (now<=fishes[tokenId].feedTime.add(pausePrey)) {return false;}
        return true;
    }
    
    function statusHunter(uint256 tokenId) public view returns (bool) {
        if (now<=fishes[tokenId].huntTime.add(pauseHunter)) {return false;}
        return true;
    }
    
    function shareToValue(uint256 share) public view returns (uint256) {
        if (totalShares == 0) {return 0;}
        return share.mul(balanceFishes).div(totalShares);
    }
    
    function valueToShare(uint256 value) public view returns (uint256) {
        if (balanceFishes == 0) {return 0;}
        return value.mul(totalShares).div(balanceFishes);
    }
    
    function _newShare(uint256 value) private view returns (uint256) {
        if (totalShares == 0) {return value;}
        return value.mul(totalShares).div(balanceFishes.sub(value));
    }
    
    function _newFeedValue(uint256 share) private view returns (uint256) {
        uint256 value=shareToValue(share);
        return value.mul(percentFeed).div(100);
    }
    
    function _newGenes() private view returns(uint64) {
        return uint64(uint256(keccak256(abi.encodePacked(now, totalShares, balanceFishes)))%(10**11));
    }
    
    function _strConcat(string memory _a, string memory _b, string memory _c) private pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        string memory abc = new string(_ba.length + _bb.length + _bc.length);
        bytes memory babc = bytes(abc);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babc[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babc[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babc[k++] = _bc[i];
        }
        return string(babc);
    }
    
    function _uint2str(uint _i) private pure returns (string memory _uintAsString) {
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