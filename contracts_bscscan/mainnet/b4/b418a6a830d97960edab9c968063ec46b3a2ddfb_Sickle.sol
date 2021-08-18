/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-22
*/

/**
 *Submitted for verification at Bscscan.com/ on 2021-05-22
*/

// ----------------------------------------------------------------------------
//
// Symbol      : DFF
// Name        : DefiFine
// Total supply: 80,000,000,000,000
// Decimals    : 8
// Website     : defifine.tech
//
// Your gateway into the decentralize financial (Defi) world. 
// Gain first hand experience without risking too much.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/**
 * @title SafeMath
 */
library SafeMath {

    /**
    * Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

interface AltcoinToken {
    function balanceOf(address _owner) external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
}

    contract Sickle {
    
    using SafeMath for uint256;
    address payable owner;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => address) referrals;

    string public constant name = "Sickle";
    string public constant symbol = "Sickle";
    uint public constant decimals = 8;
    
    uint256 public totalSupply = 2e20;
    uint256 public totalDistributed = 2e20;        
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Burn(address indexed burner, uint256 value);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
    constructor () {
        owner = payable(msg.sender);
        // 5% dev fund,
        // 20% presale,
        // 15% promotion, airdrop and contest
        uint256 projectFund = totalSupply.mul(40).div(100);
        distr(owner, projectFund);
    }
    
    function transferOwnership(address payable newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function distr(address _to, uint256 _amount) private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);        
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }

    function balanceOf(address _owner) view public returns (uint256) {
        return balances[_owner];
    }

    // mitigates the BEP20 short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // mitigates the BEP20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }

    function withdraw() onlyOwner public {
        address myAddress = address(this);
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
    
    function withdrawAltcoinTokens(address _tokenContract) onlyOwner public returns (bool) {
        AltcoinToken token = AltcoinToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    //**Staking */

    bool public stakingPaused = true;

    modifier canStake() {
        require(!stakingPaused);
        _;
    }

    function pauseStaking() onlyOwner public {
        stakingPaused = true;
    }

    function resumeStaking() onlyOwner public {
        stakingPaused = false;
    }

    struct Stake {
        uint256 amount;
        uint256 at;
        uint256 term;
    }

    struct Staker {
        bool registered;
        address referer;
        uint256 referrals;
        uint paidAt;
        uint256 totalReward;
        Stake[] stakes;
    }

    uint256 public totalStaked;
    uint256 public totalEarned;
    uint256 public constant STAKINGRETURN = 190;
    uint256 public constant ADAY = 28800;
    mapping(address => Staker) stakers;

    event Staked(address indexed _from, uint256 _value, uint256 _term);
    event Referral(address indexed _user, address indexed _from, uint256 _value);
    event Harvest(address indexed _user, uint256 _value);

    function stake(uint256 _amount, address referer) canStake public returns (bool) {
        require(_amount > 0, 'invalid amount');
        require(_amount <= balances[msg.sender], 'insufficient balance');
        require(totalDistributed.add(_amount.add(_amount.div(10))) <= totalSupply, 'distribution is over');

        if (!stakers[msg.sender].registered) {
            stakers[msg.sender].registered = true;
            stakers[msg.sender].paidAt = block.number;

            if (stakers[referer].registered && referer != msg.sender) {
                stakers[msg.sender].referer = referer;
                stakers[referer].referrals++;
            }
        }

        balances[msg.sender] = balances[msg.sender].sub(_amount);

        stakers[msg.sender].stakes.push(Stake(_amount, block.number, stakingPeriod()));
        
        uint256 refAmount;
        if (stakers[referer].registered && referer != msg.sender) {
            refAmount = _amount.div(10);
            balances[referer] = balances[referer].add(refAmount);
            emit Transfer(address(this), referer, refAmount);
            emit Referral(referer, msg.sender, refAmount);
        }

        // reserve {_amount} token that will be earned by this staker
        totalDistributed = totalDistributed.add(_amount.add(refAmount));
        totalStaked = totalStaked.add(_amount);
        emit Staked(msg.sender, _amount, stakingPeriod());
        return true;
    }

    // stakingReward is the % a staker earns daily untill STAKINGRETURN is earned
    function stakingReward() public view returns(uint256) {
        return STAKINGRETURN.mul(ADAY).mul(100).div(stakingPeriod());
    }

    // stakingPeriod is the number of days it takes a staker to earn 200% of his stake
    // while earning thesame amount daily.
    // It starts at 120 and increase as the circulating supply increases
    function stakingPeriod() public view returns(uint256) {
        uint256 unminted = totalSupply.sub(totalDistributed);
        uint256 period = totalSupply.mul(45).div(unminted);
        if (period > 360) {
            period = 360;
        }
        return period.mul(ADAY);
    }

    function _withdrawable(address user) internal view returns (uint256 amount) {
        Staker storage staker = stakers[user];
        
        for (uint i = 0; i < staker.stakes.length; i++) {
            Stake storage dep = staker.stakes[i];
                
            uint finish = dep.at + dep.term;
            uint since = staker.paidAt > dep.at ? staker.paidAt : dep.at;
            uint till = block.number > finish ? finish : block.number;

            if (since < till) {
                amount += dep.amount * (till - since) * STAKINGRETURN / dep.term / 100;
            }
        }
    }

    function harvest() public returns (bool) {
        require(stakers[msg.sender].registered);
        uint256 amount = _withdrawable(msg.sender);
        require(amount >= 0);
        stakers[msg.sender].paidAt = block.number;
        balances[msg.sender] = balances[msg.sender].add(amount);
        totalEarned = totalEarned.add(amount);
        stakers[msg.sender].totalReward = stakers[msg.sender].totalReward.add(amount);
        emit Transfer(address(this), msg.sender, amount);
        emit Harvest(msg.sender, amount);

        return true;
    }
    
    function _farmSize(address user) internal view returns (uint256){
        Staker storage staker = stakers[user];
        
        uint256 amount;
        for (uint i = 0; i < staker.stakes.length; i++) {
            Stake storage dep = staker.stakes[i];
            if(dep.at + dep.term < block.number) {
                continue;
            }
            amount = amount + dep.amount;
        }
        return amount;
    }
    
    function farmSize() public view returns(uint256) {
        return _farmSize(msg.sender);
    }
    
    function withdrawable() public view returns(uint256) {
        return _withdrawable(msg.sender);
    }
    
    function rewardReceived() public view returns(uint256) {
        return stakers[msg.sender].totalReward;
    }
}