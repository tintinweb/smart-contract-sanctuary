/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// File: contracts/SnowcorpPresale.sol



pragma solidity ^0.8.0;

contract SntestPresale {

	mapping (address => uint) public _presaleAddresses;
	mapping (address => uint) public _presaleAddressesMinted;
	address public owner;
    address public mainContract;
    
    constructor () {
        owner = msg.sender;
    }

    function setMainContract(address _address) public {
        require(msg.sender == owner, "SNOWCORP: You are not the owner");
        mainContract = _address;
    }

    function addPresalers(address[] calldata _addresses, uint[] calldata _amounts) public {
        require(msg.sender == owner, "SNOWCORP: You are not the owner");
        for (uint x = 0; x < _addresses.length; x++) {
            _presaleAddresses[_addresses[x]] = _amounts[x];
        }
    }
    
    function removePresalers(address[] calldata _addresses) public {
        require(msg.sender == owner, "SNOWCORP: You are not the owner");
        for (uint x = 0; x < _addresses.length; x++) {
            _presaleAddresses[_addresses[x]] = 0;
        }
    }

    function isInPresale(address _address) public view returns (uint) {
        return _presaleAddresses[_address];
    }

    function presaleMinted(address _address) public view returns (uint) {
        return _presaleAddressesMinted[_address];
    }

    function addToMinted(address _address, uint count) public {
        require(msg.sender == mainContract, "SNOWCORP: Only main contract can call the function");
        if (_presaleAddressesMinted[_address] > 0) {
            require(_presaleAddressesMinted[_address] < _presaleAddresses[_address], "SNOWCORP: Exceeds the max you can mint in the presale");
                _presaleAddressesMinted[_address] += count;
        }else{
                _presaleAddressesMinted[_address] = count;
        }
    }

}