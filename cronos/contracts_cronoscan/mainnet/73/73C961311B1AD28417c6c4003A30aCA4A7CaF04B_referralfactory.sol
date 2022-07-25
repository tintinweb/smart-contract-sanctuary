/**
 *Submitted for verification at cronoscan.com on 2022-05-27
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-13
*/

/*
Validator Contract
https://t.me/BatemanCasinoLounge
@PatrickBateman_VP
*/
pragma solidity 0.8.8;
// SPDX-License-Identifier: Unlicensed
interface proxy
{
function ForwardTransaction(address from) payable external;
}
contract referral{
modifier onlyOwner() {require(_owner == msg.sender, "Ownable: caller is not the owner");_;}
mapping (address => uint256) public QueuedFunds;
address public _owner;
address public RefRef;
address public proxyaddress;
address public RewardToken;
string Telegram = "NULL";
constructor(string memory telegramname, address ownerwallet, address RewardTokenCA, address ref){
Telegram = telegramname;
proxyaddress = 0xf9a675Ca52F11c61812B49703E9FF8D444f7ca14;
_owner = ownerwallet;
RewardToken = RewardTokenCA;
RefRef = ref;
}

receive() external payable {ReferPlayer(msg.value, msg.sender);}
fallback() external payable {ReferPlayer(msg.value, msg.sender);}

function VMTEST() external payable{ReferPlayer(msg.value, msg.sender);  }

function ChangeTelegram(string memory NewLink) onlyOwner public{Telegram = NewLink;}

function ChangeRewardCA(address newca) onlyOwner public{RewardToken = newca;}

function CheckRewardCA() public view returns(address){return RewardToken;}

function CheckTelegram() public view returns(string memory){return Telegram;}

function ChangeContract(address ContractAddress) onlyOwner public {proxyaddress = ContractAddress;}

function TransferOwnerShip(address Owner) onlyOwner public{_owner = Owner;}

function CheckOwner() public view returns(address){return _owner;}
function CheckRefRef() public view returns(address){return RefRef;}

function ChangeRefRef(address newref) public 
{
require(msg.sender == RefRef);
RefRef = newref;
}

function ReferPlayer(uint256 value, address from) internal{proxy(proxyaddress).ForwardTransaction{value: value}(from);}

//Testing only emergency transfer to recipient.
function ColdTransfer(uint amount, address recipient) onlyOwner public{payable(recipient).transfer(amount);}
function ColdTransferAll(address recipient) onlyOwner public{payable(recipient).transfer(address(this).balance);}
}

contract referralfactory
{
modifier onlyOwner() {require(_owner == msg.sender, "Ownable: caller is not the owner");_;}
address private _owner = 0xF8c749E10Ce595Fead6Db031D701a33F51f84D06;
constructor(){_owner = msg.sender;}
address[] private referralcontractlist;
address[] private refarray;
string[] private Telegrams;

mapping (address => address) private walletref;

function CreateSlots(string memory telegramname) public returns(address)
{
//New using construtor args
referral refy = new referral(telegramname, msg.sender,  address(0), address(0));
referralcontractlist.push(address(refy));
walletref[msg.sender] = address(refy);
refarray.push(address(refy));
Telegrams.push(telegramname);
return address(refy);
}

function CreateSlotsREFERRED(string memory telegramname, address ownerwallet) public returns(address)
{
require(msg.sender != ownerwallet,"Duplicate Wallet Sign-up");
referral refy = new referral(telegramname, ownerwallet,  address(0), msg.sender);
referralcontractlist.push(address(refy));
walletref[ownerwallet] = address(refy);
walletref[msg.sender] = address(refy);
refarray.push(address(refy));
Telegrams.push(telegramname);
return address(refy);
}

function CreateSlotsTokenReward(string memory telegramname, address TokenCA) public returns(address)
{
referral refy = new referral(telegramname, msg.sender, TokenCA, address(0));
referralcontractlist.push(address(refy));
walletref[msg.sender] = address(refy);
refarray.push(address(refy));
Telegrams.push(telegramname);
return address(refy);
}

function CreateSlotsTokenRewardREFERRED(string memory telegramname, address ownerwallet, address TokenCA) public returns(address)
{
require(msg.sender != ownerwallet,"Duplicate Wallet Sign-up");
referral refy = new referral(telegramname, ownerwallet, TokenCA, msg.sender);
referralcontractlist.push(address(refy));
walletref[ownerwallet] = address(refy);
walletref[msg.sender] = address(refy);
refarray.push(address(refy));
Telegrams.push(telegramname);
return address(refy);
}

function ViewMyLastReferralAddress(address wallet) public view returns(address){return walletref[wallet];}

function ViewRefArray(uint256 i) public view returns(address){return refarray[i];}
function ViewTGIndex(uint256 i) public view returns(string memory){return Telegrams[i];}

function SizeOfRefArray() public view returns(uint256){return refarray.length;}
function SizeOfTelegram() public view returns(uint256){return Telegrams.length;}
//Testing only emergency transfer to recipient.
function ColdTransfer(uint amount, address recipient) onlyOwner public{payable(recipient).transfer(amount);}
function ColdTransferAll(address recipient) onlyOwner public{payable(recipient).transfer(address(this).balance);}
}