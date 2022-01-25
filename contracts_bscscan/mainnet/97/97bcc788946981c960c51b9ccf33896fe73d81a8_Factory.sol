/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// SPDX-License-Identifier: BUSL-1.1

// File: interfaces/IEmergency.sol



pragma solidity 0.8.11;

interface IEmergency {
   function approveEmergencyAssetWithdraw(uint maxAmount, address destination) external;
   function daoMultiSigEmergencyWithdraw(address tokenAddress, address to, uint amount) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: interfaces/IRoleAccess.sol



pragma solidity 0.8.11;

interface IRoleAccess {
    function isAdmin(address user) view external returns (bool);
    function isDeployer(address user) view external returns (bool);
    function isConfigurator(address user) view external returns (bool);
    function isApprover(address user) view external returns (bool);
    function isRole(string memory roleName, address user) view external returns (bool);
}

// File: interfaces/IDeedManager.sol



pragma solidity 0.8.11;


interface IDeedManager {
    function addDeed(address deedContract, address projectOwner) external;   
    function getRoles() external view returns (IRoleAccess);
    function getDeedsCount() external view returns(uint);
}


// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

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
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
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
        return computedHash;
    }
}

// File: lib/Constant.sol




pragma solidity 0.8.11;

library Constant {
    uint    public constant FACTORY_VERSION     = 1;
    uint    public constant SUPERDEED_VERSION   = 2;
    address public constant ZERO_ADDRESS        = address(0);
    uint    public constant PCNT_100            = 1e6;
    uint    public constant EMERGENCY_WINDOW    = 1 days;
}



// File: lib/DataType.sol




pragma solidity 0.8.11;

library DataType {
      
    struct Store {
        Asset asset;
        Groups groups;
        mapping(uint => NftInfo) nftInfoMap; // Maps NFT Id to NftInfo
        uint nextIds; // NFT Id management 
        mapping(address=>Action[]) history; // History management
        Erc721Handler erc721Handler; // Erc721 asset deposit & claiming management
    }

    struct Asset {
        string symbol;
        string deedName;
        address tokenAddress;
        AssetType tokenType;
        uint tokenId; // Specific for ERC1155 type of asset only
    }

    struct Groups {
        Group[] items;
        uint vestingStartTime; // Global timestamp for vesting to start
    }
    
    struct GroupInfo {
        string name;
        uint totalEntitlement; // Total tokens to be distributed to this group
    }

    struct GroupState {
        bool finalized;
        bool funded;
    }

    struct Group {
        GroupInfo info;
        VestingItem[] vestItems;
        bytes32 merkleRoot; // Deed Claims using Merkle tree
        mapping(uint => uint) deedClaimMap;
        GroupState state;
    }

    struct Erc721Handler {
        uint[] erc721IdArray;
        mapping(uint => bool) idExistMap;
        uint erc721NextClaimIndex;
        uint numErc721TransferedOut;
        uint numUsedByVerifiedGroups;
    }

    struct NftInfo {
        uint groupId;
        uint totalEntitlement; 
        uint totalClaimed;
        bool valid;
    }  

    struct VestingItem {
        VestingReleaseType releaseType;
        uint delay;
        uint duration;
        uint percent;
    }
    
    struct Action {
        uint128     actionType;
        uint128     time;
        uint256     data1;
        uint256     data2;
    }
   
    struct History {
        mapping(address=>Action[]) investor;
        Action[] campaignOwner;
    }
    
    // ENUMS
    enum AssetType {
        ERC20,
        ERC1155,
        ERC721
    }

    enum VestingReleaseType {
        LumpSum,
        Linear,
        Unsupported
    }

    enum ActionType {
        AppendGroups,
        DefineVesting,
        UploadUsersData,
        SetAssetAddress,
        FinalizeGroup,
        FundInForGroup,
        FundInForGroupOverrided,
        StartVesting,
        ClaimDeed,
        ClaimTokens
    }
}


    
// File: logic/Vesting.sol



pragma solidity ^0.8.2;



library Vesting {

    function defineVesting(DataType.Groups storage groups, uint groupId, DataType.VestingItem[] calldata vestItems) internal returns (uint) {
        
        uint len = vestItems.length;
        _require(groupId < groups.items.length && len > 0, "Invalid parameter");

        DataType.Group storage item = groups.items[groupId];

        // Clear existing vesting items
        delete item.vestItems;

        // Append items
        uint totalPercent;
        for (uint n=0; n<len; n++) {

            DataType.VestingReleaseType relType = vestItems[n].releaseType;

            _require(relType < DataType.VestingReleaseType.Unsupported, "Invalid type");
            _require(!(relType == DataType.VestingReleaseType.Linear && vestItems[n].duration == 0), "Linear type cannot have 0 duration");
            _require(vestItems[n].percent > 0, "Invalid percent");
            
            totalPercent += vestItems[n].percent;
            item.vestItems.push(vestItems[n]);
        }
        // The total percent have to add up to 100 %
        _require(totalPercent == Constant.PCNT_100, "Must add up to 100%");
        return len;
    }

    function getClaimable(DataType.Groups storage groups, uint groupId) internal view returns (uint claimablePercent) {

        _require(groupId < groups.items.length, "Invalid group Id");

        uint start = groups.vestingStartTime;
        uint end = block.timestamp;

        // Vesting not started yet ?
        if (start == 0 || end <= start) {
            return 0;
        }

        DataType.VestingItem[] storage items = groups.items[groupId].vestItems;
        uint len = items.length;
       
        for (uint n=0; n<len; n++) {

            (uint percent, bool continueNext, uint traverseBy) = getRelease(items[n], start, end);
            claimablePercent += percent;

            if (continueNext) {
                start += traverseBy;
            } else {
                break;
            }
        }
    }

    function getRelease(DataType.VestingItem storage item, uint start, uint end) internal view returns (uint releasedPercent, bool continueNext, uint traverseBy) {

        releasedPercent = 0;
        bool passedDelay = (end > (start + item.delay));
        if (passedDelay) {
           
            if (item.releaseType == DataType.VestingReleaseType.LumpSum) {
                releasedPercent = item.percent;
                continueNext = true;
                traverseBy = item.delay;
            } else if (item.releaseType == DataType.VestingReleaseType.Linear) {
                uint elapsed = end - start - item.delay;
                releasedPercent = min(item.percent, (item.percent * elapsed) / item.duration);
                continueNext = (end > (start + item.delay + item.duration));
                traverseBy = (item.delay+item.duration);
            } 
            else {
                assert(false);
            }
        } 
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _require(bool condition, string memory error) pure internal {
        require(condition, error);
    }
}

// File: logic/MerkleClaims.sol



pragma solidity 0.8.11;



library MerkleClaims {

    function isClaimed(DataType.Group storage group, uint index) internal view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = group.deedClaimMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function setClaimed(DataType.Group storage group, uint index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        group.deedClaimMap[claimedWordIndex] = group.deedClaimMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(DataType.Group storage group, uint index, address account, uint256 amount, bytes32[] calldata merkleProof) internal  {
        _require(!isClaimed(group, index), "Already claimed.");
        _require( amount > 0 && verifyClaim(group, index, account, amount, merkleProof), "Invalid amount or proof");
        setClaimed(group, index);
    }

    function verifyClaim(DataType.Group storage group, uint index, address account, uint amount, bytes32[] calldata merkleProof) internal view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        return MerkleProof.verify(merkleProof, group.merkleRoot, node);
    }

    function _require(bool condition, string memory error) pure internal {
        require(condition, error);
    }
}

// File: logic/Groups.sol



pragma solidity 0.8.11;


library Groups {

    event AppendGroup(address indexed user, string name);
    event SetGroupFinalized(address indexed user, uint groupId, string name);
    event UploadGroupUserData(address indexed user, uint groupId, uint totalTokens);

    function appendGroups(DataType.Groups storage groups, string[] memory names) external returns (uint len) {
        len = names.length;
        for (uint n=0; n<len; n++) {
            
            (bool found, ) = exist(groups, names[n]);
            _require(!found, "Group already exist");

            DataType.Group storage newGroup = groups.items.push();
            newGroup.info.name = names[n];
            emit AppendGroup(msg.sender, names[n]);
        }
    }

    function uploadUsersData(DataType.Groups storage groups, uint groupId, bytes32 root, uint totalTokens) external {
        DataType.Group storage item = groups.items[groupId];
        _require(!item.state.finalized, "Already finalized");
        item.merkleRoot = root;
        item.info.totalEntitlement = totalTokens;
        emit UploadGroupUserData(msg.sender, groupId, totalTokens);
    }

    function setFinalized(DataType.Groups storage groups, uint groupId, string memory groupName) external {
        DataType.Group storage item = groups.items[groupId];
        _require(!item.state.finalized, "Already finalized");
        _require(item.merkleRoot.length > 0, "No merkle root");
        _require(item.info.totalEntitlement > 0, "No entitlement");
        _require(item.vestItems.length > 0, "No vesting item");
        item.state.finalized = true;
        emit SetGroupFinalized(msg.sender, groupId, groupName);
    }

    function statusCheck(DataType.Groups storage groups, uint groupId) public view returns (bool, string memory) {
        uint len = groups.items.length;
        if (groupId >= len) { return (false, "Invalid group id"); }

        DataType.Group storage item = groups.items[groupId];
        if (!item.state.finalized) { return (false, "Not yet finalized"); }
        if (item.merkleRoot.length == 0) { return (false, "No merkle root"); }
        if (item.info.totalEntitlement == 0) { return (false, "No entitlement"); }
        if (item.vestItems.length == 0) { return (false, "No vesting item"); }
        return (true, "ok");
    }

    function getGroupName(DataType.Groups storage groups, uint groupId) external view returns (string memory ) {
        _require(groupId  < groups.items.length, "Invalid Id");
        return groups.items[groupId].info.name;
    }

    function exist(DataType.Groups storage groups, string memory name) private view returns (bool, uint) {
        uint len = groups.items.length;
        for (uint n=0; n<len; n++) {
            if (_strcmp(groups.items[n].info.name, name)) {
                return (true, n);
            }
        }
        return (false, 0);
    }

    function _strcmp(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function _require(bool condition, string memory error) pure private {
        require(condition, error);
    }
}


// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: core/DataStore.sol



pragma solidity 0.8.11;










contract DataStore {
        
    using SafeERC20 for IERC20;
    using Groups for *;
    using MerkleClaims for *;

    DataType.Store private _dataStore;
    IRoleAccess private _roles;

    address public projectOwner;

    // Emergency Withdrawal Support
    uint internal _emergencyMaxAmount;
    uint internal _emergencyExpiryTime;
    address internal _emergencyDestination;
    bool internal _isFunded;
    
    modifier onlyProjectOwner() {
        _require(msg.sender == projectOwner, "Not project owner");
        _;
    }
    
    modifier onlyDaoMultiSig() {
        _require(_roles.isAdmin(msg.sender), "Not dao multiSig");
        _;
    }

    modifier onlyProjectOwnerOrConfigurator() {
        _require(msg.sender == projectOwner || _roles.isConfigurator(msg.sender), "Not project owner or configurator");
        _;
    }

    modifier onlyProjectOwnerOrApprover() {
        _require(msg.sender == projectOwner || _roles.isApprover(msg.sender), "Not project owner or approver");
        _;
    }

    modifier notLive() {
        _require(!isLive(), "Already live");
        _;
    }

    event SetAssetDetails(address indexed user, address tokenAddress, DataType.AssetType tokenType, uint tokenIdFor1155);
    event FinalizeGroup(address indexed user, uint groupId, string groupName);
    event FundInForGroup(address indexed user, uint groupId, string groupName, uint amount);
    event FundInForGroupOverrided(address indexed user, uint groupId, string groupName);
    event StartVesting(address indexed user, uint timeStamp);
    event ClaimDeed(address indexed user, uint timeStamp, uint groupId, uint claimIndex, uint amount, uint nftId);
    event ClaimTokens(address indexed user, uint timeStamp, uint id, uint amount);
    event Split(uint timeStamp, uint id1, uint id2, uint amount);
    event SplitPercent(uint timeStamp, uint id1, uint id2, uint percent);
    event Combine(uint timeStamp, uint id1, uint id2);
    event ApprovedEmergencyWithdraw(address indexed approver, uint amount, uint expiry, address destination);
    event DaoMultiSigEmergencyWithdraw(address to, address tokenAddress, uint amount);
    
    constructor (IRoleAccess roles, address campaignOwner) {
        _require(campaignOwner != Constant.ZERO_ADDRESS, "Invalid address");
        _roles = roles;
        projectOwner = campaignOwner;
    }

    //--------------------//
    //   QUERY FUNCTIONS  //
    //--------------------//

    function getAsset() external view returns (DataType.Asset memory) {
        return _dataStore.asset;
    }

    function getGroupCount() external view returns (uint) {
        return _groups().items.length;
    }

    function getGroupInfo(uint groupId) public view returns (DataType.GroupInfo memory) {
        return _groups().items[groupId].info;
    }

    function getGroupState(uint groupId) public view returns (DataType.GroupState memory) {
        return _groups().items[groupId].state;
    }

    function checkGroupStatus(uint groupId) external view returns (bool, string memory) {
        return _groups().statusCheck(groupId);
    }

    function getVestingInfo(uint groupId) external view returns (DataType.VestingItem[] memory) {
        return _groups().items[groupId].vestItems;
    }

    function getVestingStartTime() external view returns (uint) {
        return _groups().vestingStartTime;
    }

    function getNftInfo(uint nftId) public view returns (DataType.NftInfo memory) {
        return _store().nftInfoMap[nftId];
    }

    function isLive() public view returns (bool) {
        uint time = _groups().vestingStartTime;
        return (time != 0 && block.timestamp > time);
    }

    function isDeedClaimed(uint groupId, uint index) external view returns (bool) {
        DataType.Group storage group = _groups().items[groupId];
        return group.isClaimed(index);
    }

    function verifyDeedClaim(uint groupId, uint index, address account, uint amount, bytes32[] calldata merkleProof) external view returns (bool) {
        DataType.Group storage group = _groups().items[groupId];
        return group.verifyClaim(index, account, amount, merkleProof);
    }

    //--------------------//
    // INTERNAL FUNCTIONS //
    //--------------------//
    function _store() internal view returns (DataType.Store storage) {
        return _dataStore;
    }

    function _groups() internal view returns (DataType.Groups storage) {
        return _dataStore.groups;
    }

    function _asset() internal view returns (DataType.Asset storage) {
        return _dataStore.asset;
    }

    function _nextNftIdIncrement() internal returns (uint) {
        return _dataStore.nextIds++;
    }

    function _transferAssetOut(address to, uint amount) internal {

        DataType.AssetType assetType = _asset().tokenType;
        address token = _asset().tokenAddress;

        if (assetType == DataType.AssetType.ERC20) {
            IERC20(token).safeTransfer(to, amount);
        } else if (assetType == DataType.AssetType.ERC1155) {
            IERC1155(token).safeTransferFrom(address(this), to, _asset().tokenId, amount, "");
        } else if (assetType == DataType.AssetType.ERC721) {
            
            DataType.Erc721Handler storage handler = _store().erc721Handler;
            uint len = handler.erc721IdArray.length;
            require(handler.numErc721TransferedOut + amount <= len, "Exceeded Amount");
        
            for (uint n=0; n<amount; n++) {
                uint id = handler.erc721IdArray[handler.erc721NextClaimIndex++];
                IERC721(token).safeTransferFrom(address(this), to, id);
            }
            handler.numErc721TransferedOut += amount;
        }
    }

    function _transferOutErc20(address token, address to, uint amount) internal {
        IERC20(token).safeTransfer(to, amount);
    }
    
    function _setAsset(string memory tokenSymbol, string memory deedName) internal {
        _dataStore.asset.symbol = tokenSymbol;
        _dataStore.asset.deedName = deedName;
    }

    function _setAssetDetails(address tokenAddress, DataType.AssetType tokenType, uint tokenIdFor1155) internal {
        _require(tokenAddress != Constant.ZERO_ADDRESS, "Invalid address");
        _dataStore.asset.tokenAddress = tokenAddress;
        _dataStore.asset.tokenType = tokenType;
        _dataStore.asset.tokenId = tokenIdFor1155;
        emit SetAssetDetails(msg.sender, tokenAddress, tokenType, tokenIdFor1155);
    }

    function _recordHistory(DataType.ActionType actType, uint data1) internal {
        _recordHistory(actType, data1, 0);
    }

    function _recordHistory(DataType.ActionType actType, uint data1, uint data2) internal {
       DataType.Action memory act = DataType.Action(uint128(actType), uint128(block.timestamp), data1, data2);
       _dataStore.history[msg.sender].push(act);
    }

    function _check(uint groupId, string memory groupName) internal view returns (bool matched) {
        matched = _strcmp(_groups().items[groupId].info.name, groupName);
        _require(matched, "Unmatched group");
    }

    function _strcmp(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function _require(bool condition, string memory error) pure internal {
        require(condition, error);
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: SuperDeedV2.sol



pragma solidity 0.8.11;








contract SuperDeedV2 is ERC721Enumerable, IEmergency, ERC1155Holder, ERC721Holder, DataStore, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using MerkleClaims for DataType.Group;
    using Groups for *;
    using Vesting for *;

    string private constant SUPER_DEED = "SuperDeed";
    string private constant BASE_URI = "https://superlauncher.io/metadata/";

    constructor(
        IRoleAccess roles,
        address projectOwnerAddress, 
        string memory tokenSymbol, 
        string memory deedName
    ) 
        ERC721(deedName, SUPER_DEED)  
        DataStore(roles, projectOwnerAddress)
    {
        _setAsset(tokenSymbol, deedName);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC1155Receiver) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId) || 
            ERC1155Receiver.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 /*tokenId*/) public view virtual override returns (string memory) {
        return  string(abi.encodePacked(BASE_URI, _store().asset.deedName));
    }

    //--------------------//
    //   SETUP & CONFIG   //
    //--------------------//

    function appendGroups(string[] memory names) external notLive onlyProjectOwnerOrConfigurator {
        uint added = _groups().appendGroups(names);
        _recordHistory(DataType.ActionType.AppendGroups, added);
    }

    function defineVesting(uint groupId, string memory groupName, DataType.VestingItem[] calldata vestItems) external  notLive onlyProjectOwnerOrConfigurator {    
        _require(!getGroupState(groupId).finalized, "Cannot change after group is finalized");
        _check(groupId, groupName);
        uint added = _groups().defineVesting(groupId, vestItems);
        _recordHistory(DataType.ActionType.DefineVesting, added);
    }

    function uploadUsersData(uint groupId, string memory groupName, bytes32 merkleRoot, uint totalTokens) external  notLive onlyProjectOwnerOrConfigurator {   
        _check(groupId, groupName);
        _groups().uploadUsersData(groupId, merkleRoot, totalTokens);
        _recordHistory(DataType.ActionType.UploadUsersData, groupId, totalTokens);
    }

    function setAssetDetails(address tokenAddress, DataType.AssetType tokenType, uint tokenIdFor1155) external notLive onlyProjectOwnerOrConfigurator {
        _require(!_isFunded, "The asset has been funded in");
        _setAssetDetails(tokenAddress, tokenType, tokenIdFor1155);
        _recordHistory(DataType.ActionType.SetAssetAddress, uint160(tokenAddress), uint(tokenType));
    }

    function setGroupFinalized(uint groupId, string memory groupName) external notLive onlyProjectOwnerOrApprover {
        _check(groupId, groupName);
        _groups().setFinalized(groupId, groupName);
        emit FinalizeGroup(msg.sender, groupId, groupName);
        _recordHistory(DataType.ActionType.FinalizeGroup, groupId);
    }

    function fundInForGroup(uint groupId, string memory groupName, uint tokenAmount) external notLive onlyProjectOwnerOrApprover {
        _check(groupId, groupName);
        _require(_asset().tokenAddress != Constant.ZERO_ADDRESS, "Invalid address");
        
        // Check required token Amount is correct?
        DataType.Group storage group = _groups().items[groupId];
        _require(tokenAmount == group.info.totalEntitlement, "Wrong token amount");

        // Group must be finalized and not yet fund in
        _require(group.state.finalized, "Not yet finalized");
        _require(!group.state.funded, "Already funded");
        group.state.funded = true;
        _isFunded = true;
        
        DataType.AssetType assetType = _asset().tokenType;
        if (assetType == DataType.AssetType.ERC20) {
            IERC20(_asset().tokenAddress).safeTransferFrom(msg.sender, address(this), tokenAmount); 
        } else if (assetType == DataType.AssetType.ERC1155) {
            IERC1155(_asset().tokenAddress).safeTransferFrom(msg.sender, address(this), _asset().tokenId, tokenAmount, ""); 
        } else {
            // Verify that the amount has been deposied already ?
            DataType.Erc721Handler storage handler = _store().erc721Handler;

            uint totalDeposited721 = handler.erc721IdArray.length;
            _require(totalDeposited721 >= (handler.numUsedByVerifiedGroups + tokenAmount), "Insufficient deposited erc721");
            handler.numUsedByVerifiedGroups += tokenAmount;
        }   
        emit FundInForGroup(msg.sender, groupId, groupName, tokenAmount);
        _recordHistory(DataType.ActionType.FundInForGroup, groupId, tokenAmount);
    }

    // For projects that are unable to fund in fully, but able to do progressive fund-ins, the MS DAO can override the
    // full FundIn requirement. In this case the project need to prove to SuperLauncher that they can provide the 
    // required assets on time without failure. For example, project can provide a funding contract for this purpose.
    function fundInForGroupOverride(uint groupId, string memory groupName) external notLive onlyDaoMultiSig {

        _check(groupId, groupName);
        _require(_asset().tokenAddress != Constant.ZERO_ADDRESS, "Invalid address");
        
        // Check required token Amount is correct?
        DataType.Group storage group = _groups().items[groupId];
        // Group must be finalized and not yet fund in
        _require(group.state.finalized, "Not yet finalized");
        _require(!group.state.funded, "Already funded");
        group.state.funded = true;
        _isFunded = true;

        emit FundInForGroupOverrided(msg.sender, groupId, groupName);
        _recordHistory(DataType.ActionType.FundInForGroupOverrided, groupId, 0);
    }

    function notifyErc721Deposited(uint[] calldata ids) external notLive onlyProjectOwnerOrApprover {

        _require(_asset().tokenType == DataType.AssetType.ERC721, "Not Erc721 asset");
        address token = _asset().tokenAddress;

        DataType.Erc721Handler storage handler = _store().erc721Handler;

        uint id;
        uint len = ids.length;
        for (uint n=0; n<len; n++) {

            // Make sure it is owned by this contract
            id = ids[n];
            _require(IERC721(token).ownerOf(id) == address(this), "Nft Id not deposited");
            
            if (!handler.idExistMap[id]) {
                handler.idExistMap[id] = true;
                handler.erc721IdArray.push(id);
            }
        }
    }

    // If startTime is 0, the vesting wil start immediately.
    function startVesting(uint startTime) external notLive onlyProjectOwnerOrApprover {

        // Make sure that the asset address are set before start vesting
        _require(_asset().tokenAddress != Constant.ZERO_ADDRESS, "Set token address first");
        _require(_isFunded, "At least one group needs to be funded");

        if (startTime==0) {
            startTime = block.timestamp;
        } 
        _require(startTime >= block.timestamp, "Cannot back-date vesting");
        _groups().vestingStartTime = startTime;
        emit StartVesting(msg.sender, startTime);
        _recordHistory(DataType.ActionType.StartVesting, startTime);
    }

    //--------------------//
    //   USER OPERATION   //
    //--------------------//

    // A user address can participate in multiple groups. In this way, a user address can claim multiple deeds.
    function claimDeeds(uint[] calldata groupIds, uint[] calldata indexes, uint[] calldata amounts, bytes32[][] calldata merkleProofs) external nonReentrant {
        
        uint len = groupIds.length;
        _require(len > 0 && len == indexes.length && len == merkleProofs.length, "Invalid parameters");

        uint grpId;
        uint claimIndex;
        uint amount;
        uint nftId;

        DataType.Groups storage groups = _groups();
        for (uint n=0; n<len; n++) {
            
            grpId = groupIds[n];
            claimIndex = indexes[n];
            amount = amounts[n]; 

            DataType.Group storage item = groups.items[grpId];
            _require(item.state.finalized, "Not finalized");
            _require(!item.isClaimed(claimIndex), "Already claimed");

            item.claim(claimIndex, msg.sender, amount, merkleProofs[n]);
            
            // Mint NFT
            nftId = _mintInternal(msg.sender, grpId, amount, 0);
            emit ClaimDeed(msg.sender, block.timestamp, grpId, claimIndex, amount, nftId);
            _recordHistory(DataType.ActionType.ClaimDeed, grpId, nftId);
        }
    }

    function getGroupReleasable(uint groupId) external view returns (uint percentReleasable, uint totalEntitlement) {
        
        if (getGroupState(groupId).finalized) {
            totalEntitlement =  getGroupInfo(groupId).totalEntitlement;
            percentReleasable = _groups().getClaimable(groupId);
        }
    }

    function getClaimable(uint nftId) public view returns (uint claimable, uint totalClaimed, uint totalEntitlement) {
        DataType.NftInfo memory nft = getNftInfo(nftId);
        if (nft.valid) {
            totalEntitlement =  nft.totalEntitlement;
            totalClaimed = nft.totalClaimed;

            uint percentReleasable = _groups().getClaimable(nft.groupId);
            if (percentReleasable > 0) {
                uint totalReleasable = (percentReleasable * totalEntitlement) / Constant.PCNT_100;
                if (totalReleasable > totalClaimed) {
                    claimable = totalReleasable - totalClaimed;
                }
            }
        }
    }

    // ERC721 cannot be batchTransfer. In order to make sure the claim will not fail due to claiming
    // a huge number of ERC721 token, we allow specifying a claim amount 'maxAmount'. This way, the
    // user can claim multiple times without having gas limitation issue.
    // If maxAmount is set to 0, it will claim all available tokens.
    function claimTokens(uint nftId, uint maxAmount) external nonReentrant {
        _require(ownerOf(nftId) == msg.sender, "Not owner");

        // if this group is not yet funded, it should not be claimable
        uint groupId = getNftInfo(nftId).groupId;
        require(getGroupState(groupId).funded, "Group not funded yet");

        (uint claimable, ,) =  getClaimable(nftId);
        _require(claimable > 0, "Nothing to claim");
        
        // Partial claim ?
        if (maxAmount != 0 && claimable > maxAmount) {
            claimable = maxAmount;
        }
    
        DataType.NftInfo storage nft = _store().nftInfoMap[nftId];
        nft.totalClaimed += claimable;

        _transferAssetOut(msg.sender, claimable);
        emit ClaimTokens(msg.sender, block.timestamp, nftId, claimable);
        _recordHistory(DataType.ActionType.ClaimTokens, nftId, claimable);
    }

    // Split an amount of entitlement out from the "remaining" entitlement from an exceeding Deed and becomes a new Deed.
    // After the split, both Deeds should have non-zero remaining entitlement left.
    function split(uint id, uint amount) external nonReentrant returns (uint newId) {
        _require(ownerOf(id) == msg.sender, "Not owner");
        
        DataType.NftInfo storage nft = _store().nftInfoMap[id];

        uint entitlementLeft = nft.totalEntitlement - nft.totalClaimed;
        _require(amount > 0 && entitlementLeft > amount, "Invalid amount");

        // Calculate the new NFT's required totalEntitlemnt totalClaimed, in a way that these values are distributed 
        // as fairly as possible between the parent and child NFT. 
        // Important note is that the sum of the totalEntitlement and totalClaimed before and after the split 
        // should remain the same. Nothing more or less is resulted due to the split.
        uint neededTotalEnt = (amount * nft.totalEntitlement) / entitlementLeft;
        _require(neededTotalEnt > 0, "Invalid amount");
        uint neededTotalClaimed = neededTotalEnt - amount;

        nft.totalEntitlement -= neededTotalEnt;
        nft.totalClaimed -= neededTotalClaimed;

        // Sanity Check
        _require(nft.totalEntitlement > 0 && nft.totalClaimed < nft.totalEntitlement, "Fail check");
        
        // mint new nft
        newId = _mintInternal(msg.sender, nft.groupId, neededTotalEnt, neededTotalClaimed);
        emit Split(block.timestamp, id, newId, amount);
    }

    function combine(uint id1, uint id2) external nonReentrant {
        _require(ownerOf(id1) == msg.sender && ownerOf(id2) == msg.sender, "Not owner");

        DataType.NftInfo storage nft1 = _store().nftInfoMap[id1];
        DataType.NftInfo memory nft2 = _store().nftInfoMap[id2];
        
        // Must be the same group
        _require(nft1.groupId == nft2.groupId, "Not same group");

        // Since the vesting items are the same, we can just add up the 2 nft 
        nft1.totalEntitlement += nft2.totalEntitlement;
        nft1.totalClaimed += nft2.totalClaimed;
         
        // Burn NFT 2 
        _burn(id2);
        delete _store().nftInfoMap[id2];

        emit Combine(block.timestamp, id1, id2);
    }

    function version() external pure returns (uint) {
        return Constant.SUPERDEED_VERSION;
    }

    // Implements IEmergency 
    function approveEmergencyAssetWithdraw(uint maxAmount, address destination) external override onlyProjectOwner {
        _emergencyMaxAmount = maxAmount;
        _emergencyExpiryTime = block.timestamp + Constant.EMERGENCY_WINDOW;
        _emergencyDestination = destination;
        emit ApprovedEmergencyWithdraw(msg.sender, _emergencyMaxAmount, _emergencyExpiryTime, _emergencyDestination);
    }

    function daoMultiSigEmergencyWithdraw(address tokenAddress, address to, uint amount) external override onlyDaoMultiSig {
       
        // If withdrawn token is the asset, then we will require projectOwner to approve.
        // Every approval allow 1 time withdraw only.
        if (tokenAddress == _asset().tokenAddress) {
            _require((amount <= _emergencyMaxAmount) && (block.timestamp <= _emergencyExpiryTime), "Criteria not met");
            _require(to == _emergencyDestination, "Wrong withdrawal destination");

            // Reset 
            _emergencyMaxAmount = 0;
            _emergencyExpiryTime = 0;
            _emergencyDestination = Constant.ZERO_ADDRESS;

            _transferAssetOut(to, amount);
        } else {
            // Withdraw non asset ERC20   
            _transferOutErc20(tokenAddress, to, amount); 
        }
        emit DaoMultiSigEmergencyWithdraw(to, tokenAddress, amount);
    }

    //--------------------//
    // INTERNAL FUNCTIONS //
    //--------------------//
 
    function _mintInternal(address to, uint groupId, uint totalEntitlement, uint totalClaimed) internal returns (uint id) {
        _require(totalEntitlement > 0, "Invalid entitlement");
        id = _nextNftIdIncrement();
        _mint(to, id);

        // Setup the certificate's info
        _store().nftInfoMap[id] = DataType.NftInfo(groupId, totalEntitlement, totalClaimed, true);
    }
}

// File: Factory.sol



pragma solidity 0.8.11;



contract Factory {
    
    IDeedManager private _manager;

    event CreateDeed(address newDeed, address projectOwner);

    constructor(IDeedManager manager) {
        _manager = manager;
    }

    //--------------------//
    // EXTERNAL FUNCTIONS //
    //--------------------//
    function createNewDeed(address projectOwner, string calldata symbol) external {

        IRoleAccess roles = _manager.getRoles();
        require(roles.isDeployer(msg.sender), "Not deployer");
        require(projectOwner != address(0), "Invalid address");
       
        // Deploy Deed certificate
        string memory deedName = string(abi.encodePacked(symbol, "-Deed")); // Append symbol from XYZ -> XYZ-Deed
        bytes32 salt = keccak256(abi.encodePacked(deedName, _manager.getDeedsCount(), msg.sender));
        address deedAddress = address(new SuperDeedV2{salt:salt}(roles, projectOwner, symbol, deedName)); 
       
        _manager.addDeed(deedAddress, projectOwner);
        emit CreateDeed(deedAddress, projectOwner);
    }

    function version() external pure returns (uint) {
        return Constant.FACTORY_VERSION;
    }
}