/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

pragma solidity 0.4.26; /*

                                                                                
                                        @@@                                     
                                     [email protected]@@@@@@                                   
                                   @@@@@@@@@@@@@                                
                                [email protected]@@@@@@@@@@@@@@@@                              
                              @@@@@@@@@@@@@@@@@@@@@                             
                           ,@@@@@@@@@@@@@@@@@@@@&                               
                         @@@@@@@@@@@@@@@@@@@@@                                  
                      ,@@@@@@@@@@@@@@@@@@@@&                                    
                    @@@@@@@@@@@@@@@@@@@@@                                       
                 *@@@@@@@@@@@@@@@@@@@@%                                         
               @@@@@@@@@@@@@@@@@@@@@          @                                 
            *@@@@@@@@@@@@@@@@@@@@#          @@@@@#                              
          @@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@                            
       /@@@@@@@@@@@@@@@@@@@@(          @@@@@@@@@@@@@@@%                         
     @@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@                       
     @@@@@@@@@@@@@@@@@@@@@            ,@@@@@@@@@@@@@@@@@@@@%                    
        @@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@                  
          @@@@@@@@@@@@@@@@@@@@@            ,@@@@@@@@@@@@@@@@@@@@&               
             @@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@             
               @@@@@@@@@@@@@@@@@@@@@.           [email protected]@@@@@@@@@@@@@@@@@@@@          
                  @@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@        
                    @@@@@@@@@@@@@@@@@@@@@.            @@@@@@@@@@@@@@@@@@@@@     
                       @@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@   
                         &@@@@@@@@@@@@@@@@@@@@,          %@@@@@@@@@@@@@@@@@@@@, 
                            @@@@@@@@@@@@@@@@&          @@@@@@@@@@@@@@@@@@@@@    
                              %@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@.      
                                 @@@@@@%          @@@@@@@@@@@@@@@@@@@@@         
                                   #@          @@@@@@@@@@@@@@@@@@@@@.           
                                             @@@@@@@@@@@@@@@@@@@@@              
                                          @@@@@@@@@@@@@@@@@@@@@                 
                                        @@@@@@@@@@@@@@@@@@@@@                   
                                     @@@@@@@@@@@@@@@@@@@@@                      
                                   @@@@@@@@@@@@@@@@@@@@@                        
                                @@@@@@@@@@@@@@@@@@@@@                           
                                @@@@@@@@@@@@@@@@@@@                             
                                   @@@@@@@@@@@@@                                
                                     @@@@@@@@@                                  
                                        @@@ 



░░░░░░░░░░░░░░░░░░░░░░░░░░██╗███████╗██████╗  █████╗░░░░░░░░░░░░░░░░░░░░░░
██████╗██████╗██████╗░░░░░██║██╔════╝██╔══██╗██╔══██╗██████╗██████╗██████╗
╚═════╝╚═════╝╚═════╝░░░░░██║█████╗░░██████╔╝███████║╚═════╝╚═════╝╚═════╝
██████╗██████╗██████╗██╗░░██║██╔══╝░░██╔══██╗██╔══██║██████╗██████╗██████╗
╚═════╝╚═════╝╚═════╝╚█████╔╝███████╗██║░░██║██║░░██║╚═════╝╚═════╝╚═════╝
░░░░░░░░░░░░░░░░░░░░░░╚════╝░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝░░░░░░░░░░░░░░░░░░░░░

========== 'JERA' Token contract with following features ==========
    => ERC20 Compliance
    => Higher degree of control by owner - safeguard functionality
    => SafeMath implementation 
    => Burnable and minting 


============================== Stats ===============================
    => Name/Nombre      : JERA
    => Symbol/Simbolo   : JERA
    => Initial Supply/ 
       Preminado        : 4500000
    => Total supply
       Maximo de tokens : 15000000
    => Decimals/
       Decimales        : 18
    
    the rest of the tokens will be created via interaction 
    with the smart contract

    el resto de tokens se crearan via interaccion
    con el contrato inteligente

-------------------------------------------------------------------
 Copyright (c) 2021 onwards JERA.
 Contract designed with ❤ by P&P
-------------------------------------------------------------------
*/ 

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 interface ERC20 {
    function totalSupply() public view returns(uint supply);

    function balanceOf(address _owner) public view returns(uint balance);

    function transfer(address _to, uint _value) public returns(bool success);

    function transferFrom(address _from, address _to, uint _value) public returns(bool success);

    function approve(address _spender, uint _value) public returns(bool success);

    function allowance(address _owner, address _spender) public view returns(uint remaining);

    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


    // ERC20 Token Smart Contract
    contract JERA {
        
        string public constant name = "JERA";
        string public constant symbol = "JERA";
        uint8 public constant decimals = 18;
        uint public _totalSupply = 4500000000000000000000000;
        uint256 public RATE = 300000000000000000;
        bool public isMinting = true;
        string public constant generated_by  = "P&P";
        
        using SafeMath for uint256;
        address public owner;
        
         modifier onlyOwner() {
            if (msg.sender != owner) {
                throw;
            }
             _;
         }
     
        mapping(address => uint256) balances;
        // Owner of account approves the transfer of an amount to another account
        mapping(address => mapping(address=>uint256)) allowed;

        // Its a payable function works as a token factory.
        function () payable{
            createTokens();
        }

        // Constructor
         constructor() public payable {
            owner = 0x3396aC4d01a15545eCD6fC8E5CB2e4fD61AF50B1; 
            balances[owner] = _totalSupply;
        }

          //allows owner to burn tokens that are not sold in a crowdsale
        function burnTokens(uint256 _value) onlyOwner {

             require(balances[msg.sender] >= _value && _value > 0 );
             _totalSupply = _totalSupply.sub(_value);
             balances[msg.sender] = balances[msg.sender].sub(_value);
             
        }
  
         function createTokens() payable {
            if(isMinting == true){
                require(msg.value > 0);
                uint256  tokens = msg.value.div(100000000000000).mul(RATE);
                balances[msg.sender] = balances[msg.sender].add(tokens);
                _totalSupply = _totalSupply.add(tokens);
                owner.transfer(msg.value);
            }
            else{
                throw;
            }
        }


        function endCrowdsale() onlyOwner {
            isMinting = false;
        }

        function changeCrowdsaleRate(uint256 _value) onlyOwner {
            RATE = _value;
        }


        
        function totalSupply() constant returns(uint256){
            return _totalSupply;
        }

        function balanceOf(address _owner) constant returns(uint256){
            return balances[_owner];
        }
   
        function transfer(address _to, uint256 _value)  returns(bool) {
            require(balances[msg.sender] >= _value && _value > 0 );
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }
        

    function transferFrom(address _from, address _to, uint256 _value)  returns(bool) {
        require(allowed[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) returns(bool){
        allowed[msg.sender][_spender] = _value; 
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns(uint256){
        return allowed[_owner][_spender];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}