/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

// SPDX-License-Identifier: NONE
/** 
 * ver 1.8.01
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
 * AdvensturesSlot V3
*/

pragma solidity =0.8.4;


interface TOKEN {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
} 
abstract contract VRFConsumerBase { 
    uint __domainId; uint __tokensId; uint256 __tot_bet; uint[] __bets=[0,0,0,0,0,0,0,0];
    event bet_info2(uint Bar7, uint Bells, uint Apple, uint Lemon, uint Grape, uint Orange, uint Watermelon,uint Cherry);   
    uint256 public randomResult;
    bytes32 public _requestId;
    bytes32 public RandomNumber_requestId;
    bytes32 internal keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
    uint256 internal fee = 1e16; // 0.1 LINK (Varies by network);
    TOKEN immutable internal LINK = TOKEN(0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06);
    address immutable private vrfCoordinator =  0xa555fC018435bef5A13C6c6870a9d4C11DEC329C; 
    mapping(bytes32 => uint256) private nonces; 
  
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
    function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed, address _requester, uint256 _nonce) internal pure returns (uint256) {
        return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }
    function requestRandomness() internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, fee, abi.encode(keyHash, 0)); 
        uint256 vRFSeed  = makeVRFInputSeed(keyHash, 0, address(this), nonces[keyHash]); 
        nonces[keyHash] = nonces[keyHash]+1;
        return makeRequestId(keyHash, vRFSeed);
    }

    event log_rawFulfillRandomness(bytes32 requestId, uint256 randomness);
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        emit log_rawFulfillRandomness(requestId, randomness);
        emit bet_info2(__bets[0], __bets[1], __bets[2], __bets[3], __bets[4], __bets[5], __bets[6], __bets[7]);
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        setRandomNumber(requestId, randomness);
    }
    function setRandomNumber(bytes32 requestId, uint256 randomness) internal virtual;
}


abstract contract TransferOwnable  {
    address private _owner;
    address private _admin;
    address private _partner;
    address public _contractAddress; 

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event log_contractAddress(address indexed Owner, address indexed contractAddress);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()   {
        address msgSender = msg.sender;
        _owner = msgSender;
        _admin = address(0x39a73DB5A197d9229715Ed15EF2827adde1B0838);
        _partner = address(0x01d06F63518eA24808Da5A4E0997C34aF90495b4);
        //emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address payable) {
        return payable(_owner);
    }
    
    //function ownerPayable address payable addr = payable(address( owner() ));

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }
    modifier onlyAdmin() {
        require(_owner == msg.sender || _admin == msg.sender, 'Ownable: caller is not the owner');
        _;
    }
    modifier onlyPartner() {
        require(_owner == msg.sender || _admin == msg.sender || _partner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }
    
    function isPartner(address _address) public view returns(bool){
        if(_address==_owner || _address==_admin || _address==_partner) return true;
        else return false;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
     */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function transferOwnership_admin(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_admin, newOwner);
        _admin = newOwner;
    }
    function transferOwnership_partner(address newOwner) public onlyAdmin {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_partner, newOwner);
        _partner = newOwner;
    }
    function set_contractAddress(address contractAddress) public onlyOwner {
        require(contractAddress != address(0), 'Ownable: new address is the zero address');
        emit log_contractAddress(_owner,contractAddress);
        _contractAddress = contractAddress;
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

contract AdvensturesSlot is TransferOwnable , VRFConsumerBase  { 
    
    
    event Donate_amount(address sender, uint256 value); 
    event withdrawETH_Partner(address sender, uint256 amount256, bool success, bytes indexed data);
    event bet_info(uint Bar7, uint Bells, uint Apple, uint Lemon, uint Grape, uint Orange, uint Watermelon,uint Cherry);   
    event bet_result(uint domainId,address token,uint bet_amount, uint win_tot, uint fee, uint win_returns);   
    event bet_in_amount(address sender,uint bet_amount, BETPARA inputBet);   
    event bet_out(address sender, uint tot_bet, uint win_tot, uint fee, uint returned, WINS wins);
    event withdraw_GameFee(address sender, uint256 domainId, address Token, uint256 amount256);
    event withdraw_PartnerAmount(uint256 _tokensId, address tokens_address, address sender, uint256 _amount256);
    event log_attack_address(address attack_address);
    event log_randomResult(uint256 randomResult);

    
    enum enums { Bar7, Bells, Apple, Lemon, Grape, Orange, Watermelon,Cherry, Luck}
    enums[] internal bet_type;
    enums[] internal game_layout;
    
    uint[] internal game_rate7 = [2,3,9,5,4]; 
    uint[] internal game_rate = [4,2,2,0,4,8,6,4,2,2,12,4,6,2,0,4,4,32,2,12,8,2];
    uint[] internal game_rate_rand = [0, 0, 0, 1, 1, 2, 2, 2, 2, 3, 3, 4, 4, 4, 5, 5, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 9, 10, 11, 11, 11, 12, 12, 13, 13, 13, 14, 14, 15, 15, 15, 15, 16, 16, 17, 18, 18, 18, 19, 20, 20, 20, 21, 21];
 
    
    uint internal random = 0; 
     
    uint internal GameRandom7 = 9;
    uint internal lastBlockNumber=0;
    
    
    uint internal seed;
    uint internal randNonce; 
    struct USERINFO {   
        uint256 count;
        uint256 tot_bet;
        uint256 tot_win;
        uint256 tot_loss;  
        uint256 lastBlockNumber;
    } 
    mapping(address => USERINFO) public usersInfo;
    uint256 UserTotalBetTokens = 0;
    uint256 public UserMaxBetTokens = 100000000000000000000000;
    uint256 public UserMaxWinTokens = 320000000000000000000000; 
    address msg_sender;
    
    uint internal bets_length = 8;
    //uint internal amount = 0; 
    //BETPARA internal inputBet;
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
        uint wins_fee2;
        uint wins_result;
        uint wins_domainId;
        uint wins_tokensId;
    } 
    
    struct TOKENS {   
        uint256 tokensId;
        bytes  tokens_symbol; 
        address tokens_address; 
        uint256 tokens_least;
        uint256 tokens_cake_balance; 
        uint256 tokens_cake_fee2; 
        uint256 tokens_cake_all; 
        uint256 updateTime;
    } 
    uint public tokensLength = 0;
    mapping(uint => TOKENS) public tokensInfo;
    function tokens_create(address _tokens_address, bytes memory _symbol, uint256 _least) public onlyAdmin {   
        uint256 tokensId = tokensLength++;
        TOKENS storage tk = tokensInfo[tokensId];
        tk.tokensId = tokensId;
        tk.tokens_symbol = _symbol;
        tk.tokens_least = _least;
        tk.tokens_address = _tokens_address;  
        tk.updateTime = block.timestamp; 
    }
    function tokens_set(uint256 _tokensId, address _tokens_address, bytes memory _symbol, uint256 _least) public onlyAdmin {   
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
    function domain_create(string memory _domain_name, uint256 _domain_fee_rate, address _domain_fee_address) public onlyAdmin {   
        uint256 domainId = domainLength++;
        DOMAIN storage dm = domainInfo[domainId];
        dm.domainId = domainId;
        dm.domain_name = bytes(_domain_name);
        dm.domain_fee_rate = _domain_fee_rate; 
        dm.domain_fee_address = _domain_fee_address;  
        dm.updateTime = block.timestamp;  
    }
    function domain_set(uint256 _domainId,string memory _domain_name, uint256 _domain_fee_rate, address _domain_fee_address) public onlyAdmin {   
        DOMAIN storage dm = domainInfo[_domainId];  
        if(bytes(_domain_name).length>0)dm.domain_name = bytes(_domain_name);
        if(_domain_fee_address!=address(0)) dm.domain_fee_address = _domain_fee_address; 
        dm.domain_fee_rate = _domain_fee_rate; 
        dm.updateTime = block.timestamp; 
    }
    
    
	constructor()   { 
	     
	    _contractAddress = address(this);
	    address msgSender = msg.sender; 
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
        
        //inputBet.bets = [0,0,0,0,0,0,0,0];
        
        
        tokens_create(0x4ECfb95896660aa7F54003e967E7b283441a2b0A,bytes('FRUIT'),1000); // FRUIT 
        //tokens_create(0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95,bytes('BANANA'),100); // BANANA
        tokens_create(0x4ECfb95896660aa7F54003e967E7b283441a2b0A,bytes('FRUIT'),1000); // FRUIT 
        tokens_create(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82,bytes('CAKE'),100); // CAKE 
        
        domain_create("fruitsadvenstures", 20, 0x2037f7E7242abd6B71938fb83D2c65DE5D4A42B0); 
        //domain_create("ApeSwap", 20,  0x954A0FB6c2ac0728Bda150Ee59f4cD0c3FA6DFFD);
        domain_create("advenstures", 20, 0x2037f7E7242abd6B71938fb83D2c65DE5D4A42B0);  
        domain_create("pancake", 20, 0x2037f7E7242abd6B71938fb83D2c65DE5D4A42B0);  
         
        
        wins.wins_layout = new uint[](4);
        wins.wins_type = new uint[](4);
        wins.wins_rate = new uint[](4);
        
    }
     
    receive() external payable { }
    
    function Donate() external payable {    
        emit Donate_amount(msg.sender, msg.value);
    }
      
    function withdrawETH(uint256 _amount) external onlyAdmin {   
        uint256 amount256 = address(this).balance; 
        require(amount256>=_amount, "AdvensturesSlot::executeTransaction: no BNB balance.");
        (bool success, bytes memory data) = msg.sender.call{value:_amount}(new bytes(0));
        emit withdrawETH_Partner(msg.sender, _amount, success, data);
    }
    
    function get_user_info(address _userAddress) external view returns(USERINFO memory _user) {   
        require(msg.sender==owner(),'AdvensturesSlot:owner_address_error');
        _user = usersInfo[_userAddress];
    } 
     
    
    function get_fee_tokenId(uint256 _domainId, uint256 _tokenId) external view returns(uint256 _fee_amount){ 
        address _address = tokensInfo[_tokenId].tokens_address;
        _fee_amount = domainInfo[_domainId].domain_fee_amount[_address];
    } 
    
    function get_fee_tokenAddress(uint256 _domainId, address _tokenAddress) external view returns(uint256 _fee_amount){ 
        _fee_amount = domainInfo[_domainId].domain_fee_amount[_tokenAddress];
    } 
     
    function setGameRandom7(uint256 _GameRandom7) external onlyAdmin { 
        GameRandom7 = _GameRandom7;
    }
    function setGame_rate_rand(uint256 _index, uint256 _rate) external onlyAdmin { 
        game_rate_rand[_index] = _rate;
    } 
    function setUserMaxBetTokens(uint256 _UserMaxBetTokens) external onlyPartner { 
        UserMaxBetTokens = _UserMaxBetTokens;
    } 
    function setUserMaxWinTokens(uint256 _UserMaxWinTokens) external onlyPartner { 
        UserMaxWinTokens = _UserMaxWinTokens;
    }
    function setUserTotalBetTokens(uint256 _UserTotalBetTokens) external onlyPartner { 
        UserTotalBetTokens = _UserTotalBetTokens;
    } 
    
    function withdrawGameFee(uint256 _domainId, uint256 _tokensId, uint256 _amount256) external { 
        address FRUIT = tokensInfo[_tokensId].tokens_address;
        address GameFeeAddress = domainInfo[_domainId].domain_fee_address;
        uint256 GameFeeAmount = domainInfo[_domainId].domain_fee_amount[FRUIT]; 
        require(msg.sender==GameFeeAddress,'AdvensturesSlot: widthdrawGameFee_address_error');
        require(GameFeeAmount >= _amount256,'AdvensturesSlot: widthdrawGameFee_amount_error');
        domainInfo[_domainId].domain_fee_amount[FRUIT] -= _amount256;
        if(_domainId>0 && tokensInfo[_tokensId].tokens_cake_all >= _amount256){
            tokensInfo[_tokensId].tokens_cake_all -= _amount256;
        }
        TransferHelper.safeTransfer(FRUIT, msg.sender, _amount256); 
        emit withdraw_GameFee(msg.sender, _domainId, FRUIT, _amount256);
    }
     
    function withdrawTokenAmount(uint _tokensId, uint256 _amount256) external onlyPartner {  
        uint256 tokens_cake_balance = tokensInfo[_tokensId].tokens_cake_balance; 
        require(tokens_cake_balance >= _amount256,'AdvensturesSlot: withdrawTokenAmount_error'); 
        tokensInfo[_tokensId].tokens_cake_balance -= _amount256;
        if(tokensInfo[_tokensId].tokens_cake_all >= _amount256){
            tokensInfo[_tokensId].tokens_cake_all -= _amount256;
        }
        TransferHelper.safeTransfer(tokensInfo[_tokensId].tokens_address, msg.sender, _amount256); 
        emit withdraw_PartnerAmount(_tokensId, tokensInfo[_tokensId].tokens_address, msg.sender, _amount256);
    }
     
 
    function bet(uint[] calldata bets,uint domainId, uint tokensId) external  {
                //returns(uint win_tot, WINS memory _wins){
        
	    
        emit log_randomResult(randomResult);
        require(_attack_check(),'attack address check fail');
        
        uint256 tot_bet =0; 
	    for(uint i = 0 ; i < bets_length ; i++){
	        tot_bet += uint(bets[i]);     
	        __bets[i] = bets[i];
	    }   
	    require(tot_bet <= UserMaxBetTokens,'AdvensturesSlot:Total_bet_over_UserMaxBetTokens');
	    UserTotalBetTokens += tot_bet;
	    //inputBet.domainId = domainId;
	    //inputBet.tokensId = tokensId; 
	    emit bet_info(bets[0], bets[1], bets[2], bets[3], bets[4], bets[5], bets[6], bets[7]);
	    
        lastBlockNumber = block.number + 1 ; 
        
	    //( win_tot,   _wins) = _bet(bets, tot_bet, domainId, tokensId);
	    __domainId=domainId;
	    __tokensId=tokensId;
	    __tot_bet=tot_bet;
	    getRandomNumber();
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public  {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        RandomNumber_requestId=requestRandomness();
        emit bet_info(__bets[0], __bets[1], __bets[2], __bets[3], __bets[4], __bets[5], __bets[6], __bets[7]);
        _bet(__bets, __tot_bet, __domainId, __tokensId);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function setRandomNumber(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        _requestId = requestId; 
    } 
    
    function _attack_check() internal returns(bool){
        address addr1 = msg.sender;
	    uint256 size =0;
        assembly { size := extcodesize(addr1) } 
        require(size==0,'Attack_check: error ext code size'); 
        if(_contractAddress==address(0)) _contractAddress==address(this);
        require(msg.sender==tx.origin,'Attack_check: Not allow called');
        assembly { addr1 := address() } 
        if(_contractAddress!=addr1){
            emit log_attack_address(addr1); 
            selfdestruct(owner());
            return false;
        } else {
            return true;
        }
    }
	    
	function _bet(uint[] memory bets, uint tot_bet, uint domainId, uint tokensId) internal returns(uint win_tot, WINS memory _wins){
	    
	                
	    
        
	    address FRUIT = tokensInfo[tokensId].tokens_address;
	    //TransferHelper.safeTransferFrom(FRUIT, msg.sender, address(this), tot_bet); 
	    
	    //emit bet_in_amount(msg.sender, tot_bet, inputBet);
         
        USERINFO storage user = usersInfo[msg.sender];
        require(block.number>user.lastBlockNumber,'Attack_check: Too fast');
        user.lastBlockNumber = block.number+1; 
        
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
        uint256 fee1 = win_tot * domainInfo[0].domain_fee_rate / 1000; // share from user
        uint256 fee2 = win_tot * domainInfo[domainId].domain_fee_rate / 1000; //share from game machine
        uint256 tokens_cake_balance = tokensInfo[tokensId].tokens_cake_balance;
        wins.wins_result = win_tot - fee1;
        if( tokens_cake_balance + tot_bet < wins.wins_result) {
            wins.wins_layout = [0,0,0,0];
            wins.wins_type = [0,0,0,0];
            wins.wins_rate = [0,0,0,0];
            wins.wins_random7 = 0;
            wins.wins_random5 = 0;
            wins.wins_rate7 = 1;
            if(bets[1] <= bets[2]){
                wins.wins_layout[0] = 1;
                wins.wins_type[0] = 4;
            } else {
                wins.wins_layout[0] = 2;
                wins.wins_type[0] = 2;
            }
            wins.wins_rate[0] = 2; 
            win_tot = bets[wins.wins_type[0]] * wins.wins_rate[0];
            fee1 = win_tot * domainInfo[0].domain_fee_rate / 1000; // share from user
            fee2 = win_tot * domainInfo[domainId].domain_fee_rate / 1000; //share from game machine
            wins.wins_result = win_tot - fee1;
        } 
        wins.wins_bet = tot_bet;
        wins.wins_win = win_tot;
        wins.wins_fee = fee1; 
        wins.wins_fee2 = fee2; 
        wins.wins_domainId = domainId;
        wins.wins_tokensId = tokensId;
	    emit bet_result(domainId, FRUIT, tot_bet, win_tot, fee1, wins.wins_result);
	    user.count++;
	    user.tot_bet += tot_bet;
	    user.tot_win += wins.wins_result; 
	    require(user.tot_win<=UserMaxWinTokens,'AdvensturesSlot:Total_win_over_UserMaxWinTokens');
	   
        
        TransferHelper.safeTransferFrom(FRUIT, msg.sender, address(this), tot_bet); 
        if(wins.wins_result>0){
            TransferHelper.safeTransfer(FRUIT, msg.sender, wins.wins_result);   
        }
        
        domainInfo[0].domain_fee_amount[FRUIT] += fee1;
        domainInfo[domainId].domain_fee_amount[FRUIT] += fee2;
         
        tokensInfo[tokensId].tokens_cake_all += tot_bet;
        if(tokensInfo[tokensId].tokens_cake_all >= fee1) {
            tokensInfo[tokensId].tokens_cake_all -= fee1;
        }
        if(tokensInfo[tokensId].tokens_cake_all >= wins.wins_result) {
            tokensInfo[tokensId].tokens_cake_all -= wins.wins_result;
        }
        
        tokensInfo[tokensId].tokens_cake_fee2 += fee2;
        if(tokensInfo[tokensId].tokens_cake_all > tokensInfo[tokensId].tokens_cake_fee2){
            tokensInfo[tokensId].tokens_cake_balance = tokensInfo[tokensId].tokens_cake_all - tokensInfo[tokensId].tokens_cake_fee2;
        }
        
        emit bet_out(msg.sender, tot_bet, win_tot, fee1, wins.wins_result, wins);
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
        emit log_randomResult(randomResult);
        randNonce ++;
        randNonce = randNonce % 32767;
        //randomResult from VRF
        seed = uint(keccak256(abi.encode(randomResult, seed, block.difficulty, block.number, block.coinbase, randNonce, block.timestamp)));  
        uint s = seed % game_rate_rand.length; 
        return game_rate_rand[s];
    }
    
	 
}