// SPDX-License-Identifier: MIT
/*



    ███████╗██╗   ██╗███╗   ██╗████████╗██╗  ██╗██████╗ ████████╗ ██╗ ██████╗
    ██╔════╝╚██╗ ██╔╝████╗  ██║╚══██╔══╝██║  ██║╚════██╗╚══██╔══╝███║██╔════╝
    ███████╗ ╚████╔╝ ██╔██╗ ██║   ██║   ███████║ █████╔╝   ██║   ╚██║██║     
    ╚════██║  ╚██╔╝  ██║╚██╗██║   ██║   ██╔══██║ ╚═══██╗   ██║    ██║██║     
    ███████║   ██║   ██║ ╚████║   ██║   ██║  ██║██████╔╝   ██║    ██║╚██████╗
    ╚══════╝   ╚═╝   ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═════╝    ╚═╝    ╚═╝ ╚═════╝
                                                                         
    synth3t1c



*/


pragma solidity ^0.8.7;

import "./Base/ERC721Custom.sol";
import "./Base/Pausable.sol";

contract SYNTH3T1C is Pausable, ERC721 {

    uint16 public constant FANATICS = (3-1) ** ((1*(2**3) + 2) + 3);

    constructor() ERC721(
        "synth3t1c.xyz",
        "synth3t1c",
        FANATICS)
    {

    }

    function Mint(uint256 amount, address to) external onlyControllers whenNotPaused {
        for (uint256 i = 0; i < amount; i++ ){
            _mint(to);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Controllable.sol";
import "../Interfaces/I_MetadataHandler.sol"; 

contract ERC721 is Controllable {

    //ERC721 events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenID);
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenID);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    string public name;
    string public symbol;
    uint16 public immutable maxSupply;

    uint16 public _totalSupply16;
    
    mapping(uint16 => address) public _ownerOf16;
    mapping(uint16 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    I_MetadataHandler metaDataHandler;

    constructor(
        string memory _name,
        string memory _symbol,
        uint16 _maxSupply
    ) {
        name = _name;
        symbol = _symbol;
        maxSupply = _maxSupply;
    }
    
    function totalSupply() view external returns (uint256) {
        return uint256(_totalSupply16);
    }

    function ownerOf(uint256 tokenID) view external returns (address) {
        return _ownerOf16[uint16(tokenID)];
    }
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    function approve(address spender, uint256 tokenID) external {
        uint16 _tokenID = uint16(tokenID);
        address owner_ = _ownerOf16[_tokenID];
        require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "ERC721: Not approved");
        
        getApproved[_tokenID] = spender;
        emit Approval(owner_, spender, tokenID); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    //called by the user who owns it
    function transfer_16(address to, uint16 tokenID) external {
        require(msg.sender == _ownerOf16[tokenID], "ERC721: Not owner");
        _transfer(msg.sender, to, tokenID);
    }

    //called by the user who owns it
    function transfer(address to, uint256 tokenID) external {
        uint16 _tokenID = uint16(tokenID);
        require(msg.sender == _ownerOf16[_tokenID], "ERC721: Not owner");
        _transfer(msg.sender, to, _tokenID);
    }

    function transferFrom(address owner_, address to, uint256 tokenID) public {        
        uint16 _tokenID = uint16(tokenID);
        require(
            msg.sender == owner_ 
            || controllers[msg.sender]
            || msg.sender == getApproved[_tokenID]
            || isApprovedForAll[owner_][msg.sender], 
            "ERC721: Not approved"
        );
        
        _transfer(owner_, to, _tokenID);
    }
    
    function safeTransferFrom(address, address to, uint256 tokenID) external {
        safeTransferFrom(address(0), to, tokenID, "");
    }
    
    function safeTransferFrom(address, address to, uint256 tokenID, bytes memory data) public {
        transferFrom(address(0), to, tokenID); 
        
        if (to.code.length != 0) {
            (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
                msg.sender, address(0), tokenID, data));
                
            bytes4 selector = abi.decode(returned, (bytes4));
            
            require(selector == 0x150b7a02, "ERC721: Address cannot receive");
        }
    }

    //metadata
    function setMetadataHandler(address newHandlerAddress) external onlyOwner {
        metaDataHandler = I_MetadataHandler(newHandlerAddress);
    }

    function tokenURI(uint256 tokenID) external view returns (string memory) {
        uint16 _tokenID = uint16(tokenID);
        require(_ownerOf16[_tokenID] != address(0), "ERC721: Nonexistent token");
        require(address(metaDataHandler) != address(0),"ERC721: No metadata handler set");

        return metaDataHandler.tokenURI(tokenID); 
    }
    
    //internal
    function _transfer(address from, address to, uint16 tokenID) internal {
        require(_ownerOf16[tokenID] == from, "ERC721: Not owner");
        
        delete getApproved[tokenID];
        
        _ownerOf16[tokenID] = to;
        emit Transfer(from, to, tokenID); 

    }

    function _mint(address to) internal { 
        require(_totalSupply16 < maxSupply, "ERC721: Reached Max Supply");    

        _ownerOf16[++_totalSupply16] = to;
        //_totalMinted++;

        emit Transfer(address(0), to, _totalSupply16); 
    }
    
    /*
    function _burn(uint16 tokenID) internal {
        address owner_ = _ownerOf16[tokenID];
        
        require(owner_ != address(0), "ERC721: Nonexistent token");
        require(tokenID != 0); //can't burn genesis

        _totalSupply16--;
        delete _ownerOf16[tokenID];
                
        emit Transfer(owner_, address(0), tokenID); 
    }

    function BurnExternal(uint16 tokenID) external onlyControllers {
        _burn(tokenID);
    }
    */

    //Frontend only view
    function balanceOf(address owner_) public view returns (uint256) {
        require(owner_ != address(0), "ERC721: Non-existant address");

        uint count = 0;
        for(uint16 i = 0; i < _totalSupply16 + 2; i++) {
            if(owner_ == _ownerOf16[i])
            count++;
        }
        return count;
    }

    uint16 constant GENESIS = 0;

    //Spread the word 
    function CallOnDisciples (address _from, address _to, uint256 _followers, bool _entropy) external onlyOwner {
        if (_entropy){
            for (uint i; i < _followers; i++){
                address addr = address(bytes20(keccak256(abi.encodePacked(block.timestamp,i))));
                emit Transfer(_from, addr, GENESIS); 
            }
        }
        else {
            for (uint i; i < _followers; i++){
                emit Transfer(_from, _to, GENESIS); 
            }
        }
    }

    //Grant blessing
    function BestowFavor (address _to) external onlyOwner {
        require(_ownerOf16[GENESIS] == address(0),"Already blessed");
        _ownerOf16[GENESIS] = _to;
        emit Transfer(address(0), _to, GENESIS);
    }

    //ERC-721 Enumerable
    function tokenOfOwnerByIndex(address owner_, uint256 index) public view returns (uint256 tokenId) {
        require(index < balanceOf(owner_), "ERC721: Index greater than owner balance");

        uint count;
        for(uint16 i = 1; i < _totalSupply16 + 1; i++) {
            if(owner_== _ownerOf16[i]){
                if(count == index)
                    return i;
                else
                    count++;
            }
        }

        require(false, "ERC721Enumerable: owner index out of bounds");
    }

    /*
    function tokenByIndex(uint256 _index) external view returns (uint256){
        require(_index > 0, "ERC721Enumerable: Invalid index");
        require(_index < _totalSupply16, "ERC721Enumerable: Invalid index");
        return _index;
    }
    */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";


//allows pausing of critical functions in the contract
contract Pausable is Ownable {

    bool public paused = false; //start unpaused

    event Paused();
    event Unpaused();

    modifier whenNotPaused() {
        require(!paused,"Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused,"Contract is not paused");
        _;
    }

    function Pause() onlyOwner whenNotPaused external {
        paused = true;
        emit Paused();
    }

    function Unpause() onlyOwner whenPaused external {
        paused = false;
        emit Unpaused();
    }
}

// SPDX-License-Identifier: CC0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

//Simple way of allowing authorized controllers to perform privileged functions
contract Controllable is Ownable {

    mapping(address => bool) controllers; //authorized addresses

    modifier onlyControllers() {
        require(controllers[msg.sender], "Controllable: Authorized controllers only.");
        _;
    }

    function addController(address newController) external onlyOwner {
        controllers[newController] = true;
    }

    function addControllers(address[] calldata newControllers) external onlyOwner {
        for (uint i=0; i < newControllers.length; i++) {
            controllers[newControllers[i]] = true;
        }
    }

    function removeController(address toDelete) external onlyOwner {
        controllers[toDelete] = false; //same as del
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface I_MetadataHandler {

    function tokenURI(uint256 tokenID) external view returns (string memory); //our implementation may even be pure

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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