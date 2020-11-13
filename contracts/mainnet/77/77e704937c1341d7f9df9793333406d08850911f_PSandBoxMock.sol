pragma experimental ABIEncoderV2;

interface ERC20 {
    function totalSupply() external view returns(uint supply);

    function balanceOf(address _owner) external view returns(uint balance);

    function transfer(address _to, uint _value) external returns(bool success);

    function transferFrom(address _from, address _to, uint _value) external returns(bool success);

    function approve(address _spender, uint _value) external returns(bool success);

    function allowance(address _owner, address _spender) external view returns(uint remaining);

    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}



contract PSandBoxMock{

    //globals
    mapping (address => mapping (address => uint256)) depositBalances;
    address ETH_TOKEN_ADDRESS  = address(0x0);
    address payable owner;
    address [6] stakableTokensList;
    string [6] stakableTokensByNameList;
    
    
    modifier onlyOwner() {
        if (msg.sender == owner) _;
    }
    
  
  constructor() public payable {
      
        owner= msg.sender;
        
        //Dummy data
        populateData();
         
        
  }
  
    function populateData() public{
        stakableTokensByNameList = ["WETH", "DAI", "USDC", "PLEX", "PLEXUSDCLP", "PLEXETHLP"];
     
         
         
         stakableTokensList = [0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 0x6B175474E89094C44Da98b954EedeAC495271d0F, 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x0391D2021f89DC339F60Fff84546EA23E337750f, 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 0xa0246c9032bC3A600820415aE600c6388619A14D]; 
        
       
    }


   function deposit(address tokenAddress, uint256 amount) public returns (bool){
       
        ERC20 thisToken = ERC20(tokenAddress);
        require(thisToken.transferFrom(msg.sender, address(this), amount), "Not enough tokens to transferFrom or no approval");
        
        depositBalances[msg.sender][tokenAddress] = depositBalances[msg.sender][tokenAddress]  + amount;
        
        return true;
   }

   function withdraw(address tokenAddress, uint256 amount) public returns(bool){
       
        ERC20 thisToken = ERC20(tokenAddress);
        require(thisToken.balanceOf(msg.sender) >= amount, "You do not have enough tokens to withdraw in balanceOf");
        
        depositBalances[msg.sender][tokenAddress] = depositBalances[msg.sender][tokenAddress]  - amount;
        
        require(thisToken.transfer(msg.sender, amount), "You dont have enough tokens inside this contract to withdraw from deposits");
       
        return true;
        
   }
   
    function getStakableTokens() view public  returns (address[6] memory, string[6] memory){
        
        return (stakableTokensList, stakableTokensByNameList);
        
    }
   
   function getComposition() view public returns(uint256[] memory compAmounts, address[] memory compTokens, string[] memory compNames){
      
       uint256[] memory compAmounts1;
       address[] memory compTokens1;
       string[] memory compNames1;
       
       compAmounts[0] =3000402303203202;
       compAmounts[1]= 3000402303203202;
       compAmounts[2] = 3000402303203202;
       
       compNames[0] = "FARM";
       compNames[1] = "Picke";
       compNames[2] = "YEARN";
       
       return (compAmounts1, compTokens1, compNames1);
       
   }

   function getAPY(address tokenAddress) public view returns(uint256){
    
    return random(uint(tokenAddress));
    
   }
   

   function getTotalValueLockedAggregated() public view returns (uint256){
      return 770567001;
   }

   function getTotalValueLockedInternalByToken(address tokenAddress) public view returns (uint256){
    return 40203 + random(3);
   }
   function getTotalValueLockedInternal() public view returns (uint256){
    return 5790567;
   }
   function timeLeftInEpoch() public view returns (uint256){
        random(2);
   }

   function getAmountStakedByUser(address tokenAddress, address userAddress) public view returns(uint256){
        return depositBalances[userAddress][tokenAddress];
   }
   function getThisTokenPrice() view public returns(uint256){
        return random(1);
   }
   
   function getUserCurrentReward(address userAddress) view public returns(uint256){
        return random(uint256(userAddress));
   }
   
   function getUserPotentialReward(address userAddress) view public returns(uint256){
        return random(7);
   }
   
 
   
   function random(uint256 nonce) internal view returns (uint) {
    
    uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % 900;
    randomnumber = randomnumber + 100;
    
    return randomnumber;
}


    function getUserWalletBalance(address userAddress, address tokenAddress) public returns (uint256){
        ERC20 token = ERC20(tokenAddress);
        return token.balanceOf(userAddress);
        
    }

    function adminWithdrawTokens(address token, uint amount, address payable destination) public onlyOwner returns(bool) {

         if (address(token) == ETH_TOKEN_ADDRESS) {
             destination.transfer(amount);
         }
         else {
             ERC20 tokenToken = ERC20(token);
             require(tokenToken.transfer(destination, amount));
         }

         return true;
     }



    function kill() virtual public onlyOwner {
       
            selfdestruct(owner);
         
    }

   
  
}