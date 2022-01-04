// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IBEP20.sol";
import "./IRobotCore.sol";
import "./IPieceCore.sol";

contract MekaDeployer is Ownable {
    address public _mekaAddress;
    address private _signatureAddress;
    address public _robotCoreAddress;
    address public _pieceCoreAddress;
    uint256 public _minConversion;
    mapping(uint256 => bool) usedNonces;
    event Withdraw(address receiver, uint256 amount);
    event Deposit(address receiver, uint256 amount);

    constructor(
        address meka,
        address robotCore,
        address pieceCore
    ) {
        _mekaAddress = meka;
        _signatureAddress = owner();
        _robotCoreAddress = robotCore;
        _pieceCoreAddress = pieceCore;
        _minConversion = 10 * 10**18;
    }

    function setRobotddress(address robotCore) external onlyOwner {
        _robotCoreAddress = robotCore;
    }

    function setPieceAddress(address pieceCore) external onlyOwner {
        _pieceCoreAddress = pieceCore;
    }

    function setMekaMinersAddress(address meka) external onlyOwner {
        _mekaAddress = meka;
    }

    function setSignatureAddress(address signatureAddress) external onlyOwner {
        _signatureAddress = signatureAddress;
    }

    function setMekaConversionRate(uint256 amount) external onlyOwner {
        _minConversion = amount * 10**18;
    }

    function getSignatureAddress() external view onlyOwner returns (address) {
        return _signatureAddress;
    }

    function convertToMeka(
        address _receiver,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) external {
        require(!isContract(msg.sender), "contract not allowed");
        require(_receiver != address(0));
        require(verify(_receiver, _amount, _nonce, _signature), "not signed");
        require(!usedNonces[_nonce], "invalid nonce");
        require(
            IBEP20(_mekaAddress).transfer(_receiver, _amount),
            "insuficient balance on contract"
        );
        usedNonces[_nonce] = true;

        emit Withdraw(_receiver, _amount);
    }

    function convertFromMeka(
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) external {
        require(!isContract(msg.sender), "contract not allowed");
        require(_amount >= _minConversion, "lower than necessary");
        require(verify(msg.sender, _amount, _nonce, _signature), "not signed");
        require(!usedNonces[_nonce], "used nonce");
        require(
            IBEP20(_mekaAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "insuficient balance"
        );

        usedNonces[_nonce] = true;

        emit Deposit(msg.sender, _amount);
    }

    function attachToRobot(
        address _owner,
        uint256 _robotId,
        uint256 _pieceId,
        uint8 _pieceType,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) external {
        require(_robotId != 0, "invalid robotId");
        require(verify(_owner, _amount, _nonce, _signature), "not signed");
        require(!usedNonces[_nonce]);

        usedNonces[_nonce] = true;
        IRobotCore(_robotCoreAddress).attachPiece(
            _owner,
            _robotId,
            _pieceId,
            _pieceType,
            _amount
        );
        IPieceCore(_pieceCoreAddress).burnPiece(_pieceId);
    }

    function createRobot(
        uint256 _amount,
        uint256 _nonce,
        bool _withOre,
        string memory _tokenURI,
        bytes memory _signature
    ) external {
        require(msg.sender != address(0));
        require(verify(msg.sender, _amount, _nonce, _signature), "not signed");
        require(!usedNonces[_nonce]);

        usedNonces[_nonce] = true;
        IRobotCore(_robotCoreAddress).createRobot(
            msg.sender,
            _amount,
            _withOre,
            _tokenURI
        );
    }

    function createPiece(
        uint256 _amount,
        uint256 _nonce,
        bool _fromFarm,
        string memory _tokenURI,
        bytes memory _signature
    ) external {
        require(msg.sender != address(0));
        require(verify(msg.sender, _amount, _nonce, _signature), "not signed");
        require(!usedNonces[_nonce]);

        usedNonces[_nonce] = true;
        IPieceCore(_pieceCoreAddress).createPiece(
            msg.sender,
            _amount,
            _fromFarm,
            _tokenURI
        );
    }

    function getBalance() public view returns (uint256) {
        return IBEP20(_mekaAddress).balanceOf(address(this));
    }

    function withdraw() external onlyOwner {
        IBEP20(_mekaAddress).transfer(owner(), getBalance());
    }

    function getMessageHash(
        address _to,
        uint256 _amount,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _nonce));
    }

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

    function isContract(address _address) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    function verify(
        address _to,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return
            recoverSigner(ethSignedMessageHash, _signature) ==
            _signatureAddress;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRobotCore {
    function createRobot(
        address _owner,
        uint256 _amount,
        bool _withOre,
        string memory tokenURI
    ) external;

    function attachPiece(
        address _owner,
        uint256 _robotId,
        uint256 _pieceId,
        uint8 _pieceType,
        uint256 _amount
    ) external;

    function createRobotFromBundle(
        address _owner,
        uint8 packageType,
        uint8 robotQuantity
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IPieceCore {
    function createPiece(
        address _owner,
        uint256 _amount,
        bool _fromFarm,
        string memory tokenURI
    ) external;

    function burnPiece(uint256 _pieceId) external;

    function createPieceFromBundle(
        address _owner,
        uint8 packageType,
        uint8 robotQuantity
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IBEP20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}