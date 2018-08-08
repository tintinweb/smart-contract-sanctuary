pragma solidity ^0.4.16;

/***********************************************
 ***************
 * UTF8 library
 * == FINAL ==
 ***************
 **********************************************/
library UTF8 {
    function getStringLength(string str) internal pure returns(int256 length) {
        uint256 i = 0;
        bytes memory str_rep = bytes(str);
        while(i < str_rep.length) {
            if (str_rep[i] >> 7 == 0)         i += 1;
            else if (str_rep[i] >> 5 == 0x6)  i += 2;
            else if (str_rep[i] >> 4 == 0xE)  i += 3;
            else if (str_rep[i] >> 3 == 0x1E) i += 4;
            else                              i += 1;
            length++;
        }
    }
}


/***********************************************
 ***************
 * Math library
 ***************
 **********************************************/
library Math {
    function divide(int256 numerator, int256 denominator, uint256 precision) internal pure returns(int256) {
        int256 _numerator = numerator * int256(10 ** (precision + 1));
        int256 _quotient  = ((_numerator / denominator) + 5) / 10;
        return _quotient;
    }

    function rand(uint256 nonce, int256 min, int256 max) internal view returns(int256) {
        return int256(uint256(keccak256(nonce + block.number + block.timestamp)) % uint256((max - min))) + min;
    }

    function rand16(uint256 nonce, uint16 min, uint16 max) internal view returns(uint16) {
        return uint16(uint256(keccak256(nonce + block.number + block.timestamp)) % uint256(max - min)) + min;
    }

    function rand8(uint256 nonce, uint8 min, uint8 max) internal view returns(uint8) {
        return uint8(uint256(keccak256(nonce + block.number + block.timestamp)) % uint256(max - min)) + min;
    }

    function percent(uint256 value, uint256 per) internal pure returns(uint256) {
        return uint256((divide(int256(value), 100, 4) * int256(per)) / 10000);
    }
}


/***********************************************
 ***************
 * Ownable contract
 * == FINAL ==
 ***************
 **********************************************/
contract Ownable {
    address public owner;
    
    modifier onlyOwner()  { require(msg.sender == owner); _; }

    function Ownable() public { owner = msg.sender; }

    function updateContractOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}


/***********************************************
 ***************
 * Priced contract
 ***************
 **********************************************/
contract Priced is Ownable {
    uint256 private price       = 500000000000000000;  // Basic price in wei
    uint16  private zMax        = 1600;                // Max z for get price percent
    uint256 private zPrice      = 25000000000000000;   // Price for each item in z index (in wei)
    uint8   private commission  = 10;                  // Update commission in percent

    function setPriceData(uint256 _price, uint16 _zMax, uint256 _zPrice, uint8 _commission) external onlyOwner {
        price       = _price;
        zMax        = _zMax;
        zPrice      = _zPrice;
        commission  = _commission;
    }

    function getCreatePrice(uint16 z, uint256 zCount) internal view returns(uint256) {
        return ((price * uint256(Math.divide(int256(z), int256(zMax), 4))) / 10000) + (zPrice * zCount);
    }

    function getCommission(uint256 starPrice) internal view returns(uint256) {
        return Math.percent(starPrice, commission);
    }
}


/***********************************************
 ***************
 * Control contract
 * == FINAL ==
 ***************
 **********************************************/
contract Control is Ownable {
    /**
     * Withdraw balance
     */
    function withdrawBalance(address recipient, uint256 value) external onlyOwner {
        require(value > 0);
        require(value < address(this).balance);
        recipient.transfer(value);
    }
}


/***********************************************
 ***************
 * Storage contract
 ***************
 **********************************************/
contract Storage {
    struct Star {
        address owner;   // Star owner
        uint8   gid;     // Star galaxy id
        uint8   zIndex;  // Star z
        uint16  box;     // Current xy box 
        uint8   inbox;   // Random x-y in box
        uint8   stype;   // Star type
        uint8   color;   // Star color
        uint256 price;   // Price for this star
        uint256 sell;    // Sell price for this star
        bool    deleted; // Star is deleted
        string  name;    // User defined star name
        string  message; // User defined message
    }

    // General stars storage
    Star[] internal stars;

    // Stars at zIndex area (gid => zIndex => count)
    mapping(uint8 => mapping(uint8 => uint16)) internal zCount;    

    // Stars positions (gid => zIndex => box => starId)
    mapping(uint8 => mapping(uint8 => mapping(uint16 => uint256))) private positions;    


    /**
     * Add new star
     */
    function addStar(address owner, uint8 gid, uint8 zIndex, uint16 box, uint8 inbox, uint8 stype, uint8 color, uint256 price) internal returns(uint256) {
        Star memory _star = Star({
            owner: owner,
            gid: gid, zIndex: zIndex, box: box, inbox: inbox,
            stype: stype, color: color,
            price: price, sell: 0, deleted: false, name: "", message: ""
        });
        uint256 starId = stars.push(_star) - 1;
        placeStar(gid, zIndex, box, starId);
        return starId;
    }

    function placeStar(uint8 gid, uint8 zIndex, uint16 box, uint256 starId) private {
        zCount[gid][zIndex]         = zCount[gid][zIndex] + 1;
        positions[gid][zIndex][box] = starId;
    }

    function setStarNameMessage(uint256 starId, string name, string message) internal {
        stars[starId].name    = name;
        stars[starId].message = message;
    }

    function setStarNewOwner(uint256 starId, address newOwner) internal {
        stars[starId].owner = newOwner;
    }

    function setStarSellPrice(uint256 starId, uint256 sellPrice) internal {
        stars[starId].sell = sellPrice;
    }

    function setStarDeleted(uint256 starId) internal {
        stars[starId].deleted = true;
        setStarSellPrice(starId, 0);
        setStarNameMessage(starId, "", "");
        setStarNewOwner(starId, address(0));

        Star storage _star = stars[starId];
        zCount[_star.gid][_star.zIndex]               = zCount[_star.gid][_star.zIndex] - 1;
        positions[_star.gid][_star.zIndex][_star.box] = 0;
    }


    /**
     * Get star by id
     */
    function getStar(uint256 starId) external view returns(address owner, uint8 gid, uint8 zIndex, uint16 box, uint8 inbox,
                                                           uint8 stype, uint8 color,
                                                           uint256 price, uint256 sell, bool deleted,
                                                           string name, string message) {
        Star storage _star = stars[starId];
        owner      = _star.owner;
        gid        = _star.gid;
        zIndex     = _star.zIndex;
        box        = _star.box;
        inbox      = _star.inbox;
        stype      = _star.stype;
        color      = _star.color;
        price      = _star.price;
        sell       = _star.sell;
        deleted    = _star.deleted;
        name       = _star.name;
        message    = _star.message;
    }

    function getStarIdAtPosition(uint8 gid, uint8 zIndex, uint16 box) internal view returns(uint256) {
        return positions[gid][zIndex][box];
    }

    function starExists(uint256 starId) internal view returns(bool) {
        return starId > 0 && starId < stars.length && stars[starId].deleted == false;
    }

    function isStarOwner(uint256 starId, address owner) internal view returns(bool) {
        return stars[starId].owner == owner;
    }
}


/***********************************************
 ***************
 * Validation contract
 ***************
 **********************************************/
contract Validation is Priced, Storage {
    uint8   private gidMax     = 5;
    uint16  private zMin       = 100;
    uint16  private zMax       = 1600;
    uint8   private lName      = 25;
    uint8   private lMessage   = 140;
    uint8   private maxCT      = 255; // Max color, types
    uint256 private nonce      = 1;
    uint8   private maxIRandom = 4;
    uint16  private boxSize    = 20;  // Universe box size
    uint8   private inboxXY    = 100;

    // Available box count in each z index (zIndex => count)
    mapping(uint8 => uint16) private boxes;


    /**
     * Set validation data
     */
    function setValidationData(uint16 _zMin, uint16 _zMax, uint8 _lName, uint8 _lMessage, uint8 _maxCT, uint8 _maxIR, uint16 _boxSize) external onlyOwner {
        zMin       = _zMin;
        zMax       = _zMax;
        lName      = _lName;
        lMessage   = _lMessage;
        maxCT      = _maxCT;
        maxIRandom = _maxIR;
        boxSize    = _boxSize;
        inboxXY    = uint8((boxSize * boxSize) / 4);
    }

    function setGidMax(uint8 _gidMax) external onlyOwner {
        gidMax = _gidMax;
    }


    /**
     * Get set boxes
     */
    function setBoxCount(uint16 z, uint16 count) external onlyOwner {
        require(isValidZ(z));
        boxes[getZIndex(z)] = count;
    }

    function getBoxCount(uint16 z) external view returns(uint16 count) {
        require(isValidZ(z));
        return boxes[getZIndex(z)];
    }

    function getBoxCountZIndex(uint8 zIndex) private view returns(uint16 count) {
        return boxes[zIndex];
    }


    /**
     * Get z index and z count
     */
    function getZIndex(uint16 z) internal view returns(uint8 zIndex) {
        return uint8(z / boxSize);
    }

    function getZCount(uint8 gid, uint8 zIndex) public view returns(uint16 count) {
        return zCount[gid][zIndex];
    }

    
    /**
     * Validate star parameters
     */
    function isValidGid(uint8 gid) internal view returns(bool) {
        return gid > 0 && gid <= gidMax;
    }

    function isValidZ(uint16 z) internal view returns(bool) {
        return z >= zMin && z <= zMax;
    }

    function isValidBox(uint8 gid, uint8 zIndex, uint16 box) internal view returns(bool) {
        return getStarIdAtPosition(gid, zIndex, box) == 0;
    }


    /**
     * Check name and message length
     */
    function isValidNameLength(string name) internal view returns(bool) {
        return UTF8.getStringLength(name) <= lName;
    }

    function isValidMessageLength(string message) internal view returns(bool) {
        return UTF8.getStringLength(message) <= lMessage;
    }


    /**
     * Check is valid msg value
     */
    function isValidMsgValue(uint256 price) internal returns(bool) {
        if (msg.value < price) return false;
        if (msg.value > price)
            msg.sender.transfer(msg.value - price);
        return true;
    }


    /**
     * Get random number
     */
    function getRandom16(uint16 min, uint16 max) private returns(uint16) {
        nonce++;
        return Math.rand16(nonce, min, max);
    }

    function getRandom8(uint8 min, uint8 max) private returns(uint8) {
        nonce++;
        return Math.rand8(nonce, min, max);
    }

    function getRandomColorType() internal returns(uint8) {
        return getRandom8(0, maxCT);
    }


    /**
     * Get random star position
     */
    function getRandomPosition(uint8 gid, uint8 zIndex) internal returns(uint16 box, uint8 inbox) {
        uint16 boxCount = getBoxCountZIndex(zIndex);
        uint16 randBox  = 0;
        if (boxCount == 0) revert();

        uint8 ii   = maxIRandom;
        bool valid = false;
        while (!valid && ii > 0) {
            randBox = getRandom16(0, boxCount);
            valid   = isValidBox(gid, zIndex, randBox);
            ii--;
        }

        if (!valid) revert();
        return(randBox, getRandom8(0, inboxXY));
    }
}


/***********************************************
 ***************
 * Stars general contract
 ***************
 **********************************************/
contract Stars is Control, Validation {
    // Contrac events
    event StarCreated(uint256 starId);
    event StarUpdated(uint256 starId, uint8 reason);
    event StarDeleted(uint256 starId, address owner);
    event StarSold   (uint256 starId, address seller, address buyer, uint256 price);
    event StarGifted (uint256 starId, address sender, address recipient);


    /**
     * Constructor
     */
    function Stars() public {
        // Add star with zero index
        uint256 starId = addStar(address(0), 0, 0, 0, 0, 0, 0, 0);
        setStarNameMessage(starId, "Universe", "Big Bang!");
    }


    /**
     * Create star
     */
    function createStar(uint8 gid, uint16 z, string name, string message) external payable {
        // Check basic requires
        require(isValidGid(gid));
        require(isValidZ(z));
        require(isValidNameLength(name));
        require(isValidMessageLength(message));

        // Get zIndex
        uint8   zIndex    = getZIndex(z);
        uint256 starPrice = getCreatePrice(z, getZCount(gid, zIndex));
        require(isValidMsgValue(starPrice));

        // Create star (need to split method into two because solidity got error - to deep stack)
        uint256 starId = newStar(gid, zIndex, starPrice);
        setStarNameMessage(starId, name, message);

        // Event and returns data
        emit StarCreated(starId);
    }

    function newStar(uint8 gid, uint8 zIndex, uint256 price) private returns(uint256 starId) {
        uint16 box; uint8 inbox;
        uint8   stype  = getRandomColorType();
        uint8   color  = getRandomColorType();
        (box, inbox)   = getRandomPosition(gid, zIndex);
        starId         = addStar(msg.sender, gid, zIndex, box, inbox, stype, color, price);
    }


    /**
     * Update start method
     */
    function updateStar(uint256 starId, string name, string message) external payable {
        // Exists and owned star
        require(starExists(starId));
        require(isStarOwner(starId, msg.sender));

        // Check basic requires
        require(isValidNameLength(name));
        require(isValidMessageLength(message));        

        // Get star update price
        uint256 commission = getCommission(stars[starId].price);
        require(isValidMsgValue(commission));

        // Update star
        setStarNameMessage(starId, name, message);
        emit StarUpdated(starId, 1);
    }    


    /**
     * Delete star
     */
    function deleteStar(uint256 starId) external payable {
        // Exists and owned star
        require(starExists(starId));
        require(isStarOwner(starId, msg.sender));

        // Get star update price
        uint256 commission = getCommission(stars[starId].price);
        require(isValidMsgValue(commission));

        // Update star data
        setStarDeleted(starId);
        emit StarDeleted(starId, msg.sender);
    }    


    /**
     * Set star sell price
     */
    function sellStar(uint256 starId, uint256 sellPrice) external {
        // Exists and owned star
        require(starExists(starId));
        require(isStarOwner(starId, msg.sender));
        require(sellPrice < 10**28);

        // Set star sell price
        setStarSellPrice(starId, sellPrice);
        emit StarUpdated(starId, 2);
    }    


    /**
     * Gift star
     */
    function giftStar(uint256 starId, address recipient) external payable {
        // Check star exists owned
        require(starExists(starId));
        require(recipient != address(0));
        require(isStarOwner(starId, msg.sender));
        require(!isStarOwner(starId, recipient));

        // Get gift commission
        uint256 commission = getCommission(stars[starId].price);
        require(isValidMsgValue(commission));

        // Update star
        setStarNewOwner(starId, recipient);
        setStarSellPrice(starId, 0);
        emit StarGifted(starId, msg.sender, recipient);
        emit StarUpdated(starId, 3);
    }    


    /**
     * Buy star
     */
    function buyStar(uint256 starId, string name, string message) external payable {
        // Exists and NOT owner
        require(starExists(starId));
        require(!isStarOwner(starId, msg.sender));
        require(stars[starId].sell > 0);

        // Get sell commission and check value
        uint256 commission = getCommission(stars[starId].price);
        uint256 starPrice  = stars[starId].sell;
        uint256 totalPrice = starPrice + commission;
        require(isValidMsgValue(totalPrice));

        // Transfer money to seller
        address seller = stars[starId].owner;
        seller.transfer(starPrice);

        // Update star data
        setStarNewOwner(starId, msg.sender);
        setStarSellPrice(starId, 0);
        setStarNameMessage(starId, name, message);
        emit StarSold(starId, seller, msg.sender, starPrice);
        emit StarUpdated(starId, 4);
    }        
}