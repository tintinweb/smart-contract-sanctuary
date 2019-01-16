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
Contact HEAD : Kitty721 interface for ugly trading winnings
==================================================================== */

contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

/* =================================================================
Contact END : Kitty721 interface for ugly trading winnings
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


/* =================================================================
Contact HEAD : Five link gaming structure 
==================================================================== */

contract Game_FiveLink_DataSets is Base_Datasets {
    
    struct Five_link_Game {
        
        address Whos_Turn;
        string Winnner;
    }
}

/* =================================================================
Contact END : Five link gaming structure 
==================================================================== */


/* =================================================================
Contact HEAD : Processing profile data 
==================================================================== */

contract Processing_ProfileData is Game_FiveLink_DataSets {
    
    function Create_UserAcount
    (
        string memory User_Name,
        uint32 User_Id
    ) 
    public payable{
        
        string memory _User_Name = User_Name;
        address payable _User_Address = msg.sender;
        uint32 _User_Id = User_Id;
        uint32 _Rankning_Socre = 0;
        uint32 _MoneyMoney = uint32((msg.value).mul(uint(99)/100));
        
        uint32[] memory _Played_History_GameId;
        uint32[] memory _History_Winning_Games_Id;
        
        Mapping_UserId_UserProfile[_User_Id] = 
        User_Profile( 
            _User_Name, 
            _User_Address, 
            _User_Id, 
            _Rankning_Socre, 
            _MoneyMoney,
            _Played_History_GameId,
            _History_Winning_Games_Id);
    }

    function Update_UserPlayHistory_Data (uint32 User_Id, uint32 DataOf_Played_History_GameId) internal {
        
        require (msg.sender == Mapping_UserId_UserProfile[User_Id].User_Address);
        
        Mapping_UserId_UserProfile[User_Id].Played_History_GameId.push(DataOf_Played_History_GameId);
        
    }

    function Update_UserWinningHistory_Data (uint32 User_Id, uint32 DataOf_History_Winning_Games_Id) internal {
        
        require (msg.sender == Mapping_UserId_UserProfile[User_Id].User_Address);
        
        Mapping_UserId_UserProfile[User_Id].History_Winning_Games.push(DataOf_History_Winning_Games_Id);
        
    }
    


    function Update_GamesPrfile_Copy (uint Game_Id, uint32[2] memory Played_Step, uint32 Whitch_Player_Turn) private {
    
    uint Game_Type = 5;
    
    Game_Profile storage Updata_Profile_Object = Mapping_Index_GameId_Record[Game_Type][Game_Id];
    
    if (Whitch_Player_Turn == 0) {
        
        Updata_Profile_Object._Game_Records.First_Player_Records.push(Played_Step);
        
        } else if (Whitch_Player_Turn == 1) {
        
        Updata_Profile_Object._Game_Records.Second_Player_Records.push(Played_Step);

        }

    }
    
}

/* =================================================================
Contact END : Processing profile data 
==================================================================== */








/* =================================================================
Contact HEAD : visualization of the five link game
==================================================================== */


contract Showing_Visualization is Game_FiveLink_DataSets {
    
//functionality of showing visualization

    //functionality of showing user profile
    function Fetch_User_Profile(uint32 User_Id) public view returns (User_Profile memory) {
        
        User_Profile memory User_Profile_instance = Mapping_UserId_UserProfile[User_Id];
        
        return User_Profile_instance;
    
    }


    
    
    //function of setting default fivelink gameboard
    function _Setting_Default_GameBoard(uint GameBoard_Size) public pure returns (int32[][] memory) {
        
        int32[][] memory Current_Game_Object;
            
        for (uint line = 0; line <= GameBoard_Size; line.add(1)) {
            for (uint column = 0; column <= GameBoard_Size; column.add(1)) {
                
                if(line==0 && column==0){ 
                    Current_Game_Object[line][column] = 0; }
                else if(line==0){ 
                    Current_Game_Object[line][column] = int32(column); }
                else if(column==0){ 
                    Current_Game_Object[line][column] = int32(line); }
                else if(line==1 && column==1){ 
                    Current_Game_Object[line][column] = -7; }
                else if(line==1 && column==GameBoard_Size){ 
                    Current_Game_Object[line][column] = -9; }
                else if(line==GameBoard_Size && column == 1){ 
                    Current_Game_Object[line][column] = -1; }
                else if(line==GameBoard_Size && column == GameBoard_Size){ 
                    Current_Game_Object[line][column] = -3; }
                else if(line==1){ 
                    Current_Game_Object[line][column] = -8; }
                else if(column==1){ 
                    Current_Game_Object[line][column] = -4; }
                else if(column==GameBoard_Size){ 
                    Current_Game_Object[line][column] = -6; }
                else if(line==GameBoard_Size){
                    Current_Game_Object[line][column] = -2; }
                else{ 
                    Current_Game_Object[line][column] = -5; } 
            }
        }
        
        return Current_Game_Object;
    }    
    
    
    //Putting the play records to game board
    function _Setting_Current_GameBoard_Scenario(int32[][] memory Default_GameBoard, uint32[2][] memory First_Player_Records, uint32[2][] memory Second_Player_Records) public view returns(int32[][] memory) {
        
        uint32[2] memory Chess_Possition;
        int32[][] memory Current_GameBoard_Result;
        
        for (uint Step_Number = 0; Step_Number <= First_Player_Records.length; Step_Number++) {
            Chess_Possition = First_Player_Records[Step_Number];
            Default_GameBoard[Chess_Possition[0]][Chess_Possition[1]] = -1111;
        }
        
        for (uint Step_Number = 0; Step_Number <= Second_Player_Records.length; Step_Number++) {
            Chess_Possition = Second_Player_Records[Step_Number];
            Default_GameBoard[Chess_Possition[0]][Chess_Possition[1]] = -1110;            
        }
        
        Current_GameBoard_Result = Default_GameBoard;
        
        return Current_GameBoard_Result;
        
    }
    
    
    //visualization fivelink gameboard
    function _Transfer_GameBoard_ArrayToString(int32[][] memory Untransfer_Array) public view returns (string memory) {
        
        uint Im_Cute_GameBoard_Size = Untransfer_Array.length;
        string memory Im_Cute_Transformation_String;
        
        for (uint line = 0; line <= Im_Cute_GameBoard_Size; line++) {

            Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String," \n "));
            
            for(uint column = 0; column <= Im_Cute_GameBoard_Size; column++) {
                
                if (Untransfer_Array[line][column] == 0) {
                    Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String," 0 "));
                    }
                else if (Untransfer_Array[line][column] == -7) { 
                    Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String," ┌ "));
                    }
                else if (Untransfer_Array[line][column] == -9) { 
                    Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String," ┐ "));
                    }
                else if (Untransfer_Array[line][column] == -1) { 
                    Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String," └ "));
                    }
                else if (Untransfer_Array[line][column] == -3) { 
                    Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String," ┘ "));
                    }
                else if (Untransfer_Array[line][column] == -8) { 
                    Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String," ┬ "));
                    }
                else if (Untransfer_Array[line][column] == -4) { 
                    Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String," ├ "));
                    }
                else if (Untransfer_Array[line][column] == -6) { 
                    Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String," ┤ "));
                    }
                else if (Untransfer_Array[line][column] == -2) { 
                    Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String," ┴ "));
                    }
                else if (Untransfer_Array[line][column] == -5) { 
                    Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String," ┼ "));
                    }
                else if (Untransfer_Array[line][column] == -1110) { 
                    Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String," ○ "));
                    }
                else if (Untransfer_Array[line][column] == -1111) { 
                    Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String," ● "));
                    }
                else if (Untransfer_Array[line][column] == int32(column) || Untransfer_Array[line][column] == int32(line)){ 
                    Im_Cute_Transformation_String = string(abi.encodePacked(Im_Cute_Transformation_String, line));
                    }
            }
        }
        
        return Im_Cute_Transformation_String;
    }
    
    
    //functionality of showing the current five link game visualization string
    function Fetch_Game_Board_Vitualization(uint32 Game_Id) public view returns (string memory) {
        
        uint FiveLink_GameType = 5;
        Game_Profile storage Current_Game = Mapping_Index_GameId_Record[FiveLink_GameType][Game_Id] ;
        
        uint _GameBoard_Size = Current_Game.GameBoard_Size ;
        int32[][] memory Default_GameBoard_object ; 
        int32[][] memory Current_Game_Instance ; 
        
        uint32[2][] memory First_Player_Records = Current_Game._Game_Records.First_Player_Records ; 
        uint32[2][] memory Second_Player_Records = Current_Game._Game_Records.Second_Player_Records;
        
        Default_GameBoard_object = _Setting_Default_GameBoard(_GameBoard_Size) ;
                
        Current_Game_Instance = _Setting_Current_GameBoard_Scenario(Default_GameBoard_object, First_Player_Records, Second_Player_Records);
        
        return _Transfer_GameBoard_ArrayToString(Current_Game_Instance);
    }

    
}

/* =================================================================
Contact END : visualization of the five link game
==================================================================== */







/* =================================================================
Contact HEAD : Five link game playing procedures
==================================================================== */

contract Play_FiveLink_Game is Processing_ProfileData, Showing_Visualization {
    
    //control accessing address for the player of the turn
//    modifier AccessControl(some_parameter_or_not) {
//    require(msg.sender == some_way_doing_control);
//    _;
//    }

    //event of launch new step
    event launch_new_step (uint16[2] Put_Step, uint Game_Type, uint Game_Id) ; 
    
    //event of showing virtualization board
    event Show_Vitualization (string virtualization_board, uint Game_Type, uint Game_Id);
    
    //event of showing User_Information
    
    
    //initialiing a new five link game
    function Create_FiveLink_Game
    (
        uint16 GameBoard_Size,
        uint32 Game_Id,
        uint32[] memory _Player_Id
    )
    public payable {
        
        
        uint Betting_Amount = (msg.value).mul(uint(95)/100);
        uint16 Game_Type = 5;
        Game_Records memory _Game_Records;
        
        Mapping_Index_GameId_Record[Game_Type][Game_Id] = 
        Game_Profile(   
            Game_Type, 
            GameBoard_Size, 
            Game_Id, 
            uint32 (Betting_Amount), 
            _Player_Id, 
            _Game_Records);
    }


// functionality of playing fivelink game
    function Playing_FiveLink_Game(uint16[2] memory Put_Step, uint32 Game_Id) public returns(address, uint16[2] memory) {
        
        //fetch game object
        uint Game_Type = 5;
        Game_Profile storage Current_Game = Mapping_Index_GameId_Record[Game_Type][Game_Id] ;

        //current game profile
        uint First_Player_Id = Current_Game.Player_Id[0] ;
        uint Second_Player_Id = Current_Game.Player_Id[1] ;
        User_Profile memory First_Player_Profile= Mapping_UserId_UserProfile[First_Player_Id] ;
        User_Profile memory Second_Player_Profile = Mapping_UserId_UserProfile[Second_Player_Id] ;
        
        //ensure the chess is putting inside the game board
        require(Put_Step[0] <= Current_Game.GameBoard_Size && Put_Step[1] <= Current_Game.GameBoard_Size) ;
        //ensure chess overlapping
        require(msg.sender == First_Player_Profile.User_Address || msg.sender == Second_Player_Profile.User_Address);
        
        //launch new step
        emit launch_new_step(Put_Step, Game_Type, Game_Id);
        
        
        //current player address
        address _First_Player_Address = First_Player_Profile.User_Address ;
        address _Second_Player_Address = Second_Player_Profile.User_Address ;
        
        //currnet playing records
        uint32[2][] storage _First_Player_Records = Current_Game._Game_Records.First_Player_Records ;
        uint32[2][] storage _Second_Player_Records = Current_Game._Game_Records.Second_Player_Records ;
        
        //put chess if first player access the function
        if(msg.sender == _First_Player_Address){
            require(_First_Player_Records.length >= _Second_Player_Records.length);
            _First_Player_Records.push(Put_Step);
        } 
        //put chess if second player access the function     
        else if(msg.sender == _Second_Player_Address) {
            require(_First_Player_Records.length == _Second_Player_Records.length);
            _Second_Player_Records.push(Put_Step);
        } 
    
    return (msg.sender, Put_Step);
        
    }
    
    
//functionality of determine the winner

    //winning vertification of player records input 
    function Determine_ChessPossition_Winning(uint32[2][] memory _Examing_Array, uint32[2] memory Last_Chess_Put) public returns (bool) {
        
        bool win = false;
        uint Check_Counter ;
        uint32[2][] memory Examing_Array = _Examing_Array;
        uint X_Axis = Last_Chess_Put[0] ;
        uint Y_Axis = Last_Chess_Put[1] ;
        uint Examing_Chess = Examing_Array[X_Axis][Y_Axis];
    
        for (int position = -4; position <= 4; position++) {
            if (Examing_Array[uint(int(X_Axis) + (position))][Y_Axis] == Examing_Chess) {
                Check_Counter = Check_Counter.add(1);
                while (Check_Counter >= 5) {win = true;}
            } else {Check_Counter = 0;}
        }
        for (int position = -4; position <= 4; position++) {
            if (Examing_Array[X_Axis][uint(int(Y_Axis) + (position))] == Examing_Chess) {
                Check_Counter = Check_Counter.add(1);
                while (Check_Counter >= 5) {win = true;}
            } else {Check_Counter = 0;}
        }
        for (int position = -4; position <= 4; position++) {
            if (Examing_Array[uint(int(X_Axis) + (position))][uint(int(Y_Axis) + (position))] == Examing_Chess) {
                Check_Counter = Check_Counter.add(1);
                while (Check_Counter >= 5) {win = true;}
            } else {Check_Counter = 0;}
        }
        for (int position = -4; position <= 4; position++) {
            if (Examing_Array[uint(int(X_Axis) + (position))][uint(int(Y_Axis) - (position))] == Examing_Chess) {
                Check_Counter = Check_Counter.add(1);
                while (Check_Counter >= 5) {win = true;}
            } else {Check_Counter = 0;}
        } 
        
        return win;
    }              
        
    //winning examination
    function Determine_FiveLinkGame_Winner(uint32[2][] memory Input_Array) public returns (bool) {
        
        uint32[2][] memory Examing_Array = Input_Array;
        uint Array_Length = Examing_Array.length ;
        uint32[2] memory Last_Chess_Put = Examing_Array[Array_Length.sub(1)] ;
        
        return Determine_ChessPossition_Winning(Examing_Array, Last_Chess_Put);
        
    }        

    function _Send_Bettings_to_Winner(uint _BettingAmount,uint To_winner_Id ) private {
        
        address payable SendETH_Address = Mapping_UserId_UserProfile[To_winner_Id].User_Address;
        uint reward = _BettingAmount.mul(uint(9)/10);
        SendETH_Address.transfer(reward);


    }
    
    function Determine_FiveLinkGame_Result(uint32 Game_Id) public returns (uint){
        
        uint FiveLink_GameType = 5;
        Game_Profile memory Current_Game = Mapping_Index_GameId_Record[FiveLink_GameType][Game_Id];
        uint MoneyMoney_Bettings = Current_Game.Betting_Amount;
        
        uint32[2][] memory _First_Player_Records = Current_Game._Game_Records.First_Player_Records;
        uint32[2][] memory _Second_Player_Records = Current_Game._Game_Records.Second_Player_Records;
        uint Winnner_UserId;
        
        if (Determine_FiveLinkGame_Winner(_First_Player_Records)) {
            
            Winnner_UserId = Current_Game.Player_Id[0];
            
        } else if (Determine_FiveLinkGame_Winner(_Second_Player_Records)) {
            
            Winnner_UserId = Current_Game.Player_Id[1];
            
        } else {
            
            Winnner_UserId = 0;
            
        }       
        
        _Send_Bettings_to_Winner(MoneyMoney_Bettings, Winnner_UserId);
        
        if (Winnner_UserId == 1) {
            
        Update_UserPlayHistory_Data(Current_Game.Player_Id[0], Game_Id);
        Update_UserPlayHistory_Data(Current_Game.Player_Id[1], Game_Id);
        Update_UserWinningHistory_Data(Current_Game.Player_Id[0], Game_Id);       
            
        } else if (Winnner_UserId == 0) {
            
        Update_UserPlayHistory_Data(Current_Game.Player_Id[0], Game_Id);
        Update_UserPlayHistory_Data(Current_Game.Player_Id[1], Game_Id);
        Update_UserWinningHistory_Data(Current_Game.Player_Id[1], Game_Id);       
        
        }    
        
        return Winnner_UserId;
        
    }
}

/* =================================================================
Contact END : Five link game playing procedures
==================================================================== */







/* =================================================================
Contact HEAD : Worship LU godness from <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0568606a72606b71456268646c692b666a68">[email&#160;protected]</a>
==================================================================== */
/* =================================================================
Contact END : Worship LU godness from <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7518101a02101b01351218141c195b161a18">[email&#160;protected]</a>
==================================================================== */