/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

pragma solidity =0.8.6;

contract Con {
    uint public count;
    
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
    
    // same name with other
    function setCount(uint _count) external {
        count = _count;
    }

    function destroy() external {
        selfdestruct(payable(msg.sender));
    }
    
    receive() external payable {
    }
}