pragma solidity ^0.4.16;
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    function Owned() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
contract JungleScratch is Owned {
    using SafeMath for uint;
    uint public LimitBottom = 0.02 ether;
    uint public LimitTop = 0.1 ether;
    
    address public Drawer;
    struct Game {
        bytes32 SecretKey_P;
        bool isPlay;
        bool isPay;
        uint Result;
        uint Time;
        address Buyer;
        uint value;
    }
    
    mapping (bytes32 => Game) public TicketPool;
    
    event SubmitTicket(bytes32 indexed SecretKey_D_hash, uint Bet_amount,bytes32 SecretKey_P, address Player);   
    event Result(bytes32 SecretKey_D_hash, bytes32 SecretKey_D,address Buyer, uint[] Bird_Result, uint Game_Result, uint time);
    event Pay(bytes32 indexed SecretKey_D_hash, address indexed Buyer, uint Game_Result);
    event Owe(bytes32 indexed SecretKey_D_hash, address indexed Buyer, uint Game_Result);
    event OwePay(bytes32 indexed SecretKey_D_hash, address indexed Buyer, uint Game_Result);
    
    function JungleScratch (address drawer_) public {
        Drawer = drawer_;
    }
    
    function submit(bytes32 secretKey_P, bytes32 secretKey_D_hash) payable public {
        require(msg.value == 0.02 ether || msg.value == 0.04 ether || msg.value == 0.06 ether || msg.value == 0.08 ether || msg.value == 0.1 ether);
        require(TicketPool[secretKey_D_hash].Time == 0);
        require(msg.value >= LimitBottom && msg.value <= LimitTop);
        uint check = msg.value.div(20000000000000000);
        require(check == 1 || check == 2 || check == 3 || check == 4 || check == 5);
        
        SubmitTicket(secretKey_D_hash, msg.value, secretKey_P, msg.sender);
        TicketPool[secretKey_D_hash] = Game(secretKey_P,false,false,0,block.timestamp,msg.sender,msg.value);
    }
    
    function award(bytes32 secretKey_D) public {
        
        require(Drawer == msg.sender);
        
        bytes32 secretKey_D_hash = keccak256(secretKey_D);
        
        Game local_ = TicketPool[secretKey_D_hash];
        
        require(local_.Time != 0 && !local_.isPlay);
        
        uint game_result = 0;
        uint[] memory RandomResult = new uint[](9);
        
        RandomResult[0] = uint(keccak256("Pig World is an AWESOME team",secretKey_D,&#39;a&#39;,local_.SecretKey_P)) % 1000 + 1;
        RandomResult[1] = uint(keccak256(local_.SecretKey_P,"Every Game in our world is provably fair",secretKey_D,&#39;b&#39;)) % 1000 + 1;
        RandomResult[2] = uint(keccak256(&#39;c&#39;,secretKey_D,"OMG it is a revolution dapp",local_.SecretKey_P)) % 1000 + 1;
        RandomResult[3] = uint(keccak256(secretKey_D,"hahahaha",local_.SecretKey_P,&#39;d&#39;,"thanks for our team member and all player support.")) % 1000 + 1;
        RandomResult[4] = uint(keccak256("CC is our CEO",secretKey_D,"he can eat Betel nut",local_.SecretKey_P,&#39;e&#39;)) % 1000 + 1;
        RandomResult[5] = uint(keccak256(20180612,"justin is our researcher",secretKey_D,"and he love little girl(at least 18, so it is ok)",local_.SecretKey_P,&#39;f&#39;)) % 1000 + 1;
        RandomResult[6] = uint(keccak256("jeremy is our marketing",secretKey_D,&#39;g&#39;,local_.SecretKey_P,"he is very humble and serious")) % 1000 + 1;
        RandomResult[7] = uint(keccak256(&#39;h&#39;,secretKey_D,"We are a geek team",local_.SecretKey_P,"we love blockchain")) % 1000 + 1;
        RandomResult[8] = uint(keccak256(secretKey_D,"hope you win a big prize",local_.SecretKey_P,"love you all!!!",&#39;i&#39;)) % 1000 + 1;
        
        for (uint n = 0; n < 9; n++) {
            
            if(RandomResult[n]< 81){
                RandomResult[n] = 0;
            } else if(RandomResult[n]< 168){
                RandomResult[n] = 1;
            } else if(RandomResult[n]< 266){
                RandomResult[n] = 2;
            } else if(RandomResult[n]< 381){
                RandomResult[n] = 3;
            } else if(RandomResult[n]< 535){
                RandomResult[n] = 4;
            } else if(RandomResult[n]< 749){
                RandomResult[n] = 5;
            } else if(RandomResult[n]< 1001){
                RandomResult[n] = 6;
            }
        }
            
        for(uint nn = 0; nn < 6; nn++){
            uint count = 0;
            for(uint p = 0; p < 9; p++){
                if(RandomResult[p] == nn)
                    count ++;
            }
            
            if(count >= 3 && nn == 0)
                game_result = game_result.add(TicketPool[secretKey_D_hash].value.div(20000000000000000).mul(0.1 ether));
                
            if(count >= 3 && nn == 1)
                game_result = game_result.add(TicketPool[secretKey_D_hash].value.div(20000000000000000).mul(0.08 ether));
                
            if(count >= 3 && nn == 2)
                game_result = game_result.add(TicketPool[secretKey_D_hash].value.div(20000000000000000).mul(0.06 ether));
                
            if(count >= 3 && nn == 3)
                game_result = game_result.add(TicketPool[secretKey_D_hash].value.div(20000000000000000).mul(0.04 ether));
                
            if(count >= 3 && nn == 4)
                game_result = game_result.add(TicketPool[secretKey_D_hash].value.div(20000000000000000).mul(0.02 ether)); 
                
            if(count >= 3 && nn == 5)
                game_result = game_result.add(TicketPool[secretKey_D_hash].value.div(20000000000000000).mul(0.01 ether)); 
        }
    
        
        if(game_result != 0){
            TicketPool[secretKey_D_hash].Result = game_result;
            if (address(this).balance >= game_result && TicketPool[secretKey_D_hash].Buyer.send(game_result)) {
                TicketPool[secretKey_D_hash].isPay = true;
                Pay(secretKey_D_hash,TicketPool[secretKey_D_hash].Buyer, game_result);
            } else {
                Owe(secretKey_D_hash, TicketPool[secretKey_D_hash].Buyer, game_result);
                TicketPool[secretKey_D_hash].isPay = false;
            } 
         } else {
            TicketPool[secretKey_D_hash].isPay = true;
        }
        
        Result(secretKey_D_hash, secretKey_D, TicketPool[secretKey_D_hash].Buyer, RandomResult, game_result, block.timestamp);
        TicketPool[secretKey_D_hash].isPlay = true;
    }
    
    function () public payable {
       
    }
    
    function withdraw(uint withdrawEther_) public onlyOwner {
        msg.sender.transfer(withdrawEther_);
    }
    
    function changeLimit(uint _bottom, uint _top) public onlyOwner {
        LimitBottom = _bottom;
        LimitTop = _top;
    }
    
    function changeDrawer(address drawer_) public onlyOwner {
        Drawer = drawer_;
    }
    
    function getisPlay(bytes32 secretKey_D_hash) public constant returns (bool isplay){
        return TicketPool[secretKey_D_hash].isPlay;
    }
    
    function getTicketTime(bytes32 secretKey_D_hash) public constant returns (uint Time){
        return TicketPool[secretKey_D_hash].Time;
    }
    
    function chargeOwe(bytes32 secretKey_D_hash) public {
        require(!TicketPool[secretKey_D_hash].isPay);
        require(TicketPool[secretKey_D_hash].isPlay);
        require(TicketPool[secretKey_D_hash].Result != 0);
        
        if(address(this).balance >= TicketPool[secretKey_D_hash].Result){
            if (TicketPool[secretKey_D_hash].Buyer.send(TicketPool[secretKey_D_hash].Result)) {
                TicketPool[secretKey_D_hash].isPay = true;
                OwePay(secretKey_D_hash, TicketPool[secretKey_D_hash].Buyer, TicketPool[secretKey_D_hash].Result);
            }
        } 
    }
}