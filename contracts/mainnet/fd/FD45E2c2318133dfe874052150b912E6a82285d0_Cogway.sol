/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;


abstract contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) virtual public view returns (uint256);
    function transfer(address to, uint256 value) virtual public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) virtual public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) virtual public returns (bool);
    function approve(address spender, uint256 value) virtual public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function isOwnable() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract BasicToken is Ownable, ERC20Basic {

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    function transfer(address to, uint256 value) public override(ERC20Basic) returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);

        assert(balances[msg.sender] <= value);
        balances[msg.sender] = balances[msg.sender] - (value);
        balances[to] = balances[to]+(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function balanceOf(address _owner) public override(ERC20Basic) view returns (uint256 balance) {
        return balances[_owner];
    }
    function transferFrom(address from, address to, uint256 value) public override(ERC20Basic) returns (bool) {
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        assert(balances[from] <= value);
        balances[from] = balances[from]- (value);
        balances[to] = balances[to] + (value);
        allowed[from][msg.sender] = allowed[from][msg.sender] - (value);
        emit Transfer(from, to, value);
        return true;
    }
    function approve(address spender, uint256 value) public override(ERC20Basic) returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function allowance(address owner, address spender) public override(ERC20Basic) view returns (uint256) {
        return allowed[owner][spender];
    }
    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender] + (addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            assert(oldValue <= subtractedValue);
            allowed[msg.sender][spender] = oldValue - (subtractedValue);
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;
    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    function mint(address to, uint256 amount) onlyOwner canMint virtual public returns (bool) {
        totalSupply = totalSupply+(amount);
        balances[to] = balances[to]+(amount);
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
    event Burn(address indexed burner, uint256 value);
    function burn(uint256 _amount) public {
        require(_amount <= balances[msg.sender]);
        address burner = msg.sender;
        assert(balances[burner] <= _amount);
        balances[burner] = balances[burner] - (_amount);
        assert(totalSupply <= _amount);
        totalSupply = totalSupply - (_amount);
        emit Burn(burner, _amount);
    }
}

/*contract ICogwayToken is Ownable, VariableSupplyToken {
function mint(address to, uint256 amount) public override(MintableToken) returns (bool);
function burn(uint256 _amount) public override(VariableSupplyToken);
}*/

contract Cogway is BasicToken {
    string public name = "Cogway Token";
    uint8 public decimals = 8;
    string public symbol = "COG";
    string public version = "0.1";
    constructor(uint256 total_supply) {
        totalSupply += total_supply;
    }
}