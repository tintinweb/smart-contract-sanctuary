/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

pragma solidity ^0.8.0;

interface Delegation {
}

contract Anal {
    event Groyped(string);
    bytes private laid;

    constructor() {

    }

    fallback() external {

    }

    function getLaid() public view returns(bytes memory) {
        return laid;
    }

    function groyp() public {
        laid = (msg.data);
        emit Groyped(string(abi.encodePacked("Groyped by ", msg.sender)));
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
        (bool result,) = address(anal).delegatecall(abi.encodeWithSignature("groyp()"));
        require(result);
    }

    function getLaid() public returns(bytes memory) {
        (,bytes memory sneega) = address(anal).call(abi.encodeWithSignature("getLaid()"));
        return sneega;
    }

    function pwn() public {
        (bool result,) = address(d).delegatecall(msg.data);
        require(result);
    }
}