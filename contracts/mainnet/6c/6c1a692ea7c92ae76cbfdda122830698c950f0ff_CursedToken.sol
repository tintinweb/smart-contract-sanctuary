pragma solidity ^0.4.21;

contract ERC20 {
    function balanceOf(address tokenowner) public constant returns (uint);
    function allowance(address tokenowner, address spender) public constant returns (uint);
    function transfer(address to, uint tokencount) public returns (bool success);
    function approve(address spender, uint tokencount) public returns (bool success);
    function transferFrom(address from, address to, uint tokencount) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokencount);
    event Approval(address indexed tokenowner, address indexed spender, uint tokencount);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokencount, address token, bytes data) public;
}

contract CursedToken is ERC20 {
    string public symbol = "CCB";
    string public name = "Cursed Cornbread";
    uint8 public decimals = 0;
    uint public totalSupply = 0;
    address public owner = 0x55516b579E56C1287f0700eddDa352C2d2c5b3b6;

    // all funds will go to GiveDirectly charity 
    // https://web.archive.org/web/20180313215224/https://www.givedirectly.org/give-now?crypto=eth#
    address public withdrawAddress = 0xa515BDA9869F619fe84357E3e44040Db357832C4;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function CursedToken() public {
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function balanceOf(address tokenowner) public constant returns (uint) {
        return balances[tokenowner];
    }

    function allowance(address tokenowner, address spender) public constant returns (uint) {
        return allowed[tokenowner][spender];
    }

    function transfer(address to, uint tokencount) public returns (bool success) {
        require(msg.sender==to || 0==tokencount);
        balances[msg.sender] = sub(balances[msg.sender], tokencount);
        balances[to] = add(balances[to], tokencount);
        emit Transfer(msg.sender, to, tokencount);
        return true;
    }

    function approve(address spender, uint tokencount) public returns (bool success) {
        allowed[msg.sender][spender] = tokencount;
        emit Approval(msg.sender, spender, tokencount);
        return true;
    }

    function issue(address to, uint tokencount) public returns (bool success) {
        require(msg.sender==owner);
        balances[to] = add(balances[to], tokencount);
        totalSupply += tokencount;
        emit Transfer(address(0), to, tokencount);
        return true;
    }

    function transferFrom(address from, address to, uint tokencount) public returns (bool success) {
        require(from==to || 0==tokencount);
        balances[from] = sub(balances[from], tokencount);
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokencount);
        balances[to] = add(balances[to], tokencount);
        emit Transfer(from, to, tokencount);
        return true;
    }

    function approveAndCall(address spender, uint tokencount, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokencount;
        emit Approval(msg.sender, spender, tokencount);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokencount, this, data);
        return true;
    }

    // Anyone can send the ether in the contract at any time to charity
    function withdraw() public returns (bool success) {
        withdrawAddress.transfer(address(this).balance);
        return true;
    }

    function () public payable {
    }

}