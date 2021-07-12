/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// SPDX-License-Identifier: -- 🎲 --

pragma solidity ^0.7.0;

// Slot Machine Logic Contract ///////////////////////////////////////////////////////////
// Author: Decentral Games ([email protected]) ///////////////////////////////////////
// Single Play - Simple Slots - TokenIndex

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
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
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'SafeMath: modulo by zero');
        return a % b;
    }
}

contract AccessController {

    address public ceoAddress;
    address public workerAddress;

    bool public paused = false;

    // mapping (address => enumRoles) accessRoles; // multiple operators idea

    event CEOSet(address newCEO);
    event WorkerSet(address newWorker);

    event Paused();
    event Unpaused();

    constructor() {
        ceoAddress = msg.sender;
        workerAddress = msg.sender;
        emit CEOSet(ceoAddress);
        emit WorkerSet(workerAddress);
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

    function setWorker(address _newWorker) external {
        require(
            _newWorker != address(0x0),
            'AccessControl: invalid worker address'
        );
        require(
            msg.sender == ceoAddress || msg.sender == workerAddress,
            'AccessControl: invalid worker address'
        );
        workerAddress = _newWorker;
        emit WorkerSet(workerAddress);
    }

    function pause() external onlyWorker whenNotPaused {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyCEO whenPaused {
        paused = false;
        emit Unpaused();
    }
}

interface TreasuryInstance {

    function getTokenAddress(
        uint8 _tokenIndex
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

contract TreasurySlots is AccessController {

    using SafeMath for uint128;

    uint256 private factors;
    TreasuryInstance public treasury;

    event GameResult(
        address _player,
        uint8 _tokenIndex,
        uint128 _landID,
        uint256 indexed _number,
        uint128 indexed _machineID,
        uint256 _winAmount
    );

    constructor(
        address _treasury,
        uint16 factor1,
        uint16 factor2,
        uint16 factor3,
        uint16 factor4
    ) {
        treasury = TreasuryInstance(_treasury);

        require(
            factor1 > factor2 + factor3 + factor4,
            'Slots: incorrect ratio'
        );

        factors |= uint256(factor1)<<0;
        factors |= uint256(factor2)<<16;
        factors |= uint256(factor3)<<32;
        factors |= uint256(factor4)<<48;
    }

    function play(
        address _player,
        uint128 _landID,
        uint128 _machineID,
        uint128 _betAmount,
        bytes32 _localhash,
        uint8 _tokenIndex
    ) public whenNotPaused onlyWorker {

        require(
            treasury.checkApproval(_player, _tokenIndex) >= _betAmount,
            'Slots: exceeded allowance amount'
        );

        require(
            treasury.getMaximumBet(_tokenIndex) >= _betAmount,
            'Slots: exceeded maximum bet amount'
        );

        require(
            treasury.checkAllocatedTokens(_tokenIndex) >= getMaxPayout(_betAmount),
            'Slots: not enough tokens for payout'
        );

        treasury.tokenInboundTransfer(
            _tokenIndex,
            _player,
            _betAmount
        );

        treasury.consumeHash(
           _localhash
        );

        (uint256 _number, uint256 _winAmount) = _launch(
            _localhash,
            _betAmount
        );

        if (_winAmount > 0) {
            treasury.tokenOutboundTransfer(
                _tokenIndex,
                _player,
                _winAmount
            );
        }

        emit GameResult(
            _player,
            _tokenIndex,
            _landID,
            _number,
            _machineID,
            _winAmount
        );
    }

    function _launch(
        bytes32 _localhash,
        uint128 _betAmount
    ) internal view returns (
        uint256 number,
        uint256 winAmount
    ) {
        number = getRandomNumber(_localhash) % 1000;
        uint256 _numbers = number;

        uint8[5] memory _positions = [255, 0, 16, 32, 48];
        uint8[10] memory _symbols = [4, 4, 4, 4, 3, 3, 3, 2, 2, 1];
        uint256 _winner = _symbols[_numbers % 10];

        for (uint256 i = 0; i < 2; i++) {
            _numbers = uint256(_numbers) / 10;
            if (_symbols[_numbers % 10] != _winner) {
                _winner = 0;
                break;
            }
        }

        delete _symbols;
        delete _numbers;

        winAmount = _betAmount.mul(
            uint16(
                factors>>_positions[_winner]
            )
        );
    }

    function getRandomNumber(
        bytes32 _localhash
    ) private pure returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    _localhash
                )
            )
        );
    }

    function getPayoutFactor(
        uint8 _position
    ) external view returns (uint16) {
       return uint16(
           factors>>_position
        );
    }

    function getMaxPayout(
        uint128 _betSize
    ) public view returns (uint256) {
        return _betSize.mul(
            uint16(
                factors>>0
            )
        );
    }

    function updateFactors(
        uint16 factor1,
        uint16 factor2,
        uint16 factor3,
        uint16 factor4
    ) external onlyCEO {

        require(
            factor1 > factor2 + factor3 + factor4,
            'Slots: incorrect ratio'
        );

        factors = uint256(0);

        factors |= uint256(factor1)<<0;
        factors |= uint256(factor2)<<16;
        factors |= uint256(factor3)<<32;
        factors |= uint256(factor4)<<48;
    }

    function updateTreasury(
        address _newTreasuryAddress
    ) external onlyCEO {
        treasury = TreasuryInstance(
            _newTreasuryAddress
        );
    }

    function migrateTreasury(
        address _newTreasuryAddress
    ) external {
        require(
            msg.sender == address(treasury),
            'Slots: wrong treasury address'
        );
        treasury = TreasuryInstance(_newTreasuryAddress);
    }
}