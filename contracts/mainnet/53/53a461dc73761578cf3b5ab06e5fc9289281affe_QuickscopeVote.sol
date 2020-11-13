// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title QuickScopeVote - A simple contract which collects votes to act the Unimergency operation
 * @dev the vote can be done by staking the tokens of the preselected DFOhub Programmable Equities (buidl, arte, UniFi).
 * The vote can be performed for a certain amount of time (expressed in block).
 * To vote you need to approve the token transfer first.
 * You can vote to accept or refuse the strategy action.
 * Once you voted you cannot redeem your tokens until the end of the voting period.
 * You can vote several times and with different tokens. You can redeem all of them in just one shot.
 */
contract QuickscopeVote {
    uint256 private _startBlock;
    uint256 private _endBlock;

    address[] private _votingTokens;

    mapping(address => mapping(address => mapping(bool => uint256))) private _votes;
    mapping(address => bool) private _redeemed;

    uint256 private _accepts;
    uint256 private _refuses;

    event Vote(address indexed voter, address indexed votingToken, bool indexed accept, uint256 votingTokenPosition, uint256 amount);

    /**
    * @dev Contract constructor
    * @param startBlock The block number indicating the start of the voting period
    * @param endBlock The block number indicating the end of the voting period and the start of the redeem procedure
    * @param votingTokens The allowed tokens that can be used for voting
    */
    constructor(
        uint256 startBlock,
        uint256 endBlock,
        address[] memory votingTokens
    ) {
        _startBlock = startBlock;
        _endBlock = endBlock;
        _votingTokens = votingTokens;
    }

    /**
     * @return The block number indicating the start of the voting period
    */
    function startBlock() public view returns (uint256) {
        return _startBlock;
    }

    /**
     * @return The block number indicating the end of the voting period and the start of the redeem procedure
    */
    function endBlock() public view returns (uint256) {
        return _endBlock;
    }

    /**
     * @return The allowed tokens that can be used for voting
    */
    function votingTokens() public view returns (address[] memory) {
        return _votingTokens;
    }

    /**
     * @return accepts - all the votes in favor of the procedure
     * @return refuses - all the votes to deny the action of the procedure
    */
    function votes() public view returns (uint256 accepts, uint256 refuses) {
        return (_accepts, _refuses);
    }

    /**
     * @dev Gives back all the votes made by a single voter
     * @param voter The address of the voter you want to know the situation
     * @return addressAccepts the array of the votes made to accept. Every single position indicates the chosen voting token (positions are the same of the array given back by votingTokens() function).
     * @return addressRefuses the array of the votes made to refuse. Every single position indicates the chosen voting token (positions are the same of the array given back by votingTokens() function).
     */
    function votes(address voter) public view returns (uint256[] memory addressAccepts, uint256[] memory addressRefuses) {
        addressAccepts = new uint256[](_votingTokens.length);
        addressRefuses = new uint256[](_votingTokens.length);
        for(uint256 i = 0; i < _votingTokens.length; i++) {
            addressAccepts[i] = _votes[voter][_votingTokens[i]][true];
            addressRefuses[i] = _votes[voter][_votingTokens[i]][false];
        }
    }

    /**
     * @param voter The address of the voter you want to know the situation
     * @return true: the voter already redeemed its tokens, false otherwhise.
     */
    function redeemed(address voter) public view returns (bool) {
        return _redeemed[voter];
    }

    /**
     * @dev The voting function, it raises the "Vote" event
     * @param accept true means votes are for accept, false means votes are for refuse the proposal
     * @param votingTokenPosition The position in the voting token array given back by te votingTokens() function
     * @param amount The amount of tokens you want to stake to vote
     */
    function vote(bool accept, uint256 votingTokenPosition, uint256 amount) public {
        require(block.number >= _startBlock, "Survey not yet started");
        require(block.number < _endBlock, "Survey has ended");

        address votingTokenAddress = _votingTokens[votingTokenPosition];

        IERC20(votingTokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        _votes[msg.sender][votingTokenAddress][accept] = _votes[msg.sender][votingTokenAddress][accept] + amount;
        if(accept) {
            _accepts += amount;
        } else {
            _refuses += amount;
        }
        emit Vote(msg.sender, votingTokenAddress, accept, votingTokenPosition, amount);
    }

    /**
     * @dev The redeem function. It can be called just one time per voter and just after the end of the Voting period.
     * It does not matter what is the vote, how many times the address voted or if he used different tokens, the procedure will gives back to him everything in just one shot.
     * @param voter The address of the voter which staked the tokens.
     */
    function redeemVotingTokens(address voter) public {
        require(block.number >= _startBlock, "Survey not yet started");
        require(block.number >= _endBlock, "Survey is still running");
        require(!_redeemed[voter], "This voter already redeemed his stake");
        (uint256[] memory voterAccepts, uint256[] memory voterRefuses) = votes(voter);
        for(uint256 i = 0; i < _votingTokens.length; i++) {
            uint256 totalVotesByToken = voterAccepts[i] + voterRefuses[i];
            if(totalVotesByToken > 0) {
                IERC20(_votingTokens[i]).transfer(voter, totalVotesByToken);
            }
        }
        _redeemed[voter] = true;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 amount) external;
}