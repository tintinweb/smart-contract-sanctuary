pragma solidity ^0.4.25;
 
 contract Mtoken{
       
       string public  name="token";
       string public  symbol="MAS";
       uint public  decimal =8;
        uint256 public totalSupply;
      // uint  public totalToken;
       mapping(address=>uint256) public balanceoF;
       mapping(address => mapping (address => uint256)) allowed;
       
         event approvel(address indexed tokenOwner, address indexed spender,uint token);
        event transfers(address indexed From,address indexed To,uint token);
      
       constructor (  uint256 _initialAmount,string _tokenName,uint8 _decimalUnits,
        string _tokenSymbol ) public {
        balanceoF[msg.sender] = _initialAmount;               
        totalSupply = _initialAmount;                        
        name = _tokenName;                                   
        decimal = _decimalUnits;                            
        symbol = _tokenSymbol;                              
    }
           // uint value;
           //   function totalSupply() public returns(uint ){
            //      return _totalSupply;
       
       function balanceOf(address tokenOwner) public view returns(uint ){
           return balanceoF[tokenOwner];
       }
       function transfer(address reciever,uint _value) public returns(bool){
           require(balanceoF[msg.sender]>_value);
           balanceoF[msg.sender] -=_value;
           balanceoF[reciever]=balanceoF[reciever]+_value;
           emit transfers(msg.sender, reciever, _value);
           return true;
           
       }
       function approve(address _spender,uint _value) public returns(bool){
           allowed[msg.sender][_spender]=_value;
           emit  approvel(msg.sender ,_spender,_value);
        //   emit approvel(msg.sender,_spender,_value);
           return true;
       }
       function allowence(address owner,address _spender) public view returns(uint){
           return allowed[owner][_spender];
       }
       function transferFron(address owner,address buyer,uint _value)public returns(bool){
           require(_value <= balanceoF[owner]);
           require(_value <= allowed[owner][msg.sender]);
           
           balanceoF[owner]=balanceoF[owner]-_value;
           allowed[owner][msg.sender]=allowed[owner][msg.sender]-_value;
           balanceoF[buyer]=balanceoF[buyer]+_value;
           emit  transfers(owner,buyer,_value);
           return true;
       }
       
       
 }