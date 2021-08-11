pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Farm is Context, Ownable {

    using SafeMath for uint;

    uint256 public roi;
    uint256 private percentage;
    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public totalBlocks;
    bool active;

    IERC20 public LPtoken;
    IERC20 public STBU;

    mapping (address => uint256) public balance;

    struct stakeHolder {
        uint256 _roi;
        uint256 share;
        uint256 calcBlock;
        uint256 availableButNotClaimed;
        uint256 totalClaimed;
    }

    uint256 public defaultStakePerBlock;

    mapping(address => stakeHolder) public holders;

    uint256 public rewardAllocation;

    event LogClaim(address, uint256);

    constructor(address _LP, address _STBU) public {
        LPtoken = IERC20(_LP);
        STBU = IERC20(_STBU);
        roi = 10**8;
        percentage = 10**8;
        uint256 stake = 10**18;
        defaultStakePerBlock = stake.mul(220).div(100);
        totalBlocks = 2296215;
    }

    /**
     * @dev Throws if contract is not active.
     */
    modifier isActive() {
        require(active, "Farm: is not active");
        require(endBlock >= block.number, "Farm: is closed");
        _;
    }

    /**
     * @dev Activating the staking with start block.
     * Can only be called by the current owner.
     */
    function ativate() public onlyOwner returns (bool){
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
    function stakeholderShare(address hodler) public view returns (uint256) {
        uint256 hBalance = balance[hodler];
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
        if (balance[from] > 0) {
            uint _staked = _calculateStaked(from);
            holders[from].availableButNotClaimed = _staked.add(holders[from].availableButNotClaimed);
            rewardAllocation = rewardAllocation.sub(holders[from].availableButNotClaimed);
        }
        require(LPtoken.transferFrom(from, to, _amount));
        balance[from] = balance[from].add(_amount);
        _calculateHolder(from, roi);
    }

    /**
     * @dev Claim STBU reward.
     * Can only be called when contract is active.
     */
    function claim () public isActive {
        address _to = msg.sender;
        _claim(_to);
        _calculateHolder(_to, roi);
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
        _calculateHolder(_to, roi);

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
        _calculateHolder(_to, roi);
    }

    /**
     * @dev Calcultae share and roi for the holder
     */
    function _calculateHolder(address holder, uint256 _roi) internal {
        stakeHolder memory sH = holders[holder];
        sH._roi = _roi;
        sH.share = stakeholderShare(holder);
        sH.calcBlock = block.number;
        holders[holder] = sH;
    }

    /**
     * @dev Send available reward to the holder
     */
    function _claim(address _to) internal {
        uint _staked = _calculateStaked(_to);
        uint256 total = _staked.add(holders[_to].availableButNotClaimed);
        holders[_to].availableButNotClaimed = 0;
        holders[_to].totalClaimed = holders[_to].totalClaimed.add(total);
        rewardAllocation = rewardAllocation.sub(total);
        require(STBU.transfer(_to, total));
        emit LogClaim(_to, _staked);
    }

    /**
     * @dev Calculate available reward for the holder
     */
    function _calculateStaked(address holder) internal view returns(uint256){
        stakeHolder memory st = holders[holder];
        uint256 currentBlock = block.number;
        uint256 amountBlocks = currentBlock.sub(st.calcBlock);
        if(currentBlock >= endBlock) {
            amountBlocks = endBlock.sub(st.calcBlock);
        }
        uint256 fullAmount = rewardAllocation.div(totalBlocks).mul(amountBlocks);
        uint256 _stakeAmount = fullAmount.mul(st.share).div(percentage);
        return _stakeAmount;
    }


    /**
     * @dev get base staking data
     */
    function getStakerData(address _player) public view returns(address, uint256, uint256, uint256) {
        uint256 staked = _calculateStaked(_player);
        stakeHolder memory st = holders[_player];
        return (_player, staked.add(st.availableButNotClaimed), st._roi, stakeholderShare(_player));
    }


    function emergencyWithdraw() public {
        address user = msg.sender;
        uint _balance = balance[user];
        balance[user] = 0;
        require(LPtoken.transfer(user, _balance), "LP: unable to transfer coins");
        _calculateHolder(user, roi);
    }

}