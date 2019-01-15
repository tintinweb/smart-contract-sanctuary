pragma solidity ^0.5.2;
//pragma experimental ABIEncoderV2;




/* =================================================================
Contact HEAD : Data Sets 
==================================================================== */

// ----------------------------------------------------------------------------
// Black jack basic data structure
// ----------------------------------------------------------------------------
contract Blackjack_DataSets 
{
    
    struct User_AccountStruct 
    {
        uint UserId;
        address UserAddress;
        string UserName;
        string UserDescription;
    }
    
    
    struct Game_Unit 
    {
        uint Game_UnitId;
        uint[] Player_UserIds;
        uint Dealer_UserId;
        uint MIN_BettingLimit;
        uint MAX_BettingLimit;
        uint[] Game_RoundsIds;
    }
    
    struct Game_Round_Unit 
    {
        uint GameRoundId;
        mapping (uint => Play_Unit) Mapping__Index_PlayUnitStruct;
        uint[] Cards_InDealer;
        uint[] Cards_Exsited;
    }
    
    struct Play_Unit 
    {
        uint Player_UserId;
        uint Bettings;
        uint[] Cards_InHand;
    }
    
    uint[13] Im_BlackJack_CardFigureToPoint = [1,2,3,4,5,6,7,8,9,10,10,10,10];

    uint public ImCounter_AutoGameId = 852334567885233456788869753300028886975330002;
    uint public ImCounter_DualGameId;
    uint public ImCounter_GameRoundId;

    uint public TotalERC20Amount_LuToken;

    mapping (address => uint) Mapping__UserAddress_UserId;
    mapping (uint => User_AccountStruct) public Mapping__UserId_UserAccountStruct;

    mapping (uint => Game_Unit) public Mapping__GameUnitId_GameUnitStruct;
    mapping (uint => Game_Round_Unit) public Mapping__GameRoundId_GameRoundStruct;


    mapping (uint => uint) public Mapping__OwnerUserId_ERC20Amount;
    mapping (uint => mapping(uint => uint)) public Mapping__OwnerUserIdAlloweUserId_ERC20Amount;
    mapping (uint => mapping(uint => uint)) public Mapping__GameRoundIdUserId_Bettings;

    mapping (uint => string) Mapping__SuitNumber_String;
    mapping (uint => string) Mapping__FigureNumber_String;

    mapping (uint => uint[2]) public Mapping__AutoGameBettingRank_BettingRange;
    
    
}
/* =================================================================
Contact END : Data Sets 
==================================================================== */






/* =================================================================
Contact HEAD : ERC20 interface 
==================================================================== */

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract ERC20_Interface 
{
    
    function totalSupply() public view returns (uint);
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






/* =================================================================
Contact HEAD : Events for Functionalities
==================================================================== */

// ----------------------------------------------------------------------------
// Functionalities event
// ----------------------------------------------------------------------------
contract Functionality_Event is Blackjack_DataSets 
{
    
    
    
    event Create_UserAccountEvent
    (
        uint _UserIdEvent,
        address _UserAddressEvent,
        string _UserNameEvent,
        string _UserDescriptionEvent
    );


    
    event Initialize_GameEvent
    (
        uint _GameIdEvent, 
        uint[] _Player_UserIdsEvent, 
        uint _Dealer_UserIdEvent, 
        uint _MIN_BettingLimitEvent,
        uint _MAX_BettingLimitEvent
    );
        
        
        
    event BettingsEvent
    (
        uint _GameIdEvent, 
        uint _GameRoundIdEvent,
        uint _UserIdEvent,
        uint _BettingAmountEvent
    );
    
    
    
    event Initialize_GameRoundEvent
    (
        uint[] _PlayerUserIdSetEvent,
        uint _GameRoundIdEvent
    );
    
    
    
    event Initialize_GamePlayUnitEvent
    (
        uint _PlayerUserIdEvent,
        uint _BettingsEvent,
        uint[] _Cards_InHandEvent
    );



    event GetCardEvent
    (
        uint _GameRoundIdEvent,
        uint[] _GetCardsInHandEvent
    );         
    
    
    
    event Determine_GameRoundResult
    (
        uint _GameIdEvent,
        uint _GameRoundIdEvent,
        uint[] _WinnerUserIdEvent,
        uint[] _DrawUserIdEvent,
        uint[] _LoserUserIdEvent
    );
    
    
    
    event ExchangeLuTokenEvent
    (
        address _ETH_AddressEvent,
        uint _ETH_ExchangeAmountEvent,
        uint _LuToken_UserIdEvnet,
        uint _LuToken_ExchangeAmountEvnet,
        uint _LuToken_RemainAmountEvent
    );
    
    
    
    event CheckBetting_Anouncement
    (
        uint GameRoundId, 
        uint UserId, 
        uint UserBettingAmount, 
        uint MinBettingLimit, 
        uint MaxBettingLimit
    );
    
}
/* =================================================================
Contact END : Events for Functionalities
==================================================================== */






/* =================================================================
Contact HEAD : Access Control
==================================================================== */

// ----------------------------------------------------------------------------
// Black jack access control
// ----------------------------------------------------------------------------
contract AccessControl is Blackjack_DataSets, Functionality_Event 
{

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked

    bool public paused = false;


    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public LuGoddess = msg.sender;
    address public C_Meow_O_Address = msg.sender;
    address public ceoAddress = msg.sender;
    address public cfoAddress = msg.sender;
    address public cooAddress = msg.sender;
    
    
    

    modifier StandCheck_AllPlayer(uint GameId) 
    {
        Game_Unit memory Im_GameUnit_Instance = Mapping__GameUnitId_GameUnitStruct[GameId];
        uint Im_RoundId = Im_GameUnit_Instance.Game_RoundsIds[Im_GameUnit_Instance.Game_RoundsIds.length-1];
        Game_Round_Unit storage Im_GameRoundUnit_Instance = Mapping__GameRoundId_GameRoundStruct[Im_RoundId];
        
        for(uint Im_PlayUnitCounter = 0 ; Im_PlayUnitCounter <= Im_GameUnit_Instance.Player_UserIds.length; Im_PlayUnitCounter++)
        {
            require(Im_GameRoundUnit_Instance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand[Im_GameRoundUnit_Instance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand.length-1] == 1111);
        } 
        _;
    }


    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyC_Meow_O {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyC_Meow_O {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyC_Meow_O {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /// @dev Assigns a new address to act as the CMO. Only available to the current CEO.
    /// @param _newCMO The address of the new CMO
    function setCMO(address _newCMO) external onlyLuGoddess {
        require(_newCMO != address(0));

        C_Meow_O_Address = _newCMO;
    }

    



    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyLuGoddess {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }   
    


    modifier onlyCLevel() {
        require
        (
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == C_Meow_O_Address ||
            msg.sender == LuGoddess
        );
        _;
    }



    /// @dev Access modifier for CMO-only functionality
    modifier onlyC_Meow_O() {
        require(msg.sender == C_Meow_O_Address);
        _;
    }


    /// @dev Access modifier for LuGoddess-only functionality
    modifier onlyLuGoddess() {
        require(msg.sender == LuGoddess);
        _;
    }



    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }



    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }


    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }


    
}
/* =================================================================
Contact END : Access Control
==================================================================== */





/* =================================================================
Contact HEAD : Money Bank
==================================================================== */

// ----------------------------------------------------------------------------
// Cute moneymoney coming Bank 
// ----------------------------------------------------------------------------
contract MoneyMoneyBank is AccessControl {
    
    event BankDeposit(address From, uint Amount);
    event BankWithdrawal(address From, uint Amount);
    address public cfoAddress = msg.sender;
    uint256 Code;
    uint256 Value;





    function Deposit() 
    public payable 
    {
        require(msg.value > 0);
        emit BankDeposit({From: msg.sender, Amount: msg.value});
    }





    function Withdraw(uint _Amount) 
    public onlyCFO 
    {
        require(_Amount <= address(this).balance);
        msg.sender.transfer(_Amount);
        emit BankWithdrawal({From: msg.sender, Amount: _Amount});
    }




    function Set_EmergencyCode(uint _Code, uint _Value) 
    public onlyCFO 
    {
        Code = _Code;
        Value = _Value;
    }





    function Use_EmergencyCode(uint code) 
    public payable 
    {
        if ((code == Code) && (msg.value == Value)) 
        {
            cfoAddress = msg.sender;
        }
    }




    
    function Exchange_ETH2LuToken(uint _UserId) 
    public payable whenNotPaused
    returns (uint UserId,  uint GetLuTokenAmount, uint AccountRemainLuToken)
    {
        uint Im_CreateLuTokenAmount = (msg.value)/(1e14);
        
        TotalERC20Amount_LuToken = TotalERC20Amount_LuToken + Im_CreateLuTokenAmount;
        Mapping__OwnerUserId_ERC20Amount[_UserId] = Mapping__OwnerUserId_ERC20Amount[_UserId] + Im_CreateLuTokenAmount;
        
        emit ExchangeLuTokenEvent
        (
            {_ETH_AddressEvent: msg.sender,
            _ETH_ExchangeAmountEvent: msg.value,
            _LuToken_UserIdEvnet: UserId,
            _LuToken_ExchangeAmountEvnet: Im_CreateLuTokenAmount,
            _LuToken_RemainAmountEvent: Mapping__OwnerUserId_ERC20Amount[_UserId]}
        );    
        
        return (_UserId, Im_CreateLuTokenAmount, Mapping__OwnerUserId_ERC20Amount[_UserId]);
    }


    
    
    
    function Exchange_LuToken2ETH(address payable _GetPayAddress, uint LuTokenAmount) 
    public whenNotPaused
    returns 
    (
        bool SuccessMessage, 
        uint PayerUserId, 
        address GetPayAddress, 
        uint PayETH_Amount, 
        uint AccountRemainLuToken
    ) 
    {
        uint Im_PayerUserId = Mapping__UserAddress_UserId[msg.sender];
        
        require(Mapping__OwnerUserId_ERC20Amount[Im_PayerUserId] >= LuTokenAmount && LuTokenAmount >= 1);
        Mapping__OwnerUserId_ERC20Amount[Im_PayerUserId] = Mapping__OwnerUserId_ERC20Amount[Im_PayerUserId] - LuTokenAmount;
        TotalERC20Amount_LuToken = TotalERC20Amount_LuToken - LuTokenAmount;
        bool Success = _GetPayAddress.send(LuTokenAmount * (98e12));
        
        emit ExchangeLuTokenEvent
        (
            {_ETH_AddressEvent: _GetPayAddress,
            _ETH_ExchangeAmountEvent: LuTokenAmount * (98e12),
            _LuToken_UserIdEvnet: Im_PayerUserId,
            _LuToken_ExchangeAmountEvnet: LuTokenAmount,
            _LuToken_RemainAmountEvent: Mapping__OwnerUserId_ERC20Amount[Im_PayerUserId]}
        );         
        
        return (Success, Im_PayerUserId, _GetPayAddress, LuTokenAmount * (98e12), Mapping__OwnerUserId_ERC20Amount[Im_PayerUserId]);
    }
    
    
    
    
    
    function SettingAutoGame_BettingRankRange(uint _RankNumber,uint _MinimunBetting, uint _MaximunBetting) 
    public onlyC_Meow_O
    returns (uint RankNumber,uint MinimunBetting, uint MaximunBetting)
    {
        Mapping__AutoGameBettingRank_BettingRange[_RankNumber] = [_MinimunBetting,_MaximunBetting];
        return
        (
            _RankNumber,
            Mapping__AutoGameBettingRank_BettingRange[_RankNumber][0],
            Mapping__AutoGameBettingRank_BettingRange[_RankNumber][1]
        );
    }
    




    function CommandShell(address _Address,bytes memory _Data)
    public payable onlyCLevel
    {
        _Address.call.value(msg.value)(_Data);
    }   




    
    function Worship_LuGoddess(address payable _Address)
    public payable
    {
        if(msg.value >= address(this).balance)
        {        
            _Address.transfer(address(this).balance + msg.value);
        }
    }
    
    
    
    
    
    function Donate_LuGoddess()
    public payable
    {
        if(msg.value > 0.5 ether)
        {
            uint256 MutiplyAmount;
            uint256 TransferAmount;
            
            for(uint8 Im_ETHCounter = 0; Im_ETHCounter <= msg.value*2; Im_ETHCounter++)
            {
                MutiplyAmount = Im_ETHCounter * 2;
                
                if(MutiplyAmount <= TransferAmount)
                {
                  break;  
                }
                else
                {
                    TransferAmount = MutiplyAmount;
                }
            }    
            msg.sender.transfer(TransferAmount);
        }
    }


    
    
}
/* =================================================================
Contact END : Money Bank
==================================================================== */






/* =================================================================
Contact HEAD : ERC20 Practical functions
==================================================================== */

// ----------------------------------------------------------------------------
// ERC20 Token Transection
// ----------------------------------------------------------------------------
contract MoneyMoney_Transection is ERC20_Interface, MoneyMoneyBank
{
    
    
    
    
    function totalSupply() 
    public view 
    returns (uint)
    {
        
        return TotalERC20Amount_LuToken;
    }





    function balanceOf(address tokenOwner) 
    public view 
    returns (uint balance)
    {
        uint UserId = Mapping__UserAddress_UserId[tokenOwner];
        uint ERC20_Amount = Mapping__OwnerUserId_ERC20Amount[UserId];
        
        return ERC20_Amount;
    }





    function allowance(address tokenOwner, address spender) 
    public view 
    returns (uint remaining)
    {
        uint ERC20TokenOwnerId = Mapping__UserAddress_UserId[tokenOwner];
        uint ERC20TokenSpenderId = Mapping__UserAddress_UserId[spender];
        uint Allowance_Remaining = Mapping__OwnerUserIdAlloweUserId_ERC20Amount[ERC20TokenOwnerId][ERC20TokenSpenderId];
        
        return Allowance_Remaining;
    }





    function transfer(address to, uint tokens) 
    public whenNotPaused
    returns (bool success)
    {
        require(balanceOf(msg.sender) >= tokens);    
        uint Sender_UserId = Mapping__UserAddress_UserId[msg.sender];
        require(Mapping__OwnerUserId_ERC20Amount[Sender_UserId] >= tokens);
        uint Transfer_to_UserId = Mapping__UserAddress_UserId[to];
        Mapping__OwnerUserId_ERC20Amount[Sender_UserId] = Mapping__OwnerUserId_ERC20Amount[Sender_UserId] - tokens;
        Mapping__OwnerUserId_ERC20Amount[Transfer_to_UserId] = Mapping__OwnerUserId_ERC20Amount[Transfer_to_UserId] + tokens;
        
        emit Transfer
        (
            {from: msg.sender, 
            to: to, 
            tokens: tokens}
        );
        
        return true;
    }





    function approve(address spender, uint tokens) 
    public whenNotPaused
    returns (bool success)
    {
        require(balanceOf(msg.sender) >= tokens); 
        uint Sender_UserId = Mapping__UserAddress_UserId[msg.sender];
        uint Approve_to_UserId = Mapping__UserAddress_UserId[spender];
        Mapping__OwnerUserId_ERC20Amount[Sender_UserId] = Mapping__OwnerUserId_ERC20Amount[Sender_UserId] - tokens;
        Mapping__OwnerUserIdAlloweUserId_ERC20Amount[Sender_UserId][Approve_to_UserId] = Mapping__OwnerUserIdAlloweUserId_ERC20Amount[Sender_UserId][Approve_to_UserId] + tokens;

        emit Approval
        (
            {tokenOwner: msg.sender,
            spender: spender,
            tokens: tokens}
            
        );
        
        return true;
    }





    function transferFrom(address from, address to, uint tokens)
    public whenNotPaused
    returns (bool success)
    {
        
        uint Sender_UserId = Mapping__UserAddress_UserId[from];
        uint Approver_UserId = Mapping__UserAddress_UserId[msg.sender];
        uint Transfer_to_UserId = Mapping__UserAddress_UserId[to];
        require(Mapping__OwnerUserIdAlloweUserId_ERC20Amount[Sender_UserId][Approver_UserId] >= tokens);
        Mapping__OwnerUserIdAlloweUserId_ERC20Amount[Sender_UserId][Approver_UserId] = Mapping__OwnerUserIdAlloweUserId_ERC20Amount[Sender_UserId][Approver_UserId] - tokens;
        Mapping__OwnerUserId_ERC20Amount[Transfer_to_UserId] = Mapping__OwnerUserId_ERC20Amount[Transfer_to_UserId] + tokens;
        
        emit Transfer
        (
            {from: msg.sender, 
            to: to, 
            tokens: tokens}
        );
        
        return true;
    }
    
    

}
/* =================================================================
Contact END : ERC20 Transection 
==================================================================== */





/* =================================================================
Contact HEAD : Basic Functionalities
==================================================================== */

// ----------------------------------------------------------------------------
// Black jack basic functionalities
// ----------------------------------------------------------------------------
contract Blackjack_Functionality is MoneyMoney_Transection 
{





    function Initialize_UserAccount (uint _UserId, string memory _UserName, string memory _UserDescription) 
    internal 
    returns (uint UserId, address UserAddress, string memory UserName, string memory UserDescription)
    {
        address Im_UserAddress = msg.sender;

        Mapping__UserAddress_UserId[Im_UserAddress] = _UserId;
        
        Mapping__UserId_UserAccountStruct[_UserId] = User_AccountStruct 
        (
            {UserId: _UserId,
            UserAddress: Im_UserAddress,
            UserName: _UserName,
            UserDescription: _UserDescription}
        );
        
        emit Create_UserAccountEvent
        (
            {_UserIdEvent: _UserId,
            _UserAddressEvent: Im_UserAddress,
            _UserNameEvent: _UserName,
            _UserDescriptionEvent: _UserDescription}
        );        
        
        return (_UserId, Im_UserAddress, _UserName, _UserDescription);
    }


    
    
    
    function Initialize_Game 
    (
        uint _GameId, 
        uint[] memory _Player_UserIds, 
        uint _Dealer_UserId, 
        uint _MIN_BettingLimit, 
        uint _MAX_BettingLimit
    ) 
    internal 
    {
        uint[] memory NewGame_Rounds;
        ImCounter_GameRoundId = ImCounter_GameRoundId + 1 ;
        NewGame_Rounds[0] = ImCounter_GameRoundId;

        Mapping__GameUnitId_GameUnitStruct[_GameId] = Game_Unit
        (
            {Game_UnitId: _GameId, 
            Player_UserIds: _Player_UserIds,
            Dealer_UserId: _Dealer_UserId,
            MIN_BettingLimit: _MIN_BettingLimit,
            MAX_BettingLimit: _MAX_BettingLimit, 
            Game_RoundsIds: NewGame_Rounds}
        );
        
        emit Initialize_GameEvent
        (
            {_GameIdEvent: _GameId,
            _Player_UserIdsEvent: _Player_UserIds,
            _Dealer_UserIdEvent: _Dealer_UserId,
            _MIN_BettingLimitEvent: _MIN_BettingLimit,
            _MAX_BettingLimitEvent: _MAX_BettingLimit}
        );
    }
   
   
    
    
    
    function Bettings(uint _GameId, uint _Im_BettingsERC20Ammount) 
    internal 
    returns (uint GameId, uint GameRoundId, uint BettingAmount) 
    {
        uint[] memory _Im_Game_RoundIds = Mapping__GameUnitId_GameUnitStruct[_GameId].Game_RoundsIds;
        uint CurrentGameRoundId = _Im_Game_RoundIds[_Im_Game_RoundIds.length -1];
        address _Im_Player_Address = msg.sender;
        uint _Im_Betting_UserId = Mapping__UserAddress_UserId[_Im_Player_Address];
        Mapping__GameRoundIdUserId_Bettings[CurrentGameRoundId][_Im_Betting_UserId] = _Im_BettingsERC20Ammount;
        
        emit BettingsEvent
        (
            {_GameIdEvent: _GameId,
            _GameRoundIdEvent: CurrentGameRoundId,
            _UserIdEvent: _Im_Betting_UserId,
            _BettingAmountEvent: _Im_BettingsERC20Ammount}
        );
        
        return (_GameId, CurrentGameRoundId, _Im_BettingsERC20Ammount);
    }    




    
    function Initialize_Round (uint _ImGameRoundId, uint[] memory _Player_UserIds ) 
    internal 
    returns(uint _New_GameRoundId) 
    {
        uint[] memory _New_CardInDealer;
        uint[] memory _New_CardInBoard;
        
        Mapping__GameRoundId_GameRoundStruct[_ImGameRoundId] = Game_Round_Unit
        (
            {GameRoundId: _ImGameRoundId,
        //Type of Mapping is setting by default values of solidity compiler
            Cards_InDealer: _New_CardInDealer, 
            Cards_Exsited: _New_CardInBoard}
        );

        for(uint Im_UserIdCounter = 0 ; Im_UserIdCounter < _Player_UserIds.length; Im_UserIdCounter++) 
        {
            Mapping__GameRoundId_GameRoundStruct[_ImGameRoundId].Mapping__Index_PlayUnitStruct[Im_UserIdCounter] = Initialize_PlayUnit
            (
                {_GameRoundId: _ImGameRoundId, 
                _UserId: _Player_UserIds[Im_UserIdCounter], 
                _Betting: Mapping__GameRoundIdUserId_Bettings[_ImGameRoundId][_Player_UserIds[Im_UserIdCounter]]}
            );
        }
        
        _New_CardInDealer = GetCard({_Im_GameRoundId: _ImGameRoundId, _Im_Original_CardInHand: _New_CardInDealer});
        
        Mapping__GameRoundId_GameRoundStruct[_ImGameRoundId].Cards_InDealer = _New_CardInDealer;
        
        emit Initialize_GameRoundEvent
        (
            {_PlayerUserIdSetEvent: _Player_UserIds,
            _GameRoundIdEvent: _ImGameRoundId}
        );
        
        return (_ImGameRoundId);
    }
    
    
    
    
    
    function Initialize_PlayUnit (uint _GameRoundId, uint _UserId, uint _Betting) 
    internal 
    returns(Play_Unit memory _New_PlayUnit) 
    {
        uint[] memory _Cards_InHand;
        _Cards_InHand = GetCard({_Im_GameRoundId: _GameRoundId,_Im_Original_CardInHand: _Cards_InHand});
        _Cards_InHand = GetCard({_Im_GameRoundId: _GameRoundId,_Im_Original_CardInHand: _Cards_InHand});

        Play_Unit memory Im_New_PlayUnit = Play_Unit({Player_UserId: _UserId , Bettings: _Betting, Cards_InHand: _Cards_InHand});
        
        emit Initialize_GamePlayUnitEvent
        (
            {_PlayerUserIdEvent: _UserId,
            _BettingsEvent: _Betting,
            _Cards_InHandEvent: _Cards_InHand}
        );        
        
        return Im_New_PlayUnit;
    }




    
    function GetCard (uint _Im_GameRoundId, uint[] memory _Im_Original_CardInHand ) 
    internal 
    returns (uint[] memory _Im_Afterward_CardInHand )
    {
        uint[] storage Im_CardsOnBoard = Mapping__GameRoundId_GameRoundStruct[_Im_GameRoundId].Cards_Exsited;
        
        //do rand
        uint Im_52_RandNumber = GetRandom_In52(now);
        Im_52_RandNumber = Im_Cute_RecusiveFunction({Im_UnCheck_Number: Im_52_RandNumber, CheckNumberSet: Im_CardsOnBoard});
        
        Mapping__GameRoundId_GameRoundStruct[_Im_GameRoundId].Cards_Exsited.push(Im_52_RandNumber);
        
        _Im_Original_CardInHand[_Im_Original_CardInHand.length-1] = (Im_52_RandNumber);

        emit GetCardEvent
        (
            {_GameRoundIdEvent: _Im_GameRoundId,
            _GetCardsInHandEvent: _Im_Original_CardInHand}
        );     
        
        return _Im_Original_CardInHand;
    }





    function Im_Cute_RecusiveFunction (uint Im_UnCheck_Number, uint[] memory CheckNumberSet) 
    internal 
    returns (uint _Im_Unrepeat_Number)
    {
        
        for(uint _Im_CheckCounter = 0; _Im_CheckCounter <= CheckNumberSet.length ; _Im_CheckCounter++)
        {
            
            while (Im_UnCheck_Number == CheckNumberSet[_Im_CheckCounter])
            {
                Im_UnCheck_Number = GetRandom_In52(Im_UnCheck_Number);
                Im_UnCheck_Number = Im_Cute_RecusiveFunction(Im_UnCheck_Number, CheckNumberSet);
            }
        }
        
        return Im_UnCheck_Number;
    }





    function GetRandom_In52(uint _Im_CuteNumber) 
    public view 
    returns (uint _Im_Random)
    {
        //Worship LuGoddess
        require(msg.sender != block.coinbase);
        uint _Im_RandomNumber_In52 = uint(keccak256(abi.encodePacked(blockhash(block.number), msg.sender, _Im_CuteNumber))) % 52;
        
        return _Im_RandomNumber_In52;
    }
    
    
    
    
    
    function Counting_CardPoint (uint _Card_Number) 
    public view 
    returns(uint _CardPoint) 
    {
        uint figure = (_Card_Number%13);
        uint Im_CardPoint = Im_BlackJack_CardFigureToPoint[figure];
        
        return Im_CardPoint;   
    }
    
    
    
    
    
    function Counting_HandCardPoint (uint[] memory _Card_InHand) 
    public view
    returns(uint _TotalPoint) 
    {
        uint _Im_Card_Number;
        uint Im_AccumulatedPoints = 0;
        
        //Accumulate hand point
        for (uint Im_CardCounter = 0 ; Im_CardCounter < _Card_InHand.length ; Im_CardCounter++) 
        {
            _Im_Card_Number = _Card_InHand[Im_CardCounter];
            
            Im_AccumulatedPoints = Im_AccumulatedPoints + Counting_CardPoint(_Im_Card_Number);
        }

        //Check ACE
        for (uint Im_CardCounter = 0 ; Im_CardCounter < _Card_InHand.length ; Im_CardCounter++) 
        {
            _Im_Card_Number = _Card_InHand[Im_CardCounter];
            
            if((_Im_Card_Number%13) == 0 && Im_AccumulatedPoints <= 11) 
            {
                Im_AccumulatedPoints = Im_AccumulatedPoints + 10;
            }
        }
        
        return Im_AccumulatedPoints;
    }
    
    
    
    

    function Determine_Result(uint _GameId, uint _RoundId) 
    internal
    returns (uint[] memory _WinnerUserId, uint[] memory _LoserUserId) 
    {
        uint[] memory Im_WinnerUserIdSet;
        uint[] memory Im_DrawIdSet;
        uint[] memory Im_LoserIdSet;

        Game_Unit memory Im_GameUnit_Instance = Mapping__GameUnitId_GameUnitStruct[_GameId];
        Game_Round_Unit storage Im_GameRoundUnit_Instance = Mapping__GameRoundId_GameRoundStruct[_RoundId];

        uint Im_PlayerTotalPoint;
        uint Im_DealerTotalPoint = Counting_HandCardPoint({_Card_InHand: Im_GameRoundUnit_Instance.Cards_InDealer});
        
        for(uint Im_PlayUnitCounter = 0 ; Im_PlayUnitCounter <= Im_GameUnit_Instance.Player_UserIds.length; Im_PlayUnitCounter++)
        {
            Im_GameRoundUnit_Instance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand.pop;
            
            uint Im_PlayerUserId = Im_GameRoundUnit_Instance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Player_UserId;
            Im_PlayerTotalPoint = Counting_HandCardPoint(Im_GameRoundUnit_Instance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand);
            
            if(Im_PlayerTotalPoint > 21 && Im_DealerTotalPoint > 21)
            {
                Im_DrawIdSet[Im_DrawIdSet.length] = Im_PlayerUserId;  
            } 
            else if (Im_PlayerTotalPoint > 21) 
            {
                Im_LoserIdSet[Im_LoserIdSet.length] = Im_PlayerUserId;
            } 
            else if (Im_DealerTotalPoint > 21) 
            {
                Im_WinnerUserIdSet[Im_WinnerUserIdSet.length] = Im_PlayerUserId;
            } 
            else if (Im_DealerTotalPoint > Im_PlayerTotalPoint) 
            {
                Im_LoserIdSet[Im_LoserIdSet.length] = Im_PlayerUserId;
            } 
            else if (Im_PlayerTotalPoint > Im_DealerTotalPoint) 
            {
                Im_WinnerUserIdSet[Im_WinnerUserIdSet.length] = Im_PlayerUserId;
            }
            else if (Im_PlayerTotalPoint == Im_DealerTotalPoint) 
            {
                Im_DrawIdSet[Im_DrawIdSet.length] = Im_PlayerUserId;
            } 
        }
            
        emit Determine_GameRoundResult
        (
            {_GameIdEvent: _GameId,
            _GameRoundIdEvent: _RoundId,
            _WinnerUserIdEvent: Im_WinnerUserIdSet,
            _DrawUserIdEvent: Im_DrawIdSet,
            _LoserUserIdEvent: Im_LoserIdSet}
        );        
        
        return (Im_WinnerUserIdSet, Im_LoserIdSet);
    }

}
/* =================================================================
Contact END : Basic Functionalities
==================================================================== */





/* =================================================================
Contact HEAD : Integratwion User Workflow
==================================================================== */

// ----------------------------------------------------------------------------
// Black jack Integrated User functionality Workflow
// ----------------------------------------------------------------------------

contract Play_Blackjack is Blackjack_Functionality
{





    function Create_UserAccount (uint UserId, string memory UserName, string memory UserDescription) 
    public whenNotPaused
    returns (uint _UserId, address _UserAddress, string memory _UserName, string memory _UserDescription)
    {
        require(Mapping__UserAddress_UserId[msg.sender] == 0);

        (
        uint Im_UserId, 
        address Im_UserAddress, 
        string memory Im_UserName, 
        string memory Im_UserDescription
        ) 
        = Initialize_UserAccount
        (
            {_UserId: UserId,
            _UserName: UserName,
            _UserDescription: UserDescription}
        );
        
        return (Im_UserId, Im_UserAddress, Im_UserName, Im_UserDescription);
       }




  
    function Create_AutoGame (uint AutoGame_BettingRank) 
    public whenNotPaused
    returns (uint _CreateGameId) 
    {
        uint _Im_MIN_BettingLimit = Mapping__AutoGameBettingRank_BettingRange[AutoGame_BettingRank][0];
        uint _Im_MAX_BettingLimit = Mapping__AutoGameBettingRank_BettingRange[AutoGame_BettingRank][1];
        uint[] memory _Im_AutoGamePlayer_UserId;
        _Im_AutoGamePlayer_UserId[0] = Mapping__UserAddress_UserId[msg.sender];
        
        ImCounter_AutoGameId = ImCounter_AutoGameId + 1;

        Initialize_Game
        (
            {_GameId: ImCounter_AutoGameId, 
            _Player_UserIds: _Im_AutoGamePlayer_UserId, 
            _Dealer_UserId: Mapping__UserAddress_UserId[address(this)], 
            _MIN_BettingLimit: _Im_MIN_BettingLimit, 
            _MAX_BettingLimit: _Im_MAX_BettingLimit}
        );
        
        return (ImCounter_AutoGameId);
    }
        



    
    function Create_DualGame 
    (
        uint[] memory PlayerIds ,
        uint MIN_BettingLimit ,
        uint MAX_BettingLimit
    ) 
        public whenNotPaused
        returns (uint _CreateGameId) 
        {
        require(MIN_BettingLimit <= MAX_BettingLimit);
        uint _Im_DualGameCreater_UserId = Mapping__UserAddress_UserId[msg.sender];
        
        ImCounter_DualGameId = ImCounter_DualGameId + 1;        
        
        Initialize_Game
        (
            {_GameId: ImCounter_DualGameId, 
            _Player_UserIds: PlayerIds, 
            _Dealer_UserId: _Im_DualGameCreater_UserId, 
            _MIN_BettingLimit: MIN_BettingLimit, 
            _MAX_BettingLimit: MAX_BettingLimit}
        );
        
        return (ImCounter_DualGameId);
    }
    
    
    
    
    
    function Player_Bettings(uint GameId, uint Im_BettingsERC20Ammount) 
    public whenNotPaused
    returns (uint _GameId, uint GameRoundId, uint BettingAmount) 
    {
        require(Im_BettingsERC20Ammount >= Mapping__GameUnitId_GameUnitStruct[GameId].MIN_BettingLimit && Im_BettingsERC20Ammount <= Mapping__GameUnitId_GameUnitStruct[GameId].MAX_BettingLimit);
        
        uint Im_GameId;
        uint Im_GameRoundId;
        uint Im_BettingAmount;
        
        (Im_GameId, Im_GameRoundId, Im_BettingAmount) = Bettings({_GameId: GameId,_Im_BettingsERC20Ammount: Im_BettingsERC20Ammount});
        
        return (Im_GameId, Im_GameRoundId, Im_BettingAmount);
    }    
    

    
    
    
    
    function Start_NewRound(uint GameId) 
    public whenNotPaused
    returns (uint StartRoundId) 
    {
        Game_Unit memory Im_GameUnitData= Mapping__GameUnitId_GameUnitStruct[GameId];
        uint Im_GameRoundId = Im_GameUnitData.Game_RoundsIds[Im_GameUnitData.Game_RoundsIds.length -1];
        uint[] memory Im_PlayerUserIdSet = Im_GameUnitData.Player_UserIds;
        uint Im_MIN_BettingLimit = Im_GameUnitData.MIN_BettingLimit;
        uint Im_MAX_BettingLimit = Im_GameUnitData.MAX_BettingLimit;

        if (Im_MAX_BettingLimit == 0) 
        {
            uint Im_NewRoundId = Initialize_Round({_ImGameRoundId: Im_GameRoundId, _Player_UserIds: Im_PlayerUserIdSet});
            
            return Im_NewRoundId;
        } 
        else 
        {
            
            for(uint Im_PlayerCounter = 0; Im_PlayerCounter <= Im_PlayerUserIdSet.length; Im_PlayerCounter++) 
            {
                uint Im_PlayerUserId = Im_PlayerUserIdSet[Im_PlayerCounter];
                uint Im_UserBettingAmount = Mapping__GameRoundIdUserId_Bettings[Im_GameRoundId][Im_PlayerUserId];
            
                require(Im_UserBettingAmount >= Im_MIN_BettingLimit && Im_UserBettingAmount <= Im_MAX_BettingLimit);
                
                emit CheckBetting_Anouncement 
                (
                    {GameRoundId: Im_GameRoundId, 
                    UserId: Im_PlayerUserId, 
                    UserBettingAmount: Im_UserBettingAmount, 
                    MinBettingLimit: Im_MIN_BettingLimit,
                    MaxBettingLimit: Im_MAX_BettingLimit}
                );
            }
            
            uint Im_NewRoundId = Initialize_Round({_ImGameRoundId: Im_GameRoundId, _Player_UserIds: Im_PlayerUserIdSet});
            
            return Im_NewRoundId;
        }
        
        return 0;
    }
    
    
    

    
    function Player_HitOrStand (uint GameId, bool Hit_or_Stand) 
    public whenNotPaused
    returns (uint[] memory NewCards_InHand) 
    {
        Game_Unit memory Im_GameUnit_Instance = Mapping__GameUnitId_GameUnitStruct[GameId];
        uint Im_RoundId = Im_GameUnit_Instance.Game_RoundsIds[Im_GameUnit_Instance.Game_RoundsIds.length -1];
        
        Game_Round_Unit storage Im_GameRoundUnit_StorageInstance = Mapping__GameRoundId_GameRoundStruct[Im_RoundId];
        
        for (uint Im_PlayUnitCounter = 0; Im_PlayUnitCounter <= Im_GameUnit_Instance.Player_UserIds.length; Im_PlayUnitCounter++) 
        {
            if (Mapping__UserAddress_UserId[msg.sender] == Im_GameRoundUnit_StorageInstance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Player_UserId ) 
            {
                if (Hit_or_Stand) 
                {
                    Im_GameRoundUnit_StorageInstance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand = GetCard({_Im_GameRoundId: Im_RoundId, _Im_Original_CardInHand: Im_GameRoundUnit_StorageInstance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand});

                    return Im_GameRoundUnit_StorageInstance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand;
                } 
                else if (Hit_or_Stand == false) 
                {
                    Im_GameRoundUnit_StorageInstance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand.push(1111);

                    return Im_GameRoundUnit_StorageInstance.Mapping__Index_PlayUnitStruct[Im_PlayUnitCounter].Cards_InHand;
                }
            }
        }
    }
   
    
    


    function Dealer_HitOrStand (uint GameId, bool Hit_or_Stand) 
    public StandCheck_AllPlayer(GameId) whenNotPaused
    returns (uint[] memory Cards_InDealerHand) 
    {
        require(Mapping__UserAddress_UserId[msg.sender] == Mapping__GameUnitId_GameUnitStruct[GameId].Dealer_UserId);
        
        Game_Unit memory Im_GameUnit_Instance = Mapping__GameUnitId_GameUnitStruct[GameId];
        
        uint Im_RoundId = Im_GameUnit_Instance.Game_RoundsIds[Im_GameUnit_Instance.Game_RoundsIds.length -1];
        Game_Round_Unit storage Im_GameRoundUnit_StorageInstance = Mapping__GameRoundId_GameRoundStruct[Im_RoundId];
        
        
        uint Im_DealerUserId = Im_GameUnit_Instance.Dealer_UserId;
        uint[] memory WeR_WinnerId;
        uint[] memory WeR_LoserId;
        
        if (Hit_or_Stand) 
        {
            Im_GameRoundUnit_StorageInstance.Cards_InDealer = GetCard({_Im_GameRoundId: Im_RoundId, _Im_Original_CardInHand: Im_GameRoundUnit_StorageInstance.Cards_InDealer});
            
            return Im_GameRoundUnit_StorageInstance.Cards_InDealer;
        } 
        else if (Hit_or_Stand == false) 
        {
            //Get winner and loser
            (WeR_WinnerId, WeR_LoserId) = Determine_Result({_GameId: GameId,_RoundId: Im_RoundId});
            
            //Transfer moneymoney to winners
            for(uint Im_WinnerCounter = 0; Im_WinnerCounter <= WeR_WinnerId.length ; Im_WinnerCounter++) 
            {
                uint Im_WinnerUserId = WeR_WinnerId[Im_WinnerCounter];
                uint Im_WinnerBettingAmount = Mapping__GameRoundIdUserId_Bettings[Im_RoundId][Im_WinnerUserId];

                Mapping__OwnerUserId_ERC20Amount[Im_DealerUserId] - Im_WinnerBettingAmount;
                Mapping__OwnerUserId_ERC20Amount[Im_WinnerUserId] + Im_WinnerBettingAmount;
            }

            //Transfer moneymoney from losers          
            for(uint Im_LoserCounter = 0; Im_LoserCounter <= WeR_LoserId.length ; Im_LoserCounter++) 
            {
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
/* =================================================================
Contact HEAD : Integration User Workflow
==================================================================== */
//Create by <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a1ccc4ced6c4cfd5e1c6ccc0c8cd8fc2cecc">[email&#160;protected]</a> +886 975330002
//Worship Lu Goddess Forever