//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./LibHabilitation.sol";
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function add8(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
     function sub8(uint8 a, uint8 b) internal pure returns (uint8) {
        return sub8(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub8(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b <= a, errorMessage);
        uint8 c = a - b;

        return c;
    }


    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/// @title Contract for users onboarding
/// @notice Allows parent address to get, add and modify data via indexes.
/// @dev All indexes are starting at 1

/********************************************************************************\
*                          Implementation of a Habilitation Folder.
*                         = = = = = = = = = = = = = = = 
*
* Author: Sergio Giardina ( [email protected])
*
/******************************************************************************/

contract HabilitationDirectory is Context {
    
  using SafeMath for uint256;
    /********************************************************************************\
*                          Private Variables 

/******************************************************************************/
  
  address private ownerAddress;
  address private acquirerServer;
  address private parentAddress;
  address private issuerAddress;
  string public safeVersion = "01.04";
  uint private customerId;
  uint private safeType ;
  uint private issuerQB;
  string[] private IndexList;
  string[] private Categories;
  string private listCategory;
  string private listCurrencies;
  uint private CountCategories;
  uint private acquirerActivationStatus;
  uint private issuerActivationStatus;
  uint private CountIndexHabiliatedList;
  uint private CountIndexOrders;

  mapping (uint => LibHabilitation.Order) private orders;
  mapping (address => LibHabilitation.HabStruct) private habilitatedAddressesInfo;
  mapping (uint => address) private habilitatedAddressesList;
  mapping (address => mapping (string => uint)) private habilitatedAddressAuthTrans;

  
/*
  address public ownerAddress;
  address  public parentAddress;
  address public issuerAddress;
  string public safeVersion = "01.02";
  uint public customerId;
  uint public issuerQB;
  uint public safeType ;
  string[] public IndexList;
   uint public acquirerActivationStatus;
  uint public issuerActivationStatus;
  
  uint public CountIndexHabiliatedList;
  uint public CountIndexOrders;
  
  mapping (uint => LibHabilitation.Order) public orders;
  mapping (address => LibHabilitation.HabStruct) public habilitatedAddressesInfo;
  mapping (uint => address) public habilitatedAddressesList;
  mapping (address => mapping (string => uint)) public habilitatedAddressAuthTrans;
  mapping (address => mapping (uint => string)) public habilitatedAddressTransName;
  
  
*/
   /********************************************************************************\
*                          Implementation of modifiers

/******************************************************************************/
  

  modifier onlyParent() {
      require(_msgSender() == parentAddress || _msgSender() == acquirerServer, "Only parent or Acquirer server");
      _;
  }
  
  modifier onlyIssuer() {
      require(_msgSender() == issuerAddress, "Only Issuer");

     
      _;
  }

  
  modifier PermissionToCreate() {
     require(habilitatedAddressesInfo[_msgSender()].valid == 1, "Not habilitated");
      require(habilitatedAddressesInfo[_msgSender()].Hab_create == true, "Not allowed");
      _;
 }


  modifier checkActive() {
    require(issuerActivationStatus == 1 && acquirerActivationStatus == 1, "Not activated");
    _;
    
}
 
 modifier checkCategory(string memory category) { 
     bool found = _checkElementInArrayString(category,Categories,CountCategories);
     require(found == true, "This category is not in the folder ");
     _;
 }
  
 modifier checkIndex(uint _index , uint CountIndex) {
      require(_index <= CountIndex && _index > 0  , "not allowed");
      _;
 }
 
 modifier validSign(uint _index){
    require(habilitatedAddressesInfo[_msgSender()].valid == 1, "Not habilitated");
    require(habilitatedAddressesInfo[_msgSender()].Hab_sign == true, "Not allowed");
    require(orders[_index - 1 ].LastStatus == 1 , "Not allowed sign");
    _;
 }
 
 modifier valid(address _habilitated)
 {   require(_habilitated != address(0), "address not valid");
      require(habilitatedAddressesInfo[_habilitated].valid == 1 ,"address not habilitated");
      _;
     
 }
 
 
   /********************************************************************************\
*                          Implementation of a Internal Functions.

/******************************************************************************/

     function checkCategoryFunction(string memory category) private view { 
     bool found = _checkElementInArrayString(category,Categories,CountCategories);
     require(found == true, "This category is not in the folder ");}
  

 
 
     function createOrderInternal(bytes32  _m, bytes32[] memory _header, address[] memory _trans, uint[] memory _vectorHeader) private {
                LibHabilitation.Order storage r = orders[CountIndexOrders];
                CountIndexOrders = CountIndexOrders.add(1);
              
                
                 r.merkleHeader = _m;
      r.IndexTransaction = _trans.length;
      r.IndexIssuer = 1;
      r.IndexAcquirer = 0;
      r.signed = false;
      r.LastStatus = 1;
      for(uint i = 0 ; i < r.IndexTransaction ; i++)
      {
          r.transactAddress[i] = _trans[i];
          r.VectorHeader[i] = _vectorHeader[i];
      }
      for(uint i = 0; i < _header.length ; i++)
      {
          r.Header[i] = _header[i];
      }
      r.IndexHeader = _header.length;
      r.IssStates[0] = LibHabilitation.StatusOrder(1,block.timestamp, _msgSender());
     // r.AcqStates[0] = LibHabilitation.StatusAcquirer(0,block.timestamp);
       
            
        }
    

    
  /********************************************************************************\
*                          Implementation of a constructor Functions.

/******************************************************************************/


  constructor(address _parentAddress,address _issuerAddress,uint _issuerQB, uint _customerId, string[] memory indexes, string memory _listCategory,string[] memory categories, string memory _listCurrencies , address _acquirerServer) {
      require(_parentAddress != address(0),"Not Valid");
      require(_issuerAddress != address(0),"Not Valid");
      require(_customerId > 0 ,"Not valid customerId");
      require(_issuerQB >= 0 ,"Not valid issuerQB");
      require(indexes.length == 12 ,"Not valid indexes");
      
      ownerAddress = _msgSender();
      parentAddress = _parentAddress;
      issuerAddress = _issuerAddress;
      acquirerServer = _acquirerServer;
      safeType = 10;
      issuerQB = _issuerQB;
      customerId = _customerId;
      acquirerActivationStatus = 0;
      issuerActivationStatus = 0;
      IndexList.push(indexes[0]);
      IndexList.push(indexes[1]);
      IndexList.push(indexes[2]);
      IndexList.push(indexes[3]);
      IndexList.push(indexes[4]);
      IndexList.push(indexes[5]);
      IndexList.push(indexes[6]);
      IndexList.push(indexes[7]);
      IndexList.push(indexes[8]);
      IndexList.push(indexes[9]);
      IndexList.push(indexes[10]);
      IndexList.push(indexes[11]);
      CountCategories = categories.length;
      for(uint i = 0 ; i < categories.length ; i++)
      {Categories.push(categories[i]);}
      listCategory = _listCategory;
      listCurrencies = _listCurrencies;
      
      
      
  }
  
   // @notice: return's parentAddress, issuerAddress, safeType, customerId,issuerQB safeVersion,acquirerActivationStatus, issuerActivationStatus
  function getVariables() public view returns(address,address, uint,uint,uint,string memory,string memory, string memory,uint,uint,address) {
      return (parentAddress, issuerAddress, safeType, customerId, issuerQB, safeVersion, listCategory, listCurrencies,acquirerActivationStatus, issuerActivationStatus,acquirerServer);
  }
  
  
  // @notice: Change status folder activation by issuer address
  function ActivationSignIssuer(uint _status) public onlyIssuer {
     // require(FolderActivation != _status, "Activation Status is already in this state")
      require(_status == 1 || _status == 2, "  not allowed ");
      issuerActivationStatus = _status;
      
  }
   // @notice: Change status folder activation by parent Address 
  function ActivationSignAcquirer(uint _status) public onlyParent{
     // require(FolderActivation != _status, "Activation Status is already in this state")
      require(_status == 1 || _status == 2, "  not allowed ");
      acquirerActivationStatus = _status;

  }
 
  /********************************************************************************\
*                          Implementation of a Index Functions.

/******************************************************************************/
  
  /// @notice Creates index at the end of IndezList
  
 function indexCreate() public onlyParent checkActive {
      IndexList.push("");
  }
  
  /// @notice Updates data at varList index - 1
  function indexUpdate(uint _index, string memory _data) public onlyParent  checkActive checkIndex(_index,IndexList.length) {
      IndexList[_index - 1] = _data;
  }

  /// @notice Returns last index of IndexList + 1
  function indexGetLast() public view returns(uint) {
      return IndexList.length;
  }

  /// @notice Returns IndexList data at index - 1
  function indexGetData(uint _index) public checkIndex(_index,IndexList.length)  view returns(string memory )  {
      return IndexList[_index - 1];
  }
  /// @notice : Returns list habilitated 
  function IssuerGetList() public view returns(address[] memory){
      address[] memory list = new address[](CountIndexHabiliatedList);
      for(uint i = 0 ; i < CountIndexHabiliatedList ; i++)
      {
          list[i] = habilitatedAddressesList[i];
      }
      return list;
  }
  
   /********************************************************************************\
*                          Implementation of a Issuer Functions ( Habilitated addresses).

/******************************************************************************/

  
  
  
  /// @notice : Returns data of habilitated
  function IssuerGetData(address _habilitated) public valid(_habilitated) view returns(uint, bool, bool,string memory, bytes32[] memory, uint[] memory) {
     LibHabilitation.HabStruct memory HabilitatedAddr = habilitatedAddressesInfo[_habilitated];
     uint[] memory amount = new uint[](CountCategories);
     bytes32[] memory _categories = new bytes32[](CountCategories);
     //string[] memory cat = new string[](HabilitatedAddr.IndexCategories);
     for(uint i = 0 ; i < amount.length ; i++)
     {
         amount[i] =  habilitatedAddressAuthTrans[_habilitated][Categories[i]];
         _categories[i] = _stringToBytes32(Categories[i]);
        
     }
     
     return (HabilitatedAddr.encryptionKeyIndex,HabilitatedAddr.Hab_create,HabilitatedAddr.Hab_sign,_bytes32ToString(HabilitatedAddr.iban), _categories,amount);
  }
    
    /// @notice Wrapper for EOA ( encryptionKeyIndex = 0 )
  function IssuerEoaCreate(address _habilitated, bytes32 _iban)  public onlyIssuer checkActive  {
          
          IssuerCreate(_habilitated,0,_iban);
          
      }
      
  
  /// @notice Create a new issuer - new habilitated to create
  function IssuerCreate(address _habilitated, uint _encryptionKeyIndex, bytes32 _iban) public  onlyIssuer  checkActive   {
     
      require(_habilitated != address(0), "address not valid");
      require(habilitatedAddressesInfo[_habilitated].Hab_create == false ,"address already habilitated to create");
   
      
      if(habilitatedAddressesInfo[_habilitated].valid == 1)
      {
          require(habilitatedAddressesInfo[_habilitated].encryptionKeyIndex == _encryptionKeyIndex , "Habilitation to create refused");
          habilitatedAddressesInfo[_habilitated].Hab_create = true ;
      }else {
      habilitatedAddressesInfo[_habilitated] = LibHabilitation.HabStruct(_encryptionKeyIndex,_iban,true,false,1,CountIndexHabiliatedList);
      habilitatedAddressesList[CountIndexHabiliatedList] = _habilitated;
      CountIndexHabiliatedList = CountIndexHabiliatedList.add(1);
     }
  } 
  
     /// @notice Wrapper for EOA ( encryptionKeyIndex = 0 )
  function IssuerEoaSign(address _habilitated, bytes32[] memory _cat, uint[] memory _amount,bytes32 _iban) public onlyIssuer checkActive {
         
          IssuerSign(_habilitated,0,_cat,_amount,_iban);
          
      }
      
   /// @notice Create a new issuer - new habilitated to sign ( with transaction type auth)
  function IssuerSign(address _habilitated, uint _encryptionKeyIndex, bytes32[] memory _cat, uint[] memory _amount, bytes32 _iban)  public onlyIssuer checkActive {
    
    
      for(uint i = 0 ; i < _cat.length ; i++)
      { checkCategoryFunction(_bytes32ToString(_cat[i]));}
      require(_habilitated != address(0), "address not valid");
      require(_cat.length == _amount.length,"not valid");
      require(_cat.length == CountCategories,"not valid length");
      require(habilitatedAddressesInfo[_habilitated].Hab_sign == false ,"address already habilitated to create");
     
      
      
      
       if(habilitatedAddressesInfo[_habilitated].valid == 1)
      {
          require(habilitatedAddressesInfo[_habilitated].encryptionKeyIndex == _encryptionKeyIndex , "Habilitation to sign refused");
          require(habilitatedAddressesInfo[_habilitated].iban == _iban, "Habilitation to sign refused");
          habilitatedAddressesInfo[_habilitated].Hab_sign = true ;
          
      }else {
     habilitatedAddressesInfo[_habilitated]  = LibHabilitation.HabStruct(_encryptionKeyIndex,_iban,false,true,1,CountIndexHabiliatedList);
      habilitatedAddressesList[CountIndexHabiliatedList] = _habilitated;
      CountIndexHabiliatedList = CountIndexHabiliatedList.add(1);
      }
      

      
       for(uint i = 0 ; i < _cat.length; i++)
      {  require(_amount[i] >= 0, "Amount of Transactions not valid ");
      habilitatedAddressAuthTrans[_habilitated][_bytes32ToString(_cat[i])] = _amount[i];
      
      }
      
  }  
  
     /// @notice Create a new issuer - new habilitated to sign ( with transaction type auth)
  function IssuerUpdateCategory(address _habilitated, string memory _cat, uint _amount) public onlyIssuer  checkActive checkCategory(_cat) valid(_habilitated){
 
     require(habilitatedAddressesInfo[_habilitated].Hab_sign == true, " Not permission to sign ");
     habilitatedAddressAuthTrans[_habilitated][_cat] = _amount;
     
      
     
     
  }
  
  function IssuerRemoveCategory(address _habilitated, string memory _cat)  public onlyIssuer  checkActive  checkCategory(_cat) valid(_habilitated){
    /* require(habilitatedAddressesInfo[_habilitated].Hab_sign == true, " Not permission to sign ");
     require(habilitatedAddressAuthTrans[_habilitated][_cat] > 0 , "Not possible to remove ");
     habilitatedAddressAuthTrans[_habilitated][_cat] = 0;
     habilitatedAddressesInfo[_habilitated].IndexCategories = habilitatedAddressesInfo[_habilitated].IndexCategories.sub(1);
     string memory lastCat = habilitatedAddressTransName[_habilitated][habilitatedAddressesInfo[_habilitated].IndexCategories];
     if( habilitatedAddressesInfo[_habilitated].IndexCategories != 0)
      {
          for(uint i = 0 ; i < habilitatedAddressesInfo[_habilitated].IndexCategories ; i++)
          {
              if(_StringEquals(habilitatedAddressTransName[_habilitated][i],_cat))
               {
                   habilitatedAddressTransName[_habilitated][i] = lastCat; 
                   break;
               }
          }
          
      }
      else{
          if(habilitatedAddressesInfo[_habilitated].Hab_create == true)
           {habilitatedAddressesInfo[_habilitated].Hab_sign = false ;
            habilitatedAddressesInfo[_habilitated].any = false;}
          else 
          {
              IssuerDelete(_habilitated);
          }
               
           }
      */
      
  }
 
  /// @notice delete an isser existent and replace it in the list with the last 
  function IssuerDelete(address _habilitated)  public onlyIssuer  checkActive  valid(_habilitated) {
      
      
      habilitatedAddressesInfo[_habilitated].valid = 0;
      habilitatedAddressesInfo[_habilitated].Hab_create = false;
      habilitatedAddressesInfo[_habilitated].Hab_sign = false ;
      habilitatedAddressesInfo[_habilitated].iban = _stringToBytes32("null");
      
  
     
      for( uint i = 0 ; i < CountCategories ; i++)
      {habilitatedAddressAuthTrans[_habilitated][Categories[i]] = 0; }
      
      uint index  = habilitatedAddressesInfo[_habilitated].index;
      CountIndexHabiliatedList = CountIndexHabiliatedList.sub(1);
      if(CountIndexHabiliatedList != 0)
      {habilitatedAddressesInfo[habilitatedAddressesList[CountIndexHabiliatedList]].index = index;
      habilitatedAddressesList[index] = habilitatedAddressesList[CountIndexHabiliatedList];}
      habilitatedAddressesList[CountIndexHabiliatedList] = address(0);
  }
  
   /********************************************************************************\
*      Implementation of a Orders Functions.

/******************************************************************************/
      /// @notice Returns last index of Orders + 1
  function OrderGetLast() public view returns(uint) {
      return CountIndexOrders;
  }
   /// @notice Returns _merkleheader
    function OrderGetMerkleHeader(uint _index ) public  checkIndex(_index,CountIndexOrders) view returns(bytes32) {
      return orders[_index - 1].merkleHeader;
  }
  
  
  
  /// @notice Returns Orders data at index - 1
  function OrderGetData(uint _index) public  checkIndex(_index,CountIndexOrders) view returns(address[] memory , bytes32[] memory ,uint[] memory)  {
      
      address[] memory addr = new address[](orders[_index - 1].IndexTransaction);
      bytes32[] memory data = new bytes32[](orders[_index - 1].IndexHeader);
      uint[] memory dataVector = new uint[](orders[_index - 1].IndexTransaction);
          
      for (uint i = 0 ; i < orders[_index - 1].IndexTransaction; i++)
      {
          addr[i] = orders[_index - 1 ].transactAddress[i];
          dataVector[i] = orders[_index - 1 ].VectorHeader[i];
      }
      for(uint i = 0 ; i < orders[_index - 1].IndexHeader; i++)
      {
          data[i] = orders[_index - 1 ].Header[i];
      }
      return (addr,data,dataVector);
  }
  /*
  function OrderGetDataIndex(uint _index,uint _dindex) public view returns(LibHabilitation.Transaction memory ) {
      require(_index <= CountIndexOrders && _index > 0  , "index not allowed");
      
        return orders[_index - 1 ].transactions[_dindex];
     
      
  } */
  
  /// @notice Returns Orders Status at index - 1
  function OrderGetHabilitated(uint _index) public checkIndex(_index,CountIndexOrders) view returns(uint[] memory,uint[] memory, address[] memory )  {
        address[] memory addr = new address[](orders[_index - 1].IndexIssuer);
        uint[] memory status = new uint[](orders[_index - 1].IndexIssuer);
        uint[] memory timestamp = new uint[](orders[_index - 1].IndexIssuer);
        
       for (uint i = 0 ; i < orders[_index - 1].IndexIssuer; i++)
      {
          addr[i] = orders[_index - 1 ].IssStates[i].habilitatedAddress;
          status[i] =  orders[_index - 1 ].IssStates[i].issuerStatus;
          timestamp[i] =  orders[_index - 1 ].IssStates[i].IssuerTimeStampStatus;
      }
      return (status,timestamp,addr);
  } 
  /// @notice Returns Orders - Acquirer Status at index - 1
  function OrderGetAcquirer(uint _index) public  checkIndex(_index,CountIndexOrders)  view returns(uint[] memory, uint[] memory) {
      uint[] memory status = new uint[](orders[_index - 1].IndexAcquirer);
        uint[] memory timestamp = new uint[](orders[_index - 1].IndexAcquirer);
       for (uint i = 0 ; i < orders[_index - 1].IndexAcquirer; i++)
      {
          status[i] = orders[_index - 1 ].AcqStates[i].AcquStatus;
          timestamp[i] = orders[_index - 1 ].AcqStates[i].AcquirerTimeStampStatus;
          
      }
      return (status,timestamp);
  }
  /// @notice Create a new orders with his transactions
  
  function OrderCreate(bytes32 _merkleheader,address[] memory _TransAddress, bytes32[] memory _TransData,uint[] memory _vectorHeader)  public checkActive PermissionToCreate  {
      
     
      require(_TransAddress.length > 0 && _TransAddress.length == _vectorHeader.length , "Not valid");
      require(_TransData.length    == _vectorHeader[_TransAddress.length - 1], "Not valid vectors");
      createOrderInternal(_merkleheader,_TransData,_TransAddress,_vectorHeader);
      
    
     }
  
  /// @notice Add a new transaction a _index order
  function OrderAdd(uint _index, address _Address, bytes32[] memory _Data) public checkActive  PermissionToCreate checkIndex(_index,CountIndexOrders)  {
      uint j = 0;
      require(orders[_index - 1 ].LastStatus == 1 , "Not allowed add");
      require(orders[_index - 1 ].IndexTransaction >= 1, "Add Invalid");
      orders[_index - 1 ].transactAddress[orders[_index - 1].IndexTransaction]=  _Address ;
      orders[_index - 1 ].VectorHeader[orders[_index - 1].IndexTransaction] = orders[_index - 1 ].IndexHeader.add(_Data.length);
      orders[_index - 1 ].IndexHeader = orders[_index - 1 ].IndexHeader.add(_Data.length);
      
      for(uint i = orders[_index - 1 ].VectorHeader[orders[_index - 1].IndexTransaction - 1] ; i < orders[_index - 1 ].IndexHeader; i ++ )
      {
          orders[_index - 1].Header[i] = _Data[j];
          j= j.add(1);
      }
      orders[_index - 1 ].IndexTransaction = orders[_index - 1 ].IndexTransaction.add(1);
      
  } 
 /// @notice Change status of order 
  function OrderIssuerStatusChange(uint _index, uint _newStatus)   public checkActive  PermissionToCreate checkIndex(_index,CountIndexOrders){
    
      require(_newStatus != 3 && _newStatus != 1 && _newStatus != 0,"Not all status");
      if(_newStatus == 2 )
      {require(orders[_index - 1 ].LastStatus == 1 , "Not all change");}
      else
      {require(orders[_index - 1 ].LastStatus == 3 , "Not all change");}
      orders[_index - 1].LastStatus = _newStatus;
      orders[_index - 1].IssStates[orders[_index - 1].IndexIssuer] = LibHabilitation.StatusOrder(_newStatus,block.timestamp, _msgSender());
      orders[_index - 1 ].IndexIssuer = orders[_index - 1 ].IndexIssuer.add(1);
     }
     
    
 /// @notice Sign order 
   function OrderSign(uint _index, uint _amount, string memory _category,string memory _M) public checkActive checkCategory(_category)  checkIndex(_index,CountIndexOrders) validSign(_index) {
 
     require(habilitatedAddressAuthTrans[_msgSender()][_category]!= 0 ,"Category not auth");
     require(habilitatedAddressAuthTrans[_msgSender()][_category]> _amount ,"Cat VALID,amount not valid");
     require(orders[_index - 1].merkleHeader == _KeccakHashFromString(_category,_amount,_M),"not valid merkle");
     
     
     orders[_index - 1].LastStatus = 3;
     orders[_index - 1].signed = true;
     orders[_index - 1].IssStates[orders[_index - 1 ].IndexIssuer] = LibHabilitation.StatusOrder(3,block.timestamp, _msgSender());
     orders[_index - 1 ].IndexIssuer = orders[_index - 1 ].IndexIssuer.add(1);
   }
   
   /// @notice Change status of parent - order
  function OrderAcquirerAdd(uint _index, uint _newStatus) public onlyParent checkActive  checkIndex(_index,CountIndexOrders)  {
      
      
      orders[_index - 1].AcqStates[orders[_index - 1 ].IndexAcquirer] = LibHabilitation.StatusAcquirer(_newStatus, block.timestamp);
      orders[_index - 1 ].IndexAcquirer = orders[_index - 1 ].IndexAcquirer.add(1);
     }
     

   


}