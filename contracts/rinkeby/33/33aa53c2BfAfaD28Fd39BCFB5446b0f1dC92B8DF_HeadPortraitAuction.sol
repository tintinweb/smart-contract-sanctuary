/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// File: @openzeppelin\contracts\utils\Strings.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin\contracts\security\ReentrancyGuard.sol

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts\OwnableContract.sol

pragma solidity ^0.8.0;

contract OwnableContract {
    address public owner;
    address public pendingOwner;
    address public admin;
    address public dev;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewDev(address oldDev, address newDev);
    event NewOwner(address oldOwner, address newOwner);
    event NewPendingOwner(address oldPendingOwner, address newPendingOwner);

    constructor(){
        owner = msg.sender;
        admin = msg.sender;
        dev   = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"onlyOwner");
        _;
    }

    modifier onlyPendingOwner {
        require(msg.sender == pendingOwner,"onlyPendingOwner");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner,"onlyAdmin");
        _;
    } 

    modifier onlyDev {
        require(msg.sender == dev  || msg.sender == owner,"onlyDev");
        _;
    } 
    
    function transferOwnership(address _pendingOwner) public onlyOwner {
        emit NewPendingOwner(pendingOwner, _pendingOwner);
        pendingOwner = _pendingOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit NewOwner(owner, address(0));
        emit NewAdmin(admin, address(0));
        emit NewPendingOwner(pendingOwner, address(0));

        owner = address(0);
        pendingOwner = address(0);
        admin = address(0);
    }
    
    function acceptOwner() public onlyPendingOwner {
        emit NewOwner(owner, pendingOwner);
        owner = pendingOwner;

        address newPendingOwner = address(0);
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }    
    
    function setAdmin(address newAdmin) public onlyOwner {
        emit NewAdmin(admin, newAdmin);
        admin = newAdmin;
    }

    function setDev(address newDev) public onlyOwner {
        emit NewDev(dev, newDev);
        dev = newDev;
    }

}

// File: contracts\HeadPortraitAuction.sol

pragma solidity ^0.8.0;




interface HeadPortraitNFTInterface{
    function mint() external;
    function totalSupply() external returns(uint256);
}

contract HeadPortraitAuction is OwnableContract, ReentrancyGuard{

    using Strings for uint256;

    bool public buySwitch = false;

    uint256 public startTime;

    uint256 public endTime;

    uint256 public mintNftPerUser = 2;

    uint256 public typesUser = 3;

    address public headPortraitNFT721;

    mapping(uint256 => uint256) public nftPricePerMap;

    mapping(uint256 => uint256) public nftNumPerMap;

    mapping(uint256 => uint256) public aleadyMintNftNumPerMap;

    mapping(address => uint256) public userBuyNftCountPer;

    mapping(uint256 => mapping(address => bool)) public addressBelongWhichTypeMap;

    constructor(address _headPortraitNFT721){
        nftPricePerMap[0] = 0;          // appoint user
        nftPricePerMap[1] = 0.02 ether; // whitelist user
        nftPricePerMap[2] = 0.08 ether; // ordinary user

        nftNumPerMap[0] = 50;  // appoint user
        nftNumPerMap[1] = 150; // whitelist user
        nftNumPerMap[2] = 800; // ordinary user

        headPortraitNFT721 = _headPortraitNFT721;
    }

    function getAddressBelongWhichTypeIndex(address userAddr) internal view returns(uint256){
        uint256 index = 2;
        for(uint256 i=0; i<typesUser; i++){
            if(addressBelongWhichTypeMap[i][userAddr]){
                index = i;
            }
        }
        return index;
    }

    function getMaxTotalSupply() public view returns(uint256){
        uint256 maxTotalSupply = 0;
        for(uint256 i=0; i<typesUser; i++){
            maxTotalSupply += nftNumPerMap[i];
        }
        return maxTotalSupply;
    }

    function getRemainingNftQuantity() public returns(uint256){
        HeadPortraitNFTInterface headPortraitNFTInterface = HeadPortraitNFTInterface(headPortraitNFT721);
        return getMaxTotalSupply() - headPortraitNFTInterface.totalSupply();
    }

    function getDifferentAddressPrice(address userAddr) public view returns(uint256){
        return nftPricePerMap[getAddressBelongWhichTypeIndex(userAddr)];
    }

    function getRemainingBuyNftCountPerUser(address userAddr) public view returns(uint256){
        return mintNftPerUser - userBuyNftCountPer[userAddr];
    }

    function updateHeadPortraitNFT721(address _headPortraitNFT721) public onlyAdmin{
        headPortraitNFT721 = _headPortraitNFT721;
    }

    function updateBuySwitch(bool _buySwitch) public onlyAdmin{
        buySwitch = _buySwitch;
    }

    function updateStartAndEndTime(uint256 _startTime, uint256 _endTime) public onlyAdmin{
        startTime = _startTime;
        endTime = _endTime;
    }

    function updateMintNftPerUser(uint256 _mintNftPerUser) public onlyAdmin{
        mintNftPerUser = _mintNftPerUser;
    }

    function updateAddressBelongWhichTypeMap(uint256 index, address userAddr, bool isAddressExist) public onlyAdmin{
        addressBelongWhichTypeMap[index][userAddr] = isAddressExist;
    }

    function addUserCategoryAndSetUpPriceAndAmount(uint256 price, uint256 amount) public onlyAdmin{
        typesUser++;
        nftPricePerMap[typesUser] = price;
        nftNumPerMap[typesUser] = amount;
    }

    function buy(uint256 amount) public payable nonReentrant{
        require(buySwitch, "buySwitch is false.");
        require(startTime <= block.timestamp && block.timestamp <= endTime, "not within the purchase time.");
        HeadPortraitNFTInterface headPortraitNFTInterface = HeadPortraitNFTInterface(headPortraitNFT721);
        require(headPortraitNFTInterface.totalSupply() < getMaxTotalSupply(), "out if stock.");
        uint256 index = getAddressBelongWhichTypeIndex(msg.sender);
        require(aleadyMintNftNumPerMap[index] <= nftNumPerMap[index], "the inventory of this category is insufficient.");
        require(amount <= mintNftPerUser, "upper limit exceeded.");
        require(userBuyNftCountPer[msg.sender] + amount <= mintNftPerUser, "each user can mint at most two.");
        require(nftPricePerMap[index] <= msg.value, "insufficient eth.");

        aleadyMintNftNumPerMap[index] += amount;
        userBuyNftCountPer[msg.sender] += amount;

        for(uint256 i=0; i<amount; i++){
            headPortraitNFTInterface.mint();
        }
    }

    function withdraw(address to) public onlyOwner{
        payable((to)).transfer(address(this).balance);
    }
}