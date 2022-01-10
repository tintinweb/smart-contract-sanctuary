/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract simpleAuction{
//chuc nang gi. lam ntn
//dat gia tien o dau, thoi gian nao,
//dat tien nam trong thoi gian phien giao dich con hoat dong
//- thoi gian phien dau gia
//- gia tri dat no phai lon hon gia tri lon nhat taij thoi diem do

//- rut tien
//sau khi rut thi luong rut = so tien da dat 
//sau khi rut vi bang 0

//khi action ket thuc
// khi nao ket thuc
// su kien transfer san pham cho nguoi dat construction

// variables
address payable public beneficiary;
uint public auctionEndTime;
uint public highestBid;
address public highestBidder;
mapping(address => uint) public pendingReturns;
bool ended = false;

event highestBidincrease (address bidder, uint amount);
event auctionEnded(address winner, uint amount);


constructor (uint _bidddingTime,address payable _beneficiary){
beneficiary  = _beneficiary;
auctionEndTime = block.timestamp + _bidddingTime;

}
//function
function bid() public payable{
// neu thoi gian con hoat dong
if (block.timestamp > auctionEndTime){
    revert("Phien dau gia da ket thuc");
}
if (msg.value <= highestBid){
    revert("Gia cua ban thap hon gia cao nhat");
}
if (highestBid != 0){
    pendingReturns[highestBidder] += highestBid;
}
highestBidder = msg.sender;
highestBid = msg.value;
emit highestBidincrease(msg.sender, msg.value);


}
function withdraw() public returns(bool){
uint amount = pendingReturns[msg.sender];
if (amount >0)
{
    pendingReturns[msg.sender] = 0;
    if (!payable(msg.sender).send(amount))
    {
        pendingReturns[msg.sender] = amount;
        return false;

    }
    

}
return true;

}

function auctionEnd() public {
if (ended){
    revert("Phien dau gia da co the ket thuc ");

}
if (block.timestamp < auctionEndTime){
    revert("Phien dau gia chua ket thuc");
}
ended = true;
emit auctionEnded(highestBidder, highestBid);
// beneficiary : tu dong transfer
beneficiary.transfer(highestBid); 

}


}