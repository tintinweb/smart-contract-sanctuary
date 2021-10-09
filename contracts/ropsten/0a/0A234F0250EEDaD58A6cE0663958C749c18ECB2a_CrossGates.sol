// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract CrossGates {
    mapping(address=>bool) public canJoin;
    mapping(address=>bool) public isComplete;
    mapping(address=>bool) public gateOnePass;
    mapping(address=>bool) public gateTwoPass;
    bytes4 private Pass;

    constructor (bytes4 pass) public {
        Pass = pass;
    }

    function join (bytes4 pass) public {
        require(Pass==pass,"Wrong passpord!");
        require(tx.origin==msg.sender);
        require(!isContract(msg.sender),"Contract is not allowed!");
        canJoin[tx.origin] = true;
    }

    function complete() external returns(bool) {
        require(!isComplete[tx.origin],"Already pass!");
        require(gateOnePass[tx.origin],"Please pass the gateOne!");
        require(gateTwoPass[tx.origin],"Please pass the gateTwo!");
        isComplete[tx.origin] = true;
        return true;
    }

    function gateOne() external {
        require(canJoin[tx.origin],"Join first!");
        require(gasleft()%1234==0,"Gas amount error!");
        require(!gateOnePass[tx.origin],"Already pass gateOne!");
        require(tx.origin!=msg.sender,"Wrong address!");
        require(!isContract(msg.sender),"Contract is not allowed!");
        chageGateOneState();
    }

    function gateTwo(uint num) external{
        require(canJoin[tx.origin],"Join first!");
        require(!gateTwoPass[tx.origin],"Already pass gateTwo!");
        require(num == uint32(bytes4(blockhash(block.number-1))),"Wrong num!");
        require(uint160(msg.sender)&0xffffffff==0x11111111,"Wrong address!");
        callFunction('chageGateTwoState()');
    }

    function chageGateOneState() internal {
        gateOnePass[tx.origin] = true;
    }

    function chageGateTwoState() public {
        require(msg.sender==address(this),"Wrong caller!");
        gateTwoPass[tx.origin] = true;

    }
    
    function callFunction(bytes memory func) public {
        require(gateOnePass[tx.origin],"Pass gateOne first!");
        (bool succuss,) = address(this).call(abi.encodePacked(bytes4(keccak256(func))));
        require(succuss);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}