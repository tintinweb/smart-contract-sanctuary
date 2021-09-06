/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

pragma solidity ^0.4.26;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract wBBT {
    string public name     = "wBUYBACK";
    string public symbol   = "wBBT";
    uint8  public decimals = 18;
    uint256 public totalSupply = 0;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    
    address constant public buybackToken = 0xB3670F91E86a96EeDA0c75b1573035A6277226fb;
    IERC20 Token = IERC20(buybackToken);

    function deposit(uint wad) public {
        require(Token.balanceOf(msg.sender) >= wad, "Insufficient balance.");
        Token.transferFrom(msg.sender, address(this), wad);
        balanceOf[msg.sender] += wad;
        totalSupply += wad;
        emit Deposit(msg.sender, wad);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad, "Insufficient balance.");
        balanceOf[msg.sender] -= wad;
        totalSupply -= wad;
        Token.transfer(msg.sender, wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return totalSupply;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
    public
    returns (bool)
    {
        require(balanceOf[src] >= wad, "Insufficient balance.");

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