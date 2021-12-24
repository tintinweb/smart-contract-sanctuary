/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-24
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-24
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-23
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract GameContract is Context {
    address private _contract;

    event ContractOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _contract = msgSender;
        emit ContractOwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function gameContract() public view returns (address) {
        return _contract;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyContract() {
        require(_contract == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferContractOwnership(address newOwner) public virtual onlyContract {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit ContractOwnershipTransferred(_contract, newOwner);
        _contract = newOwner;
    }
}

contract Server is Context {
    address private _server;

    event ServerOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _server = msgSender;
        emit ServerOwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function serverAddress() public view returns (address) {
        return _server;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyServer() {
        require(_server == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferServerOwnership(address newOwner) public virtual onlyServer {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit ServerOwnershipTransferred(_server, newOwner);
        _server = newOwner;
    }
}

interface IRandomContract {
    event NewRequest(bytes32 indexed id, bytes32 usersSeed);
    event RequestFilled(bytes32 indexed id, bytes32 usersSeed, bytes32 serverSeed, uint number);

    function requestRandom(bytes32 _usersSeed) external returns (bytes32 requestId);
}

interface IRandomReceiver {
    function randomReponse(bytes32 _requestId, uint _number) external;
}

contract RandomContract is GameContract, Server, IRandomContract {
    bytes32[] private _hashes;

    mapping(bytes32 => bytes32) public _requests;

    function hashes() view external returns(bytes32[] memory) {
        return _hashes;
    }

    function addHashes(bytes32[] calldata _hashes_) external onlyServer {
        for (uint256 i = 0; i < _hashes_.length; i++) {
            _hashes.push(_hashes_[i]);
        }
    }

    function removeHash(uint _index) external onlyServer {
        _removeAt(_index);
    }

    function _removeAt(uint _index) internal {
        if (_index >= _hashes.length) return;
        
        _hashes[_index] = _hashes[_hashes.length - 1];
        _hashes.pop();
    }

    function requestRandom(bytes32 _usersSeed) external override onlyContract returns (bytes32 requestId) {
        bytes32 _hash = _hashes[0];
        _removeAt(0);
        require(_requests[_hash] == bytes32(0), "RANDOM: The hash already exists !");
        _requests[_hash] = _usersSeed;

        emit NewRequest(_hash, _usersSeed);
        return _hash;
    }

    function fillRandom(uint _number, bytes32 _id, bytes32 _usersSeed, bytes32 _serverSeed, bytes32 _newHash) external onlyServer {
        _hashes.push(_newHash);
        IRandomReceiver(gameContract()).randomReponse(_id, _number);

        emit RequestFilled(_id, _usersSeed, _serverSeed ,_number);
    }
}