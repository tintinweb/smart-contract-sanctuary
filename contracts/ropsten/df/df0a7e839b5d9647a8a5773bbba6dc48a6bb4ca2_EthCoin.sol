/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity 0.6.0;

contract EthCoin{
    
    string public name;
    string public symbol;
    uint8 public decimals = 6;
    uint256 public totalSupply;
    
    
    uint256 initialSupply = 510000000;
    string tokenName = 'SILCOIN';
    string tokenSymbol = 'SILC';
    
    
     struct User {
        bool exists;
        uint256 userId;
        address userAddress;
		uint256 silWallet;
	}
	
	string private pkey;
	
    mapping (address => User) public alluser;
    
    
     event Transfer(address indexed sender, address indexed reciver, uint256 value);
    
    
    constructor(string memory setkey) public {
        
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        name = tokenName;                                 
        symbol = tokenSymbol;  
        pkey=setkey;
        
        User memory owner = User({
            exists:true,
		    userId:1,
		    userAddress:msg.sender,
		    silWallet:totalSupply
		});
		
       alluser[msg.sender] = owner;
    }
    
    
    function register(uint256 uId) public{
        
		require(alluser[msg.sender].exists != true,"Address exists");
	
		User memory user = User({
		    exists:true,
		    userId:uId,
		    userAddress:msg.sender,
		    silWallet:0
		});
		
       alluser[msg.sender] = user;
	 
    }
    
    
     function transferSilCoin(string memory skey,uint256 value,address _to) public{
        
             require(keccak256(bytes(pkey)) == keccak256(bytes(skey)),'invalid key');
         
             require(alluser[msg.sender].userAddress != address(0x0),'invalid address');
             require(alluser[msg.sender].exists == true,'sender not exists');
             require(alluser[msg.sender].silWallet >=value,'sender balence less');
             
           
             require(alluser[_to].userAddress != address(0x0),'invalid address');
             require(alluser[_to].exists == true,'reciver not exists');
             
       
             alluser[msg.sender].silWallet-=value;

             alluser[_to].silWallet+=value;
             
              emit Transfer(msg.sender, _to, value);
             
        
    }
    
         function transferSilCoinByAddr(uint256 value,address _to) public{
        
             require(msg.sender != address(0x0),'invalid address');
             
              emit Transfer(msg.sender, _to, value);
             
        
    }
    
}