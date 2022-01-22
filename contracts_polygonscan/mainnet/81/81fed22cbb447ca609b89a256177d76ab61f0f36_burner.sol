// SPDX-License-Identifier: UNLICENCED
pragma solidity >0.8.0;
import "./Ownable.sol";
interface ghn {
    function burn(uint256 tokenId) external;
    function tokenOfOwnerByIndex(address owner ,uint256 index)external view returns(uint256);
}
contract burner is Ownable{
    address nft=address(0xE953aa1CFD934d04Ff7c92f46f7d2D03c736D696);

    function batchBurn(uint256 _amount) external onlyOwner{
        for (uint256 i = 0; i < _amount; i++) {
            ghn(nft).burn(ghn(nft).tokenOfOwnerByIndex(address(this),0));
        }
    }
}