/**
 *Submitted for verification at Etherscan.io on 2020-08-17
*/

/*

Smart Contract was developed by nodeberry.com for cubebit business solutions.

*/



pragma solidity ^0.7.0;

contract AdcubeContract1 {
    
    constructor(){
        owner = msg.sender;
    }
    
    uint256 public price = 50000000000000000;
    uint256 public spillover = 3880000000000000;
    uint256 public referralBonus = 5000000000000000;
    address public owner;
    
    uint256 public totalUsers = 0;
    uint256 public userAccounts = 0;
    
    struct User{
        address referrer;
        uint256 totalAccounts;
        bool active;
        mapping(uint256 => Account) accounts;
    }
    
    struct UserDetails{
        string fname;
        string lname;
        string username;
        string country;
        string location;
        bool show;
    }
    
    struct Account {
        bool active;
        address[] uplines;
        address[] downlines;
    }
    
    mapping(address => User) public users;
    
    mapping (address => UserDetails) public details;
    
    event Recieved(address,uint);
    
    event Referral(address,uint);
    
    event LevelBonus(address,uint);

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function updateFiatPrice(uint256 _price, uint256 _referralBonus, uint256 _spillover) public onlyOwner{
         price = _price;
         spillover = _spillover;
         referralBonus = _referralBonus;
    }
    
    function register(address payable _referrer, uint256 _referrerAccount) external payable{
        require(msg.value == price);
        if(_referrer == owner){
            registration(msg.sender,_referrer,_referrerAccount);
        }
        else{
            User storage u = users[msg.sender];
            User storage r = users[_referrer];
            Account storage ra = r.accounts[_referrerAccount];
            require(r.active == true);
            require(ra.active == true);
            require(u.active == false);
            registration(msg.sender,_referrer,_referrerAccount);
        }
    }
    
    function deactive(address _account, uint256 _accountNo) public onlyOwner{
        User storage u = users[_account];
        Account storage ua = u.accounts[_accountNo];
        ua.active = false;
    }
    
    function blacklist(address _account) public onlyOwner{
        User storage u = users[_account];
        u.active = false;
    }
    
    function reactivate(address _account) public onlyOwner{
        User storage u = users[_account];
        u.active = true;
    }
    
    function registration(address _user, address payable _referrer, uint256 _referrerAccount) private{
        totalUsers = totalUsers + 1;
        userAccounts = userAccounts + 1;
        User storage u = users[_user];
        Account storage ua = u.accounts[1];
        if(_referrer != owner){
            u.referrer = _referrer;
            u.totalAccounts = 1;
            u.active = true;
            ua.active = true;
            pushDownlines(_user,_referrer,_referrerAccount);
            pushUplines(_user,_referrer,_referrerAccount,1);
            sendDirectBonus(_referrer);
        } 
        else{
            u.referrer = owner;
            u.totalAccounts = 1;
            u.active = true;
            ua.active = true;
            sendDirectBonus(payable(owner));
            pushDownlines(_user,_referrer,_referrerAccount);
            pushUplines(_user,_referrer,_referrerAccount,1);
        }
    }
    
    function pushUplines(address _user, address payable _referrer,uint256 _referrerAccount, uint256 _userAccount) private{
        User storage u = users[_user];
        User storage r = users[_referrer];
        Account storage ra = r.accounts[_referrerAccount];
        Account storage ua = u.accounts[_userAccount];
        ua.uplines.push(_referrer);   
        for(uint256 i = 0; i < ra.uplines.length; i++){
               ua.uplines.push(ra.uplines[i]);
         }
        sendSpillOver(ua.uplines);
    }
    
    function pushDownlines(address _user, address payable _referrer, uint256 _referrerAccount) private {
        User storage r = users[_referrer];
        Account storage ra = r.accounts[_referrerAccount];
        ra.downlines.push(_user);
        for(uint256 i=0; i < ra.uplines.length; i++ ){
            User storage u = users[ra.uplines[i]];
            uint256 total = u.totalAccounts;
            for(uint256 j=total;j>0;j--){
              Account storage ua = u.accounts[j];
              if(ua.active == true){
                  ua.downlines.push(_user);
                  break;
              }
              j++;
            }
         }
        if(_referrerAccount == 1 && ra.downlines.length >= 39){
                 ra.active = false;
         }
         else if(_referrerAccount == 2 && ra.downlines.length >= 1082){
                 ra.active = false;
         }
         else if(_referrerAccount > 2 && ra.downlines.length >= 29514){
                ra.active = false;
         }
         else{
             ra.active = true;
         }
    }
    
    
    function purchase() external payable{
         require(msg.value == price);
         User storage u = users[msg.sender];
         uint256 newAccount = u.totalAccounts;
         newAccount = newAccount + 1;
         uint256 oldAccount = u.totalAccounts;
         require(u.active == true);
         userAccounts = userAccounts + 1;
         Account storage o = u.accounts[oldAccount];
         Account storage a = u.accounts[newAccount];
         a.active = true;
         a.uplines = o.uplines;
         u.totalAccounts = newAccount;
         sendDirectBonus(payable(u.referrer));
         sendSpillOver(a.uplines);
    }
    
    
    function sendSpillOver(address[] memory _reciepients) private{
        if(_reciepients.length > 9){
           for(uint i=0;i< 9;i++){
              payable( _reciepients[i]).transfer(spillover);
              emit LevelBonus(_reciepients[i],spillover);
           }
        }
        else{
          for(uint i=0;i<_reciepients.length;i++){
              payable( _reciepients[i]).transfer(spillover);
              emit LevelBonus(_reciepients[i],spillover);
           }  
        }
    }
    
    function sendDirectBonus(address payable _reciever) private {
        _reciever.transfer(referralBonus);
        emit Referral(_reciever,referralBonus);
    }
    
    function updateOwnership(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }
    
    function balanceOf() external view returns(uint256){
        return address(this).balance;
    }
    
    function getUplines(uint _accountId) public view returns(address[] memory, bool status){
        User storage u = users[msg.sender];
        require(u.totalAccounts >= _accountId);
        Account storage a = u.accounts[_accountId];
        return(a.uplines,a.active);
    }
    
    function getDownlines(uint _accountId) public view returns(address[] memory, bool status){
        User storage u = users[msg.sender];
        Account storage a = u.accounts[_accountId];
        require(a.active == true);
        return(a.downlines,a.active);
    }
    
    function getOwnerDonwlines(uint _accountId) public view onlyOwner returns(address[] memory){
        User storage u = users[owner];
        Account storage a = u.accounts[_accountId];
        return(a.downlines);
    }
    
    function getAccountDetails(address _user) public view returns(address, uint, bool){
        User storage u = users[_user];
        return(u.referrer,u.totalAccounts,u.active);
    }
    
    function getUserAccountDetails(address _user, uint256 _account) public view returns(address[] memory, address[] memory){
        User storage u = users[_user];
        Account storage a = u.accounts[_account];
        return(a.uplines,a.downlines);
    }
    
    function validate(address _address) public view returns(bool){
        User storage u = users[_address];
        return u.active;
    }
    
    function updateProfile(string memory _fname, string memory _lname, string memory _country, string memory _location, string memory _username, bool _show) public{
        UserDetails storage detail = details[msg.sender];
        detail.fname = _fname;
        detail.lname = _lname;
        detail.country = _country;
        detail.location = _location;
        detail.username = _username;
        detail.show = _show;
    }
    
    function getProfile() public view returns(string memory,string memory,string memory,string memory,string memory,bool){
        UserDetails storage detail = details[msg.sender];
        return(detail.fname,detail.lname,detail.country,detail.location,detail.username,detail.show);
    }
    
    function drain() public onlyOwner{
        payable(owner).transfer(address(this).balance);
    }
 
}