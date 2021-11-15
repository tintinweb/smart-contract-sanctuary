pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";



interface iFeed {
    function feed (uint256) external ;
    function BattleAttack (uint256) external returns(uint256) ;
     function Attack (uint256, uint256) external returns(uint256) ;
     function _levelUp(uint256) external;
     function _levelDown(uint256) external;
     function ownerOf(uint256) external;
     function AFighter ( address addr, uint256 _tokenId) external returns (uint256);
     function getStrength (uint256) external returns (uint256);
     function getDogeOwner(uint256 tokenId) external returns(address);
     function getDogeCaptureTime(uint256 tokenId) external returns(uint256);
     function dogeNapped(address addr, uint256 tokenId) external;
}

contract dogpound{


    event GameCreated(address player, uint256 tokenId, uint256 _tokenId);
    event GameJoined(uint256 index, address player);
    event GameResult(uint256 index, address winner, uint256 amount);
    event NewDoge (string name);
    event Transfer (address to, uint256 amount, uint256 balance);
    event DogeCaptured(uint256 tokenId, address pirate);

    address public addy;
    address public raddy;
    address private addr;
    address public Owner = msg.sender;
    mapping(address => uint256) public DogeFighter;
    address fighterAddy;
    uint256 _num;
    uint256 equationResult;
    uint256 public g;
    

    uint256 index;
    mapping(uint256 => Game) gameIndex;
    mapping(bytes32 => Game) requestIndex;

    struct Game {
        uint256 index;
        uint256 player1;
        uint256 player2;
        uint256 amount;
        address winner;
       uint256 blockstamp;
        
    }
    
    

    modifier onlyOwner(){
        require(msg.sender == Owner);
        _;
    }
    modifier HasTransferApproval(uint256 tokenId){
        IERC721 tokenContract = IERC721(addy);
        require(tokenContract.getApproved(tokenId) == address(this));
        _;
    }
    
    function feed(uint256 _tokenId) external payable {
        iFeed(addy).feed(_tokenId);
    
    
    }

    function withdraw() public payable onlyOwner{
       require (payable(msg.sender).send(address(this).balance));
   }

   function setAddy(address _addy)public onlyOwner returns(address){
           addy = _addy;
           return addy;


   }

   function BattleAttack(uint256 _tokenId) external {
       iFeed(addy).BattleAttack(_tokenId);

   }

   function Attack(uint256 tokenId, uint256 _tokenId) external{
       iFeed(addy).Attack(tokenId , _tokenId);
   }

    function AFighter (uint256 _tokenId) public {
        iFeed(addy).AFighter(msg.sender,_tokenId);
      

   }

   function Battle (uint256 tokenId, uint256 _tokenId) public returns (address _winner){
       uint256 a = iFeed(addy).getStrength(tokenId);
       uint256 b = iFeed(addy).getStrength(_tokenId);
       uint256 c = a + b ;

        bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) ));
           //bytes2 equation = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes2(predictableRandom[2]) >> 16 );
        uint256 base = 35+((55*uint256(uint8(predictableRandom[3])))/255);



       _num = 100+((55*uint256(uint8(predictableRandom[3])))/255) / 2;

       equationResult = ((_num +block.timestamp * base) % base);
       g =  equationResult % 3;

       if (((a % g)/c) > ((b % g)/c)){
            iFeed(addy)._levelUp(tokenId);
            iFeed(addy)._levelDown(_tokenId);
            _winner = iFeed(addy).getDogeOwner(tokenId);
          }

          else{
              iFeed(addy)._levelUp(_tokenId);
              iFeed(addy)._levelDown(tokenId);
              _winner = iFeed(addy).getDogeOwner(_tokenId);
          }

        Game memory newGame = Game(index, tokenId, _tokenId, _num, _winner, block.timestamp);
        gameIndex[index] = newGame;
        //index += 1;

        emit GameCreated(msg.sender, tokenId, _tokenId);

       return(_winner);
   } 
   
   function get_game_info(uint256 _index) external view returns(uint256 _i, uint256 tokenId, uint256 _tokenId, uint256 _number, address _winner, uint256 blockstamp) {
       
        Game memory game = gameIndex[_index];
        return (_index, game.player1, game.player2, game.amount, game.winner, block.timestamp);
    }

    function captureDoge(uint256 tokenId)  external  payable HasTransferApproval(tokenId){

        //require(msg.value >=itemsForSale[id].askingPrice, "not enough funds sent");
        require(msg.sender != iFeed(addy).getDogeOwner(tokenId));
        
        uint256 death = (iFeed(addy).getDogeCaptureTime(tokenId) - block.timestamp);
        address  dogOwner = iFeed(addy).getDogeOwner(tokenId);
        require(msg.value == 0.05 ether);


        if (death <= 0 ){

        //itemsForSale[id].isSold = true;
        //activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false;
        IERC721(addy).safeTransferFrom(iFeed(addy).getDogeOwner(tokenId), msg.sender, tokenId);
       payable(dogOwner).transfer(msg.value);
       } else {
           revert();
       }

        //emit itemSold(id, msg.sender, itemsForSale[id].askingPrice);
        emit DogeCaptured(tokenId, msg.sender);
    }

    function napdoge(uint256 tokenId) public {
          
          iFeed(raddy).dogeNapped(msg.sender, tokenId);

    }
    

    function setRaddy(address _raddy)public onlyOwner returns(address){
           raddy = _raddy;
           return raddy;


   }
   

   
    
    
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

