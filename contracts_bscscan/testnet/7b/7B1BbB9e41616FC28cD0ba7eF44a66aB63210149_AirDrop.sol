/**
 *Submitted for verification at BscScan.com on 2021-07-17
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


contract AirDrop is Ownable {
    using SafeMath for uint;
    
    event rewardClaimed( address _team, uint _amount);
    event airdropWalletDiv( address indexed _team, uint _amount);
    
    struct AirdropStruct {
        uint _balances;
        uint _pendingReward;
        bool _isExist;
    }
    
    mapping(address => AirdropStruct) public AirDropWallets;
    mapping(address => bool) public auth;
    
    address[] public AirDropList;
    address public _RewardPool;
    IERC20 public DXB;
    
    uint public lockPeriod = 43200;
    uint public startTime = block.timestamp;
    
    constructor( address[] memory _airdrops, address _rewardPool) {
        require(_airdrops.length <= 30, "AirDrop :: limited to 30 IW");
        _RewardPool = _rewardPool;
        
        
        for(uint i=0; i< _airdrops.length;i++){
            AirDropList.push(_airdrops[i]);
            AirDropWallets[_airdrops[i]]._isExist = true;
        }
    }
    
    modifier onlyAuth(){
        require(auth[_msgSender()], "AirDrop :: only  auth");
        _;
    }
    
    receive() external payable {
    }
    
    /** 
     * @dev Calls setAuth() function to set authentication to address.
     * @param _regAuth auth address.
     */
    function setAuth( address _regAuth) public onlyOwner { auth[_regAuth] = true; }
    
    /** 
     * @dev Calls updatedDXB() function to update DXB address.
     * @param _DXB DXB token address.
     */
    function updatedDXB( IERC20 _DXB) public onlyOwner {
        require((address(_DXB) != address(0)) && ( address(DXB) == address(0)), "AirDrop :: updatedDXB : DXB address is already set");
        DXB = _DXB;
    }
    
    /** 
     * @dev Calls transferFromIAirDrop() function to receive tokens send for airdrop.
     * @param _owner DXB address.
     * @param _AirDropWallet airdrop address.
     * @param _amount token to send.
     * @return bool 
     */
    function transferFromIAirDrop( address _owner, address _AirDropWallet, uint _amount) public onlyAuth returns (bool) {
        require(AirDropWallets[_AirDropWallet]._isExist, "AirDrop :: invalid _IAirDrop");
        require(DXB.balanceOf(_owner) >= _amount, "AirDrop :: insufficient balance");
        require(DXB.allowance(_owner, address(this)) >= _amount, "AirDrop :: insufficient allowance");
        
        DXB.transferFrom(_owner, address(this), _amount);
        AirDropWallets[_AirDropWallet]._balances = AirDropWallets[_AirDropWallet]._balances.add(_amount);
        
        return true;
    }
    
    /** 
     * @dev Calls getReward() function to receive rewards from reward pool.
     * @return bool 
     */
    function getReward() public returns (bool) {
        require((AirDropWallets[_msgSender()]._isExist) || (_msgSender() == owner()), "IAirDrop :: getReward : Invalid IW or onwer");
        if(( RewardPool(_RewardPool).viewClaimReward(address(this)) == 0) && (AirDropWallets[_msgSender()]._pendingReward == 0)) { return false; }
        
        address _contract = address(this);
        
        uint _bfBalance = _contract.balance;
        
        RewardPool(_RewardPool).withdrawReward();
        
        uint _newBalance = _contract.balance.sub(_bfBalance);
        
        if(_newBalance > 0){
            uint currentSharePerBlok = getBNBValuePerShare(_newBalance);
            for(uint i=0;i<AirDropList.length;i++){
                uint rewardBNB = currentSharePerBlok.mul(AirDropWallets[AirDropList[i]]._balances).div(1e12);
                AirDropWallets[AirDropList[i]]._pendingReward = AirDropWallets[AirDropList[i]]._pendingReward.add(rewardBNB.div(1e18));
            }
        }
        
        if((AirDropWallets[_msgSender()]._pendingReward > 0) && (_msgSender() != owner())){
            uint _reward = AirDropWallets[_msgSender()]._pendingReward;
            AirDropWallets[_msgSender()]._pendingReward = 0;
            payable(_msgSender()).transfer(_reward);
            emit rewardClaimed( _msgSender(), _reward);
        }
        
        return true;
    }
    
    /** 
     * @dev Calls distributeWallet() function to distribute tokens to others.
     * @return bool 
    */
    function distributeWallet() public returns (bool) {
        require((AirDropWallets[_msgSender()]._isExist));
        require((startTime != 0) && (startTime.add(lockPeriod) < block.timestamp), "IAirDrop :: distributeTeamWallet : Requires 180 days to pass");
        require(IERC20(DXB).balanceOf(address(this)) >= AirDropWallets[_msgSender()]._balances, "IAirDrop :: distributeTeamWallet : insufficient balance to distribute");
        
        _safeTransfer(_msgSender(), AirDropWallets[_msgSender()]._balances);
        AirDropWallets[_msgSender()]._balances = 0;
        
        return true;
    }
    
    /** 
     * @dev Calls viewAirDropReward() function to view rewards.
     * @param _AirDropWallet airdrop wallet address to view rewards.
     * @return uint 
     */
    function viewAirDropReward( address _AirDropWallet) public view returns (uint) {
        uint _contractReward =  RewardPool(_RewardPool).viewClaimReward(address(this));
        if((DXB.balanceOf(address(this)) == 0)) { return 0;}
        uint currentSharePerBlok = getBNBValuePerShare(_contractReward);
        uint rewardBNB = (currentSharePerBlok.mul(AirDropWallets[_AirDropWallet]._balances).div(1e12)).div(1e18);
        rewardBNB = rewardBNB.add(AirDropWallets[_AirDropWallet]._pendingReward);
        
        return rewardBNB;
    }
    
    /** 
     * @dev Calls getBNBValuePerShare() function to view tokens per share.
     * @param amount BNB rewards.
     * @return uint rewards per share
     */
    function getBNBValuePerShare( uint amount) private view returns (uint) {
        return (amount.mul(1e12)).mul(1e18).div(DXB.balanceOf(address(this)));
    }
    
    /** 
     * @dev Calls _safeTransfer() function to send bnb to airdrop wallets.
     * @param _sender sender address.
     * @param _amount BNB to send.
     * @return uint rewards per share
     */
    function _safeTransfer( address _sender, uint _amount) private returns (bool) {
        DXB.transfer( _sender, _amount);
        emit airdropWalletDiv( _sender, _amount);
        return true;
    }
    
}