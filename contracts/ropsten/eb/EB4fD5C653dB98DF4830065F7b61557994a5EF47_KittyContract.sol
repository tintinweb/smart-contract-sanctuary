/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}




library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}




abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}








abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}




interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}



//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract KittyContract is IERC721,Ownable, Pausable {
    using SafeMath for uint256;
    
    event Birth(
        address owner, 
        uint256 kittenId, 
        uint256 mumId, 
        uint256 dadId, 
        uint256 genes
    );
 
    mapping (address => uint256) private ownershipTokenCount;
    mapping (uint256 => address) private ownershipTokenID;
    mapping (uint256 => address) private kittyIndexToApproved;
    mapping (address => mapping(address => bool)) private _operatorApprovals; 

    
    string  constant  private tName = 'Carlos Kitty Token';
    string  constant private tSymbol = 'CKT';
    bytes4 internal constant MAGIC_ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")); // from IERC721 interface

    struct Kitty {
        uint256 genes;
        uint64 birthTime;
        uint32 mumId;
        uint32 dadId;
        uint16 generation;
    }
    Kitty[] kitties;
    
    function close() onlyOwner public {
        address closeOwner = owner();
        selfdestruct(payable(closeOwner)); 
    }

    function pause() external  onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external   onlyOwner whenPaused {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId) external pure override  returns(bool){ // FOR ERC765
        return interfaceId == type(IERC165).interfaceId;
    }

    function breed(uint256 _dadId, uint256 _mumId) public whenNotPaused  {
        require(_dadId < kitties.length &&_mumId < kitties.length);
        require(ownershipTokenID[_dadId]==  msg.sender && ownershipTokenID[_mumId]== msg.sender); // check ownership 
        uint256 dadDna = kitties[_dadId].genes; // you got the DNA 
        uint256 mumDna = kitties[_mumId].genes;
        uint256 newGen;  // figure out the generation
        if(kitties[_dadId].generation >= kitties[_mumId].generation){
            newGen = kitties[_dadId].generation + 1;
        }
        else 
        {
            newGen = kitties[_mumId].generation + 1;
        }
        uint256 newDna= _mixDna(dadDna, mumDna);
        _createKitty(_mumId, _dadId, newGen,newDna, msg.sender); // create a new cat with te new properties, give it to the msg.sender   
    }

    function balanceOf(address owner) external view override whenNotPaused returns (uint256 balance){
        return ownershipTokenCount[owner];
    }

    function totalSupply() external view whenNotPaused returns (uint256 total) {
        return kitties.length;
    }

    function name() external pure  returns (string memory tokenName) {
        return tName;
    }

    function symbol() external pure  returns (string memory tokenSymbol) {
        return tSymbol;
    }

    function ownerOf(uint256 tokenId) external view override whenNotPaused returns (address owner) {
        return ownershipTokenID[tokenId];
    }

    function transfer(address to, uint256 tokenId) external  payable whenNotPaused {
        require(to != address(0)); //`to` cannot be the zero address.
        require(to != address(this)); // to` can not be the contract address.
        require(_owns(msg.sender, tokenId));    // tokenId` token must be owned by `msg.sender`
        _transfer(msg.sender, to, tokenId);
        emit Transfer(msg.sender, to, tokenId); // Emits a {Transfer} event.
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        ownershipTokenID[_tokenId] = _to;       
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete kittyIndexToApproved[_tokenId];
        }
        emit Transfer(_from, _to, _tokenId);
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return ownershipTokenID[_tokenId] == _claimant;
    }

    function _createKitty(
        uint256 _mumId,
        uint256 _dadId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    ) private returns (uint256) {
        Kitty memory _kitty = Kitty({
            genes: _genes,
            birthTime: uint64(block.timestamp),
            mumId: uint32(_mumId),
            dadId: uint32(_dadId),
            generation: uint16(_generation)
        });
        kitties.push(_kitty);
        uint256 newKittenId = kitties.length - 1;
        emit Birth(_owner, newKittenId, _mumId, _dadId, _genes);
        _transfer(address(0), _owner, newKittenId);
        return newKittenId;
    }

    function createKittyGen0(uint256 genes)  public payable whenNotPaused returns (uint256) { // anyone can create generation 0 kitty 
        return _createKitty(0, 0, 0, genes, msg.sender);
    }

    function getKitty(uint256 kittyId) public view whenNotPaused returns(uint256, uint64, uint32, uint32, uint16){
             return (kitties[kittyId].genes, kitties[kittyId].birthTime, kitties[kittyId].mumId,
             kitties[kittyId].dadId, kitties[kittyId].generation); 
    }

    function approve(address _approved, uint256 _tokenId) external override whenNotPaused{
        require(_owns(msg.sender, _tokenId),"msg.sender is not the owner");
        kittyIndexToApproved[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId, address from) external whenNotPaused {
        require(_owns(from, _tokenId),"msg.sender is not the owner");
        kittyIndexToApproved[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }
    
    function getApproved(uint256 _tokenId) external view override whenNotPaused  returns (address) {
        require(ownershipTokenID[_tokenId]== msg.sender, "You are not the owner of the tokenId");
        require(_tokenId < kitties.length, "the tokenID does not exist");    
        return kittyIndexToApproved[_tokenId];
    }
    
    function setApprovalForAll(address _operator, bool _approved) external override whenNotPaused {
        require(_operator != msg.sender);
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator,_approved);
    }
    
    function isApprovedForAll(address _owner, address _operator) external view override whenNotPaused returns (bool) {
         return _operatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external override whenNotPaused {
        require(_to != address(0)); 
        //require(_to != address(this)); 
        require(_owns(msg.sender, _tokenId) || kittyIndexToApproved[_tokenId] == msg.sender || _operatorApprovals[_from][msg.sender] == true);
        //Throws unless `msg.sender` is the current owner or is the approved address for this NFT or  is an authorized operator
        require(_owns(_from, _tokenId)); //Throws if `_from` is not the current owner
        require(_tokenId < kitties.length, "the tokenID does not exist"); 
        _transfer(_from,  _to,  _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external override whenNotPaused{
        require(_owns(msg.sender, _tokenId) || kittyIndexToApproved[_tokenId] == msg.sender || _operatorApprovals[_from][msg.sender] == true);
        require(_owns(_from, _tokenId));
        require(_to != address(0));
        require(_tokenId < kitties.length, "the tokenID does not exist");
        _SafeTransferFrom(_from, _to, _tokenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override whenNotPaused{
        require(_owns(msg.sender, _tokenId) || kittyIndexToApproved[_tokenId] == msg.sender || _operatorApprovals[_from][msg.sender] == true);
        require(_owns(_from, _tokenId));
        require(_to != address(0));
        require(_tokenId < kitties.length, "the tokenID does not exist");
        _SafeTransferFrom(_from, _to, _tokenId, '0');
    }

    function _SafeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) internal {
        _transfer(_from, _to, _tokenId);
        require(_checkERC721Support(_from, _to, _tokenId, _data));
    }

    function _checkERC721Support(address _from, address _to, uint256 _tokenId, bytes memory _data) internal returns(bool){
        if(!_isContract(_to)){ // if the address is not a contract is easy otherwise you need to know if this contract can manipulate ERC721 tokens
            return true;    
        }
        bytes4 returnData = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data); // call onERC721Received() function(in ERC721 you must include this function) on IERC721Receiver contract
        return returnData == MAGIC_ERC721_RECEIVED;
    }

    function _isContract(address _to) internal view returns (bool){
        uint32 size; 
        assembly { // only to talk directly.  machine code 
            size := extcodesize(_to) // gets the size 
        }
        return size > 0; // for a contract must be > 0 
    }

    function _mixDna(uint256 _dadDna, uint256 _mumDna) internal pure returns (uint256){
        uint256 mod= 10000000000000000;
        uint256 div= 100000000000000;
        uint256 newDna= 0;
        uint i;

        for (i=1; i<=8; i++){
            if(i%2==0) {// _dadDna wins 
            newDna = (newDna*100)+((_dadDna%mod)/div);
            }
            else { // _mumDna wins
            newDna = (newDna*100)+((_mumDna%mod)/div);
            }
            mod = mod/100;
            div = div/100;
        }
        return newDna;
    }
        
}