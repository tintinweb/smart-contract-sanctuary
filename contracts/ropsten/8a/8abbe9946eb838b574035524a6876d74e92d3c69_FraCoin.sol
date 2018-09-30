pragma solidity 0.4.24;

contract FraCoin {
    
    address public owner ;                  //Ersteller der Coins und 
                                            //einziger der die Coins Minen darf
    address public FraCoinAuction ;         // Adresse der FraCoin Auktion
    string public Str_Name ;                //Name of the Coin 
    string public Str_Symbol;               //Symbol of the Coin
    uint8 public int_Decimals = 18;         //Decimals for Coin 
    
    uint256 private int_Price ;             //Current Price of a Coin in Ether
    uint256 private int_ExCoins ;           //Existing Coins
    
    mapping (address => uint256) public balanceOf;
    
    function FraCoin() public  
    {
        Str_Name = "FraCoin" ;
        Str_Symbol = "FRC" ; 
        int_ExCoins = 0 ; 
        owner = msg.sender ;
        
    }
    
    /* Funktion um zu minen bzw. Neue Tokens oder Coins zu erstellen 
    *  Funktion soll nur f&#252;r den Owner des Vertrages gehen. Dieser ist in 
    *  Owner abgespeichert !!
    */
    
    function mintFraCoins(uint256 Menge) public
    {
        //if (owner == msg.sender) 
        //{
            balanceOf[owner] = balanceOf[owner] + Menge;
            int_ExCoins = int_ExCoins + Menge; 
            
        //}    
    }
    
    //Funktion um die Adresse der Funktion anzupassen 
    
    function setFracoinAuction () public 
    {
        FraCoinAuction = msg.sender ; 
    }
    
     /* Funktion um Coins zwischen zwei Accounts zu transferieren  
     *  Funktion soll nur f&#252;r den Owner des Vertrages gehen. Dieser ist in 
     *  Owner abgespeichert !!
     */
    
    function TransferCoinsFrom (address _from, address _to, uint amount) public
    {
       if ((owner == msg.sender) || (FraCoinAuction == msg.sender))
        {
            if (balanceOf[_from] >= amount )
            {
                balanceOf[_from] = balanceOf[_from] - amount ; 
                balanceOf[_to] = balanceOf[_to] + amount ;
            }
        }
    }


    /* Funktion um Coins zwischen zwei Accounts zu transferieren  
     * Funktion soll jeder ausf&#252;hren k&#246;nnen. Der Msg Sender ist der 
     * Sender der Coins
     */
    
    function TransferCoins (address _to, uint8 amount) public 
    {
        if (balanceOf[msg.sender] >= amount)
        {
            balanceOf[msg.sender] = balanceOf[msg.sender] - amount ; 
            balanceOf[_to] = balanceOf[_to] + amount ;
        }
    }
    

    function mintIfNecessary (uint amount) public
    {
        if (balanceOf[owner] < amount )
        {
            mintFraCoins (amount - balanceOf[owner]) ;
        }
    }
    
}