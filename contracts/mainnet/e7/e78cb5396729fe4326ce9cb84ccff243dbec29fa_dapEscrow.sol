pragma solidity ^0.4.11;

contract dapEscrow{
    
    struct Bid{
        bytes32 name;
        address oracle;
        address seller;
        address buyer;
        uint price;
        uint timeout;
        dealStatus status;
        uint fee;
        bool isLimited;
    }
    
    enum dealStatus{ unPaid, Pending, Closed, Rejected, Refund }
    
    mapping (address => Bid[]) public bids;
    mapping (address => uint) public pendingWithdrawals;
    
    event amountRecieved(
        address seller,
        uint bidId
    );
    
    event bidClosed(
        address seller,
        uint bidId
        );
        
    event bidCreated(
        address seller,
        bytes32 name,
        uint bidId
        );
        
    event refundDone(
        address seller,
        uint bidId
        );
        
    event withdrawDone(
        address person,
        uint amount
        );
    
    event bidRejected(
        address seller,
        uint bidId
        );
        
    function getBidIndex(address seller, bytes32 name) public constant returns (uint){
        for (uint8 i=0;i<bids[seller].length;i++){
            if (bids[seller][i].name == name){
                return i;
            }
        }
    }
    
    function getBidsNum (address seller) public constant returns (uint bidsNum) {
        return bids[seller].length;
    }
    
    function sendAmount (address seller, uint bidId) external payable{
        Bid storage a = bids[seller][bidId];
        require(msg.value == a.price && a.status == dealStatus.unPaid);
        if (a.isLimited == true){
            require(a.timeout > block.number);
        }
        a.status = dealStatus.Pending;
        amountRecieved(seller, bidId);
    }
    
    function createBid (bytes32 name, address seller, address oracle, address buyer, uint price, uint timeout, uint fee) external{
        require(name.length != 0 && price !=0);
        bool limited = true;
        if (timeout == 0){
            limited = false;
        }
        bids[seller].push(Bid({
            name: name, 
            oracle: oracle, 
            seller: seller, 
            buyer: buyer,
            price: price,
            timeout: block.number+timeout,
            status: dealStatus.unPaid,
            fee: fee,
            isLimited: limited
        }));
        uint bidId = bids[seller].length-1;
        bidCreated(seller, name, bidId);
    }
    
    function closeBid(address seller, uint bidId) external returns (bool){
        Bid storage bid = bids[seller][bidId];
        if (bid.isLimited == true){
            require(bid.timeout > block.number);
        }
        require(msg.sender == bid.oracle && bid.status == dealStatus.Pending);
        bid.status = dealStatus.Closed;
        pendingWithdrawals[bid.seller]+=bid.price-bid.fee;
        pendingWithdrawals[bid.oracle]+=bid.fee;
        withdraw(bid.seller);
        withdraw(bid.oracle);
        bidClosed(seller, bidId);
        return true;
    }
    
    function refund(address seller, uint bidId) external returns (bool){
        require(bids[seller][bidId].buyer == msg.sender && bids[seller][bidId].isLimited == true && bids[seller][bidId].timeout < block.number && bids[seller][bidId].status == dealStatus.Pending);
        Bid storage a = bids[seller][bidId];
        a.status = dealStatus.Refund;
        pendingWithdrawals[a.buyer] = a.price;
        withdraw(a.buyer);
        refundDone(seller,bidId);
        return true;
    }
    function rejectBid(address seller, uint bidId) external returns (bool){
        if (bids[seller][bidId].isLimited == true){
            require(bids[seller][bidId].timeout > block.number);
        }
        require(msg.sender == bids[seller][bidId].oracle && bids[seller][bidId].status == dealStatus.Pending);
        Bid storage bid = bids[seller][bidId];
        bid.status = dealStatus.Rejected;
        pendingWithdrawals[bid.oracle] = bid.fee;
        pendingWithdrawals[bid.buyer] = bid.price-bid.fee;
        withdraw(bid.buyer);
        withdraw(bid.oracle);
        bidRejected(seller, bidId);
        return true;
    }
    
    function withdraw(address person) private{
        uint amount = pendingWithdrawals[person];
        pendingWithdrawals[person] = 0;
        person.transfer(amount);
        withdrawDone(person, amount);
    }
    
}