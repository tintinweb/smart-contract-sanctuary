// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import '../interfaces/IERC20.sol';

/**
 * @title TomiBallot
 * @dev Implements voting process along with vote delegation
 */
contract TomiBallotRevenue {
    struct Voter {
        uint256 weight; // weight is accumulated by delegation
        bool participated; // if true, that person already voted
        address delegate; // person delegated to
    }

    mapping(address => Voter) public participators;

    address public governor;
    address public proposer;
    uint256 public endBlockNumber;
    bool public ended;
    string public subject;
    string public content;


    uint256 public total;
    uint256 public createTime;

    modifier onlyGovernor() {
        require(msg.sender == governor, 'TomiBallot: FORBIDDEN');
        _;
    }

    /**
     * @dev Create a new ballot.
     */
    constructor(
        address _proposer,
        uint256 _endBlockNumber,
        address _governor,
        string memory _subject,
        string memory _content
    ) public {
        proposer = _proposer;
        endBlockNumber = _endBlockNumber;
        governor = _governor;
        subject = _subject;
        content = _content;
        createTime = block.timestamp;
    }

    /**
     * @dev Give 'participator' the right to vote on this ballot.
     * @param participator address of participator
     */
    function _giveRightToJoin(address participator) private returns (Voter storage) {
        require(block.number < endBlockNumber, 'Bollot is ended');
        Voter storage sender = participators[participator];
        require(!sender.participated, 'You already participate in');
        sender.weight += IERC20(governor).balanceOf(participator);
        require(sender.weight != 0, 'Has no right to participate in');
        return sender;
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public {
        Voter storage sender = _giveRightToJoin(msg.sender);
        require(to != msg.sender, 'Self-delegation is disallowed');

        while (participators[to].delegate != address(0)) {
            to = participators[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, 'Found loop in delegation');
        }
        sender.participated = true;
        sender.delegate = to;
        Voter storage delegate_ = participators[to];
        if (delegate_.participated) {
            // If the delegate already voted,
            // directly add to the number of votes
            total += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
            total += sender.weight;
        }
    }

    /**
     * @dev Give your vote (including votes delegated to you) to proposal 'proposals[proposal].name'.
     */
    function participate() public {
        Voter storage sender = _giveRightToJoin(msg.sender);
        sender.participated = true;
        total += sender.weight;
    }

    function end() public onlyGovernor returns (bool) {
        require(block.number >= endBlockNumber, 'ballot not yet ended');
        require(!ended, 'end has already been called');
        ended = true;
        return ended;
    }

    function weight(address user) external view returns (uint256) {
        Voter memory participator = participators[user];
        return participator.weight;
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}