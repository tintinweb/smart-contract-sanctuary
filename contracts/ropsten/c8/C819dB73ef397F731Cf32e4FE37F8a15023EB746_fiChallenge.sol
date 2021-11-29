/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

pragma solidity ^0.4.21;

interface IName {
    function name() external view returns (bytes32);
}

contract fiChallenge {
    bool public isComplete;
    bool public isTested1;
    bool public isTested2;

    function authenticate() public {
        require(isSmarx(msg.sender));
        require(isBadCode(msg.sender));

        isComplete = true;
    }

    function authenticate1() public returns (bool) {
        require(isSmarx(msg.sender));
        isTested1 = true;
    }

    function authenticate2() public returns (bool) {
        require(isSmarx(msg.sender));
        require(isBad(msg.sender));
        isTested2 = true;
    }

    function msgSender() public view returns (address) {
        return msg.sender;
    }

    function tested1() public view returns(bool) {
        return isTested1;
    }

    function tested2() public view returns(bool) {
        return isTested2;
    }

    function setTested1(bool _isTested1) public {
        isTested1 = _isTested1;
    }

    function setTested2(bool _isTested2) public {
        isTested2 = _isTested2;
    }

    function isSmarx(address addr) internal view returns (bool) {
        return IName(addr).name() == bytes32("smarx");
    }

    function isSmarx1(address addr) external view returns (bool) {
        return IName(addr).name() == bytes32("smarx");
    }
    
    function isBadCode(address _addr) internal pure returns (bool) {
        bytes20 addr = bytes20(_addr);
        bytes20 id = hex"000000000000000000000000000000000badc0de";
        bytes20 mask = hex"000000000000000000000000000000000fffffff";

        for (uint256 i = 0; i < 34; i++) {
            if (addr & mask == id) {
                return true;
            }
            mask <<= 4;
            id <<= 4;
        }

        return false;
    }

    function isBad(address _addr) internal pure returns (bool) {
        bytes20 addr = bytes20(_addr);
        bytes20 id = hex"0000000000000000000000000000000000000bad";
        bytes20 mask = hex"0000000000000000000000000000000000000fff";

        for (uint256 i = 0; i < 34; i++) {
            if (addr & mask == id) {
                return true;
            }
            mask <<= 4;
            id <<= 4;
        }

        return false;
    }
}