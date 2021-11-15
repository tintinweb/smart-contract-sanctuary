pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/Math.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";



interface iFeed {
    function feed (uint256) external ;
    function feed2 (uint256) external ;
    function BattleAttack (uint256) external returns(uint256) ;
     function Attack (uint256, uint256) external returns(uint256) ;
     function _levelUp(uint256) external;
     function _levelDown(uint256) external;
     function ownerOf(uint256) external returns(address);
     function AFighter ( address addr, uint256 _tokenId) external returns (uint256);
     function getStrength (uint256 ) external view returns (uint256);
     function getDogeOwner(uint256 ) external view returns(address);
     function getDogeCaptureTime(uint256 tokenId) external returns(uint256);
     function dogeNapped(address addr, uint256 tokenId) external;
     function getAFighter(address addy) external view returns(uint256);
     function tokenIsInMarket(uint256, address) external view returns(bool);
     function transferFrom(address, address, uint256) external;
     function transfer(address, uint256) external;
}

contract dogpound is Ownable{

    using SafeMath for uint256;

   


    event GameCreated(address player, uint256 tokenId, uint256 _tokenId);
    event GameJoined(uint256 index, address player);
    event GameResult(uint256 index, address winner, uint256 amount);
    event NewDoge (string name);
    event Transfer (address to, uint256 amount, uint256 balance);
    event DogeCaptured(uint256 tokenId, address pirate);

    address public addy;
    address public market;
    address private addr;
    address public chewy;
    address payable public store;
    address public gameContract;
    address public Owner = msg.sender;
    //mapping(address => uint256) public DogeFighter;
    address fighterAddy;
    uint256 public _num;
    uint256 equationResult;
    uint256 public g;
    uint256 gc = 0;
    uint256 battleFee = 1;
    
    

    uint256 index = 0;
    mapping(uint256 => Game) gameIndex;
    mapping(bytes32 => Game) requestIndex;
    mapping(address =>  uint256 [])  userGames;

    struct Game {
        uint256 index;
        uint256 player1;
        uint256 player2;
        uint256 amount;
        address winner;
       uint256 blockstamp;
        
    }
    
    
   /** 
    modifier onlyOwner(){
        require(msg.sender == Owner);
        _;
    }
    */
    modifier HasTransferApproval(uint256 tokenId){
        IERC721 tokenContract = IERC721(addy);
        require(tokenContract.getApproved(tokenId) == gameContract);
        _;
    }
    
    function feed(uint256 _tokenId) external payable {
        iFeed(addy).feed(_tokenId);
    
    
    }

    function feedToo(uint256 _tokenId) external payable {
        iFeed(addy).feed2(_tokenId);
    
    
    }

    function withdraw() public payable onlyOwner{
       require (payable(msg.sender).send(address(this).balance));
   }

   function setAddy(address _addy)public onlyOwner returns(address){
           addy = _addy;
           return addy;


   }

   function setRaddy(address _addy)public onlyOwner returns(address){
           market = _addy;
           return market;


   }

   function setChewy(address _addy)public onlyOwner returns(address){
           chewy = _addy;
           return chewy;


   }

   function setBattleFee(uint256 fee)public onlyOwner returns(uint256){
           battleFee = fee;
           return battleFee;


   }

    function setStore(address payable _store)public onlyOwner returns(address){
           store = _store;
           return store;


   }

   function setGameContract(address  _gameContract)public onlyOwner returns(address){
           gameContract = _gameContract;
           return gameContract;


   }

   /** 
   function BattleAttack(uint256 _tokenId) external {
       iFeed(addy).BattleAttack(_tokenId);

   }

   function Attack(uint256 tokenId, uint256 _tokenId) external{
       iFeed(addy).Attack(tokenId , _tokenId);
   }
   */

   function isInMarket(uint256 tokenId) public view returns(uint256){
        bool status = iFeed(market).tokenIsInMarket(tokenId,addy);
        if( status = true){
            return 1;
        }
        else{
            return 0;
        }

   }

    function AFighter (uint256 _tokenId) public {
        
        uint256 status = isInMarket(_tokenId);
       
        require( status == 0);
        iFeed(addy).AFighter(msg.sender,_tokenId);
      

   }
   function BFighter (uint256 _tokenId) public {
        
       
        require(iFeed(market).tokenIsInMarket(_tokenId, addy) == false);
        
        iFeed(addy).AFighter(msg.sender,_tokenId);
      

   }

   function DogeFighter (address addry) public view returns(uint256){
         uint256 fighter =  iFeed(addy).getAFighter(addry);
        return fighter;
   }

   function getStrength(uint256 tokenId) public view returns (uint256){
       uint256 strength = iFeed(addy).getStrength(tokenId);
       return strength;

   }
   
   function getDogeOwner(uint256 tokenId) public view returns(address){
       address dogeOwner = iFeed(addy).getDogeOwner(tokenId);
       return dogeOwner;

   }

   function _levelUp(uint256 tokenId) private {
        iFeed(addy)._levelUp(tokenId);

   }


   function _levelDown(uint256 tokenId) private {
        iFeed(addy)._levelDown(tokenId);

   }

 

   /** FREE BATTLE 
   function BattleDoge (uint256 _tokenId) public returns(uint256 _winner){
        uint256 tokenId = iFeed(addy).getAFighter(msg.sender);

        require(_tokenId != tokenId);
        require(msg.sender == iFeed(addy).getDogeOwner(tokenId));

        bytes32 predictableRandom = keccak256(abi.encodePacked( block.timestamp));
           //bytes2 equation = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes2(predictableRandom[2]) >> 16 );
        uint256 a = 35+((55*uint256(uint8(predictableRandom[3])))/255);

           
       uint256 b = 55+((55*uint256(uint8(predictableRandom[3])))/255);

       uint256 c = block.timestamp;

       uint256 d = a + b;
       
        uint256 q = c % d;

       _num = q % 2;


  //moveable code

       if (_num > 0){
            iFeed(addy)._levelUp(tokenId);
            iFeed(addy)._levelDown(_tokenId);
            _winner = tokenId;
            

            
          }

          else{
              iFeed(addy)._levelUp(_tokenId);
              iFeed(addy)._levelDown(tokenId);
              _winner = _tokenId;
              
          }

//ends here

       Game memory newGame = Game(index, tokenId, _tokenId, _num, iFeed(addy).ownerOf(_winner), block.timestamp);
        gameIndex[index] = newGame;
        emit GameCreated(msg.sender, tokenId, _tokenId);
        
        gc++;


      

     //move code back here


     //end here

        
        userGames[msg.sender].push(index);
        userGames[iFeed(addy).getDogeOwner(_tokenId)].push(index);
        index++;
        
        return(_winner);
    

   }

    */


  /** 
   function BattleDoge (uint256 _tokenId) public returns(uint256 _winner){
        uint256 tokenId = iFeed(addy).getAFighter(msg.sender);

        require(_tokenId != tokenId);
        require(msg.sender == iFeed(addy).getDogeOwner(tokenId));

        iFeed(chewy).transferFrom(msg.sender, store, battleFee);

        bytes32 predictableRandom = keccak256(abi.encodePacked( block.timestamp));
           //bytes2 equation = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes2(predictableRandom[2]) >> 16 );
        uint256 a = 35+((55*uint256(uint8(predictableRandom[3])))/255);

           
       uint256 b = 55+((55*uint256(uint8(predictableRandom[3])))/255);

       uint256 c = block.timestamp;

       uint256 d = a + b;
       
        uint256 q = c % d;

       _num = q % 2;


  //moveable code

       if (_num > 0){
            iFeed(addy)._levelUp(tokenId);
            iFeed(addy)._levelDown(_tokenId);
            _winner = tokenId;
            

            
          }

          else{
              iFeed(addy)._levelUp(_tokenId);
              iFeed(addy)._levelDown(tokenId);
              _winner = _tokenId;
              
          }

//ends here

       Game memory newGame = Game(index, tokenId, _tokenId, _num, iFeed(addy).ownerOf(_winner), block.timestamp);
        gameIndex[index] = newGame;
        emit GameCreated(msg.sender, tokenId, _tokenId);
        
        gc++;


      

     //move code back here


     //end here

        
        userGames[msg.sender].push(index);
        userGames[iFeed(addy).getDogeOwner(_tokenId)].push(index);
        index++;
        
        return(_winner);
    

   }
   */

 function BattleDoge (uint256 _tokenId) public returns(uint256 _winner){
        uint256 tokenId = iFeed(addy).getAFighter(msg.sender);

        require(_tokenId != tokenId);
        require(msg.sender == iFeed(addy).getDogeOwner(tokenId));

        iFeed(chewy).transferFrom(msg.sender, store, battleFee);

        uint256 from = block.difficulty;
        uint256 to = 1927817238127182123200018909812;
       uint256 salty = block.timestamp;
        //uint256  z ;
        //uint256 _num;
        
 
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                    block.number +
                    salty
                )
            )
        );
         //v =(seed.mod(to - from) + from);
         _num = (seed.mod(to - from) + from) % 2;
        //return (v,z) ;
    


  //moveable code

       if (_num > 0){
            iFeed(addy)._levelUp(tokenId);
            iFeed(addy)._levelDown(_tokenId);
            _winner = tokenId;
            

            
          }

          else{
              iFeed(addy)._levelUp(_tokenId);
              iFeed(addy)._levelDown(tokenId);
              _winner = _tokenId;
              
          }

//ends here

       Game memory newGame = Game(index, tokenId, _tokenId, _num, iFeed(addy).ownerOf(_winner), block.timestamp);
        gameIndex[index] = newGame;
        emit GameCreated(msg.sender, tokenId, _tokenId);
        
        gc++;


      

     //move code back here


     //end here

        
        userGames[msg.sender].push(index);
        userGames[iFeed(addy).getDogeOwner(_tokenId)].push(index);
        index++;
        
        return(_winner);
    

   }






   
   function get_game_info(uint256 _index) external view returns(uint256 _i, uint256 tokenId, uint256 _tokenId, uint256 _number, address _winner, uint256 blockstamp) {
       
        Game memory game = gameIndex[_index];
        return (_index, game.player1, game.player2, game.amount, game.winner, game.blockstamp);
    }

    function gameCount() public view returns(uint256){
        return gc;
    }
   

   function getUserGames(address user) public view returns(uint256 [] memory){

      uint[] memory result = userGames[user];
      
      return result;
  }

  function BurnTokens(uint256 amount, address payable dead) public onlyOwner{
      iFeed(chewy).transfer(dead, amount);

  }




    

    
  }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

