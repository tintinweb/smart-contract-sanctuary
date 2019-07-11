/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

// File: contracts/interfaces/token/Token.sol

pragma solidity 0.5.10;


interface Token {
    function approve(address _spender, uint256 _value) external returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) external returns (bool success);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

// File: contracts/interfaces/token/TokenConverter.sol

pragma solidity 0.5.10;



interface TokenConverter {

    function convert(
        Token _fromToken,
        Token _toToken,
        uint256 _fromAmount,
        uint256 _minReturn
    ) external payable returns (uint256 amount);

    function getReturn(
        Token _fromToken,
        Token _toToken,
        uint256 _fromAmount
    ) external returns (uint256 amount);

}

// File: contracts/interfaces/uniswap/UniswapFactoryInterface.sol

pragma solidity 0.5.10;

contract UniswapFactoryInterface {
    function getExchange(address token) external view returns (address exchange);
}

// File: contracts/interfaces/uniswap/UniswapExchangeInterface.sol

pragma solidity 0.5.10;

contract UniswapExchangeInterface {
    function getEthToTokenInputPrice(uint256 ethSold) external view returns (uint256 tokensBought);
    function getEthToTokenOutputPrice(uint256 tokensBought) external view returns (uint256 ethSold);
    function getTokenToEthInputPrice(uint256 tokensSold) external view returns (uint256 ethBought);
    function getTokenToEthOutputPrice(uint256 ethBought) external view returns (uint256 tokensSold);

    function tokenToEthTransferInput(
        uint256 tokensSold,
        uint256 minEth,
        uint256 deadline,
        address recipient
    ) external returns (uint256  ethBought);
    function ethToTokenTransferInput(
        uint256 minTokens,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256  tokensBought);
    function tokenToTokenTransferInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address recipient,
        address tokenAddr
    ) external returns (uint256 tokensBought);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity&#39;s arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it&#39;s recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
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
     * Counterpart to Solidity&#39;s `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * @dev Moves `amount` tokens from the caller&#39;s account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller&#39;s tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender&#39;s allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller&#39;s
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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

// File: contracts/proxy/UniswapProxy.sol

pragma solidity 0.5.10;


contract UniswapProxy is TokenConverter, Ownable {

    using SafeMath for uint256;

    uint public constant WAD = 10 ** 18;
    IERC20 constant internal ETH_TOKEN_ADDRESS = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    UniswapFactoryInterface uniswapFactory;

    event Swap(address indexed sender, IERC20 srcToken, IERC20 destToken, uint amount);

    event WithdrawTokens(address _token, address _to, uint256 _amount);
    event WithdrawEth(address _to, uint256 _amount);
    event SetUniswap(address _uniswap);

    constructor (address _uniswap) public {
        uniswapFactory = UniswapFactoryInterface(_uniswap);
        emit SetUniswap(_uniswap);
    }

    function setUniswap(address _uniswap) external onlyOwner returns (bool) {
        uniswapFactory = UniswapFactoryInterface(_uniswap);
        emit SetUniswap(_uniswap);
        return true;
    }

    function getReturn(
        Token from,
        Token to,
        uint256 srcQty
    ) external returns (uint256) {
        return getExpectedRate(IERC20(address(from)), IERC20(address(to)), srcQty);
        // return (srcQty * getExpectedRate(address(from), address(to), srcQty)) / 10 ** 18; // TODO: ?
    }

    function getExpectedRate(IERC20 from, IERC20 to, uint srcQty) view internal returns (uint) {
        if (from == ETH_TOKEN_ADDRESS) {
            address uniswapTokenAddress = uniswapFactory.getExchange(address(to));
            return wdiv(UniswapExchangeInterface(uniswapTokenAddress).getEthToTokenInputPrice(srcQty), srcQty);
        } else if (to == ETH_TOKEN_ADDRESS) {
            address uniswapTokenAddress = uniswapFactory.getExchange(address(from));
            return wdiv(UniswapExchangeInterface(uniswapTokenAddress).getTokenToEthInputPrice(srcQty), srcQty);
        } else {
            uint ethBought = UniswapExchangeInterface(uniswapFactory.getExchange(address(from))).getTokenToEthInputPrice(srcQty);
            return wdiv(UniswapExchangeInterface(uniswapFactory.getExchange(address(to))).getEthToTokenInputPrice(ethBought), ethBought);
        }
    }

    // TODO:
    function convert(
        Token from,
        Token to,
        uint256 srcQty,
        uint256 minReturn
    ) external payable returns (uint256 destAmount) {

        IERC20 srcToken = IERC20(address(from));
        IERC20 destToken = IERC20(address(to));

        address sender = msg.sender;
        if (srcToken == ETH_TOKEN_ADDRESS && destToken != ETH_TOKEN_ADDRESS) {
            require(msg.value == srcQty, "ETH not enought");
            destAmount = execSwapEtherToToken(destToken, srcQty, sender);
        } else if (srcToken != ETH_TOKEN_ADDRESS && destToken == ETH_TOKEN_ADDRESS) {
            require(msg.value == 0, "ETH not required");
            destAmount = execSwapTokenToEther(srcToken, srcQty, sender);
        } else {
            require(msg.value == 0, "ETH not required");
            destAmount = execSwapTokenToToken(srcToken, srcQty, destToken, sender);
        }

        require(destAmount > minReturn, "Return amount too low");
        emit Swap(msg.sender, srcToken, destToken, destAmount);

        return destAmount;
    }

    /*
    @notice Swap the user&#39;s ETH to IERC20 token
    @param token destination token contract address
    @param destAddress address to send swapped tokens to
    */
    function execSwapEtherToToken (IERC20 token, uint srcQty, address destAddress) public payable returns(uint) {

        address uniswapTokenAddress = uniswapFactory.getExchange(address(token));
        // Send the swapped tokens to the destination address and send the swapped tokens to the destination address
        uint tokenAmount = UniswapExchangeInterface(uniswapTokenAddress).
                ethToTokenTransferInput.value(srcQty)(1, block.timestamp + 1, destAddress);

        return tokenAmount;
    }

    /*
    @notice Swap the user&#39;s IERC20 token to ETH
    @param token source token contract address
    @param tokenQty amount of source tokens
    @param destAddress address to send swapped ETH to
    */
    function execSwapTokenToEther (IERC20 token, uint tokenQty, address destAddress) internal returns(uint) {

        // Check that the player has transferred the token to this contract
        require(token.transferFrom(msg.sender, address(this), tokenQty), "Error pulling tokens");

        // Set the spender&#39;s token allowance to tokenQty
        address uniswapTokenAddress = uniswapFactory.getExchange(address(token));
        token.approve(uniswapTokenAddress, tokenQty);

        // Swap the IERC20 token to ETH and send the swapped ETH to the destination address
        uint ethAmount = UniswapExchangeInterface(uniswapTokenAddress).tokenToEthTransferInput(tokenQty, 1, block.timestamp + 1, destAddress);

        return ethAmount;
    }

    /*
    @dev Swap the user&#39;s IERC20 token to another IERC20 token
    @param srcToken source token contract address
    @param srcQty amount of source tokens
    @param destToken destination token contract address
    @param destAddress address to send swapped tokens to
    */
    function execSwapTokenToToken(
        IERC20 srcToken,
        uint256 srcQty,
        IERC20 destToken,
        address destAddress
    ) internal returns (uint) {

        // Check that the player has transferred the token to this contract
        require(srcToken.transferFrom(msg.sender, address(this), srcQty), "Error pulling tokens");

        // Set the spender&#39;s token allowance to srcQty
        address uniswapTokenAddress = uniswapFactory.getExchange(address(destToken));
        srcToken.approve(uniswapTokenAddress, srcQty);

        // Swap the IERC20 token to IERC20 and send the swapped tokens to the destination address
        uint destAmount = UniswapExchangeInterface(uniswapTokenAddress).tokenToTokenTransferInput(
            srcQty,
            1,  //TODO:
            1,  //TODO:
            block.timestamp + 1,
            destAddress,
            address(destToken)
        );

        return destAmount;
    }

    function withdrawTokens(
        Token _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        emit WithdrawTokens(address(_token), _to, _amount);
        return _token.transfer(_to, _amount);
    }

    function withdrawEther(
        address payable _to,
        uint256 _amount
    ) external onlyOwner {
        emit WithdrawEth(_to, _amount);
        _to.transfer(_amount);
    }

    function() external payable {}

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = ((x.mul(WAD)).add(y / 2)) / y;
    }
}