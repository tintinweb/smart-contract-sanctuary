// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./ERC20.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

contract StakingPool is ERC20 {
    using SafeMath for uint256;
    uint256 private constant BASE = 10;
    uint256 private constant EXPONENTIATION = 18;
    uint256 private constant MIN_STAKE_BALANCE = BASE ** EXPONENTIATION;

    enum StakeType {
        Block,
        SixMonth,
        OneYear,
        Flexiable
    }
    struct Stake {
        uint256 amount;
        uint blockNumber;
        uint timestamp;
    }

    struct UnStake {
        uint256 amount;
        uint timestamp;
    }

    address private _owner;
    uint256 private _totalStaked;
    uint256 private _lockedRewards;
    uint256 private _feePool;
    uint256 private _lastStakingTime;
    uint256 private _lastUnStakingTime;

    mapping(address => mapping(StakeType => Stake)) private _stakers;
    mapping(address => mapping(StakeType => UnStake)) private _unstakers;

    event Withdrawed(address indexed account, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _owner = msg.sender;
    }

    modifier onlyPositive(uint256 amount) {
        require(amount > 0, "Amount must be greater than zero");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function lockedRewards() public view returns (uint256) {
        return _lockedRewards;
    }
    
    function feePool() public view returns (uint256) {
        return _feePool;
    }

    function lastStakingTime() public view returns (uint256) {
        return _lastStakingTime;
    }

    function lastUnStakingTime() public view returns (uint256) {
        return _lastUnStakingTime;
    }

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function setLockerRewards(uint256 lockedRewards_) public onlyOwner {
        _lockedRewards = lockedRewards_;
    }

    function setFeePool(uint256 feelPool_) public onlyOwner {
        _feePool = feelPool_;
    }

    function _beforeTokenTransfer(uint256 amount) private pure {
        require(amount * BASE ** EXPONENTIATION >= MIN_STAKE_BALANCE, "Minimal stake balance should be more or equal to 1 token");
    }

    function stake(uint amount, StakeType stakeType) public returns (bool) {
        _stake(amount, stakeType);
        return true;
    }

    function _stake(uint amount, StakeType stakeType) onlyPositive(amount) private {
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        _beforeTokenTransfer(amount);
        Stake memory staker = _stakers[msg.sender][stakeType];
        /**
            this staker has already stake;
            tinh lai cho khoang thoi gian da dc stake, roi cong vao lan stake moi, bat dau thoi gian stake moi
         */
        if(staker.timestamp > 0) {
            if(stakeType == StakeType.Block) {

            }
            if(stakeType == StakeType.SixMonth) {
                
            }
            if(stakeType == StakeType.OneYear) {
                
            }
            if(stakeType == StakeType.Flexiable) {
                
            }
        } else {
            _stakers[msg.sender][stakeType] = Stake({ 
                amount: amount,
                blockNumber: block.number,
                timestamp: block.timestamp
            });
        }
        _mint(msg.sender, amount);
        _totalStaked = _totalStaked.add(amount);
        _lastStakingTime = block.timestamp;
    }

    function getBalanceStaked(address account, StakeType stakeType) public view returns (uint256) {
        return _stakers[account][stakeType].amount;
    }

    function unstake(uint amount, StakeType stakeType) public returns (bool) {
        _unstake(amount, stakeType);
        return true;
    }

    function _unstake(uint amount, StakeType stakeType) onlyPositive(amount) private {
        Stake memory staker = _stakers[msg.sender][stakeType];
        require(amount <= staker.amount, "Amount exceeds balance");

        _stakers[msg.sender][stakeType] = Stake({ 
            amount: staker.amount.sub(amount),
            blockNumber: block.number,
            timestamp: block.timestamp
        });
        _totalStaked.sub(amount);
        _unstakers[msg.sender][stakeType] = UnStake({amount: amount, timestamp: block.timestamp});
        _burn(msg.sender, amount);
        _lastUnStakingTime = block.timestamp;
    }

    function _calculateUnstake() private {

    }

    function withdraw() public {

        uint256 totalAmount;

        Stake storage stakeBlock = _stakers[msg.sender][StakeType.Block];
        if(stakeBlock.amount > 0) {
            totalAmount = totalAmount.add(stakeBlock.amount);
            stakeBlock.amount = stakeBlock.amount.sub(stakeBlock.amount);
            _unstakers[msg.sender][StakeType.Block] = UnStake({amount: stakeBlock.amount, timestamp: block.timestamp});
        }

        Stake storage stake6m = _stakers[msg.sender][StakeType.SixMonth];
        if(stake6m.amount > 0) {
            totalAmount = totalAmount.add(stake6m.amount);
            stake6m.amount = stake6m.amount.sub(stake6m.amount);
            _unstakers[msg.sender][StakeType.SixMonth] = UnStake({amount: stake6m.amount, timestamp: block.timestamp});
        }

        Stake storage stake1y = _stakers[msg.sender][StakeType.OneYear];
        if(stake1y.amount > 0) {
            totalAmount = totalAmount.add(stake1y.amount);
            stake1y.amount = stake1y.amount.sub(stake1y.amount);
            _unstakers[msg.sender][StakeType.OneYear] = UnStake({amount: stake1y.amount, timestamp: block.timestamp});
        }

        Stake storage stakeFlex = _stakers[msg.sender][StakeType.Flexiable];
        if(stakeFlex.amount > 0) {
            totalAmount = totalAmount.add(stakeFlex.amount);
            stakeFlex.amount = stakeFlex.amount.sub(stakeFlex.amount);
            _unstakers[msg.sender][StakeType.Flexiable] = UnStake({amount: stakeFlex.amount, timestamp: block.timestamp});
        }

        payable(msg.sender).transfer(totalAmount);
        _burn(msg.sender, totalAmount);
        _totalStaked = _totalStaked.sub(totalAmount);
        emit Withdrawed(msg.sender, totalAmount);
    }

}