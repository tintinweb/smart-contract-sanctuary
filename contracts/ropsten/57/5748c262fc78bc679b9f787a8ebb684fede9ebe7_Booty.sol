pragma solidity 0.8.10;

// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./ERC20.sol";
import "./IBooty.sol";
import "./SafeMath.sol";

contract Booty is IBooty, ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private immutable _cap = 1e27;

  // Allowlist of addresses to mint or burn
  mapping(address => bool) public controllers;
  
  constructor() ERC20("Booty", "$BOOTY") {}
  
    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

  /**
   * Mint $BOOTY to a recipient.
   * @param to the recipient of the $BOOTY
   * @param amount the amount of $BOOTY to mint
   */
  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    require(ERC20.totalSupply() < cap(), "ERC20: Cap reached..");
    
    if (ERC20.totalSupply().add(amount) > cap()) {
        uint256 lastMintableAmount = cap().sub(ERC20.totalSupply());
        super._mint(to, lastMintableAmount);
    }

    if (ERC20.totalSupply().add(amount) <= cap()) {
        super._mint(to, amount);
    }
  }

  /**
   * Burn $BOOTY from a holder.
   * @param from the holder of the $BOOTY
   * @param amount the amount of $BOOTY to burn
   */
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  /**
   * Enables an address to mint / burn.
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * Disables an address from minting / burning.
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
  
  // @Dev transfer any ERC20 token from this address..
  function transferAnyERC20Token(ERC20 tokenAdd, address recipient, uint256 amount) public onlyOwner {
      ERC20(tokenAdd).transfer(recipient, amount);
  }
}