/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: NONE
/** 
 * ver 1.7.5
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

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;



/**
 * token contract functions
*/
abstract contract Token {
    function getReserves() external virtual  view returns (uint112 _reserve0, uint112 _reserve1);
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
contract theOwnable {
    address private _owner;
    address private _admin;
    address private _partner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     constructor() internal  {
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


}

contract PokeAndWin is theOwnable{   
    uint rows = 7;
    uint cols = 5;
    uint cells_size = rows * cols;
    uint public prize_cells = 0;
    uint internal seed;
    uint internal randNonce;
    address public bnb_address = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public fee_address;
    uint256 public fee_1000 = 20;
    
    address public fruit_bnb = 0xf3531a1c93056EC6FB59a358B2007eca0a2ebe9f;
    
    constructor( ) public { 
        fee_address = msg.sender;
        domain_create(msg.sender, 20);
    }
    
    event log_add_token(address _tokenAddress, address _from, uint256 _amount, uint qty);
    event log_add_nft(address _tokenAddress, address _from, uint256 _nftTokenId);
    
    struct DOMAIN {   
        uint256 domainId;
        uint256 fee_1000; 
        address fee_address; 
        uint256 timeCreate;
    }   
    struct GROUP {  
        uint256 groupId;
        uint256 prize_cells; 
        uint256 poke_bnb_price;
        uint256 box_length;
    }
    struct BOX {  
        uint256 groupId;
        uint256 boxId;
        uint256 pokesInfoId; 
        uint256 uintAmount;
        uint256 timeCreate;
        uint256 timeSoldout;
        uint256 timeRecycle;
    }
    struct SHOWBOX {  
        uint256 groupId;
        uint256 boxId;
    }
    struct PRIZE {
        address tokenAddress;
        uint256 tokenAmount;
        uint256 qty;
        uint256 nftTokenId;
        uint256 nftExtent;
    }
    struct POKE {
        uint256 groupId;
        uint256 boxId;
        uint256 pokeId;
        address tokenAddress;
        uint256 tokenAmount; 
        uint256 nftTokenId;
        uint256 nftExtent;
        address winnerAddress;
        uint256 winTime;
        uint256 recycle;
    }
    
    
    uint public domainLength = 0;
    mapping(uint => DOMAIN) public domainInfo;

    //group 批號 
    uint public groupLength = 0;
    mapping(uint => GROUP) public groupInfo;
    mapping(uint => mapping(uint => BOX)) public boxsInfo;
    uint public showboxLength = 0;
    mapping(uint => SHOWBOX) public showboxInfo;
    
    uint public pokesLength = 0;
    mapping(uint => mapping(uint => POKE)) private pokesInfo; 

    uint public prizeLength = 0; 
    mapping(uint => PRIZE) public prizesInfo;
    
    
    function Partner_balanceOf() public view returns(uint256 _balance) {
        require(isPartner(msg.sender));
        _balance = address(this).balance; 
    } 
    function Partner_withdraw() public onlyPartner {
        uint256 amount = address(this).balance;
        msg.sender.transfer(amount); 
    } 
 
    function Partner_withdraw_token(address _token) public onlyPartner {
        uint256 balance = Token(_token).balanceOf(address(this));
        Token(_token).transfer(msg.sender, balance); 
    } 
 
    function Partner_withdraw_extent(address _nfttoken,uint256 _nftTokenId) public onlyPartner {
        uint256 extent = Token(_nfttoken).balanceOfExent(address(this), _nftTokenId);
        Token(_nfttoken).transferExtent(msg.sender, _nftTokenId, extent); 
    } 
    
    
    function get_showboxInfo(uint256 _id) public view returns(SHOWBOX memory s)  { 
        s = showboxInfo[_id];
    }
 
    function get_pokesInfo(uint256 _groupId, uint256 _pokeId) public view returns(POKE memory p)  {
        require(isPartner(msg.sender));
        p = pokesInfo[_groupId][_pokeId];
    }
    
    function set_fee(address _fee_address, uint256 _fee_1000) public onlyOwner {
         fee_address = _fee_address;
         fee_1000 = _fee_1000;
    }  
    
    function domain_create(address _fee_address, uint256 _fee_1000) public onlyPartner {   
        uint256 domainId = domainLength++;
        DOMAIN storage dm = domainInfo[domainId];
        dm.domainId = domainId;
        dm.fee_address = _fee_address; 
        dm.fee_1000 = _fee_1000; 
        dm.timeCreate = block.timestamp; 
    }
    
    function domain_set(uint256 _domainId, address _fee_address, uint256 _fee_1000) public onlyPartner {   
        DOMAIN storage dm = domainInfo[_domainId];  
        dm.fee_address = _fee_address; 
        dm.fee_1000 = _fee_1000; 
        dm.timeCreate = block.timestamp; 
        domainLength++; 
    }
 
    function push_showbox(uint256 _groupId, uint256 _boxId) internal {
        uint showbox_id = showboxLength++;
        SHOWBOX storage s = showboxInfo[showbox_id];
        s.groupId = _groupId;
        s.boxId = _boxId;
    }
    function pop_showbox(uint256 _groupId, uint256 _boxId) internal returns(bool){
        for(uint i=0; i < showboxLength; i++){
            if(showboxInfo[i].groupId == _groupId && showboxInfo[i].boxId == _boxId){
                showboxLength--;
                showboxInfo[i].groupId = showboxInfo[showboxLength].groupId;
                showboxInfo[i].boxId = showboxInfo[showboxLength].boxId;
                showboxInfo[showboxLength].groupId = 0;
                showboxInfo[showboxLength].boxId = 0;
                return true;
            }
        }
        return false;
    }
    
    function group_create(uint256 poke_bnb_price) public onlyPartner {   
        uint groupId = groupLength++;
        GROUP storage g = groupInfo[groupId];
        g.groupId = groupId;
        g.prize_cells = prize_cells;
        g.poke_bnb_price = poke_bnb_price; 
        g.box_length = 0;
        _group_create(g);
    }
 
    function _group_create(GROUP storage g) internal onlyPartner {   
        while(prize_cells>=cells_size){
            _group_create_box(g);
        }
    }
 
    function _group_create_box(GROUP storage g) internal onlyPartner {   
        uint boxId = g.box_length++;
        BOX storage bx = boxsInfo[g.groupId][boxId];
        bx.groupId = g.groupId;
        bx.boxId = boxId;
        bx.timeCreate = block.timestamp; 
        for(uint i=0; i < cells_size; i++){
            uint pokeId = pokesLength++;
            POKE storage p = pokesInfo[pokeId][i]; 
            p.groupId = bx.groupId;
            p.boxId = bx.boxId;
            p.pokeId = pokeId;
            set_random_prize(p);
        } 
        push_showbox(bx.groupId,bx.boxId);
    }
    
    function set_random_prize(POKE storage p) internal {
        uint r = randomize(0, prizeLength);
        PRIZE storage g = prizesInfo[r];
        p.tokenAddress = g.tokenAddress; 
        p.tokenAmount = g.tokenAmount; 
        p.nftTokenId = g.nftTokenId;
        if(g.nftTokenId>0){
            p.nftExtent = 1; 
            g.nftExtent--;
            if(g.nftExtent==0) remove_prize(r);
        } else if(g.qty>0){  
            p.nftExtent = 0;  
            g.qty--;
            if(g.qty==0) remove_prize(r);
        } else remove_prize(r);
    }
    
    function box_recycle(uint256 groupId, uint256 boxId) public onlyPartner { 
        require(boxsInfo[groupId][boxId].timeCreate > 0);
        require(boxsInfo[groupId][boxId].timeRecycle == 0);
        uint256 pokesInfoId = boxsInfo[groupId][boxId].pokesInfoId;
        for(uint i=0;i<cells_size;i++){
            POKE storage p = pokesInfo[pokesInfoId][i];
            if(p.winTime==0){
                p.recycle = block.timestamp;
                if(p.nftTokenId>0){
                     _add_nft(p.tokenAddress, p.nftTokenId, p.nftExtent);
                } else if(p.tokenAmount>0){
                    _add_token(p.tokenAddress, p.tokenAmount, 1);
                }
            }
        } 
        boxsInfo[groupId][boxId].timeRecycle = block.timestamp;
        pop_showbox(groupId,boxId);
    } 
    
     
    // add prize
    function prize_add_bnb(uint256 _amount, uint256 _qty) payable public  {
        address _tokenAddress = bnb_address;
        uint256 all_amount = msg.value;
        require(all_amount == _amount * _qty); 
        _add_token(_tokenAddress, _amount, _qty);
        rebuild_prize_cells(); 
    }
    
    function prize_add_token(address _tokenAddress, uint256 _amount, uint256 _qty) public  {
        uint256 all_amount = _amount * _qty;
        require(_tokenAddress!=address(0) && _amount>0 && _qty>0);
        require(Token(_tokenAddress).transferFrom(address(msg.sender), address(this), all_amount));
        _add_token(_tokenAddress, _amount, _qty);
        rebuild_prize_cells();
    }
    
    function _add_token(address _tokenAddress, uint256 _amount, uint256 _qty) internal {
        prizesInfo[prizeLength].tokenAddress = _tokenAddress;
        prizesInfo[prizeLength].tokenAmount = _amount;
        prizesInfo[prizeLength].qty = 1;
        prizesInfo[prizeLength].nftTokenId = 0;  
        prizesInfo[prizeLength].nftExtent = 0;  
        prizeLength++; 
        rebuild_prize_cells();
        emit log_add_token(_tokenAddress, address(msg.sender), _amount, _qty);
    }
    
    function add_nft(address _tokenAddress, uint256 _nftTokenId, uint256 _nftExtent) public  {
        require(_tokenAddress!=address(0) && _nftTokenId>0 && _nftExtent>0);
        require(Token(_tokenAddress).transferFromExtent(address(msg.sender), address(this), _nftTokenId, _nftExtent));
        _add_nft(_tokenAddress, _nftTokenId, _nftExtent);
    }
    
    function _add_nft(address _tokenAddress, uint256 _nftTokenId, uint256 _nftExtent) internal {
        prizesInfo[prizeLength].tokenAddress = _tokenAddress;
        prizesInfo[prizeLength].tokenAmount = 0;
        prizesInfo[prizeLength].nftTokenId = _nftTokenId;
        prizesInfo[prizeLength].nftExtent = _nftExtent; 
        prizeLength++; 
        emit log_add_nft(_tokenAddress, address(msg.sender), _nftTokenId);
    } 
    
    function remove_prize(uint r) internal {
        prizesInfo[r] = prizesInfo[prizeLength-1];
        prizeLength--;
    }
     
    function rebuild_prize_cells() internal {
        uint _prize_cells = 0;
        for(uint i=0; i<prizeLength; i++){
            _prize_cells += prizesInfo[i].qty +  prizesInfo[i].nftExtent;
        }
        prize_cells = _prize_cells;
    }
    
    //戳洞 pokeId = x + z*7;
    function poke(uint256 _groupId, uint256 _boxId, uint256 _pokeId) external payable {
        uint256 pokesInfoId = boxsInfo[_groupId][_boxId].pokesInfoId;
        uint256 poke_bnb_price = groupInfo[_groupId].poke_bnb_price;
        require(pokesInfo[pokesInfoId][_pokeId].winTime==0,'PokeAndWin: POKE_POKEID_WINTIME');
        require(msg.value < poke_bnb_price, 'PokeAndWin: INSUFFICIENT_A_AMOUNT'); 
        POKE storage p = pokesInfo[pokesInfoId][_pokeId];
        if(p.nftTokenId>0 && p.nftExtent>0){
            require(Token(p.tokenAddress).transferExtent(msg.sender, p.nftTokenId, 1));
        } else if(p.tokenAmount>0){
            require(Token(p.tokenAddress).transfer(msg.sender, p.tokenAmount));
        } 
        p.winnerAddress = msg.sender;
        p.winTime = block.timestamp;
    } 
    
    function randomize(uint _min, uint _max) internal  returns (uint) { 
        randNonce ++;
        randNonce = randNonce % 32767;
        seed = uint(keccak256(abi.encode(seed, block.number, block.coinbase, randNonce, block.timestamp)));  
        return _min + (seed % (_max - _min) );
    }
    
    
    /*
    
    function uint2bytes(uint256 _amount) internal pure returns (bytes memory result) { 
        uint a = _amount;
        uint p = 0;
        bytes memory buff = new bytes(80);
        if(a==0) {
            buff[p++] = byte('0');
        } else {
            while(a > 0) {
                buff[p++] = byte( 48 + uint8(a % 10) );
                a = a / 10;
            }
        }
        result = new bytes(p+2);
        for(uint i=0; i < p; i++){
            result[i] = buff[p-i-1];
        }
        result[p++] = byte(',');
        result[p++] = byte(' ');
    }
    function address2hexbytes(address _address) internal pure returns (bytes memory) { 
        bytes memory alphabet = "0123456789abcdef";
        bytes20 value = bytes20(_address);
        bytes memory buffer = new bytes(44);
        buffer[0] = byte('0');
        buffer[1] = byte('x');
        for(uint i=0;i<20; i++){
            uint8 temp = uint8(value[i]);
            buffer[i*2+2] = alphabet[temp >> 4];
            buffer[i*2+3] = alphabet[temp & 0x0f];
        }
        buffer[42] = byte(',');
        buffer[43] = byte(' ');
        return buffer;
    }
      
    function MergeBytes(bytes[] memory list) internal pure returns (bytes memory result) {
        uint totallen = 0;
        for(uint k=0; k < list.length; k++){ 
            totallen += list[k].length;
        } 
        result = new bytes(totallen);
        uint start = 0;  
        for(uint k=0; k < list.length; k++){ 
            bytes memory a = list[k];  
            uint len = a.length;
            for(uint i=0; i < len; i++){ 
                if(start<totallen)result[start++] = a[i];
            }
        }
    }
    
    
    
    function get_pokesInfo(uint id) public view returns (string memory){  
        POKE memory p = pokesInfo[id][0];
        
        bytes[] memory list = new bytes[](5);
        list[0] = address2hexbytes(p.tokenAddress);
        list[1] = address2hexbytes(p.winnerAddress);
        list[2] = uint2bytes(p.tokenAmount);
        list[3] = uint2bytes(p.nftTokenId);
        list[4] = uint2bytes(p.winTime);
        bytes memory bb = MergeBytes(list);
         
        return string(bb);
    }
    */
    
    /*
    mapping(address => CURRENCY) public currencyInfo;
    struct CURRENCY {    
        address pair_address; 
        uint112 _reserve0;
        uint112 _reserve1;
    }    
    function set_currency(address _pair_address) public {
        CURRENCY storage cc = currencyInfo[_pair_address]; 
        (cc._reserve0, cc._reserve1) = Token(_pair_address).getReserves(); 
        cc.pair_address = _pair_address;
    }
    */
    
}