pragma solidity 0.4.24;

contract FraCoinAuct {
    struct store 
    {
        bool voted ; 
        uint weight ; 
    }
    
    struct vote 
    {
        address voter; 
        uint8 votedAmount ;
    }
    
    vote[] public votes;
    
    address public _FraCoin ;                // Stores the address of the FraCoin contract 
    address public _CoinOwner ;              // Address of the FraCoin Creator
    address public owner ;                   // Address of owner
                            
    string public Name ;                     // Name of the Auction
    
    uint public CoinsToBeAuctioned;          // Amount of Coins in the Auction that can be voted for
    uint public numElements;                 // Number of Elements in the vote array 
    
    mapping (address => store) public stores ;
    

    
    function FraCoinAuct (string AuctName ,uint Coins , address addr) public
    {   
        owner = msg.sender; 
        _FraCoin = addr ; 
        StartAuction(AuctName,Coins); 
   }
    
    function StartAuction (string AuctName ,uint Coins ) public
    {
        Name = AuctName ; 
        
        CoinsToBeAuctioned = Coins ; 
        numElements = 0 ; 
        mintCoins(CoinsToBeAuctioned);                                // If Fraports Account doesn&#39;t have enough Coins, they shall be minted on the Account 
  
    }
    
    function EndAuction () public
    {
        uint maxProStore; 
        uint remainingCoins;
        require (msg.sender == owner) ; 
         
        
        maxProStore = CoinsToBeAuctioned / numElements; 
        FraCoin FRC = FraCoin(_FraCoin) ;
        
        for (uint i = 0 ; i < numElements; i++)
        {
            if (votes[i].votedAmount > maxProStore) 
            {   // Wenn der Store mehr will als das Max kriegt er ersteinmal das Max.
                FRC.TransferCoinsFrom (owner, votes[i].voter,votes[i].votedAmount);
            } 
            if (votes[i].votedAmount < maxProStore) 
            {   // Wenn der Store weniger will als das Max bekommt er den Anteil den er wollte.
                FRC.TransferCoinsFrom (owner, votes[i].voter,votes[i].votedAmount);
                remainingCoins = remainingCoins + (maxProStore - votes[i].votedAmount); 
            }
        }
       
    }
    
    function authorizeStore (address _store) public
    {
        require (owner == msg.sender) ; 
        require (!stores[_store].voted) ;
        
        stores[_store].weight = 1 ; 
    }
    
    function bid (uint8 amount) public 
    {
        require (stores[msg.sender].weight == 1) ; 
   
        
        votes.push(vote(msg.sender,amount)); 
        
        numElements = numElements + 1 ; 
        stores[msg.sender].voted = true ; 

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
        function TransferCoinsFrom (address _from, address _to, uint8 amount) public; 
    }