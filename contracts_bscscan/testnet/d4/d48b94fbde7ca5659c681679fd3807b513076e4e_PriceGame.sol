/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract PriceGame{
    uint256 public constant TOTAL_RATE = 100; // 100%
    uint256 public rewardRate; 
    uint256 public treasuryRate;

    enum Stages {
        Initial,
        GenesisRound,
        NormalRound,
        Paused
    }

    enum RoundStages {
        Start,
        Locked,
        Ended
    }

    struct Round {
        RoundStages stage;
        uint256 epoch;
        uint256 startBlock;
        uint256 lockBlock;
        uint256 endBlock;
        uint256 lockPrice;
        uint256 closePrice;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool pseudoRound;
    }

    enum Position {
        Bull,
        Bear
    }

    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    mapping(uint256 => address[]) public playerList;
    mapping(uint256 => Round) public rounds;
    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(address => uint256[]) public userRounds;
    Stages public stage;
    uint256[] public pendingRounds;
    address public owner;
    uint256 public treasuryAmount;
    uint256 public currentEpoch;
    uint256 public lastActiveEpoch;
    uint256 public currentPrice;
    uint256 public epochBlocks;

    event Claim(
        address indexed sender,
        uint256 indexed currentEpoch,
        uint256 amount
    );
    event StartRound(uint256 indexed epoch, uint256 blockNumber);
    event LockRound(uint256 indexed epoch, uint256 blockNumber, uint256 price);
    event EndRound(uint256 indexed epoch, uint256 blockNumber, uint256 price);
    event BetBull(
        address indexed sender,
        uint256 indexed currentEpoch,
        uint256 amount
    );
    event BetBear(
        address indexed sender,
        uint256 indexed currentEpoch,
        uint256 amount
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    modifier transitionAfter() {
        _;
        nextStage();
    }

    function nextStage() internal {
        stage = Stages(uint(stage) + 1);
    }

    function nextEpoch() internal {
        currentEpoch = currentEpoch + 1;
    }

    // constructor(uint256 _epochBlocks) {
    //     owner = msg.sender;
    //     epochBlocks = _epochBlocks;
    // }
    function initialize(uint256 _epochBlocks) public {
        owner = msg.sender;
        epochBlocks = _epochBlocks;
        rewardRate = 99;
        treasuryRate = 1;
        lastActiveEpoch = 1;
        currentPrice = 100;
        stage = Stages.Initial;
    }


    function next() external onlyOwner {
        if(stage == Stages.Initial) {
            nextStage();
            nextEpoch();
            _startRound(currentEpoch);
        } else if (stage == Stages.GenesisRound) {
            require(getNextRequiredAssistance() <= 0, "getNextRequiredAssistance() need to be 0 or below");
            _lockRound(currentEpoch);
            nextEpoch();
            _startRound(currentEpoch);
            nextStage();
        } else if (stage == Stages.NormalRound) {
            require(getNextRequiredAssistance() <= 0, "getNextRequiredAssistance() need to be 0 or below");
            _endRound(currentEpoch - 1);
            _calculateRewards(currentEpoch - 1);
            Round memory round = rounds[currentEpoch - 1];

            if (round.rewardAmount > 0) {
                _distributeRewards(currentEpoch - 1);
            }

            _lockRound(currentEpoch);
            nextEpoch();
            _startRound(currentEpoch);
        }
    }
    function getUserRounds(
        address user,
        uint256 cursor,
        uint256 size
    )
        external
        view
        returns (
            uint256[] memory,
            BetInfo[] memory,
            uint256
        )
    {
        uint256 length = size;

        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        BetInfo[] memory betInfo = new BetInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[user][cursor + i];
            betInfo[i] = ledger[values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }

    function betBear() external payable {
        require(
            ledger[currentEpoch][msg.sender].amount == 0,
            "Can only bet once per round"
        );

        // Update round data
        uint256 amount = msg.value;
        Round storage round = rounds[currentEpoch];
        round.bearAmount = round.bearAmount + amount;

        // Update user data
        BetInfo storage betInfo = ledger[currentEpoch][msg.sender];
        betInfo.position = Position.Bear;
        betInfo.amount = amount;
        userRounds[msg.sender].push(currentEpoch);
        round.pseudoRound = false;

        // Update playerlist
        playerList[currentEpoch].push(msg.sender);

        emit BetBear(msg.sender, currentEpoch, amount);
    }

    function betBull() external payable {
        require(
            ledger[currentEpoch][msg.sender].amount == 0,
            "Can only bet once per round"
        );
        Round storage round = rounds[currentEpoch];
        require(round.stage == RoundStages.Start, "Round not bettable");

        // Update round data
        uint256 amount = msg.value;
        round.bullAmount = round.bullAmount + amount;

        // Update user data
        BetInfo storage betInfo = ledger[currentEpoch][msg.sender];
        betInfo.position = Position.Bull;
        betInfo.amount = amount;
        userRounds[msg.sender].push(currentEpoch);
        round.pseudoRound = false;

        // Update playerlist
        playerList[currentEpoch].push(msg.sender);

        emit BetBull(msg.sender, currentEpoch, amount);
    }

    function _startRound(uint256 epoch) internal {
        Round storage round = rounds[epoch];
        round.startBlock = block.number;
        round.lockBlock = block.number + epochBlocks;
        round.endBlock = block.number + epochBlocks * 2;
        round.epoch = epoch;
        placePseudoRandomBet();

        emit StartRound(epoch, block.number);
    }

    function _lockRound(uint256 epoch) internal {
        Round storage round = rounds[epoch];
        round.lockPrice = currentPrice;
        round.stage =  RoundStages.Locked;
        round.endBlock = block.number + epochBlocks;

        emit LockRound(epoch, block.number, round.lockPrice);
    }

    function _endRound(uint256 epoch) internal {
        Round storage round = rounds[epoch];
        round.closePrice = currentPrice;
        round.stage = RoundStages.Ended;
        lastActiveEpoch = lastActiveEpoch + 1;
        // round.oracleCalled = true;

        emit EndRound(epoch, block.number, round.closePrice);
    }

    function getRound(uint epoch) public view returns(Round memory) {
        return rounds[epoch];
    }

    function getCurrentRound() public view returns(Round memory) {
        return rounds[currentEpoch];
    }

    
    function getNextRequiredAssistance() public view returns(int256) {
        if (lastActiveEpoch == 0) {
            return int(block.number);
        }
        Round memory _round = rounds[lastActiveEpoch];
        if(_round.stage == RoundStages.Start) {
            return int(_round.lockBlock) - int(block.number);
        } else {
            return int(_round.endBlock) - int(block.number);
        }
    }

    function setCurrentPrice(uint256 price) external onlyOwner {
        currentPrice = price;
    }

    function donateTreasury() external payable onlyOwner {
        treasuryAmount = treasuryAmount + msg.value;
    }

    function claimTreasury(address payable _to) public onlyOwner {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
       _to.transfer(address(this).balance);
    }

    function getTreasuryAmount() public view returns (uint) {
        return treasuryAmount;
    }

    function getRandomNumber() public view returns (uint) {
        uint hashBlock = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, currentEpoch)));
        uint result = hashBlock % 99;
        if (result != 0) {
            return result;
        } else {
            return 32;
        }
    }

    function placePseudoRandomBet() internal {
        uint256 totalBetAmount = 0.001 ether;
        uint256 randomNumber = getRandomNumber();
        uint256 amountBull = randomNumber * 10 ** 13;
        uint256 amountBear = (100 - randomNumber) * 10 ** 13;
        Round storage round = rounds[currentEpoch];
        round.pseudoRound = true;
        round.bullAmount = amountBull;
        round.bearAmount = amountBear;
        treasuryAmount = treasuryAmount - amountBull - amountBear;
    }
    function _calculateRewards(uint256 epoch) internal {
        Round storage round = rounds[epoch];
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        uint256 treasuryAmt;

        if (round.pseudoRound) {
            treasuryAmount = treasuryAmount + round.bearAmount + round.bullAmount;
            // round.bearAmount = 0;
            // round.bullAmount = 0;
        } else {
            // Bull wins
            if (round.closePrice > round.lockPrice) {
                rewardBaseCalAmount = round.bullAmount;
                rewardAmount = ((round.bullAmount + round.bearAmount) * rewardRate) / TOTAL_RATE;
                treasuryAmt = (round.bullAmount + round.bearAmount) - rewardAmount;
            // Bear wins
            } else if (round.closePrice < round.lockPrice) {
                rewardBaseCalAmount = round.bearAmount;
                rewardAmount = ((round.bullAmount + round.bearAmount) * rewardRate) / TOTAL_RATE;
                treasuryAmt = (round.bullAmount + round.bearAmount) - rewardAmount;
            } else {
                rewardBaseCalAmount = 0;
                rewardAmount = 0;
                treasuryAmt = round.bullAmount + round.bearAmount;
            }
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;

        treasuryAmount = treasuryAmount + treasuryAmt;
    }

    function getPlayerList(uint256 epoch)
        public
        view
        returns (address[] memory)
    {
        address[] memory _playerList = playerList[epoch];
        return _playerList;
    }

    function _distributeRewards(uint256 epoch) internal {
        require(rounds[epoch].rewardAmount > 0, "No Rewards to distribute");

        uint256 reward;
        address claimant;
        address[] memory _playerList = getPlayerList(epoch);

        for (uint256 i = 0; i < _playerList.length; i++) {
            claimant = _playerList[i];
            reward = 0;
            // Round valid, claim rewards
            if (rounds[epoch].stage == RoundStages.Ended) {
                if (claimable(epoch, claimant) == true) {
                    Round memory round = rounds[epoch];
                    reward = ledger[epoch][claimant]
                        .amount *
                        round.rewardAmount /
                        round.rewardBaseCalAmount;
                }
            }
            // Round invalid, refund bet amount
            else {
                // if (refundable(epoch, claimant) == true) {
                //     reward = ledger[epoch][claimant].amount;
                // }
            }
            if (reward > 0) {
                BetInfo storage betInfo = ledger[epoch][claimant];
                betInfo.claimed = true;
                _safeTransferBNB(address(claimant), reward);

                emit Claim(claimant, epoch, reward);
            }
        }
    }

    function claimable(uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        Round memory round = rounds[epoch];
        if (round.lockPrice == round.closePrice) {
            return false;
        }
        return
            round.stage == RoundStages.Ended &&
            ((round.closePrice > round.lockPrice &&
                betInfo.position == Position.Bull) ||
                (round.closePrice < round.lockPrice &&
                    betInfo.position == Position.Bear));
    }

    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{gas: 23000, value: value}("");
        require(success, "TransferHelper: BNB_TRANSFER_FAILED");
    }
    
}