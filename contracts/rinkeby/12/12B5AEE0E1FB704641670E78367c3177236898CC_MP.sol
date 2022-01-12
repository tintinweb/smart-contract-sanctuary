// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;

contract MP {

address  owner = 0x9f9F60007A7b5585A918E6B9d2e88C3d24839512;
address Econ = 0xd9145CCE52D386f254917e481eB44e9943F39138;
mapping (address =>uint256) soldlist;
mapping (uint256 =>address) soldtoken;
uint256 ts = 0; //count for total sold
uint256 price = 2000000000000;

    KGT kg = KGT(Econ);
    ERC721 Er = ERC721(Econ);



function totalsold() public view returns(uint256) {
require(msg.sender == owner,"only for owner");

return(ts);
}


function getprice()public view returns(uint256){
    return(price);

}

function buy(address to,uint256 tokenid) public payable returns(bool){


require(soldtoken[tokenid] == address(0),"Token Invalid or Already sold");
require(tokenid >= 0);
require(tokenid < 100);
require(msg.value >= 0.002 ether ,"Value less then the price" );
kg.mint(to,tokenid);
soldlist[to] = tokenid;
soldtoken[tokenid] = to;
ts +=1;
return (true);
}


}


interface KGT{

    function mint(address _to, uint256 _tokenId) external;
}

interface  ERC721{


    function balanceOf(address owner) external view returns (uint256 balance);


    function ownerOf(uint256 tokenId) external view returns (address owner);

    function symbol() external view  returns (string memory);


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}