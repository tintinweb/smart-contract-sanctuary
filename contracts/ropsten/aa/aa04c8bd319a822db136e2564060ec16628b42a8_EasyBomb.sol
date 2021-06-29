/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.5.10;

contract Launcher{
    uint256 public deadline;
    function setdeadline(uint256 _deadline) public {}
}

contract EasyBomb{
    bool private hasExplode = false;
    address private launcher_address;
    bytes32 private password;
    bool public power_state = true;
    bytes4 constant launcher_start_function_hash = bytes4(keccak256("setdeadline(uint256)"));
    Launcher launcher;

    function msgPassword() public returns (bytes32 result)  {
        bytes memory msg_data = msg.data;
        if (msg_data.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(msg_data, add(0x20, 0x24)))
        }
    }

    modifier isOwner(){
        require(msgPassword() == password);
        require(msg.sender != tx.origin);
        uint x;
        assembly { x := extcodesize(caller) }
        require(x == 0);
        _;
    }

    modifier notExplodeYet(){
        launcher = Launcher(launcher_address);
        require(block.number < launcher.deadline());
        hasExplode = true;
        selfdestruct(msg.sender);
        _;
    }
		constructor(address _launcher_address, bytes32 _fake_flag) public {
        launcher_address = _launcher_address;
        password = _fake_flag ;
    }

    function setCountDownTimer(uint256 _deadline) public isOwner notExplodeYet {
        launcher_address.delegatecall(abi.encodeWithSignature("setdeadline(uint256)",_deadline));
    }
}