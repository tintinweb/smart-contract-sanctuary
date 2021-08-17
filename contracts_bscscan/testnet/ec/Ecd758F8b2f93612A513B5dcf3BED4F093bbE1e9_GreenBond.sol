// SPDX-License-Identifier: --🌲--

pragma solidity ^0.8.0;

import './ERC20.sol';

import './SafeMath.sol';

import './Address.sol';

// Manages ownership of Green Bond
contract Ownable {
    
  // Address of treedefi owner
  address public _owner;
  
  /**
	 * @dev Fired in transferOwnership() when ownership is transferred
	 *
	 * @param _previousOwner an address of previous owner
	 * @param _newOwner an address of new owner
	 */
  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner_ The address to transfer ownership to.
   */
  function transferOwnership(address newOwner_) public {
    require(msg.sender == _owner);  
    require(newOwner_ != address(0));
    emit OwnershipTransferred(_owner, newOwner_);
    _owner = newOwner_;
  }

}

/**
 * @title Green Bond Version 1.0
 *
 * @author treedefi
 */
contract GreenBond is ERC20, Ownable {
    
  using SafeMath for uint256;
  
  using Address for address;
  
  // Total number of existing linkers
  uint256 public linkerCount;
  
  // Mapping from address to isLinker
  mapping(address => bool) public isLinker;
  
  // Mapping from linker address to linkerData 
  mapping(address => Link) public linkerData;
  
  // `Link` records data of GreenBond supply of linker 
  struct Link {
    uint256 totalMint;
    uint256 totalBurn;
  }
    
  /**
	 * @dev Fired in mintGreenBond() when green bonds minted  
	 *      successfully to user's address
	 *
	 * @param _linker address defines linker address that mints green bonds to user 
	 * @param _to address of user in which green bonds are minted  
	 * @param _value defines amount of green bonds minted
	 */
  event Minted(
    address indexed _linker,
    address indexed _to,
    uint256 _value
  );
  
  /**
	 * @dev Fired in burnGreenBond() when green bonds burned  
	 *      successfully to user's address
	 *
	 * @param _linker address defines linker address that burns green bonds of user 
	 * @param _to address of user from which green bonds are burned  
	 * @param _value defines amount of green bonds burned
	 */
  event Burned(
    address indexed _linker,
    address indexed _to,
    uint256 _value
  );
  
  /**
	 * @dev Fired in addLinker() and removeLinker() when linker   
	 *      added/removed successfully by treedefi owner
	 *
	 * @param _by defines address which added/removed linker contract  
	 * @param _linker defines address of linker contract   
	 * @param _isLinked defines if linker contract is added or removed
	 */
  event Linking(
    address indexed _by,
    address indexed _linker,
    bool _isLinked
  );
  
  /**
	* @dev Creates/deploys Green Bond Version 1.0
	*
	*/
  constructor() ERC20('Green Bond', 'GreenBond') {
      _owner = _msgSender();
  }
  
  /**
    * @dev Returns the address of treedefi owner.
    */
  function getOwner() external view returns (address) {
     return _owner;
  }
  
  /** 
    * @dev Adds address of linker contract for mint/burn role
    * 
    * @notice restricted function, should be called by Owner only
    * @notice only contract address can be added as linker
    * @param linker_ address of linker contract
    */
  function addLinker(address linker_) external {
      
      require(
        _msgSender() == _owner,
        "Treedefi: Only Owner can add linker"
      );
      
      require(
        !isLinker[linker_],
        "Treedefi: address already linked"
      );
      
      require(
        Address.isContract(linker_),
        "Treedefi: invalid address"
      );
    
    // Add linker
    isLinker[linker_] = true;
    
    // Increment linker counter
    linkerCount++;
    
    // Emit an event
    emit Linking(_msgSender(), linker_, true);

  }
  
  /** 
    * @dev Removes address of linker contract for mint/burn role
    * 
    * @notice restricted function, should be called by Owner only
    * @param linker_ address of linker contract
    */
  function removeLinker(address linker_) external {
      
      require(
        _msgSender() == _owner,
        "Treedefi: Only Owner can remove linker"
      );
      
      require(
        isLinker[linker_],
        "Treedefi: address is not linked"
      );

    // Removes linker
    isLinker[linker_] = false;
    
    // Decrement linker counter
    linkerCount--;
    
    // Emit an event
    emit Linking(_msgSender(), linker_, false);
    
  }
  
  /** 
    * @dev Mint green bonds to given address
    * 
    * @notice restricted function, should be called by linker contract only
    * @param to_ defines address to which green bonds are going to be minted 
    * @param amount_ defines amount of green bonds to be minted
    * @return success_ defines status of function execution
    */
  function mintGreenBond(
    address to_,
    uint256 amount_
  )
    external
    returns(bool success_)
  {
    
    require(
        isLinker[_msgSender()],
        "Treedefi: Only linker can mint green bonds"
    );
    
    // Mint green bonds to given address  
    _mint(to_, amount_);
    
    // Add minted amount to linker account
    linkerData[_msgSender()].totalMint = linkerData[_msgSender()].totalMint.add(amount_);
    
    // Emit an event
    emit Minted( _msgSender(), to_, amount_);
    
    // Give callback
    return true;
    
  }    
  
  /** 
    * @dev Burn green bonds of given address
    * 
    * @notice restricted function, should be called by linker contract only
    * @param to_ defines address from which green bonds are going to be burned
    * @param amount_ defines amount of green bonds to be burned
    * @return success_ defines status of function execution
    */
  function burnGreenBond(
    address to_,
    uint256 amount_
  )
    external
    returns(bool success_)
  {
    
    require(
        isLinker[_msgSender()],
        "Treedefi: Only linker can burn green bonds"
    );
      
    // Burn green bonds from given address  
    _burn(to_, amount_);
    
    // Substract burned amount from linker account
    linkerData[_msgSender()].totalBurn = linkerData[_msgSender()].totalBurn.add(amount_);
    
    // Emit an event
    emit Burned( _msgSender(), to_, amount_);
    
    // Give callback
    return true;
    
  }
  
}