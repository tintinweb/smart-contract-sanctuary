pragma solidity ^0.8.0;

import "IERC20.sol";



contract Sep06Token is IERC20 {
    string public constant name = "Sep06Token";
    string public constant symbol = "STN";
    uint8 public constant decimals = 6;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 1_000_000_000_000_000;

    address public owner;

    using SafeMath for uint256;

    constructor() public {
        balances[msg.sender] = totalSupply_;
        owner = msg.sender;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender], "Not enough tokens (0)");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner_, address delegate) public override view returns (uint) {
        return allowed[owner_][delegate];
    }

    function transferFrom(address owner_, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner_], "Not enough tokens (1)");
        require(numTokens <= allowed[owner_][msg.sender], "Not enough tokens (2)");

        balances[owner_] = balances[owner_].sub(numTokens);
        allowed[owner_][msg.sender] = allowed[owner_][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner_, buyer, numTokens);
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