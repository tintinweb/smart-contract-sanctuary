/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-04
 */

/**
 *Submitted for verification at Etherscan.io on 2018-06-12
 */

pragma solidity ^0.4.13;

library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library ArrayUtils {
    /**
     * Replace bytes in an array with bytes in another array, guarded by a bitmask
     * Efficiency of this function is a bit unpredictable because of the EVM's word-specific model (arrays under 32 bytes will be slower)
     *
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     * @return The updated byte array (the parameter will be modified inplace)
     */
    function guardedArrayReplace(
        bytes memory array,
        bytes memory desired,
        bytes memory mask
    ) internal pure {
        require(array.length == desired.length);
        require(array.length == mask.length);

        uint256 words = array.length / 0x20;
        uint256 index = words * 0x20;
        assert(index / 0x20 == words);
        uint256 i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] =
                    ((mask[i] ^ 0xff) & array[i]) |
                    (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     *
     * @dev Arrays must be of equal length, otherwise will return false
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(a)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(b))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(a, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(b, 0x20)
                    // the next line is the loop condition:
                    // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint256 index, bytes source)
        internal
        pure
        returns (uint256)
    {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for {

                } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint256 index, address source)
        internal
        pure
        returns (uint256)
    {
        uint256 conv = uint256(source) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint256 index, uint256 source)
        internal
        pure
        returns (uint256)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint256 index, uint8 source)
        internal
        pure
        returns (uint256)
    {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }
}

contract ReentrancyGuarded {
    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard() {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }
}

contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint256 amount);
    event ReceivedTokens(
        address indexed from,
        uint256 value,
        address indexed token,
        bytes extraData
    );

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(
        address from,
        uint256 value,
        address token,
        bytes extraData
    ) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, this, value));
        emit ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    function() public payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

library SaleKindInterface {
    /**
     * Side: buy or sell.
     */
    enum Side {
        Buy,
        Sell
    }

    /**
     * Currently supported kinds of sale: fixed price, Dutch auction.
     * English auctions cannot be supported without stronger escrow guarantees.
     * Future interesting options: Vickrey auction, nonlinear Dutch auctions.
     */
    enum SaleKind {
        FixedPrice,
        DutchAuction
    }

    /**
     * @dev Check whether the parameters of a sale are valid
     * @param saleKind Kind of sale
     * @param expirationTime Order expiration time
     * @return Whether the parameters were valid
     */
    function validateParameters(SaleKind saleKind, uint256 expirationTime)
        internal
        pure
        returns (bool)
    {
        /* Auctions must have a set expiration date. */
        return (saleKind == SaleKind.FixedPrice || expirationTime > 0);
    }

    /**
     * @dev Return whether or not an order can be settled
     * @dev Precondition: parameters have passed validateParameters
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function canSettleOrder(uint256 listingTime, uint256 expirationTime)
        internal
        view
        returns (bool)
    {
        return
            (listingTime < now) &&
            (expirationTime == 0 || now < expirationTime);
    }

    /**
     * @dev Calculate the settlement price of an order
     * @dev Precondition: parameters have passed validateParameters.
     * @param side Order side
     * @param saleKind Method of sale
     * @param basePrice Order base price
     * @param extra Order extra price data
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function calculateFinalPrice(
        Side side,
        SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    ) internal view returns (uint256 finalPrice) {
        if (saleKind == SaleKind.FixedPrice) {
            return basePrice;
        } else if (saleKind == SaleKind.DutchAuction) {
            uint256 diff = SafeMath.div(
                SafeMath.mul(extra, SafeMath.sub(now, listingTime)),
                SafeMath.sub(expirationTime, listingTime)
            );
            if (side == Side.Sell) {
                /* Sell-side - start price: basePrice. End price: basePrice - extra. */
                return SafeMath.sub(basePrice, diff);
            } else {
                /* Buy-side - start price: basePrice. End price: basePrice + extra. */
                return SafeMath.add(basePrice, diff);
            }
        }
    }
}

contract ProxyRegistry is Ownable {
    /* DelegateProxy implementation contract. Must be initialized. */
    address public delegateProxyImplementation;

    /* Authenticated proxies by user. */
    mapping(address => OwnableDelegateProxy) public proxies;

    /* Contracts pending access. */
    mapping(address => uint256) public pending;

    /* Contracts allowed to call those proxies. */
    mapping(address => bool) public contracts;

    /* Delay period for adding an authenticated contract.
       This mitigates a particular class of potential attack on the PlaNFT DAO (which owns this registry) - if at any point the value of assets held by proxy contracts exceeded the value of half the WYV supply (votes in the DAO),
       a malicious but rational attacker could buy half the PlaNFT and grant themselves access to all the proxy contracts. A delay period renders this attack nonthreatening - given two weeks, if that happened, users would have
       plenty of time to notice and transfer their assets.
    */
    uint256 public DELAY_PERIOD = 2 weeks;

    /**
     * Start the process to enable access for specified contract. Subject to delay period.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function startGrantAuthentication(address addr) public onlyOwner {
        require(!contracts[addr] && pending[addr] == 0);
        pending[addr] = now;
    }

    /**
     * End the process to nable access for specified contract after delay period has passed.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function endGrantAuthentication(address addr) public onlyOwner {
        require(
            !contracts[addr] &&
                pending[addr] != 0 &&
                ((pending[addr] + DELAY_PERIOD) < now)
        );
        pending[addr] = 0;
        contracts[addr] = true;
    }

    /**
     * Revoke access for specified contract. Can be done instantly.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address of which to revoke permissions
     */
    function revokeAuthentication(address addr) public onlyOwner {
        contracts[addr] = false;
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return New AuthenticatedProxy contract
     */
    function registerProxy() public returns (OwnableDelegateProxy proxy) {
        require(proxies[msg.sender] == address(0));
        proxy = new OwnableDelegateProxy(
            msg.sender,
            delegateProxyImplementation,
            abi.encodeWithSignature(
                "initialize(address,address)",
                msg.sender,
                address(this)
            )
        );
        proxies[msg.sender] = proxy;
        return proxy;
    }
}

contract TokenTransferProxy {
    /* Authentication registry. */
    ProxyRegistry public registry;

    /**
     * Call ERC20 `transferFrom`
     *
     * @dev Authenticated contract only
     * @param token ERC20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(registry.contracts(msg.sender));
        return ERC20(token).transferFrom(from, to, amount);
    }
}

contract OwnedUpgradeabilityStorage {
    // Current implementation
    address internal _implementation;

    // Owner of the contract
    address private _upgradeabilityOwner;

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    /**
     * @dev Sets the address of the owner
     */
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }

    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() public view returns (address) {
        return _implementation;
    }

    /**
     * @dev Tells the proxy type (EIP 897)
     * @return Proxy type, 2 for forwarding proxy
     */
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return 2;
    }
}

contract AuthenticatedProxy is TokenRecipient, OwnedUpgradeabilityStorage {
    /* Whether initialized. */
    bool initialized = false;

    /* Address which owns this proxy. */
    address public user;

    /* Associated registry with contract authentication information. */
    ProxyRegistry public registry;

    /* Whether access has been revoked. */
    bool public revoked;

    /* Delegate call could be used to atomically transfer multiple assets owned by the proxy contract with one order. */
    enum HowToCall {
        Call,
        DelegateCall
    }

    /* Event fired when the proxy access is revoked or unrevoked. */
    event Revoked(bool revoked);

    /**
     * Initialize an AuthenticatedProxy
     *
     * @param addrUser Address of user on whose behalf this proxy will act
     * @param addrRegistry Address of ProxyRegistry contract which will manage this proxy
     */
    function initialize(address addrUser, ProxyRegistry addrRegistry) public {
        require(!initialized);
        initialized = true;
        user = addrUser;
        registry = addrRegistry;
    }

    /**
     * Set the revoked flag (allows a user to revoke ProxyRegistry access)
     *
     * @dev Can be called by the user only
     * @param revoke Whether or not to revoke access
     */
    function setRevoke(bool revoke) public {
        require(msg.sender == user);
        revoked = revoke;
        emit Revoked(revoke);
    }

    /**
     * Execute a message call from the proxy contract
     *
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param calldata Calldata to send
     * @return Result of the call (success or failure)
     */
    function proxy(
        address dest,
        HowToCall howToCall,
        bytes calldata
    ) public returns (bool result) {
        require(
            msg.sender == user || (!revoked && registry.contracts(msg.sender))
        );
        if (howToCall == HowToCall.Call) {
            result = dest.call(calldata);
        } else if (howToCall == HowToCall.DelegateCall) {
            result = dest.delegatecall(calldata);
        }
        return result;
    }

    /**
     * Execute a message call and assert success
     *
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall What kind of call to make
     * @param calldata Calldata to send
     */
    function proxyAssert(
        address dest,
        HowToCall howToCall,
        bytes calldata
    ) public {
        require(proxy(dest, howToCall, calldata));
    }
}

contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() public view returns (address);

    /**
     * @dev Tells the type of proxy (EIP 897)
     * @return Type of proxy, 2 for upgradeable proxy
     */
    function proxyType() public pure returns (uint256 proxyTypeId);

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    function() public payable {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}

contract OwnedUpgradeabilityProxy is Proxy, OwnedUpgradeabilityStorage {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Upgrades the implementation address
     * @param implementation representing the address of the new implementation to be set
     */
    function _upgradeTo(address implementation) internal {
        require(_implementation != implementation);
        _implementation = implementation;
        emit Upgraded(implementation);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

    /**
     * @dev Tells the address of the proxy owner
     * @return the address of the proxy owner
     */
    function proxyOwner() public view returns (address) {
        return upgradeabilityOwner();
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0));
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy.
     * @param implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address implementation) public onlyProxyOwner {
        _upgradeTo(implementation);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy
     * and delegatecall the new implementation for initialization.
     * @param implementation representing the address of the new implementation to be set.
     * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address implementation, bytes data)
        public
        payable
        onlyProxyOwner
    {
        upgradeTo(implementation);
        require(address(this).delegatecall(data));
    }
}

contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {
    constructor(
        address owner,
        address initialImplementation,
        bytes calldata
    ) public {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        require(initialImplementation.delegatecall(calldata));
    }
}

contract PlaNFTProxyRegistry is ProxyRegistry {
    string public constant name = "Project PlaNFT Proxy Registry";

    /* Whether the initial auth address has been set. */
    bool public initialAddressSet = false;

    constructor() public {
        delegateProxyImplementation = new AuthenticatedProxy();
    }

    /**
     * Grant authentication to the initial Exchange protocol contract
     *
     * @dev No delay, can only be called once - after that the standard registry process with a delay must be used
     * @param baseAddress Address of the contract to grant authentication
     * @param extraAddress Address of the contract to grant authentication
     */
    function grantInitialAuthentication(
        address baseAddress,
        address extraAddress
    ) public onlyOwner {
        require(!initialAddressSet);
        initialAddressSet = true;
        contracts[baseAddress] = true;
        contracts[extraAddress] = true;
    }
}

contract PlaNFTTokenTransferProxy is TokenTransferProxy {
    constructor(ProxyRegistry registryAddr) public {
        registry = registryAddr;
    }
}

contract ExchangeCore is ReentrancyGuarded, Ownable {
    /* The token used to pay exchange fees. */
    ERC20 public exchangeToken;

    /* User registry. */
    ProxyRegistry public registry;

    /* Token transfer proxy. */
    TokenTransferProxy public tokenTransferProxy;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized2;

    /* Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
    mapping(bytes32 => bool) public approvedOrders;

    /* Orders match index. */
    mapping(bytes32 => uint256) public matchIndex;

    /* Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
    mapping(bytes32 => bool) public approvedOrders2;

    /* Orders match offset. */
    mapping(bytes32 => uint256) public matchIndex2;

    /* For split fee orders, minimum required protocol maker fee, in basis points. Paid to owner (who can change it). */
    uint256 public minimumMakerProtocolFee = 0;

    /* For split fee orders, minimum required protocol taker fee, in basis points. Paid to owner (who can change it). */
    uint256 public minimumTakerProtocolFee = 0;

    /* Recipient of protocol fees. */
    address public protocolFeeRecipient;

    /* Fee method: protocol fee or split fee. */
    enum FeeMethod {
        ProtocolFee,
        SplitFee
    }

    /* Order type: random order or scope order. */
    enum OrderType {
        RandomOrder,
        ScopeOrder
    }

    //exchange fee to owner
    uint256 public _exchangeFee = 250;

    //exchange fee to owner
    uint256 public _relayExchangeFee = 250;

    /* Recipient of protocol fees. */
    address public _rewardFeeRecipient;

    /* Recipient of protocol fees. */
    address public _relayRewardFeeRecipient;

    /* Inverse basis point. */
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    // Delay to set fee
    uint256 public _delaySetFeeTime = 1 days;

    // Relay to set fee
    uint256 public _relaySetFeeTime = 0;

    // Delay to set fee
    uint256 public _delaySetFeeRecipientTime = 3 days;

    // Relay to set fee
    uint256 public _relaySetFeeRecipientTime = 0;

    // /* An ECDSA signature. */
    // struct Sig {
    //     /* v parameter */
    //     uint8 v;
    //     /* r parameter */
    //     bytes32 r;
    //     /* s parameter */
    //     bytes32 s;
    // }

    /* An order on the exchange. */
    struct Order {
        /* Exchange address, intended as a versioning mechanism. */
        address exchange;
        /* Order maker address. */
        address maker;
        /* Order taker address, if specified. */
        address taker;
        /* Maker relayer fee of the order, unused for taker order. */
        uint256 makerRelayerFee;
        /* Taker relayer fee of the order, or maximum taker fee for a taker order. */
        uint256 takerRelayerFee;
        /* Maker protocol fee of the order, unused for taker order. */
        uint256 makerProtocolFee;
        /* Taker protocol fee of the order, or maximum taker fee for a taker order. */
        uint256 takerProtocolFee;
        /* nft minter. */
        address minter;
        /* OrderType (random order or scope order.). */
        OrderType orderType;
        /* Fee method (protocol token or split fee). */
        FeeMethod feeMethod;
        /* Side (buy/sell). */
        SaleKindInterface.Side side;
        /* Kind of sale. */
        SaleKindInterface.SaleKind saleKind;
        /* Target. */
        address target;
        /* HowToCall. */
        AuthenticatedProxy.HowToCall howToCall;
        /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint256 basePrice;
        /* Auction extra parameter - minimum bid increment for English auctions, starting/ending price difference. */
        uint256 extra;
        /* Listing timestamp. */
        uint256 listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint256 salt;
    }

    event OrderApproved(
        bytes32 indexed hash,
        address indexed maker,
        uint256 makerRelayerFee,
        uint256 takerRelayerFee,
        uint256 makerProtocolFee,
        uint256 takerProtocolFee,
        address indexed minter
    );
    event OrderCancelled(bytes32 indexed hash);
    event OrdersMatched(
        bytes32 buyHash,
        bytes32 sellHash,
        address indexed maker,
        address indexed taker,
        uint256 price
    );
    event RelaySetFee(
        address owner,
        uint256 relaySetFeeTime,
        uint256 relayExchangeFee
    );
    event SetFee(address owner, uint256 exchangeFee);
    event RelaySetRecipientFee(
        address owner,
        address relayRewardFeeRecipient,
        uint256 relaySetFeeRecipientTime
    );
    event SetFeeRecipient(address owner, address rewardFeeRecipient);

    function setFee(uint256 exchangeFee_) public onlyOwner {
        require(_relaySetFeeTime != 0, "PlaNFT: _relaySetFee not call");
        require(
            _relayExchangeFee == exchangeFee_,
            "PlaNFT: _relayExchangeFee not equal exchangeFee_"
        );
        require(
            _relaySetFeeTime + _delaySetFeeTime <= block.timestamp,
            "Pla_TNFT: _delaySetFeeTime not arrive"
        );
        _relaySetFeeTime = 0;
        _exchangeFee = exchangeFee_;
        emit SetFee(msg.sender, _exchangeFee);
    }

    function relaySetFee(uint256 relayExchangeFee_) public onlyOwner {
        _relaySetFeeTime = block.timestamp;
        _relayExchangeFee = relayExchangeFee_;
        emit RelaySetFee(msg.sender, _relayExchangeFee, _relaySetFeeTime);
    }

    function setFeeRecipient(address rewardFeeRecipient_) public onlyOwner {
        require(
            _relaySetFeeRecipientTime != 0,
            "PlaNFT: _relaySetFee not call"
        );
        require(
            _relayRewardFeeRecipient == rewardFeeRecipient_,
            "PlaNFT: _relayRewardFeeRecipient not equal rewardFeeRecipient_"
        );
        require(
            _relaySetFeeRecipientTime + _delaySetFeeRecipientTime <=
                block.timestamp,
            "Pla_TNFT: _delaySetFeeTime not arrive"
        );
        _relaySetFeeRecipientTime = 0;
        _rewardFeeRecipient = rewardFeeRecipient_;
        emit SetFeeRecipient(msg.sender, _rewardFeeRecipient);
    }

    function relaySetFeeRecipient(address relayRewardFeeRecipient_)
        public
        onlyOwner
    {
        _relaySetFeeRecipientTime = block.timestamp;
        _relayRewardFeeRecipient = relayRewardFeeRecipient_;
        emit RelaySetRecipientFee(
            msg.sender,
            _relayRewardFeeRecipient,
            _relaySetFeeRecipientTime
        );
    }

    /**
     * @dev Change the minimum maker fee paid to the protocol (owner only)
     * @param newMinimumMakerProtocolFee New fee to set in basis points
     */
    function changeMinimumMakerProtocolFee(uint256 newMinimumMakerProtocolFee)
        public
        onlyOwner
    {
        minimumMakerProtocolFee = newMinimumMakerProtocolFee;
    }

    /**
     * @dev Change the minimum taker fee paid to the protocol (owner only)
     * @param newMinimumTakerProtocolFee New fee to set in basis points
     */
    function changeMinimumTakerProtocolFee(uint256 newMinimumTakerProtocolFee)
        public
        onlyOwner
    {
        minimumTakerProtocolFee = newMinimumTakerProtocolFee;
    }

    /**
     * @dev Change the protocol fee recipient (owner only)
     * @param newProtocolFeeRecipient New protocol fee recipient address
     */
    function changeProtocolFeeRecipient(address newProtocolFeeRecipient)
        public
        onlyOwner
    {
        protocolFeeRecipient = newProtocolFeeRecipient;
    }

    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            require(tokenTransferProxy.transferFrom(token, from, to, amount));
        }
    }

    /**
     * @dev Charge a fee in protocol tokens
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function chargeProtocolFee(
        address from,
        address to,
        uint256 amount
    ) internal {
        transferTokens(exchangeToken, from, to, amount);
    }

    function sizeOf(Order memory order, uint256 length)
        internal
        pure
        returns (uint256)
    {
        return ((0x14 * 6) + (0x20 * (9 + length)) + 5);
    }

    function hashOrder(Order memory order, uint256[] tokens)
        internal
        pure
        returns (bytes32 hash)
    {
        /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
        uint256 size = sizeOf(order, tokens.length);
        bytes memory array = new bytes(size);
        uint256 index;
        assembly {
            index := add(array, 0x20)
        }
        index = ArrayUtils.unsafeWriteAddress(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddress(index, order.maker);
        index = ArrayUtils.unsafeWriteAddress(index, order.taker);
        index = ArrayUtils.unsafeWriteUint(index, order.makerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.makerProtocolFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerProtocolFee);
        index = ArrayUtils.unsafeWriteAddress(index, order.minter);
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.orderType));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.feeMethod));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.saleKind));
        index = ArrayUtils.unsafeWriteAddress(index, order.target);
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.howToCall));
        index = ArrayUtils.unsafeWriteAddress(index, order.paymentToken);
        index = ArrayUtils.unsafeWriteUint(index, order.basePrice);
        index = ArrayUtils.unsafeWriteUint(index, order.extra);
        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
        index = ArrayUtils.unsafeWriteUint(index, order.salt);
        for (uint256 i = 0; i < tokens.length; i++) {
            index = ArrayUtils.unsafeWriteUint(index, tokens[i]);
        }
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
        return hash;
    }

    function hashToSign(Order memory order, uint256[] tokens)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                "\x19Ethereum Signed Message:\n32",
                hashOrder(order, tokens)
            );
    }

    function requireValidOrder(Order memory order, uint256[] tokens)
        internal
        view
        returns (bytes32)
    {
        bytes32 hash = hashToSign(order, tokens);
        require(validateOrder(hash, order));
        return hash;
    }

    function validateOrderParameters(Order memory order)
        internal
        view
        returns (bool)
    {
        /* Order must be targeted at this protocol version (this Exchange contract). */
        if (order.exchange != address(this)) {
            return false;
        }

        /* Order must possess valid sale kind parameter combination. */
        if (
            !SaleKindInterface.validateParameters(
                order.saleKind,
                order.expirationTime
            )
        ) {
            return false;
        }

        /* If using the split fee method, order must have sufficient protocol fees. */
        if (
            order.feeMethod == FeeMethod.SplitFee &&
            (order.makerProtocolFee < minimumMakerProtocolFee ||
                order.takerProtocolFee < minimumTakerProtocolFee)
        ) {
            return false;
        }

        return true;
    }

    function validateOrder(bytes32 hash, Order memory order)
        internal
        view
        returns (bool)
    {
        /* Not done in an if-conditional to prevent unnecessary ecrecover evaluation, which seems to happen even though it should short-circuit. */

        /* Order must have valid parameters. */
        if (!validateOrderParameters(order)) {
            return false;
        }

        if (order.orderType == OrderType.RandomOrder) {
            /* Order must have not been canceled or already filled. */
            if (cancelledOrFinalized[hash]) {
                return false;
            }

            /* Order authentication. Order must be either:
            /* (a) previously approved */
            if (approvedOrders[hash]) {
                return true;
            }
        } else {
            /* Order must have not been canceled or already filled. */
            if (cancelledOrFinalized2[hash]) {
                return false;
            }

            /* Order authentication. Order must be either:
            /* (a) previously approved */
            if (approvedOrders2[hash]) {
                return true;
            }
        }

        // /* or (b) ECDSA-signed by maker. */
        // if (ecrecover(hash, sig.v, sig.r, sig.s) == order.maker) {
        //     return true;
        // }

        return false;
    }

    function approveOrder(Order memory order, uint256[] tokens) internal {
        /* CHECKS */

        /* Assert sender is authorized to approve order. */
        require(msg.sender == order.maker);

        /* Calculate order hash. */
        bytes32 hash = hashToSign(order, tokens);

        if (order.orderType == OrderType.RandomOrder) {
            require(
                tokens.length > 0,
                "PlaExchange: size must bigger than zero"
            );
            /* Assert order has not already been approved. */
            require(!approvedOrders[hash]);
            /* EFFECTS */

            /* Mark order as approved. */
            approvedOrders[hash] = true;

            matchIndex[hash] = 0;
        } else {
            require(tokens.length == 2, "PlaExchange: tokens scope illegal");
            /* Assert order has not already been approved. */
            require(!approvedOrders2[hash]);
            /* EFFECTS */

            /* Mark order as approved. */
            approvedOrders2[hash] = true;

            matchIndex2[hash] = 0;
        }

        /* Log approval event. */
        emit OrderApproved(
            hash,
            order.maker,
            order.makerRelayerFee,
            order.takerRelayerFee,
            order.makerProtocolFee,
            order.takerProtocolFee,
            order.minter
        );
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     */
    function cancelOrder(Order memory order, uint256[] tokens) internal {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, tokens);

        /* Assert sender is authorized to cancel order. */
        require(msg.sender == order.maker);

        /* EFFECTS */

        /* Mark order as cancelled, preventing it from being matched. */
        order.orderType == OrderType.RandomOrder
            ? cancelledOrFinalized[hash] = true
            : cancelledOrFinalized2[hash] = true;

        /* Log cancel event. */
        emit OrderCancelled(hash);
    }

    /**
     * @dev Calculate the current price of an order (convenience function)
     * @param order Order to calculate the price of
     * @return The current price of the order
     */
    function calculateCurrentPrice(Order memory order)
        internal
        view
        returns (uint256)
    {
        return
            SaleKindInterface.calculateFinalPrice(
                order.side,
                order.saleKind,
                order.basePrice,
                order.extra,
                order.listingTime,
                order.expirationTime
            );
    }

    function calculateMatchPrice(Order memory buy, Order memory sell)
        internal
        view
        returns (uint256)
    {
        /* Calculate sell price. */
        uint256 sellPrice = SaleKindInterface.calculateFinalPrice(
            sell.side,
            sell.saleKind,
            sell.basePrice,
            sell.extra,
            sell.listingTime,
            sell.expirationTime
        );

        /* Calculate buy price. */
        uint256 buyPrice = SaleKindInterface.calculateFinalPrice(
            buy.side,
            buy.saleKind,
            buy.basePrice,
            buy.extra,
            buy.listingTime,
            buy.expirationTime
        );

        /* Require price cross. */
        require(buyPrice >= sellPrice);

        /* Maker/taker priority. */
        return sell.minter != address(0) ? sellPrice : buyPrice;
    }

    function executeFundsTransfer(Order memory buy, Order memory sell)
        internal
        returns (uint256)
    {
        /* Only payable in the special case of unwrapped Ether. */
        if (sell.paymentToken != address(0)) {
            require(msg.value == 0);
        }

        /* Calculate match price. */
        uint256 price = calculateMatchPrice(buy, sell);

        /* If paying using a token (not Ether), transfer tokens. This is done prior to fee payments to that a seller will have tokens before being charged fees. */
        if (price > 0 && sell.paymentToken != address(0)) {
            transferTokens(sell.paymentToken, buy.maker, sell.maker, price);
        }

        /* Amount that will be received by seller (for Ether). */
        uint256 receiveAmount = price;

        /* Amount that must be sent by buyer (for Ether). */
        uint256 requiredAmount = price;

        uint256 feeToExchange = SafeMath.div(
            SafeMath.mul(_exchangeFee, price),
            INVERSE_BASIS_POINT
        );

        /* Determine maker/taker and charge fees accordingly. */
        if (sell.minter != address(0)) {
            /* Sell-side order is maker. */

            /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
            require(sell.takerRelayerFee <= buy.takerRelayerFee);

            if (sell.feeMethod == FeeMethod.SplitFee) {
                /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
                require(sell.takerProtocolFee <= buy.takerProtocolFee);

                /* Maker fees are deducted from the token amount that the maker receives. Taker fees are extra tokens that must be paid by the taker. */
                if (sell.makerRelayerFee == 0 && sell.takerRelayerFee == 0) {
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = SafeMath.sub(
                            receiveAmount,
                            feeToExchange
                        );
                        address(_rewardFeeRecipient).transfer(feeToExchange);
                    } else {
                        transferTokens(
                            sell.paymentToken,
                            sell.maker,
                            _rewardFeeRecipient,
                            feeToExchange
                        );
                    }
                }
                if (sell.makerRelayerFee > 0) {
                    uint256 makerRelayerFee = SafeMath.div(
                        SafeMath.mul(sell.makerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = SafeMath.sub(
                            SafeMath.sub(receiveAmount, makerRelayerFee),
                            feeToExchange
                        );
                        sell.minter.transfer(makerRelayerFee);
                        address(_rewardFeeRecipient).transfer(feeToExchange);
                    } else {
                        transferTokens(
                            sell.paymentToken,
                            sell.maker,
                            sell.minter,
                            makerRelayerFee
                        );
                        transferTokens(
                            sell.paymentToken,
                            sell.maker,
                            address(_rewardFeeRecipient),
                            feeToExchange
                        );
                    }
                }

                if (sell.takerRelayerFee > 0) {
                    uint256 takerRelayerFee = SafeMath.div(
                        SafeMath.mul(sell.takerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    if (sell.paymentToken == address(0)) {
                        requiredAmount = SafeMath.add(
                            SafeMath.add(requiredAmount, takerRelayerFee),
                            feeToExchange
                        );
                        sell.minter.transfer(takerRelayerFee);
                        address(_rewardFeeRecipient).transfer(feeToExchange);
                    } else {
                        transferTokens(
                            sell.paymentToken,
                            buy.maker,
                            sell.minter,
                            takerRelayerFee
                        );
                        transferTokens(
                            sell.paymentToken,
                            buy.maker,
                            _rewardFeeRecipient,
                            feeToExchange
                        );
                    }
                }

                if (sell.makerProtocolFee > 0) {
                    uint256 makerProtocolFee = SafeMath.div(
                        SafeMath.mul(sell.makerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = SafeMath.sub(
                            receiveAmount,
                            makerProtocolFee
                        );
                        protocolFeeRecipient.transfer(makerProtocolFee);
                    } else {
                        transferTokens(
                            sell.paymentToken,
                            sell.maker,
                            protocolFeeRecipient,
                            makerProtocolFee
                        );
                    }
                }

                if (sell.takerProtocolFee > 0) {
                    uint256 takerProtocolFee = SafeMath.div(
                        SafeMath.mul(sell.takerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    if (sell.paymentToken == address(0)) {
                        requiredAmount = SafeMath.add(
                            requiredAmount,
                            takerProtocolFee
                        );
                        protocolFeeRecipient.transfer(takerProtocolFee);
                    } else {
                        transferTokens(
                            sell.paymentToken,
                            buy.maker,
                            protocolFeeRecipient,
                            takerProtocolFee
                        );
                    }
                }
            } else {
                /* Charge maker fee to seller. */
                chargeProtocolFee(
                    sell.maker,
                    sell.minter,
                    sell.makerRelayerFee
                );
                chargeProtocolFee(
                    sell.maker,
                    _rewardFeeRecipient,
                    _exchangeFee
                );
                /* Charge taker fee to buyer. */
                chargeProtocolFee(buy.maker, sell.minter, sell.takerRelayerFee);
                chargeProtocolFee(buy.maker, _rewardFeeRecipient, _exchangeFee);
            }
        } else {
            /* Buy-side order is maker. */

            /* Assert taker fee is less than or equal to maximum fee specified by seller. */
            require(buy.takerRelayerFee <= sell.takerRelayerFee);

            if (sell.feeMethod == FeeMethod.SplitFee) {
                /* The Exchange does not escrow Ether, so direct Ether can only be used to with sell-side maker / buy-side taker orders. */
                require(sell.paymentToken != address(0));

                /* Assert taker fee is less than or equal to maximum fee specified by seller. */
                require(buy.takerProtocolFee <= sell.takerProtocolFee);

                if (buy.makerRelayerFee == 0 && buy.takerRelayerFee == 0) {
                    transferTokens(
                        sell.paymentToken,
                        sell.maker,
                        _rewardFeeRecipient,
                        feeToExchange
                    );
                }

                if (buy.makerRelayerFee > 0) {
                    makerRelayerFee = SafeMath.div(
                        SafeMath.mul(buy.makerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    transferTokens(
                        sell.paymentToken,
                        buy.maker,
                        buy.minter,
                        makerRelayerFee
                    );
                    transferTokens(
                        sell.paymentToken,
                        buy.maker,
                        _rewardFeeRecipient,
                        feeToExchange
                    );
                }

                if (buy.takerRelayerFee > 0) {
                    takerRelayerFee = SafeMath.div(
                        SafeMath.mul(buy.takerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    transferTokens(
                        sell.paymentToken,
                        sell.maker,
                        buy.minter,
                        takerRelayerFee
                    );
                    transferTokens(
                        sell.paymentToken,
                        sell.maker,
                        _rewardFeeRecipient,
                        feeToExchange
                    );
                }

                if (buy.makerProtocolFee > 0) {
                    makerProtocolFee = SafeMath.div(
                        SafeMath.mul(buy.makerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    transferTokens(
                        sell.paymentToken,
                        buy.maker,
                        protocolFeeRecipient,
                        makerProtocolFee
                    );
                }

                if (buy.takerProtocolFee > 0) {
                    takerProtocolFee = SafeMath.div(
                        SafeMath.mul(buy.takerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    transferTokens(
                        sell.paymentToken,
                        sell.maker,
                        protocolFeeRecipient,
                        takerProtocolFee
                    );
                }
            } else {
                /* Charge maker fee to buyer. */
                chargeProtocolFee(buy.maker, buy.minter, buy.makerRelayerFee);
                chargeProtocolFee(buy.maker, _rewardFeeRecipient, _exchangeFee);
                /* Charge taker fee to seller. */
                chargeProtocolFee(sell.maker, buy.minter, buy.takerRelayerFee);
                chargeProtocolFee(
                    sell.maker,
                    _rewardFeeRecipient,
                    _exchangeFee
                );
            }
        }

        if (sell.paymentToken == address(0)) {
            /* Special-case Ether, order must be matched by buyer. */
            require(msg.value >= requiredAmount);
            sell.maker.transfer(receiveAmount);
            /* Allow overshoot for variable-price auctions, refund difference. */
            uint256 diff = SafeMath.sub(msg.value, requiredAmount);
            if (diff > 0) {
                buy.maker.transfer(diff);
            }
        }

        /* This contract should never hold Ether, however, we cannot assert this, since it is impossible to prevent anyone from sending Ether e.g. with selfdestruct. */

        return price;
    }

    function ordersCanMatch(Order memory buy, Order memory sell)
        internal
        view
        returns (bool)
    {
        return (/* Must be opposite-side. */
        (buy.side == SaleKindInterface.Side.Buy &&
            sell.side == SaleKindInterface.Side.Sell) &&
            /* Must use same order type. */
            (buy.orderType == sell.orderType) &&
            /* Must use same fee method. */
            (buy.feeMethod == sell.feeMethod) &&
            /* Must use same payment token. */
            (buy.paymentToken == sell.paymentToken) &&
            /* Must match maker/taker addresses. */
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
            /* One must be maker and the other must be taker (no bool XOR in Solidity). */
            ((sell.minter == address(0) && buy.minter != address(0)) ||
                (sell.minter != address(0) && buy.minter == address(0))) &&
            /* Must match target. */
            (buy.target == sell.target) &&
            /* Must match howToCall. */
            (buy.howToCall == sell.howToCall) &&
            /* Buy-side order must be settleable. */
            SaleKindInterface.canSettleOrder(
                buy.listingTime,
                buy.expirationTime
            ) &&
            /* Sell-side order must be settleable. */
            SaleKindInterface.canSettleOrder(
                sell.listingTime,
                sell.expirationTime
            ));
    }

    function atomicMatch_(
        address[12] addrs,
        uint256[18] uints,
        uint8[10] orderTypefeeMethodsSidesKindsHowToCalls,
        uint256[] tokens
    ) public payable {
        return
            atomicMatch(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[3],
                    OrderType(orderTypefeeMethodsSidesKindsHowToCalls[0]),
                    FeeMethod(orderTypefeeMethodsSidesKindsHowToCalls[1]),
                    SaleKindInterface.Side(
                        orderTypefeeMethodsSidesKindsHowToCalls[2]
                    ),
                    SaleKindInterface.SaleKind(
                        orderTypefeeMethodsSidesKindsHowToCalls[3]
                    ),
                    addrs[4],
                    AuthenticatedProxy.HowToCall(
                        orderTypefeeMethodsSidesKindsHowToCalls[4]
                    ),
                    ERC20(addrs[5]),
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                ),
                Order(
                    addrs[6],
                    addrs[7],
                    addrs[8],
                    uints[9],
                    uints[10],
                    uints[11],
                    uints[12],
                    addrs[9],
                    OrderType(orderTypefeeMethodsSidesKindsHowToCalls[5]),
                    FeeMethod(orderTypefeeMethodsSidesKindsHowToCalls[6]),
                    SaleKindInterface.Side(
                        orderTypefeeMethodsSidesKindsHowToCalls[7]
                    ),
                    SaleKindInterface.SaleKind(
                        orderTypefeeMethodsSidesKindsHowToCalls[8]
                    ),
                    addrs[10],
                    AuthenticatedProxy.HowToCall(
                        orderTypefeeMethodsSidesKindsHowToCalls[9]
                    ),
                    ERC20(addrs[11]),
                    uints[13],
                    uints[14],
                    uints[15],
                    uints[16],
                    uints[17]
                ),
                tokens
            );
    }

    function atomicMatch(
        Order memory buy,
        Order memory sell,
        uint256[] tokens
    ) internal reentrancyGuard {
        /* CHECKS */

        /* Ensure buy order validity and calculate hash if necessary. */
        bytes32 buyHash;
        require(
            buy.maker == msg.sender,
            "PlaExchange: caller is not buy maker"
        );
        require(validateOrderParameters(buy));

        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash = requireValidOrder(sell, tokens);

        /* Must be matchable. */
        require(ordersCanMatch(buy, sell));

        /* Target must exist (prevent malicious selfdestructs just prior to order settlement). */
        uint256 size;
        address target = sell.target;
        assembly {
            size := extcodesize(target)
        }
        require(size > 0);

        /* Retrieve delegateProxy contract. */
        OwnableDelegateProxy delegateProxy = registry.proxies(sell.maker);

        /* Proxy must exist. */
        require(delegateProxy != address(0));

        /* Assert implementation. */
        require(
            delegateProxy.implementation() ==
                registry.delegateProxyImplementation()
        );

        /* Access the passthrough AuthenticatedProxy. */
        AuthenticatedProxy proxy = AuthenticatedProxy(delegateProxy);

        /* INTERACTIONS */

        /* Execute funds transfer and pay fees. */
        uint256 price = executeFundsTransfer(buy, sell);
        /* Execute specified call through proxy. */

        uint256 tokenId;
        if (sell.orderType == OrderType.RandomOrder) {
            require(
                matchIndex[sellHash] < tokens.length,
                "PlaExchange: illegal match index"
            );
            tokenId = tokens[matchIndex[sellHash]];
            matchIndex[sellHash] = matchIndex[sellHash] + 1;
        } else {
            require(
                matchIndex2[sellHash] < tokens[1] - tokens[0],
                "PlaExchange: illegal match index"
            );
            tokenId = matchIndex2[sellHash] + tokens[0];
            matchIndex2[sellHash] = matchIndex2[sellHash] + 1;
        }
        require(
            proxy.proxy(
                sell.target,
                sell.howToCall,
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    sell.maker,
                    buy.maker,
                    tokenId
                )
            )
        );

        /* Log match event. */
        emit OrdersMatched(
            buyHash,
            sellHash,
            sell.minter != address(0) ? sell.maker : buy.maker,
            sell.minter != address(0) ? buy.maker : sell.maker,
            price
        );
    }
}

contract Exchange is ExchangeCore {
    /**
     * @dev Call guardedArrayReplace - library function exposed for testing.
     */
    function guardedArrayReplace(
        bytes array,
        bytes desired,
        bytes mask
    ) public pure returns (bytes) {
        ArrayUtils.guardedArrayReplace(array, desired, mask);
        return array;
    }

    /**
     * @dev Call calculateFinalPrice - library function exposed for testing.
     */
    function calculateFinalPrice(
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    ) public view returns (uint256) {
        return
            SaleKindInterface.calculateFinalPrice(
                side,
                saleKind,
                basePrice,
                extra,
                listingTime,
                expirationTime
            );
    }

    /**
     * @dev Call hashToSign - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashToSign_(
        address[6] addrs,
        uint256[9] uints,
        OrderType orderType,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[] tokens
    ) public pure returns (bytes32) {
        return
            hashToSign(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[3],
                    orderType,
                    feeMethod,
                    side,
                    saleKind,
                    addrs[4],
                    howToCall,
                    ERC20(addrs[5]),
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                ),
                tokens
            );
    }

    /**
     * @dev Call validateOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrder_(
        address[6] addrs,
        uint256[9] uints,
        OrderType orderType,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[] tokens
    ) public view returns (bool) {
        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            uints[2],
            uints[3],
            addrs[3],
            orderType,
            feeMethod,
            side,
            saleKind,
            addrs[4],
            howToCall,
            ERC20(addrs[5]),
            uints[4],
            uints[5],
            uints[6],
            uints[7],
            uints[8]
        );
        return validateOrder(hashToSign(order, tokens), order);
    }

    /**
     * @dev Call approveOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function approveOrder_(
        address[6] addrs,
        uint256[9] uints,
        OrderType orderType,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[] tokens
    ) public {
        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            uints[2],
            uints[3],
            addrs[3],
            orderType,
            feeMethod,
            side,
            saleKind,
            addrs[4],
            howToCall,
            ERC20(addrs[5]),
            uints[4],
            uints[5],
            uints[6],
            uints[7],
            uints[8]
        );
        return approveOrder(order, tokens);
    }

    /**
     * @dev Call cancelOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function cancelOrder_(
        address[6] addrs,
        uint256[9] uints,
        OrderType orderType,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        uint256[] tokens
    ) public {
        return
            cancelOrder(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[3],
                    orderType,
                    feeMethod,
                    side,
                    saleKind,
                    addrs[4],
                    howToCall,
                    ERC20(addrs[5]),
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                ),
                tokens
            );
    }
}

contract PlaNFTExchange is Exchange {
    string public constant name = "Project PlaNFT Exchange";

    string public constant version = "1.0";

    string public constant codename = "Lambton Worm";

    /**
     * @dev Initialize a PlaNFTExchange instance
     * @param registryAddress Address of the registry instance which this Exchange instance will use
     * @param tokenAddress Address of the token used for protocol fees
     */
    constructor(
        ProxyRegistry registryAddress,
        TokenTransferProxy tokenTransferProxyAddress,
        ERC20 tokenAddress,
        address protocolFeeAddress,
        address rewardFeeRecipient
    ) public {
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        exchangeToken = tokenAddress;
        protocolFeeRecipient = protocolFeeAddress;
        _rewardFeeRecipient = rewardFeeRecipient;
        owner = msg.sender;
    }
}