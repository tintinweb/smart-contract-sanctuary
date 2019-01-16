pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


/* =================================================================
Contact HEAD : Im cute n safe ^_^
==================================================================== */

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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

/* =================================================================
Contact END : Im cute n safe ^_^
==================================================================== */



/* =================================================================
Contact HEAD : Basic data structure 
==================================================================== */

contract Base_Datasets {
    
    using SafeMath for uint;    
    using SafeMath for uint8;
    using SafeMath for uint16;
    using SafeMath for uint32;
    using SafeMath for uint256;
    using SafeMath for int;    
    using SafeMath for int8;
    using SafeMath for int16;
    using SafeMath for int32;
    using SafeMath for int256;

    
    struct User_Profile 
    {
        string User_Name;
        address payable User_Address;
        
        uint32 User_Id;
        uint32 Rankning_Socre;        
        uint32 MoneyMoney;

        uint32[] Played_History_GameId;
        uint32[] History_Winning_Games;
    }

    struct Game_Records 
    {
        uint32[2][] First_Player_Records;
        uint32[2][] Second_Player_Records;
    }
    
    
    struct Game_Profile 
    {
        uint16 Game_Type;
        uint16 GameBoard_Size;
        uint32 Game_Id;
        uint32 Betting_Amount;
        uint32[] Player_Id;
        Game_Records _Game_Records;
    }
    

    mapping(uint => User_Profile) Mapping_UserId_UserProfile;
    mapping(uint => mapping(uint => Game_Profile)) Mapping_Index_GameId_Record;
    

}

/* =================================================================
Contact END : Basic data structure 
==================================================================== */