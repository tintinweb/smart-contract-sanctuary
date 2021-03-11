//Telcoin, LLC.
pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Mintable.sol";
import "./Ownable.sol";


contract StableCoin is ERC20Burnable, ERC20Mintable, Ownable {
  /**
   * @dev Initializes the contract by setting `name`, `symbol`, 'decimals', and creating an initial supply of tokens
   */
  constructor (string memory name, string memory symbol, uint8 decimal, uint256 initialSupply) public ERC20(name, symbol) Ownable() {
    _setupDecimals(decimal);
    _mint(msg.sender, initialSupply * (10 ** uint256(decimals())));
  }

  /**
   * @dev Removes tokens from circulation
   * @param amount the quantity that is to be removed
   */
  function burn(uint256 amount) public override onlyOwner {
      _burn(_msgSender(), amount);
  }

  /**
   * @dev Removes tokens from circulation from a source other than token owner, with owner's approval
   * @param account the address the tokens are being burned from
   * @param amount the quantity that is to be removed
   */
  function burnFrom(address account, uint256 amount) public override onlyOwner {
      uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");
      _approve(account, _msgSender(), decreasedAllowance);
      _burn(account, amount);
  }

  /**
   * @dev introduces tokens into circulation
   * @param amount the quantity that is to be added
   */
  function mint(uint256 amount) public override onlyOwner {
      _mint(_msgSender(), amount);
  }

  /**
   * @dev introduces tokens into circulation at the address provided
   * @param account the recipient of the newly minted tokens
   * @param amount the quantity that is to be added
   */
  function mintTo(address account, uint256 amount) public override onlyOwner {
      _mint(account, amount);
  }
}