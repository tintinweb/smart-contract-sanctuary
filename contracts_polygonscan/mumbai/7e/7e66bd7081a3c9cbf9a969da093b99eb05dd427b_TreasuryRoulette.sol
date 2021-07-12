/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// File: contracts/common-contracts/SafeMath.sol

pragma solidity ^0.5.17;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/common-contracts/AccessController.sol

pragma solidity ^0.5.17;

contract AccessController {

    address public ceoAddress;
    address public workerAddress;

    bool public paused = false;

    event CEOSet(address newCEO);
    event WorkerSet(address newWorker);

    event Paused();
    event Unpaused();

    constructor() public {
        ceoAddress = msg.sender;
        workerAddress = msg.sender;
        emit CEOSet(ceoAddress);
    }

    modifier onlyCEO() {
        require(
            msg.sender == ceoAddress,
            'AccessControl: CEO access denied'
        );
        _;
    }

    modifier onlyWorker() {
        require(
            msg.sender == workerAddress,
            'AccessControl: worker access denied'
        );
        _;
    }

    modifier whenNotPaused() {
        require(
            !paused,
            'AccessControl: currently paused'
        );
        _;
    }

    modifier whenPaused {
        require(
            paused,
            'AccessControl: currenlty not paused'
        );
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(
            _newCEO != address(0x0),
            'AccessControl: invalid CEO address'
        );
        ceoAddress = _newCEO;
        emit CEOSet(ceoAddress);
    }

    function setWorker(address _newWorker) public onlyWorker {
        require(
            _newWorker != address(0x0),
            'AccessControl: invalid worker address'
        );
        workerAddress = _newWorker;
        emit WorkerSet(workerAddress);
    }

    function pause() public onlyCEO whenNotPaused {
        paused = true;
        emit Paused();
    }

    function unpause() public onlyCEO whenPaused {
        paused = false;
        emit Unpaused();
    }
}

// File: contracts/common-contracts/TreasuryInstance.sol

pragma solidity ^0.5.17;

interface TreasuryInstance {

    function getTokenAddress(
        uint256 _tokenIndex
    ) external view returns (address);

    function tokenInboundTransfer(
        uint8 _tokenIndex,
        address _from,
        uint256 _amount
    )  external returns (bool);

    function tokenOutboundTransfer(
        uint8 _tokenIndex,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function checkAllocatedTokens(
        uint8 _tokenIndex
    ) external view returns (uint256);

    function checkApproval(
        address _userAddress,
        uint8 _tokenIndex
    ) external view returns (uint256 approved);

    function getMaximumBet(
        uint8 _tokenIndex
    ) external view returns (uint128);

    function consumeHash(
        bytes32 _localhash
    ) external returns (bool);
}

// File: contracts/treasury-example/TreasuryRoulette.sol

pragma solidity ^0.5.17;

// Roulette Logic Contract ///////////////////////////////////////////////////////////
// Author: Decentral Games ([email protected]) ///////////////////////////////////////
// Roulette - MultiPlayer - TokenIndex 2.0




contract TreasuryRoulette is AccessController {

    using SafeMath for uint128;
    using SafeMath for uint256;

    uint256 private store;

    enum BetType { Single, EvenOdd, RedBlack, HighLow, Column, Dozen }

    mapping (uint => uint) public maxSquareBets;
    mapping (uint => mapping (uint => mapping (uint => uint))) public currentBets;

    Bet[] public bets;
    uint256[] winAmounts;

    struct Bet {
        address player;
        uint8 betType;
        uint8 number;
        uint8 tokenIndex;
        uint128 value;
    }

    event GameResult(
        address[] _players,
        uint8[] _tokenIndex,
        uint256 indexed _landID,
        uint256 indexed _number,
        uint256 indexed _machineID,
        uint256[] _winAmounts
    );

    TreasuryInstance public treasury;

    constructor(
        address _treasuryAddress,
        uint128 _maxSquareBetDefault,
        uint8 _maxNumberBets
    ) public {
        treasury = TreasuryInstance(_treasuryAddress);
        store |= _maxNumberBets<<0;
        store |= _maxSquareBetDefault<<8;
        store |= now<<136;
    }

    function checknow64() public view returns (uint64) {
        return uint64(now);
    }

    function createBet(
        address _player,
        uint8 _betType,
        uint8 _number,
        uint8 _tokenIndex,
        uint128 _value
    ) external whenNotPaused onlyCEO {
        bet(
            _player,
            _betType,
            _number,
            _tokenIndex,
            _value
        );
    }

    function bet(
        address _player,
        uint8 _betType,
        uint8 _number,
        uint8 _tokenIndex,
        uint128 _value
    ) internal {

        currentBets[_tokenIndex][_betType][_number] += _value;

        uint256 _maxSquareBet = maxSquareBets[_tokenIndex] == 0
            ? uint128(store>>8)
            : maxSquareBets[_tokenIndex];

        require(
            currentBets[_tokenIndex][_betType][_number] <= _maxSquareBet,
            'Roulette: exceeding maximum bet limit'
        );

        bets.push(Bet({
            player: _player,
            betType: _betType,
            number: _number,
            tokenIndex: _tokenIndex,
            value: _value
        }));
    }

    function launch(
        bytes32 _localhash
    ) external whenNotPaused onlyCEO returns(
        uint256[] memory,
        uint256 number
    ) {
        return _launch(_localhash);
    }

    function _launch(
        bytes32 _localhash
    ) private returns(uint256[] memory, uint256 number) {

        require(now > store>>136, 'Roulette: expired round');
        require(bets.length > 0, 'Roulette: must have bets');

        winAmounts.length = 0;

        store ^= (store>>136)<<136;
        store |= now<<136;

        uint diff = block.difficulty;
        bytes32 hash = _localhash;
        Bet memory lb = bets[bets.length-1];

        number = uint(
            keccak256(
                abi.encodePacked(
                    now, diff, hash, lb.betType, lb.player, lb.number
                )
            )
        ) % 37;

        for (uint i = 0; i < bets.length; i++) {
            bool won = false;
            Bet memory b = bets[i];
            if (b.betType == uint(BetType.Single) && b.number == number) {
                won = true;
            } else if (b.betType == uint(BetType.EvenOdd)) {
                if (number > 0 && number % 2 == b.number) {
                    won = true;
                }
            } else if (b.betType == uint(BetType.RedBlack) && b.number == 0) {
                if ((number > 0 && number <= 10) || (number >= 19 && number <= 28)) {
                    won = (number % 2 == 1);
                } else {
                    won = (number % 2 == 0);
                }
            } else if (b.betType == uint(BetType.RedBlack) && b.number == 1) {
                if ((number > 0 && number <= 10) || (number >= 19 && number <= 28)) {
                    won = (number % 2 == 0);
                } else {
                    won = (number % 2 == 1);
                }
            } else if (b.betType == uint(BetType.HighLow)) {
                if (number >= 19 && b.number == 0) {
                    won = true;
                }
                if (number > 0 && number <= 18 && b.number == 1) {
                    won = true;
                }
            } else if (b.betType == uint(BetType.Column)) {
                if (b.number == 0) won = (number % 3 == 1);
                if (b.number == 1) won = (number % 3 == 2);
                if (b.number == 2) won = (number % 3 == 0);
            } else if (b.betType == uint(BetType.Dozen)) {
                if (b.number == 0) won = (number <= 12);
                if (b.number == 1) won = (number > 12 && number <= 24);
                if (b.number == 2) won = (number > 24);
            }

            if (won) {
                uint256 betWin = b.value.mul(
                    getPayoutForType(b.betType, b.number)
                );
                winAmounts.push(betWin);
            } else {
                winAmounts.push(0);
            }
            currentBets[b.tokenIndex][b.betType][b.number] = 0;
        }

        delete bets;
        return(winAmounts, number);
    }

    function play(
        address[] memory _players,
        uint256 _landID,
        uint256 _machineID,
        uint8[] memory _betIDs,
        uint8[] memory _betValues,
        uint128[] memory _betAmount,
        bytes32 _localhash,
        uint8[] memory _tokenIndex
    ) public whenNotPaused onlyWorker {

        require(
            _betIDs.length == _betValues.length,
            'Roulette: inconsistent amount of betsValues'
        );

        require(
            _tokenIndex.length == _betAmount.length,
            'Roulette: inconsistent amount of betAmount'
        );

        require(
            _betValues.length == _tokenIndex.length,
            'Roulette: inconsistent amount of tokenIndex'
        );

        require(
            _betIDs.length <= uint8(store>>0),
            'Roulette: maximum amount of bets reached'
        );

        treasury.consumeHash(_localhash);
        bool[5] memory checkedTokens;

        for (uint8 i = 0; i < _betIDs.length; i++) {

            require(
                treasury.getMaximumBet(_tokenIndex[i]) >= _betAmount[i],
                'Roulette: bet amount is more than maximum'
            );

            treasury.tokenInboundTransfer(
                _tokenIndex[i],
                _players[i],
                _betAmount[i]
            );

            bet(
                _players[i],
                _betIDs[i],
                _betValues[i],
                _tokenIndex[i],
                _betAmount[i]
            );

            if (!checkedTokens[_tokenIndex[i]]) {
                uint256 tokenFunds = treasury.checkAllocatedTokens(_tokenIndex[i]);
                require(
                    getNecessaryBalance(_tokenIndex[i]) <= tokenFunds,
                    'Roulette: not enough tokens for payout'
                );
                checkedTokens[_tokenIndex[i]] = true;
            }
        }

        delete checkedTokens;

        uint256 _spinResult;
        (winAmounts, _spinResult) = _launch(_localhash);

        for (uint8 i = 0; i < winAmounts.length; i++) {
            if (winAmounts[i] > 0) {
                treasury.tokenOutboundTransfer(
                    _tokenIndex[i],
                    _players[i],
                    winAmounts[i]
                );
            }
        }

        emit GameResult(
            _players,
            _tokenIndex,
            _landID,
            _spinResult,
            _machineID,
            winAmounts
        );
    }

    function getPayoutForType(
        uint256 _betType,
        uint256 _betNumber
    ) public pure returns(uint256) {

        if (_betType == uint8(BetType.Single))
            return _betNumber > 36 ? 0 : 36;
        if (_betType == uint8(BetType.EvenOdd))
            return _betNumber > 1 ? 0 : 2;
        if (_betType == uint8(BetType.RedBlack))
            return _betNumber > 1 ? 0 : 2;
        if (_betType == uint8(BetType.HighLow))
            return _betNumber > 1 ? 0 : 2;
        if (_betType == uint8(BetType.Column))
            return _betNumber > 2 ? 0 : 3;
        if (_betType == uint8(BetType.Dozen))
            return _betNumber > 2 ? 0 : 3;

        return 0;
    }

    function getNecessaryBalance(
        uint256 _tokenIndex
    ) public view returns (
        uint256 _necessaryBalance
    ) {

        uint256 _necessaryForBetType;
        uint256[6] memory betTypesMax;

        for (uint8 _i = 0; _i < bets.length; _i++) {
            Bet memory b = bets[_i];
            if (b.tokenIndex == _tokenIndex) {

                uint256 _payout = getPayoutForType(b.betType, b.number);
                uint256 _square = currentBets[b.tokenIndex][b.betType][b.number];

                require(
                    _payout > 0,
                    'Roulette: incorrect bet type/value'
                );

                _necessaryForBetType = _square.mul(_payout);

                if (_necessaryForBetType > betTypesMax[b.betType]) {
                    betTypesMax[b.betType] = _necessaryForBetType;
                }
            }
        }

        for (uint8 _i = 0; _i < betTypesMax.length; _i++) {
            _necessaryBalance = _necessaryBalance.add(
                betTypesMax[_i]
            );
        }
    }

    function getBetsCountAndValue() external view returns(uint value, uint) {
        for (uint i = 0; i < bets.length; i++) {
            value += bets[i].value;
        }
        return (bets.length, value);
    }

    function getBetsCount() external view returns (uint256) {
        return bets.length;
    }

    function changeMaxSquareBet(
        uint256 _tokenIndex,
        uint256 _newMaxSquareBet
    ) external onlyCEO {
        maxSquareBets[_tokenIndex] = _newMaxSquareBet;
    }

    function changeMaxSquareBetDefault(
        uint128 _newMaxSquareBetDefault
    ) external onlyCEO {
        store ^= uint128((store>>8))<<8;
        store |= _newMaxSquareBetDefault<<8;
    }

    function changeMaximumBetAmount(
        uint8 _newMaximumBetAmount
    ) external onlyCEO {
        store ^= uint8(store)<<0;
        store |= _newMaximumBetAmount<<0;
    }

    function changeTreasury(
        address _newTreasuryAddress
    ) external onlyCEO {
        treasury = TreasuryInstance(_newTreasuryAddress);
    }

    function migrateTreasury(
        address _newTreasuryAddress
    ) external {
        require(
            msg.sender == address(treasury),
            'Roulette: wrong treasury address'
        );
        treasury = TreasuryInstance(_newTreasuryAddress);
    }
}