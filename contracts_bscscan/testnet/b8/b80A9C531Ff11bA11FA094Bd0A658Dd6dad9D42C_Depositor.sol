/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// File: contracts\blueprints\Depositor.sol

pragma solidity 0.6.12;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
        token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
        token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata =
        address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {

            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IMultiStrategy {
    function deposit(uint256 amount, address depositor) external returns (bool);
    function depositBNB(address depositor) external payable returns (bool);
    
    function withdraw(uint256 ramount, address depositor) external returns (bool);
    function withdrawBNB(uint256 ramount, address depositor) external returns (bool);
    
    function withdrawAll(address depositor) external returns (bool);
    function withdrawAllBNB(address depositor) external returns (bool);

    function underlyingToken() external returns (address);
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

contract Depositor is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant PRECISION = 10**18;
    address public constant wbnbAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address[] public pools;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor() public {}

    function poolLength() public view returns(uint256) {
        return pools.length;
    }

    function add(
        address pool
    ) public onlyOwner {
        pools.push(pool);
    }

    function addLiquidity(uint256 pid, uint256 amount) public nonReentrant {
        require(amount > 0, "Insufficient Amount");
        require(pid < poolLength() && pid >= 0, "Invalid Pool Id");
        
        address pool = pools[pid];
        address underlyingCoin = IMultiStrategy(pool).underlyingToken();
        IERC20(underlyingCoin).safeApprove(pool, amount);
        IERC20(underlyingCoin).safeTransferFrom(msg.sender, address(this), amount);
        
        IMultiStrategy(pool).deposit(amount, msg.sender);
        
        emit Deposit(msg.sender, pid, amount);
    }

    function addLiquidityBNB(uint256 pid) public payable nonReentrant {
        require(msg.value > 0, "Insufficient Amount");
        require(pid < poolLength() && pid >= 0, "Invalid Pool Id");
        
        address pool = pools[pid];
        address underlyingCoin = IMultiStrategy(pool).underlyingToken();
        require(underlyingCoin == wbnbAddress, "Pool Is Not WBNB");
        
        IMultiStrategy(pool).depositBNB{value: msg.value}(msg.sender);
        
        emit Deposit(msg.sender, pid, msg.value);
    }

    function removeLiquidity(uint256 pid, uint256 ramount) public nonReentrant {
        require(ramount > 0, "Invalid Amount");
        require(pid < poolLength() && pid >= 0, "Invalid Pool Id");

        address pool = pools[pid];
        address underlyingCoin = IMultiStrategy(pool).underlyingToken();
        
        uint256 ubalance = IERC20(underlyingCoin).balanceOf(address(this));
        IMultiStrategy(pool).withdraw(ramount, msg.sender);
        ubalance = ubalance.sub(IERC20(underlyingCoin).balanceOf(address(this)));

        IERC20(underlyingCoin).safeTransfer(msg.sender, ubalance);

        emit Withdraw(msg.sender, pid, ramount);
    }

     function removeLiquidityBNB(uint256 pid, uint256 ramount) public nonReentrant {
        require(ramount > 0, "Invalid Amount");
        require(pid < poolLength() && pid >= 0, "Invalid Pool Id");

        address pool = pools[pid];
        address underlyingCoin = IMultiStrategy(pool).underlyingToken();
        require(underlyingCoin == wbnbAddress, "Pool Is Not WBNB");

        uint256 ubalance = address(this).balance;
        IMultiStrategy(pool).withdrawBNB(ramount, msg.sender);
        ubalance = ubalance.sub(address(this).balance);

        (bool sent, bytes memory data) = address(msg.sender).call{value: ubalance}("");
        require(sent, "Failed to sent BNB");

        emit Withdraw(msg.sender, pid, ramount);
    }

    function removeAllLiquidity(uint256 pid) public nonReentrant {
        require(pid < poolLength() && pid >= 0, "Invalid Pool Id");

        address pool = pools[pid];
        address underlyingCoin = IMultiStrategy(pool).underlyingToken();
        
        uint256 ubalance = IERC20(underlyingCoin).balanceOf(address(this));
        IMultiStrategy(pool).withdrawAll(msg.sender);
        ubalance = ubalance.sub(IERC20(underlyingCoin).balanceOf(address(this)));

        IERC20(underlyingCoin).safeTransfer(msg.sender, ubalance);

        emit Withdraw(msg.sender, pid, ubalance);
    }

    function removeAllLiquidityBNB(uint256 pid) public nonReentrant {
        require(pid < poolLength() && pid >= 0, "Invalid Pool Id");

        address pool = pools[pid];
        address underlyingCoin = IMultiStrategy(pool).underlyingToken();
        require(underlyingCoin == wbnbAddress, "Pool Is Not WBNB");

        uint256 ubalance = address(this).balance;
        IMultiStrategy(pool).withdrawAllBNB(msg.sender);
        ubalance = ubalance.sub(address(this).balance);
        
        (bool sent, bytes memory data) = address(msg.sender).call{value: ubalance}("");
        require(sent, "Failed to sent BNB");

        emit Withdraw(msg.sender, pid, ubalance);
    }
}