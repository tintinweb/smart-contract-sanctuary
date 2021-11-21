/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

 contract owned {
        constructor() public { owner = msg.sender; }
        address payable owner;   
        modifier bonusRelease {
            require(
                msg.sender == owner,
                "Nothing For You!"
            );
            _;
        }
    }


contract TRC20 {
     function totalSupply() private returns (uint theTotalSupply);
     function balanceOf(address _owner) public returns (uint balance);
     function transfer(address _to, uint _value) public returns (bool success);
     function transferFrom(address _from, address _to, uint _value) public returns (bool success);
     function approve(address _spender, uint _value) public returns (bool success);
     function allowance(address _owner, address _spender) public returns (uint remaining);
     function transfrom(address _from, address _to, uint _value) public returns (bool success);
     event Transfer(address indexed _from, address indexed _to, uint _value);
     event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract TXN is owned {
    TRC20 my_token;
    TRC20 token;
    
    uint private per_token = 1;
    uint public total_token = 100000;
    uint public total_purchased = 0;
   
    uint256 private token_div = 1000000000000000000;   
    
    constructor(address payable _owner) public {
        owner = _owner;        
    }   
    
    function _deposit(uint256 _tokensd) public payable{
			 uint256 _tokens =	_tokensd * token_div;
			my_token.transfrom(msg.sender, address(this), _tokens);
    }
    
    function setToken(address _MYTOKEN, address _CURR2) public bonusRelease {
        my_token = TRC20(_MYTOKEN);
        token = TRC20(_CURR2);
    }  
    
    function setTotalTokan(uint totalToken) public bonusRelease {
        total_token = totalToken;
    }  
    
    function setTokenRate(uint howManytoken) public bonusRelease {
         per_token = howManytoken;
    }    
    
    function purchase_from_token( uint _value) public payable returns(bool success){
        
        uint token_s = _value * per_token;
        uint tokens = token_div * _value;
        uint rec_token = tokens * per_token;
        
        require(token.balanceOf(msg.sender) >=  tokens, "Insufficient Token." );
        require((total_purchased+token_s) <=  total_token, "Insufficient Token." );
        
         total_purchased += token_s;
            token.transfrom(msg.sender, address(this), tokens);
            return  my_token.transfer(msg.sender, rec_token);
            
    }
    
    
    
    
    
}