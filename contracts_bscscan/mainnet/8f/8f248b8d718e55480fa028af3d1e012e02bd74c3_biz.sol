/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

pragma solidity ^0.6.9;

   interface Intf {
    function getAnswer() external view returns (bytes32);
}

contract biz {
    string private soln;
    
    address hidder;
    bytes32 answer;
    

    
    constructor(address _add) public payable {
        hidder = _add;
        getAnsr();
    }
    
    function getAnsr() private {
        answer = Intf(hidder).getAnswer();
    }
    
    
    
    function tryAnswer(string memory _ans) public {
        checkAns(_ans);
    }
    
    function checkAns(string memory _ans) internal {
        require(answer == keccak256(abi.encodePacked(_ans)));
        address payable _to = msg.sender;
        _to.transfer(address(this).balance);
        
    }
    
}