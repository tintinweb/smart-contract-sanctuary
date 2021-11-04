/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

// SPDX-License-Identifier: --🦉--

//File Context.sol
pragma solidity =0.7.6;

contract Context {

    /**
     * @dev returns address executing the method
     */
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    /**
     * @dev returns data passed into the method
     */
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

//File SafeMath.sol

pragma solidity =0.7.6;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

//File SafeMath8.sol
pragma solidity =0.7.6;

library SafeMath8 {

    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b <= a);
        uint8 c = a - b;
        return c;
    }

    function mul(uint8 a, uint8 b) internal pure returns (uint8) {

        if (a == 0) {
            return 0;
        }

        uint8 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b > 0);
        uint8 c = a / b;
        return c;
    }

    function mod(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b != 0);
        return a % b;
    }
}

//File Events.sol
pragma solidity =0.7.6;

contract Events {

    event Withdraw_Reward (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Ido (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Marketing (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Advisor (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Team (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Strategic (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Private_sale (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );
    
    event Reward(
        address indexed to,
        uint256 value
    );

    event Claim(
        address indexed to,
        uint256 value
    );

    event Lock(
        address indexed from,
        uint256 value
    );

    event UnLock(
        address indexed from
    );
}

//File IERC20.sol
pragma solidity =0.7.6;

interface IERC20 {
    function decimals() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//File Ownable.sol
pragma solidity =0.7.6;
 /**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
  address internal _owner;

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

//File GameReward.sol
pragma solidity =0.7.6;

contract GameReward is Ownable, Events {
    using SafeMath for uint256;
    using SafeMath8 for uint8;
    
    address public qdropToken;

    uint256 constant public  unlockTaxPercentage = 5;
    address public lockAddress = 0x0DC2F71bc86bD691Cc267Beb42889b7b3a11c76e;
    address public qdropRewardAddress = 0xd7D11Ce20eA022A3f8bC4D33F58FB1b5341924D4;
    struct DataReward {
        uint lastTimeStamp;
        uint256 totalRewards;
    }

    struct DataLock{
        bool locked;
        uint8 membership;
        uint lastLockTimeStamp;
    }

    mapping (address => DataReward) private _rewards;
    mapping (address => DataLock) private _locks;

    constructor (address _qdropToken) {
        qdropToken = _qdropToken;
    }
    
    function UpdateRewardAddress(address _newAddress) public returns(bool){
       qdropRewardAddress = _newAddress;
       return true;
    }

    function UpdateLockAddress(address _newAddress) public returns(bool){
       lockAddress = _newAddress;
       return true;
    }

    function claim(address _to, uint256 amount) public returns(bool){
        DataReward memory _reward = _rewards[_to];
        require(_to != address(0x0));
        uint256 balance = IERC20(qdropToken).balanceOf(qdropRewardAddress);
        require(_reward.totalRewards != 0 && _reward.totalRewards <= balance, "No available funds.");
        _rewards[_to].totalRewards = _rewards[_to].totalRewards.sub(amount);

        uint256 allowance = IERC20(qdropToken).allowance(address(this), _to);
        if(_reward.lastTimeStamp + 7 days > block.timestamp)
            amount = amount.sub(amount.mul(unlockTaxPercentage).div(100));

        _rewards[_to].lastTimeStamp = block.timestamp;
        IERC20(qdropToken).approve(qdropRewardAddress, allowance + amount);
        IERC20(qdropToken).transferFrom(qdropRewardAddress, _to, amount);

        emit Claim(
            _to,
            amount
        );
        return true;
    }

    function addReward(address _to, uint256 amount) public onlyOwner {
        require(_to != address(0x0));
        uint256 balance = IERC20(qdropToken).balanceOf(qdropRewardAddress);
        uint256 allowance = IERC20(qdropToken).allowance(address(this), _to);
        require(amount <= balance, "No available funds.");
        require(IERC20(qdropToken).approve(_to, allowance + amount), "Appove function does not work");
        _rewards[_to].totalRewards += amount;

        emit Reward(
            _to,
            amount
        );
    }

    function lock(address _from, uint256 amount) public returns(bool){
        require(_from != address(0x0) && !_locks[_from].locked, "Already Locked or 0x00 address");
        
        require(amount == 2*10**18 || amount == 4*10**18 || amount == 6*10**18 || amount == 8*10**18 || amount == 10*10**18, "Invalid Amount");
  
        _locks[_from].locked = true;
        _locks[_from].membership = uint8(amount.div(1 ether).div(2));
        _locks[_from].lastLockTimeStamp = block.timestamp;

        //uint256 allowance = IERC20(qdropToken).allowance(address(this), _from);
        //IERC20(qdropToken).approve(_from, allowance + amount);
        IERC20(qdropToken).transferFrom(_from, lockAddress, amount);

        emit Lock(
            _from,
            amount
        );
        return true;
    }

    function unlock(address _to) public returns(bool){
        DataLock memory _lock = _locks[_to];
        uint256 amount = uint256(_lock.membership).mul(1 ether).mul(2);
        uint256 tax;
        
        require(_to != address(0x0) && _lock.locked,"Wrong address or not locked");

        if(_lock.lastLockTimeStamp + 7 days > block.timestamp){
            tax = amount.mul(unlockTaxPercentage).div(100);
        }

        _locks[_to].locked = false;

        uint256 allowance = IERC20(qdropToken).allowance(address(this), _to);
        IERC20(qdropToken).approve(_to, allowance + amount.sub(tax));
        IERC20(qdropToken).transferFrom(lockAddress, _to, amount.sub(tax));

        if(tax != 0){
            uint256 Reward_allowance = IERC20(qdropToken).allowance(address(this), qdropRewardAddress);
            IERC20(qdropToken).approve(qdropRewardAddress, Reward_allowance + tax); //
            IERC20(qdropToken).transferFrom(lockAddress, qdropRewardAddress, tax);
        }

        emit UnLock(
            _to
        );

        return true;
    }

    function reward(address _to) public view returns (uint256, uint, address, address) {
        DataReward memory _reward = _rewards[_to];
        return (_reward.totalRewards, _reward.lastTimeStamp, msg.sender, qdropRewardAddress);
    }

    function checkLock(address _from) public view returns(bool, uint8, uint256){
        return (_locks[_from].locked, _locks[_from].membership, _locks[_from].lastLockTimeStamp);
    }
}