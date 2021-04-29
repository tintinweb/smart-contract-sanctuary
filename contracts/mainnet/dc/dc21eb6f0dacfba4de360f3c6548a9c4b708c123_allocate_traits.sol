/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.7.3;

//SPDX-License-Identifier: UNLICENSED
// produced by the Solididy File Flattener (c) David Appleton 2018 - 2020 and beyond
// contact : [email protected]
// source  : https://github.com/DaveAppleton/SolidityFlattery
// released under Apache 2.0 licence
// input  /Users/daveappleton/Documents/akombalabs/trait_allocator/traits/allocate_traits.sol
// flattened :  Monday, 26-Apr-21 04:37:03 UTC
abstract contract IRNG {

    function requestRandomNumber() external virtual returns (bytes32 requestId) ;

    function isRequestComplete(bytes32 requestId) external virtual view returns (bool isCompleted) ; 

    function randomNumber(bytes32 requestId) external view virtual returns (uint256 randomNum) ;
}
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

contract allocate_traits {
    using Strings for *;

    IRNG               rng;
    bytes32 public     stash;
    bool    public     random_processed;
    bool    public     data_folder_set;
    bool    public     _FuzeBlown;
    string  public     baseURI;

    
    uint256 constant   num_og = 90;
    uint256 constant   num_alphas = 900;
    uint256 constant   num_founders = 9000;
    uint256 public     random;
    uint256 public     og_rand;
    uint256 public     alpha_rand;
    uint256 public     founder_rand;

    event ProcessRandom();

    address owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner,"Unauthorised");
        _;
    }

    constructor(address _owner,IRNG _rng) {
        owner = _owner;
        rng = _rng;
    }

    function the_big_red_button() external onlyOwner {
        require(!_FuzeBlown,"You can ony use the BIG RED BUTTON if the fuzes are not blown");
        stash = rng.requestRandomNumber();
        burnDataFolder();
    }

    function ready_to_process() public view returns (bool) {
        return rng.isRequestComplete(stash);
    }

    function process_random() external onlyOwner {
        require(_FuzeBlown,"You need to press the BIG RED BUTTON");
        require(ready_to_process(),"The random number is not ready yet");
        random = rng.randomNumber(stash);
        uint mask = 0xffffffffffffffff; // 8 bytes or 64 bits
        og_rand = (random & mask);
        alpha_rand = (random >> 64) & mask;
        founder_rand = (random >> 128) & mask;
        random_processed = true;
        emit ProcessRandom();
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(random_processed,"Randomization not complete");
        uint id = tokenId;
        if (tokenId < 10) {
            //
        } else if (tokenId < 100) {
            id = ((tokenId + og_rand) % 90) + 10;
        } else if (tokenId < 1000) {
            id = ((tokenId + alpha_rand) % 900) + 100;
        } else if (tokenId < 10000){
            id = ((tokenId + founder_rand) % 9000) + 1000;
        }
        return iTokenURI(id);
    }

    function setDataFolder(string memory _baseURI) external onlyOwner {
        require(!_FuzeBlown,"This data can no longer be changed");
        baseURI = _baseURI;
        data_folder_set = true;
    }

    function burnDataFolder() internal onlyOwner {
        require(data_folder_set,"This data can no longer be changed");
        _FuzeBlown = true;
    }

    function iTokenURI(uint256 tokenId) public view returns (string memory) {
        // reformat to directory structure as below
        string memory folder = (tokenId % 100).toString(); 
        string memory file = tokenId.toString();
        string memory slash = "/";
        return string(abi.encodePacked(baseURI,folder,slash,file,".json"));
    }

}