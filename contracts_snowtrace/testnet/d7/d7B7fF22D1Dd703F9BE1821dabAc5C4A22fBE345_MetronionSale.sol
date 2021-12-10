//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IMetronionNFT } from "./interface/IMetronionNFT.sol";
import { IMetronionSale } from "./interface/IMetronionSale.sol";
import { Whitelist } from "./utils/Whitelist.sol";
import { TokenWithdrawable } from "./utils/TokenWithdrawable.sol";

contract MetronionSale is IMetronionSale, Whitelist, TokenWithdrawable {
    using Address for address;

    uint64 public constant CAP_OWNER_INITIAL_MINT = 500;
    uint64 public constant CAP_PER_PRIVATE_ADDRESS = 1;
    uint64 public constant CAP_PER_ADDRESS = 5;
    uint256 public constant SALE_PRICE = 2 * 10**18; // 2 AVAX

    IMetronionNFT public immutable override nftContract;
    mapping(uint256 => SaleConfig) internal _saleConfigs; // mapping from version id to sale config
    mapping(uint256 => SaleRecord) internal _saleRecords; // mapping from version id to sale record
    mapping(uint256 => mapping(address => UserRecord)) internal _userRecords; // mapping from version id to map of user record

    constructor(
        IMetronionNFT _nftContract,
        uint256 _versionId,
        uint256 _maxWhitelistSize,
        uint64 _privateTime,
        uint64 _publicTime,
        uint64 _endTime
    ) Whitelist(_versionId, _maxWhitelistSize) {
        nftContract = _nftContract;
        _saleConfigs[_versionId] = SaleConfig({
            privateTime: _privateTime,
            publicTime: _publicTime,
            endTime: _endTime
        });
    }

    /**
     * @dev withdraw BNB from sale fund
     * Only owner can call
     */
    function withdrawSaleFunds(address payable recipient, uint256 amount) external onlyOwner {
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "MetronionSale: withdraw funds failed");
        emit WithdrawSaleFunds(recipient, amount);
    }

    /**
     * @dev Buy an amount of Metronions
     * Maximum amount for private and public sale will be different
     * @param versionId Metronion version, starting at 0
     * @param amount amount of Metronions
     */
    function buy(uint256 versionId, uint64 amount) external payable override {
        address buyer = msg.sender;
        // only EOA or the owner can buy, disallow contracts to buy
        require(!buyer.isContract() || buyer == owner(), "MetronionSale: only EOA or owner");

        _validateAndUpdateBuy(versionId, buyer, amount);

        nftContract.mintMetronion(versionId, amount, buyer);
    }

    /**
     * @dev validate data if it's valid to buy
     * Cannot buy more than max supply
     * If the buyer is the owner, then in the sale period buyer can buy up to CAP_OWNER_INITIAL_MINT with price = 0
     * After sale period owner can free to buy with price = 0
     * If the buy time is in private sale time, only whitelisted user can buy up to CAP_PER_PRIVATED_ADDRESS with SALE_PRICE per Metronion
     * If the buy time is in public sale time, each buyer can buy up to CAP_PER_ADDRESS with SALE_PRICE per Metronion
     * @param versionId version id
     * @param buyer buyer address
     * @param amount amount of Metronions
     */
    function _validateAndUpdateBuy(
        uint256 versionId,
        address buyer,
        uint64 amount
    ) internal {
        IMetronionNFT.Version memory versionConfig = nftContract.versionById(versionId);
        // buy amount cannot exceed max supply
        require(
            _saleRecords[versionId].totalSold + amount <= versionConfig.maxSupply,
            "MetronionSale: exceed buy amount"
        );
        SaleConfig memory saleConfig = _saleConfigs[versionId];
        uint256 totalPaid = msg.value;
        uint256 timestamp = block.timestamp;

        if (msg.sender == owner()) {
            // owner can buy up to CAP_OWNER_INITIAL_MINT in sale time
            if (timestamp < saleConfig.endTime) {
                require(
                    _saleRecords[versionId].ownerBought + amount <= CAP_OWNER_INITIAL_MINT,
                    "MetronionSale: exceed owner cap"
                );
            }
            _saleRecords[versionId].ownerBought += amount;
            _saleRecords[versionId].totalSold += amount;
            emit OwnerBought(buyer, versionId, totalPaid);
            return;
        }

        UserRecord memory userRecord = getUserRecord(versionId, buyer);
        require(timestamp >= saleConfig.privateTime, "MetronionSale: not started");
        require(timestamp <= saleConfig.endTime, "MetronionSale: sale ended");

        if (timestamp >= saleConfig.privateTime && timestamp < saleConfig.publicTime) {
            // only whitelisted can buy at this period
            require(isWhitelistedAddress(versionId, buyer), "MetronionSale: not whitelisted buyer");
            require(totalPaid == amount * SALE_PRICE, "MetronionSale: invalid paid value");
            require(userRecord.privateBought + amount <= CAP_PER_PRIVATE_ADDRESS, "MetronionSale: exceed private cap");
            _userRecords[versionId][buyer].privateBought += amount;
            _saleRecords[versionId].totalSold += amount;
            _saleRecords[versionId].privateSold += amount;
            emit PrivateBought(buyer, versionId, totalPaid);
            return;
        }

        if (timestamp >= saleConfig.publicTime && timestamp < saleConfig.endTime) {
            // public sale
            require(totalPaid == amount * SALE_PRICE, "MetronionSale: invalid paid value");
            require(userRecord.publicBought + amount <= CAP_PER_ADDRESS, "MetronionSale: exceed public cap");
            _userRecords[versionId][buyer].publicBought += amount;
            _saleRecords[versionId].totalSold += amount;
            _saleRecords[versionId].publicSold += amount;
            emit PublicBought(buyer, versionId, totalPaid);
        }
    }

    /**
     * @dev Return sale config for specific version
     * @param versionId Metronion version, starting at 0
     */
    function getSaleConfig(uint256 versionId) external view override returns (SaleConfig memory config) {
        config = _saleConfigs[versionId];
    }

    /**
     * @dev Return sale record for specific version
     * @param versionId Metronion version, starting at 0
     */
    function getSaleRecord(uint256 versionId) public view returns (SaleRecord memory saleRecord) {
        return _saleRecords[versionId];
    }

    /**
     * @dev get user record for buy amount in private and public sale for specific version
     * @param versionId Metronion version, starting at 0
     * @param account user address
     */
    function getUserRecord(uint256 versionId, address account) public view returns (UserRecord memory userRecord) {
        return _userRecords[versionId][account];
    }

    // callback function
    receive() external payable {
        emit ReceiveETH(msg.sender, msg.value);
    }
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IMetronionNFT is IERC721Enumerable {
    struct Metronion {
        string name;
        uint256 version;
    }

    struct Version {
        uint256 startingIndex;
        uint256 currentSupply;
        uint256 maxSupply;
        string provenance;
    }

    event MetronionCreated(uint256 indexed metronionId, uint256 indexed versionId, address to);
    event NameChanged(uint256 indexed metronionId, string newName);
    event AccessoriesEquipped(uint256 indexed metronionId, uint256[] accessoryIds);
    event AccessoriesUnequipped(uint256 indexed metronionid, uint256[] accessoryIds);
    event StartingIndexFinalized(uint256 versionId, uint256 startingIndex);
    event NewVersionAdded(uint256 versionId);
    event UpdateBaseURI(string uri);

    /**
     * @dev Mint Metronions, can only called by operator
     * Can mint up to MAX_METRONION_SUPPLY
     * @param versionId Version of Metronion to mint
     * @param amount Amount of Metronions to mint
     * @param to Address to mint Metronions to
     */
    function mintMetronion(
        uint256 versionId,
        uint256 amount,
        address to
    ) external;

    /**
     * @dev Owner equips accessories to their Metronion by burning ERC1155 Accessory NFTs.
     * Can only call by Metronion's owner
     * @param metronionId Metronion ID
     * @param accessoryIds Accessory IDs
     */
    function equipAccessories(uint256 metronionId, uint256[] memory accessoryIds) external;

    /**
     * @dev Owner remove accessories from their Metronion by minting ERC1155 Accessory NFTs back to the owner.
     * Can only call by Metronion's owner
     * @param metronionId Metronion ID
     * @param accessoryIds Accessory IDs
     */
    function removeAccessories(uint256 metronionId, uint256[] memory accessoryIds) external;

    /**
     * @dev Change Metronion name
     * Can only called by metronion's owner
     * New name should not duplicate with the old name
     * @param metronionId Metronion ID
     * @param newName Metronion name
     */
    function changeMetronionName(uint256 metronionId, string memory newName) external;

    /**
     * @dev Get Metronion info
     * @param metronionId Metronion ID
     */
    function getMetronion(uint256 metronionId) external view returns (Metronion memory metronion);

    /**
     * @dev Get accessories that Metronion equipped
     * @param metronionId Metronion ID
     * @param accessoriesType Accessories type, start from 0
     */
    function getMetronionAccessory(uint256 metronionId, uint256 accessoriesType)
        external
        view
        returns (uint256 accessoryId);

    /**
     * @dev add new version of Metronion
     * Can only call by contract's owner
     * @param maxSupply Max supply
     * @param provenance Provenance
     */
    function addNewVersion(uint256 maxSupply, string memory provenance) external;

    /**
     * @dev Call only by owner to finalized starting index
     * @param versionId version ID should exist
     */
    function finalizeStartingIndex(uint256 versionId) external;

    /**
     * @dev return latest version of Metronion
     */
    function getLatestVersion() external view returns (uint256);

    /**
     * @dev return version config for specific versionId
     * @param versionId version id
     */
    function versionById(uint256 versionId) external view returns (Version memory version);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IMetronionNFT } from "./IMetronionNFT.sol";

interface IMetronionSale {
    struct SaleConfig {
        uint64 privateTime; // private sale start time
        uint64 publicTime; // public sale start time
        uint64 endTime; // public sale end time
    }

    struct SaleRecord {
        uint64 totalSold;
        uint64 privateSold;
        uint64 publicSold;
        uint64 ownerBought;
    }

    struct UserRecord {
        uint64 privateBought; // amount of Metronions user have bought in the private time
        uint64 publicBought; // amount of Metronions user have bought in the public time
    }

    event ReceiveETH(address from, uint256 amount);
    event PrivateBought(address indexed buyer, uint256 versionId, uint256 totalWeiPaid);
    event PublicBought(address indexed buyer, uint256 versionId, uint256 totalWeiPaid);
    event OwnerBought(address indexed buyer, uint256 versionId, uint256 totalWeiPaid);
    event WithdrawSaleFunds(address indexed recipient, uint256 amount);

    /**
     * @dev Buy an amount of Metronions
     * Maximum amount for private and public sale will be different
     * @param versionId Metronion version, starting at 0
     * @param amount amount of Metronions
     */
    function buy(uint256 versionId, uint64 amount) external payable;

    /**
     * @dev Withdraw sale funds from contract
     * Can only call by owner
     * @param recipient Address to receive funds
     * @param amount Amount of funds in wei
     */
    function withdrawSaleFunds(address payable recipient, uint256 amount) external;

    /**
     * @dev Return sale config for specific version
     * @param versionId Metronion version, starting at 0
     */
    function getSaleConfig(uint256 versionId) external view returns (SaleConfig memory config);

    /**
     * @dev Return sale record for specific version
     * @param versionId Metronion version, starting at 0
     */
    function getSaleRecord(uint256 versionId) external view returns (SaleRecord memory saleRecord);

    /**
     * @dev get user record for buy amount in private and public sale for specific version
     * @param versionId Metronion version, starting at 0
     * @param account user address
     */
    function getUserRecord(uint256 versionId, address account) external view returns (UserRecord memory UserRecord);

    /**
     * @dev return MetronionNFT contract address
     * Override with public variable
     */
    function nftContract() external view returns (IMetronionNFT);
}

//SPDX-License-Identifier: MIT

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IWhitelist } from "../interface/IWhitelist.sol";

pragma solidity ^0.8.0;

contract Whitelist is IWhitelist, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // list of whitelisted addresses, key is the versionId
    mapping(uint256 => EnumerableSet.AddressSet) internal _whitelistGroup;

    // mapping from versionId to max whitelist address
    mapping(uint256 => uint256) public maxWhitelistSize;

    constructor(uint256 _versionId, uint256 _maxWhitelistSize) {
        maxWhitelistSize[_versionId] = _maxWhitelistSize;
    }

    /**
     * @dev Update the list of whitelisted addresses for specific version
     * Can only called by owner
     * @param versionId Metronion version, starting at 0
     * @param accounts list of address need to be updated
     * @param isWhitelisted value indicates whether to add or remove from the whitelisted list
     */
    function updateWhitelistedGroup(
        uint256 versionId,
        address[] calldata accounts,
        bool isWhitelisted
    ) external override onlyOwner {
        EnumerableSet.AddressSet storage group = _whitelistGroup[versionId];
        uint256 maxSize = maxWhitelistSize[versionId];

        if (isWhitelisted) {
            require(group.length() + accounts.length <= maxSize, "Whitelist: too many addresses");
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            if (isWhitelisted && group.add(accounts[i])) {
                emit UpdateWhitelistedAddress(versionId, accounts[i], true);
            } else if (!isWhitelisted && group.remove(accounts[i])) {
                emit UpdateWhitelistedAddress(versionId, accounts[i], false);
            }
        }
    }

    /**
     * @dev return whether address is whitelisted
     * @param versionId Metronion version, starting at 0
     * @param account address need to be checked
     */
    function isWhitelistedAddress(uint256 versionId, address account) public view override returns (bool) {
        EnumerableSet.AddressSet storage group = _whitelistGroup[versionId];
        return group.contains(account);
    }

    /**
     * @dev return list of whitelisted address
     * @param versionId Metronion version, starting at 0
     */
    function getWhitelistedGroup(uint256 versionId) public view override returns (address[] memory accounts) {
        EnumerableSet.AddressSet storage group = _whitelistGroup[versionId];
        uint256 groupLength = group.length();
        accounts = new address[](groupLength);
        for (uint256 i = 0; i < groupLength; i++) {
            accounts[i] = group.at(i);
        }
    }

    /**
     * @dev return number of whitelisted address
     * @param versionId Metronion version, starting at 0
     */
    function countWhitelistedGroup(uint256 versionId) public view override returns (uint256) {
        EnumerableSet.AddressSet storage group = _whitelistGroup[versionId];
        return group.length();
    }

    /**
     * @dev update max whitelist size for specific version
     * Can only called by owner
     * @param versionId Metronion version, starting at 0
     * @param maxSize max size
     */
    function updateMaxWhitelistSize(uint256 versionId, uint256 maxSize) external onlyOwner {
        EnumerableSet.AddressSet storage group = _whitelistGroup[versionId];
        require(group.length() <= maxSize, "Whitelist: current group size is bigger then new size");
        maxWhitelistSize[versionId] = maxSize;
    }
}

//SPDX-License-Identifier: MIT

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

pragma solidity ^0.8.0;

contract TokenWithdrawable is Ownable, Pausable {
    mapping(IERC20 => bool) public whitelistTokens; // contains list of whitelist token can be withdraw

    event UpdateWhitelistToken(IERC20 token, bool isWhitelist);
    event WithdrawToken(IERC20 token, uint256 amount);

    constructor() {}

    /**
     * @dev update list of whitelist tokens. Whitelisted tokens can be withdrawn
     * can only called by the owner
     * @param listTokens list of token addresses
     * @param isWhitelist is whitelist boolean value
     */
    function updateWhitelistTokens(IERC20[] calldata listTokens, bool isWhitelist) external onlyOwner {
        for (uint256 i = 0; i < listTokens.length; i++) {
            whitelistTokens[listTokens[i]] = isWhitelist;
            emit UpdateWhitelistToken(listTokens[i], isWhitelist);
        }
    }

    /**
     * @dev check if token can be withdrawn
     * @param token token address
     */
    function isTokenWithdrawable(IERC20 token) external view returns (bool) {
        return whitelistTokens[token];
    }

    /**
     * @dev withdraw token from this contract
     * can only called by the owner
     * @param token token address to withdraw
     * @param amount amount token to withdraw
     */
    function withdrawToken(IERC20 token, uint256 amount) external whenNotPaused onlyOwner {
        require(token.balanceOf(address(this)) >= amount, "TokenWithdrawable: amount exceed balance");
        require(whitelistTokens[token] == true, "TokenWithdrawable: token is not whitelisted");
        token.transferFrom(address(this), owner(), amount);
        emit WithdrawToken(token, amount);
    }

    /**
     * @dev Call by only owner to pause the withdraw
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Call by only owner to unpause the withdraw
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWhitelist {
    event UpdateWhitelistedAddress(uint256 versionId, address account, bool isWhitelisted);

    /**
     * @dev Update the list of whitelisted addresses for specific version
     * Can only called by owner
     * @param versionId Metronion version, starting at 0
     * @param accounts list of address need to be updated
     * @param isWhitelisted value indicates whether to add or remove from the whitelisted list
     */
    function updateWhitelistedGroup(
        uint256 versionId,
        address[] calldata accounts,
        bool isWhitelisted
    ) external;

    /**
     * @dev return whether address is whitelisted
     * @param versionId Metronion version, starting at 0
     * @param account address need to be checked
     */
    function isWhitelistedAddress(uint256 versionId, address account) external view returns (bool);

    /**
     * @dev return list of whitelisted address
     * @param versionId Metronion version, starting at 0
     */
    function getWhitelistedGroup(uint256 versionId) external view returns (address[] memory accounts);

    /**
     * @dev return number of whitelisted address
     * @param versionId Metronion version, starting at 0
     */
    function countWhitelistedGroup(uint256 versionId) external view returns (uint256);

    /**
     * @dev update max whitelist size for specific version
     * Can only called by owner
     * @param versionId Metronion version, starting at 0
     * @param maxSize max size
     */
    function updateMaxWhitelistSize(uint256 versionId, uint256 maxSize) external;
}

// SPDX-License-Identifier: MIT

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
    constructor() {
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