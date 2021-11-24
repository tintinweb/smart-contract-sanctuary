/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

pragma solidity 0.5.17;

contract user {
    
    mapping(address => address) private _user;
    
    uint256 private _userCnt;
    
    constructor() public {
        _userCnt = 0;
    }
    
    event registered(address invitee ,address inviter);
    
    function register(address invitee,address inviter) public {
        
        require(invitee != address(0));
        //require(inviter != address(0));
        
        if( _user[invitee] == address(0)){
            
            if(inviter == address(0)){
                inviter = invitee;
            }
            
            _user[invitee] = inviter;
        
            _userCnt += 1;
        
            emit registered(invitee,inviter);  
        }
        else{
            require(false, "User already registered");
        }
        
    }
    
    
    function getUserCnt() public view returns(uint256 userCnt){
        return _userCnt;
    }
    
    
    function getInviter(address invitee) view public returns(address inviter){
        return _user[invitee];
    }
    
}