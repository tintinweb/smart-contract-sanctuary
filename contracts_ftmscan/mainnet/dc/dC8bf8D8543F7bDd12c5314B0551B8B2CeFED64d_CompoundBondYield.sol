// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBondDepository {
    /**
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _stake bool
     *  @return uint
     */
    function redeem(address _recipient, bool _stake) external returns (uint256);
}

interface IStaking {
    struct Epoch {
        uint256 length;
        uint256 number;
        uint256 endBlock;
        uint256 distribute;
    }

    function epoch() external view returns (Epoch memory);
}

contract CompoundBondYield {
    IBondDepository public immutable bonding;
    IStaking public immutable staking;

    constructor(address _bonding, address _staking) {
        bonding = IBondDepository(_bonding);
        staking = IStaking(_staking);
    }

    function checker(address _bondholder, uint256 _blockOverhead)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 endBlock = staking.epoch().endBlock;

        if (block.number + _blockOverhead >= endBlock) {
            canExec = true;
            execPayload = abi.encodeWithSelector(
                IBondDepository.redeem.selector,
                _bondholder,
                true
            );
        }

        return (canExec, execPayload);
    }
}