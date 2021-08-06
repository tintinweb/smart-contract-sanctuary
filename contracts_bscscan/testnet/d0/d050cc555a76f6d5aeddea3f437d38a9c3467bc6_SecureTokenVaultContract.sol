/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

pragma solidity ^0.8.4;

/*
 * SPDX-License-Identifier: MIT

todo: 

AIM 
- send transaction containing addresses[] and amounts[] to this contract
- if address balance exists, add new amount to it
- when a user withdraws, set amount to zero

//deposit token
//function ownerSetAllocation(addresses[], amounts[]) { require owner}
//function ownerWithdrawTokenBalance(sender)
//function ownerWithdrawEthBalance(sender)

//function userWithdrawTokens(sender) OK
//function publicGetBalance(address)



//track total rewards paid


*/

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}

contract SecureTokenVaultContract {
    IERC20Token public tokenContract;  // the token being Earned => used in vaultTokenSetup
    uint256 public totalRewardsPaid;  //totalRewardsPaid out by this contract (withdrawn by users)
    uint256 public totalRewardsAllocated; //totalRewardsAllocated by this contract 

    uint public vaultStatus; //0=inactive, 1=active
    
    //address payable owner;
    address public owner;
    
    mapping (uint=> address ) public rewardHolders; //incremented for each address , add check if exsts
    mapping (address => uint) public rewardBalance; //incremented for each transaciont
    mapping (address => uint256) public rewardHoldersEarnings;//v3
    

    event Earned(address holder, uint256 amount);
    event HoldersCount(uint256 _totalHolders);
    
    event YouWithdraw(address holder, uint256 amount);
    event CurrentBalance(address holder, uint256 amount);
    

    //Works
    // attempt to set some vars on contract creation
    constructor () {
        owner  = msg.sender;
        vaultStatus=0; //0=inactive, 1=active
        //tokenContract = '0xe5202ef5bef816beb34fec953138b320e1b7b79f'; // here ideally to save time
    }
    
    

    function vaultTokenSetup(IERC20Token _tokenContract) public {
       require(msg.sender == owner, "You do not have the required permission.");  
        //owner = msg.sender;
        tokenContract = _tokenContract; //set the contract address of default token
    }
    
    
    function UpdatevaultStatus(uint _vaultStatus) public {
       require(msg.sender == owner, "You do not have the required permission.");  
       vaultStatus=_vaultStatus;
    }
    
    // Guards against integer overflows
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }
    
   
     
    // RECEIVE BALANCE UPDATES
    function ownerSetAllocation(address[] calldata addresses, uint256[] calldata amounts) public {
        require(vaultStatus == 1); //The presale must be active
        
        
        for(uint i = 0; i < addresses.length; i++) {

            //do something addresses[i], amounts[i]
            address userAddress = addresses[i];
            uint256 addBalance = amounts[i];
            rewardBalance[userAddress] += addBalance;
            rewardHoldersEarnings[userAddress] += addBalance;
            totalRewardsAllocated += addBalance;
            
            emit CurrentBalance(userAddress, rewardBalance[userAddress]);

        }
        
        
        
    }

    
    
    
    
    //RETURN UNUSED TOKENS TO OWNER
    function ownerWithdrawTokenBalance() public {
        require(msg.sender == owner, "You do not have the required permission.");
        tokenContract.transfer(owner, tokenContract.balanceOf(address(this)));
    }
    

    //RETURN UNUSED BNB TO OWNER (IN CASE OF MISTAKENLY SENT BNB)
    function ownerWithdrawEthBalance() public payable {
        require(msg.sender == owner, "You do not have the required permission.");  
        payable(owner).transfer(address(this).balance);
  }
    
    
       //LET USER WITHDRAW TOKENS
    function userWithdrawTokens() public  {
        require(vaultStatus == 1);
    
        //make sure the user has a balance greater than zero
        require(rewardBalance[msg.sender] > 0, "User balance is insufficient.");
        uint256 withdrawAmount =  rewardBalance[msg.sender]; //withdraw the full balance of this user
        
        //ensure the transfer is successful
        require(tokenContract.transfer(msg.sender, withdrawAmount),"Could not successfully transfer the tokens."); 

        rewardBalance[msg.sender] = 0; // set the users balance to zero
        totalRewardsAllocated += withdrawAmount;
                
        emit YouWithdraw(msg.sender,withdrawAmount);
    }

           
           //LET ANYONE CHECK BALANCE
           // may not need this function
    function publicGetBalance(address userAddress) public returns (uint256 userBalance) {
        userBalance=rewardBalance[userAddress];//current balance of this address   
        emit CurrentBalance(msg.sender,userBalance);        
        return userBalance;
    }
            
   
}