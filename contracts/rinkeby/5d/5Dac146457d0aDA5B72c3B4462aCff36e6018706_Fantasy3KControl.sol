// contracts/F3kControl.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IF3K1155.sol";
import "./IF3K721.sol";

contract Fantasy3KControl is ReentrancyGuard, Ownable {
    using Address for address;
    event BlindBoxPriceChanged(uint256 _epicBoxPrice, uint256 _LegendBoxPrice);
    event SaleConfigChanged (uint256 round, uint256 start, uint256 end, uint256 number, uint256 epicNumber, uint256 epicBoxPrice, uint256 legendNumber, uint256 legendBoxPrice);
    event AddWhiteList(address[] whitelist);
    event WhiteBlindBox(address to);
    event EpicBlindBox(address to);
    event LegendBlindBox(address to);
    event PayeeAdded(address account, uint256 shares_);
    event PaymentReceived(address account, uint256 amount);
    event OpenBlindBox(uint256 id);
    event MintTokens(address to, uint256 count, uint256 mtype);

    struct SaleConfig {
        uint256 round;
        uint256 startTime;
        uint256 endTime;
        uint256 whiteNumber;
        uint256 epicNumber;
        uint256 epicBoxPrice;
        uint256 legendNumber;
        uint256 legendBoxPrice;
        uint256 whiteBoxPrice;
    }

    struct BoxIdx {
        uint256 _id;
        address _address;
        uint256 _round;
        uint32  _amount;
        uint256 _height;
    }

    struct OpenBoxIdx {
        uint256 _burnId;
        uint256 _start;
        uint256 _end;
        uint256 _height;
    }
    
    uint256 public immutable whiteListPrice = 0.05 ether; 
    uint256 public boxLength;
    uint256 public openboxLength;
    F3K721 private f3k721;
    F3K1155 private f3k1155;

    mapping (address => bool) public whiteList;
    mapping (address => bool) private top10List;
    mapping (uint256 => BoxIdx) boxIdxs;
    mapping (uint256 => OpenBoxIdx) openBoxIdxs;

    address public f3kVault;
    SaleConfig public saleConfig;

    constructor(
        address _f3k721,
        address _f3k1155,
        address _f3kVault
    ) {
        f3k721 = F3K721(_f3k721);
        f3k1155 = F3K1155(_f3k1155);
        f3kVault = _f3kVault;
    }

    function setBaseURI(string calldata newbaseURI) external onlyOwner {
        f3k721.setBaseURI(newbaseURI);
    }

    function addWhiteList(address[] memory whitelist) public onlyOwner {

        require(whitelist.length == 50, "Fantasy3K: incorrect whiteList length");

        for (uint64 i; i < whitelist.length; i++){
            if (i < 10) {
               top10List[whitelist[i]] = true;
            }else{
               whiteList[whitelist[i]] = true;
            }
        }

        emit AddWhiteList(whitelist);
    }

    function whiteListAirDrop(address[] memory whitelist, uint32[] memory number) public onlyOwner {

        require(whitelist.length == 50, "Fantasy3K: incorrect whiteList airdrop length");
        require(whitelist.length == number.length, "Fantasy3K: incorrect whiteList or number length");

        for (uint64 i; i < whitelist.length; i++){
            if (number[i] >1) {
                require(top10List[whitelist[i]] == true, "Fantasy3K: not top10List address");
                boxUpdate(f3k1155.nextTokenId(), whitelist[i], 0, 6);
                f3k1155.mint(whitelist[i], 6);
            } else {
                require(whiteList[whitelist[i]] == true, "Fantasy3K: not whitelist address");
                f3k721.mintTokens(whitelist[i], 1);
            }
        }
    }

    function whiteBlindBox() public payable {
        SaleConfig memory _saleConfig = saleConfig;

        //require(_saleConfig.round  == 0, "Fantasy3K: whiteBlindBox sold has end");
        require(_saleConfig.whiteNumber  > 0, "Fantasy3K: whiteBlindBox has sold out");
        require(whiteListPrice == msg.value, "Fantasy3K: incorrect Ether value");
        require(whiteList[msg.sender] == true, "Fantasy3K: not whitelist address");
        require(block.timestamp < _saleConfig.endTime, "Fantasy3K: whitelist sale is end"); 

        boxUpdate(f3k1155.nextTokenId(), msg.sender, 0, 6);

        saleConfig.whiteNumber -= 1;

        f3k1155.mint(msg.sender, 6);
        whiteList[msg.sender] = false;
        emit WhiteBlindBox(msg.sender);
    }

    function epicBlindBox() public payable {
        SaleConfig memory _saleConfig = saleConfig;

        require(_saleConfig.round  > 0, "Fantasy3K: epicBlindBox has not started");
        require(_saleConfig.epicBoxPrice == msg.value, "Fantasy3K: incorrect Ether value");
        require(_saleConfig.epicNumber  > 0, "Fantasy3K: epicBlindBox has sold out");
        require(block.timestamp >= _saleConfig.startTime, "Fantasy3K: sale not started");
        require(block.timestamp < _saleConfig.endTime, "Fantasy3K: sale is end");
        require(!msg.sender.isContract(), "Fantasy3K: caller can't be a contract");

        saleConfig.epicNumber -= 1;

        boxUpdate(f3k1155.nextTokenId(), msg.sender, _saleConfig.round, 5);

        f3k1155.mint(msg.sender, 5);

        emit EpicBlindBox(msg.sender);      
    }

    function legendBlindBox() public payable {
        SaleConfig memory _saleConfig = saleConfig;

        require(_saleConfig.round  > 0, "Fantasy3K: legendBlindBox has not started");
        require(_saleConfig.legendBoxPrice == msg.value, "Fantasy3K: incorrect Ether value");
        require(_saleConfig.legendNumber > 0, "Fantasy3K: legendBlindBox has sold out");
        require(block.timestamp >= _saleConfig.startTime, "Fantasy3K: sale not started");
        require(block.timestamp < _saleConfig.endTime, "Fantasy3K: sale is end");
        require(!msg.sender.isContract(), "Fantasy3K: caller can't be a contract");

        saleConfig.legendNumber -= 1;
        boxUpdate(f3k1155.nextTokenId(), msg.sender, _saleConfig.round, 50);

        f3k1155.mint(msg.sender, 50);
        emit LegendBlindBox(msg.sender);
    }


    function openBlindBox(uint256 id) public {
        require(f3k1155.balanceOf(msg.sender, id) > 0, "Doesn't own the token"); 
        uint256 fromBalance = f3k1155.balanceOf(msg.sender, id);

        f3k1155.burnToken(msg.sender, id, fromBalance);

        nftUpdate(id, f3k721.nextTokenId(), f3k721.nextTokenId() + fromBalance);

        f3k721.mintTokens(msg.sender, fromBalance); 
        emit OpenBlindBox(id);
    }

    function mintTokens(address to, uint256 count, uint256 mtype) public onlyOwner {
    
        if (mtype == 1155){
            f3k1155.mint(to, count);
        }else if (mtype == 721) {
            f3k721.mintTokens(to, count);
        }
        emit MintTokens(to, count, mtype);
    }

    function nftUpdate(uint256 burnId, uint256 start, uint256 end) private {
        uint256 _openBoxLength = openboxLength;

        openBoxIdxs[_openBoxLength] = OpenBoxIdx({
            _burnId: burnId, 
            _start: start, 
            _end: end, 
            _height: block.number});

        openboxLength++;
    }

    function boxUpdate(uint256 id, address to, uint256 round, uint32 amount) private {
        uint256 _boxLength = boxLength;

        boxIdxs[_boxLength] = BoxIdx({
            _id: id, 
            _address: to, 
            _round: round, 
            _amount: amount,
            _height: block.number});

        boxLength += 1;

    }

    function getBoxMap(uint256 index) public view returns(uint256 id, address addr, uint256 round, uint32 amount, uint256 height){
        BoxIdx memory b = boxIdxs[index];
        return (b._id, b._address, b._round, b._amount, b._height);
    }

    function getOpenBoxMap(uint256 index) public view returns(uint256 burnId, uint256 start, uint256 end, uint256 height){
        OpenBoxIdx memory b = openBoxIdxs[index];
        return (b._burnId, b._start, b._end, b._height);
    }

    function setUpSale(
        uint256 round, 
        uint256 start, 
        uint256 end, 
        uint256 whiteNumber, 
        uint256 epicNumber, 
        uint256 epicBoxPrice,
        uint256 legendNumber,
        uint256 legendBoxPrice
    ) external onlyOwner {
        uint256 _round = round;
        uint256 _startTime = start;
        uint256 _endTime = end;
        uint256 _whiteNumber = whiteNumber;
        uint256 _epicNumber = epicNumber;
        uint256 _epicBoxPrice = epicBoxPrice;
        uint256 _legendNumber = legendNumber;
        uint256 _legendBoxPrice = legendBoxPrice;

        require(_round > 0 && _whiteNumber > 0 && _epicNumber > 0 && _legendNumber > 0, "Fantasy3k: zero amount");
        require(start > 0 && _endTime > _startTime, "Fantasy3k: invalid time range");

        saleConfig = SaleConfig({
            round: _round,
            startTime: _startTime,
            endTime: _endTime,
            whiteNumber: _whiteNumber,
            epicNumber: _epicNumber,
            epicBoxPrice: _epicBoxPrice,
            legendNumber: _legendNumber,
            legendBoxPrice: _legendBoxPrice,
            whiteBoxPrice: whiteListPrice
        });

        emit SaleConfigChanged(_round, _startTime, _endTime, _whiteNumber, _epicNumber, _epicBoxPrice, _legendNumber, _legendBoxPrice);
    }

    function setF3K721Contract(address _f3k721New) external onlyOwner {
        f3k721 = F3K721(_f3k721New);
    }

    function setF3K1155Contract(address _f3k1155New) external onlyOwner {
        f3k1155 = F3K1155(_f3k1155New);
    }

    function setVaultAddress(address _f3k1155New) external onlyOwner {
        f3k1155 = F3K1155(_f3k1155New);
    }

    // add vault address
    function withdraw() nonReentrant external {
        Address.sendValue(payable(f3kVault), address(this).balance);
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// contracts/F3K721.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface F3K1155 {
    function mint(address to, uint256 amountToMint) external;

    function nextTokenId() external view returns (uint256);
    
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function burnToken(address account, uint256 id, uint256 value) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

// contracts/F3K721.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface F3K721 {
    function mintTokens(address to, uint256 count) external;

    function setBaseURI(string calldata newbaseURI) external;

    function nextTokenId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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