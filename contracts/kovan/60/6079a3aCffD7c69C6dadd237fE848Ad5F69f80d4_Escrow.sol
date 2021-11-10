/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

pragma solidity ^0.5.6;
contract Escrow
{
    address payable player1;
    address payable player2;
    
    struct item
    {
        string b_name;
        uint no_units;
        uint total;
        uint price_per_unit;
        string date;
    }
    item product;
    
    uint balance;//escrow balance amount
    uint start;//starting time
    uint end;//ending time
    
    event notify(string notification);//notification to the sender
    
    enum state{AWAITING_player1_PAYMENT,AWAITING_DELIVERY,AWAITING_FUND_RELEASE,COMPLETE}//state of the smart contract
    state current;

    bool public player1OK;
    bool public player2OK;
    
    constructor (address payable _player2) public//player1 is the deployer 
    {
        player1=msg.sender;
        player2=_player2;
        current=state.AWAITING_player1_PAYMENT;
    }    
    
    function b_Product_details(string memory _b_name,uint units,string memory _date,uint p_p_u) public
    {
        product.b_name=_b_name;
        product.no_units=units;
        product.date=_date;
        product.price_per_unit=p_p_u;
        product.total=product.price_per_unit*product.no_units;//total amount to be paid                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    }
    
    function ()payable external//fallback function
    {
        require(msg.sender==player1,"Can only be accessed by the player1");
            require(current==state.AWAITING_player1_PAYMENT,"Payment has already been made...");
                require(msg.value>product.total,"Entered amount is less that required amount...");
                    balance=msg.value;
                    start=block.timestamp;
                    current=state.AWAITING_DELIVERY;
                    emit notify("player1 has deposited the required amount in the Escrow account");  
    }
    
     function escrow_balance()public view returns (uint)//returns the balance of the contract
    {
        return address(this).balance;
    }
    
    function player2_deny_service() public
    {
        require(msg.sender==player2,"You cannot hack my contract...");
        require(current==state.AWAITING_DELIVERY);
            player1.transfer(address(this).balance);
            current=state.COMPLETE;
    }
    
    function player2_send_product() public payable
    {
        require(msg.sender==player2,"Can be accessed only by sender");
            require(current==state.AWAITING_DELIVERY);
                    player2OK=true;
    }
    
     function b_delivery_received() public payable
    {
        require(msg.sender==player1);
        require(current==state.AWAITING_DELIVERY);
            player1OK=true;
        current=state.AWAITING_FUND_RELEASE;
        if(player2OK==true)
            release_fund();
    }
    
    function release_fund()private
    {
            if(player1OK&&player2OK)
                player2.transfer((address(this).balance));
            current=state.COMPLETE;
    }
    function withdraw_amount() public 
    {
        end=block.timestamp;
        require(current==state.AWAITING_DELIVERY);
        require(msg.sender==player1);
        if(player1OK==false&&player2OK==true)
            player2.transfer(address(this).balance);
        else if(player1OK&&!player2OK&&end>start+172800)//time exceeds 30 days after the player1 has deposited in the escrow contract
        {
            require(address(this).balance!=0,"Already money transferred");
            player1.transfer(address(this).balance);
        }
        current=state.COMPLETE;
    }
}