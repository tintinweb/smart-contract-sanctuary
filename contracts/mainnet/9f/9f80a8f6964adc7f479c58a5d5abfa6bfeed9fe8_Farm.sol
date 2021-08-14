pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Farm is Ownable {

    using SafeMath for uint;

    IERC20 public STBU;
    IERC20 public LPtoken;

    struct stakeHolder {
        uint256 calcBlock;
        uint256 totalClaimed;
    }

    bool public active;
    uint256 public roi;
    uint256 public endBlock;
    uint256 public startBlock;
    uint256 public totalBlocks;
    uint256 private percentage;
    uint256 public rewardAllocation;
    uint256 public defaultStakePerBlock;

    mapping (address => uint256) public balance;
    mapping(address => stakeHolder) public holders;

    event LogClaim(address, uint256);

    constructor(address _LP, address _STBU) public {
        LPtoken = IERC20(_LP);
        STBU = IERC20(_STBU);
        roi = 10**18;
        percentage = 10**18;
        uint256 stake = 10**18;
        defaultStakePerBlock = stake.mul(220).div(100);
        totalBlocks = 2296215;
    }

    /**
     * @dev Throws if contract is not active.
     */
    modifier isActive() {
        require(active, "Farm: is not active");
        _;
    }

    /**
     * @dev Activating the staking with start block.
     * Can only be called by the current owner.
     */
    function activate() public onlyOwner returns (bool){
        startBlock = block.number;
        endBlock = startBlock.add(totalBlocks);
        rewardAllocation = defaultStakePerBlock.mul(totalBlocks);
        active = true;
        return true;
    }

    /**
     * @dev Deactivating the staking.
     * Can only be called by the current owner.
     */
    function deactivate() public onlyOwner returns (bool) {
        active = false;
        endBlock = block.number;
        require(STBU.transfer(owner(), STBU.balanceOf(address(this))), "Deactivation: transfer failure");
        return true;
    }

    /**
     * @dev Pause/unpause the staking.
     * Can only be called by the current owner.
     */
    function pause(bool _value) public onlyOwner returns (bool) {
        active = _value;
        return true;
    }

    /**
     * @dev get current stake per block.
     */
    function getStakePerBlock() public view returns (uint256) {
        return rewardAllocation.div(totalBlocks);
    }

    /**
     * @dev Returns the share of the holder.
     */
    function stakeholderShare(address user) public view returns (uint256) {
        uint256 hBalance = balance[user];
        uint256 supply = LPtoken.balanceOf(address(this));
        if (supply > 0) {
            return hBalance.mul(percentage).div(supply);
        }
        return 0;
    }

    /**
     * @dev Deposits the LP tokens.
     * Can only be called when contract is active.
     */
    function depositLPTokens (uint256 _amount) public isActive {
        address from = msg.sender;
        address to = address(this);
        require(block.number >= holders[from].calcBlock, "Deposit: unable to calculate block");
        require(endBlock > block.number, "Farm: is not active");
        if (balance[from] > 0) {
            _claim(from);
        }
        require(LPtoken.transferFrom(from, to, _amount), "LP: unable to transfer coins");
        balance[from] = balance[from].add(_amount);
        _calculateHolder(from);
    }

    /**
     * @dev Claim STBU reward.
     * Can only be called when contract is active.
     */
    function claim () public isActive {
        address _to = msg.sender;
        _claim(_to);
        _calculateHolder(_to);
    }

    /**
     * @dev Claim STBU reward and Unstake LP tokens.
     * Can only be called when contract is active.
     */
    function claimAndUnstake () public isActive {
        address _to = msg.sender;
        uint _balance = balance[_to];
        _claim(_to);
        balance[_to] = 0;
        require(LPtoken.transfer(_to, _balance), "LP: unable to transfer coins");
        _calculateHolder(_to);

    }

    /**
     * @dev Unstake LP tokens.
     * Can only be called when contract is active.
     */
    function unstake(uint256 _amount) public isActive {
        address _to = msg.sender;
        uint _balance = balance[_to];
        require(_balance >= _amount, "LP: wrong amount");
        _claim(_to);
        balance[_to] = _balance.sub(_amount);
        require(LPtoken.transfer(_to, _amount), "LP: unable to transfer coins");
        _calculateHolder(_to);
    }

    /**
     * @dev Calcultae share and roi for the holder
     */
    function _calculateHolder(address holder) internal {
        stakeHolder memory sH = holders[holder];
        sH.calcBlock = block.number;
        holders[holder] = sH;
    }

    /**
     * @dev Send available reward to the holder
     */
    function _claim(address _to) internal {
        uint _staked = _calculateStaked(_to);
        holders[_to].totalClaimed = holders[_to].totalClaimed.add(_staked);
        rewardAllocation = rewardAllocation.sub(_staked);
        require(STBU.transfer(_to, _staked));
        emit LogClaim(_to, _staked);
    }

    /**
     * @dev Calculate available reward for the holder
     */
    function _calculateStaked(address holder) internal view returns(uint256){
        stakeHolder memory st = holders[holder];
        uint256 share = stakeholderShare(holder);
        uint256 currentBlock = block.number;
        uint256 amountBlocks = 0;
        if(currentBlock >= endBlock) {
            amountBlocks = endBlock.sub(st.calcBlock);
        } else {
            amountBlocks = currentBlock.sub(st.calcBlock);
        }

        uint256 fullAmount = rewardAllocation.div(totalBlocks).mul(amountBlocks);
        uint256 _stakeAmount = fullAmount.mul(share).div(percentage);
        return _stakeAmount;
    }

    /**
     * @dev get base staking data
     */
    function getStakerData(address _player) public view returns(address, uint256, uint256, uint256) {
        uint256 staked = _calculateStaked(_player);
        return (_player, staked, roi, stakeholderShare(_player));
    }

    function emergencyWithdraw() public {
        address user = msg.sender;
        uint _balance = balance[user];
        balance[user] = 0;
        require(LPtoken.transfer(user, _balance), "LP: unable to transfer coins");
        _calculateHolder(user);
    }

}