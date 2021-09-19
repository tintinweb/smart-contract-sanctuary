/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ERC20 {  
    function decimals() external view returns (uint8 decimals); 
    function totalSupply() external view returns (uint totalSupply);  
    function balanceOf(address _owner) external view returns (uint balance);  
    function transfer(address _to, uint _value) external returns (bool success);  
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);  
    function approve(address _spender, uint _value) external returns (bool success);  
    function allowance(address _owner, address _spender) external view returns (uint remaining);  
}

interface IERC721Receiver {
    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) external returns (bytes4);
}

interface ERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    
    
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}


interface rarity is ERC721 {
    // function balanceOf(address owner) external view returns (uint);
    // function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    // function approve(address to, uint256 tokenId) external;
    // function getApproved(uint) external view returns (address);
    // function ownerOf(uint) external view returns (address);
    function level(uint) external view returns (uint);
    

    function adventurers_log(uint) external view returns (uint);
    function class(uint) external view returns (uint);
    function summon(uint _class) external;
    function next_summoner() external view returns (uint);
    function spend_xp(uint _summoner, uint _xp) external;
    function adventure(uint _summoner) external ;
    function level_up(uint _summoner) external;
    
    function xp_required(uint curent_level)  external view  returns (uint);
    function xp(uint _summoner)  external view  returns (uint);
}

interface rarity_attributes {
    function character_created(uint) external view returns (bool);
    function ability_scores(uint) external view returns (uint32,uint32,uint32,uint32,uint32,uint32);
}

interface rarity_skills {
    function get_skills(uint _summoner) external view returns (uint8[36] memory);
}

interface rarity_gold {
    function approve(uint from, uint spender, uint amount) external returns (bool);
    function allowance(uint summoner,uint executer) external view returns (uint);
    function balanceOf(uint summoner) external view returns (uint);
    function claim(uint summoner) external;
    function transfer(uint from, uint to, uint amount) external returns (bool);
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

interface rarity_crafting_materials_i {
    function adventure(uint _summoner) external returns (uint reward);
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

// interface codex_base_random {
//     function d20(uint _summoner) external view returns (uint);
// }
interface rarity_crafting is ERC721 {
    //function SUMMMONER_ID() external view returns (uint);
    function craft(uint _summoner, uint8 _base_type, uint8 _item_type, uint _crafting_materials) external;
    function simulate(uint _summoner, uint _base_type, uint _item_type, uint _crafting_materials) external view returns (bool crafted, int check, uint cost, uint dc);
}


contract ropsten_craft_demo is IERC721Receiver {

    rarity _rm = rarity(0x64A66c7FD681E94D4B54AAb08B3d4A5B2BBcC02D );
    rarity_attributes _aattr = rarity_attributes( 0xf4537e2B4F2C1E5ee8a1fa57620D2808F716AB00);
    rarity_crafting_materials_i _materials_1 = rarity_crafting_materials_i(0x094208FB64554cE9258AD4C598ec327560790daD );
    rarity_gold _gold = rarity_gold(0xBA57FfE606BABE2dA0832d38977887643cB050Ec );
    rarity_skills _skills = rarity_skills( 0x926D5E3CfC2E6A9796Ac836BD18FB626637664B4);

    //codex_base_random constant _random = codex_base_random( 0x3764B6c7272C2a8D933A9962f38E8cc4065EB6Ef);
    rarity_crafting  _crafting = rarity_crafting(0xb503F3F6F6ed2BDB0aDaE36071D3ab784eDD6572);  //ropsten-standard:0x672dF7ee4C09F5a596D797A707619DfC4719ae23
    
    address immutable _owner;
    //uint constant CRAFTING_SUMMMONER_ID=1758709;
    

    bool public last_crafted;
    int  public last_check;
    uint public last_cost;
    uint public last_dc;
    

    constructor(){
        _owner=payable(msg.sender);
    }
    
    function onERC721Received(address,address ,uint256 ,bytes calldata ) public virtual override  returns (bytes4){
        return this.onERC721Received.selector;
    }


    function withdraw_erc721(address contact_addr,uint max) external {
        address _inner=address(this);
        
        ERC721 _erc721=ERC721(contact_addr);
        
        uint len = _erc721.balanceOf(_inner);
        for (uint i = 0; (i < len) && (i < max); i++) {
            uint _id=_erc721.tokenOfOwnerByIndex(_inner,i);
            _erc721.transferFrom(_inner,_owner,_id);
        }
    }
    
    
    function withdraw_erc20(address contact_addr) external{
        address _inner=address(this);
        
        if(_inner.balance>0){
            payable(_owner).transfer(_inner.balance);
        }
        
        ERC20 _erc20=ERC20(contact_addr);
        if(_erc20.balanceOf(_inner) >0){
            _erc20.transfer(_owner,_erc20.balanceOf(_inner));
        }
    }
    
        
    function set_rarity(address addr) external {
        require(_owner==msg.sender);
        _rm=rarity(addr);
    }
    
    function set_crafting(address addr) external {
        require(_owner==msg.sender);
        _crafting=rarity_crafting(addr);
    }

    function set_attributes(address addr) external {
        require(_owner==msg.sender);
        _aattr=rarity_attributes(addr);
    }
    
    function set_materials_1(address addr) external {
        require(_owner==msg.sender);
        _materials_1=rarity_crafting_materials_i(addr);
    }
    
    function set_gold(address addr) external {
        require(_owner==msg.sender);
        _gold=rarity_gold(addr);
    }
    
    function set_skills(address addr) external {
        require(_owner==msg.sender);
        _skills=rarity_skills(addr);
    }
    
    
    function getAddress(uint8 index) external view returns (address){
        if(index==0 ){
            return address(_rm);
        }else if(index==1){
            return address(_aattr);
        }else if(index==2){
            return address(_gold); 
        }else if(index==3){
            return address(_skills);
        }else if(index==4 ){
            return address(_materials_1);
        }else if(index==5){
            return address(_crafting);
        }else if(index==255){
            return _owner;
        }else{
            return address(0);
        }
    }
    


    function craft(uint _summoner, uint8 _base_type, uint8 _item_type) external{
        require(_owner==msg.sender);
        (last_crafted,last_check,last_cost,last_dc)=_crafting.simulate(_summoner, _base_type, _item_type, 0) ;
        if(last_crafted){
            _crafting.craft(_summoner, _base_type, _item_type, 0);
        }
    }
    

    function  approve_all() external {
        require(_owner==msg.sender);
        
        address me=address(this);
        uint len = _rm.balanceOf(_owner);
        for (uint i = 0; i < len; i++) {
            uint id=_rm.tokenOfOwnerByIndex(_owner,i);
            _rm.approve(me, id);
        }
    }
    
    
    function adventure_all() external {
        require(_owner==msg.sender);
        
        uint len = _rm.balanceOf(_owner);
        for (uint i = 0; i < len; i++) {
            uint id=_rm.tokenOfOwnerByIndex(_owner,i);
            if(block.timestamp>_rm.adventurers_log(id) ){
                _rm.adventure(id);
            }
        }
    }
   

    function level_up_all() external {
        require(_owner==msg.sender);
        
        uint len = _rm.balanceOf(_owner);
        for (uint i = 0; i < len; i++) {
            uint _id=_rm.tokenOfOwnerByIndex(_owner,i);
            uint _level = _rm.level(_id);
            if( _rm.xp(_id)>= _rm.xp_required(_level) ){
                _rm.level_up(_id);
            }
        }
    }    
    
    
    function gold_claim_all() external {
        require(_owner==msg.sender);
        
        uint len = _rm.balanceOf(_owner);
        for (uint i = 0; i < len; i++) {
            uint _id=_rm.tokenOfOwnerByIndex(_owner,i);
            _gold.claim(_id);
        }
    }
    
    function crafting_adventure_batch(uint256[] calldata _ids) external {
        require(_owner==msg.sender);
        
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            _materials_1.adventure(_ids[i]);
        }
    }
    
    function gold_claim_batch(uint256[] calldata _ids) external {
        require(_owner==msg.sender);
        
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            _gold.claim(_ids[i]);
        }
    }

    function gold_tranfer_batch(uint _from,uint[] calldata _ids,uint _val) external {
        require(_owner==msg.sender);
        
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            uint _to= _ids[i];
            if(_rm.ownerOf(_to)==msg.sender &&  _to!=_from){
                _gold.transfer(_from,_ids[i],_val);
            }
        }
    }
    
    function gold_summary_batch(uint256[] calldata _ids,uint _to,uint _val) external {
        require(_owner==msg.sender);
        require(_rm.ownerOf(_to) == msg.sender);
        
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            uint _from=_ids[i];
            if(_from!=_to){
                if(_val>_gold.balanceOf(_from)){
                    _val=_gold.balanceOf(_from);
                }
                _gold.transfer(_from,_to, _val);
            }
        }
    }
    
    function gold_summary_all(address addr,uint _to,uint _val) external {
        require(_owner==msg.sender);
        require(_rm.ownerOf(_to) == msg.sender);
        
        uint len = _rm.balanceOf(addr);
        for (uint i = 0; i < len; i++) {
            uint _from=_rm.tokenOfOwnerByIndex(addr,i);
            if(_from!=_to){
                if(_val>_gold.balanceOf(_from)){
                    _val=_gold.balanceOf(_from);
                }
                _gold.transfer(_from,_to, _val);
            }
        }
    }
}