// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./ChainlinkClient.sol";
import "./Ownable.sol";
import "./Median.sol";

contract SatDetails is ChainlinkClient, Ownable {
  uint256 constant private ORACLE_PAYMENT = 1 * LINK;

  /*
    Structures and mapping related to the final information preserved
  */
  struct satDetailsStruct{
      bytes12 name; // Maximum 12 characters
      bytes4 nationality; // 4 bytes <==> 4 letters per country max
      uint32 apogee; // apogee in meters
      uint32 perigee; // perigee in meters
      uint32 inclination; // inclination * 1000
      uint32 launchDate; // Number of seconds since 4 octobre 1957 00:00 am (launch day of Sputnik 1)
  }

  // mapping (bytes12 => uint256) satNameToId;
  
  mapping (uint256 => satDetailsStruct) satDetailsMapping;
  
  
  /*
    Information related to the consensus
  */
  
  struct occurenceStruct{
      mapping (bytes4 => uint8) nationalityOcc;
      mapping (bytes12 => uint8) nameOcc;
      uint32[] apogeeOcc;
      uint32[] perigeeOcc;
      uint32[] inclinationOcc;
      uint32[] launchDateOcc;
      // Needed to track who answered to not let him submit multiple times
      mapping (address => bool) participants;
  }
  
  // maps sat id to the occurences
  mapping (uint256 => occurenceStruct) satOccurenceMapping;
  
  // maps requestId to the satId
  mapping (bytes32 => uint256) requestSatIdMapping;
  

  constructor() public Ownable() {
    setPublicChainlinkToken();
  }

// block.number
  
  
  /* TO BE COMPLETED  */
  
  function requestSatDetails(address _oracle, string memory _jobId, uint _satId) public onlyOwner
  {

    /*  
        Should add a line to specify the amount of replies
        Should add a line to delete request after a time period
    */
    string memory satId = uint2str(_satId);
    Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), address(this), this.fulfillSatDetails.selector);
    req.add("satId", satId);
    bytes32 requestId = sendChainlinkRequestTo(_oracle, req, ORACLE_PAYMENT);
    requestSatIdMapping[requestId] = _satId;
  }  
  
  
  function fulfillSatDetails(bytes32 _requestId, uint _data) public recordChainlinkFulfillment(_requestId)
  {
    
    uint _satId = requestSatIdMapping[_requestId];
    
    // Checking if address already answered
    // require(satOccurenceMapping[_satId].participants[msg.sender]==false, "Oracle already answered");
    
    // Unpacking variables
    (bytes4 _nationality, bytes12 _name, uint32 _apogee, uint32 _perigee, uint32 _inclination, uint32 _launchDate) = decodeInput(_data);
    
    satOccurenceMapping[_satId].participants[msg.sender]=true;
    
    /* Updating relative fields */
    
    // Updating the occurences of details
    satOccurenceMapping[_satId].nationalityOcc[_nationality] += 1;
    satOccurenceMapping[_satId].nameOcc[_name] += 1;
    
    satOccurenceMapping[_satId].apogeeOcc.push(_apogee);
    satOccurenceMapping[_satId].perigeeOcc.push(_perigee);
    satOccurenceMapping[_satId].inclinationOcc.push(_inclination);
    satOccurenceMapping[_satId].launchDateOcc.push(_launchDate);
    
    // Doing consensus on the values emitted
    consensusSatDetails(_satId, _nationality, _name);
    
    // emit RequestSatNameFulfilled(_requestId, convertedString);
  }
  
 
  
  function decodeInput(uint _data) pure internal returns (bytes4 _nationality, bytes12 _name, uint32 _apogee, uint32 _perigee, uint32 _inclination, uint32 _launchDate) {
        
        // Declarations of (_satId, _nationality ...) were made in the return  
        assembly {
        /* Old values */
        //   _satId := sar(224, _data)
        //   _nationality := add(0x0, shl(32, _data))
        //   _apogee := sar(160, _data)
        //   _perigee := sar(128, _data)
        //   _inclination := sar(96, _data)
        
        _nationality := add(0x0, _data)
        _name := add(0x0, shl(32, _data))
        _apogee := sar(96, _data)
        _perigee := sar(64, _data)
        _inclination := sar(32, _data)
        // Number of seconds since 4 octobre 1957 00:00 am (launch day of Sputnik 1)
        _launchDate := sar(0, _data)
        
        }
      
  }
  
  /*  TO BE COMPLETED */
  
  function consensusSatDetails(uint256 _satId, bytes4 _nationality, bytes12 _name) internal {
      // Checking if number of replies is sufficient
      if (satOccurenceMapping[_satId].apogeeOcc.length >= 3){
        satDetailsMapping[_satId].apogee = Median.calculateInplace(satOccurenceMapping[_satId].apogeeOcc);
        satDetailsMapping[_satId].perigee = Median.calculateInplace(satOccurenceMapping[_satId].perigeeOcc);
        satDetailsMapping[_satId].inclination = Median.calculateInplace(satOccurenceMapping[_satId].inclinationOcc);
        satDetailsMapping[_satId].launchDate = Median.calculateInplace(satOccurenceMapping[_satId].launchDateOcc);
        
        
      // Update nationality only if enough addresses agree on the same one
      if(satOccurenceMapping[_satId].nationalityOcc[_nationality] >= 3 /* && satDetailsMapping[_satId].nationality == "" */){
         satDetailsMapping[_satId].nationality = _nationality;
      }
      
      // Update name only if enough addresses agree on the same one
      if(satOccurenceMapping[_satId].nameOcc[_name] >= 3 /* && satDetailsMapping[_satId].name == "" */){
         satDetailsMapping[_satId].name = _name;
      // satNameToId[_name] = _satId;
      }
          
      }
  }
  

  function getChainlinkToken() public view returns (address) {
    return chainlinkTokenAddress();
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }

  function cancelRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  )
    public
    onlyOwner
  {
    cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
  }
  
  
  
  // Helper functions
  function stringToBytes32(string memory source) private pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly { // solhint-disable-line no-inline-assembly
      result := mload(add(source, 32))
    }
  }
  
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

  
function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    
    function viewSatDetails (uint _satId) view public 
    returns (uint satId, 
            string memory name,
            string memory nationality,
            uint32 apogee,
            uint32 perigee,
            uint32 inclination,
            uint32 launchYear,
            uint32 launchMonth,
            uint32 launchDay){
    
        satId = _satId;
        name = bytes32ToString(satDetailsMapping[_satId].name);
        nationality = bytes32ToString(satDetailsMapping[_satId].nationality);
        apogee = satDetailsMapping[_satId].apogee;
        perigee = satDetailsMapping[_satId].perigee;
        inclination = satDetailsMapping[_satId].inclination;
        launchYear = satDetailsMapping[_satId].launchDate / uint32(10000);
        launchMonth = (satDetailsMapping[_satId].launchDate % uint32(10000)) / uint32(100);
        launchDay = satDetailsMapping[_satId].launchDate % uint32(100);
        
    }
    
}