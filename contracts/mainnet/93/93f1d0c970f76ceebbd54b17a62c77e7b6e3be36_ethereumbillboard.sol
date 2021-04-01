/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;
contract ethereumbillboard {
    bytes32[] private tags;
    bytes32[] private urls;
    bytes32[] private imgs;
    address private owner;
    uint256 private cost = 0.005 ether; //per char
    modifier ceo {
        require(owner == msg.sender);
        _;
    }
   constructor ()  {
    owner = msg.sender;
   }
   function changeOwner(address newO) public ceo {
        owner = newO;
    }
    receive() external payable {}
    function addTag(string calldata tag_weight, string calldata url, string calldata imgUrl, uint256 weight) external payable {
        require(weight>0);
        if(msg.sender!=owner) require(msg.value>=(bytes(tag_weight).length-2) * cost * weight );
        tags.push(sToB32(tag_weight));
        urls.push(sToB32(url));
        imgs.push(sToB32(imgUrl));
    }
    function withdraw() ceo public  {
        payable(msg.sender).transfer(address(this).balance);
    }
    function chgCost(uint256 price) ceo public {
        cost=price;
    }
    function sToB32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
    function strA(bytes32[] memory bA) internal pure returns (string[]  memory){
        string[] memory sA = new string[](bA.length);
            for (uint i = 0; i < bA.length; i++) {
                sA[i] = string(abi.encodePacked(bA[i]));
            }
            return sA;
    }
   function getTags()  public view returns ( string[] memory tagsA, string[] memory urlsA, string[] memory imgUrlsA,uint256 price) {
      tagsA = strA(tags);
      urlsA = strA(urls);
      imgUrlsA = strA(imgs);
      price = cost;
   }
}