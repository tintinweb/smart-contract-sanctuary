pragma solidity ^0.4.25;

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
  constructor() public {
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
      
  }

}


contract ForeverChance is Ownable {
    
    event onBingo(address winner, uint256 curr, uint256 playernum, uint256 award);
    
    uint256 private constant decimal = 10000;
    uint256 private constant costPercent = 200;    // 2% to cost
    
    uint256 private maxPot = 0.1 ether;
    uint256 private price = 0.001 ether;
    
    uint256 private currentPot = 0;
    uint256 private costPot = 0;
    address private lastWinner = 0;
    
    address[] private arr_players;
    mapping (address => uint256) map_awards;
    
    uint256 private randseed = 2666;
    
    
    function getCurrentPot() public view returns(uint256){
        return currentPot;
    }
    
    function getPlayerAward(address _addr) public view returns(uint256){
        return map_awards[_addr];
    }
    
    function getLastWinner() public view returns(address){
        return lastWinner;
    }
    
    function getPlayerNum() public view returns(uint256){
        return arr_players.length;
    }
    
    function setting(uint256 _maxPot, uint256 _price) public onlyOwner(){
        maxPot = _maxPot;
        price = _price;
    }
    
    address costaddr = 0xD448a104D1A39981341ac4DbC74172f5766D466a;
    function withdraw() private{
        uint256 award = map_awards[msg.sender];
        if (award > 0){
            map_awards[msg.sender] = 0;
            msg.sender.transfer(award);
        }
        
        if (msg.sender == costaddr){
            msg.sender.transfer(costPot);
            costPot = 0;
        }
    }
    
    function join() private{
        // set player
        require(msg.value%price == 0, "Must be an integer multiple of price.");
        uint256 n = msg.value / price;
        for (uint256 i=0; i<n; i++){
            arr_players.push(msg.sender);
        }
        uint256 cost = msg.value * costPercent / decimal;
        costPot = costPot + cost;
        currentPot = currentPot + msg.value - cost;
    }
    
    function calcBingo() private{
        // calc award
        if(currentPot >= maxPot){
            randseed++;
            uint256 bingocur = uint256( keccak256( abi.encodePacked(blockhash(block.number-1) ,  msg.sender, randseed) ) ) % arr_players.length;
            address bingoaddr = arr_players[bingocur];
            map_awards[bingoaddr] = map_awards[bingoaddr] + currentPot;
            lastWinner = bingoaddr;
            currentPot = 0;
            emit onBingo(bingoaddr, bingocur, getPlayerNum(), currentPot);
        }
    }
    
    function () payable public{
        if (msg.value == 0){
            withdraw();
            return;
        }else{
            join();
            calcBingo();
        }
    }
    
}