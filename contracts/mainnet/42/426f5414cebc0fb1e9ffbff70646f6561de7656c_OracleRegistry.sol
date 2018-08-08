/*

  Copyright 2018 bZeroX, LLC
  Inspired by TokenRegistry.sol, Copyright 2017 ZeroEx Intl.

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

pragma solidity 0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/// @title Oracle Registry - Oracles added to the bZx network by decentralized governance
contract OracleRegistry is Ownable {

    event LogAddOracle(
        address indexed oracle,
        string name
    );

    event LogRemoveOracle(
        address indexed oracle,
        string name
    );

    event LogOracleNameChange(address indexed oracle, string oldName, string newName);

    mapping (address => OracleMetadata) public oracles;
    mapping (string => address) internal oracleByName;

    address[] public oracleAddresses;

    struct OracleMetadata {
        address oracle;
        string name;
    }

    modifier oracleExists(address _oracle) {
        require(oracles[_oracle].oracle != address(0), "OracleRegistry::oracle doesn&#39;t exist");
        _;
    }

    modifier oracleDoesNotExist(address _oracle) {
        require(oracles[_oracle].oracle == address(0), "OracleRegistry::oracle exists");
        _;
    }

    modifier nameDoesNotExist(string _name) {
        require(oracleByName[_name] == address(0), "OracleRegistry::name exists");
        _;
    }

    modifier addressNotNull(address _address) {
        require(_address != address(0), "OracleRegistry::address is null");
        _;
    }

    /// @dev Allows owner to add a new oracle to the registry.
    /// @param _oracle Address of new oracle.
    /// @param _name Name of new oracle.
    function addOracle(
        address _oracle,
        string _name)
        public
        onlyOwner
        oracleDoesNotExist(_oracle)
        addressNotNull(_oracle)
        nameDoesNotExist(_name)
    {
        oracles[_oracle] = OracleMetadata({
            oracle: _oracle,
            name: _name
        });
        oracleAddresses.push(_oracle);
        oracleByName[_name] = _oracle;
        emit LogAddOracle(
            _oracle,
            _name
        );
    }

    /// @dev Allows owner to remove an existing oracle from the registry.
    /// @param _oracle Address of existing oracle.
    function removeOracle(address _oracle, uint _index)
        public
        onlyOwner
        oracleExists(_oracle)
    {
        require(oracleAddresses[_index] == _oracle, "OracleRegistry::invalid index");

        oracleAddresses[_index] = oracleAddresses[oracleAddresses.length - 1];
        oracleAddresses.length -= 1;

        OracleMetadata storage oracle = oracles[_oracle];
        emit LogRemoveOracle(
            oracle.oracle,
            oracle.name
        );
        delete oracleByName[oracle.name];
        delete oracles[_oracle];
    }

    /// @dev Allows owner to modify an existing oracle&#39;s name.
    /// @param _oracle Address of existing oracle.
    /// @param _name New name.
    function setOracleName(address _oracle, string _name)
        public
        onlyOwner
        oracleExists(_oracle)
        nameDoesNotExist(_name)
    {
        OracleMetadata storage oracle = oracles[_oracle];
        emit LogOracleNameChange(_oracle, oracle.name, _name);
        delete oracleByName[oracle.name];
        oracleByName[_name] = _oracle;
        oracle.name = _name;
    }

    /// @dev Checks if an oracle exists in the registry
    /// @param _oracle Address of registered oracle.
    /// @return True if exists, False otherwise.
    function hasOracle(address _oracle)
        public
        view
        returns (bool) {
        return (oracles[_oracle].oracle == _oracle);
    }

    /// @dev Provides a registered oracle&#39;s address when given the oracle name.
    /// @param _name Name of registered oracle.
    /// @return Oracle&#39;s address.
    function getOracleAddressByName(string _name)
        public
        view
        returns (address) {
        return oracleByName[_name];
    }

    /// @dev Provides a registered oracle&#39;s metadata, looked up by address.
    /// @param _oracle Address of registered oracle.
    /// @return Oracle metadata.
    function getOracleMetaData(address _oracle)
        public
        view
        returns (
            address,  //oracleAddress
            string   //name
        )
    {
        OracleMetadata memory oracle = oracles[_oracle];
        return (
            oracle.oracle,
            oracle.name
        );
    }

    /// @dev Provides a registered oracle&#39;s metadata, looked up by name.
    /// @param _name Name of registered oracle.
    /// @return Oracle metadata.
    function getOracleByName(string _name)
        public
        view
        returns (
            address,  //oracleAddress
            string    //name
        )
    {
        address _oracle = oracleByName[_name];
        return getOracleMetaData(_oracle);
    }

    /// @dev Returns an array containing all oracle addresses.
    /// @return Array of oracle addresses.
    function getOracleAddresses()
        public
        view
        returns (address[])
    {
        return oracleAddresses;
    }

    /// @dev Returns an array of oracle addresses, an array with the length of each oracle name, and a concatenated string of oracle names
    /// @return Array of oracle names, array of name lengths, concatenated string of all names
    function getOracleList()
        public
        view
        returns (address[], uint[], string)
    {
        if (oracleAddresses.length == 0)
            return;

        address[] memory addresses = oracleAddresses;
        uint[] memory nameLengths = new uint[](oracleAddresses.length);
        string memory allStrings;
        
        for (uint i = 0; i < oracleAddresses.length; i++) {
            string memory tmp = oracles[oracleAddresses[i]].name;
            nameLengths[i] = bytes(tmp).length;
            allStrings = strConcat(allStrings, tmp);
        }

        return (addresses, nameLengths, allStrings);
    }

    /// @dev Concatenates two strings
    /// @return concatenated string
    function strConcat(
        string _a,
        string _b)
        internal
        pure
        returns (string)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)
            bab[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++)
            bab[k++] = _bb[i];
        
        return string(bab);
    }
}