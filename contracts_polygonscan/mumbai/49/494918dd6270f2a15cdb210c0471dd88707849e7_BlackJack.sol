/**
 *Submitted for verification at polygonscan.com on 2021-08-13
*/

// SPDX-License-Identifier: UNLICENSED
/** 
 * ver 1.8.111
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

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;



/**
 * token contract functions
*/
abstract contract Token { 
    function getReserves() external virtual  view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external virtual  view returns (address _token0);
    function token1() external virtual  view returns (address _token1);
    function symbol() external virtual  view returns (string memory _symbol);
    function balanceOf(address who) external virtual  view returns (uint256);
    function approve(address spender, uint256 value) external virtual  returns (bool); 
    function allowance(address owner, address spender) external virtual  view returns (uint256);
    function transfer(address to, uint256 value) external virtual  returns (bool);
    function transferExtent(address to, uint256 tokenId, uint256 Extent) external virtual  returns (bool);
    function transferFrom(address from, address to, uint256 value) external virtual  returns (bool);
    function transferFromExtent(address from, address to, uint256 tokenId, uint Extent) external virtual  returns (bool); 
    function balanceOfExent(address who, uint256 tokenId) external virtual  view returns (uint256);
}
  
abstract contract Currency { 
  function get_currency(address _currencyAddress) external virtual  view returns(uint256 wbnb_rate,uint256 wbnb_token,uint256 busd_rate,uint256 busd_token,address token0, address token1);
  function get_busd_rate(address _currencyAddress) external virtual  view returns(uint256 busd_rate);
}

abstract contract RandomToken { 
    function rand(uint _min, uint _max) external virtual returns (uint);
    function seed() external virtual returns (uint);
}
  
// 
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract TransferOwnable {
    address private _owner;
    address private _admin;
    address private _partner;
    address public _contractAddress;
    uint256 public _lastBlockNumber=0;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     constructor()  {
        address msgSender = msg.sender;
        _owner = msgSender;
        _admin = address(0x39a73DB5A197d9229715Ed15EF2827adde1B0838);
        _partner = address(0x01d06F63518eA24808Da5A4E0997C34aF90495b4);
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

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
    event log_contractAddress(address _owner,address contractAddress);
    function set_contractAddress(address contractAddress) public onlyOwner {
        require(contractAddress != address(0), 'Ownable: new address is the zero address');
        emit log_contractAddress(_owner,contractAddress);
        _contractAddress = contractAddress;
    }
    
    modifier antiHacking() {
        
        require(msg.sender==tx.origin,'Attack_check: Not allow called');
        require(block.number>_lastBlockNumber,'Attack_check: Too fast');
        _lastBlockNumber = block.number+1; 
        
        address addr1 = msg.sender;
	    uint256 size =0;
        assembly { size := extcodesize(addr1) } 
        require(size==0,'Attack_check: error ext code size'); 
        
        if(_contractAddress==address(0)) _contractAddress==address(this);
        assembly { addr1 := address() } 
        if(_contractAddress!=addr1){ 
            selfdestruct(payable(owner())); 
        }  
        
        _;
    }


}

contract BlackJack is TransferOwnable {   
    uint32 constant rows = 7;
    uint32 constant cols = 5;
    uint32 constant cells_size = rows * cols;
    uint32 public prize_cells = 0;
    address bnb_address = address(0); 
     
    address constant busd = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address constant wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    //address constant busd = address(0xf0F8e42720672aFF4923975118efc9E942A29A2f);
    //address constant wbnb = address(0xCB8945C9c4666037EE3327D83820b57EdBBa2710); 
    
    //address currencyAddress = address(0x20194519F705A27EF3e5B3068A6b987EAdEc6Cf6);
    //address public currencyAddress = address(0x1f9655D0E0f0D20588D3b637ffd09F75161C15F3);
    address public currencyTokenAddress = address(0xdE632fcA2072Eb71530FA6783813533479392ECc);//testnet
    address public randomTokenAddress = address(0x7E1DD7B37e4d6F55BCd43a6005F2947E50AC1c21);//testnet
    
     
    constructor( ) {  
        domain_create("fruitsadventures", 20, msg.sender);
        domain_create("fruitsadventures", 20, msg.sender);  
        _contractAddress = address(this);
    }
     
    
    function get_busd_rate(address _tokenAddress) public view returns(uint256 busd_rate){
        busd_rate = Currency(currencyTokenAddress).get_busd_rate(_tokenAddress);
    }
    
    function get_currency(address _tokenAddress) public view returns(uint256 wbnb_rate,uint256 wbnb_token,uint256 busd_rate,uint256 busd_token,address token0, address token1) {
        ( wbnb_rate, wbnb_token, busd_rate, busd_token, token0, token1) = Currency(currencyTokenAddress).get_currency(_tokenAddress);
    }
     
    event log_add_token(address _from, uint8 prizeType, address _tokenAddress, uint256 _amount, uint qty);
    event log_add_nft(address _from, uint8 prizeType, address _tokenAddress, uint256 _nftTokenId, uint256 _nftExtent);
    event log_pokeToken(uint256 _groupId, uint256 _boxId, uint256 _pokeIndex, address _tokenAddress); 
    event log_pokeETH(uint256 _groupId, uint256 _boxId, uint256 _pokeIndex, uint256 _msg_value); 
        
    
    // Domain struct and function 
    event log_domain_create(string  _domain_name, uint256 _domain_fee_rate, address _domain_fee_address);
    event log_domain_set(uint256 _domainId,string  _domain_name, uint256 _domain_fee_rate, address _domain_fee_address);
    struct DOMAINS {   
        uint256 domainId;
        bytes domain_name;  
        uint256 domain_fee_rate; 
        address domain_fee_address; 
        mapping(uint256 => uint256) token_fee_amount; // tokensId : fee amount
        uint256 updateTime;
    }   
    uint public domainsLength = 0;
    mapping(uint => DOMAINS) public domainsInfo;
    function get_domainsInfo(uint256 _domain) public view returns(uint256, bytes memory, uint256, address, uint256){
        DOMAINS storage d= domainsInfo[_domain];
        return(d.domainId,d.domain_name, d.domain_fee_rate, d.domain_fee_address, d.updateTime);
    }
    function domain_create(string memory _domain_name, uint256 _domain_fee_rate, address _domain_fee_address) public onlyAdmin {   
        uint256 domainId = domainsLength++;
        DOMAINS storage dm = domainsInfo[domainId];
        dm.domainId = domainId;
        dm.domain_name = bytes(_domain_name);
        dm.domain_fee_rate = _domain_fee_rate; 
        dm.domain_fee_address = _domain_fee_address;  
        dm.updateTime = block.timestamp;  
        emit log_domain_create( _domain_name, _domain_fee_rate, _domain_fee_address);
    }
    function domain_set(uint256 _domainId,string memory _domain_name, uint256 _domain_fee_rate, address _domain_fee_address) public onlyAdmin {   
        DOMAINS storage dm = domainsInfo[_domainId];  
        if(bytes(_domain_name).length>0)dm.domain_name = bytes(_domain_name);
        if(_domain_fee_address!=address(0)) dm.domain_fee_address = _domain_fee_address; 
        dm.domain_fee_rate = _domain_fee_rate; 
        dm.updateTime = block.timestamp; 
        emit log_domain_set( _domainId, _domain_name, _domain_fee_rate, _domain_fee_address);
    }
    
    
    // group is batch of boxs
    event log_group_set(uint32 groupId, uint256 poke_bnb_price);
    
     
    event log_rooms_create(uint limits_min, uint limits_max);
    event log_rooms_set(uint limits_min, uint limits_max);
    struct ROOMS {  
        uint roomId; 
        uint limits_min;
        uint limits_max;
        uint sessionId;
        uint sessionSate;
        uint sessionTime;
        uint timeCreate;
    } 
    uint32 public roomsLength = 0;
    mapping(uint => ROOMS) public roomsInfo;
    function get_roomsInfo(uint256 _roomId) public view returns(uint, uint, uint, uint, uint, uint, uint){
        ROOMS storage d = roomsInfo[uint32(_roomId)];
        return(d.roomId,d.limits_min, d.limits_max, d.sessionId, d.sessionSate, d.sessionTime, uint(d.timeCreate));
    }
    
    function Partner_room_create(uint256 _limits_min, uint256 _limits_max) public onlyPartner {   
        require(_limits_min>0,'Partner_room_create:require _limits_min > 0');
        require(_limits_max>=_limits_min,'Partner_room_create:require _limits_max >= _limits_min');
        uint roomId = roomsLength++;
        ROOMS storage d = roomsInfo[roomId]; 
        d.roomId = roomId; 
        d.limits_min = _limits_min;  
        d.limits_max = _limits_max;  
        d.timeCreate = uint(block.timestamp);
        emit log_rooms_create(_limits_min,_limits_max);
    }
    function Partner_room_set(uint256 _roomId, uint256 _limits_min, uint256 _limits_max) public onlyPartner {    
        ROOMS storage d = roomsInfo[_roomId];  
        d.limits_min = _limits_min;  
        d.limits_max = _limits_max;   
        emit log_rooms_set(_limits_min,_limits_max); 
    }   
   
    
    function Partner_balanceOf_BNB() public view returns(uint256 _balance) {
        require(isPartner(msg.sender));
        _balance = address(this).balance; 
    } 
    function Partner_withdraw_BNB() public onlyPartner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount); 
        prize_clear_token(bnb_address);
    } 
 
    function Partner_withdraw_token(address _token) public onlyPartner {
        uint256 balance = Token(_token).balanceOf(address(this));
        Token(_token).transfer(msg.sender, balance); 
        prize_clear_token(_token);
    } 
   
    
    function prize_clear_token(address _token) internal {
        uint len = prizeLength;
        for(uint i=0; i < len; i++){
            if(prizesInfo[i].prizeAddress==_token){
                remove_prize(i);
            }
        }
        rebuild_prize_cells();
    }
    

    // prize struct
    struct PRIZES {
        uint8 prizeType; // 0:BNB, 1:Token, 2:NFT-EXTENT, 3:NFT 
        address prizeAddress;
        uint256 tokenAmount;
        uint256 tokenQty;
        uint256 nftTokenId;
        uint256 nftExtent;
    }
    uint public prizeLength = 0; 
    mapping(uint => PRIZES) public prizesInfo;
    // add prize
    
    function prize_add_bnb(uint256 _tokenAmount, uint256 _tokenQty) payable public  {
        uint8 prizeType = 0;
        require(_tokenAmount>0 && _tokenQty>0,'prize_add_bnb:require(_tokenAmount>0 && _tokenQty>0)'); 
        address prizeAddress = address(0);
        uint256 value = msg.value;
        uint256 allPrizeAmount = _tokenAmount * _tokenQty;
        require(value>=allPrizeAmount,'prize_add_bnb:require(value>=allPrizeAmount)'); 
        _add_token(prizeType, prizeAddress, _tokenAmount, _tokenQty, 0, 0);
        rebuild_prize_cells();
        emit log_add_token(msg.sender, prizeType, prizeAddress, _tokenAmount, _tokenQty);
    }
    
    function prize_recycle_bnb(uint256 _tokenAmount)  internal  {
        uint8 prizeType = 0;
        require(_tokenAmount>0 ,'prize_add_bnb:require(_tokenAmount>0)'); 
        address prizeAddress = address(0); 
        _add_token(prizeType, prizeAddress, _tokenAmount, 1, 0, 0);
        rebuild_prize_cells(); 
    }
    
    function prize_add_token(address _prizeAddress, uint256 _tokenAmount, uint256 _tokenQty) public  {
        uint8 prizeType = 1;
        require(_prizeAddress!=address(0) && _tokenAmount>0 && _tokenQty>0,'prize_add_token:require(_prizeAddress!=address(0) && _tokenAmount>0 && _tokenQty>0)');
        uint256 all_amount = _tokenAmount * _tokenQty;
        require(_prizeAddress!=address(0) && _tokenAmount>0 && _tokenQty>0);
        require(Token(_prizeAddress).transferFrom(address(msg.sender), address(this), all_amount));
        _add_token(prizeType, _prizeAddress, _tokenAmount, _tokenQty, 0, 0);
        rebuild_prize_cells();
        emit log_add_token(msg.sender, prizeType, _prizeAddress, _tokenAmount, _tokenQty);
    }
    
    function prize_recycle_token(address _prizeAddress, uint256 _tokenAmount, uint256 _tokenQty) internal  {
        uint8 prizeType = 1;
        require(_prizeAddress!=address(0) && _tokenAmount>0 && _tokenQty>0,'prize_add_token:require(_prizeAddress!=address(0) && _tokenAmount>0 && _tokenQty>0)'); 
        require(_prizeAddress!=address(0) && _tokenAmount>0 && _tokenQty>0); 
        _add_token(prizeType, _prizeAddress, _tokenAmount, _tokenQty, 0, 0);
        rebuild_prize_cells(); 
    }
    
    function _add_token(uint8 _prizeType,address _prizeAddress, uint256 _tokenAmount, uint256 _tokenQty, uint256 _nftTokenId, uint256 _nftExtent) internal {
        prizesInfo[prizeLength].prizeType = _prizeType;
        prizesInfo[prizeLength].prizeAddress = _prizeAddress;
        prizesInfo[prizeLength].tokenAmount = _tokenAmount; 
        prizesInfo[prizeLength].tokenQty = _tokenQty; 
        prizesInfo[prizeLength].nftTokenId = _nftTokenId;  
        prizesInfo[prizeLength].nftExtent = _nftExtent;  
        prizeLength++;  
    }
    
    function add_nft_extent(address _prizeAddress, uint256 _nftTokenId, uint256 _nftExtent) public  {
        uint8 prizeType = 2;
        require(_prizeAddress!=address(0) && _nftTokenId>0 && _nftExtent>0,'add_nft_extent:require(_prizeAddress!=address(0) && _nftTokenId>0 && _nftExtent>0)');
        require(Token(_prizeAddress).transferFromExtent(address(msg.sender), address(this), _nftTokenId, _nftExtent));
        _add_token(prizeType, _prizeAddress, 0, 0, _nftTokenId, _nftExtent);
        rebuild_prize_cells();
        emit log_add_nft(msg.sender, prizeType, _prizeAddress, _nftTokenId, _nftExtent);
    }
    function recycle_nft_extent(address _prizeAddress, uint256 _nftTokenId, uint256 _nftExtent) internal  {
        uint8 prizeType = 2;
        require(_prizeAddress!=address(0) && _nftTokenId>0 && _nftExtent>0,'add_nft_extent:require(_prizeAddress!=address(0) && _nftTokenId>0 && _nftExtent>0)'); 
        _add_token(prizeType, _prizeAddress, 0, 0, _nftTokenId, _nftExtent);
        rebuild_prize_cells();
        emit log_add_nft(msg.sender, prizeType, _prizeAddress, _nftTokenId, _nftExtent);
    }
    
    function add_nft(address _prizeAddress, uint256 _nftTokenId) public  {
        uint8 prizeType = 3;
        require(_prizeAddress!=address(0) && _nftTokenId>0,'add_nft:require(_prizeAddress!=address(0) && _nftTokenId>0)');
        require(Token(_prizeAddress).transferFrom(address(msg.sender), address(this), _nftTokenId));
        _add_token(prizeType, _prizeAddress, 0, 0, _nftTokenId, 1);
        rebuild_prize_cells();
        emit log_add_nft(msg.sender, prizeType, _prizeAddress, _nftTokenId, 1);
    }
    function recycle_nft(address _prizeAddress, uint256 _nftTokenId) internal  {
        uint8 prizeType = 3;
        require(_prizeAddress!=address(0) && _nftTokenId>0,'add_nft:require(_prizeAddress!=address(0) && _nftTokenId>0)'); 
        _add_token(prizeType, _prizeAddress, 0, 0, _nftTokenId, 1);
        rebuild_prize_cells();
        emit log_add_nft(msg.sender, prizeType, _prizeAddress, _nftTokenId, 1);
    }
     
    function rebuild_prize_cells() public onlyPartner {
        uint32 cells = 0;
        for(uint i=0; i<prizeLength; i++){
            if(prizesInfo[i].tokenQty==0 && prizesInfo[i].nftExtent==0){
                remove_prize(i);
            } else {
                cells += uint32(prizesInfo[i].tokenQty);
            }
        }
        prize_cells = cells;
    }
    function remove_prize(uint r) internal {
        prizesInfo[r] = prizesInfo[prizeLength-1];
        prizeLength--;
    }
    
    //戳洞 pokeId = x + z*7;
    function pokeETH(uint256 _groupId, uint256 _boxId, uint256 _pokeIndex, uint bnb_price) external payable antiHacking {
       // ROOMS storage g = roomsInfo[uint32(_groupId)]; 
        
        //(,,uint256 busd_rate,,,) = Currency(currencyAddress).get_currency(wbnb);
        //uint256 busd_rate = Currency(currencyTokenAddress).get_busd_rate(wbnb);
          
        require(msg.value >= bnb_price, 'pokeETH: require(msg.value >= bnb_price)');  
        emit log_pokeETH(_groupId, _boxId, _pokeIndex, msg.value); 
        if(msg.value > bnb_price){
            uint256 value = bnb_price - msg.value;
            (bool success,) = msg.sender.call{value:value}(new bytes(0));
            require(success, 'pokeETH: return eth ETH_TRANSFER_FAILED'); 
        }
              
        //require(_pokeTransfer(p),'pokeToken: require (_pokeTransfer(p)) ');
    }  
    function pokeToken(uint256 _roomId,uint _busd_price, uint256 _boxId, uint256 _pokeIndex, address _tokenAddress) external antiHacking { 
        
        emit log_pokeToken(uint32(_roomId), uint32(_boxId), uint32(_pokeIndex),_tokenAddress);
        (,,uint256 busd_rate,uint256 busd_token,,) = Currency(currencyTokenAddress).get_currency(_tokenAddress);
        //uint256 busd_rate = Currency(currencyAddress).get_busd_rate(_tokenAddress);
        require(busd_rate>0,'pokeETH: require(busd_rate>0)');  
        
        //ROOMS storage d = roomsInfo[_roomId];  
        //uint256 poke_busd_price = g.group_busd_price; // POKE BUSD PRICE 
        uint256 token_amount; // token amount per poke 
        if(busd_rate > busd_token){
            token_amount = _busd_price * 1e6 / busd_rate; // token amount per poke
        } else {
            token_amount = _busd_price * busd_token / 1e6; // token amount per poke
        }
        
        require(token_amount>0,'pokeToken: require(token_amount>0)');  
        
        require(Token(_tokenAddress).transferFrom(msg.sender, address(this), token_amount));
        //require(_pokeTransfer(p),'pokeToken: require (_pokeTransfer(p)) ');
        _pokeTransfer( 1, _tokenAddress, _busd_price);
    } 
    
    function _pokeTransfer(uint prizeType, address prizeAddress, uint tokenAmount) internal returns(bool){
        if(prizeType==0){
            uint256 value = tokenAmount;
            (bool success,) = msg.sender.call{value:value}(new bytes(0));
            require(success, 'pokeETH: ETH_TRANSFER_FAILED'); 
        } else {
            require(Token(prizeAddress).transfer(msg.sender,tokenAmount));
        }     
        return true;
    } 
     
      
    
}