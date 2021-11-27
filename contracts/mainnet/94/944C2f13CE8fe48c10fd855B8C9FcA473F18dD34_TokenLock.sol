/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol



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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol



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

// File: contracts\TokenLock.sol


pragma solidity ^0.8.0;



contract TokenLock is Ownable {

    event BeneficiaryUpdated(address account);

    event ReleaseInfoCreated(uint256 time, uint256 amount);
    event ReleaseInfoUpdated(uint256 time, uint256 amount);
    event Released(address account, uint256 amount, uint256 indexFrom, uint256 indexTo);

    struct ReleaseInfo {
        uint128 time;
        uint128 amount;
    }

    IERC20 private _token;

    address private _beneficiary;

    uint256 private _releaseIndex;

    uint256 private _totalReleases;

    mapping(uint256 => ReleaseInfo) private _releases; 

    /**
     * @dev Constructor
     */
    constructor(address token, address beneficiary)
    {
        _token = IERC20(token);

        _beneficiary = beneficiary;
    }

    /**
     * @dev Updates beneficiary address
     */
    function updateBeneficiary(address account)
        external
        onlyOwner
    {
        require(account != address(0), "TokenLock: address is invalid");

        _beneficiary = account;

        emit BeneficiaryUpdated(account);
    }

    /**
     * @dev Returns smart contract information
     */
    function getContractInfo()
        external
        view
        returns (address, address, uint256, uint256, uint256)
    {
        return (address(_token), _beneficiary, _totalReleases, _token.balanceOf(address(this)), _releaseIndex);
    }

    /**
     * @dev Creates release information
     */
    function createReleaseInfo(uint128[] memory times, uint128[] memory amounts)
        external
        onlyOwner
    {
        uint256 length = times.length;

        require(length == amounts.length, "TokenLock: array length is invalid");

        uint256 index = _totalReleases;

        uint128 lastTime = index == 0 ? 0 : _releases[index - 1].time;

        for (uint256 i = 0; i < length; i++) {
            uint128 time = times[i];
            uint128 amount = amounts[i];

            require(lastTime < time, "TokenLock: time is invalid");

            _releases[index++] = ReleaseInfo(time, amount);

            lastTime = time;

            emit ReleaseInfoCreated(time, amount);
        }

        if (_totalReleases != index) {
            _totalReleases = index;
        }
    }

    // /**
    //  * @dev Updates release information
    //  */
    // function updateReleaseInfo(uint128 index, uint128 time, uint128 amount)
    //     external
    //     onlyOwner
    // {
    //     require(index >= _releaseIndex, "TokenLock: index is invalid");

    //     ReleaseInfo storage info = _releases[index];

    //     require(info.time > 0, "TokenLock: info does not exist");

    //     uint128 prevTime = index > 0 ? _releases[index - 1].time : 0;

    //     uint128 nextTime = index == _totalReleases - 1 ? type(uint128).max : _releases[index + 1].time;

    //     require(time > prevTime && time < nextTime, "TokenLock: time is invalid");

    //     info.time = time;
    //     info.amount = amount;

    //     emit ReleaseInfoUpdated(time, amount);
    // }

    /**
     * @dev Returns release information
     */
    function getReleaseInfo(uint256 indexFrom, uint256 indexTo)
        external
        view
        returns (ReleaseInfo[] memory)
    {
        uint256 cnt = 0;
        uint256 size = indexTo - indexFrom + 1;

        ReleaseInfo[] memory tmps = new ReleaseInfo[](size);

        for (uint256 i = indexFrom; i <= indexTo; i++) {
            if (_releases[i].time == 0) {
                break;
            }

            tmps[cnt++] = _releases[i];
        }

        ReleaseInfo[] memory releases = new ReleaseInfo[](cnt);

        for (uint256 i = 0; i < cnt; i++) {
            releases[i] = tmps[i];
        }

        return releases;
    }

    /**
     * @dev Returns release balance
     */
    function getReleaseBalance()
        public
        view
        returns (uint256, uint256, uint256)
    {
        uint256 balance;
        uint256 length = _totalReleases;
        uint256 currentTime = block.timestamp;
        uint256 indexFrom = _releaseIndex;
        uint256 indexTo = indexFrom;

        for (uint256 i = indexFrom; i < length; i++) {
            ReleaseInfo memory info = _releases[i];

            if (currentTime < info.time) {
                break;
            }

            balance += info.amount;
            indexTo++;
        }

        return (indexFrom, indexTo, balance);
    }

    /**
     * @dev Releases token
     */
    function release()
        external
    {
        (uint256 indexFrom, uint256 indexTo, uint256 balance) = getReleaseBalance();

        require(indexTo > indexFrom, "TokenLock: can not release");

        _releaseIndex = indexTo;

        if (balance > 0) {
            _token.transfer(_beneficiary, balance);
        }

        emit Released(_beneficiary, balance, indexFrom, indexTo);
    }

}