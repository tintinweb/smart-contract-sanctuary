/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
//                                                                                                                                                          
//WWWWWWWW                           WWWWWWWW     OOOOOOOOO     RRRRRRRRRRRRRRRRR      SSSSSSSSSSSSSSS HHHHHHHHH     HHHHHHHHHIIIIIIIIIIBBBBBBBBBBBBBBBBB   
//W::::::W                           W::::::W   OO:::::::::OO   R::::::::::::::::R   SS:::::::::::::::SH:::::::H     H:::::::HI::::::::IB::::::::::::::::B  
//W::::::W                           W::::::W OO:::::::::::::OO R::::::RRRRRR:::::R S:::::SSSSSS::::::SH:::::::H     H:::::::HI::::::::IB::::::BBBBBB:::::B 
//W::::::W                           W::::::WO:::::::OOO:::::::ORR:::::R     R:::::RS:::::S     SSSSSSSHH::::::H     H::::::HHII::::::IIBB:::::B     B:::::B
// W:::::W           WWWWW           W:::::W O::::::O   O::::::O  R::::R     R:::::RS:::::S              H:::::H     H:::::H    I::::I    B::::B     B:::::B
//  W:::::W         W:::::W         W:::::W  O:::::O     O:::::O  R::::R     R:::::RS:::::S              H:::::H     H:::::H    I::::I    B::::B     B:::::B
//   W:::::W       W:::::::W       W:::::W   O:::::O     O:::::O  R::::RRRRRR:::::R  S::::SSSS           H::::::HHHHH::::::H    I::::I    B::::BBBBBB:::::B 
//    W:::::W     W:::::::::W     W:::::W    O:::::O     O:::::O  R:::::::::::::RR    SS::::::SSSSS      H:::::::::::::::::H    I::::I    B:::::::::::::BB  
//     W:::::W   W:::::W:::::W   W:::::W     O:::::O     O:::::O  R::::RRRRRR:::::R     SSS::::::::SS    H:::::::::::::::::H    I::::I    B::::BBBBBB:::::B 
//      W:::::W W:::::W W:::::W W:::::W      O:::::O     O:::::O  R::::R     R:::::R       SSSSSS::::S   H::::::HHHHH::::::H    I::::I    B::::B     B:::::B
//       W:::::W:::::W   W:::::W:::::W       O:::::O     O:::::O  R::::R     R:::::R            S:::::S  H:::::H     H:::::H    I::::I    B::::B     B:::::B
//        W:::::::::W     W:::::::::W        O::::::O   O::::::O  R::::R     R:::::R            S:::::S  H:::::H     H:::::H    I::::I    B::::B     B:::::B
//         W:::::::W       W:::::::W         O:::::::OOO:::::::ORR:::::R     R:::::RSSSSSSS     S:::::SHH::::::H     H::::::HHII::::::IIBB:::::BBBBBB::::::B
//          W:::::W         W:::::W           OO:::::::::::::OO R::::::R     R:::::RS::::::SSSSSS:::::SH:::::::H     H:::::::HI::::::::IB:::::::::::::::::B 
//           W:::W           W:::W              OO:::::::::OO   R::::::R     R:::::RS:::::::::::::::SS H:::::::H     H:::::::HI::::::::IB::::::::::::::::B  
//            WWW             WWW                 OOOOOOOOO     RRRRRRRR     RRRRRRR SSSSSSSSSSSSSSS   HHHHHHHHH     HHHHHHHHHIIIIIIIIIIBBBBBBBBBBBBBBBBB   
//                                                                                                                                                          
// ----------------------------------------------------------------------------

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract Worshib is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    

    constructor() public {
        name = "WORSHIB Token";
        symbol = "WOSHIB";
        decimals = 18;
        _totalSupply = 10000000000000000000000000000;
        
        balances[msg.sender] = 10000000000000000000000000000;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}