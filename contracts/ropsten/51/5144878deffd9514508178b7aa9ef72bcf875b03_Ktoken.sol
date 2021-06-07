/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ktoken {
    string public constant name = "Ktoken";
    string public constant symbol = "Ktoken";
    uint8 public constant decimals = 18;
    uint256 public INITIAL_SUPPLY = 1000000000000;

    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event _mint(address reciever, uint256 amount);

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    uint256 totalSupply_;

    address private _admin =
        address(0x1Bf87D4d8049AEd774Fe118971e87a315819e772);

    using SafeMath for uint256;

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
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

    function approve(address delegate, uint256 numTokens)
        public
        returns (bool)
    {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
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

    modifier onlyAdmin(address _address) {
        require(msg.sender == _address, "Invalid admin address!");
        _;
    }

    function mint(address receiver, uint256 amount)
        public
        onlyAdmin(msg.sender)
        returns (bool)
    {
        balances[receiver] = balances[receiver].add(amount);
        emit _mint(receiver, amount);
        return true;
    }

    function updateAdmin(address newAdmin) public onlyAdmin(msg.sender) returns (bool) {
        
        _admin=newAdmin;
        return true;
    }

    function getSymbol() public pure returns (string memory) {
        return symbol;
    }

    function getName() public pure returns (string memory) {
        return name;
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