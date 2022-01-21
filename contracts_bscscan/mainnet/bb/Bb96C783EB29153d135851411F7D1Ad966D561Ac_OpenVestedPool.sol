//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./OpenPool.sol";

contract OpenVestedPool is OpenPool {
    uint256 public unlockPeriod;
    uint256 public totalUnlock;
    uint256 public cliff;
    uint256 public afterPurchaseCliff;

    uint256 public initialUnlock;
    uint256 public unlockPerPeriod;

    uint256 public constant ONE_HUNDRED_PERCENT = 1e18 * 100;

    event Claimed(address who, uint256 tokens);

    constructor(
        address _paymentToken,
        address _poolToken,
        uint256 _startDate,
        uint256 _closeDate,
        uint256 _goal,
        uint256 _initialUnlock,
        uint256 _unlockPeriod,
        uint256 _totalUnlock,
        uint256 _cliff,
        uint256 _afterPurchaseCliff,
        uint256 _unlockPerPeriod
    ) OpenPool(_paymentToken, _poolToken, _startDate, _closeDate, _goal) {
        poolType = PoolTypes.Vested;

        initialUnlock = _initialUnlock;
        unlockPeriod = _unlockPeriod;
        totalUnlock = _totalUnlock;
        cliff = _cliff;
        afterPurchaseCliff = _afterPurchaseCliff;
        unlockPerPeriod = _unlockPerPeriod;
    }

    function canClaim(address user) public view returns (bool) {
        return (getClaimableTokens(user) > 0);
    }

    function getClaimableTokens(address user) public view returns (uint256) {
        if (block.timestamp < (startDate + afterPurchaseCliff) || !hasBought(user)) return 0;

        uint256 tokensToClaimAfterPurchase = (allocations[user].amount * initialUnlock) / ONE_HUNDRED_PERCENT;
        uint256 tokenstToClaimPerPeriod = (allocations[user].amount * unlockPerPeriod) / ONE_HUNDRED_PERCENT;
        uint256 claimed = allocations[user].claimed;
        uint256 amount = allocations[user].amount;
        if (block.timestamp >= totalUnlock + startDate + cliff || claimed + tokenstToClaimPerPeriod > amount) return amount - claimed;

        if (claimed == 0) {
            uint256 claimable = tokensToClaimAfterPurchase;
            return claimable;
        } else {
            if (block.timestamp < startDate + afterPurchaseCliff + cliff) return 0;
            uint256 claimable = (((block.timestamp - startDate - afterPurchaseCliff - cliff) / unlockPeriod)) * tokenstToClaimPerPeriod + tokensToClaimAfterPurchase - claimed;
            if (claimable > amount - claimed) return amount - claimable;

            return claimable;
        }
    }

    function buy() public override(OpenPool) {
        super.buy();

        if (afterPurchaseCliff == 0) {
            uint256 tokensToClaimAfterPurchase = (allocations[msg.sender].amount * initialUnlock) / ONE_HUNDRED_PERCENT;
            allocations[msg.sender].claimed = tokensToClaimAfterPurchase;
            allocations[msg.sender].claimedAt = block.timestamp;
            poolToken.transfer(msg.sender, tokensToClaimAfterPurchase);
            emit Claimed(msg.sender, tokensToClaimAfterPurchase);
        }
    }

    function claim() public {
        uint256 claimable = getClaimableTokens(msg.sender);
        require(claimable > 0, "Nothing to claim");

        allocations[msg.sender].claimed += claimable;
        allocations[msg.sender].claimedAt = block.timestamp;
        poolToken.transfer(msg.sender, claimable);

        emit Claimed(msg.sender, claimable);
    }

    function finishedClaiming(address user) external view returns (bool) {
        return (allocations[user].claimed == allocations[user].amount);
    }

    function nextClaimingAt(address wallet) public view returns (uint256) {
        if (canClaim(wallet) || !hasBought(wallet)) return 0;
        if (allocations[wallet].claimed == 0) {
            return startDate + afterPurchaseCliff;
        } else {
            if (block.timestamp - startDate < afterPurchaseCliff) return startDate + afterPurchaseCliff;
            if (block.timestamp - startDate - afterPurchaseCliff < cliff) return startDate + afterPurchaseCliff + cliff + unlockPeriod;
            uint256 periodsPassed = (block.timestamp - startDate - cliff - afterPurchaseCliff) / unlockPeriod;
            return startDate + afterPurchaseCliff + cliff + unlockPeriod * (periodsPassed + 1);
        }
    }

    function remained(address wallet) public view returns (uint256) {
        return allocations[wallet].amount - allocations[wallet].claimed;
    }

    function batchSetBuyData(
        address[] calldata _recepients,
        uint256[] calldata _amounts,
        uint256[] calldata _claimed,
        uint256[] calldata _claimedAt,
        uint256 _rate
    ) external onlyOwner {
        uint256 _tokensSold;
        uint256 _paymentsReceived;
        for (uint32 i = 0; i < _recepients.length; i++) {
            allocations[_recepients[i]].amount = _amounts[i];
            allocations[_recepients[i]].claimed = _claimed[i];
            allocations[_recepients[i]].claimedAt = _claimedAt[i];
            allocations[_recepients[i]].rate = _rate;
            allocations[_recepients[i]].bought = true;

            _tokensSold += _amounts[i];
            _paymentsReceived += (_amounts[i] * _rate) / _divider;
        }
        paymentsReceived = _paymentsReceived;
        tokensSold = _tokensSold;
    }

    function claimingInfo(address wallet)
        external
        view
        returns (
            uint256 allocation,
            uint256 claimed,
            uint256 remainedToClaim,
            uint256 available,
            bool _canClaim,
            uint256 _nextClaimingAt
        )
    {
        return (allocations[wallet].amount, allocations[wallet].claimed, remained(wallet), getClaimableTokens(wallet), canClaim(wallet), nextClaimingAt(wallet));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

abstract contract OpenPool is Ownable {
    enum PoolTypes {
        Regular,
        Vested
    }

    uint256 public ticketSize = 25000 * 1e18;
    uint256 public rate = 1000;

    PoolTypes public poolType;

    struct Allocation {
        uint256 amount;
        bool bought;
        uint256 claimed;
        uint256 rate;
        uint256 claimedAt;
    }
    mapping(address => Allocation) public allocations;

    IERC20 public paymentToken;
    IERC20 public poolToken;
    address _receiver = 0x2983cF6AEc2165BBd314252fE2Ab2aC1671e592D;

    uint256 public startDate;
    uint256 public closeDate;

    uint256 public paymentsReceived;
    uint256 public goal;
    uint256 public tokensSold;

    uint256 internal _divider = 100000;

    event TokensBought(address participant, uint256 amount, uint256 spent);

    function saleActive() public view returns (bool) {
        return (block.timestamp >= startDate && block.timestamp <= closeDate);
    }

    function canBuy(address wallet) public view returns (bool) {
        if (!saleActive()) return false;
        if (allocations[wallet].bought == true) return false;
        return true;
    }

    function hasBought(address wallet) public view returns (bool) {
        return (allocations[wallet].bought);
    }

    function isVested() external view returns (bool) {
        return poolType == PoolTypes.Vested;
    }

    function buy() public virtual {
        require(saleActive(), "The sale is not active");
        require(canBuy(msg.sender), "You cant buy tokens");
        require(!hasBought(msg.sender), "Youve already bought tokens");
        require(paymentsReceived <= goal, "Sale goal reached");

        uint256 amount = ticketSize;
        uint256 paymentToReceive = (amount * rate) / _divider;

        require(paymentToken.allowance(msg.sender, address(this)) >= paymentToReceive, "Payment token wasnt approved");

        allocations[msg.sender].rate = rate;
        allocations[msg.sender].amount = ticketSize;
        allocations[msg.sender].bought = true;

        paymentToken.transferFrom(msg.sender, _receiver, paymentToReceive);

        tokensSold += amount;
        paymentsReceived += paymentToReceive;

        emit TokensBought(msg.sender, amount, paymentToReceive);
    }

    constructor(
        address _paymentToken,
        address _poolToken,
        uint256 _startDate,
        uint256 _closeDate,
        uint256 _goal
    ) {
        require(_startDate < _closeDate, "Wrong dates");

        goal = _goal;
        paymentToken = IERC20(_paymentToken);
        poolToken = IERC20(_poolToken);
        startDate = _startDate;
        closeDate = _closeDate;
    }

    function setGoal(uint256 _goal) external onlyOwner {
        goal = _goal;
    }

    function setSaleDates(uint256 _startDate, uint256 _closeDate) external onlyOwner {
        require(startDate < closeDate && startDate != 0 && closeDate != 0, "Wrong dates");
        startDate = _startDate;
        closeDate = _closeDate;
    }

    function setPoolTokens(address _paymentToken, address _poolToken) external onlyOwner {
        paymentToken = IERC20(_paymentToken);
        poolToken = IERC20(_poolToken);
    }

    function setAllocation(
        address _to,
        uint256 _amount,
        uint256 _rate
    ) external onlyOwner {
        allocations[_to].amount = _amount;
        allocations[_to].claimed = 0;
        allocations[_to].rate = _rate;
        allocations[_to].bought = false;
    }

    function batchSetAllocations(
        address[] calldata _recepients,
        uint256[] calldata _amounts,
        uint256 _rate
    ) external onlyOwner {
        for (uint32 i = 0; i < _recepients.length; i++) {
            allocations[_recepients[i]].amount = _amounts[i];
            allocations[_recepients[i]].claimed = 0;
            allocations[_recepients[i]].rate = _rate;
            allocations[_recepients[i]].bought = false;
        }
    }

    function extractPaymentToken() external onlyOwner {
        paymentToken.transfer(msg.sender, paymentToken.balanceOf(address(this)));
    }

    function extractPoolToken() external onlyOwner {
        poolToken.transfer(msg.sender, poolToken.balanceOf(address(this)));
    }

    function extractBNB() external onlyOwner {
        msg.sender.call{value: address(this).balance}("");
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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