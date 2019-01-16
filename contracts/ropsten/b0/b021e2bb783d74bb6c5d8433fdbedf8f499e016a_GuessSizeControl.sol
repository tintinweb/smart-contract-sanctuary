pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
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

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal
    {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


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
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract Pausable is Ownable {
    event Paused();
    event Unpaused();

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused();
    }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused();
    }
}

contract GuessSizeDataInterface{
    function GetPlayers(uint8 _roomIndex) public view returns(address[]);
    function GetBanker(uint8 _roomIndex) public view returns(address);
    function GetBankerCandidate(uint8 _roomIndex) public view returns(address);
    function GetBankerRound(uint8 _roomIndex) public view returns(uint16);
    function GetBankerProfit(uint8 _roomIndex) public view returns(uint256);
    function GetNonce(uint8 _roomIndex) public view returns(uint256);
    function GetRoundIndex(uint8 _roomIndex) public view returns(uint256);
    function GetBankerPrincipal(uint8 _roomIndex) public view returns(uint256);
    function GetCandidatePrincipal(uint8 _roomIndex) public view returns(uint256);
    function GetPlayerNumber(uint8 _roomIndex) public view returns(uint8);
    function GetBetInfo(uint8 _roomIndex,uint256 _roundIndex,address _addr) public view returns(uint256,uint8);
    function AddBankerProfit(uint8 _roomIndex,uint256 _value) external;
    function SubBankerProfit(uint8 _roomIndex,uint256 _value) external;
    function SetBanker(uint8 _roomIndex,address _addr) external;
    function SetBankerCandidate(uint8 _roomIndex,address _addr) external;
    function CleanBankerProfit(uint8 _roomIndex) external;
    function RoomNonceAdd(uint8 _roomIndex) external;
    function RoomRoundAdd(uint8 _roomIndex) external;
    function AddBankerPrincipal(uint8 _roomIndex,uint256 _value) external;
    function SubBankerPrincipal(uint8 _roomIndex,uint256 _value) external;
    function SetBankerPrincipal(uint8 _roomIndex,uint256 _value) external;
    function SetCandidatePrincipal(uint8 _roomIndex,uint256 _value) external;
    function SetRoundResult(uint8 _roomIndex,uint8 _dice1,uint8 _dice2,uint8 _dice3,uint8 _cardType) external;
    function DissolutionRoom(uint8 _roomIndex,bool _isClean) external;
    function AddPlayer(uint8 _roomIndex,address _addr) external;
    function SetPlayerBetInfo(uint8 _roomIndex,address _player,uint256 _bet,uint8 _cardType) external;
    function CleanBankerCandidate(uint8 _roomIndex) external;
    function CleanBankerRound(uint8 _roomIndex)external;
    function AddBankerRound(uint8 _roomIndex) external;
    function GetCurrentRoomAndRound(address _addr) external view returns(uint8,uint256,bool);
    function GetLastRoomAndRound(address _addr) external view returns(uint8,uint256,bool);
    function SetCurrentRoomAndRound(address _addr,uint8 _roomIndex,uint256 _roundIndex,bool _isbanker) external;
    function SetLastRoomAndRound(address _addr,uint8 _roomIndex,uint256 _roundIndex,bool _isbanker) external;
    function CleanCurrentRoomAndRound(address _addr) external;
}

contract GuessSizeControl is Pausable{
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public token;

    GuessSizeDataInterface GuessSizeData;

    address developer;

    enum CardType{Big,Small}

    uint8 constant decimals = 18; // solium-disable-line uppercase
    uint256  minLimitBet = 1 *(10**3)*(10 ** uint256(decimals));
    uint256  maximalBet = 1 *(10**4)*(10 ** uint256(decimals));

    uint256 minLimitBankerPrincipal = 6 *(10**4)*(10 ** uint256(decimals));

    uint8 RoomMaxPlayerNumber = 6;

    uint16 minlimitBankerRound = 6;
    
    constructor(ERC20 _token,address _addr) public
    {
        token = _token;
        developer = _addr;
    }

    event event_lottery(uint8 _roomIndex,uint8 _dice1,uint8 _dice2,uint8 _dice3);
    event event_winner(uint8 _roomIndex,address _addr,uint256 _value);
    event event_underdog(uint8 _roomIndex,address _addr,uint256 _value);
    event event_bankerChange(uint8 _roomIndex,address _banker,address _bankerCandidate);
    event event_cleanRoom(uint8 _roomIndex,bool _isClean);
    event event_quitBankerCandidate(uint8 _roomIndex,address _addr,uint256 _value);
    event event_quitBanker(uint8 _roomIndex,address _addr,uint256 _value);

    function JoinGameAsBanker(uint8 _roomIndex,uint256 _gcc) external whenNotPaused{
        uint8 currentRoomIndex;
        (currentRoomIndex,,) = GuessSizeData.GetCurrentRoomAndRound(msg.sender);
        require(currentRoomIndex == 0);
        require(GuessSizeData.GetBanker(_roomIndex) == address(0));
        require(_gcc >= minLimitBankerPrincipal);

        token.safeTransferFrom(msg.sender, this, _gcc);
        
        GuessSizeData.SetCurrentRoomAndRound(msg.sender,_roomIndex,GuessSizeData.GetRoundIndex(_roomIndex),true);
        GuessSizeData.SetBanker(_roomIndex,msg.sender);
        GuessSizeData.SetBankerPrincipal(_roomIndex,_gcc);
        GuessSizeData.CleanBankerProfit(_roomIndex);
        GuessSizeData.CleanBankerRound(_roomIndex);
    }

    function RobBanker(uint8 _roomIndex,uint256 _bet,uint256 _principal,uint8 _cardType) external whenNotPaused{
        uint8 currentRoomIndex;
        (currentRoomIndex,,) = GuessSizeData.GetCurrentRoomAndRound(msg.sender);
        require(currentRoomIndex == 0);
        require(GuessSizeData.GetBanker(_roomIndex) != address(0));
        require(GuessSizeData.GetBankerCandidate(_roomIndex) == address(0));
        require(_principal >= GuessSizeData.GetBankerPrincipal(_roomIndex));
        
        uint256 total = _bet.add(_principal);
        token.safeTransferFrom(msg.sender, this, total);

        GuessSizeData.SetCurrentRoomAndRound(msg.sender,_roomIndex,GuessSizeData.GetRoundIndex(_roomIndex),false);
        GuessSizeData.SetBankerCandidate(_roomIndex,msg.sender);
        GuessSizeData.SetCandidatePrincipal(_roomIndex,_principal);
        RoomPlayersAdd(_roomIndex,msg.sender,_bet,_cardType);
        if(GuessSizeData.GetPlayerNumber(_roomIndex) >= RoomMaxPlayerNumber){
            GetLottery(_roomIndex);
        }
    }

    function JoinGameAsPlayer(uint8 _roomIndex,uint256 _gcc,uint8 _cardType) external whenNotPaused{
        uint8 currentRoomIndex;
        (currentRoomIndex,,) = GuessSizeData.GetCurrentRoomAndRound(msg.sender);
        require(currentRoomIndex == 0);
        require(GuessSizeData.GetBanker(_roomIndex) != address(0));
        require(_gcc >= minLimitBet && _gcc <= maximalBet);
        require(GuessSizeData.GetPlayerNumber(_roomIndex) <= RoomMaxPlayerNumber);

        token.safeTransferFrom(msg.sender, this, _gcc);
        
        GuessSizeData.SetCurrentRoomAndRound(msg.sender,_roomIndex,GuessSizeData.GetRoundIndex(_roomIndex),false);
        RoomPlayersAdd(_roomIndex,msg.sender,_gcc,_cardType);
        if(GuessSizeData.GetPlayerNumber(_roomIndex) >= RoomMaxPlayerNumber){
            GetLottery(_roomIndex);
        }
    }

    function Lottery(uint8 _roomIndex) private returns(uint8){
        uint8 dice1 = RandomNumber(_roomIndex);
        uint8 dice2 = RandomNumber(_roomIndex);
        uint8 dice3 = RandomNumber(_roomIndex);

        uint8 cardType = GetCardType(dice1,dice2,dice3);

        GuessSizeData.SetRoundResult(_roomIndex,dice1,dice2,dice3,cardType);
        emit event_lottery(_roomIndex,dice1,dice2,dice3);
        
        return(cardType);
    }

    function RandomNumber(uint8 _roomIndex) private returns(uint8 random) 
    {
        random = uint8(keccak256(abi.encodePacked(now,_roomIndex, GuessSizeData.GetNonce(_roomIndex)))) % 5;
        GuessSizeData.RoomNonceAdd(_roomIndex);
        return random + 1;
    }

    function SetDataAddress(address _addr) external onlyOwner{
        GuessSizeData = GuessSizeDataInterface(_addr);
    }

    function GetCardType(uint8 _dice1,uint8 _dice2,uint8 _dice3) private pure returns(uint8){
        uint8 total = _dice1 + _dice2 + _dice3;

        if(total >= 11){
            return 0;
        }else{
            return 1;
        }
    }

    function GetLottery(uint8 _roomIndex) private{
        //生成游戏结果，执行结算函数;
        CardType cardType = CardType(Lottery(_roomIndex));
        
        address[] memory players = GuessSizeData.GetPlayers(_roomIndex);

        uint256 roundIndex = GuessSizeData.GetRoundIndex(_roomIndex);

        address bankerCandidate = GuessSizeData.GetBankerCandidate(_roomIndex);

        uint256 total_tax = 0;
        bool candidateIsWin = false;
        for(uint8 i = 0;i< players.length;i++){
            uint256 p_bet;
            uint8 p_cardType;
            (p_bet,p_cardType) = GuessSizeData.GetBetInfo(_roomIndex,roundIndex,players[i]);

            if(CardType(p_cardType) == cardType){
                if(players[i] == bankerCandidate){
                    candidateIsWin = true;
                }
                uint256 afterTax;
                uint256 tax;
                (afterTax,tax) = CollectTaxes(p_bet);
                uint256 total = afterTax.add(p_bet);

                token.safeTransfer(players[i],total);
                emit event_winner(_roomIndex,players[i],p_bet);
                total_tax += tax;
                GuessSizeData.SubBankerPrincipal(_roomIndex,p_bet);
                GuessSizeData.SubBankerProfit(_roomIndex,p_bet);
            }else
            {
                GuessSizeData.AddBankerPrincipal(_roomIndex,p_bet);
                GuessSizeData.AddBankerProfit(_roomIndex,p_bet);
                emit event_underdog(_roomIndex,players[i],p_bet);
            }
            
            SetLastRoomAndRound(players[i],_roomIndex,roundIndex,false);
        }
        token.safeTransfer(developer,tax);
        Settlement(_roomIndex,candidateIsWin);

        GuessSizeData.RoomRoundAdd(_roomIndex);
    }

    function RoomPlayersAdd(uint8 _roomIndex,address _player,uint256 _bet,uint8 _cardType) private{
        GuessSizeData.AddPlayer(_roomIndex,_player);
        GuessSizeData.SetPlayerBetInfo(_roomIndex,_player,_bet,_cardType);
    }

    function Settlement(uint8 _roomIndex,bool _candidateIsWin) private{
        address banker = GuessSizeData.GetBanker(_roomIndex);
        uint256 profit = GuessSizeData.GetBankerProfit(_roomIndex);
        uint256 bankerPrincipal = GuessSizeData.GetBankerPrincipal(_roomIndex);
        address candidate = GuessSizeData.GetBankerCandidate(_roomIndex);
        uint256 candidatePrincipal = GuessSizeData.GetCandidatePrincipal(_roomIndex);
        uint256 roundIndex =GuessSizeData.GetRoundIndex(_roomIndex);

        uint256 surplus =0;
        if(candidate != address(0))
        {
            if(_candidateIsWin == true)
            {
                if(profit >0){
                    uint256 afterTax;
                    uint256 tax;
                    (afterTax,tax) = CollectTaxes(profit);
                    token.safeTransfer(developer,tax);
                    surplus = bankerPrincipal.sub(tax);
                }else{
                    surplus = bankerPrincipal;
                }
                token.safeTransfer(banker,surplus);
                emit event_quitBanker(_roomIndex,banker,surplus);
                emit event_bankerChange(_roomIndex,banker,candidate);

                SetLastRoomAndRound(banker,_roomIndex,roundIndex,true);
                
                GuessSizeData.SetBanker(_roomIndex,candidate);
                GuessSizeData.SetBankerPrincipal(_roomIndex,candidatePrincipal);
                GuessSizeData.SetCurrentRoomAndRound(candidate,_roomIndex,roundIndex,true);
                GuessSizeData.CleanBankerRound(_roomIndex);
                GuessSizeData.CleanBankerProfit(_roomIndex);
            }
            else
            {
                token.safeTransfer(candidate,candidatePrincipal);
                emit event_quitBankerCandidate(_roomIndex,candidate,candidatePrincipal);
            }
            GuessSizeData.CleanBankerCandidate(_roomIndex);

            GuessSizeData.DissolutionRoom(_roomIndex,false);
            emit event_cleanRoom(_roomIndex,false);
        }
        else
        {
           /* if(bankerPrincipal < minLimitBankerPrincipal)
            {
                token.safeTransfer(banker,bankerPrincipal);
                emit event_quitBanker(_roomIndex,banker,bankerPrincipal);

                GuessSizeData.DissolutionRoom(_roomIndex,true);
                SetLastRoomAndRound(banker,_roomIndex,roundIndex,true);
                emit event_cleanRoom(_roomIndex,true);
            }else
            {
                GuessSizeData.DissolutionRoom(_roomIndex,false);
                emit event_cleanRoom(_roomIndex,false);
            } */     
        }
    }

    function CollectTaxes(uint256 _value) private pure returns(uint256 _afterTax,uint256 _tax){
        _tax = _value.mul(5).div(100);
        _afterTax = _value.sub(_tax);
    }

    function BankerExit(uint8 _roomIndex) public{
        address banker = GuessSizeData.GetBanker(_roomIndex);
        require(msg.sender == banker);
        require(GuessSizeData.GetBankerRound(_roomIndex) >= minlimitBankerRound);
        
        uint256 bankerPrincipal = GuessSizeData.GetBankerPrincipal(_roomIndex);
        uint256 profit = GuessSizeData.GetBankerProfit(_roomIndex);
        uint256 surplus =0;
        if(profit >0){
            uint256 afterTax;
            uint256 tax;
            (afterTax,tax) = CollectTaxes(profit);
            token.safeTransfer(developer,tax);
            surplus = bankerPrincipal.sub(tax);
        }else{
            surplus = bankerPrincipal;
        }
        
        token.safeTransfer(banker,surplus);
        
        SetLastRoomAndRound(banker,_roomIndex,GuessSizeData.GetRoundIndex(_roomIndex),true);
        GuessSizeData.CleanBankerProfit(_roomIndex);
        emit event_quitBanker(_roomIndex,banker,surplus);
    }

    function SetLastRoomAndRound(address _addr,uint8 _roomIndex,uint256 _roundIndex,bool _isbanker) private{
        GuessSizeData.CleanCurrentRoomAndRound(_addr);
        GuessSizeData.SetLastRoomAndRound(_addr,_roomIndex,_roundIndex,_isbanker);
    } 
}