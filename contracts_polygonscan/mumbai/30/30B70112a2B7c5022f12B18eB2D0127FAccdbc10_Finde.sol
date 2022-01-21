// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Finde {
    using Counters for Counters.Counter;
    Counters.Counter private _uriIndexCounter ;

    mapping(uint256 => address) public indexToAddress;
    mapping(address => uint256) public addressToIndex;
    mapping(address => string) public addressToURI;
    mapping(string => address[]) public countryToAddresses;
    mapping(string => mapping(address => uint256)) public countryToIndexOfAddress;


    constructor () {
        _uriIndexCounter.increment(); // start counter from 1;
    }

    function addURI(string memory _uri, string memory _country) public {
        
        if(addressToIndex[msg.sender] == 0){

            indexToAddress[_uriIndexCounter.current()] = msg.sender;
            addressToIndex[msg.sender] = _uriIndexCounter.current();

            _uriIndexCounter.increment();
        }
        
        if( countryToIndexOfAddress[_country][msg.sender] == 0){
            countryToAddresses[_country].push(msg.sender);
            countryToIndexOfAddress[_country][msg.sender] = countryToAddresses[_country].length;            
        }

        addressToURI[msg.sender] = _uri;
    }

    function getPagenatedURIs(uint256 _from, uint256 _limit) public view returns(string[] memory){
        require(_limit > 0 && _limit <= 10, "FINDE: Invalid Parameters" );
        
        string[] memory data = new string[](_limit);
        
        for(uint i=0; i< _limit; i++){
            data[i] = addressToURI[indexToAddress[_from+i]];
        }
        
        return data;
    }

    function getPagenatedURIsByCountry(string memory _country, uint256 _from, uint256 _limit) public view returns(string[] memory){
        require(_limit > 0 && _limit <= 10, "FINDE: Invalid Parameters" );
        
        string[] memory data = new string[](_limit);
        
        for(uint i=0; i< _limit; i++){
            
            data[i] = addressToURI[countryToAddresses[_country][_from+i]];
        }
        
        return data;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}