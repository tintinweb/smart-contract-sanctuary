pragma solidity ^0.6.12;

import './dodo.sol';
// import './testCoin.sol';

/**
 * @dev Collection of functions related to the address type
 */

contract Lottery {
    using SafeMath for uint256;
    using Address for address;
    
    //Token contract
    DOYCOINOfficialMain dodo;
    
    //propotion of fee cut
    uint256 public winnerCut = 800;
    uint256 public poolCut = 100;
    uint256 public feeWalletCut = 100;
    
    //developer wallet
    address public devWallet;
    
    //total players
    uint256 public maxPlayer = 3;
    
    //fee structure
    uint256 public currentFee = 200 * 10**2;
    uint256 public currentTotal = 200 * 3 * 10**2; 
    
    //player array
    address[3] public players;
    
    //currentCount to track the players in the field
    uint256 public currentCount;
    
    //lastWinner of the lottery
    address public lastWinner;
    
    //boolean for claim 
    bool public is_claimed = true;
    
    constructor (address payable _tokenAddress, address payable _devWallet) public{
        dodo = DOYCOINOfficialMain(_tokenAddress);
        devWallet = _devWallet;
        currentCount = 0;
    }
    
    
    //payer can call this to participate in the game
    //the transfer amount must be allowed to transfer through the contract
    function participateInGame(uint256 valueSent) public payable{
        require(valueSent == currentFee, "You must send 200 tokens to participate in game");
        dodo.transferFrom(msg.sender, address(this) ,currentFee);
        
        currentCount += 1;
        uint256 currentPlayerCount = currentPlayersNumber();
        players[currentPlayerCount] = msg.sender;
        
        if(currentPlayerCount == 0){
            uint256 winnerCount = chooseWinner();
            lastWinner = players[winnerCount];
            transferToDev();
            is_claimed = false;
        }
    }
    
    function currentPlayersNumber() public view returns(uint256){
        return currentCount % maxPlayer;
    }
    
    //choose the winer count
    function chooseWinner() internal returns(uint256){
        uint256 winnerAddressCount = (uint256(keccak256(abi.encodePacked(block.timestamp))) + currentCount) % maxPlayer;
        return winnerAddressCount;
    }
    
    
    //trasfer amount to the winner
    function transferToDev() internal{
        uint256 feeWalletCutAmount = currentTotal.mul(feeWalletCut).div(1000);
        uint256 winAmount = currentTotal.mul(winnerCut).div(1000);

        dodo.transfer(devWallet, feeWalletCutAmount);
    }
    
    //called to claim the price by winner
    function claimPrize() public{
        require(msg.sender == lastWinner, "You are not the winner!");
        require(!is_claimed, "Amount Already Claimed.");
        is_claimed = true;
        
        uint256 winAmount = currentTotal.mul(winnerCut).div(1000);
        dodo.transfer(lastWinner, winAmount);
    }
}