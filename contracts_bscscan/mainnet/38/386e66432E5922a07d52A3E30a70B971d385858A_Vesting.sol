/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}









contract Vesting{
address public TokenAddress;
IBEP20 Token;
address public owner;
constructor(address token)
{
    TokenAddress=token;
    Token=IBEP20(token);
    owner=msg.sender;
}



modifier onlyOwner{
    require(msg.sender==owner);
    _;
}
uint VestStartTimestamp;
uint TotalVestTime=100 days;
function StartVesting() public onlyOwner{
    require(VestStartTimestamp==0);
    VestStartTimestamp=block.timestamp;
}
mapping(address=>uint) vestedTokenOfAccount;
mapping(address=>uint) unvestedToken;



//VestTime in Seconds from vestStart
mapping(address=>uint) vestDuration;
mapping(address=>uint) delayedVestStart;
function GetVestedToken(address account) public view returns(uint){
    return vestedTokenOfAccount[account]-unvestedToken[account];
}
function GetVestStart(address account) public view returns(uint256){
    require(VestStartTimestamp>0,"Vesting not yet started");
    return VestStartTimestamp+delayedVestStart[account];
}
function GetVestTime(address account) public view returns(uint256){
    uint time=vestDuration[account];
    if(time<TotalVestTime) return TotalVestTime;
    else return time;
}

uint public RecordedBalance;
uint public NotAccountedToken;
function _updateToken() private{
    uint Balance=Token.balanceOf(address(this));
    uint NewBalance=Balance-RecordedBalance;
    NotAccountedToken+=NewBalance;
    RecordedBalance=Balance;
}
function ProlongVestPeriod(address account, uint secondsToVestStart, uint secondsForUnvest) public onlyOwner{
    require(VestStartTimestamp<=block.timestamp&&VestStartTimestamp!=0);
    require(VestStartTimestamp+GetVestTime(account)<block.timestamp+secondsForUnvest);
    require(secondsToVestStart<=secondsForUnvest);
    uint TimeSinceVestStart=(block.timestamp-VestStartTimestamp);

    delayedVestStart[account]=TimeSinceVestStart+secondsToVestStart;
    vestDuration[account]=secondsForUnvest;

    vestedTokenOfAccount[account]-=unvestedToken[account];
    unvestedToken[account]=0;
}




function VestToken(uint Amount, address Recipient) public onlyOwner{
    _updateToken();
    require(NotAccountedToken>=Amount);
    NotAccountedToken-=Amount;

    if(vestedTokenOfAccount[Recipient]==0)
        if(VestStartTimestamp!=0){
            ProlongVestPeriod(Recipient, 0, TotalVestTime);
        }
    
    vestedTokenOfAccount[Recipient]+=Amount;
    vestedTokenOfAccount[Recipient]-=unvestedToken[Recipient];
    unvestedToken[Recipient]=0;
}

//Substracts amount from recorded Balance;
function _transfer(address recipient, uint amount) private{
    require(amount>0);
    RecordedBalance-=amount;
    Token.transfer(recipient, amount);
}

function Unvest(uint PermilleToUnvest) public{
    _updateToken();
    require(PermilleToUnvest<=1000,"Can't unvest more than 100%");
    uint VestStart=GetVestStart(msg.sender);
    require((VestStart<=block.timestamp)&&(VestStartTimestamp!=0),"Vesting not yet started");
    uint vestedToken=vestedTokenOfAccount[msg.sender];
    uint TimeSinceVestStart=block.timestamp-VestStart;
    uint UnvestTime=GetVestTime(msg.sender);

    uint UnlockedToken;
    if(TimeSinceVestStart>=UnvestTime) UnlockedToken=vestedToken;
    else UnlockedToken=vestedToken*TimeSinceVestStart/UnvestTime;
    UnlockedToken-=unvestedToken[msg.sender];
    uint TokenToClaim=UnlockedToken*PermilleToUnvest/1000;
    unvestedToken[msg.sender]+=TokenToClaim;
    _transfer(msg.sender, TokenToClaim);
}


}