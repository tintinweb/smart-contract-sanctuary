/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

//sifti 0x1f4F824D33AF95888E5AD4766afA07eB9c9D9cd6
//busd 0xf12De697FA86f7E47B10f8C913425b651e5C720E
//owner 0xb68B3585fA60AAa5bb496E2B22269B9Aca8C6542

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
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

contract DemoContract  {
     using SafeMath for uint256;
        address public owner;
    /*
        struct Details{
         string name;
         uint mobile_no;
         bool adult;
         uint sifti_tokens;
         uint busd_tokens;
     }*/
     struct User {
        uint id;
        //mapping(uint256 => Details) details;
        string name;
         uint mobile_no;
         bool adult;
         uint sifti_tokens;
         uint busd_tokens;
    }
    
    
    mapping(address => User) public users;
    
    uint256 private constant INTEREST_CYCLE = 1 days;

    uint public lastUserId = 2;
    uint256 public tokenPrice=40*1e16;
    //bool public isAdminOpen;
    //bool public buyOn;
    //uint256 public  MINIMUM_BUY = 1e18;
    //uint256 public  MINIMUM_SELL = 20*1e18;    //@ 20busd
	
    
    event Registration(address indexed user, uint indexed userId);
    
    IBEP20 private siftiToken; 
    IBEP20 private busdToken; 

    constructor(address ownerAddress, IBEP20 _busdToken, IBEP20 _siftiToken) public
    {
        owner = ownerAddress;
        
        siftiToken = _siftiToken;
        busdToken = _busdToken;
        
        User memory user = User({
            id: 1,
            name : "Ip singh",
            mobile_no : 9968616173,
            adult : true,
            busd_tokens : 0,
            sifti_tokens : 0

        });

        users[ownerAddress] = user;
        
        emit Registration(ownerAddress,users[ownerAddress].id);

    } 
    /*
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }
    */
    function registration(address _userAddress, string memory _name, uint _mobile, bool _ad, uint _sift, uint _busd) public 
    {
        require(!isUserExists(_userAddress), "user exists");
        
        uint32 size;
        assembly {
            size := extcodesize(_userAddress)
        }
        
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            name: _name,
            mobile_no: _mobile,
            adult: _ad,
            sifti_tokens: _sift,
            busd_tokens: _busd
        });
        
        users[_userAddress] = user;
        lastUserId++;
        
        emit Registration(_userAddress,users[_userAddress].id);
    }
        function buyToken(uint256 tokenQty) public payable
	{
	     //require(buyOn,"Buy Stopped.");
	     require(!isContract(msg.sender),"Can not be contract");
         require(isUserExists(msg.sender), "user not exists");
	     //require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     uint256 buy_amt=(tokenQty/1e18)*tokenPrice;
	     require(busdToken.balanceOf(msg.sender)>=(buy_amt),"Low Balance");
	     //require(busdToken.allowance(msg.sender,address(this))>=buy_amt,"Invalid buy amount");
	     
	     users[msg.sender].busd_tokens=users[msg.sender].busd_tokens+tokenQty;
	     busdToken.transferFrom(msg.sender ,address(this), (buy_amt));
	     siftiToken.transfer(msg.sender , tokenQty);
	     
         //total_token_buy=total_token_buy+tokenQty;
		 //emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice, buy_amt);					
	 }


    function sellToken(uint256 tokenQty) public payable
	{
	     //require(sellOn,"sell Stopped.");
	     //require(!isContract(msg.sender),"Can not be contract");
         require(isUserExists(msg.sender), "user not exists");
	     //require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     uint256 sell_amt=(tokenQty/1e18)*tokenPrice;
	     require(siftiToken.balanceOf(msg.sender)>=(sell_amt),"Low Balance");
	     //require(elucksToken.allowance(msg.sender,address(this))>=sell_amt,"Invalid sell amount");
	     
	     users[msg.sender].sifti_tokens=users[msg.sender].sifti_tokens+tokenQty;
	     siftiToken.transferFrom(msg.sender ,address(this), (tokenQty));
	     busdToken.transfer(msg.sender , sell_amt);                 
	 }

    
    function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }

}