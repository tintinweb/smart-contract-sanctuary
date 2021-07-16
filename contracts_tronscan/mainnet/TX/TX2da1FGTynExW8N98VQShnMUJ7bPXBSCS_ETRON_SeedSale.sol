//SourceUnit: seedsale.sol

pragma solidity >=0.4.0 <0.7.0;
interface ETR20 {
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function transfer(address recipient, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract ETRON_SeedSale {
ETR20 public ETRON;
address public SELLER;
constructor() public {
ETRON = ETR20(0x41723b9a69d73e2b9d0a61ba2341610294f0addc53);
SELLER = address(0x418ecee341e2f71ac279bf18342587a82ed896159c);
}
function safeTransferFrom(
ETR20 token, address sender, address recipient, uint256 amount
) private {
bool sent = token.transferFrom(sender, recipient, amount);
require(sent, "ETRON transfer failed");
}
uint256 private TRX_PER_ETR = 10;
uint256 private SellerTakeTRX = 0;
uint256 private SellerGiveETR = 0;
mapping (address => uint256) private BuyerGiveTRX;
mapping (address => uint256) private BuyerTakeETR;
function rContract() public view returns(address) {
return address(this);
}
function rContractTRX() public view returns(uint256) {
return address(this).balance;
}
function rContractETR() public view returns(uint256) {
return ETRON.balanceOf(address(this));
}
function rSellerPrice() public view returns(uint256) {
return TRX_PER_ETR;
}
function wSellerPrice(uint256 TRX) public returns(uint256) {
if (msg.sender == SELLER) {
TRX_PER_ETR = TRX;
return TRX;
}
}
function rSellerTakeTRX() public view returns(uint256) {
return SellerTakeTRX;
}
function rSellerGiveETR() public view returns(uint256) {
return SellerGiveETR;
}
function rBuyerGiveTRX() public view returns(uint256) {
return BuyerGiveTRX[msg.sender];
}
function rBuyerTakeETR() public view returns(uint256) {
return BuyerTakeETR[msg.sender];
}
function () external payable {}
function wSeedSaleETR() public payable returns(uint256) {
uint256 GiveTRX = msg.value;
uint256 TakeETR = uint256(msg.value / TRX_PER_ETR);
if (GiveTRX > 0 && TakeETR >= 1000000) {
SellerTakeTRX += GiveTRX;
SellerGiveETR += TakeETR;
BuyerGiveTRX[msg.sender] += GiveTRX;
BuyerTakeETR[msg.sender] += TakeETR;
ETRON.transfer(msg.sender, TakeETR);
return TakeETR;
} else {
return 0;
}
}
function wSellerReceiveTRX(uint256 TRX) public returns(uint256) {
if (msg.sender == SELLER) {
uint256 ContractTRX = address(this).balance;
uint256 AmountTRX = 0;
if (TRX > 0 && TRX <= ContractTRX) {
AmountTRX = TRX;
} else {
AmountTRX = ContractTRX;
}
if (AmountTRX > 0) {
msg.sender.transfer(AmountTRX);
}
return AmountTRX;
}
}
function wSellerReceiveETR(uint256 ETR) public returns(uint256) {
if (msg.sender == SELLER) {
uint256 ContractETR = ETRON.balanceOf(address(this));
uint256 AmountETR = 0;
if (ETR > 0 && ETR <= ContractETR) {
AmountETR = ETR;
} else {
AmountETR = ContractETR;
}
if (AmountETR > 0) {
ETRON.transfer(msg.sender, AmountETR);
}
return AmountETR;
}
}
function wAssignSeller(address NEW) public returns(address) {
if (msg.sender == SELLER) {
SELLER = NEW;
return NEW;
}
}
}