// SPDX-License-Identifier: --🌲--

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

import "./SafeMath.sol";

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
 * @title Treedefi Forest Nftree Version 2.0
 *
 * @author treedefi
 */
contract NftreeV2 is ERC721Enumerable, Ownable {
      
  using SafeMath for uint256;    
  
  // Mapping from address to _isMinter 
  mapping(address => bool) private _isMinter;
  
  // Mapping from treeId to _isExists 
  mapping(string => bool) public _isExists;
  
  // Mapping from tokenId to tree data
  mapping(uint => Tree) public _treeData;
  
  // Number of trees minted
  uint private _treeCount;
  
  // Fee for carbon credit
  uint256 private _carbonCreditFee;
  
  // Fee for green bond
  uint256 private _greenBondFee;
 
  // To check re-entrancy
  bool internal _locked;
  
  // Mapping from address to epoch generation data of index
  mapping(address => mapping(uint256 => Generation)) public _epochGeneration;
    
  // `Tree` keeps information realted to specific tree    
  struct Tree {
    string treeId;
    string treeName;
    string longitude;
    string latitude;
    uint256 carbonDioxideOffset;
  }
  
  // `Generation` records amount generated for specific epoch
  struct Generation {
        uint256 carbonCredit;
        uint256 greenBond;
  }
  
  /**
	 * @dev Fired in generateCarbonCredit() and generateGreenBond() 
	 *      when generation happens
	 *
	 * @param _from an address of generator
	 * @param _tokenId Id of Nftree
	 * @param _epochIndex an index number of epoch
	 * @param _value an amount that is generated
	 * @param _type "Green Bond" or "Carbon Credit"
	 */
  event Generated(
        address indexed _from,
        uint256 indexed _tokenId,
        uint256 _epochIndex,
        uint256 _value,
        string _type
  );
  
  // Checks re-entrancy
  modifier noReentrant() {
        require(!_locked, "No re-entrancy");
        _locked = true;
        _;
        _locked = false;
  }


  /**
	 * @dev Creates/deploys treedefi forest Nftree version 2.0
	 *
	 * @param own_ address of the founding owner of Nftree V2
	 */
  constructor(address own_) 
    ERC721(
            "Treedefi Collectibles",
            "NFTREE", 
            "https://api.treedefi.com/forest/"
          ) 
  {
    _owner = own_;
  }


  /**
    * @dev Returns the address of treedefi owner.
    */
  function getOwner() external view returns (address) {
        return _owner;
  }


  /** 
    * @notice Change baseURI for tokenURI JSON metadata
    * @param URI_ string baseURI to change
    */
  function setBaseURI(string memory URI_) external {
      require(
        _msgSender() == _owner,
        " Treedefi: Only Owner can set baseURI "
      );

    _setBaseURI(URI_);

  }
  
  /** 
    * @notice Add address for minter role
    * @param minter_ address of minter
    */
  function addMinter(address minter_) external {
      require(
        _msgSender() == _owner,
        " Treedefi: Only Owner can add minter "
      );

    _isMinter[minter_] = true;

  }
  
    /** 
    * @notice Remove address for minter role
    * @param minter_ address of minter
    */
  function removeMinter(address minter_) external {
      require(
        _msgSender() == _owner,
        " Treedefi: Only Owner can remove minter "
      );

    _isMinter[minter_] = false;

  }

  /** @dev Mint NFT and assign it to `owner`, increasing the total supply.
     *@param treeId_ string defines id of tree
     *@param treeName_ string defines name of tree
     *@param longitude_ string defines longitude of tree
     *@param latitude_ string defines latitude of tree
     *@param carbonDioxideOffset_ unsigned integer defines CO2 offset(gram/year) of tree
     */
  function mint(
      string memory treeId_, 
      string memory treeName_, 
      string memory longitude_,
      string memory latitude_,
      uint256 carbonDioxideOffset_
  ) 
    external 
    returns(uint256)
  { 

    require(
      (_msgSender() == _owner || _isMinter[_msgSender()]),
      " Treedefi: Only Owner or Minter can mint the tokens "
      );

    require(
      ! _isExists[treeId_],
      " Treedefi: token with similar tree ID already exists "
      );  
    
    // Increase tree counter 
    _treeCount++;
    
    // Mint new tree to the owner address
    _mint(_owner, _treeCount);
    
    // Record existance of new tree
    _isExists[treeId_] = true;
    
    // Record data associated with given tree
    _treeData[_treeCount] = Tree(treeId_, treeName_, longitude_, latitude_, carbonDioxideOffset_);

    return _treeCount;
    
  }
  
  /** @dev Edit location data of tree
     *@param tokenId_ unsigned integer defines token id of tree
     *@param longitude_ string defines longitude of tree
     *@param latitude_ string defines latitude of tree
     */
  function editTreeData(
      uint256 tokenId_, 
      string memory longitude_,
      string memory latitude_
  ) 
    external 
  {
      
     require(
      _msgSender() == _owner,
      " Treedefi: Only Owner can edit tree data "
      );
    
     // Replace existing longitude data with given longitude  
     _treeData[tokenId_].longitude = longitude_;
     
     // Replace existing latitude data with given latitude
     _treeData[tokenId_].latitude = latitude_;
     
  }
  
  /** @dev Sets fee for carbon credit generation
     *@param fee_ unsigned integer defines fee
     */
  function setCarbonCreditFee(
     uint256 fee_
  ) 
    external 
  {
      
     require(
      _msgSender() == _owner,
      " Treedefi: Only Owner can edit tree data "
      );
      
     _carbonCreditFee = fee_;
     
  }
  
  /** @dev Sets fee for green bond generation
     *@param fee_ unsigned integer defines fee
     */
  function setGreenBondFee(
     uint256 fee_
  ) 
    external 
  {
      
     require(
      _msgSender() == _owner,
      " Treedefi: Only Owner can edit tree data "
      );
      
     _greenBondFee = fee_;
     
  }
  
  /** @dev Generate epoch for token Id
     *@param tokenId_ unsigned integer defines token Id
     */
  function generateEpoch(
     uint256 tokenId_
  )   
    external
  {
      
      require(
       _msgSender() == ownerOf(tokenId_),
       " Treedefi: Only Owner of token can generate carbon credit "
      );
     
      // Generates new epoch for given token Id
      _generateEpoch(_msgSender(), tokenId_);
      
  }
  
  /** @dev Generates carbon credits for epoch
     *@param tokenId_ unsigned integer defines token id of tree
     *@param epochIndex_ unsigned integer defines index of epoch
     *@param carbonCredit_ unsigned integer defines number of carbon credits
     */
  function generateCarbonCredit(
     uint256 tokenId_,
     uint256 epochIndex_,
     uint256 carbonCredit_
  )   
    external
    payable
    noReentrant 
  {
      
     require(
       msg.value >= carbonCredit_.mul(_carbonCreditFee),
       " Treedefi: Provided value is not enough to generate carbon credits "
     );
     
     // Calculates total carbon offset of given epoch
     uint256 _generation = calculateGeneration(tokenId_,epochIndex_);
    
     require(
      _generation >= _epochGeneration[_msgSender()][epochIndex_].carbonCredit
      .add(_epochGeneration[_msgSender()][epochIndex_].greenBond)
      .add(carbonCredit_),
      " Treedefi: New generation exceeds epoch generation bountry "
     );
     
     // Add current generation into existing epoch generation of given epoch 
     _epochGeneration[_msgSender()][epochIndex_].carbonCredit = 
        _epochGeneration[_msgSender()][epochIndex_].carbonCredit
        .add(carbonCredit_);
        
     emit Generated(_msgSender(), tokenId_, epochIndex_, carbonCredit_, "carbon credit");    
  }
  
  /** @dev Generates green bonds for epoch
     *@param tokenId_ unsigned integer defines token id of tree
     *@param epochIndex_ unsigned integer defines index of epoch
     *@param greenBond_ unsigned integer defines number of green bonds
     */
  function generateGreenBond(
     uint256 tokenId_,
     uint256 epochIndex_,
     uint256 greenBond_
  )   
    external
    payable
    noReentrant 
  {
      
     require(
       msg.value >= greenBond_.mul(_greenBondFee),
       " Treedefi: Provided value is not enough to generate green bonds "
     );
     
     // Calculates total carbon offset of given epoch
     uint256 _generation = calculateGeneration(tokenId_,epochIndex_);
    
     require(
      _generation >= _epochGeneration[_msgSender()][epochIndex_].carbonCredit
      .add(_epochGeneration[_msgSender()][epochIndex_].greenBond)
      .add(greenBond_),
      " Treedefi: New generation exceeds epoch generation bountry "
     );
     
     // Add current generation into existing epoch generation of given epoch 
     _epochGeneration[_msgSender()][epochIndex_].greenBond = 
        _epochGeneration[_msgSender()][epochIndex_].greenBond
        .add(greenBond_);
    
     emit Generated(_msgSender(), tokenId_, epochIndex_, greenBond_, "green bond");         
  }
  
  /** @dev Calculates total generation for epoch
     *@param tokenId_ unsigned integer defines token id of tree
     *@param epochIndex_ unsigned integer defines index of epoch
     */
  function calculateGeneration(
     uint256 tokenId_,
     uint256 epochIndex_
  )
    public
    view
    returns (uint256)
  {
     return (_epochData[_msgSender()][epochIndex_].end
            .sub(_epochData[_msgSender()][epochIndex_].start))
            .mul(_treeData[tokenId_].carbonDioxideOffset).div(31536000);
  }    
  
  // withdraw the earnings :-)
  function withdraw() external {
      
    require(
      _msgSender() == _owner,
      " Treedefi: Only Owner can withdraw funds "
      );
    
    // Fetch current balance of Nftree V2 contract  
	uint256 balance = address(this).balance;
	
	// Transfer current balance to owner's address 
	payable(_msgSender()).transfer(balance);
  
  }
  
}