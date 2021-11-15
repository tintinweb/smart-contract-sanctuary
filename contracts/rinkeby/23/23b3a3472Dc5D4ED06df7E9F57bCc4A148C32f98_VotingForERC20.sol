//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

/*
* This smart contract implements voting for tokenholders of ERC20 tokens based on the principle
* "one token - one vote"
* It requires external script to count votes.
*
* Rules:
* Voting can be started for any contract with ERC20 tokens, to start a voting an address have to own at lest one token.
* To start a voting, voting creator must provide:
* 1) address of a contract with tokens (ERC20),
* 2) text of the proposal,
* 3) number of block on witch voting will be finished and results have to be calculated.
*
* Every proposal for a contract receives a sequence number that serves as a proposal ID for this contract.
* Each smart contract with tokens has its own numbering.
* So proposal can be identified by contract address with tokens + number (ID) of the proposal.
*
* To vote 'for' or 'against' voter has to provide an address of a contract with tokens + proposal ID.
*
* In most scenarios only votes 'for' can be used, who did not voted 'for' can be considered as voted 'against'.
* But our dApp also supports votes 'against'
*
* To calculate results we collect all voted addresses by an external script, which is also open sourced.
* Than we check their balances in tokens on resulting block, and and sum up the voices.
* Thus, for the results, the number of tokens of the voter at the moment of voting does not matter
* (it should just has at least one).
* What matters is the number of tokens on the voter's address on the block where the results should calculated.
*
*/

abstract contract ERC20TokensContract {

    /*
    * These are functions that smart contract needs to have to work with our dApp
    */

    function balanceOf(address _owner) external view virtual returns (uint256 balance);

    function totalSupply() external view virtual returns (uint256);

    string public name;

    string public symbol;

}

contract VotingForERC20 {

    mapping(address => uint256) public votingCounterForContract;
    mapping(address => mapping(uint256 => string)) public proposalText;
    mapping(address => mapping(uint256 => uint256)) public numberOfVotersFor;
    mapping(address => mapping(uint256 => uint256)) public numberOfVotersAgainst;
    mapping(address => mapping(uint256 => mapping(uint256 => address))) public votedFor;
    mapping(address => mapping(uint256 => mapping(uint256 => address))) public votedAgainst;
    mapping(address => mapping(uint256 => mapping(address => bool))) public boolVotedFor;
    mapping(address => mapping(uint256 => mapping(address => bool))) public boolVotedAgainst;
    mapping(address => mapping(uint256 => uint256)) public resultsInBlock;

    event Proposal(
        address indexed forContract,
        uint indexed proposalId,
        address indexed by,
        string proposalText,
        uint resultsInBlock
    );

    function create(
        address _erc20ContractAddress, //...1
        string calldata _proposalText, //...2
        uint256 _resultsInBlock //..........3
    ) external returns (bool success){

        ERC20TokensContract erc20TokensContract = ERC20TokensContract(_erc20ContractAddress);

        require(
            erc20TokensContract.balanceOf(msg.sender) > 0,
            "Only tokenholder can start voting"
        );

        require(
            _resultsInBlock > block.number,
            "Block for results should be later than current block"
        );

        // votingCounterForContract[_erc20ContractAddress]++; // < does not work
        votingCounterForContract[_erc20ContractAddress] = votingCounterForContract[_erc20ContractAddress] + 1;
        uint proposalId = votingCounterForContract[_erc20ContractAddress];

        proposalText[_erc20ContractAddress][proposalId] = _proposalText;
        resultsInBlock[_erc20ContractAddress][proposalId] = _resultsInBlock;

        emit Proposal(_erc20ContractAddress, proposalId, msg.sender, _proposalText, _resultsInBlock);

        return true;
    }

    event VoteFor(
        address indexed forContract,
        uint indexed proposalId,
        address indexed by
    );

    event VoteAgainst(
        address indexed forContract,
        uint indexed proposalId,
        address indexed by
    );

    function voteFor(
        address _erc20ContractAddress, //..1
        uint256 _proposalId //.............2
    ) external returns (bool success){

        ERC20TokensContract erc20TokensContract = ERC20TokensContract(_erc20ContractAddress);

        require(
            erc20TokensContract.balanceOf(msg.sender) > 0,
            "Only tokenholder can vote"
        );

        require(
            resultsInBlock[_erc20ContractAddress][_proposalId] > block.number,
            "Voting finished"
        );

        require(
            !boolVotedFor[_erc20ContractAddress][_proposalId][msg.sender],
            "Already voted"
        );
        require(
            !boolVotedAgainst[_erc20ContractAddress][_proposalId][msg.sender],
            "Already voted"
        );

        numberOfVotersFor[_erc20ContractAddress][_proposalId] = numberOfVotersFor[_erc20ContractAddress][_proposalId] + 1;
        uint voterId = numberOfVotersFor[_erc20ContractAddress][_proposalId];

        votedFor[_erc20ContractAddress][_proposalId][voterId] = msg.sender;
        boolVotedFor[_erc20ContractAddress][_proposalId][msg.sender] = true;

        emit VoteFor(_erc20ContractAddress, _proposalId, msg.sender);

        return true;
    }

    function voteAgainst(
        address _erc20ContractAddress, //..1
        uint256 _proposalId //.............2
    ) external returns (bool success){

        ERC20TokensContract erc20TokensContract = ERC20TokensContract(_erc20ContractAddress);

        require(
            erc20TokensContract.balanceOf(msg.sender) > 0,
            "Only tokenholder can vote"
        );

        require(
            resultsInBlock[_erc20ContractAddress][_proposalId] > block.number,
            "Voting finished"
        );

        require(
            !boolVotedFor[_erc20ContractAddress][_proposalId][msg.sender],
            "Already voted"
        );
        require(
            !boolVotedAgainst[_erc20ContractAddress][_proposalId][msg.sender],
            "Already voted"
        );

        numberOfVotersAgainst[_erc20ContractAddress][_proposalId] = numberOfVotersAgainst[_erc20ContractAddress][_proposalId] + 1;
        uint voterId = numberOfVotersAgainst[_erc20ContractAddress][_proposalId];

        votedAgainst[_erc20ContractAddress][_proposalId][voterId] = msg.sender;
        boolVotedAgainst[_erc20ContractAddress][_proposalId][msg.sender] = true;

        emit VoteAgainst(_erc20ContractAddress, _proposalId, msg.sender);

        return true;
    }

}

