// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

contract REBEL is ERC20, ERC20Burnable, AccessControl {
    using SafeMath for uint256;
      
    uint256 public constant cap = 1700000000000000000000000000;
    uint256 private _remainingSupply;
    uint256 public developersFunding;
    uint256 public liquityFunding;
    
    address public developersAddress = 0x78225f18a19F26041c616c464a57403ffb94acCC;
    address public liquityAddress = 0xfda48cC92EE5354468EA46E9bd06d3EaBA8C4e16;

    constructor() ERC20("Confederate Coin", "REBEL") {
        _setupRole(DEFAULT_ADMIN_ROLE, developersAddress);
        _remainingSupply = cap;
        
        developersFunding = cap.mul(10).div(100);
        _mint(developersAddress, developersFunding);
        reduceSupplyBy(developersFunding);
        
        liquityFunding = cap.mul(90).div(100);
        _mint(liquityAddress, liquityFunding);
        reduceSupplyBy(liquityFunding);
    }

    function remainingSupply() public view returns (uint256) {
      return _remainingSupply;
    }
    
    function reduceSupplyBy(uint256 amount) private {
      _remainingSupply = _remainingSupply - amount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}