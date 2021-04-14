/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;

/**
 * @dev Little contract to play a game with visitors of botcito.me
 */
contract Botcito {
    
    struct Player {
        uint256[] games;
        uint256 payoutIndex;
    }
    
    address public owner = msg.sender;
    
    uint256 public playAmount = 1e16; // 0.01 BNB
    uint256 public winAmount = 5e16; // 0.05 BNB
    uint8 public possibleValues = 36;
    uint8 public minWinValue = 30;
    
    uint256 private verificationBlockDelta = 1;

    uint256 private gameCount = 0;
    
    mapping(address => Player) public players;
    mapping(uint256 => uint256) public gameBlocks;
    
    modifier onlyBy(address _account) {
        require( msg.sender == _account, "Not authorized");
        _;
    }
    
    function getBalance(address _player) public view returns (uint256) {
        Player memory _p = players[_player];
        uint256 _count =  _p.games.length;
        uint256 _balance = 0;
        for(uint256 _i = _p.payoutIndex; _i < _count; _i++) {
            if (isGameWin(_p.games[_i])) {
                _balance += winAmount;
            }
        }
        return _balance;
    }
    
    function isGameWin(uint256 _gameNumber) public view returns (bool) {
        uint8 _result = getGameResult(_gameNumber);
        return _result >= minWinValue;
    }
    
    function getGameResult(uint256 _gameNumber) public view returns (uint8) {
        return uint8(uint256(blockhash(gameBlocks[_gameNumber] + verificationBlockDelta)) % possibleValues);
    }
    
    function changeGameConfig(uint256 _playAmount, uint256 _winAmount, uint8 _possibleValues, uint8 _minWinValue) external onlyBy(owner) {
        playAmount = _playAmount;
        winAmount = _winAmount;
        possibleValues = _possibleValues;
        minWinValue = _minWinValue;
    }
    
    function play() external payable {
        require(msg.value == playAmount, "Invalid amount sent");
        
        // store block number of this game
        gameBlocks[gameCount] = block.number;
        players[msg.sender].games.push(gameCount);
        gameCount++;
        
    }
    
    function cashout() external {
        uint256 _balance = getBalance(msg.sender);

        require(address(this).balance >= _balance, "Not enough reserves");
        
        players[msg.sender].payoutIndex = players[msg.sender].games.length;
        payable(msg.sender).transfer(_balance);
    }
    
    function withdraw(uint256 _amount) external onlyBy(owner) {
        require(address(this).balance >= _amount, "Invalid amount sent");
        payable(owner).transfer(_amount);
    }

}