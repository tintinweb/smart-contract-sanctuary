pragma solidity ^0.4.24;
//-------------------------------------------------------------------------------------------------------------------------
//*--------------------------------------------------------------------------------------------------
//----------------Call Option Contract of WIT
//Token Name=  CallOptionsWIT
//Symbol= CWIT
//Deployed To:

//Prepared by: Muhamad Hammad Ahmed
//------------------------------------------------------------------------------------------------------------------------------

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
//-------ERC721 Interface-----------------------------------------------------------------------------------------------------------------------
contract ERC721Interface {
   // ERC20 compatible functions
   function name() constant returns (string name);
   function symbol() constant returns (string symbol);
   function totalSupply() constant returns (uint256 totalSupply);
   function balanceOf(address _owner) constant returns (uint balance);
   // Functions that define ownership
   function ownerOf(uint256 _tokenId) constant returns (address owner);
   function approve(address _to, uint256 _tokenId);
   function takeOwnership(uint256 _tokenId);
   function transfer(address _to, uint256 _tokenId);
   function tokenOfOwnerByIndex(address _owner, uint256 _index) constant returns (uint tokenId);
   // Token metadata
   function tokenMetadata(uint256 _tokenId) constant returns (string infoUrl);
   // Events
   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}
//--------------------*/
contract CryptoWitCalls{
    // CONSTANTS ***/

  string public constant Token_name = "CryptoWIT Call Option";
  string public constant Token_symbol = "CWIT";

    /*State Variables*/
  address optionWriter;
  uint optionsId=1;
  
 //**Data types */ 
    struct cwt{
        string name;
        address writer;
        address buyer;
    uint underlying;
    uint Premium;
    uint strikePrice;
    uint contractDate;
    uint effectiveDate;
    uint expiryDate;
}
/*--------------------Events---*/
event logString(string);
 event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

 /*** ----------------------------------STORAGE & Records ***/

  cwt[] options;

  mapping (uint256 => address) public optionsIndexToOwner;
  mapping (address => uint256) ownershipOptionCount;
  mapping (uint256 => address) public optionsIndexToApproved;


    constructor(){
    optionWriter=msg.sender;
    emit logString("Constructor is executed");
    }
   
   function () public payable {
   //  createOption("Sample Option, 20,100, 5,200e,400,600);
       uint eth = msg.value;
       if(eth<=1){
       createOption("Option for ETH 1", 99,100, 1,200,400,600);    
       }else if(eth==2){
         createOption("Option for ETH 2", 98,100, 2,200,400,600);   
       }else if(eth==3){
         createOption("Option for ETH 3", 97,100, 3,200,400,600);   
       }
   }  
    function getOptionholderbyId(uint id) public view returns(address){
        return options[id].buyer;
        
    }
    function getOptionWriterrbyId(uint id) public view returns(address){
        return options[id].writer;
        
    }
    function getOptionNameholderbyId(uint id) public view returns(string){
        return options[id].name;
        
    }
    function createOption(string _name, uint _strikePrice,uint _underlying, uint _premium,uint _contractDate,uint _effectiveDate,uint _expiryDate){
       address optionBuyer= tx.origin; 
       
        cwt memory cwit= cwt(_name,optionWriter,optionBuyer,_underlying,_premium,_strikePrice,_contractDate,_effectiveDate,_expiryDate);
    
    options.push(cwit);
   optionsIndexToOwner[optionsId]=optionBuyer;
   ownershipOptionCount[optionBuyer]++;
    optionsId++;
    emit logString("Option is Created");
    } 
    
      function isExpired(uint _otionId) returns (bool) {/* returns true if option is expired */
        return options[_otionId].expiryDate < now;
    }
    
    function excercise(uint optionId, uint price) returns(bool)  {
        cwt memory opt= options[optionId];
        require(tx.origin == opt.buyer);
        require(!isExpired(optionId));
        
        /*code to call transfer from function from another Token contract*/
      emit logString("optionis excercised");
      return true;
                
    }
     /***fromERC721*/
        /*** INTERNAL FUNCTIONS ***/

  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {// confirms ownership
    return optionsIndexToOwner[_tokenId] == _claimant;
    emit logString("confirmed that token is owned by Claimant");
  }

  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {//confirmsfirms if authorized approved
    return optionsIndexToApproved[_tokenId] == _claimant;//confirm if authorized
    emit logString("confirmed that Claimant is authorized");
  }

  function _approve(address _to, uint256 _tokenId) internal {//authorize for transfer
    optionsIndexToApproved[_tokenId] = _to;
    
    emit logString("Approved for transfer of Option");

   // Approval(tokenIndexToOwner[_tokenId], tokenIndexToApproved[_tokenId], _tokenId);//event
  }
 // function takeOwnership(uint256 _tokenId);

  function _transfer(address _from, address _to, uint256 _optionId) internal {//transfer tokens
    ownershipOptionCount[_to]++;//increasing ownership count
    optionsIndexToOwner[_optionId] = _to; // changing ownership

    if (_from != address(0)) {
      ownershipOptionCount[_from]--;// decreasing ownership count
      delete optionsIndexToApproved[_optionId];// deleting the authorized by previous owner
    }

    //Transfer(_from, _to, _tokenId);//event 
  }
  
  /*** ERC721 IMPLEMENTATION ***/

  /*function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
    return ((_interfaceID == InterfaceID_ERC165) || (_interfaceID == InterfaceID_ERC721));
  }*/
 /*** ERC20 Compatible Functions ***/
 
  function name() constant returns (string _name){
    return Token_name;
  }
    function symbol() constant returns (string symbol){
    return Token_symbol;
    }
 function totalSupply() public view returns (uint256) {
    return options.length;
  }
  function balanceOf(address _owner) public view returns (uint256) {//returns number of Options on a particular address
  
  /*--Function that define ownership--*/
    return ownershipOptionCount[_owner];//returns options count for a specific address
  }

  function ownerOf(uint256 _optionId) external view returns (address owner) {//returns the owner of a particular option
    owner = optionsIndexToOwner[_optionId];

    require(owner != address(0));
  }

  function approve(address _to, uint256 _optionId) external {//ERC721 function to authorize  thirdpartyby the option owner
    require(_owns(msg.sender, _optionId));// confirms if the authorizer is really the owner of option

    _approve(_to, _optionId);// calls internal function to authorize thirdparty
  }

  function transfer(address _to, uint256 _optionId) external {// owner can transfer the tokens
    require(_to != address(0));
    require(_to != address(this));// to avoid sendingitself
    require(_owns(msg.sender, _optionId));//confirms ownership

    _transfer(msg.sender, _to, _optionId);// transferred by calling the internal function
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {//authorized thirdparty can transfer
    require(_to != address(0));// 
    require(_to != address(this));// avoid sending itsel
    require(_approvedFor(msg.sender, _tokenId));// confirm if it is an authorized thirdparty by owner
    require(_owns(_from, _tokenId));// // confirms if owner really owns it

    _transfer(_from, _to, _tokenId);// calling internal function to transfer
  }

  function tokensOfOwner(address _owner) external view returns (uint256[]) {//returns list/array of options owned by a particular address
    uint256 balance = balanceOf(_owner);

    if (balance == 0) {
      return new uint256[](0);// if balance is 0 returns a empty array
    } else {
      uint256[] memory result = new uint256[](balance);// array of uint of size "balance""
      uint256 maxOptionId = totalSupply();
      uint256 idx = 0;

      uint256 tokenId;
      for (tokenId = 1; tokenId <= maxOptionId; tokenId++) {
        if (optionsIndexToOwner[tokenId] == _owner) {
          result[idx] = tokenId;
          idx++;
        }
      }
    }

    return result;
  }

        
    }