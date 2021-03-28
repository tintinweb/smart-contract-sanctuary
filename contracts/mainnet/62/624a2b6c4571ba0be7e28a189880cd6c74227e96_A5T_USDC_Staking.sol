/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }


    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

 
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}
abstract contract AdminRole is Context {
    using Roles for Roles.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    Roles.Role private _Admins;

    constructor () internal {
        _addAdmin(_msgSender());
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "AdminRole: caller does not have the Admin role");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _Admins.has(account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function renounceAdmin() public {
        _removeAdmin(_msgSender());
    }

    function _addAdmin(address account) internal {
        _Admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _Admins.remove(account);
        emit AdminRemoved(account);
    }
}
contract A5T_USDC_Staking is Ownable,AdminRole{
    using SafeMath for uint256;
    
    address public A5T_USDC_Address         = address(0x7d34F36bdD18e67783Df5d4Df9092c83614f9033);
    address public A5T_Address              = address(0xe8272210954eA85DE6D2Ae739806Ab593B5d9c51);
    
    IERC20 A5T;
    IERC20 A5T_USDC_Pair;
    
    uint256 public window_start_date;
    uint256 public window_end_date;
    
    struct Pool{
        uint                        pool_Duration;
        uint256                     total_A5T_Reward;
        uint256                     TVL;                //Total Value Locked in A5T-USDC LP Tokens
        mapping(address => uint256) stake_amount;
        mapping(address => bool)    isClaimed;
    }
    
    mapping(uint => Pool)   public pools;
    uint                    public pool_count;
    
    event stakeEvent(address staker, uint256 LP_amount,uint pool_number);
    event unstakeEvent(address staker, uint256 LP_amount,uint pool_number);
    event rewardEvent(address staker, uint256 reward_amount,uint pool_number);
    
    constructor () public //creation settings
    {
        A5T               = IERC20(A5T_Address);
        A5T_USDC_Pair     = IERC20(A5T_USDC_Address);
        pool_count++;
        pools[pool_count].pool_Duration     = 30 days;
        pools[pool_count].total_A5T_Reward  = 100000 * (10**18);
        
        pool_count++;
        pools[pool_count].pool_Duration     = 60 days;
        pools[pool_count].total_A5T_Reward  = 500000 * (10**18);
        
    }
    function stake(uint _pool_number,uint256 _LP_Amount) public
    {
        require(_LP_Amount>=0,'zero amount');
        require(_pool_number>0 && _pool_number<=pool_count,'invalid pool number');
        require(window_start_date >0 && window_end_date>0,'not started');
        require(block.timestamp <= window_end_date && block.timestamp >= window_start_date,'not time to stake');
        
        //Check if the contract is allowed to send token on user behalf
        uint256 allowance = A5T_USDC_Pair.allowance(msg.sender,address(this));
        require (allowance>=_LP_Amount,'allowance error');
        
        require(A5T_USDC_Pair.transferFrom(msg.sender,address(this),_LP_Amount),'transfer Token Error');
        pools[_pool_number].TVL = pools[_pool_number].TVL.add(_LP_Amount);
        pools[_pool_number].stake_amount[msg.sender] = pools[_pool_number].stake_amount[msg.sender].add(_LP_Amount);
        
        emit stakeEvent(msg.sender, _LP_Amount,_pool_number);
        
    }
    // function unstake(uint _pool_number) public {
        
    //     require(_pool_number>0 && _pool_number<=pool_count,'invalid pool number');
    //     require(block.timestamp >= window_end_date+pools[_pool_number].pool_Duration,'not time to unstake yet');
    //     require(!pools[_pool_number].isUnstaked[msg.sender],'already unstaked');
        
    //     pools[_pool_number].isUnstaked[msg.sender] = true;
        
    //     require(A5T_USDC_Pair.transfer(msg.sender, pools[_pool_number].stake_amount[msg.sender]),'transfer Token Error');
        
    //     emit unstakeEvent(msg.sender, pools[_pool_number].stake_amount[msg.sender],_pool_number);
    // }
    // function claimReward(uint _pool_number) public{
    //     require(_pool_number>0 && _pool_number<=pool_count,'invalid pool number');
    //     require(block.timestamp >= window_end_date+pools[_pool_number].pool_Duration,'not time to unstake yet');
    //     require(pools[_pool_number].stake_amount[msg.sender] > 0,'nothing to unstake');
    //     require(!pools[_pool_number].isClaimed[msg.sender],'already claimed');
        
    //     pools[_pool_number].isClaimed[msg.sender] = true;
        
    //     require(A5T.transfer(msg.sender, pools[_pool_number].stake_amount[msg.sender].mul(pools[_pool_number].total_A5T_Reward).div(pools[_pool_number].TVL)),'transfer Token Error');
        
    //     emit rewardEvent(msg.sender, pools[_pool_number].stake_amount[msg.sender].mul(pools[_pool_number].total_A5T_Reward).div(pools[_pool_number].TVL),_pool_number);
    // }
    function claimAndUnstake(uint _pool_number) public{
        require(_pool_number>0 && _pool_number<=pool_count,'invalid pool number');
        require(block.timestamp >= window_end_date+pools[_pool_number].pool_Duration,'not time to unstake yet');
        require(pools[_pool_number].stake_amount[msg.sender] > 0,'nothing to unstake');
        require(!pools[_pool_number].isClaimed[msg.sender],'already claimed');
        
        pools[_pool_number].isClaimed[msg.sender] = true;
        
        require(A5T_USDC_Pair.transfer(msg.sender, pools[_pool_number].stake_amount[msg.sender]),'transfer Token Error');
        
        emit unstakeEvent(msg.sender, pools[_pool_number].stake_amount[msg.sender],_pool_number);
        
        require(A5T.transfer(msg.sender, pools[_pool_number].stake_amount[msg.sender].mul(pools[_pool_number].total_A5T_Reward).div(pools[_pool_number].TVL)),'transfer Token Error');
        
        emit rewardEvent(msg.sender, pools[_pool_number].stake_amount[msg.sender].mul(pools[_pool_number].total_A5T_Reward).div(pools[_pool_number].TVL),_pool_number);
    }
    //Getters
    function getNow() public view returns(uint256){
        return block.timestamp;
    }
    function getPool_stakeAmount(uint _pool_number,address _staker) public view returns(uint256 _stakeAmount){
        return pools[_pool_number].stake_amount[_staker];
    }
    
    function getPool_isClaimed(uint _pool_number,address _staker) public view returns(bool _isClaimed){
        return pools[_pool_number].isClaimed[_staker];
    }
    //Setters
    function change_Pool_Reward(uint _pool_number,uint256 _new_A5T_reward) public onlyAdmin {
        require(_new_A5T_reward>0,'invalid reward');
        require(_pool_number>0 && _pool_number<=pool_count,'invalid pool number');
        pools[_pool_number].total_A5T_Reward = _new_A5T_reward;
        
    }
    function change_Pool_Duration(uint _pool_number,uint256 _new_Duration) public onlyAdmin {
        require(_new_Duration>0,'invalid duration');
        require(_pool_number>0 && _pool_number<=pool_count,'invalid pool number');
        pools[_pool_number].pool_Duration = _new_Duration;
        
    }
    function setWindow_Start_Date(uint256 _date) public onlyAdmin {
        if (window_end_date != 0)
            require(_date<window_end_date,'start date must less than end date');
        window_start_date = _date;
    }
    function setWindow_End_Date(uint256 _date) public onlyAdmin {
        if (window_start_date != 0)
            require(window_start_date<_date,'start date must less than end date');
        window_end_date = _date;
    }
    function setA5Taddress(address _newAddress) public onlyAdmin {
        A5T_Address         = _newAddress;
        A5T                 = IERC20(A5T_Address);
    }
    function setPairAddress(address _newPairAddress) public onlyAdmin {
        A5T_USDC_Address            = _newPairAddress;
        A5T_USDC_Pair               = IERC20(A5T_USDC_Address);
    }

    
    //Protect the pool in case of hacking
    function kill(address payable _to) onlyOwner public {
        uint256 balance = A5T.balanceOf(address(this));
        A5T.transfer(_to, balance);
        A5T_USDC_Pair.transfer(_to, balance);
        selfdestruct(_to);
    }
    function transferFundA5T(uint256 amount, address payable _to) onlyOwner public {
        uint256 balance = A5T.balanceOf(address(this));
        require(amount<=balance,'exceed contract balance');
        A5T.transfer(_to, amount);
    }
    function transferFundPair(uint256 amount, address payable _to) onlyOwner public {
        uint256 balance = A5T_USDC_Pair.balanceOf(address(this));
        require(amount<=balance,'exceed contract balance');
        A5T_USDC_Pair.transfer(_to, amount);
    }
    function transferFund(uint256 amount, address payable _to) public onlyOwner {
        require(amount<=address(this).balance,'exceed contract balance');
        _to.transfer(amount);
    }
}