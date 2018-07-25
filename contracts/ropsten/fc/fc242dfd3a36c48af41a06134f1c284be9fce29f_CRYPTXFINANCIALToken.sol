pragma solidity ^0.4.24;

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

contract Interface {
    function Supply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);

}

contract CRYPTXFINANCIALToken is Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;
    address owner;

    mapping(address => uint) public balanceOf;
    mapping (address => bool) public frozenAccount;

    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);

    constructor() public {
        symbol = &quot;CRYPTXALP&quot;;
        name = &quot;CRYPTX FINANCIAL Token&quot;;
        decimals = 18;
        owner = msg.sender;
        totalSupply = 250000000000000000000000000;
        balanceOf[0xE184B6Ab25b93af0C69d861AE3fb04Ed46e975BE] = 162500000000000000000000000;
        balanceOf[0xee8E5F10D7af6b24D975437113DF615e8AaDdd68] = 37500000000000000000000000;
        balanceOf[0xd8BD8f9727551f9020B2FB5f31fd70695a580E10] = 25000000000000000000000000;
        balanceOf[0x56573670d5C93eEdEA152CE9d0C7FCb9069EF8ab] = 12500000000000000000000000;
        balanceOf[0x34cbA53790768a24BFc9967874aEacda3EF0f0A2] = 6250000000000000000000000;
        balanceOf[0x2EBe0DDA227a86ddBb57236a37b4467f9214C28d] = 1250000000000000000000000;
        balanceOf[0x55d9cf37A28b2B7447F9e325D82cBc0A47F714E8] = 5000000000000000000000000;
        emit Transfer(address(0), 0xE184B6Ab25b93af0C69d861AE3fb04Ed46e975BE,162500000000000000000000000 );
        emit Transfer(address(0), 0xee8E5F10D7af6b24D975437113DF615e8AaDdd68,37500000000000000000000000 );
        emit Transfer(address(0), 0xd8BD8f9727551f9020B2FB5f31fd70695a580E10,25000000000000000000000000 );
        emit Transfer(address(0), 0x56573670d5C93eEdEA152CE9d0C7FCb9069EF8ab,12500000000000000000000000 );
        emit Transfer(address(0), 0x34cbA53790768a24BFc9967874aEacda3EF0f0A2,6250000000000000000000000 );
        emit Transfer(address(0), 0x2EBe0DDA227a86ddBb57236a37b4467f9214C28d,1250000000000000000000000 );
        emit Transfer(address(0), 0x55d9cf37A28b2B7447F9e325D82cBc0A47F714E8,5000000000000000000000000 );
    
    }

    function Supply() public constant returns (uint) {
        return totalSupply  - balanceOf[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balanceOf[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != 0x0);
        require(tokens > 0);
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[to]);
        require(balanceOf[msg.sender] >= tokens);
        require(safeAdd(balanceOf[to], tokens) >= balanceOf[to]);

        uint256 previousBalances = safeAdd(balanceOf[msg.sender], balanceOf[to]);

        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        require(balanceOf[msg.sender] + balanceOf[to] == previousBalances);
        return true;
    }

    function freezeAccount(address target, bool freeze)  public {
        require(msg.sender == owner);
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     function burn(uint256 amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], amount);
        totalSupply = safeSub(totalSupply, amount);
        emit Burn(msg.sender, amount);
        return true;
    }

    function () public payable {
        revert();
    }

}