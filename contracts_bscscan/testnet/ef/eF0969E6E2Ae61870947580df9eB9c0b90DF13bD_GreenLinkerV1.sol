// SPDX-License-Identifier: --🌲--

pragma solidity ^0.8.0;

import './SafeMath.sol';

// Get a link to Green Bond BEP20 smart contract
interface IGreenBond {
    
    // Mint new tokens
    function mintGreenBond(
        address user,
        uint256 amount
    ) external returns (bool success);
    
    // Burn existing tokens
    function burnGreenBond(
        address user,
        uint256 amount
    ) external returns (bool success);
    
}

// Get a link to treedefi collectibles BEP721 smart contract
interface ITreedefiForest {
    
    // `Generation` records amount generated for specific epoch
    struct Generation {
        uint256 carbonCredit;
        uint256 greenBond;
    }
    
    // `Epoch` records holding of tree for specific duration
    struct Epoch {
        uint256 start;
        uint256 end;
        uint256 treeId;
    }
    
    // returns `Generation` for given epoch
    function _epochGeneration(
        address user,
        uint256 index
    ) external returns (Generation memory generation);
    
    // returns `Epoch` for given index
    function _epochData(
        address user,
        uint256 index
    ) external returns (Epoch memory epochData);
    
    // returns owner address for given treeId
    function ownerOf(
      uint256 _id
    ) external returns (address);
    
    // returns operator address for given treeId
    function getApproved(
      uint256 tokenId
    ) external returns (address);
    
    // returns address of treedefi owner
    function getOwner() external returns (address);

}


/**
 * @title Green Bond Linker Version 1.0
 *
 * @author treedefi
 */
contract GreenLinkerV1 {
    
  using SafeMath for uint256; 
  
  // Address of treedefi owner
  address public _owner;
  
  // Link to treedefi collectibles
  ITreedefiForest private NFTREE; 
  
  // Link to green bonds 
  IGreenBond private GREENBOND;
  
  // Total number of carbon credits converted from green bonds 
  uint256 public _totalCarbonCredits;
  
  // Mapping from address to number of green bonds minted from co2 offset of specific tree 
  mapping(address => mapping(uint256 => uint256)) public _greenBondMinted; 
  
  // Mapping from address to `Conversion` data
  mapping(address => Conversion[]) public _carbonCreditConverted;
  
  // Mapping from treeId to greenbond supply generated from co2 offset
  mapping(uint256 => uint256) public _treeSupply;
  
  // `Conversion` records data of green bond to carbon credit conversion
  struct Conversion {
    uint256 _treeId;  
    uint256 _amount;
    uint256 _time;
  }
  
  /**
	 * @dev Fired in _mintGreenBond() when green bonds minted  
	 *      successfully to user's address
	 *
	 * @param _to tokens minted to this address 
	 * @param _by tokens minted by this address 
	 * @param _epochIndex an index number of epoch
	 * @param _value an amount that is minted
	 */  
  event GreenBond(
    address indexed _to,
    address indexed _by,
    uint256 indexed _epochIndex,
    uint256 _value
  );
  
  /**
	 * @dev Creates/deploys Green Bond Linker Version 1.0
	 *
	 * @param nftree_ address of treedefi collectibles
	 * @param greenBond_ address of green bonds
	 */    
  constructor(address nftree_, address greenBond_) {
     
     // verify inputs are set
	 require(nftree_ != address(0), "Treedefi: Treedefi Collectibles address is not set");
	 require(greenBond_ != address(0), "Treedefi: Green Bond address is not set");
	 
	 // setup smart contract internal state
     NFTREE = ITreedefiForest(nftree_);
     GREENBOND = IGreenBond(greenBond_);
     _owner = NFTREE.getOwner();
	
  }
  
  /**
    * @dev Returns the address of treedefi owner
    */
  function getOwner() external view returns (address) {
     return _owner;
  }
  
  /** @notice upgrades admin address to existing NFTREE V2 owner
     *        as ownership of NFTREE V2 is transferable
     */
  function upgradeOwnerAddress() external {
    _owner = NFTREE.getOwner();
  }
  
  /**
    * @dev Returns number of total conversion made by given address
    * 
    * @param address_ address of user 
    */
  function getConversionCount(address address_) 
    external
    view
    returns(uint256)
  {
     return _carbonCreditConverted[address_].length;
  }
  
  /** @dev Mint Green Bond and assign it to user, increasing the total supply
     *@param to_ defines address of assignee
     *@param amount_ array defines amount of green bonds are going to be minted
     *@param epochIndex_ array defines index from which green bonds are going to be minted 
     *@return success_ bool defines status of function execution  
     */
  function mintGreenBond(
    address to_,
    uint256[] memory amount_,
    uint256[] memory epochIndex_
  )
    external
    returns(bool success_)
  {

    require(
        amount_.length == epochIndex_.length,
        "Treedefi: Invalid input data"
    );
    
    uint256 _length = amount_.length;
    
    for(uint i; i < _length; i++){
        // Mint green bonds
        _mintGreenBond(
            to_,
            amount_[i],
            epochIndex_[i]
        );    
    }
    
    return true;
    
  }    
  
  /** @dev Called internally to mint green bonds to given address for given epoch 
     *@param to_ defines address of assignee
     *@param amount_ defines amount of green bonds are going to be minted
     *@param epochIndex_ defines index from which green bonds are going to be minted 
     */
  function _mintGreenBond(
    address to_,
    uint256 amount_,
    uint256 epochIndex_
  ) 
    internal
  {
     
     // Get green bonds generation data from treedefi collectibles 
     uint256 _greenBondGeneration = NFTREE._epochGeneration(to_, epochIndex_).greenBond
                                   .mul(1E18); 
    
     require(
       amount_ > 0,
       " Treedefi: Please provide valid amount"
     );
     
     require(
       _greenBondGeneration >= amount_.add(_greenBondMinted[to_][epochIndex_]),
       " Treedefi: Given amount is more than green bonds generated for epoch"
     );
     
     // Get tokenId of tree associated with given epoch from treedefi collectibles
     uint256 _treeId = NFTREE._epochData(to_, epochIndex_).treeId;
     
     // Mint green bonds to given address
     bool _success = GREENBOND.mintGreenBond(to_, amount_);
     
     require(
       _success,
       " Treedefi: Mint request failed"
     );
     
     // Add minted amount to given epoch
     _greenBondMinted[to_][epochIndex_] = _greenBondMinted[to_][epochIndex_].add(amount_);
     
     // Add minted amount to given tree
     _treeSupply[_treeId] = _treeSupply[_treeId].add(amount_);
     
     // Emit an event
     emit GreenBond( to_, msg.sender, epochIndex_, amount_);
     
  }
  
  /** @dev Burn Green Bond and assign Carbon Credit to user, decreasing the total supply
     *@param amount_ array defines amount of green bonds are going to be converted
     *@param treeId_ array defines tokenId of tree from which carbon credits are going to be generated  
     *@return success_ bool defines status of function execution  
     */
  function convertGreenBondToCarbonCredit(
    uint256[] memory amount_,
    uint256[] memory treeId_
  ) 
    external
    returns(bool success_)
  {
  
    require(
        amount_.length == treeId_.length,
        "Treedefi: Invalid input data"
    );
    
    uint256 _length = amount_.length;
    
    for(uint i; i < _length; i++){
        // Burn green bonds and generate carbon credits
        _convertGreenBondToCarbonCredit(
            amount_[i],
            treeId_[i]
        );    
    }
    
    return true;
    
  }
  
  /** @dev Called internally to burn Green Bond and assign Carbon Credit to user
     *@param amount_ defines amount of green bonds are going to be converted
     *@param treeId_ defines tokenId of tree from which carbon credits are going to be generated  
     */
  function _convertGreenBondToCarbonCredit(
    uint256 amount_,
    uint256 treeId_
  ) 
    internal 
  {
      
     require(
       amount_ > 0,
       " Treedefi: Please provide valid amount"
     );
     
     require(
       amount_ <= _treeSupply[treeId_],
       " Treedefi: Provided value exceeds green bond supply of given tree "
     );
     
     // Burn green bonds of given address
     bool _success = GREENBOND.burnGreenBond(msg.sender, amount_);
     
     require(
       _success,
       " Treedefi: Burn request failed"
     );
     
     // Remove burned amount from given tree
     _treeSupply[treeId_] = _treeSupply[treeId_].sub(amount_);
     
     // Increment carbon credits conversion counter
     _totalCarbonCredits = _totalCarbonCredits.add(amount_);
     
     // Read `Conversion`
     Conversion memory _conversion = Conversion(treeId_, amount_, block.timestamp);
     
     // Record `Conversion` for given address
     _carbonCreditConverted[msg.sender].push(_conversion);  
     
  }
  
}