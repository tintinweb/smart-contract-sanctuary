// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./FixedPoint.sol";

contract Jackpot is Ownable {
    using SafeMath for uint256;
    using FixedPoint for FixedPoint.uq144x112;
    using FixedPoint for FixedPoint.uq112x112;

    address public _marketWallet = 0xCa09441f094A9BdC553Aed501e1Be1145D88F72b;
    address public _deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 public _currentRound = 1;
    uint256 public _totalTickets = 0;
    uint256 public _totalToClaimReward = 0;
    uint256 public _totalClaimedReward = 0;

    mapping(uint256 => uint256) private _toClaimReward;
    mapping(uint256 => uint256) private _claimedReward;

    mapping(uint256 => mapping(address => bool)) private _isClaimed;
    mapping(uint256 => mapping(address => uint256)) private _winnersReward;
    mapping(uint256 => address[3]) private _winners;

    mapping(uint256 => uint256) private _totalTicketsR;

    mapping(uint256 => mapping(address => uint256)) private _holdersTickets;
    mapping(uint256 => mapping(address => bool)) private _isAdded;
    mapping(uint256 => address[]) private _holders;

    mapping(address => bool) private _exclude;

    mapping(address => bool) private _dxsale;

    uint256 public _minPrize = 10 ether;
    uint256 public _maxPrize = 100 ether;
    uint256 public _totalPrize = 60;

    uint256 public _firstPrize = 50;
    uint256 public _secondPrize = 30;
    uint256 public _thirdPrize = 20;

    uint256 public _firstPrizeOdds = 300;
    uint256 public _secondPrizeOdds = 200;
    uint256 public _thirdPrizeOdds = 150;

    uint256 public _lastJackpotTS = 0;
    uint256 public _jackpotPeriod = 24 hours;
    uint256 public _jackpotThreshold = 0.3 ether;

    bool private _jackpoting = false;

    bool public _isBasedOnToken = false;
    uint256 public _tokensAmont = 1000000 * (10**18);

    bool public _enableSubTickets = false;

    uint256 public _presalePrice = 18000000 * (10**18);

    event WithdrawETH(address indexed _addr, uint256 indexed amount);
    event NewRound(uint256 indexed round);
    event TicketsCountChanged();

    constructor() public {}

    /*************** onlyOwner function ***************/

    function setTokensAmont(uint256 tokensAmont) external onlyOwner {
        _tokensAmont = tokensAmont;
    }

    function setLastJackpotTS(uint256 lastJackpotTS) external onlyOwner {
        _lastJackpotTS = lastJackpotTS;
    }

    function setJackpotThreshold(uint256 jackpotThreshold) external onlyOwner {
        _jackpotThreshold = jackpotThreshold;
    }

    function setJackpotPeriod(uint256 jackpotPeriod) external onlyOwner {
        _jackpotPeriod = jackpotPeriod;
    }

    function enableBasedOnToken(bool isBasedOnToken) external onlyOwner {
        _isBasedOnToken = isBasedOnToken;
    }

    function excludeJackpot(address holder) external onlyOwner {
        _exclude[holder] = true;
    }

    function setDxsale(address dxRouter, address presaleRouter)
        external
        onlyOwner
    {
        _exclude[dxRouter] = true;
        _exclude[presaleRouter] = true;
        _dxsale[dxRouter] = true;
        _dxsale[presaleRouter] = true;
    }

    function setPrizePercent(
        uint256 total,
        uint256 first,
        uint256 second,
        uint256 third
    ) external onlyOwner {
        _totalPrize = total;
        _firstPrize = first;
        _secondPrize = second;
        _thirdPrize = third;
    }

    function setPrizeOdds(
        uint256 first,
        uint256 second,
        uint256 third
    ) external onlyOwner {
        _firstPrizeOdds = first;
        _secondPrizeOdds = second;
        _thirdPrizeOdds = third;
    }

    function setPrize(uint256 minPrize, uint256 maxPrize) external onlyOwner {
        _minPrize = minPrize;
        _maxPrize = maxPrize;
    }

    function setEnableSubTickets(bool enableSubTickets) external onlyOwner {
        _enableSubTickets = enableSubTickets;
    }

    function setMarketWallet(address newMarketaddress) external {
        require(
            msg.sender == _marketWallet && newMarketaddress != _marketWallet,
            "Jackpot: Cannot update marketwallet"
        );
        _marketWallet = newMarketaddress;
    }

    function jackpot(
        address pair,
        address from,
        address to,
        uint256 amount
    ) external onlyOwner {
        uint256 totalReward = ((address(this).balance).sub(_totalToClaimReward))
            .mul(_totalPrize)
            .div(100);
        totalReward = totalReward > _maxPrize ? _maxPrize : totalReward;

        if (
            totalReward >= _minPrize &&
            _lastJackpotTS > 0 &&
            (block.timestamp - _lastJackpotTS) >= _jackpotPeriod &&
            !_jackpoting
        ) {
            _jackpoting = true;
            uint256 round = _currentRound;
            jackpot(round, totalReward);
            _currentRound += 1;
            emit NewRound(_currentRound);
            _lastJackpotTS = block.timestamp;
            _jackpoting = false;
        }

        uint256 tickets = 0;
        if (_currentRound == 1 && _dxsale[from]) {
            tickets = amount.div(_presalePrice).mul(2);
            addTickets(_currentRound, to, tickets);
        } else {
            if (_isBasedOnToken) {
                tickets = amount.div(_tokensAmont);
            } else {
                uint256 price = getTokenPerBNBPrice(pair, _jackpotThreshold);
                tickets = (amount.add(price.mul(10).div(100))).div(price);
            }

            if (from == pair) {
                addTickets(_currentRound, to, tickets);
            }

            if (_enableSubTickets && to == pair) {
                subTickets(_currentRound, from, tickets);
            }
        }
    }

    /*************** private function ************/

    function jackpot(uint256 round, uint256 totalReward) private {
        uint256 totalTickets = _totalTicketsR[round];
        if (totalTickets > 0) {
            (address winner1, uint256 amount1) = jackpot(
                round,
                totalReward.mul(_firstPrize).div(100),
                totalTickets.mul(_firstPrizeOdds).div(100)
            );

            (address winner2, uint256 amount2) = jackpot(
                round,
                totalReward.mul(_secondPrize).div(100),
                totalTickets.mul(_secondPrizeOdds).div(100)
            );

            (address winner3, uint256 amount3) = jackpot(
                round,
                totalReward.mul(_thirdPrize).div(100),
                totalTickets.mul(_thirdPrizeOdds).div(100)
            );

            _winners[round] = [winner1, winner2, winner3];

            uint256 amount = amount1.add(amount2).add(amount3);
            _totalToClaimReward = _totalToClaimReward.add(amount);
            _toClaimReward[round] = amount;
        }
    }

    function jackpot(
        uint256 round,
        uint256 reward,
        uint256 range
    ) private returns (address winner, uint256 amount) {
        uint256 target = random(range);
        uint256 totalParticipants = _holders[round].length;
        uint256 total;
        for (uint256 idx = 0; idx < totalParticipants; idx++) {
            address curAddress = _holders[round][idx];
            uint256 num = _holdersTickets[round][curAddress];
            if (
                num > 0 &&
                !_exclude[curAddress] &&
                _winnersReward[round][curAddress] == 0
            ) {
                total += num;
                if (total >= target) {
                    _winnersReward[round][curAddress] = reward;
                    return (curAddress, reward);
                }
            }
        }

        return (_deadWallet, 0);
    }

    function addTickets(
        uint256 round,
        address holder,
        uint256 tickets
    ) private {
        if (tickets > 0 && !_exclude[holder]) {
            _holdersTickets[round][holder] = _holdersTickets[round][holder].add(
                tickets
            );
            _totalTicketsR[round] = _totalTicketsR[round].add(tickets);
            _totalTickets += tickets;

            if (!_isAdded[round][holder]) {
                _isAdded[round][holder] = true;
                _holders[round].push(holder);
            }
            emit TicketsCountChanged();
        }
    }

    function subTickets(
        uint256 round,
        address holder,
        uint256 tickets
    ) private {
        if (tickets > 0 && !_exclude[holder]) {
            _holdersTickets[round][holder] = _holdersTickets[round][holder].sub(
                tickets
            );
            _totalTicketsR[round] = _totalTicketsR[round].sub(tickets);
            _totalTickets -= tickets;
            emit TicketsCountChanged();
        }
    }

    function getTokenPerBNBPrice(address uniswapV2Pair, uint256 amountIn)
        private
        view
        returns (uint256 amountOut)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        address token0 = pair.token0();
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        if (token0 == owner()) {
            amountOut = (FixedPoint.fraction(reserve0, reserve1).mul(amountIn))
                .decode144();
        } else {
            amountOut = (FixedPoint.fraction(reserve1, reserve0).mul(amountIn))
                .decode144();
        }
    }

    function random(uint256 _length) private view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(now, block.difficulty, msg.sender))
            ) % _length;
    }

    /*************** public function **************/

    function viewtoClaimReward(uint256 round) public view returns (uint256) {
        return _toClaimReward[round];
    }

    function viewClaimedReward(uint256 round) public view returns (uint256) {
        return _claimedReward[round];
    }

    function viewTotalTicketsR(uint256 round) public view returns (uint256) {
        return _totalTicketsR[round];
    }

    function viewWinners(uint256 round)
        public
        view
        returns (address[3] memory)
    {
        return _winners[round];
    }

    function viewIsClaimed(uint256 round, address holder)
        public
        view
        returns (bool)
    {
        return _isClaimed[round][holder];
    }

    function viewWinnersReward(uint256 round, address holder)
        public
        view
        returns (uint256)
    {
        return _winnersReward[round][holder];
    }

    function viewHoldersTickets(uint256 round, address holder)
        public
        view
        returns (uint256)
    {
        return _holdersTickets[round][holder];
    }

    /******************* public function with requirement */
    function claimJackpotReward(uint256 round) public {
        uint256 amount = _winnersReward[round][msg.sender];
        require(
            !_isClaimed[round][msg.sender] &&
                amount > 0 &&
                _totalToClaimReward >= amount &&
                _toClaimReward[round] >= amount,
            "Cannot claim"
        );

        (bool success, ) = msg.sender.call{value: amount}("");
        if (success) {
            _totalClaimedReward = _totalClaimedReward.add(amount);
            _claimedReward[round] = _claimedReward[round].add(amount);

            _totalToClaimReward = _totalToClaimReward.sub(amount);
            _toClaimReward[round] = _toClaimReward[round].sub(amount);

            _isClaimed[round][msg.sender] = true;
        }
    }

    function withdrawEth() public {
        require(msg.sender == _marketWallet, "Cannot Claim");
        uint256 amount = address(this).balance;
        (bool success, ) = address(_marketWallet).call{value: amount}("");
        if (success) {
            emit WithdrawETH(_marketWallet, amount);
        }
    }

    function withdrawEth(uint256 amount) public {
        require(msg.sender == _marketWallet, "Cannot Claim");
        (bool success, ) = address(_marketWallet).call{value: amount}("");
        if (success) {
            emit WithdrawETH(_marketWallet, amount);
        }
    }

    receive() external payable {}
}