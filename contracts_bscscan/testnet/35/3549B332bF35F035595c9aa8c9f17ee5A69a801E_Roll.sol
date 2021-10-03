/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.7;

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

  function transferFrom(address from, address to, uint256 value) external returns(bool success);
}

contract VRFRequestIDBase {
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed, address _requester, uint256 _nonce) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

abstract contract VRFConsumerBase is VRFRequestIDBase {
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  mapping(bytes32 => uint256) private nonces;

  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

contract Roll is VRFConsumerBase {
    address public manager;

    bool public bettingEnabled;

    uint public rollUnderLowerLimit;
    uint public rollUnderUpperLimit;
    uint public taxFree;
    uint public minimumBet;
    uint public maximumBet;
    uint public totalRolls;
    uint public totalBet;
    uint public totalWon;

    bytes32 internal keyHash;
    uint256 internal fee;

    struct Rolls {
        uint timestamp;
        address wallet;
        uint bet;
        uint chance;
        uint result;
        bool win;
        bool completed;
    }

    mapping(bytes32 => Rolls) private rolls;

    event ShowResult(bytes32 indexed requestId, Rolls roll);

    constructor(bool _bettingEnabled, uint _rollUnderLowerLimit, uint _rollUnderUpperLimit, uint _taxFree, uint _minimumBet, uint _maximumBet, uint _totalRolls, uint _totalBet, uint _totalWon) VRFConsumerBase(0xa555fC018435bef5A13C6c6870a9d4C11DEC329C, 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06) {
        manager = msg.sender;
        bettingEnabled = _bettingEnabled;
        rollUnderLowerLimit = _rollUnderLowerLimit;
        rollUnderUpperLimit = _rollUnderUpperLimit;
        taxFree = _taxFree;
        minimumBet = _minimumBet;
        maximumBet = _maximumBet;
        totalRolls = _totalRolls;
        totalBet = _totalBet;
        totalWon = _totalWon;

        keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
        fee = 0.1 * 10 ** 18;
    }

    function addToPool() public payable restricted {}

    function transferOut(uint amount) public restricted {
        payable(manager).transfer(amount);
    }
    
    function enter(uint rollUnder) public payable min max enabled {
        require(rollUnder > rollUnderLowerLimit && rollUnder < rollUnderUpperLimit, "Chance of winning % out of range.");
        totalRolls++;
        totalBet = totalBet+msg.value;
        getRandomNumber(rollUnder);
    }

    function enableBetting() public restricted {
        bettingEnabled = true;
    }

    function disableBetting() public restricted {
        bettingEnabled = false;
    }

    function setRollUnderLowerLimit(uint value) public restricted {
        rollUnderLowerLimit = value;
    }

    function setRollUnderUpperLimit(uint value) public restricted {
        rollUnderUpperLimit = value;
    }

    function setMinimumBetValue(uint value) public restricted {
        minimumBet = value;
    }

    function setMaximumBetValue(uint value) public restricted {
        maximumBet = value;
    }

    function payout(uint rollUnder) private {
        uint prize = calculateWin(rollUnder);
        uint profit = prize-msg.value;
        totalWon = totalWon+profit;
        payable(msg.sender).transfer(prize);
    }

    function calculateWin(uint rollUnder) private view returns (uint) {
        return (msg.value+(msg.value*(100-rollUnder)/rollUnder))*taxFree/100;
    }

    function getRandomNumber(uint rollUnder) private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 reqId = requestRandomness(keyHash, fee);
        rolls[reqId] = Rolls(block.timestamp, msg.sender, msg.value, rollUnder, 0, false, false);
        return reqId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        Rolls memory roll = rolls[requestId];
        uint rollResult = (randomness % 101) + 1;
        bool win = rollResult < roll.chance;  
        roll.result = rollResult;
        roll.win = win;
        roll.completed = true;      
        if (win) payout(roll.chance);
        emit ShowResult(requestId, roll);
    }

    function getResult(bytes32 requestId) public view returns (Rolls memory) {
        return rolls[requestId];
    }
    
    modifier restricted() {
        require(msg.sender == manager, "Permission denied.");
        _;
    }

    modifier min() {
        require(msg.value >= minimumBet, "Bet value must be equal or greater than minimum limit.");
        _;
    }

    modifier max() {
        require(msg.value <= maximumBet, "Bet value must be equal or less than maximum limit.");
        _;
    }

    modifier enabled() {
        require(bettingEnabled == true, "Betting has been disabled.");
        _;
    }
}