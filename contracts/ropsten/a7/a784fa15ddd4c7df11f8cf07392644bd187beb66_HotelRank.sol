pragma solidity ^0.4.25;



/*

   DIMENSION SRL

   www.dimension.it

*/



library SafeMath {



  /**

  * @dev Multiplies two numbers, reverts on overflow.

  */

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {

    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the

    // benefit is lost if &#39;b&#39; is also tested.

    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

    if (a == 0) {

      return 0;

    }



    uint256 c = a * b;

    require(c / a == b);



    return c;

  }



  /**

  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.

  */

  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b > 0); // Solidity only automatically asserts when dividing by 0

    uint256 c = a / b;

    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold



    return c;

  }



  /**

  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).

  */

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b <= a);

    uint256 c = a - b;



    return c;

  }



  /**

  * @dev Adds two numbers, reverts on overflow.

  */

  function add(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a + b;

    require(c >= a);



    return c;

  }



  /**

  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),

  * reverts when dividing by zero.

  */

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b != 0);

    return a % b;

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