/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

pragma solidity ^0.6.12;
    
    // SPDX-License-Identifier: MIT
    
    library SafeMath {
      function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
      }
    
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
        
        uint256 c = a / b;
        return c;
      }
    
      function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
      }
    
      function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
      }
    
      function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
      }
    }
    
    contract Owned {
        address payable public owner;
    
        event OwnershipTransferred(address indexed _from, address indexed _to);
    
        constructor() public {
            owner = msg.sender;
        }
    
        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
        
        function getOwner() public view returns(address){
        return owner;
        }
    
        function transferOwnership(address payable _newOwner) public onlyOwner {
            owner = _newOwner;
            emit OwnershipTransferred(msg.sender, _newOwner);
        }
    }
    
    
    interface IBEP20 {
        function decimals() external view returns (uint256 balance);
       function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    }
    
    
    contract BSCMemepad is Owned {
        using SafeMath for uint256;
        
        bool public isPresaleOpen;
        
        address public tokenAddress = 0xaeB049D29784Cd1Da3887a9f96068b5a8805B819;
        uint256 public tokenDecimals = 9;
        
        
        uint256 public tokenRatePerEth = 60000000000;
        uint256 public rateDecimals = 0;
        
        uint256 public soldTokens=0;
        
        uint256 public totalsold = 0;
        
        struct UserStruct {
        bool isExist;
        address referrer;
        uint256 directCount;
        address[] referral;
        uint256 amount;
        uint256 earned;
        uint256 signedTime;
        }
        
    
      mapping (address => UserStruct) public users;
      mapping (address => address) public _parent;
    
      event Rewards(address indexed _from, address indexed _referrer, uint256 amount);
      event Claim(address indexed _from,address indexed _to,uint256 amount);
    
      uint256 public userCount = 0;
      uint256 public totalEarned = 0;
      
      uint256 public totalFee = 1000;
   
    
      uint256[] public rewardLevel;
        
      mapping(address => mapping(address => uint256)) public usersInvestments;
      mapping(address => mapping(address => uint256)) public usersSold;
        
      mapping(address => mapping(address => uint256)) public balanceOf;
      
        constructor() public {
        owner = msg.sender;
        rewardLevel.push(400);
        rewardLevel.push(200);
        rewardLevel.push(100);
        rewardLevel.push(100);
        rewardLevel.push(100);
        rewardLevel.push(50);
        rewardLevel.push(50);
         users[msg.sender] = UserStruct({
            isExist : true,
            referrer : address(0),
            directCount: 0,
            referral: new address[](0),
            amount: 0,
            earned: 0,
            signedTime: block.timestamp
        });
        _parent[msg.sender] = address(0);
        }
        
        function setTokenAddress(address token) external onlyOwner {
            tokenAddress = token;
            tokenDecimals = IBEP20(tokenAddress).decimals();
        }
        
        function setTokenRatePerEth(uint256 rate) external onlyOwner {
            tokenRatePerEth = rate;
        }
        
        function setRateDecimals(uint256 decimals) external onlyOwner {
            rateDecimals = decimals;
        }
        
        function getUserInvestments(address user) public view returns (uint256){
            return usersInvestments[tokenAddress][user];
        }
        
        function getUserClaimbale(address user) public view returns (uint256){
            return balanceOf[tokenAddress][user];
        }
        
        function buyTokens(address _referrer) public payable{
            uint256 _amount = msg.value;
            // Refferal Fee Collection
            _amount = _amount.sub(_amount.mul(totalFee).div(10000));
            require( (IBEP20(tokenAddress).balanceOf(address(this))).sub(soldTokens) > 0 ,"Insufficient Liquidity !");
            uint256 tokenAmount = getTokensPerEth(_amount);
            require((IBEP20(tokenAddress).transfer(msg.sender,tokenAmount)),"Transfer Failed !");
            soldTokens = soldTokens.add(tokenAmount);
            usersInvestments[tokenAddress][msg.sender] = usersInvestments[tokenAddress][msg.sender].add(_amount);
            if(!users[msg.sender].isExist){
                signupUser(_referrer,_amount);
            }else{
                rewardDistribution(msg.sender,_amount);
            }
            
        }
        
        function sellTokens(address _referrer,uint256 _amount) public {
           // The sell tokens 
            require(IBEP20(tokenAddress).transferFrom(msg.sender,address(this), _amount),"Insufficient balance from User");
            uint256 ethAmount = getEthPerTokens(_amount);
            require(ethAmount <= address(this).balance , "Insufficient Liquidity !");
            // Refferal Fee
            ethAmount = ethAmount.sub(ethAmount.mul(totalFee).div(10000));
            usersSold[tokenAddress][msg.sender] = usersSold[tokenAddress][msg.sender].add(_amount);
            payable(msg.sender).transfer(ethAmount);
             if(!users[msg.sender].isExist){
                signupUser(_referrer,_amount);
            }else{
                rewardDistribution(msg.sender,_amount);
            }
            
        }
        
        function getTokensPerEth(uint256 amount) public view returns(uint256) {
            return amount.mul(tokenRatePerEth).div(
                10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
                );
        }
        
        function getEthPerTokens(uint256 amount) public view returns(uint256) {
            return amount.div(tokenRatePerEth).mul(
                10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
                );
        }
        
        
        function withdrawBNB() public onlyOwner{
            require(address(this).balance > 0 , "No Funds Left");
             owner.transfer(address(this).balance);
        }
        
        function getUnsoldTokensBalance() public view returns(uint256) {
            return IBEP20(tokenAddress).balanceOf(address(this));
        }
        
        function getUnsoldTokens() external onlyOwner {
            require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
            IBEP20(tokenAddress).transfer(owner, (IBEP20(tokenAddress).balanceOf(address(this))).sub(soldTokens) );
        }
        
        function signupUser(address _referrer,uint256 amount) public{
        require(!users[msg.sender].isExist,"User already Exists !");
        _referrer = users[_referrer].isExist ? _referrer : getOwner();
         users[msg.sender] = UserStruct({
            isExist : true,
            referrer : _referrer,
            directCount: 0,
            referral: new address[](0),
            amount: 0,
            earned: 0,
            signedTime: block.timestamp
        });
        _parent[msg.sender] = _referrer;
        users[_referrer].referral.push(msg.sender);
        users[_referrer].directCount = users[_referrer].directCount.add(1);
        userCount++;
       rewardDistribution(msg.sender,amount);
       }
    
      function rewardDistribution(address _user,uint256 _amount)internal{
            for(uint256 i=0; i < rewardLevel.length;i++){
                _user = users[_parent[_user]].isExist ? _parent[_user] : getOwner();
                uint256 toTransfer = _amount.mul(rewardLevel[i]).div(10000);
                users[_user].amount = users[_user].amount.add(toTransfer);
                emit Rewards(address(this),_user,toTransfer);
            }
            
      }
    
      function getLevels() public view returns (uint256[] memory){
            return rewardLevel;
      }
      
      function getReferalperUser(address _user) public view returns (address[] memory){
        return users[_user].referral;
    }
    
    function setLevelpercent(uint256 _level,uint256 _percent) external onlyOwner{
        rewardLevel[_level] = _percent;
    }
    
    function addNewLevel(uint256 _percent) external onlyOwner {
        rewardLevel.push(_percent);
    }
        
      function claimRewards() public{
            uint256 toTransfer = users[msg.sender].amount;
           // IBEP20(tokenAddress).transfer(msg.sender,toTransfer);
           //Claim Rewards in BNB
            payable(msg.sender).transfer(toTransfer);
            users[msg.sender].amount = 0;
            users[msg.sender].earned = users[msg.sender].earned.add(toTransfer);
            totalEarned = totalEarned.add(toTransfer);
            emit Claim(address(this),msg.sender,toTransfer);  
        }
}