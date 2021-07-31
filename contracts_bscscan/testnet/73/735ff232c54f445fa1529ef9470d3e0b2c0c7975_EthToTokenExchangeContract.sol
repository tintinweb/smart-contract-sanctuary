/**
 *Submitted for verification at BscScan.com on 2021-07-31
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


#1 deploy the contract
#2 call function TokenSaleSetup via remix (contractaddress of token to be sold)
eg. 100000000000000 uint256 for price = 10,000 tokens per eth
#3 owner should send tokens-to-be-sold to the contract address (created in #1)
#4 users can then send eth to the contract



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
    
    uint256 public totalDepositedEthBalance;
    
    uint public vest_ts_1;
    uint public vest_ts_2;
    uint public vest_ts_3;
    uint public vest_ts_4;
    uint public vest_ts_5;
    
    uint public preSaleStatus; //0=inactive, 1=active
    
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
    

    //Works
    // attempt to set some vars on contract creation
    constructor () public {
        owner = msg.sender;
        _totalHolders=0;
          wallet_max_token_amt = 100000000000000000000000;
          min_eth_amt= 10000000000000;
          max_eth_amt = 10000000000000000000;
          //price = 100000000000000; //100000000000000000 * (1/12500)
          price = 100000000000000000 * (1/12500);
          //address tokenContract = 0xe5202ef5bef816beb34fec953138b320e1b7b79f;
          
          vest_ts_1=1626820582;
          vest_ts_2=1626830582;
          vest_ts_3=1626840582;
          vest_ts_4=1626850582;
          vest_ts_5=1626860582;
          preSaleStatus=0;
          
          
    }
    
        function getDepositAmount() public view returns (uint256) {
        return totalDepositedEthBalance;
    }
    
    //Works
    function TokenSaleSetup(IERC20Token _tokenContract) public {
       require(msg.sender == owner, "You do not have the required permission.");  
        //owner = msg.sender;
        tokenContract = _tokenContract;
        //price = _price;
        //min_eth_amt=_min_eth_amt;
        //max_eth_amt=_max_eth_amt;
    }
    
    //Works
    function UpdateVestTime(uint _vest_ts_1,uint _vest_ts_2,uint _vest_ts_3,uint _vest_ts_4,uint _vest_ts_5) public {
       require(msg.sender == owner, "You do not have the required permission.");  
       vest_ts_1=_vest_ts_1;
       vest_ts_2=_vest_ts_2;
       vest_ts_3=_vest_ts_3;
       vest_ts_4=_vest_ts_4;
       vest_ts_5=_vest_ts_5;
    }
    
    function UpdatePrice(uint _price) public {
       require(msg.sender == owner, "You do not have the required permission.");  
       price=_price;
    }
    
    function UpdatePreSaleStatus(uint _preSaleStatus) public {
       require(msg.sender == owner, "You do not have the required permission.");  
       preSaleStatus=_preSaleStatus;
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
    
    //Works - TES MIN / MAX
    // DEFAULT FUNCTION FOR INBOUND TRANSFERS (send eth to contract to purchase automatically)
    // NOTE- MINIMUM GAS SHOULD BE 300000
    function () payable public {
    require(msg.sender != owner);  
    require(preSaleStatus == 1); //The presale must be active
    
    
    uint receiveTokens=msg.value/price; //how many tokens to credit the sender with (human readable)
    
    tokensSold += receiveTokens; //keep track of all sold tokens

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
    
    totalDepositedEthBalance += msg.value;
    
    emit Sold(msg.sender, receiveTokens);
    emit Contribution(msg.sender, msg.value);
    
    emit HoldersCount(_totalHolders);
    emit ThisBuyer(msg.sender);
       
    }
    
    
    
    
    
    //Works
    // DAPP PURCHASE FUNCTION
    function buyTokens(uint256 numberOfTokens) public payable {
         require(preSaleStatus == 1); //The presale must be active
        require(msg.value == safeMultiply(numberOfTokens, price), "Either the Price or NumberOfTokens is incorrect.");

        uint256 scaledAmount = safeMultiply(numberOfTokens,
            uint256(10) ** tokenContract.decimals());

        require(tokenContract.balanceOf(this) >= scaledAmount, "Not enough tokens available to sell.");
        
        // verify purchase amount must be 0.1ETH
        //require(msg.value == 100000000000000000);
        require(msg.value >= min_eth_amt,"The purchase amount is too low.");
        require(msg.value <= max_eth_amt, "The purchase amount is too high.");
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
        
        totalDepositedEthBalance += msg.value;
        
        emit HoldersCount(_totalHolders);
        emit ThisBuyer(msg.sender);
        
        
    }

    /* TODO: 
    split transfer eth to owner
    return unsold tokens (or burn)
    add saleisactive flag
    
    */
    
    //works
    function endSale() public {
        require(msg.sender == owner, "You do not have the required permission.");
        
        //preSaleStatus=0;

        // Send Eth from contract to the owner.
        msg.sender.transfer(address(this).balance);
    }
    
    
    function endSaleVesting() public {
        require(msg.sender == owner, "You do not have the required permission.");
        
        // Send unsold tokens back to the origin. (or burn address)
        require(tokenContract.transfer(owner, tokenContract.balanceOf(this)));
    }
    
    
    
         //works  
       function withdrawTokens() public  {
        
        //make sure the user has a balance greater than zero
        require(b_shares[msg.sender] > 0, "User balance is insufficient.");
        require(block.timestamp > vest_ts_1, "Vesting is not available yet.");
        
      
        //uint256 withdrawAmount =  purchasedTokens[msg.sender]; //full amount 
        uint256 withdrawAmount =  returnVestable(); //only allow vested tokens to be withdrawn
        
        require(tokenContract.transfer(msg.sender, withdrawAmount),"Could not successfully transfer the tokens."); 

        //purchasedTokens[msg.sender] = 0;
        //b_shares[msg.sender] =0;
        b_shares[msg.sender] -= withdrawAmount;
                
        emit YouVested(msg.sender,withdrawAmount);
            }
            
   
   
    /*
    TO do ~ Maybe
    change the vesting amount to percentage fraction
    eg. u_maxvestable = (purchasedTokens[msg.sender] * vest_fraction_1) //vest_fraction_1=0.2
    
    use writable/updatable params for vesting times and fractions
    
    */
   
     //works
         // use this to confirm currently vestable amount for a user
         // function f() internal pure returns (uint ret) { return g(7) + f(); }
      function returnVestable() public returns (uint256 u_actualVestable) {
      	
      	uint256 u_maxvestable;
      	uint256 u_unvestable;
      	//uint256 u_actualVestable;
      	
      	u_maxvestable=0;
      	//time block must be in reverse order 
      	if (block.timestamp > vest_ts_5  )  { u_maxvestable = (purchasedTokens[msg.sender] / 5) *5 ;} //eg 300
        else if (block.timestamp > vest_ts_4 )   { u_maxvestable = (purchasedTokens[msg.sender] / 5) *4 ;} //eg 300
        else if (block.timestamp > vest_ts_3 )   {u_maxvestable = (purchasedTokens[msg.sender] / 5) *3 ;} //eg 300
        else if (block.timestamp > vest_ts_2 )   { u_maxvestable = (purchasedTokens[msg.sender] / 5) *2 ; } //eg 200
        else if (block.timestamp > vest_ts_1)  {u_maxvestable = (purchasedTokens[msg.sender] / 5) *1;} //eg 100
        else {u_maxvestable =0;} //eg 0
        
    	
    	u_unvestable = purchasedTokens[msg.sender]  - u_maxvestable;							
    	u_actualVestable = b_shares[msg.sender] - u_unvestable;
      	

      	 emit ShowMaxVestable(msg.sender,u_actualVestable);
      	 return u_actualVestable;
      }
   
 
            
            
       function buydummyfunction(uint amount) public payable {
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