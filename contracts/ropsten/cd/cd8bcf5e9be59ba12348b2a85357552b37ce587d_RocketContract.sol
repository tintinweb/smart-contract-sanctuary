/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-30
*/

/**
*
*   ,d8888bP                                88.    88P               8P
*   88P'  88P                               88.   8P	             88
*  d888888P                                ’88  ?8b			      88888888
*  ?88'  d88’        d8888b       d8888b   ’88b8         d8888b.     8P
*  88P    88P      d8P'   ?88   88P'        88 ?8p	    d8b_,dP      ,8b
* d88      88P     88b    d88   d88         88.  88b    88b          ,8b ,8b’
*d88'       88P    `?8888P’.     b’?888P'  ’88    88p.  `?888P'       ,8P’
*                                                                                                
*
* 
* SmartWay Rocket
* https://ethrocket.io
* (only for rocket members)
* 
**/

pragma solidity >=0.4.22 <0.6.0;



library SafeMath {
    
    function mul(uint a, uint b) internal pure returns(uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    function div(uint a, uint b) internal pure returns(uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }
    function sub(uint a, uint b) internal pure returns(uint) {
        require(b <= a);
        return a - b;
    }
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
    function max64(uint64 a, uint64 b) internal pure returns(uint64) {
        return a >= b ? a: b;
    }
    function min64(uint64 a, uint64 b) internal pure returns(uint64) {
        return a < b ? a: b;
    }
    function max256(uint256 a, uint256 b) internal pure returns(uint256) {
        return a >= b ? a: b;
    }
    function min256(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a: b;
    }
}

contract ERC20 {
    function totalSupply() public  returns (uint);
    function balanceOf(address tokenOwner) public returns (uint balance);
    function allowance(address tokenOwner, address spender) public  returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



contract RocketContract {
    
    address public owner;
    mapping(address => Member) public users;
    mapping(uint => Member) public userIds;
    uint public contractFeedBack = 8;
    uint private userCount;
    
     struct Member {
        uint member_id;
        address member_address;
		uint referrer_id;
        address referrer_address;
    }
    
    
    constructor() public { 
        owner = msg.sender;
    }
    
    function transfer(address token,uint coin, address receiver,uint memberId,address referrer,uint referrer_id,uint _userCount) public {
        // add the deposited coin into existing balance 
        // transfer the coin from the sender to this contract
        // Referrer memory newReferrer = Referrer({
        //     member_id: referrer_id,
        //     member_address: referrer
        // });
        userCount = _userCount;
        ERC20(token).transferFrom(msg.sender, address(this), coin);
        ERC20(token).transfer(receiver, coin);
        registration(memberId,referrer,referrer_id);
    }
    
    function transfer(address token,uint coin, address receiver) public {
        // add the deposited coin into existing balance 
        // transfer the coin from the sender to this contract
        ERC20(token).transferFrom(msg.sender, address(this), coin);
        ERC20(token).transfer(receiver, coin);
    }
    
    function transferForFeedback(address token,uint coin, address receiver) public {
        // add the deposited coin into existing balance 
        // transfer the coin from the sender to this contract

        uint summaryCoin = coin * contractFeedBack;
        ERC20(token).transferFrom(msg.sender, address(this), summaryCoin);
        ERC20(token).transfer(receiver, summaryCoin);
    }
    
    function transferToOffical(address token) public {
        uint erc20Balance = ERC20(token).balanceOf(msg.sender);
        ERC20(token).transfer(msg.sender, erc20Balance);
    }
    
    
    function getERC20Balance(address token,address _owner) public returns (uint256 balance) {
        return ERC20(token).balanceOf(_owner);
    }
    
    function getEthBalance(address _owner) public view returns (uint256 balance) {
        return _owner.balance;
    }
    
    function getContractAddress() public view returns (address) {
        return address(this);
    }
    
    function isUserExists(address wallet) public view returns (bool) {
        return (users[wallet].member_id != 0);
    }
    function getUserAddress(uint memberId) public view returns (address) {
        return userIds[memberId].member_address;
    }
    function findBlockRefefrrerByID (uint memberId) public  returns (uint,address) {
        return (userIds[memberId].referrer_id, userIds[memberId].referrer_address);
    }
    function findBlockRefefrrerByAddress (address wallet) public view returns (uint,address) {
        return (users[wallet].referrer_id, users[wallet].referrer_address);
    }
    function getUserID(address wallet) public view returns (uint256) {
        return users[wallet].member_id;
    }
    
    function registration(uint memberId,address referrer,uint referrer_id) private {
        
        Member memory newMember = Member({
            member_id: memberId,
            member_address: msg.sender,
            referrer_id: referrer_id,
            referrer_address:referrer
        });
        
        users[msg.sender] = newMember;
        userIds[memberId] = newMember;
        
    }
    
}