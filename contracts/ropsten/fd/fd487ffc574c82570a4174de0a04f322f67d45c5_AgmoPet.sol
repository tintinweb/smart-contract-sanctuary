pragma solidity ^0.4.0;

contract AgmoPet {
    address owner;
    uint currentSeason;
    uint globalPetId;
    int distanceTolerance;
    uint expPerScan;
    uint scanResetHour;
    uint levelCap;
    address[] userAddress;
    mapping(uint => string) seasonDescription;
    mapping(address => User) users;
    mapping(uint => Pet) pets;
    mapping(uint => mapping(uint => uint)) matchings; 
    mapping(uint => Coordinate) listeners;
    
    //TODO
    //coins
    mapping(uint => Equipment) gachapons;
    string marketPlaces;
    //trading
    
    struct Coordinate {
        int Latitude;
        int Longitude;
    }
    
    struct Pet{
        mapping(uint => uint) Equipments;
        uint Id;
        uint[] EquipmentList;
        uint Type;
        uint Exp;
        uint Level;
        uint Personality;
        string Name;
        address Owner;
    }
    
    struct User {
        string Name;
        uint[] InventoryList;
        uint[] PetIdList;
        bool Intialized;
    }
    
    struct Equipment {
        uint Id;
        string Name;
        uint Position;
        uint Probability;
    }
    
    constructor() public {
        currentSeason = 1;
        globalPetId = 1;
        distanceTolerance = 5000;
        expPerScan = 5000;
        scanResetHour = 24;
        levelCap = 50;
        seasonDescription[currentSeason] = "Christmas 2018";
        owner = msg.sender;
    }
    
    function addSeason(string _name) public ownerOnly{
        currentSeason++;
        seasonDescription[currentSeason] = _name;
        addSeasonPetForEveryone(currentSeason);
    }
    
    function addSeasonPetForEveryone(uint _seasonId) private {
        for(uint i=0; i < userAddress.length; i++){
            addPet(userAddress[i], _seasonId);
        }
    }
    
    function addPet(address _address, uint _seasonId) private {
        string memory name = strConcat(users[_address].Name, "&#39;s pet");
        users[_address].PetIdList.push(globalPetId);
        pets[globalPetId] = Pet({Type: _seasonId, Exp:1, Level:1, Personality:1, Name: name, EquipmentList : new uint[](0), Id : globalPetId, Owner: _address});
        globalPetId++;
    }
    
    function addNewUser(address _address, string _name) public ownerOnly {
        //Only register if new user
        require(!users[_address].Intialized);
        
        //Start Adding new user
        userAddress.push(_address);
        User memory newUser;
        newUser.Name = _name;
        newUser.Intialized = true;
        users[_address] = newUser;
        
        //Add current season pet for him
        addPet(_address, currentSeason);
    }

    function getCurrentSeason() public view returns (uint, string) {
        return (currentSeason, seasonDescription[currentSeason]);
    }
    
    function getAllSeason() public view returns (string){
        string memory ret = "\x5B";
        
        for (uint i=1; i <= currentSeason; i++) {
            string memory result = strConcat(&#39;{"name": "&#39;, seasonDescription[i] , &#39;","id": "&#39;);
            result = appendUintToString(result, i);
            result = strConcat(result, &#39;"}&#39;);
            if(i != currentSeason){
                result = strConcat(result, ",");
            }
            ret = strConcat(ret, result);
        }
        ret = strConcat(ret, "\x5D");
        return ret;
    }
    
    function updatePet(uint _petId, string _name, uint _personality) public petOwnerOnly(_petId) {
        pets[_petId].Name = _name;
        pets[_petId].Personality = _personality;
    }
    
    function getPets() public userOnly view returns (string){
        User storage user = users[msg.sender];
        
        string memory ret = "\x5B";
        
        for (uint i=0; i < user.PetIdList.length; i++) {
            uint currentPetId = user.PetIdList[i];
            Pet storage userPet = pets[currentPetId];
            string memory result = getPetJson(userPet);
            if(i != user.PetIdList.length - 1){
                result = strConcat(result, ",");
            }
            ret = strConcat(ret, result);
        }
        ret = strConcat(ret, "\x5D");
        return ret;
    }
    
    function getPet(uint _petId) public userOnly view returns (string){
        return getPetJson(pets[_petId]);
    }
    
    function getPetJson(Pet _pet) private pure returns (string) {
        string memory result = strConcat(&#39;{"name": "&#39;, _pet.Name , &#39;","type": "&#39;);
        result = appendUintToString(result, _pet.Type);
        result = strConcat(result, &#39;", "exp" : "&#39;);
        result = appendUintToString(result, _pet.Exp);
        result = strConcat(result, &#39;", "level" : "&#39;);
        result = appendUintToString(result, _pet.Level);
        result = strConcat(result, &#39;", "personality" : "&#39;);
        result = appendUintToString(result, _pet.Personality);
        result = strConcat(result, &#39;", "id" : "&#39;);
        result = appendUintToString(result, _pet.Id);
        result = strConcat(result, &#39;"}&#39;);
        return result;
    }
    
    //Exp needed to level y = x^2 + 100
    function getExpNeededToLevel(uint _level) private pure returns (uint){
        return (_level * _level) + 100;
    }
    
    function listen(uint _petId, int _latitude, int _longitude) public petOwnerOnly(_petId) {
        listeners[_petId] = Coordinate(_latitude, _longitude);
    }
    
    function scan(uint _petId, int _latitude, int _longitude, uint _targetPetId) public petOwnerOnly(_petId) {
        Coordinate memory targetCoordinate = listeners[_targetPetId];
        //Cannot scan self
        require(pets[_targetPetId].Owner != msg.sender);
        //Must be near together
        require(targetCoordinate.Latitude != 0 && targetCoordinate.Longitude != 0);
        require(isNear(_latitude, _longitude, targetCoordinate.Latitude, targetCoordinate.Longitude));
        //Must exceed scanResetHour hours
        uint totalHours = (now - matchings[_petId][_targetPetId]) / 60 / 60;
        require(totalHours > scanResetHour);
        
        //Credit exp
        pets[_petId].Exp = pets[_petId].Exp + expPerScan;
        pets[_targetPetId].Exp = pets[_targetPetId].Exp + expPerScan;
        
        //Levelup if possible
        levelUpPet(pets[_petId]);
        levelUpPet(pets[_targetPetId]);
        
        //Set last scan to now
        matchings[_petId][_targetPetId] = now;
        matchings[_targetPetId][_petId] = now;
    }
    
    function levelUpPet(Pet storage pet) private {
        //TODO need to give extra reward
        if(pet.Level >= levelCap)
            return;
        while(getExpNeededToLevel(pet.Level) < pet.Exp){
            uint expNeeded = getExpNeededToLevel(pet.Level);
            pet.Level++;
            pet.Exp = pet.Exp - expNeeded;
        }
    }
    
    function getLastScanned(uint _petId, uint _targetPetId) public userOnly view returns (uint) {
        return matchings[_petId][_targetPetId];
    }
    
    function setDistanceTolerance(int newTolerance) public ownerOnly {
        distanceTolerance = newTolerance;
    }
    
    function getDistanceTolerance() public ownerOnly view returns (int) {
        return distanceTolerance;
    }
    
    function isNear(int _lat1, int _long1, int _lat2, int _long2) private view returns (bool){
        int latDifference = _lat1 - _lat2;
        if(latDifference < 0){
            latDifference = latDifference * -1;
        }
        int longDifference = _long1 - _long2;
        if(longDifference < 0){
            longDifference = longDifference * -1;
        }
        
        int difference = latDifference + longDifference;
        if(difference < distanceTolerance){
            return true;
        }
        return false;
    }
    
    function setExpPerScan(uint _newExp) public ownerOnly{
        expPerScan = _newExp;
    }
    
    function getExpPerScan() public view returns (uint){
        return expPerScan;
    }
    
    function setLevelCap(uint _newLevelCap) public ownerOnly {
        levelCap = _newLevelCap;
    }
    
    function getLevelCap() public view returns (uint){
        return levelCap;
    }
    
    function setScanResetHour(uint _newScanResetHour) public ownerOnly {
        scanResetHour = _newScanResetHour;
    }
    
    function getScanResetHour() public view returns (uint){
        return scanResetHour;
    }
    
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }
    
    modifier userOnly {
        require(users[msg.sender].Intialized);
        _;
    }
    
    modifier petOwnerOnly(uint _petId) {
        require(users[msg.sender].Intialized);
        require(pets[_petId].Owner == msg.sender);
        _;
    }
    
    //library
    function uintToString(uint v) pure private returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
    }

    function appendUintToString(string inStr, uint v) pure private returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }
    
    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    
    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }
    
    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }
    
    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }
}