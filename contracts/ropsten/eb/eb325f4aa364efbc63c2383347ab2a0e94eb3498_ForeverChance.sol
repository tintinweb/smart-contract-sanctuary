pragma solidity ^0.4.25;

contract ForeverChance{
    
    uint256 private maxPot = 0.05 ether;
    uint256 private price = 0.01 ether;
    
    uint256 private currentPot = 0;
    address private lastWinner = 0;
    
    address[] private arr_players;
    mapping (address => uint256) map_awards;
    
    
    function getCurrentPot() public view returns(uint256){
        return currentPot;
    }
    
    function getPlayerAward(address _addr) public view returns(uint256){
        return map_awards[_addr];
    }
    
    function getLastWinner() public view returns(address) {
        return lastWinner;
    }
    
    function withdraw() private{
        uint256 award = map_awards[msg.sender];
        if (award > 0){
            map_awards[msg.sender] = 0;
            msg.sender.transfer(award);
        }
    }
    
    function () payable public{
        if (msg.value == 0){
            withdraw();
            return;
        }else{
            // set player
            require(msg.value%price == 0, "Must be an integer multiple of price.");
            uint256 n = msg.value / price;
            for (uint256 i=0; i<n; i++){
                arr_players.push(msg.sender);
            }
            currentPot = currentPot + msg.value;
            
            // calc award
            if(currentPot >= maxPot){
                uint256 bingocur = uint256( keccak256( abi.encodePacked(blockhash(block.number-1) ,  msg.sender) ) ) % arr_players.length;
                address bingoaddr = arr_players[bingocur];
                map_awards[bingoaddr] = map_awards[bingoaddr] + currentPot;
                currentPot = 0;
            }
            
        }
        
    }
    
}