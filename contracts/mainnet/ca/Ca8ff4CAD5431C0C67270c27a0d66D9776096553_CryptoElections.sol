pragma solidity ^0.4.17;
//**
//**
contract ERC721 {
   // ERC20 compatible functions
  string public name = "CryptoElections";
  string public symbol = "CE";
   function totalSupply()  public view returns (uint256);
   function balanceOf(address _owner) public constant returns (uint);
   // Functions that define ownership
   function ownerOf(uint256 _tokenId) public constant returns (address owner);
   function approve(address _to, uint256 _tokenId) public returns (bool success);
   function takeOwnership(uint256 _tokenId) public;
   function transfer(address _to, uint256 _tokenId) public returns (bool success);
  function transferFrom(address _from, address _to, uint _tokenId) public returns (bool success);
   function tokensOfOwnerByIndex(address _owner, uint256 _index) view public  returns (uint tokenId);
   // Token metadata
 // function tokenMetadata(uint256 _tokenId) constant returns (string infoUrl);
 function implementsERC721() public pure returns (bool);
}

contract CryptoElections is ERC721 {

    /* Define variable owner of the type address */
    address creator;

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    modifier onlyCountryOwner(uint256 countryId) {
        require(countries[countryId].president==msg.sender);
        _;
    }
    modifier onlyCityOwner(uint cityId) {
        require(cities[cityId].mayor==msg.sender);
        _;
    }

    struct Country {
        address president;
        string slogan;
        string flagUrl;
    }
    struct City {
        address mayor;
        string slogan;
        string picture;
        uint purchases;
        uint startPrice;
          uint multiplierStep;
    }
    
    
    
    bool maintenance=false;
    bool transferEnabled=false;
    bool inited=false;
    event withdrawalEvent(address user,uint value);
    event pendingWithdrawalEvent(address user,uint value);
    event assignCountryEvent(address user,uint countryId);
    event buyCityEvent(address user,uint cityId);
    
       // Events
   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
   
   
    mapping(uint => Country) public countries ;
    mapping(uint =>  uint[]) public countriesCities ;
    mapping(uint =>  uint) public citiesCountries ;

    mapping(uint =>  uint) public cityPopulation ;
    mapping(uint => City) public cities;
    mapping(address => uint[]) public userCities;
    mapping(address => uint) public userPendingWithdrawals;
    mapping(address => string) public userNicknames;
     mapping(bytes32 => bool) public takenNicknames;
    mapping(address => mapping (address => uint256)) private allowed;
       
    uint totalCities=0;

 function implementsERC721() public pure returns (bool)
    {
        return true;
    }



    // ------------------------------------------------------------------------
    // Returns alloed status
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        require(transferEnabled);
        return allowed[tokenOwner][spender];
    }

   function totalSupply()  public  view returns (uint256 ) {
       
       return totalCities;
   }
    function CryptoElections() public {
        creator = msg.sender;
    }

    function () public payable {
        revert();
    }
   
    
      function balanceOf(address _owner) constant public returns (uint balance) {
          
          return userCities[_owner].length;
      }
      
        function ownerOf(uint256 _tokenId) constant public  returns (address owner) {
            
            return cities[_tokenId].mayor;
        }
 
 
       function approve(address _to, uint256 _tokenId) public returns (bool success){
           require(transferEnabled);
       require(msg.sender == ownerOf(_tokenId));
       require(msg.sender != _to);
       allowed[msg.sender][_to] = _tokenId;
       Approval(msg.sender, _to, _tokenId);
       return true;
   }
   
     function takeOwnership(uint256 _tokenId) public {
         require(transferEnabled);
       require(cityPopulation[_tokenId]!=0);
       address oldOwner = ownerOf(_tokenId);
       address newOwner = msg.sender;
       require(newOwner != oldOwner);
       // cities can be transfered one-by-one
       require(allowed[oldOwner][newOwner] == _tokenId);
       
       
       _removeUserCity(oldOwner,_tokenId);
       cities[_tokenId].mayor=newOwner;
       _addUserCity(newOwner,_tokenId);
       
   
       Transfer(oldOwner, newOwner, _tokenId);
   }
   

      function transfer(address _to, uint256 _tokenId) public  returns (bool success) {
       require(transferEnabled);
       address currentOwner = msg.sender;
       address newOwner = _to;
      
        require(cityPopulation[_tokenId]!=0);
       require(currentOwner == ownerOf(_tokenId));
       require(currentOwner != newOwner);
       require(newOwner != address(0));
        _removeUserCity(currentOwner,_tokenId);
       cities[_tokenId].mayor=newOwner;
   
        _addUserCity(newOwner,_tokenId);
       Transfer(currentOwner, newOwner, _tokenId);
       return true;
   }
   
     function transferFrom(address from, address to, uint _tokenId) public returns (bool success) {
         
           require(transferEnabled);
       address currentOwner = from;
       address newOwner = to;
      
        require(cityPopulation[_tokenId]!=0);
       require(currentOwner == ownerOf(_tokenId));
       require(currentOwner != newOwner);
       require(newOwner != address(0));
         // cities can be transfered one-by-one
       require(allowed[currentOwner][msg.sender] == _tokenId);
       
        _removeUserCity(currentOwner,_tokenId);
       cities[_tokenId].mayor=newOwner;
   
        _addUserCity(newOwner,_tokenId);
       Transfer(currentOwner, newOwner, _tokenId);
       
         return true;
         
     }
   
   
    function tokensOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint tokenId) {
       
        return userCities[_owner][_index];
    }
   // Token metadata


  
    function markContractAsInited() public
    onlyCreator() 
    {
     inited=true;   
    }
    
    
 /*
    Functions to migrate from previous contract. After migration is complete this functions will be blocked
    */
    function addOldMayors(uint[] citiesIds,uint[] purchases,address[] mayors) public 
    onlyCreator()
    {
        require(!inited);
        for (uint i = 0;i<citiesIds.length;i++) {
            cities[citiesIds[i]].mayor = mayors[i];
            cities[citiesIds[i]].purchases = purchases[i];
        }
    }
    
    function addOldNickname(address user,string nickname) public
    onlyCreator()
    {
        require(!inited);
           takenNicknames[keccak256(nickname)]=true;
         userNicknames[user] = nickname;
    }
    function addOldPresidents(uint[] countriesIds,address[] presidents) public
    onlyCreator()
    {
        require(!inited);
        for (uint i = 0;i<countriesIds.length;i++) {
            countries[countriesIds[i]].president = presidents[i];
        }
    }
    
      function addOldWithdrawals(address[] userIds,uint[] withdrawals) public
    onlyCreator()
    {
        require(!inited);
        for (uint i = 0;i<userIds.length;i++) {
            userPendingWithdrawals[userIds[i]] = withdrawals[i];
        }
    }
    
    /* This function is executed at initialization and sets the owner of the contract */
    /* Function to recover the funds on the contract */
    function kill() public
    onlyCreator()
    {
        selfdestruct(creator);
    }

    function transferContract(address newCreator) public
    onlyCreator()
    {
        creator=newCreator;
    }



    // Contract initialisation
    function addCountryCities(uint countryId,uint[] _cities,uint multiplierStep,uint startPrice)  public
    onlyCreator()
    {
        countriesCities[countryId] = _cities;
        for (uint i = 0;i<_cities.length;i++) {
            Transfer(0x0,address(this),_cities[i]);
            cities[_cities[i]].multiplierStep=multiplierStep;
              cities[_cities[i]].startPrice=startPrice;
            citiesCountries[_cities[i]] = countryId;
        }
        //skipping uniquality check
        totalCities+=_cities.length;
    }
    function setMaintenanceMode(bool _maintenance) public
    onlyCreator()
    {
        maintenance=_maintenance;
    }

   function setTransferMode(bool _status) public
    onlyCreator()
    {
        transferEnabled=_status;
    }
    // Contract initialisation
    function addCitiesPopulation(uint[] _cities,uint[]_populations)  public
    onlyCreator()
    {

        for (uint i = 0;i<_cities.length;i++) {

            cityPopulation[_cities[i]] = _populations[i];
        }
        
    }

    function setCountrySlogan(uint countryId,string slogan) public
    onlyCountryOwner(countryId)
    {
        countries[countryId].slogan = slogan;
    }

    function setCountryPicture(uint countryId,string _flagUrl) public
    onlyCountryOwner(countryId)
    {
        countries[countryId].flagUrl = _flagUrl;
    }

    function setCitySlogan(uint256 cityId,string _slogan) public
    onlyCityOwner(cityId)
    {
        cities[cityId].slogan = _slogan;
    }

    function setCityPicture(uint256 cityId,string _picture) public
    onlyCityOwner(cityId)
    {
        cities[cityId].picture = _picture;
    }

function stringToBytes32(string memory source) private pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}
    // returns address mayor;
        
      function getCities(uint[] citiesIds)  public view returns (City[]) {
     
        City[] memory cityArray= new City[](citiesIds.length);
     
        for (uint i=0;i<citiesIds.length;i++) {
          
            cityArray[i]=cities[citiesIds[i]];
          
            
        }
        return cityArray;
        
    }
    
              function getCitiesStrings(uint[] citiesIds)  public view returns (  bytes32[],bytes32[]) {
     
        bytes32 [] memory slogans=new bytes32[](citiesIds.length);
         bytes32 [] memory pictures=new bytes32[](citiesIds.length);
   
     
        for (uint i=0;i<citiesIds.length;i++) {
          
            slogans[i]=stringToBytes32(cities[citiesIds[i]].slogan);
            pictures[i]=stringToBytes32(cities[citiesIds[i]].picture);
       
            
        }
        return (slogans,pictures);
        
    }
    
   
    function getCitiesData(uint[] citiesIds)  public view returns (  address [],uint[],uint[],uint[]) {
   
         address [] memory mayors=new address[](citiesIds.length);
   
        uint [] memory purchases=new uint[](citiesIds.length);
        uint [] memory startPrices=new uint[](citiesIds.length);
        uint [] memory multiplierSteps=new uint[](citiesIds.length);
                                    
        for (uint i=0;i<citiesIds.length;i++) {
            mayors[i]=(cities[citiesIds[i]].mayor);
      
            purchases[i]=(cities[citiesIds[i]].purchases);
            startPrices[i]=(cities[citiesIds[i]].startPrice);
            multiplierSteps[i]=(cities[citiesIds[i]].multiplierStep);
            
        }
        return (mayors,purchases,startPrices,multiplierSteps);
        
    }
    
    function getCountriesData(uint[] countriesIds)  public view returns (    address [],bytes32[],bytes32[]) {
          address [] memory presidents=new address[](countriesIds.length);
        bytes32 [] memory slogans=new bytes32[](countriesIds.length);
         bytes32 [] memory flagUrls=new bytes32[](countriesIds.length);
   
        for (uint i=0;i<countriesIds.length;i++) {
            presidents[i]=(countries[countriesIds[i]].president);
            slogans[i]=stringToBytes32(countries[countriesIds[i]].slogan);
            flagUrls[i]=stringToBytes32(countries[countriesIds[i]].flagUrl);
            
        }
        return (presidents,slogans,flagUrls);
        
    }

    function withdraw() public {
        if (maintenance) revert();
        uint amount = userPendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks

        userPendingWithdrawals[msg.sender] = 0;
        withdrawalEvent(msg.sender,amount);
        msg.sender.transfer(amount);
    }
  
  function getPrices2(uint purchases,uint startPrice,uint multiplierStep) public pure returns (uint[4]) {
      
        uint price=startPrice;
        uint pricePrev = price;
        uint systemCommission = startPrice;
        uint presidentCommission = 0;
        uint ownerCommission;

        for (uint i = 1;i<=purchases;i++) {
            if (i<=multiplierStep)
                price = price*2;
            else
                price = (price*12)/10;

            presidentCommission = price/100;
            systemCommission = (price-pricePrev)*2/10;
            ownerCommission = price-presidentCommission-systemCommission;

            pricePrev = price;
        }
        return [price,systemCommission,presidentCommission,ownerCommission];
    }


    function setNickname(string nickname) public returns(bool) {
        if (maintenance) revert();
        if (takenNicknames[keccak256(nickname)]==true) {
                     return false;
        }
        userNicknames[msg.sender] = nickname;
        takenNicknames[keccak256(nickname)]=true;
        return true;
    }

    function _assignCountry(uint countryId)    private returns (bool) {
        uint  totalPopulation;
        uint  controlledPopulation;

        uint  population;
        for (uint i = 0;i<countriesCities[countryId].length;i++) {
            population = cityPopulation[countriesCities[countryId][i]];
            if (cities[countriesCities[countryId][i]].mayor==msg.sender) {
                controlledPopulation += population;
            }
            totalPopulation += population;
        }
        if (controlledPopulation*2>(totalPopulation)) {
            countries[countryId].president = msg.sender;
            assignCountryEvent(msg.sender,countryId);
            return true;
        } else {
            return false;
        }
    }
    

    function buyCity(uint cityId) payable  public  {
        if (maintenance) revert();
        uint[4] memory prices = getPrices2(cities[cityId].purchases,cities[cityId].startPrice,cities[cityId].multiplierStep);

        if (cities[cityId].mayor==msg.sender) {
            revert();
        }
        if (cityPopulation[cityId]==0) {
            revert();
        }

        if ( msg.value+userPendingWithdrawals[msg.sender]>=prices[0]) {
            // use user limit
            userPendingWithdrawals[msg.sender] = userPendingWithdrawals[msg.sender]+msg.value-prices[0];
            pendingWithdrawalEvent(msg.sender,userPendingWithdrawals[msg.sender]+msg.value-prices[0]);

            cities[cityId].purchases = cities[cityId].purchases+1;

            userPendingWithdrawals[cities[cityId].mayor] += prices[3];
            pendingWithdrawalEvent(cities[cityId].mayor,prices[3]);

            if (countries[citiesCountries[cityId]].president==0) {
                userPendingWithdrawals[creator] += prices[2];
                pendingWithdrawalEvent(creator,prices[2]);

            } else {
                userPendingWithdrawals[countries[citiesCountries[cityId]].president] += prices[2];
                pendingWithdrawalEvent(countries[citiesCountries[cityId]].president,prices[2]);
            }
            // change mayor
            address oldMayor;
            oldMayor=cities[cityId].mayor;
            if (cities[cityId].mayor>0) {
                _removeUserCity(cities[cityId].mayor,cityId);
            }



            cities[cityId].mayor = msg.sender;
            _addUserCity(msg.sender,cityId);

            _assignCountry(citiesCountries[cityId]);

            //send money to creator
            creator.transfer(prices[1]);
           // buyCityEvent(msg.sender,cityId);
             Transfer(0x0,msg.sender,cityId);

        } else {
            revert();
        }
    }
    function getUserCities(address user) public view returns (uint[]) {
        return userCities[user];
    }

    function _addUserCity(address user,uint cityId) private {
        bool added = false;
        for (uint i = 0; i<userCities[user].length; i++) {
            if (userCities[user][i]==0) {
                userCities[user][i] = cityId;
                added = true;
                break;
            }
        }
        if (!added)
            userCities[user].push(cityId);
    }

    function _removeUserCity(address user,uint cityId) private {
        for (uint i = 0; i<userCities[user].length; i++) {
            if (userCities[user][i]==cityId) {
                delete userCities[user][i];
            }
        }
    }

}