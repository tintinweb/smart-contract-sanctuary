/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-25
*/

pragma solidity ^0.5.16;

 // SPDX-License-Identifier: MIT
/**
Bird On-chain Oracle to confirm rating with 2+ consensus before update using the off-chain API https://www.bird.money/docs
*/

contract BirdOracle {
  BirdRequest[] onChainRequests; //keep track of list of on-chain requests
  uint minConsensus = 2; //minimum number of consensus before confirmation 
  uint birdNest = 3; // bird consensus count
  uint trackId = 0; //increament id's

    /**
   * Bird Standard API Request
   * id: "1"
   * url: "https://www.bird.money/analytics/address/ethaddress"
   * key: "bird_rating"
   * value: "0.4" => 400000000000000000
   * arrivedBirds: 0
   * resolved: true/false
   * addr: 0x...
   * response: response from off-chain oracles 
   * nest: approved off-chain oracles nest/addresses and keep track of vote (1=not voted, 2=voted)
   */
  struct BirdRequest {
    uint id;   
    string url; 
    string key; 
    uint value;
    uint arrivedBirds;
    bool resolved;
    address addr;
    mapping(uint => uint) response;
    mapping(address => uint) nest; 
  }
  
    /**
   * Bird Standard API Request
   * Off-Chain-Request from outside the blockchain 
   */
  event OffChainRequest (
    uint id,
    string url,
    string key
  );

    /**
   * To call when there is consensus on final result
   */
   
  event UpdatedRequest (
    uint id,
    string url,
    string key,
    uint value
  );

  // container for the ratings
  mapping (address => uint) ratings;

  function newChainRequest (
    string memory _url,
    string memory _key
  )
  public   
  {
    uint length = onChainRequests.push(BirdRequest(trackId, _url, _key, 0, 0, false, address(0)));
    BirdRequest storage r = onChainRequests[length - 1];

    /**
   * trusted oracles in bird nest
   */
    address trustedBird1 = address(0x35fA8692EB10F87D17Cd27fB5488598D33B023E5);
    address trustedBird2 = address(0x58Fd79D34Edc6362f92c6799eE46945113A6EA91);
    address trustedBird3 = address(0x0e4338DFEdA53Bc35467a09Da483410664d34e88);
    
    /**
   * track votes
   */
    r.nest[trustedBird1] = 1;
    r.nest[trustedBird2] = 1;
    r.nest[trustedBird3] = 1;

    /**
   * save caller address
   */
    //r.addr = msg.sender;

    string memory addrStr = extractAddress(_url);
    r.addr = parseAddr(addrStr);

    /**
   * Off-Chain event trigger
   */
    emit OffChainRequest (
      trackId,
      _url,
      _key
    );

    /**
   * Off-Chain event trigger
   */
    trackId++;
  }

  //called by the oracle to record its answer
    /**
   * Off-Chain oracle to update its consensus answer
   */
  function updatedChainRequest (
    uint _id,
    uint _valueResponse
  ) public {

    BirdRequest storage trackRequest = onChainRequests[_id];

    if (trackRequest.resolved)
      return;

    /**
   * To confirm an address/oracle is part of the trusted nest and has not voted
   */
    if(trackRequest.nest[msg.sender] == 1){
        
        /**
       * change vote value to = 2 from 1
       */
      trackRequest.nest[msg.sender] = 2;
      
        /**
       * Loop through responses for empty position, save the response
       * TODO: refactor
       */
      uint tmpI = trackRequest.arrivedBirds;
      trackRequest.response[tmpI] = _valueResponse;
      trackRequest.arrivedBirds = tmpI + 1;
      
      uint currentConsensusCount = 1;
      
        /**
       * Loop through list and check if min consensus has been reached
       */
      
      for(uint i = 0; i < tmpI; i++){
        uint a = trackRequest.response[i];
        uint b = _valueResponse;

        if(a == b){
          currentConsensusCount++;
          if(currentConsensusCount >= minConsensus){
            trackRequest.value = _valueResponse;
            trackRequest.resolved = true;

            // Save value and user information into the bird rating container
            ratings[trackRequest.addr] = trackRequest.value;
            
            emit UpdatedRequest (
              trackRequest.id,
              trackRequest.url,
              trackRequest.key,
              trackRequest.value
            );
          }
        }
      }
    }
  }

    /**
   * access to saved ratings after Oracle consensus
   */

  function getRatingByAddress(address _addr) public view returns (uint) {
    return ratings[_addr];
  }

  function getRatingByAddressString(string memory _str) public view returns (uint) {
    return ratings[parseAddr(_str)];
  }

  function getRating() public view returns (uint) {
    return ratings[msg.sender];
  }

  function extractAddress(string memory url) internal pure returns (string memory) {
    bytes memory strBytes = bytes(url);
    uint index = strBytes.length - 1;
    while (index >= 0) {
      if (strBytes[index] == "/" || strBytes[index] == "\\")
        break;
      index--;
    }
    require(index >= 0, "No address found.");
    return substring(url, index + 1);
  }

  function substring(string memory str, uint startIndex) internal pure returns (string memory) {
    return substring(str, startIndex, bytes(str).length);
  }

  function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex - startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
  }

  function parseAddr(string memory str) internal pure returns (address){
    bytes memory strBytes = bytes(str);
    uint160 iaddr = 0;
    uint160 b1;
    uint160 b2;
    for (uint i = 2; i < 2+2*20; i += 2){
      iaddr *= 256;
      b1 = uint160(uint8(strBytes[i]));
      b2 = uint160(uint8(strBytes[i + 1]));
      if ((b1 >= 97) && (b1 <= 102)) {
        b1 -= 87;
      } else if ((b1 >= 65) && (b1 <= 70)) {
        b1 -= 55;
      } else if ((b1 >= 48) && (b1 <= 57)) {
        b1 -= 48;
      }
      if ((b2 >= 97) && (b2 <= 102)) {
        b2 -= 87;
      } else if ((b2 >= 65) && (b2 <= 70)) {
        b2 -= 55;
      } else if ((b2 >= 48) && (b2 <= 57)) {
        b2 -= 48;
      }
      iaddr += (b1 * 16 + b2);
    }
    return address(iaddr);
  }
}