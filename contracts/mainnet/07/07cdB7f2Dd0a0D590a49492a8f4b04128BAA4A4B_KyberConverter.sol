// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/ERC20.sol

pragma solidity ^0.5.2;

interface ERC20 {
    function totalSupply() external view returns (uint supply);

    function balanceOf(address _owner) external view returns (uint balance);

    function transfer(address _to, uint _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint _value) external returns (bool success);

    function approve(address _spender, uint _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint remaining);

    function decimals() external view returns (uint digits);

    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// File: contracts/kyber/KyberNetworkProxyInterface.sol

pragma solidity ^0.5.2;


interface KyberNetworkProxyInterface {
    function maxGasPrice() external view returns (uint);

    function getUserCapInWei(address user) external view returns (uint);

    function getUserCapInTokenWei(address user, ERC20 token) external view returns (uint);

    function enabled() external view returns (bool);

    function info(bytes32 id) external view returns (uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view
    returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes calldata hint) external payable returns (uint);
}

// File: contracts/community/IDonationCommunity.sol

pragma solidity ^0.5.2;

interface IDonationCommunity {

    function donateDelegated(address payable _donator) external payable;

    function name() external view returns (string memory);

    function charityVault() external view returns (address);
}

// File: contracts/kyber/KyberConverter.sol

pragma solidity ^0.5.2;






contract KyberConverter is Ownable {
    using SafeMath for uint256;
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    KyberNetworkProxyInterface public kyberNetworkProxyContract;
    address public walletId;

    // Events
    event Swap(address indexed sender, ERC20 srcToken, ERC20 destToken);

    /**
     * @dev Payable fallback to receive ETH while converting
     **/
    function() external payable {
    }

    constructor (KyberNetworkProxyInterface _kyberNetworkProxyContract, address _walletId) public {
        kyberNetworkProxyContract = _kyberNetworkProxyContract;
        walletId = _walletId;
    }

    /**
     * @dev Gets the conversion rate for the destToken given the srcQty.
     * @param srcToken source token contract address
     * @param srcQty amount of source tokens
     * @param destToken destination token contract address
     */
    function getConversionRates(
        ERC20 srcToken,
        uint srcQty,
        ERC20 destToken
    ) public
    view
    returns (uint, uint)
    {
        return kyberNetworkProxyContract.getExpectedRate(srcToken, destToken, srcQty);
    }

    /**
     * @dev Swap the user's ERC20 token to ETH
     * Note: requires 'approve' srcToken first!
     * @param srcToken source token contract address
     * @param srcQty amount of source tokens
     */
    function executeSwapMyERCToETH(ERC20 srcToken, uint srcQty) public {
        swapERCToETH(srcToken, srcQty, msg.sender);
        emit Swap(msg.sender, srcToken, ETH_TOKEN_ADDRESS);
    }


    /**
     * @dev Swap the user's ERC20 token to ETH and donates to the community.
     * Note: requires 'approve' srcToken first!
     * @param srcToken source token contract address
     * @param srcQty amount of source tokens
     * @param community address of the donation community
     */
    function executeSwapAndDonate(ERC20 srcToken, uint srcQty, IDonationCommunity community) public {
        swapERCToETH(srcToken, srcQty, address(this));
        // donate ETH to the community
        community.donateDelegated.value(address(this).balance)(msg.sender);
        emit Swap(msg.sender, srcToken, ETH_TOKEN_ADDRESS);
    }

    function swapERCToETH(ERC20 srcToken, uint srcQty, address destAddress) internal {
        uint minConversionRate;

        // Check that the token transferFrom has succeeded
        require(srcToken.transferFrom(msg.sender, address(this), srcQty));

        // Set the spender's token allowance to tokenQty
        require(srcToken.approve(address(kyberNetworkProxyContract), srcQty));

        // Get the minimum conversion rate
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(srcToken, ETH_TOKEN_ADDRESS, srcQty);
        // -5% max
        minConversionRate = minConversionRate.mul(95).div(100);
        // +5% max
        uint maxDestAmount = srcQty.mul(minConversionRate).mul(105).div(100);

        // Swap the ERC20 token and send to 'this' contract address
        bytes memory hint;
        uint256 amount = kyberNetworkProxyContract.tradeWithHint(
            srcToken,
            srcQty,
            ETH_TOKEN_ADDRESS,
            destAddress,
            maxDestAmount,
            minConversionRate,
            walletId,
            hint
        );

        // Return the change of src token
        uint256 change = srcToken.balanceOf(address(this));

        if (change > 0) {
            require(
                srcToken.transfer(msg.sender, change),
                "Could not transfer change to sender"
            );
        }
    }

    function executeSwapMyETHToERC(address _ercAddress) public payable returns (uint256) {
        uint minConversionRate;
        uint srcQty = msg.value;
        address destAddress = msg.sender;
        ERC20 ercToken = ERC20(_ercAddress);

        // Get the minimum conversion rate
        (minConversionRate,) = kyberNetworkProxyContract.getExpectedRate(ETH_TOKEN_ADDRESS, ercToken, srcQty);

        uint maxDestAmount = srcQty.mul(minConversionRate).mul(105).div(100);
        // 5%

        // Swap the ERC20 token and send to destAddress
        bytes memory hint;
        uint256 amount = kyberNetworkProxyContract.tradeWithHint.value(srcQty)(
            ETH_TOKEN_ADDRESS,
            srcQty,
            ercToken,
            destAddress,
            maxDestAmount,
            minConversionRate,
            walletId,
            hint
        );
        // Return the change of ETH if any
        uint256 change = address(this).balance;
        if (change > 0) {
            address(msg.sender).transfer(change);
        }
        // Log the event
        emit Swap(msg.sender, ETH_TOKEN_ADDRESS, ercToken);

        return amount;
    }

    /**
     * @dev Recovery for the remaining change
     */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient funds to withdraw");
        msg.sender.transfer(address(this).balance);
    }

}