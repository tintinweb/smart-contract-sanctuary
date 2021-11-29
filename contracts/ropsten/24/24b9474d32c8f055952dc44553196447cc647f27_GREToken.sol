// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ERC20.sol";

contract GREToken is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    constructor() ERC20('Gaming Real Estate Metaverse', 'GRE') {
        _mint(msg.sender, 1000000000 * 10 ** 18);
    }

    function mint(uint256 mintAmount) public onlyOwner{
        _mint(msg.sender, mintAmount);
    }
    
    function burn(uint256 burnAmount) public onlyOwner{
        _burn(msg.sender, burnAmount);
    }

}