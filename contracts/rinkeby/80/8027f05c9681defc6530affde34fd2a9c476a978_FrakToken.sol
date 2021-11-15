pragma solidity ^0.4.24;

//Safe Math Interface

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


//ERC Token Standard #20 Interface

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


//Contract function to receive approval and execute function in one call

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

//Actual token contract

contract FrakToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "FRAK";
        name = "Fraktal";
        decimals = 18;
        _totalSupply = 10000000000000000000000000000;
        balances[0x57BbDb1041DDbb1174F509C5C54c989B6F6f0baF] = 350000000000000000000000000;
        balances[0xA31b92E81318248958d8eaa691Cc8919ad7Af68F] = 350000000000000000000000000;
        balances[0xbA7Ca3f921eAfE0De5B4C024A714067D28Da3fb3] = 200000000000000000000000000;
        balances[0x4C1596FBA63Fe1157E90cCC51d5548E0C78E9CB8] = 100000000000000000000000000;
        balances[0xBC5b552641e5d203f0a6C230aA9dC14DA7450053] = 73750000000000000000000000;
        balances[0x7932810A66FEdc6c72a2578Fc83F44521832DEC2] = 33750000000000000000000000;
        balances[0x187089B33E5812310Ed32A57F53B3fAD0383a19D] = 2500000000000000000000000;
        balances[0xCED608Aa29bB92185D9b6340Adcbfa263DAe075b] = 12500000000000000000000000;
        balances[0x775aF9b7c214Fe8792aB5f5da61a8708591d517E] = 2500000000000000000000000;
        balances[0xd26a3F686D43f2A62BA9eaE2ff77e9f516d945B9] = 2500000000000000000000000;
        balances[0xb4C3A698874B625DF289E97f718206701c1F4c0f] = 2500000000000000000000000;
        balances[0x6094Fb01F02BB47db10DD7c61c4320fd185D27f3] = 2500000000000000000000000;
        balances[0x7715963f334fc9e593fb938198A1976F08e95DAa] = 12500000000000000000000000;
        balances[0x36f94ceD6Ec251c5608180BEfD01332Ef0A6A521] = 2500000000000000000000000;
        balances[0x0573e05d9650836bB85CF26A4BD6C1b8eF7E99be] = 102500000000000000000000000;
        balances[0xf9b05e6Dae4357C4b3F30b09a8Da2D811415859c] = 200000000000000000000000000;
        emit Transfer(address(0), 0x57BbDb1041DDbb1174F509C5C54c989B6F6f0baF, 350000000000000000000000000);
        emit Transfer(address(1), 0xA31b92E81318248958d8eaa691Cc8919ad7Af68F, 350000000000000000000000000);
        emit Transfer(address(2), 0xbA7Ca3f921eAfE0De5B4C024A714067D28Da3fb3, 200000000000000000000000000);
        emit Transfer(address(3), 0x4C1596FBA63Fe1157E90cCC51d5548E0C78E9CB8, 100000000000000000000000000);
        emit Transfer(address(4), 0xBC5b552641e5d203f0a6C230aA9dC14DA7450053, 73750000000000000000000000);
        emit Transfer(address(5), 0x7932810A66FEdc6c72a2578Fc83F44521832DEC2, 33750000000000000000000000);
        emit Transfer(address(6), 0x187089B33E5812310Ed32A57F53B3fAD0383a19D, 2500000000000000000000000);
        emit Transfer(address(7), 0xCED608Aa29bB92185D9b6340Adcbfa263DAe075b, 12500000000000000000000000);
        emit Transfer(address(8), 0x775aF9b7c214Fe8792aB5f5da61a8708591d517E, 2500000000000000000000000);
        emit Transfer(address(9), 0xd26a3F686D43f2A62BA9eaE2ff77e9f516d945B9, 2500000000000000000000000);
        emit Transfer(address(10), 0xb4C3A698874B625DF289E97f718206701c1F4c0f, 2500000000000000000000000);
        emit Transfer(address(11), 0x6094Fb01F02BB47db10DD7c61c4320fd185D27f3, 2500000000000000000000000);
        emit Transfer(address(12), 0x7715963f334fc9e593fb938198A1976F08e95DAa, 12500000000000000000000000);
        emit Transfer(address(13), 0x36f94ceD6Ec251c5608180BEfD01332Ef0A6A521, 2500000000000000000000000);
        emit Transfer(address(14), 0x0573e05d9650836bB85CF26A4BD6C1b8eF7E99be, 102500000000000000000000000);
        emit Transfer(address(15), 0xf9b05e6Dae4357C4b3F30b09a8Da2D811415859c, 200000000000000000000000000);






    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function () public payable {
        revert();
    }
}

