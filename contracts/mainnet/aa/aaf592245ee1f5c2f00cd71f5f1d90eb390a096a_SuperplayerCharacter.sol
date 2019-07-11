/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity&#39;s arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it&#39;s recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
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
     * Counterpart to Solidity&#39;s `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/eth_superplayer_select_character.sol

pragma solidity ^0.5.0;







contract SuperplayerCharacter is Ownable {
  using SafeMath for uint256;


  event CharacterSelect(address from ,uint32 chaId) ;
  mapping(address => uint32) public addrMapCharacterIds;
  uint256 changeFee = 0;


  struct Character {
    uint32 id ;
    uint weight ;
  }


  Character[] private characters;
  uint256 totalNum = 0;
  uint256 totalWeight = 0;

  constructor() public {
      _addCharacter(1,1000000);
      _addCharacter(2,1000000);
      _addCharacter(3,1000000);
      _addCharacter(4,1000);
      _addCharacter(5,1000);
      _addCharacter(6,1000);
  }


  function AddCharacter(uint32 id ,uint weight ) public onlyOwner{
    _addCharacter(id,weight);
  }


  function SetFee( uint256 fee ) public onlyOwner {
    changeFee = fee;
  }




  function withdraw( address payable to )  public onlyOwner{
    require(to == msg.sender); //to == msg.sender == _owner
    to.transfer((address(this).balance ));
  }

  function getConfig() public view returns(uint32[] memory ids,uint256[] memory weights){
     ids = new uint32[](characters.length);
     weights = new uint[](characters.length);
     for (uint i = 0;i < characters.length ; i++){
          Character memory ch  = characters[i];
          ids[i] = ch.id;
          weights[i] = ch.weight;
     }
  }

  function () payable external{
    require(msg.value >= changeFee);
    uint sum = 0 ;
    uint index = characters.length - 1;

    uint weight = uint256(keccak256(abi.encodePacked(block.timestamp,msg.value,block.difficulty))) %totalWeight + 1;

    for (uint i = 0;i < characters.length ; i++){
      Character memory ch  = characters[i];
      sum += ch.weight;
      if( weight  <=  sum ){
        index = i;
        break;
      }
    }
    _selectCharacter(msg.sender,characters[index].id);

    msg.sender.transfer(msg.value.sub(changeFee));
  }

  function _selectCharacter(address from,uint32 id) internal{
    addrMapCharacterIds[from] = id;
    emit CharacterSelect(from,id);
  }



  function  _addCharacter(uint32 id ,uint weight) internal  {
    Character memory char = Character({
      id : id,
      weight :weight
    });
    characters.push(char);
    totalNum = totalNum.add(1);
    totalWeight  = totalWeight.add(weight);
  }

}