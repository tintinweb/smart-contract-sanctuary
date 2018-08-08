/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

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
pragma solidity ^0.4.11;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/// @title Token Register Contract
/// @author Kongliang Zhong - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6a0105040d06030b040d2a0605051a1803040d4405180d">[email&#160;protected]</a>>,
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4521242b2c202905292a2a35372c2b226b2a3722">[email&#160;protected]</a>>.
contract TokenRegistry is Ownable {

    address[] public tokens;

    mapping (string => address) tokenSymbolMap;

    function registerToken(address _token, string _symbol)
        public
        onlyOwner {
        require(_token != address(0));
        require(!isTokenRegisteredBySymbol(_symbol));
        require(!isTokenRegistered(_token));
        tokens.push(_token);
        tokenSymbolMap[_symbol] = _token;
    }

    function unregisterToken(address _token, string _symbol)
        public
        onlyOwner {
        require(tokenSymbolMap[_symbol] == _token);
        delete tokenSymbolMap[_symbol];
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == _token) {
                tokens[i] == tokens[tokens.length - 1];
                tokens.length --;
                break;
            }
        }
    }

    function isTokenRegisteredBySymbol(string symbol)
        public
        constant
        returns (bool) {
        return tokenSymbolMap[symbol] != address(0);
    }

    function isTokenRegistered(address _token)
        public
        constant
        returns (bool) {

        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function getAddressBySymbol(string symbol)
        public
        constant
        returns (address) {
        return tokenSymbolMap[symbol];
    }
}