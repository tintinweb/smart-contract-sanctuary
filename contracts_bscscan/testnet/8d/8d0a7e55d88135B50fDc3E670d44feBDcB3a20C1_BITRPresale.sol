/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function burn(uint256 value) external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}

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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
}
   
contract BITRPresale  {
    using SafeMath for uint256;
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        uint256 refIncome;
        uint256 selfBuy;
    }
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
   
    uint public lastUserId = 2;
    uint public total_token_buy = 0;
	uint public MINIMUM_BUY = 1*1e18;
	uint public tokenPrice = 1*1e17;
    address public owner;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint bnb_amount);
    
   //For Token Transfer
   
   IBEP20 private BITRToken; 
   event onBuy(address buyer , uint256 amount);
   mapping(address => uint256) public boughtOf;

    constructor(address ownerAddress, IBEP20 _BITRtoken)  
    {
        owner = ownerAddress;
        BITRToken = _BITRtoken;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            refIncome: uint(0),
            selfBuy: uint(0)
        });
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
    }
    
    receive() external payable {}

    function registrationExt(address referrerAddress) external payable 
    {
        registration(msg.sender, referrerAddress);
    }
   
    function registration(address userAddress, address referrerAddress) private 
    {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            refIncome: 0,
            selfBuy: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        lastUserId++;
        users[referrerAddress].partnersCount++;
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function buyToken(uint256 tokenQnt,address referrer) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQnt>=MINIMUM_BUY,"Invalid minimum quantity");
	     require(msg.value==(tokenQnt/1e18)*tokenPrice,"Invalid value");
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender, referrer);   
	     }
	     require(isUserExists(msg.sender), "user not exists");
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+tokenQnt;
         users[referrer].refIncome=tokenQnt.mul(10).div(100);
	     BITRToken.transfer(msg.sender ,tokenQnt);
	     BITRToken.transfer(referrer ,tokenQnt.mul(10).div(100));
         total_token_buy=total_token_buy+tokenQnt;
		 emit TokenDistribution(address(this), msg.sender, tokenQnt,msg.value);					
	}
	 
	function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }
	
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }    
  
    function token_setting(uint min_buy) public payable
    {
           require(msg.sender==owner,"Only Owner");
           MINIMUM_BUY = min_buy;
    }
    
    function price_setting(uint token_price) public payable
    {
           require(msg.sender==owner,"Only Owner");
           tokenPrice = token_price;
    }
    
    function withdraw(uint value) public payable 
    {
         require(msg.sender==owner,"Only Owner");
         payable(owner).transfer(value);
    }
    
    function withdrawToken(uint256 tokenQnt) public payable
    {
         require(msg.sender==owner,"Only Owner");
         BITRToken.transfer(msg.sender,tokenQnt);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
}