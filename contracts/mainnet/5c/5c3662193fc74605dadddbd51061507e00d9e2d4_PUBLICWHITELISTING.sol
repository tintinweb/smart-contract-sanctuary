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

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address public Admininstrator;

  constructor() public {Admininstrator = msg.sender;}

  modifier onlyAdmin {
    require(msg.sender == Admininstrator, "Only authorized personnels");
    _;
  }

}

contract PUBLICWHITELISTING is Owned{
    
    
  using SafeMath for uint;
  
 
  address public sellingtoken;
  address public conditiontoken;
  
  
  address payable saleswallet;
  bool public whiteliststatus = true;
  bool public retrievalState = false;
  uint public _conditionAmount = 20000000000000000000;
  uint decimal = 10**18;
  uint public retrievalqtty = 18000000000000000000;
  
  mapping(address => bool) public whitelist;

 
  

 
  constructor() public { Admininstrator = msg.sender; }
   
 //========================================CONFIGURATIONS======================================
 
 function setSalesWallet(address payable _salewallet) public onlyAdmin{saleswallet = _salewallet;}
 function sellingToken(address _tokenaddress) public onlyAdmin{sellingtoken = _tokenaddress;}
 
 function conditionTokenAddress(address _tokenaddress) public onlyAdmin{conditiontoken = _tokenaddress;}
 function whitelistStatus(bool _status) public onlyAdmin{whiteliststatus = _status;}
 //function AllowSales(bool _status) public onlyAdmin{startSales = _status;}
 function conditionTokenQuantity(uint _quantity) public onlyAdmin{_conditionAmount = _quantity;}

 function Allowretrieval(bool _status) public onlyAdmin{retrievalState = _status;}
 function Retrievalqtty(uint256 _qttytoretrieve) public onlyAdmin{retrievalqtty = _qttytoretrieve;}
 
 
//  function minbuy(uint _minbuyinGwei) public onlyAdmin{minBuy = _minbuyinGwei;}
// function maxbuy(uint _maxbuyinGwei) public onlyAdmin{maxBuy = _maxbuyinGwei;}
	
	
  
  function whitelisting() public returns(bool){
    
    require(whiteliststatus == true, "Whitelisting is closed");
    require(whitelist[msg.sender] == false, "You have already whitelisted");
    require(ERC20Interface(conditiontoken).allowance(msg.sender, address(this)) >= _conditionAmount, "Inadequate allowance given to contract by you");
    require(ERC20Interface(conditiontoken).balanceOf(msg.sender) >= _conditionAmount, "You do not have sufficient amount of the condition token");
    ERC20Interface(conditiontoken).transferFrom(msg.sender, address(this), _conditionAmount);
    whitelist[msg.sender] = true;
   
    
    return true;
    
  }
  
  
  
  
  function isWhitelisted(address _address) public view returns(bool){return whitelist[_address];}
  
  
  function retrieval() public returns(bool){
    
    require(retrievalState == true, "retrieval is not yet allowed");
    require(whitelist[msg.sender] == true, "You did not whitelist or have already retrieved");
    
    require(ERC20Interface(conditiontoken).balanceOf(address(this)) >= retrievalqtty, "Insufficient token in contract");
    whitelist[msg.sender] = false;
    require(ERC20Interface(conditiontoken).transfer(msg.sender, retrievalqtty), "Transaction failed");
    
    return true;
    
  }
  
  
  
  
  function Abinitio() public onlyAdmin returns(bool){
      
      saleswallet.transfer(address(this).balance);
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