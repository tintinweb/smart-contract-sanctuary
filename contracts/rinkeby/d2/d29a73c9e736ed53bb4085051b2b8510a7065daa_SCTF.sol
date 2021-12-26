/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

contract SCTF {

    bool public success;
    mapping(address=>address) public target;
    uint256 public value =1e18 ether;
    
    function payforflag() payable public {
        (bool status, ) = target[msg.sender].delegatecall(abi.encodeWithSignature(""));
        require(status);
        
    }
    function changesuccess() payable public {
        require(msg.value > 1e18 ether,"error value");
        success=true;
    }
    function isSolved() public returns(bool) {
        return success;
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
        target[msg.sender] = contracAaddr;
    }
    
}