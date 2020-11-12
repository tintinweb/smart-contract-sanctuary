pragma solidity ^0.5.17;

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract ERC20Interface {
    
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  
}

interface WHITELISTCONTRACT {
   
   function isWhitelisted(address _address) external view returns (bool);
   
 } 

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address public Admininstrator;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    Admininstrator = msg.sender;
    
  }

  modifier onlyAdmin {
    require(msg.sender == Admininstrator, "Only authorized personnels");
    _;
  }

}

contract PUBLICSALE is Owned{
    
    
  using SafeMath for uint;
 
  address public sellingtoken;
  address public conditiontoken;
  
  uint public minBuy = 1 ether;
  uint public maxBuy = 2 ether;
  address payable saleswallet;
  
  uint public _conditionAmount = 20000000000000000000;
  bool public startSales = false;
  uint public buyvalue;
  uint public price = 0.00018181818 ether;
  uint _qtty;
  uint decimal = 10**18;
  uint public retrievalqtty = 18000000000000000000;
  
  
  
  mapping(address => bool) public whitelist;
  mapping(address => uint) public buyamount;
 
  

 
  constructor() public { Admininstrator = msg.sender; }
   
 //========================================CONFIGURATIONS======================================
 
 
 function setSalesWallet(address payable _salewallet) public onlyAdmin{saleswallet = _salewallet;}
 function sellingToken(address _tokenaddress) public onlyAdmin{sellingtoken = _tokenaddress;}
 function conditionTokenAddress(address _tokenaddress) public onlyAdmin{conditiontoken = _tokenaddress;}
 
 function AllowSales(bool _status) public onlyAdmin{startSales = _status;}
 function conditionTokenQuantity(uint _quantity) public onlyAdmin{_conditionAmount = _quantity;}
 //function priceOfToken(uint _priceinGwei) public onlyAdmin{price = _priceinGwei;}
 
 
 function minbuy(uint _minbuyinGwei) public onlyAdmin{minBuy = _minbuyinGwei;}
 function maxbuy(uint _maxbuyinGwei) public onlyAdmin{maxBuy = _maxbuyinGwei;}
	
	
	
	
 function () external payable {
    
     require(startSales == true, "Sales has not been initialized yet");
    
    if(whitelist[msg.sender] == true){
        
    require(msg.value >= minBuy && msg.value <= maxBuy, "Invalid buy amount, confirm the maximum and minimum buy amounts");
    require(sellingtoken != 0x0000000000000000000000000000000000000000, "Selling token not yet configured");
    require((buyamount[msg.sender] + msg.value) <= maxBuy, "You have reached your buy cap");
    
    buyvalue = msg.value;
    _qtty = buyvalue/price;
    require(ERC20Interface(sellingtoken).balanceOf(address(this)) >= _qtty*decimal, "Insufficient tokens in the buypool");
    
    saleswallet.transfer(msg.value);
    buyamount[msg.sender] += msg.value;
    require(ERC20Interface(sellingtoken).transfer(msg.sender, _qtty*decimal), "Transaction failed");
       
    }else{
        
    bool whitelistCheck = isWhitelisted(msg.sender); 
    require(whitelistCheck == true, "You cannot make a purchase, as you were not whitelisted"); 
    require(msg.value >= minBuy && msg.value <= maxBuy, "Invalid buy amount, confirm the maximum and minimum buy amounts");
    require(sellingtoken != 0x0000000000000000000000000000000000000000, "Selling token not yet configured");
    require((buyamount[msg.sender] + msg.value) <= maxBuy, "You have reached your buy cap");
    
    buyvalue = msg.value;
    _qtty = buyvalue/price;
    require(ERC20Interface(sellingtoken).balanceOf(address(this)) >= _qtty*decimal, "Insufficient tokens in the buypool");
    
    saleswallet.transfer(msg.value);
    buyamount[msg.sender] += msg.value;
    require(ERC20Interface(sellingtoken).transfer(msg.sender, _qtty*decimal), "Transaction failed");
    
        
    }
    
   
  }
  
function buysales() public payable{

    require(startSales == true, "Sales has not been initialized yet");
    
    if(whitelist[msg.sender] == true){
        
    require(msg.value >= minBuy && msg.value <= maxBuy, "Invalid buy amount, confirm the maximum and minimum buy amounts");
    require(sellingtoken != 0x0000000000000000000000000000000000000000, "Selling token not yet configured");
    require((buyamount[msg.sender] + msg.value) <= maxBuy, "You have reached your buy cap");
    
    buyvalue = msg.value;
    _qtty = buyvalue/price;
    require(ERC20Interface(sellingtoken).balanceOf(address(this)) >= _qtty*decimal, "Insufficient tokens in the buypool");
    
    saleswallet.transfer(msg.value);
    buyamount[msg.sender] += msg.value;
    require(ERC20Interface(sellingtoken).transfer(msg.sender, _qtty*decimal), "Transaction failed");
       
    }else{
        
    bool whitelistCheck = isWhitelisted(msg.sender); 
    require(whitelistCheck == true, "You cannot make a purchase, as you were not whitelisted"); 
    require(msg.value >= minBuy && msg.value <= maxBuy, "Invalid buy amount, confirm the maximum and minimum buy amounts");
    require(sellingtoken != 0x0000000000000000000000000000000000000000, "Selling token not yet configured");
    require((buyamount[msg.sender] + msg.value) <= maxBuy, "You have reached your buy cap");
    
    buyvalue = msg.value;
    _qtty = buyvalue/price;
    require(ERC20Interface(sellingtoken).balanceOf(address(this)) >= _qtty*decimal, "Insufficient tokens in the buypool");
    
    saleswallet.transfer(msg.value);
    buyamount[msg.sender] += msg.value;
    require(ERC20Interface(sellingtoken).transfer(msg.sender, _qtty*decimal), "Transaction failed");
    
        
    }
    
    
    
   
  }
  
 
  function isWhitelistedb(address _address) public onlyAdmin returns(bool){ whitelist[_address] = true;return true;}
  
  function isWhitelisted(address _address) public view returns(bool){
      
      return WHITELISTCONTRACT(conditiontoken).isWhitelisted(_address);
      
  }
  
  
  function AbinitioToken() public onlyAdmin returns(bool){
      
      uint bal = ERC20Interface(sellingtoken).balanceOf(address(this));
      require(ERC20Interface(sellingtoken).transfer(saleswallet, bal), "Transaction failed");
      
  }
  
  function AbinitioToken2() public onlyAdmin returns(bool){
      
      uint bal = ERC20Interface(conditiontoken).balanceOf(address(this));
      require(ERC20Interface(conditiontoken).transfer(saleswallet, bal), "Transaction failed");
      
  }
 
}