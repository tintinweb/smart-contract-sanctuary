// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./Enums/Status.sol";
import "./Interfaces/IRevolverRoll.sol";

contract Resolver {

    address public immutable revolverRoll;

    constructor(address _revolverRoll) {
        require(_revolverRoll != address(0), "ADDRESS_ZERO");
        revolverRoll = _revolverRoll;
    }

    /**
     * @notice Check if game is ready for start
     */
    function checkerStartGame() external view returns (bool canExec, bytes memory execPayload) {
        uint256 lastGameId = IRevolverRoll(revolverRoll).lastGameId();
        for (uint256 i=0; i <= lastGameId; i++){
            (Status status, , , , , ,) = IRevolverRoll(revolverRoll).games(i);
            if (status == Status.PlayersReady) {
                canExec = true;
                execPayload = abi.encodeWithSelector(IRevolverRoll.startGame.selector, uint256(i));        
            }
        }
    }

    /**
     * @notice Check if game is ready for finish
     */
    function checkerFinishGame() external view returns (bool canExec, bytes memory execPayload) {
        uint256 lastGameId = IRevolverRoll(revolverRoll).lastGameId();
        for (uint256 i=0; i <= lastGameId; i++){
            (Status status, , , , , ,) = IRevolverRoll(revolverRoll).games(i);
            if (status == Status.Started) {
                canExec = true;
                execPayload = abi.encodeWithSelector(IRevolverRoll.finishGame.selector, uint256(i));        
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "../Enums/Status.sol";

interface IRevolverRoll {
    function createGame() external payable;
    function enterGame(uint256 _gameId) external payable;
    function startGame(uint256 _gameId) external;
    function finishGame(uint256 _gameId) external;    
    function claimPrize(uint256 _gameId) external ;
    function whitdraw() external;
    function withdrawTokens(address _tokenAddress, uint256 _tokenAmount) external;
    function lastGameId() external view returns (uint256);
    function games(uint256 _gameId) external view returns (Status, address, address, address, uint256, uint256, bytes32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

enum Status {
    NoExisting,
    WaitingToPlayer2,
    PlayersReady,
    Started,
    Claimable,
    Closed
}