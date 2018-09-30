pragma solidity ^0.4.4;

contract Token {

         /// @return quantit&#224; totale di token

    function totalSupply() constant returns (uint256 supply) {}

         /// @param _owner L&#39;indirizzo a cui sar&#224; assegnato il saldo iniziale
         /// @return bilancio

    function balanceOf(address _owner) constant returns (uint256 balance) {}

         /// @notice send `_value` token to `_to` from `msg.sender`
         /// @param _to L&#39;indirizzo del destinatario
         /// @param _value La quantit&#224; di token da trasferire
         /// @return Se il trasferimento ha avuto successo o meno

    function transfer(address _to, uint256 _value) returns (bool success) {}

         /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
         /// @param _from L&#39;indirizzo del mittente
         /// @param _to L&#39;indirizzo del destinatario
         /// @param _value La quantit&#224; di token da trasferire
         /// @return Se il trasferimento ha avuto successo o meno

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

         /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
         /// @param _spender L&#39;indirizzo dell&#39;account in grado di trasferire i token
         /// @param _value La quantit&#224; di wei da approvare per il trasferimento
         /// @return Se l&#39;approvazione ha avuto successo o meno

    function approve(address _spender, uint256 _value) returns (bool success) {}

         /// @param _owner L&#39;indirizzo dell&#39;account proprietario di token
         /// @param _spender L&#39;indirizzo dell&#39;account in grado di trasferire i token
         /// @return La quantit&#224; di token rimanenti

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Il valore predefinito presuppone che totalSupply non pu&#242; essere superiore al massimo(2^256 - 1).
        //Se il tuo token esce dal totalSupply e pu&#242; emettere pi&#249; token con il passare del tempo, &#232; necessario controllare se non si avvolge
        //Sostituisci il se con questo invece
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {

        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //come sopra. Sostituisci questa linea con quanto segue se vuoi proteggerti dagli invii di wrapping.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {

        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract myToken is StandardToken {  //Update the contract name.

    /* Variabili pubbliche del token */

   /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */

    string public name;                   // Nome token
    uint8 public decimals;                // Quanti decimali mostrare. Lo standard &#232; 18
    string public symbol;                 // Un identificatore
    string public version = &#39;H1.0&#39;; 
    uint256 public unitsOneEthCanBuy;     // Quante unit&#224; della tua moneta possono essere acquistate entro 1 ETH
    uint256 public totalEthInWei;         // WEI &#232; la pi&#249; piccola unit&#224; di ETH. Qui archiviamo l&#39;ETH totale raccolto tramite il nostro ICO.
    address public fundsWallet;           // Dove dovrebbe andare l&#39;ETH 

    // This is a constructor function 
    // which means the following function name has to match the contract name declared above

    function myToken() {
        balances[msg.sender] = 10000000000000000000000;             //Tutti i token iniziali. Se lo impostiamo a 1000 per esempio. Se vuoi che i tuoi token iniziali siano X e il tuo decimale sia 5, imposta questo valore su X * 100000
        totalSupply = 10000000000000000000000;                      //Aggiorna l&#39;offerta totale (1000 per esempio) 
        name = "myToken";                                           // Imposta il nome del token
        decimals = 18;                                              // Quantit&#224; di decimali visualizzati
        symbol = "MYTO";                                            // Imposta il simbolo
        unitsOneEthCanBuy = 10;                                     // Imposta il prezzo del tuo token per l&#39;ICO 
        fundsWallet = msg.sender;                                   // Il proprietario del contratto ottiene ETH
    }

    function() payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount); // Messaggio inviato in broadcast sulla blockchain

        //Transferische gli ether a fundsWallet
        fundsWallet.transfer(msg.value);                               
    }

    /* Approva e quindi chiama il contratto di ricezione */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //chiama la funzione receiveApproval sul contratto che desideri ricevere. Questo crea manualmente la firma della funzione in modo da non dover includere un contratto qui solo per questo.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //si presume che quando esegue ci&#242; che la chiamata debba avere successo, altrimenti si utilizzerebbe invece vanilla.

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}