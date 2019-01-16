pragma solidity ^0.4.25;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
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
    
    
    uint256[] private maxPotSetting = [1 ether, 2 ether, 4 ether, 8 ether, 16 ether, 32 ether, 64 ether, 128 ether];
    uint256 private maxPotCur = 0;
    uint256 private maxPot = 0;
    uint256 private price = 0.01 ether;
    
    uint256 private currentPot = 0;
    uint256 private costPot1 = 0;
    uint256 private costPot2 = 0;
    
    address[] private arr_players;
    mapping (address => uint256) map_awards;
    
    uint256 private randseed = 2666;
    
    function getPrice() public view returns(uint256){
        return price;
    }
    
    function getCurrentPot() public view returns(uint256){
        return currentPot;
    }
    
    function getRewardPot() public view returns(uint256){
        return maxPot;
    }
    
    function getRewardPotSetting() public view returns(uint256[]){
        return maxPotSetting;
    }
    
    function getPlayerAward(address _addr) public view returns(uint256){
        return map_awards[_addr];
    }
    
    function getPlayerNum() public view returns(uint256){
        return arr_players.length;
    }
    
    function setting(uint256 _maxPot, uint256 _price) public onlyOwner(){
        maxPot = _maxPot;
        price = _price;
    }
    
    address costaddr1 = 0xD448a104D1A39981341ac4DbC74172f5766D466a;
    address costaddr2 = 0x801f63655C71bD628D1677414D9A1A9C24AAC6bD;
    
    function withdraw() private{
        uint256 award = map_awards[msg.sender];
        if (award > 0){
            map_awards[msg.sender] = 0;
            msg.sender.transfer(award);
        }
        
        if (msg.sender == costaddr1){
            msg.sender.transfer(costPot1);
            costPot1 = 0;
        }
        
        if (msg.sender == costaddr2){
            msg.sender.transfer(costPot2);
            costPot2 = 0;
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
        costPot1 = costPot1 + cost/2;
        costPot2 = costPot2 + cost/2;
        currentPot = currentPot + msg.value - cost;
    }
    
    function setNextPot() private{
        if (maxPotCur + 1 < maxPotSetting.length){
            maxPotCur++;
            maxPot = maxPotSetting[maxPotCur];
        }
    }
    
    function calcBingo() private{
        // calc award
        if(currentPot >= maxPot){
            randseed++;
            uint256 bingocur = uint256( keccak256( abi.encodePacked(blockhash(block.number-1) ,  msg.sender, randseed) ) ) % arr_players.length;
            address bingoaddr = arr_players[bingocur];
            map_awards[bingoaddr] = map_awards[bingoaddr] + currentPot;
            emit onBingo(bingoaddr, bingocur, getPlayerNum(), currentPot);
            currentPot = 0;
            setNextPot();
        }
    }
    
    function() payable public{
        if (msg.value == 0){
            withdraw();
            return;
        }else{
            join();
            calcBingo();
        }
    }
    
    constructor() public{
        maxPot = maxPotSetting[0];
    }
    
}