pragma solidity ^0.4.24;

contract Ownable {
  // state variables
  address owner;

  // modifiers
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /*constructor () public {
	// owner = msg.sender;
	owner = 0x7E8E46802a93Cca96dD063EBD4F4b24DbD7642e1; // mainnet Owner
	owner = 0x805c55Decb84461B27A8ad77AeBda78Eecd37835; // Ropsten Owner
  }*/
}






/**
 * @title Migratable
 * Helper contract to support intialization and migration schemes between
 * different implementations of a contract in the context of upgradeability.
 * To use it, replace the constructor with a function that has the
 * `isInitializer` modifier starting with `"0"` as `migrationId`.
 * When you want to apply some migration code during an upgrade, increase
 * the `migrationId`. Or, if the migration code must be applied only after
 * another migration has been already applied, use the `isMigration` modifier.
 * This helper supports multiple inheritance.
 * WARNING: It is the developer&#39;s responsibility to ensure that migrations are
 * applied in a correct order, or that they are run at all.
 * See `Initializable` for a simpler version.
 */
contract Migratable {
  /**
   * @dev Emitted when the contract applies a migration.
   * @param contractName Name of the Contract.
   * @param migrationId Identifier of the migration applied.
   */
  event Migrated(string contractName, string migrationId);

  /**
   * @dev Mapping of the already applied migrations.
   * (contractName => (migrationId => bool))
   */
  mapping (string => mapping (string => bool)) internal migrated;

  /**
   * @dev Internal migration id used to specify that a contract has already been initialized.
   */
  string constant private INITIALIZED_ID = "initialized";


  /**
   * @dev Modifier to use in the initialization function of a contract.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   */
  modifier isInitializer(string contractName, string migrationId) {
    validateMigrationIsPending(contractName, INITIALIZED_ID);
    validateMigrationIsPending(contractName, migrationId);
    _;
    emit Migrated(contractName, migrationId);
    migrated[contractName][migrationId] = true;
    migrated[contractName][INITIALIZED_ID] = true;
  }

  /**
   * @dev Modifier to use in the migration of a contract.
   * @param contractName Name of the contract.
   * @param requiredMigrationId Identifier of the previous migration, required
   * to apply new one.
   * @param newMigrationId Identifier of the new migration to be applied.
   */
  modifier isMigration(string contractName, string requiredMigrationId, string newMigrationId) {
    require(isMigrated(contractName, requiredMigrationId), "Prerequisite migration ID has not been run yet");
    validateMigrationIsPending(contractName, newMigrationId);
    _;
    emit Migrated(contractName, newMigrationId);
    migrated[contractName][newMigrationId] = true;
  }

  /**
   * @dev Returns true if the contract migration was applied.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   * @return true if the contract migration was applied, false otherwise.
   */
  function isMigrated(string contractName, string migrationId) public view returns(bool) {
    return migrated[contractName][migrationId];
  }

  /**
   * @dev Initializer that marks the contract as initialized.
   * It is important to run this if you had deployed a previous version of a Migratable contract.
   * For more information see https://github.com/zeppelinos/zos-lib/issues/158.
   */
  function initialize() isInitializer("Migratable", "1.2.1") public {
  }

  /**
   * @dev Reverts if the requested migration was already executed.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   */
  function validateMigrationIsPending(string contractName, string migrationId) private view {
    require(!isMigrated(contractName, migrationId), "Requested target migration ID has already been run");
  }
}


contract vchain is Ownable, Migratable {
    // custom types
  struct Entity {
    string name;
    string location;
    string web;
    string  phone;
    uint NoOfPayments;
  }
  
  struct Article {
    uint id;
    address creator;
    address holder;
    string name;
  }

  // state variables
  mapping (uint => Article) public articles;
  uint articleCounter;
  uint price;
  
  // table of address details
  mapping (address => Entity) public AddressToEntity;

  // events
  event LogSellArticle(
    uint indexed _id,
    address indexed _seller,
    string _name
  );
  event LogBuyArticle(
    uint indexed _id,
    //address indexed _seller,
    address indexed _buyer
    //string _name
  );
  event SetEntity(
      address indexed _entity,
	  string _name
    );

  function initialize(uint256 _price, address _owner) isInitializer("vchain", "0") public {
   price = _price;
   owner = _owner;
 }

  
  // deactivate the contract
  /* function kill() public onlyOwner {
    selfdestruct(owner);
  } */

    // don&#39;t set constructor because zOS will handle it
    
    function SetPrice(uint _price) public onlyOwner {
        price = _price;
    }
    
    function GetPrice() public view returns(uint) {
        return price;
    }
    
  // Introduce the Entity
  function Intro(string _name, string _location, string _web, string _phone) public {
        AddressToEntity[msg.sender] = Entity(
          _name,
          _location,
          _web,
          _phone,
          0
        );
        
        emit SetEntity(msg.sender, _name);
  }
  
  // Create batch of items
  function CreateBatch(uint _quantity, string _name) public payable {
    // If sales volume is a multiple of 1,000 and times of deposit is not enough, then require the Sender to deposit
    if (getSaleVolume() >= (AddressToEntity[msg.sender].NoOfPayments + 1) * 10) {
        require (msg.value == price);
        AddressToEntity[msg.sender].NoOfPayments++;
    }
      
      for(uint i = 1; i <= _quantity; i++) {
            // a new article
            articleCounter++;
            
            articles[articleCounter] = Article(
              articleCounter,
              msg.sender,
              0x0,
              _name
              );
			  
			emit LogSellArticle(articleCounter, msg.sender, _name);
      }
  }

  // fetch the number of articles in the contract
  function getNumberOfArticles() public view returns (uint) {
    return articleCounter;
  }

  // fetch and return all article IDs for articles of msg.sender
  function getArticlesOwn() public view returns (uint[]) {
    // prepare output array
    uint[] memory articleIds = new uint[](articleCounter);

    uint numberOfArticlesOwn = 0;
    // iterate over articles
    for(uint i = 1; i <= articleCounter;  i++) {
      // keep the ID if the article own
      if(
          ((msg.sender == articles[i].creator) || (msg.sender ==articles[i].holder))
         )  {
            articleIds[numberOfArticlesOwn] = articles[i].id;
            numberOfArticlesOwn++;
      }
    }

    // copy the articleIds array into a smaller forSale array
    uint[] memory forSale = new uint[](numberOfArticlesOwn);
    for(uint j = 0; j < numberOfArticlesOwn; j++) {
      forSale[j] = articleIds[j];
    }
    return forSale;
  }

// VChain - count the number of items the msg.sender created. Only original creators are charged.
  function getSaleVolume() public view returns (uint) {
    uint volume = 0;
    // iterate over articles
    for(uint i = 1; i <= articleCounter;  i++) {
        if (articles[i].creator == msg.sender) {
            volume++;
        }
    }

    return volume;
  }
  
  // Sell multiple items
  function SellMulti(uint[] _ids, address _buyer) public {
    // we check whether there is an article for sale
    require(articleCounter > 0);
    
    // retrieve articles
    for (uint i=0; i < _ids.length; i++) {
         // we check that the article exists
        require(_ids[i] > 0 && _ids[i] <= articleCounter);
        
        // we retrieve the article
        Article storage article = articles[_ids[i]];
        // we check that if the creator not yet sell, then require msg.sender must be creator. Otherwise, msg.sender must be the holder
    
        if (article.holder == 0X0) {
        // the seller must be the creator
        require(msg.sender == article.creator);
        } else {
        require(msg.sender == article.holder);
        }
        
        // keep buyer&#39;s information
        article.holder = _buyer;
        
        // trigger the event
        emit LogBuyArticle(_ids[i], article.holder);
    }
  }
  
  function getOwner() public view returns(address) {
      return owner;
  }
  
  // withdraw fund
  function withdraw() public onlyOwner {
      msg.sender.transfer(address(this).balance);
  }
  
}