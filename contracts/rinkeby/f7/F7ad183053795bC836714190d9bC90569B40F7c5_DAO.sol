//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract DAO {
    enum VoteOption {
        NONE,
        FOR,
        AGAINST
    }

    enum VotingResult {
        NONE,
        ACCEPTED,
        REJECTED,
        INVALID
    }

    enum VotingType {
        NONE,
        STANDART,
        NO_RECIPIENT
    }

    struct Voting {
        string description;
        uint256 createdAt;
        uint256 duration;
        uint256 totalSupplyAtCreation;
        uint256 totalFor;
        uint256 totalAgainst;
        VotingResult result;
        VotingType votingType;
        address recipient;
        bytes callData;
        mapping(address => VoteOption) addressOption;
    }

    struct AddressBalance {
        uint256 balance;
        uint256 timestamp;
        uint256 withdrawTime;
    }

    uint256 public constant minimumQuorumPercentage = 50;

    IERC20 public ercContract;
    uint256 private _votingId;
    mapping(uint256 => Voting) private _idVoting;
    mapping(address => AddressBalance) private _addressBalance;
    mapping(address => address) private _voteDelegation;

    event VotingCreated(
        uint256 indexed votingId,
        string description,
        VotingType votingType
    );
    event Vote(
        uint256 indexed votingId,
        address voter,
        VoteOption option,
        uint256 voteAmount
    );
    event VotingFinished(
        uint256 indexed votingId,
        uint256 totalVoted,
        VotingResult result
    );

    modifier validVoting(uint256 id) {
        require(_idVoting[id].createdAt > 0, "Voting not found");
        _;
    }

    function setErcContract(address _ercContract) external {
        ercContract = IERC20(_ercContract);
    }

    function createVoting(
        string memory description,
        address recipient,
        bytes memory callData
    ) external {
        _createVoting(description, VotingType.STANDART, recipient, callData);
    }

    function createVoting(string memory description) external {
        _createVoting(description, VotingType.NO_RECIPIENT, address(0), "");
    }

    function delegateVotesTo(address delegateAddress) external {
        _voteDelegation[msg.sender] = delegateAddress;
    }

    function vote(uint256 votingId, VoteOption option) external {
        _vote(votingId, msg.sender, option);
    }

    function voteFor(
        uint256 votingId,
        address votingAddress,
        VoteOption option
    ) external {
        require(
            _voteDelegation[votingAddress] != address(0),
            "This address did not delegate his votes to any address yet"
        );
        require(
            _voteDelegation[votingAddress] == msg.sender,
            "You cannot vote for this address"
        );
        _vote(votingId, votingAddress, option);
    }

    function finishVoting(uint256 votingId) external validVoting(votingId) {
        Voting storage voting = _idVoting[votingId];
        uint256 votingEndTime = voting.createdAt + voting.duration;
        require(block.timestamp > votingEndTime, "Too early to finish");
        require(voting.result == VotingResult.NONE, "Voting already finished");

        VotingResult result;
        uint256 totalVoted = voting.totalFor + voting.totalAgainst;
        uint256 minimumQuorum = (voting.totalSupplyAtCreation *
            minimumQuorumPercentage) / 100;

        if (totalVoted >= minimumQuorum) {
            if (voting.totalFor > voting.totalAgainst) {
                result = VotingResult.ACCEPTED;
            } else {
                result = VotingResult.REJECTED;
            }
        } else {
            result = VotingResult.INVALID;
        }

        voting.result = result;

        if (result == VotingResult.ACCEPTED) {
            if (voting.votingType == VotingType.STANDART) {
                (bool success, ) = voting.recipient.call(voting.callData);
                require(success, "Voting finished unsuccessfully");
            }
        }

        emit VotingFinished(votingId, totalVoted, result);
    }

    function getAddressVote(uint256 votingId, address voterAddress)
        external
        view
        returns (VoteOption)
    {
        return _idVoting[votingId].addressOption[voterAddress];
    }

    function getVotingDetail(uint256 votingId)
        external
        view
        validVoting(votingId)
        returns (
            string memory description,
            uint256 createdAt,
            uint256 duration,
            uint256 totalSupplyAtCreation,
            uint256 totalFor,
            uint256 totalAgainst,
            VotingResult result,
            VotingType votingType,
            address recipient,
            bytes memory callData
        )
    {
        Voting storage voting = _idVoting[votingId];

        return (
            voting.description,
            voting.createdAt,
            voting.duration,
            voting.totalSupplyAtCreation,
            voting.totalFor,
            voting.totalAgainst,
            voting.result,
            voting.votingType,
            voting.recipient,
            voting.callData
        );
    }

    function deposit(uint256 amount) external {
        AddressBalance storage balance = _addressBalance[msg.sender];
        balance.balance += amount;
        balance.timestamp = block.timestamp;
        // Assuming user approved tokens for this contract
        ercContract.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw() external {
        AddressBalance storage balance = _addressBalance[msg.sender];
        require(balance.balance > 0, "This address balance is empty");
        require(
            block.timestamp > balance.withdrawTime,
            "Too early to withdraw"
        );
        uint256 amount = balance.balance;
        balance.balance = 0;
        balance.timestamp = block.timestamp;
        ercContract.transfer(msg.sender, amount);
    }

    function _createVoting(
        string memory description,
        VotingType votingType,
        address recipient,
        bytes memory callData
    ) private {
        uint256 duration = 3 * (60 * 60 * 24); // 3 days in seconds
        Voting storage voting = _idVoting[_votingId++];
        voting.result = VotingResult.NONE;
        voting.votingType = votingType;
        voting.description = description;
        voting.createdAt = block.timestamp;
        voting.duration = duration;
        voting.recipient = recipient;
        voting.callData = callData;
        voting.totalSupplyAtCreation = ercContract.totalSupply();

        emit VotingCreated(_votingId - 1, description, votingType);
    }

    function _vote(
        uint256 votingId,
        address votingAddress,
        VoteOption option
    ) private validVoting(votingId) {
        Voting storage voting = _idVoting[votingId];
        AddressBalance storage balance = _addressBalance[votingAddress];
        uint256 votingEndTime = voting.createdAt + voting.duration;
        require(votingEndTime > block.timestamp, "Voting is already ended");
        require(option != VoteOption.NONE, "Invalid vote");
        require(
            voting.addressOption[votingAddress] == VoteOption.NONE,
            "The address already voted"
        );

        uint256 amountToVote = balance.balance;

        require(amountToVote > 1, "Balance is not enough for voting");

        voting.addressOption[votingAddress] = option;

        if (option == VoteOption.FOR) {
            voting.totalFor += amountToVote;
        } else {
            voting.totalAgainst += amountToVote;
        }

        if (votingEndTime > balance.withdrawTime)
            balance.withdrawTime = votingEndTime;

        emit Vote(votingId, votingAddress, option, amountToVote);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the total supply in the contract.
     * @return total amount of supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the balance of given account.
     * @param account account to fetch balance for.
     * @return total amount of supply.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Transfers amount of tokens from caller of the method to recipient.
     * @param recipient tokens recipient address.
     * @param amount amount to send to recipient.
     * @return result of the transfer.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the amount of tokens that owner allowed spender to use.
     * @param owner owner of tokens.
     * @param spender spender of tokens.
     * @return amount of tokens to spend.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets the amount of tokens that caller of the function allows to be used by spender.
     * @param spender spender of tokens.
     * @param amount allowed amount to spend by spender.
     * @return result of the operation.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Transfers amount of tokens from sender to recipient.
     * @param sender sender of tokens.
     * @param recipient tokens recipient address.
     * @param amount amount to send to recipient.
     * @return result of the transfer.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev The amount of decimals for the token.
     * @return result the decimals of the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Emitted when given amount of token transferred between two accounts.
     * @param from sender of tokens.
     * @param to tokens recipient address.
     * @param amount amount being sent to recipient.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Emitted when the allowance is set between accounts.
     * @param owner owner of tokens.
     * @param spender tokens spender address.
     * @param amount amount being approved.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}