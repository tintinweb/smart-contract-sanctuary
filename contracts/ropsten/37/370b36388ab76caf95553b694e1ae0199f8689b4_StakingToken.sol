pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title Staking Token (STK)
 * @author Alberto Cuesta Canada
 * @notice Implements a basic ERC20 staking token with incentive distribution.
 */
contract StakingToken is ERC20, Ownable {
    using SafeMath for uint256;

    /**
     * @notice We usually require to know who are all the stakeholders.
     */
    address[] internal stakeholders;

    /**
     * @notice The stakes for each stakeholder.
     */
    mapping(address => uint256) internal stakes;

    mapping (address => uint256) private _lastDividends;

    uint256 _totalSupply = 100000000000;
    uint256 totalDividends = 0;
    uint256 unclaimedDividends = 0;

    modifier updateDividend(address investor) {
        uint256 owing = dividendsOwing(investor);

        if (owing > 0) {
            unclaimedDividends = unclaimedDividends.sub(owing);
            _mint(investor, owing);
            //_updateBalance(investor, balanceOf(investor).add(owing));
            _lastDividends[investor] = totalDividends;
        }
     _;
    }

    function dividendsOwing(address investor) internal returns(uint256) {
        uint256 totalUsersBalance = _totalSupply.sub(balanceOf(owner()));
        uint256 newDividends = totalDividends.sub(_lastDividends[investor]);
        
        if (newDividends == 0 || balanceOf(investor) == 0 || totalUsersBalance == 0) {
            return 0;
        }
        
        uint256 owingPercent = balanceOf(investor).mul(100).div(totalUsersBalance);
        return owingPercent.mul(newDividends).div(100);
    }

    function disburse(uint256 amount) onlyOwner public {
        _burn(owner(), amount);
        
        totalDividends = totalDividends.add(amount);
        unclaimedDividends =  unclaimedDividends.add(amount);
    }

    function claimDividend() public {
        address investor = msg.sender;
        uint256 owing = dividendsOwing(investor);

        if (owing > 0) {
            unclaimedDividends = unclaimedDividends.sub(owing);
            _mint(investor, owing);
            _lastDividends[investor] = totalDividends;
        }
    }

    /**
     * @notice The accumulated rewards for each stakeholder.
     */
    mapping(address => uint256) internal rewards;
    
    constructor(address _owner) ERC20("The Coupons App", "COUPONS")
        public
    { 
        _mint(_owner, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view override returns (uint8) {
        return 0;
    }

    // ---------- STAKES ----------

    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake The size of the stake to be created.
     */
    function createStake(uint256 _stake)
        public
    {
        _burn(msg.sender, _stake);
        if(stakes[msg.sender] == 0) addStakeholder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
    }

    /**
     * @notice A method for a stakeholder to remove a stake.
     * @param _stake The size of the stake to be removed.
     */
    function removeStake(uint256 _stake)
        public
    {
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
        if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        _mint(msg.sender, _stake);
    }

    /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder];
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
        }
        return _totalStakes;
    }

    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder, 
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder The stakeholder to add.
     */
    function addStakeholder(address _stakeholder)
        public
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder)
        public
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }

    // ---------- REWARDS ----------
    
    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param _stakeholder The stakeholder to check rewards for.
     */
    function rewardOf(address _stakeholder) 
        public
        view
        returns(uint256)
    {
        return rewards[_stakeholder];
    }

    /**
     * @notice A method to the aggregated rewards from all stakeholders.
     * @return uint256 The aggregated rewards from all stakeholders.
     */
    function totalRewards()
        public
        view
        returns(uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            _totalRewards = _totalRewards.add(rewards[stakeholders[s]]);
        }
        return _totalRewards;
    }

    /** 
     * @notice A simple method that calculates the rewards for each stakeholder.
     * @param _stakeholder The stakeholder to calculate rewards for.
     */
    function calculateReward(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakes[_stakeholder] / 100;
    }

    /**
     * @notice A method to distribute rewards to all stakeholders.
     */
    function distributeRewards() 
        public
        onlyOwner
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];
            uint256 reward = calculateReward(stakeholder);
            rewards[stakeholder] = rewards[stakeholder].add(reward);
        }
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his rewards.
     */
    function withdrawReward() 
        public
    {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        _mint(msg.sender, reward);
    }
}