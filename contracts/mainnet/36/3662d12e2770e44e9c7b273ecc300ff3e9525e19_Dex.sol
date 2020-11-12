// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

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

library ECDSA {
    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

contract Configurations is Ownable {
    using SafeMath for uint256;
    uint256 public minFee;
    uint256 public maxFee;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public percentageFee;
    uint256 public collectedFee;

    address public pauser;
    address public feeAccount;
    address public middleware;

    string[] public pairs;
    uint256[] public minRate;
    uint256[] public maxRate;

    uint256 public rateDecimals = 18;
    string public baseCurrency = "GSU";

    mapping(string => uint8) public pairIndex;

    event PauserChanged(address pauser);
    event MiddlewareChanged(address middleware);
    event FeeAccountUpdated(address feeAccount);
    event RateUpdated(uint8 pair, uint256 minRate, uint256 maxRate);
    event AmountUpdated(uint256 minAmount, uint256 maxAmount);
    event FeeUpdated(uint256 minFee, uint256 maxFee, uint256 percentageFee);

    /**
     * @dev Throws if called by any account other than the pauser.
     */
    modifier onlyPauser() {
        require(pauser == _msgSender(), "Dex: caller is not the pauser");
        _;
    }

    constructor(
        uint256 _minFee,
        uint256 _maxFee,
        uint256 _percentageFee,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256[] memory _minRate,
        uint256[] memory _maxRate,
        address _feeAccount,
        address _middleware
    ) public {
        require(_feeAccount != address(0x0));
        collectedFee = 0;
        minFee = _minFee;
        maxFee = _maxFee;
        minRate = _minRate;
        maxRate = _maxRate;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        percentageFee = _percentageFee;
        setfeeAccount(_feeAccount);
        setMiddleware(_middleware);
        setPauser(_msgSender());
        pairs.push("GSU/ETH");
        pairs.push("ETH/GSU");
        pairs.push("GSU/USDT");
        pairs.push("USDT/GSU");
        pairIndex["GSU/ETH"] = 0;
        pairIndex["ETH/GSU"] = 1;
        pairIndex["GSU/USDT"] = 2;
        pairIndex["USDT/GSU"] = 3;
    }

    function setMinFee(uint256 _minFee) external onlyOwner returns (bool) {
        require(_minFee <= maxFee);
        minFee = _minFee;
        emit FeeUpdated(minFee, maxFee, percentageFee);
        return true;
    }

    function setMaxFee(uint256 _maxFee) external onlyOwner returns (bool) {
        require(_maxFee >= minFee);
        maxFee = _maxFee;
        emit FeeUpdated(minFee, maxFee, percentageFee);
        return true;
    }

    function setPercentageFee(uint256 _percentageFee)
        external
        onlyOwner
        returns (bool)
    {
        percentageFee = _percentageFee;
        emit FeeUpdated(minFee, maxFee, percentageFee);
        return true;
    }

    function setfeeAccount(address _feeAccount)
        public
        onlyOwner
        returns (bool)
    {
        require(_feeAccount != address(0x0));

        feeAccount = _feeAccount;
        emit FeeAccountUpdated(feeAccount);
        return true;
    }

    function setMiddleware(address _middleware)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _middleware != address(0x0),
            "[Dex] middleware is ZERO Address"
        );
        middleware = _middleware;
        emit MiddlewareChanged(middleware);
        return true;
    }

    function setPauser(address _pauser) public onlyOwner returns (bool) {
        require(_pauser != address(0x0), "[Dex] pauser is ZERO Address");
        pauser = _pauser;
        emit PauserChanged(pauser);
        return true;
    }

    function collectFee(uint256 _fee) internal returns (bool) {
        collectedFee = collectedFee.add(_fee);
        return true;
    }

    function claimFee(uint256 _fee) internal returns (bool) {
        collectedFee = collectedFee.sub(_fee);
        return true;
    }

    function setMinRate(uint8 pair, uint256 rate)
        public
        onlyOwner
        returns (bool)
    {
        require(rate != 0);
        minRate[pair] = rate;
        emit RateUpdated(pair, minRate[pair], maxRate[pair]);
        return true;
    }

    function setMaxRate(uint8 pair, uint256 rate)
        public
        onlyOwner
        returns (bool)
    {
        require(rate >= minRate[pair]);
        maxRate[pair] = rate;
        emit RateUpdated(pair, minRate[pair], maxRate[pair]);
        return true;
    }

    function setMinAmount(uint256 amount) public onlyOwner returns (bool) {
        require(amount != 0);
        minAmount = amount;
        emit AmountUpdated(minAmount, maxAmount);
        return true;
    }

    function setMaxAmount(uint256 amount) public onlyOwner returns (bool) {
        require(amount >= minAmount);
        maxAmount = amount;
        emit AmountUpdated(minAmount, maxAmount);
        return true;
    }
}

interface ILIQUIDITY {
    function balanceOf(string calldata symbol) external view returns (uint256);

    function contractAddress(string calldata symbol)
        external
        view
        returns (address);

    function transfer(
        string calldata symbol,
        address payable recipient,
        uint256 amount
    ) external returns (bool);
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Dex is Ownable, Pausable, Configurations {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    ILIQUIDITY public liquidityContract;

    event FeeWithdrawn(address to, uint256 amount);
    event LiquidityContractUpdated(ILIQUIDITY liquidityContract);
    event Swap(
        address indexed sender,
        string buy,
        string sell,
        uint256 buyAmount,
        uint256 sellAmount,
        uint256 rate,
        uint256 fee
    );

    constructor(
        uint256 _minFee,
        uint256 _maxFee,
        uint256 _percentageFee,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256[] memory _minRate,
        uint256[] memory _maxRate,
        address _feeAccount,
        address _middleware,
        ILIQUIDITY _liquidity
    )
        public
        Configurations(
            _minFee,
            _maxFee,
            _percentageFee,
            _minAmount,
            _maxAmount,
            _minRate,
            _maxRate,
            _feeAccount,
            _middleware
        )
    {
        setLiquidity(_liquidity);
    }

    // Reject incoming ethers
    receive() external payable {
        revert();
    }

    // swap currencies
    function swap(
        string calldata buy,
        string calldata sell,
        uint256 amount,
        uint256 rate,
        uint32 expireTime,
        bytes calldata signature
    ) external payable whenNotPaused returns (bool) {
        if (
            keccak256(bytes(buy)) == keccak256(bytes(baseCurrency)) &&
            keccak256(bytes(sell)) == keccak256(bytes("ETH"))
        ) {
            require(
                _beforeSwap(buy, sell, msg.value, rate, expireTime, signature)
            );
            return swapETHForGSU(rate);
        }

        require(msg.value == 0, "[Dex] ethers are not accepted");
        require(_beforeSwap(buy, sell, amount, rate, expireTime, signature));

        if (
            keccak256(bytes(buy)) == keccak256(bytes("ETH")) &&
            keccak256(bytes(sell)) == keccak256(bytes(baseCurrency))
        ) {
            return swapGSUForETH(amount, rate);
        } else {
            return swapTokens(buy, sell, amount, rate);
        }
    }

    /**
     * @dev Pauses swap.
     *
     * See {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external onlyPauser {
        _pause();
    }

    /**
     * @dev Unpauses swap.
     *
     * See {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external onlyPauser {
        _unpause();
    }

    function withdrawFee(uint256 _fee) external onlyOwner returns (bool) {
        require(_fee <= collectedFee);

        require(
            liquidityContract.transfer(baseCurrency, payable(feeAccount), _fee)
        );

        require(claimFee(_fee), "[Dex] unable to update collected fee");

        emit FeeWithdrawn(feeAccount, _fee);

        return true;
    }

    function setLiquidity(ILIQUIDITY _liquidity)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _liquidity != ILIQUIDITY(address(0x0)),
            "[Dex] liquidityContract is ZERO Address"
        );
        liquidityContract = _liquidity;
        emit LiquidityContractUpdated(liquidityContract);
        return true;
    }

    function _beforeSwap(
        string memory buy,
        string memory sell,
        uint256 amount,
        uint256 rate,
        uint32 expireTime,
        bytes memory signature
    ) private view returns (bool) {
        require(verifySigner(buy, sell, amount, rate, expireTime, signature));
        require(verifySwap(buy, sell, amount, rate, expireTime));
        return true;
    }

    function swapETHForGSU(uint256 rate) private returns (bool) {
        uint256 amountBase = (swapAmount("GSU", "ETH", msg.value, rate));

        (uint256 fee, uint256 netAmount) = chargeFee(amountBase);

        payable(address(liquidityContract)).transfer(msg.value);
        liquidityContract.transfer("GSU", _msgSender(), netAmount);
        emit Swap(_msgSender(), "GSU", "ETH", netAmount, msg.value, rate, fee);
        return true;
    }

    function swapGSUForETH(uint256 amount, uint256 rate)
        private
        returns (bool)
    {
        require(_moveTokensToLiquidity("GSU", amount));

        (uint256 fee, uint256 netAmount) = chargeFee(amount);

        uint256 amountWei = (swapAmount("ETH", "GSU", netAmount, rate));

        require(
            liquidityContract.transfer("ETH", _msgSender(), amountWei),
            "[Dex] error in token tranfer"
        );

        emit Swap(_msgSender(), "ETH", "GSU", amountWei, amount, rate, fee);
        return true;
    }

    function swapTokens(
        string memory buy,
        string memory sell,
        uint256 amount,
        uint256 rate
    ) private returns (bool) {
        uint256 fee;
        uint256 buyAmount;

        require(_moveTokensToLiquidity(sell, amount));

        //if baseCurrency is received deduct fee directly from amount
        if (keccak256(bytes(sell)) == keccak256(bytes(baseCurrency))) {
            (uint256 _fee, uint256 netAmount) = chargeFee(amount);
            buyAmount = (swapAmount(buy, sell, netAmount, rate));
            fee = _fee;
        } else {
            //else convert amount to baseCurrency then deduct fee
            (fee, buyAmount) = chargeFee((swapAmount(buy, sell, amount, rate)));
        }

        // tranfer buyAmount to sender.
        require(
            liquidityContract.transfer(buy, _msgSender(), buyAmount),
            "[Dex] error in token tranfer"
        );

        emit Swap(_msgSender(), buy, sell, buyAmount, amount, rate, fee);

        return true;
    }

    function _moveTokensToLiquidity(string memory currency, uint256 amount)
        private
        returns (bool)
    {
        address _contractAddress = contractAddress(currency);
        require(
            IERC20(_contractAddress).transferFrom(
                _msgSender(),
                address(liquidityContract),
                amount
            ),
            "[Dex] error in tranferFrom"
        );
        return true;
    }

    function chargeFee(uint256 amount)
        internal
        returns (uint256 fee, uint256 netAmount)
    {
        uint256 _fee = calculateFee(amount);
        uint256 _amount = amount.sub(_fee);
        collectFee(_fee);
        return (_fee, _amount);
    }

    function verifySwap(
        string memory buy,
        string memory sell,
        uint256 amount,
        uint256 rate,
        uint32 expireTime
    ) public view whenNotPaused returns (bool) {
        require(expireTime > block.timestamp, "[Dex] rate is expired");
        require(
            rate >= minRate[pairId(buy, sell)],
            "[Dex] rate is less than minRate"
        );
        require(
            rate <= maxRate[pairId(buy, sell)],
            "[Dex] rate is greater than maxRate"
        );

        uint256 _amount = toBaseCurrency(sell, amount, rate);
        require(_amount >= minAmount, "[Dex] amount is less than minAmount");
        require(_amount <= maxAmount, "[Dex] amount is greater than maxAmount");
        require(liquidity(buy) >= _amount, "[Dex] Not enough liquidity");

        return true;
    }

    function pairId(string memory buy, string memory sell)
        private
        view
        returns (uint8)
    {
        string memory _pair = string(abi.encodePacked(buy, "/", sell));
        return pairIndex[_pair];
    }

    function toBaseCurrency(
        string memory from,
        uint256 amount,
        uint256 rate
    ) private view returns (uint256) {
        if (keccak256(bytes(from)) == keccak256(bytes(baseCurrency))) {
            return amount;
        } else {
            return swapAmount("GSU", from, amount, rate);
        }
    }

    function swapAmount(
        string memory buy,
        string memory sell,
        uint256 amount,
        uint256 rate
    ) private view returns (uint256) {
        uint256 exponent = (rateDecimals.add(decimals(buy))).sub(
            decimals(sell)
        );
        return (amount.mul(10**exponent)).div(rate);
    }

    function verifySigner(
        string memory buy,
        string memory sell,
        uint256 amount,
        uint256 rate,
        uint32 expireTime,
        bytes memory signature
    ) public view returns (bool) {
        address signer = keccak256(
            abi.encodePacked(buy, sell, amount, rate, expireTime)
        )
            .recover(signature);

        require(middleware == signer, "[Dex] signer is not middleware");

        return true;
    }

    function decimals(string memory symbol) public view returns (uint256) {
        if (keccak256(bytes(symbol)) == keccak256(bytes("ETH"))) return 18;
        else {
            address contractAddress = liquidityContract.contractAddress(symbol);
            return IERC20(contractAddress).decimals();
        }
    }

    function contractAddress(string memory symbol)
        public
        view
        returns (address)
    {
        return liquidityContract.contractAddress(symbol);
    }

    function liquidity(string memory symbol) public view returns (uint256) {
        return liquidityContract.balanceOf(symbol);
    }

    function calculateFee(uint256 baseAmount) public view returns (uint256) {
        uint256 divisor = uint256(100).mul((10**decimals(baseCurrency)));
        uint256 _fee = (baseAmount.mul(percentageFee)).div(divisor);

        if (_fee < minFee) {
            _fee = minFee;
        } else if (_fee > maxFee) {
            _fee = maxFee;
        }
        return _fee;
    }

    function destroy() external onlyOwner {
        selfdestruct(payable(owner()));
    }
}