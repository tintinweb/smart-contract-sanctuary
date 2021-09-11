// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./Enum.sol";
import "./SignatureDecoder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (bool success);
}

interface IGelatoPokeMe {
    /// @notice Helper func to query fee and feeToken
    function getFeeDetails() external view returns (uint256, address);

    function getSelector(string calldata _func) external pure returns (bytes4);

    function getResolverHash(
        address _resolverAddress,
        bytes memory _resolverData
    ) external pure returns (bytes32);

    function getTaskId(
        address _taskCreator,
        address _execAddress,
        bytes4 _selector,
        bool _useTaskTreasuryFunds,
        address _feeToken,
        bytes32 _resolverHash
    ) external pure returns (bytes32);

    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 task);

    function getTaskIdsByUser(address _taskCreator)
        external
        view
        returns (bytes32[] memory);

    function cancelTask(bytes32 _taskId) external;
}

contract AllowanceModule is SignatureDecoder, Ownable {
    string public constant NAME = "Allowance Module";
    string public constant VERSION = "0.1.0";
    address payable public immutable GELATO;
    address public immutable GELATO_POKE_ME;
    address public resolver;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public gasLimit = 10**6;

    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH =
        0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;
    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );

    bytes32 public constant ALLOWANCE_TRANSFER_TYPEHASH =
        0x80b006280932094e7cc965863eb5118dc07e5d272c6670c4a7c87299e04fceeb;
    // keccak256(
    //     "AllowanceTransfer(address safe,address token,uint96 amount,address paymentToken,uint96 payment,uint16 nonce)"
    // );

    // Safe -> Delegate -> Allowance
    mapping(address => mapping(address => mapping(address => Allowance)))
        public allowances;
    // Safe -> maxGasPrice
    mapping(address => uint256) public maxGasPrice;
    // Safe -> paymentToken
    mapping(address => mapping(address => bool)) public paymentTokens;
    // Safe -> Delegate -> Tokens
    mapping(address => mapping(address => address[])) public tokens;
    // Safe -> Delegates double linked list entry points
    mapping(address => uint48) public delegatesStart;
    // Safe -> Delegates double linked list
    mapping(address => mapping(uint48 => Delegate)) public delegates;

    // We use a double linked list for the delegates. The id is the first 6 bytes.
    // To double check the address in case of collision, the address is part of the struct.
    struct Delegate {
        address delegate;
        uint48 prev;
        uint48 next;
    }

    // The allowance info is optimized to fit into one word of storage.
    struct Allowance {
        uint96 amount;
        uint96 spent;
        uint16 resetTimeMin; // Maximum reset time span is 65k minutes
        uint32 lastResetMin;
        uint16 nonce;
    }

    struct Info {
        address delegate;
        address token;
        Allowance allowance;
    }

    event AddDelegate(address indexed safe, address delegate);
    event RemoveDelegate(address indexed safe, address delegate);
    event ExecuteAllowanceTransfer(
        address indexed safe,
        address delegate,
        address token,
        address to,
        uint96 value,
        uint16 nonce
    );
    event PayAllowanceTransfer(
        address indexed safe,
        address delegate,
        address paymentToken,
        address paymentReceiver,
        uint96 payment
    );
    event SetAllowance(
        address indexed safe,
        address delegate,
        address token,
        uint96 allowanceAmount,
        uint16 resetTime
    );
    event ResetAllowance(address indexed safe, address delegate, address token);
    event DeleteAllowance(
        address indexed safe,
        address delegate,
        address token
    );
    event NewMaxGasPrice(address indexed safe, uint256 newMaxGasPrice);
    event SetGelatoAddress(
        address indexed oldGelato,
        address indexed newGelato
    );
    event SetResolverAddress(
        address indexed oldResolver,
        address indexed newResolver
    );
    event SetPaymentToken(address indexed paymentToken);
    event RemovePaymentToken(address indexed paymentToken);
    event CreateGelatoTask(
        address indexed safe,
        address indexed token,
        address indexed paymentToken
    );
    event CancelGelatoTask(
        address indexed safe,
        address indexed token,
        address indexed paymentToken,
        bytes32 task
    );

    constructor(address payable gelato, address gelatoPokeMe) {
        GELATO = gelato;
        GELATO_POKE_ME = gelatoPokeMe;
    }

    /// @dev Allows to update the allowance for a specified token. This can only be done via a Safe transaction.
    /// @param delegate Delegate whose allowance should be updated.
    /// @param token Token contract address.
    /// @param allowanceAmount allowance in smallest token unit.
    /// @param resetTimeMin Time after which the allowance should reset
    /// @param resetBaseMin Time based on which the reset time should be increased
    function setAllowance(
        address delegate,
        address token,
        uint96 allowanceAmount,
        uint16 resetTimeMin,
        uint32 resetBaseMin
    ) public {
        require(delegate != address(0), "delegate != address(0)");
        require(
            delegates[msg.sender][uint48(delegate)].delegate == delegate,
            "delegates[msg.sender][uint48(delegate)].delegate == delegate"
        );
        Allowance memory allowance = getAllowance(msg.sender, delegate, token);
        if (allowance.nonce == 0) {
            // New token
            // Nonce should never be 0 once allowance has been activated
            allowance.nonce = 1;
            tokens[msg.sender][delegate].push(token);
        }
        // Divide by 60 to get current time in minutes
        // solium-disable-next-line security/no-block-members
        uint32 currentMin = uint32(block.timestamp / 60);
        if (resetBaseMin > 0) {
            require(resetBaseMin <= currentMin, "resetBaseMin <= currentMin");
            allowance.lastResetMin =
                currentMin -
                ((currentMin - resetBaseMin) % resetTimeMin);
        } else if (allowance.lastResetMin == 0) {
            allowance.lastResetMin = currentMin;
        }
        allowance.resetTimeMin = resetTimeMin;
        allowance.amount = allowanceAmount;
        updateAllowance(msg.sender, delegate, token, allowance);
        emit SetAllowance(
            msg.sender,
            delegate,
            token,
            allowanceAmount,
            resetTimeMin
        );
    }

    function getAllowance(
        address safe,
        address delegate,
        address token
    ) private view returns (Allowance memory allowance) {
        allowance = allowances[safe][delegate][token];
        // solium-disable-next-line security/no-block-members
        uint32 currentMin = uint32(block.timestamp / 60);
        // Check if we should reset the time. We do this on load to minimize storage read/ writes
        if (
            allowance.resetTimeMin > 0 &&
            allowance.lastResetMin <= currentMin - allowance.resetTimeMin
        ) {
            allowance.spent = 0;
            // Resets happen in regular intervals and `lastResetMin` should be aligned to that
            allowance.lastResetMin =
                currentMin -
                ((currentMin - allowance.lastResetMin) %
                    allowance.resetTimeMin);
        }
        return allowance;
    }

    function updateAllowance(
        address safe,
        address delegate,
        address token,
        Allowance memory allowance
    ) private {
        allowances[safe][delegate][token] = allowance;
    }

    /// @dev Allows to reset the allowance for a specific delegate and token.
    /// @param delegate Delegate whose allowance should be updated.
    /// @param token Token contract address.
    function resetAllowance(address delegate, address token) public {
        Allowance memory allowance = getAllowance(msg.sender, delegate, token);
        allowance.spent = 0;
        updateAllowance(msg.sender, delegate, token, allowance);
        emit ResetAllowance(msg.sender, delegate, token);
    }

    /// @dev Allows to remove the allowance for a specific delegate and token. This will set all values except the `nonce` to 0.
    /// @param delegate Delegate whose allowance should be updated.
    /// @param token Token contract address.
    function deleteAllowance(address delegate, address token) public {
        Allowance memory allowance = getAllowance(msg.sender, delegate, token);
        allowance.amount = 0;
        allowance.spent = 0;
        allowance.resetTimeMin = 0;
        allowance.lastResetMin = 0;
        updateAllowance(msg.sender, delegate, token, allowance);
        emit DeleteAllowance(msg.sender, delegate, token);
    }

    /// @dev Allows to use the allowance to perform a transfer.
    /// @param safe The Safe whose funds should be used.
    /// @param token Token contract address.
    /// @param to Address that should receive the tokens.
    /// @param amount Amount that should be transferred.
    /// @param paymentToken Token that should be used to pay for the execution of the transfer.
    /// @param payment Amount to should be paid for executing the transfer.
    /// @param delegate Delegate whose allowance should be updated.
    /// @param signature Signature generated by the delegate to authorize the transfer.
    function executeAllowanceTransfer(
        GnosisSafe safe,
        address token,
        address payable to,
        uint96 amount,
        address paymentToken,
        uint96 payment,
        address delegate,
        bytes memory signature
    ) public {
        require(to == delegate, "delegate only");
        // Get current state
        Allowance memory allowance = getAllowance(
            address(safe),
            delegate,
            token
        );
        bytes memory transferHashData = generateTransferHashData(
            address(safe),
            token,
            to,
            amount,
            paymentToken,
            payment,
            allowance.nonce
        );

        // Update state
        allowance.nonce = allowance.nonce + 1;
        uint96 newSpent = allowance.spent + amount;
        // Check new spent amount and overflow
        require(
            newSpent > allowance.spent && newSpent <= allowance.amount,
            "newSpent > allowance.spent && newSpent <= allowance.amount"
        );
        allowance.spent = newSpent;
        updateAllowance(address(safe), delegate, token, allowance);

        // Perform external interactions
        // Check signature
        checkSignature(delegate, signature, transferHashData, safe);

        if (payment > 0 && msg.sender == GELATO_POKE_ME) {
            uint256 payment256;
            (payment256, paymentToken) = IGelatoPokeMe(GELATO_POKE_ME)
                .getFeeDetails();
            payment = uint96(payment256);
            require(payment == payment256, "No overflow");
            if (paymentToken == ETH) {
                require(
                    payment <= maxGasPrice[address(safe)] * gasLimit,
                    "Gas fees > allowed"
                ); // deterministic gas calculation
            } else {
                require(
                    paymentTokens[address(safe)][paymentToken],
                    "payment token not whitelisted"
                );
            }
            require(
                tx.gasprice <= maxGasPrice[address(safe)],
                "tx.gasprice is > maxGas price"
            );
            // solium-disable-next-line
            transfer(safe, paymentToken, GELATO, payment);
            // solium-disable-next-line
            emit PayAllowanceTransfer(
                address(safe),
                delegate,
                paymentToken,
                GELATO,
                payment
            );
        }

        // Transfer token
        transfer(safe, token, to, amount);
        emit ExecuteAllowanceTransfer(
            address(safe),
            delegate,
            token,
            to,
            amount,
            allowance.nonce - 1
        );
    }

    /// @dev Creates a task on Gelato PokeMe
    /// @param token The token which will be transfered to delegate.
    /// @param paymentToken Token that should be used to pay for the execution of the transfer.
    function createGelatoTask(address token, address paymentToken) external {
        if (paymentToken != ETH)
            require(
                paymentTokens[msg.sender][paymentToken],
                "payment token not whitelisted"
            );

        bytes memory resolverData = abi.encodeWithSignature(
            "checker(address,address)",
            msg.sender,
            token
        );

        createTask(GnosisSafe(msg.sender), paymentToken, resolverData);

        emit CreateGelatoTask(msg.sender, token, paymentToken);
    }

    /// @dev Cancel task on Gelato PokeMe
    /// @param token The token which will be transfered to delegate.
    /// @param paymentToken Token that should be used to pay for the execution of the transfer.
    function cancelGelatoTask(address token, address paymentToken) external {
        bytes memory resolverData = abi.encodeWithSignature(
            "checker(address,address)",
            msg.sender,
            token
        );
        bytes32 resolverHash = IGelatoPokeMe(GELATO_POKE_ME).getResolverHash(
            resolver,
            resolverData
        );

        bytes32 taskId = IGelatoPokeMe(GELATO_POKE_ME).getTaskId(
            msg.sender,
            address(this),
            this.executeAllowanceTransfer.selector,
            false,
            paymentToken,
            resolverHash
        );

        cancelTask(GnosisSafe(msg.sender), taskId);

        emit CancelGelatoTask(msg.sender, token, paymentToken, taskId);
    }

    function getTasksBySafe(address safe)
        public
        view
        returns (bytes32[] memory tasks)
    {
        tasks = IGelatoPokeMe(GELATO_POKE_ME).getTaskIdsByUser(safe);
    }

    function getTaskId(
        address safe,
        address token,
        address paymentToken
    ) external view returns (bool isActive, bytes32 task) {
        bytes memory resolverData = abi.encodeWithSignature(
            "checker(address,address)",
            safe,
            token
        );
        bytes32 resolverHash = IGelatoPokeMe(GELATO_POKE_ME).getResolverHash(
            resolver,
            resolverData
        );

        task = IGelatoPokeMe(GELATO_POKE_ME).getTaskId(
            safe,
            address(this),
            this.executeAllowanceTransfer.selector,
            false,
            paymentToken,
            resolverHash
        );

        bytes32[] memory taskIds = getTasksBySafe(safe);
        for (uint256 i = 0; i < taskIds.length; i++) {
            if (task == taskIds[i]) {
                isActive = true;
                break;
            }
        }
    }

    /// @dev Returns the chain id used by this contract.
    function getChainId() public pure returns (uint256) {
        uint256 id;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    /// @dev Generates the data for the transfer hash (required for signing)
    function generateTransferHashData(
        address safe,
        address token,
        address to,
        uint96 amount,
        address paymentToken,
        uint96 payment,
        uint16 nonce
    ) private view returns (bytes memory) {
        uint256 chainId = getChainId();
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_SEPARATOR_TYPEHASH, chainId, this)
        );
        bytes32 transferHash = keccak256(
            abi.encode(
                ALLOWANCE_TRANSFER_TYPEHASH,
                safe,
                token,
                to,
                amount,
                paymentToken,
                payment,
                nonce
            )
        );
        return
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                domainSeparator,
                transferHash
            );
    }

    /// @dev Generates the transfer hash that should be signed to authorize a transfer
    function generateTransferHash(
        address safe,
        address token,
        address to,
        uint96 amount,
        address paymentToken,
        uint96 payment,
        uint16 nonce
    ) public view returns (bytes32) {
        return
            keccak256(
                generateTransferHashData(
                    safe,
                    token,
                    to,
                    amount,
                    paymentToken,
                    payment,
                    nonce
                )
            );
    }

    function checkSignature(
        address expectedDelegate,
        bytes memory signature,
        bytes memory transferHashData,
        GnosisSafe safe
    ) private view {
        address signer = recoverSignature(signature, transferHashData);
        require(
            (expectedDelegate == signer &&
                delegates[address(safe)][uint48(signer)].delegate == signer) ||
                msg.sender == GELATO_POKE_ME,
            "expectedDelegate == signer && delegates[address(safe)][uint48(signer)].delegate == signer"
        );
    }

    // We use the same format as used for the Safe contract, except that we only support exactly 1 signature and no contract signatures.
    function recoverSignature(
        bytes memory signature,
        bytes memory transferHashData
    ) private view returns (address owner) {
        // If there is no signature data msg.sender should be used
        if (signature.length == 0) return msg.sender;
        // Check that the provided signature data is as long as 1 encoded ecsda signature
        require(signature.length == 65, "signatures.length == 65");
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(signature, 0);
        // If v is 0 then it is a contract signature
        if (v == 0) {
            revert("Contract signatures are not supported by this module");
        } else if (v == 1) {
            // If v is 1 we also use msg.sender, this is so that we are compatible to the GnosisSafe signature scheme
            owner = msg.sender;
        } else if (v > 30) {
            // To support eth_sign and similar we adjust v and hash the transferHashData with the Ethereum message prefix before applying ecrecover
            owner = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        keccak256(transferHashData)
                    )
                ),
                v - 4,
                r,
                s
            );
        } else {
            // Use ecrecover with the messageHash for EOA signatures
            owner = ecrecover(keccak256(transferHashData), v, r, s);
        }
        // 0 for the recovered owner indicates that an error happened.
        require(owner != address(0), "owner != address(0)");
    }

    function createTask(
        GnosisSafe safe,
        address paymentToken,
        bytes memory resolverData
    ) private {
        bytes memory data = abi.encodeWithSelector(
            IGelatoPokeMe.createTaskNoPrepayment.selector,
            address(this),
            this.executeAllowanceTransfer.selector,
            resolver,
            resolverData,
            paymentToken
        );
        require(
            safe.execTransactionFromModule(
                GELATO_POKE_ME,
                0,
                data,
                Enum.Operation.Call
            ),
            "Could not execute task creation"
        );
    }

    function cancelTask(GnosisSafe safe, bytes32 taskId) private {
        bytes memory data = abi.encodeWithSelector(
            IGelatoPokeMe.cancelTask.selector,
            taskId
        );
        require(
            safe.execTransactionFromModule(
                GELATO_POKE_ME,
                0,
                data,
                Enum.Operation.Call
            ),
            "Could not execute task creation"
        );
    }

    function transfer(
        GnosisSafe safe,
        address token,
        address payable to,
        uint96 amount
    ) private {
        if (token == address(0) || token == ETH) {
            // solium-disable-next-line security/no-send
            require(
                safe.execTransactionFromModule(
                    to,
                    amount,
                    "",
                    Enum.Operation.Call
                ),
                "Could not execute ether transfer"
            );
        } else {
            bytes memory data = abi.encodeWithSignature(
                "transfer(address,uint256)",
                to,
                amount
            );
            require(
                safe.execTransactionFromModule(
                    token,
                    0,
                    data,
                    Enum.Operation.Call
                ),
                "Could not execute token transfer"
            );
        }
    }

    function getTokens(address safe, address delegate)
        public
        view
        returns (address[] memory)
    {
        return tokens[safe][delegate];
    }

    function getTokenAllowance(
        address safe,
        address delegate,
        address token
    ) public view returns (uint256[5] memory) {
        Allowance memory allowance = getAllowance(safe, delegate, token);
        return [
            uint256(allowance.amount),
            uint256(allowance.spent),
            uint256(allowance.resetTimeMin),
            uint256(allowance.lastResetMin),
            uint256(allowance.nonce)
        ];
    }

    /// @dev Allows to add a delegate.
    /// @param delegate Delegate that should be added.
    function addDelegate(address delegate) public {
        uint48 index = uint48(delegate);
        require(index != uint256(0), "index != uint(0)");
        address currentDelegate = delegates[msg.sender][index].delegate;
        if (currentDelegate != address(0)) {
            // We have a collision for the indices of delegates
            require(currentDelegate == delegate, "currentDelegate == delegate");
            // Delegate already exists, nothing to do
            return;
        }
        uint48 startIndex = delegatesStart[msg.sender];
        delegates[msg.sender][index] = Delegate(delegate, 0, startIndex);
        delegates[msg.sender][startIndex].prev = index;
        delegatesStart[msg.sender] = index;
        emit AddDelegate(msg.sender, delegate);
    }

    /// @dev Allows to add a set max gas price for user
    /// @param newMaxGasPrice New Max Gas Price to set.
    function setMaxGasPrice(uint256 newMaxGasPrice) public {
        maxGasPrice[msg.sender] = newMaxGasPrice;
        emit NewMaxGasPrice(msg.sender, newMaxGasPrice);
    }

    /// @dev Allows to update the resolver
    /// @param newResolver New resoler address
    function setResolverAddress(address newResolver) public onlyOwner {
        require(newResolver != address(0), "Address Can't be Zero");
        address oldResolver = resolver;
        resolver = newResolver;
        emit SetResolverAddress(oldResolver, newResolver);
    }

    /// @dev Allows to remove a delegate.
    /// @param delegate Delegate that should be removed.
    /// @param removeAllowances Indicator if allowances should also be removed. This should be set to `true` unless this causes an out of gas, in this case the allowances should be "manually" deleted via `deleteAllowance`.
    function removeDelegate(address delegate, bool removeAllowances) public {
        Delegate memory current = delegates[msg.sender][uint48(delegate)];
        // Delegate doesn't exists, nothing to do
        if (current.delegate == address(0)) return;
        if (removeAllowances) {
            address[] storage delegateTokens = tokens[msg.sender][delegate];
            for (uint256 i = 0; i < delegateTokens.length; i++) {
                address token = delegateTokens[i];
                // Set all allowance params except the nonce to 0
                Allowance memory allowance = getAllowance(
                    msg.sender,
                    delegate,
                    token
                );
                allowance.amount = 0;
                allowance.spent = 0;
                allowance.resetTimeMin = 0;
                allowance.lastResetMin = 0;
                updateAllowance(msg.sender, delegate, token, allowance);
                emit DeleteAllowance(msg.sender, delegate, token);
            }
        }
        if (current.prev == 0) {
            delegatesStart[msg.sender] = current.next;
        } else {
            delegates[msg.sender][current.prev].next = current.next;
        }
        if (current.next != 0) {
            delegates[msg.sender][current.next].prev = current.prev;
        }
        delete delegates[msg.sender][uint48(delegate)];
        emit RemoveDelegate(msg.sender, delegate);
    }

    /// @dev Allows Gelato to use this token as payment for executing transactions
    /// @param token New payment token to activate
    function setPaymentToken(address token) public {
        require(token != address(0), "Address Can't be Zero");
        bool isSet = paymentTokens[msg.sender][token];
        require(!isSet, "Payment Token already set");
        paymentTokens[msg.sender][token] = true;
        emit SetPaymentToken(token);
    }

    /// @dev Disallows Gelato to use this token as payment for executing transactions
    /// @param token Old payment token to remove
    function removePaymentToken(address token) public {
        require(token != address(0), "Address Can't be Zero");
        bool isSet = paymentTokens[msg.sender][token];
        require(isSet, "Payment Token is not set");
        paymentTokens[msg.sender][token] = false;
        emit RemovePaymentToken(token);
    }

    function getDelegates(
        address safe,
        uint48 start,
        uint8 pageSize
    ) public view returns (address[] memory results, uint48 next) {
        results = new address[](pageSize);
        uint8 i = 0;
        uint48 initialIndex = (start != 0) ? start : delegatesStart[safe];
        Delegate memory current = delegates[safe][initialIndex];
        while (current.delegate != address(0) && i < pageSize) {
            results[i] = current.delegate;
            i++;
            current = delegates[safe][current.next];
        }
        next = uint48(current.delegate);
        // Set the length of the array the number that has been used.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(results, i)
        }
    }

    function getInfo(
        address safe,
        uint48 start,
        uint8 pageSize
    ) external view returns (Info[] memory) {
        Info[] memory info;
        uint256 counter;
        (address[] memory allDelegates, ) = getDelegates(safe, start, pageSize);
        for (uint256 i = 0; i <= allDelegates.length; i++) {
            address[] memory allTokens = getTokens(safe, allDelegates[i]);
            for (uint256 j = 0; j <= allTokens.length; j++) {
                info[counter].delegate = allDelegates[i];
                info[counter].token = allTokens[j];
                info[counter].allowance = getAllowance(
                    safe,
                    allDelegates[i],
                    allTokens[j]
                );
                counter++;
            }
        }
        return info;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Enum} from "./Enum.sol";
import {GnosisSafe} from "./AllowanceModule.sol";

interface IAllowanceModule {
    struct Allowance {
        uint96 amount;
        uint96 spent;
        uint16 resetTimeMin;
        uint32 lastResetMin;
        uint16 nonce;
    }

    struct Delegate {
        address delegate;
        uint48 prev;
        uint48 next;
    }

    function delegatesStart(address safe) external view returns (uint48);

    function delegates(address safe, uint48 node)
        external
        view
        returns (Delegate memory delegate);

    function getTokenAllowance(
        address safe,
        address delegate,
        address token
    ) external view returns (uint256[5] memory);

    function executeAllowanceTransfer(
        GnosisSafe safe,
        address token,
        address payable to,
        uint96 amount,
        address paymentToken,
        uint96 payment,
        address delegate,
        bytes memory signature
    ) external;
}

contract Resolver {
    IAllowanceModule public immutable allowanceModule;

    constructor(address _allowanceModule) {
        allowanceModule = IAllowanceModule(_allowanceModule);
    }

    function checker(
        address _safe,
        address _token
    ) external view returns (bool canExec, bytes memory execPayload) {
        uint48 entry = allowanceModule.delegatesStart(_safe);

        IAllowanceModule.Delegate memory currentNode = allowanceModule
            .delegates(_safe, entry);

        do {
            uint96 amount;
            (canExec, amount) = _canTransferToDelegate(
                _safe,
                currentNode.delegate,
                _token
            );
            if (canExec) {
                execPayload = _getPayload(
                    _safe,
                    _token,
                    currentNode.delegate,
                    amount
                );
                return (canExec, execPayload);
            }

            uint48 nextNode = currentNode.next;
            currentNode = allowanceModule.delegates(_safe, nextNode);
        } while (currentNode.delegate != address(0));

        return (canExec, execPayload);
    }

    /// @dev Checks if delegate has remaining allowance.
    function _canTransferToDelegate(
        address _safe,
        address _delegate,
        address _token
    ) internal view returns (bool, uint96) {
        uint256[5] memory allowance = allowanceModule.getTokenAllowance(
            _safe,
            _delegate,
            _token
        );

        uint96 amount = uint96(allowance[0]);
        uint96 spent = uint96(allowance[1]);

        if (amount > spent) {
            uint96 remaining = amount - spent;
            return (true, remaining);
        }

        return (false, 0);
    }

    function _getPayload(
        address _safe,
        address _token,
        address _delegate,
        uint96 _amount
    ) internal pure returns (bytes memory payload) {
        bytes memory signature = new bytes(0);
        uint96 fee = 1;
        address paymentToken = address(0);

        payload = abi.encodeWithSelector(
            IAllowanceModule.executeAllowanceTransfer.selector,
            _safe,
            _token,
            _delegate,
            _amount,
            paymentToken,
            fee,
            _delegate,
            signature
        );
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
/// @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
/// @author Richard Meissner - <[email protected]>
contract SignatureDecoder {
    
    /// @dev Recovers address who signed the message
    /// @param messageHash operation ethereum signed message hash
    /// @param messageSignature message `txHash` signature
    /// @param pos which signature to read
    function recoverKey (
        bytes32 messageHash,
        bytes memory messageSignature,
        uint256 pos
    )
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(messageSignature, pos);
        return ecrecover(messageHash, v, r, s);
    }

    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to peform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}