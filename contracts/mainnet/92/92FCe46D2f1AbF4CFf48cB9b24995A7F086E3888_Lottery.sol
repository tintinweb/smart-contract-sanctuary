// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IToken {
    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    function burn(uint256 amount) external;
}

interface CudlFinance {
    function claimMiningRewards(uint256 nftId) external;

    function buyAccesory(uint256 nftId, uint256 id) external;

    function itemPrice(uint256 itemId) external view returns (uint256);

    function lastTimeMined(uint256 petId) external view returns (uint256);
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract Lottery {
    using SafeMath for uint256;
    CudlFinance public immutable cudlFinance;
    IToken public immutable cudl;
    uint256 public food;

    uint256 public nftOriginId;

    mapping(uint256 => address[]) public players;
    mapping(uint256 => mapping(address => uint256)) public ticketsByPlayers;

    uint256 public currentPet = 0;
    uint256 public currentRound = 0;
    uint256 public end = 0;
    uint256 public start = 0;

    uint256 public randomBlockSize = 3;

    address winner1;
    address winner2;
    address winner3;
    address winner4;

    address public owner;

    // overflow
    uint256 public MAX_INT = 2**256 - 1;

    event LotteryStarted(
        uint256 round,
        uint256 start,
        uint256 end,
        uint256 petId,
        uint256 foodId
    );
    event LotteryEnded(
        uint256 round,
        uint256 petId,
        uint256 cudlPrize,
        address winner1,
        address winner2,
        address winner3,
        address winner4
    );

    event LotteryTicketBought(address participant, uint256 tickets);

    constructor() public {
        cudlFinance = CudlFinance(0x9c10AeD865b63f0A789ae64041581EAc63458209);
        cudl = IToken(0xeCD20F0EBC3dA5E514b4454E3dc396E7dA18cA6A);
        owner = msg.sender;
    }

    function startLottery(
        uint256 _food,
        uint256 _days,
        uint256 _petId,
        uint256 _nftOriginId
    ) external {
        require(msg.sender == owner, "!owner");
        food = _food;
        currentRound = currentRound + 1;
        end = now + _days * 1 days;
        start = now;
        cudl.approve(address(cudlFinance), MAX_INT);
        currentPet = _petId;
        nftOriginId = _nftOriginId;
        emit LotteryStarted(currentRound, start, end, currentPet, food);
    }

    function getInfos(address player)
        public
        view
        returns (
            uint256 _participants,
            uint256 _end,
            uint256 _start,
            uint256 _cudlSize,
            uint256 _food,
            uint256 _currentPet,
            uint256 _foodPrice,
            uint256 _ownerTickets,
            uint256 _currentRound
        )
    {
        _participants = players[currentRound].length;
        _end = end;
        _start = start;
        _cudlSize = cudl.balanceOf(address(this));
        _food = food;
        _currentPet = currentPet;
        _foodPrice = cudlFinance.itemPrice(food);
        _ownerTickets = ticketsByPlayers[currentRound][player];
        _currentRound = currentRound;
    }

    function buyTicket(address _player) external {
        require(start != 0, "The lottery did not start yet");
        if (now > end) {
            endLottery();
            return;
        }

        uint256 lastTimeMined = cudlFinance.lastTimeMined(currentPet);
        uint8 tickets = 1;

        require(
            cudl.transferFrom(
                msg.sender,
                address(this),
                cudlFinance.itemPrice(food)
            )
        );
        cudlFinance.buyAccesory(currentPet, food);

        // We mine if possible, the person that get the feeding transaction gets an extra ticket
        if (lastTimeMined + 1 days < now) {
            cudlFinance.claimMiningRewards(currentPet);
            tickets = 2;
        }

        for (uint256 i = 0; i < tickets; i++) {
            players[currentRound].push(_player);
            ticketsByPlayers[currentRound][_player] =
                ticketsByPlayers[currentRound][_player] +
                1;
        }
        emit LotteryTicketBought(_player, tickets);
    }

    function endLottery() public {
        require(now > end && end != 0);
        uint256 cudlBalance = cudl.balanceOf(address(this));

        end = 0;
        start = 0;

        // pick first winner (the vNFT)
        winner1 = players[currentRound][
            randomNumber(block.number, players[currentRound].length)
        ];

        IERC721(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69).safeTransferFrom(
            address(this),
            winner1,
            nftOriginId
        );

        // pick second winner (50% cudl)
        winner2 = players[currentRound][
            randomNumber(block.number - 1, players[currentRound].length)
        ];
        require(cudl.transfer(winner2, cudlBalance.mul(37).div(100)));

        // pick third winner (25% cudl)
        winner3 = players[currentRound][
            randomNumber(block.number - 3, players[currentRound].length)
        ];
        require(cudl.transfer(winner3, cudlBalance.mul(19).div(100)));

        // pick fourth winner (25% cudl)
        winner4 = players[currentRound][
            randomNumber(block.number - 4, players[currentRound].length)
        ];
        require(cudl.transfer(winner4, cudlBalance.mul(19).div(100)));

        //burn the leftover (25%)
        cudl.burn(cudl.balanceOf(address(this)));

        emit LotteryEnded(
            currentRound,
            currentPet,
            cudlBalance,
            winner1,
            winner2,
            winner3,
            winner4
        );
    }

    /* generates a number from 0 to 2^n based on the last n blocks */
    function randomNumber(uint256 seed, uint256 max)
        public
        view
        returns (uint256 _randomNumber)
    {
        uint256 n = 0;
        for (uint256 i = 0; i < randomBlockSize; i++) {
            if (
                uint256(
                    keccak256(
                        abi.encodePacked(blockhash(block.number - i - 1), seed)
                    )
                ) %
                    2 ==
                0
            ) n += 2**i;
        }
        return n % max;
    }
}

