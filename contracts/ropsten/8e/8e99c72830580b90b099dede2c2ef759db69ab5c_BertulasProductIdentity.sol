/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.0 <0.6.0;

/**
 * @title BertulasProductIdentity
 * @dev Manage the identity registration of a product
 */
contract BertulasProductIdentity {

    struct Product {   // Basic data of an agrifood product
        string  name;
        string producer;
        string description;
        string ean;
        Production production;
        mapping(uint => Tracking) tracking;
        uint trackingSize;
        string imageHash;
        bool valid;
    }

    struct Production {  // Data about a specific production batch
        string lotCode;
        uint256 startProductionDate;
        uint256 deadlineDate;
        uint256 endProductionDate;
        uint amount;
        mapping(uint => Ingredient) ingredients;
        uint ingredientsSize;
        bool valid;
        string nutritional;
    }

    struct Ingredient {  // Data about a product ingredient
        string name;
        string lot;
        uint qty;
    }

    struct Tracking {    // Data about a product location on a given date
        string description;
        uint256 date;
        string position;

    }

    Product private product;

    function createProduct(string memory name, string memory  producer, string memory  description, string memory  ean, string memory imageHash) public {
        product.name = name;
        product.producer = producer;
        product.description = description;
        product.ean = ean;
        product.valid = true;
        product.imageHash = imageHash;

    }

    function createProduction(string memory  lot, uint256 startProductionDate, uint256 deadlineDate,uint256 endProductionDate, uint amount, string memory nutritional) public {
        require(product.valid);

        product.production.lotCode = lot;
        product.production.startProductionDate = startProductionDate;
        product.production.deadlineDate = deadlineDate;
        product.production.endProductionDate = endProductionDate;
        product.production.amount = amount;
        product.production.valid = true;
        product.production.nutritional = nutritional;
    }

    function createIngredient(string memory  name, string memory  lot, uint qty) public {
        require(product.valid);
        require(product.production.valid);

        Ingredient memory i = Ingredient(
            {
            name : name,
            lot : lot,
            qty : qty
            }
        );

        product.production.ingredients[product.production.ingredientsSize] = i;
        product.production.ingredientsSize++;
    }

    function createTracking(string memory description, uint256 date, string memory position) public {
        require(product.valid);

        Tracking memory t = Tracking(
            {
            description: description,
            date: date,
            position: position
            }
        );

        product.tracking[product.trackingSize] = t;
        product.trackingSize++;
    }

    function getProduct() public view returns(string memory name, string memory producer,  string memory description, string memory ean, uint trackingSize, string memory imageHash) {
        return(product.name, product.producer, product.description, product.ean, product.trackingSize, product.imageHash);
    }

    function getProduction() public view returns(string memory lot, uint256 startProductionDate, uint256 deadlineDate,uint256 endProductionDate, uint amount, uint ingredientsSize, string memory nutritional) {

        Production memory p = product.production;
        return(p.lotCode, p.startProductionDate, p.deadlineDate, p.endProductionDate, p.amount, p.ingredientsSize, p.nutritional);
    }

    function getIngredient(uint index) public view returns(string memory name, string memory lot, uint qty, uint i){

        Ingredient memory ing = product.production.ingredients[index];
        return (ing.name, ing.lot, ing.qty, index);
    }


    function getTracking(uint index) public view returns(string memory description, uint256 date, string memory position, uint i){
        Tracking memory t = product.tracking[index];
        return (t.description, t.date, t.position, index);

    }
}