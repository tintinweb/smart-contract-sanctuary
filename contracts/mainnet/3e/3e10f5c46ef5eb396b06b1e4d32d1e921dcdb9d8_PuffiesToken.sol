/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

/**
 * 
                                                                                                                                                             
                                         ffffffffffffffff    ffffffffffffffff    iiii                                                 iiii                   
                                        f::::::::::::::::f  f::::::::::::::::f  i::::i                                               i::::i                  
                                       f::::::::::::::::::ff::::::::::::::::::f  iiii                                                 iiii                   
                                       f::::::fffffff:::::ff::::::fffffff:::::f                                                                              
ppppp   ppppppppp   uuuuuu    uuuuuu   f:::::f       fffffff:::::f       ffffffiiiiiii     eeeeeeeeeeee        ssssssssss           iiiiiii    ooooooooooo   
p::::ppp:::::::::p  u::::u    u::::u   f:::::f             f:::::f             i:::::i   ee::::::::::::ee    ss::::::::::s          i:::::i  oo:::::::::::oo 
p:::::::::::::::::p u::::u    u::::u  f:::::::ffffff      f:::::::ffffff        i::::i  e::::::eeeee:::::eess:::::::::::::s          i::::i o:::::::::::::::o
pp::::::ppppp::::::pu::::u    u::::u  f::::::::::::f      f::::::::::::f        i::::i e::::::e     e:::::es::::::ssss:::::s         i::::i o:::::ooooo:::::o
 p:::::p     p:::::pu::::u    u::::u  f::::::::::::f      f::::::::::::f        i::::i e:::::::eeeee::::::e s:::::s  ssssss          i::::i o::::o     o::::o
 p:::::p     p:::::pu::::u    u::::u  f:::::::ffffff      f:::::::ffffff        i::::i e:::::::::::::::::e    s::::::s               i::::i o::::o     o::::o
 p:::::p     p:::::pu::::u    u::::u   f:::::f             f:::::f              i::::i e::::::eeeeeeeeeee        s::::::s            i::::i o::::o     o::::o
 p:::::p    p::::::pu:::::uuuu:::::u   f:::::f             f:::::f              i::::i e:::::::e           ssssss   s:::::s          i::::i o::::o     o::::o
 p:::::ppppp:::::::pu:::::::::::::::uuf:::::::f           f:::::::f            i::::::ie::::::::e          s:::::ssss::::::s        i::::::io:::::ooooo:::::o
 p::::::::::::::::p  u:::::::::::::::uf:::::::f           f:::::::f            i::::::i e::::::::eeeeeeee  s::::::::::::::s  ...... i::::::io:::::::::::::::o
 p::::::::::::::pp    uu::::::::uu:::uf:::::::f           f:::::::f            i::::::i  ee:::::::::::::e   s:::::::::::ss   .::::. i::::::i oo:::::::::::oo 
 p::::::pppppppp        uuuuuuuu  uuuufffffffff           fffffffff            iiiiiiii    eeeeeeeeeeeeee    sssssssssss     ...... iiiiiiii   ooooooooooo   
 p:::::p                                                                                                                                                     
 p:::::p                                                                                                                                                     
p:::::::p                                                                                                                                                    
p:::::::p                                                                                                                                                    
p:::::::p                                                                                                                                                    
ppppppppp                                                                                                                                                    
                                                                                                                                                             

*/

pragma solidity ^0.5.0;


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


contract PuffiesToken is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    

    constructor() public {
        name = "PuffiesToken | Puffies.io";
        symbol = "PUFF";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        
        balances[msg.sender] = 100000000000000000000000000;
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