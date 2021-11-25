/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

// File: contracts/IBEP20.sol



pragma solidity ^0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// File: contracts/Vesting.sol



pragma solidity ^0.8.4;



contract Vesting is Ownable {

    mapping(address => uint256) public vestedAmount;
    mapping(address => uint256) public claimedAmount;

    uint256 public start;
    uint256 public end;
    IBEP20 public token;
    uint256 public duration;
    uint256 public unlockPercentsOnStart;

    event NewVesting(address indexed investor, uint256 amount);
    event Claimed(address indexed investor, uint256 amount, uint256 left);

    constructor() {
    }

    function init(uint256 _start, uint256 _end, uint256 _unlockPercentsOnStart, IBEP20 _token) external onlyOwner {
        require(_end > _start, "EGS");
        require(_unlockPercentsOnStart < 10000, "PTH");

        start = _start;
        end = _end;
        token = _token;
        duration = _end - _start;
        unlockPercentsOnStart = _unlockPercentsOnStart;
    }

    function addInvestors(address[] memory investors, uint256[] memory amounts) external onlyOwner {
        uint256 totalAmount = 0;
        uint256 length = investors.length;
        require(amounts.length == length, "ICL");

        for (uint256 i = 0; i < length; i++) {
            vestedAmount[investors[i]] += amounts[i];
            totalAmount += amounts[i];
            emit NewVesting(investors[i], amounts[i]);
        }

        token.transferFrom(msg.sender, address(this), totalAmount);
    }

    function addInvestor(address investor, uint256 amount) external onlyOwner {
        vestedAmount[investor] += amount;
        token.transferFrom(msg.sender, address(this), amount);
        emit NewVesting(investor, amount);
    }

    function claim() external {
        address investor = msg.sender;
        claimFor(investor);
    }

    function claimFor(address investor) public {
        uint256 claimable = claimableAmount(investor);
        uint256 totalUnclaimed = vestedAmount[investor] - claimedAmount[investor];

        claimedAmount[investor] += claimable;
        emit Claimed(investor, claimedAmount[investor], totalUnclaimed-claimable);

        token.transfer(investor, claimable);
    }

    function claimableAmount(address investor) public view returns (uint256) {
        return _vestedAmount(investor) - claimedAmount[investor];
    }

    function _vestedAmount(address investor) private view returns (uint256) {
        uint256 _vested = vestedAmount[investor];
        uint256 unlockAtStart = _vested * unlockPercentsOnStart / 10000;

        if (block.timestamp < start) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return _vested;
        } else {
            return unlockAtStart + ((_vested - unlockAtStart) * (block.timestamp - start) / duration);
        }
    }
}