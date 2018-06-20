pragma solidity ^0.4.19;
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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}
contract PreSell is Ownable,ERC721{
    using SafeMath for uint256;
    struct Coach{
        uint256 drawPrice;
        uint256 emoteRate;
        uint256 sellPrice;
        uint8   isSell;
        uint8   category;
    }
    event initialcoach(uint _id);
    event drawcoach(uint _id,address _owner);
    event purChase(uint _id, address _newowner, address _oldowner);
    event inviteCoachBack(address _from,address _to, uint _fee);
    Coach[] public originCoach;
    Coach[] public coaches; 
    mapping(uint=>address) coachToOwner;
    mapping(uint=>uint) public coachAllnums;
    mapping(address=>uint) ownerCoachCount;
    mapping (uint => address) coachApprovals;
    //modifier
    modifier onlyOwnerOf(uint _id) {
        require(msg.sender == coachToOwner[_id]);
        _;
    }
    //owner draw _money
    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }
    //initial coach and coach nums;
    function initialCoach(uint _price,uint _emoterate,uint8 _category,uint _num) public onlyOwner{ 
      uint id = originCoach.push(Coach(_price,_emoterate,0,0,_category)) - 1;
      coachAllnums[id] = _num;
      emit initialcoach(id);
    }
    function drawCoach(uint _id,address _address) public payable{ 
        require(msg.value == originCoach[_id].drawPrice && coachAllnums[_id] > 0 );
        uint id = coaches.push(originCoach[_id]) -1;
        coachToOwner[id] = msg.sender;
        ownerCoachCount[msg.sender] = ownerCoachCount[msg.sender].add(1);
        coachAllnums[_id]  = coachAllnums[_id].sub(1);
        if(_address != 0){ 
                 uint inviteFee = msg.value * 5 / 100;
                 _address.transfer(inviteFee);
                 emit inviteCoachBack(msg.sender,_address,inviteFee);
        }
        emit drawcoach(_id,msg.sender);
    }
     //ERC721 functions;
    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return ownerCoachCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return coachToOwner[_tokenId];
    }
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        require(_to != _from);
        ownerCoachCount[_to] = ownerCoachCount[_to].add(1) ;
        ownerCoachCount[_from] = ownerCoachCount[_from].sub(1);
        coachToOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        coachApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }
    function takeOwnership(uint256 _tokenId) public {
        require(coachApprovals[_tokenId] == msg.sender && coachToOwner[_tokenId] != msg.sender);
        address owner = ownerOf(_tokenId);
        _transfer(owner, msg.sender, _tokenId);
    }
    //market functions
        //market functions
    function setCoachPrice(uint _id,uint _price) public onlyOwnerOf(_id){ 
        coaches[_id].isSell = 1;
        coaches[_id].sellPrice = _price;
    }
    function coachTakeOff(uint _id) public onlyOwnerOf(_id){
        coaches[_id].isSell = 0;
    }
    function purchase(uint _id) public payable{
        require(coaches[_id].isSell == 1 && msg.value == coaches[_id].sellPrice && msg.sender != coachToOwner[_id]);
        address owner = coachToOwner[_id];
        ownerCoachCount[owner] = ownerCoachCount[owner].sub(1) ;
        ownerCoachCount[msg.sender] = ownerCoachCount[msg.sender].add(1);
        coachToOwner[_id] = msg.sender;
        owner.transfer(msg.value);
        emit purChase(_id,msg.sender,owner);
    }
    
}