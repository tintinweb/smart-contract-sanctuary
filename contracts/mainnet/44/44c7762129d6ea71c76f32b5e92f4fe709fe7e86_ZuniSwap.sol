pragma solidity ^0.7.1;


// Twitter: https://twitter.com/zuniswap
contract ZuniSwap {
    string public name     = "ZUN";
    string public symbol   = "ZuniSwap";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    uint256 private constant T_SUPPLY = 1000 * 10 ** 18;

    constructor() {
        emit Transfer(address(0), msg.sender, T_SUPPLY);
        balanceOf[msg.sender] = T_SUPPLY;
    }

    function totalSupply() external pure returns (uint) {
        return T_SUPPLY;
    }

    function approve(address guy, uint wad) external returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(src == msg.sender || allowance[src][msg.sender] >= T_SUPPLY);

        uint256 bal = balanceOf[src];
        require(bal >= wad);
        balanceOf[src] = bal - wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}