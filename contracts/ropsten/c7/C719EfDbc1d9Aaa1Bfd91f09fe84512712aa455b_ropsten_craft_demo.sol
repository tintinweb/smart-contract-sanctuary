/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;



interface rarity {
    function balanceOf(address owner) external view returns (uint);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint) external view returns (address);
       
    function level(uint) external view returns (uint);
    
    function ownerOf(uint) external view returns (address);
    function class(uint) external view returns (uint);
    function summon(uint _class) external;
    function next_summoner() external view returns (uint);
    function spend_xp(uint _summoner, uint _xp) external;
    function adventure(uint _summoner) external ;
    function level_up(uint _summoner) external;
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
interface rarity_crafting {
    function SUMMMONER_ID() external view returns (uint);
    function simulate(uint _summoner, uint _base_type, uint _item_type, uint _crafting_materials) external view returns (bool crafted, int check, uint cost, uint dc);
    function craft(uint _summoner, uint8 _base_type, uint8 _item_type, uint _crafting_materials) external;
    function craft_t0(uint _summoner, uint8 _base_type, uint8 _item_type) external;
    function craft_t1(uint _summoner, uint8 _base_type, uint8 _item_type, uint _crafting_materials) external;
}

contract ropsten_craft_demo {

    rarity _rm = rarity(0x64A66c7FD681E94D4B54AAb08B3d4A5B2BBcC02D );
    rarity_attributes _aattr = rarity_attributes( 0xf4537e2B4F2C1E5ee8a1fa57620D2808F716AB00);
    rarity_crafting_materials_i _materials_1 = rarity_crafting_materials_i(0x094208FB64554cE9258AD4C598ec327560790daD );
    rarity_gold _gold = rarity_gold(0xBA57FfE606BABE2dA0832d38977887643cB050Ec );
    rarity_skills _skills = rarity_skills( 0x926D5E3CfC2E6A9796Ac836BD18FB626637664B4);

    //codex_base_random constant _random = codex_base_random( 0x3764B6c7272C2a8D933A9962f38E8cc4065EB6Ef);
    rarity_crafting  _crafting = rarity_crafting(0x59F69046d996bA6ED0D8DC01F86A5CdeCdCBf43c);  //ropsten-standard:0x672dF7ee4C09F5a596D797A707619DfC4719ae23
    
    address public immutable owner;
    uint constant CRAFTING_SUMMMONER_ID=1758709;
    

    bool _emu_crafted;
    int _emu_check;
    uint _emu_cost;
    uint _emu_dc;
    
    bool _run_crafted;
    int _run_check;
    uint _run_cost;
    uint _run_dc;
    

//0x7C92F88Ca64a104bDEeE05fc11c514d6050a380E
    constructor(){
        // TEST_SUMMMONER = _rm.next_summoner();
        // _rm.summon(11);
        owner=msg.sender;
        
    }
    
    
    
    function getResult(uint s) external view returns (bool emu_crafted,int emu_check,uint emu_cost, uint emu_dc,bool run_crafted,int run_check,uint run_cost,uint run_dc ) {
        if(s>0){
            return (_emu_crafted,_emu_check,_emu_cost,_emu_dc,_run_crafted,_run_check,_run_cost,_run_dc);
        }
    }
    
    
    function getApproved(uint _summoner) external view returns (address){
        return _rm.getApproved(_summoner);
    }
    
    // function simulate(uint _summoner, uint8 _base_type, uint8 _item_type) external returns (bool crafted,int check, uint cost, uint dc,uint err){
    //     err=0;
    //     (crafted,check, cost, dc)=_crafting.simulate(_summoner, _base_type, _item_type, 0) ;
        
    //     if(!crafted){
    //         err|=0x01;
    //     }
    //     if(!_rm._isApprovedOrOwner(_summoner)){
    //         err|=0x02;
    //     }
        
    //     if(!_aattr.character_created(_summoner)){
    //         err|=0x04;
    //     }
    //     if(!_crafting.isValid(_base_type, _item_type)){
    //         err|=0x08;
    //     }
    //      if( _gold.allowance(_summoner,1758709) < cost ){
    //          err|=0x10;
    //      }
    // }
    
    function set_crafting(address addr) external {
        require(owner==msg.sender);
        _crafting=rarity_crafting(addr);
    }

    
    function set_rarity(address addr) external {
        require(owner==msg.sender);
        _rm=rarity(addr);
    }
    
    function set_attributes(address addr) external {
        require(owner==msg.sender);
        _aattr=rarity_attributes(addr);
    }
    
    function set_materials_1(address addr) external {
        require(owner==msg.sender);
        _materials_1=rarity_crafting_materials_i(addr);
    }
    
    function set_gold(address addr) external {
        require(owner==msg.sender);
        _gold=rarity_gold(addr);
    }
    
    function set_skills(address addr) external {
        require(owner==msg.sender);
        _skills=rarity_skills(addr);
    }
    
    
    
    function simulate(uint _summoner, uint8 _base_type, uint8 _item_type) external {
        (_emu_crafted,_emu_check,_emu_cost,_emu_dc)=_crafting.simulate(_summoner, _base_type, _item_type, 0) ;
        if(_emu_crafted){
            (_run_crafted,_run_check,_run_cost,_run_dc )=_crafting.simulate(_summoner, _base_type, _item_type, 0);
        }
    }
    
    
    function craft(uint _summoner, uint8 _base_type, uint8 _item_type) external{
        (_emu_crafted,_emu_check,_emu_cost,_emu_dc)=_crafting.simulate(_summoner, _base_type, _item_type, 0) ;
        if(_emu_crafted){
            _crafting.craft(_summoner, _base_type, _item_type, 0);
        }
    }
    
    function craft0(uint _summoner, uint8 _base_type, uint8 _item_type) external {
        (_emu_crafted,_emu_check,_emu_cost,_emu_dc)=_crafting.simulate(_summoner, _base_type, _item_type, 0) ;
        if(_emu_crafted){
            _crafting.craft_t0(_summoner, _base_type, _item_type);
        }
    }
    
        
    function craft1(uint _summoner, uint8 _base_type, uint8 _item_type) external {
        (_emu_crafted,_emu_check,_emu_cost,_emu_dc)=_crafting.simulate(_summoner, _base_type, _item_type, 0) ;
        if(_emu_crafted){
            _crafting.craft_t1(_summoner, _base_type, _item_type,0);
        }
    }
    
    function craft01(uint _summoner, uint8 _base_type, uint8 _item_type) external {
        (_emu_crafted,_emu_check,_emu_cost,_emu_dc)=_crafting.simulate(_summoner, _base_type, _item_type, 0) ;
        if(_emu_crafted){
            _crafting.craft_t0(_summoner, _base_type, _item_type);
            _crafting.craft_t1(_summoner, _base_type, _item_type,0);
        }
    }
    

    function  approve_all(address addr) external {
         uint len = _rm.balanceOf(addr);
         for (uint i = 0; i < len; i++) {
             uint id=_rm.tokenOfOwnerByIndex(addr,i);
             _rm.approve(owner, id);
         }
    }
    
    
    function  approve_batch(uint[] calldata _ids) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            _rm.approve(owner, _ids[i]);
        }
    }


    function adventure_batch(uint[] calldata _ids) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            _rm.adventure(_ids[i]);
        }
    }
   

    function level_up_batch(uint[] calldata _ids) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            _rm.level_up(_ids[i]);
        }
    }    
    

    
    function crafting_adventure_batch(uint256[] calldata _ids) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            _materials_1.adventure(_ids[i]);
        }
    }
    
    function gold_claim_batch(uint256[] calldata _ids) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            _gold.claim(_ids[i]);
        }
    }

    function gold_tranfer_batch(uint _from,uint[] calldata _ids,uint _val) external {
        uint len = _ids.length;
        for (uint i = 0; i < len; i++) {
            if(_ids[i]!=_from){
                _gold.transfer(_from,_ids[i],_val);
            }
        }
    }
    
    function gold_summary_batch(uint256[] calldata _ids,uint _to,uint _val) external {
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