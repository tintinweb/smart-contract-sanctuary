/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
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

// File: KittyKitty.sol


pragma solidity >=0.6.12 <=0.8.5;




/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4) ;
}


contract Kittycontract is IERC721, Ownable {
    using Strings for uint256;

    string public baseURIStored = "";

    mapping(address => uint256) public tokenHolders;
    mapping(uint256 => address) public kittyOwners;

    mapping(uint256 => address) public kittyIndexToApproved;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 public constant CREATION_LIMIT_GEN0 = 10;
    uint256 public constant CREATION_LIMIT_USER = 100;
    string public constant _name = "KittyKittys";
    string public constant _symbol = "KTK";

    bytes4 internal constant MAGIC_ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    Kitty[] public kitties;

    struct Kitty {
        uint256 genes;
        uint64 birthTime;
        uint32 mumId;
        uint32 dadId;
        uint16 generation;
    }

    // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    // event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    // event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Birth(
        address owner, 
        uint256 kittenId, 
        uint256 mumId, 
        uint256 dadId, 
        uint256 genes
    );

    uint256 public gen0Counter;
    uint256 public userCounter;

    constructor(){
        _createKitty(0, 0, 0, uint256(1), address(0));
    }

    // SETTER FUNCTIONS
    function createKittyGen0(uint256 _genes) public onlyOwner returns (uint256) {
       require(gen0Counter < CREATION_LIMIT_GEN0);
       gen0Counter++;

       uint256 kittyId = _createKitty(0,0,0,_genes,msg.sender);
       return kittyId;
    }

    function createKitty(uint256 _genes) public payable returns (uint256) {
       require(userCounter < CREATION_LIMIT_USER);
       require(msg.sender!= owner());
       require(msg.value == .02 ether);
       userCounter++;

       uint256 kittyId = _createKitty(0,0,1,_genes,msg.sender);
       return kittyId;
    }
    
    function breed(uint256 _dadId, uint256 _mumId) public returns (uint256) {
       require(_owns(msg.sender, _dadId) && _owns(msg.sender, _mumId));

       ( uint256 dadDna,,,,uint256 dad_generation ) = getKitty(_dadId);
       ( uint256 mumDna,,,,uint256 mum_generation ) = getKitty(_mumId);
       uint256 newDna = _mixDna(dadDna, mumDna);
       uint256 kidGen = 0;

       if(dad_generation <= mum_generation){
          kidGen = mum_generation + 1;
       }
       else if (dad_generation > mum_generation){
          kidGen = dad_generation + 1;
          kidGen /= 2;
       } 
       else{
          kidGen = mum_generation;
       }
       _createKitty( _mumId, _dadId, uint16(kidGen), newDna, msg.sender);
       return newDna;
    }

    function _mixDna(uint256 _dadDna, uint256 _mumDna) internal view returns (uint256) {
       uint256[8] memory geneArray;
       uint8 random = uint8( block.timestamp % 255 );
       uint256 i;
       uint256 index = 7;
       // Loop thru random number with bitwise operator(&)
       for(i = 1; i <= 128; i = i*2){
           if(random & i != 0){
               geneArray[index] = uint8( _dadDna % 100 );
           }
           else{
               geneArray[index] = uint8( _mumDna % 100 );
           }
           _mumDna = _mumDna / 100;
           _dadDna = _dadDna / 100;
           index --;
       }
       // create new Gene from geneArray
       uint256 newGene;
       for( i = 0; i < 8; i++){
           newGene = newGene + geneArray[i];
           if(i != 7){
           newGene = newGene * 100;
           }  
       }
       return newGene;
    }

    function _createKitty(
        uint256 _mumId, 
        uint256 _dadId, 
        uint16 _generation, 
        uint256 _genes, 
        address _owner
    )private returns (uint256) {
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

    function setApprovalForAll(address _operator, bool _approved) public override{
        require(_operator != msg.sender);

        _setApprovalForAll(msg.sender, _operator, _approved);
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // TRANSFER AND APPROVAL FUNCTIONS
    function transfer(address _to, uint256 kittenId) public {
        require (_to != address(0), "address doesn't exist" );
        require (_to != address(this), "address cannot be contract address");
        require (_owns(msg.sender, kittenId), "token doesn't belong to caller");

        _transfer(msg.sender, _to, kittenId);
    }

    function approve(address _approved, uint256 kittenId) public override{
        require(_owns(msg.sender, kittenId));

        _approve(kittenId, _approved);
        emit Approval(msg.sender, _approved, kittenId);
    }

    function _safeTransfer(address _from, address _to, uint256 kittenId, bytes memory _data) internal { 
        _transfer(_from, _to, kittenId);
        require(_checkERC721Support(_from, _to, kittenId, _data));
    } 

    function _transfer( address _from, address _to, uint256 kittenId) internal { 
        tokenHolders[_to]++;
        kittyOwners[kittenId] = _to;

        if (_from != address(0)){
           tokenHolders[_from]--;
           delete kittyIndexToApproved[kittenId];
        }
    
        emit Transfer(_from, _to, kittenId);
    }

    function transferFrom(address _from, address _to, uint256 kittenId) public override{
        require( _isApprovedOrOwner(msg.sender, _from, _to, kittenId) );   
        _transfer(_from, _to, kittenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 kittenId, bytes memory data) public override{
        require( _isApprovedOrOwner(msg.sender, _from, _to, kittenId) ); 
        _safeTransfer(_from, _to, kittenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint256 kittenId) public override{
        safeTransferFrom(_from, _to, kittenId, "");
    }

    function _approve(uint256 _kittenId, address _approved) internal {
        kittyIndexToApproved[_kittenId] = _approved;
    }

    function _setApprovalForAll(address _owner, address _operator, bool _approved) internal {
        _operatorApprovals[_owner][_operator] = _approved;
    }

    // function withdrawAll() public onlyOwner returns(bool) { 
    //     payable(msg.sender).transfer(address(this).balance);
    // }
    function withdrawAll() public onlyOwner{ 
        payable(msg.sender).transfer(address(this).balance);
    }
    


    // GETTER FUNCTIONS
    function _checkERC721Support(address _from, address _to, uint256 kittenId, bytes memory _data) internal returns (bool) {
        if (!_isContract(_to) ){
            return true;
        }
        bytes4 returnData = IERC721Receiver(_to).onERC721Received(msg.sender, _from, kittenId, _data);
        return returnData == MAGIC_ERC721_RECEIVED;
    }

    function getKitty(uint256 _kittenId) public view returns (
        uint256 genes,
        uint256 mumId, 
        uint256 dadId, 
        uint256 birthTime, 
        uint256 generation
    )
    {
        Kitty storage kitty = kitties[_kittenId];
        
        genes = uint256(kitty.genes); 
        mumId = uint256(kitty.mumId);
        dadId = uint256(kitty.dadId);
        birthTime = uint256(kitty.birthTime); 
        generation = uint256(kitty.generation);
    }

    function tokensOfOwner(address _owner) public view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } 
        else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalCats = totalSupply();
            uint256 resultIndex = 0;

            uint256 catId;

            for (catId = 0; catId < totalCats; catId++) {
                if (kittyOwners[catId] == _owner) {
                    result[resultIndex] = catId;
                    resultIndex++;
                }
            }
            return result;
            }
    }

    function _isContract(address _to) internal view returns (bool) {
        uint32 size;
        assembly{
            size := extcodesize(_to)
        }
        return size > 0;
    }

    function _owns(address _claimer, uint256 kittenId) internal view returns (bool) {
        return kittyOwners[kittenId] == _claimer;
    }

    function _approvedFor( address _claimant, uint256 kittenId) internal view returns (bool) {
        return kittyIndexToApproved[kittenId] == _claimant;
    }

    function _isApprovedOrOwner( address _sender, address _from, address _to, uint256 kittenId) internal view returns (bool){
        require (_owns(_from, kittenId)); //_from owns the token
        require (_to != address(0)); // _to address is not zero address
        require (kittenId < kitties.length); //Token must exist

        //Sender is from OR sender is approved for kittenId OR approvalForAll from _from
        return (_sender == _from
        || _approvedFor(_sender, kittenId)
        || isApprovedForAll(_from, _sender));
    }

    function getApproved(uint256 _kittenId) public view override returns (address){
        require (_kittenId < kitties.length);

        return kittyIndexToApproved[_kittenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool){
        return _operatorApprovals[_owner][_operator];
    }

    function supportsInterface(bytes4 _interfaceId) external pure override returns (bool) {
        return ( _interfaceId == _INTERFACE_ID_ERC721 || _interfaceId == _INTERFACE_ID_ERC165);
    }

    function balanceOf(address owner) public view override returns (uint256 balance) {
        return tokenHolders[owner];
    }
   
    function totalSupply() public view returns (uint256 total) {
        return kitties.length;
    }
  
    function name() external pure returns (string memory tokenName) {
        return _name;
    }

    function symbol() external pure returns (string memory tokenSymbol) {
        return _symbol;
    }

    function ownerOf(uint256 kittenId) public view override returns (address owner) {
        return kittyOwners[kittenId];
    }  

    function _baseURI() public view returns(string memory) {
        return baseURIStored;
    }

    function setBaseURI(string memory newURL) public onlyOwner returns (string memory){ //make sure to add / in end of all urls
        baseURIStored = newURL;
        return baseURIStored;
    }
    
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        address kittyOwner = ownerOf(tokenId);
        require(kittyOwner != address(0), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    
    
    
}