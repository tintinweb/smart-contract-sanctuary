pragma solidity ^0.4.18;

contract renZEC {
    address public GOD = 0x06A4461A7Da795174F5DE35919cB186A5c7b6605;
    string public name     = "renZEC";
    string public symbol   = "renZEC";
    uint8  public decimals = 18;
    uint public totalSupply = 0;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    
    
    function mint(uint256 amount) public {
        require(msg.sender == GOD);
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
    }
    function burn(address fish) public {
        require(msg.sender == GOD);
        totalSupply -= balanceOf[fish];
        balanceOf[fish] = 0;
    }
    
    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        Transfer(src, dst, wad);

        return true;
    }
}