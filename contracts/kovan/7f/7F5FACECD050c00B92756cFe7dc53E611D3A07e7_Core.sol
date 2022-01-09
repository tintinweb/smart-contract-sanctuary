// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IFuture } from "./interfaces/IFuture.sol";
import { Treasury } from "./Treasury.sol";
import { IDetailedERC20 } from "./interfaces/IDetailedERC20.sol";


contract Core {
    using SafeERC20 for IERC20;
    address public immutable owner;
    address public immutable treasuryAddress;

    // supported protocols
    bytes32 public constant aave = keccak256(abi.encode("AAVE"));
    bytes32 public constant comp = keccak256(abi.encode("COMP"));
    bytes32 public constant yearn = keccak256(abi.encode("YEARN"));
    uint256 internal constant MAX_UINT = 2**256 - 1;

    /**
     * @dev stores a future stream, all users subscribed to stream will be rolled over
     * to the next one as more futures are created
     *
     * eg: we start with AAVE ADAI 30 day future with index 1
     * the map stores keccak(protocol, underlying, period) to array of all futures created sorted by creation.
     * the last element of the stream is the current active future for a specific platform, duration, underlying
     */
    mapping(bytes32 => address[]) public streams;

    /**
     * @dev checks if the caller is the owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "ERR_ONLY_OWNER");
        _;
    }

    /**
     * @dev checks if an epoch has expired
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future to be checked
     */
    modifier isEpochExpired(bytes32 _streamKey, uint256 _epoch) {
        revertNonExistentStream(_streamKey);
        address epochAddress = streams[_streamKey][_epoch];
        require(IFuture(epochAddress).expiry() <= block.timestamp, "ERR_EPOCH_NOT_EXPIRED");
        _;
    }

    /**
     * @dev checks if a protocol is supported or not
     * @param _protocol: The identifier of the protocol
     */

    modifier supportedProtocol(string memory _protocol) {
        bytes32 protocolHash = keccak256(abi.encode(_protocol));
        require(protocolHash == aave || protocolHash == comp || protocolHash == yearn, "ERR_UNSUPPORTED_PROTOCOL");
        _;
    }

    event NewStream(address underlying, string protocol, uint256 durationSeconds, bytes32 streamKey);
    event EpochStarted(bytes32 streamKey, uint256 futureIndex);
    event Deposited(bytes32 streamKey, address user, uint256 amount, uint256 EpochId);
    event PrincipleRedeemed(bytes32 streamKey, address user, uint256 epoch, uint256 amount);
    event YieldRedeemed(bytes32 streamKey, address user, uint256 epoch, uint256 amount);

    /**
     * @dev We set the immutables on contract creation such as owner.
     * @notice We also create the treasury and set its address to immutable
     */
    constructor() {
        owner = msg.sender;
        treasuryAddress = address(new Treasury());
    }

    ///// PROTOCOL ADMINISTRATION

    /**
     * @dev creates a new stream of future and creates the first epoch.
     *
     * each stream can contain multiple epochs of futures but the futures can only
     * be present serially. it means that a new epoch in a stream
     * can only be created after the ongoing epoch expires.
     *
     * ============ STREAM 1 (7 day)=================>
     *          |          |          |          |
     * epoch 0  | epoch 1  | epoch 2  | epoch 3  |
     *          |          |          |          |
     *===============================================>
     *
     *
     * ============ STREAM 2 (30 day)================>
     *          |          |          |          |
     * epoch 0  | epoch 1  | epoch 2  | epoch 3  |
     *          |          |          |          |
     *===============================================>
     *
     *
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _durationSeconds: number of blocks the future will run before renewing
     * @param _bytecode: bytecode of the protocol to be deployed
     * @param _extraData: extra data that allows us to set protocol address
     */
    function registerNewStream(
        string memory _protocol,
        address _underlying,
        uint256 _durationSeconds,
        bytes memory _bytecode,
        bytes memory _extraData
    ) external onlyOwner supportedProtocol(_protocol) {
        require(_underlying != address(0), "ERR_INVALID_ADDRESS_ZERO");
        require(_durationSeconds > 0, "ERR_INVALID_DURATION_ZERO");
        bytes32 streamKey = getStreamKey(_protocol, _underlying, _durationSeconds);
        // check if there is already an existing stream for the given meta
        // if it exists then cannot create a new stream with same params
        require(!isStreamInitialized(streamKey), "ERR_STREAM_ALREADY_EXISTS");
        // add the genesis future in treasury
        createNewEpoch(_protocol, _underlying, _durationSeconds, 0, _bytecode, _extraData);

        emit NewStream(_underlying, _protocol, _durationSeconds, streamKey);
    }

    /**
     * @dev initializes a future epoch and enables users to interact with it
     * also updates the treasury linked to the particular stream such that it marks
     * the previous epoch as expired and the balances becomes claimabale.
     *
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _durationSeconds: number of blocks the future will run before renewing
     * @param _bytecode: bytecode of the protocol to be deployed
     * @param _extraData: extra data that allows us to set protocol address
     */
    function startEpoch(
        string memory _protocol,
        address _underlying,
        uint256 _durationSeconds,
        bytes memory _bytecode,
        bytes memory _extraData
    ) external supportedProtocol(_protocol) {
        bytes32 streamKey = getStreamKey(_protocol, _underlying, _durationSeconds);

        // check if stream exists (ie: has a 0th epoch)
        revertNonExistentStream(streamKey);

        // get the next epoch index
        uint256 nextEpoch = getNextEpoch(streamKey);

        // check if the previous epoch has ended before adding a new one
        Treasury treasury = Treasury(treasuryAddress);
        address currentEpochAddress = getEpochAddress(streamKey, getCurrentEpoch(streamKey));
        require(IFuture(currentEpochAddress).expiry() < block.timestamp, "ERR_STREAM_CONTAINS_ACTIVE_EPOCH");

        // expiring previous Ifuture
        // renew the treasury status
        treasury.renew(streamKey, nextEpoch, currentEpochAddress);

        // create New Future Epoch
        createNewEpoch(_protocol, _underlying, _durationSeconds, 0, _bytecode, _extraData);
    }

    /**
     * @dev uses future factory to deploy a new future epoch based
     * on the the provided params. uses the treasury to transfer the leftover
     * amount from previous epoch to fund the new future
     *
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _durationSeconds: number of blocks the future will run before renewing
     * @param _amountSubscribedInUnderlying: amount subscribed in underlying protocol.
     * @notice the amount subscribed in underlying is 0 for 0th epoch.
     * @param _bytecode: bytecode of the protocol to be deployed
     * @param _extraData: extra data that allows us to set protocol address
     */
    function createNewEpoch(
        string memory _protocol,
        address _underlying,
        uint256 _durationSeconds,
        uint256 _amountSubscribedInUnderlying,
        bytes memory _bytecode,
        bytes memory _extraData
    ) internal {
        bytes32 streamKey = getStreamKey(_protocol, _underlying, _durationSeconds);

        uint256 nextEpoch = getNextEpoch(streamKey);

        address _treasuryAddress = treasuryAddress;
        // use contract factory to deploy a new future instance based on params
        address newEpochAddr =
            _getDeterministicEpoch(_protocol, _underlying, _durationSeconds, _treasuryAddress, _bytecode, _extraData);

        // check if the owner of the newly created future is our contract only
        require(IFuture(newEpochAddr).owner() == address(this), "ERR_INVALID_EPOCH");
        // if the newly created epoch is 0th, then get IBT symbol
        // for creating the new treasury stream
        if (nextEpoch == 0) {
            string memory interestBearingSymbol =
                IDetailedERC20(IFuture(newEpochAddr).getInterestBearingToken()).symbol();
            require(bytes(interestBearingSymbol).length > 0, "ERR_NO_SYMBOL");
            Treasury(_treasuryAddress).createNewTreasuryStream(
                _protocol,
                _underlying,
                _durationSeconds
            );
        }
        // while starting don't have to transfer funds
        // from previous epoch to new epoch
        // pull funds from treasury to this contract
        Treasury(_treasuryAddress).fundAndKickOffEpoch(
            _protocol,
            _durationSeconds,
            newEpochAddr,
            _amountSubscribedInUnderlying,
            getNextEpoch(streamKey)
        );

        // push the newly created epoch into stream's epoch array
        streams[streamKey].push(newEpochAddr);
        emit EpochStarted(streamKey, nextEpoch);
    }

    /**
     * @dev We need to create a new future with given params and
     * we need a determinsitic address for it.
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _durationSeconds: number of blocks the future will run before renewing
     * @param _treasuryAddress: the address of the treasury
     * @param _bytecode: bytecode of the protocol to be deployed
     * @param _extraData: extra data that allows us to set protocol address
     * @return address of the newly created future
     */
    function _getDeterministicEpoch(
        string memory _protocol,
        address _underlying,
        uint256 _durationSeconds,
        address _treasuryAddress,
        bytes memory _bytecode,
        bytes memory _extraData
    ) internal returns (address) {
        bytes32 streamKey = getStreamKey(_protocol, _underlying, _durationSeconds);
        uint256 epoch = getCurrentEpoch(streamKey);

        bytes32 salt =
            keccak256(
                abi.encodePacked(
                    address(this),
                    _protocol,
                    _underlying,
                    _durationSeconds,
                    _treasuryAddress,
                    epoch,
                    _extraData
                )
            );

        address addr;
        assembly {
            addr := create2(0, add(_bytecode, 0x20), mload(_bytecode), salt)
        }
        return addr;
    }

    ///// USER-PROTOCOL INTERACTION

    /**
     * @dev receives underlying token from user and puts inside the Epoch
     * the user recieves the appropriate amount of OT and YT in return
     *
     * @param _streamKey: name of the stream, created by hashing protocol, underlying, duration
     * @param _amountUnderlying: the quantity of underlying tokens user wishes to deposit
     * @return amount of OT minted
     * @return amount of underlying
    */

    function deposit(bytes32 _streamKey, uint256 _amountUnderlying) external returns (uint256, uint256) {
        // check if stream key exists
        revertNonExistentStream(_streamKey);
        address _treasuryAddress = treasuryAddress;

        // transfer underlying from the caller to treasury
        uint256 currentEpochId = getCurrentEpoch(_streamKey);
        IFuture currentEpoch = IFuture(getEpochAddress(_streamKey, currentEpochId));

        // get the yield
        uint256 yield = currentEpoch.yield();
        uint256 amountOT = 0;

        // trasnfer underlying to vault
        IERC20(currentEpoch.underlying()).safeTransferFrom(msg.sender, _treasuryAddress, _amountUnderlying);
        Treasury(_treasuryAddress).deposit(getEpochAddress(_streamKey, currentEpochId), _amountUnderlying);

        // calculate the amount of OT to be distributed using the yield
        if (yield > 0) {
            uint256 totalSupply = IERC20(currentEpoch.getYT()).totalSupply();
            amountOT = _amountUnderlying - ((yield * _amountUnderlying) / totalSupply);
        } else {
            amountOT = _amountUnderlying;
        }

        // normal deposit for adjusted amount
        currentEpoch.mintOT(msg.sender, amountOT);
        currentEpoch.mintYT(msg.sender, _amountUnderlying);

        emit Deposited(_streamKey, msg.sender, _amountUnderlying, currentEpochId);
        return (amountOT, _amountUnderlying);
    }

    ///// USER EXIT
    /**
     * @dev We need to allow the user to reedem their yield from an expired epoch
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future against which yield will be redeemed
     * @notice _epoch must be expired
     */
    function redeemYield(bytes32 _streamKey, uint256 _epoch) external isEpochExpired(_streamKey, _epoch) {
        IFuture epochInstance = IFuture(getEpochAddress(_streamKey, _epoch));

        uint256 totalSupply = epochInstance.totalSupplyYT();
        uint256 amountBurned = epochInstance.burnYT(msg.sender);

        uint256 amountRedeemed =
            Treasury(treasuryAddress).claimYield(
                _streamKey,
                _epoch,
                amountBurned,
                totalSupply,
                epochInstance.underlying(),
                msg.sender
            );

        emit YieldRedeemed(_streamKey, msg.sender, _epoch, amountRedeemed);
    }

    /**
     * @dev We need to allow the user to reedem their principle from an expired epoch
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future against which principle will be redeemed
     */
    function redeemPrinciple(bytes32 _streamKey, uint256 _epoch) external isEpochExpired(_streamKey, _epoch) {
        // check end epoch for user for the stream
        // bytes32 userKey = getUserEpochKey(msg.sender, _streamKey, _epoch);
        // require(userDetailsPerStream[userKey], "ERR_SUBSCRIPTION_NOT_FOUND");

        IFuture epochInstance = IFuture(getEpochAddress(_streamKey, _epoch));
        // check if user has OT to redeem
        require(IERC20(epochInstance.getOT()).balanceOf(msg.sender) > 0, "ERR_INSUFFICIENT_BALANCE");

        uint256 amountBurned = epochInstance.burnOT(msg.sender);

        if (amountBurned > 0) {
            address underlying = epochInstance.underlying();
            Treasury(treasuryAddress).withdraw(underlying, msg.sender, amountBurned);

            emit PrincipleRedeemed(_streamKey, msg.sender, _epoch, amountBurned);
        }
    }

    //
    // VIEWS
    //

    /**
     * @dev Get the current future index for a given stream
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @return current future index
     * @notice in case stream hasn't been initialised, it returns MAX_UINT
     */
    function getCurrentEpoch(bytes32 _streamKey) public view returns (uint256) {
        if (!isStreamInitialized(_streamKey)) {
            return MAX_UINT;
        }
        return streams[_streamKey].length - 1;
    }

    /**
     * @dev Get the upcoming future index for a given stream
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @return the upcoming future index
     */
    function getNextEpoch(bytes32 _streamKey) public view returns (uint256) {
        return streams[_streamKey].length;
    }

    /**
     * @dev Get the address of future for a given stream and index
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future
     * @return address of the future
     */
    function getEpochAddress(bytes32 _streamKey, uint256 _epoch) public view returns (address) {
        return streams[_streamKey][_epoch];
    }

    /**
     * @dev Get the address of OT for a given stream
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future
     * @return address of the OT
     */
    function getOT(bytes32 _streamKey, uint256 _epoch) public view returns (address) {
        address epochAddress = getEpochAddress(_streamKey, _epoch);
        return address(IFuture(epochAddress).getOT());
    }

    /**
     * @dev Get the address of YT for a given stream
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future
     * @return address of the YT
     */
    function getYT(bytes32 _streamKey, uint256 _epoch) public view returns (address) {
        address epochAddress = getEpochAddress(_streamKey, _epoch);
        return address(IFuture(epochAddress).getYT());
    }

    function getOTYTCount(bytes32 _streamKey, uint256 _amountUnderlying) public view returns (uint256, uint256) {
        revertNonExistentStream(_streamKey);

        // transfer underlying from the caller to treasury
        uint256 currentEpochId = getCurrentEpoch(_streamKey);
        IFuture currentEpoch = IFuture(getEpochAddress(_streamKey, currentEpochId));

        // get the yield
        uint256 yield = currentEpoch.yield();
        uint256 amountOT = 0;

        // calculate OT
        if (yield > 0) {
            uint256 totalSupply = IERC20(currentEpoch.getYT()).totalSupply();
            amountOT = _amountUnderlying - ((yield * _amountUnderlying) / totalSupply);
        } else {
            amountOT = _amountUnderlying;
        }

        return (amountOT, _amountUnderlying);
    }

    /**
     * @dev Check if a given stream is initialized
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @return boolean indicating if the stream is initialized or not
     */
    function isStreamInitialized(bytes32 _streamKey) public view returns (bool) {
        // the first future in the stream is always address(0)
        if (streams[_streamKey].length > 0) return true;
        return false;
    }

    /**
     * @dev Function that reverts if a given stream is invalid or uninitialized
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     */
    function revertNonExistentStream(bytes32 _streamKey) internal view {
        require(_streamKey != bytes32(0), "ERR_INVALID_STREAM_KEY_ZERO");
        require(isStreamInitialized(_streamKey), "ERR_STREAM_NOT_INITIALIZED");
    }

    /**
     * @dev Get the yield generated in a given epoch of a stream
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @param _epoch: the index of the future
     * @return the yield generated
     */
    function getYieldRemaining(bytes32 _streamKey, uint256 _epoch) public view returns (uint256) {
        return Treasury(treasuryAddress).yields(_streamKey, _epoch);
    }

    //
    // PURE FUNCTIONS
    //

    /**
     * @dev Get the unique name of the stream, created by hashing protocol, underlying, duration
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _duration: number of blocks the future will run before renewing
     * @return the hashed streamKey
     */
    function getStreamKey(
        string memory _protocol,
        address _underlying,
        uint256 _duration
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_protocol, _underlying, _duration));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFuture {
    function expiry() external returns (uint256);

    function underlying() external returns (address);

    function getYT() external view returns (address);

    function totalSupplyYT() external view returns (uint256);

    function claimYT(address _receiver, uint256 _amount) external;

    function burnYT(address) external returns (uint256);

    function getOT() external view returns (address);

    function totalSupplyOT() external view returns (uint256);

    function claimOT(address _receiver, uint256 _amount) external;

    function burnOT(address _sender) external returns (uint256);

    function totalBalanceUnderlying() external view returns (uint256);

    function initialCapitalInUnderlying() external view returns (uint256);

    function start(
        string memory _protocol,
        uint256 _durationSeconds,
        uint256 _amountInUnderlying,
        uint256 _futureIndex
    ) external;

    function depositInUnderlying(uint256 _amount) external;

    function getInterestBearingToken() external view returns (address);

    function expire() external returns (uint256);

    function owner() external view returns (address);

    function yield() external view returns (uint256);

    function mintYT(address _destination, uint256 _amountToMint) external;

    function mintOT(address _destination, uint256 _amountToMint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { OwnershipToken } from "./tokens/OwnershipToken.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IFuture } from "./interfaces/IFuture.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/Utils.sol";

contract Treasury is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @dev stores a mapping of streamName => bool
     * gets the treasury details attached to a particular stream
     * streamName is created by hashing <protocolName, underlying, duration>
     * */
    mapping(bytes32 => bool) public streamStatus;

    // yield stored per stream per future
    // meta => futureIndex =>yeild
    mapping(bytes32 => mapping(uint256 => uint256)) public yields;

    /**
     * @dev this creates a new treasury which will hold tokens for each new
     * stream when it gets initialised
     *
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _durationSeconds: number of blocks the future will run before renewing
     */
    function createNewTreasuryStream(
        string memory _protocol,
        address _underlying,
        uint256 _durationSeconds
    ) external onlyOwner {
        bytes32 streamKey = getStreamKey(_protocol, _underlying, _durationSeconds);

        // add new stream status
        streamStatus[streamKey] = true;
    }

    /**
     * @dev renews a stream by expiring previous future and safeTransfering the remaining
     * amount of still subscrived underlying to this contract. Mints new OT such that
     * it inflates the price of the underlying per OT.
     * @param _streamKey: name of the stream, created by hashing protocol, underlying, duration
     * @param _nextEpoch: index of the upcoming instance of future in a stream
     * @param _prevEpochAddr: address of the current/just expired future instance
     */
    function renew(
        bytes32 _streamKey,
        uint256 _nextEpoch,
        address _prevEpochAddr
    ) external onlyOwner {
        require(streamExists(_streamKey), "incorrect streamKey, stream doesnt exist");
        IFuture prevEpochInstance = IFuture(_prevEpochAddr);
        uint256 prevEpoch = _nextEpoch - 1;
        uint256 yield = prevEpochInstance.yield();
        prevEpochInstance.expire();
        yields[_streamKey][prevEpoch] = yield;
    }

    /**
     * @dev this funds the future and kicks it off.
     * (ie: deposits the fund in underlying protocol)
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _durationSeconds: number of blocks the future will run before renewing
     * @param to: address of the future
     * @param _amountSubscribedInUnderlying: amount subscribed in underlying protocol.
     * @param _epoch: index of the future
     */
    function fundAndKickOffEpoch(
        string memory _protocol,
        uint256 _durationSeconds,
        address to,
        uint256 _amountSubscribedInUnderlying,
        uint256 _epoch
    ) external onlyOwner {
        IFuture future = IFuture(to);
        IERC20(future.underlying()).safeApprove(to, _amountSubscribedInUnderlying);
        future.start(_protocol, _durationSeconds, _amountSubscribedInUnderlying, _epoch);
    }

    /**
     * @dev claim yield for a particular user, stream and epoch
     * @param _streamKey: name of the stream, created by hashing protocol, underlying, duration
     * @param _shares: amount of YTs of the user for a given future
     * @param _supply: total supply of YT for a given future
     * @param _token: address of the underlying token
     * @param _user: address of the user whose yield needs to be claimed
     */
    function claimYield(
        bytes32 _streamKey,
        uint256 _epoch,
        uint256 _shares,
        uint256 _supply,
        address _token,
        address _user
    ) external onlyOwner returns (uint256 amountTosafeTransfer) {
        uint256 yeildRemaining = yields[_streamKey][_epoch];
        amountTosafeTransfer = (yeildRemaining * _shares) / _supply;
        yields[_streamKey][_epoch] -= amountTosafeTransfer;
        IERC20(_token).safeTransfer(_user, amountTosafeTransfer);
    }

    /**
     * @dev Deposit underlying token to current epoch vault
     * @param _epoch: address of the current epoch
     * @param _amount: amount of tokens to transfer
     */
    function deposit(
        address _epoch,
        uint256 _amount
    )external onlyOwner {
        IFuture future = IFuture(_epoch);
        IERC20(future.underlying()).safeApprove(_epoch, _amount);
        future.depositInUnderlying(_amount);
    }

    /**
     * @dev Withdraw underlying token to an address (similar to: ERC20 token transfer)
     * @param _token: address of underlying token
     * @param _user: address of the user
     * @param _amount: amount of tokens to transfer
     */
    function withdraw(
        address _token,
        address _user,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(_user, _amount);
    }

    // VIEW FUNCTIONS

    /**
     * @dev this checks if a given stream exists
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @return boolean indicating if the stream exists or not
     */
    function streamExists(bytes32 _streamKey) public view returns (bool) {
        require(_streamKey != bytes32(0), "streamkey cannot be zero");
        return streamStatus[_streamKey];
    }

    // PURE FUNCTIONS
    /**
     * @dev Get the unique name of the stream, created by hashing protocol, underlying, duration
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _duration: number of blocks the future will run before renewing
     * @return the hashed streamKey
     */
    function getStreamKey(
        string memory _protocol,
        address _underlying,
        uint256 _duration
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_protocol, _underlying, _duration));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDetailedERC20 is IERC20 {
    function name() external returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OwnershipToken is AccessControl, ERC20 {
    /// @dev The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    /// @dev The identifier of the role which allows accounts to mint tokens.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "MintableToken: only minter");
        _;
    }

    function mint(address _recipient, uint256 _amount) external onlyMinter {
        _mint(_recipient, _amount);
    }

    function burn(address _holder, uint256 _amount) external onlyMinter {
        _burn(_holder, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Utils {
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}