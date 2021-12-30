pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../contracts/INumbreSeason.sol";
import "../contracts/INumbreERC721.sol";
import "../contracts/INumbreBuyProxy.sol";

contract NumbreAwardPools is INumbreSeason, Initializable{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    enum AuthType{ NONE, OWNER, ADMIN }

    event saveSeasonRecord(
        AwardRatio seasonHistory,
        uint256 seasonId,
        uint256[] tokenIds
    );

    event exchangeBonus(
        uint256 seasonId,
        uint256 tokenId,
        address winner,
        uint256 bonus
    );

    uint256 private endBlackNum;
    uint256 private seasonId;
    struct AwardRatio {
        address pool;           // Accumulate for the winner of the next period
        address dev;            // Leave it to developers for marketing
        address dao;            // DAO funds

        uint8 winnerRatio;
        uint8 poolRatio;
        uint8 devRatio;
        uint8 daoRatio;

        uint256 winnerPrize;
        uint256 poolPrize;
        uint256 devPrize;
        uint256 daoPrize;

        uint256 winnerNumber;   // Number of winners

        uint256 startBlock;   // The prize pool begins block.Number
        uint256 endBlock;   // End of prize pool block.Number
    }
    struct Winner {
        address wallet;
        bool exchange;
        uint256 prize;
    }
    mapping(uint256 => AwardRatio) seasonHistory;
    mapping(address => AuthType) owners;
    mapping(uint256 => mapping(uint256 => Winner)) winnerHistory;   // seasonId => tokenId => Winner

    uint256 public seasonBlockNum;
    address public numbreERC721Address;
    address public numbreBuyProxyAddress;
    uint256 unBonus;        // Unredeemed bonus


    modifier onlyOwner() {
        require(owners[msg.sender] == AuthType.OWNER, 'access deny');
        _;
    }

    modifier onlyAdmin() {
        require(owners[msg.sender] == AuthType.ADMIN || owners[msg.sender] == AuthType.OWNER, 'access deny');
        _;
    }

    modifier onlyBuyProxy() {
        require(msg.sender == numbreBuyProxyAddress, "access deny");
        _;
    }

    function initialize() initializer public {
        seasonId = 1;
        seasonBlockNum = 20000;
        owners[msg.sender] = AuthType.OWNER;
        endBlackNum = block.number + seasonBlockNum;
        seasonHistory[seasonId] = AwardRatio({
        pool: address(this),
        dev: address(0),
        dao: address(0),
        winnerRatio: 50,
        poolRatio: 20,
        devRatio: 20,
        daoRatio: 10,
        winnerPrize: 0,
        poolPrize: 0,
        devPrize: 0,
        daoPrize: 0,
        winnerNumber: 0,
        startBlock: block.number,
        endBlock: endBlackNum
        });
    }

    function modifyRatio(uint8 winnerRatio, uint8 poolRatio, uint8 devRatio, uint8 daoRatio) public onlyOwner {
        AwardRatio memory info = seasonHistory[seasonId];
        seasonHistory[seasonId] = AwardRatio({
        pool: info.pool,
        dev: info.dev,
        dao: info.dao,
        winnerRatio: winnerRatio,
        poolRatio: poolRatio,
        devRatio: devRatio,
        daoRatio: daoRatio,
        winnerPrize: info.winnerPrize,
        poolPrize: info.poolPrize,
        devPrize: info.devPrize,
        daoPrize: info.daoPrize,
        winnerNumber: info.winnerNumber,
        startBlock: info.startBlock,
        endBlock: info.endBlock
        });
    }

    function addRatioAddress(address dao, address dev) public onlyOwner {
        AwardRatio memory info = seasonHistory[seasonId];
        seasonHistory[seasonId] = AwardRatio({
        pool: address(this),
        dev: dev,
        dao: dao,
        winnerRatio: info.winnerRatio,
        poolRatio: info.poolRatio,
        devRatio: info.devRatio,
        daoRatio: info.daoRatio,
        winnerPrize: info.winnerPrize,
        poolPrize: info.poolPrize,
        devPrize: info.devPrize,
        daoPrize: info.daoPrize,
        winnerNumber: info.winnerNumber,
        startBlock: info.startBlock,
        endBlock: info.endBlock
        });
    }

    function addAuthority(address admin, AuthType auth) public onlyOwner {

        if(auth == AuthType.NONE){
            delete owners[admin];
        }else{
            owners[admin] = auth;
        }
    }

    function showAuthority(address admin) public view virtual returns (uint) {
        return uint(owners[admin]);
    }

    function getSeasonId() external view override returns (uint256) {
        if(endBlackNum > block.number){
            return seasonId;
        }else{
            return 0;
        }
    }

    function getRatioInfo(uint256 _seasonId) external view override returns (uint256, uint256, uint256, uint256){
        AwardRatio memory info = seasonHistory[_seasonId];
        return (info.winnerRatio, info.poolRatio, info.devRatio, info.daoRatio);
    }

    function getSeasonPrize(uint256 _seasonId) external view override returns (uint256){
        if(_seasonId == seasonId){
            return address(this).balance - unBonus;
        }
        AwardRatio memory info = seasonHistory[_seasonId];
        return info.winnerPrize + info.poolPrize + info.devPrize + info.daoPrize;
    }

    function getEndBlackNum() public view returns (uint256) {
        return endBlackNum;
    }

    function liquidationSeason() public returns (uint256) {
        require(endBlackNum < block.number, 'Season is underway');
        AwardRatio memory info = seasonHistory[seasonId];

        uint256[] memory _tokenIds = INumbreERC721(numbreERC721Address).getSeasonMaxToken(seasonId); //Get win tokenIds
        info.winnerNumber = _tokenIds.length;
        uint256 _prize = (address(this).balance - unBonus) * info.winnerRatio / 100 / info.winnerNumber;
        info.winnerPrize = _prize * info.winnerNumber;
        info.poolPrize = (address(this).balance - unBonus) * info.poolRatio / 100;
        info.devPrize = (address(this).balance - unBonus) * info.daoRatio / 100;
        info.daoPrize = address(this).balance - unBonus - info.winnerPrize - info.poolPrize - info.devPrize;

        unBonus += info.winnerPrize;

        seasonHistory[seasonId] = AwardRatio({
        pool: info.pool,
        dev: info.dev,
        dao: info.dao,
        winnerRatio: info.winnerRatio,
        poolRatio: info.poolRatio,
        devRatio: info.devRatio,
        daoRatio: info.daoRatio,
        winnerPrize: info.winnerPrize,
        poolPrize: info.poolPrize,
        devPrize: info.devPrize,
        daoPrize: info.daoPrize,
        winnerNumber: info.winnerNumber,
        startBlock: info.startBlock,
        endBlock: info.endBlock
        });

        for(uint256 i = 0; i < info.winnerNumber; i++){
            winnerHistory[seasonId][_tokenIds[i]] = Winner({
            wallet: address(0),
            exchange: false,
            prize: _prize
            });
        }

        emit saveSeasonRecord(seasonHistory[seasonId], seasonId, _tokenIds);

        payable(info.dev).transfer(info.devPrize);
        payable(info.dao).transfer(info.daoPrize);

        seasonId += 1;
        endBlackNum = block.number + 1 + seasonBlockNum;

        seasonHistory[seasonId] = AwardRatio({
        pool: info.pool,
        dev: info.dev,
        dao: info.dao,
        winnerRatio: info.winnerRatio,
        poolRatio: info.poolRatio,
        devRatio: info.devRatio,
        daoRatio: info.daoRatio,
        winnerPrize: 0,
        poolPrize: 0,
        devPrize: 0,
        daoPrize: 0,
        winnerNumber: 0,
        startBlock: block.number + 1,
        endBlock: endBlackNum
        });

        INumbreBuyProxy(numbreBuyProxyAddress).newSeason();
        return seasonId;
    }

    function receiveAward(uint256 _tokenId, uint256 _seasonId) external returns (uint256){

        require(_seasonId > 0, 'Not awarded');

        Winner memory info = winnerHistory[_seasonId][_tokenId];
        require( !info.exchange, 'Bonus has been redeemed');

        address winner = INumbreERC721(numbreERC721Address).numbreOwnerOf(_tokenId); //Get winner address
        require(msg.sender == winner, 'Not a recipient');

        payable(winner).transfer(info.prize);

        winnerHistory[_seasonId][_tokenId] = Winner({
        wallet: winner,
        exchange: true,
        prize: info.prize
        });

        unBonus -= info.prize;

        emit exchangeBonus(_seasonId, _tokenId, winner, info.prize);

        return info.prize;
    }

    function setBuyProxyAddress(address newAddress) external onlyAdmin {
        numbreBuyProxyAddress = newAddress;
    }

    function setERC721Address(address newAddress) external onlyAdmin {
        numbreERC721Address = newAddress;
    }

    function resetEndBlockNum() external onlyAdmin {
        endBlackNum = block.number + seasonBlockNum;
    }

    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

pragma solidity ^0.8.0;

interface INumbreSeason {
    function getSeasonId() external view returns (uint256);
    function getSeasonPrize(uint256 _seasonId) external view returns (uint256);
    function getRatioInfo(uint256 _seasonId) external view returns (uint256, uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INumbreERC721 {
    function getPieceInfo(uint256 tokenId) external view returns (uint256 level, uint256 x, uint256 y, address user, uint256 seasonId);

    function updatePieceInfo(uint256 tokenId, uint256 level, uint256 x, uint256 y, uint256 _type) external;

    function mint(address user, uint256 seasonId) external returns (uint256);

    function getSeasonMaxToken(uint256 seasonId) external view returns (uint256[] memory tokenIds);

    function numbreOwnerOf(uint256 tokenId) external view returns (address user);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INumbreBuyProxy {
    function newSeason() external;
}