pragma solidity 0.5.0;

contract LocalInventoryManagement {
    
    address creator;
    
    struct ShopOwner {
        string id;
        string name;
        bool isValue;
    }
    
    struct Product {
        string id;
        string name;
        string categoryId;
        string shopOwnerId;
        uint quantity;
        string status;
        bool isValue;
    }
    
    struct Category {
        string id;
        string name;
        bool isValue;
    }
    
    mapping(string => ShopOwner) private mapShopOwner;
    mapping(string => Product) private mapProduct;
    mapping(string => Category) private mapCategory;
    
    modifier isSuperAdmin() {
        // check the msg sender as super admin
        _;
    }
    
    modifier isProductExist(string memory _id) {
        require(mapProduct[_id].isValue == false, &#39;product already exists&#39;);
        _;
    }
    
    modifier isShopOwner(string memory _shopOwnerId) {
        require(mapShopOwner[_shopOwnerId].isValue == true, &#39;Invalid shop owner id&#39;);
        _;
    }
    
    modifier isCategory(string memory _categoryId) {
        require(mapCategory[_categoryId].isValue == true, &#39;Invalid category id&#39;);
        _;
    }
    
    function createShopOwner(string memory _id, string memory _name) 
        public payable returns(bool success) {
        mapShopOwner[_id] = ShopOwner(_id, _name, true);
        return (true);
    }
    
    function getShopOwner(string memory _id) public view returns (string memory, string memory) {
        return (mapShopOwner[_id].id, mapShopOwner[_id].name);
    }
    
    function createProduct(string memory _id, 
                            string memory _name, 
                            string memory _categoryId, 
                            string memory _shopOwnerId,
                            uint _quantity) public payable 
                            isSuperAdmin() 
                            isProductExist(_id) 
                            isShopOwner(_shopOwnerId) 
                            isCategory(_categoryId) 
                            returns(bool success) {
        mapProduct[_id] = Product(_id, _name, _categoryId, _shopOwnerId, _quantity, &#39;Available&#39;, true);
        return (true);
    }
    
    function getProduct(string memory _id) public view 
            returns(string memory, string memory, string memory, string memory, uint, string memory) {
        return (mapProduct[_id].id,
            mapProduct[_id].name,
            mapProduct[_id].categoryId, 
            mapProduct[_id].shopOwnerId,
            mapProduct[_id].quantity,
            mapProduct[_id].status);
    }
    
    function createCategory(string memory _id, string memory _name) public payable returns(bool success) {
        mapCategory[_id] = Category(_id, _name, true);
        return (true);
    }
    
    function getCategory(string memory _id) public view returns(string memory, string memory) {
        return (mapCategory[_id].id, mapCategory[_id].name);
    }
}