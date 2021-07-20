/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.4;

contract Dice {
    uint32 constant POUNDAGE_BASE = 1000;

    uint16 public poundagePercent = 20;
    uint128 public minPoundage = 0.001 ether;
    uint40 public maxNumberSpan = 150;

    bool public stopBet;
    uint public minBet = 0.01 ether;
    uint public maxProfit = 5 ether;
    uint public frozenAssets;

    address public owner;
    address private nextOwner;
    address public croupier;
    address public signAddr;

    struct Bet {
        uint128 amount;
        uint8 modulo;
        uint40 placeBlockNumber;
        bytes5 userBets;
        address gambler;
        bytes32 secretSign;
    }

    mapping(bytes32 => Bet) bets;

    event Commit(bytes32 key, uint amount);
    event SendFunds(bytes32 key, int8 ret, uint amount);
    event SendFundsFailed(bytes32 key, int8 ret, uint amount);

    constructor() {
        address presetAddr = 0x0000000000000000000000000000001234567890;
        owner = msg.sender;
        croupier = presetAddr;
        signAddr = presetAddr;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    modifier onlyCroupier {
        require(msg.sender == croupier, "OnlyCroupier methods called by non-croupier.");
        _;
    }

    function approveNextOwner(address _nextOwner) external onlyOwner {
        require (_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() external {
        require (msg.sender == nextOwner, "Can only accept preapproved new owner.");
        owner = nextOwner;
    }

    receive() external payable {}

    function setCroupier(address newCroupier) external onlyOwner {
        croupier = newCroupier;
    }

    function setSignAddr(address newSignAddr) external onlyOwner {
        signAddr = newSignAddr;
    }

    function setBetStatus(bool _stopBet) external onlyOwner {
        stopBet = _stopBet;
    }
    function setMinBet(uint _minBet) external onlyOwner {
        minBet = _minBet;
    }
    function setMaxProfit(uint _maxProfit) external onlyOwner {
        maxProfit = _maxProfit;
    }
    function setPoundagePercent(uint16 _poundagePercent) external onlyOwner {
        poundagePercent = _poundagePercent;
    }
    function setMinPoundage(uint128 _minPoundage) external onlyOwner {
        minPoundage = _minPoundage;
    }
    function setMaxNumberSpan(uint40 _maxNumberSpan) external onlyOwner {
        maxNumberSpan = _maxNumberSpan;
    }

    function withdraw(address beneficiary, uint withdrawAmount) external onlyOwner {
        require (frozenAssets + withdrawAmount <= address(this).balance, "Not enough funds.");
        payable(beneficiary).transfer(withdrawAmount);
    }

    function kill() external onlyOwner {
        selfdestruct(payable(owner));
    }

    function checkUserBets(uint8 modulo, bytes5 userBets) private pure {
        if(modulo == 2) {
            uint8 s = uint8(userBets[0]);
            require(s > 0 && s <= 2, "bet data is invalid.");
        }else if(modulo == 6) {
            for(uint8 i = 0; i < userBets.length; i++) {
                uint8 s = uint8(userBets[0]);
                require(s >= 0 && s <= 6, "bet data is invalid.");
            }
        }else if(modulo == 100) {
            uint8 s = uint8(userBets[0]);
            require(s > 0 && s < 98, "bet data is invalid.");
        }else {
            revert("modulo is invalid.");
        }
    }

    function placeBet(uint8 modulo, bytes5 userBets, uint40 requestBlock, bytes32 key, bytes32 secretSign, bytes32 r, bytes32 s) external payable {
        require(!stopBet, "Game Pause!");
        require (block.number <= requestBlock + maxNumberSpan, "Commit has expired.");

        bytes32 sha3Hash = keccak256(abi.encodePacked(key, requestBlock, userBets));
        require(
            signAddr == ecrecover(sha3Hash, 27, r, s) || signAddr == ecrecover(sha3Hash, 28, r, s),
            "ECDSA signature is not valid."
        );

        Bet storage bet = bets[key];
        require(bet.gambler == address(0), "Bet should be in a 'clean' state.");

        checkUserBets(modulo, userBets);

        uint amount = msg.value;
        require(amount >= minBet, "Amount should be within range.");
        uint winAmount = getWinAmount(amount, modulo, getBetPercent(modulo, userBets));
        require(winAmount <= amount + maxProfit, "maxProfit limit violation.");
        frozenAssets += winAmount;
        require(frozenAssets <= address(this).balance, "Cannot afford to lose this bet.");

        bet.amount = uint128(amount);
        bet.modulo = modulo;
        bet.userBets = userBets;
        bet.placeBlockNumber = uint40(block.number);
        bet.gambler = msg.sender;
        bet.secretSign = secretSign;

        emit Commit(key, amount);
    }

    function settleBet(bytes32 key, bytes32 halfRandom) external onlyCroupier {
        Bet storage bet = bets[key];
        
        uint8 modulo = bet.modulo;
        uint128 amount = bet.amount;
        bytes5 userBets = bet.userBets;

        require(amount > 0, "The bet was settled");
        require(block.number > bet.placeBlockNumber, "settleBet in the same block as placeBet, or before.");

        bytes32 blockHash = blockhash(bet.placeBlockNumber);
        if(blockHash > 0) {
            require(bet.secretSign == keccak256(abi.encodePacked(halfRandom, key)), "signature is invalid.");

            bet.amount = 0;
            bytes32 entropy = keccak256(abi.encodePacked(halfRandom, blockHash));
            uint8 result = uint8(uint(entropy) % modulo + 1);
            uint winAmount = getResultAmount(amount, modulo, result, userBets);
            sendFunds(key, bet.gambler, int8(result), winAmount);
        }else {
            bet.amount = 0;
            sendFunds(key, bet.gambler, -2, amount);
        }
        uint betFrozen = getWinAmount(amount, modulo, getBetPercent(modulo, userBets));
        if(betFrozen > frozenAssets) {
            frozenAssets = 0;
        }else {
            frozenAssets -= betFrozen;
        }
    }

    function refundBet(bytes32 key) external onlyCroupier {
        Bet storage bet = bets[key];
        uint amount = bet.amount;
        uint8 modulo = bet.modulo;

        require(amount > 0, "The bet was settled");
        bet.amount = 0;
        sendFunds(key, bet.gambler, -2, amount);
        uint betFrozen = getWinAmount(amount, modulo, getBetPercent(modulo, bet.userBets));
        if(betFrozen > frozenAssets) {
            frozenAssets = 0;
        }else {
            frozenAssets -= betFrozen;
        }
    }

    function getBetPercent(uint8 modulo, bytes5 userBets) private pure returns (uint8 percent) {
        percent = modulo;
        if(modulo == 2) {
            percent = 1;
        }else if(modulo == 6) {
            percent = 0;
            for(uint8 i = 0; i < userBets.length; i++) {
                if(userBets[i] > 0) percent++;
            }
        }else if(modulo == 100) {
            percent = uint8(userBets[0]);
        }
    }

    function getResultAmount(uint amount, uint8 modulo, uint8 ret, bytes5 userBets) private view returns (uint winAmount) {
        winAmount = 1;
        if(modulo == 100) {
            if(ret >= uint8(userBets[0])) {
                winAmount = getWinAmount(amount, modulo, getBetPercent(modulo, userBets));
            }
        }else {
            for(uint8 i = 0; i < userBets.length; i++) {
                if(ret == uint8(userBets[i])) {
                    winAmount = getWinAmount(amount, modulo, getBetPercent(modulo, userBets));
                    break;
                }
                if(modulo == 2 && i == 0) break;
            }
        }
    }

    function getWinAmount(uint amount, uint8 modulo, uint8 percent) private view returns (uint winAmount) {
        winAmount = amount * modulo / percent;
        uint poundage = (winAmount - amount) * poundagePercent / POUNDAGE_BASE;
        if(poundage < minPoundage) poundage = minPoundage;
        winAmount -= poundage;
    }

    function sendFunds(bytes32 key, address gambler, int8 ret, uint amount) private {
        if(payable(gambler).send(amount)) {
            emit SendFunds(key, ret, amount);
        }else {
            emit SendFundsFailed(key, ret, amount);
        }
    }
}