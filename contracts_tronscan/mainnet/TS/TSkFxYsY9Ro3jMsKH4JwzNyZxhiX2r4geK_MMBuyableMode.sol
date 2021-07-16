//SourceUnit: MMBuyableMode.sol

 /**
 * @title MMBuyableMode
 * @author Davinder Singh
 * @notice Implements a Smart Contract to buy all Digital assets in MM.
 */

pragma solidity ^0.4.24;

contract MMBuyableMode {
    /**
     * @notice Use this to store contract owner.
     */
    address owner;
    address directorAddress;
    /**
     * @notice Following 5 variables will store Each digital(using in game) asset's price .
     */
    uint256 donkeyPrice;
    uint256 camelPrice;
    uint256 landPrice;
    uint256 metalDetector;
    uint256 excavator;
    /**
     * @notice A land structure refred to one specific land/sqaure.
     */
    struct Land {
        uint256 lid;
        uint256 price;
        address owner;
        bool isPurchasable;
    }
    /**
     * @notice This array store all land bought by users/players.
     */
    Land[] lands;
    /**
     * @notice This mapping will map Land id to Land owner's TRON address.
     */
    mapping (uint256 => address) lidToOwner;
    /**
     * @notice This mapping will map Land id(0-49352) to Lands array index.
     */
    mapping (uint256 => uint256) lidToLandsIdx;
    
   /**
     * @notice Events.
     */
    enum AssetType {FreshLand, PreOwnedLand, Donkey, Camel, MetalDetector, Excavator}
    event BuyLandEvent(address caller, string user, AssetType itemType, uint256 landId, uint256 callValue, uint256 itemCount, bool status, string description);
    event BuyOtherAssetEvent(address caller, string user, AssetType itemType, uint256 callValue, uint256 itemCount, bool status, string description);

    constructor() public {
        owner = msg.sender;
    }
    /**
     * @notice Fallback function.
     */
    function () external payable {
    }
    /**
     * @notice Self Destructive function.
     */
    function kill() external {
        require(msg.sender == owner,"Only contract owner has access to this api.");
        selfdestruct(owner);
    }
   
    /**
     * @notice function to check contract owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }
    /**
     */
    function verifyDirectorAddress(address dirAddress) external view returns (bool) {
        // require(dirAddress != address(0),"Address should not be 0 Address");
        return dirAddress == directorAddress;
    }
    /**
    */
    // function checkDirectorAddress() external view returns(address,address) {
    //     return (directorAddress, owner);
    // }
    /**
    * @notice Set Director Address
    *
     */
     function setDirectorAddresss (address dirAddress) external {
        require(msg.sender == owner,"Only contract owner has access to this api.");
        require(dirAddress != address(0),"Address should not be 0 Address");
        directorAddress = dirAddress;
     }
     
    /**
     * @notice Function to transfer ownership.
     */
    function transferOwnership(address newOwner) external {
        require(newOwner != address(0),"New Owner should not be 0 Address");
        require(msg.sender == owner,"Caller must be owner of this contract");
        owner = newOwner;
    }
    /**
     * @notice Function to set Land price in SUN.
     */
    function setLandPrice(uint256 price) external {
        require(msg.sender == owner,"Only contract owner has access to this api.");
        landPrice = price;
    }
    /**
     * @notice Function to set Donkey price in SUN.
     */
    function setDonkeyPrice(uint256 price) external {
        require(msg.sender == owner,"Only contract owner has access to this api.");
        donkeyPrice = price;
    }
    /**
     * @notice Function to set Camel price in SUN.
     */
    function setCamelPrice(uint256 price) external {
        require(msg.sender == owner,"Only contract owner has access to this api.");
        camelPrice = price;
    }
    /**
     * @notice Function to set Metal Detector price in SUN.
     */
    function setMDPrice(uint256 price) external {
        require(msg.sender == owner,"Only contract owner has access to this api.");
        metalDetector = price;
    }
    /**
     * @notice Function to set Excavator price in SUN.
     */
    function setExcavatorPrice(uint256 price) external  {
        require(msg.sender == owner,"Only contract owner has access to this api.");
        excavator = price;
    }
    /**
     * @notice Function to get price list of all digital assets.
     */
    function getPriceList() external view returns(string,uint256[]) {
        uint256[] memory priceList = new uint256[](5);
        priceList[0] = donkeyPrice;
        priceList[1] = camelPrice;
        priceList[2] = landPrice;
        priceList[3] = metalDetector;
        priceList[4] = excavator;
        return("Donkey,Camel,Land,Metal Detector,Excavator",priceList);
    }

    /**
     * @notice Function to rest lands array.
     */
    function resetLands() external {
        require(msg.sender == owner,"Only contract owner has access to this api.");
        delete lands;
    }
    /**
     * @notice Function return total lands has been bought.
     */
    function totalLands() external view returns(uint256 tLands) {
        tLands = lands.length;
    }
    /**
     * @notice Function to check land attributes.
     */
    function getLand(uint256 landId)external view returns(uint256 lid,uint256 lPrice,address lOwner, bool lIsPurchasable){
        uint256 landIdx = lidToLandsIdx[landId];
        Land memory land = lands[landIdx];
        require(landId == land.lid, "This land does not exist");
        lid = land.lid;
        lPrice = land.price;
        lOwner = land.owner;
        lIsPurchasable = land.isPurchasable;
    }
    /**
     * @notice Function to set land on resale and set cutom price.
     */
    function setLandResalePrice(uint256 landId,uint256 lPrice) external returns(bool status){
        require(lidToOwner[landId] != address(0), "You can't put this land on re-sale");
        require(msg.sender == lidToOwner[landId],"Caller should be owner this land");
        uint256 landIdx = lidToLandsIdx[landId];
        Land storage land = lands[landIdx];
        land.price = lPrice;
        land.isPurchasable = true;
        status = true;
        return status;
    }


     /**
     * @notice Function to remove land  from resale.
     */
    function removeFromResale(uint256 landId, address ownerAddress) external returns(bool status){
        require(lidToOwner[landId] != address(0), "You can't remove this land from re-sale");
        require(ownerAddress == lidToOwner[landId],"Caller should be owner this land");
        uint256 landIdx = lidToLandsIdx[landId];
        Land storage land = lands[landIdx];
        land.isPurchasable = false;
        status = true;
        return status;
    }



    /**
     * @notice Function to buy a land.
     */
    function buyLand(uint256 landId,string userName) external payable {
        require(msg.value == landPrice,"TRX value should be equal to Land price.");
        require(lidToLandsIdx[landId] == 0, "This land is already bought");
        require(directorAddress != address(0), "Director address should be valid");
        directorAddress.transfer(msg.value);
        Land memory land = Land({
            lid : landId,
            price : landPrice,
            owner : msg.sender,
            isPurchasable: false
        });
        uint256 landIdx = lands.push(land) - 1;
        lidToLandsIdx[landId] = landIdx;
        lidToOwner[landId] = msg.sender;
        emit BuyLandEvent(msg.sender, userName, AssetType.FreshLand,landId, msg.value, 1, true, "Land bought succesfully");
    }
    /**
     * @notice Function to buy resale land.
     */
    function buyResaleLand(uint256 landId, string userName) external payable {
        uint256 landIdx = lidToLandsIdx[landId];
        Land storage land = lands[landIdx];
        require(land.price == msg.value, "TRX value should be equal to Land price.");
        require(land.owner != address(0), "Land owner must be a valid Tron address");
        require(msg.sender != address(0), "Sender should be valid tron address");
        require(land.isPurchasable == true, "Land should be available for purchase");
        land.owner.transfer(msg.value);
        land.owner = msg.sender;
        land.isPurchasable = false;
        lidToOwner[landId] = msg.sender;
        emit BuyLandEvent(msg.sender, userName, AssetType.PreOwnedLand,landId, msg.value, 1, true, "Pre-owned land bought succesfully");
    }
    /**
     * @notice Function to buy Donkey.
     */
    function buyDonkey(string userName) external payable {
        require(msg.value == donkeyPrice,"TRX value should be equal to Donkey price.");
        require(directorAddress != address(0),"Address should not be 0 Address");
        directorAddress.transfer(msg.value);
        emit BuyOtherAssetEvent(msg.sender, userName, AssetType.Donkey, msg.value, 1, true, "Donkey purchase succesfull");
    }
    /**
     * @notice Function to buy Camel.
     */
    function buyCamel(string userName) external payable {
        require(msg.value == camelPrice,"TRX value should be equal to Camel price.");
        require(directorAddress != address(0),"Address should not be 0 Address");
        directorAddress.transfer(msg.value);
        emit BuyOtherAssetEvent(msg.sender, userName, AssetType.Camel, msg.value, 1, true, "Camel purchase succesfull");
    }
    /**
     * @notice Function to buy MetalDetector.
     */
    function buyMetalDetector(uint256 quantity, string userName) external payable returns(bool) {
        require(quantity >= 1,"Quantity must be at least 1");
        require(msg.value == (metalDetector * quantity),"TRX value should be equal to Metal Detector price.");
        require(directorAddress != address(0),"Address should not be 0 Address");
        directorAddress.transfer(msg.value);
        emit BuyOtherAssetEvent(msg.sender, userName, AssetType.MetalDetector, msg.value, quantity, true, "Metal Detector purchase succesfull");
        return true;
    }
    /**
     * @notice Function to buy Excavator.
     */
    function buyExcavator(uint256 quantity, string userName)  external payable returns(bool) {
        require(quantity >= 1,"Quantity must be at least 1");
        require(msg.value == (excavator * quantity),"TRX value should be equal to Excavator price.");
        require(directorAddress != address(0),"Address should not be 0 Address");
        directorAddress.transfer(msg.value);
        emit BuyOtherAssetEvent(msg.sender, userName, AssetType.Excavator, msg.value, quantity, true, "Excavator purchase succesfull");
        return true;
    }
}