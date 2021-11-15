//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract SpaceX {
    // Storage
    mapping(address => bool) private _hasSpace;
    mapping(address => bytes32[10]) private _spaces;
    mapping(bytes32 => uint256) private _points;
    uint256 private _maxPoints = 0;

    /* Create a space and increment the maxPoints (essentially a total member count). */
    function createSpace(address _address) public {
        require(
            _hasSpace[_address] == false,
            "This address already has a space"
        );
        _hasSpace[_address] = true;
        _maxPoints++;
    }

    /* Allows users to manage storage space with 10 IPFS hashes that link to a standard Post. */
    function updateSpace(uint8 slot, bytes32 ipfsHash) public {
        require(slot < 10, "Slot must be 0 - 9.");

        // If there's already something stored in the slot selected and remove a point from its score.
        if (_spaces[msg.sender][slot] != 0)
            _points[_spaces[msg.sender][slot]]--;

        // Store the ipfs hash
        _spaces[msg.sender][slot] = ipfsHash;

        // Add a point
        _points[ipfsHash]++;
    }

    /*  Return the list of IPFS hashes for the provided space. */
    function getSpace(address _address)
        public
        view
        returns (bytes32[10] memory)
    {
        return _spaces[_address];
    }

    /* Remove a space and decrement the max points. */
    function removeSpace(address _address) public {
        require(
            _hasSpace[_address] == true,
            "This address doesn't have a space."
        );
        _hasSpace[_address] = false;

        // Empty their space
        for (uint8 i = 0; i < 9; i++) {
            if (_points[_spaces[_address][i]] > 0)
                _points[_spaces[_address][i]]--;
            _spaces[_address][i] = 0;
        }

        // Decrement max points;
        _maxPoints--;
    }

    /* Return the score for the provided IPFS hash. */
    function getPoints(bytes32 ipfsHash) public view returns (uint256) {
        return _points[ipfsHash];
    }

    /* Return the score for the provided IPFS hash. */
    function getPointsAsPercentageOfTotal(bytes32 ipfsHash)
        public
        view
        returns (uint256)
    {
        return (100 * _points[ipfsHash]) / _maxPoints;
    }

    // /*
    //     There is no capped supply of the coin in this implementation.
    //     The wallet used to deploy the contract can mint any amount and send to any address using this function.
    // */
    // function mint(address to, uint256 amount) public onlyOwner {
    //     _mint(to, amount, "", "");
    // }
}

