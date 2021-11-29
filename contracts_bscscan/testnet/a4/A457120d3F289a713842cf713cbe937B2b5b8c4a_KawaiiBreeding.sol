pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : - x;
    }
}


interface IERC1155 {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    function mint(address to, uint256 tokenId, uint256 value) external;

    function burn(address _account, uint256 _id, uint256 _amount) external;
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

contract Signed {
    mapping(bytes32 => bool) public  permitDoubleSpending;

    function getSigner(bytes32 data, uint8 v, bytes32 r, bytes32 s) internal returns (address){
        require(!permitDoubleSpending[data], "Forbidden double spending");
        permitDoubleSpending[data] = true;
        return ecrecover(getEthSignedMessageHash(data), v, r, s);
    }
    //    FUNCTION internal
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function checkPermitDoubleSpendingBatch(bytes32[] memory _datas) external view returns (bool[] memory){
        bool[] memory isChecks = new bool[](_datas.length);
        for (uint256 i = 0; i < _datas.length; i++) {
            isChecks[i] = permitDoubleSpending[_datas[i]];
        }
        return isChecks;
    }

}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public BREEDING_HASH;
    mapping(address => uint256) public nonces;


    constructor() internal {
        NAME = "KawaiiBreeding";
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(NAME)),
                keccak256(bytes('1')),
                chainId,
                this
            )
        );

        BREEDING_HASH = keccak256("Data(bytes adminSignedData,uint256 nonce)");
    }

    function verify(bytes32 data, address sender, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                data
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);

        require(recoveredAddress != address(0) && recoveredAddress == sender, "Invalid nonce");
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused external {
        paused = false;
        Unpause();
    }
}


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

        if (valueIndex != 0) {// Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1;
            // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

contract KawaiiBreeding is Signed, Pausable, SignData {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using EnumerableSet for EnumerableSet.UintSet;

    IBEP20 public kawaiiToken;
    IBEP20 public milkyToken;
    mapping(address => bool) public isSigner;
    uint256 public minFeeKawaii;
    uint256 public minFeeMilky;
    uint256 public maxFeeKawaii;
    uint256 public maxFeeMilky;

    struct DataLog {
        uint256 tokenIdF0;
        uint256 tokenIdF1;
        uint256 time;
    }

    mapping(address => mapping(uint256 => DataLog)) public dataLogs;

    mapping(address => EnumerableSet.UintSet) internal breedings;

    event Breeding(address indexed sender, uint256 nonce, uint256 timeBreeding, uint256 tokenIdF0, uint256 tokenIdF1);
    event Claim(address indexed sender, uint256 nonce, uint256 tokenIdF0, uint256 tokenIdF1);
    event Fee(IBEP20 token, uint256 min, uint256 max);

    constructor(IBEP20 _kawaiiToken, IBEP20 _milkyToken, uint256 _minFeeKawaii, uint256 _maxFeeKawaii, uint256 _minFeeMilky, uint256 _maxFeeMilky) public validAddress(address(_kawaiiToken)) validAddress(address(_milkyToken)) {
        kawaiiToken = _kawaiiToken;
        milkyToken = _milkyToken;
        isSigner[msg.sender] = true;
        minFeeKawaii = _minFeeKawaii;
        maxFeeKawaii = _maxFeeKawaii;
        minFeeMilky = _minFeeMilky;
        maxFeeMilky = _maxFeeMilky;
    }

    modifier validAddress(address _address){
        require(_address != address(0), "Address is 0x");
        _;
    }
    function setKawaiiToken(IBEP20 _kawaiiToken) external validAddress(address(_kawaiiToken)) onlyOwner {
        kawaiiToken = _kawaiiToken;
    }

    function setSigner(address user, bool _result) external onlyOwner {
        isSigner[user] = _result;
    }

    function setMinMaxFeeKawaii(uint256 _minFee, uint256 _maxFee) external onlyOwner {
        minFeeKawaii = _minFee;
        maxFeeKawaii = _maxFee;
        emit Fee(kawaiiToken, _minFee, _maxFee);
    }

    function setMinMaxFeeMilky(uint256 _minFee, uint256 _maxFee) external onlyOwner {
        minFeeMilky = _minFee;
        maxFeeMilky = _maxFee;
        emit Fee(milkyToken, _minFee, _maxFee);
    }

    function sizeOfBreeding(address user) public view returns (uint256){
        return breedings[user].length();
    }

    function getIndexBreeding(address user, uint256 _index) public view returns (uint256){
        return breedings[user].at(_index);
    }

    function getIndexBreedingBatch(address user, uint8[] memory _indexs) public view returns (uint256[] memory){
        uint256[] memory datas = new uint256[](_indexs.length);

        for (uint256 i = 0; i < _indexs.length; i++) {
            datas[i] = breedings[user].at(_indexs[i]);
        }
        return datas;
    }

    function getDataLogBatch(address user, uint8[] memory _indexs) public view returns (DataLog[] memory){
        DataLog[] memory datas = new DataLog[](_indexs.length);

        for (uint256 i = 0; i < _indexs.length; i++) {
            datas[i] = dataLogs[user][_indexs[i]];
        }
        return datas;
    }

    function breeding(bytes memory data) external whenNotPaused {
        (address _sender,uint256 _timestamp,bytes memory _dataInput,
        bytes memory _adminSignedData,
        uint8 v, bytes32 r, bytes32 s) = abi.decode(data, (address, uint256, bytes, bytes, uint8, bytes32, bytes32));

        {
            uint256 nonce = nonces[_sender]++;
            verify(keccak256(abi.encode(BREEDING_HASH, keccak256(_adminSignedData), nonce)), _sender, v, r, s);
            (v, r, s) = abi.decode(_adminSignedData, (uint8, bytes32, bytes32));
            address signer = getSigner(
                keccak256(
                    abi.encode(address(this), this.breeding.selector, _dataInput, _timestamp, nonce)
                ), v, r, s);

            require(isSigner[signer], "Forbidden");
        }

        (IERC1155 _nft1155Address,
        uint256[] memory _inputNFTIds,
        uint256[] memory _inputAmounts,
        uint256 _timeBreeding,
        uint256  _tokenIdF0,
        uint256  _tokenIdF1,
        uint256 _kawaiiPrice,
        uint256 _milkyPrice) = abi.decode(
            _dataInput,
            (IERC1155, uint256[], uint256[], uint256, uint256, uint256, uint256, uint256)
        );

        address sender = _sender;

        require(_kawaiiPrice >= minFeeKawaii && _kawaiiPrice <= maxFeeKawaii, "Invalid kawaii price");
        require(_milkyPrice >= minFeeMilky && _milkyPrice <= maxFeeMilky, "Invalid milky price");

        require(_inputNFTIds.length == _inputAmounts.length, "Invalid input length");
        kawaiiToken.safeTransferFrom(sender, address(this), _kawaiiPrice);
        milkyToken.safeTransferFrom(sender, address(this), _milkyPrice);

        for (uint256 i = 0; i < _inputNFTIds.length; i++) {
            _nft1155Address.burn(sender, _inputNFTIds[i], _inputAmounts[i]);
        }

        _nft1155Address.safeTransferFrom(sender, address(this), _tokenIdF0, 1, "0x");

        dataLogs[sender][nonces[sender].sub(1)] = DataLog(_tokenIdF0, _tokenIdF1, block.timestamp.add(_timeBreeding));

        breedings[sender].add(nonces[sender].sub(1));

        emit Breeding(sender, nonces[sender].sub(1), block.timestamp.add(_timeBreeding), _tokenIdF0, _tokenIdF1);
    }

    function claimBreeding(IERC1155 _nft1155Address, address sender, uint256[] calldata _indexs) external {
        for (uint256 i = 0; i < _indexs.length; i++) {
            bool _is = breedings[sender].contains(_indexs[i]);
            require(_is, "index not found");

            require(dataLogs[sender][_indexs[i]].time <= block.timestamp, "time breeding not finished");
            _nft1155Address.safeTransferFrom(address(this), sender, dataLogs[sender][_indexs[i]].tokenIdF0, 1, "0x");
            _nft1155Address.mint(sender, dataLogs[sender][_indexs[i]].tokenIdF1, 1);
            breedings[sender].remove(_indexs[i]);

            emit Claim(sender, _indexs[i], dataLogs[sender][_indexs[i]].tokenIdF0, dataLogs[sender][_indexs[i]].tokenIdF1);
        }
    }

    function inCaseTokenStuck(address token, address to, uint256 amount) external onlyOwner {
        IBEP20(token).safeTransfer(to, amount);
    }

    function inCaseNFTStuck(IERC1155 kawaiiCore, address to, uint256 id, uint256 amount) external onlyOwner {
        kawaiiCore.safeTransferFrom(address(this), to, id, amount, "0x");
    }


    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external pure returns (bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external pure returns (bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}