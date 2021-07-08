/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: NONE
/** 
 * ver 1.7.8
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

interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IFruitsToken { 

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
 
	//-------------------------- end BEP20

    function mint(address _to, uint256 _amount) external;  

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    function delegates(address delegator) external view returns (address);

    function delegate(address delegatee) external;

    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;

    function getCurrentVotes(address account) external view returns (uint256);

    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);

}

interface IWBNB { 

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);  

    function deposit() external payable;
    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad) external returns (bool);
}


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
contract Ownable is Context {
    address private _owner;
    address private _partner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PartnerTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    modifier onlyPartner() {
        require(_owner == _msgSender() || _partner == _msgSender(), 'Ownable: caller is not the partner');
        _;
    }
    function transferPartner(address newOwner) public onlyPartner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit PartnerTransferred(_partner, newOwner);
        _partner = newOwner;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
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


contract AdvensturesSlot is Context,Ownable { 
    
    event bet_in_amount(address sender, uint bet1, uint bet2, uint bet3, uint bet4, uint bet5, uint bet6, uint bet7, uint bet8); 
    event bet_out_win(address sender, uint256 tot_bet, uint256 win_tot, string wins_layout, string wins_type, string wins_rate, uint win7_rate);
    event bet_out_loss(address sender, uint256 tot_bet, uint256 win_tot, string wins_layout, string wins_type, string wins_rate, uint win7_rate);
    event bet_out_tie(address sender, uint256 tot_bet, uint256 win_tot, string wins_layout, string wins_type, string wins_rate, uint win7_rate);
    event withdraw_GameFee1(address sender, address Token, uint256 amount256);
    event withdraw_GameFee2(address sender, address Token, uint256 amount256);
    event withdraw_partner(address sender, address Token, uint256 amount256);
    
    enum enums { Bar7, Bells, Apple, Lemon, Grape, Orange, Watermelon,Cherry, Luck}
    enums[] public bet_type;
    enums[] public game_layout;
    uint[] public game_rate;
    uint[] public game_rate_rand;
    uint[] public game_rate7 = [2,3,9,5,4]; 
    
     
    uint public random = 0;
    uint public random7 = 0;
    uint public min = 0;
    uint public max = 0;
    uint[] public wins_layout = [0,0,0,0];
    uint[] public wins_type = [0,0,0,0];
    uint[] public wins_rate = [0,0,0,0];
    uint public win7 = 0;
    uint public win7_rate = 0;
    uint public GameRandom7 = 9;
    uint256 supply = 0;
    
    address public FRUIT = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public GameFeeAddress1 = 0x2037f7E7242abd6B71938fb83D2c65DE5D4A42B0; 
    address public GameFeeAddress2 = 0x7FD69663955faFC309a052b19769AE5202598982; // must approve this game address
    uint256 public GameFeeAmount1 = 0;
    uint256 public GameFeeAmount2 = 0;
    uint256 public GameFeeRate1 = 20;
    uint256 public GameFeeRate2 = 20;
    uint256 public amount = 0;
    uint256 public GameCakeBalance = 0;
  
    string public wins_layout_str = "";
    string public wins_type_str = "";
    string public wins_rate_str = ""; 
    
    uint internal seed;
    uint internal randNonce;
	    
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
        game_rate = [4,2,2,0,4,8,6,4,2,2,12,4,6,2,0,4,4,32,2,12,8,2];
        game_rate_rand = [0, 0, 0, 1, 1, 2, 2, 2, 2, 3, 3, 4, 4, 4, 5, 5, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 9, 10, 11, 11, 11, 12, 12, 13, 13, 13, 14, 14, 15, 15, 15, 15, 16, 16, 17, 18, 18, 18, 19, 20, 20, 20, 21, 21];
        
	    max=uint(game_layout.length);
	    seed = block.timestamp;
        randNonce = 1;
        
        
    }
   
    
 
     
    function setFruitAddress(address _FRUIT) external onlyOwner { 
        FRUIT = _FRUIT;
    }
    function setGameFeeAddress1(address _GameFeeAddress) external onlyOwner { 
        GameFeeAddress1 = _GameFeeAddress;
    }
    function setGameFeeAddress2(address _GameFeeAddress) external onlyOwner { 
        GameFeeAddress2 = _GameFeeAddress;
    }
    function setGameFeeAmount1(uint256 _GameFeeAmount) external onlyOwner { 
        GameFeeAmount1 = _GameFeeAmount;
    }
    function setGameFeeAmount2(uint256 _GameFeeAmount) external onlyOwner { 
        GameFeeAmount2 = _GameFeeAmount;
    }
    function setGameFeeRate1(uint256 _GameFeeRate) external onlyOwner { 
        GameFeeRate1 = _GameFeeRate;
    }
    function setGameFeeRate2(uint256 _GameFeeRate) external onlyOwner { 
        GameFeeRate2 = _GameFeeRate;
    }
     
    function setGameRandom7(uint256 _GameRandom7) external onlyPartner { 
        GameRandom7 = _GameRandom7;
    }
    function setGame_rate_rand(uint256 _index, uint256 _rate) external onlyPartner { 
        game_rate_rand[_index] = _rate;
    }
    
    function withdrawGameFee1(uint256 _amount256) external { 
        require(msg.sender==GameFeeAddress1,'AdvensturesBar: widthdrawGameFee1_error1');
        require(GameFeeAmount1 > _amount256,'AdvensturesBar: widthdrawGameFee1_error2');
        GameFeeAmount1 -= _amount256;
        TransferHelper.safeTransfer(FRUIT, msg.sender, _amount256); 
        emit withdraw_GameFee1(msg.sender, FRUIT, _amount256);
    }

    function withdrawGameFee2(uint256 _amount256) external { 
        require(msg.sender==GameFeeAddress2,'AdvensturesBar: widthdrawGameFee2_error1');
        require(GameFeeAmount2 > _amount256,'AdvensturesBar: widthdrawGameFee2_error2');
        GameFeeAmount2 -= _amount256;
        TransferHelper.safeTransfer(FRUIT, msg.sender, _amount256); 
        emit withdraw_GameFee2(msg.sender, FRUIT, _amount256);
    }
    
    function withdrawPartner(uint256 _amount256) external onlyPartner {  
        require(GameCakeBalance > _amount256,'AdvensturesBar: withdrawPartner');
        GameCakeBalance -= _amount256;
        TransferHelper.safeTransfer(FRUIT, msg.sender, _amount256); 
        emit withdraw_partner(msg.sender, FRUIT, _amount256);
    }
     
 
    function bet(uint[] calldata bets) external  returns(uint win_tot, uint r7_rate, uint[] memory _rate, uint[] memory _type, uint[] memory _layout){
         
	    emit bet_in_amount(msg.sender, bets[0], bets[1], bets[2], bets[3], bets[4], bets[5], bets[6], bets[7]);
        
        uint tot_bet =0;
	    for(uint i=0;i<bets.length;i++){
	        tot_bet += uint(bets[i]);       
	    } 
         
        play_start(); 
         
        _rate = wins_rate;
        _type = wins_type;
        _layout = wins_layout;
        r7_rate = win7_rate; 
        
        win_tot = 0;
        
        if(wins_rate[0]==0){
            if(wins_type[1] < bets.length) win_tot += bets[wins_type[1]] * wins_rate[1];
            if(wins_type[2] < bets.length) win_tot += bets[wins_type[2]] * wins_rate[2];
            if(wins_type[3] < bets.length) win_tot += bets[wins_type[3]] * wins_rate[3];
        } else if(wins_type[0] < bets.length){  
            win_tot += bets[wins_type[0]] * wins_rate[0];
        } 
        win_tot = win_tot * r7_rate; 
         
        if( win_tot > GameCakeBalance ) {
            wins_type[0] = 1;
            wins_rate[0] = 2;
            win7_rate = 0;
            win_tot = bets[wins_type[0]] * wins_rate[0];
        }
        uint256 fee1 = win_tot * GameFeeRate1 / 1000;
        uint256 fee2 = win_tot * GameFeeRate2 / 1000;
        uint256 win_total = win_tot - fee1 - fee2;
           
        GameFeeAmount1 += fee1;
        GameFeeAmount2 += fee2;
        GameCakeBalance += tot_bet - win_total;
        
        if(tot_bet > win_total) {
            uint256 amount1 = tot_bet - win_total;
            TransferHelper.safeTransferFrom(FRUIT, msg.sender, address(this), amount1); 
            emit bet_out_win(msg.sender, tot_bet, win_total, wins_layout_str, wins_type_str, wins_rate_str, win7_rate);
        } else if(tot_bet < win_total) {
            uint256 amount2 = win_total - tot_bet;
            TransferHelper.safeTransfer(FRUIT, msg.sender, amount2); 
            emit bet_out_loss(msg.sender, tot_bet, win_total, wins_layout_str, wins_type_str, wins_rate_str, win7_rate);
        } else {
            emit bet_out_tie(msg.sender, tot_bet, win_total, wins_layout_str, wins_type_str, wins_rate_str, win7_rate);
        }
        
	    wins_layout_str = uintarrayToString(wins_layout);
        wins_type_str = uintarrayToString(wins_type);
        wins_rate_str = uintarrayToString(wins_rate); 
        
        
    }
    
    function play_start() internal {  
        uint rand=0;
        wins_layout = [0,0,0,0];
        wins_type = [0,0,0,0];
        wins_rate = [0,0,0,0];
    
        random7 = randomize(0,GameRandom7);  
        random = randomize_game_rate_rand();   
        wins_layout[0] = random;
        wins_type[0] = uint(game_layout[random]);
        wins_rate[0] = game_rate[random];
        if(wins_rate[0]==0){
             
            uint index = 1;
            rand = randomize_unlock();
            wins_layout[index] = rand;
            wins_rate[index]=game_rate[rand];
            wins_type[index] = uint(game_layout[rand]);
             
            rand = randomize_unlock(); 
            if(rand != wins_layout[index]){
                index++;
                wins_layout[index] = rand;
                wins_rate[index]=game_rate[rand];
                wins_type[index] = uint(game_layout[rand]);
            }   
            
            rand = randomize_unlock(); 
            if(rand != wins_layout[index]){
                index++;
                wins_layout[index] = rand;
                wins_rate[index]=game_rate[rand];
                wins_type[index] = uint(game_layout[rand]);
            } 
            
        }
        if(random7==7){
            randNonce++;
            win7 = randomize(0,5);
            win7_rate = game_rate7[win7];
        } else {
            win7 = 9999;
            win7_rate = 1;
        } 
    } 
 
    function randomize(uint _min, uint _max) internal  returns (uint) { 
        randNonce ++;
        randNonce = randNonce % 32767;
        seed = uint(keccak256(abi.encode(seed, block.number, block.coinbase, randNonce, block.timestamp)));  
        return _min + (seed % _max);
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
    
    function uintarrayToString(uint[] memory uintArray) internal pure returns (string memory str) {
        str = "";
        for(uint i=0;i<uintArray.length;i++){
            string memory s = uintToString(uintArray[i]);
            
            str = string(abi.encodePacked(str, " ", s));
        }
    }
    
    function uintToString(uint v) internal pure returns (string memory str) {
        if(v==0) return "0";
        uint vv = v;
        uint len;
        while (vv != 0) {
            len++;
            vv = uint(vv / 10);
        }
        bytes memory bstr = new bytes(len); 
        while (len > 0) {
            len--;
            bstr[len] = bytes1(uint8(48 + v % 10));
            v /= 10;
        }  
        return string(bstr);
    }
	 
}