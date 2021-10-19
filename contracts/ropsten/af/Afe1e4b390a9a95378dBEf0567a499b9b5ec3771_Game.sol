/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

contract Game {

    event ForFlag(address indexed addr);
    mapping(address=>address) public target;
    
    function payforflag(address payable _addr) public {
        
        require(_addr != address(0));
        
        (bool status, ) = target[msg.sender].delegatecall(abi.encodeWithSignature(""));
        require(status);
        selfdestruct(_addr);
    }
    
    function sendFlag() public payable {
        require(msg.value >= 1000000000 ether);
        emit ForFlag(msg.sender);
    }
    
    function registContract(address a, bytes memory message, bytes32 salt) public {
        uint256 asize;
        assembly {
            asize := extcodesize(a)
        }
        require(asize == 0);
        bool callSuccess;
        bytes memory result;
        (callSuccess, result) = a.call(message);
        require(callSuccess, "Call revert");
        require(result.length > 0, "Return value is incorrect");
        address contracAaddr;
        salt = keccak256(abi.encodePacked(salt, msg.sender));
        assembly {
          contracAaddr := create2(0, add(message, 0x20), mload(message), salt)
          if iszero(extcodesize(contracAaddr)) {
            revert(0, 0)
          }
        } 
        require(uint160(contracAaddr) < uint160(0x0001000000000000000000000000000000000000), "Not magic address");
        assembly {
            asize := extcodesize(contracAaddr)
        }       
        require(asize < 100, "Pls save storage space.");
        target[msg.sender] = contracAaddr;
    }
    
}