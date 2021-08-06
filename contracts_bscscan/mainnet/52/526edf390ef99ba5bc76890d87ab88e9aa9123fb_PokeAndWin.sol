/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

// SPDX-License-Identifier: NONE
/** 
 * ver 1.8.04
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
    function balanceOf(address who) external virtual  view returns (uint256);
    function approve(address spender, uint256 value) external virtual  returns (bool); 
    function allowance(address owner, address spender) external virtual  view returns (uint256);
    function transfer(address to, uint256 value) external virtual  returns (bool);
    function transferExtent(address to, uint256 tokenId, uint256 Extent) external virtual  returns (bool);
    function transferFrom(address from, address to, uint256 value) external virtual  returns (bool);
    function transferFromExtent(address from, address to, uint256 tokenId, uint Extent) external virtual  returns (bool); 
    function balanceOfExent(address who, uint256 tokenId) external virtual  view returns (uint256);
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
    address public _contractAddress=address(0);
    uint256 public _lastBlockNumber=0;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     constructor()  {
        address msgSender = msg.sender;
        _owner = msgSender;
        _admin = msgSender;
        _partner = msgSender;
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

contract PokeAndWin is TransferOwnable {   
    uint32 constant rows = 7;
    uint32 constant cols = 5;
    uint32 constant cells_size = rows * cols;
    uint32 public prize_cells = 0;
    address public bnb_address = address(0); 
    
    address constant fruit_bnb = 0xf3531a1c93056EC6FB59a358B2007eca0a2ebe9f;
    address constant pair_bnb_busd = 0x51e6D27FA57373d8d4C256231241053a70Cb1d93;
    address constant busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address constant wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant WBNB_TEST = 0xCB8945C9c4666037EE3327D83820b57EdBBa2710;
    
    uint internal seed;
    uint internal randNonce;
    constructor( ) {  
        domain_create("fruitsadventures", 20, msg.sender);
        domain_create("fruitsadventures", 20, msg.sender);
    }
     
    event log_add_token(address _from, uint8 prizeType, address _tokenAddress, uint256 _amount, uint qty);
    event log_add_nft(address _from, uint8 prizeType, address _tokenAddress, uint256 _nftTokenId, uint256 _nftExtent);
    event log_pokeToken(uint256 _groupId, uint256 _index, uint256 _cellId, address _tokenAddress); 
        
    
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
    event log_group_create(uint32 groupId, uint256 poke_bnb_price);
    event log_group_set(uint32 groupId, uint256 poke_bnb_price);
    
     
    struct GROUPS {  
        uint32 groupId; 
        uint32 startBoxId;
        uint32 endBoxId; 
        uint256 group_busd_price;
        uint32 timeCreate;
        uint32 timeRecycle;
        uint8 isRecycle;
    } 
    uint32 public groupsLength = 0;
    mapping(uint32 => GROUPS) public groupsInfo;
    function get_groupsInfo(uint256 _groupId) public view returns(uint32, uint32, uint32, uint256, uint32, uint32, uint8){
        GROUPS storage d = groupsInfo[uint32(_groupId)];
        return(d.groupId,d.startBoxId, d.endBoxId, d.group_busd_price, d.timeCreate, d.timeRecycle, d.isRecycle);
    }
    
    struct BOXS {  
        uint32 groupId;
        uint32 boxId;
        uint32 pokedCount;
        uint32 pokeIdStart;
        uint32 pokeIdEnd;
        mapping(uint32 => uint32) pokesInfo; // store poke info
        uint32 timeCreate; 
        uint32 timeRecycle;
        uint8 isRecycle;
    }
    uint32 public boxsLength = 0;
    mapping(uint32 => BOXS) public boxsInfo; 
    function get_boxsInfo(uint256 _groupId) public view returns(uint32, uint32, uint32, uint32, uint32, uint32, uint32, uint8){
        BOXS storage d = boxsInfo[uint32(_groupId)];
        return(d.groupId, d.boxId, d.pokedCount, d.pokeIdStart, d.pokeIdEnd, d.timeCreate, d.timeRecycle, d.isRecycle);
    }
    
    struct POKES {
        uint32 pokeId;
        uint32 groupId;
        uint32 boxId;
        uint8 prizeType;
        address prizeAddress; //prize
        uint256 tokenAmount; 
        uint256 nftTokenId; 
        address winnerAddress; // winner
        uint32 winTime;
        uint32 timeCreate; 
        uint32 timeRecycle;
        uint8 isPoke;
        uint8 isRecycle;
    }
    uint32 public pokesLength = 0;
    mapping(uint32 => POKES) private pokesInfo; 
    function get_pokesInfo(uint256 _pokeId) public view returns(uint32, uint32, uint32, uint8, address, uint256, uint256, uint32, uint32, uint32, uint8, uint8){
        POKES storage d = pokesInfo[uint32(_pokeId)];
        return(d.pokeId, d.groupId, d.boxId, d.prizeType, d.prizeAddress, d.tokenAmount, d.nftTokenId, d.winTime, d.timeCreate, d.timeRecycle, d.isPoke, d.isRecycle);
    }
    function get_pokesInfo2(uint256 _pokeId) public view returns(uint32, uint32, uint32, uint8, address, uint256, uint256, address, uint8, uint8){
        POKES storage d = pokesInfo[uint32(_pokeId)];
        return(d.pokeId, d.groupId, d.boxId, d.prizeType, d.prizeAddress, d.tokenAmount, d.nftTokenId, d.winnerAddress, d.isPoke, d.isRecycle);
    }
 
    uint32 public showboxLength = 0;
    mapping(uint32 => uint32) public showboxInfo;  // boxId
    

    
    function get_box_poke(uint _boxId, uint _pokeIndex) public view returns(uint32 groupId,uint32 boxId,uint32 pokeId,uint8 isPoke) { 
        require(_pokeIndex>=0 && _pokeIndex<=cells_size,'get_box_poke:_pokeIndex>=0 && _pokeIndex<=cells_size)');
        BOXS storage bx = boxsInfo[uint32(_boxId)];
        uint32 pId = bx.pokesInfo[uint32(_pokeIndex)];
        POKES memory poke = pokesInfo[pId];
        groupId = poke.groupId;
        boxId = poke.boxId;
        pokeId = poke.pokeId;
        isPoke = poke.isPoke; 
    }
   
    function Partner_get_pokesInfo(uint index) public view returns(POKES memory poke) { 
        if(isPartner(msg.sender))  poke = pokesInfo[uint32(index)];
    }
    function Partner_recycle_box(uint boxId) external onlyPartner { 
        BOXS storage bx = boxsInfo[uint32(boxId)];
        for(uint32 pokeId=bx.pokeIdStart; pokeId < bx.pokeIdEnd; pokeId++){
            POKES storage p = pokesInfo[pokeId]; 
            if(p.prizeType==0){
                prize_recycle_bnb(p.tokenAmount);
            } else if(p.prizeType==1){
                prize_recycle_token(p.prizeAddress, p.tokenAmount, 1);
            } else if(p.prizeType==2){
                recycle_nft_extent(p.prizeAddress, p.nftTokenId, 1);
            } else if(p.prizeType==3){
                recycle_nft(p.prizeAddress, p.nftTokenId);
            }
            p.timeRecycle = uint32(block.timestamp);
            p.isRecycle = 1; 
        } 
        resuild_showbox();
    }
    function group_create(uint256 group_busd_price, uint256 box_number) public onlyPartner {   
        require(box_number>0,'group_create:require box_number > 0');
        uint32 groupId = groupsLength++;
        GROUPS storage g = groupsInfo[groupId];
        g.startBoxId = boxsLength;
        g.groupId = groupId; 
        g.group_busd_price = group_busd_price;  
        g.timeCreate = uint32(block.timestamp);
        g.isRecycle = 0;
        _group_create(g,box_number);
        emit log_group_create(groupId,group_busd_price);
    }
    function group_set(uint256 groupId, uint256 group_busd_price) public onlyPartner {    
        GROUPS storage g = groupsInfo[uint32(groupId)]; 
        g.group_busd_price = group_busd_price;  
        emit log_group_set(g.groupId,group_busd_price);
    }
    function _group_create(GROUPS storage g, uint256 box_number) internal onlyPartner {  
        require(prize_cells>=cells_size,'group_create:require(prize_cells>=cells_size)');
        while(prize_cells>=cells_size && box_number>0){ 
            _group_create_box(g);
            box_number--;
        }
    }
    function _group_create_box(GROUPS storage g) internal onlyPartner {   
        uint32 boxId = boxsLength++; 
        g.endBoxId = boxId;
        BOXS storage bx = boxsInfo[boxId];
        bx.groupId = g.groupId;
        bx.boxId = boxId;
        bx.timeCreate = uint32(block.timestamp); 
        bx.isRecycle = 0;
        bx.pokedCount = 0;
        bx.pokeIdStart = pokesLength;
        for(uint32 i=0; i < cells_size; i++){
            uint32 pokeId = pokesLength++;
            POKES storage p = pokesInfo[pokeId]; 
            p.groupId = bx.groupId;
            p.boxId = bx.boxId;
            p.pokeId = pokeId;
            p.winnerAddress = address(0); // winner
            p.winTime = 0;
            p.timeCreate = uint32(block.timestamp);
            p.isRecycle = 0;
            _poke_random_prize(p);
        } 
        
        bx.pokeIdEnd = pokesLength;
        push_showbox(bx.boxId);
    }
    
    function _poke_random_prize(POKES storage p) internal {
        require(prizeLength>0,'group_create:require prizeLength>0');
        uint r = randomize(0, prizeLength);
        PRIZES storage prize = prizesInfo[r];
        p.prizeType = prize.prizeType; 
        p.prizeAddress = prize.prizeAddress; 
        p.tokenAmount = prize.tokenAmount; 
        p.nftTokenId = prize.nftTokenId;
        if(prize.prizeType==0 || prize.prizeType==1){ // BNB,TOKEN
            if(prize.tokenQty>0){
                prize.tokenQty--; 
                if(prize.tokenQty==0) remove_prize(r);
            } else {
                remove_prize(r);
                _poke_random_prize(p);
            }
        } else if(prize.prizeType==2 || prize.prizeType==3){  // NFT-EXTENT, NFT
            prize.nftExtent--;
            if(prize.nftExtent==0) remove_prize(r);
        }  else {
            remove_prize(r);
            _poke_random_prize(p);
        }
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
 
    function Partner_withdraw_extent(address _nfttoken,uint256 _nftTokenId) public onlyPartner {
        uint256 extent = Token(_nfttoken).balanceOfExent(address(this), _nftTokenId);
        Token(_nfttoken).transferExtent(msg.sender, _nftTokenId, extent); 
    } 
    
 
    function push_showbox(uint256 _boxId) internal {
        uint32 showbox_id = showboxLength++;
        showboxInfo[showbox_id] = uint32(_boxId);
    }
    function resuild_showbox() public {
        for(uint32 i=0; i < showboxLength; i++){
            uint32 boxId = showboxInfo[i];
            if(boxsInfo[boxId].isRecycle==1){
                showboxLength--;
                showboxInfo[i] = showboxInfo[showboxLength];
            }
        }
    }
    function get_boxid_showboxIndex(uint256 _index) public view returns(uint32 boxId)  { 
        boxId = showboxInfo[uint32(_index)];
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
    function pokeETH(uint256 _groupId, uint256 _boxId, uint256 _cellId) external payable antiHacking {
        GROUPS storage g = groupsInfo[uint32(_groupId)];
        uint256 group_busd_price = g.group_busd_price;
        CURRENCYS memory currency = currencysInfo[wbnb];
        uint busd_rate = currency.busd_rate;
        uint256 bnb_price = group_busd_price * 1e8 / busd_rate;
        require(msg.value >= bnb_price, 'pokeETH: require(msg.value >= bnb_price)');  
        BOXS storage b = boxsInfo[uint32(_boxId)];
        uint32 pokeId = b.pokesInfo[uint32(_cellId)];
        POKES storage p = pokesInfo[pokeId];
        require(p.winTime==0,'pokeETH: require(p.winTime==0)');  
        require(p.prizeType>=0 && p.prizeType<=3,'pokeETH: require(p.prizeType>=0 && p.prizeType<=3)');  
        _pokeTransfer(p);
    } 
    function pokeToken(uint256 _groupId, uint256 _boxId, uint256 _cellId, address _tokenAddress) external antiHacking {
        uint256 busd_rate = currencysInfo[_tokenAddress].busd_rate; 
        require(busd_rate>0,'pokeToken: require(busd_rate>0)');  
        emit log_pokeToken(uint32(_groupId), uint32(_boxId), uint32(_cellId),_tokenAddress);
        GROUPS storage g = groupsInfo[uint32(_groupId)];
        uint256 poke_busd_price = g.group_busd_price; // BUSD PRICE 
        BOXS storage b = boxsInfo[uint32(_boxId)];
        uint32 pokeId = b.pokesInfo[uint32(_cellId)];
        POKES storage p = pokesInfo[pokeId];
        require(p.winTime==0,'pokeToken: require(p.winTime==0)');  
        require(p.prizeType>=0 && p.prizeType<=3,'pokeToken: require(p.prizeType>=0 && p.prizeType<=3)');  
        
        uint256 token_amount = poke_busd_price * busd_rate;  
        require(token_amount>0,'pokeToken: require(token_amount>0)');  
        require(Token(_tokenAddress).transferFrom(msg.sender, address(this), token_amount));
        _pokeTransfer(p);
    } 
    
    function _pokeTransfer(POKES storage p) internal {
        if(p.prizeType==0){
            uint256 value = p.tokenAmount;
            (bool success,) = msg.sender.call{value:value}(new bytes(0));
            require(success, 'pokeETH: ETH_TRANSFER_FAILED'); 
        } else if(p.prizeType==1){
            require(Token(p.prizeAddress).transfer(msg.sender, p.tokenAmount));
        } else if(p.prizeType==2){
            require(Token(p.prizeAddress).transferExtent(msg.sender, p.nftTokenId, 1));
        } else if(p.prizeType==3){
            require(Token(p.prizeAddress).transfer(msg.sender, p.nftTokenId));
        }
        p.winnerAddress = msg.sender;
        p.winTime = uint32(block.timestamp);
        BOXS storage bx = boxsInfo[p.boxId];
        bx.pokedCount++;
    } 
    
    function randomize(uint _min, uint _max) internal  returns (uint) { 
        randNonce ++;
        randNonce = randNonce % 32767;
        seed = uint(keccak256(abi.encode(seed, block.difficulty, block.number, block.coinbase, randNonce, block.timestamp)));  
        return _min + (seed % (_max - _min) );
    }
    
     
    uint32 public currencysLength=0;
    mapping(uint32 => address) public currencysList; 
    mapping(address => CURRENCYS) public currencysInfo; // token currency
    struct CURRENCYS {    
        uint32 currencysId;
        address tokenAddress; 
        address pairAddress; 
        address token0;
        address token1;
        uint112 _reserve0;
        uint112 _reserve1;
        uint32 wbnb_rate;
        uint32 busd_rate;
    }     
    function setCURRENCY(address _tokenAddress, address _pirAddress) public onlyPartner { 
        CURRENCYS memory wbnb_busd = currencysInfo[wbnb];
        CURRENCYS storage c = currencysInfo[_tokenAddress];
        (c._reserve0, c._reserve1,)=Token(_pirAddress).getReserves(); 
        c.tokenAddress = _tokenAddress;
        c.pairAddress = _pirAddress;
        c.token0 = Token(_pirAddress).token0();
        c.token1 = Token(_pirAddress).token1(); 
        
        if(c.token0==busd){
            c.busd_rate = uint32(c._reserve0*1e8/c._reserve1);
        } else if(c.token1==busd){
            c.busd_rate = uint32(c._reserve1*1e8/c._reserve0);
        } else if(c.token0==wbnb){
            c.busd_rate = uint32(wbnb_busd.busd_rate * c._reserve0 / c._reserve1);
        } else if(c.token1==wbnb){
            c.busd_rate = uint32(wbnb_busd.busd_rate * c._reserve1 / c._reserve0);
        }
        c.wbnb_rate = uint32(c.busd_rate / wbnb_busd.busd_rate);
        
        if(c.currencysId==0){
            //new currencysList
            c.currencysId = currencysLength;
            currencysList[currencysLength++] = _tokenAddress;
        } 
    }
    
}