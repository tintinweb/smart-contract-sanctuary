// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SignatureVerify.sol";

contract UniqStoreHelper is Ownable, SignatureVerify {
    // ----- VARIABLES ----- //
    address internal _storeAddress;
    uint256 internal _transactionOffset;

    // ----- CONSTRUCTOR ----- //
    constructor(address _storeContractAddress) {
        _storeAddress = _storeContractAddress;
        _transactionOffset = 2 hours;
    }

    // ----- VIEWS ----- //
    function getStoreAddress() external view returns (address) {
        return _storeAddress;
    }

    // ----- MESSAGE SIGNATURE ----- //
    /// @dev not test for functions related to signature
    function getMessageHash(
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymnetTokenAddress,
        uint256 _timestamp
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_tokenIds, _price, _paymnetTokenAddress, _timestamp)
            );
    }

    /// @dev not test for functions related to signature
    function verifySignature(
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _tokenIds,
            _price,
            _paymentTokenAddress,
            _timestamp
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    // ----- PUBLIC METHODS ----- //

    function buyToken(
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymentToken,
        address _receiver,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable {
        require(_tokenIds.length == 1, "More than one token");
        require(_timestamp + _transactionOffset >= block.timestamp, "Transaction timed out");
        require(
            verifySignature(_tokenIds, _price, _paymentToken, _signature, _timestamp),
            "Signature mismatch"
        );
        if (_price != 0) {
            if (_paymentToken == address(0)) {
                require(msg.value >= _price, "Not enough ether");
                if (_price < msg.value) {
                    payable(msg.sender).transfer(msg.value - _price);
                }
            } else {
                require(
                    IERC20(_paymentToken).transferFrom(
                        msg.sender,
                        address(this),
                        _price
                    )
                );
            }
        }
        address[] memory receivers = new address[](1);
        receivers[0] = _receiver;
        IUniqCollections(_storeAddress).batchMintSelectedIds(
            _tokenIds,
            receivers
        );
    }

    function buyTokens(
        uint256[] memory _tokenIds,
        uint256 _priceForPackage,
        address _paymentToken,
        address _receiver,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable {
        require(_timestamp + _transactionOffset >= block.timestamp, "Transaction timed out");
        require(
            verifySignature(
                _tokenIds,
                _priceForPackage,
                _paymentToken,
                _signature,
                _timestamp
            ),
            "Signature mismatch"
        );
        if (_priceForPackage != 0) {
            if (_paymentToken == address(0)) {
                require(msg.value >= _priceForPackage, "Not enough ether");
                if (_priceForPackage < msg.value) {
                    payable(msg.sender).transfer(msg.value - _priceForPackage);
                }
            } else {
                require(
                    IERC20(_paymentToken).transferFrom(
                        msg.sender,
                        address(this),
                        _priceForPackage
                    )
                );
            }
        }
        address[] memory _receivers = new address[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _receivers[i] = _receiver;
        }
        IUniqCollections(_storeAddress).batchMintSelectedIds(
            _tokenIds,
            _receivers
        );
    }

    // ----- PROXY METHODS ----- //

    function pEditClaimingAddress(address _newAddress) external onlyOwner {
        IUniqCollections(_storeAddress).editClaimingAdress(_newAddress);
    }

    function pEditRoyaltyFee(uint256 _newFee) external onlyOwner {
        IUniqCollections(_storeAddress).editRoyaltyFee(_newFee);
    }

    function pEditTokenUri(string memory _ttokenUri) external onlyOwner {
        IUniqCollections(_storeAddress).editTokenUri(_ttokenUri);
    }

    function pRecoverERC20(address token) external onlyOwner {
        IUniqCollections(_storeAddress).recoverERC20(token);
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        Ierc20(token).transfer(owner(), val);
    }

    function pTransferOwnership(address newOwner) external onlyOwner {
        IUniqCollections(_storeAddress).transferOwnership(newOwner);
    }

    function pBatchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses
    ) external onlyOwner {
        IUniqCollections(_storeAddress).batchMintSelectedIds(_ids, _addresses);
    }

    function pMintNextToken(address _receiver) external onlyOwner{
        IUniqCollections(_storeAddress).mintNextToken(_receiver);
    }

    // ----- OWNERS METHODS ----- //

    function editStoreAddress(address _newStoreAddress) external onlyOwner {
        _storeAddress = _newStoreAddress;
    }

    function withdrawTokens(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        Ierc20(token).transfer(owner(), val);
    }

    function setTransactionOffset(uint256 _newOffset) external onlyOwner{
        _transactionOffset = _newOffset;
    }

    receive() external payable {}

    function withdrawETH() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}

interface IUniqCollections {
    function editClaimingAdress(address _newAddress) external;

    function editRoyaltyFee(uint256 _newFee) external;

    function batchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses
    ) external;

    function editTokenUri(string memory _ttokenUri) external;

    function recoverERC20(address token) external;

    function transferOwnership(address newOwner) external;

    function mintNextToken(address _receiver) external;
}

interface Ierc20 {
    function transfer(address, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract SignatureVerify{

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
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