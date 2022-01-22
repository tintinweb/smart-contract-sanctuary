/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract MultiLottery {

    address payable public owner;
    uint public ownerFee;

    struct Lottery {

        // We're going to draw from this array, as players have different chances of winning based on the amount of money they invested.
        // Can contain multiple times same address
        address payable[] _playersPool;

        // unique players list
        address payable[] players;

        // keep track of players investments in case of a refund
        uint [] _playerInvestment;

        // this is a mapping of entered players, to ensure that a player didn't enter twice
        mapping (address => uint) _playersEntryCheck;

        // lottery prices related vars
        uint lotteryPriceMin;
        uint lotteryPriceMax;
        uint lotteryTicketsMax;

        // informational vars
        uint drawId;
        mapping (uint => address payable) lotteryHistory;
        bool isActive;
        uint lotteryBalance;

    }

    // Lottery mapping
    uint private _numLottery;
    mapping (uint => Lottery) lotteriesMapping;

    constructor() {
        _numLottery = 1;
        ownerFee = 5;
        owner = payable(msg.sender);
    }

    // Create lotteries instance
    function createLottery(uint _lotteryPriceMin, uint _lotteryPriceMax) public onlyOwner {
        Lottery storage lotteryInstance = lotteriesMapping[_numLottery++];

        lotteryInstance.lotteryPriceMin = _lotteryPriceMin;
        lotteryInstance.lotteryPriceMax = _lotteryPriceMax;
        lotteryInstance.lotteryTicketsMax = _lotteryPriceMax / _lotteryPriceMin;
        lotteryInstance.drawId = 1;
        lotteryInstance.isActive = true;

    }



    // MODIFIERS




    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }




    // EVENTS




    event NewPlayer(
        uint indexed lotteryId,
        uint indexed drawId,
        address playerAddress,
        uint amountDeposited
    );

    event NewWinner(
        uint indexed lotteryId,
        uint indexed drawId,
        address playerAddress,
        uint amountWon
    );




    // GETTERS




    function getLotteryPrize(uint _lotteryId) public view returns (uint) {
        return _getRewardAmount(lotteriesMapping[_lotteryId].lotteryBalance);
    }

    function getPlayers(uint _lotteryId) public view returns (address payable[] memory) {
        return lotteriesMapping[_lotteryId].players;
    }

    function getMinPrice(uint _lotteryId) public view returns (uint) {
        return lotteriesMapping[_lotteryId].lotteryPriceMin;
    }

    function getMaxPrice(uint _lotteryId) public view returns (uint) {
        return lotteriesMapping[_lotteryId].lotteryPriceMax;
    }

    function getPastWinner(uint _lotteryId, uint _drawId) public view returns (address) {
        return lotteriesMapping[_lotteryId].lotteryHistory[_drawId];
    }

    function getLotteryState(uint _lotteryId) public view returns (bool) {
        return lotteriesMapping[_lotteryId].isActive;
    }




    // PRIVATE FUNCTIONS




    // Verify that players has not entered more than once
    function _setPlayerEntryCheck(Lottery storage _lottery, address _player) private {
        _lottery._playersEntryCheck[_player] = _lottery.drawId + 1;
    }

    function _hasEntered(Lottery storage _lottery, address _player) private view returns (bool) {
        if (_lottery._playersEntryCheck[_player] > _lottery.drawId) {
            return true;
        } else {
            return false;
        }
    }

    // Determine players tickets in _playersPool based on their invested amount
    function _determinePlayerTickets(Lottery storage _lottery, uint _amount) private view returns (uint) {
        uint _playerTickets = _amount * _lottery.lotteryTicketsMax / _lottery.lotteryPriceMax;
        if (_playerTickets <= 0) {
            return 1;
        } else {
            return _playerTickets;
        }
    }

    // Add player entries to pool
    function _addPlayerToPool(Lottery storage _lottery, uint _amount, address payable _player) private {
        for (uint i = 0; i < _determinePlayerTickets(_lottery, _amount); i++) {
            _lottery._playersPool.push(payable(_player));
        }
    }

    // calculate reward amount
    function _getRewardAmount(uint _pot) private view returns (uint) {
        return _pot * (100 - ownerFee) / 100;
    }

    // reset lottery state
    function _resetLotteryState(Lottery storage _lottery) private {
        _lottery.drawId++;
        _lottery.lotteryBalance = 0;
        _lottery._playersPool = new address payable[](0);
        _lottery.players = new address payable[](0);
        _lottery._playerInvestment = new uint[](0);
    }




    // LOTTERY RELATED FUNCTIONS




    // Setters
    function setLotteryPriceMin(uint _lotteryId, uint _lotteryPriceMinInWei) public onlyOwner {
        require(_lotteryPriceMinInWei >= .00001 ether && _lotteryPriceMinInWei <= lotteriesMapping[_lotteryId].lotteryPriceMax, "MinEntryPriceError: min entry has to be minimum 0.00001 eth and can't be superior than lotteryPriceMax");
        lotteriesMapping[_lotteryId].lotteryPriceMin = _lotteryPriceMinInWei;
        _setLotteryTicketsMax(lotteriesMapping[_lotteryId]);
    }

    function setLotteryPriceMax(uint _lotteryId, uint _lotteryPriceMaxInWei) public onlyOwner {
        require(_lotteryPriceMaxInWei >= .0001 ether && _lotteryPriceMaxInWei >= lotteriesMapping[_lotteryId].lotteryPriceMin, "MaxEntryPriceError: max entry has to be minimum 0.0001 eth and can't be inferior than min entry");
        lotteriesMapping[_lotteryId].lotteryPriceMax = _lotteryPriceMaxInWei;
        _setLotteryTicketsMax(lotteriesMapping[_lotteryId]);
    }

    function _setLotteryTicketsMax(Lottery storage _lottery) private {
        _lottery.lotteryTicketsMax = _lottery.lotteryPriceMax / _lottery.lotteryPriceMin;
    }

    function setOwnerFee(uint _fee) public onlyOwner {
        require(_fee > 0 && _fee < 15, "SetFeeError: fee must be greater than 0 and lower than 15");
        ownerFee = _fee;
    }

    function setState(uint _lotteryId, bool _state) public onlyOwner {
        lotteriesMapping[_lotteryId].isActive = _state;
    }


    // Core functions
    function enter(uint _lotteryId) public payable {
        require(lotteriesMapping[_lotteryId].isActive, "PausedError: cannot enter while lottery is paused");
        require(!_hasEntered(lotteriesMapping[_lotteryId], msg.sender), "AlreadyEnteredError: cannot enter more than once");
        require(msg.value >= lotteriesMapping[_lotteryId].lotteryPriceMin && msg.value <= lotteriesMapping[_lotteryId].lotteryPriceMax, "EnterPriceError: amount inferior than lotteryPriceMin or superior than lotteryPriceMax");

        // We first add player investment into lottery balance
        lotteriesMapping[_lotteryId].lotteryBalance = lotteriesMapping[_lotteryId].lotteryBalance + msg.value;

        // We add player entries to the _playersPool array based on what he had invested
        _addPlayerToPool(lotteriesMapping[_lotteryId], msg.value, payable(msg.sender));

        // then we add it to the playerEntryCheck mapping
        _setPlayerEntryCheck(lotteriesMapping[_lotteryId], msg.sender);

        // and finally, we add it to our public players array and playerInvestment array
        lotteriesMapping[_lotteryId].players.push(payable(msg.sender));
        lotteriesMapping[_lotteryId]._playerInvestment.push(msg.value);

        // Emit NewPlayer event
        emit NewPlayer(_lotteryId, lotteriesMapping[_lotteryId].drawId, msg.sender, msg.value);
    }


    // generates a pseudo random number.
    // We don't use block current data so it should be miner resistant.
    // Even if a miner manipulated the blockhash in expectation of the drawing,
    // the use of seeds prevents him to guess what would be the final number.
    function getRandomNumber(uint _ownerSalt, uint _innerSalt) public view returns (uint) {
        return uint(
            keccak256(
                abi.encodePacked(
                    _ownerSalt,
                    _innerSalt,
                    blockhash(block.number - 1),
                    blockhash(block.number - 2),
                    blockhash(block.number - 3)
                )
            )
        );
    }


    // Picks the winner of the lottery, put it in winners list then reset _playersPool and players
    function pickWinner(uint _lotteryId, uint _ownerSalt, uint _innerSalt) public onlyOwner {

        // determine winner
        uint index = getRandomNumber(_ownerSalt, _innerSalt) % lotteriesMapping[_lotteryId]._playersPool.length;

        // determine money repartition
        uint _rewardAmount = _getRewardAmount(lotteriesMapping[_lotteryId].lotteryBalance);
        uint _feeAmount = lotteriesMapping[_lotteryId].lotteryBalance - _rewardAmount;

        // transfer prize to winner, transfer fees to owner
        lotteriesMapping[_lotteryId]._playersPool[index].transfer(_rewardAmount);
        owner.transfer(_feeAmount);

        // we add winner to lottery history
        lotteriesMapping[_lotteryId].lotteryHistory[lotteriesMapping[_lotteryId].drawId] = lotteriesMapping[_lotteryId]._playersPool[index];

        // Emit NewWinner event
        emit NewWinner(_lotteryId, lotteriesMapping[_lotteryId].drawId, lotteriesMapping[_lotteryId]._playersPool[index], _rewardAmount);

        // reset lottery state
        _resetLotteryState(lotteriesMapping[_lotteryId]);
    }

    // refund all current lottery players and reset lottery state
    function refund(uint _lotteryId) public onlyOwner {
        for (uint i = 0; i < lotteriesMapping[_lotteryId].players.length; i++) {
            lotteriesMapping[_lotteryId].players[i].transfer(lotteriesMapping[_lotteryId]._playerInvestment[i]);
        }
        _resetLotteryState(lotteriesMapping[_lotteryId]);
    }
}