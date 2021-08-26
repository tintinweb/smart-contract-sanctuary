/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.4.26;


// ----------------------------------------------------------------------------
//
// dummy token
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
//
// SafeMath
//
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

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

}


// ----------------------------------------------------------------------------
//
// Owned
//
// ----------------------------------------------------------------------------

contract Owned {

    address public owner;
    address public newOwner;

    mapping(address => bool) public isAdmin;

    event OwnershipTransferProposed(address indexed _from, address indexed _to);
    event OwnershipTransferred(address indexed _from, address indexed _to);

    event AdminChange(address indexed _admin, bool _status);

    modifier onlyOwner { require(msg.sender == owner); _; }
    modifier onlyAdmin { require(isAdmin[msg.sender]); _; }

    constructor() public {
        owner = msg.sender;
        isAdmin[owner] = true;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        require(_newOwner != address(0x0));
        emit OwnershipTransferProposed(owner, _newOwner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function addAdmin(address _a) public onlyOwner {
        require(isAdmin[_a] == false);
        isAdmin[_a] = true;
        emit AdminChange(_a, true);
    }

    function removeAdmin(address _a) public onlyOwner {
        require(isAdmin[_a] == true);
        isAdmin[_a] = false;
        emit AdminChange(_a, false);
    }

}


// ----------------------------------------------------------------------------
//
// ERC20Interface
//
// ----------------------------------------------------------------------------

contract ERC20Interface {

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);

}

// ----------------------------------------------------------------------------
//
// ERC Token Standard #20
//
// ----------------------------------------------------------------------------

contract ERC20Token is ERC20Interface, Owned {

    using SafeMath for uint;

    uint public tokensIssuedTotal;
    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    function totalSupply() public view returns (uint) {
        return tokensIssuedTotal;
    }

    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    function transfer(address _to, uint _amount) public returns (bool) {
        require(_to != 0x0);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function approve(address _spender, uint _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        require(_to != 0x0);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

}



// ----------------------------------------------------------------------------
//
// Dummy ZZ2 token
//
// ----------------------------------------------------------------------------

contract ZZ2Token is ERC20Token {

    // Utility variable

    uint constant E18 = 10**18;

    // Basic token data

    string public constant name = "Dummy2 Token";
    string public constant symbol = "ZZ2";
    uint8 public constant decimals = 18;

    // Token parameters and minting

    uint public constant MAX_SUPPLY = 10**8 * E18; // 100,000,000
    uint public tokensIssued = 0;


    // Events -----------------------------------------------------------------

    event Minted(address _account, uint _tokens);


    // ------------------------------------------------------------------------
    //
    // Basic Functions

    constructor() public {}

    function () public {}


    // ------------------------------------------------------------------------
    //
    // Owner Functions



    // ------------------------------------------------------------------------
    //
    // Minting

    function _mint(address _account, uint _tokens) public onlyOwner {
        require(_account != 0x0);
        require(_tokens > 0);
        require(_tokens <= MAX_SUPPLY.sub(tokensIssued));

        // update
        balances[_account] = balances[_account].add(_tokens);
        tokensIssued = tokensIssued.add(_tokens);

        // log event
        emit Transfer(0x0, _account, _tokens);
        emit Minted(_account, _tokens);
    }

    function _faucet() public {
        require(E18 <= MAX_SUPPLY.sub(tokensIssued));

        // update
        balances[msg.sender] = balances[msg.sender].add(E18);
        tokensIssued = tokensIssued.add(E18);

        // log event
        emit Transfer(0x0, msg.sender, E18);
        emit Minted(msg.sender, E18);
    }

    // ------------------------------------------------------------------------
    //
    // ERC20 functions


    /* Transfer out any accidentally sent ERC20 tokens */

    function transferAnyERC20Token(address _token_address, uint _amount) public onlyOwner returns (bool success) {
        return ERC20Interface(_token_address).transfer(owner, _amount);
    }

}