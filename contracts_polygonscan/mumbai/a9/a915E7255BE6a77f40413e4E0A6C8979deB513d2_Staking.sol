pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Staking is Context, Ownable {

    using SafeMath for uint;

    address manager;
    uint256 public roi;
    address public stakingPool;
    uint256 private percentage;
    uint256 public startBlock;
    bool active;
    uint256 public period;

    IERC20 LPtoken;
    IERC20 RPG;

    mapping (address => uint256) public balance;

    struct stakeHolder {
        uint256 _roi;
        uint256 share;
        uint256 calcBlock;
        uint256 _updateTime;
    }

    uint256 private defaultStakePerBlock;

    mapping(address => stakeHolder) public holders;
    mapping(uint256 => address) private holdersById;
    mapping(uint8 => uint256) public tiers;

    event LogUserRank(address, uint256, uint256);
    event LogClaim(address, uint256);

    constructor(address _LP, address _stakingPool, address _manager, address _RPG) public {
        LPtoken = IERC20(_LP);
        RPG = IERC20(_RPG);
        stakingPool = _stakingPool;
        roi = 100000000;
        percentage = 1e8;
        defaultStakePerBlock = 1e8;
        period = 604800;
        _setManager(_manager);
        tiers[1] = 200000000;
        tiers[2] = 150000000;
        tiers[3] = 125000000;
        tiers[4] = 100000000;
    }

    /**
     * @dev Throws if contract is not active.
     */
    modifier isActive() {
        require(active, "Staking: staking is not active");
        _;
    }

    /**
     * @dev Throws if caller is not manager.
     */
    modifier onlyManager() {
        require(msg.sender == manager, "Staking: onlyManager");
        _;
    }

    /**
     * @dev Activating the staking with start block.
     * Can only be called by the current owner.
     */
    function ativate() public onlyOwner returns (bool){
        startBlock = block.number;
        active = true;
        return true;
    }

    /**
     * @dev Deactivating the staking.
     * Can only be called by the current owner.
     */
    function deactivate() public onlyOwner returns (bool) {
        active = false;
        return true;
    }

    /**
     * @dev Change the manager address.
     */
    function _setManager(address _manager) internal {
        manager = _manager;
    }

    /**
     * @dev Change the manager address.
     * Can only be called by the current owner.
     */
    function changeManager(address _manager) public onlyOwner {
        manager = _manager;
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
    function depositLPTokens (uint256 _amount) external payable isActive {
        address from = msg.sender;
        address to = address(this);
        // require(holdersById[id] == from || holdersById[id] == address(0), "Holder is not match");
        // if (holdersById[id] == address(0)) {
        //     holdersById[id] = from;
        // }
        if (balance[from] > 0) {
            _claim(msg.sender);
        }
        require(LPtoken.transferFrom(from, to, _amount));
        balance[from] = balance[from].add(_amount);
        _calculateHolder(from, roi);
    }

    /**
     * @dev Claim RPG reward.
     * Can only be called when contract is active.
     */
    function claim (address payable _to) public payable isActive {
        _to = msg.sender;
        _claim(_to);
        _calculateHolder(_to, roi);
    }

    /**
     * @dev Claim RPG reward and Unstake LP tokens.
     * Can only be called when contract is active.
     */
    function claimAndUnstake (address payable _to) public payable isActive {
        _to = msg.sender;
        uint _balance = balance[_to];
        _claim(_to);
        balance[_to] = 0;
        require(LPtoken.transfer(_to, _balance), "LP: unable to transfer coins");
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
        sH._updateTime = now;
        holders[holder] = sH;
    }

    /**
     * @dev Send available reward to the holder
     */
    function _claim(address _to) internal {
        uint _staked = _calculateStaked(_to);
        require(RPG.transferFrom(address(stakingPool), _to, _staked));
        emit LogClaim(_to, _staked);
    }

    /**
     * @dev Calculate available reward for the holder
     */
    function _calculateStaked(address holder) internal view returns(uint256){
        stakeHolder memory st = holders[holder];
        uint256 currentBlock = block.number;
        uint256 amountBlocks = currentBlock.sub(st.calcBlock);
        uint256 fullAmount = defaultStakePerBlock.mul(amountBlocks);
        uint256 _stakeAmount = fullAmount.mul(st.share).div(percentage).mul(st._roi).div(percentage);
        return _stakeAmount;
    }

    /**
     * @dev Scheduled function to process calim and ranking update
     * Can be called only from the manager account
     */
    function processRankingUpdate(address[] memory _players, uint8[] memory _rank)
    public onlyManager {
        require(_players.length == _rank.length);
        uint256 length = _players.length;
        for (uint256 i=0; i<length; i++) {
            address h = _players[i];
            uint256 r = tiers[_rank[i]];
            if (r < 1e8) {
                r = 1e8;
            }
            if(holders[h].share > 0 &&
            r < 2e8 &&
                holders[h]._updateTime.add(period) <= now) {
                uint256 _staked = _calculateStaked(h);
                require(RPG.transferFrom(address(stakingPool), h, _staked));
                holders[h]._roi = r;
                holders[h]._updateTime = now;
                emit LogUserRank(_players[i], r, holders[_players[i]].share);
            }
        }
    }

    /**
     * @dev get base staking data
     */
    function getStakerData(address _player) public view returns(address, uint256, uint256, uint256) {
        uint256 staked = _calculateStaked(_player);
        stakeHolder memory st = holders[_player];
        return (_player, staked, st._roi, st.share);
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function depos() public payable returns(bool) {
        return true;
    }

    function sendTo(address payable _to) public onlyOwner payable returns(bool) {
        _to.transfer(address(this).balance);
    }

}