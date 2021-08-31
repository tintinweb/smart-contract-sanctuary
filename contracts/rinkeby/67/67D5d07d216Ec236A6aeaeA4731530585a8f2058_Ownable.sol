/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract RetailerRole {
    using Roles for Roles.Role;

    // Define 2 events, one for Adding, and other for Removing
    event RetailerAdded(address indexed account);
    event RetailerRemoved(address indexed account);

    // Define a struct 'retailers' by inheriting from 'Roles' library, struct Role
    Roles.Role private retailers;

    // In the constructor make the address that deploys this contract the 1st retailer
    constructor() public {
        _addRetailer(msg.sender);
    }

    // Define a modifier that checks to see if msg.sender has the appropriate role
    modifier onlyRetailer() {
        require(isRetailer(msg.sender));
        _;
    }

    // Define a function 'isRetailer' to check this role
    function isRetailer(address account) public view returns (bool) {
        return retailers.has(account);
    }

    // Define a function 'addRetailer' that adds this role
    function addRetailer(address account) public onlyRetailer {
        _addRetailer(account);
    }

    // Define a function 'renounceRetailer' to renounce this role
    function renounceRetailer() public {
        _removeRetailer(msg.sender);
    }

    // Define an internal function '_addRetailer' to add this role, called by 'addRetailer'
    function _addRetailer(address account) internal {
        retailers.add(account);
        emit RetailerAdded(account);
    }

    // Define an internal function '_removeRetailer' to remove this role, called by 'removeRetailer'
    function _removeRetailer(address account) internal {
        retailers.remove(account);
        emit RetailerRemoved(account);
    }
}

contract FarmerRole {
    using Roles for Roles.Role;

    // Define 2 events, one for Adding, and other for Removing
    event FarmerAdded(address indexed account);
    event FarmerRemoved(address indexed account);

    // Define a struct 'farmers' by inheriting from 'Roles' library, struct Role
    Roles.Role private farmers;

    // In the constructor make the address that deploys this contract the 1st farmer
    constructor() public {
        _addFarmer(msg.sender);
    }

    // Define a modifier that checks to see if msg.sender has the appropriate role
    modifier onlyFarmer() {
        require(isFarmer(msg.sender));
        _;
    }

    // Define a function 'isFarmer' to check this role
    function isFarmer(address account) public view returns (bool) {
        return farmers.has(account);
    }

    // Define a function 'addFarmer' that adds this role
    function addFarmer(address account) public onlyFarmer {
        _addFarmer(account);
    }

    // Define a function 'renounceFarmer' to renounce this role
    function renounceFarmer() public {
        _removeFarmer(msg.sender);
    }

    // Define an internal function '_addFarmer' to add this role, called by 'addFarmer'
    function _addFarmer(address account) internal {
        farmers.add(account);
        emit FarmerAdded(account);
    }

    // Define an internal function '_removeFarmer' to remove this role, called by 'removeFarmer'
    function _removeFarmer(address account) internal {
        farmers.remove(account);
        emit FarmerRemoved(account);
    }
}

contract DistributorRole {
    using Roles for Roles.Role;

    // Define 2 events, one for Adding, and other for Removing
    event DistributorAdded(address indexed account);
    event DistributorRemoved(address indexed account);

    // Define a struct 'distributors' by inheriting from 'Roles' library, struct Role
    Roles.Role private distributors;

    // In the constructor make the address that deploys this contract the 1st distributor
    constructor() public {
        _addDistributor(msg.sender);
    }

    // Define a modifier that checks to see if msg.sender has the appropriate role
    modifier onlyDistributor() {
        require(isDistributor(msg.sender));
        _;
    }

    // Define a function 'isDistributor' to check this role
    function isDistributor(address account) public view returns (bool) {
        return distributors.has(account);
    }

    // Define a function 'addDistributor' that adds this role
    function addDistributor(address account) public onlyDistributor {
        _addDistributor(account);
    }

    // Define a function 'renounceDistributor' to renounce this role
    function renounceDistributor() public {
        _removeDistributor(msg.sender);
    }

    // Define an internal function '_addDistributor' to add this role, called by 'addDistributor'
    function _addDistributor(address account) internal {
        distributors.add(account);
        emit DistributorAdded(account);
    }

    // Define an internal function '_removeDistributor' to remove this role, called by 'removeDistributor'
    function _removeDistributor(address account) internal {
        distributors.remove(account);
        emit DistributorRemoved(account);
    }
}

contract ConsumerRole {
    using Roles for Roles.Role;

    // Define 2 events, one for Adding, and other for Removing
    event ConsumerAdded(address indexed account);
    event ConsumerRemoved(address indexed account);

    // Define a struct 'consumers' by inheriting from 'Roles' library, struct Role
    Roles.Role private consumers;

    // In the constructor make the address that deploys this contract the 1st consumer
    constructor() public {
        _addConsumer(msg.sender);
    }

    // Define a modifier that checks to see if msg.sender has the appropriate role
    modifier onlyConsumer() {
        require(isConsumer(msg.sender));
        _;
    }

    // Define a function 'isConsumer' to check this role
    function isConsumer(address account) public view returns (bool) {
        return consumers.has(account);
    }

    // Define a function 'addConsumer' that adds this role
    function addConsumer(address account) public onlyConsumer {
        _addConsumer(account);
    }

    // Define a function 'renounceConsumer' to renounce this role
    function renounceConsumer() public {
        _removeConsumer(msg.sender);
    }

    // Define an internal function '_addConsumer' to add this role, called by 'addConsumer'
    function _addConsumer(address account) internal {
        consumers.add(account);
        emit ConsumerAdded(account);
    }

    // Define an internal function '_removeConsumer' to remove this role, called by 'removeConsumer'
    function _removeConsumer(address account) internal {
        consumers.remove(account);
        emit ConsumerRemoved(account);
    }
}

contract SupplyChain is
    ConsumerRole,
    DistributorRole,
    FarmerRole,
    RetailerRole
{
    // Define 'owner'
    address owner;

    // Define a variable called 'upc' for Universal Product Code (UPC)
    uint256 upc;

    // Define a variable called 'sku' for Stock Keeping Unit (SKU)
    uint256 sku;

    // Define a public mapping 'items' that maps the UPC to an Item.
    mapping(uint256 => Item) items;

    // Define a public mapping 'itemsHistory' that maps the UPC to an array of TxHash,
    // that track its journey through the supply chain -- to be sent from DApp.
    mapping(uint256 => string[]) itemsHistory;

    // Define enum 'State' with the following values:
    enum State {
        Harvested, // 0
        Processed, // 1
        Packed, // 2
        ForSale, // 3
        Sold, // 4
        Shipped, // 5
        Received, // 6
        Purchased // 7
    }

    State constant defaultState = State.Harvested;

    // Define a struct 'Item' with the following fields:
    struct Item {
        uint256 sku; //DONE Stock Keeping Unit (SKU)
        uint256 upc; //DONE Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
        address ownerID; //dynamic DONE 0, Metamask-Ethereum address of the current owner as the product moves through 8 stages
        address payable originFarmerID; //Metamask-Ethereum address of the Farmer
        string originFarmName; //DONE Farmer Name
        string originFarmInformation; //DONE Farmer Information
        string originFarmLatitude; //DONE Farm Latitude
        string originFarmLongitude; //DONE Farm Longitude
        uint256 productID; //DONE Product ID potentially a combination of upc + sku
        string productNotes; //DONE Product Notes
        uint256 productPrice; //DONE Product Price
        State itemState; // Product State as represented in the enum above
        address distributorID; //DONE Metamask-Ethereum address of the Distributor
        address retailerID; //DONE Metamask-Ethereum address of the Retailer
        address payable consumerID; //DONE Metamask-Ethereum address of the Consumer
    }

    // Define 8 events with the same 8 state values and accept 'upc' as input argument
    event Harvested(uint256 upc);
    event Processed(uint256 upc);
    event Packed(uint256 upc);
    event ForSale(uint256 upc);
    event Sold(uint256 upc);
    event Shipped(uint256 upc);
    event Received(uint256 upc);
    event Purchased(uint256 upc);

    // Define a modifer that checks to see if msg.sender == owner of the contract
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner is allowed");
        _;
    }

    // Define a modifer that verifies the Caller
    modifier verifyCaller(address _address) {
        require(
            msg.sender == _address,
            "Caller is not authorized to make this transaction."
        );
        _;
    }

    // Define a modifier that checks if the paid amount is sufficient to cover the price
    modifier paidEnough(uint256 _price) {
        require(
            msg.value >= _price,
            "Amount sent does not cover product's price."
        );
        _;
    }

    // Define a modifier that checks the price and refunds the remaining balance
    modifier checkValue(uint256 _upc) {
        _;
        uint256 _price = items[_upc].productPrice;
        uint256 amountToReturn = msg.value - _price;
        address payable consumerID_add = items[_upc].consumerID;
        consumerID_add.transfer(amountToReturn);
    }

    // Define a modifier that checks if an item.state of a upc is Harvested
    modifier harvested(uint256 _upc) {
        require(
            items[_upc].itemState == State.Harvested,
            "Item has not been Harvested"
        );
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Processed
    modifier processed(uint256 _upc) {
        require(
            items[_upc].itemState == State.Processed,
            "Items is not Processed."
        );
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Packed
    modifier packed(uint256 _upc) {
        require(items[_upc].itemState == State.Packed, "Items is not Packed.");
        _;
    }

    // Define a modifier that checks if an item.state of a upc is ForSale
    modifier forSale(uint256 _upc) {
        require(
            items[_upc].itemState == State.ForSale,
            "Items is not ForSale."
        );
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Sold
    modifier sold(uint256 _upc) {
        require(items[_upc].itemState == State.Sold, "Items is not Sold.");
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Shipped
    modifier shipped(uint256 _upc) {
        require(
            items[_upc].itemState == State.Shipped,
            "Items is not Shipped."
        );
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Received
    modifier received(uint256 _upc) {
        require(
            items[_upc].itemState == State.Received,
            "Items is not Received."
        );
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Purchased
    modifier purchased(uint256 _upc) {
        require(
            items[_upc].itemState == State.Purchased,
            "Item has not been purchased before."
        );
        _;
    }

    // In the constructor set 'owner' to the address that instantiated the contract
    // and set 'sku' to 1
    // and set 'upc' to 1
    constructor() public payable {
        owner = msg.sender;
        sku = 1;
        upc = 1;
    }

    // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
    function harvestItem(
        uint256 _upc,
        address payable _originFarmerID,
        string memory _originFarmName,
        string memory _originFarmInformation,
        string memory _originFarmLatitude,
        string memory _originFarmLongitude,
        string memory _productNotes
    ) public {
        // Add the new item as part of Harvest
        items[_upc].upc = _upc;
        items[_upc].sku = sku;
        items[_upc].ownerID = _originFarmerID;
        items[_upc].itemState = State.Harvested;
        items[_upc].originFarmerID = _originFarmerID;
        items[_upc].originFarmName = _originFarmName;
        items[_upc].productID = _upc + sku;
        items[_upc].originFarmInformation = _originFarmInformation;
        items[_upc].originFarmLatitude = _originFarmLatitude;
        items[_upc].originFarmLongitude = _originFarmLongitude;
        items[_upc].productNotes = _productNotes;
        // Increment sku
        sku = sku + 1;
        // Emit the appropriate event
        emit Harvested(_upc);
    }

    // FARMER
    // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
    // Call modifier to check if upc has passed previous supply chain stage
    // Call modifier to verify caller of this function
    function processItem(uint256 _upc)
        public
        harvested(_upc)
        verifyCaller(items[_upc].ownerID)
    {
        // Update the appropriate fields
        items[_upc].itemState = State.Processed;
        // Emit the appropriate event
        emit Processed(_upc);
    }

    // FARMER
    // Define a function 'packItem' that allows a farmer to mark an item 'Packed'
    // Call modifier to check if upc has passed previous supply chain stage
    // Call modifier to verify caller of this function
    function packItem(uint256 _upc)
        public
        processed(_upc)
        verifyCaller(items[_upc].ownerID)
    {
        // Update the appropriate fields
        items[_upc].itemState = State.Packed;
        // Emit the appropriate event
        emit Packed(_upc);
    }

    // FARMER
    // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
    // Call modifier to check if upc has passed previous supply chain stage
    // Call modifier to verify caller of this function
    function sellItem(uint256 _upc, uint256 _price)
        public
        packed(_upc)
        verifyCaller(items[_upc].ownerID)
    {
        // Update the appropriate fields
        items[_upc].itemState = State.ForSale;
        items[_upc].productPrice = _price;
        // Emit the appropriate event
        emit ForSale(_upc);
    }

    // DISTRIBUTOR
    // DONE Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
    // DONE Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough,
    // DONE and any excess ether sent is refunded back to the buyer
    // DONE Call modifier to check if upc has passed previous supply chain stage
    // DONE Call modifer to check if buyer has paid enough
    // DONE Call modifer to send any excess ether back to buyer
    function buyItem(uint256 _upc)
        public
        payable
        forSale(_upc)
        paidEnough(items[_upc].productPrice)
        checkValue(_upc)
    {
        // Update the appropriate fields - ownerID, distributorID, itemState
        items[_upc].itemState = State.Sold;
        // Uptade the consumer for a proper checking of checkValue modifier
        items[_upc].consumerID = msg.sender;
        items[_upc].distributorID = msg.sender;
        // Transfer money to farmer
        uint256 _price = items[_upc].productPrice;
        items[_upc].originFarmerID.transfer(_price);
        // Change ownerId to new owner
        items[_upc].ownerID = msg.sender;
        // Updates the price with additional markup
        items[_upc].productPrice = (items[_upc].productPrice * 110) / 100;
        // emit the appropriate event
        emit Sold(_upc);
    }

    // DISTRIBUTOR
    // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
    // Use the above modifers to check if the item is sold
    // DONE Call modifier to check if upc has passed previous supply chain stage
    // DONE Call modifier to verify caller of this function
    function shipItem(uint256 _upc)
        public
        sold(_upc)
        verifyCaller(items[_upc].ownerID)
    {
        // Update the appropriate fields
        items[_upc].itemState = State.Shipped;
        // Emit the appropriate event
        emit Shipped(_upc);
    }

    // RETAILER
    // DONE Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
    // DONE Use the above modifiers to check if the item is shipped
    // DONE Call modifier to check if upc has passed previous supply chain stage
    function receiveItem(uint256 _upc)
        public
        shipped(_upc)
    // Access Control List enforced by calling Smart Contract / DApp
    {
        // Update the appropriate fields - ownerID, retailerID, itemState, consumerID
        items[_upc].ownerID = msg.sender;
        items[_upc].retailerID = msg.sender;
        items[_upc].consumerID = msg.sender;
        items[_upc].itemState = State.Received;
        // Emit the appropriate event
        emit Received(_upc);
    }

    // CONSUMER
    // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
    // Use the above modifiers to check if the item is received
    // DONE Call modifier to check if upc has passed previous supply chain stage
    function purchaseItem(uint256 _upc)
        public
        received(_upc)
    // Access Control List enforced by calling Smart Contract / DApp
    {
        // Update the appropriate fields - ownerID, consumerID, itemState
        items[_upc].ownerID = msg.sender;
        items[_upc].consumerID = msg.sender;
        items[_upc].itemState = State.Purchased;
        // Emit the appropriate event
        emit Purchased(_upc);
    }

    // Define a function 'fetchItemBufferOne' that fetches the data
    function fetchItemBufferOne(uint256 _upc)
        public
        view
        returns (
            uint256 itemSKU, // 0
            uint256 itemUPC, // 1
            address ownerID, // 2
            address originFarmerID, // 3
            string memory originFarmName, // 4
            string memory originFarmInformation, // 5
            string memory originFarmLatitude, // 6
            string memory originFarmLongitude // 7
        )
    {
        // Assign values to the 8 parameters
        itemSKU = items[_upc].sku;
        itemUPC = items[_upc].upc;
        ownerID = items[_upc].ownerID;
        originFarmerID = items[_upc].originFarmerID;
        originFarmName = items[_upc].originFarmName;
        originFarmInformation = items[_upc].originFarmInformation;
        originFarmLatitude = items[_upc].originFarmLatitude;
        originFarmLongitude = items[_upc].originFarmLongitude;

        return (
            itemSKU,
            itemUPC,
            ownerID,
            originFarmerID,
            originFarmName,
            originFarmInformation,
            originFarmLatitude,
            originFarmLongitude
        );
    }

    // Define a function 'fetchItemBufferTwo' that fetches the data
    function fetchItemBufferTwo(uint256 _upc)
        public
        view
        returns (
            uint256 itemSKU, // 0
            uint256 itemUPC, // 1
            uint256 productID, // 2
            string memory productNotes, // 3
            uint256 productPrice, // 4
            State itemState, // 5
            address distributorID, // 6
            address retailerID, // 7
            address consumerID // 8
        )
    {
        // Assign values to the 9 parameters
        itemSKU = items[_upc].sku;
        itemUPC = items[_upc].upc;
        productID = items[_upc].productID;
        productNotes = items[_upc].productNotes;
        productPrice = items[_upc].productPrice;
        itemState = items[_upc].itemState;
        distributorID = items[_upc].distributorID;
        retailerID = items[_upc].retailerID;
        consumerID = items[_upc].consumerID;
        return (
            itemSKU,
            itemUPC,
            productID,
            productNotes,
            productPrice,
            itemState,
            distributorID,
            retailerID,
            consumerID
        );
    }
}

contract Ownable is SupplyChain {
    address private origOwner;

    // Define an Event
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /// Assign the contract to an owner
    constructor() public {
        origOwner = msg.sender;
        emit TransferOwnership(address(0), origOwner);
    }

    /// Look up the address of the owner
    function ownerAddress() public view returns (address) {
        return origOwner;
    }

    /// Define a function modifier 'onlyOwner'
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /// Check if the calling address is the owner of the contract
    function isOwner() public view returns (bool) {
        return msg.sender == origOwner;
    }

    /// Define a function to renounce ownerhip
    function renounceOwnership() public onlyOwner {
        emit TransferOwnership(origOwner, address(0));
        origOwner = address(0);
    }

    /// Define a public function to transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /// Define an internal function to transfer ownership
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit TransferOwnership(origOwner, newOwner);
        origOwner = newOwner;
    }
}