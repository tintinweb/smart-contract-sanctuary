/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

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
 
contract MSCIToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor() public {
        symbol = "MSCI";
        name = "MSCI DeFi presentation 5/28/2021 Commemorative Coin";
        decimals = 0;
        _totalSupply = 47;
        balances[0xea4Cc82A9D19037BA90A4e2aFa6b7D09ddd90698] = 10;
        balances[0x40f35708670714982F402316f5a64C45bFb993a1] = 1;
        balances[0xB787A749e0d1f7c36Ca5856c9806ae9AE077a687] = 1;
        balances[0x40C7D020D94d0031b47969F92aC25EE7d3F83ff0] = 1;
        balances[0x15014798BE3E92051AbC72E4C0B621fF219e06eD] = 1;
        balances[0xE611afD2b1F6f62C7c9c595564cB8E114Fd79EAf] = 1;
        balances[0x0a6249bae0e45718b8b46F97A81fb0b3483e1329] = 1;
        balances[0xF85397854F372cB8AA5755147eb0E90810819a3f] = 1;
        balances[0xf0342863e821d0dC0dc8e54c4797E370b7978F33] = 1;
        balances[0x289D13050D80bBE0a3eC82b6bd329f380A237346] = 1;
        balances[0x4c49aADa8259a5bD41f58673C351d48a54EaF5Fe] = 1;
        balances[0x0338e2f97da50f1FEEe866caF6cED20f8dC26478] = 1;
        balances[0xac0fF19E56be4e62D6280EF76B43405FeB65075F] = 1;
        balances[0x2d1cF4c79c3483bdb730f4b310034e43b9a77E2d] = 1;
        balances[0xF5a0383910653505919A70914BEabACF73fc3c36] = 1;
        balances[0x1caD64C2f93d79ab6301E0A2fdd9A982a9F613F7] = 1;
        balances[0x56D7eE276640009D5D75f5943644901F005B400D] = 1;
        balances[0xfA40496E6f411542009a38E02dDBC11c41d71D9C] = 1;
        balances[0xb49011Bb6Fd3471e6e506b0d6a511378b057E43f] = 1;
        balances[0xB4A958214056Da974EB2e3431a66E755D4d05268] = 1;
        balances[0xD968156BCD7ACF8ecbc0C5286198d64630E67066] = 1;
        balances[0x52b61c09Ca55f7044161fFbBc496c842E54ef9f5] = 1;
        balances[0xe31794Ad9844A8618b376C1e2be0Cc23d4Ce4315] = 1;
        balances[0x8A85FC5DFD2450279a8291765F44aa49712A2139] = 1;
        balances[0x19eDfce4ec520585876970C1D3E5924D85D2110b] = 1;
        balances[0xC92A50483E9CC414A0D81ACFD31276CAcFB314bd] = 1;
        balances[0x0D24BC33d51c8d906a4300737d7141E97Df52bFd] = 1;
        balances[0x98D5e71Ed45E4Ced3b5715De289E736BE37C9953] = 1;
        balances[0xa1bE6f95A43Fe1D17cA06D6249a8368d4820ABb7] = 1;
        balances[0x4a891722A81D7bD02A54fE7b96ceFd8341CFc978] = 1;
        balances[0xeFA0dDCF3d488E7cA88098c5E6d790a130735159] = 1;
        balances[0x35Ce5B836Fc32d26f31C1b510e100684a9639d3F] = 1;
        balances[0x3DC807F2Bfc3256c98dB37EC386490Cc7f368D2c] = 1;
        balances[0x660006A8CF246Cd33cF40DC5cC057d3AAEA95968] = 1;
        balances[0x31306858091113a1e541824eA57D53e1aD59B339] = 1;
        balances[0x5f7AeD347aF04CADe683C1022f5eA8E004Ec2da2] = 1;
        balances[0xF774A897095336AC71758302De5cC01755d335CB] = 1;
        balances[0xE016dd7C04665D0F23b8161314BdDA9424b51a04] = 1;
        
        emit Transfer(address(0), 0xea4Cc82A9D19037BA90A4e2aFa6b7D09ddd90698, 1);
        emit Transfer(address(0), 0x40f35708670714982F402316f5a64C45bFb993a1, 1);
        emit Transfer(address(0), 0xB787A749e0d1f7c36Ca5856c9806ae9AE077a687, 1);
        emit Transfer(address(0), 0x40C7D020D94d0031b47969F92aC25EE7d3F83ff0, 1);
        emit Transfer(address(0), 0x15014798BE3E92051AbC72E4C0B621fF219e06eD, 1);
        emit Transfer(address(0), 0xE611afD2b1F6f62C7c9c595564cB8E114Fd79EAf, 1);
        emit Transfer(address(0), 0x0a6249bae0e45718b8b46F97A81fb0b3483e1329, 1);
        emit Transfer(address(0), 0xF85397854F372cB8AA5755147eb0E90810819a3f, 1);
        emit Transfer(address(0), 0xf0342863e821d0dC0dc8e54c4797E370b7978F33, 1);
        emit Transfer(address(0), 0x289D13050D80bBE0a3eC82b6bd329f380A237346, 1);
        emit Transfer(address(0), 0x4c49aADa8259a5bD41f58673C351d48a54EaF5Fe, 1);
        emit Transfer(address(0), 0x0338e2f97da50f1FEEe866caF6cED20f8dC26478, 1);
        emit Transfer(address(0), 0xac0fF19E56be4e62D6280EF76B43405FeB65075F, 1);
        emit Transfer(address(0), 0x2d1cF4c79c3483bdb730f4b310034e43b9a77E2d, 1);
        emit Transfer(address(0), 0xF5a0383910653505919A70914BEabACF73fc3c36, 1);
        emit Transfer(address(0), 0x1caD64C2f93d79ab6301E0A2fdd9A982a9F613F7, 1);
        emit Transfer(address(0), 0x56D7eE276640009D5D75f5943644901F005B400D, 1);
        emit Transfer(address(0), 0xfA40496E6f411542009a38E02dDBC11c41d71D9C, 1);
        emit Transfer(address(0), 0xb49011Bb6Fd3471e6e506b0d6a511378b057E43f, 1);
        emit Transfer(address(0), 0xB4A958214056Da974EB2e3431a66E755D4d05268, 1);
        emit Transfer(address(0), 0xD968156BCD7ACF8ecbc0C5286198d64630E67066, 1);
        emit Transfer(address(0), 0x52b61c09Ca55f7044161fFbBc496c842E54ef9f5, 1);
        emit Transfer(address(0), 0xe31794Ad9844A8618b376C1e2be0Cc23d4Ce4315, 1);
        emit Transfer(address(0), 0x8A85FC5DFD2450279a8291765F44aa49712A2139, 1);
        emit Transfer(address(0), 0x19eDfce4ec520585876970C1D3E5924D85D2110b, 1);
        emit Transfer(address(0), 0xC92A50483E9CC414A0D81ACFD31276CAcFB314bd, 1);
        emit Transfer(address(0), 0x0D24BC33d51c8d906a4300737d7141E97Df52bFd, 1);
        emit Transfer(address(0), 0x98D5e71Ed45E4Ced3b5715De289E736BE37C9953, 1);
        emit Transfer(address(0), 0xa1bE6f95A43Fe1D17cA06D6249a8368d4820ABb7, 1);
        emit Transfer(address(0), 0x4a891722A81D7bD02A54fE7b96ceFd8341CFc978, 1);
        emit Transfer(address(0), 0xeFA0dDCF3d488E7cA88098c5E6d790a130735159, 1);
        emit Transfer(address(0), 0x35Ce5B836Fc32d26f31C1b510e100684a9639d3F, 1);
        emit Transfer(address(0), 0x3DC807F2Bfc3256c98dB37EC386490Cc7f368D2c, 1);
        emit Transfer(address(0), 0x660006A8CF246Cd33cF40DC5cC057d3AAEA95968, 1);
        emit Transfer(address(0), 0x31306858091113a1e541824eA57D53e1aD59B339, 1);
        emit Transfer(address(0), 0x5f7AeD347aF04CADe683C1022f5eA8E004Ec2da2, 1);
        emit Transfer(address(0), 0xF774A897095336AC71758302De5cC01755d335CB, 1);
        emit Transfer(address(0), 0xE016dd7C04665D0F23b8161314BdDA9424b51a04, 1);
        
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