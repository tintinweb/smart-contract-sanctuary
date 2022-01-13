/**
 *Submitted for verification at snowtrace.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IRouter {
    function addPlugin(address _plugin) external;
    function pluginTransfer(address _token, address _account, address _receiver, uint256 _amount) external;
    function pluginIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function pluginDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;
}

interface IYakRouter {
    struct Trade {
        uint amountIn;
        uint amountOut;
        address[] path;
        address[] adapters;
    }
    function swapNoSplit(Trade calldata,address, uint256) external;
    function swapNoSplitFromAVAX(Trade calldata,address, uint256) external payable;
    function swapNoSplitToAVAX(Trade calldata,address, uint256) external;
}

interface IERC20 {
    event Approval(address,address,uint);
    event Transfer(address,address,uint);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function transferFrom(address,address,uint) external returns (bool);
    function allowance(address,address) external view returns (uint);
    function approve(address,uint) external returns (bool);
    function transfer(address,uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function nonces(address) external view returns (uint);  // Only tokens that support permit
    function permit(address,address,uint256,uint256,uint8,bytes32,bytes32) external;  // Only tokens that support permit
    function swap(address,uint256) external;  // Only Avalanche bridge tokens 
    function swapSupply(address) external view returns (uint);  // Only Avalanche bridge tokens 
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'SafeMath: ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'SafeMath: ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'SafeMath: ds-math-mul-overflow');
    }
}

library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
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
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract myArb is Ownable{
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public vault = 0x9ab2De34A33fB459b538c43f251eB825645e8595;
    IRouter public GMXRouter = IRouter(0x5F719c2F1095F7B9fc68a68e35B51194f4b6abe8);
    IYakRouter public YakRouter = IYakRouter(0xC4729E56b831d74bBc18797e0e17A295fA77488c);

    struct Trade {
        uint amountIn;
        uint amountOut;
        address[] path;
        address[] adapters;
    }

    function arb(IYakRouter.Trade calldata _trade, address _to, uint256 _fees, address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) onlyOwner payable external {
        YakRouter.swapNoSplitFromAVAX{value: msg.value}(_trade, _to, _fees);
        GMXRouter.swap(_path, _amountIn, _minOut, _receiver);

        if(address(this).balance < msg.value){
            revert("Not Profitable");
        }
        payable(msg.sender).transfer(address(this).balance);
    }

    function arbOtherWay(IYakRouter.Trade calldata _trade, address _to, uint256 _fees, address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) onlyOwner payable external {
        GMXRouter.swap(_path, _amountIn, _minOut, _receiver);
        YakRouter.swapNoSplitFromAVAX{value: msg.value}(_trade, _to, _fees);
        if(address(this).balance < msg.value){
            revert("Not Profitable");
        }
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw() onlyOwner external {
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverERC20(address _tokenAddress, uint _tokenAmount) external onlyOwner {
        require(_tokenAmount > 0, "Nothing to recover");
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
    }

    function approve(address token, address ad, uint256 amount) external onlyOwner {
        IERC20(token).approve(ad,amount);
    }
}