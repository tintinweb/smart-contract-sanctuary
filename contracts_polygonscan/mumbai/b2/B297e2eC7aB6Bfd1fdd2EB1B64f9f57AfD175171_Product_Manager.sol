/**
 *Submitted for verification at polygonscan.com on 2022-01-04
*/

// File: Product_Manager.sol


pragma solidity ^0.8.0;

library Product {
   
    struct item{
        uint wid;
        uint create_time;
        uint value;
        address owner;

    }

}
interface NFT_Manager_Interface {
    function Mint(
        address owner_addr,
        uint256 id,
        uint256 qty,
        bytes memory title
    ) external;
}

interface Rebecca_Token {
 
    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}


contract Product_Manager  {
    
    address Main_Token_Contract_Addr = 0xC647D7aaBF2A91B5d2a9029357d34c2a10781647;
    address NFT_Manager_Contract_Addr = 0x3C5b1641fDd4139a61b6A24CFaeC5c7166C0b419 ;
    mapping(address => bytes32[])  Product_List;
    mapping(bytes32 => Product.item) Product_Setting;
    uint Now_Water_ID; //流水號
    Rebecca_Token Main_Token_Contract ;
    NFT_Manager_Interface NFT_Mag_Contract;

    address owner;
    constructor ()  {
        owner = msg.sender;
        Main_Token_Contract = Rebecca_Token(Main_Token_Contract_Addr);
        NFT_Mag_Contract = NFT_Manager_Interface(NFT_Manager_Contract_Addr);
    }
    function Get_All_Product_List(address addr) public view returns (bytes32[] memory) {
        return Product_List[addr];
    }
    function Set_Main_Token_Contract(address addr) public {
        require(msg.sender == owner);
        Main_Token_Contract_Addr = addr;
        Main_Token_Contract = Rebecca_Token(Main_Token_Contract_Addr);
    }
    function Set_NFT_Manager_Contract(address addr) public {
        require(msg.sender == owner);
        NFT_Manager_Contract_Addr = addr;
        NFT_Mag_Contract = NFT_Manager_Interface(NFT_Manager_Contract_Addr);
    }
    //銷售商品
    function Sale_Product(bytes32 item_hash,uint256 qty) public{
        require(Product_Setting[item_hash].create_time != 0,'Product is Exist!');

        Product.item memory Product_CFG = Product_Setting[item_hash];
        uint256 value = Product_CFG.value;

        Main_Token_Contract.transferFrom(msg.sender,Product_CFG.owner,value*qty);

        NFT_Mag_Contract.Mint( msg.sender,Product_CFG.wid,qty,"0x001");

    }
    //創建商品
    function Create_Product(uint256 token_value) public{

        Now_Water_ID +=1; 
        bytes32 item_hash = Gen_Item_Hash(msg.sender, Now_Water_ID,block.timestamp);
        // require(Product_Money[item_hash].create_time != 0,'Product is Exist!');
        Product.item memory Product_CFG ;

        Product_CFG.create_time = block.timestamp;
        Product_CFG.value = token_value;
        Product_CFG.wid = Now_Water_ID;
        Product_CFG.owner = msg.sender;
        Product_Setting[item_hash] = Product_CFG;
        Product_List[msg.sender].push(item_hash);
        

    }


    function Gen_Item_Hash(address addr,uint256 id,uint256 water_num) internal returns(bytes32 _id) {
            bytes32 id = keccak256(abi.encodePacked(addr,id,water_num));
            return id;

    }
    
   
    
}