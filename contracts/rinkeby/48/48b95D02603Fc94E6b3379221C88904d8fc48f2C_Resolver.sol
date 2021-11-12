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
     * @notice Check if any game is ready for start
     */
    function checkerStartGame() external view returns (bool _canExec, bytes memory _execPayload) {
        uint256[] memory gamesToStart = IRevolverRoll(revolverRoll).getIdsGamesOnWaitingPlayer();
        _canExec = gamesToStart.length > 0;
        gamesToStart = getFrist100(gamesToStart);
        _execPayload = abi.encodeWithSelector(IRevolverRoll.startGame.selector, uint256[](gamesToStart));
    }

    /**
     * @notice Check if any game is ready for finish
     */
    function checkerFinishGame() external view returns (bool _canExec, bytes memory _execPayload) {
        (uint256[] memory gamesToFinish) = IRevolverRoll(revolverRoll).getIdsGamesOnStartedAndRNReady();
        _canExec = gamesToFinish.length > 0;
        gamesToFinish = getFrist100(gamesToFinish);
        _execPayload = abi.encodeWithSelector(IRevolverRoll.startGame.selector, uint256[](gamesToFinish));
    }

    /**
     * @notice Get the frist 100 element form array
     * @param _array: Array
     * @return The new array with the first 100 elements
     */
    function getFrist100(uint256[] memory _array) internal pure returns (uint256[] memory) {
        if (_array.length < 100) {
            return _array;
        }
        else
        {
            uint256[] memory arrayFrist100 = new uint256[](100);
            for (uint256 idx = 0; idx < 100; idx++) {
                arrayFrist100[idx] = _array[idx];
            }
            return arrayFrist100;
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
    function games(uint256 _gameId) external view returns (Status, address, address, address, uint256, uint256, uint256, bytes32);
    function getIdsGamesOnWaitingPlayer() external view returns(uint256[] memory);
    function getIdsGamesOnStartedAndRNReady() external view returns(uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

enum Status {
    NoExisting,
    WaitingToPlayer2,
    PlayersReady,
    Started,
    Claimable,
    Closed,
    Canceled
}