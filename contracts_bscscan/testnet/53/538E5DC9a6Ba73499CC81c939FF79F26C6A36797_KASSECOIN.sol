/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

pragma solidity 0.5.4;

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
   
contract KASSECOIN  {
    using SafeMath for uint256;
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        bool airdropClaim;
        uint256 refIncome;
        uint256 levelIncome;
        uint256 selfBuy;
        uint256 selfSell;
        uint256 planCount;
    }
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
   
    uint public lastUserId = 2;
    uint public  total_token_buy = 0;
	uint256 public airdropFee =21*1e14;
	uint public  MINIMUM_BUY = 1e16;
	uint public tokenPrice = 2320000000000;
    address public owner;
    address private buyingWallet;
    address private feeWallet;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint bnb_amount);
    event Airdrop(address  _user, uint256 tokenQnt);
    
   //For Token Transfer
   
   IBEP20 private KasseToken; 
   event onBuy(address buyer , uint256 amount);
   mapping(address => uint256) public boughtOf;

    constructor(address ownerAddress, IBEP20 _kassetoken,address _buyingfeeWallet,address _feeWallet) public 
    {
        owner = ownerAddress;
        buyingWallet=_buyingfeeWallet;
        feeWallet=_feeWallet;
        KasseToken = _kassetoken;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            refIncome: uint(0),
            airdropClaim:true,
            levelIncome: uint(0),
            selfBuy: uint(0),
            selfSell: uint(0),
            planCount: uint(0)
        });
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
    }
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

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
            airdropClaim:false,
            levelIncome: 0,
            selfBuy: 0,
            selfSell: 0,
            planCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
        users[referrerAddress].partnersCount++;
        

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function buyToken(uint256 _value,address referrer) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(msg.value>=MINIMUM_BUY,"Invalid minimum quantity");
	     require(msg.value==_value,"Invalid Value");
	     uint256 amount =(_value/tokenPrice)*1e18;
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender, referrer);   
	     }
	     require(isUserExists(msg.sender), "user not exists");
	     
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+amount;
	     KasseToken.transfer(msg.sender , amount);
	     KasseToken.transfer(users[msg.sender].referrer,amount);
	     users[users[msg.sender].referrer].refIncome=users[users[msg.sender].referrer].refIncome+amount;
         total_token_buy=total_token_buy+amount;
         address(uint160 (buyingWallet)).transfer(msg.value);
// 		 emit TokenDistribution(address(this), msg.sender, amount, priceLevel[priceIndex],buy_amt);					
	 }
	 
    function getAirdrop(address referrer) public payable
	{
	     uint256 airdropToken=370*1e18;
	     require(!isContract(msg.sender),"Can not be contract");
	     require(!users[msg.sender].airdropClaim,"User already Claimed!");
         require(isUserExists(referrer),"Referrer not exist!");
	     require(msg.value==airdropFee,"Invalid airdrop fee") ;
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender, referrer);   
	     }
	     require(isUserExists(msg.sender), "user not exists");
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+airdropToken;
	     users[msg.sender].airdropClaim=true;
	     KasseToken.transfer(msg.sender , airdropToken);
	     KasseToken.transfer(referrer , airdropToken);
	     address(uint160 (feeWallet)).transfer(msg.value);
         emit Airdrop(msg.sender,airdropToken);
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
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
}