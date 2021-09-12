/**
 *Submitted for verification at BscScan.com on 2021-09-12
*/

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: rexstaker.sol

pragma solidity ^0.8.7;


 
interface IStaking{
    function createStake(uint256 _stakedAmount,uint32 _stakingDays,string calldata _description) external returns (bytes16, uint32);
    function moveStake(bytes16 _stakeID, address _toAddress) external;
}

contract TokenReceiver is Ownable{
    
    mapping(address => bool) deservesRex;
    mapping(address => uint256) claimedRex;
    uint256 private maxClaim = 0;

    uint256 private HOLDER_COUNT=0;

    address private REX_address = 0x5E0B09b04d6990E76DFE9BF84552a940FD0BE05E;
    address private M_REX_address = 0x76837D56D1105bb493CDDbEFeDDf136e7c34f0c4;
    address private T_REX_address = 0x69D4D2B858B3cBDDA3f365A5CE9566eAFB043D9c;
    address private BURN_address = 0x000000000000000000000000000000000000dEaD;
    address private DEV_address = 0x3AaFb23B9c90250816A37E2574A4C4F4E719B82C;
    
    IERC20 REX = IERC20(REX_address);
    IERC20 MREX = IERC20(M_REX_address);
    IERC20 TREX = IERC20(T_REX_address);
    
    function hasTREX(address account) public view returns (uint256) {
        return TREX.balanceOf(account);
    }
    
    function claimableREX(address account) public view returns (uint256){
        return (maxClaim/HOLDER_COUNT) - claimedRex[account];
    }
    
    
    function holdersTREX() public view returns (uint256){
        return HOLDER_COUNT;
    }
    
    function rexClaimed(address account) public view returns (uint256){
        return claimedRex[account];
    }

    function inSnapshot(address account) public view returns (bool){
        return deservesRex[account];
    }    
    

    //In case something goes wrong before renouncing
    
    function withdrawRex() onlyOwner external {
        uint256 b = REX.balanceOf(address(this));
        REX.transfer(owner(),b);
    }
    
    function withdrawMRex() onlyOwner external {
        MREX.transfer(owner(),1);
    }
    
    function withdrawTRex() onlyOwner external {
        TREX.transfer(owner(),1);
    }
    
    //Find other way to get this information. I don't think it's possible
    
    function setSnapshot(address[] calldata _T_REX_Snapshot) onlyOwner external {
            for (uint i=0; i<_T_REX_Snapshot.length; i++) {
                deservesRex[_T_REX_Snapshot[i]] = true;
            }
             HOLDER_COUNT += _T_REX_Snapshot.length;
    }
    
    
    function devClaim() external{
         address from = msg.sender;
         require(DEV_address == from, "Only dev can claim this");
         
         uint256 rexReward = maxClaim - claimedRex[from];
         REX.transfer(DEV_address, rexReward);
         claimedRex[from] = maxClaim;
    }
    
    function trexClaim() external{
         address from = msg.sender;
         require(deservesRex[from]==true, "Not in snapshot");
         require(TREX.balanceOf(from)>0,"No TREX");
         
         uint256 rexReward = (maxClaim/HOLDER_COUNT) - claimedRex[from];
         REX.transfer(from, rexReward);
         claimedRex[from] += rexReward;
    }
    
    
    function stakeForMe(uint256 ammount,uint32 stakeDays) external {
        address from = msg.sender;
        
        REX.transferFrom(from, address(this), ammount);
        
        uint256 taxed = (ammount / 20) * 17;
        uint256 rewards = (ammount-taxed)/3;
        
        REX.transfer(BURN_address, rewards);
        maxClaim+=rewards; //Used it both devClaim and trexClaim
        
        (bytes16 stakeID,) = IStaking(REX_address).createStake(taxed,stakeDays,"no_name");
        IStaking(REX_address).moveStake(stakeID,from);
    }
}