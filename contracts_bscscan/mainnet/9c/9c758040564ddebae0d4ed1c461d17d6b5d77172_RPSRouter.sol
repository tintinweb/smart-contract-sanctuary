/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

// File: contracts/RPS/interfaces/IRPS.sol


pragma solidity ^0.8.0;

interface IRPS {
    function playPVP(address[2] memory _players, bytes32[2] memory _teams, bool _winner, uint8 _betID, uint256 _landTokenId) external;
    function playPVE(address _player, bytes32 _team, bool _winner, uint256 _landTokenId) external;
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/RPS/RPSRouter.sol


pragma solidity ^0.8.0;



contract RPSRouter is Ownable {

    IRPS RPS;
    mapping(address => bool) public isOperator;

    modifier onlyOperator() {
        require(isOperator[msg.sender], "RPSRouter: Not an operator");
        _;
    }

    constructor(address _owner, address _operator, IRPS _rps) {
        _transferOwnership(_owner);
        RPS = _rps;
        isOperator[_operator] = true;
    }

    function bulkSettlementPVP(address[2][] memory _bulkPlayers, bytes32[2][] memory _teamNames, bool[] memory _winners, uint8[] memory _betIds, uint256[] memory _landTokenIds) public onlyOperator {
        require((_bulkPlayers.length == _teamNames.length) && (_winners.length == _betIds.length) && (_betIds.length == _landTokenIds.length), "RPSRouter: Length mismatch");

        for (uint i; i < _bulkPlayers.length; i++) {
            RPS.playPVP(_bulkPlayers[i], _teamNames[i], _winners[i], _betIds[i], _landTokenIds[i]);
        }
        
    }

    function bulkSettlementPVE(address[] memory _bulkPlayers, bytes32[] memory _teamNames, bool[] memory _winners, uint256[] memory _landTokenIds) public onlyOperator {
        require((_bulkPlayers.length == _teamNames.length) && (_winners.length == _landTokenIds.length), "RPSRouter: Length mismatch");

        for (uint i; i < _bulkPlayers.length; i++) {
            RPS.playPVE(_bulkPlayers[i], _teamNames[i], _winners[i], _landTokenIds[i]);
        }
        
    }

    function whitelistOperator(address _operator, bool _value) external onlyOwner {
        require(_operator != address(0), "RPSRouter: Zero address");
        require(isOperator[_operator] != _value, "RPSRouter: Already set");

        isOperator[_operator] = true;
    }
}