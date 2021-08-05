/**
 *Submitted for verification at Etherscan.io on 2020-09-12
*/

pragma experimental ABIEncoderV2;
pragma solidity >=0.4.22 <0.7.0;


// ----------------------------------------------------------------------------
// ERC Token SafeMath
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}
interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
contract TokenStake {
    using SafeMath for uint;
    using SafeMath for uint256;
    
    address public _owner;
    address public _token;
    uint public _apr;
    uint public _aprPerDay;
    uint public  thousand = 1000000;
    uint256 public _poolLimit = 50e18;
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event NewStake(address indexed account, uint indexed amount, uint indexed year);
    event ClaimStake(address indexed account,uint indexed stakeId, uint indexed amount);
    event UnLockStake(address indexed account, uint indexed stakeId);
    struct Stake {
        uint year; // total year;
        uint256 amount;
        uint timeDeposit;
        uint256 claimed;
        uint256 reward;
        uint256 apr;
        bool locked;
        bool openLockForce;
        
    }
    bool _openLockForce = false;
    mapping(address => Stake[]) public _staker;
    address [] public _activeAddress;
    bool public _freeze = false;
    modifier ownerOnly () {
        require(msg.sender == _owner, "NO_ACCESS");
        _;
    }
    
    modifier notFreezing() {
        require(_freeze == false, "ITS_COLD");
        _;
    }
    constructor (address tokenERC, uint aprPercentage, uint256 poolLimit) public {
        _token = tokenERC;
        _apr = aprPercentage * thousand;
        _aprPerDay = _apr / 365;
        _owner = msg.sender; 
        _poolLimit = poolLimit;
        emit OwnerSet(address(0), _owner);
    }
    function getApr() public view returns(uint256) {
        return _apr;
    }
    function getPoolLimit() public view returns(uint256) {
        return _poolLimit;
    }
    function getPoolLockForce() public view returns(bool) {
        return _openLockForce;
    }
    function startStake(uint256 amount, uint year) public  notFreezing returns (uint) {
        require(amount >= 1 ether, "MIN_1_TOKEN");
        require(year > 0, "MIN_1_YEAR");
        require((amount % 1 ether) == 0, "1_INTERVAL");
        require(totalPoolToken().add(amount) <= _poolLimit, "POOL_LIMIT");
        uint reward = (amount * (_apr / 100)) * year;
        if(_staker[msg.sender].length == 0) {
            _activeAddress.push(msg.sender);
        }
        _staker[msg.sender].push(Stake({
            year: year,
            amount: amount,
            timeDeposit: now,
            claimed: 0,
            reward: reward,
            apr: _apr,
            locked: true,
            openLockForce: false
        }));
        ERC20(_token).transferFrom(msg.sender, address(this), amount);
        emit NewStake(msg.sender, amount, year);
        return reward;
    }
    function stakesOf(address account) public view returns(Stake [] memory){
        return _staker[account];
    }
    function claimStake(uint id) public notFreezing returns  (bool) {
        uint claim = stakeCanClaim(msg.sender, id);
        require(claim > 0, "NOTHING_CAN_CLAIM");
        require(_staker[msg.sender][id].claimed.add(claim) <= _staker[msg.sender][id].reward  , "hmm is this bug ?");
        _staker[msg.sender][id].claimed = _staker[msg.sender][id].claimed.add(claim);
        ERC20(_token).transfer(msg.sender, claim / thousand);
        emit ClaimStake(msg.sender, id, claim);
        return true;
    }
    function unlockStake(uint stakeId) public notFreezing returns (bool) {
        require(_staker[msg.sender][stakeId].locked == true, "ALREADY_CLAIMED");
        if(_staker[msg.sender][stakeId].openLockForce == true) {
            ERC20(_token).transfer(msg.sender, _staker[msg.sender][stakeId].amount);
            _staker[msg.sender][stakeId].locked = false;
            emit UnLockStake(msg.sender, stakeId);
            return true;
        }
        uint totalDay = (now - _staker[msg.sender][stakeId].timeDeposit) / 86400;
        if(totalDay > _staker[msg.sender][stakeId].year * 365) {
            ERC20(_token).transfer(msg.sender, _staker[msg.sender][stakeId].amount);
            _staker[msg.sender][stakeId].locked = false;
            emit UnLockStake(msg.sender, stakeId);
            return true;
        }
        
    }
    function stakeCanClaim(address account, uint id) public view returns (uint) {
        require(_staker[account][id].amount > 0, "NO_CLAIM_AVAILABLE");
        Stake memory tk = _staker[account][id];
        uint totalDay = (now-tk.timeDeposit) / 1 days;
        uint totalDayReward = (_aprPerDay * totalDay) / 100;
        uint reward = tk.amount * totalDayReward;
        uint claimable = (reward > tk.reward ? tk.reward : reward) - tk.claimed;
        return claimable;
    }
    /*
        get active
    */
    function totalActiveAddressCount() public view returns (uint) {
        return _activeAddress.length;
    }
    function totalPoolToken() public view returns (uint) {
        uint total;
        for(uint a = 0; a < _activeAddress.length; a++){
            for(uint b = 0; b < _staker[_activeAddress[a]].length; b++) {
                total = total + _staker[_activeAddress[a]][b].amount;
            }
        }
        return total;
    }
    /* OWNER FEATURE */
    // ANTI HAZARD WHEN SOMETHING WENT WRONG IN BETA 
    function withdrawToken(uint256 amount) public ownerOnly returns (bool) {
        ERC20(_token).transfer(msg.sender, amount);
        return true;
    }
    // SET FREEZE COLD BZZZZZ
    function setFreeze(bool freezeStatus) public ownerOnly returns (bool) {
        _freeze = freezeStatus;
        return true;
    }
    function setOpenLockForce(bool lockForce) public ownerOnly returns (bool) {
        _openLockForce = lockForce;
        return true;
    }
    function setOpenLockForce(address account, uint stakeId, bool lockForce) public ownerOnly returns (bool) {
        _staker[account][stakeId].openLockForce = lockForce;
        return true;
    }
    function setAPR(uint aprPercentage) public ownerOnly returns (bool) {
        _apr = aprPercentage * thousand;
        _aprPerDay = _apr / 365;
        return true;
    }
    function setPoolLimit(uint256 limit) public ownerOnly returns (bool) {
        _poolLimit = limit;
        return true;
    }
    function setOwner(address newOwner) public ownerOnly returns (bool) {
        _owner = newOwner;
        return true;
    }
    
}