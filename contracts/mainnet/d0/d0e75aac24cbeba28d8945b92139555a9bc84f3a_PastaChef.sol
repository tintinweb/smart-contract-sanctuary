pragma solidity ^0.7.0;

import { SafeMath } from "./SafeMath.sol";

interface TokenInterface {
    function transfer(address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

interface UniswapV2Pair {
    function sync() external;
}

contract PastaChef {
    using SafeMath for uint256;

    /// @notice Contract name
    string public constant name = "Pasta Chef v1";

    /// @notice Contract owner (Timelock contract)
    address public immutable owner;

    /// @notice Reward starting block
    uint256 public immutable startBlock;

    /// @notice Reward ending block
    uint256 public endBlock;

    /// @notice Last block in which pasta rewards have been distributed
    uint256 public lastUpdatedBlock;

    /// @notice Pasta reward per block
    uint256 public pastaPerBlock;

    /// @notice ETH/PASTA v2 Uniswap pool
    UniswapV2Pair public constant pool = UniswapV2Pair(0xE92346d9369Fe03b735Ed9bDeB6bdC2591b8227E);

    /// @notice PASTA v2 token
    TokenInterface public constant pasta = TokenInterface(0xE54f9E6Ab80ebc28515aF8b8233c1aeE6506a15E);

    event Claimed(address indexed claimer, uint256 amount);
    event UpdateRewardRate(uint256 oldRate, uint256 newRate);
    event UpdateEndBlock(uint256 oldEnd, uint256 newEnd);

    constructor(address _timelock, uint256 _startBlock, uint256 _endBlock, uint256 _pastaPerBlock) {
        require(_timelock != address(0x0), "PastaChef::invalid-address");
        require(_startBlock >= block.number, "PastaChef::invalid-start-block");
        require(_endBlock >= block.number && _endBlock > _startBlock, "PastaChef::invalid-end-block");
        require(_pastaPerBlock > 0, "PastaChef::invalid-rewards");

        owner = _timelock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        lastUpdatedBlock = _startBlock;
        pastaPerBlock = _pastaPerBlock;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "PastaChef::unauthorized");
        _;
    }

    function pendingRewards() public view returns (uint256) {
        if (block.number <= startBlock || lastUpdatedBlock > endBlock) return 0;

        uint256 blockNumber = block.number;
        if (blockNumber > endBlock) {
            blockNumber = endBlock;
        }
        return blockNumber.sub(lastUpdatedBlock).mul(pastaPerBlock);
    }

    function claimForAll() public {
        uint256 rewards = pendingRewards();
        require(rewards > 0, "PastaChef::already-claimed");

        uint256 balance = pasta.balanceOf(address(this));
        require(balance >= rewards, "PastaChef::insufficient-pasta");

        require(pasta.transfer(address(pool), rewards), "PastaChef::failed-to-distribute");
        pool.sync();

        lastUpdatedBlock = block.number;

        emit Claimed(msg.sender, rewards);
    }

    function updateRewardRate(uint256 _pastaPerBlock) external onlyOwner {
        require(_pastaPerBlock > 0, "PastaChef::invalid-rewards");

        claimForAll();

        emit UpdateRewardRate(pastaPerBlock, _pastaPerBlock);

        pastaPerBlock = _pastaPerBlock;
    }

    function updateEndBlock(uint256 _endBlock) external onlyOwner {
        require(_endBlock >= block.number && _endBlock > startBlock, "PastaChef::invalid-end-block");
        require(endBlock > block.number, "PastaChef::reward-period-over");

        emit UpdateEndBlock(endBlock, _endBlock);

        endBlock = _endBlock;
    }

    function sweep(address to) external onlyOwner {
        require(block.number > endBlock, "PastaChef::reward-period-not-over");
        uint256 balance = pasta.balanceOf(address(this));

        require(pasta.transfer(to, balance));
    }
}