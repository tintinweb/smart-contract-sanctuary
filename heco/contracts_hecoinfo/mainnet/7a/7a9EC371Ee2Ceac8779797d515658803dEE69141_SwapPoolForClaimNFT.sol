/**
 *Submitted for verification at hecoinfo.com on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;
pragma experimental ABIEncoderV2;
library EnumerableSet {
    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex;
                // Replace lastValue's index to valueIndex
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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "k004");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "k002");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "k003");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "k005");

        (bool success,) = recipient.call{value : amount}("");
        require(success, "k006");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "k007");
        require(isContract(target), "k008");

        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "k009");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "k010");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }
}

interface IERC721Enumerable {
    
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
     function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract SwapPoolForClaimNFT is Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    bool public canSwap = false;
    bool public canClaim = false;
    
    IERC20 public swapToken;
    uint256 public swapPrice;
    IERC721Enumerable public SwapNFT;
    IERC721Enumerable public claimNFT;
    uint256 public claimTimes = 0;
    mapping(uint256 => uint256) public canClaimBlockNumList;
    mapping(uint256 => uint256) public canClaimAmountList;
    mapping(address => mapping(uint256 => mapping(uint256 => claimiItem))) public userClaimList2;
    mapping(address => uint256[]) public userTokenIdList;
    mapping(uint256=>EnumerableSet.UintSet) private ClaimTokenIdSet;
    EnumerableSet.UintSet private SwapTokenIdSet;

    event swapTokenEvent(address _user,uint256 _tokenId,uint256 _time);
    event claimTokenEvent(address _user,uint256 _tokenId,uint256 _time,uint256 _amount);

    struct claimiItem {
        uint256 tokenId;
        bool hasClaim;
    }
    
    function enableSwap() external onlyOwner {
        canSwap = true;
    }
    
    function disableSwap() external onlyOwner {
        canSwap = false;
    }
    
    
    function enableClaim() external onlyOwner {
        canClaim = true;
    }
    
    function disableClaim() external onlyOwner {
        canClaim = false;
    }
    
    function setSwapNFT(IERC721Enumerable _SwapNFT) external onlyOwner {
        SwapNFT = _SwapNFT;
    }
    
    
    function setClaimNFT(IERC721Enumerable _claimNFT) external onlyOwner {
        claimNFT = _claimNFT;
    }
    
    // function setSwapInfo(IERC20 _swapToken, uint256 _swapPrice) external onlyOwner {
    //     swapToken = _swapToken;
    //     swapPrice = _swapPrice;
    // }
    
    function claimTimeLines(uint256[] memory timeList, uint256[] memory amountList) external onlyOwner {
        claimTimes = 0;
        for (uint256 i = 0; i < timeList.length; i++) {
            canClaimBlockNumList[i] = timeList[i];
            canClaimAmountList[i] = amountList[i];
            claimTimes = claimTimes.add(1);
        }
    }
    
    event claimNFT2(address _from, address _to, uint256 _tokenId);

    function SwapToken(uint256 _tokenId) external {
        require(canSwap,"e0");
        userTokenIdList[msg.sender].push(_tokenId);
        SwapNFT.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _tokenId);
        SwapTokenIdSet.add(_tokenId);
        emit swapTokenEvent(msg.sender,_tokenId,block.timestamp);
        claimNFT.transferFrom(address(this), msg.sender, claimNFT.tokenOfOwnerByIndex(address(this),0));
        emit claimNFT2(address(this), msg.sender, claimNFT.tokenOfOwnerByIndex(address(this),0));
    }
    
    function SwapTokenList(uint256[] memory _tokenIdList) external {
        require(canSwap,"e1");
        for (uint256 i=0;i<_tokenIdList.length;i++) {
            userTokenIdList[msg.sender].push(_tokenIdList[i]);
            SwapNFT.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _tokenIdList[i]);
            SwapTokenIdSet.add(_tokenIdList[i]);
            emit swapTokenEvent(msg.sender,_tokenIdList[i],block.timestamp);
            claimNFT.transferFrom(address(this), msg.sender, claimNFT.tokenOfOwnerByIndex(address(this),0));
            emit claimNFT2(address(this), msg.sender, claimNFT.tokenOfOwnerByIndex(address(this),0));
        }
    }
    
    function getUserTokenIdList(address _address) external view returns (uint256[] memory) {
        return userTokenIdList[_address];
    }
    
    function userClaimList(address _user,uint256 _tokenId,uint256 _time) external view returns (claimiItem memory claimInfo) {
        claimInfo.tokenId = isInArray(_tokenId,userTokenIdList[_user])?_tokenId:0;
        claimInfo.hasClaim = userClaimList2[_user][_tokenId][_time].hasClaim;
    }
    
    function isInArray(uint256 _tokenId,uint256[] memory _tokenIdList) public pure returns(bool) {
        for (uint256 i=0;i<_tokenIdList.length;i++) {
            if (_tokenId == _tokenIdList[i]) {
                return true;
            }
        }
        return false;
    }
    
    // function claimToken(uint256 _tokenId, uint256 _time) external {
    //     require(canClaim,"e2");
    //     require(isInArray(_tokenId,userTokenIdList[msg.sender]),"e3");
    //     require(canClaimAmountList[_time]>0,"e4");
    //     require(!userClaimList2[msg.sender][_tokenId][_time].hasClaim, "e5");
    //     require(block.timestamp >= canClaimBlockNumList[_time], "e6");
    //     swapToken.safeTransfer(msg.sender, canClaimAmountList[_time]);
    //     userClaimList2[msg.sender][_tokenId][_time].hasClaim = true;
    //     ClaimTokenIdSet[_time].add(_tokenId);
    //     emit claimTokenEvent(msg.sender,_tokenId,_time,canClaimAmountList[_time]);
    // }
    
    // function claimTokenAll(uint256 _time) external {
    //     require(canClaim,"e7");
    //     require(block.timestamp >= canClaimBlockNumList[_time], "e8");
    //     require(canClaimAmountList[_time]>0,"e8");
    //     uint256[] memory _tokenIdList = userTokenIdList[msg.sender];
    //     for (uint256 i=0;i<_tokenIdList.length;i++) {
    //         uint256 _tokenId = _tokenIdList[i];
    //         if (!userClaimList2[msg.sender][_tokenId][_time].hasClaim) {
    //             swapToken.safeTransfer(msg.sender, canClaimAmountList[_time]);
    //             userClaimList2[msg.sender][_tokenId][_time].hasClaim = true;
    //             ClaimTokenIdSet[_time].add(_tokenId);
    //             emit claimTokenEvent(msg.sender,_tokenId,_time,canClaimAmountList[_time]);
    //         }
    //     }
    // }
    
    function takeErc20Token(IERC20 _token) external onlyOwner {
        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "e10");
        _token.safeTransfer(msg.sender, amount);
    }
    
    function takeETH() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "e11");
        payable(msg.sender).transfer(amount);
    }
    
    function getSwapTokenListNum() external view returns(uint256) {
        return SwapTokenIdSet.length();
    }
    
    function getSwapTokenList() external view returns(uint256[] memory) {
        return SwapTokenIdSet.values();
    }
    
    function getSwapTokenListByIndex(uint256 _index) external view returns(uint256) {
        return SwapTokenIdSet.at(_index);
    }
    
    function getSwapTokenListByIndexList(uint256[] memory _indexList) external view returns(uint256[] memory SwapTokenLists) {
        SwapTokenLists = new uint256[](_indexList.length);
        for (uint256 i=0;i<_indexList.length;i++) {
            SwapTokenLists[i] = SwapTokenIdSet.at(_indexList[i]);
        }
    }
    
    
    function getClaimTokenIdNum(uint256 _time) external view returns(uint256) {
        return ClaimTokenIdSet[_time].length();
    }
    
    function getClaimTokenIdList(uint256 _time) external view returns(uint256[] memory) {
        return ClaimTokenIdSet[_time].values();
    }
    
    function getClaimTokenIdListByIndex(uint256 _time,uint256 _index) external view returns(uint256) {
        return ClaimTokenIdSet[_time].at(_index);
    }
    
    function getClaimTokenIdListByIndexList(uint256 _time,uint256[] memory _indexList) external view returns(uint256[] memory ClaimTokenIdLists) {
        ClaimTokenIdLists = new uint256[](_indexList.length);
        for (uint256 i=0;i<_indexList.length;i++) {
            ClaimTokenIdLists[i] = ClaimTokenIdSet[_time].at(_indexList[i]);
        }
    }
    
    
    function claimNft(IERC721Enumerable _nftToken, uint256 _num) public onlyOwner {
        require(_nftToken.balanceOf(address(this)) >= _num, "k01");
        for (uint256 i = 0; i < _num; i++) {
            uint256 _token_id = _nftToken.tokenOfOwnerByIndex(address(this), 0);
            _nftToken.transferFrom(address(this), msg.sender, _token_id);
        }
    }
    
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public returns (bytes4) {
        return 0x150b7a02;
    }
    
    receive() payable external {}
}