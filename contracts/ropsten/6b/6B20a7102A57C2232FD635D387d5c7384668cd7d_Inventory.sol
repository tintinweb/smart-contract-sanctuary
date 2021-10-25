/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inventory : The Following types of inventory are considered
// 1 : Raw material to manufacture new products
// 2 : Finished products are stored in the inventory.
// Assets : 2 types of assets are considered.
// 1  :  Tangible
// 2  :  Intangible
// An organization need to purchase  the raw material to manufacture the products.
// This raw material is stored in Stores.
// Part of the raw material is to be sent to manufacturing department.
// Manufacturing department manufactures products.
// Finished products are stored in the inventory.

contract Inventory {
   
   
   mapping(string=>uint256) public assets;
   mapping (string=>uint256) public asset_qty_inventory;
   mapping (string=>uint256) public asset_qty_manufacturing;
   string [] assets_inventory;

   modifier OnlyInventory(uint256 deptno){
       require(deptno == 1);
       _;
   }
   modifier OnlyManufacturing(uint256 deptno){
     require(deptno == 2);
       _;
   }
   // Assumed that there are 2 departments whch are numbered as 1 and 2
   // department 1 is the stores department
   // department 2 is the manufacturing department
   
   function add_raw_material_to_inventory(string memory asset_id,uint256 deptno,uint256 qty) public OnlyInventory(deptno){
    assets[asset_id] = 1;
    asset_qty_inventory[asset_id]  = qty;
    assets_inventory.push(asset_id);
       }
   
   
   
   // sending raw material to prepare a product to manufacturing department from store department.
    
    function send_raw_material_to_manufacturing(string memory asset_id,uint256 deptno,uint256 qty_sent) public OnlyInventory(deptno) {
        assets[asset_id ] = 2;
        asset_qty_manufacturing[asset_id] += qty_sent;
        asset_qty_inventory[asset_id] -=  qty_sent;
        
    }   
   
    function find_department(string memory asset_id) public view returns(uint256){
        return assets[asset_id];
    }
   
    function list_all_assets() public view returns(string [] memory){
        return assets_inventory;
    }
  // List all assets under the control of the department(deptno)
    function list_all_assets_deptwise(uint256 deptno)public view returns(string[] memory ){
       string []  memory all_assets_deptwise_list; 
       uint8  k=0;
      for (uint8 i =0;i< assets_inventory.length;i++) {
          string memory id_of_asset = assets_inventory[i];
          if(assets[id_of_asset] == deptno){
                all_assets_deptwise_list[k] = id_of_asset;
                k++;
          }
      }   
     return all_assets_deptwise_list;   
    }
// manufacturing department manufactures a product and adds it to invetory( because fininshed product is an Inventory)
    function add_product(string memory prod_id,uint256 deptno)public OnlyManufacturing(deptno){
       assets[prod_id] = 1;
       assets_inventory.push(prod_id);
    }
// Add company tangible assets like land,building,vehicles etc.
    function add_tangible_assets(string memory asset_id) public {
        assets[asset_id] = 1;
        assets_inventory.push(asset_id);
    }
// Add company intangible assets like patents,copyrights etc    
    function add_non_tangible_assets(string memory asset_id) public {
        assets[asset_id] = 1;
        assets_inventory.push(asset_id);
    }
    

}