/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

pragma solidity ^0.8.0;

contract Insurance{
    mapping(address=>uint256) private accounts;
    mapping(address=>address) private _users;
    
    // address [] _users;
    address private _owner;
    
    constructor() payable{
        _owner = msg.sender;
    }
    modifier onlyAdmin{
        require(_owner==msg.sender,"you are not authorize for the function call");
        _;
    }
    function getUser(address user) public view onlyAdmin returns(bool){
        // require(_owner==msg.sender,"you are not authorize for the function call");
        bool available;
        if(_users[user]==msg.sender){
            available = true;
        }
        else{
            available=false;
        }
        return available;
    }
    function changeOwner(address owner) public onlyAdmin returns(bool){
        // require(_owner==msg.sender,"you are not authorize for the function call");
        _owner= owner;
        return true;
    }
    function depositeAmount(address _user,uint _amount)public payable{
        require(_user == msg.sender, "you are not authorize for the function call");
        require(_amount>0,"please amount greater then 0");
        accounts[_user]=_amount;
        _users[_user]= _user;
    }
    function withdraw(address payable _to,uint256 _amount)public payable  returns(bool){
        require(_users[_to] == msg.sender, "you are not authorize for the function call");
        bool result;
        if(accounts[_to]>0){
            result= _to.send(_amount);
             accounts[_to]-=_amount;
        }
        else{
            result = false;
        }
        return result;
    }
    function transferAmount(address payable _to,uint256 _amount)public payable onlyAdmin returns(bool){
        bool result= _to.send(_amount);
        return result;
    }
    function getAccountBalance(address _account) public view returns(uint256){
        return accounts[_account];
    }
    
}