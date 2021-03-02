/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HelloWorldF1 {
    event ReceiveEther(string, address, uint256);
    
    address owner;
    string errorMessage = "call function not successed";
    
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() external payable {
        emit ReceiveEther("receive ether", msg.sender, msg.value);
    }
    
    function getName() public pure returns(string memory) {
        return unicode"contract HelloWorldF1 😊";
    }
    
    function etherBalances() public view onlyOwner returns(uint256){
        return address(this).balance;
    }
    
    function transferEther(address payable _recipient) public onlyOwner returns(bool) {
        bool success = _recipient.send(address(this).balance);
        require(success, "function transferEther not successed");
        return success;
    }
    
    function callFunction(bytes memory data) public returns(bytes memory) {
        (bool success, bytes memory returndata) = address(this).call(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }   
    }
}