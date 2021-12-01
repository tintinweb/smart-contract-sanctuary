// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract WigglyNFT is ERC1155, Ownable{

    constructor() ERC1155("https://nft.wiggly.finance/tokens/{id}.json"){
      _mint(msg.sender, 0, 250, "");
      _mint(msg.sender, 1, 250, "");
      _mint(msg.sender, 2, 250, "");
      _mint(msg.sender, 3, 250, "");
    }

    function mint(address _account, uint256 _id, uint256 _amount) public onlyOwner returns(bool){
      _mint(_account,_id,_amount, "");
      return true;
    }

    function burn(uint256 _id, uint256 _amount) public returns(bool){
      _burn(msg.sender,_id,_amount);
      return true;  
    }

}