pragma solidity ^0.5.1;
//pragma experimental ABIEncoderV2;




/* =================================================================
Contact HEAD : Data Sets 
==================================================================== */

// ----------------------------------------------------------------------------
// Black jack basic data structure
// ----------------------------------------------------------------------------
contract Blackjack_DataSets {
    
    struct User_AccountStruct {
        
        uint UserId;
        address UserAddress;
        string UserName;
    }
    
    
    struct Game_Unit {
        uint Game_UnitId;
        uint[] Player_UserIds;
        uint Dealer_UserId;
        uint MIN_BettingLimit;
        uint MAX_BettingLimit;
        uint[] Game_RoundsIds;
    }
    
    struct Game_Round_Unit {
        
        uint GameRoundId;
        mapping (uint => Play_Unit) Mapping__Index_PlayUnitStruct;
        uint[] Cards_InDealer;
        uint[] Cards_Exsited;
    }
    
    struct Play_Unit {
        
        uint Player_UserId;
        uint Bettings;
        uint[] Cards_InHand;
    }

    mapping (address => uint) Mapping__UserAddress_UserId;
    mapping (uint => User_AccountStruct) Mapping__UserId_UserAccountStruct;
    
    mapping (uint => Game_Unit) Mapping__GameUnitId_GameUnitStruct;
    mapping (uint => Game_Round_Unit) Mapping__GameRoundId_GameRoundStruct;
    mapping (uint => mapping(uint => uint)) Mapping__GameRoundIdUserId_Bettings;

    mapping (uint => uint) Mapping__OwnerUserId_ERC20Amount;
    mapping (uint => mapping(uint => uint)) Mapping__OwnerUserIdAlloweUserId_ERC20Amount;

    mapping (uint => string) Mapping__SuitNumber_String;
    mapping (uint => string) Mapping__FigureNumber_String;
    
    uint[13] Im_BlackJack_CardFigureToPoint = [1,2,3,4,5,6,7,8,9,10,10,10,10];
    
    uint public ImCounter_AutoGameId = 852334567885233456788869753300028886975330002 ;
    uint public ImCounter_DualGameId;
    uint public ImCounter_GameRoundId;
}
/* =================================================================
Contact END : Data Sets 
==================================================================== */



contract AccessControl is Blackjack_DataSets {
    
    modifier StandCheck_AllPlayer(uint GameId) {

        Game_Unit memory Im_GameUnit_Instance = Mapping__GameUnitId_GameUnitStruct[GameId];
        uint Im_RoundId = Im_GameUnit_Instance.Game_RoundsIds[Im_GameUnit_Instance.Game_RoundsIds.length-1];
        Game_Round_Unit storage Im_GameRoundUnit_Instance = Mapping__GameRoundId_GameRoundStruct[Im_RoundId];
//        Play_Unit[] memory Im_PlayUnitSet = Im_GameRoundUnit_Instance.PlayUnits;
        
        for(uint Im_PlayUnitCounter = 0 ; Im_PlayUnitCounter <= Im_GameUnit_Instance.Player_UserIds.length; Im_PlayUnitCounter++){
            
            require(Im_GameRoundUnit_Instance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand[Im_GameRoundUnit_Instance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand.length-1] == 1111);
        } 
        _;
    }
}



/* =================================================================
Contact HEAD : ERC20 interface 
==================================================================== */

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract ERC20_Interface {
    
//    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/* =================================================================
Contact END : ERC20 interface
==================================================================== */


contract MoneyMoney_Transection is Blackjack_DataSets {
    
//    function totalSupply() public view returns (uint){}

    function balanceOf(address tokenOwner) public view returns (uint balance){
        
        uint UserId = Mapping__UserAddress_UserId[tokenOwner];
        uint ERC20_Amount = Mapping__OwnerUserId_ERC20Amount[UserId];
        return ERC20_Amount;
        
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
        
        uint ERC20TokenOwnerId = Mapping__UserAddress_UserId[tokenOwner];
        uint ERC20TokenSpenderId = Mapping__UserAddress_UserId[spender];
        uint Allowance_Remaining = Mapping__OwnerUserIdAlloweUserId_ERC20Amount[ERC20TokenOwnerId][ERC20TokenSpenderId];
        return Allowance_Remaining;
    }

    function transfer(address to, uint tokens) public returns (bool success){
        
        require(balanceOf({tokenOwner: msg.sender}) >= tokens);
        uint Sender_UserId = Mapping__UserAddress_UserId[msg.sender];
//        require(Mapping__OwnerUserId_ERC20Amount[Sender_UserId] >= tokens);
        uint Transfer_to_UserId = Mapping__UserAddress_UserId[to];
        Mapping__OwnerUserId_ERC20Amount[Sender_UserId] = Mapping__OwnerUserId_ERC20Amount[Sender_UserId] - tokens;
        Mapping__OwnerUserId_ERC20Amount[Transfer_to_UserId] = Mapping__OwnerUserId_ERC20Amount[Transfer_to_UserId] + tokens;
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success){
        
        require(balanceOf({tokenOwner: msg.sender}) >= tokens);
        uint Sender_UserId = Mapping__UserAddress_UserId[msg.sender];
//        require(Mapping__OwnerUserId_ERC20Amount[Sender_UserId] >= tokens);
        uint Approve_to_UserId = Mapping__UserAddress_UserId[spender];
        Mapping__OwnerUserId_ERC20Amount[Sender_UserId] = Mapping__OwnerUserId_ERC20Amount[Sender_UserId] - tokens;
        Mapping__OwnerUserIdAlloweUserId_ERC20Amount[Sender_UserId][Approve_to_UserId] = Mapping__OwnerUserIdAlloweUserId_ERC20Amount[Sender_UserId][Approve_to_UserId] + tokens;
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        
        require(balanceOf({tokenOwner: from}) >= tokens);
        uint Sender_UserId = Mapping__UserAddress_UserId[from];
//        require(Mapping__OwnerUserId_ERC20Amount[Sender_UserId] >= tokens);
        uint Approver_UserId = Mapping__UserAddress_UserId[msg.sender];        
        uint Transfer_to_UserId = Mapping__UserAddress_UserId[to];
        Mapping__OwnerUserIdAlloweUserId_ERC20Amount[Sender_UserId][Approver_UserId] = Mapping__OwnerUserIdAlloweUserId_ERC20Amount[Sender_UserId][Approver_UserId] - tokens;
        Mapping__OwnerUserId_ERC20Amount[Transfer_to_UserId] = Mapping__OwnerUserId_ERC20Amount[Transfer_to_UserId] + tokens;
        return true;
    }
}



/* =================================================================
Contact HEAD : Basic Functionalities
==================================================================== */

// ----------------------------------------------------------------------------
// Black jack basic functionalities
// ----------------------------------------------------------------------------
contract Blackjack_Functionality is Blackjack_DataSets, AccessControl {
    
    event Initialize_GameEvent(uint _GameIdEvent, uint[] _Player_UserIdsEvent, uint _Dealer_UserIdEvent, uint _MIN_BettingLimitEvent ,uint _MAX_BettingLimitEvent);
    event BettingsEvent(uint _GameId, uint _GameRoundId,uint _UserId ,uint _BettingAmount);
    
    function Initialize_Game (uint _GameId, uint[] memory _Player_UserIds, uint _Dealer_UserId, uint _MIN_BettingLimit ,uint _MAX_BettingLimit) internal returns(bool _Success){
        
        uint[] memory NewGame_Rounds;
        NewGame_Rounds[0] = ImCounter_GameRoundId;
        ImCounter_GameRoundId = ImCounter_GameRoundId + 1 ;
        
        Mapping__GameUnitId_GameUnitStruct[_GameId] = Game_Unit(
            {Game_UnitId: _GameId, 
            Player_UserIds: _Player_UserIds,
            Dealer_UserId: _Dealer_UserId,
            MIN_BettingLimit: _MIN_BettingLimit,
            MAX_BettingLimit: _MAX_BettingLimit, 
            Game_RoundsIds: NewGame_Rounds});
        
        emit Initialize_GameEvent({
            _GameIdEvent: _GameId,
            _Player_UserIdsEvent: _Player_UserIds,
            _Dealer_UserIdEvent: _Dealer_UserId,
            _MIN_BettingLimitEvent: _MIN_BettingLimit,
            _MAX_BettingLimitEvent: _MAX_BettingLimit});
        
        return true;
    }
    
    
    function Bettings(uint _GameId, uint _Im_BettingsERC20Ammount) internal returns (uint GameId, uint GameRoundId, uint BettingAmount) {

        uint[] memory _Im_Game_RoundIds = Mapping__GameUnitId_GameUnitStruct[_GameId].Game_RoundsIds;
        uint CurrentGameRoundId = _Im_Game_RoundIds[_Im_Game_RoundIds.length -1];
        address _Im_Player_Address = msg.sender;
        uint _Im_Betting_UserId = Mapping__UserAddress_UserId[_Im_Player_Address];
        Mapping__GameRoundIdUserId_Bettings[CurrentGameRoundId][_Im_Betting_UserId] = _Im_BettingsERC20Ammount;
        
        emit BettingsEvent({
            _GameId: _GameId,
            _GameRoundId: CurrentGameRoundId,
            _UserId: _Im_Betting_UserId,
            _BettingAmount: _Im_BettingsERC20Ammount});
        
        return (_GameId, CurrentGameRoundId, _Im_BettingsERC20Ammount);
    }    

    
    function Initialize_Round (uint _ImGameRoundId, uint[] memory _Player_UserIds ) internal returns(uint _New_GameRoundId) {
        
        uint[] memory _New_CardInDealer;
        uint[] memory _New_CardInBoard;
        
        Mapping__GameRoundId_GameRoundStruct[_ImGameRoundId] = Game_Round_Unit({
        GameRoundId: _ImGameRoundId,
        //Type of Mapping is setting by default values of solidity compiler
        Cards_InDealer: _New_CardInDealer, 
        Cards_Exsited: _New_CardInBoard});
        

        for(uint Im_UserIdCounter = 0 ; Im_UserIdCounter < _Player_UserIds.length; Im_UserIdCounter++) {
            Mapping__GameRoundId_GameRoundStruct[_ImGameRoundId].Mapping__Index_PlayUnitStruct[Im_UserIdCounter] = Initialize_PlayUnit({
                _GameRoundId: _ImGameRoundId, 
                _UserId: _Player_UserIds[Im_UserIdCounter], 
                _Betting: Mapping__GameRoundIdUserId_Bettings[_ImGameRoundId][_Player_UserIds[Im_UserIdCounter]]});
        }
        
        _New_CardInDealer = GetCard({_Im_GameRoundId: _ImGameRoundId, _Im_Original_CardInHand: _New_CardInDealer});
        
        Mapping__GameRoundId_GameRoundStruct[_ImGameRoundId].Cards_InDealer = _New_CardInDealer;
        
        return (_ImGameRoundId);
    }
    
    function Initialize_PlayUnit (uint _GameRoundId, uint _UserId, uint _Betting) internal returns(Play_Unit memory _New_PlayUnit) {
        
        uint[] memory _Cards_InHand;
        _Cards_InHand = GetCard({_Im_GameRoundId: _GameRoundId,_Im_Original_CardInHand: _Cards_InHand});
        _Cards_InHand = GetCard({_Im_GameRoundId: _GameRoundId,_Im_Original_CardInHand: _Cards_InHand});

        Play_Unit memory Im_New_PlayUnit = Play_Unit({Player_UserId: _UserId , Bettings: _Betting, Cards_InHand: _Cards_InHand});
        return Im_New_PlayUnit;
    }


    
    function GetCard (uint _Im_GameRoundId, uint[] memory _Im_Original_CardInHand ) internal returns (uint[] memory _Im_Afterward_CardInHand ){
        
        uint[] storage Im_CardsOnBoard = Mapping__GameRoundId_GameRoundStruct[_Im_GameRoundId].Cards_Exsited;
        
        //do rand
        uint Im_52_RandNumber = GetRandom_In52(now);
        Im_52_RandNumber = Im_Cute_RecusiveFunction({Im_UnCheck_Number: Im_52_RandNumber, CheckNumberSet: Im_CardsOnBoard});
        
        Mapping__GameRoundId_GameRoundStruct[_Im_GameRoundId].Cards_Exsited.push(Im_52_RandNumber);
        
        _Im_Original_CardInHand[_Im_Original_CardInHand.length-1] = (Im_52_RandNumber);
        
        return _Im_Original_CardInHand;
    }

    function Im_Cute_RecusiveFunction (uint Im_UnCheck_Number, uint[] memory CheckNumberSet) internal returns (uint _Im_Unrepeat_Number){
        for(uint _Im_CheckCounter = 0; _Im_CheckCounter <= CheckNumberSet.length ; _Im_CheckCounter++){
            while (Im_UnCheck_Number == CheckNumberSet[_Im_CheckCounter]){
                Im_UnCheck_Number = GetRandom_In52(Im_UnCheck_Number);
                Im_Cute_RecusiveFunction(Im_UnCheck_Number, CheckNumberSet);
            }
        }
        return Im_UnCheck_Number;
    }

    function GetRandom_In52(uint _Im_CuteNumber) public view returns (uint _Im_Random){
        //Worship LuGodness
        require(msg.sender != block.coinbase);
        uint _Im_RandomNumber_In52 = uint(keccak256(abi.encodePacked(blockhash(block.number), msg.sender, _Im_CuteNumber))) % 52;
        return _Im_RandomNumber_In52;
    }
    
    
    function Counting_CardPoint (uint _Card_Number) public view returns(uint _CardPoint) {
        uint figure = (_Card_Number%13);
        uint Im_CardPoint = Im_BlackJack_CardFigureToPoint[figure];
        return Im_CardPoint;   
    }
    
    function Counting_HandCardPoint (uint[] memory _Card_InHand) public view returns(uint _TotalPoint) {
        
        uint _Im_Card_Number;
        uint Im_TotalCumulativePoints;
        
        //Accumulate hand point
        for (uint Im_CardCounter = 0 ; Im_CardCounter < _Card_InHand.length ; Im_CardCounter++) {
    
            _Im_Card_Number = _Card_InHand[Im_CardCounter];
            
            Im_TotalCumulativePoints = Im_TotalCumulativePoints + Counting_CardPoint(_Im_Card_Number);
        }

        //Check ACE
        for (uint Im_CardCounter = 0 ; Im_CardCounter < _Card_InHand.length ; Im_CardCounter++) {
            
            _Im_Card_Number = _Card_InHand[Im_CardCounter];
            
            if((_Im_Card_Number%13)==0 && Im_TotalCumulativePoints <= 11) {
            
                Im_TotalCumulativePoints = Im_TotalCumulativePoints + 10;
            }
        }
        
        return Im_TotalCumulativePoints;
    }
    

    function Determine_Result(uint _GameId, uint _RoundId) internal returns (uint[] memory _WinnerUserId, uint[] memory _LoserUserId) {

        uint[] memory Im_WinnerUserIdSet;
        uint[] memory Im_DrawIdSet;
        uint[] memory Im_LoserIdSet;

        Game_Unit memory Im_GameUnit_Instance = Mapping__GameUnitId_GameUnitStruct[_GameId];
        Game_Round_Unit storage Im_GameRoundUnit_Instance = Mapping__GameRoundId_GameRoundStruct[_RoundId];

        uint Im_PlayerTotalPoint;
        uint Im_DealerTotalPoint = Counting_HandCardPoint({_Card_InHand: Im_GameRoundUnit_Instance.Cards_InDealer});
        
        for(uint Im_PlayUnitCounter = 0 ; Im_PlayUnitCounter <= Im_GameUnit_Instance.Player_UserIds.length; Im_PlayUnitCounter++){
            
            Im_GameRoundUnit_Instance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand.pop;
            
            uint Im_PlayerUserId = Im_GameRoundUnit_Instance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Player_UserId;
            Im_PlayerTotalPoint = Counting_HandCardPoint(Im_GameRoundUnit_Instance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand);
            
            if(Im_PlayerTotalPoint > 21 && Im_DealerTotalPoint > 21){
                
                Im_DrawIdSet[Im_DrawIdSet.length] = Im_PlayerUserId;  
                
            } else if (Im_PlayerTotalPoint > 21) {
                
                Im_LoserIdSet[Im_LoserIdSet.length] = Im_PlayerUserId;
                
            } else if (Im_DealerTotalPoint > 21) {
                
                Im_WinnerUserIdSet[Im_WinnerUserIdSet.length] = Im_PlayerUserId;
                
            } else if (Im_PlayerTotalPoint == Im_DealerTotalPoint) {
                
                Im_DrawIdSet[Im_DrawIdSet.length] = Im_PlayerUserId;
                
            } else if (Im_DealerTotalPoint > Im_PlayerTotalPoint) {
                
                Im_LoserIdSet[Im_LoserIdSet.length] = Im_PlayerUserId;
                
            } else if (Im_PlayerTotalPoint > Im_DealerTotalPoint) {
                
                Im_WinnerUserIdSet[Im_WinnerUserIdSet.length] = Im_PlayerUserId;
            }
        }

        return (Im_WinnerUserIdSet, Im_LoserIdSet);
    }



}

/* =================================================================
Contact END : Basic Functionalities
==================================================================== */





    
/*
contract Integration_WorkFlow is Blackjack_Functionality {
    User Sight
    
    選擇遊戲(產生GameId)
    1.AUTO / DUAL
    2.是否玩錢錢 金額上下限 > AUTO的玩家/DUAL莊家地址發函數調用(或AUTO自動調用)
    3若選擇DUAL 則莊家輸入不同玩家UserID(1~N) 玩家地址發出同意函數 > 莊家地址發函數調用(或AUTO自動調用) 
  
1 Game  
    function_CreateAutoGame(GameId/ BettingsMax/BettingsMin) >Put Zero for none betting game =>玩家調用
    function_CreateDualGame(GameId/ Player_UserId[]/BettingsMax/BettingsMin) > watting for answer =>莊家調用
    
    
2-1 Round
    function_CreateGameRound(Auto){ CreateGameRoundId}
    function_PutBettings(GameId/ BettingAmount)=>1.第一輪玩家下注 不完錢錢Betting=0 > 玩家地址發函數調用

2-2 round init card    
    function_CreateRound_StartInitialCards(GameId/RoundId) returns(RoundId)莊家地址發函數調用(或AUTO自動調用)

    要有PUBLIC VIEW看場面的牌 (Mapping__GameRoundId_GameRoundStruct[GameRoundId].Cards_InDealer Mapping__GameRoundId_GameRoundStruct[GameRoundId].PlayUnits.Cards_InHand/ )
    
2-3 round deal card for each player
    function_Round_PlayUnitControl(GameId/ RoundId / HitOrStand) > 玩家地址發函數調用 思考要怎麼做控制調用順序
    
    
2-4 round Dealer card and determain winner
    function_Round_DealerControl(GameId/ RoundId / HitOrStand)
    function_DeterminwinnerAndSendsMoney(Auto_After_DealerControl_Stand)
    
    function_CreateGameRound(Auto)

    進行遊戲
    
    進行"一輪""(產生RoundId) > 莊家地址發函數調用(或AUTO自動調用)
    1.玩家下注(不玩錢錢就省略) > 玩家地址發函數調用
    2.下注完成可執行發牌行為 > 玩家都兩張> 莊家1張  > 莊家地址發函數調用(或AUTO自動調用)
    
    3.進入迴圈 第一位玩家要牌 停牌 
    要有PUBLIC VIEW看場面的牌 (Mapping__GameRoundId_GameRoundStruct[GameRoundId].Cards_InDealer Mapping__GameRoundId_GameRoundStruct[GameRoundId].PlayUnits.Cards_InHand/ )
    要牌的控制設計 是否要做玩家須依序要牌
    
    4.莊家要牌停牌  > 莊家地址發函數調用(或AUTO自動調用)
    
    5.決定該輪勝負  > 莊家地址發函數調用(或AUTO自動調用)
    
    進行"一輪""(產生RoundId)
}
*/


/* =================================================================
Contact HEAD : Integrated User functionality Workflow
==================================================================== */

// ----------------------------------------------------------------------------
// Black jack Integrated User functionality Workflow
// ----------------------------------------------------------------------------

contract Blackjack_GamePlay is Blackjack_Functionality, MoneyMoney_Transection {
    

    mapping (uint => uint[2]) Mapping__AutoGameBettingRank_BettingRange;
    
    event CheckBetting_Anouncement(uint GameRoundId, uint UserId, uint UserBettingAmount, uint MinBettingLimit, uint MaxBettingLimit);
    
  
    function Create_AutoGame (uint AutoGame_BettingRank) public returns (bool _SuccessMessage, uint _CreateGameId) {
        
        uint _Im_MIN_BettingLimit = Mapping__AutoGameBettingRank_BettingRange[AutoGame_BettingRank][0];
        uint _Im_MAX_BettingLimit = Mapping__AutoGameBettingRank_BettingRange[AutoGame_BettingRank][1];
        uint[] memory _Im_AutoGamePlayer_UserId;
        _Im_AutoGamePlayer_UserId[0] = Mapping__UserAddress_UserId[msg.sender];

        bool _Im_message = Initialize_Game({_GameId: ImCounter_AutoGameId, 
        _Player_UserIds: _Im_AutoGamePlayer_UserId, 
        _Dealer_UserId: Mapping__UserAddress_UserId[address(this)], 
        _MIN_BettingLimit: _Im_MIN_BettingLimit, 
        _MAX_BettingLimit: _Im_MAX_BettingLimit});
        
        ImCounter_AutoGameId = ImCounter_AutoGameId + 1;
        
        return (_Im_message, ImCounter_AutoGameId);
    }
        

    
    function Create_DualGame (uint[] memory PlayerIds ,uint MIN_BettingLimit ,uint MAX_BettingLimit) public returns (bool _SuccessMessage, uint _CreateGameId) {

        require(MIN_BettingLimit <= MAX_BettingLimit);
        
        uint _Im_DualGameCreater_UserId = Mapping__UserAddress_UserId[msg.sender];
        
        bool _Im_message = Initialize_Game({_GameId: ImCounter_DualGameId, 
        _Player_UserIds: PlayerIds, 
        _Dealer_UserId: _Im_DualGameCreater_UserId, 
        _MIN_BettingLimit: MIN_BettingLimit, 
        _MAX_BettingLimit: MAX_BettingLimit});

        ImCounter_DualGameId = ImCounter_DualGameId + 1;
        
        return (_Im_message, ImCounter_DualGameId);
    }
    
    
    
    function Player_Bettings(uint GameId, uint Im_BettingsERC20Ammount) public returns (uint _GameId, uint GameRoundId, uint BettingAmount) {

        require(Im_BettingsERC20Ammount >= Mapping__GameUnitId_GameUnitStruct[GameId].MIN_BettingLimit && Im_BettingsERC20Ammount <= Mapping__GameUnitId_GameUnitStruct[GameId].MAX_BettingLimit);
        
        uint Im_GameId;
        uint Im_GameRoundId;
        uint Im_BettingAmount;
        
        (Im_GameId, Im_GameRoundId, Im_BettingAmount) = Bettings({_GameId: GameId,_Im_BettingsERC20Ammount: Im_BettingsERC20Ammount});
        
        return (Im_GameId, Im_GameRoundId, Im_BettingAmount);
    }    
    

    
    function Start_NewRound(uint GameId) public returns (uint StartRoundId) {
        
        Game_Unit memory Im_GameUnitData= Mapping__GameUnitId_GameUnitStruct[GameId];
        uint Im_GameRoundId = Im_GameUnitData.Game_RoundsIds[Im_GameUnitData.Game_RoundsIds.length -1];
        uint[] memory Im_PlayerUserIdSet = Im_GameUnitData.Player_UserIds;
        uint Im_MIN_BettingLimit = Im_GameUnitData.MIN_BettingLimit;
        uint Im_MAX_BettingLimit = Im_GameUnitData.MAX_BettingLimit;

        if (Im_MAX_BettingLimit == 0) {
            
            uint Im_NewRoundId = Initialize_Round({_ImGameRoundId: Im_GameRoundId, _Player_UserIds: Im_PlayerUserIdSet});
            
            return Im_NewRoundId;
            
        } else {
            
            for(uint Im_PlayerCounter = 0; Im_PlayerCounter <= Im_PlayerUserIdSet.length; Im_PlayerCounter++) {
                
                uint Im_PlayerUserId = Im_PlayerUserIdSet[Im_PlayerCounter];
                uint Im_UserBettingAmount = Mapping__GameRoundIdUserId_Bettings[Im_GameRoundId][Im_PlayerUserId];
            
                require(Im_UserBettingAmount >= Im_MIN_BettingLimit && Im_UserBettingAmount <= Im_MAX_BettingLimit);
                
                emit CheckBetting_Anouncement ({
                    GameRoundId: Im_GameRoundId, 
                    UserId: Im_PlayerUserId, 
                    UserBettingAmount: Im_UserBettingAmount, 
                    MinBettingLimit: Im_MIN_BettingLimit,
                    MaxBettingLimit: Im_MAX_BettingLimit});
            }
            
            uint Im_NewRoundId = Initialize_Round({_ImGameRoundId: Im_GameRoundId, _Player_UserIds: Im_PlayerUserIdSet});
            
            return Im_NewRoundId;
        }
        
        return 0;
    }
    

    
    function Player_HitOrStand (uint GameId, bool Hit_or_Stand) public returns (uint[] memory NewCards_InHand) {
    
        Game_Unit memory Im_GameUnit_Instance = Mapping__GameUnitId_GameUnitStruct[GameId];
        uint Im_RoundId = Im_GameUnit_Instance.Game_RoundsIds[Im_GameUnit_Instance.Game_RoundsIds.length -1];
        
        Game_Round_Unit storage Im_GameRoundUnit_StorageInstance = Mapping__GameRoundId_GameRoundStruct[Im_RoundId];
        
        for (uint Im_PlayUnitCounter = 0; Im_PlayUnitCounter <= Im_GameUnit_Instance.Player_UserIds.length; Im_PlayUnitCounter++) {
            
            if (Mapping__UserAddress_UserId[msg.sender] == Im_GameRoundUnit_StorageInstance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Player_UserId ) {
                
                if (Hit_or_Stand) {
                    
                    Im_GameRoundUnit_StorageInstance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand = GetCard({_Im_GameRoundId: Im_RoundId, _Im_Original_CardInHand: Im_GameRoundUnit_StorageInstance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand});

                    return Im_GameRoundUnit_StorageInstance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand;
                    
                } else if (Hit_or_Stand == false) {
                    
                    Im_GameRoundUnit_StorageInstance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand.push(1111);

                    return Im_GameRoundUnit_StorageInstance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand;
                }
            }
        }
    }
    


    function Dealer_HitOrStand (uint GameId, bool Hit_or_Stand) public StandCheck_AllPlayer(GameId) returns (uint[] memory Cards_InDealerHand) {
        
        require(Mapping__UserAddress_UserId[msg.sender] == Mapping__GameUnitId_GameUnitStruct[GameId].Dealer_UserId);
        
        Game_Unit memory Im_GameUnit_Instance = Mapping__GameUnitId_GameUnitStruct[GameId];
        
        uint Im_RoundId = Im_GameUnit_Instance.Game_RoundsIds[Im_GameUnit_Instance.Game_RoundsIds.length -1];
        Game_Round_Unit storage Im_GameRoundUnit_StorageInstance = Mapping__GameRoundId_GameRoundStruct[Im_RoundId];
        
        
        uint Im_DealerUserId = Im_GameUnit_Instance.Dealer_UserId;
        uint[] memory WeR_WinnerId;
        uint[] memory WeR_LoserId;
        
        if (Hit_or_Stand) {
            
            Im_GameRoundUnit_StorageInstance.Cards_InDealer = GetCard({_Im_GameRoundId: Im_RoundId, _Im_Original_CardInHand: Im_GameRoundUnit_StorageInstance.Cards_InDealer});
            
            return Im_GameRoundUnit_StorageInstance.Cards_InDealer;
            
        } else if (Hit_or_Stand == false) {
            
            //Get winner and loser
            (WeR_WinnerId, WeR_LoserId) = Determine_Result({_GameId: GameId,_RoundId: Im_RoundId});
            
            //Transfer moneymoney to winners
            for(uint Im_WinnerCounter = 0; Im_WinnerCounter <= WeR_WinnerId.length ; Im_WinnerCounter++) {
                
                uint Im_WinnerUserId = WeR_WinnerId[Im_WinnerCounter];
                uint Im_WinnerBettingAmount = Mapping__GameRoundIdUserId_Bettings[Im_RoundId][Im_WinnerUserId];
                
                Mapping__OwnerUserId_ERC20Amount[Im_DealerUserId] - Im_WinnerBettingAmount;
                Mapping__OwnerUserId_ERC20Amount[Im_WinnerUserId] + Im_WinnerBettingAmount;
            }
            
            //Transfer moneymoney from losers          
            for(uint Im_LoserCounter = 0; Im_LoserCounter <= WeR_LoserId.length ; Im_LoserCounter++) {

                uint Im_LoserUserId = WeR_WinnerId[Im_LoserCounter];
                uint Im_LoserBettingAmount = Mapping__GameRoundIdUserId_Bettings[Im_RoundId][Im_LoserUserId];
                
                Mapping__OwnerUserId_ERC20Amount[Im_DealerUserId] + Im_LoserBettingAmount;
                Mapping__OwnerUserId_ERC20Amount[Im_LoserUserId] - Im_LoserBettingAmount;
            }
            
            //Create New Round ID
            ImCounter_GameRoundId = ImCounter_GameRoundId + 1;
            Mapping__GameUnitId_GameUnitStruct[GameId].Game_RoundsIds.push(ImCounter_GameRoundId);


            return Im_GameRoundUnit_StorageInstance.Cards_InDealer;
        }
    }
    


}
//    function Determine_Winnner (Ga)
    
/* =================================================================
Contact HEAD : Integrated User functionality Workflow
==================================================================== */

//Create by <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="8ce1e9e3fbe9e2f8ccebe1ede5e0a2efe3e1">[email&#160;protected]</a> 
//Worship Lu Godness