/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: Block8
pragma solidity 0.8.3;

abstract contract Utility {
    function getRandomNumber() external view virtual returns (uint256);

    function setNonce(uint256 _nonce) external virtual;
}

contract LuckyDraw {
    address public manager;
    address utilityAddress;
    address[] participents;
    Utility utils;

    event participentAdded(address participent, uint256 contribution);
    event winnerAnnounced(address winner, uint256 pool);
    event utilityAddressUpdated(address newAddress);

    constructor() {
        manager = msg.sender;
    }

    function participate() public payable {
        require(msg.value >= 0.1 ether);
        participents.push(msg.sender);
        emit participentAdded(msg.sender, msg.value);
    }

    function getParticipents() public view returns (address[] memory) {
        return participents;
    }

    function pickWinner() public managerOnly {
        uint256 index = utils.getRandomNumber() % participents.length;
        address winner = participents[index];
        uint256 pool = address(this).balance;
        payable(winner).transfer(address(this).balance);
        participents = new address[](0);
        emit winnerAnnounced(winner, pool);
    }

    function setUtilityAddress(address _utilityAddress) public managerOnly {
        utils = Utility(utilityAddress);
        utilityAddress = _utilityAddress;
        emit utilityAddressUpdated(utilityAddress);
    }

    function setUtilityNonce() public managerOnly {
        uint256 nonce = uint256(keccak256(abi.encodePacked(block.timestamp)));
        utils.setNonce(nonce);
    }

    modifier managerOnly() {
        require(
            msg.sender == manager,
            "Unauthorized access!, Only manager is allowed to do this operation"
        );
        _;
    }
}