/**
 *Submitted for verification at BscScan.com on 2021-08-30
*/

interface IERC1155 {
    function mint(address to, uint256 tokenId, uint256 value) external;
}

contract Faucet {


    function claimFaucet(IERC1155 nft1155,address sender) public {
        nft1155.mint(sender, 205001, 10);
        for(uint256 i =201001; i<201012;i++){
              nft1155.mint(sender, i, 2);
        }
          for(uint256 i =206001; i<206011;i++){
              nft1155.mint(sender, i, 2);
        }
    }
}