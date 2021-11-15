// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DIADataNFT.sol";

library NFTUtil {
	function randomByte(uint256 seed) private view returns (uint8) {
		return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender, seed)))%256);
	}

	function randInt(uint256 max, uint256 seed) external view returns (uint256) {
		return randomByte(seed) % max;
	}
}

contract DIAGenesisMinter is Ownable {
	using NFTUtil for *;

	address[] public genesisNFTs;
	address[] public postGenesisNFTs;

	//true = means in genesis
	//false = post genesis
	mapping (address => bool) allNFTs;

	uint256 private seed;

	constructor(uint256 _seed) {
		seed = _seed;
	}

	event MintedDataNFT(address DIADataNFT, address owner, uint256 numMinted, uint256 newRank, bool isGenesis);
	event NewNFT(address NFTAddr);
	event UpdatedNFT(address NFTAddr, bool isGenesis);

	function updateSeed(uint256 newSeed) external onlyOwner {
		seed = newSeed;
	}

	function addNFT(address _addr) public onlyOwner{
		allNFTs[_addr] = true;
		genesisNFTs.push(_addr);
		emit NewNFT(_addr);
	}

	function updateNFT(address _addr, bool _isGenesis) public onlyOwner{
		allNFTs[_addr] = _isGenesis;
		if (_isGenesis){
			//updating to Genesis, remove from post-genesis if its there
			for(uint256 i = 0; i < postGenesisNFTs.length; i++) {
				if(postGenesisNFTs[i] == _addr) {
					postGenesisNFTs[i] = postGenesisNFTs[postGenesisNFTs.length - 1];
					postGenesisNFTs.pop();
				}
			}
		}else{
			//if its not genesis, remove it from the genesisNFT
			for(uint256 i = 0; i < genesisNFTs.length; i++) {
				if(genesisNFTs[i] == _addr) {
					genesisNFTs[i] = genesisNFTs[genesisNFTs.length - 1];
					genesisNFTs.pop();
				}
			}
		}
		emit UpdatedNFT(_addr, _isGenesis);
	}

	function postGenesisMint(uint256 NFTIndex) external{
		DIADataNFT diaDataNFTImpl = DIADataNFT(postGenesisNFTs[NFTIndex]);
		require(!diaDataNFTImpl.genesisPhase());
		require(diaDataNFTImpl.started());
		// Randomize for the case that not all Non-Common NFTs are minted yet
		uint256 newRank = NFTUtil.randInt(diaDataNFTImpl.NUM_PRIVILEGED_RANKS(), seed);		
		uint256 mintedRank = diaDataNFTImpl._mintDataNFT(msg.sender, newRank);

		// Transfer payment token to burn address
		require(ERC20(diaDataNFTImpl.paymentToken()).transferFrom(msg.sender, diaDataNFTImpl.burnAddress(), diaDataNFTImpl.burnAmount()), "Payment token transfer to burn address failed.");
		// Transfer payment token to minting pool
		require(ERC20(diaDataNFTImpl.paymentToken()).transferFrom(msg.sender, address(diaDataNFTImpl), diaDataNFTImpl.mintingPoolAmount()), "Payment token transfer to minting pool failed.");
		// Transfer payment token to source NFT pool
		require(ERC20(diaDataNFTImpl.paymentToken()).transferFrom(msg.sender, address(diaDataNFTImpl.diaSourceNFTImpl()), diaDataNFTImpl.diaSourceNFTImpl().getSourcePoolAmount(diaDataNFTImpl.sourceNFTId())), "Payment token transfer to source pool failed.");

		emit MintedDataNFT(postGenesisNFTs[NFTIndex], msg.sender, diaDataNFTImpl.numMintedNFTs(), mintedRank, false);
	}

	function genesisMint() external {

		uint256 genesisNFTIndex = NFTUtil.randInt(genesisNFTs.length, seed);

		DIADataNFT diaDataNFTImpl = DIADataNFT(genesisNFTs[genesisNFTIndex]);
		
		uint256 newRank = NFTUtil.randInt(diaDataNFTImpl.NUM_PRIVILEGED_RANKS(), seed);
		uint256 triedNFTIds = 0;

		while(!diaDataNFTImpl.started() ||
					!diaDataNFTImpl.genesisPhase() ||
					!diaDataNFTImpl.exists() ||
				  diaDataNFTImpl.numMintedNFTs() >= diaDataNFTImpl.NUM_PRIVILEGED_RANKS()) {
			require(triedNFTIds < genesisNFTs.length, "Couldn't find NFT to mint.");
			genesisNFTIndex = (genesisNFTIndex + 1) % (genesisNFTs.length);
			diaDataNFTImpl = DIADataNFT(genesisNFTs[genesisNFTIndex]);
			triedNFTIds += 1;
		}
		uint256 mintedRank = diaDataNFTImpl._mintDataNFT(msg.sender, newRank);
		// Transfer payment token to burn address
		require(ERC20(diaDataNFTImpl.paymentToken()).transferFrom(msg.sender, diaDataNFTImpl.burnAddress(), diaDataNFTImpl.burnAmount()), "Payment token transfer to burn address failed.");
		// Transfer payment token to minting pool
		require(ERC20(diaDataNFTImpl.paymentToken()).transferFrom(msg.sender, address(diaDataNFTImpl), diaDataNFTImpl.mintingPoolAmount()), "Payment token transfer to minting pool failed.");
		// Transfer payment token to source NFT pool
		require(ERC20(diaDataNFTImpl.paymentToken()).transferFrom(msg.sender, address(diaDataNFTImpl.diaSourceNFTImpl()), diaDataNFTImpl.diaSourceNFTImpl().getSourcePoolAmount(diaDataNFTImpl.sourceNFTId())), "Payment token transfer to source pool failed.");
		
		emit MintedDataNFT(genesisNFTs[genesisNFTIndex], msg.sender, diaDataNFTImpl.numMintedNFTs(), mintedRank, true);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./DIASourceNFT.sol";
import "./Strings.sol";

contract DIADataNFT is Ownable, ERC1155 {

	using Math for uint256;
	using Strings for string;

	address public DIASourceNFTAddr;
	DIASourceNFT public diaSourceNFTImpl = DIASourceNFT(DIASourceNFTAddr);

	address public DIAGenesisMinterAddr;

	uint256 public constant NUM_PRIVILEGED_RANKS = 10;

	uint256 public numMintedNFTs;
	mapping (uint256 => address) rankMinter;
	mapping (uint256 => uint256) rankClaims;
	mapping (uint256 => uint) lastClaimPayout;
	bool public exists;
	bool public started;
	bool public genesisPhase;
	uint256 public sourceNFTId;
	mapping (address => uint256) public mintsPerWallet;
	uint256 public maxMintsPerWallet = 3;

	address public paymentToken;
	address public constant burnAddress = address(0x000000000000000000000000000000000000dEaD);
	uint256 public burnAmount;
	uint256 public mintingPoolAmount;

	constructor(address _paymentToken, uint256 _burnAmount, uint256 _mintingPoolAmount, address _DIAGenesisMinterAddr, bytes memory metadataURI) ERC1155(string(metadataURI)) {
		require(_paymentToken != address(0), "Payment token address is 0.");
		paymentToken = _paymentToken;
		burnAmount = _burnAmount;
		mintingPoolAmount = _mintingPoolAmount;
		DIAGenesisMinterAddr = _DIAGenesisMinterAddr;
	}

	event NewDataNFTCategory(uint256 sourceNFTId);
	event MintedDataNFT(address owner, uint256 numMinted, uint256 newRank);
	event ClaimedMintingPoolReward(uint256 rank, address claimer);

	function uri(uint256 _id) public view override returns (string memory) {
		if (_id > NUM_PRIVILEGED_RANKS) {
			_id = NUM_PRIVILEGED_RANKS;
		}
		return string(abi.encodePacked(
			super.uri(_id),
			Strings.uint2str(_id),
			".json"
		));
	}

	function finishGenesisPhase() external onlyOwner {
		genesisPhase = false;
	}

	function startMinting() external onlyOwner {
		started = true;
	}

	function updateMaxMintsPerWallet(uint256 newValue) external onlyOwner {
		maxMintsPerWallet = newValue;
	}

	function updateDIAGenesisMinterAddr(address newAddress) external onlyOwner {
		DIAGenesisMinterAddr = newAddress;
	}

	function setSrcNFT(address _newAddress) external onlyOwner {
		DIASourceNFTAddr = _newAddress;
		diaSourceNFTImpl = DIASourceNFT(DIASourceNFTAddr);
	}

	function generateDataNFTCategory(uint256 _sourceNFTId) external {
		require(diaSourceNFTImpl.balanceOf(msg.sender, _sourceNFTId) > 0);
		exists = true;
		genesisPhase = true;
		started = false;
		sourceNFTId = _sourceNFTId;
		emit NewDataNFTCategory(_sourceNFTId);
	}

	function getRankClaim(uint256 newRank, uint256 max) public view returns (uint256) {
		// 1. Get tetrahedron sum of token units to distribute
		uint256 totalClaimsForMint = getTetrahedronSum(max);
		// 2. Get raw claim from the rank of an NFT
		uint256 rawRankClaim = (getInverseTetrahedronNumber(newRank, max) * mintingPoolAmount) / totalClaimsForMint;
		// 3. Special cases: privileged ranks
		if (newRank == 1 || newRank == 2) {
			return ((getInverseTetrahedronNumber(1, max) * mintingPoolAmount) / totalClaimsForMint + (getInverseTetrahedronNumber(2, max) * mintingPoolAmount) / totalClaimsForMint) / 2;
		} else if (newRank == 3 || newRank == 4 || newRank == 5) {
			return ((getInverseTetrahedronNumber(3, max) * mintingPoolAmount) / totalClaimsForMint + (getInverseTetrahedronNumber(4, max) * mintingPoolAmount) / totalClaimsForMint + (getInverseTetrahedronNumber(5, max) * mintingPoolAmount) / totalClaimsForMint) / 3;
		} else if (newRank == 6 || newRank == 7 || newRank == 8 || newRank == 9) {
			return ((getInverseTetrahedronNumber(6, max) * mintingPoolAmount) / totalClaimsForMint + (getInverseTetrahedronNumber(7, max) * mintingPoolAmount) / totalClaimsForMint + (getInverseTetrahedronNumber(8, max) * mintingPoolAmount) / totalClaimsForMint + (getInverseTetrahedronNumber(9, max) * mintingPoolAmount) / totalClaimsForMint) / 4;
		}
		return rawRankClaim;
	}

	function _mintDataNFT(address _origin, uint256 _newRank) public returns (uint256) {
		require(msg.sender == DIAGenesisMinterAddr, "Only callable from the genesis minter contract");
		// Check that category exists
		require(exists, "_mintDataNFT.Category must exist");
		// Get current number minted of the NFT
		uint256 numMinted = numMintedNFTs;

		if (numMinted < NUM_PRIVILEGED_RANKS) {
			while (rankMinter[_newRank] != address(0)) {
				_newRank = (_newRank + 1) % NUM_PRIVILEGED_RANKS;
			}
		} else {
			_newRank = numMinted;
		}

		for (uint256 i = 0; i < Math.max(NUM_PRIVILEGED_RANKS, numMinted); i++) {
			rankClaims[i] += getRankClaim(i, Math.max(NUM_PRIVILEGED_RANKS, numMinted));
		}

		// Check that the wallet is still allowed to mint
		require(mintsPerWallet[_origin] < maxMintsPerWallet, "Sender has used all its mints");

		// Mint data NFT
		_mint(_origin, _newRank, 1, "");

		// Update data struct
		rankMinter[_newRank] = _origin;
		numMintedNFTs = numMinted + 1;

		// Update Source NFT data
		uint256 currSourceNFTId = sourceNFTId;

		diaSourceNFTImpl.notifyDataNFTMint(currSourceNFTId);

		mintsPerWallet[_origin] += 1;
		emit MintedDataNFT(_origin, numMinted, _newRank);
		return _newRank;
	}

	function getRankMinter(uint256 rank) external view returns (address) {
	    return rankMinter[rank];
	}

	function getLastClaimPayout(uint256 rank) external view returns (uint) {
	    return lastClaimPayout[rank];
	}

	function claimMintingPoolReward(uint256 rank) public {
		require(!genesisPhase);
		address claimer = msg.sender;
		require(balanceOf(claimer, rank) > 0);

		uint256 reward = rankClaims[rank];

		// transfer reward to claimer
		require(ERC20(paymentToken).transfer(claimer, reward));
		// Set claim to 0 for rank
		rankClaims[rank] = 0;
		emit ClaimedMintingPoolReward(rank, claimer);
	}

	function getRewardAmount(uint256 rank) public view returns (uint) {
		return rankClaims[rank];
	}

	// Returns the n-th tetrahedron number
	function getTetrahedronNumber(uint256 n) internal pure returns (uint256) {
		return (n * (n + 1) * (n + 2))/ 6;
	}

	// Returns the n-th tetrahedron number from above
	function getInverseTetrahedronNumber(uint256 n, uint256 max) internal pure returns (uint256) {
		return getTetrahedronNumber(max - n);
	}

	function getTetrahedronSum(uint256 n) internal pure returns (uint256) {
		uint256 acc = 0;
		// Start at 1 so that the last minter doesn't get 0
		for (uint256 i = 1; i <= n; i++) {
			acc += getTetrahedronNumber(i);
		}
		return acc;
	}

	function getMintedNFTs() external view returns (uint) {
		return numMintedNFTs;
	}

	/*function getErcRank(uint256 internalRank) public pure returns (uint256) {
		// Translate rank to ERC1155 ID "rank" info
		uint256 ercRank = 0;
		if (internalRank == 0) { ercRank = 0; }
		else if (internalRank == 1 || internalRank == 2) { ercRank = 1; }
		else if (internalRank == 3 || internalRank == 4 || internalRank == 5) { ercRank = 2; }
		else if (internalRank == 6 || internalRank == 7 || internalRank == 8 || internalRank == 9) { ercRank = 3; }
		else { ercRank = 4; }
		return ercRank;
	}*/
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

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            _balances[id][from] = fromBalance - amount;
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        _balances[id][account] = accountBalance - amount;

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DIASourceNFT is Ownable, ERC1155 {

	address public paymentToken;
	mapping (address => bool) public dataNFTContractAddresses;

	struct SourceNFTMetadata {
		uint256 claimablePayout;
		bool exists;
		address admin;
		uint256[] parentIds;
		uint256[] parentPayoutShares;
		uint256 payoutShare;
		uint256 sourcePoolAmount;
	}

	mapping (uint256 => SourceNFTMetadata) public sourceNfts;

	constructor(address newOwner) ERC1155("https://api.diadata.org/v1/nft/source_{id}.json") {
		transferOwnership(newOwner);
	}

	function setMetadataUri(string memory metadataURI) onlyOwner external {
		_setURI(metadataURI);
	}

	function getSourcePoolAmount(uint256 sourceNftId) external view returns (uint256) {
		return sourceNfts[sourceNftId].sourcePoolAmount;
	}
	
	function setSourcePoolAmount(uint256 sourceNftId, uint256 newAmount) external {
	    require(sourceNfts[sourceNftId].admin == msg.sender, "Source Pool Amount can only be set by the sART admin");
	    sourceNfts[sourceNftId].sourcePoolAmount = newAmount;
	}

	function addDataNFTContractAddress(address newAddress) onlyOwner external {
		require(newAddress != address(0), "New address is 0.");
		dataNFTContractAddresses[newAddress] = true;
	}

	function removeDataNFTContractAddress(address oldAddress) onlyOwner external {
		require(oldAddress != address(0), "Removed address is 0.");
		dataNFTContractAddresses[oldAddress] = false;
	}

	function updateAdmin(uint256 sourceNftId, address newAdmin) external {
		require(sourceNfts[sourceNftId].admin == msg.sender);
		sourceNfts[sourceNftId].admin = newAdmin;
	}

	function addParent(uint256 sourceNftId, uint256 parentId, uint256 payoutShare) external {
		require(sourceNfts[sourceNftId].admin == msg.sender);
		require(sourceNfts[sourceNftId].payoutShare >= payoutShare);
		require(sourceNfts[parentId].exists, "Parent NFT does not exist!");

		sourceNfts[sourceNftId].payoutShare -= payoutShare;
		sourceNfts[sourceNftId].parentPayoutShares.push(payoutShare);
		sourceNfts[sourceNftId].parentIds.push(parentId);
	}

	function updateParentPayoutShare(uint256 sourceNftId, uint256 parentId, uint256 newPayoutShare) external {
		require(sourceNfts[sourceNftId].admin == msg.sender);
		
		uint256 arrayIndex = (2**256) - 1;
		// find parent ID in payout shares
		for (uint256 i = 0; i < sourceNfts[sourceNftId].parentPayoutShares.length; i++) {
			if (sourceNfts[sourceNftId].parentIds[i] == parentId) {
				arrayIndex = i;
				break;
			}
		}

		uint256 payoutDelta;
		// Check if we can distribute enough payout shares
		if (newPayoutShare >= sourceNfts[sourceNftId].parentPayoutShares[arrayIndex]) {
			payoutDelta = newPayoutShare - sourceNfts[sourceNftId].parentPayoutShares[arrayIndex];
			require(sourceNfts[sourceNftId].payoutShare >= payoutDelta, "Error: Not enough shares left to increase payout!");
			sourceNfts[sourceNftId].payoutShare -= payoutDelta;
			sourceNfts[sourceNftId].parentPayoutShares[arrayIndex] += payoutDelta;
		} else {
			payoutDelta = sourceNfts[sourceNftId].parentPayoutShares[arrayIndex] - newPayoutShare;
			require(sourceNfts[sourceNftId].parentPayoutShares[arrayIndex] >= payoutDelta, "Error: Not enough shares left to decrease payout!");
			sourceNfts[sourceNftId].payoutShare += payoutDelta;
			sourceNfts[sourceNftId].parentPayoutShares[arrayIndex] -= payoutDelta;
		}
	}

	function generateSourceToken(uint256 sourceNftId, address receiver) external onlyOwner {
		sourceNfts[sourceNftId].exists = true;
		sourceNfts[sourceNftId].admin = msg.sender;
		sourceNfts[sourceNftId].payoutShare = 10000;

		_mint(receiver, sourceNftId, 1, ""); 
	}

	function notifyDataNFTMint(uint256 sourceNftId) external {
		require(dataNFTContractAddresses[msg.sender], "notifyDataNFTMint: Only data NFT contracts can be used to mint data NFTs");
		require(sourceNfts[sourceNftId].exists, "notifyDataNFTMint: Source NFT does not exist!");
		for (uint256 i = 0; i < sourceNfts[sourceNftId].parentIds.length; i++) {
			uint256 currentParentId = sourceNfts[sourceNftId].parentIds[i];
			sourceNfts[currentParentId].claimablePayout += (sourceNfts[sourceNftId].parentPayoutShares[i] * sourceNfts[sourceNftId].sourcePoolAmount) / 10000;
		}
		sourceNfts[sourceNftId].claimablePayout += (sourceNfts[sourceNftId].payoutShare * sourceNfts[sourceNftId].sourcePoolAmount) / 10000;
	}

	function claimRewards(uint256 sourceNftId) external {
		address claimer = msg.sender;
		require(sourceNfts[sourceNftId].admin == claimer);
		uint256 payoutDataTokens = sourceNfts[sourceNftId].claimablePayout;

		require(ERC20(paymentToken).transfer(claimer, payoutDataTokens), "Token transfer failed.");
		sourceNfts[sourceNftId].claimablePayout = 0;
	}
}

// SPDX-License-Identifier: MIT


pragma solidity 0.8.0;

library Strings {
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
			if (_i == 0) {
				return "0";
			}
			uint j = _i;
			uint len;
			while (j != 0) {
				len++;
				j /= 10;
			}
			bytes memory bstr = new bytes(len);
			uint k = len;
			while (_i != 0) {
				k = k-1;
				uint8 temp = (48 + uint8(_i - _i / 10 * 10));
				bytes1 b1 = bytes1(temp);
				bstr[k] = b1;
				_i /= 10;
			}
			return string(bstr);
		}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

