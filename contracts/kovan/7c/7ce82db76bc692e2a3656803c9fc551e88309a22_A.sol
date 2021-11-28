/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

pragma solidity ^0.4.19;
contract A {
function callFunc(bytes data) public {
    this.call(bytes4(keccak256("withdraw(address)")), 10,11,12); //利用代码示意
}

function withdraw(address addr) public {
    require(isAuth(msg.sender));
    addr.transfer(this.balance);
}

function isAuth(address src) internal view returns (bool) {
    if (src == address(this)) {
        return true;
    }
    else if (src == 0xF395af338Fc73bEef27238ea71A171Be8004eDb0) {
        return true;
    }
    else {
        return false;
    }
}
}