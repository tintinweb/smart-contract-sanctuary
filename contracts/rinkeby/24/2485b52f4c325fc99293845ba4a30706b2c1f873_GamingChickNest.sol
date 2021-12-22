/**
 *Submitted for verification at Etherscan.io on 2021-12-22
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

// File: contracts\GamingChickNest.sol

pragma solidity ^0.8.0;



interface HeadPortrait721Interface{

    struct Attribute{
        uint32 background;
        uint32 skinColor;
        uint32 clothes;
        uint32 hatBack;
        uint32 beak;
        uint32 hatFront;
        uint32 eyes;
        uint32 front;
        uint256 reserve;
    }
    
    function mint(address user, uint256 tokenId, Attribute memory attribute) external;
}

contract GamingChickNest is OwnableContract{

    using Strings for uint256;

    address public headPortrait721;

    address public signer1;
    address public signer2;

    uint16 public tokenId = 1016;
    
    uint256 public aleadyClaimCount = 0;
    uint256 public maxClaimCount = 20;

    bool public isUseTokenIdRandom = true;

    uint32[] public clothes = [1000100,1000200,1000300,1000400,1000500,1011100,1011200,1011300,1011400,1011500,1012100,1012200,1012300,1012400,1012500,1013100,1013200,1013300,1013400,1013500,1014100,1014200,1014300,1014400,1014500,1015100,1015200,1015300,1015400,1015500,1021100,1021200,1021300,1021400,1021500,1022100,1022200,1022300,1022400,1022500,1023100,1023200,1023300,1023400,1023500,1024100,1024200,1024300,1024400,1024500,1025100,1025200,1025300,1025400,1025500,1031100,1031200,1031300,1031400,1031500,1041100,1041200,1041300,1041400,1041500,1042100,1042200,1042300,1042400,1042500,1043100,1043200,1043300,1043400,1043500,1044100,1044200,1044300,1044400,1044500,1045100,1045200,1045300,1045400,1045500,1051100,1051200,1051300,1051400,1051500,1052100,1052200,1052300,1052400,1052500,1053100,1053200,1053300,1053400,1053500,1054100,1054200,1054300,1054400,1054500,1055100,1055200,1055300,1055400,1055500,1061100,1061200,1061300,1061400,1061500,1062100,1062200,1062300,1062400,1062500,1063100,1063200,1063300,1063400,1063500,1064100,1064200,1064300,1064400,1064500,1065100,1065200,1065300,1065400,1065500,1071100,1071200,1071300,1071400,1071500,1072100,1072200,1072300,1072400,1072500,1073100,1073200,1073300,1073400,1073500,1074100,1074200,1074300,1074400,1074500,1075100,1075200,1075300,1075400,1075500,1081100,1081200,1081300,1081400,1081500,1082100,1082200,1082300,1082400,1082500,1083100,1083200,1083300,1083400,1083500,1084100,1084200,1084300,1084400,1084500,1085100,1085200,1085300,1085400,1085500,1091100,1091200,1091300,1091400,1091500,1092100,1092200,1092300,1092400,1092500,1093100,1093200,1093300,1093400,1093500,1094100,1094200,1094300,1094400,1094500,1095100,1095200,1095300,1095400,1095500,1101100,1101200,1101300,1101400,1101500,1102100,1102200,1102300,1102400,1102500,1103100,1103200,1103300,1103400,1103500,1104100,1104200,1104300,1104400,1104500,1105100,1105200,1105300,1105400,1105500,1111101,1111201,1111301,1111401,1111501,1112101,1112201,1112301,1112401,1112501,1113101,1113201,1113301,1113401,1113501,1114101,1114201,1114301,1114401,1114501,1115101,1115201,1115301,1115401,1115501,1121100,1121200,1121300,1121400,1121500,1122100,1122200,1122300,1122400,1122500,1123100,1123200,1123300,1123400,1123500,1124100,1124200,1124300,1124400,1124500,1125100,1125200,1125300,1125400,1125500,1131100,1131200,1131300,1131400,1131500,1132100,1132200,1132300,1132400,1132500,1133100,1133200,1133300,1133400,1133500,1134100,1134200,1134300,1134400,1134500,1135100,1135200,1135300,1135400,1135500,1141100,1141200,1141300,1141400,1141500,1142100,1142200,1142300,1142400,1142500,1143100,1143200,1143300,1143400,1143500,1144100,1144200,1144300,1144400,1144500,1145100,1145200,1145300,1145400,1145500];

    mapping(uint256 => bool) public claimedOrderId;

    uint8 public partColorCount = 5;
    uint8 public skinColorCount = 5;

    uint32[] public bgs = [1,2,3,4,5,6];

    mapping(uint32 => uint32) public rarityProbabilityTotalMap;
    mapping(uint32 => uint32[]) public rareNumberMap;
    mapping(uint32 => uint32[]) public probabilityMap;

    // ****************** FRONT ******************
    uint32[] public frontArray = [702,703,704,705];
    mapping(uint32 => uint32) public specialFrontMap;
    mapping(uint32 => bool) public skinColorAndPartColorFrontMap;
    // ****************** FRONT END ******************

    // ****************** HAT FRONT ******************
    uint32[] public hatFrontArray = [501,502,503,504,505,506,507,508,509,510,511,512,513];
    mapping(uint32 => bool) public skinColorAndPartColorHatFrontMap;
    // ****************** HAT FRONT END ******************

    // ****************** Head = SkinColor ******************
    uint32[] public skinColorArray = [301];
    // ****************** Head = SkinColor END ******************

    // ****************** BEAK ******************
    uint32[] public beakArray = [401,402,403,404,405,407,410,411,412];
    mapping(uint32 => bool) public isDependentHatFront;
    mapping(uint32 => bool) public skinColorAndPartColorBeakMap;
    // ****************** BEAK END ******************

    // ****************** EYES ******************
    uint32[] public eyesArray = [601,602,603,604,605,606,608,609,610,611,613,614,616,618];
    mapping(uint32 => bool) public skinColorAndPartColorEyesMap;
    // ****************** EYES END ******************

    event Claim(uint256 orderId, uint256 tokenId, address user);
    event AleadyClaim(uint256 orderId, uint256 tokenId, address user);

    constructor(address _headPortrait721){
        headPortrait721 = _headPortrait721;
        signer1 = address(0xd5F6cfca09240650Af7c4E46E7337cDA495fDfd7);
        signer2 = signer1;

        rarityProbabilityTotalMap[0] = 50;
        rarityProbabilityTotalMap[4] = 80;
        rarityProbabilityTotalMap[6] = 100;

        rareNumberMap[0] = [7,8,9,10];
        rareNumberMap[4] = [406,408,409];
        rareNumberMap[6] = [607,612,615,617];

        probabilityMap[0] = [50,200,600,1000];
        probabilityMap[4] = [50,550,1000];
        probabilityMap[6] = [250,450,650,1000];

        specialFrontMap[111] = 701;

        skinColorAndPartColorFrontMap[703] = true;

        skinColorAndPartColorHatFrontMap[510] = true;

        isDependentHatFront[501] = true;
        isDependentHatFront[502] = true;
        isDependentHatFront[503] = true;
        isDependentHatFront[505] = true;
        isDependentHatFront[506] = true;
        isDependentHatFront[508] = true;
        isDependentHatFront[510] = true;
        isDependentHatFront[511] = true;
        isDependentHatFront[512] = true;

        skinColorAndPartColorBeakMap[401] = true;
        skinColorAndPartColorBeakMap[403] = true;
        skinColorAndPartColorBeakMap[404] = true;

        skinColorAndPartColorEyesMap[615] = true;
        skinColorAndPartColorEyesMap[617] = true;
    }

    function updateMaxClaimCount(uint256 _maxClaimCount) public onlyAdmin{
        maxClaimCount = _maxClaimCount;
    }

    function initClothes(uint32[] memory _clothes) public onlyAdmin{
        clothes = _clothes;
    }

    function updateClothes(uint32 _clothes) public onlyAdmin{
        clothes.push(_clothes);
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
        require(aleadyClaimCount + orderId.length <= maxClaimCount, "Maximum claims exceeded.");
        require(orderId.length == tokenIds.length, "orderId length should eq floatAmount length");
        require(orderId.length == signature.length, "orderId length should eq signature length");
        for(uint256 i=0; i<orderId.length; i++){
            claim(orderId[i], tokenIds[i], signature[i]);
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

        uint256 nftTokenId;
        if(_tokenId == 0){
            nftTokenId = tokenId;
            tokenId++;
        }else{
            require(0 < _tokenId && _tokenId <= 1000, "_tokenId is error.");
            nftTokenId = _tokenId;
        }

        HeadPortrait721Interface.Attribute memory attribute = getAttributes(nftTokenId);
        HeadPortrait721Interface headPortrait721Interface = HeadPortrait721Interface(headPortrait721);
        headPortrait721Interface.mint(msg.sender, nftTokenId, attribute);

        claimedOrderId[orderId] = true;

        emit Claim(orderId, nftTokenId, msg.sender);

        aleadyClaimCount++;
    }

    function claimOfAdmin(address user, uint256 _tokenId) public onlyAdmin{
        require(_tokenId <= 1000, "_tokenId is error.");
        HeadPortrait721Interface.Attribute memory attribute = getAttributes(_tokenId);
        HeadPortrait721Interface headPortrait721Interface = HeadPortrait721Interface(headPortrait721);
        headPortrait721Interface.mint(user, _tokenId, attribute);

        emit Claim(0, tokenId, user);
    }

    function updatePartColorCount(uint8 _partColorCount) public onlyAdmin{
        partColorCount = _partColorCount;
    }

    function updateSkinColorCount(uint8 _skinColorCount) public onlyAdmin{
        skinColorCount = _skinColorCount;
    }

    function updateRarityProbabilityTotalMap(uint32 a, uint32 b) public onlyAdmin{
        rarityProbabilityTotalMap[a] = b;
    }

    function updateRareNumberMap(uint32 a, uint32[] memory b) public onlyAdmin{
        rareNumberMap[a] = b;
    }

    function updateProbabilityMap(uint32 a, uint32[] memory b) public onlyAdmin{
        probabilityMap[a] = b;
    }

    function updateArray(uint8 index, uint32[] memory data) public onlyAdmin{
        if(index == 1){
            bgs = data;
        }else if(index == 2){
            frontArray = data;
        }else if(index == 3){
            hatFrontArray = data;
        }else if(index == 4){
            skinColorArray = data;
        }else if(index == 5){
            beakArray = data;
        }else if(index == 6){
            eyesArray = data;
        }
    }

    function updateSpecialFrontMap(uint32 a, uint32 b) public onlyAdmin{
        specialFrontMap[a] = b;
    }

    function updateMap(uint8 index, uint32 a, bool b) public onlyAdmin{
        if(index == 1){
            skinColorAndPartColorFrontMap[a] = b;
        }else if(index == 2){
            skinColorAndPartColorHatFrontMap[a] = b;
        }else if(index == 3){
            isDependentHatFront[a] = b;
        }else if(index == 4){
            skinColorAndPartColorBeakMap[a] = b;
        }else if(index == 5){
            skinColorAndPartColorEyesMap[a] = b;
        }
    }

    function getAttributes(uint256 _tokenId) public view returns(HeadPortrait721Interface.Attribute memory attribute){
        uint256 random = getRandom(_tokenId);

        // background
        uint256 backgroundRarity = rarityProbabilityTotalMap[0];
        random = uint256(keccak256(abi.encode(random, 1)));
        uint256 bgsRandom = random % 1000;
        if(backgroundRarity != 0 && bgsRandom < backgroundRarity){
            random = uint256(keccak256(abi.encode(random, 2)));
            uint256 bgsIndex2 = random % 1000;
            for(uint256 i=0; i<probabilityMap[0].length; i++){
                if(bgsIndex2 < probabilityMap[0][i]){
                    attribute.background = rareNumberMap[0][i];
                    break;
                }
            }
        }else{
            random = uint256(keccak256(abi.encode(random, 3)));
            uint256 bgsIndex2 = random % bgs.length;
            attribute.background = bgs[uint32(bgsIndex2)];
        }

        // Clothes = Body
        random = uint256(keccak256(abi.encode(random, 4)));
        uint256 clothesIndex = random % clothes.length;
        uint32 _clothes = clothes[uint32(clothesIndex)];
        attribute.clothes = _clothes;

        // 1113501 desc
        uint32 one = _clothes % 10;                 // 1 hatFront、hatBack || Front
        uint32 three = _clothes / 100 % 10;         // 5 head = skincolor
        uint32 four = _clothes / 1000 % 10;         // 3 part color

        // Head = SkinColor
        random = uint256(keccak256(abi.encode(random, 11)));
        attribute.skinColor = skinColorArray[uint32(random % skinColorArray.length)] * 10000 + three * 100;

        if(one == 0){
            random = uint256(keccak256(abi.encode(random, 5)));
            uint256 frontOrHatFront = random % 2;
            if(frontOrHatFront == 0){ // FRONT
                random = uint256(keccak256(abi.encode(random, 6)));
                if(skinColorAndPartColorFrontMap[frontArray[random % frontArray.length]]){
                    attribute.front = frontArray[uint32(random % frontArray.length)] * 100000 + uint32(random % partColorCount + 1) * 10000 + three * 1000;
                }else{
                    attribute.front = frontArray[uint32(random % frontArray.length)] * 100000 + uint32(random % partColorCount + 1) * 10000;
                }
            }else{ // HATFRONT
                random = uint256(keccak256(abi.encode(random, 8)));
                uint256 hatFrontIndex = random % hatFrontArray.length;
                random = uint256(keccak256(abi.encode(random, 9)));
                uint256 partIndex = random % partColorCount + 1;
                if(skinColorAndPartColorHatFrontMap[hatFrontArray[hatFrontIndex]]){
                    random = uint256(keccak256(abi.encode(random, 10)));
                    uint256 skinIndex = random % skinColorCount + 1;
                    attribute.hatFront = hatFrontArray[uint32(hatFrontIndex)] * 10000 + uint32(partIndex) * 1000 + uint32(skinIndex) * 100;
                }else{
                    attribute.hatFront = hatFrontArray[uint32(hatFrontIndex)] * 10000 + uint32(partIndex) * 100;
                }
                // 501
                uint32 _one = hatFrontArray[hatFrontIndex] % 10;         // 1   
                uint32 _two = hatFrontArray[hatFrontIndex] / 10 % 10;    // 0
                attribute.hatBack = 2 * 1000000 + _two * 100000 + _one * 10000 + uint32(partIndex) * 1000;
            }
        }else{
            uint32 _key = (_clothes / 1000000 % 10) * 100 + (_clothes / 100000 % 10) * 10 + (_clothes / 10000 % 10);
            if(specialFrontMap[_key] != 0){
                attribute.front = specialFrontMap[_key] * 100000 + four * 10000 + _key;
            }else{
                random = uint256(keccak256(abi.encode(random, 6)));
                uint256 frontIndex = random % frontArray.length;
                random = uint256(keccak256(abi.encode(random, 7)));
                uint256 partIndex = random % partColorCount + 1;
                if(skinColorAndPartColorFrontMap[frontArray[frontIndex]]){
                    attribute.front = frontArray[uint32(frontIndex)] * 100000 + uint32(partIndex) * 10000 + three * 1000;
                }else{
                    attribute.front = frontArray[uint32(frontIndex)] * 100000 + uint32(partIndex) * 10000;
                }
            }
        }
        // BEAK
        uint32 key = (attribute.hatFront / 1000000 % 10) * 100 + (attribute.hatFront / 100000 % 10) * 10 + (attribute.hatFront / 10000 % 10);
        uint32 hatFrontLastThird = attribute.hatFront / 100 % 10;

        uint256 beakRarity = rarityProbabilityTotalMap[4];
        random = uint256(keccak256(abi.encode(random, 12)));
        if(beakRarity != 0 && (random % 1000) < backgroundRarity){
            random = uint256(keccak256(abi.encode(random, 13)));
            uint32 beakTopThree = 0;
            for(uint256 i=0; i<probabilityMap[4].length; i++){
                if((random % 1000) < probabilityMap[4][i]){
                    beakTopThree = rareNumberMap[4][i];
                    break;
                }
            }
            if(skinColorAndPartColorBeakMap[beakTopThree]){
                if(attribute.hatFront != 0 && isDependentHatFront[key]){
                    attribute.beak = beakTopThree * 10000 + hatFrontLastThird * 1000 + three * 100;
                }else{
                    random = uint256(keccak256(abi.encode(random, 14)));
                    attribute.beak = beakTopThree * 10000 + uint32(random % partColorCount + 1) * 1000 + three * 100;
                }
            }else{
                if(attribute.hatFront != 0 && isDependentHatFront[key]){
                    attribute.beak = beakTopThree * 10000 + hatFrontLastThird * 1000;
                }else{
                    random = uint256(keccak256(abi.encode(random, 14)));
                    attribute.beak = beakTopThree * 10000 + uint32(random % partColorCount + 1) * 1000;
                }
            }
        }else{
            random = uint256(keccak256(abi.encode(random, 15)));
            uint32 beakNumber = beakArray[uint32(random % beakArray.length)];
            if(skinColorAndPartColorBeakMap[beakNumber]){
                if(attribute.hatFront != 0 && isDependentHatFront[key]){
                    attribute.beak = beakNumber * 10000 + hatFrontLastThird * 1000 + three * 100;
                }else{
                    random = uint256(keccak256(abi.encode(random, 16)));
                    attribute.beak = beakNumber * 10000 + uint32(random % partColorCount + 1) * 1000 + three * 100;
                }
            }else{
                if(attribute.hatFront != 0 && isDependentHatFront[key]){
                    attribute.beak = beakNumber * 10000 + hatFrontLastThird * 1000;
                }else{
                    random = uint256(keccak256(abi.encode(random, 16)));
                    attribute.beak = beakNumber * 10000 + uint32(random % partColorCount + 1) * 1000;
                }
            }
        }
        // EYES
        uint256 eyesRarity = rarityProbabilityTotalMap[6];
        random = uint256(keccak256(abi.encode(random, 17)));
        if(eyesRarity != 0 && (random % 1000) < backgroundRarity){
            random = uint256(keccak256(abi.encode(random, 18)));
            uint32 eyesTopThree = 0;
            for(uint256 i=0; i<probabilityMap[6].length; i++){
                if((random % 1000) < probabilityMap[6][i]){
                    eyesTopThree = rareNumberMap[6][i];
                    break;
                }
            }
            if(skinColorAndPartColorEyesMap[eyesTopThree]){
                random = uint256(keccak256(abi.encode(random, 19)));
                attribute.eyes = uint32(eyesTopThree) * 10000 + uint32(random % partColorCount + 1) * 1000 + three * 100;
            }else{
                attribute.eyes = uint32(eyesTopThree) * 10000 + three * 100;
            }
        }else{
            random = uint256(keccak256(abi.encode(random, 20)));
            uint256 eyesIndex = random % eyesArray.length;
            if(skinColorAndPartColorEyesMap[eyesArray[uint32(eyesIndex)]]){
                random = uint256(keccak256(abi.encode(random, 21)));
                attribute.eyes = eyesArray[uint32(eyesIndex)] * 10000 + uint32(random % partColorCount + 1) * 1000 + three * 100;
            }else{
                attribute.eyes = eyesArray[uint32(eyesIndex)] * 10000 + three * 100;
            }
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