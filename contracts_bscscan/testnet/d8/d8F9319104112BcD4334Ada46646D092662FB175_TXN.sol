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


library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

   
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
    
    using SafeMath for uint256;
   
    TRC20 my_token;
    TRC20 token;
    
    uint private per_token = 1;
    uint public total_token = 100000;
    uint public total_purchased = 0;
   
    uint256 private token_div = 1000000;   
    
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
        
        uint token_s = SafeMath.mul(_value , per_token);
        uint tokens = SafeMath.mul(token_div , _value);
        uint rec_token = SafeMath.mul(tokens , per_token);
        
        require(token.balanceOf(msg.sender) >=  tokens, "Insufficient Token." );
        require((total_purchased+token_s) <=  total_token, "Insufficient Token." );
        
        total_purchased = SafeMath.add(total_purchased,total_token);
        
        token.transfrom(msg.sender, address(this), tokens);
        return  my_token.transfer(msg.sender, rec_token);
            
    }
    
    
    
    
    
}