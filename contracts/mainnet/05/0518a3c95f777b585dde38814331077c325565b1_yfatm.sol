pragma solidity ^0.5.0;

import "ERC20.sol";
import "ERC20Detailed.sol";
contract YFATM is ERC20, ERC20Detailed {
    address owner;
    using SafeMath for uint256;
    ERC20 public token;

    constructor () public ERC20Detailed("YFATOM", "YFATM", 18) {
        _mint(msg.sender, 15000 * (10 ** uint256(decimals())));
        owner=msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}