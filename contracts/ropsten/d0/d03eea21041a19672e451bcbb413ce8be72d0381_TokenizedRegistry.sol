/**
 *Submitted for verification at Etherscan.io on 2019-07-06
*/

/**
 * Copyright 2017-2019, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


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

contract TokenizedRegistry is Ownable {

    mapping (address => TokenMetadata) public tokens;
    mapping (string => address) internal tokenBySymbol;
    mapping (string => address) internal tokenByName;

    address[] public tokenAddresses;

    struct TokenMetadata {
        address token;
        address asset; // iToken -> loanToken, pToken -> tradeToken
        string name;
        string symbol;
        uint256 tokenType; // 0=no type set, 1=iToken, 2=pToken
        uint256 index;
    }

    modifier tokenExists(address _token) {
        require(tokens[_token].token != address(0), "token doesn&#39;t exist");
        _;
    }

    modifier tokenDoesNotExist(address _token) {
        require(tokens[_token].token == address(0), "token exists");
        _;
    }

    modifier nameDoesNotExist(string memory _name) {
        require(tokenByName[_name] == address(0), "name exists");
        _;
    }

    modifier symbolDoesNotExist(string memory _symbol) {
        require(tokenBySymbol[_symbol] == address(0), "symbol exists");
        _;
    }

    modifier addressNotNull(address _address) {
        require(_address != address(0), "address is null");
        _;
    }

    function addTokens(
        address[] memory _tokens,
        address[] memory _assets,
        string[] memory _names,
        string[] memory _symbols,
        uint256[] memory _types)
        public
        onlyOwner
    {
        require(_tokens.length == _assets.length
                && _assets.length == _names.length
                && _names.length == _symbols.length
                && _symbols.length == _types.length, "array length mismatch");

        for(uint256 i=0; i < _tokens.length; i++) {
            addToken(
                _tokens[i],
                _assets[i],
                _names[i],
                _symbols[i],
                _types[i]
            );
        }
    }

    function removeTokens(
        address[] memory _tokens)
        public
        onlyOwner
    {
        for(uint256 i=0; i < _tokens.length; i++) {
            removeToken(_tokens[i]);
        }
    }

    /// @dev Allows owner to add a new token to the registry.
    /// @param _token Address of new token.
    /// @param _asset Asset address of new token.
    /// @param _name Name of new token.
    /// @param _symbol Symbol for new token.
    /// @param _type TokenType (iToken, pToken, etc.) for new token.
    function addToken(
        address _token,
        address _asset,
        string memory _name,
        string memory _symbol,
        uint256 _type)
        public
        onlyOwner
        tokenDoesNotExist(_token)
        addressNotNull(_token)
        symbolDoesNotExist(_symbol)
        nameDoesNotExist(_name)
    {
        tokens[_token] = TokenMetadata({
            token: _token,
            asset: _asset,
            name: _name,
            symbol: _symbol,
            tokenType: _type,
            index: tokenAddresses.length
        });
        tokenAddresses.push(_token);
        tokenBySymbol[_symbol] = _token;
        tokenByName[_name] = _token;
    }

    /// @dev Allows owner to remove an existing token from the registry.
    /// @param _token Address of existing token.
    function removeToken(
        address _token)
        public
        onlyOwner
        tokenExists(_token)
    {
        uint256 _index = tokens[_token].index;
        require(tokenAddresses[_index] == _token, "invalid index");

        tokenAddresses[_index] = tokenAddresses[tokenAddresses.length - 1];
        tokens[tokenAddresses[_index]].index = _index;
        tokenAddresses.length -= 1;

        TokenMetadata memory token = tokens[_token];
        delete tokenBySymbol[token.symbol];
        delete tokenByName[token.name];
        delete tokens[_token];
    }

    /// @dev Allows owner to modify an existing token&#39;s name.
    /// @param _token Address of existing token.
    /// @param _name New name.
    function setTokenName(address _token, string memory _name)
        public
        onlyOwner
        tokenExists(_token)
        nameDoesNotExist(_name)
    {
        TokenMetadata storage token = tokens[_token];
        delete tokenByName[token.name];
        tokenByName[_name] = _token;
        token.name = _name;
    }

    /// @dev Allows owner to modify an existing token&#39;s symbol.
    /// @param _token Address of existing token.
    /// @param _symbol New symbol.
    function setTokenSymbol(address _token, string memory _symbol)
        public
        onlyOwner
        tokenExists(_token)
        symbolDoesNotExist(_symbol)
    {
        TokenMetadata storage token = tokens[_token];
        delete tokenBySymbol[token.symbol];
        tokenBySymbol[_symbol] = _token;
        token.symbol = _symbol;
    }


    /*
     * View functions
     */
    /// @dev Provides a registered token&#39;s address when given the token symbol.
    /// @param _symbol Symbol of registered token.
    /// @return Token&#39;s address.
    function getTokenAddressBySymbol(string memory _symbol)
        public
        view
        returns (address)
    {
        return tokenBySymbol[_symbol];
    }

    /// @dev Provides a registered token&#39;s address when given the token name.
    /// @param _name Name of registered token.
    /// @return Token&#39;s address.
    function getTokenAddressByName(string memory _name)
        public
        view
        returns (address)
    {
        return tokenByName[_name];
    }

    /// @dev Provides a registered token&#39;s metadata, looked up by address.
    /// @param _token Address of registered token.
    /// @return Token metadata.
    function getTokenByAddress(address _token)
        public
        view
        returns (TokenMetadata memory)
    {
        return tokens[_token];
    }

    /// @dev Provides a registered token&#39;s metadata, looked up by name.
    /// @param _name Name of registered token.
    /// @return Token metadata.
    function getTokenByName(string memory _name)
        public
        view
        returns (TokenMetadata memory)
    {
        address _token = tokenByName[_name];
        return getTokenByAddress(_token);
    }

    /// @dev Provides a registered token&#39;s metadata, looked up by symbol.
    /// @param _symbol Symbol of registered token.
    /// @return Token metadata.
    function getTokenBySymbol(string memory _symbol)
        public
        view
        returns (TokenMetadata memory)
    {
        address _token = tokenBySymbol[_symbol];
        return getTokenByAddress(_token);
    }

    /// @dev Returns an array containing all token addresses.
    /// @return Array of token addresses.
    function getTokenAddresses()
        public
        view
        returns (address[] memory)
    {
        return tokenAddresses;
    }

    /// @dev Provides a list of registered token metadata.
    /// @param _start The starting token to return.
    /// @param _count The total amount of tokens to return if they exist. Amount returned can be less.
    /// @param _tokenType Only return tokens matching this type (0 == return all).
    /// @return Token metadata list.
    function getTokens(
        uint256 _start,
        uint256 _count,
        uint256 _tokenType)
        public
        view
        returns (TokenMetadata[] memory tokenData)
    {
        uint256 end = min256(tokenAddresses.length, add(_start, _count));
        if (end == 0 || _start >= end) {
            return tokenData;
        }

        uint256 actualSize;
        TokenMetadata[] memory tokenDataComplete = new TokenMetadata[](end-_start);
        end = end-_start;
        uint256 i;
        for (i=0; i < end-_start; i++) {
            TokenMetadata memory token = tokens[tokenAddresses[i+_start]];
            if (_tokenType > 0 && token.tokenType != _tokenType) {
                if (end < tokenAddresses.length)
                    end++;

                continue;
            }
            actualSize++;
            tokenDataComplete[i] = token;
        }
        
        if (tokenDataComplete.length == actualSize) {
            return tokenDataComplete;
        } else {
            // clean up data
            tokenData = new TokenMetadata[](actualSize);
            uint256 j;
            for (i=0; i < tokenDataComplete.length; i++) {
                if (tokenDataComplete[i].token != address(0)) {
                    tokenData[j] = tokenDataComplete[i];
                    j++;
                }
            }
            return tokenData;
        }
    }

    function isTokenType(
        address _token,
        uint256 _tokenType)
        public
        view
        returns (bool valid)
    {
        (valid,) = _getTokenForType(
            _token,
            _tokenType
        );
    }

    function getTokenAsset(
        address _token,
        uint256 _tokenType)
        public
        view
        returns (address)
    {
        bool valid;
        TokenMetadata memory token;
        (valid, token) = _getTokenForType(
            _token,
            _tokenType
        );
        if (valid) {
            return token.asset;
        } else {
            return address(0);
        }
    }

    function _getTokenForType(
        address _token,
        uint256 _tokenType)
        internal
        view
        returns (bool valid, TokenMetadata memory token)
    {
        token = tokens[_token];
        if (token.token != address(0)
            && token.token == _token
            && (_tokenType == 0
                || token.tokenType == _tokenType))
        {
            valid = true;
        } else {
            valid = false;
        }
    }

    function add(
        uint256 _a,
        uint256 _b)
        internal
        pure
        returns (uint256 c)
    {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }

    function min256(
        uint256 _a,
        uint256 _b)
        internal
        pure
        returns (uint256)
    {
        return _a < _b ? _a : _b;
    }
}