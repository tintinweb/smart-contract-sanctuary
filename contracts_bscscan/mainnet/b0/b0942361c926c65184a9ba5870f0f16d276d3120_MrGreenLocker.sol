/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

/*
This is a universal TokenLocker, made by @MrGreenCrypto.

You can lock LP tokens, but also any kind of token that you wish to lock for whatever reason.

The contract is built to be trustless, so you don't have to trust me or anyone to use this TokenLocker with peace of mind.
There is no way for me, you or anyone else to withdraw tokens before the timer ends.

This will be deployed to https://mrgreencrypto.com/tokenlocker

Join the community here: https://t.me/mrgreengroup

If you use my TokenLocker to lock the LP for your project,
I might post it in my call channel for free:
https://t.me/mrgreencalls

If you want to talk to me directly, use this link: https://t.me/MrGreenCrypto

*/
pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

library EnumerableSet {
    struct Set {bytes32[] _values; mapping(bytes32 => uint256) _indexes;}
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastvalue;
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {return set._indexes[value] != 0;}
    function _length(Set storage set) private view returns (uint256) {return set._values.length;}
    function _at(Set storage set, uint256 index) private view returns (bytes32) {return set._values[index];}
    function _values(Set storage set) private view returns (bytes32[] memory) {return set._values;}
    struct Bytes32Set { Set _inner;}
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {return _add(set._inner, value);}
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {return _remove(set._inner, value);}
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {return _contains(set._inner, value);}
    function length(Bytes32Set storage set) internal view returns (uint256) {return _length(set._inner);}
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {return _at(set._inner, index);}
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {return _values(set._inner);}
    struct AddressSet {Set _inner;}
    function add(AddressSet storage set, address value) internal returns (bool) {return _add(set._inner, bytes32(uint256(uint160(value))));}
    function remove(AddressSet storage set, address value) internal returns (bool) {return _remove(set._inner, bytes32(uint256(uint160(value))));}
    function contains(AddressSet storage set, address value) internal view returns (bool) {return _contains(set._inner, bytes32(uint256(uint160(value))));}
    function length(AddressSet storage set) internal view returns (uint256) {return _length(set._inner);}
    function at(AddressSet storage set, uint256 index) internal view returns (address) {return address(uint160(uint256(_at(set._inner, index))));}
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;
        assembly {result := store}
        return result;
    }
    struct UintSet {Set _inner;}
    function add(UintSet storage set, uint256 value) internal returns (bool) {return _add(set._inner, bytes32(value));}
    function remove(UintSet storage set, uint256 value) internal returns (bool) {return _remove(set._inner, bytes32(value));}
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {return _contains(set._inner, bytes32(value));}
    function length(UintSet storage set) internal view returns (uint256) {return _length(set._inner);}
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {return uint256(_at(set._inner, index));}
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;
        assembly {result := store}
        return result;
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

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {return functionCall(target, data, "Address: low-level call failed");}
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {return functionCallWithValue(target, data, 0, errorMessage);}
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {return functionCallWithValue(target, data, value, "Address: low-level call with value failed");}
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {return functionStaticCall(target, data, "Address: low-level static call failed");}
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {return functionDelegateCall(target, data, "Address: low-level delegate call failed");}
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));}
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));}
    function safeApprove(IERC20 token, address spender, uint256 value ) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {_transferOwnership(_msgSender());}
    function owner() public view virtual returns (address) {return _owner;}
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {_transferOwnership(address(0));}
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {_status = _NOT_ENTERED;}
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender,uint amount0In,uint amount1In,uint amount0Out,uint amount1Out,address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

contract MrGreenLocker is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    IPancakeFactory public pancakeFactory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address payable public feeReceiver;

    struct TokenLock {
        address token;
        address owner;
        uint256 tokenAmount;
        uint256 unlockTime;
    }

    uint256 public lockNonce = 0;
    uint256 public bnbFeeForAnyLock = 0.05 ether;
    uint256 public bnbFeeForLpLock = 0.05 ether;
    uint256 public bnbFeeForIncrease = 0.01 ether;

    mapping(uint256 => TokenLock) public tokenLocks;

    mapping(address => EnumerableSet.UintSet) private userLocks;

    event OnTokenLock(
        uint256 indexed lockId,
        address indexed tokenAddress,
        address indexed owner,
        uint256 amount,
        uint256 unlockTime
    );
    event OnTokenUnlock(uint256 indexed lockId);
    event OnLockWithdrawal(uint256 indexed lockId, uint256 amount);
    event OnLockAmountIncreased(uint256 indexed lockId, uint256 amount);
    event OnLockDurationIncreased(uint256 indexed lockId, uint256 newUnlockTime);
    event OnLockOwnershipTransferred(uint256 indexed lockId, address indexed newOwner);

    modifier onlyLockOwner(uint lockId) {
        TokenLock storage lock = tokenLocks[lockId];
        require(lock.owner == address(msg.sender), "NO ACTIVE LOCK OR NOT OWNER");
        _;
    }

    constructor() {
        feeReceiver = payable(msg.sender);
        
    }

    /**
    * @notice locks pancake liquidity token or any token until specified time
    * @param token/anyToken token address to lock
    * @param amount amount of tokens to lock
    * @param unlockTime unix time in seconds after that tokens can be withdrawn
    * @param withdrawer account that can withdraw tokens to it's balance
    */
    function lockLPTokens(address token, uint256 amount, uint256 unlockTime, address payable withdrawer) external payable nonReentrant returns (uint256 lockId) {
        require(amount > 0, "ZERO AMOUNT");
        require(token != address(0), "ZERO TOKEN");
        require(msg.value >= bnbFeeForLpLock, "Don't be cheap, please pay the price");
        require(unlockTime > block.timestamp, "Don't try to cheat, unlock time must be in the future");
        require(unlockTime < 10000000000, "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS");
        address lpToken = ReturnLPAddressforToken(token);
        transferFees();

        TokenLock memory lock = TokenLock({
            token: lpToken,
            owner: withdrawer,
            tokenAmount: amount,
            unlockTime: unlockTime
        });

        lockId = lockNonce++;
        tokenLocks[lockId] = lock;

        userLocks[withdrawer].add(lockId);

        IERC20(lpToken).safeTransferFrom(msg.sender, address(this), amount);
        emit OnTokenLock(lockId, lpToken, withdrawer, amount, unlockTime);
        return lockId;
    }

function lockAnyTokens(address anyToken, uint256 amount, uint256 unlockTime, address payable withdrawer) external payable nonReentrant returns (uint256 lockId) {
        require(amount > 0, "ZERO AMOUNT");
        require(anyToken != address(0), "ZERO TOKEN");
        require(msg.value >= bnbFeeForAnyLock, "Don't be cheap, please pay the price");
        require(unlockTime > block.timestamp, "Don't try to cheat, unlock time must be in the future");
        require(unlockTime < 10000000000, "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS");
        transferFees();

        TokenLock memory lock = TokenLock({
            token: anyToken,
            owner: withdrawer,
            tokenAmount: amount,
            unlockTime: unlockTime
        });

        lockId = lockNonce++;
        tokenLocks[lockId] = lock;

        userLocks[withdrawer].add(lockId);

        IERC20(anyToken).safeTransferFrom(msg.sender, address(this), amount);
        emit OnTokenLock(lockId, anyToken, withdrawer, amount, unlockTime);
        return lockId;
    }
    function checkLpTokenIsPancake(address lpToken) private view returns (bool){
        IPancakePair pair = IPancakePair(lpToken);
        address factoryPair = pancakeFactory.getPair(pair.token0(), pair.token1());
        return factoryPair == lpToken;
    }

    function ReturnLPAddressforToken(address enteredAddress) public view returns(address){
            address actualPair = pancakeFactory.getPair(WBNB,enteredAddress);
            return actualPair;
        }
  

    /**
    * @notice increase unlock time of already locked tokens
    * @param newUnlockTime new unlock time (unix time in seconds)
    */
    function extendLockTime(uint256 lockId, uint256 newUnlockTime) external nonReentrant onlyLockOwner(lockId) {
        require(newUnlockTime > block.timestamp, "Don't try to cheat, unlock time must be in the future");
        require(newUnlockTime < 10000000000, "INVALID UNLOCK TIME, MUST BE UNIX TIME IN SECONDS");
        TokenLock storage lock = tokenLocks[lockId];
        require(lock.unlockTime < newUnlockTime, "extending = longer lock, not shorter");
        lock.unlockTime = newUnlockTime;
        emit OnLockDurationIncreased(lockId, newUnlockTime);
    }

    /**
    * @notice add tokens to an existing lock
    * @param amountToIncrement tokens amount to add
    */
    function increaseLockAmount(uint256 lockId, uint256 amountToIncrement) external payable nonReentrant onlyLockOwner(lockId) {
        require(amountToIncrement > 0, "Can't increase LockAmount by 0 tokens");
        require(msg.value >= bnbFeeForIncrease, "Don't be cheap, please pay the price");
        TokenLock storage lock = tokenLocks[lockId];
        transferFees();

        lock.tokenAmount = lock.tokenAmount + amountToIncrement;
        IERC20(lock.token).safeTransferFrom(msg.sender, address(this), amountToIncrement);
        emit OnLockAmountIncreased(lockId, amountToIncrement);
    }

    /**
    * @notice withdraw all tokens from lock. Current time must be greater than unlock time
    * @param lockId lock id to withdraw
    */
    function withdraw(uint256 lockId) external {
        TokenLock storage lock = tokenLocks[lockId];
        withdrawPartially(lockId, lock.tokenAmount);
    }

    /**
    * @notice withdraw specified amount of tokens from lock. Current time must be greater than unlock time
    * @param lockId lock id to withdraw tokens from
    * @param amount amount of tokens to withdraw
    */
    function withdrawPartially(uint256 lockId, uint256 amount) public nonReentrant onlyLockOwner(lockId) {
        TokenLock storage lock = tokenLocks[lockId];
        require(lock.tokenAmount >= amount, "AMOUNT EXCEEDS LOCKED");
        require(block.timestamp >= lock.unlockTime, "NOT YET UNLOCKED");
        IERC20(lock.token).safeTransfer(lock.owner, amount);

        lock.tokenAmount = lock.tokenAmount - amount;
        if(lock.tokenAmount == 0) {
            //clean up storage to save gas
            userLocks[lock.owner].remove(lockId);
            delete tokenLocks[lockId];
            emit OnTokenUnlock(lockId);
        }
        emit OnLockWithdrawal(lockId, amount);
    }

    /**
    * @notice transfer lock ownership to another account
    * @param lockId lock id to transfer
    * @param newOwner account to transfer lock
    */
    function transferLock(uint256 lockId, address newOwner) external onlyLockOwner(lockId) {
        require(newOwner != address(0), "ZERO NEW OWNER");
        TokenLock storage lock = tokenLocks[lockId];
        userLocks[lock.owner].remove(lockId);
        userLocks[newOwner].add(lockId);
        lock.owner = newOwner;
        emit OnLockOwnershipTransferred(lockId, newOwner);
    }

    function transferFees() private {
        transferBnb(feeReceiver, address(this).balance);
    }


    /**
    * @notice get user's locks number
    * @param user user's address
    */
    function userLocksLength(address user) external view returns (uint256) {
        return userLocks[user].length();
    }

    /**
    * @notice get user lock id at specified index
    * @param user user's address
    * @param index index of lock id
    */
    function userLockAt(address user, uint256 index) external view returns (uint256) {
        return userLocks[user].at(index);
    }

    function transferBnb(address recipient, uint256 amount) private {
        (bool res,  ) = recipient.call{value: amount}("");
        require(res, "BNB TRANSFER FAILED");
    }

    function setFeeReceiver(address payable newFeeReceiver) external onlyOwner {
        require(newFeeReceiver != address(0), "ZERO ADDRESS");
        feeReceiver = newFeeReceiver;
    }

    function setFees(uint256 feeForLP, uint256 feeForAny, uint256 feeForExt) external onlyOwner {
        bnbFeeForAnyLock = 0.01 ether * feeForAny;
        bnbFeeForLpLock = 0.01 ether * feeForLP;
        bnbFeeForIncrease = 0.01 ether * feeForExt;
    }

}