/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

pragma solidity 0.8.7;

contract greeter{
    
    string greeting = "Hallo ";
    uint256 price = 1 gwei;
    address payable public owner;
    
    constructor(){
        owner = payable(msg.sender);
    }
    
    function greetMe(string memory _name) public payable returns(string memory _greeting){
        if(msg.value >= price){
            return string(abi.encodePacked(greeting, _name));
        }else{
            return string(abi.encodePacked(uint2str(msg.value), " Wei sind zu wenig (min. 1 Gwei!)"));
        }
    }
    
    function withdraw() public returns (bool success){
        if(msg.sender == owner){

            (bool success, bytes memory data) = owner.call{value: address(this).balance}("");
            
            // Let the user know, whether the sending was successful or not.
            return success;
        }
    }
    
    function getBalance() public view returns(uint balance){
        return address(this).balance;
    }

 function uint2str(uint256 _i) internal pure returns (string memory str){
        if (_i == 0){
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0){
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }


}