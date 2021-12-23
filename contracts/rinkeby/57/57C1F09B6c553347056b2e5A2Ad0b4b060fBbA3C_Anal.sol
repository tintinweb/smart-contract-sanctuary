/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

pragma solidity ^0.8.0;

interface Delegation {
}

contract Anal {
    event Groyped(bytes);

    constructor() {

    }

    fallback() external {

    }

    function groyp() public {
        emit Groyped(msg.data);
    }
}

contract DelegateCall {
    Delegation d;
    Anal anal;

    constructor(address addr) {
        d = Delegation(addr);
        anal = new Anal();
    }

    function getAnalAddress() public view returns(address) {
        return address(anal);
    }

    function grape() public {
        address(anal).delegatecall(abi.encodeWithSignature("groyp()"));
    }

    function pwn() public {
        (bool result,) = address(d).delegatecall(msg.data);
        require(result);
    }
}