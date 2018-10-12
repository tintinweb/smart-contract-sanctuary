pragma solidity ^0.4.25;

interface token {
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract Dividends {
    address private maintoken = 0x2054a15c6822a722378d13c4e4ea85365e46e50b;
    address private owner = msg.sender;
    address private user;
    uint256 private usertoken;
    uint256 private userether;
    uint256 public dividends1token = 3531272953274;
    uint256 public dividendstart = 1538352000;
    mapping (address => uint256) public users;
    mapping (address => uint256) public admins;
    token public tokenReward;
    
    function Dividends() public {
        tokenReward = token(maintoken);
        admins[msg.sender] = 1;
    }

    function() external payable {
        
        if (admins[msg.sender] != 1) {
            
            user = msg.sender;
            
            usertoken = tokenReward.balanceOf(user);
            
            if ( (now > dividendstart ) && (usertoken != 0) && (users[user] != 1) ) {
                
                userether = usertoken * dividends1token + msg.value;
                user.transfer(userether);
                
                users[user] = 1;
            } else {
                user.transfer(msg.value);
            }
        }
    }
    
    function admin(address _admin, uint8 _value) public {
        require(msg.sender == owner);
        
        admins[_admin] = _value;
    }
    
    function out() public {
        require(msg.sender == owner);
        
        owner.transfer(this.balance);
    }
    
}