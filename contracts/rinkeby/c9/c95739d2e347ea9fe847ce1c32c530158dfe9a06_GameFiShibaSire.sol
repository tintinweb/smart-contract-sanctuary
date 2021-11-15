//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//Shiba data structure
struct DogsMetaData {
    uint8 ethnicity;
    uint8 profession;
    uint8 head; //2 
    uint8 mouse; 
    uint8 eyes; 
    uint8 body; 
    uint8 collar; 
    uint8 tail; 
    uint8 ear; 
    uint8 cap; 
    uint8 clothing; 
    uint8 ornaments; //11 gen
    uint64 attack;
    uint64 defense;
    uint64 speed;
    uint32 father;
    uint32 mother;
    uint64 birth;
}

//Growth attributes
struct GrowthValue { uint8 attack; uint8 defense; uint8 speed; }

//Monitor lock
struct MonitorInfos {
    uint64 lefttime;
    bytes24 message;
}

//Fertility allocation
struct SireAttrConfig {
    uint8 ethnicity_option;
    //Occupational gene range
    uint8 profession_option;
    //Head gene range
    uint8 head_option;
    //Mouth gene range
    uint8 mouse_option;
    //Eye gene range
    uint8 eyes_option;
    //Body gene range
    uint8 body_option;
    //Collar gene range
    uint8 collar_option;
    //Tail gene range
    uint8 tail_option;
    //Clothing gene range
    uint8 clothing_option;
    //Ear gene range
    uint8 ear_option;
    //Hat gene range
    uint8 cap_option;
    //Accessories gene range
    uint8 ornaments_option;
}

interface IGameFiShibaSire {
    function sire( DogsMetaData memory _father, DogsMetaData memory _mother ) external returns (DogsMetaData memory);
    function sireFee(uint time) external view returns (uint256);
    function growingInfos() external view  returns(GrowthValue[] memory);
    function knighthood(uint tokenId) external view returns(uint);
    function identity() external view returns (uint[] memory);
    function genRarity(uint gen) external view returns(bool);
}

interface IGameFiShibaMonitor{
    function isMonitoring(uint256 tokenId) external view returns (bool) ;
    function monitorInfos(uint256 tokenId) external view returns (MonitorInfos memory);
}

interface IGameFiShiba is IERC721,IERC721Receiver,IERC721Enumerable,IGameFiShibaMonitor{
    function mint(address to, DogsMetaData memory meta) external returns (uint256 _tokenId);
    function sire(uint father,uint mother) external returns(uint _tokenId);
    function metaData(uint tokenId) external view returns (DogsMetaData memory);
    function exists(uint tokenId) external view returns (bool);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./GameFiShibaCommon.sol";

library GameFiShibaLib {
    function _randomSpeed(uint256 nonce) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        nonce,
                        msg.sender,
                        block.timestamp,
                        block.coinbase,
                        blockhash(block.number - 1)
                    )
                )
            );
    }

    function encodePack(DogsMetaData memory metaData) internal pure returns(bytes memory _packBytes){
        {
            _packBytes = abi.encodePacked(metaData.ethnicity, metaData.profession, metaData.head, metaData.mouse, metaData.eyes, metaData.body, metaData.collar, metaData.tail, metaData.ear, metaData.cap, metaData.clothing);
        }
        return abi.encodePacked( _packBytes, metaData.ornaments, metaData.attack, metaData.defense, metaData.speed, metaData.father, metaData.mother,metaData.birth);
    }
    
    function decodePack(bytes memory metaBytes) internal pure returns (DogsMetaData memory metaData)
    {
        uint8[18] memory _sizeOf = [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 8, 8, 8, 4, 4, 8 ];
        assembly {
            let offset := 32
            for {
                let i := 0
            } lt(i, 18) {
                i := add(i, 1)
            } {
                let size :=mload(add(_sizeOf, mul(i, 32)))
                mstore(
                    add(metaData, mul(i, 32)),
                    shr(
                        mul(
                            sub(32, size),
                            8
                        ),
                        mload(add(metaBytes, offset))
                    )
                )
                offset := add(offset, size)
            }
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./GameFiShibaCommon.sol";
import "./GameFiShibaLib.sol";


////////////////////////////////////////////////////////////////////////
////      ________                         ___________ __           ////
////     /  _____/ _____     _____    ____ \_   _____/|__|          ////    
////    /   \  ___ \__  \   /     \ _/ __ \ |    __)  |  |          ////
////    \    \_\  \ / __ \_|  Y Y  \\  ___/ |     \   |  |          ////
////     \______  /(____  /|__|_|  / \___  >\___  /   |__|          ////
////            \/      \/       \/      \/     \/                  ////
////           _________ __      __ ___                             ////
////          /   _____/|  |__  |__|\_ |__  _____                   ////
////          \_____  \ |  |  \ |  | | __ \ \__  \                  ////
////          /        \|   Y  \|  | | \_\ \ / __ \_                ////
////         /_______  /|___|  /|__| |___  /(____  /                ////
////                 \/      \/          \/      \/                 ////
////                                                gamefishiba.io  ////   
////////////////////////////////////////////////////////////////////////

/// @title GameFi Shiba
/// @author GameFi Shiba team
contract GameFiShibaSire is IGameFiShibaSire,Ownable  {
    
    using SafeMath for uint256;

    event SireConfigChange(address);
    event SireFeeChange(address);
    event IdentityChange(address);

    IGameFiShiba private _gamefishiba;
    
    SireAttrConfig public  sireConfig;
    //Career growth attribute range
    GrowthValue[] private  _growthValue;
    //Fertility cost
    uint[] private _sireFee ;

    uint private nonce = 0;
    //Special gene 
    uint[] private _identity;
    //Special gene construction
    mapping(uint=>bool) _genRarity;


    constructor(address gamefishiba_) {
        _gamefishiba = IGameFiShiba(gamefishiba_);
        _growthValue.push(GrowthValue(5,3,3));
        _growthValue.push(GrowthValue(5,3,3));
        _growthValue.push(GrowthValue(3,6,2));
        _growthValue.push(GrowthValue(3,5,4));
        _growthValue.push(GrowthValue(3,4,4));
        _growthValue.push(GrowthValue(3,4,4));
        _growthValue.push(GrowthValue(3,4,4));
        //race, occupation, head, mouth, eyes, body, collar, tail, clothes, ears, hat, accessories
        sireConfig = SireAttrConfig(4,7,5,5,5,5,30,5,30,5,30,30);
        //Fertility consumes gold coins
        _sireFee = [680*10**18,980*10**18,1480*10**18,1980*10**18,2880*10**18,3880*10**18];
        //Special gene : Hats, clothes, pendants
        _identity = [9,10,11];
    }

    function sire( DogsMetaData memory _father, DogsMetaData memory _mother ) external override returns (DogsMetaData memory _childDog){
        require(msg.sender == address(_gamefishiba),'sire fail');
        nonce = nonce.add(1);
        uint256 random = GameFiShibaLib._randomSpeed(nonce);
        uint8[] memory randomArray = new uint8[](32);
        assembly {
            let len := mload(randomArray)
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 1)
            } {
                let r := and(random, shl(mul(i, 0x8),0xff))
                mstore(add(add(randomArray, 0x20), mul(i, 0x20)), shr(mul(i, 0x8),r))
            }
        }
        // ethnicity;  profession;  head;  mouse;  eyes;  body;  collar;  tail;  ear;  cap;  clothing;  ornaments;  attack;  defense;  speed;  father;  mother;  birth;
        uint8 professionGen = calculateGenWithoutZero(randomArray[0],_father.profession,_mother.profession,sireConfig.profession_option);
        GrowthValue memory growthvalue = _growthValue[professionGen];
        uint8 collar = calculateGen(randomArray[1],_father.collar,_mother.collar,sireConfig.collar_option);
        SireAttrConfig memory _sireConfig = sireConfig;
        _childDog = DogsMetaData(
            calculateGenWithoutZero(randomArray[2],_father.ethnicity,_mother.ethnicity,_sireConfig.ethnicity_option),
            professionGen,
            calculateGenWithoutZero(randomArray[3] + randomArray[14],_father.head,_mother.head,_sireConfig.head_option),
            calculateGenWithoutZero(randomArray[4] + randomArray[15],_father.mouse,_mother.mouse,_sireConfig.mouse_option),
            calculateGenWithoutZero(randomArray[5] + randomArray[16],_father.eyes,_mother.eyes,_sireConfig.eyes_option),
            calculateGenWithoutZero(randomArray[6] + randomArray[17],_father.body,_mother.body,_sireConfig.body_option),
            collar,
            calculateGenWithoutZero(randomArray[7] + randomArray[18],_father.tail,_mother.tail,_sireConfig.tail_option),
            calculateGenWithoutZero(randomArray[8] + randomArray[19],_father.ear,_mother.ear,_sireConfig.ear_option),
            calculateGenWithoutZero(randomArray[9] + randomArray[20],_father.cap,_mother.cap,_sireConfig.cap_option),
            collar,
            calculateGen(randomArray[10],_father.ornaments,_mother.ornaments,sireConfig.ornaments_option),
            growthvalue.attack * 9 + (randomArray[11] % 3) * growthvalue.attack,
            growthvalue.defense * 9 + (randomArray[12] % 3) * growthvalue.defense,
            growthvalue.speed * 9 + (randomArray[13] % 3) * growthvalue.speed, 
            0,
            0,
            uint64(block.timestamp)
        );
    }
    
    function sireFee(uint time) public view override returns(uint){
        return _sireFee[time];
    }

    function setSireConfig(SireAttrConfig memory sireConfig_) public onlyOwner{
        sireConfig = sireConfig_;
        emit SireConfigChange(msg.sender);
    }

    function setSireFee(uint[] memory sireFee_) public onlyOwner{
        _sireFee = sireFee_;
        emit SireConfigChange(msg.sender);
    }

    function setIdentity(uint[] memory identity_) public onlyOwner{
        _identity = identity_;
        emit IdentityChange(msg.sender);
    }

    function growingInfos() public view override returns(GrowthValue[] memory){
        return _growthValue;
    }

    function calculateGenWithoutZero(uint seed,uint father,uint mother,uint mutation) private pure returns(uint8){
        return uint8(seed  > 178 ? (seed % mutation + 1) : (seed > 89? father:mother));
    }

    function calculateGen(uint seed,uint father,uint mother,uint mutation) private pure returns(uint8){
        return uint8(seed  > 178 ? seed % mutation : (seed > 89? father:mother));
    }


    //Which genes were included in the rarity calculation
    function identity() public view override returns (uint[] memory){
        return _identity;
    }
    //Determine whether a gene is a rare gene
    function genRarity(uint gen) public view override returns(bool){
        return _genRarity[gen];
    }
    //Set gene rarity
    function setGenRarity(uint gen,bool rarity) public onlyOwner{
        _genRarity[gen]  = rarity;
    }

    //Judge the rarity level of genes
    function knighthood(uint tokenId) public override view returns(uint){
        require(_gamefishiba.exists(tokenId),'no exists');
        //struct to static array
        uint[18] memory childDog = abi.decode(abi.encode(_gamefishiba.metaData(tokenId)),(uint[18]));
        uint[100] memory component;
        uint max;
        for(uint i=0;i<_identity.length;i++){
            uint gen = childDog[_identity[i]];
            if( _genRarity[gen] && ++component[gen] > max){
                max = component[gen];
            }
        }
        return max;
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
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

