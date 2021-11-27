/**
 *Submitted for verification at polygonscan.com on 2021-11-26
*/

// SPDX-License-Identifier: GPL-0.3
/**
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>
*/
pragma solidity ^0.8.7;
/**
 * Interface as ERC20 standard
 */

interface IFRC20 {
    
  /**
   * Returns string of token name
   */
  function name() external view returns (string memory);
  
  /**
   * Returns string of token symbol
   */
  function symbol() external view returns (string memory);

  /**
   * Returns uint8 of token decimals
   */
  function decimals() external view returns (uint8);

  /**
   * Returns amount of token supply
   */
  function totalSupply() external view returns (uint256);

  /**
   * Return amount balance of specific address
   */
  function balanceOf(address guy) external view returns (uint256);

  /**
   * Function for move balance from one address to another address
   * This function will return boolean after proccess was completed
   */
  function transfer(address dst, uint256 wad) external returns (bool);

  /**
   * Return the remaining amout of token that spender can spend
   */
  function allowance(address src, address dst) external view returns (uint256);

  /**
   * Function to approve spender for spending amount of token
   */
  function approve(address dst, uint256 wad) external returns (bool);

  /**
   * Same like transfer function but here the sender can be anyone that have access (allowed) to source (holder)
   */
  function transferFrom(address src, address dst, uint256 wad) external returns (bool);

  /**
   * Event that will emited after transfer / transferFrom function
   */
  event Transfer(address indexed src, address indexed dst, uint256 wad);
  
  /**
   * Event that will emited after user approve a transaction
   */
  event Approval(address indexed src, address indexed dst, uint256 wad);

}


/**
 * Extension for using math in other contracts
 */
library  Math {
  
  /**
   * Sum two number and return the results
   */
  function add(uint x, uint y) internal pure returns (uint z) 
  {
        
    require((z = x + y) >= x);
        
  }

  /**
   * Sub two number and return the result
   */
  function sub(uint x, uint y) internal pure returns (uint z) 
  {
        
    require((z = x - y) <= x);
        
  }

}


/**
 * Main contract for ERC20 token standard
 * Using IFRC for the interface
 * Using Math for math operations
 */
contract FRC20 is IFRC20 {

  using Math for uint;

  mapping(address => uint256) private $balanceOf;
  mapping(address => mapping(address => uint256)) private $allowances;
    
  uint256 private $totalSupply;
  string private $name;
  string private $symbol;

  /**
   * Contract constructor that will set the token name and symbol
   */
  constructor(string memory _name, string memory _symbol)
  {

    $name = _name;
    $symbol = _symbol;
        
  }

  /**
   * As defined in Interface this will return the value of token name
   */
  function name() public view virtual override returns (string memory)
  {

    return $name;
        
  }

  /**
   * As defined in Interface this will return the value of token aymbol
   */
  function symbol() public view virtual override returns (string memory)
  {
        
    return $symbol;
        
  }

  /**
   * As defined in Interface this will return the value of token decimals
   */
  function decimals() public view virtual override returns (uint8)
  {
        
    return 18;
        
  }

  /**
   * As defined in Interface this will return the amount of token supply
   */
  function totalSupply() public view virtual override returns (uint256)
  {
        
    return $totalSupply;
        
  }

  /**
   * As defined in Interface this will return the amount of balance for specific address
   */
  function balanceOf(address guy) public view virtual override returns (uint256)
  {
        
    return $balanceOf[guy];
        
  }

  /**
   * As defined in Interface this will return the amount of allowances
   */
  function allowance(address src, address dst) public view virtual override returns (uint256)
  {
        
    return $allowances[src][dst];
        
  }

  /**
   * Transfer function to move token from one address to another
   */
  function transfer(address dst, uint256 wad) public virtual override returns (bool)
  {
  
    /**
     * Instead using the logic for transfer here, we call the transferFrom from function to handle the logic
     * we set the token source to msg.sender(transaction trigger)
     * for the destination we inherit from above as dst
     * and the amount of token is wad
     */
    return transferFrom(msg.sender, dst, wad);

  }

  /**
   * Transfer function for third party
   * Unlike transfer above, this function allow third party to move your balance to other address if the third party was allowed to do that
   */
  function transferFrom(address src, address dst, uint256 wad) public virtual override returns (bool)
  {
  
    /**
     * From here we call _safeTransfer function and pass the params to handle the logic
     */
    return _safeTransfer(src, dst, wad);
        
  }

  /**
   * function for handle transfer
   */
  function _safeTransfer(address src, address dst, uint256 wad) internal returns (bool)
  {
    
    /**
     * Transfer from zero address is porhibited so we check if the sender are not the zero address
     */
    require(src != address(0), "Transfer from zero address");

    /**
     * Also transfer to zero address was porhibited, but for that we have burn function
     */
    require(dst != address(0), "Transfer to zero address");

    /**
     * Check if the balance of sender was enough to transfer
     */
    require(balanceOf(src) >= wad, "Insufficient balance");

    /**
     * If sender was not the transaction caller, we need to verify if the transaction caller have permission to spend the token
     */
    if (src != msg.sender)
      {
        
        /**
         * Verify if the transaction caller have permision and the alowance was enough for transaction
         */
        require(allowance(src, dst) >= wad, "Insufficient allowance");

        /**
         * Decrease allowances of transaction caller using Sub function
         */
        $allowances[src][dst]= allowance(src, dst).sub(wad);
            
      }

      /**
       * Set the balance of sender after transfer
       */
      $balanceOf[src] = balanceOf(src).sub(wad);

      /**
       * Set the balance of recipient after transfer
       */
      $balanceOf[dst] = balanceOf(dst).add(wad);
      
      /**
       * Emit the transfer event to write transaction history on blockchain
       */
      emit Transfer(src, dst, wad);

      // return true of the proccess wass successed
      return true;
        
    }

    /**
     * Function for approving third party to spend your balance
     */
    function approve(address dst, uint256 wad) public virtual override returns (bool)
    {

      /**
        * Approving for zero address was porhibited so we check that here
        */
      require(dst != address(0), "Approval for zero address");

      /**
       * set the allowance
       */
      $allowances[msg.sender][dst] = wad;

      /**
       * Emit the Approval event to blockchain
       */
      emit Approval(msg.sender, dst, wad);

      /**
       * Return true if the transaction was successed
       */
      return true;
        
    }

    /**
     * mint function for minting new token
     * this will be used once when the token was deployed
     */
    function _mint(address dst, uint256 wad) internal
    {

      /**
       * check if destination address is not zero address
       */
      require(dst != address(0), "Mint to zero address");

      /**
       * set the totalSupply
       */
      $totalSupply = totalSupply().add(wad);

      /**
       * send the token to destination address
       */
      $balanceOf[dst] = balanceOf(dst).add(wad);

      /**
       * emit Transfer event to write transaction into blockchain
       */
      emit Transfer(address(0), dst, wad);
        
    }

    /**
     * burn function for burning the token
     */
    function _burn(address src, uint256 wad) internal
    {

      /**
       * Check if the source is valid address
       */
      require(src != address(0), "Burn from zero address");

      /**
       * Check if the source have enough balance
       */
      require(balanceOf(src) >= wad, "Insufficient balance");

      /**
       * check if source is the source is transaction caller,
       * if no, verify if the caller has permission to spend source balance
       */
      if (src != msg.sender)
        {

          /**
           * Check if transaction caller still have enough balance to spend
           */
          require(allowance(src, msg.sender) >= wad, "Insufficient allowance");

          /**
           * Decrease allowances value of the transaction caller from source address
           */
          $allowances[src][msg.sender] = allowance(src, msg.sender).sub(wad);

        }

        /**
         * set balance after burn
         */
        $balanceOf[src] = balanceOf(src).sub(wad);

        emit Transfer(src, address(0), wad);

    }
    
}


/**
 * ERC20 burnable support
 */
abstract contract FRC20Burnable is FRC20 {

  using Math for uint;

  /**
   * Burn function for burning an token
   */
  function burn(uint256 wad) public virtual
  {

    /**
     * Using erc20 burn function
     */
    _burn(msg.sender, wad);

  }

  /**
   * Function for burn token from someone address that authorize you for spending their balance
   */
  function burnForm(address src, uint256 wad) public virtual
  {

    /**
     * Using erc20 burn function
     */
    _burn(src, wad);

  }

}

/**
 * Contract for FUOC token
 */
contract FUOC is FRC20 {

  /**
   * constructor for defining token name, token symbol, and total supply
   */
  constructor() FRC20("Fuoc Token", "FUOC")
  {

    /**
     * This was initial mint of token to create the supply
     */
    _mint(msg.sender, 1000000000 ether);
    
  }
    
}