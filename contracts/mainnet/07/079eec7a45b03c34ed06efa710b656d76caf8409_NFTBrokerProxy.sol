/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/*
 __________________________________
|                                  |
| $ + $ + $ + $ + $ + $ + $ + $ + $|
|+ $ + $ + $ + $ + $ + $ + $ + $ + |
| + $ + $ + $ + $ + $ + $ + $ + $ +|
|$ + $ + $ + $ + $ + $ + $ + $ + $ |
| $ + $ + $ + $ + $ + $ + $ + $ + $|
|+ $ + $ + $ + $ + $ + $ + $ + $ + |
| + $ + $ + $ + $ + $ + $ + $ + $ +|
|__________________________________|

*/

contract NFTBrokerProxy {

    modifier onlyOwner() {
        require(msg.sender == getOwner(), "caller not the owner");
        _;
    }

    constructor (address target) {
        setTargetSlot(target);
        setOwnerSlot(tx.origin);
    }

    fallback() external payable {
        address target = getTargetSlot();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}

    /**
     * @dev Gets proxy target address from storage slot.
     * @return target Address of smart contract source code.
     */
    function getTargetSlot() internal view returns (address target) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.NFTBrokerProxy.target')) - 1);
        assembly {
            target := sload(
                /* slot */
                0x172d303713ab541af50b05036cc57f0c0c8733f85d5ceb2137350b11166ad9bd
            )
        }
    }

    function getTarget() public view returns (address target) {
        return getTargetSlot();
    }

    /**
     * @dev Sets proxy target address to storage slot.
     * @param target Address of smart contract source code.
     */
    function setTargetSlot(address target) internal {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.NFTBrokerProxy.target')) - 1);
        assembly {
            sstore(
                /* slot */
                0x172d303713ab541af50b05036cc57f0c0c8733f85d5ceb2137350b11166ad9bd,
                target
            )
        }
    }

    function setTarget(address target) public onlyOwner {
        setTargetSlot(target);
    }

    /**
     * @dev Gets proxy owner address from storage slot.
     * @return owner Address of owner.
     */
    function getOwnerSlot() internal view returns (address owner) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.NFTBrokerProxy.owner')) - 1);
        assembly {
            owner := sload(
                /* slot */
                0x2d33df155922a1acf3c04048b6cc8aa3f641ab2dc6ecf84d346b5653b679e017
            )
        }
    }

    function getOwner() public view returns (address owner) {
        return getOwnerSlot();
    }

    /**
     * @dev Sets proxy owner address to storage slot.
     * @param owner Address of owner.
     */
    function setOwnerSlot(address owner) internal {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.NFTBrokerProxy.owner')) - 1);
        assembly {
            sstore(
                /* slot */
                0x2d33df155922a1acf3c04048b6cc8aa3f641ab2dc6ecf84d346b5653b679e017,
                owner
            )
        }
    }

    function setOwner(address owner) public onlyOwner {
        setOwnerSlot(owner);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "cannot use zero address");
        setOwner(newOwner);
    }

}