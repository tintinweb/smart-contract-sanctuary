/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

pragma solidity ^0.6.11;

interface Mintable {
  function mintMSD(address token, address usr, uint256 wad) external;

  function burn(address usr, uint256 wad) external;
}

contract TestMint{
    address public l2USX;
    address public l2msdController;

    constructor(address _l2USX, address _l2msdController) public {
        l2USX = _l2USX;
        l2msdController = _l2msdController;
    }

    function mint(address to, uint256 amount) public {
        Mintable(l2msdController).mintMSD(l2USX, to, amount);
    }
}