/**
 *   _____________   _______ _____ ___________ ________  ________ _   _ ______
 *  /  __ | ___ \ \ / | ___ |_   _|  _  |  _  |  ___|  \/  |  _  | \ | |___  /
 *  | /  \| |_/ /\ V /| |_/ / | | | | | | | | | |__ |      | | | |  \| |  / /
 *  | |   |    /  \ / |  __/  | | | | | | | | |  __|| |\/| | | | |     | / /
 *  \ \__/| |\ \  | | | |     | | \ \_/ | |/ /| |___| |  | \ \_/ | |\  |/ /___
 *   \____\_| \_| \_/ \_|     \_/  \___/|___/ \____/\_|  |_/\___/\_| \_\_____/
 *
 *
 *  #CryptoDemonz, Wheel of Destiny v2
 *
 * It’s a wheel with 13 segments, each segment defines a value like 2, 3, …, 12, 13, and it has a wild segment which pays 0.
 * The player can place a bet and has to figure out which multiplier or which color will be the result when the wheel is stopped.
 * After betting, the wheel starts spinning and spinning, then it stops.
 * Anyone who successfully figured out the color of the segment where the wheel's stopped gets back their bet amount, 
 * or in case figuring out the winning multiplier they get the prize: bet amount x 12.
 * Otherwise, the player loses their bet.
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./VRFConsumerBase.sol";
import "./IxLLTH.sol";

contract Wheel is Ownable, VRFConsumerBase {
    using SafeMath for uint256;
    using Address for address;

    // instance of xLLTH token
    IxLLTH internal _xLLTH;

    // payout multiplier
    uint256 public payoutMultiplier = 12;

    // maximum value that can be placed as bets
    uint256 public maxBet = 10000 * 10**18;

    // minimum value of the wheel segment multiplier
    uint256 public minMultiplier = 1; // 1 - WILD

    // maximum value of the wheel segment multiplier
    uint256 public maxMultiplier = 13;

    // fee required to fulfill a VRF request
    uint256 public fee;

    // public key against which randomness is generated
    bytes32 public keyHash;

    // the address of the smart contract which verifies if the numbers returned from Chainlink are actually random
    address public VRFCoordinator = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;

    // LINK token's address
    address public LINKToken = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;

    // bets of players
    mapping(address => uint256) public bets;

    // color-bets of players
    mapping(address => uint256) public colorBets;

    // multipliers of players
    mapping(address => uint256) public multipliers;

    // mapping of player's address to requestId
    mapping(address => bytes32) public addressToRequestId;

    // mapping of requestId to the returned random number
    mapping(bytes32 => uint256) public requestIdToRandomNumber;

    // mapping of requestId to player's address
    mapping(bytes32 => address) public requestIdToAddress;

    // mapping to player's spawn holdings (Spawn1 - 1, Spawn2 - 2, Spawn - 3)
    mapping(address => uint256) public addressToSpawn;

    // sending random number for front-end
    event RandomIsArrived(bytes32 requestId, uint256 randomNumber);

    // sending request ID for front-end
    event RequestIdIsCreated(address player, bytes32 requestId);

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    constructor(address xLLTH_) VRFConsumerBase(VRFCoordinator, LINKToken) {
        _xLLTH = IxLLTH(xLLTH_);
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 * 10**18; // 0.0001 LINK
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function requestIdOf(address player) external view returns (bytes32) {
        return addressToRequestId[player];
    }

    function getxLLTHBalance() external view returns (uint256) {
        return _xLLTH.balanceOf(address(this));
    }

    function betOf(address player) external view returns (uint256) {
        require(player != address(0));
        return bets[player];
    }

    function getLINKBalance() external view returns (uint256) {
        return LINK.balanceOf(address(this));
    }

    //-------------------------------------------------------------------------
    // SET FUNCTIONS
    //-------------------------------------------------------------------------

    function setLLTH(address xLLTH_) external onlyOwner {
        _xLLTH = IxLLTH(xLLTH_);
    }

    function setMinMultiplier(uint256 minMultiplier_) external onlyOwner {
        minMultiplier = minMultiplier_;
    }

    function setMaxMultiplier(uint256 maxMultiplier_) external onlyOwner {
        maxMultiplier = maxMultiplier_;
    }

    function setMaxBet(uint256 maxBet_) external onlyOwner {
        maxBet = maxBet_;
    }

    function setPayoutMultiplier(uint256 payoutMultiplier_) external onlyOwner {
        payoutMultiplier = payoutMultiplier_;
    }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    // Transfers prize, resets mappings and array.
    function _closeRound(address player) internal {
        require(player != address(0), "Address cannot be null.");

        if (
            getWinningMultiplier(player) != 1 &&
            multipliers[player] == getWinningMultiplier(player)
        ) {
            uint256 amount;

            if (addressToSpawn[player] == 1) {
                amount = bets[player].mul(payoutMultiplier).mul(1100).div(1000); // Spawn1 - 1.1x
            } else if (addressToSpawn[player] == 2) {
                amount = bets[player].mul(payoutMultiplier).mul(1200).div(1000); // Spawn2 - 1.2x
            } else if (addressToSpawn[player] == 3) {
                amount = bets[player].mul(payoutMultiplier).mul(1300).div(1000); // Spawn3 - 1.3x
            } else {
                amount = bets[player].mul(payoutMultiplier);
            }

            _xLLTH.mintForGames(player, amount);

        } else if (getWinningMultiplier(player) != 1 && getWinningMultiplier(player) % 2 == colorBets[player]) {
            _xLLTH.mintForGames(player, bets[player]);
        }
    }

    //-------------------------------------------------------------------------
    // EXTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    // Called by front-end when placing bet. It saves player's data and tranfers their bet to this contract's address.
    function placeBet(
        uint256 bet,
        uint256 multiplier,
        uint256 color,
        uint256 spawn
    ) external {
        require(
            bet <= maxBet,
            "Bet amount must be less than the max bet amount."
        );
        require(multiplier > 1, "Multiplier must be between 1 and 14.");
        require(multiplier < 14, "Multiplier must be between 1 and 14.");
        require(
            _xLLTH.balanceOf(address(msg.sender)) >= bet,
            "Not enough xLLTH token in your wallet."
        );
        require(spawn < 4, "Spawn must be less than 4.");
        require(color < 2, "Color must be 0 or 1."); // 0 - black, 1 - red

        addressToSpawn[msg.sender] = spawn;
        _xLLTH.transferFrom(msg.sender, address(this), bet);

        uint256 amount;
        // fee
        if (spawn == 1) {
            amount = bet.mul(970).div(1000); // Spawn1 - 3%
        } else if (spawn == 2) {
            amount = bet.mul(980).div(1000); // Spawn2 - 2%
        } else if (spawn == 3) {
            amount = bet.mul(990).div(1000); // Spawn3 - 1%
        } else {
            amount = bet.mul(960).div(1000); // Non-holder - 4%
        }

        getRandomNumber(msg.sender);
        bets[msg.sender] = amount;
        colorBets[msg.sender] = color;
        multipliers[msg.sender] = multiplier;
    }

    function withdrawxLLTH(address account) external onlyOwner {
        uint256 balance = _xLLTH.balanceOf(address(this));
        _xLLTH.transfer(account, balance);
    }

    function withdrawLINK(address account) public onlyOwner {
        uint256 balance = LINK.balanceOf(address(this));
        LINK.transfer(account, balance);
    }

    //-------------------------------------------------------------------------
    // RANDOM NUMBER FUNCTIONS
    //-------------------------------------------------------------------------

    function getRandomNumber(address player) internal {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK.");
        bytes32 requestId = requestRandomness(keyHash, fee);
        addressToRequestId[player] = requestId;
        requestIdToAddress[requestId] = player;

        emit RequestIdIsCreated(player, requestId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
       uint256 randomNumber = (randomness %
            (maxMultiplier.add(1) - minMultiplier)) + minMultiplier; // random number between 0 and 14
        requestIdToRandomNumber[requestId] = randomNumber;

        _closeRound(requestIdToAddress[requestId]);

        emit RandomIsArrived(requestId, randomNumber);
    }

    function getWinningMultiplier(address player)
        public
        view
        returns (uint256)
    {
        return requestIdToRandomNumber[addressToRequestId[player]];
    }
}