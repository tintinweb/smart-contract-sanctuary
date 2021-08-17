/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

pragma solidity ^ 0.8.4;

//SPDX-License-Identifier:MIT

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract BetContract{

    using SafeMath for uint256;
    
    IBEP20 Token;
    address payable public Admin;

    bool public betAvailable;

    uint256 public GlobalTotalBetAmont;
    uint256 public GlobalbetERCount;
    uint256 public BetDuration;
    uint256 public PlayersCOUNT;
    uint256 public TotalBetAmont;
    uint256 public betERCount;
    uint256 public WinersWeightCount;
    uint256 public StartBetPrice;
    uint256 public EndBetprice;
    uint256 public StartBettime;
    uint256 public EndBettime;
    uint256 public betPair;

    modifier isAdmin(){
        require(Admin == msg.sender);
        _;
    }
    struct BET{
        uint256 NumberofTOkens;
        uint256 timetoBET;
        bool win;
        bool isDraw;
        uint256 BETweight;
        bool prediction;
        uint256 Reward;
        bool pending;
    }
    struct User{
        uint256 totalTOKENSBet;
        uint256 RewardTOtal;
        uint256 winCOunt;
        uint256 loseCOnt;
        uint256 betCount;
        mapping(uint256 => BET)BetHistory;
        
    }
    mapping(address => User) public Players;
    mapping(uint256 => address) public BetIDs;
    
    constructor() {
        Admin =  payable(0x607541193dd9f7D3409f97b587EE3ab3d515C271);
        Token = IBEP20(0x454ac549a24ced7164c6A3BAED490FBd5e6D09dd);
        BetDuration = 5 minutes;
        PlayersCOUNT = 0;
        betERCount = 0;
        StartBetPrice = 0;
        EndBetprice = 0;
    }
    modifier BetOpen(){
        require(betAvailable,"You cannot bet Until admin Opens Again");
        _;
    }
    
    function Price(address Aggregator) public view returns (uint256) {
        (,int price,,,) = AggregatorV3Interface(Aggregator).latestRoundData();
        return uint256(price);
    }
    function BETTOKENS(bool Up , uint256 amountoftokens) public BetOpen{     
        require(block.timestamp > StartBettime && block.timestamp < EndBettime,"Cant Bet before TIME");
        require(amountoftokens.mod(100) == 0 && amountoftokens > 0,"Price shuold be Multiple of 5$ or 100 tokens");
        User storage user = Players[msg.sender];
        if(Up)
        {
            user.BetHistory[++user.betCount].prediction = true;
        }else{
            user.BetHistory[++user.betCount].prediction = false;
        }
        user.totalTOKENSBet = user.totalTOKENSBet.add(amountoftokens);
        user.BetHistory[user.betCount].NumberofTOkens = amountoftokens;
        user.BetHistory[user.betCount].timetoBET = block.timestamp;
        user.BetHistory[user.betCount].win = false;
        user.BetHistory[user.betCount].pending = true;
        user.BetHistory[user.betCount].BETweight = amountoftokens.div(100);
        Token.transferFrom(msg.sender,address(this),amountoftokens);
        BetIDs[betERCount] = msg.sender;
        betERCount++;
        GlobalbetERCount++;
        TotalBetAmont = TotalBetAmont.add(amountoftokens);
        GlobalTotalBetAmont = GlobalTotalBetAmont.add(amountoftokens);
    }

    function Start(address Aggregator) public isAdmin {
        betERCount = 0;
        StartBetPrice = Price(Aggregator);
        StartBettime = block.timestamp;
        EndBettime = block.timestamp + BetDuration;
        TotalBetAmont = 0;
        WinersWeightCount = 0;
        betAvailable = true;
    }

    function Stop(address Aggregator) public isAdmin {
        require(block.timestamp > StartBettime + BetDuration,"Cant stop before Default time");
        EndBetprice = Price(Aggregator);
        if(StartBetPrice < EndBetprice ){
            updatedata(true);
        }else if(StartBetPrice > EndBetprice ){
            updatedata(false);
        }else if(StartBetPrice == EndBetprice){
            Draw();
        }
        betAvailable = false;
    }

    function intializeBet(uint256 pairCount) public isAdmin {
        betPair = pairCount;
    }

    function Draw() internal{
        for(uint256 counter; counter < betERCount ; counter++)
        {
                Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].isDraw = true;
                Token.transfer(msg.sender,Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].NumberofTOkens);
        }
    }

    function updatedata(bool up) internal{
        if(up)
        {
            for(uint256 counter; counter < betERCount ; counter++){
                if(Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].prediction){
                    WinersWeightCount = WinersWeightCount.add(Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].BETweight);
                    Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].win = true;
                    Players[BetIDs[counter]].winCOunt++;
                }
                else{
                    Players[BetIDs[counter]].loseCOnt++;
                }
            }
        }else
        {
            for(uint256 counter; counter < betERCount ; counter++)
        {
            if(!Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].prediction){
                WinersWeightCount = WinersWeightCount.add(Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].BETweight);
                Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].win = true;
                Players[BetIDs[counter]].winCOunt++;
                
            }else{
                Players[BetIDs[counter]].loseCOnt++;
            }
        }
        }
        if(WinersWeightCount == 0 && TotalBetAmont > 0){

            Token.transfer(Admin,TotalBetAmont);

        }else if(TotalBetAmont > 0){
            Token.transfer(Admin,TotalBetAmont.mul(30).div(100));
            TotalBetAmont = TotalBetAmont.mul(70).div(100);
        }
        if(WinersWeightCount != 0){
            uint256 Perweightreward = TotalBetAmont.div(WinersWeightCount);
            for(uint256 counter; counter < betERCount ; counter++)
            {
                if(Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].win){
                    Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].Reward = Perweightreward.mul(Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].BETweight);
                    Players[BetIDs[counter]].RewardTOtal = Players[BetIDs[counter]].RewardTOtal.add(Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].Reward);
                    Token.transfer(BetIDs[counter],Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].Reward);
                }
            }
        }
        for(uint256 counter; counter < betERCount ; counter++)
            {
                Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].betCount].pending = false;
            }
    }
    
    function SetBetAvailibility(bool val) public isAdmin {
        betAvailable = val;
    }

    function SetBetDuration(uint256 time) public isAdmin{
        BetDuration = time;
    }

    function changeAdmin(address payable _new) public isAdmin{
        Admin = _new;
    }

    function getUserBetData(address _user, uint256 _index) public view returns(uint256, bool, bool, bool, bool, uint256){
        User storage user = Players[_user];
        return(
            user.BetHistory[_index].NumberofTOkens,
            user.BetHistory[_index].prediction,
            user.BetHistory[_index].pending,
            user.BetHistory[_index].win,
            user.BetHistory[_index].isDraw,
            user.BetHistory[_index].Reward
        );
    }

    function getUserData(address _user) public view returns(uint256, uint256, uint256, uint256, uint256){
        User storage user = Players[_user];
        return(
            user.totalTOKENSBet,
            user.RewardTOtal,
            user.winCOunt,
            user.loseCOnt,
            user.betCount
        );
    }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}