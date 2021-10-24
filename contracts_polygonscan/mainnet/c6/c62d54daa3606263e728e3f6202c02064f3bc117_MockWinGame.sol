/**
 *Submitted for verification at polygonscan.com on 2021-10-24
*/

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: contracts/IWinnerTable.sol

pragma solidity ^0.8.2;

abstract contract IWinnerTable {

    enum GState {NotActive, Active, END}

    GState private cgState;

    event NewWinner(address user);

    modifier gameNotActivated() {
        require(cgState == GState.NotActive, "tournament finished");
        _;
    }

    function isWinner(address user) external view virtual returns (bool);

    function getWinners() external view virtual returns (address[] memory);

    function inheritAndStart(address prevWinnableGame) external virtual;

    function gameState() external view returns (GState) {
        return _gameState();
    }

    function _gameState() internal view returns (GState) {
        return cgState;
    }

    function _setState(GState state) internal virtual {
        require(state != GState.NotActive, "can't set not active");
        if (state == GState.Active) {
            require(cgState == GState.NotActive, "allowed transition NotActive => Active");
        } else if (state == GState.END) {
            require(cgState == GState.Active, "allowed transition NotActive => Active");
        }
        cgState = state;
    }
}

// File: contracts/IGameCoordinator.sol

pragma solidity ^0.8.2;

interface IGameCoordinator {
    event TicketSold(address buyer, uint256 ticketID);
    event Game(address contractAddress);

    function getTicketPrice() external view returns (uint256);

    function getTicketID(address owner) external view returns (uint256);

    function getAddressByTicketID(uint256 ticketID) external view returns (address);

    function getAvailableTickets() external view returns (uint256);

    function getLimit() external view returns (uint256);

    function getSold() external view returns (uint256);

    function buy() external;

    function startNextGame(address contractAddress) external;

    function getGameCurrentNumber() external view returns (uint256);

    function getGameAddressByNumber(uint256 number)
        external
        view
        returns (address);

    function getFeeBalance() external view returns (uint256);

    function getCollectedPrize() external view returns (uint256);

    function tournamentActive() external view returns (bool);

    function payWinners() external;

    function payFees() external;

    function getTournamentFinished() external view returns (bool);
}

// File: contracts/MockWinGame.sol

pragma solidity ^0.8.2;




contract MockWinGame is IWinnerTable, Ownable {
    IGameCoordinator private gameCoordinator;
    address[] private winners;

    constructor(address gameCoordinatorAddress) {
        gameCoordinator = IGameCoordinator(gameCoordinatorAddress);
    }

    function setWinners(address winner) public onlyOwner {
        winners.push(winner);
    }

    function AllWin() public onlyOwner {
        gameCoordinator.payWinners();
    }

    function isWinner(address) external pure override returns (bool) {
        return false;
    }

    function getWinners() external view override returns (address[] memory) {
        return winners;
    }

    function inheritAndStart(address prevWinnableGame) external virtual override {}
}