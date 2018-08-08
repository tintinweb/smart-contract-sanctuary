pragma solidity 0.4.24;


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
   constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Interface {
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
     function transfer(address to, uint tokens) public returns (bool success);
     function approve(address spender, uint tokens) public returns (bool success);
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Buyers{
   
    struct Buyer{
        
        string   name;  
        string   country;
        string   city; 
        string   b_address;
        string   mobile;  
    }
    mapping(address=>Buyer) public registerbuyer;
    event BuyerAdded(address  from, string name,string country,string city,string b_address,string mobile);
    
    
      
    function registerBuyer(string _name,string _country,string _city,string _address,string _mobile) public returns(bool){
      
         require(bytes(_name).length!=0 &&
             bytes(_country).length!=0 &&
             bytes(_city).length!=0 &&
             bytes(_address).length!=0 &&
             bytes(_mobile).length!=0  
             
        );
        registerbuyer[msg.sender]=Buyer(_name,_country,_city,_address,_mobile);
        emit BuyerAdded(msg.sender,_name,_country,_city,_address,_mobile);
        return true;
        
    }
   
    function getBuyer() public constant returns(string name,string country, string city,string _address,string mobile ){
        return (registerbuyer[msg.sender].name,registerbuyer[msg.sender].country,registerbuyer[msg.sender].city,registerbuyer[msg.sender].b_address,registerbuyer[msg.sender].mobile);
    }
    
    function getBuyerbyaddress(address _useraddress) public constant returns(string name,string country, string city,string _address,string mobile ){
        return (registerbuyer[_useraddress].name,registerbuyer[_useraddress].country,registerbuyer[_useraddress].city,registerbuyer[_useraddress].b_address,registerbuyer[_useraddress].mobile);
    }
    
}

contract ProductsInterface {
     
    struct Product { // Struct
        uint256  id;
        string   name;  
        string   image;
        uint256  price;
        string   detail;
        address  _seller;
         
    }
    event ProductAdded(uint256 indexed id,address seller, string  name,string  image, uint256  price,string  detail );
   
   
    function addproduct(string _name,string _image,uint256 _price,string _detail)   public   returns (bool success);
    function updateprice(uint _index, uint _price) public returns (bool success);
  
   function getproduuct(uint _index) public constant returns(uint256 id,string name,string image,uint256  price,string detail, address _seller);
   function getproductprices() public constant returns(uint256[]);
   
}

contract OrderInterface{
    struct Order { // Struct
        uint256  id;
        uint256   quantity;  
        uint256   product_index;  
        uint256  price;
       
        address  buyer;
        address  seller;
        uint256 status;
         
    }
    uint256 public order_counter;
    mapping (uint => Order) public orders;
     
    function placeorder(  uint256   quantity,uint256   product_index)  public returns(uint256);
    event OrderPlace(uint256 indexed id, uint256   quantity,uint256   product_index,string   name,address  buyer, address  seller );
   
}

contract FeedToken is  ProductsInterface,OrderInterface, ERC20Interface,Ownable,Buyers {



   using SafeMath for uint256;
   //------------------------------------------------------------------------
    uint256 public counter=0;
    mapping (uint => Product) public seller_products;
    mapping (uint => uint) public products_price;
    mapping (address=> uint) public seller_total_products;
   //------------------------------------------------------------------------
   string public name;
   string public symbol;
   uint256 public decimals;

   uint256 public _totalSupply;
   uint256 order_counter=0;
   mapping(address => uint256) tokenBalances;
   address ownerWallet;
   // Owner of account approves the transfer of an amount to another account
   mapping (address => mapping (address => uint256)) allowed;
   
   mapping (address=>uint) privateSaleBuyerTokens;
   address[] privateSaleBuyers;
   
   mapping (address=>uint) preSaleBuyerTokens;
   address[] preSaleBuyers;
   
   mapping(address=>uint) teamMembers;
   
   uint privateSaleEndDate;
   uint preSaleEndDate;
   uint icoEndDate;
   /**
   * @dev Contructor that gives msg.sender all of existing tokens.
   */
    constructor(address wallet) public {
        owner = wallet;
        name  = "Feed";
        symbol = "FEED";
        decimals = 18;
        _totalSupply = 1000000000 * 10 ** uint(decimals);
        tokenBalances[ msg.sender] = _totalSupply;   //Since we divided the token into 10^18 parts
    }
    
     // Get the token balance for account `tokenOwner`
     function balanceOf(address tokenOwner) public constant returns (uint balance) {
         return tokenBalances[tokenOwner];
     }
  
     // Transfer the balance from owner&#39;s account to another account
     function transfer(address to, uint tokens) public returns (bool success) {
         require(to != address(0));
         require(tokens <= tokenBalances[msg.sender]);
         checkTokenVesting(msg.sender, tokens);
         tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(tokens);
         tokenBalances[to] = tokenBalances[to].add(tokens);
         emit Transfer(msg.sender, to, tokens);
         return true;
     }
     function checkUser() public constant returns(string ){
         require(bytes(registerbuyer[msg.sender].name).length!=0);
          
             return "Register User";
     }
     
     function checkTokenVesting(address sender, uint tokens) internal {
         uint lockupTime;
         uint daysPassedSinceEndDate;
         uint lockedTokens;
         if (preSaleBuyerTokens[sender] > 0 || privateSaleBuyerTokens[sender]>0 || teamMembers[sender]>0)
         {
             if (teamMembers[sender]>0)
             {
                lockupTime = uint(24).mul(uint(30)).mul(1 days);
                if (now<icoEndDate.add(lockupTime))
                {
                    lockedTokens = teamMembers[sender];
                    if (lockedTokens.add(tokens)>tokenBalances[sender])
                        revert();
                }   
             }
             else if (privateSaleBuyerTokens[sender]>0)
             {
                lockupTime = uint(12).mul(uint(30)).mul(1 days);
                uint daysPassedSincePrivateSaleEnd = now.sub(privateSaleEndDate);
                daysPassedSincePrivateSaleEnd = daysPassedSincePrivateSaleEnd.div(1 days);
                uint monthsPassedSinceICOEnd = daysPassedSincePrivateSaleEnd.div(30);
                uint unlockedTokens = privateSaleBuyerTokens[sender].div(12).mul(monthsPassedSinceICOEnd);
                lockedTokens = privateSaleBuyerTokens[sender].sub(unlockedTokens);
                if (lockedTokens.add(tokens)>tokenBalances[sender])
                    revert();
                
             }
             else if (preSaleBuyerTokens[sender]>0)
             {
               lockupTime = uint(3).mul(uint(30)).mul(1 days);
               if (now<preSaleEndDate.add(lockupTime))
                {
                    lockedTokens = preSaleBuyerTokens[sender];
                    if (lockedTokens.add(tokens)>tokenBalances[sender])
                        revert();
                }   
             }
         }
     }
     /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= tokenBalances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    checkTokenVesting(_from,_value);
    tokenBalances[_from] = tokenBalances[_from].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  
     /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

     // ------------------------------------------------------------------------
     // Total supply
     // ------------------------------------------------------------------------
     function totalSupply() public constant returns (uint) {
         return _totalSupply  - tokenBalances[address(0)];
     }
     
    
     
     // ------------------------------------------------------------------------
     // Returns the amount of tokens approved by the owner that can be
     // transferred to the spender&#39;s account
     // ------------------------------------------------------------------------
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
         return allowed[tokenOwner][spender];
     }
     
     /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
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

     
     // ------------------------------------------------------------------------
     // Don&#39;t accept ETH
     // ------------------------------------------------------------------------
     function () public payable {
         revert();
     }
 
 
     // ------------------------------------------------------------------------
     // Owner can transfer out any accidentally sent ERC20 tokens
     // ------------------------------------------------------------------------
     function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
         return ERC20Interface(tokenAddress).transfer(owner, tokens);
     }
     
    
     function placeorder( uint256   quantity,uint256   product_index)  public  returns(uint256) {
         
        require(counter>=product_index && product_index>0);
        require(bytes(registerbuyer[msg.sender].name).length!=0);//to place order you first register yourself
         
        transfer(seller_products[product_index]._seller,seller_products[product_index].price*quantity);
        orders[order_counter] = Order(order_counter,quantity,product_index,seller_products[product_index].price, msg.sender,seller_products[product_index]._seller,0);
        
        emit OrderPlace(order_counter,quantity, product_index,  seller_products[product_index].name, msg.sender, seller_products[product_index]._seller );
        order_counter++;
        return counter;
    }
    
    //------------------------------------------------------------------------
    // product methods
    //------------------------------------------------------------------------
   
   
    function addproduct(string _name,string _image,uint256 _price,string _detail)   public   returns (bool success){
          require(bytes(_name).length!=0 &&
             bytes(_image).length!=0 &&
             bytes(_detail).length!=0 
            
             
        );
        counter++;
        seller_products[counter] = Product(counter,_name,_image, _price,_detail,msg.sender);
        products_price[counter]=_price;
        emit ProductAdded(counter,msg.sender,_name,_image,_price,_detail);
        return true;
   }
  
   function updateprice(uint _index, uint _price) public returns (bool success){
      require(seller_products[_index]._seller==msg.sender);
       
     
      seller_products[_index].price=_price;
      products_price[_index]=_price;
      return true;
  }
  
   function getproduuct(uint _index) public constant returns(uint256 ,string ,string ,uint256  ,string , address )
   {
       return(seller_products[_index].id,seller_products[_index].name,seller_products[_index].image,products_price[_index],seller_products[_index].detail,seller_products[_index]._seller);
   }
   function getproductprices() public constant returns(uint256[])
   {
       uint256[] memory price = new uint256[](counter);
        
        for (uint i = 0; i <counter; i++) {
           
            price[i]=products_price[i+1];
             
        }
      return price;
   }
    
    //------------------------------------------------------------------------
    //end Products
    //------------------------------------------------------------------------
    
    function addPrivateSaleEndDate(uint256 endDate) public onlyOwner {
        privateSaleEndDate = endDate;
    }
    
    function addPreSaleEndDate(uint256 endDate) public onlyOwner {
        preSaleEndDate = endDate;
    }
    
    function addICOEndDate(uint256 endDate) public onlyOwner {
        icoEndDate = endDate;
    }
    
    function addTeamAndAdvisoryMembers(address[] members) public onlyOwner 
    {
        uint totalTeamShare = uint(100000000).mul(10**uint(decimals));
        uint oneTeamMemberShare = totalTeamShare.div(members.length);
        for (uint i=0;i<members.length;i++)
        {
            teamMembers[members[i]] = oneTeamMemberShare;
            tokenBalances[owner] = tokenBalances[owner].sub(oneTeamMemberShare);
            tokenBalances[members[i]] = tokenBalances[members[i]].add(oneTeamMemberShare);
            emit Transfer(owner,members[i],oneTeamMemberShare);
        }    
    }
    function addPrivateSaleBuyer(address buyer,uint value) public onlyOwner 
    {
        privateSaleBuyerTokens[buyer] = value;        
    }
    function addPreSaleBuyer(address buyer,uint value) public onlyOwner 
    {
        preSaleBuyerTokens[buyer] = value;
    }
}