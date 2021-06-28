/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity ^0.4.17;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract BetDog is Ownable {
    
    uint cost = 0.005 ether;
    uint rate = 10;
    uint randNonce = 0;
    uint dice = 6;
    
    struct Player{
        address playerAddress;
        uint dice;
        uint betTime;
    }
    
    Player[] public players;
    
    
    function getPool() view public returns(uint){
        return players.length * cost;
    }
    
    function Betting() payable public returns(uint){
        require(msg.value == cost);
        players.push(Player(msg.sender,randMod(dice),block.timestamp));
    }
    
    function Draw() public onlyOwner{
        address[] memory winners = whoIsWinner();
        //开奖
        require(winners.length > 0);
        uint pool = players.length * cost;
        uint fee = (pool * rate) / 100;
        uint bonus = (pool - fee ) / winners.length;
        for (uint i=0;i < winners.length ; i++){
            winners[i].transfer(bonus);
        }
        delete players;
        
    }
    
    function whoIsWinner() private view returns(address[] memory){
        uint max = 0;
        address[] memory winners;
        uint counter = 0;
        for (uint i = 0; i < players.length; i++){
            if ( players[i].dice > max ){
                delete winners;
                counter = 0;
                winners[counter] = players[i].playerAddress;
            } else if( players[i].dice == max ){
                counter ++;
                winners[counter] = players[i].playerAddress;
            }
        }
        return winners;
    }
 
      
      
    function randMod(uint _modulus) private returns(uint) {
        randNonce++;
        return uint(keccak256(block.timestamp, msg.sender, randNonce)) % _modulus;
    }
    
    function withdraw() external onlyOwner {
        owner.transfer(owner.balance);
    }
    
    function setDice(uint _dice) public onlyOwner {
        dice = _dice;
    }
    
}