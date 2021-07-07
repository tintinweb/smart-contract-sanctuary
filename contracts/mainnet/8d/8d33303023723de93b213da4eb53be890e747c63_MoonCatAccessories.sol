/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.1;

interface IMoonCatAcclimator {
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IMoonCatRescue {
    function rescueOrder(uint256 tokenId) external view returns (bytes5);
    function catOwners(bytes5 catId) external view returns (address);
}

interface IReverseResolver {
    function claim(address owner) external returns (bytes32);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

/**
 * @dev Derived from OpenZeppelin standard template
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol
 * b0cf6fbb7a70f31527f36579ad644e1cf12fdf4e
 */
library EnumerableSet {
    struct Set {
        uint256[] _values;
        mapping (uint256 => uint256) _indexes;
    }

    function at(Set storage set, uint256 index) internal view returns (uint256) {
        return set._values[index];
    }

    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function add(Set storage set, uint256 value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function remove(Set storage set, uint256 value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            if (lastIndex != toDeleteIndex) {
                uint256 lastvalue = set._values[lastIndex];
                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();
            // Delete the index for the deleted slot
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
}

library MoonCatBitSet {

    bytes32 constant Mask =  0x0000000000000000000000000000000000000000000000000000000000000001;

    function activate(bytes32[100] storage set)
        internal
    {
        set[99] |= Mask;
    }

    function deactivate(bytes32[100] storage set)
        internal
    {
        set[99] &= ~Mask;
    }

    function setBit(bytes32[100] storage set, uint16 index)
        internal
    {
        uint16 wordIndex = index / 256;
        uint16 bitIndex = index % 256;
        bytes32 mask = Mask << (255 - bitIndex);
        set[wordIndex] |= mask;
    }

    function clearBit(bytes32[100] storage set, uint16 index)
        internal
    {
        uint16 wordIndex = index / 256;
        uint16 bitIndex = index % 256;
        bytes32 mask = ~(Mask << (255 - bitIndex));
        set[wordIndex] &= mask;
    }

    function checkBit(bytes32[100] memory set, uint256 index)
        internal
        pure
        returns (bool)
    {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        bytes32 mask = Mask << (255 - bitIndex);
        return (mask & set[wordIndex]) != 0;
    }

    function isActive(bytes32[100] memory set)
        internal
        pure
        returns (bool)
    {
        return (Mask & set[99]) == Mask;
    }
}


/**
 * @title MoonCat​Accessories
 * @notice Public MoonCat Wearables infrastructure/protocols
 * @dev Allows wearable-designers to create accessories for sale and gifting.
 */
contract MoonCatAccessories {

    /* External Contracts */

    IMoonCatAcclimator MCA = IMoonCatAcclimator(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69);
    IMoonCatRescue MCR = IMoonCatRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6);

    /* Events */

    event AccessoryCreated(uint256 accessoryId, address creator, uint256 price, uint16 totalSupply, bytes30 name);
    event AccessoryManagementTransferred(uint256 accessoryId, address newManager);
    event AccessoryPriceChanged(uint256 accessoryId, uint256 price);
    event AccessoryPurchased(uint256 accessoryId, uint256 rescueOrder, uint256 price);
    event AccessoryApplied(uint256 accessoryId, uint256 rescueOrder, uint8 paletteIndex, uint16 zIndex);
    event AccessoryDiscontinued(uint256 accessoryId);

    event EligibleListSet(uint256 accessoryId);
    event EligibleListCleared(uint256 accessoryId);

    /* Structs */

    struct Accessory {            // Accessory Definition
        address payable manager;  // initially creator; payee for sales
        uint8 width;              // image width
        uint8 height;             // image height
        uint8 meta;               // metadata flags [Reserved 3b, Audience 2b, MirrorPlacement 1b, MirrorAccessory 1b, Background 1b]
        uint72 price;             // price at which accessory can be purchased (MAX ~4,722 ETH)
                                  // if set to max value, the accessory is not for sale

        uint16 totalSupply;      // total number of a given accessory that will ever exist; can only be changed by discontinuing the accessory
        uint16 availableSupply;  // number of given accessory still available for sale; decremented on each sale
        bytes28 name;            // unicode name of accessory, can only be set on creation

        bytes8[7] palettes;     // color palettes, each palette is an array of uint8 offsets into the global palette
        bytes2[4] positions;    // offsets for all 4 MoonCat poses, an offset pair of 0xffff indicates the pose is not supported
                                // position order is [standing, sleeping, pouncing, stalking]

        bytes IDAT;            // PNG IDAT chunk data for image reconstruction
    }

    struct OwnedAccessory {   // Accessory owned by an AcclimatedMoonCat
        uint232 accessoryId;  // index into AllAccessories Array
        uint8 paletteIndex;   // index into Accessory.palettes Array
        uint16 zIndex;        // drawing order indicator (lower numbers are closer to MoonCat)
                              // zIndex == 0 indicates the MoonCat is not wearing the accessory
                              // if the accessory meta `Background` bit is 1 the zIndex is interpreted as negative
    }

    struct AccessoryBatchData {   // Used for batch accessory alterations and purchases
        uint256 rescueOrder;
        uint232 ownedIndexOrAccessoryId;
        uint8 paletteIndex;
        uint16 zIndex;
    }

    using EnumerableSet for EnumerableSet.Set;

    /* State */

    bool public frozen = true;

    Accessory[] internal AllAccessories; //  Array of all Accessories that have been created
    mapping (uint256 => bytes32[100]) internal AllEligibleLists; // Accessory ID => BitSet
                                                                 // Each bit represents the eligbility of an AcclimatedMoonCat
                                                                 // An eligibleList is active when the final bit == 1

    mapping (address => EnumerableSet.Set) internal AccessoriesByManager; // Manager address => accessoryId Set

    mapping (uint256 => mapping(uint256 => bool)) internal OwnedAccessoriesByMoonCat; // AcclimatedMoonCat rescueOrder => Accessory ID => isOwned?
    mapping (uint256 => OwnedAccessory[]) public AccessoriesByMoonCat; // AcclimatedMoonCat rescueOrder => Array of AppliedAccessory structs

    mapping (bytes32 => bool) public accessoryHashes; // used to check if the image data for an accessory has already been submitted

    address payable public owner;

    uint72 constant NOT_FOR_SALE = 0xffffffffffffffffff;

    uint256 public feeDenominator = 5;
    uint256 public referralDenominator = 0;

    /* Modifiers */

    modifier onlyOwner () {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier accessoryExists (uint256 accessoryId){
        require(accessoryId < AllAccessories.length, "Accessory Not Found");
        _;
    }

    modifier onlyAccessoryManager (uint256 accessoryId) {
        require(msg.sender == AllAccessories[accessoryId].manager, "Not Accessory Manager");
        _;
    }

    modifier onlyAMCOwner (uint256 rescueOrder) {
        require(MCR.catOwners(MCR.rescueOrder(rescueOrder)) == 0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69,
                "Not Acclimated");
        address moonCatOwner = MCA.ownerOf(rescueOrder);
        require((msg.sender == moonCatOwner)
            || (msg.sender == MCA.getApproved(rescueOrder))
            || (MCA.isApprovedForAll(moonCatOwner, msg.sender)),
            "Not AMC Owner or Approved"
        );
        _;
    }

    modifier notZeroAddress (address a){
        require(a != address(0), "Zero Address");
        _;
    }

    modifier notFrozen () {
        require(!frozen, "Frozen");
        _;
    }

    modifier validPrice(uint256 price) {
        require(price <= NOT_FOR_SALE, "Invalid Price");
        _;
    }

    /* Admin */

    constructor(){
        owner = payable(msg.sender);

        // https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
        IReverseResolver(0x084b1c3C81545d370f3634392De611CaaBFf8148)
            .claim(msg.sender);
    }

    /**
     * @dev Transfer funds from the contract's wallet to an external wallet, minus a fee
     */
    function sendPayment (address payable target, uint256 amount, address payable referrer)
        internal
    {
        uint256 fee = (feeDenominator > 0) ? (amount / feeDenominator) : 0;
        uint256 referral = (referralDenominator > 0) ? (fee / referralDenominator) : 0;
        fee = fee - referral;
        uint256 payment = amount - fee - referral;
        owner.transfer(fee);
        referrer.transfer(referral);
        target.transfer(payment);
    }

    /**
     * @dev Update the amount of fee taken from each sale
     */
    function setFee (uint256 denominator)
        public
        onlyOwner
    {
        feeDenominator = denominator;
    }

    /**
     * @dev Update the amount of referral fee taken from each sale
     */
    function setReferralFee (uint256 denominator)
        public
        onlyOwner
    {
        referralDenominator = denominator;
    }

    /**
     * @dev Allow current `owner` to transfer ownership to another address
     */
    function transferOwnership (address payable newOwner)
        public
        onlyOwner
    {
        owner = newOwner;
    }

    /**
     * @dev Prevent creating and applying accessories
     */
    function freeze ()
        public
        onlyOwner
        notFrozen
    {
        frozen = true;
    }

    /**
     * @dev Enable creating and applying accessories
     */
    function unfreeze ()
        public
        onlyOwner
    {
        frozen = false;
    }

    /**
     * @dev Update the metadata flags for an accessory
     */
    function setMetaByte (uint256 accessoryId, uint8 metabyte)
        public
        onlyOwner
        accessoryExists(accessoryId)
    {
        Accessory storage accessory = AllAccessories[accessoryId];
        accessory.meta = metabyte;
    }

    /**
     * @dev Batch-update metabytes for accessories, by ensuring given bits are on
     */
    function batchOrMetaByte (uint8 value, uint256[] calldata accessoryIds)
        public
        onlyOwner
    {
        uint256 id;
        Accessory storage accessory;
        for(uint256 i = 0; i < accessoryIds.length; i++){
            id = accessoryIds[i];
            if(i < AllAccessories.length){
                accessory = AllAccessories[id];
                accessory.meta = accessory.meta | value;
            }
        }
    }

    /**
     * @dev Batch-update metabytes for accessories, by ensuring given bits are off
     */
    function batchAndMetaByte (uint8 value, uint256[] calldata accessoryIds)
        public
        onlyOwner
    {
        uint256 id;
        Accessory storage accessory;
        for(uint256 i = 0; i < accessoryIds.length; i++){
            id = accessoryIds[i];
            if(i < AllAccessories.length){
                accessory = AllAccessories[id];
                accessory.meta = accessory.meta & value;
            }
        }
    }

    /**
     * @dev Rescue ERC20 assets sent directly to this contract.
     */
    function withdrawForeignERC20(address tokenContract)
        public
        onlyOwner
    {
        IERC20 token = IERC20(tokenContract);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721(address tokenContract, uint256 tokenId)
        public
        onlyOwner
    {
        IERC721(tokenContract).safeTransferFrom(address(this), owner, tokenId);
    }

    /**
     * @dev Check if a MoonCat is eligible to purchase an accessory
     */
    function isEligible(uint256 rescueOrder, uint256 accessoryId)
        public
        view
        returns (bool)
    {
        if(MoonCatBitSet.isActive(AllEligibleLists[accessoryId])) {
            return MoonCatBitSet.checkBit(AllEligibleLists[accessoryId], rescueOrder);
        }
        return true;
    }

    /* Helpers */

    /**
     * @dev Mark an accessory as owned by a specific MoonCat, and put it on
     *
     * This is an internal function that only does sanity-checking (prevent double-buying an accessory, and prevent picking an invalid palette).
     * All methods that use this function check permissions before calling this function.
     */
    function applyAccessory (uint256 rescueOrder, uint256 accessoryId, uint8 paletteIndex, uint16 zIndex)
        private
        accessoryExists(accessoryId)
        notFrozen
        returns (uint256)
    {
        require(OwnedAccessoriesByMoonCat[rescueOrder][accessoryId] == false, "Already Owned");
        require(uint64(AllAccessories[accessoryId].palettes[paletteIndex]) != 0, "Invalid Palette");
        OwnedAccessory[] storage ownedAccessories = AccessoriesByMoonCat[rescueOrder];
        uint256 ownedAccessoryIndex = ownedAccessories.length;
        ownedAccessories.push(OwnedAccessory(uint232(accessoryId), paletteIndex, zIndex));
        OwnedAccessoriesByMoonCat[rescueOrder][accessoryId] = true;
        emit AccessoryApplied(accessoryId, rescueOrder, paletteIndex, zIndex);
        return ownedAccessoryIndex;
    }

    /**
     * @dev Ensure an accessory's image data has not been submitted before
     */
    function verifyAccessoryUniqueness(bytes calldata IDAT)
        internal
    {
        bytes32 accessoryHash = keccak256(IDAT);
        require(!accessoryHashes[accessoryHash], "Duplicate");
        accessoryHashes[accessoryHash] = true;
    }

    /* Creator */

    /**
     * @dev Create an accessory, as the contract owner
     *
     * This method allows the contract owner to deploy accessories on behalf of others. It also allows deploying
     * accessories that break some of the rules:
     *
     * This method can be called when frozen, so the owner can add to the store even when others cannot.
     * This method does not check for duplicates, so if an accessory creator wants to make a literal duplicate, that can be facilitated.
     */
    function ownerCreateAccessory(address payable manager, uint8[3] calldata WHM, uint256 priceWei, uint16 totalSupply, bytes28 name, bytes2[4] calldata positions, bytes8[7] calldata initialPalettes, bytes calldata IDAT)
        public
        onlyOwner
        returns (uint256)
    {
        uint256 accessoryId = AllAccessories.length;
        AllAccessories.push(Accessory(manager, WHM[0], WHM[1], WHM[2], uint72(priceWei), totalSupply, totalSupply, name, initialPalettes, positions, IDAT));

        bytes32 accessoryHash = keccak256(IDAT);
        accessoryHashes[accessoryHash] = true;

        emit AccessoryCreated(accessoryId, manager, priceWei, totalSupply, name);
        AccessoriesByManager[manager].add(accessoryId);
        return accessoryId;
    }

    /**
     * @dev Create an accessory with an eligible list, as the contract owner
     */
    function ownerCreateAccessory(address payable manager, uint8[3] calldata WHM, uint256 priceWei, uint16 totalSupply, bytes28 name, bytes2[4] calldata positions, bytes8[7] calldata initialPalettes, bytes calldata IDAT, bytes32[100] calldata eligibleList)
        public
        onlyOwner
        returns (uint256)
    {
        uint256 accessoryId = ownerCreateAccessory(manager, WHM, priceWei, totalSupply, name, positions, initialPalettes, IDAT);
        AllEligibleLists[accessoryId] = eligibleList;
        MoonCatBitSet.activate(AllEligibleLists[accessoryId]);
        return accessoryId;
    }

    /**
     * @dev Create an accessory
     */
    function createAccessory (uint8[3] calldata WHM, uint256 priceWei, uint16 totalSupply, bytes28 name, bytes2[4] calldata positions, bytes8[] calldata palettes, bytes calldata IDAT)
        public
        notFrozen
        validPrice(priceWei)
        returns (uint256)
    {
        require(palettes.length <= 7 && palettes.length > 0, "Invalid Palette Count");
        require(totalSupply > 0 && totalSupply <= 25440, "Invalid Supply");
        require(WHM[0] > 0 && WHM[1] > 0, "Invalid Dimensions");
        verifyAccessoryUniqueness(IDAT);
        uint256 accessoryId = AllAccessories.length;
        bytes8[7] memory initialPalettes;
        for(uint i = 0; i < palettes.length; i++){
            require(uint64(palettes[i]) != 0, "Invalid Palette");
            initialPalettes[i] = palettes[i];
        }
        AllAccessories.push(Accessory(payable(msg.sender), WHM[0], WHM[1], WHM[2] & 0x1f, uint72(priceWei), totalSupply, totalSupply, name, initialPalettes, positions, IDAT));
        //                                                                        ^ Clear reserved bits
        emit AccessoryCreated(accessoryId, msg.sender, priceWei, totalSupply, name);
        AccessoriesByManager[msg.sender].add(accessoryId);
        return accessoryId;
    }

    /**
     * @dev Create an accessory with an eligible list
     */
    function createAccessory (uint8[3] calldata WHM, uint256 priceWei, uint16 totalSupply, bytes28 name, bytes2[4] calldata positions, bytes8[] calldata palettes, bytes calldata IDAT, bytes32[100] calldata eligibleList)
        public
        returns (uint256)
    {
        uint256 accessoryId = createAccessory(WHM, priceWei, totalSupply, name, positions, palettes, IDAT);
        AllEligibleLists[accessoryId] = eligibleList;
        MoonCatBitSet.activate(AllEligibleLists[accessoryId]);
        return accessoryId;
    }

    /**
     * @dev Add a color palette variant to an existing accessory
     */
    function addAccessoryPalette (uint256 accessoryId, bytes8 newPalette)
        public
        onlyAccessoryManager(accessoryId)
    {
        require(uint64(newPalette) != 0, "Invalid Palette");
        Accessory storage accessory = AllAccessories[accessoryId];
        bytes8[7] storage accessoryPalettes = accessory.palettes;

        require(uint64(accessoryPalettes[6]) == 0, "Palette Limit Exceeded");
        uint paletteIndex = 1;
        while(uint64(accessoryPalettes[paletteIndex]) > 0){
            paletteIndex++;
        }
        accessoryPalettes[paletteIndex] = newPalette;
    }

    /**
     * @dev Give ownership of an accessory to someone else
     */
    function transferAccessoryManagement (uint256 accessoryId, address payable newManager)
        public
        onlyAccessoryManager(accessoryId)
        notZeroAddress(newManager)
    {
        Accessory storage accessory = AllAccessories[accessoryId];
        AccessoriesByManager[accessory.manager].remove(accessoryId);
        AccessoriesByManager[newManager].add(accessoryId);
        accessory.manager = newManager;
        emit AccessoryManagementTransferred(accessoryId, newManager);
    }

    /**
     * @dev Set accessory to have a new price
     */
    function setAccessoryPrice (uint256 accessoryId, uint256 newPriceWei)
        public
        onlyAccessoryManager(accessoryId)
        validPrice(newPriceWei)
    {
        Accessory storage accessory = AllAccessories[accessoryId];

        if(accessory.price != newPriceWei){
            accessory.price = uint72(newPriceWei);
            emit AccessoryPriceChanged(accessoryId, newPriceWei);
        }
    }

    /**
     * @dev Set accessory eligible list
     */
    function setEligibleList (uint256 accessoryId, bytes32[100] calldata eligibleList)
        public
        onlyAccessoryManager(accessoryId)
    {
        AllEligibleLists[accessoryId] = eligibleList;
        MoonCatBitSet.activate(AllEligibleLists[accessoryId]);
        emit EligibleListSet(accessoryId);
    }

    /**
     * @dev Clear accessory eligible list
     */
    function clearEligibleList (uint256 accessoryId)
        public
        onlyAccessoryManager(accessoryId)
    {
        delete AllEligibleLists[accessoryId];
        emit EligibleListCleared(accessoryId);
    }

    /**
     * @dev Turns eligible list on or off without setting/clearing
     */
    function toggleEligibleList (uint256 accessoryId, bool active)
        public
        onlyAccessoryManager(accessoryId)
    {
        bool isActive = MoonCatBitSet.isActive(AllEligibleLists[accessoryId]);
        if(isActive && !active) {
            MoonCatBitSet.deactivate(AllEligibleLists[accessoryId]);
            emit EligibleListCleared(accessoryId);
        } else if (!isActive && active){
            MoonCatBitSet.activate(AllEligibleLists[accessoryId]);
            emit EligibleListSet(accessoryId);
        }
    }

    /**
     * @dev Add/Remove individual rescueOrders from an eligibleSet
     */
    function editEligibleMoonCats(uint256 accessoryId, bool targetState, uint16[] calldata rescueOrders)
        public
        onlyAccessoryManager(accessoryId)
    {
        bytes32[100] storage eligibleList = AllEligibleLists[accessoryId];
        for(uint i = 0; i < rescueOrders.length; i++){
            require(rescueOrders[i] < 25440, "Out of bounds");
            if(targetState) {
                MoonCatBitSet.setBit(eligibleList, rescueOrders[i]);
            } else {
                MoonCatBitSet.clearBit(eligibleList, rescueOrders[i]);
            }
        }
        if(MoonCatBitSet.isActive(eligibleList)){
            emit EligibleListSet(accessoryId);
        }
    }

    /**
     * @dev Buy an accessory as the manager of that accessory
     *
     * Accessory managers always get charged zero cost for buying/applying their own accessories,
     * and always bypass the EligibleList (if there is any).
     *
     * A purchase by the accessory manager still reduces the available supply of an accessory, and
     * the Manager must be the owner of or be granted access to the MoonCat to which the accessory
     * is being applied.
     */
    function managerApplyAccessory (uint256 rescueOrder, uint256 accessoryId, uint8 paletteIndex, uint16 zIndex)
        public
        onlyAccessoryManager(accessoryId)
        onlyAMCOwner(rescueOrder)
        returns (uint256)
    {
        require(AllAccessories[accessoryId].availableSupply > 0, "Supply Exhausted");
        AllAccessories[accessoryId].availableSupply--;
        return applyAccessory(rescueOrder, accessoryId, paletteIndex, zIndex);
    }

    /**
     * @dev Remove accessory from the market forever by transferring
     * management to the zero address, setting it as not for sale, and
     * setting the total supply to the current existing quantity.
     */
    function discontinueAccessory (uint256 accessoryId)
        public
        onlyAccessoryManager(accessoryId)
    {
        Accessory storage accessory = AllAccessories[accessoryId];
        accessory.price = NOT_FOR_SALE;
        AccessoriesByManager[accessory.manager].remove(accessoryId);
        AccessoriesByManager[address(0)].add(accessoryId);
        accessory.manager = payable(address(0));
        accessory.totalSupply = accessory.totalSupply - accessory.availableSupply;
        accessory.availableSupply = 0;
        emit AccessoryDiscontinued(accessoryId);
    }

    /* User */

    /**
     * @dev Purchase and apply an accessory in a standard manner.
     *
     * This method is an internal method for doing standard permission checks before calling the applyAccessory function.
     * This method checks that an accessory is set to be allowed for sale (not set to the max price), that there's enough supply left,
     * and that the buyer has supplied enough ETH to satisfy the price of the accessory.
     *
     * In addition, it checks to ensure that the MoonCat receiving the accessory is owned by the address making this purchase,
     * and that the MoonCat purchasing the accessory is on the Eligible List for that accessory.
     */
    function buyAndApplyAccessory (uint256 rescueOrder, uint256 accessoryId, uint8 paletteIndex, uint16 zIndex, address payable referrer)
        private
        onlyAMCOwner(rescueOrder)
        notZeroAddress(referrer)
        accessoryExists(accessoryId)
        returns (uint256)
    {
        require(isEligible(rescueOrder, accessoryId), "Ineligible");
        Accessory storage accessory = AllAccessories[accessoryId];
        require(accessory.price != NOT_FOR_SALE, "Not For Sale");
        require(accessory.availableSupply > 0, "Supply Exhausted");
        accessory.availableSupply--;
        require(address(this).balance >= accessory.price, "Insufficient Value");
        emit AccessoryPurchased(accessoryId, rescueOrder, accessory.price);
        uint256 ownedAccessoryId = applyAccessory(rescueOrder, accessoryId, paletteIndex, zIndex);
        if(accessory.price > 0) {
            sendPayment(accessory.manager, accessory.price, referrer);
        }
        return ownedAccessoryId;
    }

    /**
     * @dev Buy an accessory that is up for sale by its owner
     *
     * This method is the typical purchase method used by storefronts;
     * it allows the storefront to claim a referral fee for the purchase.
     *
     * Passing a z-index value of zero to this method just purchases the accessory,
     * but does not make it an active part of the MoonCat's appearance.
     */
    function buyAccessory (uint256 rescueOrder, uint256 accessoryId, uint8 paletteIndex, uint16 zIndex, address payable referrer)
        public
        payable
        returns (uint256)
    {
        uint256 ownedAccessoryId = buyAndApplyAccessory(rescueOrder, accessoryId, paletteIndex, zIndex, referrer);
        if(address(this).balance > 0){
            // The buyer over-paid; transfer their funds back to them
            payable(msg.sender).transfer(address(this).balance);
        }
        return ownedAccessoryId;
    }

    /**
     * @dev Buy an accessory that is up for sale by its owner
     *
     * This method is a generic fallback method if no referrer address is given for a purchase.
     * Defaults to the owner of the contract to receive the referral fee in this case.
     */
    function buyAccessory (uint256 rescueOrder, uint256 accessoryId, uint8 paletteIndex, uint16 zIndex)
        public
        payable
        returns (uint256)
    {
        return buyAccessory(rescueOrder, accessoryId, paletteIndex, zIndex, owner);
    }

    /**
     * @dev Buy multiple accessories at once; setting a palette and z-index for each one
     */
    function buyAccessories (AccessoryBatchData[] calldata orders, address payable referrer)
        public
        payable
    {
        for (uint256 i = 0; i < orders.length; i++) {
            AccessoryBatchData memory order = orders[i];
            buyAndApplyAccessory(order.rescueOrder, order.ownedIndexOrAccessoryId, order.paletteIndex, order.zIndex, referrer);
        }
        if(address(this).balance > 0){
            // The buyer over-paid; transfer their funds back to them
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    /**
     * @dev Buy multiple accessories at once; setting a palette and z-index for each one (setting the contract owner as the referrer)
     */
    function buyAccessories (AccessoryBatchData[] calldata orders)
        public
        payable
    {
        buyAccessories(orders, owner);
    }

    /**
     * @dev Change the status of an owned accessory (worn or not, z-index ordering, color palette variant)
     */
    function alterAccessory (uint256 rescueOrder, uint256 ownedAccessoryIndex, uint8 paletteIndex, uint16 zIndex)
        public
        onlyAMCOwner(rescueOrder)
    {
        OwnedAccessory[] storage ownedAccessories = AccessoriesByMoonCat[rescueOrder];
        require(ownedAccessoryIndex < ownedAccessories.length, "Owned Accessory Not Found");
        OwnedAccessory storage ownedAccessory = ownedAccessories[ownedAccessoryIndex];
        require((paletteIndex <= 7) && (uint64(AllAccessories[ownedAccessory.accessoryId].palettes[paletteIndex]) != 0), "Palette Not Found");
        ownedAccessory.paletteIndex = paletteIndex;
        ownedAccessory.zIndex = zIndex;
        emit AccessoryApplied(ownedAccessory.accessoryId, rescueOrder, paletteIndex, zIndex);
    }

    /**
    * @dev Change the status of multiple accessories at once
    */
    function alterAccessories (AccessoryBatchData[] calldata alterations)
        public
    {
        for(uint i = 0; i < alterations.length; i++ ){
            AccessoryBatchData memory alteration = alterations[i];
            alterAccessory(alteration.rescueOrder, alteration.ownedIndexOrAccessoryId, alteration.paletteIndex, alteration.zIndex);
        }
    }

    /* View - Accessories */

    /**
     * @dev How many accessories exist in this contract?
     */
    function totalAccessories ()
        public
        view
        returns (uint256)
    {
        return AllAccessories.length;
    }

    /**
     * @dev Checks if there is an accessory with same IDAT data
     */
    function isAccessoryUnique(bytes calldata IDAT)
        public
        view
        returns (bool)
    {
        bytes32 accessoryHash = keccak256(IDAT);
        return (!accessoryHashes[accessoryHash]);
    }

    /**
     * @dev How many palettes are defined for an accessory?
     */
    function accessoryPaletteCount (uint256 accessoryId)
        public
        view
        accessoryExists(accessoryId)
        returns (uint8)
    {
        bytes8[7] memory accessoryPalettes = AllAccessories[accessoryId].palettes;
        for(uint8 i = 0; i < accessoryPalettes.length; i++) {
            if (uint64(accessoryPalettes[i]) == 0) {
                return i;
            }
        }
        return uint8(accessoryPalettes.length);
    }

    /**
     * @dev Fetch a specific palette for a given accessory
     */
    function accessoryPalette (uint256 accessoryId, uint256 paletteIndex)
        public
        view
        returns (bytes8)
    {
        return AllAccessories[accessoryId].palettes[paletteIndex];
    }

    /**
     * @dev Fetch data about a given accessory
     */
    function accessoryInfo (uint256 accessoryId)
        public
        view
        accessoryExists(accessoryId)
        returns (uint16 totalSupply, uint16 availableSupply, bytes28 name, address manager, uint8 metabyte, uint8 availablePalettes, bytes2[4] memory positions, bool availableForPurchase, uint256 price)
    {
        Accessory memory accessory = AllAccessories[accessoryId];
        availablePalettes = accessoryPaletteCount(accessoryId);
        bool available = accessory.price != NOT_FOR_SALE && accessory.availableSupply > 0;
        return (accessory.totalSupply, accessory.availableSupply, accessory.name, accessory.manager, accessory.meta, availablePalettes, accessory.positions, available, accessory.price);
    }

    /**
     * @dev Fetch image data about a given accessory
     */
    function accessoryImageData (uint256 accessoryId)
        public
        view
        accessoryExists(accessoryId)
        returns (bytes2[4] memory positions, bytes8[7] memory palettes, uint8 width, uint8 height, uint8 meta, bytes memory IDAT)
    {
        Accessory memory accessory = AllAccessories[accessoryId];
        return (accessory.positions, accessory.palettes, accessory.width, accessory.height, accessory.meta, accessory.IDAT);
    }

    /**
     * @dev Fetch EligibleList for a given accessory
     */
    function accessoryEligibleList(uint256 accessoryId)
        public
        view
        accessoryExists(accessoryId)
        returns (bytes32[100] memory)
    {
        return AllEligibleLists[accessoryId];
    }

    /*  View - Manager */

    /**
     * @dev Which address manages a specific accessory?
     */
    function managerOf (uint256 accessoryId)
        public
        view
        accessoryExists(accessoryId)
        returns (address)
    {
        return AllAccessories[accessoryId].manager;
    }

    /**
     * @dev How many accessories does a given address manage?
     */
    function balanceOf (address manager)
        public
        view
        returns (uint256)
    {
        return AccessoriesByManager[manager].length();
    }

    /**
     * @dev Iterate through a given address's managed accessories
     */
    function managedAccessoryByIndex (address manager, uint256 managedAccessoryIndex)
        public
        view
        returns (uint256)
    {
        return AccessoriesByManager[manager].at(managedAccessoryIndex);
    }

    /*  View - AcclimatedMoonCat */

    /**
     * @dev How many accessories does a given MoonCat own?
     */
    function balanceOf (uint256 rescueOrder)
        public
        view
        returns (uint256)
    {
        return AccessoriesByMoonCat[rescueOrder].length;
    }

    /**
     * @dev Iterate through a given MoonCat's accessories
     */
    function ownedAccessoryByIndex (uint256 rescueOrder, uint256 ownedAccessoryIndex)
        public
        view
        returns (OwnedAccessory memory)
    {
        require(ownedAccessoryIndex < AccessoriesByMoonCat[rescueOrder].length, "Index out of bounds");
        return AccessoriesByMoonCat[rescueOrder][ownedAccessoryIndex];
    }

    /**
     * @dev Lookup function to see if this MoonCat has already purchased a given accessory
     */
    function doesMoonCatOwnAccessory (uint256 rescueOrder, uint256 accessoryId)
        public
        view
        returns (bool)
    {
        return OwnedAccessoriesByMoonCat[rescueOrder][accessoryId];
    }

}