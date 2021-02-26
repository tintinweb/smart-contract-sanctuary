/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

// File: ../common/openzeppelin/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/SmokeSignal.sol

pragma solidity ^0.6.0;


abstract contract EthPriceOracle
{
    function read()
        public 
        virtual
        view 
        returns(bytes32);
}

struct StoredMessageData 
{
    address firstAuthor;
    uint nativeBurned;
    uint dollarsBurned;
    uint nativeTipped;
    uint dollarsTipped;
}

contract SmokeSignal 
{
    using SafeMath for uint256;

    address payable constant burnAddress = address(0x0);
    address payable donationAddress;
    EthPriceOracle public oracle;

    constructor(address payable _donationAddress, EthPriceOracle _oracle) 
        public 
    {
        donationAddress = _donationAddress;
        oracle = _oracle;
    }

    mapping (bytes32 => StoredMessageData) public storedMessageData;

    function EthPrice() 
        public
        view
        returns (uint _price)
    {
        return address(oracle) == address(0) ? 10**18 : uint(oracle.read());
    }

    function ethToUsd(uint ethAmount)
        public
        view
        returns (uint usdAmount)
    {
        usdAmount = EthPrice() * ethAmount / 10**18;
    }

    event MessageBurn(
        bytes32 indexed _hash,
        address indexed _from,
        uint _burnAmount,
        uint _burnUsdValue,
        string _message
    );

    function burnMessage(string calldata _message, uint donateAmount)
        external
        payable
        returns(bytes32)
    {
        internalDonateIfNonzero(donateAmount);

        bytes32 hash = keccak256(abi.encode(_message));

        uint burnAmount = msg.value.sub(donateAmount);

        uint burnUsdValue = ethToUsd(burnAmount);

        internalBurnForMessageHash(hash, burnAmount, burnUsdValue);

        if (storedMessageData[hash].firstAuthor == address(0))
        {
            storedMessageData[hash].firstAuthor = msg.sender;
        }

        emit MessageBurn(
            hash,
            msg.sender,
            burnAmount,
            burnUsdValue,
            _message);

        return hash;
    }

    event HashBurn(
        bytes32 indexed _hash,
        address indexed _from,
        uint _burnAmount,
        uint _burnUsdValue
    );

    function burnHash(bytes32 _hash, uint donateAmount)
        external
        payable
    {
        internalDonateIfNonzero(donateAmount);

        uint burnAmount = msg.value.sub(donateAmount);

        uint burnUsdValue = ethToUsd(burnAmount);

        internalBurnForMessageHash(_hash, burnAmount, burnUsdValue);

        emit HashBurn(
            _hash,
            msg.sender,
            burnAmount,
            burnUsdValue
        );
    }

    event HashTip(
        bytes32 indexed _hash,
        address indexed _from,
        uint _tipAmount,
        uint _tipUsdValue
    );

    function tipHashOrBurnIfNoAuthor(bytes32 _hash, uint donateAmount)
        external
        payable
    {
        internalDonateIfNonzero(donateAmount);

        uint tipAmount = msg.value.sub(donateAmount);
        
        uint tipUsdValue = ethToUsd(tipAmount);
        
        address author = storedMessageData[_hash].firstAuthor;
        if (author == address(0))
        {
            internalBurnForMessageHash(_hash, tipAmount, tipUsdValue);

            emit HashBurn(
                _hash,
                msg.sender,
                tipAmount,
                tipUsdValue
            );
        }
        else 
        {
            internalTipForMessageHash(_hash, author, tipAmount, tipUsdValue);

            emit HashTip(
                _hash,
                msg.sender,
                tipAmount,
                tipUsdValue
            );
        }
    }

    function internalBurnForMessageHash(bytes32 _hash, uint _burnAmount, uint _burnUsdValue)
        internal
    {
        internalBurn(_burnAmount);
        storedMessageData[_hash].nativeBurned += _burnAmount;
        storedMessageData[_hash].dollarsBurned += _burnUsdValue;
    }

    function internalTipForMessageHash(bytes32 _hash, address author, uint _tipAmount, uint _tipUsdValue)
        internal
    {
        internalSend(author, _tipAmount);
        storedMessageData[_hash].nativeTipped += _tipAmount;
        storedMessageData[_hash].dollarsTipped += _tipUsdValue;
    }

    function internalDonateIfNonzero(uint _wei)
        internal
    {
        if (_wei > 0)
        {
            internalSend(donationAddress, _wei);
        }
    }

    function internalSend(address _to, uint _wei)
        internal
    {
        _to.call.value(_wei)("");
    }

    function internalBurn(uint _wei)
        internal
    {
        burnAddress.call.value(_wei)("");
    }
}

contract SmokeSignal_Ethereum is SmokeSignal
{
    constructor(address payable _donationAddress) SmokeSignal(_donationAddress, EthPriceOracle(0x729D19f657BD0614b4985Cf1D82531c67569197B))
        public 
    { }
}

contract SmokeSignal_xDai is SmokeSignal
{
    constructor(address payable _donationAddress) SmokeSignal(_donationAddress, EthPriceOracle(address(0)))
        public 
    { }
}