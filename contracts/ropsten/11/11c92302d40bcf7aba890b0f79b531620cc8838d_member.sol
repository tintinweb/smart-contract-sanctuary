/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity ^0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    
     modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

contract member is ReentrancyGuard {

	using SafeMath for uint256;
	
	address payable public founder1;
	address payable public founder2;
	address payable public founder3;
	address payable public founder4;
	address payable public founder5;
	address payable public member1;	
	address payable public member2;
	address payable public member3;
	address payable public member4;
	address payable public member5;
	address payable public member6;
	
	uint256 public unlockTime1;
	bool public unlockTime1used = false;
    uint256 public unlockTime2;
    bool public unlockTime2used = false;
    uint256 public unlockTime3;
    uint256 public fullUnlock;
    bool public initialized = false;
    bool public runningTest = false;
    uint256 constant firstDivider = 5;
    uint256 constant secondDivider = 2;
    uint256 constant amountOfShares = 16;
    uint256 constant doubleShare = 2;
    
    IERC20 public  Tinv;	

	// mapping for the members
	mapping(address => bool) public members;
	
	// on deployment, add in all the members, and the token
    constructor(
        address payable founder1_, 
        address payable founder2_, 
        address payable founder3_, 
        address payable founder4_, 
        address payable founder5_,
        address payable member1_, 
        address payable member2_, 
        address payable member3_, 
        address payable member4_, 
        address payable member5_,
        address payable member6_, 
        IERC20 Tinv_) public
         {
            founder1 = founder1_;
            founder2 = founder2_;
            founder3 = founder3_;
            founder4 = founder4_;    
            founder5 = founder5_;
            member1 = member1_; 
            member2 = member2_; 
            member3 = member3_;  
            member4 = member4_; 
            member5 = member5_;  
            member6 = member6_;             
            Tinv = Tinv_;
            
            members[founder1] = true;
            members[founder2] = true;
	        members[founder3] = true;
	        members[founder4] = true;
	        members[founder5] = true;    
            members[member1] = true;
            members[member2] = true;
	        members[member3] = true;
	        members[member4] = true;
	        members[member5] = true;     	        
	        members[member6] = true; 
    }
    

	 
	function initialize() isHuman public returns (bool) {
	    require(members[msg.sender], "You are not a member");  
        require(!initialized, "already initialized");
         unlockTime1 = block.timestamp + 1 days;
         unlockTime2 = block.timestamp + 30 days;
         unlockTime3 = block.timestamp + 60 days;
         fullUnlock  = block.timestamp + 90 days;
         initialized = true;
         return true;
	}
	
	function initializeTest() isHuman public returns (bool) {
	    require(members[msg.sender], "You are not a member");  
        require(!initialized, "already initialized");
         unlockTime1 = block.timestamp + 1 hours;
         unlockTime2 = block.timestamp + 2 hours;
         unlockTime3 = block.timestamp + 3 hours;
         fullUnlock  = block.timestamp + 4 hours;
         initialized = true;
         runningTest = true;
         return true;
	}
	
		function initializeTestNow() isHuman public returns (bool) {
	    require(members[msg.sender], "You are not a member");  
        require(!initialized, "already initialized");
         unlockTime1 = block.timestamp;
         unlockTime2 = block.timestamp;
         unlockTime3 = block.timestamp;
         fullUnlock  = block.timestamp;
         initialized = true;
         runningTest = true;
         return true;
	}
	
    // this one can be called after 1 day, pays out 20% of the balance.
	function transferOne() isHuman nonReentrant public returns (bool) {
	  	require(members[msg.sender], "You are not a member");  
	  	require(!unlockTime1used, "already paid out");
	 	require(unlockTime1 < block.timestamp, "too early");
	  	require(initialized == true, "need to be initialized");
	  	unlockTime1used = true;
	  	uint256 AmountToken = IERC20(Tinv).balanceOf(address(this));
	  	uint256 oneShare = AmountToken.div(firstDivider).div(amountOfShares);
	  	AmountToken -= oneShare.mul(amountOfShares);
        Tinv.transfer(member1,oneShare);
        Tinv.transfer(member2,oneShare);
        Tinv.transfer(member3,oneShare);
        Tinv.transfer(member4,oneShare);
        Tinv.transfer(member5,oneShare);
        Tinv.transfer(member6,oneShare);
        Tinv.transfer(founder1,oneShare.mul(doubleShare));
        Tinv.transfer(founder2,oneShare.mul(doubleShare));
        Tinv.transfer(founder3,oneShare.mul(doubleShare));
        Tinv.transfer(founder4,oneShare.mul(doubleShare));
        Tinv.transfer(founder5,oneShare.mul(doubleShare));
		return true;
	}

    // this one can be called after 30 days, pays out half the balance.
	function transferTwo() isHuman nonReentrant public returns (bool) {
	  	require(members[msg.sender], "You are not a member");  
	 	require(!unlockTime2used, "already paid out");
	  	require(unlockTime2 < block.timestamp, "too early");
	  	require(initialized == true, "need to be initialized");
	  	require(unlockTime1used == true, "payout the first rate before the second");
	  	unlockTime2used = true;
	  	uint256 AmountToken = IERC20(Tinv).balanceOf(address(this));
        uint256 oneShare = AmountToken.div(secondDivider).div(amountOfShares);
        Tinv.transfer(member1,oneShare);
        Tinv.transfer(member2,oneShare);
        Tinv.transfer(member3,oneShare);
        Tinv.transfer(member4,oneShare);
        Tinv.transfer(member5,oneShare);
        Tinv.transfer(member6,oneShare);
        Tinv.transfer(founder1,oneShare.mul(doubleShare));
        Tinv.transfer(founder2,oneShare.mul(doubleShare));
        Tinv.transfer(founder3,oneShare.mul(doubleShare));
        Tinv.transfer(founder4,oneShare.mul(doubleShare));
        Tinv.transfer(founder5,oneShare.mul(doubleShare));
		return true;
	}
	
	// this one can be called after 60 days, pays out the remaining amount.
	function transferThree() isHuman nonReentrant public returns (bool) {
	  	require(members[msg.sender], "You are not a member");  
	  	require(unlockTime3 < block.timestamp, "too early");
	    require(initialized == true, "need to be initialized");
	    require(unlockTime1used == true, "payout the first rate before the third");
	    require(unlockTime2used == true, "payout the second rate before the third");
	    uint256 AmountToken = IERC20(Tinv).balanceOf(address(this));
        uint256 oneShare = AmountToken.div(amountOfShares);
        Tinv.transfer(member1,oneShare);
        Tinv.transfer(member2,oneShare);
        Tinv.transfer(member3,oneShare);
        Tinv.transfer(member4,oneShare);
        Tinv.transfer(member5,oneShare);
        Tinv.transfer(member6,oneShare);
        Tinv.transfer(founder1,oneShare.mul(doubleShare));
        Tinv.transfer(founder2,oneShare.mul(doubleShare));
        Tinv.transfer(founder3,oneShare.mul(doubleShare));
        Tinv.transfer(founder4,oneShare.mul(doubleShare));
        Tinv.transfer(founder5,oneShare.mul(doubleShare));
		return true;
	}
	
	// in case tokens get stuck in contract, then this one can be called after 90 days. 
	// Send all tokens to the caller! No distribution.
	function transferFullUnlock(uint256 _tokens) isHuman public returns (bool) {
	    require(IERC20(Tinv).balanceOf(address(this)) >= _tokens);
	  	require(members[msg.sender], "You are not a member");  
	  	require(fullUnlock < block.timestamp, "too early");
	    require(initialized == true, "need to be initialized");
        Tinv.transfer(msg.sender, _tokens);
		return true;
	}
}