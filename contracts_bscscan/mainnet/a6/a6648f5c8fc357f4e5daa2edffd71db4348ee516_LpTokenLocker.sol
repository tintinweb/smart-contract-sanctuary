/**
 *Submitted for verification at BscScan.com on 2021-08-13
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

// File: node_modules\@myContracts\contracts\lpLocker\lpLocker.sol


pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address owner, address to, uint value) external returns (bool);
}

contract LpLocker is Ownable {
    uint256 public currentTimestamp;

    struct LP {
        bool exists;
        uint256 amount;
        uint256 lockTime;
        uint256 unlockTime;
    }

    mapping(address => mapping(address => LP)) public lpBox;    // [pairAddress] => [owner] => LP
    mapping(address => bool) public lpExists;
    address[] public lpList;

    event LPLockEd(address owner, address pairAddress, uint256 amount, uint256 second);
    event LPWithdrawEd(address owner, address pairAddress, uint256 amount);

    constructor() {currentTimestamp = block.timestamp;}
    function refreshCurrentTimestamp() public {currentTimestamp = block.timestamp;}

    function lpListLength() public view returns(uint256) {return lpList.length;}

    function lockLP(address pairAddress, uint256 lpAmount, uint256 second) public {
        require(lpAmount > 0, "LP amount need greater than zero");
        require(second > 0, "Time amount need greater than zero");

        _beforeLpLock();

        if (!lpExists[pairAddress]) {
            lpExists[pairAddress] = true;
            lpList.push(pairAddress);
        }

        IERC20(pairAddress).transferFrom(msg.sender, address(this), lpAmount);

        lpBox[pairAddress][msg.sender].exists = true;
        lpBox[pairAddress][msg.sender].amount += lpAmount;
        lpBox[pairAddress][msg.sender].lockTime = block.timestamp;
        lpBox[pairAddress][msg.sender].unlockTime = block.timestamp + second;

        emit LPLockEd(msg.sender, pairAddress, lpAmount, second);
    }

    function withdrawLP(address pairAddress) public {
        require(lpBox[pairAddress][msg.sender].exists, "You don't have LPLockEd yet");

        _beforeLpWithdraw();

        LP memory lp = lpBox[pairAddress][msg.sender];
        require(block.timestamp > lp.unlockTime, "Time not finished");

        IERC20(pairAddress).transfer(msg.sender, lp.amount);

        emit LPWithdrawEd(msg.sender, pairAddress, lp.amount);
    }

    function getLPDuration(address pairAddress, address walletAddress) public view returns (uint256) {
        uint256 unlockTime = lpBox[pairAddress][walletAddress].unlockTime;
        return (unlockTime <= block.timestamp) ? 0 : unlockTime - block.timestamp;
    }

    function _beforeLpLock() internal virtual {}

    function _beforeLpWithdraw() internal virtual {}
    function rescueLossToken(IERC20 token_, address _recipient) public onlyOwner {token_.transfer(_recipient, token_.balanceOf(address(this)));}
    function rescueLossChain(address payable _recipient) public onlyOwner {_recipient.transfer(address(this).balance);}
}

// File: @myContracts\contracts\lpLocker\fee\lpLockerWithFee.sol


pragma solidity ^0.8.0;



contract lpLockerWithFee is LpLocker {
    address public TOKEN;
    uint256 public feeAmount;
    address public wallet;

    event ReceivedFee(address from, uint256 amount);
    constructor() {
//        updateFeeInfo(_token, 0, address(this));
    }
    function updateFeeInfo(address _token, uint256 amount, address feeTo) public onlyOwner {
        TOKEN = _token;
        feeAmount = amount;
        wallet = feeTo;
    }

    function _beforeLpLock() internal virtual override {
        if (feeAmount > 0) {
            emit ReceivedFee(msg.sender, feeAmount);
            IERC20(TOKEN).transferFrom(msg.sender, wallet, feeAmount);
        }
    }
}

// File: @myContracts\contracts\token\TokenMeta.sol


pragma solidity ^0.8.0;

abstract contract TokenMeta {
    string public name;
    string public symbol;

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    function toWei(uint256 num_) public pure returns(uint256) {
        return num_ * 10**decimals();
    }
}

// File: contracts\example\lpLocker_demo.sol


pragma solidity ^0.8.0;



contract LpTokenLocker is lpLockerWithFee,TokenMeta {
    constructor() TokenMeta("LP Token LOCKER","LTL") {}
}