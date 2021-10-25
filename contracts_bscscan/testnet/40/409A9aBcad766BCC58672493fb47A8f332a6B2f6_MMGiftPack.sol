/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;


interface IMMTools {
    function claimGift(address _addr) external;
}

interface IMMFossils {
    function claimGift(address _addr) external;
}

interface IMMMaterials {
    function claimGift(address _addr) external;
}

contract MMGiftPack{
    
    address public constant MMTOOLS_ADDRESS = 0x73D8df4624f20a40891fbE8B839566772b3eA255;
    address public constant MMFOSSILS_ADDRESS = 0xcA64083533E936453F318306B83f6BC79F65fF4f;
    address public constant MMMATERIALS_ADDRESS = 0x7943F82Ea30cE39B3Ebe4b7A6E1b4fcb05D88FD3;
    
    IMMTools public MMTools;
    IMMFossils public MMFossils;
    IMMMaterials public MMaterials;
    
    struct Pioneer {
        uint256 myth_hold;
        uint256 tools;
        uint256 fossils;
        uint256 materials;
        uint256 claimed_tools;
        uint256 claimed_fossils;
        uint256 claimed_materials;
    }
    
    mapping(address => Pioneer) public pioneers;
    
    address public owner;
    
    /**
     * @dev Emitted when the gift pack is claimed by an `account`.
     */
    event GiftPackClaimed(address indexed account, uint256 tools, uint256 fossils, uint256 materials);
    event ToolGiftClaimed(address indexed account, uint256 tools);
    event FossilGiftClaimed(address indexed account, uint256 fossils);
    event MaterialGiftClaimed(address indexed account, uint256 materials);
    

    constructor() {
        owner = msg.sender;
        
        MMTools = IMMTools(MMTOOLS_ADDRESS);
        MMFossils = IMMFossils(MMFOSSILS_ADDRESS);
        MMaterials = IMMMaterials(MMMATERIALS_ADDRESS);
        
    }
    
    function claimToolGift() external {
        require(pioneers[msg.sender].tools > 0, "Error: Not eligible for tool gift.");
        MMTools.claimGift(msg.sender);
        pioneers[msg.sender].tools--;
        pioneers[msg.sender].claimed_tools++;
        emit ToolGiftClaimed(msg.sender, pioneers[msg.sender].tools);
    }
    
    function claimAllToolsGift() external {
        require(pioneers[msg.sender].tools > 0, "Error: Not eligible for tool gift.");
        
        for(uint256 i = 0; i < pioneers[msg.sender].tools; i++){
            MMTools.claimGift(msg.sender);
            pioneers[msg.sender].claimed_tools++;
        }
        
        pioneers[msg.sender].tools = 0;
        emit ToolGiftClaimed(msg.sender, pioneers[msg.sender].tools);
    }
    
    function claimFossilGift() external {
        require(pioneers[msg.sender].fossils > 0, "Error: Not eligible for fossil gift.");
        MMFossils.claimGift(msg.sender);
        pioneers[msg.sender].fossils--;
        pioneers[msg.sender].claimed_fossils++;
        emit FossilGiftClaimed(msg.sender, pioneers[msg.sender].fossils);
    }
    
    function claimAllFossilsGift() external {
        require(pioneers[msg.sender].fossils > 0, "Error: Not eligible for fossil gift.");
        
        for(uint256 i = 0; i < pioneers[msg.sender].fossils; i++){
            MMFossils.claimGift(msg.sender);
            pioneers[msg.sender].claimed_fossils++;
        }
        
        pioneers[msg.sender].fossils = 0;
        emit FossilGiftClaimed(msg.sender, pioneers[msg.sender].fossils);
    }
    
    function claimMaterialGift() external {
        require(pioneers[msg.sender].materials > 0, "Error: Not eligible for material gift.");
        MMaterials.claimGift(msg.sender);
        pioneers[msg.sender].materials--;
        pioneers[msg.sender].claimed_materials++;
        emit MaterialGiftClaimed(msg.sender, pioneers[msg.sender].materials);
    }
    
    function claimAllMaterialsGift() external {
        require(pioneers[msg.sender].materials > 0, "Error: Not eligible for material gift.");

        for(uint256 i = 0; i < pioneers[msg.sender].materials; i++){
            MMaterials.claimGift(msg.sender);
            pioneers[msg.sender].claimed_materials++;
        }
        
        pioneers[msg.sender].materials = 0;
        emit MaterialGiftClaimed(msg.sender, pioneers[msg.sender].materials);
    }
    
    function claimGiftPack() external {
        require(pioneers[msg.sender].tools > 0 || 
                pioneers[msg.sender].fossils > 0 || 
                pioneers[msg.sender].materials > 0, "Error: Not eligible for gift pack.");
                
        if(pioneers[msg.sender].tools > 0){
            for(uint256 i = 0; i < pioneers[msg.sender].tools; i++){
                MMTools.claimGift(msg.sender);
                pioneers[msg.sender].claimed_tools++;
            }
        }
        
        if(pioneers[msg.sender].fossils > 0){
            for(uint256 i = 0; i < pioneers[msg.sender].fossils; i++){
                MMFossils.claimGift(msg.sender);
                pioneers[msg.sender].claimed_fossils++;
            }
        }
        
        if(pioneers[msg.sender].materials > 0){
            for(uint256 i = 0; i < pioneers[msg.sender].materials; i++){
                MMaterials.claimGift(msg.sender);
                pioneers[msg.sender].claimed_materials++;
            }
        }
        
        pioneers[msg.sender].tools = 0;
        pioneers[msg.sender].fossils = 0;
        pioneers[msg.sender].materials = 0;
        
        emit GiftPackClaimed(msg.sender, pioneers[msg.sender].tools,  pioneers[msg.sender].fossils, pioneers[msg.sender].materials);
    }
    
    function setPioneers(address[] memory _addrs, uint256[] memory _value) external {
        require(owner == msg.sender, "Error: Insufficient permission.");
        
        for(uint256 i = 0; i < _addrs.length; i++){
            uint256 tools = 0;
            uint256 fossils = 0;
            uint256 materials = 0;
            
            if(_value[i] >= 1000 && _value[i] < 5000){
                tools = 0;
                fossils = 0;
                materials = 2;
            }
            
            if(_value[i] >= 5000 && _value[i] < 20000){
                tools = 0;
                fossils = 1;
                materials = 2;
            }
            
            if(_value[i] >= 20000 && _value[i] < 100000){
                tools = 0;
                fossils = 2;
                materials = 2;
            }
            
            if(_value[i] >= 100000){
                tools = 1;
                fossils = 5;
                materials = 0;
            }
            
            pioneers[_addrs[i]].tools = tools;
            pioneers[_addrs[i]].fossils = fossils;
            pioneers[_addrs[i]].materials = materials;
        }
    }
    
}