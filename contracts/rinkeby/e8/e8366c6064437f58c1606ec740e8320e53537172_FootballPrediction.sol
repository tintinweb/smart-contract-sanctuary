/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: contracts/FootballPrediction.sol

pragma solidity ^0.8.0;



contract FootballPrediction is Ownable {
    
    event NewFixture(bytes32 fixtureId, string gameId, uint date);
    event WithdrawWinnings(address player);

    address[] public players;
    address[] public winners;
    bytes32[] public fixtureIds;

    enum resultType {win, lose, draw, noResult} // refers to home teams

    struct Fixture {
        string gameId; // e.g MNUCHE or ARSBRE
        uint date;
        uint16 homeScore;
        uint16 awayScore;
        resultType result;
    }

    struct Prediction {
        bytes32 fixtureId;
        uint16 homeScore;
        uint16 awayScore;
        resultType result;
    }

    mapping (bytes32 => Fixture) public fixtures;
    mapping (address => Prediction[]) public playerToPrediction;
    mapping (address => uint) public playerToAmountDue;

    function createFixture(string memory _game, uint _matchDate) public onlyOwner 
        returns (bytes32) {

        bytes32 fixtureId = keccak256(abi.encode(_game,_matchDate));
        fixtures[fixtureId] = Fixture(_game, _matchDate, 0, 0, resultType.noResult);
        fixtureIds.push(fixtureId);
        
        // Emit an event any time new fixture is created. UI code will listen to this and display
        emit NewFixture(fixtureId, _game, _matchDate);
        
        return fixtureId;
    }

    function balanceOfPot() public view returns (uint) {
        return address(this).balance;
    }
    
    function makePrediction(bytes32 _fixtureId, uint16 _homeScore, uint16 _awayScore)
        external payable {
        
        // Check _fixtureId is valid
        require(fixtures[_fixtureId].date != 0, "Fixture Id is invalid.");

        // Allow prediction entry only if it's entered before the match start time
        require(block.timestamp < fixtures[_fixtureId].date, "Predictions not allowed after match start.");
        
        // Make sure they paid :) For now amount to bet is fixed to 0.01 ether for simplicity
    //    require(msg.value > .001 ether, "Oops - please pay to play!");
        
        // Maintain a list of unique players and also a map of their address and prediction
        if (playerToPrediction[msg.sender].length == 0) {
            players.push(msg.sender);
        }

        resultType result;
        if (_homeScore == _awayScore) {
            result = resultType.draw;
        } else if (_homeScore > _awayScore) {
            result = resultType.win;
        } else {
            result = resultType.lose;
        }

        playerToPrediction[msg.sender].push(Prediction(_fixtureId, _homeScore, _awayScore, result));
    }

    function calculateWinners() external onlyOwner {

        Prediction[] storage playerPredictions;

        for (uint i = 0; i < players.length; i++) {
            playerPredictions = playerToPrediction[players[i]];

            for (uint j = 0; j < playerPredictions.length; j++) {
                if (playerPredictions[j].result == fixtures[playerPredictions[j].fixtureId].result) {
                    winners.push(players[i]);
                }
            } //end of inner for loop
        } //end of outer for loop

        uint perMatchWinnings = balanceOfPot() / winners.length;

        for (uint i = 0; i < winners.length; i++) {
            playerToAmountDue[winners[i]] += perMatchWinnings;
        }

        // Delete fixtures once done to save storage
        for (uint i = 0; i < fixtureIds.length; i++) {
            delete fixtures[fixtureIds[i]];
        }
        delete fixtureIds;
    }

    function updateResultForMatch(bytes32 _fixtureId, uint16 _homeScore, uint16 _awayScore) external onlyOwner {
        Fixture storage matchToUpdate = fixtures[_fixtureId];
        matchToUpdate.homeScore = _homeScore;
        matchToUpdate.awayScore = _awayScore;
        
        if (_homeScore == _awayScore) {
            matchToUpdate.result = resultType.draw;
        } else if (_homeScore > _awayScore) {
            matchToUpdate.result = resultType.win;
        } else {
            matchToUpdate.result = resultType.lose;
        }
    }

    function withdrawWinnings() public { 
        uint amount_due = playerToAmountDue[msg.sender];
        playerToAmountDue[msg.sender] = 0 ether;
        // https://solidity-by-example.org/sending-ether/
        (bool sent, ) = payable(msg.sender).call{value: amount_due}("");
        require(sent, "Failed to send Ether");

        // Emit a withdraw winning event anytime a player withdraws. UI code will listen to this and take any action as needed
        emit WithdrawWinnings(msg.sender);
    }    
}