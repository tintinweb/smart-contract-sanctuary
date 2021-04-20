pragma solidity ^0.4.11;

import './IERC20.sol';
import './SafeMath.sol';

contract MyToken is IERC20{
  using SafeMath for uint256;
  
  uint256 public _totalSupply = 0;
  
  
  string public symbol = "ERC";//Simbolo del token es. ETH
  string public constant name = "ERACLE TOKEN"; //Nome del token es. Ethereum
  uint256 public constant decimals = 2; //Numero di decimali del token, il bitcoin ne ha 8, ethereum 18
  
  uint256 public MAX_SUPPLY = 40000 * 10**decimals; //Numero massimo di token da emettere ( 1000 )
  uint256 public TOKEN_TO_CREATOR = 2000 * 10**decimals; //Token da inviare al creatore del contratto

  uint256 public constant RATE = 500; //Quanti token inviare per ogni ether ricevuto
  address public owner;
  
  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;
  
  //Funzione che permette di ricevere token solo specificando l'indirizzo
  function() payable{
      createTokens();
  }
  
  //Salviamo l'indirizzo del creatore del contratto per inviare gli ether ricevuti
  function MyToken(){
      owner = msg.sender;
      balances[msg.sender] = TOKEN_TO_CREATOR;
      _totalSupply = _totalSupply.add(TOKEN_TO_CREATOR);
  }
  
  //Creazione dei token
  function createTokens() payable{
      //Controlliamo che gli ether ricevuti siano maggiori di 0
      require(msg.value >= 0);
      
      //Creiamo una variabile che contiene gli ether ricevuti moltiplicati per il RATE
      uint256 tokens = msg.value.mul(10 ** decimals);
      tokens = tokens.mul(RATE);
      tokens = tokens.div(10 ** 18);

      uint256 sum = _totalSupply.add(tokens);
      require(sum <= MAX_SUPPLY);
      //Aggiungiamo i token al bilancio di chi ci ha inviato gli ether ed aumentiamo la variabile totalSupply
      balances[msg.sender] = balances[msg.sender].add(tokens);
      _totalSupply = sum;
      
      //Inviamo gli ether a chi ha creato il contratto
      owner.transfer(msg.value);
  }

  
  //Ritorna il numero totale di token
  function totalSupply() constant returns (uint totalSupply){
      return _totalSupply;
  }
  
  //Ritorna il bilancio dell'utente di un indirizzo
  function balanceOf(address _owner) constant returns (uint balance){
      return balances[_owner];
  }
  
  //Per inviare i Token
  function transfer(address _to, uint256 _value) returns (bool success){
      //Controlliamo che chi voglia inviare i token ne abbia a sufficienza e che ne voglia inviare più di 0
      require(
          balances[msg.sender] >= _value
          && _value > 0
      );
      //Togliamo i token inviati dal suo bilancio
      balances[msg.sender] = balances[msg.sender].sub(_value);
      //Li aggiungiamo al bilancio del ricevente
      balances[_to] = balances[_to].add(_value);
      //Chiamiamo l evento transfer
      Transfer(msg.sender, _to, _value);
      return true;
  }
  
  //Invio dei token con delega
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
      //Controlliamo che chi voglia inviare token da un indirizzo non suo abbia la delega per farlo, che
      //l'account da dove vngono inviati i token abbia token a sufficienza e
      //che i token inviati siano maggiori di 0
      require(
          allowed[_from][msg.sender] >= _value
          && balances[msg.sender] >= _value
          && _value > 0
      );
      //togliamo i token da chi li invia
      balances[_from] = balances[_from].sub(_value);
      //Aggiungiamoli al rcevente
      balances[_to] = balances[_to].add(_value);
      //Diminuiamo il valore dei token che il delegato può inviare in favore del delegante
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      //Chiamaiamo l'evento transfer
      Transfer(_from, _to, _value);
      return true;
  }
  
  //Delegare qualcuno all'invio di token
  function approve(address _spender, uint256 _value) returns (bool success){
      //Inseriamo l'indirizzo del delegato e il massimo che può inviare
      allowed[msg.sender][_spender] = _value;
      //Chiamiamo l'evento approval
      Approval(msg.sender, _spender, _value);
      return true;
  }
  
  //Ritorna il numero di token che un delegato può ancora inviare
  function allowance(address _owner, address _spender) constant returns (uint remaining){
      return allowed[_owner][_spender];
  }

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
  
}