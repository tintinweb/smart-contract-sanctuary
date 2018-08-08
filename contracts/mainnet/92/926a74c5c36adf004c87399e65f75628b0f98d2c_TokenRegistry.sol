/*

  Copyright 2017 ZeroEx Intl.

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

pragma solidity 0.4.11;

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


/// @title Token Registry - Stores metadata associated with ERC20 tokens. See ERC22 https://github.com/ethereum/EIPs/issues/22
/// @author Amir Bandeali - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="51303c382311612901233e3b3432257f323e3c">[email&#160;protected]</a>>, Will Warren - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="94e3fdf8f8d4a4ecc4e6fbfef1f7e0baf7fbf9">[email&#160;protected]</a>>
contract TokenRegistry is Ownable {

    event LogAddToken(
        address indexed token,
        string name,
        string symbol,
        uint8 decimals,
        bytes ipfsHash,
        bytes swarmHash
    );

    event LogRemoveToken(
        address indexed token,
        string name,
        string symbol,
        uint8 decimals,
        bytes ipfsHash,
        bytes swarmHash
    );

    event LogTokenNameChange(address indexed token, string oldName, string newName);
    event LogTokenSymbolChange(address indexed token, string oldSymbol, string newSymbol);
    event LogTokenIpfsHashChange(address indexed token, bytes oldIpfsHash, bytes newIpfsHash);
    event LogTokenSwarmHashChange(address indexed token, bytes oldSwarmHash, bytes newSwarmHash);

    mapping (address => TokenMetadata) public tokens;
    mapping (string => address) tokenBySymbol;
    mapping (string => address) tokenByName;

    address[] public tokenAddresses;

    struct TokenMetadata {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        bytes ipfsHash;
        bytes swarmHash;
    }

    modifier tokenExists(address _token) {
        require(tokens[_token].token != address(0));
        _;
    }

    modifier tokenDoesNotExist(address _token) {
        require(tokens[_token].token == address(0));
        _;
    }

    modifier nameDoesNotExist(string _name) {
      require(tokenByName[_name] == address(0));
      _;
    }

    modifier symbolDoesNotExist(string _symbol) {
        require(tokenBySymbol[_symbol] == address(0));
        _;
    }

    modifier addressNotNull(address _address) {
        require(_address != address(0));
        _;
    }


    /// @dev Allows owner to add a new token to the registry.
    /// @param _token Address of new token.
    /// @param _name Name of new token.
    /// @param _symbol Symbol for new token.
    /// @param _decimals Number of decimals, divisibility of new token.
    /// @param _ipfsHash IPFS hash of token icon.
    /// @param _swarmHash Swarm hash of token icon.
    function addToken(
        address _token,
        string _name,
        string _symbol,
        uint8 _decimals,
        bytes _ipfsHash,
        bytes _swarmHash)
        public
        onlyOwner
        tokenDoesNotExist(_token)
        addressNotNull(_token)
        symbolDoesNotExist(_symbol)
        nameDoesNotExist(_name)
    {
        tokens[_token] = TokenMetadata({
            token: _token,
            name: _name,
            symbol: _symbol,
            decimals: _decimals,
            ipfsHash: _ipfsHash,
            swarmHash: _swarmHash
        });
        tokenAddresses.push(_token);
        tokenBySymbol[_symbol] = _token;
        tokenByName[_name] = _token;
        LogAddToken(
            _token,
            _name,
            _symbol,
            _decimals,
            _ipfsHash,
            _swarmHash
        );
    }

    /// @dev Allows owner to remove an existing token from the registry.
    /// @param _token Address of existing token.
    function removeToken(address _token, uint _index)
        public
        onlyOwner
        tokenExists(_token)
    {
        require(tokenAddresses[_index] == _token);

        tokenAddresses[_index] = tokenAddresses[tokenAddresses.length - 1];
        tokenAddresses.length -= 1;

        TokenMetadata storage token = tokens[_token];
        LogRemoveToken(
            token.token,
            token.name,
            token.symbol,
            token.decimals,
            token.ipfsHash,
            token.swarmHash
        );
        delete tokenBySymbol[token.symbol];
        delete tokenByName[token.name];
        delete tokens[_token];
    }

    /// @dev Allows owner to modify an existing token&#39;s name.
    /// @param _token Address of existing token.
    /// @param _name New name.
    function setTokenName(address _token, string _name)
        public
        onlyOwner
        tokenExists(_token)
        nameDoesNotExist(_name)
    {
        TokenMetadata storage token = tokens[_token];
        LogTokenNameChange(_token, token.name, _name);
        delete tokenByName[token.name];
        tokenByName[_name] = _token;
        token.name = _name;
    }

    /// @dev Allows owner to modify an existing token&#39;s symbol.
    /// @param _token Address of existing token.
    /// @param _symbol New symbol.
    function setTokenSymbol(address _token, string _symbol)
        public
        onlyOwner
        tokenExists(_token)
        symbolDoesNotExist(_symbol)
    {
        TokenMetadata storage token = tokens[_token];
        LogTokenSymbolChange(_token, token.symbol, _symbol);
        delete tokenBySymbol[token.symbol];
        tokenBySymbol[_symbol] = _token;
        token.symbol = _symbol;
    }

    /// @dev Allows owner to modify an existing token&#39;s IPFS hash.
    /// @param _token Address of existing token.
    /// @param _ipfsHash New IPFS hash.
    function setTokenIpfsHash(address _token, bytes _ipfsHash)
        public
        onlyOwner
        tokenExists(_token)
    {
        TokenMetadata storage token = tokens[_token];
        LogTokenIpfsHashChange(_token, token.ipfsHash, _ipfsHash);
        token.ipfsHash = _ipfsHash;
    }

    /// @dev Allows owner to modify an existing token&#39;s Swarm hash.
    /// @param _token Address of existing token.
    /// @param _swarmHash New Swarm hash.
    function setTokenSwarmHash(address _token, bytes _swarmHash)
        public
        onlyOwner
        tokenExists(_token)
    {
        TokenMetadata storage token = tokens[_token];
        LogTokenSwarmHashChange(_token, token.swarmHash, _swarmHash);
        token.swarmHash = _swarmHash;
    }

    /*
     * Web3 call functions
     */

    /// @dev Provides a registered token&#39;s address when given the token symbol.
    /// @param _symbol Symbol of registered token.
    /// @return Token&#39;s address.
    function getTokenAddressBySymbol(string _symbol) constant returns (address) {
        return tokenBySymbol[_symbol];
    }

    /// @dev Provides a registered token&#39;s address when given the token name.
    /// @param _name Name of registered token.
    /// @return Token&#39;s address.
    function getTokenAddressByName(string _name) constant returns (address) {
        return tokenByName[_name];
    }

    /// @dev Provides a registered token&#39;s metadata, looked up by address.
    /// @param _token Address of registered token.
    /// @return Token metadata.
    function getTokenMetaData(address _token)
        public
        constant
        returns (
            address,  //tokenAddress
            string,   //name
            string,   //symbol
            uint8,    //decimals
            bytes,    //ipfsHash
            bytes     //swarmHash
        )
    {
        TokenMetadata memory token = tokens[_token];
        return (
            token.token,
            token.name,
            token.symbol,
            token.decimals,
            token.ipfsHash,
            token.swarmHash
        );
    }

    /// @dev Provides a registered token&#39;s metadata, looked up by name.
    /// @param _name Name of registered token.
    /// @return Token metadata.
    function getTokenByName(string _name)
        public
        constant
        returns (
            address,  //tokenAddress
            string,   //name
            string,   //symbol
            uint8,    //decimals
            bytes,    //ipfsHash
            bytes     //swarmHash
        )
    {
        address _token = tokenByName[_name];
        return getTokenMetaData(_token);
    }

    /// @dev Provides a registered token&#39;s metadata, looked up by symbol.
    /// @param _symbol Symbol of registered token.
    /// @return Token metadata.
    function getTokenBySymbol(string _symbol)
        public
        constant
        returns (
            address,  //tokenAddress
            string,   //name
            string,   //symbol
            uint8,    //decimals
            bytes,    //ipfsHash
            bytes     //swarmHash
        )
    {
        address _token = tokenBySymbol[_symbol];
        return getTokenMetaData(_token);
    }

    /// @dev Returns an array containing all token addresses.
    /// @return Array of token addresses.
    function getTokenAddresses()
        public
        constant
        returns (address[])
    {
        return tokenAddresses;
    }
}