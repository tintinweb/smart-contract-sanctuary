pragma solidity ^0.4.24;

contract FamilienSpardose {
    
    // Created by N. Fuchs
    
    // Name der Familienspardose
    string public spardosenName;
    
    //weist einer Addresse ein Guthaben zu
    mapping (address => uint) public guthaben;
    
    // zeigt im smart contract an, wieviel Ether alle Sparer insgesamt halten
    // ".balance" ist eine Objektattribut des Datentyps address, das f&#252;r jede wallet und jeden smart contract das entsprechende 
    //  Ether-Guthaben darstellt.
    uint public gesamtGuthaben = address(this).balance;
    
    // Konstruktorfunktion: Wird einmalig beim deployment des smart contracts ausgef&#252;hrt
    // Wenn Transaktionen, die Funktionen auszuf&#252;hren beabsichtigen, Ether mitgesendet wird (TXvalue > 0), so muss die
    //  ausgef&#252;hrte Transaktion mit "payable" gekennzeichnet sein. Sicherheitsfeature im Interesse der Nutzer
    constructor(string _name, address _sparer) payable {
        
        
        // Weist der Variablen spardosenName den String _name zu, welcher vom Ersteller
        // des smart contracts als Parameter in der Transaktion &#252;bergeben wird:
        spardosenName = _name;
        
        
        // Erstellt einen unsignierten integer, der mit der Menge Ether definiert wird, die der 
        // Transaktion mitgeliefert wird:
        uint startGuthaben = msg.value;
        
        // Wenn der ersteller des smart contracts in der transaktion einen Beg&#252;nstigten angegeben hat, soll ihm 
        // der zuvor als Startguthaben definierte Wert als Guthaben gutgeschrieben werden.
        // Das mitgesendete Ether wird dabei dem smart contract gutgeschrieben, er war der Empf&#228;nger der Transaktion.
        if (_sparer != 0x0) guthaben[_sparer] = startGuthaben;
        else guthaben[msg.sender] = startGuthaben;
    }
    
    
    // Schreibt dem Absender der Transaktion (TXfrom) ihren Wert (TXvalue) als Guthaben zu
    function einzahlen() public payable{
        guthaben[msg.sender] = msg.value;
    }
    
    // Erm&#246;glicht jemandem, so viel Ether aus dem smart contract abzubuchen, wie ihm an Guthaben zur Verf&#252;gung steht
    function abbuchen(uint _betrag) public {
        
        // Zun&#228;chst pr&#252;fen, ob dieser jemand &#252;ber ausreichend Guthaben verf&#252;gt.
        // Wird diese Bedingung nicht erf&#252;llt, wird die Ausf&#252;hrung der Funktion abgebrochen.
        require(guthaben[msg.sender] >= _betrag);
        
        // Subtrahieren des abzuhebenden Guthabens 
        guthaben [msg.sender] = guthaben [msg.sender] - _betrag;
        
        // &#220;berweisung des Ethers
        // ".transfer" ist eine Objektmethode des Datentyps address, die an die gegebene Addresse 
        // die gew&#252;nschte Menge Ether zu transferieren versucht. Schl&#228;gt dies fehl, wird die
        // Ausf&#252;hrung der Funktion abgebrochen und bisherige &#196;nderungen r&#252;ckg&#228;ngig gemacht.
        msg.sender.transfer(_betrag);
    }
    
    // Getter-Funktion; Gibt das Guthaben einer Addresse zur&#252;ck.
    // Dient der Veranschaulichung von Funktionen, die den state nicht ver&#228;ndern.
    // Nicht explizit notwendig, da jede als public Variable, so auch das mapping guthaben,
    // vom compiler eine automatische, gleichnamige Getter-Funktion erhalten, wenn sie als public
    // deklariert sind.
    function guthabenAnzeigen(address _sparer) view returns (uint) {
        return guthaben[_sparer];
    }
    
    // Eine weitere Veranschaulichung eines Funktionstyps, der den state nicht &#228;ndert. 
    // Weil mit pure gekennzeichnete Funktionen auf den state sogar garnicht nicht zugreifen k&#246;nnen,
    // werden entsprechende opcodes nicht ben&#246;tigt und der smart contract kostet weniger Guthabens
    // beim deployment ben&#246;tigt. 
    function addieren(uint _menge1, uint _menge2) pure returns (uint) {
        return _menge1 + _menge2;
    }
}