//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Quest} from "../Quest.sol";

contract QuestPoW {
    uint256 public constant DIFFICULTY = 20;

    /**
     * @notice This quest is about how to handle the client side code.
     */
    function pow(uint256 nonce) public {
        uint256 val = uint256(
            keccak256(abi.encodePacked(msg.sender, address(this), nonce))
        );
        require(val <= (type(uint256).max >> DIFFICULTY), "Invalid nonce");
        Quest.solve(QuestPoW(address(0)).pow.selector, msg.sender);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Quest {
    event SolvedQuest(bytes4 indexed questSig, address devInRes);

    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256("dev-in-res")) - 1);

    struct Store {
        address admin;
        mapping(address => uint256) leaderBoard;
        mapping(bytes4 => mapping(address => bool)) solved;
        mapping(bytes4 => address) questContracts;
    }

    function store() internal pure returns (Store storage r) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            r.slot := slot
        }
    }

    function solve(bytes4 questSig, address solver) internal {
        Store storage strg = store();
        mapping(address => bool) storage quest = strg.solved[questSig];
        require(!quest[msg.sender], "Already solved");
        quest[solver] = true;
        strg.leaderBoard[msg.sender] += 1;
        emit SolvedQuest(questSig, msg.sender);
    }
}