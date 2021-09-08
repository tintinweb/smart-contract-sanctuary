/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

pragma solidity ^0.8.7;

contract Escrow {

    address payable public buyer;
    address payable public seller;
    address public contractOwner;
        
    struct item {
        string b_name;
        uint no_units;
        uint total;
        uint price_per_unit;
        string date;
    }

    item product;
    mapping(address=>uint) public deposits;
    uint public escrowfee=400;// fee in basis points
    uint balance;//escrow balance amount
    uint start;//starting time
    uint end;//ending time
    
    event notify(string notification);//notification to the sender
    
    enum state{AWAITING_BUYER_PAYMENT,AWAITING_DELIVERY,AWAITING_FUND_RELEASE,COMPLETE}//state of the smart contract
    
    //AWAITING_BUYER_PAYMENT - initial state
    //AWAITING_DELIVERY- amount received but awaiting 
    //AWAITING_FUND_RELEASE-  waiting for delivery confirmation
    //COMPLETE - process is completed
    state public current;

    bool public buyerOK;
    bool public sellerOK;
    
    //contract owner is the deployer
    constructor (address payable _seller, address payable _buyer) {
        buyer = _buyer;
        seller = _seller;
        contractOwner = msg.sender;
        current=state.AWAITING_BUYER_PAYMENT;
    }    
    
    // update the product details
    function b_Product_details(string memory _b_name,uint units,string memory _date,uint p_p_u) public
    {
        product.b_name=_b_name;
        product.no_units=units;
        product.date=_date;
        product.price_per_unit=p_p_u;
        product.total=product.price_per_unit*product.no_units;//total amount to be paid                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    }
    
    //fallback function
    fallback() external payable {
        require(msg.sender==buyer,"Can only be accessed by the buyer");
            require(current==state.AWAITING_BUYER_PAYMENT,"Payment has already been made...");
                require(msg.value>product.total,"Entered amount is less that required amount...");
                    balance=msg.value;
                    start=block.timestamp;
                    current=state.AWAITING_DELIVERY;
                    emit notify("Buyer has deposited the required amount in the Escrow account");  
    }
    
    //returns the balance of the contract
    function escrow_balance()public view returns (uint) {
        return address(this).balance;
    }

    // incase seller deny service, refund the buyer and mark the process complete
    function seller_deny_service() public {
        require(msg.sender==seller,"You cannot hack my contract...");
        require(current==state.AWAITING_DELIVERY,"It is not the right time for this action");
        buyer.transfer(address(this).balance);
        current=state.COMPLETE;
    }
    
    function seller_send_product() public payable {
        require(msg.sender==seller,"Can be accessed only by seller");
        require(current==state.AWAITING_DELIVERY);
        sellerOK=true;
    }

    // confirms the satisfactory receipt of product
    function b_delivery_received() public payable {
        require(msg.sender==buyer," only Buyer can call this function");
        require(current==state.AWAITING_DELIVERY);
        buyerOK=true;
        current=state.AWAITING_FUND_RELEASE;
        if(sellerOK==true)
        release_fund();
    }
    
    function release_fund() private {
        uint amount =address(this).balance;
        if(buyerOK&&sellerOK) {
            seller.transfer(amount);
            deposits[seller] = deposits[seller] - amount;
        }
        current=state.COMPLETE;
    }

    function withdraw_amount() public {
        uint amount =address(this).balance;
        end=block.timestamp;
        require(current==state.AWAITING_DELIVERY);
        require(msg.sender==buyer);
        if(buyerOK==false&&sellerOK==true) {
            seller.transfer(amount);
        } 
        //time exceeds 30 days after the buyer has deposited in the escrow contract
        else if(buyerOK&&!sellerOK&&end>start+172800) {
            require(address(this).balance!=0,"Already money transferred");
            buyer.transfer(address(this).balance);
            deposits[seller] = deposits[seller] - amount; 
        }
        current=state.COMPLETE;
    }
   
    //- can be called via constructor or directly from frontend*/ 
    function deposit() public  payable {
        uint256 amount = msg.value;
        require(msg.sender==buyer,"Can only be accessed by the buyer");
        require(current==state.AWAITING_BUYER_PAYMENT,"Payment has already been made...");
        require(msg.value>product.total,"Entered amount is less that required amount...");
        balance=msg.value;
        start=block.timestamp;
        current=state.AWAITING_DELIVERY;
        emit notify("Buyer has deposited the required amount in the Escrow account");  
    
        uint256 fee = (amount *escrowfee )/ 1000;
        payable(contractOwner).transfer(fee); // transfer fee to the contract owner
        amount -= fee; // substract the fee from the amount that is going to be saved

        deposits[seller] = deposits[seller] + amount; 
        //current = state.AWAITING_CLAIM;
    }
  
}