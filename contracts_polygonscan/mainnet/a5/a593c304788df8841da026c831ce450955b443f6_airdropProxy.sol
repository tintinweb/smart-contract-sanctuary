/**
 *Submitted for verification at polygonscan.com on 2021-09-27
*/

//pragma solidity ^0.4.24;
pragma solidity ^0.6.12;
//pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT
interface IERC20{
    
    function transfer(address _to, uint256 _value) external returns (bool success);
    function symbol() external view returns(string memory);
    function balanceOf(address owner) external view returns (uint256 balance);
}
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721  {
    
    function balanceOf(address owner) external view returns (uint256 balance);
    function name() external view returns (string memory);
    
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    
    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

   
}

contract airdropProxy {//is IERC20,IERC721,IERC721Enumerable {
    address   public  manager;
    mapping(uint=>bool) public lootStatus;
    address  public nft;
    address  public ft;
    uint  public fee;
    uint  public airDropVolum;
    string  public describtion;
    
    constructor () public {
        manager=msg.sender;
    }
    
    function setPara( address ftAddr,uint volum, address nftAddr,uint _fee,string memory _describtion) public {
        require(msg.sender==manager," manager only");
        nft=nftAddr;
        ft=ftAddr;
        airDropVolum=volum;
        fee=_fee;
        describtion=_describtion;
        
    }
    
    function claim() public  {
        /*
        if(fee>0) {
            require( msg.value>=fee,"fee is not enough");
            if(msg.value>fee) msg.sender.transfer( msg.value-fee);
            manager.transfer(fee);
        }
        */
        uint numNFT=IERC721(nft).balanceOf(msg.sender);
        require( numNFT>0," you have no loot ");
        uint i;
        uint tid;
        uint nn;
        for( i=0; i< numNFT; i++) {
            tid= IERC721Enumerable(nft).tokenOfOwnerByIndex(msg.sender, i);
            if(lootStatus[tid]==false) {
                lootStatus[tid]=true;
                nn++;
            }
            
        }
        IERC20(ft).transfer(msg.sender, airDropVolum * nn);
    }
    function userNFTblance(address user) public view returns(uint){
        return(IERC721(nft).balanceOf(user));
        
    }
    function ERC20Symbol()public view returns(string memory){
        return IERC20(ft).symbol();
    }
    function ERC721name()public view returns(string memory){
        return IERC721(nft).name();
    }
    function ownerIndex2TokenId(uint index) public view returns(uint){
        
        return IERC721Enumerable(nft).tokenOfOwnerByIndex(msg.sender, index);
    }
    function setLootStatus(uint tokenId,bool status) public {
        require(msg.sender==manager);
        lootStatus[tokenId]=status;
        
    }
    function getERC20TokenAmount() public view returns(uint){
        return IERC20(ft).balanceOf(address(this));
    }
    function withDrawTokens(uint v,address _dst)public {
        require(msg.sender==manager);
        uint tt=IERC20(ft).balanceOf(address(this));
        if(v==0) v=tt;
        IERC20(ft).transfer(_dst, v);
        
    }
    function withdrawHT(address payable _dst) external {
        require(msg.sender==manager);
        _dst.transfer(address(this).balance);
    }
    receive() external payable{
        if(msg.value > 0) {
         //msg.sender.transfer(msg.value);
            claim();
        }
        else {}
            claim();
            
    }
    
    fallback() external {
        claim();
    }
   
    function kill(address payable aa) public {
        require(msg.sender==manager);
        
        selfdestruct(aa);
    }
}