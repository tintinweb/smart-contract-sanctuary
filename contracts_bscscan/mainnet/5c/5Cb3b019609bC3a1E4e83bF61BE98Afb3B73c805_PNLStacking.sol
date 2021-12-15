//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract PNLStacking is Ownable {
    event Stacked(uint256 id, uint256 PNLamount, uint256 PNLgAmount, address User);

    struct StackEntry {
        uint256 PNLamount;
        uint256 stackedAt;
        uint256 StackingTypeID;
        bool withdrawn;
    }

    struct StackingType {
        uint256 duration;
        uint256 apy;
        uint256 bonusMultiplier;
    }

    StackingType[] public stackingTypes;

    mapping(address => uint256) private _stackesCount;
    mapping(uint256 => address) private _stackOwners;

    mapping(address => StackEntry[]) public stackingData;

    IERC20 public PNL;
    uint256 public stackedAmount;
    uint256 public paidAmount;

    uint256 public stackingID;

    uint256 internal _multiplierDivider = 10;
    uint256 internal _apyDivider = 1000;

    uint256 internal _minStackAmount = 1000 ether;

    constructor(address _pnlAddress) {
        stackingTypes.push(StackingType(91 days, 20, 10));
        stackingTypes.push(StackingType(182 days, 30, 15));
        stackingTypes.push(StackingType(365 days, 40, 20));
        stackingTypes.push(StackingType(730 days, 60, 30));

        PNL = IERC20(_pnlAddress);
    }

    function getStackingOptionInfo(uint256 id)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        StackingType memory stackingType = stackingTypes[id];
        return (stackingType.duration, stackingType.apy, stackingType.bonusMultiplier);
    }

    function calculateAPY(
        uint256 amount,
        uint256 apy,
        uint256 duration
    ) public view returns (uint256) {
        return (((amount * apy)) * duration) / _apyDivider / 365 days;
    }

    function setMinStackAmount(uint256 amnt) external onlyOwner {
        _minStackAmount = amnt;
    }

    function stack(uint256 PNLAmount, uint256 StackingTypeID) external {
        require(StackingTypeID < stackingTypes.length, "Stacking type isnt found");
        require(PNLAmount >= _minStackAmount, "You cant stack that few tokens");
        (uint256 duration, , uint256 bonusMultiplier) = getStackingOptionInfo(StackingTypeID);
        uint256 PNLgAmount = ((((PNLAmount * duration) / 1 days)) * bonusMultiplier) / _multiplierDivider / 1 ether;
        PNL.transferFrom(msg.sender, address(this), PNLAmount);

        stackingID++;

        stackingData[msg.sender].push(StackEntry(PNLAmount, block.timestamp, StackingTypeID, false));
        _stackesCount[msg.sender] += 1;
        _stackOwners[stackingID] = msg.sender;
        stackedAmount += PNLAmount;

        emit Stacked(stackingID, PNLAmount, PNLgAmount, msg.sender);
    }

    function unstack(uint256 id) external {
        require(id < getStackesCount(msg.sender), "Stacking data isnt found");
        StackEntry storage stacking = stackingData[msg.sender][id];

        (uint256 duration, uint256 apy, ) = getStackingOptionInfo(stacking.StackingTypeID);

        require(!stacking.withdrawn, "Already withdrawn");
        require(block.timestamp > stacking.stackedAt + duration, "Too early to withdraw");

        stacking.withdrawn = true;
        uint256 withdrawAmnt = stacking.PNLamount + calculateAPY(stacking.PNLamount, apy, duration);

        PNL.transfer(msg.sender, withdrawAmnt);
        paidAmount += withdrawAmnt;
        stackedAmount -= stacking.PNLamount;
    }

    function getStackesCount(address user) public view returns (uint256) {
        return _stackesCount[user];
    }

    function getStackOwner(uint256 ID) public view returns (address) {
        return _stackOwners[ID];
    }

    function emergencyWithdrawn() external onlyOwner {
        PNL.transfer(msg.sender, PNL.balanceOf(address(this)));
    }

    function emergencyWithdrawnValue() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
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