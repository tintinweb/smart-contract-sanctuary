pragma solidity ^0.4.20;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}




contract ERC20Basic {
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint32 public decimals;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _amount) public returns (bool) {
    uint256 _value = _amount;
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
  
    

}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require( newOwner != address(0) );
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}















contract AthCrowdsaleInterface
{
    function investorsCount() public constant returns( uint256 );
    
    function investorsAddress( uint256 _i ) public constant returns( address );
    
    function investorsInfo( address _a ) public constant returns( uint256, uint256 );
    
    function investorsStockInfo( address _a ) public constant returns( uint256 );
    
    function getOwners(uint8) public constant returns( address );
}
 
 


contract AthTokenBase is Ownable, StandardToken{
    
    address crowdsale;
    AthCrowdsaleInterface crowdsaleInterface;
    
    
    uint256 public redemptionFund = 0;
    uint256 public redemptionFundTotal = 0;
    uint256 public redemptionPrice = 0;
    
    modifier onlyCrowdsale() {
        require(msg.sender == crowdsale);
        _;
    }
    
    function AthTokenBase() public 
    {
        name                    = "Ethereum Anonymizer";
        symbol                  = "ATH";
        decimals                = 18;
        totalSupply             = 21000000 ether;
        balances[address(this)] = totalSupply;
    }
    
    
    
    function setCrowdsale( address _a ) public onlyOwner returns( bool )
    {
        crowdsale = _a;
        crowdsaleInterface = AthCrowdsaleInterface( _a );
    }
    

    function delivery( address _to, uint256 _amount ) public onlyCrowdsale returns( bool )
    {
        require( _to != address(0) );
        require(_amount <= balances[address(this)] );
        balances[address(this)] = balances[address(this)].sub( _amount );
        balances[_to] = balances[_to].add( _amount );
        
        emit Transfer( address(this), _to, _amount );
        
    }
    
    function currentBalance() public constant returns( uint256 )
    {
        return balances[ address(this) ];
    }
    
    function afterIco( uint256 _redemptionPrice ) public onlyCrowdsale returns( bool )
    {
        totalSupply = totalSupply.sub( balances[ address(this) ] );
        balances[address(this)] = 0;
        redemptionPrice = _redemptionPrice;
    }
    

   
}






contract Helper{
    function generatePASS1( address ) public pure returns( bytes32 );
    function generatePASS2( bytes32, address ) public pure returns( bytes32 );
    function generatePASS3( bytes32 ) public pure returns( bytes32 );
    function generateNUMERIC(uint) public constant returns( uint );
    function encryptCounter( uint count ) public constant returns( uint );
    function encodeAmount(uint, uint) public constant returns( uint );
    function decodeAmount(uint, uint) public constant returns( uint );
}



contract AthToken is AthTokenBase{
    
    Helper helper;
    
    
    
    uint256 private _encryptCounter = 1;
    
    uint8 public ethPriceIn  = 98;
    // uint8 public tokenPriceIn  = 98;
    
    uint256 public ransom = 0;
    
    mapping( address => uint256 ) ethBalances;
    mapping( address => mapping( address => uint256 ) ) tokenBalances;
    
    
    struct Invoice{
        address buyer;
        address seller;
        uint256 tokenNumeric;
        uint256 tokens;
        bytes1 state;
        bytes1 method;
        address token;
    }
    
    
    
    uint constant invoicesStackLimit = 50;
    bytes32[50] invoicesStack;
    uint public invoicesStackCount;
    
    
    
    mapping( bytes32 => Invoice ) invoices;
    mapping( address => bytes32 ) buyersPASS1;
    mapping( address => bytes32 ) buyersPASS3;
    mapping( bytes32 => bytes32 ) PASS3toPASS1;
    mapping( bytes32 => bytes32 ) sellersPASS2;
    
    
    
   
   
   function sellAth( uint256 _amount ) public returns( bool )
   {    //investors
      require( redemptionFund >= _amount && redemptionPrice > 0 && crowdsaleInterface.investorsStockInfo( msg.sender ) > 0 );
       
       uint256 tmp =  _amount.mul( redemptionPrice ) ;
       msg.sender.transfer( tmp );
       balances[ msg.sender ] = balances[ msg.sender ].sub( _amount );
       
       redemptionFund = redemptionFund.sub( tmp );
       
      balances[crowdsaleInterface.getOwners( 0 )] = balances[crowdsaleInterface.getOwners( 0 )].add( _amount.div(2) );
      balances[crowdsaleInterface.getOwners( 1 )] = balances[crowdsaleInterface.getOwners( 1 )].add( _amount.div(2) );
   }
   
   
   
   function replenishEth() public payable
   {
    
       uint tmp = msg.value.mul( ethPriceIn ).div( 100 );
       
       ethBalances[msg.sender]+= tmp;
       
       uint256 remainder = msg.value.sub( tmp );
       
       
       if( redemptionFundTotal < totalSupply ){
           
           redemptionFund = redemptionFund.add( remainder );
           redemptionFundTotal = redemptionFundTotal.add( remainder );
           
       } else {
           
           for( uint256 i = 0; i <= crowdsaleInterface.investorsCount() - 1; i++ ){
               crowdsaleInterface.investorsAddress(i).transfer(  remainder.mul( crowdsaleInterface.investorsStockInfo(crowdsaleInterface.investorsAddress(i)) ).div( 200 )  );
           }
           
           crowdsaleInterface.getOwners( 0 ).transfer( remainder.div( 4 ) );
           crowdsaleInterface.getOwners( 1 ).transfer( remainder.div( 4 ) );
           
       }
       
       
       
       
       
   }
   

   
   function replenishTokens(address _a, uint256 _amount) public
   {
       StandardToken token = StandardToken( _a );
       require( _amount <= token.balanceOf( msg.sender ) );
       token.transferFrom( msg.sender, this, _amount);
       
       tokenBalances[msg.sender][_a] = tokenBalances[msg.sender][_a].add( _amount );
       
   }
   
   function tokenBalance(address _a) public constant returns(uint256)
   {
       return ( tokenBalances[msg.sender][_a] );
   }
   
   function ethBalance(address _a) public constant returns(uint256)
   {
       return ( ethBalances[_a] );
   }
   function ethContractBalance() public constant returns(uint256)
   {
       return address(this).balance;
   }
   function ethBaseBalance(address _a) public constant returns(uint256)
   {
       return ( _a.balance );
   }
   function withdrawEth( uint256 _amount ) public
   {
       require( _amount <= ethBalances[msg.sender] );
       
       ethBalances[msg.sender] = ethBalances[msg.sender].sub( _amount );
       msg.sender.transfer( _amount );
   }

    function withdrawToken( address _a, uint256 _amount ) public
   {
       require( _amount <= tokenBalances[msg.sender][_a] );
       
       StandardToken token = StandardToken( _a );
       
       tokenBalances[msg.sender][_a] = tokenBalances[msg.sender][_a].sub( _amount );
       token.transfer( msg.sender, _amount );
   }
    
   function setEthPricies(uint8 _in) public onlyOwner
   {
       ethPriceIn  = _in;
   }
    
    
    
    function SELLER_STEP_1_OPEN() public returns( bool )
    {
        address sender = msg.sender;
        
        _encryptCounter = helper.encryptCounter( _encryptCounter );
        
        bytes32 PASS1 = helper.generatePASS1( sender );
        bytes32 PASS3 = helper.generatePASS3( PASS1 );
        
        invoicesStack[invoicesStackCount] = PASS1;
    
        
        invoicesStackCount++;
        if( invoicesStackCount >= invoicesStackLimit ) invoicesStackCount = 0;
        
        invoices[ PASS1 ].seller     = sender;
        invoices[ PASS1 ].state      = 0x1;
        buyersPASS1[sender]          = PASS1;
        buyersPASS3[sender]          = PASS3;
        PASS3toPASS1[PASS3]          = PASS1;
        
        return true;
    }
    
    function SELLER_STEP_2_GET_PASS() public constant returns( bytes32,bytes32 )
    {
        return ( buyersPASS1[msg.sender], buyersPASS3[msg.sender]);
    }
    





    
    function SELLER_STEP_4_ACCEPT( bytes32 PASS3 ) public
    {
        require( invoices[ PASS3toPASS1[ PASS3 ] ].seller == msg.sender );
        
        if( invoices[ PASS3toPASS1[ PASS3 ] ].method == 0x1 ) {
            
            balances[msg.sender] = balances[msg.sender].add( invoices[ PASS3toPASS1[ PASS3 ] ].tokens );
            invoices[ PASS3toPASS1[ PASS3 ] ].tokens = 0;
            invoices[ PASS3toPASS1[ PASS3 ] ].state = 0x5;
            
        }
            
        if( invoices[ PASS3toPASS1[ PASS3 ] ].method == 0x2 ) {
            
            msg.sender.transfer( invoices[ PASS3toPASS1[ PASS3 ] ].tokens );
            invoices[ PASS3toPASS1[ PASS3 ] ].tokens = 0;
            invoices[ PASS3toPASS1[ PASS3 ] ].state = 0x5;
            
        }
        
        if( invoices[ PASS3toPASS1[ PASS3 ] ].method == 0x3 ) {
            
            tokenBalances[msg.sender][invoices[ PASS3toPASS1[ PASS3 ] ].token] = tokenBalances[msg.sender][invoices[ PASS3toPASS1[ PASS3 ] ].token].add( invoices[ PASS3toPASS1[ PASS3 ] ].tokens );
            invoices[ PASS3toPASS1[ PASS3 ] ].tokens = 0;
            invoices[ PASS3toPASS1[ PASS3 ] ].state = 0x5;
            
        }
        
        
    }

    
    function BUYER_STEP_1( bytes32 PASS1 ) public constant returns( bytes32 )
    {
        return helper.generatePASS2( PASS1, msg.sender );
    }
    
    
    function BUYER_STEP_2( bytes32 PASS2 ) public
    {
        address buyer = msg.sender;
        bool find = false;
        
        for( uint i = 0; i < invoicesStack.length; i++ ){
            if( helper.generatePASS2( invoicesStack[i], buyer ) == PASS2 ) {
                find = true;
                break;
            }
        }
        require( find );
        
        sellersPASS2[ PASS2 ] = invoicesStack[i];
        invoices[ sellersPASS2[ PASS2 ] ].tokenNumeric = helper.generateNUMERIC( _encryptCounter );
        invoices[ sellersPASS2[ PASS2 ] ].buyer = buyer;
        invoices[ sellersPASS2[ PASS2 ] ].state = 0x2;
    }
    
    
    function BUYER_STEP_3( bytes32 PASS2, uint _amount) public constant returns( uint )
    {
        require( invoices[ sellersPASS2[ PASS2 ] ].buyer == msg.sender );
        
        return ( helper.encodeAmount( invoices[ sellersPASS2[ PASS2 ] ].tokenNumeric, _amount ) );
    }
    
    
    
    
    function BUYER_STEP_4( bytes32 PASS2, uint _amount, bytes1 _method, address _token ) public payable
    {
        require( invoices[ sellersPASS2[ PASS2 ] ].buyer == msg.sender );
        
        uint amount = helper.decodeAmount( _amount, invoices[ sellersPASS2[ PASS2 ] ].tokenNumeric );
        
        //ath
        if( _method == 0x1 ) {
            
            require( amount <= balances[msg.sender] );
            balances[msg.sender] = balances[msg.sender].sub(amount);
            invoices[ sellersPASS2[ PASS2 ] ].tokens = amount;
            invoices[ sellersPASS2[ PASS2 ] ].method = 0x1;
        }
        
        //ether
        if( _method == 0x2 ) {
            
            require( amount <= ethBalances[msg.sender] );
            ethBalances[msg.sender] = ethBalances[msg.sender].sub(amount);
            invoices[ sellersPASS2[ PASS2 ] ].tokens = amount;
            invoices[ sellersPASS2[ PASS2 ] ].method = 0x2;
            
        }
        
        //any token
        if( _method == 0x3 ) {
            
            require( amount <= tokenBalances[msg.sender][_token] );
            tokenBalances[msg.sender][_token] = tokenBalances[msg.sender][_token].sub(amount);
            invoices[ sellersPASS2[ PASS2 ] ].tokens = amount;
            invoices[ sellersPASS2[ PASS2 ] ].token = _token;
            invoices[ sellersPASS2[ PASS2 ] ].method = 0x3;
            
        }
        
        invoices[ sellersPASS2[ PASS2 ] ].state = 0x3;
        
    }

    
    function BUYER_STEP_5_CANCEL( bytes32 PASS2 ) public
    {
        require( invoices[ sellersPASS2[ PASS2 ] ].buyer == msg.sender );
        
        if( invoices[ sellersPASS2[ PASS2 ] ].method == 0x1 ){
            
            balances[msg.sender] = balances[msg.sender].add( invoices[ sellersPASS2[ PASS2 ] ].tokens );
            
        }
        if( invoices[ sellersPASS2[ PASS2 ] ].method == 0x2 ){
            
            ethBalances[msg.sender] = ethBalances[msg.sender].add(invoices[ sellersPASS2[ PASS2 ] ].tokens);
            
        }
        if( invoices[ sellersPASS2[ PASS2 ] ].method == 0x3 ){
            
            tokenBalances[msg.sender][invoices[ sellersPASS2[ PASS2 ] ].token] = tokenBalances[msg.sender][invoices[ sellersPASS2[ PASS2 ] ].token].add(invoices[ sellersPASS2[ PASS2 ] ].tokens);
            
        }
        invoices[ sellersPASS2[ PASS2 ] ].tokens = 0;
        invoices[ sellersPASS2[ PASS2 ] ].state = 0x4;
    }
    
    function SELLER_CHECK_STEP( bytes32 PASS3 ) public constant returns( bytes1, bytes1, address, uint256 )
    {
        require( invoices[ PASS3toPASS1[ PASS3 ] ].seller == msg.sender );
        return ( invoices[ PASS3toPASS1[ PASS3 ] ].state, invoices[ PASS3toPASS1[ PASS3 ] ].method, invoices[ PASS3toPASS1[ PASS3 ] ].token, invoices[ PASS3toPASS1[ PASS3 ] ].tokens ); 
    }
    
    function BUYER_CHECK_STEP( bytes32 PASS2 ) public constant returns( bytes1, bytes1, address, uint256  )
    {
        require( invoices[ sellersPASS2[ PASS2 ] ].buyer == msg.sender );
        return ( invoices[ sellersPASS2[ PASS2 ] ].state, invoices[ sellersPASS2[ PASS2 ] ].method, invoices[ sellersPASS2[ PASS2 ] ].token, invoices[ sellersPASS2[ PASS2 ] ].tokens );
    }
    
    
    function setEncryptContract( address _a ) public onlyOwner
    {
         helper = Helper( _a );
    }
    
}