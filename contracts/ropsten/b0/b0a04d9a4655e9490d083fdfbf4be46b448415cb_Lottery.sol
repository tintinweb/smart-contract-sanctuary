contract Lottery {
    uint public lotteryValue;
    uint numPlayers;
    mapping(address => uint256) playing; //maps address to  etherAmt
    address[5] addressLookup; //allows lookup of address
    
    constructor() public{
        lotteryValue = 0;
        numPlayers = 0;
    }
    
    function participate() public payable{
        lotteryValue += msg.value;
        if(playing[msg.sender] == 0){//check if player already is participating. If they are increase their participation amount (shouldn&#39;t have participated more than once)
            addressLookup[numPlayers] = msg.sender;
            numPlayers++;
        }
         playing[msg.sender] += msg.value;
        
        if(numPlayers == 5){
            payAndReset();
        }
    }

    function payAndReset() private{
        uint winner = random() % 5;
        addressLookup[winner].transfer(lotteryValue);
        for(uint i = 0; i < 5; i++){
            playing[addressLookup[i]] = 0;
            addressLookup[i] = 0;
        }
        numPlayers = 0;
        lotteryValue = 0;
    }
    
    function random () private view returns(uint) {
        return uint(keccak256(block.difficulty, now, addressLookup));
    }

   
}