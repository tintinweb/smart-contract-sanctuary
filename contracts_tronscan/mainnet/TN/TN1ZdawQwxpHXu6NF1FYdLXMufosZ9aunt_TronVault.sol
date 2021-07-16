//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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
}


//SourceUnit: TronVault v2.sol

pragma solidity ^0.5.10;
import "./SafeMath.sol";

contract TronVault {

    using SafeMath for uint256;
        
    struct UserStruct {
        uint invested;
        uint withdrawn;
        uint lastTime;
        uint toClaim;
        uint refEarnings;
    }
    
    mapping(address => UserStruct) public userInfo;

    uint public totalInvested;
    uint public totalWithdrawn;
    
    uint public startTime;

    address payable public owner;

    event SetOwner(address indexed _owner);
    event Deposit(address indexed _user, uint _value);
    event Withdraw(address indexed _user, uint _value);

    constructor() public {
        totalInvested = 0;
        totalWithdrawn = 0;
        startTime = 1600880400; // 09/23/2020 @ 5:00pm (UTC)
        
        owner = msg.sender;
        emit SetOwner(msg.sender);
    }
    
    function deposit(address payable _referrer) public payable returns (bool success) {
        
        require(uint(msg.value) >= 10000000);
        require(now > startTime);
        
        userInfo[msg.sender].toClaim = getBalance(msg.sender);
        userInfo[msg.sender].invested += msg.value;
        userInfo[msg.sender].lastTime = now;
        
        totalInvested += msg.value;
        
		_referrer.transfer((msg.value).div(100));
		userInfo[_referrer].refEarnings += (msg.value).div(100);
		owner.transfer((msg.value).div(200));
		
		emit Deposit(msg.sender, msg.value);
		
        return true;
        
    }
    
    function getBalance(address _user) public view returns (uint balance) {
        
        uint timeDiff = now - userInfo[_user].lastTime;
        
        // return (userInfo[msg.sender].invested).div(86400).mul(timeDiff);
        // 100% a day
        
        // return ((userInfo[msg.sender].invested).div(8640000).mul(timeDiff)) + userInfo[msg.sender].toClaim;
        // 1% a day
        
        return ((userInfo[msg.sender].invested).div(2880000).mul(timeDiff)) + userInfo[msg.sender].toClaim;
        // 3% a day
        
    }
    
    function withdraw() public returns (bool success) {
        
        uint toWithdraw = getBalance(msg.sender);
        
        msg.sender.transfer(toWithdraw);
        
        totalWithdrawn += toWithdraw;
        userInfo[msg.sender].withdrawn += toWithdraw;
        
        userInfo[msg.sender].toClaim = 0;
        userInfo[msg.sender].lastTime = now;
        
        emit Withdraw(msg.sender, toWithdraw);
        
        return true;
        
    }
    
}