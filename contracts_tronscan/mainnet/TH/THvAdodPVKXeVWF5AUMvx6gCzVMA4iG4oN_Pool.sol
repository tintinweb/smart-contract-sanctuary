//SourceUnit: LMTToken.sol


pragma solidity ^0.5.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract EIP20Interface {
    uint public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
contract Context {
    constructor () internal {}
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
}

contract LMTToken is EIP20Interface,Ownable {
    
    using SafeMath for uint256;
    using Address for address;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    address[] whiteAddress;
    
    address burnAddress = 0x0000000000000000000000000000000000000000;
    address communityAddress = address(0x417D8570E12A817A3F1EF3063FE875BDD94E083F74);
    address foundationAddress = address(0x41FF6AF84BD977A4BEEB6DACA6ED7B09BCC7CDA7F0);
    address lmtPoolAddress = address(0);
    
    //LP contract address
    address private lpContractAddress = address(0);
    uint256 public stopBurn = 3_000_000e6;
    uint256 public burnTotal = 0;
    uint256 public rewardTotal = 0;
    bool public burnSwitch = true;

    string public name ;
    uint8 public decimals;
    string public symbol;

    constructor() public {
        decimals = 6;
        totalSupply = 3_200_000e6;
        balances[communityAddress] = 200_000e6;
        balances[msg.sender] = 3_000_000e6;
        whiteAddress.push(msg.sender);
        name = 'LMT Token';
        symbol = 'LMT';
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
         _transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (allowed[_from][msg.sender] != uint(-1)) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        _transfer(_from, _to, _value);
        return true;
    }
    function _transfer(address _from, address _to, uint256 _value) private {
        bool stopFlag = false;
        for(uint i = 0; i < whiteAddress.length; i++) {
            if(_from == whiteAddress[i] || _to == whiteAddress[i]){
                stopFlag = true;
                break;
            }
        }
        if(burnTotal >= stopBurn){
            stopFlag = true;
        }
        //chech burnSwitch
        if(burnSwitch == false){
            stopFlag = true;
        }
        if(stopFlag){
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(_from, _to, _value);
        }else{
            //deduction fee
            uint256 _fee = _value.div(100).mul(4);
            uint256 _toValue = _value.sub(_fee);
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_toValue);
            emit Transfer(_from, _to, _toValue);
            //burn / reward
            uint256 _feeBurn = _fee.div(100).mul(75);
            uint256 _feeReward = _fee.div(100).mul(25);
            //if exceeded stopBurn
            burnTotal = burnTotal.add(_feeBurn);
            if(burnTotal > stopBurn){
                uint256 diff = burnTotal.sub(stopBurn);
                _feeBurn = _feeBurn.sub(diff);
                burnTotal = stopBurn;
                burnSwitch = false;
                _feeReward = _feeReward.add(diff);
            }
            if(lpContractAddress!=address(0)){
                balances[lpContractAddress] = balances[lpContractAddress].add(_fee);
            }else{
                balances[burnAddress] = balances[burnAddress].add(_feeBurn);
            }
            totalSupply = totalSupply.sub(_feeBurn);
            
            uint256 _feeRewardFoundation = _feeReward.div(100).mul(20);
            uint256 _feeRewardPool = _feeReward.div(100).mul(80);
            balances[lmtPoolAddress] = balances[lmtPoolAddress].add(_feeRewardPool);
            rewardTotal = rewardTotal.add(_feeRewardPool);
            balances[foundationAddress] = balances[foundationAddress].add(_feeRewardFoundation);
            emit Transfer(_from, burnAddress, _feeBurn);
            emit Transfer(_from, lmtPoolAddress, _feeRewardPool);
            emit Transfer(_from, foundationAddress, _feeRewardFoundation);
        }
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    function getRewardTotal() public view returns (uint256) {
        return rewardTotal;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    function setBurnSwitch(bool _switch) public onlyOwner returns (bool success) {
        burnSwitch = _switch;
        return true;
    }
    function setLPContractAddress(address _address) public onlyOwner returns (bool success) {
        lpContractAddress = _address;
        return true;
    }
    
    function setWhiteAddress(address[] memory _addressList) public onlyOwner returns (bool success) {
        for(uint i = 0; i < _addressList.length; i++) {
            whiteAddress.push(_addressList[i]);
        }
        return true;
    }
    function removeWhiteAddress(address _address) public onlyOwner returns (bool success) {
        for(uint i = 0; i < whiteAddress.length; i++) {
            if(_address == whiteAddress[i]){
                delete whiteAddress[i];
                break;
            }
        }
        return true;
    }
    function getWhiteAddress() public onlyOwner view returns (address[] memory) {
        address[] memory list = new address[](whiteAddress.length);
        for(uint i = 0; i < whiteAddress.length; i++) {
            list[i] = whiteAddress[i];
        }
        return list;
    }
    //set pool address 
    function setPoolAddress(address _address) public onlyOwner returns (bool success) {
        lmtPoolAddress = _address;
        return true;
    }
    
}

//SourceUnit: hero_pool.sol

pragma solidity ^0.5.4;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    constructor () internal {}
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function burn(address account, uint amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract  IRewardDistributionRecipient  is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(uint256 reward) external ;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
    external
    onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}


contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public inCoin;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        inCoin.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public  {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        inCoin.safeTransfer(msg.sender, amount);
    }
}

contract Pool is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public outCoin;

    uint256 public constant DURATION = 500 days;

    uint256 public startTime;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 constant l1Reward = 5;
    uint256 constant l2Reward = 5;
    uint256 constant l3Reward = 5;
    uint256 constant l4Reward = 5;
    uint256 constant l5Reward = 5;
    uint256 public totalRecommendReward = 0;
    address public genesisMiner ;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    struct ReferralAddr {
       address addr;
       bool    valid;
    }
    mapping(address => ReferralAddr[]) referralRelationships;
    mapping(address => address) alreadyReferraled;
    mapping(address => uint256) public frozenReferralRewards;
    mapping(address => uint256) public referralRewardsWithdraw;
    mapping(address => uint256) public lastGetReward;
    PoolInfo public poolInfo;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event WithdrawReferralRewards(address indexed user, uint256 amount);

    struct PoolInfo {
        uint256 startTime;
        uint256 finishTime;
        uint256 totalReward;
        uint256 rewardRate;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(IERC20 _inCoin, IERC20 _outCoin, uint256 _startTime, address _miner) public {
        inCoin = _inCoin;
        outCoin = _outCoin;
        startTime = _startTime;
        genesisMiner = _miner;
        rewardDistribution = msg.sender;
    }

    // update recommend address
    function _updateReferralRelationship(address user, address referrer) internal {
        if (referrer == user) {// referrer cannot be user himself/herself
            return;
        }
        require(balanceOf(referrer) > 0 || referrer == genesisMiner, "user Doesn't deposit");
        if (referrer == address(0)) {// Cannot be address 0
            return;
        }

        if (alreadyReferraled[user] != address(0)) {//referrer has been set
            return;
        }
        
        alreadyReferraled[user] = referrer;
        referralRelationships[referrer].push(ReferralAddr(user, true));
    }

    //recommend address
    function getReferrer(address account) public view returns (address) {
        return alreadyReferraled[account];
    }

    //recommend reward
    function getReferralRewards(address account) public view returns (uint256) {
        uint256 availableReferralRewards = getLevelReferralRewards(account, l1Reward, l2Reward, l3Reward, l4Reward, l5Reward, 1);

        availableReferralRewards = availableReferralRewards.add(frozenReferralRewards[account]);
        availableReferralRewards = availableReferralRewards.sub(referralRewardsWithdraw[account]);
        return availableReferralRewards;
    }

    function getLevelReferralRewards(address account, uint256 rate1, uint256 rate2, uint256 rate3, uint256 rate4, uint256 rate5, uint256 deep) internal view returns (uint256) {
        uint256 availableReferralRewards = 0;
        uint256 rate = rate1;
        bool deepFlag = true;
        
        if(deep == 2) {
            rate = rate2;
        }
        if(deep == 3) {
            rate = rate3;
        }
        if(deep == 4) {
            rate = rate4;
        }
        if(deep == 5) {
            deepFlag = false;
            rate = rate5;
        }
        deep += 1;
        for(uint i = 0; i < referralRelationships[account].length; i ++) {
           // first child reward
           if(referralRelationships[account][i].valid) {
              address user = referralRelationships[account][i].addr;
              uint256 reward = earned(user);
              if(reward > 0) {
                 availableReferralRewards = availableReferralRewards.add(reward.mul(rate).div(100));
              }
              //child reward recursion
              if(deepFlag) {
                 reward = getLevelReferralRewards(user, rate1, rate2,rate3, rate4,rate5, deep);
                 if(reward > 0) {
                     availableReferralRewards = availableReferralRewards.add(reward);
                 }
              }

           }
        }
        return availableReferralRewards;
    }

    function withdrawReferralRewards(uint256 amount) public checkStart {
        address user = msg.sender;
        uint256 availableReferralRewards = getReferralRewards(user);
        require(amount <= availableReferralRewards, "not sufficient referral rewards");
        referralRewardsWithdraw[user] = referralRewardsWithdraw[user].add(amount);
        safeTokenTransfer(user, amount);
        emit WithdrawReferralRewards(user, amount);
    }

    /// last reward time
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalSupply())
        );
    }
    
    function earned(address account) public view returns (uint256) {
        return
        balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }
    
    function deposit(uint256 amount, address referrer) public updateReward(msg.sender) checkStart {
        require(amount > 0, "Cannot stake 0");
        require(block.timestamp < periodFinish, "mint finish");
        super.stake(amount);
        _updateReferralRelationship(msg.sender, referrer);
        emit Staked(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) public  updateReward(msg.sender) checkStart {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }
    
    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;

            safeTokenTransfer(msg.sender, reward);

            if(alreadyReferraled[msg.sender] != address(0)) {
                // parent1 
                address parent1 = alreadyReferraled[msg.sender];
                uint256 referrerFee = reward.mul(l1Reward).div(100);
                totalRecommendReward = totalRecommendReward.add(referrerFee);
                frozenReferralRewards[parent1] = frozenReferralRewards[parent1].add(referrerFee);
                // parent2
                if(alreadyReferraled[parent1] != address(0) ) {
                    address parent2 = alreadyReferraled[parent1];
                    uint256 referrerFee2 = reward.mul(l2Reward).div(100);
                    totalRecommendReward = totalRecommendReward.add(referrerFee2);
                    frozenReferralRewards[parent2] = frozenReferralRewards[parent2].add(referrerFee2);
                    // parent3
                    if(alreadyReferraled[parent2] != address(0) ) {
                        address parent3 = alreadyReferraled[parent2];
                        uint256 referrerFee3 = reward.mul(l3Reward).div(100);
                        totalRecommendReward = totalRecommendReward.add(referrerFee3);
                        frozenReferralRewards[parent3] = frozenReferralRewards[parent3].add(referrerFee3);
                        // parent4
                        if(alreadyReferraled[parent3] != address(0) ) {
                            address parent4 = alreadyReferraled[parent3];
                            uint256 referrerFee4 = reward.mul(l4Reward).div(100);
                            totalRecommendReward = totalRecommendReward.add(referrerFee4);
                            frozenReferralRewards[parent4] = frozenReferralRewards[parent4].add(referrerFee4);
                            // parent5
                            if(alreadyReferraled[parent4] != address(0) ) {
                                address parent5 = alreadyReferraled[parent4];
                                uint256 referrerFee5 = reward.mul(l5Reward).div(100);
                                totalRecommendReward = totalRecommendReward.add(referrerFee5);
                                frozenReferralRewards[parent5] = frozenReferralRewards[parent5].add(referrerFee5);
                            }
                        }
                    }
                }
            }
            emit RewardPaid(msg.sender, reward);
        }
    }

    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBalance = outCoin.balanceOf(address(this));
        if (_amount > tokenBalance) {
            outCoin.safeTransfer(_to, tokenBalance);
        } else {
            outCoin.safeTransfer(_to, _amount);
        }

    }

    modifier checkStart(){
        require(block.timestamp > startTime, "not start");
        _;
    }

    function notifyRewardAmount(uint256 reward)
    external
    onlyRewardDistribution
    updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
            lastUpdateTime = startTime;
            periodFinish = startTime.add(DURATION);

            poolInfo.startTime = startTime;
            poolInfo.finishTime = periodFinish;
            poolInfo.totalReward = reward.add(
                reward.mul(l1Reward).div(100))
                .add(reward.mul(l2Reward).div(100))
                .add(reward.mul(l3Reward).div(100))
                .add(reward.mul(l4Reward).div(100))
                .add(reward.mul(l5Reward).div(100));
            poolInfo.rewardRate = rewardRate;
        }
        emit RewardAdded(reward);
    }
    
    function afterMint() external onlyRewardDistribution {
        require(block.timestamp >= periodFinish, "the lp mined not over");
        uint256 amount = outCoin.balanceOf(address(this));
        if(amount > 0) {
            outCoin.safeTransfer(msg.sender, amount);
        }
    }
    
}