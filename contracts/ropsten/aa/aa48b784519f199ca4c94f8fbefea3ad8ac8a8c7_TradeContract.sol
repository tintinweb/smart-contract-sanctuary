pragma solidity ^0.5.10;

 import"./Tradetokencoin.sol";


contract TradeContract {
    
    using SafeMath for uint;
  
    Tradetoken public tradetoken;
    
    address payable public Owner;
    uint256 PriceOfToken;
    
    mapping(address => Users) User;
    
    struct Users
    { 
        uint256 NumberOfToken;
        address _address;
    }
    
    constructor (Tradetoken TokenAddress,uint256 CoinPrice) public 
    {
        tradetoken = TokenAddress;   
        PriceOfToken = CoinPrice;
        Owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender==Owner,"onlyOwner can call!");
        _;
    }
    
    event buytoken(address Address, uint256 amount);
    
    function BayToken(uint256 numberoftoken) external payable
    {
                
         uint256 getprice = Ether_To_Token(numberoftoken);
         require(msg.value >= getprice,"you enter less value");
        
        tradetoken.transfer(msg.sender,numberoftoken);
        
        User[msg.sender].NumberOfToken=numberoftoken;
        User[msg.sender]._address=msg.sender;
        
         emit buytoken(msg.sender,numberoftoken);
     
    }
    
    function swap(uint256 _amount) public payable returns(uint256 TokenValue)
    {
        // uint256 Userbalance = jaracoin.balanceOf(msg.sender);
        // if(Userbalance >= _amount)
        
        // {
            // jaracoin.approve(address(this),_amount);
            tradetoken.transferFrom(msg.sender,address(this),_amount);
            
            return _amount;
        // }
        
        // else 
        // {
        //     return 0;
        // }
            
    }
    
    function Ether_To_Token(uint256 NumberOftoken) public view  returns(uint256 Amount)
    {
        uint256 eth = NumberOftoken.mul(PriceOfToken);
        return eth;
    } 
    
    
     function withdrawal(uint256 amount) public onlyOwner {
        
        require(amount <= address(this).balance , "not have Balance");
        require(amount >= 0 , "not have Balance");
        
       
        Owner.transfer(amount);
    }
    
    
    function checkcontractbalance() public view returns(uint256) 
    {
        return address(this).balance;
    }
    function Userbalance() public view returns(uint256) 
    {
        return tradetoken.balanceOf(msg.sender);
    }
    function checkcontracttoken() public view returns(uint256) 
    {
        return tradetoken.balanceOf(address(this));
    }
    
    
}