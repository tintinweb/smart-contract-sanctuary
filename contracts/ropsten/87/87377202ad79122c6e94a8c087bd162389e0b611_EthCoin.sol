/**
 *Submitted for verification at Etherscan.io on 2021-03-13
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
        uint256 userId;
        address userAddress;
		uint256 silWallet;
	}
	 uint uidCout=1;
	
	string private pkey;
    
    mapping (address => uint256) public balanceOf;
    mapping (uint256 => User) public alluser;
    
    
     event Transfer(address indexed sender, address indexed reciver, uint256 value);
    
    
    constructor(string memory setkey) public {
        
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;               
        name = tokenName;                                 
        symbol = tokenSymbol;  
        pkey=setkey;
        
        User memory owner = User({
		    userId:uidCout,
		    userAddress:msg.sender,
		    silWallet:totalSupply
		});
		
       alluser[uidCout] = owner;
    }
    
    
    function register() public{
         uidCout++;

		User memory user = User({
		    userId:uidCout,
		    userAddress:msg.sender,
		    silWallet:0
		});
		
       alluser[uidCout] = user;
       balanceOf[msg.sender]=0;
	 
    }
    
    
     function transferSilCoin(string memory skey,uint256 value,uint256 sid,uint256 rid) public{
        
        if(keccak256(bytes(pkey)) == keccak256(bytes(skey))){
            if(alluser[sid].userId==sid){
                 require(alluser[sid].userAddress != address(0x0));
                 require(alluser[sid].silWallet >=value);
                 
                 require(alluser[rid].userId == rid);
                 require(alluser[rid].userAddress != address(0x0));
                 
                 balanceOf[alluser[sid].userAddress] -= value;  
                 alluser[sid].silWallet-=value;
                 
                 balanceOf[alluser[rid].userAddress] += value;  
                 alluser[rid].silWallet+=value;
                 
                  emit Transfer(alluser[sid].userAddress, alluser[rid].userAddress, value);
                 
            }
        }
        
    }
    
}