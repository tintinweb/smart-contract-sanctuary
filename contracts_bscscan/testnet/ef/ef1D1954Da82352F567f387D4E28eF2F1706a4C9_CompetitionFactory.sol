// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./RegularCompetitionContract.sol";
import "./P2PCompetitionContract.sol";

contract CompetitionFactory {
    function createRegularCompetitionContract(address _owner, address _creator)
        public
        returns (address)
    {
        RegularCompetitionContract regularcontract = new RegularCompetitionContract(
                _owner,
                _creator
            );
        return address(regularcontract);
    }

    function createP2PCompetitionContract(address _owner, address _creator)
        public
        returns (address)
    {
        P2PCompetitionContract p2pcontract = new P2PCompetitionContract(
            _owner,
            _creator
        );
        return address(p2pcontract);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRegularCompetitionContract {
    struct Competition {
        uint256 competitionId;
        uint256 player1;
        uint256 player2;
        Player playerWon;
        uint256 winnerReward;
    }
    struct Voting {
        uint256 player1;
        uint256 player2;
    }

    enum Privacy {
        Private,
        Public
    }
    enum Status {
        Lock,
        Open,
        End
    }
    enum Player {
        NoPlayer,
        Player1,
        Player2
    }

    event PlaceBet(
        address indexed buyer,
        uint256 numberOfVotesPlayer1,
        uint256 numberOfVotesPlayer2,
        uint256 amount
    );
    event Ready(
        uint256 timestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );
    event Close(uint256 timestamp, Player playerWon, uint256 winnerReward);
    event RewardRate(
        uint256 _rewardRateOfcreator,
        uint256 _rewardRateOfowner,
        uint256 _rewardRateOfWinner
    );
    event Destroy(uint256 timestamp);
    event WithdrawReward(address user, uint256 amount);

    function setBasic(
        bool _isPublic,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _entryFee
    ) external returns (bool);

    function depositEth() external payable;

    function start() external;

    function placeBet(
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) external payable;

    function placeBet(
        address _user,
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) external payable;

    function close() external;

    function getEntryFee() external view returns (uint256);

    function getTotalBalance() external view returns (uint256);

    function getTotalEthBet(address _user)
        external
        view
        returns (
            uint256 totalBetForPlayer1,
            uint256 totalBetForPlayer2,
            uint256 totalBet
        );

    function setRewardRate(
        uint256[] calldata _rewardRate,
        uint256 _decimalOfRate
    ) external;

    function setOracle(address _oracle) external;

    function setCompetition(
        uint256 _competitionId,
        uint256 _player1,
        uint256 _player2
    ) external;

    function withdrawReward() external;

    function destroyContract() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IP2PCompetitionContract {
    struct Competition {
        string sportType;
        string matchName;
        string streamLink;
        Player player1;
        Player player2;
        PlayerWon playerWon;
        uint256 winerReward;
        bool isAccept;
        bool resulted;
    }

    struct Voting {
        uint256 player1;
        uint256 player2;
    }

    struct Confirm {
        bool isConfirm;
        PlayerWon playerWon;
    }

    struct Player {
        address playerAddr;
        string playerName;
    }

    enum Privacy {
        Private,
        Public
    }
    enum Status {
        Lock,
        Open,
        End
    }
    enum PlayerWon {
        NoPlayer,
        Player1,
        Player2
    }

    event NewP2PCompetition(address indexed player1, address indexed player2);
    event PlaceBet(
        address indexed buyer,
        uint256 numberOfVotesPlayer1,
        uint256 numberOfVotesPlayer2,
        uint256 amount
    );
    event Ready(
        uint256 timestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );
    event Close(uint256 timestamp, PlayerWon playerWon, uint256 winerReward);
    event RewardRate(
        uint256 _rewardRateOfcreator,
        uint256 _rewardRateOfowner,
        uint256 _rewardRateOfWinner
    );
    event Destroy(uint256 timestamp);
    event WithdrawReward(address user, uint256 amount);
    event Accepted(address _player2, uint256 _timestamp);
    event ConfirmResult(address _player, bool _isWinner, uint256 _timestamp);
    event SetResult(bool _success);

    function getEntryFee() external view returns (uint256);

    function setRewardRate(uint256[] memory _rewardRate, uint256 _decimalOfRate)
        external;

    function setBasic(
        string memory _sportType,
        string memory _matchName,
        string memory _streamLink,
        string memory _player1Name,
        string memory _player2Name,
        address _player2,
        address _player1
    ) external payable returns (bool);

    function setEntryFee(uint256 _entryFee) external;

    function setStartAndEndTimestamp(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _startP2PTime,
        uint256 _endP2PTime
    ) external;

    function setDistanceTime(
        uint256 _distanceConfirmTime,
        uint256 _distanceVoteTime
    ) external;

    function setIsPublic(bool _isPublic) external;

    function depositEth() external payable;

    function acceptBetting() external;

    function placeBet(
        address user,
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) external payable;

    function confirmResult(bool _isWinner) external;

    function vote(bool _player1Win, bool _player2Win) external;

    function close() external;

    function claimable(address user)
        external
        view
        returns (bool canClaim, uint256 amount);

    function withdrawReward() external;

    function getTotalEthBet(address _user)
        external
        view
        returns (
            uint256 totalBetForPlayer1,
            uint256 totalBetForPlayer2,
            uint256 totalBet
        );

    function getTotalBalance() external view returns (uint256);

    function getPrivacy() external view returns (Privacy);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IChainLinkOracleSportData {
    function getPayment() external returns (uint256);

    function requestData(uint256 _matchId) external returns (bytes32);

    function getData(bytes32 _id) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "./interface/IChainLinkOracleSportData.sol";
import "./interface/IRegularCompetitionContract.sol";

contract RegularCompetitionContract is IRegularCompetitionContract {
    Competition public competition;
    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 public entryFee;

    uint256[] public rewardRate; //[creator, owner, winner]
    uint256 public decimalOfRate;
    address public oracle;
    mapping(address => Voting) public buyerToAmount;
    Voting public totalVote;
    mapping(address => bool) public withdrawn;
    address public immutable owner;
    address public immutable creator;

    Privacy privacy;
    Status public status = Status.Lock;

    bytes32 public requestID;

    constructor(address _owner, address _creator) {
        owner = _owner;
        creator = _creator;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "RegularCompetitionContract: Only owner");
        _;
    }

    modifier onlyCreator() {
        require(
            creator == msg.sender,
            "RegularCompetitionContract: Only creator"
        );
        _;
    }

    modifier onlyOwnerOrCreator() {
        require(
            owner == msg.sender || creator == msg.sender,
            "RegularCompetitionContract: Only owner or creator"
        );
        _;
    }

    modifier onlyOpen() {
        require(
            status == Status.Open,
            "RegularCompetitionContract: Required Open"
        );
        _;
    }

    modifier onlyLock() {
        require(
            status == Status.Lock,
            "RegularCompetitionContract: Required NOT start"
        );
        _;
    }

    modifier onlyEnd() {
        require(
            status == Status.End,
            "RegularCompetitionContract: Required NOT end"
        );
        _;
    }

    modifier betable() {
        require(
            block.timestamp >= startTimestamp &&
                block.timestamp <= endTimestamp,
            "BETTING: No betable"
        );
        _;
    }

    modifier onlyEnoughEntryFee(
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) {
        require(
            msg.value ==
                entryFee * (_numberOfVotesPlayer1 + _numberOfVotesPlayer2),
            "RegularCompetitionContract: Required ETH == entryFee * amountBet"
        );
        _;
    }

    function setOracle(address _oracle) public override onlyOwner {
        oracle = _oracle;
    }

    function getEntryFee() public view override returns (uint256) {
        return entryFee;
    }

    function setRewardRate(uint256[] memory _rewardRate, uint256 _decimalOfRate)
        public
        override
        onlyOwner
    {
        rewardRate = _rewardRate;
        decimalOfRate = _decimalOfRate;
        emit RewardRate(_rewardRate[0], _rewardRate[1], _rewardRate[2]);
    }

    function setBasic(
        bool _isPublic,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _entryFee
    ) public override onlyOwner onlyLock returns (bool) {
        require(
            block.timestamp <= _startTimestamp,
            "RegularCompetitionContract: Time is illegal"
        );
        require(
            _startTimestamp < _endTimestamp,
            "RegularCompetitionContract: endTime < startTime"
        );
        _setPrivacy(_isPublic);
        _setStartTimestamp(_startTimestamp);
        _setEndTimestamp(_endTimestamp);
        _setEntryFee(_entryFee);
        return true;
    }

    function setCompetition(
        uint256 _competitionId,
        uint256 _player1,
        uint256 _player2
    ) public override onlyOwner onlyLock {
        competition = Competition(
            _competitionId,
            _player1,
            _player2,
            Player.NoPlayer,
            0
        );
    }

    function depositEth() public payable override onlyOwnerOrCreator onlyLock {}

    function start() public override onlyOwner onlyLock {
        require(
            endTimestamp >= block.timestamp,
            "RegularCompetitionContract: expired"
        );

        status = Status.Open;
        emit Ready(block.timestamp, startTimestamp, endTimestamp);
    }

    function placeBet(
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    )
        public
        payable
        override
        onlyOpen
        betable
        onlyEnoughEntryFee(_numberOfVotesPlayer1, _numberOfVotesPlayer2)
    {
        _placeBet(msg.sender, _numberOfVotesPlayer1, _numberOfVotesPlayer2);
    }

    function placeBet(
        address user,
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    )
        external
        payable
        override
        onlyOpen
        betable
        onlyOwner
        onlyEnoughEntryFee(_numberOfVotesPlayer1, _numberOfVotesPlayer2)
    {
        _placeBet(user, _numberOfVotesPlayer1, _numberOfVotesPlayer2);
    }

    function _placeBet(
        address user,
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) private {
        require(
            user != creator,
            "RegularCompetitionContract: Creator cannot bet"
        );
        buyerToAmount[user].player1 += _numberOfVotesPlayer1;
        buyerToAmount[user].player2 += _numberOfVotesPlayer2;
        totalVote.player1 += _numberOfVotesPlayer1;
        totalVote.player2 += _numberOfVotesPlayer2;
        uint256 amount = (_numberOfVotesPlayer1 + _numberOfVotesPlayer2) *
            entryFee;
        emit PlaceBet(
            user,
            _numberOfVotesPlayer1,
            _numberOfVotesPlayer2,
            amount
        );
    }

    function close() public override onlyOpen {
        require(
            block.timestamp > endTimestamp,
            "RegularCompetitionContract: Please waiting for end time"
        );
        uint256 totalReward = getTotalBalance();
        require(
            totalReward > 0,
            "RegularCompetitionContract: Contract's balance empty"
        );
        (bool player1, bool player2, bool success) = _getResult();

        status = Status.End;

        uint256 creatorReward = 0;
        uint256 ownerReward = 0;
        uint256 winnerReward = 0;
        uint256 winnerCount;
        if (!success) {
            winnerReward =
                totalReward /
                (totalVote.player1 + totalVote.player2);
            winnerCount = totalVote.player1 + totalVote.player2;
        } else {
            if (player1 && !player2) {
                competition.playerWon = Player.Player1;
                winnerCount = totalVote.player1;
            } else if (!player1 && player2) {
                competition.playerWon = Player.Player2;
                winnerCount = totalVote.player2;
            }
            ownerReward =
                (totalReward * rewardRate[1]) /
                10**(decimalOfRate + 2);
            if (winnerCount > 0) {
                creatorReward =
                    (totalReward * rewardRate[0]) /
                    10**(decimalOfRate + 2);
                winnerReward =
                    (totalReward - ownerReward - creatorReward) /
                    winnerCount;
            } else {
                creatorReward = totalReward - ownerReward;
            }
        }
        if (creatorReward > 0) {
            Address.sendValue(payable(creator), creatorReward);
        }

        if (ownerReward > 0) {
            Address.sendValue(payable(owner), ownerReward);
        }
        competition.winnerReward = winnerReward;
        emit Close(
            block.timestamp,
            competition.playerWon,
            competition.winnerReward
        );
        if (winnerCount == 0) {
            destroyContract();
        }
    }

    function destroyContract() public override onlyEnd {
        require(
            getTotalBalance() == 0,
            "RegularCompetitionContract: There is still reward"
        );
        emit Destroy(block.timestamp);
        selfdestruct(payable(owner));
    }

    function claimable(address user)
        public
        view
        returns (bool canClaim, uint256 amount)
    {
        Voting memory voted = buyerToAmount[user];
        if (status != Status.End) {
            return (false, 0);
        }
        if (withdrawn[msg.sender]) {
            return (false, 0);
        }
        if (competition.winnerReward == 0) {
            return (false, 0);
        }
        if (competition.playerWon == Player.Player1 && voted.player1 > 0) {
            return (true, voted.player1 * competition.winnerReward);
        }
        if (competition.playerWon == Player.Player2 && voted.player2 > 0) {
            return (true, voted.player2 * competition.winnerReward);
        }
        if (competition.playerWon == Player.NoPlayer) {
            return (
                true,
                (voted.player1 + voted.player2) * competition.winnerReward
            );
        }
        return (false, 0);
    }

    function withdrawReward() external override onlyEnd {
        (bool canClaim, uint256 amount) = claimable(msg.sender);
        require(canClaim, "RegularCompetitionContract: Not claimable");
        withdrawn[msg.sender] = true;
        if (getTotalBalance() >= 2 * amount) {
            Address.sendValue(payable(msg.sender), amount);
        } else {
            Address.sendValue(payable(msg.sender), getTotalBalance());
        }
        emit WithdrawReward(msg.sender, amount);
        if (address(this).balance == 0) {
            destroyContract();
        }
    }

    function getTotalBalance() public view override returns (uint256) {
        return address(this).balance;
    }

    function getTotalEthBet(address _user)
        public
        view
        override
        returns (
            uint256 totalBetForPlayer1,
            uint256 totalBetForPlayer2,
            uint256 totalBet
        )
    {
        totalBetForPlayer1 = buyerToAmount[_user].player1 * entryFee;
        totalBetForPlayer2 = buyerToAmount[_user].player2 * entryFee;
        totalBet =
            (buyerToAmount[_user].player1 + buyerToAmount[_user].player2) *
            entryFee;
        return (totalBetForPlayer1, totalBetForPlayer2, totalBet);
    }

    function requestData() public {
        require(block.timestamp > endTimestamp);
        requestID = IChainLinkOracleSportData(oracle).requestData(
            competition.competitionId
        );
    }

    function _getResult()
        private
        view
        returns (
            bool _player1Win,
            bool _player2Win,
            bool _success
        )
    {
        uint256[] memory result = IChainLinkOracleSportData(oracle).getData(
            requestID
        );
        if (result.length == 0) {
            return (false, false, false);
        }
        if (result[1] > result[3]) {
            return (true, false, true);
        } else if (result[1] < result[3]) {
            return (false, true, true);
        } else if (result[1] == result[3]) {
            return (false, false, true);
        }
        return (false, false, false);
    }

    function _setPrivacy(bool _isPublic) private {
        if (_isPublic) {
            privacy = Privacy.Public;
        } else {
            privacy = Privacy.Private;
        }
    }

    function _setStartTimestamp(uint256 _startTimestamp) private {
        startTimestamp = _startTimestamp;
    }

    function _setEndTimestamp(uint256 _endTimestamp) private {
        endTimestamp = _endTimestamp;
    }

    function _setEntryFee(uint256 _entryFee) private {
        entryFee = _entryFee;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "./interface/IP2PCompetitionContract.sol";

contract P2PCompetitionContract is IP2PCompetitionContract {
    Competition public competition;
    uint256 public startBetTime;
    uint256 public endBetTime;
    uint256 public startP2PTime;
    uint256 public endP2PTime;
    uint256 public entryFee;

    Privacy privacy;
    Status public status = Status.Lock;

    uint256 public distanceConfirmTime;
    uint256 public distanceVoteTime;

    uint256[] public rewardRate;
    uint256 public decimalOfRate;

    mapping(address => Voting) public buyerToAmount;
    uint256 public amountBuyer;
    mapping(address => bool) public withdrawn;
    Voting public totalVote;

    mapping(address => bool) public voteResult;
    Voting public totalVoteResult;

    mapping(address => Confirm) public confirms;

    address public immutable owner;
    address public immutable creator;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyCreator() {
        require(creator == msg.sender);
        _;
    }

    modifier onlyOwnerOrCreator() {
        require(owner == msg.sender || creator == msg.sender);
        _;
    }

    modifier onlyOpen() {
        require(status == Status.Open);
        _;
    }

    modifier onlyLock() {
        require(status == Status.Lock);
        _;
    }

    modifier onlyEnd() {
        require(status == Status.End);
        _;
    }

    modifier betable() {
        require(
            block.timestamp >= startBetTime && block.timestamp <= endBetTime
        );
        _;
    }

    modifier onlyEnoughEntryFee(
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) {
        require(
            msg.value ==
                entryFee * (_numberOfVotesPlayer1 + _numberOfVotesPlayer2)
        );
        _;
    }

    constructor(address _owner, address _creator) {
        owner = _owner;
        creator = _creator;
    }

    function getEntryFee() public view override returns (uint256) {
        return entryFee;
    }

    function setRewardRate(uint256[] memory _rewardRate, uint256 _decimalOfRate)
        external
        override
        onlyOwner
    {
        rewardRate = _rewardRate;
        decimalOfRate = _decimalOfRate;
        emit RewardRate(_rewardRate[0], _rewardRate[1], _rewardRate[2]);
    }

    function setBasic(
        string memory _sportType,
        string memory _matchName,
        string memory _streamLink,
        string memory _player1Name,
        string memory _player2Name,
        address _player2,
        address _player1
    ) external payable override onlyOwner onlyLock returns (bool) {
        // require(
        //     msg.value == guaranteeFee,
        //     "P2PCompetitionContract: Player1 must deposite guarantee fee"
        // );

        require(_player2 != address(0) && _player1 != _player2);
        competition = Competition(
            _sportType,
            _matchName,
            _streamLink,
            Player(_player1, _player1Name),
            Player(_player2, _player2Name),
            PlayerWon.NoPlayer,
            0,
            false,
            false
        );

        emit NewP2PCompetition(msg.sender, _player2);
        return true;
    }

    function setEntryFee(uint256 _entryFee) external override onlyOwner {
        entryFee = _entryFee;
    }

    function setStartAndEndTimestamp(
        uint256 _startBetTime,
        uint256 _endBetTime,
        uint256 _startP2PTime,
        uint256 _endP2PTime
    ) external override onlyOwner {
        require(_startBetTime < _endBetTime && _startP2PTime < _endP2PTime);
        require(_startBetTime < _startP2PTime && _endBetTime < _endP2PTime);

        startBetTime = _startBetTime;
        endBetTime = _endBetTime;
        startP2PTime = _startP2PTime;
        endP2PTime = _endP2PTime;
    }

    function setIsPublic(bool _isPublic) external override onlyOwner {
        if (_isPublic) {
            privacy = Privacy.Public;
        } else {
            privacy = Privacy.Private;
        }
    }

    function setDistanceTime(
        uint256 _distanceConfirmTime,
        uint256 _distanceVoteTime
    ) external override onlyOwner {
        require(_distanceConfirmTime < _distanceVoteTime);
        distanceVoteTime = _distanceVoteTime;
        distanceConfirmTime = _distanceConfirmTime;
    }

    function depositEth() external payable override onlyOwnerOrCreator {} //onlyLock

    function acceptBetting() public override onlyLock {
        // require(
        //     msg.value == guaranteeFee,
        //     "P2PCompetitionContract: Player2 must deposite guarantee fee"
        // );
        require(block.timestamp <= startBetTime);
        require(msg.sender == competition.player2.playerAddr);
        competition.isAccept = true;
        _start();
        emit Accepted(msg.sender, block.timestamp);
    }

    function _start() private {
        require(competition.isAccept);

        status = Status.Open;
        emit Ready(block.timestamp, startBetTime, endBetTime);
    }

    function placeBet(
        address user,
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    )
        external
        payable
        override
        onlyOpen
        betable
        onlyOwner
        onlyEnoughEntryFee(_numberOfVotesPlayer1, _numberOfVotesPlayer2)
    {
        _placeBet(user, _numberOfVotesPlayer1, _numberOfVotesPlayer2);
    }

    function voteable() public view returns (bool) {
        if (competition.resulted) {
            return false;
        }
        address _player1 = competition.player1.playerAddr;
        address _player2 = competition.player2.playerAddr;
        if (!confirms[_player1].isConfirm || !confirms[_player2].isConfirm) {
            if (
                block.timestamp > endP2PTime + distanceConfirmTime &&
                block.timestamp < endP2PTime + distanceVoteTime
            ) {
                return true;
            } else {
                return false;
            }
        } else {
            if (confirms[_player1].playerWon == confirms[_player2].playerWon) {
                return false;
            } else {
                return true;
            }
        }
    }

    function _placeBet(
        address user,
        uint256 _numberOfVotesPlayer1,
        uint256 _numberOfVotesPlayer2
    ) private {
        require(
            user != competition.player1.playerAddr &&
                user != competition.player2.playerAddr
        );
        if (buyerToAmount[user].player1 + buyerToAmount[user].player2 == 0) {
            amountBuyer++;
        }
        buyerToAmount[user].player1 += _numberOfVotesPlayer1;
        buyerToAmount[user].player2 += _numberOfVotesPlayer2;
        totalVote.player1 += _numberOfVotesPlayer1;
        totalVote.player2 += _numberOfVotesPlayer2;
        uint256 amount = (_numberOfVotesPlayer1 + _numberOfVotesPlayer2) *
            entryFee;
        emit PlaceBet(
            user,
            _numberOfVotesPlayer1,
            _numberOfVotesPlayer2,
            amount
        );
    }

    function confirmResult(bool _isWinner) public override {
        require(
            block.timestamp > endP2PTime &&
                block.timestamp < endP2PTime + distanceConfirmTime
        );
        address _player1 = competition.player1.playerAddr;
        address _player2 = competition.player2.playerAddr;
        require(msg.sender == _player1 || msg.sender == _player2);
        require(!confirms[msg.sender].isConfirm);

        if (msg.sender == _player1) {
            if (_isWinner) {
                confirms[msg.sender] = Confirm(true, PlayerWon.Player1);
            } else {
                confirms[msg.sender] = Confirm(true, PlayerWon.Player2);
            }
        } else if (msg.sender == _player2) {
            if (_isWinner) {
                confirms[msg.sender] = Confirm(true, PlayerWon.Player2);
            } else {
                confirms[msg.sender] = Confirm(true, PlayerWon.Player1);
            }
        }

        if (confirms[_player1].isConfirm && confirms[_player2].isConfirm) {
            _setResult();
        }
        emit ConfirmResult(msg.sender, _isWinner, block.timestamp);
    }

    function _setResult() private returns (bool) {
        address _player1 = competition.player1.playerAddr;
        address _player2 = competition.player2.playerAddr;
        if (confirms[_player1].playerWon == confirms[_player2].playerWon) {
            competition.playerWon = confirms[_player1].playerWon;
            competition.resulted = true;
            return true;
        }
        return false;
    }

    function vote(bool _player1Win, bool _player2Win) public override {
        require(voteable());
        require(_player1Win == !_player2Win);
        require(
            buyerToAmount[msg.sender].player1 +
                buyerToAmount[msg.sender].player2 >
                0
        );
        require(!voteResult[msg.sender]);

        voteResult[msg.sender] = true;

        if (_player1Win) {
            totalVoteResult.player1++;
        } else {
            totalVoteResult.player2++;
        }

        if (amountBuyer > 1) {
            if (totalVoteResult.player1 >= amountBuyer / 2) {
                _setResultAfterVote();
            }

            if (totalVoteResult.player2 >= amountBuyer / 2) {
                _setResultAfterVote();
            }
        } else {
            _setResultAfterVote();
        }

        //truong hop chi cos  nguoi vote thi bi sai
    }

    function _setResultAfterVote() private {
        require(!competition.resulted);
        competition.resulted = true;
        if (totalVoteResult.player1 > totalVoteResult.player2) {
            competition.playerWon = PlayerWon.Player1;
            emit SetResult(true); //success
        } else if (totalVoteResult.player1 < totalVoteResult.player2) {
            competition.playerWon = PlayerWon.Player2;
            emit SetResult(true); //success
        } else {
            competition.playerWon = PlayerWon.NoPlayer;
        }
    }

    function close() public override onlyOpen {
        if (!competition.resulted) {
            require(block.timestamp > endP2PTime + distanceVoteTime);
        }

        uint256 totalReward = getTotalBalance();
        require(totalReward > 0);

        status = Status.End;
        uint256 creatorReward = 0;
        uint256 ownerReward = 0;
        uint256 winnerReward = 0;
        uint256 winnerCount;
        ownerReward = (totalReward * rewardRate[1]) / 10**(decimalOfRate + 2);
        if (competition.resulted) {
            if (competition.playerWon == PlayerWon.Player1) {
                winnerCount = totalVote.player1;
            } else if (competition.playerWon == PlayerWon.Player2) {
                winnerCount = totalVote.player2;
            } else {
                winnerCount = totalVote.player1 + totalVote.player2;
            }

            if (winnerCount > 0) {
                creatorReward =
                    (totalReward * rewardRate[0]) /
                    10**(decimalOfRate + 2);
                winnerReward =
                    (totalReward - ownerReward - creatorReward) /
                    winnerCount;
            } else {
                creatorReward = totalReward - ownerReward;
            }
        } else {
            winnerCount = totalVote.player1 + totalVote.player2;
            if (winnerCount > 0) {
                winnerReward = (totalReward - ownerReward) / winnerCount;
            } else {
                creatorReward = totalReward - ownerReward;
            }
        }

        if (creatorReward > 0) {
            Address.sendValue(payable(creator), creatorReward);
        }

        if (ownerReward > 0) {
            Address.sendValue(payable(owner), ownerReward);
        }

        competition.winerReward = winnerReward;

        emit Close(
            block.timestamp,
            competition.playerWon,
            competition.winerReward
        );

        if (winnerCount == 0) {
            destroyContract();
        }
    }

    function destroyContract() internal onlyEnd {
        require(getTotalBalance() == 0);
        emit Destroy(block.timestamp);
        selfdestruct(payable(owner));
    }

    function claimable(address user)
        public
        view
        override
        returns (bool canClaim, uint256 amount)
    {
        Voting memory voted = buyerToAmount[user];
        if (status != Status.End) {
            return (false, 0);
        }
        if (withdrawn[msg.sender]) {
            return (false, 0);
        }
        if (competition.winerReward == 0) {
            return (false, 0);
        }
        if (competition.playerWon == PlayerWon.Player1 && voted.player1 > 0) {
            return (true, voted.player1 * competition.winerReward);
        }
        if (competition.playerWon == PlayerWon.Player2 && voted.player2 > 0) {
            return (true, voted.player2 * competition.winerReward);
        }
        if (competition.playerWon == PlayerWon.NoPlayer) {
            return (
                true,
                (voted.player1 + voted.player2) * competition.winerReward
            );
        }
        return (false, 0);
    }

    function withdrawReward() public override onlyEnd {
        (bool canClaim, uint256 amount) = claimable(msg.sender);
        require(canClaim);
        withdrawn[msg.sender] = true;
        if (getTotalBalance() >= 2 * amount) {
            Address.sendValue(payable(msg.sender), amount);
        } else {
            Address.sendValue(payable(msg.sender), getTotalBalance());
        }
        emit WithdrawReward(msg.sender, amount);
        if (address(this).balance == 0) {
            destroyContract();
        }
    }

    function getTotalEthBet(address _user)
        public
        view
        override
        returns (
            uint256 totalBetForPlayer1,
            uint256 totalBetForPlayer2,
            uint256 totalBet
        )
    {
        totalBetForPlayer1 = buyerToAmount[_user].player1 * entryFee;
        totalBetForPlayer2 = buyerToAmount[_user].player2 * entryFee;
        totalBet =
            (buyerToAmount[_user].player1 + buyerToAmount[_user].player2) *
            entryFee;
        return (totalBetForPlayer1, totalBetForPlayer2, totalBet);
    }

    function getTotalBalance() public view override returns (uint256) {
        return address(this).balance;
    }

    function getPrivacy() public view override returns (Privacy) {
        return privacy;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}