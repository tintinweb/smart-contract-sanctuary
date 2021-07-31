/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

pragma solidity ^0.7.6;

contract A {

    function setValue(address _addr1, address _addr2, address _addr3, uint256 x) public returns (uint256) {
        B b = B(_addr1);
        B c = B(_addr2);
        B d = B(_addr3);
        b.setValue(x);
        c.setValue(x+1);
        d.setValue(x+2);
        return 2;
    }
}

contract B {
    address gaddr;

    constructor(address addr) public {
        gaddr = addr;
    }

    function setValue(uint256 x) public returns (address) {
        G g = G(gaddr);
        g.setValue(x);
        g.setValue(x+1);
        return gaddr;
    }
}
pragma solidity ^0.7.6;

contract G {
    uint256 public val;

    function setValue(uint256 v) public returns (uint256) {
        val = v;
        return val;
    }
}