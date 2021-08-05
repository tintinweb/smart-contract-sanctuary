// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

import "./EnumerableSet.sol";

import "./ITorro.sol";
import "./ITorroDao.sol";
import "./ITorroFactory.sol";
import "./CloneFactory.sol";

/// @title Factory for creation of DAOs and their governing tokens.
/// @notice Contract for creation of DAOs and their governing tokens, and handling benefits withdrawal for all available DAO pools.
/// @author ORayskiy - @robitnik_TorroDao
contract TorroFactory is ITorroFactory, CloneFactory {
  using EnumerableSet for EnumerableSet.AddressSet;

  uint256 private constant _customSupply = 1e22;
  address private _owner;
  address private _torroToken;
  address private _torroDao;
  mapping (address => uint256) private _benefits;
  mapping (address => address) private _pools;
  EnumerableSet.AddressSet private _poolTokens;
  uint256 _createPrice;
  uint256 _minMaxCost;
  
  /// @notice Event for dispatching when holder claimed benefits.
  /// @param owner address that claimed benefits.
  event ClaimBenefits(address indexed owner);

  /// @notice Event for dispatching when new governing token and DAO pool have been created.
  /// @param token token address.
  /// @param dao DAO address.
	event PoolCreated(address indexed token, address indexed dao);

  constructor(address torroToken_, address torroDao_) public {
    _owner = msg.sender;
    _torroToken = torroToken_;
    _torroDao = torroDao_;
    // 0.2 eth
    _createPrice = 2 * 10**17;
    _minMaxCost = 1 ether;
  }

  /// @notice Bodifier for onlyOwner functions.
  modifier onlyOwner() {
    require(_owner == msg.sender);
    _;
  }

  /// @notice All governing tokens created via factory.
  /// @return array of all governing token addresses.
  function poolTokens() public view returns (address[] memory) {
    uint256 length = _poolTokens.length();
    address[] memory poolTokenAddresses = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      poolTokenAddresses[i] = _poolTokens.at(i);
    }
    return poolTokenAddresses;
  }

  /// @notice Gets DAO address for governing token.
  /// @param token_ token address to get DAO address for.
  /// @return DAO address.
  function poolDao(address token_) public view returns (address) {
    return _pools[token_];
  }

  /// @notice Gets addresses of governing tokens that are visible to holder.
  /// @param holder_ holder address to get available tokens for.
  /// @return array of token addresses that holder owns or can buy.
  function poolTokensForHolder(address holder_) public view returns (address[] memory) {
    uint256 length = _poolTokens.length();
    if (length == 0) {
      return new address[](0);
    }
    address[] memory poolTokenAddresses = new address[](length);
    uint256 pointer = 0;
    for (uint256 i = 0; i < length; i++) {
      address token = _poolTokens.at(i);
      if (token != address(0x0)) {
        address dao = _pools[token];
        if ((ITorro(token).totalOf(holder_) > 0) || ITorroDao(dao).isPublic() || ITorroDao(dao).daoCreator() == holder_) {
          poolTokenAddresses[pointer++] = token;
        }
      }
    }
    return poolTokenAddresses;
  }

  /// @notice Address of the main token.
  /// @return address of the main token.  
  function mainToken() public view override returns (address) {
    return _torroToken;
  }

  /// @notice Address of the main DAO.
  /// @return address of the main DAO.
  function mainDao() public view override returns (address) {
    return _torroDao;
  }

  
  /// @notice Checks whether provided address is a valid DAO.
  /// @param dao_ address to check.
  /// @return bool true if address is a valid DAO.
  function isDao(address dao_) public view override returns (bool) {
    if (dao_ == _torroDao) {
      return true;
    }
    uint256 length = _poolTokens.length();
    for (uint256 i = 0; i < length; i++) {
      if (dao_ == _pools[_poolTokens.at(i)]) {
        return true;
      }
    }

    return false;
  }

  /// @notice Gets current price for DAO creation.
  /// @return uint256 wei price for DAO creation.
  function price() public view returns (uint256) {
    return _createPrice;
  }

  /// @notice Checks available benefits of an address.
  /// @param sender_ address to check benefits for.
  /// @return uint256 amount of benefits available.
  function benefitsOf(address sender_) public view returns (uint256) {
    return _benefits[sender_];
  }

  /// @notice Creates a cloned DAO and governing token.
  /// @param maxCost_ maximum cost of all governing tokens for created DAO.
  /// @param executeMinPct_ minimum percentage of votes needed for proposal execution.
  /// @param votingMinHours_ minimum lifetime of proposal before it closes.
  /// @param isPublic_ whether DAO is publically visible.
  /// @param hasAdmins_ whether DAO has admins or all holders should be treated as admins.
  function create(uint256 maxCost_, uint256 executeMinPct_, uint256 votingMinHours_, bool isPublic_, bool hasAdmins_) public payable {
    // Check that correct payment has been sent for creation.
    require(msg.value == _createPrice);
    // Check that maximum cost specified is equal or greater than required minimal maximum cost. 
    require(maxCost_ >= _minMaxCost);
    
    // Create clones of main governing token and DAO.
    address tokenProxy = createClone(_torroToken);
    address daoProxy = createClone(_torroDao);

    // Initialize governing token and DAO.
    ITorroDao(daoProxy).initializeCustom(_torroToken, tokenProxy, address(this), msg.sender, maxCost_, executeMinPct_, votingMinHours_, isPublic_, hasAdmins_);
    ITorro(tokenProxy).initializeCustom(daoProxy, address(this), _customSupply);

    // Save addresses of newly created governing token and DAO.
    _poolTokens.add(tokenProxy);
    _pools[tokenProxy] = daoProxy;
    
    // Forward payment to factory owner.
    payable(_owner).transfer(msg.value);

    // Emit event that new DAO pool has been created.
    emit PoolCreated(tokenProxy, daoProxy);
  }

  /// @notice Claim available benefits for holder.
  /// @param amount_ of wei to claim.
  function claimBenefits(uint256 amount_) public override {
    // Check that factory has enough eth to pay for withdrawal.
    require(amount_ <= address(this).balance);
    // Check that holder has enough benefits to withdraw specified amount.
    uint256 amount = _benefits[msg.sender];
    require(amount_ >= amount);

    // Reduce holders available withdrawal benefits.
    _benefits[msg.sender] = amount - amount_;
    
    // Transfer benefits to holder's address.
    payable(msg.sender).transfer(amount_);

    // Emit event that holder has claimed benefits.
    emit ClaimBenefits(msg.sender);
  }

  /// @notice Adds withdrawal benefits for holder.
  /// @param recipient_ holder that's getting benefits.
  /// @param amount_ benefits amount to be added to holder's existing benefits.
  function addBenefits(address recipient_, uint256 amount_) public override {
    // Check that function is triggered by one of DAO governing tokens.
    require(_torroToken == msg.sender || _poolTokens.contains(msg.sender));
    // Add holders benefits.
    _benefits[recipient_] = _benefits[recipient_] + amount_;
  }

  /// @notice Depositis withdrawal benefits.
  /// @param token_ governing token for DAO that's depositing benefits.
  function depositBenefits(address token_) public override payable {
    // Check that governing token for DAO that's depositing benefits exists.
    // And check that benefits deposition is sent by corresponding DAO.
    if (token_ == _torroToken) {
      require(msg.sender == _torroDao);
    } else {
      require(_poolTokens.contains(token_) && msg.sender == _pools[token_]);
    }
    // do nothing
  }

  /// @notice Creates clone of main DAO and migrates an existing DAO to it.
  /// @param token_ Governing token that needs to migrate to new dao.
  function migrate(address token_) public onlyOwner {
    ITorroDao currentDao = ITorroDao(_pools[token_]);
    // Create a new clone of main DAO.
    address daoProxy = createClone(_torroDao);
    // Initialize it with parameters from existing dao.
    ITorroDao(daoProxy).initializeCustom(
      _torroToken,
      token_,
      address(this),
      currentDao.daoCreator(),
      currentDao.maxCost(),
      currentDao.executeMinPct(),
      currentDao.votingMinHours(),
      currentDao.isPublic(),
      currentDao.hasAdmins()
    );

    // Update dao address reference for governing token.
    _pools[token_] = daoProxy;

    // Update governing token addresses.
    ITorro(token_).setDaoFactoryAddresses(daoProxy, address(this));
  }

  /// @notice Sets price of DAO creation.
  /// @param price_ wei price for DAO creation.
  function setPrice(uint256 price_) public onlyOwner {
    _createPrice = price_;
  }

  /// @notice Sets minimal maximum cost for new DAO creation.
  /// @param cost_ minimal maximum cost of new DAO.
  function setMinMaxCost(uint256 cost_) public onlyOwner {
    _minMaxCost = cost_;
  }

  /// @notice Transfers ownership of Torro Factory to new owner.
  /// @param newOwner_ address of new owner.
  function transferOwnership(address newOwner_) public onlyOwner {
    _owner = newOwner_;
  }

  /// @notice Sets address of new Main DAO.
  /// @param torroDao_ address of new main DAO.
  function setNewDao(address torroDao_) public onlyOwner {
    _torroDao = torroDao_;
  }
}