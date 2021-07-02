// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

contract REBEL is ERC20, ERC20Burnable, Pausable, AccessControl {
    using SafeMath for uint256;
  
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    uint256 public constant cap = 1700000000000000000000000000;
    uint256 private _remainingSupply;
    uint256 public developersFunding;
    uint256 public initialLiquityFunding;
    uint256 public initialairDropFunding;
    
    address public developersAddress = 0x78225f18a19F26041c616c464a57403ffb94acCC;
    address public initialLiquityAddress = 0xfda48cC92EE5354468EA46E9bd06d3EaBA8C4e16;
    address public initialAirdropAddress = 0x09b5057618751691dBE448Cd1f613Ef9E417534D;

    constructor() ERC20("Confederate Coin", "REBEL") {
        _setupRole(DEFAULT_ADMIN_ROLE, developersAddress);
        _setupRole(PAUSER_ROLE, developersAddress);
        _setupRole(MINTER_ROLE, developersAddress);
        _remainingSupply = cap;
        developersFunding = cap.mul(10).div(100);
        initialLiquityFunding = cap.mul(2).div(100);
        initialairDropFunding = cap.mul(1).div(100);
        _mint(developersAddress, developersFunding);
        _mint(initialLiquityAddress, initialLiquityFunding);
        _mint(initialAirdropAddress, initialairDropFunding);
        reduceSupplyBy(developersFunding);
        reduceSupplyBy(initialLiquityFunding);
    }

    
    function remainingSupply() public view returns (uint256) {
      return _remainingSupply;
    }
    
    function reduceSupplyBy(uint256 amount) private {
      _remainingSupply = _remainingSupply - amount;
    }
    
    function pause() public {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _pause();
    }

    function unpause() public {
        require(hasRole(PAUSER_ROLE, msg.sender));
        _unpause();
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender));
        require(totalSupply() + amount <= cap, "ERC20Capped: cap exceeded");
        reduceSupplyBy(amount);

        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}