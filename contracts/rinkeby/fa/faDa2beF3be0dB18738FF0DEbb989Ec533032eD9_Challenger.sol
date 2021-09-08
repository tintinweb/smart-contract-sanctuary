// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

// import "./ChallengeManager.sol";

contract Challenger {
    // ChallengeManager internal manager;
    // // constructor(address adr) public {
    // //     manager = ChallengeManager(adr);
    // // }
    // function unlockChallenge(uint256 id) external payable {
    //     IPublicLock lock = manager.getLock(id);
    //     require(address(lock) != address(0), "NO_LOCK_WITH_THIS_KEY");
    //     lock.purchase.value(msg.value)(
    //         lock.keyPrice(),
    //         msg.sender,
    //         0x0d5900731140977cd80b7Bd2DCE9cEc93F8a176B,
    //         "0x00"
    //     );
    // }
    // function submitData(
    //     uint256 id,
    //     uint32 data,
    //     uint256 time
    // ) external returns (bool) {
    //     manager.addLeaderboardEntry(id, msg.sender, data, time);
    // }
    // function receivePrice(uint256 challengeId) external {
    //     require(isWinner(challengeId), "Not the winner");
    //     //add lock withdraw
    // }
    // function isWinner(uint256 challengeId) public view returns (bool) {
    //     return msg.sender == manager.getWinner(challengeId);
    // }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}