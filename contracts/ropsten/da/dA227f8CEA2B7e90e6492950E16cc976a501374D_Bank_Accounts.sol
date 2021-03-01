/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity ^0.7.4;

/*
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
0x617F2E2fD72FD9D5503197092aC168c91465E7f2
0x17F6AD8Ef982297579C203069C1DbfFE4348c372
0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678
0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7
0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C
0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC
0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c
0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB
0x583031D1113aD414F02576BD6afaBfb302140225
0xdD870fA1b7C4700F2BD7f44238821C26f7392148
*/


struct Account{
    address account_holder;
    uint account_balance;
}

contract Bank_Accounts 
{
    
    /*Need to specify that Bank_Accounts uses the interface Bank.*/
    address public BANK_OWNER;
    uint number_of_accounts;
    
    
    bool allow=false;
    bool vote1;
    bool vote2;
    bool vote3;
    
    
    constructor()
    { 
        BANK_OWNER = msg.sender;

        number_of_accounts = 0;
        accountLedger.push();
    }
    
    Account[] accountLedger;
    mapping(address => uint256) public id;
    
    modifier onlyBank{
        require (msg.sender == BANK_OWNER);
        _;
    }
    
    modifier onlyOwner1{
        require (msg.sender == accountLedger[1].account_holder);
        _;
    }
    
    modifier onlyOwner2{
        require (msg.sender == accountLedger[2].account_holder);
        _;
    }
    
    modifier onlyOwner3{
        require (msg.sender == accountLedger[3].account_holder);
        _;
    }


    function create_new_account(address user0) public onlyBank
    {
        require(msg.sender == BANK_OWNER);
        require(id[user0] == 0);
        require(number_of_accounts < 3);
        
        number_of_accounts += 1;
        id[user0] = number_of_accounts;
      
        accountLedger.push();
 
        accountLedger[ number_of_accounts ].account_holder = user0;
        accountLedger[ number_of_accounts ].account_balance = 500;
    }
    
    function transfer_funds(address receiver, uint amount) public 
    {
        /*Necessary to include since cannot use hasAccount modifier*/
        require(allow==true);
        require( id[msg.sender] > 0);
        require( id[msg.sender] <= number_of_accounts);
        
        require( id[receiver] > 0);
        require( id[receiver] <= number_of_accounts);
        
        require(accountLedger[ id[msg.sender] ].account_balance >= amount);

        accountLedger[ id[msg.sender] ].account_balance -= amount;
        accountLedger[ id[receiver] ].account_balance += amount;
        allow = false;
        vote1 = false;
        vote2 = false;
        vote3 = false;
    }
    
    function view_account_balance(uint256 account) public view  returns(uint amt)
    {
        require( account > 0);
        require( account <= number_of_accounts);
        
        amt = accountLedger[ account ].account_balance;
        return amt;
    }
    
    function vote_1(bool vote11) public onlyOwner1
    {
        vote1=vote11;
        Check();
    }
    
    function vote_2(bool vote22) public onlyOwner2
    {
        vote2=vote22;
        Check();
    }
    
    function vote_3(bool vote33) public onlyOwner3
    {
        vote3=vote33;
        Check();
    }
    function Check() private
    {
        if((vote1==true && vote2 == true) || (vote1 ==true && vote3 == true) || (vote2==true && vote3==true))
        {
            allow = true;
        }
    }
    
    function Final_vote() public view returns (bool){
        return allow;
    }
    
}