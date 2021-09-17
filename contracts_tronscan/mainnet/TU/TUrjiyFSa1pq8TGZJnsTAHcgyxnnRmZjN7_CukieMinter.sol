//SourceUnit: CukieMinter.sol

pragma solidity ^0.5.4;

import "./SafeMath.sol";
import "./ICukie.sol";
import "./IReferrals.sol";
import "./Ownable.sol";

contract CukieMinter is Ownable {
    using SafeMath for uint256;

    // tipos de cukie
    // struct
    // // uint32 probability
    // // uint32 id
    // // uint256 tokenId
    // // string uri

    struct Type {
        uint256 id; // if true, that person already voted
        uint256 probability; // weight is accumulated by delegation
        uint8 maxSkill;
        uint8 energy;
        uint8 health;
        uint16 max;
        uint16 num;
    }

    Type[] public types;
    ICukie public cukieToken;
    IReferrals public referrals;

    uint256 price;
    uint256 priceIncrement;
    uint256 priceIncrementNum;

    uint256 totalMint = 12000;

    bool pause = false;

    mapping(uint256 => uint256[]) private _typeToTokenId;

    mapping(address => address payable) public userToSponsor;

    mapping(address => address[]) public referralsBuyed;
    mapping(address => bool) public buyers;
    
    event MintReferral(
        address indexed user,
        address indexed sponsor,
        uint256 num,
        uint256 value,
        uint256 comission,
        uint8 indexed level
    );

    uint8[6][][6] private _skills;

    address payable cobrador;

    constructor() public {
        cobrador = msg.sender;
    }

    function changeCobrador(address payable _address) public onlyOwner {
        cobrador = _address;
    }

    function addSkill(uint8 _type, uint8[6] memory skills) public onlyOwner {
        _skills[_type].push(skills);
    }

    function changeReferrals(IReferrals _referrals) public onlyOwner {
        referrals = _referrals;
    }

    function changeToken(ICukie _cukieToken) public onlyOwner {
        cukieToken = _cukieToken;
    }

    function changePrice(
        uint256 _price,
        uint256 _priceIncrement,
        uint256 _priceIncrementNum
    ) public onlyOwner {
        price = _price;
        priceIncrement = _priceIncrement;
        priceIncrementNum = _priceIncrementNum;
    }

    function getType(uint256 _index)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 _id,
            uint256 _probability,
            uint256 _tokenId,
            uint256 _num
        ) = cukieToken.getType(_index);
        uint256 _max = types[_index].max;
        return (_id, _probability, _tokenId, _max, _num);
    }

    function getNumTypes() public view returns (uint256) {
        return types.length;
    }

    function getNext() public view returns (uint256) {
        uint256 _random = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, cukieToken.totalSupply())
            )
        ).mod(11999);

        if (_random < 6843) return 0;
        if (_random < 10141) return 1;
        if (_random < 11407) return 2;
        if (_random < 11890) return 3;
        if (_random < 11993) return 4;
        if (_random < 12000) return 5;

        // god al common
        // for(uint256 _i = types.length.sub(1); _i > 0; _i = _i.sub(1)) {
        //     if(_counter <= (types[_i].max - types[_i].num)) {
        //         return _i;
        //     }
        // }

        return 0;
    }

    function withdrawn() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function addType(
        uint256 probability,
        uint256 tokenId,
        uint16 max,
        uint8 maxSkill,
        uint8 energy,
        uint8 health
    ) public onlyOwner {
        types.push(
            Type({
                id: types.length + 1,
                probability: probability,
                maxSkill: maxSkill,
                energy: energy,
                health: health,
                max: max,
                num: 0
            })
        );

        cukieToken.addType(probability, tokenId);

    }

    function getPrice(uint256 num) public view returns (uint256) {
        uint256 _numMinted = cukieToken.totalSupply();
        uint256 _price = price;
        uint256 _priceTotal = 0;
        for (uint256 i = 0; i < num; i++) {
            _numMinted = _numMinted + 1;
            if (_numMinted % priceIncrementNum == 0)
                _price = _price + priceIncrement;

            _priceTotal = _priceTotal + _price;
        }
        return _priceTotal;
        // if (cukieToken.totalSupply().mod(priceIncrementNum) >= cukieToken.totalSupply().add(num).mod(priceIncrementNum)) {
        //     return price.mul(num) + priceIncrement;
        // } else {
        //     return price.mul(num);
        // }

    }

    function _addMinted() private {
        if (cukieToken.totalSupply().mod(priceIncrementNum) == 0)
            price = price.add(priceIncrement);
    }

    function togglePause() public onlyOwner {
        pause = !pause;
    }

    function multiMint(uint256 num, address payable sponsor)
        public
        payable
    {
        require(pause == false, "contract paused");
        require(num <= 5, "Max");
        uint256 _estimatedPrice = getPrice(num);
        require(msg.value == _estimatedPrice, "Amount is not sufficient.");
        require(totalMint > cukieToken.totalSupply().add(num), "No more NFT to mint.");

        if(_estimatedPrice > price * num) {
            price = price + priceIncrement;
        }

        address payable _sponsor = referrals.getSponsor(msg.sender);

        if (sponsor == address(0)) {
            sponsor = cobrador;
        }

        // si anteriormente no tenia sponsor y nos pasa uno se lo asignamos
        if (sponsor != address(0) && _sponsor == address(0) && sponsor != msg.sender) {
            referrals.setSponsorOwner(msg.sender, sponsor);
            _sponsor = sponsor;
        } 

        // if (_sponsor != msg.sender && _sponsor != address(0) && cukieToken.balanceOf(_sponsor) > 0) {
        if (_sponsor != msg.sender && _sponsor != address(0)) {
            if(!buyers[msg.sender]) {
                buyers[msg.sender] = true;
                referralsBuyed[_sponsor].push(msg.sender);
            }
            _sponsor.transfer(msg.value / 10);
            emit MintReferral(msg.sender, _sponsor, num, msg.value, msg.value / 10, 1);
        }
        if(!buyers[msg.sender]) {
            buyers[msg.sender] = true;
        }
        //miramos si el sponsor de su sponsor califica... si es asi le pagamos
        address payable sponsor2 = referrals.getSponsor(_sponsor);
        if(referralsBuyed[sponsor2].length >= 10) {
            sponsor2.transfer(msg.value * 3 / 100);
            emit MintReferral(msg.sender, sponsor2, num, msg.value, msg.value * 3 / 100, 2);
        }
        address payable sponsor3 = referrals.getSponsor(sponsor2);
        if(referralsBuyed[sponsor3].length >= 20) {
            sponsor3.transfer(msg.value * 2 / 100);
            emit MintReferral(msg.sender, sponsor2, num, msg.value, msg.value * 2 / 100, 3);
        }

        for (uint8 i = 0; i < num; i++) {
            Type memory selected = _getRandomType();

            uint8[6] memory skills = [0,0,0,0,0,5];
            uint numSkills = 0;
            while(numSkills < selected.maxSkill) {
                uint256 selectedSkill = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, cukieToken.totalSupply(), numSkills, skills[0], skills[1], skills[2], skills[3], skills[4]))).mod(5);

                if(selectedSkill == 0 && skills[0] < 5) { //skill 1
                    numSkills++;
                    skills[0]++;
                }
                if(selectedSkill == 1 && skills[1] < 5) { //skill 2
                    numSkills++;
                    skills[1]++;
                }
                if(selectedSkill == 2 && skills[2] < 5) { //skill 3
                    numSkills++;
                    skills[2]++;
                }
                if(selectedSkill == 3 && skills[3] < 5) { //skill 4
                    numSkills++;
                    skills[3]++;
                }
                if(selectedSkill == 4 && skills[4] < 5) { //skill 5
                    numSkills++;
                    skills[4]++;
                }
            }


            cukieToken.mintWithTokenURI(
                msg.sender,
                selected.id,
                1,
                skills,
                selected.energy,
                selected.health
            );


        }
        cobrador.transfer(address(this).balance);
    }

    function _getRandomType() private view returns (Type memory) {
        Type memory temp = types[getNext()];
        return temp;
    }
}


//SourceUnit: ICukie.sol

pragma solidity ^0.5.4;


import './ITRC721.sol';
import './ITRC721Metadata.sol';


/**
 * @title TRC721MetadataMintable
 * @dev TRC721 minting logic with metadata.
 */
contract ICukie is ITRC721, ITRC721Metadata {
    
    function mintWithTokenURI(address to, uint256 tokenId, uint256 generation, uint8[6] memory skills, uint8 energy, uint8 health) public returns (bool);
    function totalSupply() public view returns (uint256);

    function getType(uint256 _index)  view public returns (uint256 ,  
                                                    uint256 , 
                                                    uint256 , 
                                                    uint256 );

    function addType(uint256 probability, uint256 tokenId) public;
}


//SourceUnit: IReferrals.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

interface IReferrals {

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getSponsor(address _address) external view returns(address payable);
    function getReferrals(address _address) external view returns(address[] memory);
    function haveSponsor(address _address) external view returns(bool);

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS 
    //-------------------------------------------------------------------------

    function setSponsor(
        address _sponsor
    ) 
    external;

    function setSponsorOwner(
        address _address, 
        address _sponsor
    ) 
    external;
}

//SourceUnit: ITRC165.sol

pragma solidity ^0.5.4;

/**
 * @dev Interface of the TRC165 standard.
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({TRC165Checker}).
 *
 * For an implementation, see {TRC165}.
 */
interface ITRC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


//SourceUnit: ITRC721.sol

pragma solidity ^0.5.4;

import '../ITRC165.sol';

/**
 * @dev Required interface of an TRC721 compliant contract.
 */
contract ITRC721 is ITRC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

//SourceUnit: ITRC721Metadata.sol


pragma solidity ^0.5.4;
/**
 * @title TRC-721 Non-Fungible Token Standard, optional metadata extension
 */
import './ITRC721.sol';
 
contract ITRC721Metadata is ITRC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//SourceUnit: Ownable.sol

pragma solidity ^0.5.4;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
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
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
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

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.4;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}