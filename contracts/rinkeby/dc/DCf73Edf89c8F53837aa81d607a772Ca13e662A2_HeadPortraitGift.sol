/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: MIT
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

// File: contracts\HeadPortraitGift.sol

pragma solidity ^0.8.0;


interface HeadPortrait721Interface{

    struct Attribute{
        uint16 background;
        uint16 skinColor;
        uint16 clothes0;
        uint16 clothes1;
        uint16 hatBack0;
        uint16 hatBack1;
        uint16 beak0;
        uint16 beak1;
        uint16 hatFront0;
        uint16 hatFront1;
        uint16 eyes0;
        uint16 eyes1;
        uint16 front;
        uint16 reserve1;
        uint16 reserve2;
        uint16 reserve3;
    }
    
    function mint(address user, uint256 tokenId, Attribute memory attribute) external;
}

contract HeadPortraitGift is OwnableContract{

    address public headPortrait721;

    address public signer1;
    address public signer2;

    uint16 public tokenId = 1001;
    
    uint16[] public background;
    uint16[] public clothes;
    uint16[] public hatBack;
    uint16[] public skinColor;
    uint16[] public beak;
    uint16[] public hatFront;
    uint16[] public eyes;
    uint16[] public front;

    bool public isUseTokenIdRandom = false;

    mapping(uint256 => bool) public claimedOrderId;

    // hatBack、hatFront、beak、eyes
    mapping(uint256 => uint16[]) public categoryToNumberMap;

    event Claim(uint256 orderId, uint256 tokenId, address user, address signer);
    event AleadyClaim(uint256 orderId, uint256 tokenId, address user);

    constructor(address _headPortrait721){
        headPortrait721 = _headPortrait721;

        background = [1,2,3,4,5,6,7];
        clothes = [101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,122,123,124,125,126,127,128,129,130,131,132,133,134,135];
        hatBack = [201,202,203];
        skinColor = [301,302,303];
        beak = [401,402,403,404]; // 401 is wheat
        hatFront = [501,502,503,504];
        eyes = [601,602,603,604,605]; // 601 is wear glasses
        front = [701];
    }

    function updateClothes(uint16 number) public onlyAdmin{
        clothes.push(number);
    }

    function updateHatBack(uint16 number) public onlyAdmin{
        hatBack.push(number);
    }

    function updateBeak(uint16 number) public onlyAdmin{
        beak.push(number);
    }

    function updateHatFront(uint16 number) public onlyAdmin{
        hatFront.push(number);
    }

    function updateEyes(uint16 number) public onlyAdmin{
        eyes.push(number);
    }

    function updateCategoryToNumberMap(uint16[] memory number, uint16[] memory array) public onlyAdmin{
        for(uint256 i=0; i<number.length; i++){
            categoryToNumberMap[number[i]] = array;
        }
    }

    function updateIsUseTokenIdRandom(bool _isUseTokenIdRandom) public onlyAdmin{
        isUseTokenIdRandom = _isUseTokenIdRandom;
    }

    function setSigner1(address _signer) public onlyOwner{
        signer1 = _signer;
    }

    function setSigner2(address _signer) public onlyOwner{
        signer2 = _signer;
    }

    function updateHeadPortrait721(address _headPortrait721) public onlyAdmin{
        headPortrait721 = _headPortrait721;
    }

    function getOrderIdIsClaim(uint256[] memory orderId) public view returns(uint256[] memory){
        uint256[] memory unconfirmedOrderId = new uint256[](orderId.length);
        uint256 count = 0;
        for(uint256 i=0; i<orderId.length; i++){
            if(!claimedOrderId[orderId[i]]){
                unconfirmedOrderId[count] = orderId[i];
                count++;
            }
        }
        return unconfirmedOrderId;
    }

    function batchClaim(uint256[] memory orderId, uint256[] memory tokenIds, bytes[] memory signature) public{
        require(orderId.length == tokenIds.length, "orderId length should eq floatAmount length");
        require(orderId.length == signature.length, "orderId length should eq signature length");
        for(uint256 i=0; i<orderId.length; i++){
            if(tokenIds[i] == 0){
                claim(orderId[i], tokenIds[i], signature[i]);
            }else{
                require(0 < tokenIds[i] && tokenIds[i]<= 1000, "tokenIds[i] is error.");
                claimAppointTokenId(orderId[i], tokenIds[i], signature[i]);
            }
        }
    }

    function claim(uint256 orderId, uint256 _tokenId, bytes memory signature) internal{
        if(claimedOrderId[orderId]){
            emit AleadyClaim(orderId, tokenId, msg.sender);
            return;
        }
    
        bytes32 hash1 = keccak256(abi.encode(address(this), msg.sender, orderId, _tokenId));

        bytes32 hash2 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash1));

        address _signer = recover(hash2, signature);
        require(_signer == signer1 || _signer == signer2, "invalid signer");

        HeadPortrait721Interface.Attribute memory attribute = getAttributes(tokenId);
        HeadPortrait721Interface headPortrait721Interface = HeadPortrait721Interface(headPortrait721);
        headPortrait721Interface.mint(msg.sender, tokenId, attribute);

        claimedOrderId[orderId] = true;

        emit Claim(orderId, tokenId, msg.sender, _signer);

        tokenId++;
    }

    function claimAppointTokenId(uint256 orderId, uint256 _tokenId, bytes memory signature) internal{
        if(claimedOrderId[orderId]){
            emit AleadyClaim(orderId, _tokenId, msg.sender);
            return;
        }
    
        bytes32 hash1 = keccak256(abi.encode(address(this), msg.sender, orderId, _tokenId));

        bytes32 hash2 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash1));

        address _signer = recover(hash2, signature);
        require(_signer == signer1 || _signer == signer2, "invalid signer");

        HeadPortrait721Interface.Attribute memory attribute = getAttributes(_tokenId);
        HeadPortrait721Interface headPortrait721Interface = HeadPortrait721Interface(headPortrait721);
        headPortrait721Interface.mint(msg.sender, _tokenId, attribute);

        claimedOrderId[orderId] = true;

        emit Claim(orderId, _tokenId, msg.sender, _signer);
    }

    function claimOfAdmin(address user, uint256 _tokenId) public onlyAdmin{
        require(_tokenId <= 1000, "_tokenId is error.");
        HeadPortrait721Interface.Attribute memory attribute = getAttributes(_tokenId);
        HeadPortrait721Interface headPortrait721Interface = HeadPortrait721Interface(headPortrait721);
        headPortrait721Interface.mint(user, _tokenId, attribute);

        emit Claim(0, tokenId, user, address(0));
    }

    function getAttributes(uint256 _tokenId) public view returns(HeadPortrait721Interface.Attribute memory attribute){
        uint256 random = getRandom(_tokenId);
        uint256 _background = random % 1000;
        if(_background < 10){
            attribute.background = background[6];
        }else if(_background < 60){
            attribute.background = background[4];
        }else if(_background < 160){
            attribute.background = background[2];
        }else if(_background < 310){
            attribute.background = background[3];
        }else if(_background < 540){
            attribute.background = background[5];
        }else if(_background < 770){
            attribute.background = background[0];
        }else if(_background < 1000){
            attribute.background = background[1];
        }

        uint16 _skinColorIndex;
        uint256 _skinColor = random % 100;
        if(_skinColor < 10){
            _skinColorIndex = 3;
            attribute.skinColor = skinColor[2];
        }else if(_skinColor < 40){
            _skinColorIndex = 1;
            attribute.skinColor = skinColor[0];
        }else if(_skinColor < 100){
            _skinColorIndex = 2;
            attribute.skinColor = skinColor[1];
        }

        uint256 _clothes = random % clothes.length;
        attribute.clothes0 = clothes[_clothes];
        attribute.clothes1 = _skinColorIndex;

        uint256 _isHat = random % 1000;
        if(_isHat < 10){
            attribute.front = front[0];
        }else{
            uint256 _hatBack = random % hatBack.length;
            attribute.hatBack0 = hatBack[_hatBack];
            if(_hatBack != 0){
                uint16[] memory hatBackArray = categoryToNumberMap[hatBack[_hatBack]];
                attribute.hatBack1 = hatBackArray[random % hatBackArray.length];
            }

            uint256 _hatFront = random % hatFront.length;
            uint16[] memory hatFrontArray = categoryToNumberMap[hatFront[_hatFront]];
            attribute.hatFront0 = hatFront[_hatFront];
            attribute.hatFront1 = hatFrontArray[random % hatFrontArray.length];
        }

        uint256 _isWheat = random % 10000;
        if(_isWheat < 100){
            uint16[] memory beakArray = categoryToNumberMap[beak[0]];
            attribute.beak0 = beak[0];
            attribute.beak1 = beakArray[random % beakArray.length];
        }else{
            uint256 index = _isWheat / 3300;
            uint16[] memory beakArray = categoryToNumberMap[beak[index + 1]];
            attribute.beak0 = beak[index + 1];
            attribute.beak1 = beakArray[random % beakArray.length];
        }

        uint256 _isWearGlasses = random % 10000;
        if(_isWearGlasses < 100){
            uint16[] memory eyesArray = categoryToNumberMap[eyes[0]];
            attribute.eyes0 = eyes[0];
            attribute.eyes1 = eyesArray[random % eyesArray.length];
        }else{
            uint256 index = _isWearGlasses / 2475;
            uint16[] memory eyesArray = categoryToNumberMap[eyes[index + 1]];
            attribute.eyes0 = eyes[index + 1];
            attribute.eyes1 = eyesArray[random % eyesArray.length];
        }
    }

    function getRandom(uint256 _tokenId) public view returns(uint256){
        uint256 random;
        if(isUseTokenIdRandom){
            random = uint256(keccak256(abi.encodePacked(_tokenId)));
        }else{
            random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.coinbase))) + block.timestamp + _tokenId;
        }
        return random;
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }
}