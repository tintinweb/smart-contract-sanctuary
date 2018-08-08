/*

  Copyright 2018 Dexdex.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.4.21;

contract Ownable {
    address public owner;

    function Ownable()
        public
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract ITrader {

  function getDataLength(
  ) public pure returns (uint256);

  function getProtocol(
  ) public pure returns (uint8);

  function getAvailableVolume(
    bytes orderData
  ) public view returns(uint);

  function isExpired(
    bytes orderData
  ) public view returns (bool); 

  function trade(
    bool isSell,
    bytes orderData,
    uint volume,
    uint volumeEth
  ) public;
  
  function getFillVolumes(
    bool isSell,
    bytes orderData,
    uint volume,
    uint volumeEth
  ) public view returns(uint, uint);

}

contract ITraders {

  /// @dev Add a valid trader address. Only owner.
  function addTrader(uint8 id, ITrader trader) public;

  /// @dev Remove a trader address. Only owner.
  function removeTrader(uint8 id) public;

  /// @dev Get trader by id.
  function getTrader(uint8 id) public view returns(ITrader);

  /// @dev Check if an address is a valid trader.
  function isValidTraderAddress(address addr) public view returns(bool);

}

contract Traders is ITraders, Ownable {

  mapping(uint8 => ITrader) public traders; // Mappings of ids of allowed addresses
  mapping(address => bool) public addresses; // Mappings of addresses of allowed addresses

  /// @dev Add a valid trader address. Only owner.
  function addTrader(uint8 protocolId, ITrader trader) public onlyOwner {
    require(protocolId == trader.getProtocol());
    traders[protocolId] = trader;
    addresses[trader] = true;
  }

  /// @dev Remove a trader address. Only owner.
  function removeTrader(uint8 protocolId) public onlyOwner {
    delete addresses[traders[protocolId]];
    delete traders[protocolId];
  }

  /// @dev Get trader by protocolId.
  function getTrader(uint8 protocolId) public view returns(ITrader) {
    return traders[protocolId];
  }

  /// @dev Check if an address is a valid trader.
  function isValidTraderAddress(address addr) public view returns(bool) {
    return addresses[addr];
  }
}