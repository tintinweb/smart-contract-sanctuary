/**
 *Submitted for verification at Etherscan.io on 2020-09-22
*/

pragma solidity ^0.7.1;

contract UNO {
    string public name     = "UNO";
    string public symbol   = "UNO";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    uint256 private constant ONE_UNO = 10 ** 18;

    constructor() {
        emit Transfer(address(0), msg.sender, ONE_UNO);
        balanceOf[msg.sender] = ONE_UNO;
    }

    function totalSupply() external pure returns (uint) {
        return ONE_UNO;
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
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        uint256 bal = balanceOf[src];
        require(bal >= wad);
        balanceOf[src] = bal - wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}