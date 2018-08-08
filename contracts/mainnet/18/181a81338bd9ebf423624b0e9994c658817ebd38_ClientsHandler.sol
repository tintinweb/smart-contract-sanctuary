pragma solidity ^0.4.21;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/** @dev contract extended Ownable */
contract ManageableContract is Ownable {

    mapping (address => bool) internal pf_manager; // SP maganer, Artificial Intelligence AI in the fuature
    uint256[] internal pf_m_count; // clients tasks counter

    mapping (address => bool) internal performers;
    uint256[] internal pf_count; // clients tasks counter

    mapping (address => bool) internal cr_manager; // client relations manager CR-Manager
    uint256[] internal cr_count; // clients tasks counter

    mapping (address => bool) internal clients;
    uint256[] internal cli_count; // clients tasks counter

    // MODIFIERS
    modifier is_cli() {
        require(clients[msg.sender] == true);
        _;
    }

    modifier is_no_cli() {
        require(clients[msg.sender] != true);
        _;
    }

    modifier is_cr_mng() {
        require(cr_manager[msg.sender] == true);
        _;
    }

    modifier is_pfm() {
        require(performers[msg.sender] == true);
        _;
    }

    modifier is_pf_mng() {
        require(pf_manager[msg.sender] == true);
        _;
    }

    modifier is_cli_trust() {
        require(
            owner == msg.sender            ||
            cr_manager[msg.sender] == true
            );
        _;
    }

    modifier is_cli_or_trust() {
        require(
            clients[msg.sender] == true    ||
            owner == msg.sender            ||
            cr_manager[msg.sender] == true ||
            performers[msg.sender] == true ||
            pf_manager[msg.sender] == true
            );
        _;
    }

    modifier is_trust() {
        require(
            owner == msg.sender            ||
            cr_manager[msg.sender] == true ||
            performers[msg.sender] == true ||
            pf_manager[msg.sender] == true
            );
        _;
    }

    function setPFManager(address _manager) public onlyOwner
        returns (bool, address)
    {
        pf_manager[_manager] = true;
        pf_m_count.push(1);
        return (true, _manager);
    }

    function setPerformer(address _to) public onlyOwner
        returns (bool, address)
    {
        performers[_to] = true;
        pf_count.push(1);
        return (true, _to);
    }

    function setCRManager(address _manager) public onlyOwner
        returns (bool, address)
    {
        cr_manager[_manager] = true;
        cr_count.push(1);
        return (true, _manager);
    }

    /** get client task length */
    function countPerformers() public view returns (uint256) {
        return pf_m_count.length;
    }

    /** get client task length */
    function countPerfManagers() public view returns (uint256) {
        return pf_count.length;
    }

    /** get client task length */
    function countCliManagers() public view returns (uint256) {
        return cr_count.length;
    }

    /** get client task length */
    function countClients() public view returns (uint256) {
        return cli_count.length;
    }
}

/** @dev contact types transform */
contract Converter {

        function bytes32ToBytes(bytes32 data) internal pure returns (bytes) {
        uint i = 0;
        while (i < 32 && uint(data[i]) != 0) {
            ++i;
        }
        bytes memory result = new bytes(i);
        i = 0;
        while (i < 32 && data[i] != 0) {
            result[i] = data[i];
            ++i;
        }
        return result;
    }

    /** @dev concat bytes array */
    function bytes32ArrayToString(bytes32[] data) internal pure returns (string) {
        bytes memory bytesString = new bytes(data.length * 32);
        uint urlLength;
        for (uint i=0; i<data.length; i++) {
            for (uint j=0; j<32; j++) {
                byte char = byte(bytes32(uint(data[i]) * 2 ** (8 * j)));
                if (char != 0) {
                    bytesString[urlLength] = char;
                    urlLength += 1;
                }
            }
        }
        bytes memory bytesStringTrimmed = new bytes(urlLength);
        for (i=0; i<urlLength; i++) {
            bytesStringTrimmed[i] = bytesString[i];
        }
        return string(bytesStringTrimmed);
    }


    function uintToBytes(uint v) internal pure returns (bytes32 ret) {
        if (v == 0) {
            ret = &#39;0&#39;;
        }
        else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function addressToBytes(address a) internal pure returns (bytes32 b){
       assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
       }
    }

    function bytesToBytes32(bytes b, uint offset) internal pure returns (bytes32) {
      bytes32 out;

      for (uint i = 0; i < 32; i++) {
        out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
      }
      return out;
    }

    function bytes32ToString(bytes32 x) internal pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

/** contract for deploy */
contract ClientsHandler is ManageableContract, Converter {

    function ClientsHandler() public {
        setPFManager(owner);
        setCRManager(owner);
    }

    string name = "Clients Handler";
    string descibe = "Clients data storage, contain methods for their obtaining and auditing";
    string version = "0.29";

    // @dev defaul validtor values
    uint256 dml = 3;
    uint256 dmxl = 100;
    uint256 tml = 3;
    uint256 tmxl = 1000;

    struct DreamStructData {
        string  hashId;
        string  dream;
        string  target;
        bool    isDream;
        bool    hasPerformer;
        address performer;

    }

    struct DreamStruct {
        bool      isClient;
        uint256[] key;

    }

    mapping(address => mapping(uint256 => DreamStructData)) internal DSData;
    mapping(address => DreamStruct) internal DStructs;
    address[] public clientsList; //count users

    struct DreamStructDataP {
        bool    isValid;
        address client;
        uint256 client_id;
    }

    struct DreamStructP {
        bool      isPerformer;
        uint256[] key;
    }

    mapping(address => mapping(uint256 => DreamStructDataP)) internal DSDataP;
    mapping(address => DreamStructP) internal DStructsP;
    address[] public performerList; //count users

    function watchPreferersTasks(address entityAddress, uint256 _id) public view {
        DSDataP[entityAddress][_id];
    }

    /** @dev return data of client&#39;s dream by id */
    function getDStructData(address _who, uint256 _dream_id)
        public
        view
        is_cli_or_trust
        returns(string, string)
    {
        require(DSData[_who][_dream_id].isDream == true);
        return (
            DSData[_who][_dream_id].dream,
            DSData[_who][_dream_id].target
        );
    }

    function isClient(address entityAddress) public constant returns(bool isIndeed) {
        return DStructs[entityAddress].isClient;
    }

    function countClients() public constant returns(uint256 cCount) {
        return clientsList.length;
    }

    function countAllCliDrm() public constant returns(uint256 acdCount) {
        uint256 l = countClients();
        uint256 r = 0;
        for(uint256 i=0; i<l; i++) {
            r += countCliDreams(clientsList[i]);
        }
        return r;
    }

    function countCliDreams(address _addr) public view returns(uint256 cdCount) {
        return DStructs[_addr].key.length;
    }

    function countPerfClients(address _addr) public view returns(uint256 cdpCount) {
        return DStructsP[_addr].key.length;
    }

    function findAllCliWithPendingTask() public returns(address[] noPerform) {

        uint256 l = countClients();
        address[] storage r;
        for(uint256 i=0; i<l; i++) {
            uint256 ll = countCliDreams(clientsList[i]);
            for(uint256 ii=0; ii<ll; ii++) {
                uint256 li = ii + 1;
                if(DSData[clientsList[i]][li].hasPerformer == false) {
                    r.push(clientsList[i]);
                }
            }
        }
        return r;
    }

    /** @dev by the address of client set performer for pending task */
    function findCliPendTAndSetPrfm(address _addr, address _performer) public returns(uint256) {

        uint256 l = countCliDreams(_addr);
        for(uint256 i=0; i<l; i++) {
            uint256 li = i + 1;
            if(DSData[_addr][li].hasPerformer == false) {
                DSData[_addr][li].hasPerformer = true;
                DSData[_addr][li].performer = _performer;

                uint256 pLen = countPerfClients(_performer);
                uint256 iLen = pLen + 1;
                DSDataP[_performer][iLen].client = _addr;
                DSDataP[_performer][iLen].client_id = li;
                DSDataP[_performer][iLen].isValid = true;
                return performerList.push(_addr);
            }
        }
    }

    /** @dev change perferfer for uncomplited task if he is fail */
    function changePrefererForTask(address _addr, uint256 _id, address _performer) public is_pf_mng returns(bool) {
        require(performers[_performer] == true);
        if(DSData[_addr][_id].isDream == true) {
            DSData[_addr][_id].hasPerformer = true;
            DSData[_addr][_id].performer = _performer;
            return true;
        }
    }

    function setValidatorForND(
        uint256 dream_min_len,
        uint256 target_min_len,
        uint256 dream_max_len,
        uint256 target_max_len
    )
        public
        onlyOwner
        returns (bool)
    {
        dml  = dream_min_len;
        dmxl = dream_max_len;
        tml  = target_min_len;
        tmxl = target_max_len;
        return true;
    }

    modifier validatorD(string dream, string target) {
        require(
            (bytes(dream).length  >  dml)  &&
            (bytes(dream).length  <= dmxl) &&
            (bytes(target).length >  tml)  &&
            (bytes(target).length <= tmxl)
        );
        _;
    }

    /** @dev allow for all who want stand client */
    function newDream(address entityAddress, string dream, string target)
        public
        validatorD(dream, target)
        returns (uint256 rowNumber)
    {
        clients[entityAddress] = true;
        DStructs[entityAddress].key.push(1);
        DStructs[entityAddress].isClient = true;
        uint256 cliLen = countCliDreams(entityAddress);
        uint256 incLen = cliLen + 1;
        DSData[entityAddress][incLen].dream = dream;
        DSData[entityAddress][incLen].target = target;
        DSData[entityAddress][incLen].isDream = true;
        return clientsList.push(entityAddress);
    }

    /** @dev allow for all who want stand client */
    function updateDream(address entityAddress, string dream, string target)
        public
        is_cli_trust
        validatorD(dream, target)
        returns (bool success)
    {
        //DStructs[entityAddress].key.push(1);
        uint256 cliLen = countCliDreams(entityAddress);
        uint256 incLen = cliLen + 1;
        DSData[entityAddress][incLen].dream = dream;
        DSData[entityAddress][incLen].target = target;
        DSData[entityAddress][incLen].isDream = true;
        return true;
    }
}