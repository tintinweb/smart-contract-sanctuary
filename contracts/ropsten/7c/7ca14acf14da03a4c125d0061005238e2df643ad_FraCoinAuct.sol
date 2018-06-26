pragma solidity 0.4.24;

contract FraCoinAuct {
    struct store 
    {
        bool voted ; 
        uint votedAmount ; 
        uint weight ; 
    }
    
    address public _FraCoin ;                // Stores the address of the FraCoin contract 
    address public _CoinOwner ;              // Address of the FraCoin Creator
    address public owner ;                   // Address of owner
                            
    string public Name ;                     // Name of the Auction
    
    
    
    uint public AuctionEnd ;                 // End of the Auction
    uint public CoinsToBeAuctioned;          // Amount of Coins in the Auction that can be voted for
    mapping (address => store) public stores ;
    

    
    function FraCoinAuct (string AuctName ,uint Coins ,uint durationMin, address addr) public
    {   
        Name = AuctName ; 
        AuctionEnd = now + (durationMin * 1 minutes) ; 
        owner = msg.sender; 
        _FraCoin = addr ; 
        CoinsToBeAuctioned = Coins ; 
        
        mintCoins(CoinsToBeAuctioned);                                // If Fraports Account doesn&#39;t have enough Coins, they shall be minted on the Account 
    }
    
    function EndAuction () public
    {
        require (msg.sender == owner) ; 
        require (now >= AuctionEnd); 
       
    }
    
    function authorizeStore (address _store) public
    {
        require (owner == msg.sender) ; 
        require (!stores[_store].voted) ;
        
        stores[_store].weight = 1 ; 
    }
    
    function bid (uint amount) public 
    {
        require (stores[msg.sender].weight == 1) ; 
        require (now < AuctionEnd) ; 
        
        stores[msg.sender].voted = true ; 
        stores[msg.sender].votedAmount = amount ; 

    }
    
    function mintCoins (uint amount) public
    {
        FraCoin FRC = FraCoin(_FraCoin) ;               // Calls Fra Coin Contract and makes sure there 
        FRC.mintIfNecessary(amount) ;       // are enough Coins on the Account of Fraport
    }
    
}


    contract FraCoin 
    {
        function mintIfNecessary (uint amount) public; 
    }