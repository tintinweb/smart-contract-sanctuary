/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

pragma solidity 0.6.6;
// ----------------------------------------------------------------------------
// 'Pink Panda' token contract
//
//                             _,add8ba,
//                            ,d888888888b,
//                           d8888888888888b                        _,ad8ba,_
//                          d888888888888888)                     ,d888888888b,
//                          I8888888888888888 _________          ,8888888888888b
//                __________`Y88888888888888P"""""""""""baaa,__ ,888888888888888,
//            ,adP"""""""""""9888888888P""^                 ^""Y8888888888888888I
//         ,a8"^           ,d888P"888P^                           ^"Y8888888888P'
//       ,a8^            ,d8888'                                     ^Y8888888P'
//      a88'           ,d8888P'                                        I88P"^
//    ,d88'           d88888P'                                          "b,
//   ,d88'           d888888'                                            `b,
//  ,d88'           d888888I                                              `b,
//  d88I           ,8888888'            ___                                `b,
// ,888'           d8888888          ,d88888b,              ____            `b,
// d888           ,8888888I         d88888888b,           ,d8888b,           `b
//,8888           I8888888I        d8888888888I          ,88888888b           8,
//I8888           88888888b       d88888888888'          8888888888b          8I
//d8886           888888888       Y888888888P'           Y8888888888,        ,8b
//88888b          I88888888b      `Y8888888^             `Y888888888I        d88,
//Y88888b         `888888888b,      `""""^                `Y8888888P'       d888I
//`888888b         88888888888b,                           `Y8888P^        d88888
// Y888888b       ,8888888888888ba,_          _______        `""^        ,d888888
// I8888888b,    ,888888888888888888ba,_     d88888888b               ,ad8888888I
// `888888888b,  I8888888888888888888888b,    ^"Y888P"^      ____.,ad88888888888I
//  88888888888b,`888888888888888888888888b,     ""      ad888888888888888888888'
//  8888888888888698888888888888888888888888b_,ad88ba,_,d88888888888888888888888
//  88888888888888888888888888888888888888888b,`"""^ d8888888888888888888888888I
//  8888888888888888888888888888888888888888888baaad888888888888888888888888888'
//  Y8888888888888888888888888888888888888888888888888888888888888888888888888P
//  I888888888888888888888888888888888888888888888P^  ^Y8888888888888888888888'
//  `Y88888888888888888P88888888888888888888888888'     ^88888888888888888888I
//   `Y8888888888888888 `8888888888888888888888888       8888888888888888888P'
//    `Y888888888888888  `888888888888888888888888,     ,888888888888888888P'
//     `Y88888888888888b  `88888888888888888888888I     I888888888888888888'
//       "Y8888888888888b  `8888888888888888888888I     I88888888888888888'
//         "Y88888888888P   `888888888888888888888b     d8888888888888888'
//            ^""""""""^     `Y88888888888888888888,    888888888888888P'
//                             "8888888888888888888b,   Y888888888888P^
//                              `Y888888888888888888b   `Y8888888P"^
//                                "Y8888888888888888P     `""""^
//                                  `"YY88888888888P'

// Deployed to : 0xCFCC41ccC8392f48bfc952e01F38FaF33E02Eaad
// Symbol      : PINKPANDA
// Name        : Pink Panda 
// Total supply: 500000000000000000000
// Decimals    : 9
//
// Enjoy.
//
// (c) by Pink Panda Team.

// ----------------------------------------------------------------------------

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}



contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



contract PINKPANDA is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;



    constructor() public {
        symbol = "PINKPANDA";
        name = "Pink Panda";
        decimals = 9;
        _totalSupply = 500000000 * 10**6 * 10**9;
        balances[0xCFCC41ccC8392f48bfc952e01F38FaF33E02Eaad] = _totalSupply;
        emit Transfer(address(0), 0xCFCC41ccC8392f48bfc952e01F38FaF33E02Eaad, _totalSupply);
    }



    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }



    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }



    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }



    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }



    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }




    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}