// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./Ownable.sol";
contract LockTimer is Ownable{
    uint256 nonce;
    // uint256 public pausedAt;

    // uint256 public canEmergencyWithDrawAfter;

    // event DelayTimeSet(uint256 delayTime);

    modifier isAbleToWithdraw(){
        // uint256 withdrawAfter = canEmergencyWithDrawAfter;

        // // Has not been set yet
        // if (withdrawAfter == 0) {
        //     withdrawAfter = 1800;
        // }
        // require(block.timestamp - pausedAt >= withdrawAfter, "Must wait for certain amount of time");
        // _;
        uint pausedAt;
        uint withdrawAfter;
        assembly {
            

        }

        _;
    }
    
    function _getPausedAt() public pure returns(uint256 pausedAt){
        
        bytes32 hashed = keccak256("pausedAt");

        assembly{
            pausedAt:=mload(hashed)
        }
    }

    function setPausedAt(uint256 timestamp) public isOwner{
        bytes32 data = bytes32(timestamp);
        bytes32 hashed = keccak256("pausedAt");
        assembly{
            mstore(hashed, data)
        }
        nonce ++;
    }

    function _setEmergencyWithdrawDelayTime(uint delayInSecs) internal {
        // require(delayInSecs >= 600, "Please set it more than 10 mins");
        // require(delayInSecs <= 3600 * 24 * 7 , "Please set it less than 1 week");
        // emit DelayTimeSet(delayInSecs);
        // canEmergencyWithDrawAfter = delayInSecs;
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Ownable {

    address public owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    function getOnwer() public view returns (address) {
        return owner;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Must be the owner of the contract.");
        _;
    }

    function transferOwnership(address newOwner) public isOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

