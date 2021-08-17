/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

abstract contract DistributorBase {
    event Distribute(address indexed from, address indexed to, uint256 amount);

    function _distribute(
        address payable[] calldata addresses,
        uint256[] calldata amounts
    ) internal {
        require(
            addresses.length == amounts.length,
            "Address array and amount array must have the same length"
        );
        uint256 n = addresses.length;
        for (uint256 i = 0; i < n; i++) {
            addresses[i].transfer(amounts[i]);
            emit Distribute(msg.sender, addresses[i], amounts[i]);
        }
        require(
            address(this).balance == 0,
            "Ether input must equal the sum of outputs"
        );
    }
}

contract DistributorOwned is DistributorBase {
    address owner = msg.sender;
    mapping(address => bool) public whitelisted;
    bool public initialized = false;

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Only whitelisted addresses");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function initialize(address[] calldata addresses) public onlyOwner {
        require(!initialized, "Already initialized");
        uint256 n = addresses.length;
        for (uint256 i = 0; i < n; i++) {
            whitelisted[addresses[i]] = true;
        }
        initialized = true;
    }

    function distribute(
        address payable[] calldata addresses,
        uint256[] calldata amounts
    ) public payable onlyWhitelisted {
        // A check on initialized is not necessary since `onlyWhitelisted`
        // is guaranteed to fail if the contract is not initialized
        _distribute(addresses, amounts);
    }
}