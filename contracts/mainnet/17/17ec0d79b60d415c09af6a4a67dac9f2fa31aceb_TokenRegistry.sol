/*

  Copyright 2017 ZeroEx Intl.
  Modifications Copyright 2018 bZeroX, LLC

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

contract TokenRegistry is Ownable {

    event LogAddToken(
        address indexed token,
        string name,
        string symbol,
        uint8 decimals,
        string url
    );

    event LogRemoveToken(
        address indexed token,
        string name,
        string symbol,
        uint8 decimals,
        string url
    );

    event LogTokenNameChange(address indexed token, string oldName, string newName);
    event LogTokenSymbolChange(address indexed token, string oldSymbol, string newSymbol);
    event LogTokenURLChange(address indexed token, string oldURL, string newURL);

    mapping (address => TokenMetadata) public tokens;
    mapping (string => address) internal tokenBySymbol;
    mapping (string => address) internal tokenByName;

    address[] public tokenAddresses;

    struct TokenMetadata {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        string url;
    }

    modifier tokenExists(address _token) {
        require(tokens[_token].token != address(0), "TokenRegistry::token doesn&#39;t exist");
        _;
    }

    modifier tokenDoesNotExist(address _token) {
        require(tokens[_token].token == address(0), "TokenRegistry::token exists");
        _;
    }

    modifier nameDoesNotExist(string _name) {
        require(tokenByName[_name] == address(0), "TokenRegistry::name exists");
        _;
    }

    modifier symbolDoesNotExist(string _symbol) {
        require(tokenBySymbol[_symbol] == address(0), "TokenRegistry::symbol exists");
        _;
    }

    modifier addressNotNull(address _address) {
        require(_address != address(0), "TokenRegistry::address is null");
        _;
    }

    /// @dev Allows owner to add a new token to the registry.
    /// @param _token Address of new token.
    /// @param _name Name of new token.
    /// @param _symbol Symbol for new token.
    /// @param _decimals Number of decimals, divisibility of new token.
    /// @param _url URL of token icon.
    function addToken(
        address _token,
        string _name,
        string _symbol,
        uint8 _decimals,
        string _url)
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
            url: _url
        });
        tokenAddresses.push(_token);
        tokenBySymbol[_symbol] = _token;
        tokenByName[_name] = _token;
        emit LogAddToken(
            _token,
            _name,
            _symbol,
            _decimals,
            _url
        );
    }

    /// @dev Allows owner to remove an existing token from the registry.
    /// @param _token Address of existing token.
    function removeToken(address _token, uint _index)
        public
        onlyOwner
        tokenExists(_token)
    {
        require(tokenAddresses[_index] == _token, "TokenRegistry::invalid index");

        tokenAddresses[_index] = tokenAddresses[tokenAddresses.length - 1];
        tokenAddresses.length -= 1;

        TokenMetadata storage token = tokens[_token];
        emit LogRemoveToken(
            token.token,
            token.name,
            token.symbol,
            token.decimals,
            token.url
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
        emit LogTokenNameChange(_token, token.name, _name);
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
        emit LogTokenSymbolChange(_token, token.symbol, _symbol);
        delete tokenBySymbol[token.symbol];
        tokenBySymbol[_symbol] = _token;
        token.symbol = _symbol;
    }

    /// @dev Allows owner to modify an existing token&#39;s icon URL.
    /// @param _token URL of token token.
    /// @param _url New URL to token icon.
    function setTokenURL(address _token, string _url)
        public
        onlyOwner
        tokenExists(_token)
    {
        TokenMetadata storage token = tokens[_token];
        emit LogTokenURLChange(_token, token.url, _url);
        token.url = _url;
    }

    /*
     * View functions
     */
    /// @dev Provides a registered token&#39;s address when given the token symbol.
    /// @param _symbol Symbol of registered token.
    /// @return Token&#39;s address.
    function getTokenAddressBySymbol(string _symbol) 
        public
        view 
        returns (address)
    {
        return tokenBySymbol[_symbol];
    }

    /// @dev Provides a registered token&#39;s address when given the token name.
    /// @param _name Name of registered token.
    /// @return Token&#39;s address.
    function getTokenAddressByName(string _name) 
        public
        view
        returns (address)
    {
        return tokenByName[_name];
    }

    /// @dev Provides a registered token&#39;s metadata, looked up by address.
    /// @param _token Address of registered token.
    /// @return Token metadata.
    function getTokenMetaData(address _token)
        public
        view
        returns (
            address,  //tokenAddress
            string,   //name
            string,   //symbol
            uint8,    //decimals
            string    //url
        )
    {
        TokenMetadata memory token = tokens[_token];
        return (
            token.token,
            token.name,
            token.symbol,
            token.decimals,
            token.url
        );
    }

    /// @dev Provides a registered token&#39;s metadata, looked up by name.
    /// @param _name Name of registered token.
    /// @return Token metadata.
    function getTokenByName(string _name)
        public
        view
        returns (
            address,  //tokenAddress
            string,   //name
            string,   //symbol
            uint8,    //decimals
            string    //url
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
        view
        returns (
            address,  //tokenAddress
            string,   //name
            string,   //symbol
            uint8,    //decimals
            string    //url
        )
    {
        address _token = tokenBySymbol[_symbol];
        return getTokenMetaData(_token);
    }

    /// @dev Returns an array containing all token addresses.
    /// @return Array of token addresses.
    function getTokenAddresses()
        public
        view
        returns (address[])
    {
        return tokenAddresses;
    }
}