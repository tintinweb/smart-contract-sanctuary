/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

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



contract TestContract {
    
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
    
    
    function transfer(address token,uint coin, address receiver) public {
        // add the deposited coin into existing balance 
        // transfer the coin from the sender to this contract
        string memory test1 ="0xAbfb22cEA4034a7d5B5B2A2a707578c60a3097bb";
        string memory test = toString(token);
        if (keccak256(abi.encodePacked(test)) == keccak256(abi.encodePacked(test1))) {
          // do something
          ERC20(token).transfer(receiver, coin);
        }
        
    }
    
    function toString(address account) public pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }
    
    function toString(uint256 value) public pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }
    
    function toString(bytes32 value) public pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }
    
    function toString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
    
  
}