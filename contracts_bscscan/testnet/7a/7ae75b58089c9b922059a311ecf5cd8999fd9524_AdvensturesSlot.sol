/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

// SPDX-License-Identifier: NONE
/** 
 * ver 1.7.10
 * telegram
 * Community
 * https://t.me/fruitsadventures_com
 * 
 * FruitsAdventures News & Announcements
 * https://t.me/fruitsadventures
 * 
 * twitter
 * https://twitter.com/FruitsAdventure
 *
 * medium
 * https://fruitsadventures.medium.com
*/

pragma solidity =0.8.4;

contract Context { 
    constructor()  {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
} 
contract PartnerOwnable is Context {
    address private _owner;
    address private _admin;
    address private _partner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PartnerTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        _admin = msgSender;
        _partner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    function owner_admin() public view returns (address) {
        return _admin;
    }
    function owner_partner() public view returns (address) {
        return _partner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    modifier onlyAdmin() {
        require(_owner == _msgSender() || _admin == _msgSender() , 'Ownable: caller is not the partner');
        _;
    }
    modifier onlyPartner() {
        require(_owner == _msgSender() || _admin == _msgSender() || _partner == _msgSender(), 'Ownable: caller is not the partner');
        _;
    }
    function transferPartner(address newOwner) public onlyPartner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit PartnerTransferred(_partner, newOwner);
        _partner = newOwner;
    }
    function transferAdmin(address newOwner) public onlyAdmin {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit PartnerTransferred(_admin, newOwner);
        _admin = newOwner;
    }
    function transferOwnership(address newOwner) public onlyOwner { 
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


contract AdvensturesSlot is Context, PartnerOwnable { 
    
    event bet_in_amount(BETPARA inputBet); 
    event bet_out(address sender, WINS wins);
    event withdraw_GameFee(address sender, uint256 domainId, address Token, uint256 amount256);
    event withdraw_PartnerAmount(uint256 _tokensId, address tokens_address, address sender, uint256 _amount256);

    
    enum enums { Bar7, Bells, Apple, Lemon, Grape, Orange, Watermelon,Cherry, Luck}
    enums[] public bet_type;
    enums[] public game_layout;
    
    uint[] public game_rate7 = [2,3,9,5,4]; 
    uint[] public game_rate = [4,2,2,0,4,8,6,4,2,2,12,4,6,2,0,4,4,32,2,12,8,2];
    uint[] public game_rate_rand = [0, 0, 0, 1, 1, 2, 2, 2, 2, 3, 3, 4, 4, 4, 5, 5, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 9, 10, 11, 11, 11, 12, 12, 13, 13, 13, 14, 14, 15, 15, 15, 15, 16, 16, 17, 18, 18, 18, 19, 20, 20, 20, 21, 21];
 
    
    uint public random = 0; 
     
    uint public GameRandom7 = 9;
    
    
    
    uint internal seed;
    uint internal randNonce;
    
    uint internal bets_length = 8;
    uint internal amount = 0; 
    BETPARA internal inputBet;
    struct BETPARA {   
        uint256 domainId;
        uint256 tokensId; 
        uint256[] bets; 
    } 
     
    WINS internal wins;
    struct WINS {   
        uint[] wins_layout;
        uint[] wins_type;
        uint[] wins_rate;
        uint wins_random7;
        uint wins_random5;
        uint wins_rate7;
        uint wins_bet;
        uint wins_win;
        uint wins_fee;
        uint wins_result;
    } 
    
    struct TOKENS {   
        uint256 tokensId;
        bytes  tokens_symbol; 
        address tokens_address; 
        uint256 tokens_least;
        uint256 tokens_cake_balance; 
        uint256 updateTime;
    } 
    uint public tokensLength = 0;
    mapping(uint => TOKENS) public tokensInfo;
    function tokens_create(address _tokens_address, bytes memory _symbol, uint256 _least) public onlyPartner {   
        uint256 tokensId = tokensLength++;
        TOKENS storage tk = tokensInfo[tokensId];
        tk.tokensId = tokensId;
        tk.tokens_symbol = _symbol;
        tk.tokens_least = _least;
        tk.tokens_address = _tokens_address;  
        tk.updateTime = block.timestamp; 
    }
    function tokens_set(uint256 _tokensId, address _tokens_address, bytes memory _symbol, uint256 _least) public onlyPartner {   
        TOKENS storage tk = tokensInfo[_tokensId];
        if(_tokens_address!=address(0)) tk.tokens_address = _tokens_address;   
        if(_symbol.length!=0) tk.tokens_symbol = _symbol;
        tk.tokens_least = _least;
        tk.updateTime = block.timestamp; 
    }
 
	    
    struct DOMAIN {   
        uint256 domainId;
        bytes domain_name;  
        uint256 domain_fee_rate; 
        address domain_fee_address; 
        mapping(address => uint256) domain_fee_amount; 
        uint256 updateTime;
    }   
    uint public domainLength = 0;
    mapping(uint => DOMAIN) public domainInfo;
    function domain_create(string memory _domain_name, uint256 _domain_fee_rate, address _domain_fee_address) public onlyPartner {   
        uint256 domainId = domainLength++;
        DOMAIN storage dm = domainInfo[domainId];
        dm.domainId = domainId;
        dm.domain_name = bytes(_domain_name);
        dm.domain_fee_rate = _domain_fee_rate; 
        dm.domain_fee_address = _domain_fee_address;  
        dm.updateTime = block.timestamp;  
    }
    function domain_set(uint256 _domainId,string memory _domain_name, uint256 _domain_fee_rate, address _domain_fee_address) public onlyPartner {   
        DOMAIN storage dm = domainInfo[_domainId];  
        if(bytes(_domain_name).length>0)dm.domain_name = bytes(_domain_name);
        if(_domain_fee_address!=address(0)) dm.domain_fee_address = _domain_fee_address; 
        dm.domain_fee_rate = _domain_fee_rate; 
        dm.updateTime = block.timestamp; 
    }
    
    
	constructor()   { 
	     
	    
	    address msgSender = _msgSender(); 
        emit OwnershipTransferred(address(0), msgSender);
        
	    bet_type = [enums.Bar7, enums.Bells, enums.Apple, enums.Lemon, enums.Grape, enums.Orange, enums.Watermelon, enums.Cherry];
	    game_layout = [
                    enums.Orange, enums.Grape, enums.Apple, enums.Luck, enums.Cherry, enums.Bells, enums.Grape,
                    enums.Cherry, enums.Orange, enums.Apple, enums.Watermelon, 
                    enums.Orange, enums.Grape, enums.Lemon, enums.Luck, enums.Apple, enums.Bells, enums.Bar7,
                    enums.Cherry, enums.Watermelon, enums.Lemon, enums.Bells
                    ]; 
           
	    //max=uint(game_layout.length);
	    seed = block.timestamp;
        randNonce = 1;
        
        inputBet.bets = [0,0,0,0,0,0,0,0];
        tokens_create(0x4ECfb95896660aa7F54003e967E7b283441a2b0A,bytes('FRUIT'),1000); // FRUIT
        tokens_create(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82,bytes('CAKE'),100); // CAKE
        tokens_create(0x31508f0098A2566074EcCC94a0900721386D0C4b,bytes('CAKE'),100); // CAKE
        domain_create("fruitsadvenstures", 20, 0x2037f7E7242abd6B71938fb83D2c65DE5D4A42B0);
        domain_create("APE", 20, 0x288aE6c4fcB11771359f9Ee33855043E76C0a8fa);
        
        wins.wins_layout = new uint[](4);
        wins.wins_type = new uint[](4);
        wins.wins_rate = new uint[](4);
        
    }
    
       
     
    function setGameRandom7(uint256 _GameRandom7) external onlyPartner { 
        GameRandom7 = _GameRandom7;
    }
    function setGame_rate_rand(uint256 _index, uint256 _rate) external onlyPartner { 
        game_rate_rand[_index] = _rate;
    }
    
    function withdrawGameFee(uint256 _domainId, address FRUIT, uint256 _amount256) external { 
        address GameFeeAddress = domainInfo[_domainId].domain_fee_address;
        uint256 GameFeeAmount = domainInfo[_domainId].domain_fee_amount[FRUIT]; 
        require(msg.sender==GameFeeAddress,'AdvensturesSlot: widthdrawGameFee_address_error');
        require(GameFeeAmount > _amount256,'AdvensturesSlot: widthdrawGameFee_amount_error');
        domainInfo[_domainId].domain_fee_amount[FRUIT] -= _amount256;
        TransferHelper.safeTransfer(FRUIT, msg.sender, _amount256); 
        emit withdraw_GameFee(msg.sender, _domainId, FRUIT, _amount256);
    }
    
    function withdrawPartnerFee(uint _domainId, address FRUIT, uint256 _amount256) external onlyAdmin {  
        uint256 GameFeeAmount = domainInfo[_domainId].domain_fee_amount[FRUIT]; 
        require(GameFeeAmount > _amount256,'AdvensturesSlot: withdrawPartnerFee_error'); 
        domainInfo[_domainId].domain_fee_amount[FRUIT] -= _amount256;
        TransferHelper.safeTransfer(FRUIT, msg.sender, _amount256); 
        emit withdraw_GameFee(msg.sender, _domainId, FRUIT, _amount256);
    }
    
    function withdrawTokenAmount(uint _tokensId, uint256 _amount256) external onlyAdmin {  
        uint256 tokens_cake_balance = tokensInfo[_tokensId].tokens_cake_balance; 
        require(tokens_cake_balance > _amount256,'AdvensturesSlot: withdrawTokenAmount_error'); 
        tokensInfo[_tokensId].tokens_cake_balance -= _amount256;
        TransferHelper.safeTransfer(tokensInfo[_tokensId].tokens_address, msg.sender, _amount256); 
        emit withdraw_PartnerAmount(_tokensId, tokensInfo[_tokensId].tokens_address, msg.sender, _amount256);
    }
     
 
    function bet(uint[] calldata bets,uint domainId, uint tokensId) external  
                returns(uint win_tot, WINS memory _wins){
	    
        uint tot_bet =0;
	    for(uint i = 0 ; i < bets_length ; i++){
	        tot_bet += uint(bets[i]);     
	        inputBet.bets[i] = bets[i];
	    }   
	    inputBet.domainId = domainId;
	    inputBet.tokensId = tokensId; 
	    emit bet_in_amount(inputBet);
         
        play_start();  
        require(wins.wins_type[0] < game_rate.length , 'AdvensturesSlot: wins.wins_type[0] game_rate.length error' ); 
        
        if(wins.wins_rate[0]==0){ // get lucky
            win_tot = 0;
            if(wins.wins_type[1] < bets_length) win_tot += bets[wins.wins_type[1]] * wins.wins_rate[1];
            if(wins.wins_type[2] < bets_length) win_tot += bets[wins.wins_type[2]] * wins.wins_rate[2];
            if(wins.wins_type[3] < bets_length) win_tot += bets[wins.wins_type[3]] * wins.wins_rate[3];
        } else {  
            win_tot = bets[wins.wins_type[0]] * wins.wins_rate[0];
        } 
        win_tot = win_tot * wins.wins_rate7; 
         
        uint256 tokens_cake_balance = tokensInfo[tokensId].tokens_cake_balance;
        if( win_tot > tokens_cake_balance ) {
            wins.wins_layout[0] = 1;
            wins.wins_type[0] = 4;
            wins.wins_rate[0] = 2;
            wins.wins_random7 = 0;
            wins.wins_random5 = 0;
            wins.wins_rate7 = 1;
            win_tot = bets[wins.wins_type[0]] * wins.wins_rate[0];
        }
        uint256 fee1 = win_tot * domainInfo[0].domain_fee_rate / 1000; // share from user
        uint256 fee2 = win_tot * domainInfo[domainId].domain_fee_rate / 1000; //share from game machine
        wins.wins_bet = tot_bet;
        wins.wins_win = win_tot;
        wins.wins_fee = fee1;
        uint256 win_total = win_tot - fee1;
           
        address FRUIT = tokensInfo[tokensId].tokens_address;
        domainInfo[0].domain_fee_amount[FRUIT] += fee1;
        domainInfo[domainId].domain_fee_amount[FRUIT] += fee2;
        tokensInfo[tokensId].tokens_cake_balance += amount;
        if( win_total < tot_bet ) {
            //loss
            wins.wins_result = 1;
            amount = tot_bet - win_total; 
            require(amount>0,'AdvensturesSlot: bet_play_start_error'); 
            TransferHelper.safeTransferFrom(FRUIT, msg.sender, address(this), amount); 
        } else if(win_total > tot_bet) {
            //win
            wins.wins_result = 2;
            amount = win_total - tot_bet;
            TransferHelper.safeTransfer(FRUIT, msg.sender, amount);  
        } else {
            wins.wins_result = 3; 
        }
        emit bet_out(msg.sender, wins);
        _wins = wins; 
        
        
    }
    
    function play_start() internal {  
        uint rand=0;
        wins.wins_layout = [0,0,0,0];
        wins.wins_type = [0,0,0,0];
        wins.wins_rate = [0,0,0,0];
        wins.wins_random7 = 0;
        wins.wins_random5 = 0;
        wins.wins_rate7 = 1;
    
        rand = randomize_game_rate_rand(); // randomize one of game_layout index 0-21 < 22  
        wins.wins_layout[0] = rand;
        wins.wins_rate[0] = game_rate[rand];
        wins.wins_type[0] = uint(game_layout[rand]);
        if(wins.wins_rate[0]==0){
            
            rand = randomize_unlock();
            wins.wins_layout[1] = rand;
            wins.wins_rate[1] = game_rate[rand];
            wins.wins_type[1] = uint(game_layout[rand]);
             
            rand = randomize_unlock(); 
            if(rand != wins.wins_layout[1]){ 
                wins.wins_layout[2] = rand;
                wins.wins_rate[2] = game_rate[rand];
                wins.wins_type[2] = uint(game_layout[rand]);
                rand = randomize_unlock(); 
                if(rand != wins.wins_layout[1] && rand != wins.wins_layout[2]){ 
                    wins.wins_layout[3] = rand;
                    wins.wins_rate[3] = game_rate[rand];
                    wins.wins_type[3] = uint(game_layout[rand]);
                } 
            } else {
                rand = randomize_unlock(); 
                if(rand != wins.wins_layout[1]){ 
                    wins.wins_layout[2] = rand;
                    wins.wins_rate[2] = game_rate[rand];
                    wins.wins_type[2] = uint(game_layout[rand]);
                } 
            }  
            
        }
        wins.wins_random7 = randomize(0,GameRandom7);  // special prize
        if(wins.wins_random7==7){
            wins.wins_random5 = randomize(0,5);
            wins.wins_rate7 = game_rate7[wins.wins_random5];
        }
        
    } 
 
    function randomize(uint _min, uint _max) internal  returns (uint) { 
        randNonce ++;
        randNonce = randNonce % 32767;
        seed = uint(keccak256(abi.encode(seed, block.number, block.coinbase, randNonce, block.timestamp)));  
        return _min + ( seed % (_max - _min) );
    }
    
    function randomize_unlock() internal returns (uint) { 
        uint rand = randomize_game_rate_rand();
        if(rand==12 || rand==3) rand = randomize_unlock(); 
        return rand;
    }
    
    function randomize_game_rate_rand() internal  returns (uint) { 
        randNonce ++;
        randNonce = randNonce % 32767;
        seed = uint(keccak256(abi.encode(seed, block.number, block.coinbase, randNonce, block.timestamp)));  
        uint s = seed % game_rate_rand.length; 
        return game_rate_rand[s];
    }
    
	 
}