/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Voter {
    // #region Storage
    uint256[] public votes;
    string[] public options;
    bool votingStarted;
    mapping(address => bool) private hasVoted;
    mapping(string => OptionPos) private posOfOption;

    // #endregion

    // #region Constructor
    // constructor(string[] memory _options) {
    //     options = _options;
    //     votes = new uint256[](options.length);

    //     for (uint256 i = 0; i < options.length; i++) {
    //         OptionPos memory optionPos = OptionPos({pos: i, exists: true});
    //         string memory optionName = options[i];

    //         posOfOption[optionName] = optionPos;
    //     }
    // }

    // #endregion

    // #region Methods
    function addOption(string memory option) public {
        require(!votingStarted);

        options.push(option);

        posOfOption[option] = OptionPos({
            pos: options.length - 1,
            exists: true
        });
    }

    function startVoting() public {
        require(!votingStarted);

        votes = new uint256[](options.length);

        for (uint256 i = 0; i < options.length; i++) {
            OptionPos memory optionPos = OptionPos({pos: i, exists: true});
            string memory optionName = options[i];

            posOfOption[optionName] = optionPos;
        }

        votingStarted = true;
    }

    function vote(uint256 option) public {
        require(!hasVoted[msg.sender], "Already voted");
        require(option >= 0 && option < options.length, "Invalid option");

        votes[option] = votes[option] + 1;
        hasVoted[msg.sender] = true;
    }

    function vote(string memory optionName) public {
        require(!hasVoted[msg.sender], "Already voted");

        OptionPos memory optionPos = posOfOption[optionName];

        if (!optionPos.exists) {
            revert("Option not found");
        }

        votes[optionPos.pos] = votes[optionPos.pos] + 1;
        hasVoted[msg.sender] = true;
    }

    function getVotes() public view returns (uint256[] memory) {
        return votes;
    }

    function isVoted() public view returns (bool) {
        return hasVoted[msg.sender];
    }

    function getOptions() public view returns (string[] memory) {
        return options;
    }

    // #endregion

    // #region Structs
    struct OptionPos {
        uint256 pos;
        bool exists;
    }
    // #endregion
}