/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract StoreForm {

    string  public  title;
    string  public  imageURL;
    string  public  description;
    uint256 public  buyPrice;
    uint256 public  rentPrice;
    
    
    function store(
            string  memory  _title,
            string  memory  _imasgeURL,
            string  memory  _description,
            uint256 _buyPrice,
            uint256 _rentPrice) public {
        title       =   _title;
        imageURL    =   _imasgeURL;
        description =   _description;
        buyPrice    =   _buyPrice;
        rentPrice   =   _rentPrice;
    }


}