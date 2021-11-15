// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./VRFConsumerBase.sol";
import "./utils/Utils.sol";
import "./utils/SafeMath8.sol";

contract ThaiLottery is VRFConsumerBase, Utils {
    using SafeMath8 for uint8;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;
    bytes32 public requestIdResult;

    uint256 public issueIndex = 0;
    address public adminAddress;

    uint8 ticketPrice = 80;
    // Total amount in THB in this round
    uint256 public ticketCount = 0;
    uint256 public totalAmount = 0;
    uint256 public totalReward = 0;

    // Time stamp of last transaction
    uint256 public lastTimestamp;

    // max number
    uint8 public maxNumber = 10;
    // max quota
    uint256 maxQuotaOfSameNumber = 50;
    // currentPrizeIndex
    uint8 currentPrizeIndex = 0;

    bool public allPrizeDrawed;
    bool public drawingPhase;
    bool public isSaveLastedState = true; // for first round, no need to save state

    uint8 private totalPrizeIndexs = 9;

    uint8 private indexFirstPrize = 0;
    uint8 private indexSecondPrize = 1;
    uint8 private indexThirdPrize = 2;
    uint8 private indexFourthPrize = 3;
    uint8 private indexFifthPrize = 4;
    uint8 private indexThreeDigitPrefix = 5;
    uint8 private indexThreeDigitSuffix = 6;
    uint8 private indexTwoDigitSuffix = 7;
    uint8 private indexFirstPrizeNeighbors = 8;

    mapping(uint8 => bool) public isDrawed;

    uint8 private sizeFirstPrize = 1;
    uint8 private sizeSecondPrize = 5;
    uint8 private sizeThirdPrize = 10;
    uint8 private sizeFourthPrize = 50;
    uint8 private sizeFifthPrize = 100;
    uint8 private sizeThreeDigitPrefix = 2;
    uint8 private sizeThreeDigitSuffix = 2;
    uint8 private sizeTwoDigitSuffix = 1;
    uint8 private sizeFirstPrizeNeighbors = 2;

    // prize => item => numbers
    mapping(uint8 => mapping(uint8 => uint8[6])) public winningNumbers;

    // issueIndex => [tokenId]
    mapping(uint256 => uint256[]) public lotteryInfo;
    // issueIndex => number[numbers] => count
    mapping(uint256 => mapping(bytes => uint8)) public historyNumberCount;
    // issueIndex => ticketCount
    mapping(uint256 => uint256) public historyTicketCount;
    // issueIndex => totalAmount
    mapping(uint256 => uint256) public historyTotalAmount;
    // issueIndex => totalReward
    mapping(uint256 => uint256) public historyTotalReward;
    // issueIndex => prize => item => numbers
    mapping(uint256 => mapping(uint8 => mapping(uint8 => uint8[6])))
        public historyWinningNumber;

    // COMMENT THIS FOR PRODUCTION
    // ===================================================
    // constructor()
    //     public
    //     VRFConsumerBase(
    //         0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
    //         0xa36085F69e2889c224210F603D836748e7dC0088 // LINK Token
    //     )
    // {
    //     keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
    //     fee = 0.1 * 10**18; // 0.1 LINK
    //     adminAddress = msg.sender;
    // }
    // ===================================================
    // COMMENT THIS FOR DEVELOPMENT
    // ===================================================
    constructor(
        address _vrfCoordinator,
        address _LINKToken,
        bytes32 _keyHash,
        uint256 _fee
    )
        public
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _LINKToken // LINK Token
        )
    {
        keyHash = _keyHash;
        fee = _fee;
        adminAddress = msg.sender;
    }

    // ===================================================

    function reset() external onlyAdmin {
        // user can buy on this phase
        require(allPrizeDrawed, "Not drawed");
        require(isSaveLastedState, "Save latest winning number to state first");
        winningNumbers[indexFirstPrize][0][0] = 0;
        winningNumbers[indexFirstPrize][0][1] = 0;
        winningNumbers[indexFirstPrize][0][2] = 0;
        winningNumbers[indexFirstPrize][0][3] = 0;
        winningNumbers[indexFirstPrize][0][4] = 0;
        winningNumbers[indexFirstPrize][0][5] = 0;
        ticketCount = 0;
        issueIndex = issueIndex.add(1);
        totalAmount = 0;
        totalReward = 0;

        isDrawed[indexFirstPrize] = false;
        isDrawed[indexSecondPrize] = false;
        isDrawed[indexThirdPrize] = false;
        isDrawed[indexFourthPrize] = false;
        isDrawed[indexFifthPrize] = false;
        isDrawed[indexThreeDigitPrefix] = false;
        isDrawed[indexThreeDigitSuffix] = false;
        isDrawed[indexTwoDigitSuffix] = false;
        isDrawed[indexFirstPrizeNeighbors] = false;
    }

    function enterDrawingPhase() external onlyAdmin {
        // user cannot buy on this phase
        require(
            !allPrizeDrawed && !drawingPhase,
            "Not drawed or not in drawing phase"
        );
        drawingPhase = true;
        lastTimestamp = block.timestamp;
    }

    function afterDrawing(uint256 randomness) private {
        if (currentPrizeIndex == indexFirstPrize) {
            // 0
            // now first prize AND first prize neighbors are beeing process

            // First Prize
            uint8[6] memory firstPrizeNumbers =
                parseWinningNumber(randomness, indexFirstPrize);

            winningNumbers[indexFirstPrize][0] = firstPrizeNumbers;

            // First Prize Neighbors
            winningNumbers[indexFirstPrizeNeighbors][0] = firstPrizeNumbers; // copy the rest value
            winningNumbers[indexFirstPrizeNeighbors][1] = firstPrizeNumbers; // copy the rest value

            // TODO: handle ending with 0 OR 9
            winningNumbers[indexFirstPrizeNeighbors][0][5] = firstPrizeNumbers[
                5
            ]
                .subUint8(1);
            winningNumbers[indexFirstPrizeNeighbors][1][5] = firstPrizeNumbers[
                5
            ]
                .addUint8(1);

            isDrawed[indexFirstPrize] = true;
            isDrawed[indexFirstPrizeNeighbors] = true;
        }

        if (currentPrizeIndex == indexSecondPrize) {
            // 1
            isDrawed[indexSecondPrize] = true;
        }
        if (currentPrizeIndex == indexThirdPrize) {
            // 2
            isDrawed[indexThirdPrize] = true;
        }
        if (currentPrizeIndex == indexFourthPrize) {
            // 3
            isDrawed[indexFourthPrize] = true;
        }
        if (currentPrizeIndex == indexFifthPrize) {
            // 4
            isDrawed[indexFifthPrize] = true;
        }
        if (currentPrizeIndex == indexThreeDigitPrefix) {
            // 5
            uint8[6] memory threeDigitPrefix =
                parseWinningNumber(randomness, indexThreeDigitPrefix);

            winningNumbers[indexThreeDigitPrefix][0][0] = 0;
            winningNumbers[indexThreeDigitPrefix][0][1] = 0;
            winningNumbers[indexThreeDigitPrefix][0][2] = 0;
            winningNumbers[indexThreeDigitPrefix][0][3] = threeDigitPrefix[0];
            winningNumbers[indexThreeDigitPrefix][0][4] = threeDigitPrefix[1];
            winningNumbers[indexThreeDigitPrefix][0][5] = threeDigitPrefix[2];
            winningNumbers[indexThreeDigitPrefix][1][0] = 0;
            winningNumbers[indexThreeDigitPrefix][1][1] = 0;
            winningNumbers[indexThreeDigitPrefix][1][2] = 0;
            winningNumbers[indexThreeDigitPrefix][1][3] = threeDigitPrefix[3];
            winningNumbers[indexThreeDigitPrefix][1][4] = threeDigitPrefix[4];
            winningNumbers[indexThreeDigitPrefix][1][5] = threeDigitPrefix[5];

            isDrawed[indexThreeDigitPrefix] = true;
        }
        if (currentPrizeIndex == indexThreeDigitSuffix) {
            // 6
            uint8[6] memory threeDigitSuffix =
                parseWinningNumber(randomness, indexThreeDigitSuffix);

            winningNumbers[indexThreeDigitPrefix][0][0] = 0;
            winningNumbers[indexThreeDigitPrefix][0][1] = 0;
            winningNumbers[indexThreeDigitPrefix][0][2] = 0;
            winningNumbers[indexThreeDigitPrefix][0][3] = threeDigitSuffix[0];
            winningNumbers[indexThreeDigitPrefix][0][4] = threeDigitSuffix[1];
            winningNumbers[indexThreeDigitPrefix][0][5] = threeDigitSuffix[2];
            winningNumbers[indexThreeDigitPrefix][1][0] = 0;
            winningNumbers[indexThreeDigitPrefix][1][1] = 0;
            winningNumbers[indexThreeDigitPrefix][1][2] = 0;
            winningNumbers[indexThreeDigitPrefix][1][3] = threeDigitSuffix[3];
            winningNumbers[indexThreeDigitPrefix][1][4] = threeDigitSuffix[4];
            winningNumbers[indexThreeDigitPrefix][1][5] = threeDigitSuffix[5];
            isDrawed[indexThreeDigitSuffix] = true;
        }
        if (currentPrizeIndex == indexTwoDigitSuffix) {
            // 7
            uint8[6] memory twoDigitSubfix =
                parseWinningNumber(randomness, indexTwoDigitSuffix);

            winningNumbers[indexTwoDigitSuffix][0][0] = 0;
            winningNumbers[indexTwoDigitSuffix][0][1] = 0;
            winningNumbers[indexTwoDigitSuffix][0][2] = 0;
            winningNumbers[indexTwoDigitSuffix][0][3] = 0;
            winningNumbers[indexTwoDigitSuffix][0][4] = twoDigitSubfix[4];
            winningNumbers[indexTwoDigitSuffix][0][5] = twoDigitSubfix[5];
            isDrawed[indexTwoDigitSuffix] = true;
        }

        allPrizeDrawed =
            isDrawed[indexFirstPrize] &&
            isDrawed[indexSecondPrize] &&
            isDrawed[indexThirdPrize] &&
            isDrawed[indexFourthPrize] &&
            isDrawed[indexFifthPrize] &&
            isDrawed[indexThreeDigitPrefix] &&
            isDrawed[indexThreeDigitSuffix] &&
            isDrawed[indexTwoDigitSuffix] &&
            isDrawed[indexFirstPrizeNeighbors];

        drawingPhase = !allPrizeDrawed;
        isSaveLastedState = false;
        lastTimestamp = block.timestamp;
    }

    function saveWinningNumberToHistory() external onlyAdmin {
        require(!isSaveLastedState, "Already save winning numbers to state");
        if (currentPrizeIndex == indexFirstPrize) {
            // 0
            // first prize
            historyWinningNumber[issueIndex][indexFirstPrize][
                0
            ] = winningNumbers[indexFirstPrize][0];

            // first prize neighbors
            historyWinningNumber[issueIndex][indexFirstPrizeNeighbors][
                0
            ] = winningNumbers[indexFirstPrizeNeighbors][0];

            historyWinningNumber[issueIndex][indexFirstPrizeNeighbors][
                1
            ] = winningNumbers[indexFirstPrizeNeighbors][1];
        }
        if (currentPrizeIndex == indexSecondPrize) {
            // 1
        }
        if (currentPrizeIndex == indexThirdPrize) {
            // 2
        }
        if (currentPrizeIndex == indexFourthPrize) {
            // 3
        }
        if (currentPrizeIndex == indexFifthPrize) {
            // 4
        }
        if (currentPrizeIndex == indexThreeDigitPrefix) {
            // 5
            historyWinningNumber[issueIndex][indexThreeDigitPrefix][
                0
            ] = winningNumbers[indexThreeDigitPrefix][0];

            historyWinningNumber[issueIndex][indexThreeDigitPrefix][
                1
            ] = winningNumbers[indexThreeDigitPrefix][1];
        }
        if (currentPrizeIndex == indexThreeDigitSuffix) {
            // 6
            historyWinningNumber[issueIndex][indexThreeDigitSuffix][
                0
            ] = winningNumbers[indexThreeDigitSuffix][0];

            historyWinningNumber[issueIndex][indexThreeDigitSuffix][
                1
            ] = winningNumbers[indexThreeDigitSuffix][1];
        }
        if (currentPrizeIndex == indexTwoDigitSuffix) {
            // 7
            historyWinningNumber[issueIndex][indexTwoDigitSuffix][
                0
            ] = winningNumbers[indexTwoDigitSuffix][0];
        }
        if (currentPrizeIndex == indexFirstPrizeNeighbors) {
            // 8
            historyWinningNumber[issueIndex][indexFirstPrizeNeighbors][
                0
            ] = winningNumbers[indexFirstPrizeNeighbors][0];

            historyWinningNumber[issueIndex][indexFirstPrizeNeighbors][
                1
            ] = winningNumbers[indexFirstPrizeNeighbors][1];
        }
        isSaveLastedState = true;
    }

    function buy(uint8[6] memory _numbers) external validNumber(_numbers) {
        require(!allPrizeDrawed && !drawingPhase, "Drawn or in drawing phase");
        bytes memory numberBytes = numberToBytes(_numbers);
        require(
            historyNumberCount[issueIndex][numberBytes] < maxQuotaOfSameNumber,
            "This number of ticket is exceeded quota."
        );
        historyNumberCount[issueIndex][numberBytes] = historyNumberCount[
            issueIndex
        ][numberBytes]
            .addUint8(1);
        ticketCount = ticketCount.add(1);
        historyTicketCount[issueIndex] = ticketCount;
        totalAmount = totalAmount.add(ticketPrice);
        historyTotalAmount[issueIndex] = totalAmount;
        lastTimestamp = block.timestamp;
    }

    // --------------------------------------------------

    function drawing(uint8 prizeIndex)
        public
        onlyAdmin
        returns (bytes32 requestId)
    {
        // COMMENT THIS FOR DEVELOPMENT
        // ===================================================
        require(
            LINK.balanceOf(address(this)) > fee,
            "Not enough LINK - fill contract with faucet"
        );
        // ===================================================

        // user cannot buy on this phase
        require(
            !allPrizeDrawed && drawingPhase,
            "Not drawned or in drawing phase"
        );
        require(prizeIndex < totalPrizeIndexs, "Prize index overflow."); // exclude first prize neighbors
        require(!isDrawed[prizeIndex], "This prize has been drawed");
        require(isSaveLastedState, "Save winning numbers to state first");

        currentPrizeIndex = prizeIndex;

        // COMMENT THIS FOR PRODUCTION
        // ===================================================
        // randomResult = uint256(keccak256(abi.encodePacked(lastTimestamp)));
        // afterDrawing(randomResult);
        // return 0;
        // ===================================================

        // COMMENT THIS FOR DEVELOPMENT
        // ===================================================
        return requestRandomness(keyHash, fee, lastTimestamp);
        // ===================================================
    }

    // @dev this function will be called by Oracle at gas limit 500,000 please save the gas as possible!
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        requestIdResult = requestId;
        randomResult = randomness;
        afterDrawing(randomness);
    }

    function withdrawLink() external onlyAdmin {
        require(
            LINK.transfer(msg.sender, LINK.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function parseWinningNumber(uint256 _randomNumber, uint8 prizeIndex)
        internal
        view
        returns (uint8[6] memory)
    {
        uint8[6] memory _winningNumbers;
        if (
            prizeIndex == indexFirstPrize ||
            prizeIndex == indexFirstPrizeNeighbors ||
            prizeIndex == indexThreeDigitPrefix ||
            prizeIndex == indexThreeDigitSuffix ||
            prizeIndex == indexTwoDigitSuffix
        ) {
            uint8 digit;
            assembly {
                digit := div(mod(_randomNumber, 1000000), 100000)
            }
            _winningNumbers[0] = uint8(digit);

            assembly {
                digit := div(mod(_randomNumber, 100000), 10000)
            }
            _winningNumbers[1] = uint8(digit);

            assembly {
                digit := div(mod(_randomNumber, 10000), 1000)
            }
            _winningNumbers[2] = uint8(digit);

            assembly {
                digit := div(mod(_randomNumber, 1000), 100)
            }
            _winningNumbers[3] = uint8(digit);

            assembly {
                digit := div(mod(_randomNumber, 100), 10)
            }
            _winningNumbers[4] = uint8(digit);

            assembly {
                digit := mod(_randomNumber, 10)
            }
            _winningNumbers[5] = uint8(digit);
        }
        return _winningNumbers;
    }

    function getLinkBalance() external view returns (uint256) {
        return LINK.balanceOf(address(this));
    }

    function getPhaseMessage() external view returns (string memory) {
        if (!allPrizeDrawed && !drawingPhase) {
            return "Buying phase, grab the tickets now!";
        }
        if (!allPrizeDrawed && drawingPhase) {
            return
                "Prepare for drawing all prizes, you cannot buy the ticket at this time.";
        }
        if (allPrizeDrawed) {
            return
                "Drawn, congrats with the winners, the tickets will be available soon.";
        }
    }

    function getTicketRemainingOfNumber(uint8[6] memory _numbers)
        external
        view
        returns (uint256)
    {
        bytes memory numberBytes = numberToBytes(_numbers);

        return
            maxQuotaOfSameNumber.sub(
                historyNumberCount[issueIndex][numberBytes]
            );
    }

    function setMaxQuotaOfSameNumber(uint256 _newMax) external onlyAdmin {
        require(_newMax != 0, "Cannot set max quota to zero");
        maxQuotaOfSameNumber = _newMax;
    }

    function setTicketPrice(uint8 _newPrice) external onlyAdmin {
        require(_newPrice != 0, "Cannot set new price to zero");
        ticketPrice = _newPrice;
    }

    // Update admin address by the previous admin.
    function setAdmin(address _adminAddress) external onlyAdmin {
        adminAddress = _adminAddress;
    }

    function checkWonTicket(uint256 _issueIndex, uint8[6] memory _numbers)
        external
        view
        returns (bool)
    {
        return
            isWonFirstPrize(_issueIndex, _numbers) ||
            isWonSecondPrize(_issueIndex, _numbers) ||
            isWonThirdPrize(_issueIndex, _numbers) ||
            isWonFourthPrize(_issueIndex, _numbers) ||
            isWonFifthPrize(_issueIndex, _numbers) ||
            isWonThreeDigitPrefix(_issueIndex, _numbers) ||
            isWonThreeDigitSuffix(_issueIndex, _numbers) ||
            isWonTwoDigitSuffix(_issueIndex, _numbers) ||
            isWonFirstPrizeNeighbors(_issueIndex, _numbers);
    }

    function isWonFirstPrize(uint256 _issueIndex, uint8[6] memory _numbers)
        public
        view
        returns (bool)
    {
        // 0
        return
            _numbers[0] ==
            historyWinningNumber[_issueIndex][indexFirstPrize][0][0] &&
            _numbers[1] ==
            historyWinningNumber[_issueIndex][indexFirstPrize][0][1] &&
            _numbers[2] ==
            historyWinningNumber[_issueIndex][indexFirstPrize][0][2] &&
            _numbers[3] ==
            historyWinningNumber[_issueIndex][indexFirstPrize][0][3] &&
            _numbers[4] ==
            historyWinningNumber[_issueIndex][indexFirstPrize][0][4] &&
            _numbers[5] ==
            historyWinningNumber[_issueIndex][indexFirstPrize][0][5];
    }

    function isWonSecondPrize(uint256 _issueIndex, uint8[6] memory _numbers)
        public
        view
        returns (bool)
    {
        // 1
    }

    function isWonThirdPrize(uint256 _issueIndex, uint8[6] memory _numbers)
        public
        view
        returns (bool)
    {
        // 2
    }

    function isWonFourthPrize(uint256 _issueIndex, uint8[6] memory _numbers)
        public
        view
        returns (bool)
    {
        // 3
    }

    function isWonFifthPrize(uint256 _issueIndex, uint8[6] memory _numbers)
        public
        view
        returns (bool)
    {
        // 4
    }

    function isWonThreeDigitPrefix(
        uint256 _issueIndex,
        uint8[6] memory _numbers
    ) public view returns (bool) {
        // 5
        bool isWon = false;
        for (uint8 index = 0; index < sizeThreeDigitPrefix; index++) {
            if (
                _numbers[0] ==
                historyWinningNumber[_issueIndex][indexThreeDigitPrefix][index][
                    3
                ] &&
                _numbers[1] ==
                historyWinningNumber[_issueIndex][indexThreeDigitPrefix][index][
                    4
                ] &&
                _numbers[2] ==
                historyWinningNumber[_issueIndex][indexThreeDigitPrefix][index][
                    5
                ]
            ) {
                isWon = true;
                break;
            }
        }
        return isWon;
    }

    function isWonThreeDigitSuffix(
        uint256 _issueIndex,
        uint8[6] memory _numbers
    ) public view returns (bool) {
        // 6
        bool isWon = false;
        for (uint8 index = 0; index < sizeThreeDigitSuffix; index++) {
            if (
                _numbers[3] ==
                historyWinningNumber[_issueIndex][indexThreeDigitSuffix][index][
                    3
                ] &&
                _numbers[4] ==
                historyWinningNumber[_issueIndex][indexThreeDigitSuffix][index][
                    4
                ] &&
                _numbers[5] ==
                historyWinningNumber[_issueIndex][indexThreeDigitSuffix][index][
                    5
                ]
            ) {
                isWon = true;
                break;
            }
        }
        return isWon;
    }

    function isWonTwoDigitSuffix(uint256 _issueIndex, uint8[6] memory _numbers)
        public
        view
        returns (bool)
    {
        // 7
        return
            _numbers[4] ==
            historyWinningNumber[_issueIndex][indexTwoDigitSuffix][0][4] &&
            _numbers[5] ==
            historyWinningNumber[_issueIndex][indexTwoDigitSuffix][0][5];
    }

    function isWonFirstPrizeNeighbors(
        uint256 _issueIndex,
        uint8[6] memory _numbers
    ) public view returns (bool) {
        // 8
        bool isWon = false;
        for (uint8 index = 0; index < sizeFirstPrizeNeighbors; index++) {
            if (
                _numbers[0] ==
                historyWinningNumber[_issueIndex][indexFirstPrizeNeighbors][
                    index
                ][0] &&
                _numbers[1] ==
                historyWinningNumber[_issueIndex][indexFirstPrizeNeighbors][
                    index
                ][1] &&
                _numbers[2] ==
                historyWinningNumber[_issueIndex][indexFirstPrizeNeighbors][
                    index
                ][2] &&
                _numbers[3] ==
                historyWinningNumber[_issueIndex][indexFirstPrizeNeighbors][
                    index
                ][3] &&
                _numbers[4] ==
                historyWinningNumber[_issueIndex][indexFirstPrizeNeighbors][
                    index
                ][4] &&
                _numbers[5] ==
                historyWinningNumber[_issueIndex][indexFirstPrizeNeighbors][
                    index
                ][5]
            ) {
                isWon = true;
                break;
            }
        }
        return isWon;
    }

    modifier validNumber(uint8[6] memory _numbers) {
        require(
            _numbers[0] < maxNumber &&
                _numbers[1] < maxNumber &&
                _numbers[2] < maxNumber &&
                _numbers[3] < maxNumber &&
                _numbers[4] < maxNumber &&
                _numbers[5] < maxNumber,
            "Overflow maxNumber"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == adminAddress,
            "Only admin can call this function."
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./vendor/SafeMathChainlink.sol";

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
    using SafeMathChainlink for uint256;

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBase expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomness the VRF output
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual;

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * @dev by the Oracle, and verified by the vrfCoordinator.
     *
     * @dev The _keyHash must already be registered with the VRFCoordinator, and
     * @dev the _fee must exceed the fee specified during registration of the
     * @dev _keyHash.
     *
     * @dev The _seed parameter is vestigial, and is kept only for API
     * @dev compatibility with older versions. It can't *hurt* to mix in some of
     * @dev your own randomness, here, but it's not necessary because the VRF
     * @dev oracle will mix the hash of the block containing your request into the
     * @dev VRF seed it ultimately uses.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of LINK to send with the request
     * @param _seed seed mixed into the input of the VRF.
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _seed
    ) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed =
            makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash].add(1);
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal immutable LINK;
    address private immutable vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    /* keyHash */
    /* nonce */
    mapping(bytes32 => uint256) private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     * @param _link address of LINK token contract
     *
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    constructor(address _vrfCoordinator, address _link) public {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness)
        external
    {
        require(
            msg.sender == vrfCoordinator,
            "Only VRFCoordinator can fulfill"
        );
        fulfillRandomness(requestId, randomness);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library SafeMath8 {
    function mulUint8(uint8 a, uint8 b) internal pure returns (uint8) {
        if (a == 0) {
            return 0;
        }
        uint8 c = a * b;
        assert(c / a == b);
        return c;
    }

    function divUint8(uint8 a, uint8 b) internal pure returns (uint8) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint8 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn’t hold
        return c;
    }

    function subUint8(uint8 a, uint8 b) internal pure returns (uint8) {
        assert(b <= a);
        return a - b;
    }

    function addUint8(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        assert(c >= a);
        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract Utils {
    constructor() public {}

    function numberToBytes(uint8[6] memory _numbers)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(_numbers);
    }

    function bytesToNumber(bytes memory _numbers)
        public
        pure
        returns (uint8[6] memory)
    {
        uint8[6] memory numbers;
        (numbers) = abi.decode(_numbers, (uint8[6]));
        return numbers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

