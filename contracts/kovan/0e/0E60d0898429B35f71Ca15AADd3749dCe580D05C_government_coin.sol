/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity ^0.5.0;



       contract government_coin  // Government to Student

       {

        //string public student_name;  // student name
        //uint  public balance; // to check balances in the token stuedent account
        address public government_account;
        
        event record (address student_name, uint balance_event , string student_name1);
        
        //uint price = 1  ;  // value of token
        
        mapping (address => uint) public balance;
        
        mapping (address => string) public names;
        
        string token_name = "EDU" ;
        string tokenSymbol = "$$";
        uint gov_initial_supply = 200;
        
       
        constructor () public 
        {
        government_account = msg.sender; // government agency
        
        balance[government_account] = gov_initial_supply;
        }
        
        
        function student_name (address student_address, string memory name) public
        {
            names[student_address] = name;
        }
        
       
        // function modifier onlyOwner 
        // {
        //     require(msg.sender == owner);
        // _;
        // }
        
        // function mint(address receiver, uint , initial_supply) public onlyOwner  //only government can mint the tokens
        // {
        //     require(msg.sender == owner);
            
        //     _mint(recipient, initial_supply);
         
            
            
        // }
        
    
        
        function transfer (address student, uint token_transfer) public  
        {
            balance[student] = balance[student]+ token_transfer; 
            balance[government_account] = balance[government_account] - token_transfer;
            
            emit record ( student, balance[student] , names[student]);
        }
        
        // function _getTotalSupply(address addr) public view returns(uint256) 
        // {
        //     gov_initial_supply = initialSupply * (1);
        //     return gov_initial_supply;
        // }
        

        
        function balances (address _account) public view returns (uint) 
        {
            //balance = address(this).balance ;
            
            
            return balance[_account];
        }
        
        
        // function student_request (uint token_transfer)
        // {
        //     require(msg.sender)
            
            
            
        // }
        
        
        
        // function government (uint token_transfer)
        // {
        //     balances[sender] -= token_transfer; 
        // }
        
        
      function() external payable
      {   }
      
       }