// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ======================= DEUS Bridge ======================
// ==========================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Sadegh: https://github.com/sadeghte
// Reza: https://github.com/bakhshandeh
// Vahid: https://github.com/vahid-dev
// Mahdi: https://github.com/Mahdi-HF

import "./IMuonV02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IERC20 {
	function transfer(address recipient, uint256 amount) external;
	function transferFrom(address sender, address recipient, uint256 amount) external;
	function pool_burn_from(address b_address, uint256 b_amount) external;
	function pool_mint(address m_address, uint256 m_amount) external;
}

interface IDEIStablecoin {
	function global_collateral_ratio() external view returns (uint256);
}

contract DeusBridge is Ownable, Pausable {
	using ECDSA for bytes32;

	/* ========== STATE VARIABLES ========== */
	struct TX {
		uint256 txId;
		uint256 tokenId;
		uint256 amount;
		uint256 fromChain;
		uint256 toChain;
		address user;
		uint256 txBlockNo;
	}

	uint256 public lastTxId = 0;  // unique id for deposit tx
	uint256 public network;  // current chain id
	uint256 public minReqSigs;  // minimum required tss
	uint256 public scale = 1e6;
	uint256 public bridgeReserve;  // it handles buyback & recollaterlize on dei pools
	address public muonContract;  // muon signature verifier contract
	address public deiAddress;
	bool    public mintable;  // use mint functions instead of transfer
	uint8   public ETH_APP_ID = 2;  // muon's eth app id
	// we assign a unique ID to each chain (default is CHAIN-ID)
	mapping (uint256 => address) public sideContracts;
	// tokenId => tokenContractAddress
	mapping(uint256 => address)  public tokens;
	mapping(uint256 => TX)       public txs;
	// user => (destination chain => user's txs id)
	mapping(address => mapping(uint256 => uint256[])) public userTxs;
	// source chain => (tx id => false/true)
	mapping(uint256 => mapping(uint256 => bool))      public claimedTxs;
	// chainId => confirmationBlock on sourceChain
	mapping(uint256 => uint256) 					  public confirmationBlocks;
	// tokenId => tokenFee
	mapping(uint256 => uint256) 					  public fee;
	// tokenId => collectedFee
	mapping(uint256 => uint256) 					  public collectedFee;
	// tokenId => claimedFee
	mapping(uint256 => uint256) 					  public claimedFee;


	/* ========== CONSTRUCTOR ========== */

	constructor(address _muon, bool _mintable, uint256 _minReqSigs, uint256 _bridgeReserve, address _deiAddress) {
		network = getExecutingChainID();
		mintable = _mintable;
		muonContract = _muon;
		minReqSigs = _minReqSigs;
		bridgeReserve = _bridgeReserve;
		deiAddress = _deiAddress;
	}


	/* ========== PUBLIC FUNCTIONS ========== */

	function deposit(
		uint256 amount, 
		uint256 toChain,
		uint256 tokenId
	) external returns (uint256 txId) {
		txId = _deposit(msg.sender, amount, toChain, tokenId);
		emit Deposit(msg.sender, tokenId, amount, toChain, txId);
	}

	function depositFor(
		address user,
		uint256 amount, 
		uint256 toChain,
		uint256 tokenId
	) external returns (uint256 txId) {
		txId = _deposit(user, amount, toChain, tokenId);
		emit Deposit(user, tokenId, amount, toChain, txId);
	}

	function deposit(
		uint256 amount, 
		uint256 toChain,
		uint256 tokenId,
		uint256 referralCode
	) external returns (uint256 txId) {
		txId = _deposit(msg.sender, amount, toChain, tokenId);
		emit DepositWithReferralCode(msg.sender, tokenId, amount, toChain, txId, referralCode);
	}

	function depositFor(
		address user,
		uint256 amount, 
		uint256 toChain,
		uint256 tokenId,
		uint256 referralCode
	) external returns (uint256 txId) {
		txId = _deposit(user, amount, toChain, tokenId);
		emit DepositWithReferralCode(user, tokenId, amount, toChain, txId, referralCode);
	}

	function _deposit(
		address user,
		uint256 amount,
		uint256 toChain,
		uint256 tokenId
	) internal whenNotPaused() returns (uint256 txId) {
		require(sideContracts[toChain] != address(0), "Bridge: unknown toChain");
		require(toChain != network, "Bridge: selfDeposit");
		require(tokens[tokenId] != address(0), "Bridge: unknown tokenId");

		IERC20 token = IERC20(tokens[tokenId]);
		if (mintable) {
			token.pool_burn_from(msg.sender, amount);
			if (tokens[tokenId] == deiAddress) {
				bridgeReserve -= amount;
			}
		} else {
			token.transferFrom(msg.sender, address(this), amount);
		}

		if (fee[tokenId] > 0) {
			uint256 feeAmount = amount * fee[tokenId] / scale;
			amount -= feeAmount;
			collectedFee[tokenId] += feeAmount;
		}

		txId = ++lastTxId;
		txs[txId] = TX({
			txId: txId,
			tokenId: tokenId,
			fromChain: network,
			toChain: toChain,
			amount: amount,
			user: user,
			txBlockNo: block.number
		});
		userTxs[user][toChain].push(txId);
	}

	function claim(
		address user,
		uint256 amount,
		uint256 fromChain,
		uint256 toChain,
		uint256 tokenId,
		uint256 currentBlockNo,
		uint256 txBlockNo,
		uint256 txId,
		bytes calldata _reqId,
		SchnorrSign[] calldata sigs
	) public {
		require(sideContracts[fromChain] != address(0), 'Bridge: source contract not exist');
		require(toChain == network, "Bridge: toChain should equal network");
		require(sigs.length >= minReqSigs, "Bridge: insufficient number of signatures");
		require(currentBlockNo -  txBlockNo >= confirmationBlocks[fromChain], "Bridge: confirmationBlock is not finished yet");

		{
			bytes32 hash = keccak256(
			abi.encodePacked(
				abi.encodePacked(sideContracts[fromChain], txId, tokenId, amount),
				abi.encodePacked(fromChain, toChain, user, txBlockNo, currentBlockNo, ETH_APP_ID)
				)
			);

			IMuonV02 muon = IMuonV02(muonContract);
			require(muon.verify(_reqId, uint256(hash), sigs), "Bridge: not verified");
		}

		require(!claimedTxs[fromChain][txId], "Bridge: already claimed");
		require(tokens[tokenId] != address(0), "Bridge: unknown tokenId");

		IERC20 token = IERC20(tokens[tokenId]);
		if (mintable) {
			token.pool_mint(user, amount);
			if (tokens[tokenId] == deiAddress) {
				bridgeReserve += amount;
			}
		} else { 
			token.transfer(user, amount);
		}

		claimedTxs[fromChain][txId] = true;
		emit Claim(user, tokenId, amount, fromChain, txId);
	}


	/* ========== VIEWS ========== */

	// This function use pool feature to handle buyback and recollateralize on DEI minter pool
	function collatDollarBalance(uint256 collat_usd_price) public view returns (uint256) {
		uint collateralRatio = IDEIStablecoin(deiAddress).global_collateral_ratio();
		return bridgeReserve * collateralRatio / 1e6;
	}

	function pendingTxs(
		uint256 fromChain, 
		uint256[] calldata ids
	) public view returns (bool[] memory unclaimedIds) {
		unclaimedIds = new bool[](ids.length);
		for(uint256 i=0; i < ids.length; i++){
			unclaimedIds[i] = claimedTxs[fromChain][ids[i]];
		}
	}

	function getUserTxs(
		address user, 
		uint256 toChain
	) public view returns (uint256[] memory) {
		return userTxs[user][toChain];
	}

	function getTx(uint256 _txId) public view returns(
		uint256 txId,
		uint256 tokenId,
		uint256 amount,
		uint256 fromChain,
		uint256 toChain,
		address user,
		uint256 txBlockNo,
		uint256 currentBlockNo
	){
		txId = txs[_txId].txId;
		tokenId = txs[_txId].tokenId;
		amount = txs[_txId].amount;
		fromChain = txs[_txId].fromChain;
		toChain = txs[_txId].toChain;
		user = txs[_txId].user;
		txBlockNo = txs[_txId].txBlockNo;
		currentBlockNo = block.number;
	}

	function getExecutingChainID() public view returns (uint256) {
		uint256 id;
		assembly {
			id := chainid()
		}
		return id;
	}


	/* ========== RESTRICTED FUNCTIONS ========== */

	function setBridgeReserve(uint _bridgeReserve) external onlyOwner {
		emit BridgeReserveSet(bridgeReserve, _bridgeReserve);

		bridgeReserve = _bridgeReserve;
	}

	function setToken(uint256 tokenId, address tokenAddress) external onlyOwner {
		tokens[tokenId] = tokenAddress;
	}

	function setConfirmationBlock(uint256 chainId, uint256 confirmationBlock) external onlyOwner {
		confirmationBlocks[chainId] = confirmationBlock;
	}

	function setNetworkID(uint256 _network) external onlyOwner {
		network = _network;
		delete sideContracts[network];
	}

	function setFee(uint256 tokenId, uint256 _fee) external onlyOwner {
		fee[tokenId] = _fee;
	}
	
	function setDeiAddress(address _deiAddress) external onlyOwner {
		deiAddress = _deiAddress;
	}

	function setMinReqSigs(uint256 _minReqSigs) external onlyOwner {
		minReqSigs = _minReqSigs;
	}

	function setSideContract(uint256 _network, address _addr) external onlyOwner {
		require (network != _network, 'Bridge: current network');
		sideContracts[_network] = _addr;
	}

	function setMintable(bool _mintable) external onlyOwner {
		mintable = _mintable;
	}

	function setEthAppId(uint8 _ethAppId) external onlyOwner {
		ETH_APP_ID = _ethAppId;
	}

	function setMuonContract(address _muonContract) external onlyOwner {
		muonContract = _muonContract;
	}

	function pause() external onlyOwner {
		super._pause();
	}

	function unpase() external onlyOwner {
		super._unpause();
	}

	function withdrawFee(uint256 tokenId, address addr) external onlyOwner {
		require(collectedFee[tokenId] > 0, "Bridge: No fee to collect");
		IERC20(tokens[tokenId]).pool_mint(addr, collectedFee[tokenId]);
		claimedFee[tokenId] += collectedFee[tokenId];
		collectedFee[tokenId] = 0;
	}

	function emergencyWithdrawETH(uint256 amount, address addr) external onlyOwner {
		require(addr != address(0));
		payable(addr).transfer(amount);
	}

	function emergencyWithdrawERC20Tokens(address _tokenAddr, address _to, uint _amount) external onlyOwner {
		IERC20(_tokenAddr).transfer(_to, _amount);
	}

	/* ========== EVENTS ========== */
	event Deposit(
		address indexed user,
		uint256 tokenId,
		uint256 amount,
		uint256 indexed toChain,
		uint256 txId
	);

	event DepositWithReferralCode(
		address indexed user,
		uint256 tokenId,
		uint256 amount,
		uint256 indexed toChain,
		uint256 txId,
		uint256 referralCode
	);

	event Claim(
		address indexed user,
		uint256 tokenId, 
		uint256 amount, 
		uint256 indexed fromChain, 
		uint256 txId
	);

	event BridgeReserveSet(uint256 bridgeReserve, uint256 _bridgeReserve);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

interface IMuonV02{
    function verify(bytes calldata reqId, uint256 hash, SchnorrSign[] calldata _sigs) external returns (bool);
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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