pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

import "../Ownable.sol";
import "./ERC1155Minter.sol";
import "../IERC20.sol";
import "../LPTokenWrapper.sol";


contract LPGenesisPoolGame is LPTokenWrapper, Ownable {
    uint256 public constant MAX_STAKE = 2020000000000000000;
    ERC1155Minter public gameMinter;

    uint256 public gameStartTime;
    uint256 public rewardNeeded;
    uint256 public width;
    string public url;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public points;

    event GameStarted(uint256 gameStartTime, uint256 rewardNeeded);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Created(address indexed user, uint256 indexed id, uint256 x, uint256 y);

    modifier updateReward(address account) {
        if (account != address(0)) {
            points[account] = earned(account);
            lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    constructor(ERC1155Minter _gameMinter, IERC20 _erc20Address) public LPTokenWrapper(_erc20Address) {
        gameMinter = _gameMinter;
    }

    function start(uint256 _gameStartTime, uint256 _amount, uint256 _imageWidth, string memory _url) public onlyOwner {
        require(gameStartTime == 0,  "Already started");
        require(block.timestamp <= _gameStartTime, "Only future time to start");

        gameStartTime = _gameStartTime;
        rewardNeeded = _amount;
        width =_imageWidth;
        url = _url;
        emit GameStarted(_gameStartTime, _amount);
    }

    function earned(address account) public view returns (uint256) {
        uint256 blockTime = block.timestamp;
        return
            points[account].add(
                (blockTime.sub(lastUpdateTime[account]).mul(1e18).div(86400).mul(
                    (balanceOf(account).mul(10000)).div(1e18)
                //1 point equals 2.02 LP tokens per day
                )).div(20200)
            );
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) {
        require(gameStartTime != 0,  "Not started yet");
        require(amount.add(balanceOf(msg.sender)) <= MAX_STAKE, "Cannot stake more than 2.02 UNI-V2 LP");

        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");

        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function redeem(uint256 _xPoint, uint256 _yPoint) public updateReward(msg.sender) {
        require(gameStartTime != 0,  "Not started yet");
        require(points[msg.sender] >= rewardNeeded, "Not enough points to play");

        points[msg.sender] = points[msg.sender].sub(rewardNeeded);
        uint256 _id = _generateId(_xPoint, _yPoint, width);
        gameMinter.create(msg.sender, 1, 1, _id, uint64(_xPoint), uint64(_yPoint), "0x");
        emit Created(msg.sender, _id, _xPoint, _yPoint);
    }

    function _generateId(uint256 _xPoint, uint256 _yPoint, uint256 _width) internal view returns(uint256) {
        uint256 id = _width * _yPoint + _xPoint;
        require(gameMinter.creators(id) == address(0), "Id already used");
        return id;
    }
}