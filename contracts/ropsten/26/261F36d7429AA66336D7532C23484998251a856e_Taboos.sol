/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

pragma solidity ^0.5.0;

contract Taboos {
    struct Taboo{
        uint index; // index start 1 to keyList.length
        uint256 no_copies;
        string image_file;
        string title;
        uint256 price;
    }
    uint256 internal _index ;
    mapping(uint256 => Taboo) internal map;
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender==owner,"owner is required");
        _;
    }
    

    function mintNFT(uint256 _no_of_copies , string memory _image_url , string memory _title , uint256 _basePrice) public onlyOwner {
        Taboo storage taboo = map[_index];
         taboo.index = _index;
         taboo.no_copies = _no_of_copies;
         taboo.image_file = _image_url;
         taboo.title = _title;
         taboo.price = _basePrice;
         
         _index +=1;
    }
    
    
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}