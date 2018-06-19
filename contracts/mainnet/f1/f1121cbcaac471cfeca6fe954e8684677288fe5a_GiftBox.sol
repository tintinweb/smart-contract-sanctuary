pragma solidity ^0.4.22;

contract GiftBox {
	address public owner;
	uint256 public gift;
	uint16[7] public gifts;
	mapping(address=>address) public friends;
	event GiftSent(address indexed gifter);
	modifier onlyOwner() {
      if (msg.sender!=owner) revert();
      _;
    }
    
    constructor() public{
        owner = msg.sender;
        gifts = [49,7,7,7,7,7,7];
        gift = 100000000000000000;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function changeGift(uint256 newGift) public onlyOwner {
        if (newGift>0) gift = newGift;
        else revert();
    }
    
    function changeFriend(address payer, address newFriend) public onlyOwner {
        if (payer!=address(0) && newFriend!=address(0)) friends[payer] = newFriend;
        else revert();
    }
    
    function transferGift(address from, address to) payable public onlyOwner {
        if (from==address(0) || to==address(0) || from==to) revert();
        friends[from] = to;
        payOut(to);
        emit GiftSent(from);
    }
    
    function sendGift(address friend) payable public {
        if (msg.value<gift || friend==address(0) || friend==msg.sender || (friend!=owner && friends[friend]==address(0))) revert();
        friends[msg.sender] = friend;
        payOut(friend);
        emit GiftSent(msg.sender);
    }
    
    function payOut(address payee) private{
        uint256 pay;
        uint256 paid = 0;
        for (uint i=0;i<7;i++) {
            pay = gift*gifts[i]/100;
            if (pay>0 && payee!=address(0)) {
                payee.transfer(pay);
                paid+=pay;
            }
            payee = friends[payee];
            if (payee==address(0)) break;
        }
        if (gift-paid>0) owner.transfer(gift-paid);
    }
    
    function () payable public {
        if (msg.value<gift) revert();
        friends[msg.sender] = owner;
    }
}