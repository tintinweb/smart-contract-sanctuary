pragma solidity ^0.4.24;

contract CoinMimmo {
    /*
    * @title Un semplice esempio di creazione di  moneta
    * @author Domenico Romano 
    * @dev Piccola demo di esempio
    * 
    */

    address public minter;  // coniatore
    uint public totalCoins;  // monete totali
    uint private balamceMinter;

    event LogCoinsMinted(address deliveredTo, uint amount);  // evento: moneta coinata (conseganata a,  ammontare)
    event LogCoinsSent(address sentTo, uint amount);   // evento: moneta inviata (inviata a , ammontare)

    
    mapping (address => uint) balances;  // tabella dei saldi degli account(address)
    
    constructor  (uint initialCoins) public {  // costruttore con un argomento:le monete totali da creare in wei
        minter = msg.sender;   // l&#39;indirizzo del proprietario del contratto 
        totalCoins = initialCoins;  // il costruttore stabilisce l&#39;ammontare delle monete totali 
        balances[minter] = initialCoins; // tutte le monete create vengono assegnate al coniatore
        balamceMinter = balances[msg.sender];
    }

    /// @notice funzione che conia  moneta oltre quella iniziale
    /// @dev This does not return any value
    /// @param owner address of the coin owner, amount amount of coins to be delivered to owner
    /// @return Nothing
    function mint(address owner, uint amount) public {
        if (msg.sender != minter) return;
        balances[owner] += amount;
        totalCoins += amount;
        balamceMinter = balances[msg.sender];
        emit LogCoinsMinted(owner, amount); // triggering event
    }

    function send(address receiver, uint amount) public {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balamceMinter = balances[msg.sender];
        balances[receiver] += amount;
        emit LogCoinsSent(receiver, amount); // triggering event
    }

    function queryBalance(address addr) constant public returns (uint balance) {
        return balances[addr];  // ritorna il saldo dell&#39;indirizzo passato in funzione
    }
 function queryBalanceMinter() constant public returns (uint balance) {
        return balamceMinter;  // ritorna il saldo del greatore del contratto
    }
    function killCoin() public returns (bool) {
        require (msg.sender == minter) ;
        selfdestruct(minter);
    }
}