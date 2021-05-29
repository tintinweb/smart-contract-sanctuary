/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

pragma solidity ^0.5.8;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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
        require(b > 0, errorMessage);
        uint256 c = a / b;

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


contract Context {
    constructor () internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}



interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {// Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract SRATsaleForWhitelist {


    constructor(
        IERC20 SRAT_) public
         {
          deployingFounder = msg.sender;
          SRAT = SRAT_;
          founder[deployingFounder] = true; 
    }
    
    
    using SafeMath for uint256;

	address payable public deployingFounder;
    mapping(address => bool) public founder;
    mapping (uint => poolStr) public pool;
    mapping (address => userStr) public buyer;
    
    IERC20 public SRAT;

    uint256 public startsAt = 0;
    uint256 public runPeriod = 10 minutes;
    bool public initialized = false;

    uint256 public poolHardcap = 5e14; 
    uint256 public maticRaised = 0;
    uint256 public tokensSold = 0;  
   
  
    struct poolStr {
        uint price;
        uint startTime;
        uint runTime;
        uint tokensSold;
    }

    uint256 public noOfPool = 0;


    struct userStr {

        bool isExist;
        uint id;
        uint token;
    }

	mapping(address => bool) public isWhiteListed;
	 
    function Whitelist(address[] calldata addrlist) external {
        for(uint i = 0; i < addrlist.length; i++){
            isWhiteListed[addrlist[i]] = true;
        }
    }

    function initialize() public returns (bool) {
        require(founder[msg.sender], "You are not a founder");	
        require(!initialized, "already initialized");
        initialized = true;
        startsAt = block.timestamp;
        poolStr memory poolInfo;
        poolInfo = poolStr({
            price : 1,
            startTime: startsAt,
            runTime: 10 minutes,
            tokensSold: 0
        });

        noOfPool++;
        pool[noOfPool] = poolInfo;
        return true;
    }
    uint256 public noOfBuyer = 0;
        
     
    function buy() public payable returns (bool) {
        require(initialized, "Not initialized");
        require(msg.value >= 1e18 && msg.value <= 2e18, 'not between');
        require(isWhiteListed[msg.sender], "You are not whitelisted");	
        isWhiteListed[msg.sender] = false;
        require(pool[1].startTime < now && uint(pool[1].startTime).add(pool[1].runTime) > now && pool[1].tokensSold < poolHardcap, "Pool not running");

        uint tokensAmount = 0;
        uint maticAmount = msg.value;

        tokensAmount = uint(maticAmount).div(pool[1].price);

        if(uint(pool[1].tokensSold).add(tokensAmount) > poolHardcap){
            tokensAmount = uint(poolHardcap).sub(pool[1].tokensSold);
            maticAmount = tokensAmount.mul(pool[1].price);
            address(msg.sender).transfer(uint(msg.value).sub(maticAmount));


        }
		

        if(!buyer[msg.sender].isExist){
            userStr memory buyerInfo;
            
            noOfBuyer++;

            buyerInfo = userStr({
                isExist: true,
                id: noOfBuyer,
     
                token: tokensAmount
            });

            buyer[msg.sender] = buyerInfo;
 
        }else{
            buyer[msg.sender].token += tokensAmount;
        }

        pool[1].tokensSold += tokensAmount;

        maticRaised += maticAmount;
        tokensSold += tokensAmount;

    // Emit an event that shows Buy successfully
        emit Buy(msg.value, tokensAmount);
        return true;
    }

    event Buy(uint256 _maticAmount, uint256 _tokenAmount);
    
    function claim() public returns (bool) {
        require(initialized, "Not initialized");
        require(uint(startsAt).add(runPeriod) < now, "Sale is running now");
        require(buyer[msg.sender].token > 0, "Nothing to claim");
        uint256 AmountX = buyer[msg.sender].token;
        SRAT.transfer(msg.sender, AmountX);
        buyer[msg.sender].token = 0;
        return true;
    }
 

    function WithdrawUnsoldTokens(uint256 Zvalue) 
	    public { require(founder[msg.sender], "You are not a founder");	
		SRAT.transfer(msg.sender, Zvalue);
    }
				    
    
    // getEnd Time 
    function getEndTime() public view returns (uint) {
        if(uint(startsAt).add(runPeriod) > now && startsAt < now){
            return uint(startsAt).add(runPeriod).sub(now);
        }else{
            return 0;
        }

    }
    }

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}