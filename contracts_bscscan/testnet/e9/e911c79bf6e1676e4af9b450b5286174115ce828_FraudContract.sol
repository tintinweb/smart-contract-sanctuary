/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

pragma solidity ^0.7.6;

contract FraudContract{


    mapping(address => mapping(bytes32 => bytes32)) private fraudlist;
    mapping(uint256 => address) private operator_list;
    mapping(address => uint8) private registered_parties;

    event LogEvent(address indexed msgSenderAddr,string message,string tckn);
    event RegisterEvent(bool message, address indexed from);

    uint8 private total_parties;
    uint256 private party_index;

    constructor() public {
        total_parties = 3;
        party_index = 0;
    }

    // Party Registration
    function registerPartner() public {
        require(party_index <= total_parties, "There is no room");
        address caller = msg.sender;
        if(registered_parties[caller] == 0){
            operator_list[party_index++] = caller;
            registered_parties[caller] = 1;
            emit RegisterEvent(true, caller);
        }
        else{
            emit RegisterEvent(false, caller);
        }
    }

    function isRegistered() public view returns(bool) {
        return registered_parties[msg.sender] != 0;
    }

    // Befor the update uperation, check the record pointer
    function isValidFraudRecord(bytes32 _key) public view returns(bool) {
        return fraudlist[msg.sender][_key] != 0;
    }
 

    function setTCKN(bytes32 _hashed_tckn, bytes32 _info) public  {
        require(isRegistered(), "Party is not registered");
        // each party sets own data
        fraudlist[msg.sender][_hashed_tckn] = _info;

    }

    function getTCKN(string memory _tckn) public view returns(address[] memory, bytes32[] memory){
        require(isRegistered(), "Party is not registered");

            address[] memory parties = new address[](total_parties);
            bytes32[] memory info = new bytes32[](total_parties);
            
	        bytes32  key = stringToBytes32(_tckn);
            for(uint8 pIndex = 0; pIndex < total_parties; pIndex++){
                
                if(fraudlist[operator_list[pIndex]][key] != 0){
                    //return result array
                    parties[pIndex] = operator_list[pIndex];
                    //return bytes32 must convert to string in DAP
                    info[pIndex] = fraudlist[operator_list[pIndex]][key];
                }
            }

            return (parties, info);
       
    }

    function getInfoString(string memory _tckn) public view returns(string memory){
        string memory infoString = "";
        (, bytes32[] memory info) = getTCKN(_tckn);
        for(uint8 pIndex = 0; pIndex < total_parties; pIndex++){
            infoString = append(infoString, bytes32ToString(info[pIndex]), ",");
        }
        return infoString;
    }

    function getAddresses() public view returns(address[] memory) {
        address[] memory parties = new address[](total_parties); //party count will parametric
        for(uint8 pIndex = 0; pIndex < total_parties; pIndex++){
            parties[pIndex] = operator_list[pIndex];
        }
        return parties;
    }

    function update(bytes32 _key, bytes32 _info) public  {
        require(isValidFraudRecord(_key), "No data found !");
        fraudlist[msg.sender][_key] = _info;
        emit LogEvent(msg.sender,"Update fraud data for ",bytes32ToString(_key));
    }
    
    function remove (bytes32 _tckn) public {
        delete fraudlist[msg.sender][_tckn];
        emit LogEvent(msg.sender,"Update fraud data for ", bytes32ToString(_tckn));
  
    }
     
    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    function bytes32ToString(bytes32 x) public pure returns (string memory) {
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
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
        return result;
    }
}