/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity ^0.4.25;

/*

todo: 

works with sending bnb for tokens
works with dapp buy tokens
withdraw feature working


show current token balance.
add delay to sending 
enable min,max sales amount


version 1.02
v1-0xeac7692ef86a105a91473b0ac74905460f81cd4d
this works.
will automatically accept eth, 
send out specified token in real time to msg.sender
and send the eth to the contract owner

#1 deploy the contract
#2 call function TokenSaleSetup via remix (specifying price, contractaddress of token to be sold)
eg. 100000000000000 uint256 for price = 10,000 tokens per eth
#3 send tokens to the contract address (created in #1)
#4 users can then send eth to the contract

#to do, should have a way to end the contract
# verify what happens if users send more eth than token available for sale

#consider adding BurnableToken, PausableToken 

*/

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}

contract EthToTokenExchangeContract {
    IERC20Token public tokenContract;  // the token being sold => used in TokenSaleSetup
    uint256 public price;              // the price, in wei, per token => used in TokenSaleSetup
    uint256 public min_eth_amt;        // the minimum someone can Purchase => used in TokenSaleSetup
    uint256 public max_eth_amt;        // the maximum someone can Purchase => used in TokenSaleSetup
    uint256 public wallet_max_token_amt;  //maximum a user can buy or hold in single wallet uint256
    
    
    address owner;
    //string mystring;

    uint256 public tokensSold;
    
    
    uint public _totalHolders; // you should initialize this to 0 in the constructor
    mapping (uint=> address ) public b_holders; //incremented for each address , add check if exsts
    mapping (address => uint) public b_shares; //incremented for each transaciont
    
    //uint256 public heldTotal;//v3
    mapping (address => uint256) public purchasedTokens;//v3
    //mapping (address => uint) public heldTimeline;//v3
    
    

    event Sold(address buyer, uint256 amount);
    event Contribution(address buyer, uint256 amount);
    //event ReleaseTokens(address buyer, uint256 amount); //v3
    event VestingNow(address thisHolder, uint256 thisAmount);
    event VestingDone(address thisHolder, uint256 thisAmount);
    event HoldersCount(uint256 _totalHolders);
    event ThisBuyer(address buyer);
    
    event YouVested(address buyer, uint256 amount);
    event ShowMaxVestable(address buyer, uint256 amount);
    
    // try this
    //event Purchase(string mystring, address buyer, uint256 amount);
    
    
    // attempt to set some vars on contract creation
    constructor () public {
        owner = msg.sender;
        _totalHolders=0;
          wallet_max_token_amt = 100000000000000000000000;
          min_eth_amt= 10000000000000;
          max_eth_amt = 10000000000000000000;
          price = 100000000000000;
          //address tokenContract = 0xe5202ef5bef816beb34fec953138b320e1b7b79f;
    }
    
    
    
    function TokenSaleSetup(IERC20Token _tokenContract) public {
       
        owner = msg.sender;
        tokenContract = _tokenContract;
        //price = _price;
        //min_eth_amt=_min_eth_amt;
        //max_eth_amt=_max_eth_amt;
    }
    
    // DEFAULT FUNCTION FOR INBOUND TRANSFERS
    // THIS WORKS NOW... removing gas expensive things fixes it.
    function () payable public {
    require(msg.sender != owner);   
    
    uint receiveTokens=msg.value/price; //how many tokens to credit the sender with (human readable)
   
    
    //buyTokens(receiveTokens); //comment this out to test
    
    emit Sold(msg.sender, receiveTokens);
    emit Contribution(msg.sender, msg.value);
    
    // Send Eth received for this purchase to the owner.
    //owner.transfer(msg.value);
    
    
    // attempt to add THIS WITHOUT OVERGASSING
    tokensSold += receiveTokens;

    uint256 scaledAmount = safeMultiply(receiveTokens,
            uint256(10) ** tokenContract.decimals());
    
    // NEED TO TRY WITH THESE LINES
    //require(scaledAmount >= min_eth_amt); //changed this
    //require(scaledAmount <= max_eth_amt); //changed this
    
    //add some function here to assign tokens
    purchasedTokens[msg.sender] += scaledAmount; //total purchase by one address
    
    b_shares[msg.sender] += scaledAmount; //current token balance, of one address
    b_holders[_totalHolders]=msg.sender; //indexed array of buyers addresses
    _totalHolders++;
    
    emit HoldersCount(_totalHolders);
    emit ThisBuyer(msg.sender);
       
    }
    
    
    
    
    
    // Guards against integer overflows
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }

    function buyTokens(uint256 numberOfTokens) public payable {
        require(msg.value == safeMultiply(numberOfTokens, price));

        uint256 scaledAmount = safeMultiply(numberOfTokens,
            uint256(10) ** tokenContract.decimals());

        require(tokenContract.balanceOf(this) >= scaledAmount);
        
        // verify purchase amount must be 0.1ETH
        //require(msg.value == 100000000000000000);
        require(msg.value >= min_eth_amt);
        require(msg.value <= max_eth_amt);
        //require(scaledAmount >= min_eth_amt); //changed this <<== CAUSING ERROR??
        //require(scaledAmount <= max_eth_amt); //changed this <<== CAUSING ERROR??


        //emit Sold(msg.sender, numberOfTokens);
        tokensSold += numberOfTokens;

        //require(tokenContract.transfer(msg.sender, scaledAmount)); //commented out
        
        //add some function here to assign tokens
        purchasedTokens[msg.sender] += scaledAmount; //use this to know the total (never decrease it)
        
        b_shares[msg.sender] += scaledAmount;  //use this to know the current balance (like a wallet)
        b_holders[_totalHolders]=msg.sender;
        _totalHolders++;
        
        emit HoldersCount(_totalHolders);
        emit ThisBuyer(msg.sender);
        
        
    }

    function endSale() public {
        require(msg.sender == owner);

        // Send unsold tokens back to the owner.
        require(tokenContract.transfer(owner, tokenContract.balanceOf(this)));

        // Send Eth from contract to the owner.
        msg.sender.transfer(address(this).balance);
        
    }
    
    
    /*
    function UpdateShares(uint shares) private {
    b_holders[_totalHolders] = msg.sender;
    b_shares[msg.sender] = shares; 
    _totalHolders++;
    } 
    */
    
    
    // function to iterate through all buyers and send them their tokens
    // if this works, can split the send further, then automate it
    
   
    function PayOut() public { //adding payable didn't work as expected
        require(msg.sender == owner);
        uint thisUserShares;
        address thisUserAddress;
        
        for(uint i = 0 ; i<_totalHolders; i++) {
            
            //b_shares[msg.sender] += scaledAmount; => thisUserShares=b_shares[thisUserAddress]
            //b_holders[_totalHolders]=msg.sender; => thisUserAddress = b_holders[i]
            thisUserAddress = b_holders[i]; // get users address based on index i
            thisUserShares=b_shares[thisUserAddress]; //get users token share based on address
            
            //shares = b_shares[b_holders[i]];
            
            emit VestingNow(thisUserAddress, thisUserShares);
            require(tokenContract.transfer(thisUserAddress, thisUserShares)); //changed this <<== CAUSING ERROR
              
              
              //event VestingNow(address thisHolder, uint256 thisAmount);
              //update the users token share to prevent multiple withdrawals
              thisUserShares=0;
              b_shares[thisUserAddress]=thisUserShares;
              
            emit VestingDone(thisUserAddress, thisUserShares);
        }
    } 
    
    
    /*
    //ok, works nicely
    //now just need to split this into 5
    function withdrawTokens() public  {
        //require(msg.value == safeMultiply(numberOfTokens, price));
        //require(tokenContract.balanceOf(this) >= scaledAmount);
        
        //make sure the user has a balance greater than zero
        require(b_shares[msg.sender] > 0);
        
        //if(block.timestamp > 1626828035)
      
      
        uint256 withdrawAmount =  purchasedTokens[msg.sender];  
        require(tokenContract.transfer(msg.sender, withdrawAmount)); 

        purchasedTokens[msg.sender] = 0;
        b_shares[msg.sender] =0;
                
        emit YouVested(msg.sender,withdrawAmount);
            }
      */
      
       function withdrawTokens() public  {
        //require(msg.value == safeMultiply(numberOfTokens, price));
        //require(tokenContract.balanceOf(this) >= scaledAmount);
        
        //make sure the user has a balance greater than zero
        require(b_shares[msg.sender] > 0);
        
        //if(block.timestamp > 1626828035)
        //withdrawVested(uint256 t_amount);
      
      
        //uint256 withdrawAmount =  purchasedTokens[msg.sender];  
        uint256 withdrawAmount =  returnVestable(); //only allow vested tokens to be withdrawn
        
        require(tokenContract.transfer(msg.sender, withdrawAmount)); 

        //purchasedTokens[msg.sender] = 0;
        //b_shares[msg.sender] =0;
        b_shares[msg.sender] -= withdrawAmount;
                
        emit YouVested(msg.sender,withdrawAmount);
            }
            
   
   
         // use this to confirm currently vestable amount for a user
         // function f() internal pure returns (uint ret) { return g(7) + f(); }
      function returnVestable() public returns (uint256 u_actualVestable) {
      	
      	uint256 u_maxvestable;
      	uint256 u_unvestable;
      	//uint256 u_actualVestable;
      	
      	u_maxvestable=0;
      	//time block must be in reverse order 
      	if (block.timestamp > 1626860582  )  { u_maxvestable = (purchasedTokens[msg.sender] / 5) *5 ;} //eg 300
        else if (block.timestamp > 1626850582 )   { u_maxvestable = (purchasedTokens[msg.sender] / 5) *4 ;} //eg 300
        else if (block.timestamp > 1626840582 )   {u_maxvestable = (purchasedTokens[msg.sender] / 5) *3 ;} //eg 300
        else if (block.timestamp > 1626830582 )   { u_maxvestable = (purchasedTokens[msg.sender] / 5) *2 ; } //eg 200
        else if (block.timestamp > 1626828035)  {u_maxvestable = (purchasedTokens[msg.sender] / 5) *1;} //eg 100
        else {u_maxvestable =0;} //eg 0
        
        
        
    
        //u_maxvestable = (purchasedTokens[msg.sender] / 5) *1; //eg 100
    	
    	u_unvestable = purchasedTokens[msg.sender]  - u_maxvestable;							
    	u_actualVestable = b_shares[msg.sender] - u_unvestable;
      	

      	 emit ShowMaxVestable(msg.sender,u_actualVestable);
      	 return u_actualVestable;
      }
   
   
    /*
      // use this to withdraw a set amount (make this internal callable only)
      function withdrawVested(uint256 t_amount) public payable {
        require(b_shares[msg.sender] >= t_amount); //ensure balance is > amount being withdrawn
        b_shares[msg.sender] -=t_amount; //reduce withdrawn amount from balance
        emit YouVested(msg.sender,t_amount); //emit withdrawn event
      }
     */ 
            
            
       function buy(uint amount) public payable {
        if (amount > msg.value / 2 ether)
            revert("Not enough Ether provided.");
        // Alternative way to do it:
        require(
            amount <= msg.value / 2 ether,
            "Not enough Ether provided."
        );
        // Perform the purchase.
    }     
            
            
            
    
}