// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IXBox.sol";
import "../Common/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract XBoxMinter is AccessControl {
    // xBox interface
    IXBox public xBox;
    // xMeta interface
    IERC20 public xMeta;

    enum RoundStatus {_isZero, Open, Paused, SoldAll, SoldOver}

    struct Round {
        string      name;
        uint        price; 
        uint        saleAmount;
        uint        soldAmount;
        uint        xMetaHoldLimit;     // xMeta hold limit
        uint64      round;              // round
        uint64      singleBuyMaxLimit;  // single buy max limit
        uint64      singleOnceBuyLimit;  // single once buy max limit
        uint64      startTime;   
        uint64      endTime;
        RoundStatus status;             // round status : 1 open, 2 paused, 3 sold all 4 sold over
        bool        whiteListOpen;      // whether open whitelist
        string      tokenURI;
    }

    mapping(string => uint) public totalSale;
    mapping(string => uint) public totalSold;

    // current round name:round
    mapping(string => Round) private currentRound;
    // history rounds name:rounds
    mapping(string => Round[]) private historyRounds;
    // mapping for round owner count, name : round : owner : count
    mapping(string =>  mapping(uint64 => mapping(address => uint64))) private _roundOwnerCount;


    /** 
     * @dev set xms contract address.
     */
    constructor(address cfo, address coo, address withdrawAddr, address xBoxAddr) AccessControl(cfo, coo, withdrawAddr) {
        xBox = IXBox(xBoxAddr);
    }
    
    function kill() public isCEO {
        payable(withdrawAddress).transfer(address(this).balance);
        selfdestruct(payable(ceoAddress));
    }

    receive() external payable {}
   


    modifier roundRunning(string memory name) {
        require(currentRound[name].round > 0, "not on sale");
        require(currentRound[name].status == RoundStatus.Open, "not on sale");
        require(currentRound[name].startTime <= uint64(block.timestamp), "this round has not started");
        require(currentRound[name].endTime >= uint64(block.timestamp), "this round end of sale");
        _;
    }

    function setxMetaAddress(address xMetaAddress) external isCEO {
        require(xMetaAddress != address(0), "should be available address");
        xMeta = IERC20(xMetaAddress);
    }

    function withdrawxMeta() external isCFO {
        SafeERC20.safeTransferFrom(xMeta, address(this), withdrawAddress, xMeta.balanceOf(address(this)));
    }

    function startNewRound(string memory name, uint64 rd, uint price, uint saleAmount, uint xMetaHoldLimit, uint64 singleBuyMaxLimit, uint64 singleOnceBuyLimit, 
        uint64 startTime, uint64 endTime, bool whiteListOpen, string memory tokenURI) external isCEO {

        if (xMetaHoldLimit > 0) {
            require (address(xMeta) != address(0), "should be config xMeta address");
        }
        require (currentRound[name].round < rd, "round error");
        require (price > 0, "should be right price");
        require (saleAmount > 0, "should be right saleAmount");
        require (startTime > 0, "should be right startTime");
        require (endTime > startTime, "should be right endTime");

        if (currentRound[name].round > 0) {
            currentRound[name].status = RoundStatus.SoldOver;
            historyRounds[name].push(currentRound[name]);
        }
        Round memory round = Round({name:name, round:rd, price:price, saleAmount:saleAmount, soldAmount:0, xMetaHoldLimit:xMetaHoldLimit, singleBuyMaxLimit:singleBuyMaxLimit, 
            singleOnceBuyLimit:singleOnceBuyLimit, startTime:startTime, endTime:endTime, status:RoundStatus.Open, whiteListOpen:whiteListOpen, tokenURI:tokenURI});
        currentRound[name] = round;
        totalSale[name] = totalSale[name] + saleAmount;
    }

    function updateThisRound(string memory name, uint64 endTime, RoundStatus status, uint xMetaHoldLimit, uint64 singleBuyMaxLimit, uint64 singleOnceBuyLimit) external isCEO {
        require(currentRound[name].round > 0, "no round");
        require(currentRound[name].status == RoundStatus.Open || currentRound[name].status == RoundStatus.Paused, "not on sale");
        if (endTime > 0) {
            currentRound[name].endTime = endTime;
        }
        currentRound[name].status = status;
        currentRound[name].xMetaHoldLimit = xMetaHoldLimit;
        currentRound[name].singleBuyMaxLimit = singleBuyMaxLimit;
        currentRound[name].singleOnceBuyLimit = singleOnceBuyLimit;
    }

    function pasueThisRound(string memory name) external isCEO roundRunning(name) {
        currentRound[name].status = RoundStatus.Paused;
    }

    function unPasueThisRound(string memory name) external isCEO {
        require(currentRound[name].status == RoundStatus.Paused, "not paused");
        currentRound[name].status = RoundStatus.Open;
    }

    function getCurrentRound(string memory name) public view returns (Round memory) {
        return currentRound[name];
    }

    function getHistoryRounds(string memory name) public view returns (Round[] memory) {
        return historyRounds[name];
    }

    function getRoundOwnerCount(string memory name, uint64 round, address owner) public view returns (uint64) {
        return _roundOwnerCount[name][round][owner];
    }

    function mintBoxes(address player, string memory name, uint64 amount) public isCOO roundRunning(name) returns (uint[] memory) {
        require(currentRound[name].saleAmount - currentRound[name].soldAmount >= amount, "insufficient quantity remaining");
        if (currentRound[name].singleOnceBuyLimit > 0) {
            require(amount <= currentRound[name].singleOnceBuyLimit, "purchase quantity once exceeds limit");
        }
        if (currentRound[name].singleBuyMaxLimit > 0) {
            uint64 count = _roundOwnerCount[name][currentRound[name].round][player];
            require(count + amount <= currentRound[name].singleBuyMaxLimit, "purchase quantity exceeds limit");
        }
        if (currentRound[name].xMetaHoldLimit > 0) {
            require (xMeta.balanceOf(player) >= currentRound[name].xMetaHoldLimit, "should be hold enough XMeta");
        }

        currentRound[name].soldAmount += amount;
        totalSold[name] = totalSold[name] + amount;
        if (currentRound[name].saleAmount == currentRound[name].soldAmount) {
            currentRound[name].status = RoundStatus.SoldAll;
        }
        _roundOwnerCount[name][currentRound[name].round][player] += amount;

        uint[] memory tokenIds = xBox.mintBatch(player, currentRound[name].round, name, amount, currentRound[name].tokenURI);

        return tokenIds;
    }
}

// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";

contract AccessControl is Pausable {

    address internal ceoAddress;
    address internal cfoAddress;
    address internal cooAddress;
    address internal withdrawAddress;

    // invokers
    mapping(address => bool) internal _signers;
    // requestIds
    mapping(uint256 => bool) internal _requestIds;

    constructor(address cfo, address coo, address withdrawAddr) {
        ceoAddress = msg.sender;
        cfoAddress = cfo;
        cooAddress = coo;
        withdrawAddress = withdrawAddr;
    }

    modifier isCEO() {
        require(msg.sender == ceoAddress, "only CEO");
        _;
    }

    modifier isCFO() {
        require(msg.sender == cfoAddress, "only CFO");
        _;
    }

    modifier isCOO() {
        require(msg.sender == cooAddress, "only COO");
        _;
    }

    modifier isCLevel() {
       require(
            // solium-disable operator-whitespace
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == cooAddress
            // solium-enable operator-whitespace
            ,"only CLevel"
        );
        _;
    }

    // modifier to check if caller is invoker
    modifier isInvoker() {
        require(_signers[msg.sender], "caller is not invoker");
        _;
    }

    // modifier to check if first request
    modifier authRequest(uint256 requestId) {
        require(requestId > 0, "invalid request");
        require(_requestIds[requestId] == false, "invalid request");
        _;
    }

    function setCEO(address _newCEO) external isCEO {
        require(_newCEO != address(0), "newCEO Address can not be 0");
        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) external isCEO {
        cfoAddress = _newCFO;
    }

    function setCOO(address _newCOO) external isCEO {
        cooAddress = _newCOO;
    }

    function setWithdrawAddress(address _newAddr) external isCFO {
        withdrawAddress = _newAddr;
    }

    function withdrawBalance() external isCFO {
        payable(withdrawAddress).transfer(address(this).balance);
    }

    function getCEO() public view returns (address) {
        return ceoAddress;
    }

    function getCFO() public view returns (address) {
        return cfoAddress;
    }

    function getCOO() public view returns (address) {
        return cooAddress;
    }

    function getWithdrawAddress() public view returns (address) {
        return withdrawAddress;
    }

    function checkBalance() external view returns(uint) {
        return address(this).balance;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external isCEO whenNotPaused {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external isCEO whenPaused {
        _unpause();
    }

    /**
     * @dev set signer
     * @param _signer of new signer address
     */
    function setSigner(address _signer) public isCEO {
        require(_signer != address(0), "should be available address");
        _signers[_signer] = true;
    }

    /**
     * @dev resign signer
     * @param _signer of exist signer address
     */
    function resignSigner(address _signer) public isCEO {
        require(_signer != address(0), "should be available address");
        require(_signers[_signer], "the address already not signer");
        _signers[_signer] = false;
    }

    /**
     * @dev Return whether signer or not 
     * @return whether is signer or not
     */
    function checkSigner(address addr) external view returns (bool) {
        return _signers[addr];
    }
}

// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

enum BoxStatus {_isZero, UnOpen, Opened}

interface IXBox is IERC721Enumerable {
    function mint(address player, uint64 round, string memory name, string memory tokenURI) external returns (uint256);
    function mintBatch(address player, uint64 round, string memory name, uint64 count, string memory tokenURI) external returns (uint256[] memory);
    function statusFetch(uint256[] memory tokenIds) external view returns (BoxStatus[] memory);
    function statusUpdate(uint256[] memory tokenIds, BoxStatus[] memory statuses) external returns (bool);
    function safeTransferBatchFrom(address from, address to, uint256[] memory tokenIds, bytes memory _data) external;
    function exist(uint256 tokenId) external view returns (bool);
    function existAll(uint256[] memory tokenIds) external view returns (bool);
    function checkOwner(address owner, uint256[] memory tokenIds) external view returns (bool);
    function filterOwnerTokenStatuses(address owner, uint256[] memory tokenIds) external view returns (uint256[] memory ids, BoxStatus[] memory statuses);
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getRoundOwnerCount(uint64 round, address owner) external returns (uint64);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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