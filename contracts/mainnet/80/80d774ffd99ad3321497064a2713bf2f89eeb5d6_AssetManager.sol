pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}






contract UserManager {

    struct User {
        string username;
        bytes32 hashToProfilePicture;
        bool exists;
    }

    uint public numberOfUsers;

    mapping(string => bool) internal usernameExists;
    mapping(address => User) public addressToUser;

    mapping(bytes32 => bool) public profilePictureExists;
    mapping(string => address) internal usernameToAddress;

    event NewUser(address indexed user, string username, bytes32 profilePicture);

    function register(string _username, bytes32 _hashToProfilePicture) public {
        require(usernameExists[_username] == false || 
                keccak256(abi.encodePacked(getUsername(msg.sender))) == keccak256(abi.encodePacked(_username))
        );

        if (usernameExists[getUsername(msg.sender)]) {
            // if he already had username, that username is free now
            usernameExists[getUsername(msg.sender)] = false;
        } else {
            numberOfUsers++;
            emit NewUser(msg.sender, _username, _hashToProfilePicture);
        }

        addressToUser[msg.sender] = User({
            username: _username,
            hashToProfilePicture: _hashToProfilePicture,
            exists: true
        });

        usernameExists[_username] = true;
        profilePictureExists[_hashToProfilePicture] = true;
        usernameToAddress[_username] = msg.sender;
    }

    function changeProfilePicture(bytes32 _hashToProfilePicture) public {
        require(addressToUser[msg.sender].exists, "User doesn&#39;t exists");

        addressToUser[msg.sender].hashToProfilePicture = _hashToProfilePicture;
    }

    function getUserInfo(address _address) public view returns(string, bytes32) {
        User memory user = addressToUser[_address];
        return (user.username, user.hashToProfilePicture);
    }

    function getUsername(address _address) public view returns(string) {
        return addressToUser[_address].username;
    } 

    function getProfilePicture(address _address) public view returns(bytes32) {
        return addressToUser[_address].hashToProfilePicture;
    }

    function isUsernameExists(string _username) public view returns(bool) {
        return usernameExists[_username];
    }

}



contract AssetManager is Ownable {

    struct Asset {
        uint id;
        uint packId;
        /// atributes field is going to be 3 digit uint where every digit can be "1" or "2"
        /// 1st digit will tell us if asset is background 1 - true / 2 - false
        /// 2nd digit will tell us if rotation is enabled 1 - true / 2 - false
        /// 3rd digit will tell us if scaling  is enabled 1 - true / 2 - false
        uint attributes;
        bytes32 ipfsHash; // image
    }

    struct AssetPack {
        bytes32 packCover;
        uint[] assetIds;
        address creator;
        uint price;
        string ipfsHash; // containing title and description
    }

    uint public numberOfAssets;
    uint public numberOfAssetPacks;

    Asset[] public assets;
    AssetPack[] public assetPacks;

    UserManager public userManager;

    mapping(address => uint) public artistBalance;
    mapping(bytes32 => bool) public hashExists;

    mapping(address => uint[]) public createdAssetPacks;
    mapping(address => uint[]) public boughtAssetPacks;
    mapping(address => mapping(uint => bool)) public hasPermission;
    mapping(uint => address) public approvedTakeover;

    event AssetPackCreated(uint indexed id, address indexed owner);
    event AssetPackBought(uint indexed id, address indexed buyer);

    function addUserManager(address _userManager) public onlyOwner {
        require(userManager == address(0));

        userManager = UserManager(_userManager);
    }

    /// @notice Function to create assetpack
    /// @param _packCover is cover image for asset pack
    /// @param _attributes is array of attributes
    /// @param _ipfsHashes is array containing all ipfsHashes for assets we&#39;d like to put in pack
    /// @param _packPrice is price for total assetPack (every asset will have average price)
    /// @param _ipfsHash ipfs hash containing title and description in json format
    function createAssetPack(
        bytes32 _packCover, 
        uint[] _attributes, 
        bytes32[] _ipfsHashes, 
        uint _packPrice,
        string _ipfsHash) public {
        
        require(_ipfsHashes.length > 0);
        require(_ipfsHashes.length < 50);
        require(_attributes.length == _ipfsHashes.length);

        uint[] memory ids = new uint[](_ipfsHashes.length);

        for (uint i = 0; i < _ipfsHashes.length; i++) {
            ids[i] = createAsset(_attributes[i], _ipfsHashes[i], numberOfAssetPacks);
        }

        assetPacks.push(AssetPack({
            packCover: _packCover,
            assetIds: ids,
            creator: msg.sender,
            price: _packPrice,
            ipfsHash: _ipfsHash
        }));

        createdAssetPacks[msg.sender].push(numberOfAssetPacks);
        numberOfAssetPacks++;

        emit AssetPackCreated(numberOfAssetPacks-1, msg.sender);
    }

    /// @notice Function which creates an asset
    /// @param _attributes is meta info for asset
    /// @param _ipfsHash is ipfsHash to image of asset
    function createAsset(uint _attributes, bytes32 _ipfsHash, uint _packId) internal returns(uint) {
        uint id = numberOfAssets;

        require(isAttributesValid(_attributes), "Attributes are not valid.");

        assets.push(Asset({
            id : id,
            packId: _packId,
            attributes: _attributes,
            ipfsHash : _ipfsHash
        }));

        numberOfAssets++;

        return id;
    }

    /// @notice Method to buy right to use specific asset pack
    /// @param _to is address of user who will get right on that asset pack
    /// @param _assetPackId is id of asset pack user is buying
    function buyAssetPack(address _to, uint _assetPackId) public payable {
        require(!checkHasPermissionForPack(_to, _assetPackId));

        AssetPack memory assetPack = assetPacks[_assetPackId];
        require(msg.value >= assetPack.price);
        // if someone wants to pay more money for asset pack, we will give all of it to creator
        artistBalance[assetPack.creator] += msg.value * 95 / 100;
        artistBalance[owner] += msg.value * 5 / 100;
        boughtAssetPacks[_to].push(_assetPackId);
        hasPermission[_to][_assetPackId] = true;

        emit AssetPackBought(_assetPackId, _to);
    }

    /// @notice Change price of asset pack
    /// @param _assetPackId is id of asset pack for changing price
    /// @param _newPrice is new price for that asset pack
    function changeAssetPackPrice(uint _assetPackId, uint _newPrice) public {
        require(assetPacks[_assetPackId].creator == msg.sender);

        assetPacks[_assetPackId].price = _newPrice;
    }

    /// @notice Approve address to become creator of that pack
    /// @param _assetPackId id of asset pack for other address to claim
    /// @param _newCreator address that will be able to claim that asset pack
    function approveTakeover(uint _assetPackId, address _newCreator) public {
        require(assetPacks[_assetPackId].creator == msg.sender);

        approvedTakeover[_assetPackId] = _newCreator;
    }

    /// @notice claim asset pack that is previously approved by creator
    /// @param _assetPackId id of asset pack that is changing creator
    function claimAssetPack(uint _assetPackId) public {
        require(approvedTakeover[_assetPackId] == msg.sender);
        
        approvedTakeover[_assetPackId] = address(0);
        assetPacks[_assetPackId].creator = msg.sender;
    }

    ///@notice Function where all artists can withdraw their funds
    function withdraw() public {
        uint amount = artistBalance[msg.sender];
        artistBalance[msg.sender] = 0;

        msg.sender.transfer(amount);
    }

    /// @notice Function to fetch total number of assets
    /// @return numberOfAssets
    function getNumberOfAssets() public view returns (uint) {
        return numberOfAssets;
    }

    /// @notice Function to fetch total number of assetpacks
    /// @return uint numberOfAssetPacks
    function getNumberOfAssetPacks() public view returns(uint) {
        return numberOfAssetPacks;
    }

    /// @notice Function to check if user have permission (owner / bought) for pack
    /// @param _address is address of user
    /// @param _packId is id of pack
    function checkHasPermissionForPack(address _address, uint _packId) public view returns (bool) {

        return (assetPacks[_packId].creator == _address) || hasPermission[_address][_packId];
    }

    /// @notice Function to check does hash exist in mapping
    /// @param _ipfsHash is bytes32 representation of hash
    function checkHashExists(bytes32 _ipfsHash) public view returns (bool) {
        return hashExists[_ipfsHash];
    }

    /// @notice method that gets all unique packs from array of assets
    function pickUniquePacks(uint[] assetIds) public view returns (uint[]) {
        require(assetIds.length > 0);

        uint[] memory packs = new uint[](assetIds.length);
        uint packsCount = 0;
        
        for (uint i = 0; i < assetIds.length; i++) {
            Asset memory asset = assets[assetIds[i]];
            bool exists = false;

            for (uint j = 0; j < packsCount; j++) {
                if (asset.packId == packs[j]) {
                    exists = true;
                }
            }

            if (!exists) {
                packs[packsCount] = asset.packId;
                packsCount++;
            }
        }

        uint[] memory finalPacks = new uint[](packsCount);
        for (i = 0; i < packsCount; i++) {
            finalPacks[i] = packs[i];
        }

        return finalPacks;
    }

    /// @notice Method to get all info for an asset
    /// @param id is id of asset
    /// @return All data for an asset
    function getAssetInfo(uint id) public view returns (uint, uint, uint, bytes32) {
        require(id >= 0);
        require(id < numberOfAssets);
        Asset memory asset = assets[id];

        return (asset.id, asset.packId, asset.attributes, asset.ipfsHash);
    }

    /// @notice method returns all asset packs created by _address
    /// @param _address is creator address
    function getAssetPacksUserCreated(address _address) public view returns(uint[]) {
        return createdAssetPacks[_address];
    }

    /// @notice Function to get ipfsHash for selected asset
    /// @param _id is id of asset we&#39;d like to get ipfs hash
    /// @return string representation of ipfs hash of that asset
    function getAssetIpfs(uint _id) public view returns (bytes32) {
        require(_id < numberOfAssets);
        
        return assets[_id].ipfsHash;
    }

    /// @notice Function to get attributes for selected asset
    /// @param _id is id of asset we&#39;d like to get ipfs hash
    /// @return uint representation of attributes of that asset
    function getAssetAttributes(uint _id) public view returns (uint) {
        require(_id < numberOfAssets);
        
        return assets[_id].attributes;
    }

    /// @notice Function to get array of ipfsHashes for specific assets
    /// @dev need for data parsing on frontend efficiently
    /// @param _ids is array of ids
    /// @return bytes32 array of hashes
    function getIpfsForAssets(uint[] _ids) public view returns (bytes32[]) {
        bytes32[] memory hashes = new bytes32[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            Asset memory asset = assets[_ids[i]];
            hashes[i] = asset.ipfsHash;
        }

        return hashes;
    }

    /// @notice method that returns attributes for many assets
    function getAttributesForAssets(uint[] _ids) public view returns(uint[]) {
        uint[] memory attributes = new uint[](_ids.length);
        
        for (uint i = 0; i < _ids.length; i++) {
            Asset memory asset = assets[_ids[i]];
            attributes[i] = asset.attributes;
        }
        return attributes;
    }

    /// @notice Function to get ipfs hash and id for all assets in one asset pack
    /// @param _assetPackId is id of asset pack
    /// @return two arrays with data
    function getAssetPackData(uint _assetPackId) public view 
    returns(bytes32, address, uint, uint[], uint[], bytes32[], string, string, bytes32) {
        require(_assetPackId < numberOfAssetPacks);

        AssetPack memory assetPack = assetPacks[_assetPackId];
        bytes32[] memory hashes = new bytes32[](assetPack.assetIds.length);

        for (uint i = 0; i < assetPack.assetIds.length; i++) {
            hashes[i] = getAssetIpfs(assetPack.assetIds[i]);
        }

        uint[] memory attributes = getAttributesForAssets(assetPack.assetIds);

        return(
            assetPack.packCover, 
            assetPack.creator, 
            assetPack.price, 
            assetPack.assetIds, 
            attributes, 
            hashes,
            assetPack.ipfsHash,
            userManager.getUsername(assetPack.creator),
            userManager.getProfilePicture(assetPack.creator)
        );
    }

    function getAssetPackPrice(uint _assetPackId) public view returns (uint) {
        require(_assetPackId < numberOfAssetPacks);

        return assetPacks[_assetPackId].price;
    }

    function getBoughtAssetPacks(address _address) public view returns (uint[]) {
        return boughtAssetPacks[_address];
    }

    /// @notice Function to get cover image for every assetpack
    /// @param _packIds is array of asset pack ids
    /// @return bytes32[] array of hashes
    function getCoversForPacks(uint[] _packIds) public view returns (bytes32[]) {
        require(_packIds.length > 0);
        bytes32[] memory covers = new bytes32[](_packIds.length);
        for (uint i = 0; i < _packIds.length; i++) {
            AssetPack memory assetPack = assetPacks[_packIds[i]];
            covers[i] = assetPack.packCover;
        }
        return covers;
    }

    function isAttributesValid(uint attributes) private pure returns(bool) {
        if (attributes < 100 || attributes > 999) {
            return false;
        }

        uint num = attributes;

        while (num > 0) {
            if (num % 10 != 1 && num % 10 != 2) {
                return false;
            } 
            num = num / 10;
        }

        return true;
    }
}