/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract DeuxCrowdsale is Context, Ownable {
    using SafeMath for uint256;

    event Sale(address indexed signer, address token0, address token1, uint256 token0Amount, uint256 token1Amount);

    struct Pair {
        address token0;
        uint256 t0decimal;
        address token1;
        uint256 t1decimal;
        uint256 price;
        uint256 provision;
        bool active;
    }

    bool public saleActive;
    Pair public pair;

    uint8 public token0Min;
    uint8 public token1Min;

    address public receiver;

    constructor() public {
        saleActive = true;
    }
    
    /**
     * @dev Throws if pair is not defined
     */
    modifier shouldPairDefined() {
        require(pair.token0 != address(0) && pair.token1 != address(0), "DEUX Crowdsale : pair is not defined");
        _;
    }

    /**
     * @dev Set receiver address
     */
    function setReceiver(address _receiver) public onlyOwner {
        receiver = _receiver;
    }

    /**
     * @dev Set sale pair
     */
    function initialize(address _token0, address _token1, uint256 _token0decimal, uint256 _token1decimal, uint256 _price, uint256 _provision) public onlyOwner {
        pair = Pair(_token0, _token0decimal, _token1, _token1decimal, _price, _provision, true);
    }

    /**
     * @dev Get liquidity for token1
     */
    function getLiquidity() internal view returns (uint256) {
        return IERC20(pair.token1).balanceOf(address(this));
    }
    
    /**
     * @dev Calculate sale amount
     */
    function calculateSendAmount(uint256 _amount) internal view returns (uint256, uint256, uint256) {
        require(_amount > pair.price, "DEUX Crowdsale : given amount should be higher than unit price");
        uint256 dustAmount = _amount % pair.price; // Dust amount for refund
        uint256 acceptAmount = _amount.sub(dustAmount); // Accept amount for sell
        uint256 ratio = acceptAmount.div(pair.price); // Sell ratio
        uint256 transferSize = pair.provision.mul(ratio); // Transfer total
        return (acceptAmount, transferSize, dustAmount);
    }
    
    /**
     * @dev Swap tokens
     */
    function buy(uint256 _amount) public shouldPairDefined {
        require(saleActive == true, "DEUX Crowdsale : sale is not active");
        require(pair.active = true, "DEUX Crowdsale : pair is not active");
        require(receiver != address(0), "DEUX Crowdsale : receiver is zero address");

        uint256 signerAllowance = IERC20(pair.token0).allowance(_msgSender(), address(this));
        require(signerAllowance >= _amount, "DEUX Crowdsale : signer allowance required for `token0`");

        // Calculate allowed amount, transfer size & dust amount for refund
        (uint256 _allowAmount, uint256 _transferSize, uint256 _dustAmount) = calculateSendAmount(_amount);

        // Send token0 to current contract
        TransferHelper.safeTransferFrom(pair.token0, _msgSender(), address(this), _amount);
        
        // Send allowAmount token0 to receiver
        TransferHelper.safeTransfer(pair.token0, receiver, _allowAmount);
        
        // Send dustAmount to signer if exist
        if (_dustAmount > 0) {
            TransferHelper.safeTransfer(pair.token0, _msgSender(), _dustAmount);
        }

        // Send token1 to signer
        TransferHelper.safeTransfer(pair.token1, _msgSender(), _transferSize);

        emit Sale(_msgSender(), pair.token0, pair.token1, _amount, _amount);
    }
    
    /**
     * @dev Add liquidity
     */
    function addLiquidity(uint256 _amount) public onlyOwner shouldPairDefined {
        uint256 allowance = IERC20(pair.token1).allowance(_msgSender(), address(this));
        require(allowance >= _amount, "DEUX Crowdsale : allowance is not enough");
        TransferHelper.safeTransferFrom(pair.token1, _msgSender(), address(this), _amount);
    }
    
    /**
     * @dev Remove liquidity
     */
    function removeLiquidity(address _to, uint256 _amount) public onlyOwner shouldPairDefined {
        require(_to != address(0), "DEUX Crowdsale : to address is zero address");
        require(getLiquidity() >= _amount, "DEUX Crowdsale : insufficient liquidity");
        
        TransferHelper.safeTransfer(pair.token1, _to, _amount);
    }
    
    /**
     * @dev Add liquidity with contract
     */
    function addLiquidityWithContract(address _contract, uint256 _amount) public onlyOwner {
        uint256 allowance = IERC20(_contract).allowance(_msgSender(), address(this));
        require(allowance >= _amount, "DEUX Crowdsale : allowance is not enough");
        TransferHelper.safeTransferFrom(_contract, _msgSender(), address(this), _amount);
    }
    
    /**
     * @dev Remove liquidity with contract
     */
    function removeLiquidityWithContract(address _contract, address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "DEUX Crowdsale : to address is zero address");
        require(IERC20(_contract).balanceOf(address(this)) >= _amount, "DEUX Crowdsale : insufficient liquidity");
        
        TransferHelper.safeTransfer(_contract, _to, _amount);
    }
}