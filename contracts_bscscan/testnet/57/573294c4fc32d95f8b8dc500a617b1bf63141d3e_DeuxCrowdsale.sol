/**
 *Submitted for verification at BscScan.com on 2021-11-12
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

interface IDeuxToken is IERC20 {
    function setVesting(address _addr, uint256 _amount, uint256[] calldata percents, uint256 unlockDaysPeriod) external returns (bool);
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
    event CapLimitChange(bool minCapActive, uint256 minCap, bool maxCapActive, uint256 maxCap);

    struct Pair {
        address token0;
        uint256 t0decimal;
        address token1;
        uint256 t1decimal;
        uint256 price;
        uint256 provision;
        bool active;
    }

    struct CapLimits {
        bool minCapActive;
        uint256 minCap;
        bool maxCapActive;
        uint256 maxCap;
    }

    bool public swapWhiteListingActive;
    mapping(address => bool) public swapWhiteList;

    mapping(bytes32 => mapping(address => uint256)) private swapLimits;

    bool public swapActive;
    Pair public pair;
    CapLimits public capLimits;

    uint256[] vestingPercents;
    uint256 unlockDaysPeriod;

    address public receiver;
    address public deuxContract;

    constructor() public {
        swapActive = true;
        swapWhiteListingActive = true;
    }

    /**
     * @dev Throws if pair is not defined
     */
    modifier shouldPairDefined() {
        require(pair.token0 != address(0) && pair.token1 != address(0), "DEUX Crowdsale : pair is not defined");
        _;
    }

    /**
     * @dev Throws if swap is not active
     */
    modifier shouldSwapActive() {
        require(swapActive == true, "DEUX Crowdsale : swap is not active");
        _;
    }

    /**
     * @dev Set deux vesting informations
     */
    function setDeuxVestingInfo(uint256[] memory percents, uint256 _unlockDaysPeriod) public onlyOwner {
        delete vestingPercents;
        for (uint256 i = 0; i < percents.length; i++) {
            require(percents[i] > 0, "Percentage can not be zero");
            vestingPercents.push(percents[i]);
        }
        unlockDaysPeriod = _unlockDaysPeriod;
    }

    /**
     * @dev Set deux contract
     */
    function setDeuxContract(address _addr) public onlyOwner {
        require(_addr != address(0), "Deux contract can not be zero address");
        deuxContract = _addr;
    }

    /**
     * @dev Add single account to whitelist
     */
    function addSingleAccountToWhitelist(address _addr) public onlyOwner {
        swapWhiteList[_addr] = true;
    }

    /**
     * @dev Remove single account from whitelist
     */
    function removeSingleAccountFromWhitelist(address _addr) public onlyOwner {
        swapWhiteList[_addr] = false;
    }

    /**
     * @dev Add multiple account to whitelist
     */
    function addMultipleAccountToWhitelist(address[] memory _addrs) public onlyOwner {
        for (uint i = 0; i < _addrs.length; i++) {
            swapWhiteList[_addrs[i]] = true;
        }
    }

    /**
     * @dev Remove multiple account from whitelist
     */
    function removeMultipleAccountFromWhitelist(address[] memory _addrs) public onlyOwner {
        for (uint i = 0; i < _addrs.length; i++) {
            swapWhiteList[_addrs[i]] = false;
        }
    }

    /**
     * @dev Set swap whitelisting status
     */
    function setSwapWhitelistingStatus(bool _swapWhiteListingActive) public onlyOwner {
        swapWhiteListingActive = _swapWhiteListingActive;
    }

    /**
     * @dev Set swap status
     */
    function setSwapStatus(bool _swapActive) public onlyOwner {
        swapActive = _swapActive;
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
    function setPair(address _token0, address _token1, uint256 _token0decimal, uint256 _token1decimal, uint256 _price, uint256 _provision) public onlyOwner {
        pair = Pair(_token0, _token0decimal, _token1, _token1decimal, _price, _provision, true);
    }

    /**
     * @dev Set swap cap limits
     */
    function setCapLimits(uint256 _minCap, uint256 _maxCap) public onlyOwner {
        bool minCapActive = false;
        bool maxCapActive = false;
        if (_minCap > 0) {
            minCapActive = true;
        }
        if (_maxCap > 0) {
            maxCapActive = true;
        }
        capLimits = CapLimits(minCapActive, _minCap, maxCapActive, _maxCap);
        emit CapLimitChange(minCapActive, _minCap, maxCapActive, _maxCap);
    }

    /**
     * @dev Get liquidity for token1
     */
    function getLiquidity() internal view returns (uint256) {
        return IERC20(pair.token1).balanceOf(address(this));
    }

    /**
     * @dev Get swap pair key
     */
    function getSwapPairKey() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(pair.token0, pair.token1));
    }

    /**
     * @dev Get available swap limit for signer address
     */
    function getSignerSwapLimit() internal view returns (uint256) {
        return swapLimits[getSwapPairKey()][_msgSender()];
    }

    /**
     * @dev Increase signer swap limit
     */
    function increaseSignerSwapLimit(uint256 _limit) internal {
        swapLimits[getSwapPairKey()][_msgSender()] = swapLimits[getSwapPairKey()][_msgSender()].add(_limit);
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

        uint256 signerSwappedLimit = getSignerSwapLimit();

        // Check acceptAmount between minCap & maxCap
        if (capLimits.minCapActive) {
            require(acceptAmount >= capLimits.minCap, "DEUX Crowdsale : acceptable amount is lower than min cap");
        }
        if (capLimits.maxCapActive) {
            require(acceptAmount <= capLimits.maxCap, "DEUX Crowdsale : acceptable amount is higher than max cap");

            // Check available cap limit for signer account
            uint256 totalLimitAfterSwap = signerSwappedLimit.add(acceptAmount);
            require(totalLimitAfterSwap <= capLimits.maxCap, "DEUX Crowdsale : total cap is higher than max cap");
        }

        return (acceptAmount, transferSize, dustAmount);
    }

    /**
     * @dev Get available swap limit & swap status for signer account
     */
    function getAvailableSwapLimit() public shouldPairDefined view returns (uint256, bool) {
        if (capLimits.maxCapActive) {
            uint256 signerSwappedLimit = getSignerSwapLimit();
            if (signerSwappedLimit > capLimits.maxCap) {
                return (0, false);
            } else {
                return (capLimits.maxCap.sub(signerSwappedLimit), true);
            }
        }
        return (0, true);
    }

    /**
     * @dev Check soft/hard cap per account for selling
     */
    function beforeBuy(uint256 _amount) internal view returns (bool) {
        require(pair.active == true, "DEUX Crowdsale : pair is not active");
        require(receiver != address(0), "DEUX Crowdsale : receiver is zero address");
        require(deuxContract != address(0), "DEUX Crowdsale : deux contract is not defined");

        if (deuxContract == pair.token1) {
            require(vestingPercents.length > 0, "DEUX Crowdsale : vesting percents is not defined");
            require(unlockDaysPeriod > 0, "DEUX Crowdsale : unlock days period is not defined");
        }

        if (swapWhiteListingActive) {
            require(swapWhiteList[_msgSender()] == true, "DEUX Crowdsale : signer is not in whitelist");
        }

        // Check signer allowance for swap
        uint256 signerAllowance = IERC20(pair.token0).allowance(_msgSender(), address(this));
        require(signerAllowance >= _amount, "DEUX Crowdsale : signer allowance required for `token0`");

        return true;
    }

    /**
     * @dev Swap tokens
     */
    function buy(uint256 _amount) public shouldPairDefined shouldSwapActive {
        require(beforeBuy(_amount) == true, "DEUX : Buy is not allowed currently");

        // Calculate allowed amount, transfer size & dust amount for refund
        (uint256 _allowAmount, uint256 _transferSize, uint256 _dustAmount) = calculateSendAmount(_amount);

        // Check liquidity
        require(_transferSize <= getLiquidity(), "DEUX Crowdsale : insufficient liquidity");

        // Send token0 to current contract
        TransferHelper.safeTransferFrom(pair.token0, _msgSender(), address(this), _amount);

        // Send allowAmount token0 to receiver
        TransferHelper.safeTransfer(pair.token0, receiver, _allowAmount);

        // Send dustAmount to signer if exist
        if (_dustAmount > 0) {
            TransferHelper.safeTransfer(pair.token0, _msgSender(), _dustAmount);
        }

        // Increase signer swap limit for future swaps
        increaseSignerSwapLimit(_allowAmount);

        // Send token1 to signer
        TransferHelper.safeTransfer(pair.token1, _msgSender(), _transferSize);

        if (deuxContract == pair.token1) {
            // bytes4(keccak256(bytes('setVesting(address,uint256,uint256[],uint256)'))) = 0x226314de
            // function setVesting(address _addr, uint256 _amount, uint256[] calldata percents, uint256 unlockDaysPeriod) external returns (bool);
            // (bool success,) = deuxContract.call(abi.encodeWithSelector(0x226314de, _msgSender(), _transferSize, [30,35,35], 30));
            // require(success, "Vesting call is failed");
            bool vestingSuccess = IDeuxToken(deuxContract).setVesting(_msgSender(), _transferSize, vestingPercents, unlockDaysPeriod);
            require(vestingSuccess == true, "Vesting call is failed");
        }

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