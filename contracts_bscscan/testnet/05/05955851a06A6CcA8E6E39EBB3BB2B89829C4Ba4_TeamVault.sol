/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

pragma solidity 0.8.0;
//SPDX-License-Identifier: UNLICENSED

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function moveBNBToWallet() external returns (bool);
    
    function balanceOfBNB( address owner) external view returns (uint);
    
    function getOwnerBNBValue() external view returns (uint);
    
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface RewardPool {
    function withdrawReward() external returns (uint);
    function viewClaimReward( address _holder) external view returns (uint);
}

contract TeamVault is Ownable {
    using SafeMath for uint;
    
    event rewardClaimed( address _team, uint _amount);
    event teamWalletDiv( address indexed _team, uint _amount);
    
    address public DXB;
    address public rewardPool;
    
    uint public timeLock = 43200;//180 days;
    uint public startTime = block.timestamp;
    
    bool public _isBalanceUpdated = false;
    
    address[] teamWalletsList;
    
    struct teamwalletStruct {
        uint _balances;
        uint _pendingReward;
        bool _isExist;
    }
    
    mapping(address => teamwalletStruct) public teamVault;
    
    constructor( address _teamOneWallet, address _teamTwoWallet, address _teamThreeWallet, address _rewardPool)  {
        teamWalletsList.push(_teamOneWallet);
        teamWalletsList.push(_teamTwoWallet);
        teamWalletsList.push(_teamThreeWallet);
        
        teamVault[_teamOneWallet]._isExist = true;
        teamVault[_teamTwoWallet]._isExist = true;
        teamVault[_teamThreeWallet]._isExist = true;
        
        rewardPool = _rewardPool;
    }
    
    receive() external payable {
    }
    
    /** 
     * @dev Calls updateDXB() function to set DXB address.
     * @param _DXB address of DXB.
    */
    function updatedDXB( address _DXB) public onlyOwner {
        require((_DXB != address(0)), "TeamVault :: updatedDXB : DXB address is already set");
        DXB = _DXB;
    }
    
    function updateTeamBalance() public onlyOwner {
        require(_isBalanceUpdated == false, "Can update only once");
        uint _balanceOf = IERC20(DXB).balanceOf(address(this));
        
        uint _halfBalance = _balanceOf.div(2);
        teamVault[teamWalletsList[0]]._balances = _halfBalance;
        teamVault[teamWalletsList[1]]._balances = _halfBalance.div(2);
        teamVault[teamWalletsList[2]]._balances = _halfBalance.div(2);
        _isBalanceUpdated = true;
    }
    
    /** 
     * @dev Calls getReward() function to get rewards.
     * @return bool true
    */
    function getReward() public returns (bool) {
        require((teamVault[_msgSender()]._isExist) || (_msgSender() == owner()), "TeamVault :: getReward : invalid team vault");
        if((RewardPool(rewardPool).viewClaimReward(address(this)) == 0) && (teamVault[_msgSender()]._pendingReward == 0)) { return false; }
        
        address _contract = address(this);
        
        uint _bfBalance = _contract.balance;
        
        RewardPool(rewardPool).withdrawReward();
        
        uint _newBalance = _contract.balance.sub(_bfBalance);
        
        if(_newBalance > 0){
            uint _balance = IERC20(DXB).balanceOf(address(this));
            uint _halfBalance = _balance.div(2);
            
            uint[3] memory _teamWalletDiv;
            
            (_teamWalletDiv[0], _teamWalletDiv[1], _teamWalletDiv[2])= (_halfBalance, _halfBalance.div(2), _halfBalance.div(2));
        
            uint currentSharePerBlock = getBNBValuePerShare(_newBalance,_balance);
            
            teamVault[teamWalletsList[0]]._pendingReward = teamVault[teamWalletsList[0]]._pendingReward.add((currentSharePerBlock.mul(_teamWalletDiv[0]).div(1e12)).div(1e18));
            teamVault[teamWalletsList[1]]._pendingReward = teamVault[teamWalletsList[1]]._pendingReward.add((currentSharePerBlock.mul(_teamWalletDiv[1]).div(1e12)).div(1e18));
            teamVault[teamWalletsList[2]]._pendingReward = teamVault[teamWalletsList[2]]._pendingReward.add((currentSharePerBlock.mul(_teamWalletDiv[2]).div(1e12)).div(1e18));
        }
        
        if((teamVault[_msgSender()]._pendingReward > 0) && (_msgSender() != owner())){
            uint _reward = teamVault[_msgSender()]._pendingReward;
            teamVault[_msgSender()]._pendingReward = 0;
            payable(_msgSender()).transfer(_reward);
            emit rewardClaimed( _msgSender(), _reward);
        }
        return true;
    }
    
    /** 
     * @dev Calls distributeTeamWallet() function to distribute tokens.
     * @return bool true
    */
    function claimDXB() public returns (bool) {
        require(teamVault[_msgSender()]._isExist, "TeamVault :: claimDXB : invalid team vault");
        require((startTime != 0) && (startTime.add(timeLock) < block.timestamp), "TeamVault :: claimDXB : Requires 180 days to pass");
        require(IERC20(DXB).balanceOf(address(this)) >= teamVault[_msgSender()]._balances, "TeamVault :: claimDXB : insufficient balance to distribute");
        
        uint _bal = teamVault[_msgSender()]._balances;
        teamVault[_msgSender()]._balances = 0;
        
        _safeTransferDXB( _msgSender(), _bal);
        return true;
    }
    
    /** 
     * @dev Calls viewInvestorReward() function to distribute tokens.
     * @param _teamWallet team wallet address
     * @return uint reward
    */
    function viewTeamReward( address _teamWallet) public view returns (uint) {
        uint _contractReward = RewardPool(rewardPool).viewClaimReward(address(this));
        uint _balance = IERC20(DXB).balanceOf(address(this));
        uint currentSharePerBlock = getBNBValuePerShare(_contractReward, _balance);
        uint _ownShare = 0;
        
        _balance = _balance.div(2);
        
        if(_teamWallet == teamWalletsList[0]) _ownShare = _balance;
        else _ownShare = _balance.div(2);
        
        uint rewardBNB = (currentSharePerBlock.mul(_ownShare).div(1e12)).div(1e18);
        rewardBNB = rewardBNB.add(teamVault[_teamWallet]._pendingReward);
        return rewardBNB;
    }
    
    /** 
     * @dev Calls _safeTransfer() function to transfer tokens.
     * @param _sender send address
     * @param _amount send amount.
    */
    function _safeTransferDXB( address _sender, uint _amount) private {
        IERC20(DXB).transfer( _sender, _amount);
        emit teamWalletDiv( _sender, _amount);
    }
    
    /** 
     * @dev Calls getBNBValuePerShare() function to get tokens.
     * @param amount total bnb
     * @param _balance DXB balance of team wallets.
     * @return uint reward
    */
    function getBNBValuePerShare( uint amount, uint _balance) private pure returns (uint) {
        return amount.mul(1e12).mul(1e18).div(_balance);
    }
    
    function _teamWalletsList() public view returns ( address [] memory) {
        require(teamVault[msg.sender]._isExist, "not a team wallet");
        return teamWalletsList;
    }
}