/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;

contract MP {

address  owner = 0x9f9F60007A7b5585A918E6B9d2e88C3d24839512;
address Econ = 0xF977E295e3FCcAFbE3C70A7bad4C3451Bd8D6C07;
mapping (address =>uint256) soldlist;
mapping (uint256 =>address) soldtoken;
uint256 ts = 0; //count for total sold
uint256 price = 2000000000000;

    KGT kg = KGT(Econ);

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
payable(owner).transfer(msg.value);
soldlist[to] = tokenid;
soldtoken[tokenid] = to;

ts +=1;
return (true);
}


}


interface KGT{

    function mint(address _to, uint256 _tokenId) external;
}