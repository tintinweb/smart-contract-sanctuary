/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.4.26;

contract PennyToken {
    string public constant name = "Penny";
    string public constant symbol = "PY";
    uint8 public constant decimals = 2;

    event Transfer(address indexed from, address indexed to, uint256 tokens);

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    using SafeMath for uint256;

    constructor(uint256 total) public {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens)
        public
        returns (bool)
    {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
}

library SafeMath {
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

contract RecieveToken {
    address public recieveOwner;

    address manager;

    function saveAddress(address _address) public {
        recieveOwner = _address;
    }

    function getBalance() public view returns (uint256) {
        PennyToken token = PennyToken(recieveOwner);
        return token.balanceOf(address(this));
    }

    function transferTokenToAddress(uint256 value) public {
        PennyToken token = PennyToken(recieveOwner);
        token.transfer(msg.sender, value);
    }
}