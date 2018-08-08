pragma solidity ^0.4.21;

interface ExchangeInterface {

    event Subscribed(address indexed user);
    event Unsubscribed(address indexed user);

    event Cancelled(bytes32 indexed hash);

    event Traded(
        bytes32 indexed hash,
        address makerToken,
        uint makerTokenAmount,
        address takerToken,
        uint takerTokenAmount,
        address maker,
        address taker
    );

    event Ordered(
        address maker,
        address makerToken,
        address takerToken,
        uint makerTokenAmount,
        uint takerTokenAmount,
        uint expires,
        uint nonce
    );

    function subscribe() external;
    function unsubscribe() external;

    function trade(address[3] addresses, uint[4] values, bytes signature, uint maxFillAmount) external;
    function cancel(address[3] addresses, uint[4] values) external;
    function order(address[2] addresses, uint[4] values) external;

    function canTrade(address[3] addresses, uint[4] values, bytes signature)
        external
        view
        returns (bool);

    function isSubscribed(address subscriber) external view returns (bool);
    function availableAmount(address[3] addresses, uint[4] values) external view returns (uint);
    function filled(bytes32 hash) external view returns (uint);
    function isOrdered(address user, bytes32 hash) public view returns (bool);
    function vault() public view returns (VaultInterface);

}

interface VaultInterface {

    event Deposited(address indexed user, address token, uint amount);
    event Withdrawn(address indexed user, address token, uint amount);

    event Approved(address indexed user, address indexed spender);
    event Unapproved(address indexed user, address indexed spender);

    event AddedSpender(address indexed spender);
    event RemovedSpender(address indexed spender);

    function deposit(address token, uint amount) external payable;
    function withdraw(address token, uint amount) external;
    function transfer(address token, address from, address to, uint amount) external;
    function approve(address spender) external;
    function unapprove(address spender) external;
    function isApproved(address user, address spender) external view returns (bool);
    function addSpender(address spender) external;
    function removeSpender(address spender) external;
    function latestSpender() external view returns (address);
    function isSpender(address spender) external view returns (bool);
    function tokenFallback(address from, uint value, bytes data) public;
    function balanceOf(address token, address user) public view returns (uint);

}

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    function min256(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

library SignatureValidator {

    enum SignatureMode {
        EIP712,
        GETH,
        TREZOR
    }

    /// @dev Validates that a hash was signed by a specified signer.
    /// @param hash Hash which was signed.
    /// @param signer Address of the signer.
    /// @param signature ECDSA signature along with the mode (0 = EIP712, 1 = Geth, 2 = Trezor) {mode}{v}{r}{s}.
    /// @return Returns whether signature is from a specified user.
    function isValidSignature(bytes32 hash, address signer, bytes signature) internal pure returns (bool) {
        require(signature.length == 66);
        SignatureMode mode = SignatureMode(uint8(signature[0]));

        uint8 v = uint8(signature[1]);
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(signature, 34))
            s := mload(add(signature, 66))
        }

        if (mode == SignatureMode.GETH) {
            hash = keccak256("\x19Ethereum Signed Message:\n32", hash);
        } else if (mode == SignatureMode.TREZOR) {
            hash = keccak256("\x19Ethereum Signed Message:\n\x20", hash);
        }

        return ecrecover(hash, v, r, s) == signer;
    }
}

library OrderLibrary {

    bytes32 constant public HASH_SCHEME = keccak256(
        "address Taker Token",
        "uint Taker Token Amount",
        "address Maker Token",
        "uint Maker Token Amount",
        "uint Expires",
        "uint Nonce",
        "address Maker",
        "address Exchange"
    );

    struct Order {
        address maker;
        address makerToken;
        address takerToken;
        uint makerTokenAmount;
        uint takerTokenAmount;
        uint expires;
        uint nonce;
    }

    /// @dev Hashes the order.
    /// @param order Order to be hashed.
    /// @return hash result
    function hash(Order memory order) internal view returns (bytes32) {
        return keccak256(
            HASH_SCHEME,
            keccak256(
                order.takerToken,
                order.takerTokenAmount,
                order.makerToken,
                order.makerTokenAmount,
                order.expires,
                order.nonce,
                order.maker,
                this
            )
        );
    }

    /// @dev Creates order struct from value arrays.
    /// @param addresses Array of trade&#39;s maker, makerToken and takerToken.
    /// @param values Array of trade&#39;s makerTokenAmount, takerTokenAmount, expires and nonce.
    /// @return Order struct
    function createOrder(address[3] addresses, uint[4] values) internal pure returns (Order memory) {
        return Order({
            maker: addresses[0],
            makerToken: addresses[1],
            takerToken: addresses[2],
            makerTokenAmount: values[0],
            takerTokenAmount: values[1],
            expires: values[2],
            nonce: values[3]
        });
    }
}

contract Ownable {

    address public owner;

    modifier onlyOwner {
        require(isOwner(msg.sender));
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function isOwner(address _address) public view returns (bool) {
        return owner == _address;
    }
}

interface ERC20 {

    function totalSupply() public view returns (uint);
    function balanceOf(address owner) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);

}

interface HookSubscriber {

    function tradeExecuted(address token, uint amount) external;

}

contract Exchange is Ownable, ExchangeInterface {

    using SafeMath for *;
    using OrderLibrary for OrderLibrary.Order;

    address constant public ETH = 0x0;

    uint256 constant public MAX_FEE = 5000000000000000; // 0.5% ((0.5 / 100) * 10**18)
    uint256 constant private MAX_ROUNDING_PERCENTAGE = 1000; // 0.1%
    
    uint256 constant private MAX_HOOK_GAS = 40000; // enough for a storage write and some accounting logic

    VaultInterface public vault;

    uint public takerFee = 0;
    address public feeAccount;

    mapping (address => mapping (bytes32 => bool)) private orders;
    mapping (bytes32 => uint) private fills;
    mapping (bytes32 => bool) private cancelled;
    mapping (address => bool) private subscribed;

    function Exchange(uint _takerFee, address _feeAccount, VaultInterface _vault) public {
        require(address(_vault) != 0x0);
        setFees(_takerFee);
        setFeeAccount(_feeAccount);
        vault = _vault;
    }

    /// @dev Withdraws tokens accidentally sent to this contract.
    /// @param token Address of the token to withdraw.
    /// @param amount Amount of tokens to withdraw.
    function withdraw(address token, uint amount) external onlyOwner {
        if (token == ETH) {
            msg.sender.transfer(amount);
            return;
        }

        ERC20(token).transfer(msg.sender, amount);
    }

    /// @dev Subscribes user to trade hooks.
    function subscribe() external {
        require(!subscribed[msg.sender]);
        subscribed[msg.sender] = true;
        emit Subscribed(msg.sender);
    }

    /// @dev Unsubscribes user from trade hooks.
    function unsubscribe() external {
        require(subscribed[msg.sender]);
        subscribed[msg.sender] = false;
        emit Unsubscribed(msg.sender);
    }

    /// @dev Takes an order.
    /// @param addresses Array of trade&#39;s maker, makerToken and takerToken.
    /// @param values Array of trade&#39;s makerTokenAmount, takerTokenAmount, expires and nonce.
    /// @param signature Signed order along with signature mode.
    /// @param maxFillAmount Maximum amount of the order to be filled.
    function trade(address[3] addresses, uint[4] values, bytes signature, uint maxFillAmount) external {
        trade(OrderLibrary.createOrder(addresses, values), msg.sender, signature, maxFillAmount);
    }

    /// @dev Cancels an order.
    /// @param addresses Array of trade&#39;s maker, makerToken and takerToken.
    /// @param values Array of trade&#39;s makerTokenAmount, takerTokenAmount, expires and nonce.
    function cancel(address[3] addresses, uint[4] values) external {
        OrderLibrary.Order memory order = OrderLibrary.createOrder(addresses, values);

        require(msg.sender == order.maker);
        require(order.makerTokenAmount > 0 && order.takerTokenAmount > 0);

        bytes32 hash = order.hash();
        require(fills[hash] < order.takerTokenAmount);
        require(!cancelled[hash]);

        cancelled[hash] = true;
        emit Cancelled(hash);
    }

    /// @dev Creates an order which is then indexed in the orderbook.
    /// @param addresses Array of trade&#39;s makerToken and takerToken.
    /// @param values Array of trade&#39;s makerTokenAmount, takerTokenAmount, expires and nonce.
    function order(address[2] addresses, uint[4] values) external {
        OrderLibrary.Order memory order = OrderLibrary.createOrder(
            [msg.sender, addresses[0], addresses[1]],
            values
        );

        require(vault.isApproved(order.maker, this));
        require(vault.balanceOf(order.makerToken, order.maker) >= order.makerTokenAmount);
        require(order.makerToken != order.takerToken);
        require(order.makerTokenAmount > 0);
        require(order.takerTokenAmount > 0);

        bytes32 hash = order.hash();

        require(!orders[msg.sender][hash]);
        orders[msg.sender][hash] = true;

        emit Ordered(
            order.maker,
            order.makerToken,
            order.takerToken,
            order.makerTokenAmount,
            order.takerTokenAmount,
            order.expires,
            order.nonce
        );
    }

    /// @dev Checks if a order can be traded.
    /// @param addresses Array of trade&#39;s maker, makerToken and takerToken.
    /// @param values Array of trade&#39;s makerTokenAmount, takerTokenAmount, expires and nonce.
    /// @param signature Signed order along with signature mode.
    /// @return Boolean if order can be traded
    function canTrade(address[3] addresses, uint[4] values, bytes signature)
        external
        view
        returns (bool)
    {
        OrderLibrary.Order memory order = OrderLibrary.createOrder(addresses, values);

        bytes32 hash = order.hash();

        return canTrade(order, signature, hash);
    }

    /// @dev Returns if user has subscribed to trade hooks.
    /// @param subscriber Address of the subscriber.
    /// @return Boolean if user is subscribed.
    function isSubscribed(address subscriber) external view returns (bool) {
        return subscribed[subscriber];
    }

    /// @dev Checks how much of an order can be filled.
    /// @param addresses Array of trade&#39;s maker, makerToken and takerToken.
    /// @param values Array of trade&#39;s makerTokenAmount, takerTokenAmount, expires and nonce.
    /// @return Amount of the order which can be filled.
    function availableAmount(address[3] addresses, uint[4] values) external view returns (uint) {
        OrderLibrary.Order memory order = OrderLibrary.createOrder(addresses, values);
        return availableAmount(order, order.hash());
    }

    /// @dev Returns how much of an order was filled.
    /// @param hash Hash of the order.
    /// @return Amount which was filled.
    function filled(bytes32 hash) external view returns (uint) {
        return fills[hash];
    }

    /// @dev Sets the taker fee.
    /// @param _takerFee New taker fee.
    function setFees(uint _takerFee) public onlyOwner {
        require(_takerFee <= MAX_FEE);
        takerFee = _takerFee;
    }

    /// @dev Sets the account where fees will be transferred to.
    /// @param _feeAccount Address for the account.
    function setFeeAccount(address _feeAccount) public onlyOwner {
        require(_feeAccount != 0x0);
        feeAccount = _feeAccount;
    }

    function vault() public view returns (VaultInterface) {
        return vault;
    }

    /// @dev Checks if an order was created on chain.
    /// @param user User who created the order.
    /// @param hash Hash of the order.
    /// @return Boolean if the order was created on chain.
    function isOrdered(address user, bytes32 hash) public view returns (bool) {
        return orders[user][hash];
    }

    /// @dev Executes the actual trade by transferring balances.
    /// @param order Order to be traded.
    /// @param taker Address of the taker.
    /// @param signature Signed order along with signature mode.
    /// @param maxFillAmount Maximum amount of the order to be filled.
    function trade(OrderLibrary.Order memory order, address taker, bytes signature, uint maxFillAmount) internal {
        require(taker != order.maker);
        bytes32 hash = order.hash();

        require(order.makerToken != order.takerToken);
        require(canTrade(order, signature, hash));

        uint fillAmount = SafeMath.min256(maxFillAmount, availableAmount(order, hash));

        require(roundingPercent(fillAmount, order.takerTokenAmount, order.makerTokenAmount) <= MAX_ROUNDING_PERCENTAGE);
        require(vault.balanceOf(order.takerToken, taker) >= fillAmount);

        uint makeAmount = order.makerTokenAmount.mul(fillAmount).div(order.takerTokenAmount);
        uint tradeTakerFee = makeAmount.mul(takerFee).div(1 ether);

        if (tradeTakerFee > 0) {
            vault.transfer(order.makerToken, order.maker, feeAccount, tradeTakerFee);
        }

        vault.transfer(order.takerToken, taker, order.maker, fillAmount);
        vault.transfer(order.makerToken, order.maker, taker, makeAmount.sub(tradeTakerFee));

        fills[hash] = fills[hash].add(fillAmount);
        assert(fills[hash] <= order.takerTokenAmount);

        if (subscribed[order.maker]) {
            order.maker.call.gas(MAX_HOOK_GAS)(HookSubscriber(order.maker).tradeExecuted.selector, order.takerToken, fillAmount);
        }

        emit Traded(
            hash,
            order.makerToken,
            makeAmount,
            order.takerToken,
            fillAmount,
            order.maker,
            taker
        );
    }

    /// @dev Indicates whether or not an certain amount of an order can be traded.
    /// @param order Order to be traded.
    /// @param signature Signed order along with signature mode.
    /// @param hash Hash of the order.
    /// @return Boolean if order can be traded
    function canTrade(OrderLibrary.Order memory order, bytes signature, bytes32 hash)
        internal
        view
        returns (bool)
    {
        // if the order has never been traded against, we need to check the sig.
        if (fills[hash] == 0) {
            // ensures order was either created on chain, or signature is valid
            if (!isOrdered(order.maker, hash) && !SignatureValidator.isValidSignature(hash, order.maker, signature)) {
                return false;
            }
        }

        if (cancelled[hash]) {
            return false;
        }

        if (!vault.isApproved(order.maker, this)) {
            return false;
        }

        if (order.takerTokenAmount == 0) {
            return false;
        }

        if (order.makerTokenAmount == 0) {
            return false;
        }

        // ensures that the order still has an available amount to be filled.
        if (availableAmount(order, hash) == 0) {
            return false;
        }

        return order.expires > now;
    }

    /// @dev Returns the maximum available amount that can be taken of an order.
    /// @param order Order to check.
    /// @param hash Hash of the order.
    /// @return Amount of the order that can be filled.
    function availableAmount(OrderLibrary.Order memory order, bytes32 hash) internal view returns (uint) {
        return SafeMath.min256(
            order.takerTokenAmount.sub(fills[hash]),
            vault.balanceOf(order.makerToken, order.maker).mul(order.takerTokenAmount).div(order.makerTokenAmount)
        );
    }

    /// @dev Returns the percentage which was rounded when dividing.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with.
    /// @return Percentage rounded.
    function roundingPercent(uint numerator, uint denominator, uint target) internal pure returns (uint) {
        // Inspired by https://github.com/0xProject/contracts/blob/1.0.0/contracts/Exchange.sol#L472-L490
        uint remainder = mulmod(target, numerator, denominator);
        if (remainder == 0) {
            return 0;
        }

        return remainder.mul(1000000).div(numerator.mul(target));
    }
}