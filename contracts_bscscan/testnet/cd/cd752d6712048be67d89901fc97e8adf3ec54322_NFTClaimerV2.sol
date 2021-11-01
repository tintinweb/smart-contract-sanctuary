/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// 

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

// File: node_modules\@openzeppelin\contracts\utils\Context.sol

// 

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

// File: @openzeppelin\contracts\access\Ownable.sol

// 

pragma solidity ^0.8.0;


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

// File: @openzeppelin\contracts\utils\Strings.sol

// 

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

// File: @openzeppelin\contracts\utils\cryptography\MerkleProof.sol

// 

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// File: src\contracts\interfaces\INFTPanda.sol

// 
pragma solidity ^0.8.0;

interface INFTPanda {
    struct MintParam {
        address _to;
        uint256 _tokenId;
        string _tokenURI;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function owner() external view returns (address);

    function transferOwnership(address _newAddress) external;

    function balanceOf(address owner_) external view returns (uint256 balance);

    function ownerOf(uint256 _tokenId) external view returns (address _ret);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner_, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner_, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mintNFT(MintParam calldata _mintParam) external;

    function _setBaseURI(string calldata uri) external;

    function setTokenURI(uint256 _tokenId, string calldata tokenURI_) external;
}

// File: src\contracts\NFTClaimerV2.sol

// 
pragma solidity ^0.8.0;






/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract SignerRole is Context {
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    constructor() {
        _addSigner(_msgSender());
    }

    modifier onlySigner() {
        require(
            isSigner(_msgSender()),
            "SignerRole: caller does not have the Signer role"
        );
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function addSigner(address account) public onlySigner {
        _addSigner(account);
    }

    function renounceSigner() public {
        _removeSigner(_msgSender());
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }
}

contract NFTClaimerV2 is Ownable, SignerRole {
    using Strings for uint256;

    INFTPanda public nftToken;
    address public nftTokenOwner;

    uint256 public claimableMinTokenId = 9001;
    uint256 public claimableMaxTokenId = 10000;

    uint256 public currentStage = 100;

    uint256[] public priceLevel; // [  0,     .01,    .02,     .03,    .04,    .1   ]
    uint256[] public timeStages; // [ day1,   day4,   day8,   day12,  day16,  day20 ]

    mapping(uint256 => mapping(uint256 => bool)) public roundClaimed;

    bool private isClaiming = false;
    bool public isWhitelistEnabled = false;

    // modifiers
    modifier Lock() {
        require(isClaiming == false, "Claimer: Claiming locked");
        isClaiming = true;
        _;
        isClaiming = false;
    }

    /// constructor

    constructor() {}

    // admin functions

    // configure price level
    function _setPriceLevel(
        uint256[] calldata _priceLevel,
        uint256[] calldata _timeStages
    ) external onlyOwner {
        require(
            _priceLevel.length == _timeStages.length,
            "Claimer: Array length mismatch"
        );
        delete priceLevel;
        delete timeStages;
        for (uint256 i = 0; i < _priceLevel.length; i++) {
            priceLevel.push(_priceLevel[i]);
            timeStages.push(_timeStages[i]);
        }
    }

    // update nft token
    function _setNftToken(address _newAddress) external onlyOwner {
        require(
            _newAddress != address(nftToken),
            "Claimer: Token configured already"
        );
        INFTPanda newNftToken = INFTPanda(_newAddress);
        require(
            newNftToken.owner() == address(this),
            "Claimer: New address must be owned by minter"
        );
        nftToken = newNftToken;
    }

    function _setNftTokenRole(address _newAddress) external onlyOwner {
        require(
            _newAddress != address(nftToken),
            "Claimer: Token configured already"
        );
        nftToken.transferOwnership(_newAddress);
    }

    // emergency withdraw functions
    function _adminWithdrawToken(
        address token_,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        require(recipient != address(0x0), "Claimer: Bad recipient");
        require(amount > 0, "Claimer: Bad amount");

        bool ok = IERC20(token_).transfer(recipient, amount);
        require(ok, "Claimer: Transfer failed");
    }

    function _adminWithdrawBnb() external onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        payable(msg.sender).transfer(address(this).balance);
    }

    // setClaimable Token range
    function _setClaimableTokenRange(uint256 min_, uint256 max_)
        external
        onlyOwner
    {
        claimableMinTokenId = min_;
        claimableMaxTokenId = max_;
    }

    // set nft token owner
    function _setNftTokenOwner(address owner_) external onlyOwner {
        nftTokenOwner = owner_;
    }

    // read functions
    // calculate price
    function calculatePrice() public view returns (uint256) {
        uint256 _current = block.timestamp;
        uint256 _curPrice = 0;
        for (uint256 i = 0; i < timeStages.length; i++) {
            if (_current >= timeStages[i]) _curPrice = priceLevel[i];
        }
        return _curPrice;
    }

    // get current stage
    function getCurrentStage() public view returns (uint256) {
        uint256 _current = block.timestamp;

        uint256 _curStage = 0;
        for (uint256 i = 0; i < timeStages.length; i++) {
            if (_current >= timeStages[i]) _curStage = i;
        }
        return _curStage;
    }

    // get tokenId's nft owner
    function _getNftOwner(uint256 _tokenId) public view returns (address) {
        address _nftOwner = address(0);
        try nftToken.ownerOf(_tokenId) returns (address _ret) {
            _nftOwner = _ret;
        } catch {}
        return _nftOwner;
    }

    // get ClaimableTokenId
    function _getClaimableTokenId(address user_, uint256 currentStage_)
        public
        view
        returns (uint256 tokenId_)
    {
        uint256 _userBalance = nftToken.balanceOf(user_);

        for (uint256 i = 0; i < _userBalance; i++) {
            uint256 _userBoughtTokenId = nftToken.tokenOfOwnerByIndex(user_, i);
            if (_userBoughtTokenId < claimableMinTokenId) continue;
            if (_userBoughtTokenId > claimableMaxTokenId) continue;
            if (!roundClaimed[currentStage_][_userBoughtTokenId])
                return _userBoughtTokenId;
        }

        return 0;
    }

    // write functions
    function claim(
        address _user,
        uint256 tokenId_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable Lock returns (uint256) {
        // check user
        require(msg.sender == _user, "Claimer: Invalid user");
        // check fund
        require(msg.value >= calculatePrice(), "Claimer: Insufficient fund");
        // check signed data
        require(
            isSigner(
                ecrecover(
                    toEthSignedMessageHash(
                        keccak256(abi.encodePacked(this, _user, tokenId_))
                    ),
                    v,
                    r,
                    s
                )
            ),
            "Claimer: Signer should sign tokenId"
        );

        // if not configured variables, return false
        require(timeStages.length > 0, "Claimer: TimeStages not configured");

        // if not started sale, return false
        uint256 _current = block.timestamp;
        require(_current >= timeStages[0], "Claimer: Claim not started");

        uint256 _currentStage = getCurrentStage();
        uint256 _claimableTokenId = _getClaimableTokenId(_user, _currentStage);
        // check if claimable
        require(_claimableTokenId > 0, "Claimer: User have no claimable token");

        // perform transfer from
        nftToken.safeTransferFrom(nftTokenOwner, address(this), tokenId_);
        nftToken.approve(_user, tokenId_);
        nftToken.safeTransferFrom(address(this), _user, tokenId_);

        // mark as claimed
        roundClaimed[_currentStage][_claimableTokenId] = true;
        return tokenId_;
    }

    // update base uri
    function updateBaseURI(string calldata uri) external onlyOwner {
        nftToken._setBaseURI(uri);
    }

    // update token uri
    function updateTokenURI(
        uint256[] calldata _tokenIds,
        string[] calldata _tokenURIs
    ) external onlyOwner {
        require(
            _tokenIds.length == _tokenURIs.length,
            "Claimer: Parameter length mismatch"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            nftToken.setTokenURI(_tokenIds[i], _tokenURIs[i]);
        }
    }

    function addSignerRole(address account) external onlyOwner {
        _addSigner(account);
    }

    function removeSignerRole(address account) external onlyOwner {
        _removeSigner(account);
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function encodePackedData(address user_, uint256 id)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(this, user_, id));
    }

    function getecrecover(
        address user_,
        uint256 id,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (address) {
        return
            ecrecover(
                toEthSignedMessageHash(
                    keccak256(abi.encodePacked(this, user_, id))
                ),
                v,
                r,
                s
            );
    }
}