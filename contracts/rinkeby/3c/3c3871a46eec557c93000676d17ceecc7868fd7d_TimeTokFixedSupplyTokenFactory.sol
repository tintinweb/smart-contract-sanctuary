/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity ^0.5.4;

// ----------------------------------------------------------------------------
// TimeTok's Fixed Supply Token 👊 + Factory v1.20-pre-release
//
// A factory to conveniently deploy your own source code verified fixed supply
// token contracts
//
// Factory deployment address: 0x{something}
//
// https://github.com/TimeTok/FixedSupplyTokenFactory
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
}


// ----------------------------------------------------------------------------
// Owned contract, with token recovery
// ----------------------------------------------------------------------------
contract Owned {
    bool initialised;
    address payable public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function init(address _owner) internal {
        require(!initialised);
        owner = address(uint160(_owner));
        initialised = true;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = address(uint160(newOwner));
        newOwner = address(0);
    }
    function recoverTokens(address token, uint tokens) public onlyOwner {
        if (token == address(0)) {
            owner.transfer((tokens == 0 ? address(this).balance : tokens));
        } else {
            ERC20Interface(token).transfer(owner, tokens == 0 ? ERC20Interface(token).balanceOf(address(this)) : tokens);
        }
    }
}


// ----------------------------------------------------------------------------
// ApproveAndCall Fallback
// NOTE for contracts implementing this interface:
// 1. An error must be thrown if there are errors executing `transferFrom(...)`
// 2. The calling token contract must be checked to prevent malicious behaviour
// ----------------------------------------------------------------------------
contract ApproveAndCallFallback {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}


// ----------------------------------------------------------------------------
// Token Interface = ERC20 + symbol + name + decimals + approveAndCall
// ----------------------------------------------------------------------------
contract TokenInterface is ERC20Interface {
    function symbol() public view returns (string memory);
    function name() public view returns (string memory);
    function decimals() public view returns (uint8);
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success);
}


// ----------------------------------------------------------------------------
// FixedSupplyToken 👊 = ERC20 + symbol + name + decimals + approveAndCall
// ----------------------------------------------------------------------------
contract FixedSupplyToken is TokenInterface, Owned {
    using SafeMath for uint;

    string _symbol;
    string  _name;
    uint8 _decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function init(address tokenOwner, string memory symbol, string memory name, uint8 decimals, uint fixedSupply) public {
        super.init(tokenOwner);
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = fixedSupply;
        balances[tokenOwner] = _totalSupply;
        emit Transfer(address(0), tokenOwner, _totalSupply);
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    // NOTE Only use this call with a trusted spender contract
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallback(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    function () external payable {
        revert();
    }
}


// ----------------------------------------------------------------------------
// TimeTok's Fixed Supply Token 👊 Factory
//
// Notes:
//   * The `newContractAddress` deprecation is just advisory
//   * A fee equal to or above `minimumFee` must be sent with the
//   `deployTokenContract(...)` call
//
// Execute `deployTokenContract(...)` with the following parameters to deploy
// your very own FixedSupplyToken contract:
//   symbol         symbol
//   name           name
//   decimals       number of decimal places for the token contract
//   totalSupply    the fixed token total supply
//
// For example, deploying a FixedSupplyToken contract with a `totalSupply`
// of 1,000.000000000000000000 tokens:
//   symbol         "ME"
//   name           "My Token"
//   decimals       18
//   initialSupply  10000000000000000000000 = 1,000.000000000000000000 tokens
//
// The TokenDeployed() event is logged with the following parameters:
//   owner          the account that execute this transaction
//   token          the newly deployed FixedSupplyToken address
//   symbol         symbol
//   name           name
//   decimals       number of decimal places for the token contract
//   totalSupply    the fixed token total supply
// ----------------------------------------------------------------------------
contract TimeTokFixedSupplyTokenFactory is Owned {
    using SafeMath for uint;

    address public newAddress;
    uint public minimumFee = 0.1 ether;
    mapping(address => bool) public isChild;
    address[] public children;

    event FactoryDeprecated(address _newAddress);
    event MinimumFeeUpdated(uint oldFee, uint newFee);
    event TokenDeployed(address indexed owner, address indexed token, string symbol, string name, uint8 decimals, uint totalSupply);

    constructor () public {
        super.init(msg.sender);
    }
    function numberOfChildren() public view returns (uint) {
        return children.length;
    }
    function deprecateFactory(address _newAddress) public onlyOwner {
        require(newAddress == address(0));
        emit FactoryDeprecated(_newAddress);
        newAddress = _newAddress;
    }
    function setMinimumFee(uint _minimumFee) public onlyOwner {
        emit MinimumFeeUpdated(minimumFee, _minimumFee);
        minimumFee = _minimumFee;
    }
    function deployTokenContract(string memory symbol, string memory name, uint8 decimals, uint totalSupply) public payable returns (FixedSupplyToken token) {
        require(msg.value >= minimumFee);
        require(decimals <= 27);
        require(totalSupply > 0);
        token = new FixedSupplyToken();
        token.init(msg.sender, symbol, name, decimals, totalSupply);
        isChild[address(token)] = true;
        children.push(address(token));
        emit TokenDeployed(owner, address(token), symbol, name, decimals, totalSupply);
        if (msg.value > 0) {
            owner.transfer(msg.value);
        }
    }
    function () external payable {
        revert();
    }
}