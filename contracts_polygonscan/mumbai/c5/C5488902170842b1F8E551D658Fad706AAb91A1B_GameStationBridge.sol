// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IERC20Mintable.sol";
import "./interfaces/IFeeDistributor.sol";
import "./interfaces/IGameStationBridge.sol";

/// @title Bridge beetwen blockchains
/// @author Applicature team
/// @dev This Smart Contract use for transfer coins/erc20 between different blockhains on base ethereum evm
contract GameStationBridge is IGameStationBridge, EIP712, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address payable;

    uint256 public constant FEE_PROPOSE_TIME_LOCKUP = 1 hours;
    uint256 public constant MAX_INITIAL_PERCENTAGE = 1e20;
    address public constant NATIVE = address(0);
    bytes32 public constant _CONTAINER_TYPEHASE =
        keccak256(
            "Container(address sender,uint256 chainIdFrom,address token,uint256 amount,uint256 nonce)"
        );
    bytes32 public constant _CONTAINER_KYC_TYPEHASE =
        keccak256("KycContainer(address sender)");
    bytes32 public constant _CONTAINER_LIQUIDITY_TYPEHASE =
        keccak256(
            "LiquidityContainer(address sender,address token,uint256 deadline,uint256 maxAvailAmount,uint256 nonce)"
        );

    mapping(uint256 => bool) public isETHChain;
    mapping(address => TokenInfo) public tokensInfo;
    mapping(uint256 => mapping(address => bool)) public supportedChainsId;
    mapping(address => mapping(address => uint256)) public userLiquidity;

    address payable public feeRecipient;
    address public feeDistributor;
    address public kycSigner;

    EnumerableSet.AddressSet internal _supportedTokens;
    EnumerableSet.AddressSet internal _signers;
    mapping(address => mapping(uint256 => bool)) internal _nonces;

    constructor(address[] memory signers_, TokenCreateInfo[] memory tokenInfos_)
        EIP712("GameStationBridge", "v1")
    {
        _addSigners(signers_);
        for (uint256 i; i < tokenInfos_.length; i++) {
            _addSuportedToken(tokenInfos_[i]);
        }
    }

    function isTokenSupported(address tokenAddress_)
        public
        view
        returns (bool)
    {
        return _supportedTokens.contains(tokenAddress_);
    }

    function getSupportedTokens()
        external
        view
        returns (address[] memory list)
    {
        uint256 lastIndex = _supportedTokens.length();

        list = new address[](lastIndex);

        for (uint256 i = 0; i < lastIndex; i++) {
            list[i] = _supportedTokens.at(i);
        }
    }

    function getSignersAddress()
        external
        view
        onlyOwner
        returns (address[] memory list)
    {
        uint256 lastIndex = _signers.length();

        list = new address[](lastIndex);

        for (uint256 i = 0; i < lastIndex; i++) {
            list[i] = _signers.at(i);
        }
    }

    function setSupportedChainToToken(
        uint256 chainId_,
        address tokenAddress_,
        bool value_
    ) external onlyOwner {
        supportedChainsId[chainId_][tokenAddress_] = value_;
        emit SetSupportedTokenToChain(tokenAddress_, chainId_, value_);
    }

    function setIsETHChain(uint256 chainId_, bool value_) external onlyOwner {
        isETHChain[chainId_] = value_;
        emit SetIsETHChain(chainId_, value_);
    }

    function addSigners(address[] calldata signers_) external onlyOwner {
        _addSigners(signers_);
    }

    function removeSigners(address[] calldata signers_) external onlyOwner {
        for (uint256 i; i < signers_.length; i++) {
            require(_signers.remove(signers_[i]), "Signer not found");
        }
        require(_signers.length() > 0, "Signers can't be empty");
    }

    function setFeeRecipient(address payable recipient_) external onlyOwner {
        require(recipient_ != address(0), "Recipient can't be zero address");
        feeRecipient = recipient_;
    }

    function setFeeDistributor(address distributor_) external onlyOwner {
        feeDistributor = distributor_;
    }

    function setKycSigner(address kycSigner_) external onlyOwner {
        kycSigner = kycSigner_;
    }

    function addSupportedToken(TokenCreateInfo calldata info_)
        external
        onlyOwner
    {
        _addSuportedToken(info_);
    }

    function proposeNewFee(address tokenAddress_, uint256 newFee_)
        external
        onlyOwner
    {
        TokenInfo storage info = tokensInfo[tokenAddress_];
        require(newFee_ < MAX_INITIAL_PERCENTAGE, "Fee is more then max");
        info.proposeFee = newFee_;
        info.proposeTime = block.timestamp + FEE_PROPOSE_TIME_LOCKUP;
    }

    function applyPropose(address tokenAddress_) external onlyOwner {
        TokenInfo storage info = tokensInfo[tokenAddress_];
        require(
            block.timestamp > info.proposeTime,
            "Lock up period"
        );
        info.fee = info.proposeFee;
    }

    function removeSupportedToken(address tokenAddress_) external onlyOwner {
        require(_supportedTokens.remove(tokenAddress_), "Token is not found");
        emit RemoveSupportedToken(tokenAddress_);
    }

    function addLiquidity(address tokenAddress_, uint256 amount_)
        external
        payable
        override
    {
        uint256 amount = _depositRequire(tokenAddress_, amount_);
        if (!_isNative(tokenAddress_)) {
            IERC20(tokenAddress_).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        }
        tokensInfo[tokenAddress_].liquidity += amount;
        userLiquidity[tokenAddress_][msg.sender] += amount;
        emit AddLiquidity(msg.sender, tokenAddress_, amount);
    }

    function withdrawLiquidity(
        address tokenAddress_,
        uint256 amount_,
        uint256 deadline_,
        uint256 maxAvailAmount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external override {
        require(!_nonces[msg.sender][nonce_], "Invalid nonce");
        require(block.timestamp < deadline_, "Time out");
        bytes32 structHash = keccak256(
            abi.encode(
                _CONTAINER_LIQUIDITY_TYPEHASE,
                msg.sender,
                tokenAddress_,
                deadline_,
                maxAvailAmount_,
                nonce_
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        _isValidSigners(digest, v_, r_, s_);
        _nonces[msg.sender][nonce_] = true;
        {
            uint256 liquidityBalance = userLiquidity[tokenAddress_][msg.sender];
            uint256 contractBalance = _isNative(tokenAddress_)
                ? address(this).balance
                : IERC20(tokenAddress_).balanceOf(address(this));
            uint256 availableAmount = liquidityBalance > contractBalance
                ? contractBalance
                : liquidityBalance;
            require(
                amount_ <= availableAmount &&
                    amount_ <= maxAvailAmount_ &&
                    amount_ != 0,
                "Incorrect amount"
            );
        }
        tokensInfo[tokenAddress_].liquidity -= amount_;
        userLiquidity[tokenAddress_][msg.sender] -= amount_;
        if (_isNative(tokenAddress_)) {
            payable(msg.sender).sendValue(amount_);
        } else {
            IERC20(tokenAddress_).safeTransfer(msg.sender, amount_);
        }
        emit RemoveLiquidity(msg.sender, tokenAddress_, amount_);
    }

    function deposit(
        uint256 chainIdTo_,
        address tokenAddress_,
        uint256 amount_,
        address recipient_,
        string memory data_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external payable override {
        require(
            supportedChainsId[chainIdTo_][tokenAddress_],
            "ChainId not supported"
        );
        if (isETHChain[chainIdTo_]) {
            require(recipient_ != address(0), "Incorrect recipient address");
        } else {
            require(bytes(data_).length != 0, "Incorrect data");
        }
        _isValidKYC(tokenAddress_, v_, r_, s_);
        uint256 amount = _depositRequire(tokenAddress_, amount_);
        uint256 feePercentage = tokensInfo[tokenAddress_].fee;
        if (feePercentage > 0) {
            uint256 fee = (amount * feePercentage) / MAX_INITIAL_PERCENTAGE;
            amount -= fee;
            _feeDistribute(tokenAddress_, fee);
        }
        _transferFrom(tokenAddress_, amount);
        emit Deposit(
            msg.sender,
            block.chainid,
            chainIdTo_,
            tokenAddress_,
            amount,
            recipient_,
            data_
        );
    }

    function withdrawFor(
        address reciver_,
        uint256 chainIdFrom_,
        address tokenAddress_,
        uint256 amount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external override {
        _withdraw(
            reciver_,
            chainIdFrom_,
            tokenAddress_,
            amount_,
            nonce_,
            v_,
            r_,
            s_
        );
    }

    function withdraw(
        uint256 chainIdFrom_,
        address tokenAddress_,
        uint256 amount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external override {
        _withdraw(
            msg.sender,
            chainIdFrom_,
            tokenAddress_,
            amount_,
            nonce_,
            v_,
            r_,
            s_
        );
    }

    function _depositRequire(address tokenAddress_, uint256 amount_)
        internal
        view
        returns (uint256)
    {
        require(isTokenSupported(tokenAddress_), "Token is not supported");
        require(!(msg.value > 0 && amount_ > 0), "Two amounts were entered");
        uint256 amount = _isNative(tokenAddress_) ? msg.value : amount_;
        require(amount > 0, "Amount must be greater than zero");
        return amount;
    }

    function _isValidKYC(
        address tokenAddress_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal view {
        if (tokensInfo[tokenAddress_].needKYC) {
            bytes32 structHash = keccak256(
                abi.encode(_CONTAINER_KYC_TYPEHASE, msg.sender)
            );
            bytes32 hash = _hashTypedDataV4(structHash);
            address messageSigner = ECDSA.recover(hash, v_, r_, s_);
            require(messageSigner == kycSigner, "Not passed KYC");
        }
    }

    function _isValidSigners(
        bytes32 digest_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) internal view {
        require(
            v_.length == r_.length &&
                r_.length == s_.length &&
                s_.length == _signers.length(),
            "Arrays have different lengths"
        );
        for (uint256 i = 0; i < v_.length; i++) {
            address messageSigner = ECDSA.recover(digest_, v_[i], r_[i], s_[i]);
            require(messageSigner == _signers.at(i), "Invalid signers");
        }
    }

    function _isNative(address tokenAddress_) internal pure returns (bool) {
        return tokenAddress_ == NATIVE;
    }

    function _withdraw(
        address recipient_,
        uint256 chainIdFrom_,
        address tokenAddress_,
        uint256 amount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) internal {
        require(isTokenSupported(tokenAddress_), "Token is not supported");
        require(!_nonces[recipient_][nonce_], "Invalid nonce");
        bytes32 structHash = keccak256(
            abi.encode(
                _CONTAINER_TYPEHASE,
                recipient_,
                chainIdFrom_,
                tokenAddress_,
                amount_,
                nonce_
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        _isValidSigners(digest, v_, r_, s_);
        _nonces[recipient_][nonce_] = true;
        if (_isNative(tokenAddress_)) {
            payable(recipient_).sendValue(amount_);
        } else if (tokensInfo[tokenAddress_].tokenType == TokenType.ERC20) {
            IERC20(tokenAddress_).safeTransfer(recipient_, amount_);
        } else {
            IERC20Mintable(tokenAddress_).mint(recipient_, amount_);
        }
        emit Withdraw(
            recipient_,
            chainIdFrom_,
            block.chainid,
            tokenAddress_,
            amount_,
            nonce_
        );
    }

    function _feeDistribute(address tokenAddress_, uint256 fee_) internal {
        if (_isNative(tokenAddress_)) {
            feeRecipient.sendValue(fee_);
        } else {
            IERC20(tokenAddress_).safeTransferFrom(
                msg.sender,
                feeRecipient,
                fee_
            );
        }
        if (feeDistributor != address(0)) {
            IFeeDistributor(feeDistributor).distributeFee(tokenAddress_, fee_);
        }
    }

    function _transferFrom(address tokenAddress_, uint256 amount_) internal {
        TokenType tokenType = tokensInfo[tokenAddress_].tokenType;
        if (_isNative(tokenAddress_)) {
            return;
        } else if (tokenType == TokenType.ERC20) {
            IERC20(tokenAddress_).safeTransferFrom(
                msg.sender,
                address(this),
                amount_
            );
        } else if (tokenType == TokenType.ERC20_MINT_BURN_V2) {
            IERC20Mintable(tokenAddress_).burnFrom(msg.sender, amount_);
        } else {
            IERC20Mintable(tokenAddress_).burn(msg.sender, amount_);
        }
    }

    function _addSigners(address[] memory signers_) internal {
        require(signers_.length > 0, "Signers array is empty");
        for (uint256 i; i < signers_.length; i++) {
            require(signers_[i] != address(0), "Signer is zero address");
            _signers.add(signers_[i]);
        }
    }

    function _addSuportedToken(TokenCreateInfo memory info_) internal {
        TokenInfo storage info = tokensInfo[info_.token];
        bool isNew = _supportedTokens.add(info_.token);
        if (isNew) {
            require(info_.fee < MAX_INITIAL_PERCENTAGE, "Fee is more then max");
            info.fee = info_.fee;
        }
        info.needKYC = info_.needKYC;
        info.tokenType = info_.tokenType;
        emit AddSuportedToken(info_.token, info, !isNew);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IGameStationBridge {
    enum TokenType {
        ERC20,
        ERC20_MINT_BURN,
        ERC20_MINT_BURN_V2
    }

    struct TokenCreateInfo {
        address token;
        bool needKYC;
        uint256 fee;
        TokenType tokenType;
    }

    struct TokenInfo {
        bool needKYC;
        uint256 fee;
        TokenType tokenType;
        uint256 liquidity;
        uint256 proposeFee;
        uint256 proposeTime;
    }

    event Deposit(
        address indexed sender,
        uint256 chainIdFrom,
        uint256 chainIdTo,
        address token,
        uint256 amount,
        address recipient,
        string data
    );

    event Withdraw(
        address indexed sender,
        uint256 chainIdFrom,
        uint256 chainIdTo,
        address token,
        uint256 amount,
        uint256 nonce
    );

    event AddLiquidity(
        address indexed sender,
        address indexed token,
        uint256 amount
    );

    event RemoveLiquidity(
        address indexed sender,
        address indexed token,
        uint256 amount
    );

    event AddSuportedToken(
        address indexed token,
        TokenInfo info,
        bool isUpdate
    );

    event SetSupportedTokenToChain(
        address indexed token,
        uint256 chainId,
        bool isSupported
    );

    event SetIsETHChain(uint256 chainId, bool isETHChain);

    event RemoveSupportedToken(address indexed token);

    event LogWithdrawToken(
        address indexed from,
        address indexed token,
        uint256 amount
    );

    function addLiquidity(address tokenAddress_, uint256 amount_)
        external
        payable;

    function withdrawLiquidity(
        address tokenAddress_,
        uint256 amount_,
        uint256 deadline_,
        uint256 maxAvailAmount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external;

    function deposit(
        uint256 chainIdTo_,
        address tokenAddress_,
        uint256 amount_,
        address recipient_,
        string memory data_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external payable;

    function withdrawFor(
        address reciver_,
        uint256 chainIdFrom_,
        address tokenAddress_,
        uint256 amount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external;

    function withdraw(
        uint256 chainIdFrom_,
        address tokenAddress_,
        uint256 amount_,
        uint256 nonce_,
        uint8[] calldata v_,
        bytes32[] calldata r_,
        bytes32[] calldata s_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFeeDistributor {
    function distributeFee(address token_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC20Mintable {
    function mint(address _to, uint256 _value) external;

    function burn(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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