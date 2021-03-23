pragma solidity 0.5.10;

import './LibInteger.sol';
import './LibBlob.sol';
import './InterfaceProduce.sol';
import './BlobDefinition.sol';
import './BlobFormation.sol';
import './BlobStorage.sol';

/**
 * @title BlobManager 
 * @dev Manage the core functionalities of blobs
 */
contract BlobManager
{
    using LibInteger for uint;

    BlobDefinition private _definition;
    BlobFormation private _formation;
    BlobStorage private _storage;
    InterfaceProduce private _producer;

    event Log(address indexed account, uint indexed blob, string action, uint data1, uint data2);

    /**
     * @dev The admin of the contract
     */
    address payable private _admin;

    /**
     * @dev The address of the definition token contract
     */
    address private _definition_contract;
    
    /**
     * @dev The address of the formation token contract
     */
    address private _formation_contract;

    /**
     * @dev The address of the blob storage contract
     */
    address private _storage_contract;

    /**
     * @dev The address of the blob producer contract
     */
    address private _producer_contract;

    /**
     * Number of tokens per minting segment
     */
    uint private constant _tokens_per_segment = 2048;

    /**
     * Starting price of minting
     */
    uint private constant _minting_starting_price = 10**17;

    /**
     * Minting price increment per segment
     */
    uint private constant _minting_price_increment = 10**17;

    /**
     * Formation grant multiplier when minting
     */
    uint private constant _minting_grant_multiplier = 10**18;

    /**
     * The formation tokens charged for merging, splitting and renaming
     */
    uint private constant _transformation_token_fee = 10**18;

    /**
     * The minimum transformation fee charged if payed by native currency
     */
    uint private constant _transformation_native_fee_min = 40 * 10**15;

    /**
     * The transformation fee increment per segment
     */
    uint private constant _transformation_native_fee_increment = 10**15;

    /**
     * The transformation fee increment gap
     */
    uint private constant _transformation_native_fee_gap = 2500 * 10**18;

    /**
     * The original minter selling fee percentage
     */
    uint private constant _minter_selling_fee_percentage = 2;

    /**
     * @dev Initialise the contract
     */
    constructor() public
    {
        //The contract creator becomes the admin
        _admin = msg.sender;
    }

    /**
     * @dev Allow access only for the admin of contract
     */
    modifier onlyAdmin()
    {
        require(msg.sender == _admin);
        _;
    }

    /**
     * @dev Withdraw from the balance of this contract
     * @param amount The amount to be withdrawn, if zero is provided the whole balance will be withdrawn
     */
    function clean(uint amount) public onlyAdmin
    {
        if (amount == 0){
            _admin.transfer(address(this).balance);
        } else {
            _admin.transfer(amount);
        }
    }

    /**
     * @dev Withdraw formation tokens of this contract
     * @param amount The amount to be withdrawn, if zero is provided the whole formation token balance will be withdrawn
     */
    function empty(uint amount) public onlyAdmin
    {
        if (amount == 0){
            _formation.transfer(_admin, _formation.balanceOf(address(this)));
        } else {
            _formation.transfer(_admin, amount);
        }
    }

    /**
     * @dev Update definition contract reference
     * @param account The address of contract
     */
    function setDefinition(address account) public onlyAdmin
    {
        _definition_contract = account;
        _definition = BlobDefinition(account);
    }

    /**
     * @dev Update formation contract reference
     * @param account The address of contract
     */
    function setFormation(address account) public onlyAdmin
    {
        _formation_contract = account;
        _formation = BlobFormation(account);
    }

    /**
     * @dev Update storage contract reference
     * @param account The address of contract
     */
    function setStorage(address account) public onlyAdmin
    {
        _storage_contract = account;
        _storage = BlobStorage(account);
    }

    /**
     * @dev Update producer contract reference
     * @param account The address of contract
     */
    function setProducer(address account) public onlyAdmin
    {
        _producer_contract = account;
        _producer = InterfaceProduce(account);
    }

    /**
     * @dev Mint new blobs
     */
    function mint() public payable
    {        
        //Must pay for minting
        require(msg.value > 0);

        //Get currently minted tokens
        uint minted = _definition.totalSupply();

        //Must pay the price
        require(_calcSegmentPrice(minted) == msg.value);

        //Grant formation tokens
        _formation.transfer(msg.sender, _calcSegmentGrant(minted));

        //Mint the token
        uint id = _definition.mint(msg.sender);

        //Save metadata
        _storage.incrementMetadata(id, _producer.init(id));

        //Save original minter
        _storage.setMinter(id, msg.sender);

        //Transfer fee
        _admin.transfer(msg.value.mul(90).div(100));

        //Emit events
        emit Log(msg.sender, id, "mint", msg.value, 0);
    }

    /**
     * @dev Merge two blobs
     * @param father The father blob id
     * @param mother The mother blob id
     */
    function merge(uint father, uint mother, uint[] memory params) public payable
    {
        //The parents must be owned by the sender
        require(msg.sender == _definition.ownerOf(father));
        require(msg.sender == _definition.ownerOf(mother));

        //The parents must not be the same
        require(father != mother);

        //Blobs must not be currently listed
        require(_storage.getListing(father) == 0);
        require(_storage.getListing(mother) == 0);

        //Parameters should be valid
        require(params.length == 6);
        for (uint i = 0; i < 6; i++) {
            require(params[i] == father || params[i] == mother);
        }

        //Read metadata of parents
        LibBlob.Metadata memory father_metadata = LibBlob.uintToMetadata(_storage.getLatestMetadata(father));
        LibBlob.Metadata memory mother_metadata = LibBlob.uintToMetadata(_storage.getLatestMetadata(mother));

        //Both father and mother should be in same level
        require(father_metadata.level == mother_metadata.level);

        //Cannot merge further after reaching level six
        require(father_metadata.level < 6 && mother_metadata.level < 6);

        //Setup partners
        father_metadata.partner = mother;
        mother_metadata.partner = father;

        //Merging increases the level of blob
        father_metadata.level = father_metadata.level.add(1);
        mother_metadata.level = mother_metadata.level.add(1);

        //Setting up father parameters
        father_metadata.param1 = (params[0] == father) ? father_metadata.param1 : mother_metadata.param1;
        father_metadata.param2 = (params[1] == father) ? father_metadata.param2 : mother_metadata.param2;
        father_metadata.param3 = (params[2] == father) ? father_metadata.param3 : mother_metadata.param3;
        father_metadata.param4 = (params[3] == father) ? father_metadata.param4 : mother_metadata.param4;
        father_metadata.param5 = (params[4] == father) ? father_metadata.param5 : mother_metadata.param5;
        father_metadata.param6 = (params[5] == father) ? father_metadata.param6 : mother_metadata.param6;

        //Setting up mother parameters
        mother_metadata.param1 = (params[0] == father) ? father_metadata.param1 : mother_metadata.param1;
        mother_metadata.param2 = (params[1] == father) ? father_metadata.param2 : mother_metadata.param2;
        mother_metadata.param3 = (params[2] == father) ? father_metadata.param3 : mother_metadata.param3;
        mother_metadata.param4 = (params[3] == father) ? father_metadata.param4 : mother_metadata.param4;
        mother_metadata.param5 = (params[4] == father) ? father_metadata.param5 : mother_metadata.param5;
        mother_metadata.param6 = (params[5] == father) ? father_metadata.param6 : mother_metadata.param6;

        //Charge for the action
        if (msg.value > 0) {
            require(msg.value == _calcTransformationNativeFee());
        } else {
            _formation.burn(msg.sender, _transformation_token_fee);
        }

        //Update metadata
        _storage.incrementMetadata(father, LibBlob.metadataToUint(father_metadata));
        _storage.incrementMetadata(mother, LibBlob.metadataToUint(mother_metadata));

        //Only father survives after merging
        _definition.disable(msg.sender, mother);
    
        //Emit events
        emit Log(msg.sender, father, "merge", msg.value, mother);
    }

    /**
     * @dev Split a blob back to its parents
     * @param id The id of blob
     */
    function split(uint id) public payable
    {
        //Blob must be owned by the sender
        require(msg.sender == _definition.ownerOf(id));

        //Blob must not be currently listed
        require(_storage.getListing(id) == 0);

        //Read metadata
        LibBlob.Metadata memory metadata = LibBlob.uintToMetadata(_storage.getLatestMetadata(id));

        //Cannot split further after reaching level one
        require(metadata.level > 1);

        //Charge for the action
        if (msg.value > 0) {
            require(msg.value == _calcTransformationNativeFee());
        } else {
            _formation.burn(msg.sender, _transformation_token_fee);
        }

        //Summon the partner
        _definition.enable(msg.sender, metadata.partner);

        //Restore metadata
        _storage.decrementMetadata(id);
        _storage.decrementMetadata(metadata.partner);
            
        //Emit events
        emit Log(msg.sender, id, "split", msg.value, metadata.partner);
    }

    /**
     * @dev Rename a blob
     * @param id The id of blob
     * @param chars The name to be set
     */
    function rename(uint id, uint[] memory chars) public payable
    {
        //Characters should be valid
        require(chars.length == 8);
        for (uint i = 0; i < 8; i++) {
            require(chars[i] >= 0 && chars[i] <= 62);
        }

        //Building name
        LibBlob.Name memory name_params;
        name_params.char1 = chars[0];
        name_params.char2 = chars[1];
        name_params.char3 = chars[2];
        name_params.char4 = chars[3];
        name_params.char5 = chars[4];
        name_params.char6 = chars[5];
        name_params.char7 = chars[6];
        name_params.char8 = chars[7];
        uint name = LibBlob.nameToUint(name_params);

        //Get current name
        uint current = _storage.getName(id);

        //The new name must be different from current name
        require(name != current);

        //The new name must be unique
        require(!_storage.isReserved(name));

        //The token must be owned by the sender
        require(msg.sender == _definition.ownerOf(id));

        //Blob must not be currently listed
        require(_storage.getListing(id) == 0);

        //Charge for the action
        if (msg.value > 0) {
            require(msg.value == _calcTransformationNativeFee());
        } else {
            _formation.burn(msg.sender, _transformation_token_fee);
        }
        
        //Release the previously reserved name
        if (current > 0) {
            _storage.setReservation(current, false);
        }

        //Set new name
        _storage.setReservation(name, true);
        _storage.setName(id, name);

        //Emit events
        emit Log(msg.sender, id, "rename", msg.value, name);
    }

    /**
     * @dev List blob for selling
     * @param id The id of blob
     * @param price The selling price
     */
    function list(uint id, uint price) public
    {
        //The price needs to be set
        require(price > 0);

        //Blob must be owned by the sender
        require(msg.sender == _definition.ownerOf(id));

        //Set selling price
        _storage.setListing(id, price); 

        //Emit events
        emit Log(msg.sender, id, "list", price, 0);
    }

    /**
     * @dev Withdraw blob from selling
     * @param id The id of blob
     */
    function withdraw(uint id) public
    {
        //Blob must be owned by the sender
        require(msg.sender == _definition.ownerOf(id));

        //Blob must be currently listed
        require(_storage.getListing(id) > 0);

        //Reset selling price
        _storage.setListing(id, 0); 

        //Emit events
        emit Log(msg.sender, id, "withdraw", 0, 0);           
    }

    /**
     * @dev Buy a listed blob
     * @param id The id of blob
     */
    function buy(uint id) public payable
    {
        uint price = _storage.getListing(id);
        uint minter_share = price.mul(_minter_selling_fee_percentage).div(100);
        uint seller_share = price.sub(minter_share);
        address payable seller = address(uint160(_definition.ownerOf(id)));

        //Blob must not be owned by the sender
        require(msg.sender != seller);

        //Blob must be currently listed
        require(price > 0);

        //Must send the buying amount
        require(msg.value == price);

        //Settle payments
        seller.transfer(seller_share);
        _storage.getMinter(id).transfer(minter_share);

        //Reset selling price
        _storage.setListing(id, 0); 

        //Transfer ownership
        _definition.move(seller, msg.sender, id);

        //Emit events
        emit Log(msg.sender, id, "buy", price, 0);           
    }

    /**
     * @dev Get common details of the system
     * @return The details
     */
    function getSystemDetails() public view returns (uint[8] memory)
    {
        uint minted = _definition.totalSupply();

        return [
            _calcSegmentId(minted),
            _calcSegmentPrice(minted),
            _calcSegmentGrant(minted),
            _calcTransformationNativeFee(),
            _formation.maxSupply(),
            _formation.totalSupply(),
            _definition.maxSupply(),
            _definition.totalSupply()
        ];
    }

    /**
     * @dev Get account related details of the system
     * @param account The account to get details about
     * @return The details
     */
    function getAccountDetails(address account) public view returns (uint[2] memory)
    {
        return [
            _definition.balanceOf(account),
            _formation.balanceOf(account)
        ];
    }

    /**
     * @dev Get blob details
     * @return The details
     */
    function getBlobDetails(uint id) public view returns (uint[] memory, uint[] memory, uint[] memory, uint, address, address)
    {
        return (
            getBlobLatestMetadataDetails(id),
            getBlobPreviousMetadataDetails(id),
            getBlobNameDetails(id),
            _storage.getListing(id),
            _storage.getMinter(id),
            _definition.ownerOf(id)
        );
    }

    /**
     * @dev Get blob latest metadata details
     * @return The details
     */
    function getBlobLatestMetadataDetails(uint id) public view returns (uint[] memory)
    {
        LibBlob.Metadata memory latest_metadata = LibBlob.uintToMetadata(_storage.getLatestMetadata(id));
        uint[] memory latest_metadata_params = new uint[](8);
        latest_metadata_params[0] = latest_metadata.partner;
        latest_metadata_params[1] = latest_metadata.level;
        latest_metadata_params[2] = latest_metadata.param1;
        latest_metadata_params[3] = latest_metadata.param2;
        latest_metadata_params[4] = latest_metadata.param3;
        latest_metadata_params[5] = latest_metadata.param4;
        latest_metadata_params[6] = latest_metadata.param5;
        latest_metadata_params[7] = latest_metadata.param6;

        return latest_metadata_params;
    }

    /**
     * @dev Get blob previous metadata details
     * @return The details
     */
    function getBlobPreviousMetadataDetails(uint id) public view returns (uint[] memory)
    {
        LibBlob.Metadata memory previous_metadata = LibBlob.uintToMetadata(_storage.getPreviousMetadata(id));
        uint[] memory previous_metadata_params = new uint[](8);
        previous_metadata_params[0] = previous_metadata.partner;
        previous_metadata_params[1] = previous_metadata.level;
        previous_metadata_params[2] = previous_metadata.param1;
        previous_metadata_params[3] = previous_metadata.param2;
        previous_metadata_params[4] = previous_metadata.param3;
        previous_metadata_params[5] = previous_metadata.param4;
        previous_metadata_params[6] = previous_metadata.param5;
        previous_metadata_params[7] = previous_metadata.param6;

        return previous_metadata_params;
    }

    /**
     * @dev Get blob name details
     * @return The details
     */
    function getBlobNameDetails(uint id) public view returns (uint[] memory)
    {
        LibBlob.Name memory name = LibBlob.uintToName(_storage.getName(id));
        uint[] memory name_params = new uint[](8);
        name_params[0] = name.char1;
        name_params[1] = name.char2;
        name_params[2] = name.char3;
        name_params[3] = name.char4;
        name_params[4] = name.char5;
        name_params[5] = name.char6;
        name_params[6] = name.char7;
        name_params[7] = name.char8;

        return name_params;
    }

    /**
     * @dev Calculates the current mining segment id
     * @param minted The number of tokens minted so far
     * @return uint The current mining segment id
     */
    function _calcSegmentId(uint minted) private pure returns (uint)
    {
        return minted.div(_tokens_per_segment);
    }

    /**
     * @dev Calculates the current mining segment price
     * @param minted The number of tokens minted so far
     * @return uint The current mining segment price
     */
    function _calcSegmentPrice(uint minted) private pure returns (uint)
    {
        return _minting_starting_price.add(_calcSegmentId(minted).mul(_minting_price_increment));
    }

    /**
     * @dev Calculates the current mining segment formation tokens grant
     * @param minted The number of tokens minted so far
     * @return uint The current mining segment formation tokens grant
     */
    function _calcSegmentGrant(uint minted) private pure returns (uint)
    {
        uint multiplier = _calcSegmentId(minted).add(2);
        return _minting_grant_multiplier.mul(multiplier.mul(multiplier.add(1))).div(2);
    }

    /**
     * @dev Calculates the native fee that should be payed for transformation
     * @return uint The current transformation native fee
     */
    function _calcTransformationNativeFee() private view returns (uint)
    {
        uint burnt_supply = _formation.maxSupply().sub(_formation.totalSupply());
        uint transformation_segment = burnt_supply.div(_transformation_native_fee_gap);

        return _transformation_native_fee_min.add(transformation_segment.mul(_transformation_native_fee_increment));
    }
}