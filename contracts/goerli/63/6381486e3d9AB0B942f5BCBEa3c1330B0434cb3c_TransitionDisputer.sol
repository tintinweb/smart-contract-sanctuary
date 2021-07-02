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
    constructor () {
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Registry is Ownable {
    // require() error messages
    string private constant REQ_BAD_ASSET = "invalid asset";
    string private constant REQ_BAD_ST = "invalid strategy";

    // Map asset addresses to indexes.
    // asset with index 1 is CELR as the platform token
    mapping(address => uint32) public assetAddressToIndex;
    mapping(uint32 => address) public assetIndexToAddress;
    uint32 public numAssets = 0;

    // Valid strategies.
    mapping(address => uint32) public strategyAddressToIndex;
    mapping(uint32 => address) public strategyIndexToAddress;
    uint32 public numStrategies = 0;

    event AssetRegistered(address asset, uint32 assetId);
    event StrategyRegistered(address strategy, uint32 strategyId);
    event StrategyUpdated(address previousStrategy, address newStrategy, uint32 strategyId);

    /**
     * @notice Register a asset
     * @param _asset The asset token address;
     */
    function registerAsset(address _asset) external onlyOwner {
        require(_asset != address(0), REQ_BAD_ASSET);
        require(assetAddressToIndex[_asset] == 0, REQ_BAD_ASSET);

        // Register asset with an index >= 1 (zero is reserved).
        numAssets++;
        assetAddressToIndex[_asset] = numAssets;
        assetIndexToAddress[numAssets] = _asset;

        emit AssetRegistered(_asset, numAssets);
    }

    /**
     * @notice Register a strategy
     * @param _strategy The strategy contract address;
     */
    function registerStrategy(address _strategy) external onlyOwner {
        require(_strategy != address(0), REQ_BAD_ST);
        require(strategyAddressToIndex[_strategy] == 0, REQ_BAD_ST);

        // Register strategy with an index >= 1 (zero is reserved).
        numStrategies++;
        strategyAddressToIndex[_strategy] = numStrategies;
        strategyIndexToAddress[numStrategies] = _strategy;

        emit StrategyRegistered(_strategy, numStrategies);
    }

    /**
     * @notice Update the address of an existing strategy
     * @param _strategy The strategy contract address;
     * @param _strategyId The strategy ID;
     */
    function updateStrategy(address _strategy, uint32 _strategyId) external onlyOwner {
        require(_strategy != address(0), REQ_BAD_ST);
        require(strategyIndexToAddress[_strategyId] != address(0), REQ_BAD_ST);

        address previousStrategy = strategyIndexToAddress[_strategyId];
        strategyAddressToIndex[previousStrategy] = 0;
        strategyAddressToIndex[_strategy] = _strategyId;
        strategyIndexToAddress[_strategyId] = _strategy;

        emit StrategyUpdated(previousStrategy, _strategy, _strategyId);
    }
}

// SPDX-License-Identifier: MIT

// 1st part of the transition applier due to contract size restrictions

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/* Internal Imports */
import {DataTypes as dt} from "./libraries/DataTypes.sol";
import {Transitions as tn} from "./libraries/Transitions.sol";
import "./libraries/ErrMsg.sol";
import "./Registry.sol";
import "./strategies/interfaces/IStrategy.sol";

contract TransitionApplier1 {
    uint128 public constant UINT128_MAX = 2**128 - 1;

    /**********************
     * External Functions *
     **********************/

    /**
     * @notice Apply a DepositTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @return new account info after applying the disputed transition
     */
    function applyDepositTransition(dt.DepositTransition memory _transition, dt.AccountInfo memory _accountInfo)
        public
        pure
        returns (dt.AccountInfo memory)
    {
        require(_transition.account != address(0), ErrMsg.REQ_BAD_ACCT);
        if (_accountInfo.account == address(0)) {
            // first time deposit of this account
            require(_accountInfo.accountId == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfo.idleAssets.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfo.shares.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfo.pending.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfo.timestamp == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            _accountInfo.account = _transition.account;
            _accountInfo.accountId = _transition.accountId;
        } else {
            require(_accountInfo.account == _transition.account, ErrMsg.REQ_BAD_ACCT);
            require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        }

        uint32 assetId = _transition.assetId;
        tn.adjustAccountIdleAssetEntries(_accountInfo, assetId);
        _accountInfo.idleAssets[assetId] += _transition.amount;

        return _accountInfo;
    }

    /**
     * @notice Apply a WithdrawTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account and global info after applying the disputed transition
     */
    function applyWithdrawTransition(
        dt.WithdrawTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.GlobalInfo memory _globalInfo
    ) public pure returns (dt.AccountInfo memory, dt.GlobalInfo memory) {
        bytes32 txHash = keccak256(
            abi.encodePacked(
                _transition.transitionType,
                _transition.account,
                _transition.assetId,
                _transition.amount,
                _transition.fee,
                _transition.timestamp
            )
        );
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(txHash), _transition.v, _transition.r, _transition.s) ==
                _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );

        require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        _accountInfo.timestamp = _transition.timestamp;

        _accountInfo.idleAssets[_transition.assetId] -= _transition.amount;
        tn.addProtoFee(_globalInfo, _transition.assetId, _transition.fee);

        return (_accountInfo, _globalInfo);
    }

    /**
     * @notice Apply a BuyTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @return new account, strategy info, and global info after applying the disputed transition
     */
    function applyBuyTransition(
        dt.BuyTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.StrategyInfo memory _strategyInfo,
        Registry _registry
    ) public view returns (dt.AccountInfo memory, dt.StrategyInfo memory) {
        bytes32 txHash = keccak256(
            abi.encodePacked(
                _transition.transitionType,
                _transition.strategyId,
                _transition.amount,
                _transition.maxSharePrice,
                _transition.fee,
                _transition.timestamp
            )
        );
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(txHash), _transition.v, _transition.r, _transition.s) ==
                _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );

        require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        _accountInfo.timestamp = _transition.timestamp;

        if (_strategyInfo.assetId == 0) {
            // first time commit of new strategy
            require(_strategyInfo.shareSupply == 0, ErrMsg.REQ_ST_NOT_EMPTY);
            require(_strategyInfo.nextAggregateId == 0, ErrMsg.REQ_ST_NOT_EMPTY);
            require(_strategyInfo.lastExecAggregateId == 0, ErrMsg.REQ_ST_NOT_EMPTY);
            require(_strategyInfo.pending.length == 0, ErrMsg.REQ_ST_NOT_EMPTY);

            address strategyAddr = _registry.strategyIndexToAddress(_transition.strategyId);
            address assetAddr = IStrategy(strategyAddr).getAssetAddress();
            _strategyInfo.assetId = _registry.assetAddressToIndex(assetAddr);
        }
        _accountInfo.idleAssets[_strategyInfo.assetId] -= _transition.amount;

        uint256 npend = _strategyInfo.pending.length;
        if (npend == 0 || _strategyInfo.pending[npend - 1].aggregateId != _strategyInfo.nextAggregateId) {
            dt.PendingStrategyInfo[] memory pends = new dt.PendingStrategyInfo[](npend + 1);
            for (uint32 i = 0; i < npend; i++) {
                pends[i] = _strategyInfo.pending[i];
            }
            pends[npend].aggregateId = _strategyInfo.nextAggregateId;
            pends[npend].maxSharePriceForBuy = _transition.maxSharePrice;
            pends[npend].minSharePriceForSell = 0;
            npend++;
            _strategyInfo.pending = pends;
        } else if (_strategyInfo.pending[npend - 1].maxSharePriceForBuy > _transition.maxSharePrice) {
            _strategyInfo.pending[npend - 1].maxSharePriceForBuy = _transition.maxSharePrice;
        }

        uint256 buyAmount = _transition.amount;
        (bool isCelr, uint256 fee) = tn.getFeeInfo(_transition.fee);
        if (isCelr) {
            _accountInfo.idleAssets[1] -= fee;
        } else {
            buyAmount -= fee;
        }

        _strategyInfo.pending[npend - 1].buyAmount += buyAmount;

        _adjustAccountPendingEntries(_accountInfo, _transition.strategyId, _strategyInfo.nextAggregateId);
        npend = _accountInfo.pending[_transition.strategyId].length;
        _accountInfo.pending[_transition.strategyId][npend - 1].buyAmount += buyAmount;
        if (isCelr) {
            _accountInfo.pending[_transition.strategyId][npend - 1].celrFees += fee;
        } else {
            _accountInfo.pending[_transition.strategyId][npend - 1].buyFees += fee;
        }

        return (_accountInfo, _strategyInfo);
    }

    /**
     * @notice Apply a SellTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @return new account, strategy info, and global info after applying the disputed transition
     */
    function applySellTransition(
        dt.SellTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.StrategyInfo memory _strategyInfo
    ) external pure returns (dt.AccountInfo memory, dt.StrategyInfo memory) {
        bytes32 txHash = keccak256(
            abi.encodePacked(
                _transition.transitionType,
                _transition.strategyId,
                _transition.shares,
                _transition.minSharePrice,
                _transition.fee,
                _transition.timestamp
            )
        );
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(txHash), _transition.v, _transition.r, _transition.s) ==
                _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );

        require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        require(_strategyInfo.assetId > 0, ErrMsg.REQ_BAD_ST);
        _accountInfo.timestamp = _transition.timestamp;

        uint256 npend = _strategyInfo.pending.length;
        if (npend == 0 || _strategyInfo.pending[npend - 1].aggregateId != _strategyInfo.nextAggregateId) {
            dt.PendingStrategyInfo[] memory pends = new dt.PendingStrategyInfo[](npend + 1);
            for (uint32 i = 0; i < npend; i++) {
                pends[i] = _strategyInfo.pending[i];
            }
            pends[npend].aggregateId = _strategyInfo.nextAggregateId;
            pends[npend].maxSharePriceForBuy = UINT128_MAX;
            pends[npend].minSharePriceForSell = _transition.minSharePrice;
            npend++;
            _strategyInfo.pending = pends;
        } else if (_strategyInfo.pending[npend - 1].minSharePriceForSell < _transition.minSharePrice) {
            _strategyInfo.pending[npend - 1].minSharePriceForSell = _transition.minSharePrice;
        }

        (bool isCelr, uint256 fee) = tn.getFeeInfo(_transition.fee);
        if (isCelr) {
            _accountInfo.idleAssets[1] -= fee;
        }

        uint32 stId = _transition.strategyId;
        _accountInfo.shares[stId] -= _transition.shares;
        _strategyInfo.pending[npend - 1].sellShares += _transition.shares;

        _adjustAccountPendingEntries(_accountInfo, stId, _strategyInfo.nextAggregateId);
        npend = _accountInfo.pending[stId].length;
        _accountInfo.pending[stId][npend - 1].sellShares += _transition.shares;
        if (isCelr) {
            _accountInfo.pending[stId][npend - 1].celrFees += fee;
        } else {
            _accountInfo.pending[stId][npend - 1].sellFees += fee;
        }

        return (_accountInfo, _strategyInfo);
    }

    /**
     * @notice Apply a SettlementTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account, strategy info, and global info after applying the disputed transition
     */
    function applySettlementTransition(
        dt.SettlementTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.StrategyInfo memory _strategyInfo,
        dt.GlobalInfo memory _globalInfo
    )
        external
        pure
        returns (
            dt.AccountInfo memory,
            dt.StrategyInfo memory,
            dt.GlobalInfo memory
        )
    {
        uint32 stId = _transition.strategyId;
        uint32 assetId = _strategyInfo.assetId;
        uint64 aggrId = _transition.aggregateId;
        require(aggrId <= _strategyInfo.lastExecAggregateId, ErrMsg.REQ_BAD_AGGR);
        require(_strategyInfo.pending.length > 0, ErrMsg.REQ_NO_PEND);
        require(aggrId == _strategyInfo.pending[0].aggregateId, ErrMsg.REQ_BAD_AGGR);
        require(_accountInfo.pending.length > stId, ErrMsg.REQ_BAD_ST);
        require(_accountInfo.pending[stId].length > 0, ErrMsg.REQ_NO_PEND);
        require(aggrId == _accountInfo.pending[stId][0].aggregateId, ErrMsg.REQ_BAD_AGGR);

        dt.PendingStrategyInfo memory stPend = _strategyInfo.pending[0];
        dt.PendingAccountInfo memory acctPend = _accountInfo.pending[stId][0];

        if (stPend.executionSucceed) {
            uint256 assetRefund = _transition.assetRefund;
            uint256 celrRefund = _transition.celrRefund;
            if (acctPend.buyAmount > 0) {
                tn.adjustAccountShareEntries(_accountInfo, stId);
                uint256 shares = (acctPend.buyAmount * stPend.sharesFromBuy) / stPend.buyAmount;
                _accountInfo.shares[stId] += shares;
                stPend.unsettledBuyAmount -= acctPend.buyAmount;
            }
            if (acctPend.sellShares > 0) {
                tn.adjustAccountIdleAssetEntries(_accountInfo, assetId);
                uint256 amount = (acctPend.sellShares * stPend.amountFromSell) / stPend.sellShares;
                uint256 fee = acctPend.sellFees;
                if (fee < assetRefund) {
                    assetRefund -= fee;
                    fee = 0;
                } else {
                    fee -= assetRefund;
                    assetRefund = 0;
                }
                if (amount < fee) {
                    fee = amount;
                }
                amount -= fee;
                tn.addProtoFee(_globalInfo, assetId, fee);
                _accountInfo.idleAssets[assetId] += amount;
                stPend.unsettledSellShares -= acctPend.sellShares;
            }
            _accountInfo.idleAssets[assetId] += assetRefund;
            tn.addProtoFee(_globalInfo, assetId, acctPend.buyFees - assetRefund);
            _accountInfo.idleAssets[1] += celrRefund;
            tn.addProtoFee(_globalInfo, 1, acctPend.celrFees - celrRefund);
        } else {
            if (acctPend.buyAmount > 0) {
                tn.adjustAccountIdleAssetEntries(_accountInfo, assetId);
                _accountInfo.idleAssets[assetId] += acctPend.buyAmount;
                stPend.unsettledBuyAmount -= acctPend.buyAmount;
            }
            if (acctPend.sellShares > 0) {
                tn.adjustAccountShareEntries(_accountInfo, stId);
                _accountInfo.shares[stId] += acctPend.sellShares;
                stPend.unsettledSellShares -= acctPend.sellShares;
            }
            _accountInfo.idleAssets[assetId] += acctPend.buyFees;
            _accountInfo.idleAssets[1] += acctPend.celrFees;
        }

        _popHeadAccountPendingEntries(_accountInfo, stId);
        if (stPend.unsettledBuyAmount == 0 && stPend.unsettledSellShares == 0) {
            _popHeadStrategyPendingEntries(_strategyInfo);
        }

        return (_accountInfo, _strategyInfo, _globalInfo);
    }

    /**
     * @notice Apply a TransferAssetTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition (source of the transfer).
     * @param _accountInfoDest The involved destination account from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account info for both accounts, and global info after applying the disputed transition
     */
    function applyAssetTransferTransition(
        dt.TransferAssetTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.AccountInfo memory _accountInfoDest,
        dt.GlobalInfo memory _globalInfo
    )
        external
        pure
        returns (
            dt.AccountInfo memory,
            dt.AccountInfo memory,
            dt.GlobalInfo memory
        )
    {
        bytes32 txHash = keccak256(
            abi.encodePacked(
                _transition.transitionType,
                _transition.toAccount,
                _transition.assetId,
                _transition.amount,
                _transition.fee,
                _transition.timestamp
            )
        );
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(txHash), _transition.v, _transition.r, _transition.s) ==
                _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );
        require(_accountInfo.accountId == _transition.fromAccountId, ErrMsg.REQ_BAD_ACCT);

        if (_accountInfoDest.account == address(0)) {
            // transfer to a new account
            require(_accountInfoDest.accountId == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.idleAssets.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.shares.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.pending.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.timestamp == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            _accountInfoDest.account = _transition.toAccount;
            _accountInfoDest.accountId = _transition.toAccountId;
        } else {
            require(_accountInfoDest.account == _transition.toAccount, ErrMsg.REQ_BAD_ACCT);
            require(_accountInfoDest.accountId == _transition.toAccountId, ErrMsg.REQ_BAD_ACCT);
        }

        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        _accountInfo.timestamp = _transition.timestamp;

        uint32 assetId = _transition.assetId;
        uint256 amount = _transition.amount;
        (bool isCelr, uint256 fee) = tn.getFeeInfo(_transition.fee);
        if (isCelr) {
            _accountInfo.idleAssets[1] -= fee;
            tn.updateOpFee(_globalInfo, true, 1, fee);
        } else {
            amount -= fee;
            tn.updateOpFee(_globalInfo, true, assetId, fee);
        }

        tn.adjustAccountIdleAssetEntries(_accountInfoDest, assetId);
        _accountInfo.idleAssets[assetId] -= _transition.amount;
        _accountInfoDest.idleAssets[assetId] += amount;

        return (_accountInfo, _accountInfoDest, _globalInfo);
    }

    /**
     * @notice Apply a TransferShareTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition (source of the transfer).
     * @param _accountInfoDest The involved destination account from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account info for both accounts, and global info after applying the disputed transition
     */
    function applyShareTransferTransition(
        dt.TransferShareTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.AccountInfo memory _accountInfoDest,
        dt.GlobalInfo memory _globalInfo
    )
        external
        pure
        returns (
            dt.AccountInfo memory,
            dt.AccountInfo memory,
            dt.GlobalInfo memory
        )
    {
        bytes32 txHash = keccak256(
            abi.encodePacked(
                _transition.transitionType,
                _transition.toAccount,
                _transition.strategyId,
                _transition.shares,
                _transition.fee,
                _transition.timestamp
            )
        );
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(txHash), _transition.v, _transition.r, _transition.s) ==
                _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );
        require(_accountInfo.accountId == _transition.fromAccountId, ErrMsg.REQ_BAD_ACCT);

        if (_accountInfoDest.account == address(0)) {
            // transfer to a new account
            require(_accountInfoDest.accountId == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.idleAssets.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.shares.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.pending.length == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            require(_accountInfoDest.timestamp == 0, ErrMsg.REQ_ACCT_NOT_EMPTY);
            _accountInfoDest.account = _transition.toAccount;
            _accountInfoDest.accountId = _transition.toAccountId;
        } else {
            require(_accountInfoDest.account == _transition.toAccount, ErrMsg.REQ_BAD_ACCT);
            require(_accountInfoDest.accountId == _transition.toAccountId, ErrMsg.REQ_BAD_ACCT);
        }

        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        _accountInfo.timestamp = _transition.timestamp;

        uint32 stId = _transition.strategyId;
        uint256 shares = _transition.shares;
        (bool isCelr, uint256 fee) = tn.getFeeInfo(_transition.fee);
        if (isCelr) {
            _accountInfo.idleAssets[1] -= fee;
            tn.updateOpFee(_globalInfo, true, 1, fee);
        } else {
            shares -= fee;
            tn.updateOpFee(_globalInfo, false, stId, fee);
        }

        tn.adjustAccountShareEntries(_accountInfoDest, stId);
        _accountInfo.shares[stId] -= _transition.shares;
        _accountInfoDest.shares[stId] += shares;

        return (_accountInfo, _accountInfoDest, _globalInfo);
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Helper to expand and initialize the 2D array of account pending entries per strategy and aggregate IDs.
     */
    function _adjustAccountPendingEntries(
        dt.AccountInfo memory _accountInfo,
        uint32 stId,
        uint64 aggrId
    ) private pure {
        uint32 n = uint32(_accountInfo.pending.length);
        if (n <= stId) {
            dt.PendingAccountInfo[][] memory pends = new dt.PendingAccountInfo[][](stId + 1);
            for (uint32 i = 0; i < n; i++) {
                pends[i] = _accountInfo.pending[i];
            }
            for (uint32 i = n; i < stId; i++) {
                pends[i] = new dt.PendingAccountInfo[](0);
            }
            pends[stId] = new dt.PendingAccountInfo[](1);
            pends[stId][0].aggregateId = aggrId;
            _accountInfo.pending = pends;
        } else {
            uint32 npend = uint32(_accountInfo.pending[stId].length);
            if (npend == 0 || _accountInfo.pending[stId][npend - 1].aggregateId != aggrId) {
                dt.PendingAccountInfo[] memory pends = new dt.PendingAccountInfo[](npend + 1);
                for (uint32 i = 0; i < npend; i++) {
                    pends[i] = _accountInfo.pending[stId][i];
                }
                pends[npend].aggregateId = aggrId;
                _accountInfo.pending[stId] = pends;
            }
        }
    }

    /**
     * Helper to pop the head from the 2D array of account pending entries for a strategy.
     */
    function _popHeadAccountPendingEntries(dt.AccountInfo memory _accountInfo, uint32 stId) private pure {
        if (_accountInfo.pending.length <= uint256(stId)) {
            return;
        }

        uint256 n = _accountInfo.pending[stId].length;
        if (n == 0) {
            return;
        }

        dt.PendingAccountInfo[] memory arr = new dt.PendingAccountInfo[](n - 1); // zero is ok for empty array
        for (uint256 i = 1; i < n; i++) {
            arr[i - 1] = _accountInfo.pending[stId][i];
        }
        _accountInfo.pending[stId] = arr;
    }

    /**
     * Helper to pop the head from the strategy pending entries.
     */
    function _popHeadStrategyPendingEntries(dt.StrategyInfo memory _strategyInfo) private pure {
        uint256 n = _strategyInfo.pending.length;
        if (n == 0) {
            return;
        }

        dt.PendingStrategyInfo[] memory arr = new dt.PendingStrategyInfo[](n - 1); // zero is ok for empty array
        for (uint256 i = 1; i < n; i++) {
            arr[i - 1] = _strategyInfo.pending[i];
        }
        _strategyInfo.pending = arr;
    }
}

// SPDX-License-Identifier: MIT

// 2nd part of the transition applier due to contract size restrictions

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/* Internal Imports */
import {DataTypes as dt} from "./libraries/DataTypes.sol";
import {Transitions as tn} from "./libraries/Transitions.sol";
import "./libraries/ErrMsg.sol";

contract TransitionApplier2 {
    uint256 public constant STAKING_SCALE_FACTOR = 1e12;

    /**********************
     * External Functions *
     **********************/

    /**
     * @notice Apply an AggregateOrdersTransition.
     *
     * @param _transition The disputed transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @return new strategy info after applying the disputed transition
     */
    function applyAggregateOrdersTransition(
        dt.AggregateOrdersTransition memory _transition,
        dt.StrategyInfo memory _strategyInfo
    ) public pure returns (dt.StrategyInfo memory) {
        uint256 npend = _strategyInfo.pending.length;
        require(npend > 0, ErrMsg.REQ_NO_PEND);
        dt.PendingStrategyInfo memory psi = _strategyInfo.pending[npend - 1];
        require(_transition.buyAmount == psi.buyAmount, ErrMsg.REQ_BAD_AMOUNT);
        require(_transition.sellShares == psi.sellShares, ErrMsg.REQ_BAD_SHARES);

        uint256 minSharesFromBuy = (_transition.buyAmount * 1e18) / psi.maxSharePriceForBuy;
        uint256 minAmountFromSell = (_transition.sellShares * psi.minSharePriceForSell) / 1e18;
        require(_transition.minSharesFromBuy == minSharesFromBuy, ErrMsg.REQ_BAD_SHARES);
        require(_transition.minAmountFromSell == minAmountFromSell, ErrMsg.REQ_BAD_AMOUNT);

        _strategyInfo.nextAggregateId++;

        return _strategyInfo;
    }

    /**
     * @notice Apply a ExecutionResultTransition.
     *
     * @param _transition The disputed transition.
     * @param _strategyInfo The involved strategy from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new strategy info after applying the disputed transition
     */
    function applyExecutionResultTransition(
        dt.ExecutionResultTransition memory _transition,
        dt.StrategyInfo memory _strategyInfo,
        dt.GlobalInfo memory _globalInfo
    ) public pure returns (dt.StrategyInfo memory, dt.GlobalInfo memory) {
        uint256 idx;
        bool found = false;
        for (uint256 i = 0; i < _strategyInfo.pending.length; i++) {
            if (_strategyInfo.pending[i].aggregateId == _transition.aggregateId) {
                idx = i;
                found = true;
                break;
            }
        }
        require(found, ErrMsg.REQ_BAD_AGGR);

        if (_transition.success) {
            _strategyInfo.pending[idx].sharesFromBuy = _transition.sharesFromBuy;
            _strategyInfo.pending[idx].amountFromSell = _transition.amountFromSell;
        }
        _strategyInfo.pending[idx].executionSucceed = _transition.success;
        _strategyInfo.pending[idx].unsettledBuyAmount = _strategyInfo.pending[idx].buyAmount;
        _strategyInfo.pending[idx].unsettledSellShares = _strategyInfo.pending[idx].sellShares;
        _strategyInfo.lastExecAggregateId = _transition.aggregateId;

        return (_strategyInfo, _globalInfo);
    }

    /**
     * @notice Apply a WithdrawProtocolFeeTransition.
     *
     * @param _transition The disputed transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new global info after applying the disputed transition
     */
    function applyWithdrawProtocolFeeTransition(
        dt.WithdrawProtocolFeeTransition memory _transition,
        dt.GlobalInfo memory _globalInfo
    ) public pure returns (dt.GlobalInfo memory) {
        _globalInfo.protoFees[_transition.assetId] -= _transition.amount;
        return _globalInfo;
    }

    /**
     * @notice Apply a TransferOperatorFeeTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account info and global info after applying the disputed transition
     */
    function applyTransferOperatorFeeTransition(
        dt.TransferOperatorFeeTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.GlobalInfo memory _globalInfo
    ) external pure returns (dt.AccountInfo memory, dt.GlobalInfo memory) {
        require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        require(_accountInfo.account != address(0), ErrMsg.REQ_BAD_ACCT);

        uint32 assetFeeLen = uint32(_globalInfo.opFees.assets.length);
        if (assetFeeLen > 1) {
            tn.adjustAccountIdleAssetEntries(_accountInfo, assetFeeLen - 1);
            for (uint256 i = 1; i < assetFeeLen; i++) {
                _accountInfo.idleAssets[i] += _globalInfo.opFees.assets[i];
                _globalInfo.opFees.assets[i] = 0;
            }
        }

        uint32 shareFeeLen = uint32(_globalInfo.opFees.shares.length);
        if (shareFeeLen > 1) {
            tn.adjustAccountShareEntries(_accountInfo, shareFeeLen - 1);
            for (uint256 i = 1; i < shareFeeLen; i++) {
                _accountInfo.shares[i] += _globalInfo.opFees.shares[i];
                _globalInfo.opFees.shares[i] = 0;
            }
        }

        return (_accountInfo, _globalInfo);
    }

    /**
     * @notice Apply a UpdateEpochTransition.
     *
     * @param _transition The disputed transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new global info after applying the disputed transition
     */
    function applyUpdateEpochTransition(dt.UpdateEpochTransition memory _transition, dt.GlobalInfo memory _globalInfo)
        public
        pure
        returns (dt.GlobalInfo memory)
    {
        if (_transition.epoch >= _globalInfo.currEpoch) {
            _globalInfo.currEpoch = _transition.epoch;
        }
        return _globalInfo;
    }

    /**
     * @notice Apply a StakeTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _stakingPoolInfo The involved staking pool from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account, staking pool and global info after applying the disputed transition
     */
    function applyStakeTransition(
        dt.StakeTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.StakingPoolInfo memory _stakingPoolInfo,
        dt.GlobalInfo memory _globalInfo
    )
        external
        pure
        returns (
            dt.AccountInfo memory,
            dt.StakingPoolInfo memory,
            dt.GlobalInfo memory
        )
    {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(
                        abi.encodePacked(
                            _transition.transitionType,
                            _transition.poolId,
                            _transition.shares,
                            _transition.fee,
                            _transition.timestamp
                        )
                    )
                ),
                _transition.v,
                _transition.r,
                _transition.s
            ) == _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );

        require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        require(_stakingPoolInfo.strategyId > 0, ErrMsg.REQ_BAD_SP);
        _accountInfo.timestamp = _transition.timestamp;

        uint32 poolId = _transition.poolId;
        uint256 feeInShares;
        (bool isCelr, uint256 fee) = tn.getFeeInfo(_transition.fee);
        if (isCelr) {
            _accountInfo.idleAssets[1] -= fee;
            tn.updateOpFee(_globalInfo, true, 1, fee);
        } else {
            feeInShares = fee;
            tn.updateOpFee(_globalInfo, false, _stakingPoolInfo.strategyId, fee);
        }
        uint256 addedShares = _transition.shares - feeInShares;

        _updatePoolStates(_stakingPoolInfo, _globalInfo);

        _adjustAccountStakedShareAndStakeEntries(_accountInfo, poolId);
        _adjustAccountRewardDebtEntries(_accountInfo, poolId, uint32(_stakingPoolInfo.rewardPerEpoch.length - 1));
        if (addedShares > 0) {
            uint256 addedStake = _getAdjustedStake(
                _accountInfo.stakedShares[poolId] + addedShares,
                _stakingPoolInfo.stakeAdjustmentFactor
            ) - _accountInfo.stakes[poolId];
            _accountInfo.stakedShares[poolId] += addedShares;
            _accountInfo.stakes[poolId] += addedStake;
            _stakingPoolInfo.totalShares += addedShares;
            _stakingPoolInfo.totalStakes += addedStake;

            for (uint32 rewardTokenId = 0; rewardTokenId < _stakingPoolInfo.rewardPerEpoch.length; rewardTokenId++) {
                _accountInfo.rewardDebts[poolId][rewardTokenId] +=
                    (addedStake * _stakingPoolInfo.accumulatedRewardPerUnit[rewardTokenId]) /
                    STAKING_SCALE_FACTOR;
            }
        }
        tn.adjustAccountShareEntries(_accountInfo, _stakingPoolInfo.strategyId);
        _accountInfo.shares[_stakingPoolInfo.strategyId] -= _transition.shares;

        return (_accountInfo, _stakingPoolInfo, _globalInfo);
    }

    /**
     * @notice Apply an UnstakeTransition.
     *
     * @param _transition The disputed transition.
     * @param _accountInfo The involved account from the previous transition.
     * @param _stakingPoolInfo The involved staking pool from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new account, staking pool and global info after applying the disputed transition
     */
    function applyUnstakeTransition(
        dt.UnstakeTransition memory _transition,
        dt.AccountInfo memory _accountInfo,
        dt.StakingPoolInfo memory _stakingPoolInfo,
        dt.GlobalInfo memory _globalInfo
    )
        external
        pure
        returns (
            dt.AccountInfo memory,
            dt.StakingPoolInfo memory,
            dt.GlobalInfo memory
        )
    {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(
                        abi.encodePacked(
                            _transition.transitionType,
                            _transition.poolId,
                            _transition.shares,
                            _transition.fee,
                            _transition.timestamp
                        )
                    )
                ),
                _transition.v,
                _transition.r,
                _transition.s
            ) == _accountInfo.account,
            ErrMsg.REQ_BAD_SIG
        );

        require(_accountInfo.accountId == _transition.accountId, ErrMsg.REQ_BAD_ACCT);
        require(_accountInfo.timestamp < _transition.timestamp, ErrMsg.REQ_BAD_TS);
        require(_stakingPoolInfo.strategyId > 0, ErrMsg.REQ_BAD_SP);
        _accountInfo.timestamp = _transition.timestamp;

        uint32 poolId = _transition.poolId;
        uint256 feeInShares;
        (bool isCelr, uint256 fee) = tn.getFeeInfo(_transition.fee);
        if (isCelr) {
            _accountInfo.idleAssets[1] -= fee;
            tn.updateOpFee(_globalInfo, true, 1, fee);
        } else {
            feeInShares = fee;
            tn.updateOpFee(_globalInfo, false, _stakingPoolInfo.strategyId, fee);
        }
        uint256 removedShares = _transition.shares;

        _updatePoolStates(_stakingPoolInfo, _globalInfo);

        require(_accountInfo.stakes.length > poolId, ErrMsg.REQ_BAD_AMOUNT);
        _adjustAccountRewardDebtEntries(_accountInfo, poolId, uint32(_stakingPoolInfo.rewardPerEpoch.length - 1));
        uint256 originalStake = _accountInfo.stakes[poolId];
        if (removedShares > 0) {
            uint256 removedStake = _accountInfo.stakes[poolId] -
                _getAdjustedStake(
                    _accountInfo.stakedShares[poolId] - removedShares,
                    _stakingPoolInfo.stakeAdjustmentFactor
                );
            _accountInfo.stakedShares[poolId] -= removedShares;
            _accountInfo.stakes[poolId] -= removedStake;
            _stakingPoolInfo.totalShares -= removedShares;
            _stakingPoolInfo.totalStakes -= removedStake;
        }
        // Harvest
        for (uint32 rewardTokenId = 0; rewardTokenId < _stakingPoolInfo.rewardPerEpoch.length; rewardTokenId++) {
            // NOTE: Calculate pending reward using original stake to avoid rounding down twice
            uint256 pendingReward = (originalStake * _stakingPoolInfo.accumulatedRewardPerUnit[rewardTokenId]) /
                STAKING_SCALE_FACTOR -
                _accountInfo.rewardDebts[poolId][rewardTokenId];
            _accountInfo.rewardDebts[poolId][rewardTokenId] =
                (_accountInfo.stakes[poolId] * _stakingPoolInfo.accumulatedRewardPerUnit[rewardTokenId]) /
                STAKING_SCALE_FACTOR;
            uint32 assetId = _stakingPoolInfo.rewardAssetIds[rewardTokenId];
            _globalInfo.rewards = tn.adjustUint256Array(_globalInfo.rewards, assetId);
            // Cap to available reward
            if (pendingReward > _globalInfo.rewards[assetId]) {
                pendingReward = _globalInfo.rewards[assetId];
            }
            _accountInfo.idleAssets[assetId] += pendingReward;
            _globalInfo.rewards[assetId] -= pendingReward;
        }
        tn.adjustAccountShareEntries(_accountInfo, _stakingPoolInfo.strategyId);
        _accountInfo.shares[_stakingPoolInfo.strategyId] += _transition.shares - feeInShares;

        return (_accountInfo, _stakingPoolInfo, _globalInfo);
    }

    /**
     * @notice Apply an AddPoolTransition.
     *
     * @param _transition The disputed transition.
     * @param _stakingPoolInfo The involved staking pool from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new staking pool info after applying the disputed transition
     */
    function applyAddPoolTransition(
        dt.AddPoolTransition memory _transition,
        dt.StakingPoolInfo memory _stakingPoolInfo,
        dt.GlobalInfo memory _globalInfo
    ) external pure returns (dt.StakingPoolInfo memory) {
        require(_transition.rewardAssetIds.length > 0, ErrMsg.REQ_BAD_LEN);
        require(_transition.rewardAssetIds.length == _transition.rewardPerEpoch.length, ErrMsg.REQ_BAD_LEN);
        require(_stakingPoolInfo.strategyId == 0, ErrMsg.REQ_BAD_SP);
        require(_transition.startEpoch >= _globalInfo.currEpoch, ErrMsg.REQ_BAD_EPOCH);

        _stakingPoolInfo.lastRewardEpoch = _transition.startEpoch;
        _stakingPoolInfo.stakeAdjustmentFactor = _transition.stakeAdjustmentFactor;
        _stakingPoolInfo.strategyId = _transition.strategyId;
        _stakingPoolInfo.rewardAssetIds = _transition.rewardAssetIds;
        _stakingPoolInfo.accumulatedRewardPerUnit = tn.adjustUint256Array(
            _stakingPoolInfo.accumulatedRewardPerUnit,
            uint32(_transition.rewardAssetIds.length)
        );
        _stakingPoolInfo.rewardPerEpoch = _transition.rewardPerEpoch;
        return _stakingPoolInfo;
    }

    /**
     * @notice Apply an UpdatePoolTransition.
     *
     * @param _transition The disputed transition.
     * @param _stakingPoolInfo The involved staking pool from the previous transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new staking pool info after applying the disputed transition
     */
    function applyUpdatePoolTransition(
        dt.UpdatePoolTransition memory _transition,
        dt.StakingPoolInfo memory _stakingPoolInfo,
        dt.GlobalInfo memory _globalInfo
    ) external pure returns (dt.StakingPoolInfo memory) {
        require(_transition.rewardPerEpoch.length == _stakingPoolInfo.rewardPerEpoch.length, ErrMsg.REQ_BAD_LEN);
        require(_stakingPoolInfo.strategyId > 0, ErrMsg.REQ_BAD_SP);

        _updatePoolStates(_stakingPoolInfo, _globalInfo);

        _stakingPoolInfo.rewardPerEpoch = _transition.rewardPerEpoch;
        return _stakingPoolInfo;
    }

    /**
     * @notice Apply a DepositRewardTransition.
     *
     * @param _transition The disputed transition.
     * @param _globalInfo The involved global info from the previous transition.
     * @return new global info after applying the disputed transition
     */
    function applyDepositRewardTransition(
        dt.DepositRewardTransition memory _transition,
        dt.GlobalInfo memory _globalInfo
    ) public pure returns (dt.GlobalInfo memory) {
        _globalInfo.rewards = tn.adjustUint256Array(_globalInfo.rewards, _transition.assetId);
        _globalInfo.rewards[_transition.assetId] += _transition.amount;
        return _globalInfo;
    }

    /*********************
     * Private Functions *
     *********************/

    function _updatePoolStates(dt.StakingPoolInfo memory _stakingPoolInfo, dt.GlobalInfo memory _globalInfo)
        private
        pure
    {
        if (_globalInfo.currEpoch > _stakingPoolInfo.lastRewardEpoch) {
            uint256 totalStakes = _stakingPoolInfo.totalStakes;
            if (totalStakes > 0) {
                uint64 numEpochs = _globalInfo.currEpoch - _stakingPoolInfo.lastRewardEpoch;
                for (
                    uint32 rewardTokenId = 0;
                    rewardTokenId < _stakingPoolInfo.rewardPerEpoch.length;
                    rewardTokenId++
                ) {
                    uint256 pendingReward = numEpochs * _stakingPoolInfo.rewardPerEpoch[rewardTokenId];
                    _stakingPoolInfo.accumulatedRewardPerUnit[rewardTokenId] += ((pendingReward *
                        STAKING_SCALE_FACTOR) / totalStakes);
                }
            }
            _stakingPoolInfo.lastRewardEpoch = _globalInfo.currEpoch;
        }
    }

    /**
     * Helper to expand the account array of staked shares and stakes if needed.
     */
    function _adjustAccountStakedShareAndStakeEntries(dt.AccountInfo memory _accountInfo, uint32 poolId) private pure {
        uint32 n = uint32(_accountInfo.stakedShares.length);
        if (n <= poolId) {
            uint256[] memory arr = new uint256[](poolId + 1);
            for (uint32 i = 0; i < n; i++) {
                arr[i] = _accountInfo.stakedShares[i];
            }
            for (uint32 i = n; i <= poolId; i++) {
                arr[i] = 0;
            }
            _accountInfo.stakedShares = arr;
        }
        n = uint32(_accountInfo.stakes.length);
        if (n <= poolId) {
            uint256[] memory arr = new uint256[](poolId + 1);
            for (uint32 i = 0; i < n; i++) {
                arr[i] = _accountInfo.stakes[i];
            }
            for (uint32 i = n; i <= poolId; i++) {
                arr[i] = 0;
            }
            _accountInfo.stakes = arr;
        }
    }

    /**
     * Helper to expand the 2D array of account reward debt entries per pool and reward token IDs.
     */
    function _adjustAccountRewardDebtEntries(
        dt.AccountInfo memory _accountInfo,
        uint32 poolId,
        uint32 rewardTokenId
    ) private pure {
        uint32 n = uint32(_accountInfo.rewardDebts.length);
        if (n <= poolId) {
            uint256[][] memory rewardDebts = new uint256[][](poolId + 1);
            for (uint32 i = 0; i < n; i++) {
                rewardDebts[i] = _accountInfo.rewardDebts[i];
            }
            for (uint32 i = n; i < poolId; i++) {
                rewardDebts[i] = new uint256[](0);
            }
            rewardDebts[poolId] = new uint256[](rewardTokenId + 1);
            _accountInfo.rewardDebts = rewardDebts;
        }
        uint32 nRewardTokens = uint32(_accountInfo.rewardDebts[poolId].length);
        if (nRewardTokens <= rewardTokenId) {
            uint256[] memory debts = new uint256[](rewardTokenId + 1);
            for (uint32 i = 0; i < nRewardTokens; i++) {
                debts[i] = _accountInfo.rewardDebts[poolId][i];
            }
            for (uint32 i = nRewardTokens; i <= rewardTokenId; i++) {
                debts[i] = 0;
            }
            _accountInfo.rewardDebts[poolId] = debts;
        }
    }

    /**
     * @notice Calculates the adjusted stake from staked shares.
     * @param _stakedShares The staked shares
     * @param _adjustmentFactor The adjustment factor, a value from (0, 1) * STAKING_SCALE_FACTOR
     */
    function _getAdjustedStake(uint256 _stakedShares, uint256 _adjustmentFactor) private pure returns (uint256) {
        return
            ((STAKING_SCALE_FACTOR - _adjustmentFactor) *
                _stakedShares +
                _sqrt(STAKING_SCALE_FACTOR * _adjustmentFactor * _stakedShares)) / STAKING_SCALE_FACTOR;
    }

    /**
     * @notice Implements square root with Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method).
     * @param _y The input
     */
    function _sqrt(uint256 _y) private pure returns (uint256) {
        uint256 z;
        if (_y > 3) {
            z = _y;
            uint256 x = _y / 2 + 1;
            while (x < z) {
                z = x;
                x = (_y / x + x) / 2;
            }
        } else if (_y != 0) {
            z = 1;
        }
        return z;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import {DataTypes as dt} from "./libraries/DataTypes.sol";
import {Transitions as tn} from "./libraries/Transitions.sol";
import "./libraries/ErrMsg.sol";
import "./libraries/MerkleTree.sol";
import "./TransitionEvaluator.sol";
import "./Registry.sol";

contract TransitionDisputer {
    // state root of empty account, strategy, staking pool, global info
    bytes32 public constant INIT_TRANSITION_STATE_ROOT =
        bytes32(0xc6011c637feab6939cc17cdfdd9e34a435f76bd08fcc224f59edaeb31fd13928);

    TransitionEvaluator public immutable transitionEvaluator;

    constructor(TransitionEvaluator _transitionEvaluator) {
        transitionEvaluator = _transitionEvaluator;
    }

    /**********************
     * External Functions *
     **********************/

    struct disputeStateInfo {
        bytes32 preStateRoot;
        bytes32 postStateRoot;
        uint32 accountId;
        uint32 accountIdDest;
        uint32 strategyId;
        uint32 stakingPoolId;
    }

    /**
     * @notice Dispute a transition.
     *
     * @param _prevTransitionProof The inclusion proof of the transition immediately before the fraudulent transition.
     * @param _invalidTransitionProof The inclusion proof of the fraudulent transition.
     * @param _accountProofs The inclusion proofs of one or two accounts involved.
     * @param _strategyProof The inclusion proof of the strategy involved.
     * @param _stakingPoolProof The inclusion proof of the staking pool involved.
     * @param _globalInfo The global info.
     * @param _prevTransitionBlock The previous transition block
     * @param _invalidTransitionBlock The invalid transition block
     * @param _registry The address of the Registry contract.
     *
     * @return reason of the transition being determined as invalid
     */
    function disputeTransition(
        dt.TransitionProof calldata _prevTransitionProof,
        dt.TransitionProof calldata _invalidTransitionProof,
        dt.AccountProof[] calldata _accountProofs,
        dt.StrategyProof calldata _strategyProof,
        dt.StakingPoolProof calldata _stakingPoolProof,
        dt.GlobalInfo calldata _globalInfo,
        dt.Block calldata _prevTransitionBlock,
        dt.Block calldata _invalidTransitionBlock,
        Registry _registry
    ) external returns (string memory) {
        require(_accountProofs.length > 0, ErrMsg.REQ_ONE_ACCT);
        if (_invalidTransitionProof.blockId == 0 && _invalidTransitionProof.index == 0) {
            require(_invalidInitTransition(_invalidTransitionProof, _invalidTransitionBlock), ErrMsg.REQ_NO_FRAUD);
            return ErrMsg.RSN_BAD_INIT_TN;
        }

        // ------ #1: verify sequential transitions
        // First verify that the transitions are sequential and in their respective block root hashes.
        _verifySequentialTransitions(
            _prevTransitionProof,
            _invalidTransitionProof,
            _prevTransitionBlock,
            _invalidTransitionBlock
        );

        // ------ #2: decode transitions to get post- and pre-StateRoot, and ids of account(s) and strategy
        (bool ok, disputeStateInfo memory dsi) = _getStateRootsAndIds(
            _prevTransitionProof.transition,
            _invalidTransitionProof.transition
        );
        // If not success something went wrong with the decoding...
        if (!ok) {
            // revert the block if it has an incorrectly encoded transition!
            return ErrMsg.RSN_BAD_ENCODING;
        }

        if ((dsi.accountId > 0) && (dsi.accountIdDest > 0)) {
            require(_accountProofs.length == 2, ErrMsg.REQ_TWO_ACCT);
        } else if (dsi.accountId > 0) {
            require(_accountProofs.length == 1, ErrMsg.REQ_ONE_ACCT);
        }

        // ------ #3: verify transition stateRoot == hash(accountStateRoot, strategyStateRoot, stakingPoolStateRoot, globalInfoHash)
        // All stateRoots for the subtrees must always be given irrespective of what is being disputed.
        require(
            _checkMultiTreeStateRoot(
                dsi.preStateRoot,
                _accountProofs[0].stateRoot,
                _strategyProof.stateRoot,
                _stakingPoolProof.stateRoot,
                transitionEvaluator.getGlobalInfoHash(_globalInfo)
            ),
            ErrMsg.REQ_BAD_NTREE
        );
        for (uint256 i = 1; i < _accountProofs.length; i++) {
            require(_accountProofs[i].stateRoot == _accountProofs[0].stateRoot, ErrMsg.REQ_BAD_SROOT);
        }

        // ------ #4: verify account, strategy and staking pool inclusion
        if (dsi.accountId > 0) {
            for (uint256 i = 0; i < _accountProofs.length; i++) {
                _verifyProofInclusion(
                    _accountProofs[i].stateRoot,
                    transitionEvaluator.getAccountInfoHash(_accountProofs[i].value),
                    _accountProofs[i].index,
                    _accountProofs[i].siblings
                );
            }
        }
        if (dsi.strategyId > 0) {
            _verifyProofInclusion(
                _strategyProof.stateRoot,
                transitionEvaluator.getStrategyInfoHash(_strategyProof.value),
                _strategyProof.index,
                _strategyProof.siblings
            );
        }
        if (dsi.stakingPoolId > 0) {
            _verifyProofInclusion(
                _stakingPoolProof.stateRoot,
                transitionEvaluator.getStakingPoolInfoHash(_stakingPoolProof.value),
                _stakingPoolProof.index,
                _stakingPoolProof.siblings
            );
        }

        // ------ #5: verify unique account id mapping for deposit and transfer tns
        uint8 transitionType = tn.extractTransitionType(_invalidTransitionProof.transition);
        if (transitionType == tn.TN_TYPE_DEPOSIT) {
            dt.DepositTransition memory transition = tn.decodePackedDepositTransition(
                _invalidTransitionProof.transition
            );
            if (
                _accountProofs[0].value.account == transition.account &&
                _accountProofs[0].value.accountId != dsi.accountId
            ) {
                return ErrMsg.RSN_BAD_ACCT_ID;
            }
        } else if (transitionType == tn.TN_TYPE_XFER_ASSET) {
            dt.TransferAssetTransition memory transition = tn.decodePackedTransferAssetTransition(
                _invalidTransitionProof.transition
            );
            if (
                _accountProofs[1].value.account == transition.toAccount &&
                _accountProofs[1].value.accountId != dsi.accountIdDest
            ) {
                return ErrMsg.RSN_BAD_ACCT_ID;
            }
        } else if (transitionType == tn.TN_TYPE_XFER_SHARE) {
            dt.TransferShareTransition memory transition = tn.decodePackedTransferShareTransition(
                _invalidTransitionProof.transition
            );
            if (
                _accountProofs[1].value.account == transition.toAccount &&
                _accountProofs[1].value.accountId != dsi.accountIdDest
            ) {
                return ErrMsg.RSN_BAD_ACCT_ID;
            }
        }

        // ------ #6: verify transition account, strategy, staking pool indexes
        if (dsi.accountId > 0) {
            require(_accountProofs[0].index == dsi.accountId, ErrMsg.REQ_BAD_INDEX);
            if (dsi.accountIdDest > 0) {
                require(_accountProofs[1].index == dsi.accountIdDest, ErrMsg.REQ_BAD_INDEX);
            }
        }
        if (dsi.strategyId > 0) {
            require(_strategyProof.index == dsi.strategyId, ErrMsg.REQ_BAD_INDEX);
        }
        if (dsi.stakingPoolId > 0) {
            require(_stakingPoolProof.index == dsi.stakingPoolId, ErrMsg.REQ_BAD_INDEX);
        }

        // ------ #7: evaluate transition and verify new state root
        // split function to address "stack too deep" compiler error
        return
            _evaluateInvalidTransition(
                _invalidTransitionProof,
                _accountProofs,
                _strategyProof,
                _stakingPoolProof,
                _globalInfo,
                dsi.postStateRoot,
                _registry
            );
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * @notice Evaluate a disputed transition
     * @dev This was split from the disputeTransition function to address "stack too deep" compiler error
     *
     * @param _invalidTransitionProof The inclusion proof of the fraudulent transition.
     * @param _accountProofs The inclusion proofs of one or two accounts involved.
     * @param _strategyProof The inclusion proof of the strategy involved.
     * @param _stakingPoolProof The inclusion proof of the staking pool involved.
     * @param _globalInfo The global info.
     * @param _postStateRoot State root of the disputed transition.
     * @param _registry The address of the Registry contract.
     */
    function _evaluateInvalidTransition(
        dt.TransitionProof calldata _invalidTransitionProof,
        dt.AccountProof[] calldata _accountProofs,
        dt.StrategyProof calldata _strategyProof,
        dt.StakingPoolProof calldata _stakingPoolProof,
        dt.GlobalInfo calldata _globalInfo,
        bytes32 _postStateRoot,
        Registry _registry
    ) private returns (string memory) {
        // Apply the transaction and verify the state root after that.
        bool ok;
        bytes memory returnData;

        dt.AccountInfo[] memory accountInfos = new dt.AccountInfo[](_accountProofs.length);
        for (uint256 i = 0; i < _accountProofs.length; i++) {
            accountInfos[i] = _accountProofs[i].value;
        }

        dt.EvaluateInfos memory infos = dt.EvaluateInfos({
            accountInfos: accountInfos,
            strategyInfo: _strategyProof.value,
            stakingPoolInfo: _stakingPoolProof.value,
            globalInfo: _globalInfo
        });
        // Make the external call
        (ok, returnData) = address(transitionEvaluator).call(
            abi.encodeWithSelector(
                transitionEvaluator.evaluateTransition.selector,
                _invalidTransitionProof.transition,
                infos,
                _registry
            )
        );

        // Check if it was successful. If not, we've got to revert.
        if (!ok) {
            return ErrMsg.RSN_EVAL_FAILURE;
        }
        // It was successful so let's decode the outputs to get the new leaf nodes we'll have to insert
        bytes32[5] memory outputs = abi.decode((returnData), (bytes32[5]));

        // Check if the combined new stateRoots of the Merkle trees is incorrect.
        ok = _updateAndVerify(_postStateRoot, outputs, _accountProofs, _strategyProof, _stakingPoolProof);
        if (!ok) {
            // revert the block because we found an invalid post state root
            return ErrMsg.RSN_BAD_POST_SROOT;
        }

        revert("No fraud detected");
    }

    /**
     * @notice Get state roots, account id, and strategy id of the disputed transition.
     *
     * @param _preStateTransition transition immediately before the disputed transition
     * @param _invalidTransition the disputed transition
     */
    function _getStateRootsAndIds(bytes memory _preStateTransition, bytes memory _invalidTransition)
        private
        returns (bool, disputeStateInfo memory)
    {
        bool success;
        bytes memory returnData;
        bytes32 preStateRoot;
        bytes32 postStateRoot;
        uint32 accountId;
        uint32 accountIdDest;
        uint32 strategyId;
        uint32 stakingPoolId;
        disputeStateInfo memory dsi;

        // First decode the prestate root
        (success, returnData) = address(transitionEvaluator).call(
            abi.encodeWithSelector(transitionEvaluator.getTransitionStateRootAndAccessIds.selector, _preStateTransition)
        );

        // Make sure the call was successful
        require(success, ErrMsg.REQ_BAD_PREV_TN);
        (preStateRoot, , , , ) = abi.decode((returnData), (bytes32, uint32, uint32, uint32, uint32));

        // Now that we have the prestateRoot, let's decode the postState
        (success, returnData) = address(transitionEvaluator).call(
            abi.encodeWithSelector(TransitionEvaluator.getTransitionStateRootAndAccessIds.selector, _invalidTransition)
        );

        // If the call was successful let's decode!
        if (success) {
            (postStateRoot, accountId, accountIdDest, strategyId, stakingPoolId) = abi.decode(
                (returnData),
                (bytes32, uint32, uint32, uint32, uint32)
            );
            dsi.preStateRoot = preStateRoot;
            dsi.postStateRoot = postStateRoot;
            dsi.accountId = accountId;
            dsi.accountIdDest = accountIdDest;
            dsi.strategyId = strategyId;
            dsi.stakingPoolId = stakingPoolId;
        }
        return (success, dsi);
    }

    /**
     * @notice Evaluate if the init transition of the first block is invalid
     *
     * @param _initTransitionProof The inclusion proof of the disputed initial transition.
     * @param _firstBlock The first rollup block
     */
    function _invalidInitTransition(dt.TransitionProof calldata _initTransitionProof, dt.Block calldata _firstBlock)
        private
        returns (bool)
    {
        require(_checkTransitionInclusion(_initTransitionProof, _firstBlock), ErrMsg.REQ_TN_NOT_IN);
        (bool success, bytes memory returnData) = address(transitionEvaluator).call(
            abi.encodeWithSelector(
                TransitionEvaluator.getTransitionStateRootAndAccessIds.selector,
                _initTransitionProof.transition
            )
        );
        if (!success) {
            return true; // transition is invalid
        }
        (bytes32 postStateRoot, , ) = abi.decode((returnData), (bytes32, uint32, uint32));

        // Transition is invalid if stateRoot does not match the expected init root.
        // It's OK that other fields of the transition are incorrect.
        return postStateRoot != INIT_TRANSITION_STATE_ROOT;
    }

    /**
     * @notice Verifies that two transitions were included one after another.
     * @dev This is used to make sure we are comparing the correct prestate & poststate.
     */
    function _verifySequentialTransitions(
        dt.TransitionProof calldata _tp0,
        dt.TransitionProof calldata _tp1,
        dt.Block calldata _prevTransitionBlock,
        dt.Block calldata _invalidTransitionBlock
    ) private pure returns (bool) {
        // Start by checking if they are in the same block
        if (_tp0.blockId == _tp1.blockId) {
            // If the blocknumber is the same, check that tp0 precedes tp1
            require(_tp0.index + 1 == _tp1.index, ErrMsg.REQ_TN_NOT_SEQ);
            require(_tp1.index < _invalidTransitionBlock.blockSize, ErrMsg.REQ_TN_NOT_SEQ);
        } else {
            // If not in the same block, check that:
            // 0) the blocks are one after another
            require(_tp0.blockId + 1 == _tp1.blockId, ErrMsg.REQ_TN_NOT_SEQ);

            // 1) the index of tp0 is the last in its block
            require(_tp0.index == _prevTransitionBlock.blockSize - 1, ErrMsg.REQ_TN_NOT_SEQ);

            // 2) the index of tp1 is the first in its block
            require(_tp1.index == 0, ErrMsg.REQ_TN_NOT_SEQ);
        }

        // Verify inclusion
        require(_checkTransitionInclusion(_tp0, _prevTransitionBlock), ErrMsg.REQ_TN_NOT_IN);
        require(_checkTransitionInclusion(_tp1, _invalidTransitionBlock), ErrMsg.REQ_TN_NOT_IN);

        return true;
    }

    /**
     * @notice Check to see if a transition is included in the block.
     */
    function _checkTransitionInclusion(dt.TransitionProof memory _tp, dt.Block memory _block)
        private
        pure
        returns (bool)
    {
        bytes32 rootHash = _block.rootHash;
        bytes32 leafHash = keccak256(_tp.transition);
        return MerkleTree.verify(rootHash, leafHash, _tp.index, _tp.siblings);
    }

    /**
     * @notice Check if the combined stateRoots of the Merkle trees matches the stateRoot.
     * @dev hash(accountStateRoot, strategyStateRoot, stakingPoolStateRoot, globalInfoHash)
     */
    function _checkMultiTreeStateRoot(
        bytes32 _stateRoot,
        bytes32 _accountStateRoot,
        bytes32 _strategyStateRoot,
        bytes32 _stakingPoolStateRoot,
        bytes32 _globalInfoHash
    ) private pure returns (bool) {
        bytes32 newStateRoot = keccak256(
            abi.encodePacked(_accountStateRoot, _strategyStateRoot, _stakingPoolStateRoot, _globalInfoHash)
        );
        return (_stateRoot == newStateRoot);
    }

    /**
     * @notice Check if an account or strategy proof is included in the state root.
     */
    function _verifyProofInclusion(
        bytes32 _stateRoot,
        bytes32 _leafHash,
        uint32 _index,
        bytes32[] memory _siblings
    ) private pure {
        bool ok = MerkleTree.verify(_stateRoot, _leafHash, _index, _siblings);
        require(ok, ErrMsg.REQ_BAD_MERKLE);
    }

    /**
     * @notice Update the account, strategy, staking pool, and global info Merkle trees with their new leaf nodes and check validity.
     * @dev The _leafHashes array holds: [account (src), account (dest), strategy, stakingPool, globalInfo].
     */
    function _updateAndVerify(
        bytes32 _stateRoot,
        bytes32[5] memory _leafHashes,
        dt.AccountProof[] memory _accountProofs,
        dt.StrategyProof memory _strategyProof,
        dt.StakingPoolProof memory _stakingPoolProof
    ) private pure returns (bool) {
        if (
            _leafHashes[0] == bytes32(0) &&
            _leafHashes[1] == bytes32(0) &&
            _leafHashes[2] == bytes32(0) &&
            _leafHashes[3] == bytes32(0) &&
            _leafHashes[4] == bytes32(0)
        ) {
            return false;
        }
        // If there is an account update, compute its new Merkle tree root.
        // If there are two account updates (i.e. transfer), compute their combined new Merkle tree root.
        bytes32 accountStateRoot = _accountProofs[0].stateRoot;
        if (_leafHashes[0] != bytes32(0)) {
            if (_leafHashes[1] != bytes32(0)) {
                accountStateRoot = MerkleTree.computeRootTwoLeaves(
                    _leafHashes[0],
                    _leafHashes[1],
                    _accountProofs[0].index,
                    _accountProofs[1].index,
                    _accountProofs[0].siblings,
                    _accountProofs[1].siblings
                );
            } else {
                accountStateRoot = MerkleTree.computeRoot(
                    _leafHashes[0],
                    _accountProofs[0].index,
                    _accountProofs[0].siblings
                );
            }
        }

        // If there is a strategy update, compute its new Merkle tree root.
        bytes32 strategyStateRoot = _strategyProof.stateRoot;
        if (_leafHashes[2] != bytes32(0)) {
            strategyStateRoot = MerkleTree.computeRoot(_leafHashes[2], _strategyProof.index, _strategyProof.siblings);
        }

        // If there is a staking pool update, compute its new Merkle tree root.
        bytes32 stakingPoolStateRoot = _stakingPoolProof.stateRoot;
        if (_leafHashes[3] != bytes32(0)) {
            stakingPoolStateRoot = MerkleTree.computeRoot(
                _leafHashes[3],
                _stakingPoolProof.index,
                _stakingPoolProof.siblings
            );
        }

        return
            _checkMultiTreeStateRoot(
                _stateRoot,
                accountStateRoot,
                strategyStateRoot,
                stakingPoolStateRoot,
                _leafHashes[4] /* globalInfoHash */
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/* Internal Imports */
import {DataTypes as dt} from "./libraries/DataTypes.sol";
import {Transitions as tn} from "./libraries/Transitions.sol";
import "./libraries/ErrMsg.sol";
import "./TransitionApplier1.sol";
import "./TransitionApplier2.sol";
import "./Registry.sol";

contract TransitionEvaluator {
    TransitionApplier1 public immutable transitionApplier1;
    TransitionApplier2 public immutable transitionApplier2;

    // Transition evaluation is split across 3 contracts, this one is the main entry point.
    // In turn, it needs to access the other two contracts to evaluate the other transitions.
    constructor(TransitionApplier1 _transitionApplier1, TransitionApplier2 _transitionApplier2) {
        transitionApplier1 = _transitionApplier1;
        transitionApplier2 = _transitionApplier2;
    }

    /**********************
     * External Functions *
     **********************/

    /**
     * @notice Evaluate a transition.
     * @dev Note: most transitions involve one account; the transfer transitions involve two (src, dest).
     *
     * @param _transition The disputed transition.
     * @param _infos The involved infos at the start of the disputed transition.
     * @param _registry The address of the Registry contract.
     * @return hashes of the accounts (src and dest), strategy, staking pool and global info after applying the disputed transition.
     */
    function evaluateTransition(
        bytes calldata _transition,
        dt.EvaluateInfos calldata _infos,
        Registry _registry
    ) external view returns (bytes32[5] memory) {
        // Extract the transition type
        uint8 transitionType = tn.extractTransitionType(_transition);
        bytes32[5] memory outputs;
        outputs[4] = getGlobalInfoHash(_infos.globalInfo);
        dt.EvaluateInfos memory updatedInfos;
        updatedInfos.accountInfos = new dt.AccountInfo[](2);

        // Apply the transition and record the resulting storage slots
        if (transitionType == tn.TN_TYPE_DEPOSIT) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.DepositTransition memory deposit = tn.decodePackedDepositTransition(_transition);
            updatedInfos.accountInfos[0] = transitionApplier1.applyDepositTransition(deposit, _infos.accountInfos[0]);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
        } else if (transitionType == tn.TN_TYPE_WITHDRAW) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.WithdrawTransition memory withdraw = tn.decodePackedWithdrawTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.globalInfo) = transitionApplier1.applyWithdrawTransition(
                withdraw,
                _infos.accountInfos[0],
                _infos.globalInfo
            );
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_BUY) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.BuyTransition memory buy = tn.decodePackedBuyTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.strategyInfo) = transitionApplier1.applyBuyTransition(
                buy,
                _infos.accountInfos[0],
                _infos.strategyInfo,
                _registry
            );
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[2] = getStrategyInfoHash(updatedInfos.strategyInfo);
        } else if (transitionType == tn.TN_TYPE_SELL) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.SellTransition memory sell = tn.decodePackedSellTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.strategyInfo) = transitionApplier1.applySellTransition(
                sell,
                _infos.accountInfos[0],
                _infos.strategyInfo
            );
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[2] = getStrategyInfoHash(updatedInfos.strategyInfo);
        } else if (transitionType == tn.TN_TYPE_XFER_ASSET) {
            require(_infos.accountInfos.length == 2, ErrMsg.REQ_TWO_ACCT);
            dt.TransferAssetTransition memory xfer = tn.decodePackedTransferAssetTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.accountInfos[1], updatedInfos.globalInfo) = transitionApplier1
            .applyAssetTransferTransition(xfer, _infos.accountInfos[0], _infos.accountInfos[1], _infos.globalInfo);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[1] = getAccountInfoHash(updatedInfos.accountInfos[1]);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_XFER_SHARE) {
            require(_infos.accountInfos.length == 2, ErrMsg.REQ_TWO_ACCT);
            dt.TransferShareTransition memory xfer = tn.decodePackedTransferShareTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.accountInfos[1], updatedInfos.globalInfo) = transitionApplier1
            .applyShareTransferTransition(xfer, _infos.accountInfos[0], _infos.accountInfos[1], _infos.globalInfo);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[1] = getAccountInfoHash(updatedInfos.accountInfos[1]);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_AGGREGATE_ORDER) {
            dt.AggregateOrdersTransition memory aggr = tn.decodePackedAggregateOrdersTransition(_transition);
            updatedInfos.strategyInfo = transitionApplier2.applyAggregateOrdersTransition(aggr, _infos.strategyInfo);
            outputs[2] = getStrategyInfoHash(updatedInfos.strategyInfo);
        } else if (transitionType == tn.TN_TYPE_EXEC_RESULT) {
            dt.ExecutionResultTransition memory res = tn.decodePackedExecutionResultTransition(_transition);
            (updatedInfos.strategyInfo, updatedInfos.globalInfo) = transitionApplier2.applyExecutionResultTransition(
                res,
                _infos.strategyInfo,
                _infos.globalInfo
            );
            outputs[2] = getStrategyInfoHash(updatedInfos.strategyInfo);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_SETTLE) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.SettlementTransition memory settle = tn.decodePackedSettlementTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.strategyInfo, updatedInfos.globalInfo) = transitionApplier1
            .applySettlementTransition(settle, _infos.accountInfos[0], _infos.strategyInfo, _infos.globalInfo);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[2] = getStrategyInfoHash(updatedInfos.strategyInfo);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_STAKE) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.StakeTransition memory stake = tn.decodePackedStakeTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.stakingPoolInfo, updatedInfos.globalInfo) = transitionApplier2
            .applyStakeTransition(stake, _infos.accountInfos[0], _infos.stakingPoolInfo, _infos.globalInfo);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[3] = getStakingPoolInfoHash(updatedInfos.stakingPoolInfo);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_UNSTAKE) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.UnstakeTransition memory unstake = tn.decodePackedUnstakeTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.stakingPoolInfo, updatedInfos.globalInfo) = transitionApplier2
            .applyUnstakeTransition(unstake, _infos.accountInfos[0], _infos.stakingPoolInfo, _infos.globalInfo);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[3] = getStakingPoolInfoHash(updatedInfos.stakingPoolInfo);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_ADD_POOL) {
            dt.AddPoolTransition memory addPool = tn.decodeAddPoolTransition(_transition);
            updatedInfos.stakingPoolInfo = transitionApplier2.applyAddPoolTransition(
                addPool,
                _infos.stakingPoolInfo,
                _infos.globalInfo
            );
            outputs[3] = getStakingPoolInfoHash(updatedInfos.stakingPoolInfo);
        } else if (transitionType == tn.TN_TYPE_UPDATE_POOL) {
            dt.UpdatePoolTransition memory updatePool = tn.decodeUpdatePoolTransition(_transition);
            updatedInfos.stakingPoolInfo = transitionApplier2.applyUpdatePoolTransition(
                updatePool,
                _infos.stakingPoolInfo,
                _infos.globalInfo
            );
            outputs[3] = getStakingPoolInfoHash(updatedInfos.stakingPoolInfo);
        } else if (transitionType == tn.TN_TYPE_DEPOSIT_REWARD) {
            dt.DepositRewardTransition memory dr = tn.decodeDepositRewardTransition(_transition);
            updatedInfos.globalInfo = transitionApplier2.applyDepositRewardTransition(dr, _infos.globalInfo);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_WITHDRAW_PROTO_FEE) {
            dt.WithdrawProtocolFeeTransition memory wpf = tn.decodeWithdrawProtocolFeeTransition(_transition);
            updatedInfos.globalInfo = transitionApplier2.applyWithdrawProtocolFeeTransition(wpf, _infos.globalInfo);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_XFER_OP_FEE) {
            require(_infos.accountInfos.length == 1, ErrMsg.REQ_ONE_ACCT);
            dt.TransferOperatorFeeTransition memory tof = tn.decodeTransferOperatorFeeTransition(_transition);
            (updatedInfos.accountInfos[0], updatedInfos.globalInfo) = transitionApplier2
            .applyTransferOperatorFeeTransition(tof, _infos.accountInfos[0], _infos.globalInfo);
            outputs[0] = getAccountInfoHash(updatedInfos.accountInfos[0]);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else if (transitionType == tn.TN_TYPE_UPDATE_EPOCH) {
            dt.UpdateEpochTransition memory ue = tn.decodeUpdateEpochTransition(_transition);
            updatedInfos.globalInfo = transitionApplier2.applyUpdateEpochTransition(ue, _infos.globalInfo);
            outputs[4] = getGlobalInfoHash(updatedInfos.globalInfo);
        } else {
            revert("Transition type not recognized");
        }
        return outputs;
    }

    /**
     * @notice Return the (stateRoot, accountId, accountIdDest, strategyId, stakingPoolId) for this transition.
     * @dev Note: most transitions involve one account; the transfer transitions involve a 2nd account (dest).
     */
    function getTransitionStateRootAndAccessIds(bytes calldata _rawTransition)
        external
        pure
        returns (
            bytes32,
            uint32,
            uint32,
            uint32,
            uint32
        )
    {
        // Initialize memory rawTransition
        bytes memory rawTransition = _rawTransition;
        // Initialize stateRoot and account and strategy IDs.
        bytes32 stateRoot;
        uint32 accountId;
        uint32 accountIdDest;
        uint32 strategyId;
        uint32 stakingPoolId;
        uint8 transitionType = tn.extractTransitionType(rawTransition);
        if (transitionType == tn.TN_TYPE_DEPOSIT) {
            dt.DepositTransition memory transition = tn.decodePackedDepositTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
        } else if (transitionType == tn.TN_TYPE_WITHDRAW) {
            dt.WithdrawTransition memory transition = tn.decodePackedWithdrawTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
        } else if (transitionType == tn.TN_TYPE_BUY) {
            dt.BuyTransition memory transition = tn.decodePackedBuyTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
            strategyId = transition.strategyId;
        } else if (transitionType == tn.TN_TYPE_SELL) {
            dt.SellTransition memory transition = tn.decodePackedSellTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
            strategyId = transition.strategyId;
        } else if (transitionType == tn.TN_TYPE_XFER_ASSET) {
            dt.TransferAssetTransition memory transition = tn.decodePackedTransferAssetTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.fromAccountId;
            accountIdDest = transition.toAccountId;
        } else if (transitionType == tn.TN_TYPE_XFER_SHARE) {
            dt.TransferShareTransition memory transition = tn.decodePackedTransferShareTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.fromAccountId;
            accountIdDest = transition.toAccountId;
        } else if (transitionType == tn.TN_TYPE_AGGREGATE_ORDER) {
            dt.AggregateOrdersTransition memory transition = tn.decodePackedAggregateOrdersTransition(rawTransition);
            stateRoot = transition.stateRoot;
            strategyId = transition.strategyId;
        } else if (transitionType == tn.TN_TYPE_EXEC_RESULT) {
            dt.ExecutionResultTransition memory transition = tn.decodePackedExecutionResultTransition(rawTransition);
            stateRoot = transition.stateRoot;
            strategyId = transition.strategyId;
        } else if (transitionType == tn.TN_TYPE_SETTLE) {
            dt.SettlementTransition memory transition = tn.decodePackedSettlementTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
            strategyId = transition.strategyId;
        } else if (transitionType == tn.TN_TYPE_STAKE) {
            dt.StakeTransition memory transition = tn.decodePackedStakeTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
            stakingPoolId = transition.poolId;
        } else if (transitionType == tn.TN_TYPE_UNSTAKE) {
            dt.UnstakeTransition memory transition = tn.decodePackedUnstakeTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
            stakingPoolId = transition.poolId;
        } else if (transitionType == tn.TN_TYPE_ADD_POOL) {
            dt.AddPoolTransition memory transition = tn.decodeAddPoolTransition(rawTransition);
            stateRoot = transition.stateRoot;
            stakingPoolId = transition.poolId;
        } else if (transitionType == tn.TN_TYPE_UPDATE_POOL) {
            dt.UpdatePoolTransition memory transition = tn.decodeUpdatePoolTransition(rawTransition);
            stateRoot = transition.stateRoot;
            stakingPoolId = transition.poolId;
        } else if (transitionType == tn.TN_TYPE_DEPOSIT_REWARD) {
            dt.DepositRewardTransition memory transition = tn.decodeDepositRewardTransition(rawTransition);
            stateRoot = transition.stateRoot;
        } else if (transitionType == tn.TN_TYPE_WITHDRAW_PROTO_FEE) {
            dt.WithdrawProtocolFeeTransition memory transition = tn.decodeWithdrawProtocolFeeTransition(rawTransition);
            stateRoot = transition.stateRoot;
        } else if (transitionType == tn.TN_TYPE_XFER_OP_FEE) {
            dt.TransferOperatorFeeTransition memory transition = tn.decodeTransferOperatorFeeTransition(rawTransition);
            stateRoot = transition.stateRoot;
            accountId = transition.accountId;
        } else if (transitionType == tn.TN_TYPE_INIT) {
            dt.InitTransition memory transition = tn.decodeInitTransition(rawTransition);
            stateRoot = transition.stateRoot;
        } else if (transitionType == tn.TN_TYPE_UPDATE_EPOCH) {
            dt.UpdateEpochTransition memory transition = tn.decodeUpdateEpochTransition(rawTransition);
            stateRoot = transition.stateRoot;
        } else {
            revert("Transition type not recognized");
        }
        return (stateRoot, accountId, accountIdDest, strategyId, stakingPoolId);
    }

    /**
     * @notice Get the hash of the AccountInfo.
     * @param _accountInfo Account info
     */
    function getAccountInfoHash(dt.AccountInfo memory _accountInfo) public pure returns (bytes32) {
        // If it's an empty struct, map it to 32 bytes of zeros (empty value)
        if (
            _accountInfo.account == address(0) &&
            _accountInfo.accountId == 0 &&
            _accountInfo.idleAssets.length == 0 &&
            _accountInfo.shares.length == 0 &&
            _accountInfo.pending.length == 0 &&
            _accountInfo.stakedShares.length == 0 &&
            _accountInfo.stakes.length == 0 &&
            _accountInfo.rewardDebts.length == 0 &&
            _accountInfo.timestamp == 0
        ) {
            return keccak256(abi.encodePacked(uint256(0)));
        }

        return keccak256(abi.encode(_accountInfo));
    }

    /**
     * @notice Get the hash of the StrategyInfo.
     * @param _strategyInfo Strategy info
     */
    function getStrategyInfoHash(dt.StrategyInfo memory _strategyInfo) public pure returns (bytes32) {
        // If it's an empty struct, map it to 32 bytes of zeros (empty value)
        if (
            _strategyInfo.assetId == 0 &&
            _strategyInfo.assetBalance == 0 &&
            _strategyInfo.shareSupply == 0 &&
            _strategyInfo.nextAggregateId == 0 &&
            _strategyInfo.lastExecAggregateId == 0 &&
            _strategyInfo.pending.length == 0
        ) {
            return keccak256(abi.encodePacked(uint256(0)));
        }

        return keccak256(abi.encode(_strategyInfo));
    }

    /**
     * @notice Get the hash of the StakingPoolInfo.
     * @param _stakingPoolInfo Staking pool info
     */
    function getStakingPoolInfoHash(dt.StakingPoolInfo memory _stakingPoolInfo) public pure returns (bytes32) {
        // If it's an empty struct, map it to 32 bytes of zeros (empty value)
        if (
            _stakingPoolInfo.strategyId == 0 &&
            _stakingPoolInfo.rewardAssetIds.length == 0 &&
            _stakingPoolInfo.rewardPerEpoch.length == 0 &&
            _stakingPoolInfo.totalShares == 0 &&
            _stakingPoolInfo.totalStakes == 0 &&
            _stakingPoolInfo.accumulatedRewardPerUnit.length == 0 &&
            _stakingPoolInfo.lastRewardEpoch == 0 &&
            _stakingPoolInfo.stakeAdjustmentFactor == 0
        ) {
            return keccak256(abi.encodePacked(uint256(0)));
        }

        return keccak256(abi.encode(_stakingPoolInfo));
    }

    /**
     * @notice Get the hash of the GlobalInfo.
     * @param _globalInfo Global info
     */
    function getGlobalInfoHash(dt.GlobalInfo memory _globalInfo) public pure returns (bytes32) {
        return keccak256(abi.encode(_globalInfo));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library DataTypes {
    struct Block {
        bytes32 rootHash;
        bytes32 intentHash; // hash of L2-to-L1 aggregate-orders transitions
        uint32 intentExecCount; // count of intents executed so far (MAX_UINT32 == all done)
        uint32 blockSize; // number of transitions in the block
        uint64 blockTime; // blockNum when this rollup block is committed
    }

    struct InitTransition {
        uint8 transitionType;
        bytes32 stateRoot;
    }

    // decoded from calldata submitted as PackedDepositTransition
    struct DepositTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        address account;
        uint32 accountId;
        uint32 assetId;
        uint256 amount;
    }

    // decoded from calldata submitted as PackedWithdrawTransition
    struct WithdrawTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        address account; // target address for "pending withdraw" handling
        uint32 accountId;
        uint32 assetId;
        uint256 amount;
        uint128 fee;
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedBuySellTransition
    struct BuyTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId;
        uint32 strategyId;
        uint256 amount;
        uint128 maxSharePrice;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedBuySellTransition
    struct SellTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId;
        uint32 strategyId;
        uint256 shares;
        uint128 minSharePrice;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedTransferTransition
    struct TransferAssetTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 fromAccountId;
        uint32 toAccountId;
        address toAccount;
        uint32 assetId;
        uint256 amount;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedTransferTransition
    struct TransferShareTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 fromAccountId;
        uint32 toAccountId;
        address toAccount;
        uint32 strategyId;
        uint256 shares;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedSettlementTransition
    struct SettlementTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 strategyId;
        uint64 aggregateId;
        uint32 accountId;
        uint128 celrRefund; // fee refund in celr
        uint128 assetRefund; // fee refund in asset
    }

    // decoded from calldata submitted as PackedAggregateOrdersTransition
    struct AggregateOrdersTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 strategyId;
        uint256 buyAmount;
        uint256 sellShares;
        uint256 minSharesFromBuy;
        uint256 minAmountFromSell;
    }

    // decoded from calldata submitted as PackedExecutionResultTransition
    struct ExecutionResultTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 strategyId;
        uint64 aggregateId;
        bool success;
        uint256 sharesFromBuy;
        uint256 amountFromSell;
    }

    // decoded from calldata submitted as PackedStakingTransition
    struct StakeTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 poolId;
        uint32 accountId;
        uint256 shares;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    // decoded from calldata submitted as PackedStakingTransition
    struct UnstakeTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId;
        uint32 poolId;
        uint256 shares;
        uint128 fee; // user signed [1bit-type]:[127bit-amt]
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes32 r; // signature r
        bytes32 s; // signature s
        uint8 v; // signature v
    }

    struct AddPoolTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 poolId;
        uint32 strategyId;
        uint32[] rewardAssetIds;
        uint256[] rewardPerEpoch;
        uint256 stakeAdjustmentFactor;
        uint64 startEpoch;
    }

    struct UpdatePoolTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 poolId;
        uint256[] rewardPerEpoch;
    }

    struct DepositRewardTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 assetId;
        uint256 amount;
    }

    struct WithdrawProtocolFeeTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 assetId;
        uint256 amount;
    }

    struct TransferOperatorFeeTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId; // destination account Id
    }

    struct UpdateEpochTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint64 epoch;
    }

    struct OperatorFees {
        uint256[] assets; // assetId -> collected asset fees. CELR has assetId 1.
        uint256[] shares; // strategyId -> collected strategy share fees.
    }

    struct GlobalInfo {
        uint256[] protoFees; // assetId -> collected asset fees owned by contract owner (governance multi-sig account)
        OperatorFees opFees; // fee owned by operator
        uint64 currEpoch; // liquidity mining epoch
        uint256[] rewards; // assetId -> available reward amount
    }

    // Pending account actions (buy/sell) per account, strategy, aggregateId.
    // The array of PendingAccountInfo structs is sorted by ascending aggregateId, and holes are ok.
    struct PendingAccountInfo {
        uint64 aggregateId;
        uint256 buyAmount;
        uint256 sellShares;
        uint256 buyFees; // fees (in asset) for buy transitions
        uint256 sellFees; // fees (in asset) for sell transitions
        uint256 celrFees; // fees (in celr) for buy and sell transitions
    }

    struct AccountInfo {
        address account;
        uint32 accountId; // mapping only on L2 must be part of stateRoot
        uint256[] idleAssets; // indexed by assetId
        uint256[] shares; // indexed by strategyId
        PendingAccountInfo[][] pending; // indexed by [strategyId][i], i.e. array of pending records per strategy
        uint256[] stakedShares; // poolID -> share balance
        uint256[] stakes; // poolID -> Adjusted stake
        uint256[][] rewardDebts; // poolID -> rewardTokenID -> Reward debt
        uint64 timestamp; // Unix epoch (msec, UTC)
    }

    // Pending strategy actions per strategy, aggregateId.
    // The array of PendingStrategyInfo structs is sorted by ascending aggregateId, and holes are ok.
    struct PendingStrategyInfo {
        uint64 aggregateId;
        uint128 maxSharePriceForBuy; // decimal in 1e18
        uint128 minSharePriceForSell; // decimal in 1e18
        uint256 buyAmount;
        uint256 sellShares;
        uint256 sharesFromBuy;
        uint256 amountFromSell;
        uint256 unsettledBuyAmount;
        uint256 unsettledSellShares;
        bool executionSucceed;
    }

    struct StrategyInfo {
        uint32 assetId;
        uint256 assetBalance;
        uint256 shareSupply;
        uint64 nextAggregateId;
        uint64 lastExecAggregateId;
        PendingStrategyInfo[] pending; // array of pending records
    }

    struct StakingPoolInfo {
        uint32 strategyId;
        uint32[] rewardAssetIds; // reward asset index -> asset ID
        uint256[] rewardPerEpoch; // reward asset index -> reward per epoch, must be limited in length
        uint256 totalShares;
        uint256 totalStakes;
        uint256[] accumulatedRewardPerUnit; // reward asset index -> Accumulated reward per unit of stake, times 1e12 to avoid very small numbers
        uint64 lastRewardEpoch; // Last epoch that reward distribution occurs. Initially set by an AddPoolTransition
        uint256 stakeAdjustmentFactor; // A fraction to dilute whales. i.e. (0, 1) * 1e12
    }

    struct TransitionProof {
        bytes transition;
        uint256 blockId;
        uint32 index;
        bytes32[] siblings;
    }

    // Even when the disputed transition only affects an account without a strategy or only
    // affects a strategy without an account, both AccountProof and StrategyProof must be sent
    // to at least give the root hashes of the two separate Merkle trees (account and strategy).
    // Each transition stateRoot = hash(accountStateRoot, strategyStateRoot).
    struct AccountProof {
        bytes32 stateRoot; // for the account Merkle tree
        AccountInfo value;
        uint32 index;
        bytes32[] siblings;
    }

    struct StrategyProof {
        bytes32 stateRoot; // for the strategy Merkle tree
        StrategyInfo value;
        uint32 index;
        bytes32[] siblings;
    }

    struct StakingPoolProof {
        bytes32 stateRoot; // for the staking pool Merkle tree
        StakingPoolInfo value;
        uint32 index;
        bytes32[] siblings;
    }

    struct EvaluateInfos {
        AccountInfo[] accountInfos;
        StrategyInfo strategyInfo;
        StakingPoolInfo stakingPoolInfo;
        GlobalInfo globalInfo;
    }

    // ------------------ packed transitions submitted as calldata ------------------

    // calldata size: 4 x 32 bytes
    struct PackedDepositTransition {
        /* infoCode packing:
        96:127 [uint32 accountId]
        64:95  [uint32 assetId]
        8:63   [0]
        0:7    [uint8 tntype] */
        uint128 infoCode;
        bytes32 stateRoot;
        address account;
        uint256 amount;
    }

    // calldata size: 7 x 32 bytes
    struct PackedWithdrawTransition {
        /* infoCode packing:
        224:255 [uint32 accountId]
        192:223 [uint32 assetId]
        128:191 [uint64 timestamp]
        16:127  [0]
        8:15    [uint8 sig-v]
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
        address account;
        uint256 amtfee; // [128bit-amount]:[128bit-fee] uint128 is large enough
        bytes32 r;
        bytes32 s;
    }

    // calldata size: 6 x 32 bytes
    struct PackedBuySellTransition {
        /* infoCode packing:
        224:255 [uint32 accountId]
        192:223 [uint32 strategyId]
        128:191 [uint64 timestamp]
        16:127  [uint112 minSharePrice or maxSharePrice] // 112 bits are enough
        8:15    [uint8 sig-v]
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
        uint256 amtfee; // [128bit-share/amount]:[128bit-fee] uint128 is large enough
        bytes32 r;
        bytes32 s;
    }

    // calldata size: 6 x 32 bytes
    struct PackedTransferTransition {
        /* infoCode packing:
        224:255 [0]
        192:223 [uint32 assetId or strategyId]
        160:191 [uint32 fromAccountId]
        128:159 [uint32 toAccountId]
        64:127  [uint64 timestamp]
        16:63   [0]
        8:15    [uint8 sig-v]
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
        address toAccount;
        uint256 amtfee; // [128bit-share/amount]:[128bit-fee] uint128 is large enough
        bytes32 r;
        bytes32 s;
    }

    // calldata size: 2 x 32 bytes
    struct PackedSettlementTransition {
        /* infoCode packing:
        224:255 [uint32 accountId]
        192:223 [uint32 strategyId]
        160:191 [uint32 aggregateId] // uint32 is enough for per-strategy aggregateId
        104:159 [uint56 celrRefund] // celr refund in 9 decimal
        8:103   [uint96 assetRefund] // asseet refund
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
    }

    // calldata size: 6 x 32 bytes
    struct PackedAggregateOrdersTransition {
        /* infoCode packing:
        32:63  [uint32 strategyId]
        8:31   [0]
        0:7    [uint8 tntype] */
        uint64 infoCode;
        bytes32 stateRoot;
        uint256 buyAmount;
        uint256 sellShares;
        uint256 minSharesFromBuy;
        uint256 minAmountFromSell;
    }

    // calldata size: 4 x 32 bytes
    struct PackedExecutionResultTransition {
        /* infoCode packing:
        64:127  [uint64 aggregateId]
        32:63   [uint32 strategyId]
        9:31    [0]
        8:8     [bool success]
        0:7     [uint8 tntype] */
        uint128 infoCode;
        bytes32 stateRoot;
        uint256 sharesFromBuy;
        uint256 amountFromSell;
    }

    // calldata size: 6 x 32 bytes
    struct PackedStakingTransition {
        /* infoCode packing:
        192:255 [0]
        160:191 [uint32 poolId]
        128:159 [uint32 accountId]
        64:127  [uint64 timestamp]
        16:63   [0]
        8:15    [uint8 sig-v]
        0:7     [uint8 tntype] */
        uint256 infoCode;
        bytes32 stateRoot;
        uint256 sharefee; // [128bit-share]:[128bit-fee] uint128 is large enough
        bytes32 r;
        bytes32 s;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library ErrMsg {
    // err message for `require` checks
    string internal constant REQ_NOT_OPER = "caller not operator";
    string internal constant REQ_BAD_AMOUNT = "invalid amount";
    string internal constant REQ_NO_WITHDRAW = "withdraw failed";
    string internal constant REQ_BAD_BLOCKID = "invalid block ID";
    string internal constant REQ_BAD_CHALLENGE = "challenge period error";
    string internal constant REQ_BAD_HASH = "invalid data hash";
    string internal constant REQ_BAD_LEN = "invalid data length";
    string internal constant REQ_NO_DRAIN = "drain failed";
    string internal constant REQ_BAD_ASSET = "invalid asset";
    string internal constant REQ_BAD_ST = "invalid strategy";
    string internal constant REQ_BAD_SP = "invalid staking pool";
    string internal constant REQ_BAD_EPOCH = "invalid epoch";
    string internal constant REQ_OVER_LIMIT = "exceeds limit";
    string internal constant REQ_BAD_DEP_TN = "invalid deposit tn";
    string internal constant REQ_BAD_EXECRES_TN = "invalid execRes tn";
    string internal constant REQ_BAD_EPOCH_TN = "invalid epoch tn";
    string internal constant REQ_ONE_ACCT = "need 1 account";
    string internal constant REQ_TWO_ACCT = "need 2 accounts";
    string internal constant REQ_ACCT_NOT_EMPTY = "account not empty";
    string internal constant REQ_BAD_ACCT = "wrong account";
    string internal constant REQ_BAD_SIG = "invalid signature";
    string internal constant REQ_BAD_TS = "old timestamp";
    string internal constant REQ_NO_PEND = "no pending info";
    string internal constant REQ_BAD_SHARES = "wrong shares";
    string internal constant REQ_BAD_AGGR = "wrong aggregate ID";
    string internal constant REQ_ST_NOT_EMPTY = "strategy not empty";
    string internal constant REQ_NO_FRAUD = "no fraud found";
    string internal constant REQ_BAD_NTREE = "bad n-tree verify";
    string internal constant REQ_BAD_SROOT = "state roots not equal";
    string internal constant REQ_BAD_INDEX = "wrong proof index";
    string internal constant REQ_BAD_PREV_TN = "invalid prev tn";
    string internal constant REQ_TN_NOT_IN = "tn not in block";
    string internal constant REQ_TN_NOT_SEQ = "tns not sequential";
    string internal constant REQ_BAD_MERKLE = "failed Merkle proof check";
    // err message for dispute success reasons
    string internal constant RSN_BAD_INIT_TN = "invalid init tn";
    string internal constant RSN_BAD_ENCODING = "invalid encoding";
    string internal constant RSN_BAD_ACCT_ID = "invalid account id";
    string internal constant RSN_EVAL_FAILURE = "failed to evaluate";
    string internal constant RSN_BAD_POST_SROOT = "invalid post-state root";
}

// SPDX-License-Identifier: MIT
/*
(The MIT License)

Copyright 2020 Optimism

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity 0.8.6;

/**
 * @title MerkleTree
 * @author River Keefer
 */
library MerkleTree {
    /*
     * An intermediate Merkle tree node identified by its index (position) at its tree level
     * and its Merkle root.  It is used in an array of struct representing the path in the
     * Merkle tree from a leaf node (starting at depth 0) to the root of the tree.  The depth
     * and the index together uniquely identify an intermediate node in the Merkle tree.
     */
    struct ComputedNode {
        uint256 index;
        bytes32 root;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Calculates a merkle root for a list of 32-byte leaf hashes.  WARNING: If the number
     * of leaves passed in is not a power of two, it pads out the tree with zero hashes.
     * If you do not know the original length of elements for the tree you are verifying,
     * then this may allow empty leaves past _elements.length to pass a verification check down the line.
     * @param _elements Array of hashes from which to generate a merkle root.
     * @return Merkle root of the leaves, with zero hashes for non-powers-of-two (see above).
     */
    function getMerkleRoot(bytes32[] memory _elements) internal pure returns (bytes32) {
        require(_elements.length > 0, "Merkle: no leaves");

        if (_elements.length == 1) {
            return _elements[0];
        }

        uint256[32] memory defaults = [
            0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563,
            0x633dc4d7da7256660a892f8f1604a44b5432649cc8ec5cb3ced4c4e6ac94dd1d,
            0x890740a8eb06ce9be422cb8da5cdafc2b58c0a5e24036c578de2a433c828ff7d,
            0x3b8ec09e026fdc305365dfc94e189a81b38c7597b3d941c279f042e8206e0bd8,
            0xecd50eee38e386bd62be9bedb990706951b65fe053bd9d8a521af753d139e2da,
            0xdefff6d330bb5403f63b14f33b578274160de3a50df4efecf0e0db73bcdd3da5,
            0x617bdd11f7c0a11f49db22f629387a12da7596f9d1704d7465177c63d88ec7d7,
            0x292c23a9aa1d8bea7e2435e555a4a60e379a5a35f3f452bae60121073fb6eead,
            0xe1cea92ed99acdcb045a6726b2f87107e8a61620a232cf4d7d5b5766b3952e10,
            0x7ad66c0a68c72cb89e4fb4303841966e4062a76ab97451e3b9fb526a5ceb7f82,
            0xe026cc5a4aed3c22a58cbd3d2ac754c9352c5436f638042dca99034e83636516,
            0x3d04cffd8b46a874edf5cfae63077de85f849a660426697b06a829c70dd1409c,
            0xad676aa337a485e4728a0b240d92b3ef7b3c372d06d189322bfd5f61f1e7203e,
            0xa2fca4a49658f9fab7aa63289c91b7c7b6c832a6d0e69334ff5b0a3483d09dab,
            0x4ebfd9cd7bca2505f7bef59cc1c12ecc708fff26ae4af19abe852afe9e20c862,
            0x2def10d13dd169f550f578bda343d9717a138562e0093b380a1120789d53cf10,
            0x776a31db34a1a0a7caaf862cffdfff1789297ffadc380bd3d39281d340abd3ad,
            0xe2e7610b87a5fdf3a72ebe271287d923ab990eefac64b6e59d79f8b7e08c46e3,
            0x504364a5c6858bf98fff714ab5be9de19ed31a976860efbd0e772a2efe23e2e0,
            0x4f05f4acb83f5b65168d9fef89d56d4d77b8944015e6b1eed81b0238e2d0dba3,
            0x44a6d974c75b07423e1d6d33f481916fdd45830aea11b6347e700cd8b9f0767c,
            0xedf260291f734ddac396a956127dde4c34c0cfb8d8052f88ac139658ccf2d507,
            0x6075c657a105351e7f0fce53bc320113324a522e8fd52dc878c762551e01a46e,
            0x6ca6a3f763a9395f7da16014725ca7ee17e4815c0ff8119bf33f273dee11833b,
            0x1c25ef10ffeb3c7d08aa707d17286e0b0d3cbcb50f1bd3b6523b63ba3b52dd0f,
            0xfffc43bd08273ccf135fd3cacbeef055418e09eb728d727c4d5d5c556cdea7e3,
            0xc5ab8111456b1f28f3c7a0a604b4553ce905cb019c463ee159137af83c350b22,
            0x0ff273fcbf4ae0f2bd88d6cf319ff4004f8d7dca70d4ced4e74d2c74139739e6,
            0x7fa06ba11241ddd5efdc65d4e39c9f6991b74fd4b81b62230808216c876f827c,
            0x7e275adf313a996c7e2950cac67caba02a5ff925ebf9906b58949f3e77aec5b9,
            0x8f6162fa308d2b3a15dc33cffac85f13ab349173121645aedf00f471663108be,
            0x78ccaaab73373552f207a63599de54d7d8d0c1805f86ce7da15818d09f4cff62
        ];

        // Reserve memory space for our hashes.
        bytes memory buf = new bytes(64);

        // We'll need to keep track of left and right siblings.
        bytes32 leftSibling;
        bytes32 rightSibling;

        // Number of non-empty nodes at the current depth.
        uint256 rowSize = _elements.length;

        // Current depth, counting from 0 at the leaves
        uint256 depth = 0;

        // Common sub-expressions
        uint256 halfRowSize; // rowSize / 2
        bool rowSizeIsOdd; // rowSize % 2 == 1

        while (rowSize > 1) {
            halfRowSize = rowSize / 2;
            rowSizeIsOdd = rowSize % 2 == 1;

            for (uint256 i = 0; i < halfRowSize; i++) {
                leftSibling = _elements[(2 * i)];
                rightSibling = _elements[(2 * i) + 1];
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[i] = keccak256(buf);
            }

            if (rowSizeIsOdd) {
                leftSibling = _elements[rowSize - 1];
                rightSibling = bytes32(defaults[depth]);
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[halfRowSize] = keccak256(buf);
            }

            rowSize = halfRowSize + (rowSizeIsOdd ? 1 : 0);
            depth++;
        }

        return _elements[0];
    }

    /**
     * Verifies a merkle branch for the given leaf hash.  Assumes the original length
     * of leaves generated is a known, correct input, and does not return true for indices
     * extending past that index (even if _siblings would be otherwise valid.)
     * @param _root The Merkle root to verify against.
     * @param _leaf The leaf hash to verify inclusion of.
     * @param _index The index in the tree of this leaf.
     * @param _siblings Array of sibling nodes in the inclusion proof, starting from depth 0 (bottom of the tree).
     * @return Whether or not the merkle branch and leaf passes verification.
     */
    function verify(
        bytes32 _root,
        bytes32 _leaf,
        uint256 _index,
        bytes32[] memory _siblings
    ) internal pure returns (bool) {
        return (_root == computeRoot(_leaf, _index, _siblings));
    }

    /**
     * Compute the root of a merkle branch for the given leaf hash.  Assumes the original length
     * of leaves generated is a known, correct input, and does not return true for indices
     * extending past that index (even if _siblings would be otherwise valid.)
     * @param _leaf The leaf hash to verify inclusion of.
     * @param _index The index in the tree of this leaf.
     * @param _siblings Array of sibling nodes in the inclusion proof, starting from depth 0 (bottom of the tree).
     * @return The new merkle root.
     */
    function computeRoot(
        bytes32 _leaf,
        uint256 _index,
        bytes32[] memory _siblings
    ) internal pure returns (bytes32) {
        bytes32 computedRoot = _leaf;

        for (uint256 i = 0; i < _siblings.length; i++) {
            if ((_index & 1) == 1) {
                computedRoot = keccak256(abi.encodePacked(_siblings[i], computedRoot));
            } else {
                computedRoot = keccak256(abi.encodePacked(computedRoot, _siblings[i]));
            }
            _index >>= 1;
        }

        return computedRoot;
    }

    /**
     * Compute the root of a merkle tree for the combined update of two leaf hashes.  Assumes the
     * original length of leaves generated is a known, correct input, and does not return a valid
     * root  for indices extending past that index (even if _siblings would be otherwise valid.)
     * @param _leaf1 The 1st leaf hash
     * @param _leaf2 The 2nd leaf hash
     * @param _index1 The index in the tree of the 1st leaf
     * @param _index2 The index in the tree of the 2nd leaf
     * @param _siblings1 Array of sibling nodes for the 1st leaf, starting from depth 0 (bottom of the tree)
     * @param _siblings2 Array of sibling nodes for the 2nd leaf, starting from depth 0 (bottom of the tree)
     * @return The new merkle root.
     */
    function computeRootTwoLeaves(
        bytes32 _leaf1,
        bytes32 _leaf2,
        uint256 _index1,
        uint256 _index2,
        bytes32[] memory _siblings1,
        bytes32[] memory _siblings2
    ) internal pure returns (bytes32) {
        require(_index1 != _index2, "Merkle: same leaf nodes");
        require(
            _siblings1.length > 0 && _siblings2.length > 0 && _siblings1.length == _siblings2.length,
            "Merkle: bad sibling len"
        );

        // Compute the Merkle path for the 1st leaf remembering the intermediate nodes.
        uint256 n = _siblings1.length;
        ComputedNode[] memory nodes = new ComputedNode[](n);
        bytes32 computedRoot = _leaf1;
        uint256 index = _index1;
        for (uint256 i = 0; i < n; i++) {
            nodes[i].index = index;
            nodes[i].root = computedRoot;

            if ((index & 1) == 1) {
                computedRoot = keccak256(abi.encodePacked(_siblings1[i], computedRoot));
            } else {
                computedRoot = keccak256(abi.encodePacked(computedRoot, _siblings1[i]));
            }
            index >>= 1;
        }

        // Compute the Merkle path for the 2nd leaf using intermediate nodes that overlap (i.e. when
        // a sibling is a previously computed node), otherwise using the input (prior) sibling values.
        computedRoot = _leaf2;
        index = _index2;
        for (uint256 i = 0; i < n; i++) {
            bytes32 sibling_root;
            if (nodes[i].index == (index ^ 1)) {
                sibling_root = nodes[i].root;
            } else {
                sibling_root = _siblings2[i];
            }

            if ((index & 1) == 1) {
                computedRoot = keccak256(abi.encodePacked(sibling_root, computedRoot));
            } else {
                computedRoot = keccak256(abi.encodePacked(computedRoot, sibling_root));
            }
            index >>= 1;
        }

        return computedRoot;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "../libraries/DataTypes.sol";

library Transitions {
    // Transition Types
    uint8 public constant TN_TYPE_INVALID = 0;
    uint8 public constant TN_TYPE_INIT = 1;
    uint8 public constant TN_TYPE_DEPOSIT = 2;
    uint8 public constant TN_TYPE_WITHDRAW = 3;
    uint8 public constant TN_TYPE_BUY = 4;
    uint8 public constant TN_TYPE_SELL = 5;
    uint8 public constant TN_TYPE_XFER_ASSET = 6;
    uint8 public constant TN_TYPE_XFER_SHARE = 7;
    uint8 public constant TN_TYPE_AGGREGATE_ORDER = 8;
    uint8 public constant TN_TYPE_EXEC_RESULT = 9;
    uint8 public constant TN_TYPE_SETTLE = 10;
    uint8 public constant TN_TYPE_WITHDRAW_PROTO_FEE = 11;
    uint8 public constant TN_TYPE_XFER_OP_FEE = 12;

    // Staking / liquidity mining
    uint8 public constant TN_TYPE_STAKE = 13;
    uint8 public constant TN_TYPE_UNSTAKE = 14;
    uint8 public constant TN_TYPE_ADD_POOL = 15;
    uint8 public constant TN_TYPE_UPDATE_POOL = 16;
    uint8 public constant TN_TYPE_DEPOSIT_REWARD = 17;
    uint8 public constant TN_TYPE_UPDATE_EPOCH = 18;

    // fee encoding
    uint128 public constant UINT128_HIBIT = 2**127;

    function extractTransitionType(bytes memory _bytes) internal pure returns (uint8) {
        uint8 transitionType;
        assembly {
            transitionType := mload(add(_bytes, 0x20))
        }
        return transitionType;
    }

    function decodeInitTransition(bytes memory _rawBytes) internal pure returns (DataTypes.InitTransition memory) {
        (uint8 transitionType, bytes32 stateRoot) = abi.decode((_rawBytes), (uint8, bytes32));
        DataTypes.InitTransition memory transition = DataTypes.InitTransition(transitionType, stateRoot);
        return transition;
    }

    function decodePackedDepositTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.DepositTransition memory)
    {
        (uint128 infoCode, bytes32 stateRoot, address account, uint256 amount) = abi.decode(
            (_rawBytes),
            (uint128, bytes32, address, uint256)
        );
        (uint32 accountId, uint32 assetId, uint8 transitionType) = decodeDepositInfoCode(infoCode);
        DataTypes.DepositTransition memory transition = DataTypes.DepositTransition(
            transitionType,
            stateRoot,
            account,
            accountId,
            assetId,
            amount
        );
        return transition;
    }

    function decodeDepositInfoCode(uint128 _infoCode)
        internal
        pure
        returns (
            uint32, // accountId
            uint32, // assetId
            uint8 // transitionType
        )
    {
        (uint64 high, uint64 low) = splitUint128(_infoCode);
        (uint32 accountId, uint32 assetId) = splitUint64(high);
        uint8 transitionType = uint8(low);
        return (accountId, assetId, transitionType);
    }

    function decodePackedWithdrawTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.WithdrawTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, address account, uint256 amtfee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, address, uint256, bytes32, bytes32)
        );
        (uint32 accountId, uint32 assetId, uint64 timestamp, uint8 v, uint8 transitionType) = decodeWithdrawInfoCode(
            infoCode
        );
        (uint128 amount, uint128 fee) = splitUint256(amtfee);
        DataTypes.WithdrawTransition memory transition = DataTypes.WithdrawTransition(
            transitionType,
            stateRoot,
            account,
            accountId,
            assetId,
            amount,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodeWithdrawInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // accountId
            uint32, // assetId
            uint64, // timestamp
            uint8, // sig-v
            uint8 // transitionType
        )
    {
        (uint128 high, uint128 low) = splitUint256(_infoCode);
        (uint64 ids, uint64 timestamp) = splitUint128(high);
        (uint32 accountId, uint32 assetId) = splitUint64(ids);
        (uint8 v, uint8 transitionType) = splitUint16(uint16(low));
        return (accountId, assetId, timestamp, v, transitionType);
    }

    function decodePackedBuyTransition(bytes memory _rawBytes) internal pure returns (DataTypes.BuyTransition memory) {
        (uint256 infoCode, bytes32 stateRoot, uint256 amtfee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, uint256, bytes32, bytes32)
        );
        (
            uint32 accountId,
            uint32 strategyId,
            uint64 timestamp,
            uint128 maxSharePrice,
            uint8 v,
            uint8 transitionType
        ) = decodeBuySellInfoCode(infoCode);
        (uint128 amount, uint128 fee) = splitUint256(amtfee);
        DataTypes.BuyTransition memory transition = DataTypes.BuyTransition(
            transitionType,
            stateRoot,
            accountId,
            strategyId,
            amount,
            maxSharePrice,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodePackedSellTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.SellTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, uint256 sharefee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, uint256, bytes32, bytes32)
        );
        (
            uint32 accountId,
            uint32 strategyId,
            uint64 timestamp,
            uint128 minSharePrice,
            uint8 v,
            uint8 transitionType
        ) = decodeBuySellInfoCode(infoCode);
        (uint128 shares, uint128 fee) = splitUint256(sharefee);
        DataTypes.SellTransition memory transition = DataTypes.SellTransition(
            transitionType,
            stateRoot,
            accountId,
            strategyId,
            shares,
            minSharePrice,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodeBuySellInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // accountId
            uint32, // strategyId
            uint64, // timestamp
            uint128, // maxSharePrice or minSharePrice
            uint8, // sig-v
            uint8 // transitionType
        )
    {
        (uint128 h1, uint128 low) = splitUint256(_infoCode);
        (uint64 h2, uint64 timestamp) = splitUint128(h1);
        (uint32 accountId, uint32 strategyId) = splitUint64(h2);
        uint128 sharePrice = uint128(low >> 16);
        (uint8 v, uint8 transitionType) = splitUint16(uint16(low));
        return (accountId, strategyId, timestamp, sharePrice, v, transitionType);
    }

    function decodePackedTransferAssetTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.TransferAssetTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, address toAccount, uint256 amtfee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, address, uint256, bytes32, bytes32)
        );
        (
            uint32 assetId,
            uint32 fromAccountId,
            uint32 toAccountId,
            uint64 timestamp,
            uint8 v,
            uint8 transitionType
        ) = decodeTransferInfoCode(infoCode);
        (uint128 amount, uint128 fee) = splitUint256(amtfee);
        DataTypes.TransferAssetTransition memory transition = DataTypes.TransferAssetTransition(
            transitionType,
            stateRoot,
            fromAccountId,
            toAccountId,
            toAccount,
            assetId,
            amount,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodePackedTransferShareTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.TransferShareTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, address toAccount, uint256 sharefee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, address, uint256, bytes32, bytes32)
        );
        (
            uint32 strategyId,
            uint32 fromAccountId,
            uint32 toAccountId,
            uint64 timestamp,
            uint8 v,
            uint8 transitionType
        ) = decodeTransferInfoCode(infoCode);
        (uint128 shares, uint128 fee) = splitUint256(sharefee);
        DataTypes.TransferShareTransition memory transition = DataTypes.TransferShareTransition(
            transitionType,
            stateRoot,
            fromAccountId,
            toAccountId,
            toAccount,
            strategyId,
            shares,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodeTransferInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // assetId or strategyId
            uint32, // fromAccountId
            uint32, // toAccountId
            uint64, // timestamp
            uint8, // sig-v
            uint8 // transitionType
        )
    {
        (uint128 high, uint128 low) = splitUint256(_infoCode);
        (uint64 astId, uint64 acctIds) = splitUint128(high);
        (uint32 fromAccountId, uint32 toAccountId) = splitUint64(acctIds);
        (uint64 timestamp, uint64 vt) = splitUint128(low);
        (uint8 v, uint8 transitionType) = splitUint16(uint16(vt));
        return (uint32(astId), fromAccountId, toAccountId, timestamp, v, transitionType);
    }

    function decodePackedSettlementTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.SettlementTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot) = abi.decode((_rawBytes), (uint256, bytes32));
        (
            uint32 accountId,
            uint32 strategyId,
            uint64 aggregateId,
            uint128 celrRefund,
            uint128 assetRefund,
            uint8 transitionType
        ) = decodeSettlementInfoCode(infoCode);
        DataTypes.SettlementTransition memory transition = DataTypes.SettlementTransition(
            transitionType,
            stateRoot,
            strategyId,
            aggregateId,
            accountId,
            celrRefund,
            assetRefund
        );
        return transition;
    }

    function decodeSettlementInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // accountId
            uint32, // strategyId
            uint64, // aggregateId
            uint128, // celrRefund
            uint128, // assetRefund
            uint8 // transitionType
        )
    {
        uint128 ids = uint128(_infoCode >> 160);
        uint64 aggregateId = uint32(ids);
        ids = uint64(ids >> 32);
        uint32 strategyId = uint32(ids);
        uint32 accountId = uint32(ids >> 32);
        uint256 refund = uint152(_infoCode >> 8);
        uint128 assetRefund = uint96(refund);
        uint128 celrRefund = uint128(refund >> 96) * 1e9;
        uint8 transitionType = uint8(_infoCode);
        return (accountId, strategyId, aggregateId, celrRefund, assetRefund, transitionType);
    }

    function decodePackedAggregateOrdersTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.AggregateOrdersTransition memory)
    {
        (
            uint64 infoCode,
            bytes32 stateRoot,
            uint256 buyAmount,
            uint256 sellShares,
            uint256 minSharesFromBuy,
            uint256 minAmountFromSell
        ) = abi.decode((_rawBytes), (uint64, bytes32, uint256, uint256, uint256, uint256));
        (uint32 strategyId, uint8 transitionType) = decodeAggregateOrdersInfoCode(infoCode);
        DataTypes.AggregateOrdersTransition memory transition = DataTypes.AggregateOrdersTransition(
            transitionType,
            stateRoot,
            strategyId,
            buyAmount,
            sellShares,
            minSharesFromBuy,
            minAmountFromSell
        );
        return transition;
    }

    function decodeAggregateOrdersInfoCode(uint64 _infoCode)
        internal
        pure
        returns (
            uint32, // strategyId
            uint8 // transitionType
        )
    {
        (uint32 strategyId, uint32 low) = splitUint64(_infoCode);
        uint8 transitionType = uint8(low);
        return (strategyId, transitionType);
    }

    function decodePackedExecutionResultTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.ExecutionResultTransition memory)
    {
        (uint128 infoCode, bytes32 stateRoot, uint256 sharesFromBuy, uint256 amountFromSell) = abi.decode(
            (_rawBytes),
            (uint128, bytes32, uint256, uint256)
        );
        (uint64 aggregateId, uint32 strategyId, bool success, uint8 transitionType) = decodeExecutionResultInfoCode(
            infoCode
        );
        DataTypes.ExecutionResultTransition memory transition = DataTypes.ExecutionResultTransition(
            transitionType,
            stateRoot,
            strategyId,
            aggregateId,
            success,
            sharesFromBuy,
            amountFromSell
        );
        return transition;
    }

    function decodeExecutionResultInfoCode(uint128 _infoCode)
        internal
        pure
        returns (
            uint64, // aggregateId
            uint32, // strategyId
            bool, // success
            uint8 // transitionType
        )
    {
        (uint64 aggregateId, uint64 low) = splitUint128(_infoCode);
        (uint32 strategyId, uint32 low2) = splitUint64(low);
        uint8 transitionType = uint8(low2);
        bool success = uint8(low2 >> 8) == 1;
        return (aggregateId, strategyId, success, transitionType);
    }

    function decodePackedStakeTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.StakeTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, uint256 sharefee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, uint256, bytes32, bytes32)
        );
        (uint32 poolId, uint32 accountId, uint64 timestamp, uint8 v, uint8 transitionType) = decodeStakingInfoCode(
            infoCode
        );
        (uint128 shares, uint128 fee) = splitUint256(sharefee);
        DataTypes.StakeTransition memory transition = DataTypes.StakeTransition(
            transitionType,
            stateRoot,
            poolId,
            accountId,
            shares,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodePackedUnstakeTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.UnstakeTransition memory)
    {
        (uint256 infoCode, bytes32 stateRoot, uint256 sharefee, bytes32 r, bytes32 s) = abi.decode(
            (_rawBytes),
            (uint256, bytes32, uint256, bytes32, bytes32)
        );
        (uint32 poolId, uint32 accountId, uint64 timestamp, uint8 v, uint8 transitionType) = decodeStakingInfoCode(
            infoCode
        );
        (uint128 shares, uint128 fee) = splitUint256(sharefee);
        DataTypes.UnstakeTransition memory transition = DataTypes.UnstakeTransition(
            transitionType,
            stateRoot,
            poolId,
            accountId,
            shares,
            fee,
            timestamp,
            r,
            s,
            v
        );
        return transition;
    }

    function decodeStakingInfoCode(uint256 _infoCode)
        internal
        pure
        returns (
            uint32, // poolId
            uint32, // accountId
            uint64, // timestamp
            uint8, // sig-v
            uint8 // transitionType
        )
    {
        (uint128 high, uint128 low) = splitUint256(_infoCode);
        (, uint64 poolIdAccountId) = splitUint128(high);
        (uint32 poolId, uint32 accountId) = splitUint64(poolIdAccountId);
        (uint64 timestamp, uint64 vt) = splitUint128(low);
        (uint8 v, uint8 transitionType) = splitUint16(uint16(vt));
        return (poolId, accountId, timestamp, v, transitionType);
    }

    function decodeAddPoolTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.AddPoolTransition memory)
    {
        (
            uint8 transitionType,
            bytes32 stateRoot,
            uint32 poolId,
            uint32 strategyId,
            uint32[] memory rewardAssetIds,
            uint256[] memory rewardPerEpoch,
            uint256 stakeAdjustmentFactor,
            uint64 startEpoch
        ) = abi.decode((_rawBytes), (uint8, bytes32, uint32, uint32, uint32[], uint256[], uint256, uint64));
        DataTypes.AddPoolTransition memory transition = DataTypes.AddPoolTransition(
            transitionType,
            stateRoot,
            poolId,
            strategyId,
            rewardAssetIds,
            rewardPerEpoch,
            stakeAdjustmentFactor,
            startEpoch
        );
        return transition;
    }

    function decodeUpdatePoolTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.UpdatePoolTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint32 poolId, uint256[] memory rewardPerEpoch) = abi.decode(
            (_rawBytes),
            (uint8, bytes32, uint32, uint256[])
        );
        DataTypes.UpdatePoolTransition memory transition = DataTypes.UpdatePoolTransition(
            transitionType,
            stateRoot,
            poolId,
            rewardPerEpoch
        );
        return transition;
    }

    function decodeDepositRewardTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.DepositRewardTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint32 assetId, uint256 amount) = abi.decode(
            (_rawBytes),
            (uint8, bytes32, uint32, uint256)
        );
        DataTypes.DepositRewardTransition memory transition = DataTypes.DepositRewardTransition(
            transitionType,
            stateRoot,
            assetId,
            amount
        );
        return transition;
    }

    function decodeWithdrawProtocolFeeTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.WithdrawProtocolFeeTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint32 assetId, uint256 amount) = abi.decode(
            (_rawBytes),
            (uint8, bytes32, uint32, uint256)
        );
        DataTypes.WithdrawProtocolFeeTransition memory transition = DataTypes.WithdrawProtocolFeeTransition(
            transitionType,
            stateRoot,
            assetId,
            amount
        );
        return transition;
    }

    function decodeTransferOperatorFeeTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.TransferOperatorFeeTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint32 accountId) = abi.decode((_rawBytes), (uint8, bytes32, uint32));
        DataTypes.TransferOperatorFeeTransition memory transition = DataTypes.TransferOperatorFeeTransition(
            transitionType,
            stateRoot,
            accountId
        );
        return transition;
    }

    function decodeUpdateEpochTransition(bytes memory _rawBytes)
        internal
        pure
        returns (DataTypes.UpdateEpochTransition memory)
    {
        (uint8 transitionType, bytes32 stateRoot, uint64 epoch) = abi.decode((_rawBytes), (uint8, bytes32, uint64));
        DataTypes.UpdateEpochTransition memory transition = DataTypes.UpdateEpochTransition(
            transitionType,
            stateRoot,
            epoch
        );
        return transition;
    }

    /**
     * Helper to expand the account array of idle assets if needed.
     */
    function adjustAccountIdleAssetEntries(DataTypes.AccountInfo memory _accountInfo, uint32 assetId) internal pure {
        uint32 n = uint32(_accountInfo.idleAssets.length);
        if (n <= assetId) {
            uint256[] memory arr = new uint256[](assetId + 1);
            for (uint32 i = 0; i < n; i++) {
                arr[i] = _accountInfo.idleAssets[i];
            }
            for (uint32 i = n; i <= assetId; i++) {
                arr[i] = 0;
            }
            _accountInfo.idleAssets = arr;
        }
    }

    /**
     * Helper to expand the account array of shares if needed.
     */
    function adjustAccountShareEntries(DataTypes.AccountInfo memory _accountInfo, uint32 stId) internal pure {
        uint32 n = uint32(_accountInfo.shares.length);
        if (n <= stId) {
            uint256[] memory arr = new uint256[](stId + 1);
            for (uint32 i = 0; i < n; i++) {
                arr[i] = _accountInfo.shares[i];
            }
            for (uint32 i = n; i <= stId; i++) {
                arr[i] = 0;
            }
            _accountInfo.shares = arr;
        }
    }

    /**
     * Helper to expand protocol fee array (if needed) and add given fee.
     */
    function addProtoFee(
        DataTypes.GlobalInfo memory _globalInfo,
        uint32 _assetId,
        uint256 _fee
    ) internal pure {
        _globalInfo.protoFees = adjustUint256Array(_globalInfo.protoFees, _assetId);
        _globalInfo.protoFees[_assetId] += _fee;
    }

    /**
     * Helper to expand the chosen operator fee array (if needed) and add a given fee.
     * If "_assets" is true, use the assets fee array, otherwise use the shares fee array.
     */
    function updateOpFee(
        DataTypes.GlobalInfo memory _globalInfo,
        bool _assets,
        uint32 _idx,
        uint256 _fee
    ) internal pure {
        if (_assets) {
            _globalInfo.opFees.assets = adjustUint256Array(_globalInfo.opFees.assets, _idx);
            _globalInfo.opFees.assets[_idx] += _fee;
        } else {
            _globalInfo.opFees.shares = adjustUint256Array(_globalInfo.opFees.shares, _idx);
            _globalInfo.opFees.shares[_idx] += _fee;
        }
    }

    /**
     * Helper to expand an array of uint256, e.g. the various fee arrays in globalInfo.
     * Takes the array and the needed index and returns the unchanged array or a new expanded one.
     */
    function adjustUint256Array(uint256[] memory _array, uint32 _idx) internal pure returns (uint256[] memory) {
        uint32 n = uint32(_array.length);
        if (_idx < n) {
            return _array;
        }

        uint256[] memory newArray = new uint256[](_idx + 1);
        for (uint32 i = 0; i < n; i++) {
            newArray[i] = _array[i];
        }
        for (uint32 i = n; i <= _idx; i++) {
            newArray[i] = 0;
        }

        return newArray;
    }

    /**
     * Helper to get the fee type and amount.
     * Returns (isCelr, fee).
     */
    function getFeeInfo(uint128 _fee) internal pure returns (bool, uint256) {
        bool isCelr = _fee & UINT128_HIBIT == UINT128_HIBIT;
        if (isCelr) {
            _fee = _fee ^ UINT128_HIBIT;
        }
        return (isCelr, uint256(_fee));
    }

    function splitUint16(uint16 _code) internal pure returns (uint8, uint8) {
        uint8 high = uint8(_code >> 8);
        uint8 low = uint8(_code);
        return (high, low);
    }

    function splitUint64(uint64 _code) internal pure returns (uint32, uint32) {
        uint32 high = uint32(_code >> 32);
        uint32 low = uint32(_code);
        return (high, low);
    }

    function splitUint128(uint128 _code) internal pure returns (uint64, uint64) {
        uint64 high = uint64(_code >> 64);
        uint64 low = uint64(_code);
        return (high, low);
    }

    function splitUint256(uint256 _code) internal pure returns (uint128, uint128) {
        uint128 high = uint128(_code >> 128);
        uint128 low = uint128(_code);
        return (high, low);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface for DeFi strategies
 * @notice Strategy provides abstraction for a DeFi strategy.
 */
interface IStrategy {
    event Buy(uint256 amount, uint256 sharesFromBuy);

    event Sell(uint256 shares, uint256 amountFromSell);

    event ControllerChanged(address previousController, address newController);

    /**
     * @notice Returns the address of the asset token.
     */
    function getAssetAddress() external view returns (address);

    /**
     * @notice aggregate orders to strategy per instructions from L2.
     *
     * @param _buyAmount The aggregated asset amount to buy.
     * @param _sellShares The aggregated shares to sell.
     * @param _minSharesFromBuy Minimal shares from buy.
     * @param _minAmountFromSell Minimal asset amount from sell.
     * @return (sharesFromBuy, amountFromSell)
     */
    function aggregateOrders(
        uint256 _buyAmount,
        uint256 _sellShares,
        uint256 _minSharesFromBuy,
        uint256 _minAmountFromSell
    ) external returns (uint256, uint256);

    /**
     * @notice Syncs and returns the price of each share
     */
    function syncPrice() external returns (uint256);

    /**
     * @notice Compounding of extra yields
     */
    function harvest() external;
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "remappings": [],
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