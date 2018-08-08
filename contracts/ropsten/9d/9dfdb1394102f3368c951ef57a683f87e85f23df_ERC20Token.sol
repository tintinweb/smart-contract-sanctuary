pragma solidity 0.4.24;

contract ERC20Token 
{
    function mintFraCoins(address _to, uint256 amount)  returns (bool success) {}
    
    function TransferCoinsFrom (address _from, address _to, uint8 amount) returns (bool success) {}
    
    function TransferCoins(address _to, uint8 amount) returns (bool success) {}
    
    function TransferCoinsEther () returns (bool success) {}
    
    function balanceOfSender() returns (uint256 balance) {}
    
    function getExCoins() returns (uint256 exCoins) {}
    
    event Transfer (address _from, address _to, uint256 amount);

}

contract Token is ERC20Token 
{
    mapping (address => uint256) balanceOf;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public initialSupply;

    
    /* Funktion um zu minen bzw. Neue Tokens oder Coins zu erstellen 
    *  Funktion soll nur f&#252;r den Owner des Vertrages gehen. Dieser ist in 
    *  Owner abgespeichert !!
    */
    
    function mintFraCoins(uint256 Menge) public returns (bool success)
    {       
            if (msg.sender == 0x9fdfD5470F1734750F68A0385Bbbc231b562282e )
            {
            balanceOf[msg.sender] = balanceOf[msg.sender] + Menge;
            return true;
            }else {return false;}
    }
    
     /* Funktion um Coins zwischen zwei Accounts zu transferieren  
     *  Funktion soll nur f&#252;r den Owner des Vertrages gehen. Dieser ist in 
     *  Owner abgespeichert !!
     */
    
    function TransferCoinsFrom (address _from, address _to, uint8 amount) public returns (bool success)
    {

            if (balanceOf[_from] >= amount )
            {
                balanceOf[_from] = balanceOf[_from] - amount ; 
                balanceOf[_to] = balanceOf[_to] + amount ;
                Transfer(_from, _to, amount);
                return true;
            }else 
            {
                return false;
            }
    }


    /* Funktion um Coins zwischen zwei Accounts zu transferieren  
     * Funktion soll jeder ausf&#252;hren k&#246;nnen. Der Msg Sender ist der 
     * Sender der Coins
     */
    
    function TransferCoins (address _to, uint8 amount) public returns (bool success) 
    {       
        if (balanceOf[msg.sender] >= amount) 
        {
            balanceOf[msg.sender] = balanceOf[msg.sender] - amount ; 
            balanceOf[_to] = balanceOf[_to] + amount ;
            Transfer(msg.sender, _to, amount);
            return true;
        } else 
        {
            return false;
        } 
    }
    
     /* Funktion um Coins zwischen zwei Accounts zu transferieren  
     *  Coins sollen transferiert werden und Ether soll transferiert werden 
     */
    
    function TransferCoinsEther () public returns (bool success)
    {
        // Ether und Coins transferrieren 
        return true;
    }
    
    // Funktion um die Balance des senders zu kriegen
    
    function balanceOfSender() public  returns (uint256 x)
    {
        return balanceOf[msg.sender] ; 
    }
    
    // Funktion um die existierende Anzahl von Coins wiederzugeben

    function getExCoins() public  returns (uint256 x)
    {
        return initialSupply ; 
    }
    
}

contract FraCoin is Token{
    
    address public owner ;                  //Ersteller der Coins und 
                                            //einziger der die Coins Minen darf
    string public Str_Name ;                //Name of the Coin 
    string public Str_Symbol;               //Symbol of the Coin
    uint8  public int_Decimals = 18;        //Decimals for Coin 
    
    uint256 public int_Price ;             //Current Price of a Coin in Ether
    uint256 public int_ExCoins ;           //Existing Coins
    
    mapping (address => uint256) public balanceOf;
    
    function FraCoin() public  
    {
        Str_Name = "FraCoin" ;
        Str_Symbol = "FC" ; 
        int_ExCoins = 0 ; 
        owner = msg.sender ;
        balanceOf[owner] = 1000; 
        
    }
    
 

}