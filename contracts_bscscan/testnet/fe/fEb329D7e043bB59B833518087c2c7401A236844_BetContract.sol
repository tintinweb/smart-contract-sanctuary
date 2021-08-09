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

contract BetContract{

    using SafeMath for uint256;
    
    IBEP20 Token;
    address payable public Admin;
    bool public betAvailable;
    uint256 public GlobalToatalBetAmont;
    uint256 public GlobalBEtERCount;
    uint256 public BetDuration;
    uint256 public PlayersCOUNT;
    uint256 public ToatalBetAmont;
    uint256 public BEtERCount;
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
        bool drawvar;
        uint256 BETweight;
        bool predictionup;
        bool predictiondown;
        uint256 Reward;
        bool Claimed;
        bool pending;
    }
    struct User{
        uint256 totalTOKENSBet;
        uint256 RewardTOtal;
        uint256 winCOunt;
        uint256 loseCOnt;
        uint256 BetCOunt;
        mapping(uint256 => BET)BetHistory;
        
    }
    mapping(address => User) public Players;
    mapping(uint256 => address) public BetIDs;
    
    constructor() {
        Admin =  payable(0xa48f0D9d0cB30eb087C6589dc804CfEe7f1ed8eD);
        Token = IBEP20(0x454ac549a24ced7164c6A3BAED490FBd5e6D09dd);
        BetDuration = 15 minutes;
        PlayersCOUNT = 0;
        BEtERCount = 0;
        StartBetPrice = 0;
        EndBetprice = 0;
    }
    modifier BetOpen(){
        require(betAvailable,"You cannot bet Until admin Opens Again");
        _;
    }
    function BETTOKENS(bool Up , uint256 amountoftokens) public BetOpen{     
        require(block.timestamp > StartBettime && block.timestamp < EndBettime,"Cant Bet before TIME");
        require(amountoftokens.mod(100) == 0 && amountoftokens > 0,"Price shuold be Multiple of 5$ or 100 tokens");
        User storage user = Players[msg.sender];
        if(Up)
        {
            user.BetHistory[++user.BetCOunt].predictionup = true;
            user.BetHistory[user.BetCOunt].predictiondown = false;
        }else{
            user.BetHistory[++user.BetCOunt].predictionup = false;
            user.BetHistory[user.BetCOunt].predictiondown = true;
        }
        user.totalTOKENSBet = user.totalTOKENSBet.add(amountoftokens);
        user.BetHistory[user.BetCOunt].NumberofTOkens = amountoftokens;
        user.BetHistory[user.BetCOunt].timetoBET = block.timestamp;
        user.BetHistory[user.BetCOunt].win = false;
        user.BetHistory[user.BetCOunt].Claimed = false;
        user.BetHistory[user.BetCOunt].pending = true;
        user.BetHistory[user.BetCOunt].BETweight = amountoftokens.div(100);
        Token.transferFrom(msg.sender,address(this),amountoftokens);
        BetIDs[BEtERCount] = msg.sender;
        BEtERCount++;
        GlobalBEtERCount++;
        ToatalBetAmont = ToatalBetAmont.add(amountoftokens);
        GlobalToatalBetAmont = GlobalToatalBetAmont.add(amountoftokens);
    }
    function Claimreward(uint256 index) public
    {
        User storage user = Players[msg.sender] ;
        require(user.BetHistory[index].Reward > 0 ,"you have no reward to claim");
        require(!user.BetHistory[index].Claimed ,"already Claimed Reward");
        Token.transfer(msg.sender,user.BetHistory[index].Reward);
        user.BetHistory[index].Claimed = true;
    }

    function Start(uint256 price) public isAdmin {
        BEtERCount = 0;
        StartBetPrice = price;
        StartBettime = block.timestamp;
        EndBettime = block.timestamp + 15 minutes;
        ToatalBetAmont = 0;
        WinersWeightCount = 0;
        betAvailable = true;
    }

    function Stop(uint256 price) public isAdmin {
        require(block.timestamp > StartBettime + 15 minutes,"Cant stop before Default time");
        EndBetprice = price;
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
        for(uint256 counter; counter < BEtERCount ; counter++)
        {
                Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].drawvar = true;
                Token.transfer(msg.sender,Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].NumberofTOkens);
        }
    }

    function updatedata(bool up) internal{
        if(up)
        {
            for(uint256 counter; counter < BEtERCount ; counter++)
        {
            if(Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].predictionup && !Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].predictiondown){
                WinersWeightCount = WinersWeightCount.add(Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].BETweight);
                Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].win = true;
                Players[BetIDs[counter]].winCOunt++;
                
            }
            else{
                Players[BetIDs[counter]].loseCOnt++;
            }
        }
        }else
        {
            for(uint256 counter; counter < BEtERCount ; counter++)
        {
            if(!Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].predictionup && Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].predictiondown){
                WinersWeightCount = WinersWeightCount.add(Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].BETweight);
                Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].win = true;
                Players[BetIDs[counter]].winCOunt++;
                
            }else{
                Players[BetIDs[counter]].loseCOnt++;
            }
        }
        }
        if(WinersWeightCount == 0 && ToatalBetAmont > 0){

            Token.transfer(Admin,ToatalBetAmont);

        }
        else if(ToatalBetAmont > 0){
            Token.transfer(Admin,ToatalBetAmont.mul(30).div(100));
            ToatalBetAmont = ToatalBetAmont.mul(70).div(100);
        }
        if(WinersWeightCount == 0) WinersWeightCount = 1;
        uint256 Perweightreward = ToatalBetAmont.div(WinersWeightCount);
        for(uint256 counter; counter < BEtERCount ; counter++)
        {
            Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].pending = false;
            if(Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].win){
                Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].Reward = Perweightreward.mul(Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].BETweight);
                Players[BetIDs[counter]].RewardTOtal = Players[BetIDs[counter]].RewardTOtal.add(Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].Reward);
                Token.transfer(BetIDs[counter],Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].Reward);
                Players[BetIDs[counter]].BetHistory[Players[BetIDs[counter]].BetCOunt].Claimed = true;
            }
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

    function getUserBetData(address _user, uint256 _index) public view returns(uint256, bool, bool, uint256, bool, bool){
        User storage user = Players[_user];
        return(
            user.BetHistory[_index].NumberofTOkens,
            user.BetHistory[_index].predictionup,
            user.BetHistory[_index].predictiondown,
            user.BetHistory[_index].Reward,
            user.BetHistory[_index].win,
            user.BetHistory[_index].Claimed
        );
    }

    function getUserData(address _user) public view returns(uint256, uint256, uint256, uint256, uint256){
        User storage user = Players[_user];
        return(
            user.totalTOKENSBet,
            user.RewardTOtal,
            user.winCOunt,
            user.loseCOnt,
            user.BetCOunt
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