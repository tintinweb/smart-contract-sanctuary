//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract StockToken {
    string public name = "Crypto Stock";
    string public symbol = "CST";
    uint8 public decimals = 18;
    uint256 totalSupply_ = 0;
    address public owner_;

    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    using SafeMath for uint256;

    modifier onlyOwner() {
        if (msg.sender != owner_)
            revert("StockToken: Only owner can perform this transaction.");
        _;
    }

    constructor(uint256 _total) {
        totalSupply_ = _total;
        balances[msg.sender] = totalSupply_;
        owner_ = msg.sender;
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

    //changed msg.sender to tx.origin
    function approve(address delegate, uint256 numTokens)
        public
        returns (bool)
    {
        allowed[tx.origin][delegate] = numTokens;
        emit Approval(tx.origin, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate)
        public
        view
        returns (uint256)
    {
        return allowed[owner][delegate];
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function addSomeTokens(uint256 numTokens) public onlyOwner {
        balances[msg.sender] += numTokens;
        emit Transfer(address(0), msg.sender, numTokens);
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}