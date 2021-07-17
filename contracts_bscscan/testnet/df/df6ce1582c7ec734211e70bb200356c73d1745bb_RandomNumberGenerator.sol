/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



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

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}


contract VRFRequestIDBase {

    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}


abstract contract VRFConsumerBase is VRFRequestIDBase {


    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;


    function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _seed
    ) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal immutable LINK;
    address private immutable vrfCoordinator;

    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
        private nonces;


    constructor(address _vrfCoordinator, address _link) {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }


    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}


interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _seed) external;

    /**
     * View latest lotteryId numbers
     */
    function viewLatestLotteryId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint32);
}


interface ICandleGenieLottery {


    function buyTickets(uint256 _lotteryId, uint32[] calldata _ticketNumbers) external payable;

    function claimTickets(
        uint256 _lotteryId,
        uint256[] calldata _ticketIds,
        uint32[] calldata _brackets
    ) external;


    function closeLottery(uint256 _lotteryId) external;


    function drawFinalNumberAndMakeLotteryClaimable(uint256 _lotteryId, bool _autoInjection) external;

    function injectFunds(uint256 _lotteryId, uint256 _amount) external payable;

    function startLottery(
        uint256 _endTime,
        uint256 _priceTicketInCake,
        uint256 _discountDivisor,
        uint256[6] calldata _rewardsBreakdown,
        uint256 _treasuryFee
    ) external;

    function viewCurrentLotteryId() external returns (uint256);
}

// File: contracts/RandomNumberGenerator.sol

pragma solidity ^0.8.4;

contract RandomNumberGenerator is VRFConsumerBase, IRandomNumberGenerator, Ownable {
    address public candleGenieLottery;
    bytes32 public keyHash;
    bytes32 public latestRequestId;
    uint32 public randomResult;
    uint256 public fee;
    uint256 public latestLotteryId;


    constructor(address _vrfCoordinator, address _linkToken) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        //
    }


    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }


    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }


    function setLotteryAddress(address _candleGenieLottery) external onlyOwner {
        candleGenieLottery = _candleGenieLottery;
    }

    function getRandomNumber(uint256 _seed) external override {
        require(msg.sender == candleGenieLottery, "Only CandleGenieLottery");
        require(keyHash != bytes32(0), "Must have valid key hash");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK tokens");

        latestRequestId = requestRandomness(keyHash, fee, _seed);
    }


    function viewLatestLotteryId() external view override returns (uint256) {
        return latestLotteryId;
    }


    function viewRandomResult() external view override returns (uint32) {
        return randomResult;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(latestRequestId == requestId, "Wrong requestId");
        randomResult = uint32(1000000 + (randomness % 1000000));
        latestLotteryId = ICandleGenieLottery(candleGenieLottery).viewCurrentLotteryId();
    }
}