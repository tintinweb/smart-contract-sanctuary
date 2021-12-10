/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

library SafeMath {
  
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IBEP20 {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MyToken  {
    
        IBEP20 ibep20Token;
        address payable private owner_;
        using SafeMath for uint256;
        address[] public userAddresses;
        uint256 tokenRate=10; 
        uint256 TGEPercentage=10;
        uint256 MonthlyPercentage = 7;
        address [] public WhiteListed;
        struct whiteListedClient{
        bool isListed;
        
        }
         modifier onlyOwner {
        require(msg.sender == owner_);
        _;
    }
        struct Crowdsaleusers {
                uint256 monthlycounter;
                bool onetimetge;
                address useraddress;
                uint256 totalinvesteduserfund;
                uint256 pendingfunds;
                bool isAlreadyexists;
                uint256 releaseTime;

            }

        mapping(address=>Crowdsaleusers) mappingToUser; 
        mapping(address=>whiteListedClient) _WhiteListed; 

    

        constructor(address _ContractAddress) {
              //  ibep20Token = IBEP20(0x94eCc33717f7284a416Cc8dE851Ac93381211658);
                ibep20Token = IBEP20(_ContractAddress);
            }
   
        

    // User can buy Token use this
    function buyToken(uint256 _bnbValue) public payable{

        require(msg.sender != address(0), "Zero address");
        require(_WhiteListed[msg.sender].isListed==true,"Your not whiteListed user");
        require(_bnbValue>=1 && _bnbValue<=3,"Please Enter BNB value Between 1 to 3BNB");

      //  uint256 bnbValue = msg.value;
        uint256 bnbValue = _bnbValue;
        //10% of ammount
        uint256 token = bnbValue*tokenRate;
        // uint256 holdToken = bnbValue - token;

        owner_.transfer(msg.value);
        if ( mappingToUser[msg.sender].isAlreadyexists==true )
        {
              mappingToUser[msg.sender].totalinvesteduserfund += token;
              mappingToUser[msg.sender].pendingfunds+= token;
              mappingToUser[msg.sender].isAlreadyexists= true; 
        }
        else
        {
                 mappingToUser[msg.sender].monthlycounter = 1;
                //  mappingToUser[msg.sender].onetimetge = false;
                 mappingToUser[msg.sender].useraddress = msg.sender;
                 mappingToUser[msg.sender].totalinvesteduserfund = token;
                 mappingToUser[msg.sender].pendingfunds = token;
                 mappingToUser[msg.sender].isAlreadyexists=true;
                 userAddresses.push(msg.sender);
        }
    }

 // Released TGE
    function releasedTGE() public payable
    {
          // https://stackoverflow.com/questions/68310368/how-to-calculate-percentage-in-solidity


      for (uint i=0; i<userAddresses.length; i++) {
             if (mappingToUser[userAddresses[i]].onetimetge == false && mappingToUser[userAddresses[i]].pendingfunds >0 ) {
                     uint256 token= (mappingToUser[userAddresses[i]].totalinvesteduserfund * TGEPercentage)/100;
                     ibep20Token.transfer(userAddresses[i], token * 10 ** 18);
                     mappingToUser[userAddresses[i]].onetimetge=true;
                     mappingToUser[userAddresses[i]].pendingfunds-=token;
                }
            
        }

 }


       // released Monthly 
    function releasedMonthly() public onlyOwner  payable
    {
      for (uint i=0; i<userAddresses.length; i++) {
             if (mappingToUser[userAddresses[i]].monthlycounter <=12 && mappingToUser[userAddresses[i]].pendingfunds >0 ){
                     uint256 token= (mappingToUser[userAddresses[i]].totalinvesteduserfund * MonthlyPercentage)/100;
                     ibep20Token.transfer(userAddresses[i], token * 10 ** 18);
                     mappingToUser[userAddresses[i]].monthlycounter+=1;
                     mappingToUser[userAddresses[i]].pendingfunds-=token;
            }
        }
    } 

    //clear all pending funds once
    // Released all pending funds
    function releasedAllPendingFunds() public onlyOwner payable
    {
          // https://stackoverflow.com/questions/68310368/how-to-calculate-percentage-in-solidity
      for (uint i=0; i<userAddresses.length; i++) {

               if(mappingToUser[userAddresses[i]].pendingfunds > 0 ) 
               {
                uint256 token= mappingToUser[userAddresses[i]].pendingfunds;
                ibep20Token.transfer(userAddresses[i], token * 10 ** 18);
                mappingToUser[userAddresses[i]].pendingfunds-=token; 
               }
            
            
        }

 }

    function releasedMonthlyByUser() public  payable
    {

           if(mappingToUser[msg.sender].releaseTime==0){
                 uint256 token= (mappingToUser[msg.sender].totalinvesteduserfund * MonthlyPercentage)/100;
                     ibep20Token.transfer(msg.sender, token * 10 ** 18);
                     mappingToUser[msg.sender].monthlycounter+=1;
                     mappingToUser[msg.sender].releaseTime=block.timestamp;
                     mappingToUser[msg.sender].pendingfunds-=token;

           }else{
               require(( block.timestamp >= mappingToUser[msg.sender].releaseTime + 28 * 1 days) && mappingToUser[msg.sender].releaseTime!=0 ,"You have alreaday claim this month Token.Please try it again next month.");
             if (mappingToUser[msg.sender].monthlycounter <=12 && mappingToUser[msg.sender].pendingfunds >0 ){
                     uint256 token= (mappingToUser[msg.sender].totalinvesteduserfund * MonthlyPercentage)/100;
                     ibep20Token.transfer(msg.sender, token * 10 ** 18);
                     mappingToUser[msg.sender].monthlycounter+=1;
                     mappingToUser[msg.sender].releaseTime=block.timestamp;
                     mappingToUser[msg.sender].pendingfunds-=token;
            }
           }
    
    } 



    function whiteListed(address _clientAddress) public onlyOwner virtual returns(bool){
         return _WhiteListed[_clientAddress].isListed=true;
         
    }

    // Get function to find pending balance for user address 
     function checkPendingBalance() public view virtual returns(uint256){
        return  mappingToUser[msg.sender].pendingfunds;
    }
    // get function to find not of monthly payment done for user address 

    // set pause functions
    // set owner called functions 
    // Apply given supply and others tokens info 
    

    // get function to find the totalinvestment balanace of users
    function totalInvestmentBalanace() public view virtual returns(uint256){
        return mappingToUser[msg.sender].totalinvesteduserfund;
    }

    function changeTGEPercentage(uint256 _TGEPercentage) public {
              TGEPercentage = _TGEPercentage;
        }

    function changeMonthlyPercentage(uint256 _MonthlyPercentage) public onlyOwner {
            MonthlyPercentage = _MonthlyPercentage;
        }

    // and give edit function , get rate function  
    function changeTokenRate(uint256 _tokenRate) public onlyOwner{
            tokenRate = _tokenRate;
        }
    // Define softcap and hardcap

    // Define token rate Price is 1 bnb = 10.000 tokens. Make it initialze via contructor 
}