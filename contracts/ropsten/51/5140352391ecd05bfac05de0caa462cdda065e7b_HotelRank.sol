pragma solidity ^0.4.21;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract HotelRank {
    struct HotelStruct {
        bytes32 name;
        uint rank;
        bytes32 rankDescription;
        uint lastUpdate;
        uint updates;
    }
    
    //Public
    address owner;
    mapping(bytes32 => HotelStruct) public hotelStructs;
 
    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }
 
    event UpdateRank(bytes32 id, bytes32 name, uint rank, bytes32 rankDescription, uint date);
                  
    constructor() public {
        owner=msg.sender;
    }
 
    function updateRank(bytes32 id, bytes32 name, uint rank, bytes32 rankDescription, uint date) public onlyOwner returns(bool success) {
        hotelStructs[id].name = name;
        hotelStructs[id].rank = rank;
        hotelStructs[id].lastUpdate = date;
        hotelStructs[id].rankDescription = rankDescription;
        hotelStructs[id].updates = SafeMath.add(hotelStructs[id].updates, 1);
        emit UpdateRank(id,name,rank,rankDescription,date);
        return true;
    } 
 }