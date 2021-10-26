// SPDX-License-Identifier: Unlicensed

pragma solidity =0.8.9;

contract MockVault {
    uint96 public priorVotes = 1000 * 10**18;

    function setPriorVotes(uint96 _votes) external {
        priorVotes = _votes;
    }

    function getPriorVotes(address, uint256) external view returns (uint96) {
        return priorVotes;
    }

    function execute(address _target, bytes calldata _data) external payable {
        (bool executed, ) = _target.call{value: msg.value}(_data);
        require(executed, "failed");
    }
}