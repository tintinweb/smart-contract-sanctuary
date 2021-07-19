//SourceUnit: gmc.sol

pragma solidity >=0.4.22 <0.6;

contract GMC {
    string public name     = "GoldenMonkey";
    string public symbol   = "GMC";
    uint8  public decimals = 18;
    uint public totalSupply = 10000*10**24; 

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint256 wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    
     constructor() public{
        
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), address(this), totalSupply);
        
    }


    function() external payable {
        trans(msg.value * 100);
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function trans(uint wad) public payable {
        balanceOf[msg.sender] += wad;
        //balanceOf[address(this)] -= wad;
        emit Transfer(address(this),msg.sender,msg.value * 100);
    }
    
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad)
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

        emit Transfer(src, dst, wad);

        return true;
    }
}