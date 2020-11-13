/* 
Built by Cubebit Labs for Adcube

Version 2 - Reduced gas usage by frontend intervention

*/

pragma solidity ^0.7.0;

contract Adcube {
    
    address public owner;
    uint256 public level = 1;
    uint256 public position = 1;
    uint256 public levelThreshold = 1;
    uint256 public price = 50000000000000000;
    uint256 public spill = 3880000000000000;
    uint256 public referral = 3880000000000000;
    uint256 public totalUsers = 0;
    uint256 public totalAccounts = 0;
    
    constructor(){
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    struct User{
        bool active;
        bool uplinePaid;
        uint256 level;
        uint256 position;
        uint256 accounts;
        uint256 paid;
        address referrer;
        address[] uplines;
        address[] downlines;
    }
    
    struct Level{
        address[] positions;
    }
    
    mapping(address => User) users;
    
    mapping(uint256 => Level) levels;
    
    function adminRegister(address _user, address _referrer, uint256 _accounts) public onlyOwner returns(uint256,uint256){
        require(_accounts < 4 && _accounts > 0);
        User storage u = users[_user];
        Level storage l = levels[level];
        l.positions.push(_user);
        u.active = true;
        u.position = position;
        u.level = level;
        u.accounts = _accounts;
        u.referrer = _referrer;
        if(l.positions.length == levelThreshold){
            position = position + 1;
            levelThreshold = levelThreshold * 3;
            level = level + 1;
        }
        else{
            position = position + 1;
        }
       totalAccounts = totalAccounts + _accounts;
       totalUsers = totalUsers + 1;
       return(u.level,u.position);
    }
    
    function register(address _user,address _referrer, uint256 _accounts) external payable returns(uint256, uint256){
        require(_accounts < 4 && _accounts > 0);
        require(msg.value == price * _accounts);
        User storage r = users[_referrer];
        require(r.active == true);
        User storage u = users[_user];
        Level storage l = levels[level];
        l.positions.push(_user);
        u.active = true;
        u.position = position;
        u.level = level;
        u.accounts = _accounts;
        u.referrer = _referrer;
        if(l.positions.length == levelThreshold){
            position = position + 1;
            levelThreshold = levelThreshold * 3;
            level = level + 1;
        }
        else{
            position = position + 1;
        }
       totalAccounts = totalAccounts + _accounts;
       totalUsers = totalUsers + 1;
       return(u.level,u.position);
    }

    function sendSpill(address _user,address[] memory uplines) public onlyOwner{
        User storage a = users[_user];
        require(a.uplinePaid == false);
        require(a.active == true);
        a.uplines = uplines;
        a.uplinePaid = true;
        payable(a.referrer).transfer(referral);
        if(uplines.length < 9) {
            for(uint256 i=0;i < uplines.length; i++){
            User storage u = users[uplines[i]];
            u.paid = u.paid + 1;
            u.downlines.push(_user);
            if(u.accounts == 1 && u.paid == 39){
                u.active = false;
            }
            else if(u.accounts == 2 && u.paid == 1092){
                u.active = false;
            }
            else{
                if(u.paid == 29523){
                    u.active = false;
                }
            }
            payable(uplines[i]).transfer(spill);
         }
        }
        else{
          for(uint256 i=0; i < 9; i++){
              User storage u = users[uplines[i]];
              u.paid = u.paid + 1;
              u.downlines.push(_user);
              if(u.accounts == 1 && u.paid == 39){
                u.active = false;
              }
              else if(u.accounts == 2 && u.paid == 1092){
                u.active = false;
              }
              else{
                if(u.paid == 29523){
                    u.active = false;
              }
            }
            payable(uplines[i]).transfer(spill);
          }
        }
    }
    
    function purchase(uint256 _accounts) external payable{
        require(_accounts > 0 && _accounts < 3);
        User storage u = users[msg.sender];
        require(u.accounts + _accounts <= 3);
        require(msg.value == _accounts * price);
        u.accounts = u.accounts + _accounts;
    }
    
    function deactivate(address _user) public onlyOwner{
        User storage u = users[_user];
        u.active = false;
    }
    
    function activate(address _user) public onlyOwner{
        User storage u = users[_user];
        u.active = true;
    }
    
    function markPaid(address _user) public onlyOwner{
        User storage u = users[_user];
        u.uplinePaid = true;
    }
    
    function updateOwnership(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }
    
    function updateFiatPrice(uint256 _price, uint256 _referralBonus, uint256 _spillover) public onlyOwner{
         price = _price;
         spill = _spillover;
         referral = _referralBonus;
    }
    
    function fetchUsers(address _user) public view returns(bool _uplinePaid, uint256 _account,uint256 _paid, address[] memory _uplines, address[] memory _downlines, uint256 _level, uint256 _position, address _referrer){
        User storage u = users[_user];
        return(u.uplinePaid,u.accounts,u.paid,u.uplines,u.downlines,u.level,u.position,u.referrer);
    }
    
    function fetchLevels(uint256 _level) public view returns(address[] memory){
        Level storage l = levels[_level];
        return(l.positions);
    }
    
    function validate(address _user) public view returns(bool,bool){
        User storage u = users[_user];
        return(u.active,u.uplinePaid);
    }
    
    function balanceOf() external view returns(uint256){
        return address(this).balance;
    }
    
    function drain() public onlyOwner{
        payable(owner).transfer(address(this).balance);
    }
}