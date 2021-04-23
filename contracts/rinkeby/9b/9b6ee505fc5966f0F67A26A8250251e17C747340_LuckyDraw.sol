/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: Block8
pragma solidity 0.8.3;

abstract contract Utility {
    function getRandomNumber() public view virtual returns (uint256);
}

contract LuckyDraw {
    address public manager;
    address utilityAddress;
    address[] participents;
    Utility utils;

    constructor() {
        manager = msg.sender;
    }

    function participate() public payable {
        require(msg.value >= 0.1 ether, "Minimum contribution is 0.01 ether");
        participents.push(msg.sender);
    }

    function getParticipents() public view returns (address[] memory) {
        return participents;
    }

    function pickWinner() public managerOnly returns (address) {
        uint256 index = utils.getRandomNumber() % participents.length;
        address winner = participents[index];
        payable(winner).transfer(address(this).balance);
        participents = new address[](0);
        return winner;
    }

    function setUtilityAddress(address _utilityAddress) public managerOnly {
        utilityAddress = _utilityAddress;
        utils = Utility(utilityAddress);
    }

    modifier managerOnly() {
        require(
            msg.sender == manager,
            "Unauthorized access!, Only manager is allowed to do this operation"
        );
        _;
    }
}