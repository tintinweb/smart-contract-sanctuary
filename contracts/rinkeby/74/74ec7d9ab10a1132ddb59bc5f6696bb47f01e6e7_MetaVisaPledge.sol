/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

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

library OrderSet {
    struct Order {
        uint256 createTime;
        uint256 tokenId;
    }

    struct Set {
        Order[] _values;
        // id => index
        mapping (uint256 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Set storage set, Order memory value) internal returns (bool) {
        if (!contains(set, value.tokenId)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value.tokenId] = set._values.length;
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
    function remove(Set storage set, Order memory value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value.tokenId];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            
            Order memory lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue.tokenId] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value.tokenId];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Set storage set, uint256 valueId) internal view returns (bool) {
        return set._indexes[valueId] != 0;
    }

    function at(Set storage set, uint256 index) internal view returns (Order memory) {
        require(set._values.length > index, "OrderSet: index out of bounds");
        return set._values[index];
    }

    function idAt(Set storage set, uint256 valueId) internal view returns (Order memory) {
        require(set._indexes[valueId] != 0, "OrderSet: set._indexes[valueId] != 0");
        uint index = set._indexes[valueId] - 1;
        require(set._values.length > index, "OrderSet: index out of bounds");
        return set._values[index];
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }
}

contract MetaVisaPledge is Ownable,IERC721Receiver {
    using OrderSet for OrderSet.Set;

    mapping(address => OrderSet.Set) private _metavisaOrderOf; // user metavisa orders
    mapping(address => OrderSet.Set) private _metavisaLimitOrderOf; // user metavisaLimit orders
    mapping(address => uint256) private _income; //user pledge income
    mapping(address => uint256) private _limitIncome; //user pledge limit income

    //IERC721[2] public  _nftAddress; //the supported NTF contract
    IERC721 public immutable NFT;
    IERC721 public immutable NFTLimit;
 
    uint256[] private _allIncomes; // Issue income array daily
    uint256[] private _allLimitIncomes; // Issue income array daily

    uint256 public _continuousDays = 5 * 30 minutes; //continuous days
    uint256 public _period  = 5 minutes;  //cycle
    uint256 public _fixedDailyReward = 166.666666 * 10**6; //Fixed gross income is paid on a daily basis
    uint256 public _fixedDailyRewardLimit = 200 * 10 **6; //Fixed gross income is paid on a daily basis
    uint256 public _startTime;
    uint256 public totalOrder;
    uint256 public totalLimitOrder;

    event Pledge(address indexed NTF,address indexed account, uint256 indexed tokenId ,uint256 createTime);
    event CancelPledge(address indexed NTF,address indexed account, uint256 indexed tokenId ,uint256 createTime);
 

    /**
     * @dev Initializes the contract by setting tow nftAddress and startTime.
     */
    constructor(IERC721 NFT_,IERC721 NFTLimit_,uint256 startTime_) {
        require(block.timestamp<startTime_, "MetaVisaPledge:The start time must be greater than the current time");
        _startTime = startTime_;
        NFT = NFT_;
        NFTLimit = NFTLimit_;
    }

    /**
     * @dev Activity time must end before operation.
     */
    modifier onlyTimeEnd() {
        require(block.timestamp > _startTime + _continuousDays, "MetaVisaPledge:Time is not over");
        _;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata ) external override returns (bytes4) {
        require(block.timestamp>=_startTime && block.timestamp <= _startTime + _continuousDays, "MetaVisaPledge: Not at the");
        require(operator == from, "MetaVisaPledge:The caller must be the owner of the NFT");
        if(address(NFT) == msg.sender){
            _pledgeMVC(tokenId,from);
        }else if(address(NFTLimit) == msg.sender){
            _pledgeMVCLimit(tokenId,from);
        }
        return this.onERC721Received.selector;
    }

    /**
     * @dev metavisa pledge.
     */
    function _pledgeMVC(uint256 tokenId,address account) private returns(bool) {
        checkUpdateIncomes(_allIncomes,totalOrder,_fixedDailyReward);

        OrderSet.Order memory order = _createOrder(tokenId);
        _metavisaOrderOf[account].add(order);
        //_metavisaOrderOf[address(0)].add(order);
        totalOrder++;
       
        emit Pledge(msg.sender,account,tokenId,block.timestamp);
        return true;
    }

    /**
     * @dev Check if any benefits are issued
     */
    function checkUpdateIncomes(uint256[] storage allIncomes,uint256 totalOrder_, uint256 fixedDailyReward) private returns(bool) {
        uint256 theoryNum = (block.timestamp - _startTime) / _period;
        uint256 maxNum =_continuousDays / _period;
            if(theoryNum>maxNum){
                theoryNum = maxNum;
            }
        if(theoryNum > allIncomes.length){
            uint256 income;
            if(totalOrder_ > 0){
                    income = fixedDailyReward / totalOrder_;
            }
            updateIncomes(allIncomes,income,theoryNum - allIncomes.length);
        }
        return true;
    }

    /**
     * @dev update incomes                                               m 
     */
    function updateIncomes(uint256[] storage allIncomes,uint256 income,uint256 num) private returns(bool) {
        for(uint256 i = 0;i<num;i++){
            allIncomes.push(income);
        }
        return true;
    }

    /**
     * @dev cancel metavisa pledge
     */
    function cancelPledgeMVC(uint256 tokenId) external virtual returns(bool) {
        require(_metavisaOrderOf[msg.sender].length() > 0, "cancelPledgeMVC: pledge of token that is not own");
        require(_metavisaLimitOrderOf[msg.sender].length() < _metavisaOrderOf[msg.sender].length(), "cancelPledgeMVC: One NTF must be pledged for each limited NTF pledged");

        OrderSet.Order memory order = _metavisaOrderOf[msg.sender].idAt(tokenId);
        checkUpdateIncomes(_allIncomes,totalOrder,_fixedDailyReward);

        uint256 income = _calcIncome(order.createTime,_allIncomes);
        _income[msg.sender] += income;

        _metavisaOrderOf[msg.sender].remove(order);
        //_metavisaOrderOf[address(0)].remove(order);
        totalOrder--;
  
        IERC721(NFT).safeTransferFrom(address(this),msg.sender,tokenId); 

        emit CancelPledge(address(NFT),msg.sender,tokenId,block.timestamp); 
        return true;
    }

    /**
     * @dev Proceeds are calculated according to the time of pledge
     */
    function _calcIncome(uint256 createTime,uint256[] memory allIncomes) private view returns(uint256) {
        uint256 income;
        if(createTime<_startTime){
            return income;
        }
        uint256 num = (createTime - _startTime) / _period;
        for(num;num<allIncomes.length;num++){
            income += allIncomes[num];
        }
        return income;
    }

    /**
     * @dev create pledge order
     */
    function _createOrder(uint256 tokenId) private view returns(OrderSet.Order memory order) {
        order.createTime = block.timestamp;
        order.tokenId = tokenId;
    }

    /**
     * @dev Returns the number of earnings in ``user``'s account.
     */
    function getIncome(address account) public view virtual returns(uint256) {
        require(account != address(0), "getIncome: income query for the zero address");
        if(_metavisaOrderOf[account].length() == 0){
            return _income[account];
        }
        uint256 sumIncome;
        OrderSet.Order[] memory orders = getMetavisaOrders(account,0,_metavisaOrderOf[account].length());
        for(uint256 i = 0;i<orders.length;i++){
            if(orders[i].createTime<_startTime){
                continue;
            }
            uint256 num = (orders[i].createTime - _startTime) / _period;
            for(num;num<_allIncomes.length;num++) {
                sumIncome += _allIncomes[num];
            }
            uint256 theoryNum = (block.timestamp - _startTime) / _period;
            uint256 maxNum =_continuousDays / _period;
            if(theoryNum>maxNum){
                theoryNum = maxNum;
            }
            uint256 incomes = _fixedDailyReward / totalOrder;
            sumIncome +=  incomes*(theoryNum -_allIncomes.length);
        }
        return _income[account]+sumIncome;
    }

    /**
     * @dev get '_account' pledge by page_metavisaOrderOf
     */
    function getMetavisaOrders(address account, uint256 _index, uint256 _offset) public view returns (OrderSet.Order[] memory orders) {
        uint256 totalSize = getMetavisaOrdersNum(account);
        require(0 < totalSize && totalSize > _index, "getAccountOrders: 0 < totalSize && totalSize > _index");
        uint256 offset = _offset;
        if (totalSize < _index + offset) {
            offset = totalSize - _index;
        }

        orders = new OrderSet.Order[](offset);
        for (uint256 i = 0; i < offset; i++) {
            orders[i] = _metavisaOrderOf[account].at(_index + i);
        }
    }

    /**
     * @dev get '_account' pledge orders num
     */
    function getMetavisaOrdersNum(address account) public view returns (uint256 totalSize) {
        totalSize = _metavisaOrderOf[account].length();
    }

    ///////////////////////////////////////////metavisaLimit////////////////////////////////////////////
    
    function _pledgeMVCLimit(uint256 tokenId,address account) private returns(bool) {
        require(_metavisaLimitOrderOf[account].length() < _metavisaOrderOf[account].length(), "_pledgeMVCLimit: One NTF must be pledged for each limited NTF pledged");

        checkUpdateIncomes(_allLimitIncomes,totalLimitOrder,_fixedDailyRewardLimit);

        OrderSet.Order memory order = _createOrder(tokenId);
        _metavisaLimitOrderOf[account].add(order);
        //_metavisaLimitOrderOf[address(0)].add(order);
        totalLimitOrder++;

        emit Pledge(msg.sender,account,tokenId,block.timestamp);
        return true;
    }

    /**
     * @dev cancel limit metavisa pledge
     */
    function cancelPledgeMVCLimit(uint256 tokenId) external virtual returns(bool) {
        require(_metavisaLimitOrderOf[msg.sender].length() > 0, "cancelPledgeMVC: pledge of token that is not own");
        OrderSet.Order memory order = _metavisaLimitOrderOf[msg.sender].idAt(tokenId);
        checkUpdateIncomes(_allLimitIncomes,totalLimitOrder,_fixedDailyReward);

        uint256 income = _calcIncome(order.createTime,_allLimitIncomes);
        _limitIncome[msg.sender] += income;

        _metavisaLimitOrderOf[msg.sender].remove(order);
        //_metavisaLimitOrderOf[address(0)].remove(order);
        totalLimitOrder--;
 
        IERC721(NFTLimit).safeTransferFrom(address(this),msg.sender,tokenId); 

        emit CancelPledge(address(NFTLimit),msg.sender,tokenId,block.timestamp);  
        return true;
    }

    /**
     * @dev Returns the number of earnings in ``user``'s account.
     */
    function getIncomeLimit(address account) public view virtual returns(uint256) {
        require(account != address(0), "MetaVisaPledge: income query for the zero address");
        if(_metavisaLimitOrderOf[account].length() == 0){
            return _limitIncome[account];
        }
        uint256 sumIncome;
        OrderSet.Order[] memory orders = getMetavisaLimitOrders(account,0,_metavisaLimitOrderOf[account].length());
        for(uint256 i = 0;i<orders.length;i++){
            if(orders[i].createTime<_startTime){
                continue;
            }
            uint256 num = (orders[i].createTime - _startTime) / _period;
            for(num;num<_allLimitIncomes.length;num++) {
                sumIncome += _allLimitIncomes[num];
            }
            uint256 theoryNum = (block.timestamp - _startTime) / _period;
            uint256 maxNum =_continuousDays / _period;
            if(theoryNum>maxNum){
                theoryNum = maxNum;
            }
            uint256 incomes = _fixedDailyRewardLimit / totalLimitOrder;
            sumIncome +=  incomes*(theoryNum -_allLimitIncomes.length);
        }
        return _limitIncome[account]+sumIncome;
    }

    function getMetavisaLimitOrders(address account, uint256 _index, uint256 _offset) public view returns (OrderSet.Order[] memory orders) {
        uint256 totalSize = getMetavisaLimitOrdersNum(account);
        require(0 < totalSize && totalSize > _index, "getMetavisaLimitOrders: 0 < totalSize && totalSize > _index");
        uint256 offset = _offset;
        if (totalSize < _index + offset) {
            offset = totalSize - _index;
        }

        orders = new OrderSet.Order[](offset);
        for (uint256 i = 0; i < offset; i++) {
            orders[i] = _metavisaLimitOrderOf[account].at(_index + i);
        }
    }

    function getMetavisaLimitOrdersNum(address account) public view returns (uint256 totalSize) {
        totalSize = _metavisaLimitOrderOf[account].length();
    }

    ///////////////////////////////////////////onlyOwner////////////////////////////////////////////

    function setNextRound(uint256 startTime_,uint256 continuousDays_,uint256 period_,uint256 fixedDailyReward_,uint256 fixedDailyRewardLimit_) external onlyOwner onlyTimeEnd returns(bool) {
        require(block.timestamp<startTime_, "MetaVisaPledge:The start time must be greater than the current time");
        _startTime = startTime_;
        _continuousDays = continuousDays_ * 1 hours;
        _period = period_ * 1 hours;
        _fixedDailyReward = fixedDailyReward_;
        _fixedDailyRewardLimit = fixedDailyRewardLimit_;
        delete _allIncomes;
        delete _allLimitIncomes;
        totalOrder = 0;
        totalLimitOrder = 0;
        return true;
    }
}