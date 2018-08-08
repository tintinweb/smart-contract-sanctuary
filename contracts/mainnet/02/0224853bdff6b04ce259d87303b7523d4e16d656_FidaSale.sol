pragma solidity ^0.4.23;

// File: zeppelin-solidity/contracts/math/Math.sol

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/BonusProgram.sol

contract BonusProgram {
  using SafeMath for uint256;

  // Amount of decimals specified for the ERC20 token
  uint constant DECIMALS = 18;

  // Initial amount of bonus program tokens
  uint256 public initialBonuslistTokens;
  // Tokens that have been bought in bonus program
  uint256 public tokensBoughtInBonusProgram = 0;

  constructor(uint256 _initialBonuslistTokens) public {
    initialBonuslistTokens = _initialBonuslistTokens;
  }

  /**
   * @dev Calculates the amount of bonus tokens a buyer gets, based on how much the buyer bought and in which bonus threshold the purchase falls.
   *      Note that this function does not modify any variables besides the _totalTokensSold, the responsibility for that lies with the caller.
   * @param _tokensBought Number of tokens a buyer bought
   * @param _totalTokensSold Number of tokens sold prior to the buyer buying their tokens
   * @return The amount of tokens the buyer should receive as bonus
   */
  function _calculateBonus(uint256 _tokensBought, uint256 _totalTokensSold) internal pure returns (uint) {
    uint _bonusTokens = 0;
    // This checks if the bonus cap has been reached.
    if (_totalTokensSold > 150 * 10**5 * 10**DECIMALS) {
      return _bonusTokens;
    }
    // Bonus tranches: [ 15%, 10%, 5%, 2.5% ]
    uint8[4] memory _bonusPattern = [ 150, 100, 50, 25 ];
    // Bonus tranche thresholds in millions
    uint256[5] memory _thresholds = [ 0, 25 * 10**5 * 10**DECIMALS, 50 * 10**5 * 10**DECIMALS, 100 * 10**5 * 10**DECIMALS, 150 * 10**5 * 10**DECIMALS ];

    for(uint8 i = 0; _tokensBought > 0 && i < _bonusPattern.length; ++i) {
      uint _min = _thresholds[i];
      uint _max = _thresholds[i+1];

      if(_totalTokensSold >= _min && _totalTokensSold < _max) {
        uint _bonusedPart = Math.min256(_tokensBought, _max - _totalTokensSold);
        _bonusTokens = _bonusTokens.add(_bonusedPart * _bonusPattern[i] / 1000);
        _tokensBought = _tokensBought.sub(_bonusedPart);
        _totalTokensSold  = _totalTokensSold.add(_bonusedPart);
      }
    }
    return _bonusTokens;
  }
}

// File: contracts/interfaces/ContractManagerInterface.sol

/**
 * @title Contract Manager Interface
 * @author Bram Hoven
 * @notice Interface for communicating with the contract manager
 */
interface ContractManagerInterface {
  /**
   * @notice Triggered when contract is added
   * @param _address Address of the new contract
   * @param _contractName Name of the new contract
   */
  event ContractAdded(address indexed _address, string _contractName);

  /**
   * @notice Triggered when contract is removed
   * @param _contractName Name of the contract that is removed
   */
  event ContractRemoved(string _contractName);

  /**
   * @notice Triggered when contract is updated
   * @param _oldAddress Address where the contract used to be
   * @param _newAddress Address where the new contract is deployed
   * @param _contractName Name of the contract that has been updated
   */
  event ContractUpdated(address indexed _oldAddress, address indexed _newAddress, string _contractName);

  /**
   * @notice Triggered when authorization status changed
   * @param _address Address who will gain or lose authorization to _contractName
   * @param _authorized Boolean whether or not the address is authorized
   * @param _contractName Name of the contract
   */
  event AuthorizationChanged(address indexed _address, bool _authorized, string _contractName);

  /**
   * @notice Check whether the accessor is authorized to access that contract
   * @param _contractName Name of the contract that is being accessed
   * @param _accessor Address who wants to access that contract
   */
  function authorize(string _contractName, address _accessor) external view returns (bool);

  /**
   * @notice Add a new contract to the manager
   * @param _contractName Name of the new contract
   * @param _address Address of the new contract
   */
  function addContract(string _contractName, address _address) external;

  /**
   * @notice Get a contract by its name
   * @param _contractName Name of the contract
   */
  function getContract(string _contractName) external view returns (address _contractAddress);

  /**
   * @notice Remove an existing contract
   * @param _contractName Name of the contract that will be removed
   */
  function removeContract(string _contractName) external;

  /**
   * @notice Update an existing contract (changing the address)
   * @param _contractName Name of the existing contract
   * @param _newAddress Address where the new contract is deployed
   */
  function updateContract(string _contractName, address _newAddress) external;

  /**
   * @notice Change whether an address is authorized to use a specific contract or not
   * @param _contractName Name of the contract to which the accessor will gain authorization or not
   * @param _authorizedAddress Address which will have its authorisation status changed
   * @param _authorized Boolean whether the address will have access or not
   */
  function setAuthorizedContract(string _contractName, address _authorizedAddress, bool _authorized) external;
}

// File: contracts/interfaces/MintableTokenInterface.sol

/**
 * @title Mintable Token Interface
 * @author Bram Hoven
 * @notice Interface for communicating with the mintable token
 */
interface MintableTokenInterface {
  /**
   * @notice Triggered when tokens are minted
   * @param _from Address which triggered the minting
   * @param _to Address on which the tokens are deposited
   * @param _tokens Amount of tokens minted
   */
  event TokensMinted(address indexed _from, address indexed _to, uint256 _tokens);

  /**
   * @notice Triggered when the deposit address changes
   * @param _old Old deposit address
   * @param _new New deposit address
   */
  event DepositAddressChanged(address indexed _old, address indexed _new);

  /**
   * @notice Called when new tokens are needed in circulation
   * @param _tokens Amount of tokens to be created
   */
  function mintTokens(uint256 _tokens) external;

  /**
   * @notice Called when tokens are bought in token sale
   * @param _beneficiary Address on which tokens are deposited
   * @param _tokens Amount of tokens to be created
   */
  function sendBoughtTokens(address _beneficiary, uint256 _tokens) external;

  /**
   * @notice Called when deposit address needs to change
   * @param _depositAddress Address on which minted tokens are deposited
   */
  function changeDepositAddress(address _depositAddress) external;
}

// File: contracts/BountyProgram.sol

contract BountyProgram {
  using SafeMath for uint256;

  // Wownity bounty address
  address public bountyAddress;

  // Amount of total tokens that were available
  uint256 TOKENS_IN_BOUNTY = 25 * 10**4 * 10**18;
  // Amount of tokens that are still available
  uint256 tokenAvailable = 25 * 10**4 * 10**18;

  // Name of this contract
  string private contractName;  
  // Contract Manager
  ContractManagerInterface private contractManager;
  // The fida mintable token
  MintableTokenInterface private mintableFida;

  /**
   * @notice Triggered when bounty wallet address is changed
   * @param _oldAddress Address where the bounty wallet used to be
   * @param _newAddress Address where the new bounty wallet is
   */
  event BountyWalletAddressChanged(address indexed _oldAddress, address indexed _newAddress);

  /**
   * @notice Triggered when a bounty is send
   * @param _bountyReceiver Address where the bounty is send to
   * @param _bountyTokens Amount of tokens that have been send
   */
  event BountySend(address indexed _bountyReceiver, uint256 _bountyTokens);

  /**
   * @notice Contructor for creating the fida bounty program
   * @param _contractName Name of this contract in the contract manager
   * @param _bountyAddress Address of where bounty tokens will be send from
   * @param _tokenAddress Address where ERC20 token is located
   * @param _contractManager Address where the contract manager is deployed
   */
  constructor(string _contractName, address _bountyAddress, address _tokenAddress, address _contractManager) public {
    contractName = _contractName;
    bountyAddress = _bountyAddress;
    mintableFida = MintableTokenInterface(_tokenAddress);
    contractManager = ContractManagerInterface(_contractManager);
  }

  /**
   * @notice Change the address to where the bounty will be send when sale starts
   * @param _walletAddress Address of the wallet
   */
  function setBountyWalletAddress(address _walletAddress) external {
    require(contractManager.authorize(contractName, msg.sender));
    require(_walletAddress != address(0));
    require(_walletAddress != bountyAddress);

    address oldAddress = bountyAddress;
    bountyAddress = _walletAddress;

    emit BountyWalletAddressChanged(oldAddress, _walletAddress);
  }

  /**
   * @notice Give out a bounty
   * @param _tokens Amount of tokens to be given out
   * @param _address Address whom will receive the bounty
   */
  function giveBounty(uint256 _tokens, address _address) external {
    require(msg.sender == bountyAddress);

    tokenAvailable = tokenAvailable.sub(_tokens);

    mintableFida.sendBoughtTokens(_address, _tokens);
  }
}

// File: contracts/oraclizeAPI_0.5.sol

// <ORACLIZE_API>
/*
Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016 Oraclize LTD



Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:



The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.



THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// This api is currently targeted at 0.4.18, please import oraclizeAPI_pre0.4.sol or oraclizeAPI_0.4 where necessary
pragma solidity ^0.4.23;

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) external payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) public payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) external payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) public payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) external payable returns (bytes32 _id);
    function getPrice(string _datasource) public returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) public returns (uint _dsprice);
    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function randomDS_getSessionPubKeyHash() external constant returns(bytes32);
}
contract OraclizeAddrResolverI {
    function getAddress() public returns (address _addr);
}
contract usingOraclize {
    uint constant day = 60*60*24;
    uint constant week = 60*60*24*7;
    uint constant month = 60*60*24*30;
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofType_Android = 0x20;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_consensys = 161;

    OraclizeAddrResolverI OAR;

    OraclizeI oraclize;
    modifier oraclizeAPI {
        if((address(OAR)==0)||(getCodeSize(address(OAR))==0))
            oraclize_setNetwork(networkID_auto);

        if(address(oraclize) != OAR.getAddress())
            oraclize = OraclizeI(OAR.getAddress());

        _;
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
      return oraclize_setNetwork();
      networkID; // silence the warning and remain backwards compatible
    }
    function oraclize_setNetwork() internal returns(bool){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){ //mainnet
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){ //ropsten testnet
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            oraclize_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){ //kovan testnet
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){ //rinkeby testnet
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            oraclize_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){ //ethereum-bridge
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){ //ether.camp ide
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){ //browser-solidity
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function __callback(bytes32 myid, string result) public {
        __callback(myid, result, new bytes(0));
    }
    function __callback(bytes32 myid, string result, bytes proof) public {
      return;
      myid; result; proof; // Silence compiler warnings
    }

    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(0, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(0, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }
    function oraclize_setProof(byte proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }
    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }

    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32){
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function parseAddr(string _a) internal pure returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 65)&&(b1 <= 70)) b1 -= 55;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 65)&&(b2 <= 70)) b2 -= 55;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }

    function strCompare(string _a, string _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    function indexOf(string _haystack, string _needle) internal pure returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length))
            return -1;
        else if(h.length > (2**128 -1))
            return -1;
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    // parseInt
    function parseInt(string _a) internal pure returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function stra2cbor(string[] arr) internal pure returns (bytes) {
            uint arrlen = arr.length;

            // get correct cbor output length
            uint outputlen = 0;
            bytes[] memory elemArray = new bytes[](arrlen);
            for (uint i = 0; i < arrlen; i++) {
                elemArray[i] = (bytes(arr[i]));
                outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3; //+3 accounts for paired identifier types
            }
            uint ctr = 0;
            uint cborlen = arrlen + 0x80;
            outputlen += byte(cborlen).length;
            bytes memory res = new bytes(outputlen);

            while (byte(cborlen).length > ctr) {
                res[ctr] = byte(cborlen)[ctr];
                ctr++;
            }
            for (i = 0; i < arrlen; i++) {
                res[ctr] = 0x5F;
                ctr++;
                for (uint x = 0; x < elemArray[i].length; x++) {
                    // if there&#39;s a bug with larger strings, this may be the culprit
                    if (x % 23 == 0) {
                        uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                        elemcborlen += 0x40;
                        uint lctr = ctr;
                        while (byte(elemcborlen).length > ctr - lctr) {
                            res[ctr] = byte(elemcborlen)[ctr - lctr];
                            ctr++;
                        }
                    }
                    res[ctr] = elemArray[i][x];
                    ctr++;
                }
                res[ctr] = 0xFF;
                ctr++;
            }
            return res;
        }

    function ba2cbor(bytes[] arr) internal pure returns (bytes) {
            uint arrlen = arr.length;

            // get correct cbor output length
            uint outputlen = 0;
            bytes[] memory elemArray = new bytes[](arrlen);
            for (uint i = 0; i < arrlen; i++) {
                elemArray[i] = (bytes(arr[i]));
                outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3; //+3 accounts for paired identifier types
            }
            uint ctr = 0;
            uint cborlen = arrlen + 0x80;
            outputlen += byte(cborlen).length;
            bytes memory res = new bytes(outputlen);

            while (byte(cborlen).length > ctr) {
                res[ctr] = byte(cborlen)[ctr];
                ctr++;
            }
            for (i = 0; i < arrlen; i++) {
                res[ctr] = 0x5F;
                ctr++;
                for (uint x = 0; x < elemArray[i].length; x++) {
                    // if there&#39;s a bug with larger strings, this may be the culprit
                    if (x % 23 == 0) {
                        uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                        elemcborlen += 0x40;
                        uint lctr = ctr;
                        while (byte(elemcborlen).length > ctr - lctr) {
                            res[ctr] = byte(elemcborlen)[ctr - lctr];
                            ctr++;
                        }
                    }
                    res[ctr] = elemArray[i][x];
                    ctr++;
                }
                res[ctr] = 0xFF;
                ctr++;
            }
            return res;
        }


    string oraclize_network_name;
    function oraclize_setNetworkName(string _network_name) internal {
        oraclize_network_name = _network_name;
    }

    function oraclize_getNetworkName() internal view returns (string) {
        return oraclize_network_name;
    }

    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32){
        require((_nbytes > 0) && (_nbytes <= 32));
        // Convert from seconds to ledger timer ticks
        _delay *= 10; 
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(_nbytes);
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly { 
            mstore(add(delay, 0x20), _delay) 
        }
        
        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);

        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = oraclize_query("random", args, _customGasLimit);
        
        bytes memory delay_bytes8_left = new bytes(8);
        
        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))

        }
        
        oraclize_randomDS_setCommitment(queryId, keccak256(delay_bytes8_left, args[1], sha256(args[0]), args[2]));
        return queryId;
    }
    
    function oraclize_randomDS_setCommitment(bytes32 queryId, bytes32 commitment) internal {
        oraclize_randomDS_args[queryId] = commitment;
    }

    mapping(bytes32=>bytes32) oraclize_randomDS_args;
    mapping(bytes32=>bool) oraclize_randomDS_sessionKeysHashVerified;

    function verifySig(bytes32 tosignh, bytes dersig, bytes pubkey) internal returns (bool){
        bool sigok;
        address signer;

        bytes32 sigr;
        bytes32 sigs;

        bytes memory sigr_ = new bytes(32);
        uint offset = 4+(uint(dersig[3]) - 0x20);
        sigr_ = copyBytes(dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(dersig, offset+(uint(dersig[offset-1]) - 0x20), 32, sigs_, 0);

        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }


        (sigok, signer) = safer_ecrecover(tosignh, 27, sigr, sigs);
        if (address(keccak256(pubkey)) == signer) return true;
        else {
            (sigok, signer) = safer_ecrecover(tosignh, 28, sigr, sigs);
            return (address(keccak256(pubkey)) == signer);
        }
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes proof, uint sig2offset) internal returns (bool) {
        bool sigok;

        // Step 6: verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)
        bytes memory sig2 = new bytes(uint(proof[sig2offset+1])+2);
        copyBytes(proof, sig2offset, sig2.length, sig2, 0);

        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(proof, 3+1, 64, appkey1_pubkey, 0);

        bytes memory tosign2 = new bytes(1+65+32);
        tosign2[0] = byte(1); //role
        copyBytes(proof, sig2offset-65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1+65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);

        if (sigok == false) return false;


        // Step 7: verify the APPKEY1 provenance (must be signed by Ledger)
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";

        bytes memory tosign3 = new bytes(1+65);
        tosign3[0] = 0xFE;
        copyBytes(proof, 3, 65, tosign3, 1);

        bytes memory sig3 = new bytes(uint(proof[3+65+1])+2);
        copyBytes(proof, 3+65, sig3.length, sig3, 0);

        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);

        return sigok;
    }

    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string _result, bytes _proof) {
        // Step 1: the prefix has to match &#39;LP\x01&#39; (Ledger Proof version 1)
        require((_proof[0] == "L") && (_proof[1] == "P") && (_proof[2] == 1));

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        require(proofVerified);

        _;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string _result, bytes _proof) internal returns (uint8){
        // Step 1: the prefix has to match &#39;LP\x01&#39; (Ledger Proof version 1)
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) return 1;

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (proofVerified == false) return 2;

        return 0;
    }

    function matchBytes32Prefix(bytes32 content, bytes prefix, uint n_random_bytes) internal pure returns (bool){
        bool match_ = true;
        
        require(prefix.length == n_random_bytes);

        for (uint256 i=0; i< n_random_bytes; i++) {
            if (content[i] != prefix[i]) match_ = false;
        }

        return match_;
    }

    function oraclize_randomDS_proofVerify__main(bytes proof, bytes32 queryId, bytes result, string context_name) internal returns (bool){

        // Step 2: the unique keyhash has to match with the sha256 of (context name + queryId)
        uint ledgerProofLength = 3+65+(uint(proof[3+65+1])+2)+32;
        bytes memory keyhash = new bytes(32);
        copyBytes(proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(sha256(context_name, queryId)))) return false;

        bytes memory sig1 = new bytes(uint(proof[ledgerProofLength+(32+8+1+32)+1])+2);
        copyBytes(proof, ledgerProofLength+(32+8+1+32), sig1.length, sig1, 0);

        // Step 3: we assume sig1 is valid (it will be verified during step 5) and we verify if &#39;result&#39; is the prefix of sha256(sig1)
        if (!matchBytes32Prefix(sha256(sig1), result, uint(proof[ledgerProofLength+32+8]))) return false;

        // Step 4: commitment match verification, keccak256(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8+1+32);
        copyBytes(proof, ledgerProofLength+32, 8+1+32, commitmentSlice1, 0);

        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength+32+(8+1+32)+sig1.length+65;
        copyBytes(proof, sig2offset-64, 64, sessionPubkey, 0);

        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[queryId] == keccak256(commitmentSlice1, sessionPubkeyHash)){ //unonce, nbytes and sessionKeyHash match
            delete oraclize_randomDS_args[queryId];
        } else return false;


        // Step 5: validity verification for sig1 (keyhash and args signed with the sessionKey)
        bytes memory tosign1 = new bytes(32+8+1+32);
        copyBytes(proof, ledgerProofLength, 32+8+1+32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) return false;

        // verify if sessionPubkeyHash was verified already, if not.. let&#39;s do it!
        if (oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] == false){
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(proof, sig2offset);
        }

        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    function copyBytes(bytes from, uint fromOffset, uint length, bytes to, uint toOffset) internal pure returns (bytes) {
        uint minLength = length + toOffset;

        // Buffer too small
        require(to.length >= minLength); // Should be a better way?

        // NOTE: the offset 32 is added to skip the `size` field of both bytes variables
        uint i = 32 + fromOffset;
        uint j = 32 + toOffset;

        while (i < (32 + fromOffset + length)) {
            assembly {
                let tmp := mload(add(from, i))
                mstore(add(to, j), tmp)
            }
            i += 32;
            j += 32;
        }

        return to;
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    // Duplicate Solidity&#39;s ecrecover, but catching the CALL return value
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
        // We do our own memory management here. Solidity uses memory offset
        // 0x40 to store the current end of memory. We write past it (as
        // writes are memory extensions), but don&#39;t update the offset so
        // Solidity will reuse it. The memory used here is only needed for
        // this context.

        // FIXME: inline assembly can&#39;t access return values
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

            // NOTE: we can reuse the request memory because we deal with
            //       the return code
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    function ecrecovery(bytes32 hash, bytes sig) internal returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

            // Here we are loading the last 32 bytes. We exploit the fact that
            // &#39;mload&#39; will pad with zeroes if we overread.
            // There is no &#39;mload8&#39; to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))

            // Alternative solution:
            // &#39;byte&#39; is not working due to the Solidity parser, so lets
            // use the second best option, &#39;and&#39;
            // v := and(mload(add(sig, 65)), 255)
        }

        // albeit non-transactional signatures are not specified by the YP, one would expect it
        // to match the YP range of [27, 28]
        //
        // geth uses [0, 1] and some clients have followed. This might change, see:
        //  https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        return safer_ecrecover(hash, v, r, s);
    }

}
// </ORACLIZE_API>

// File: contracts/PriceChecker.sol

/**
 * @title Price Checker
 * @author Bram Hoven
 * @notice Retrieves the current Ether price in euros and converts it to the amount of fida per ether
 */
contract PriceChecker is usingOraclize {

  // The address that is allowed to call the `updatePrice()` function
  address priceCheckerAddress;
  // Current price of ethereum in euros
  string public ETHEUR = "571.85000";
  // Amount of fida per ether
  uint256 public fidaPerEther = 57185000;
  // Latest callback id
  mapping(bytes32 => bool) public ids;
  // Gaslimit to be used by oraclize
  uint256 gasLimit = 58598;

  /**
   * @notice Triggered when price is updated
   * @param _id Oraclize query id
   * @param _price Price of 1 ether in euro&#39;s
   */
  event PriceUpdated(bytes32 _id, string _price);
  /**
   * @notice Triggered when updatePrice() is called
   * @param _id Oraclize query id
   * @param _fees The price of the oraclize call in ether
   */
  event NewOraclizeQuery(bytes32 _id, uint256 _fees);

  /**
   * @notice Triggered when fee is lower than this.balance
   * @param _description String with message
   * @param _fees The amount of wei it cost to perform this query
   */
  event OraclizeQueryNotSend(string _description, uint256 _fees);

  /**
   * @notice Contructor for initializing the pricechecker
   * @param _priceCheckerAddress Address which is allow to call `updatePrice()`
   */
  constructor(address _priceCheckerAddress) public payable {
    priceCheckerAddress = _priceCheckerAddress;

    _updatePrice();
  }

  /**
   * @notice Function for updating the price stored in this contract
   */
  function updatePrice() public payable {
    require(msg.sender == priceCheckerAddress);

    _updatePrice();
  }

  function _updatePrice() private {
    if (oraclize_getPrice("URL", gasLimit) > address(this).balance) {
      emit OraclizeQueryNotSend("Oraclize query was NOT sent, please add some ETH to cover for the query fee", oraclize_getPrice("URL"));
    } else {
      bytes32 id = oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHEUR).result.XETHZEUR.a[0]", gasLimit);
      ids[id] = true;
      emit NewOraclizeQuery(id, oraclize_getPrice("URL"));
    }
  }

  /**
   * @notice Oraclize callback function
   * @param _id The id of the query
   * @param _result Result of the query
   */
  function __callback(bytes32 _id, string _result) public {
    require(msg.sender == oraclize_cbAddress());
    require(ids[_id] == true);

    ETHEUR = _result;
    // Save price of ether as an uint without the 5 decimals (350.00000 * 10**5 = 35000000)
    fidaPerEther = parseInt(_result, 5);

    emit PriceUpdated(_id, _result);
  }

  /**
   * @notice Change gasLimit
   */
  function changeGasLimit(uint256 _gasLimit) public {
    require(msg.sender == priceCheckerAddress);

    gasLimit = _gasLimit;
  }
}

// File: contracts/interfaces/MemberManagerInterface.sol

/**
 * @title Member Manager Interface
 * @author Bram Hoven
 */
interface MemberManagerInterface {
  /**
   * @notice Triggered when member is added
   * @param member Address of newly added member
   */
  event MemberAdded(address indexed member);

  /**
   * @notice Triggered when member is removed
   * @param member Address of removed member
   */
  event MemberRemoved(address indexed member);

  /**
   * @notice Triggered when member has bought tokens
   * @param member Address of member
   * @param tokensBought Amount of tokens bought
   * @param tokens Amount of total tokens bought by member
   */
  event TokensBought(address indexed member, uint256 tokensBought, uint256 tokens);

  /**
   * @notice Remove a member from this contract
   * @param _member Address of member that will be removed
   */
  function removeMember(address _member) external;

  /**
   * @notice Add to the amount this member has bought
   * @param _member Address of the corresponding member
   * @param _amountBought Amount of tokens this member has bought
   */
  function addAmountBoughtAsMember(address _member, uint256 _amountBought) external;
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/FidaSale.sol

/**
 * @title Fida Sale
 * @author Bram Hoven
 * @notice Contract which will run the fida sale
 */
contract FidaSale is BonusProgram, BountyProgram, PriceChecker {
  using SafeMath for uint256;

  // Wownity wallet
  address public wallet;

  // Address which can buy tokens that have been bought with btc
  address public btcTokenBoughtAddress;
  // Address which can add addresses to the whitelist
  address public whitelistingAddress;

  // Contract Manager
  ContractManagerInterface private contractManager;
  // Name of this contract
  string private contractName;

  // The fida ERC20 token
  ERC20Basic private fidaToken;
  // The fida mintable token
  MintableTokenInterface private mintableFida;
  // Address on which the fida ERC20 contract is deployed
  address public fidaTokenAddress;
  // Amount of decimals specified for the ERC20 token
  uint256 public DECIMALS = 18;

  // Contract for earlybird check
  MemberManagerInterface public earlybird;

  // Total amount of investors
  uint256 public investorCount;

  // Investor whitelist
  mapping(address => bool) public whitelist;
  // Mapping of all our investors and amount they invested
  mapping(address => uint256) public investors;

  // Initial amount of bonus program tokens
  uint256 public INITIAL_BONUSLIST_TOKENS = 150 * 10**5 * 10**DECIMALS; // 15,000,000 fida
  // Initial amount of earlybird program tokens
  uint256 public INITIAL_EARLYBIRD_TOKENS = 50 * 10**5 * 10**DECIMALS; // 5,000,000 fida
  // Tokens that have been bought in early bird program
  uint256 public tokensBoughtInEarlybird = 0;

  // Shows the state of the bonus program
  bool public bonusProgramEnded = false;
  // Shows the state of the earlybird progran
  bool public earlybirdEnded = false;

  // Shows whether the fida sale has started
  bool public started = false;
  // Shows the state of the fida sale
  bool public finished = false;

  /**
   * @notice Triggered when token address is changed
   * @param _oldAddress Address where the ERC20 contract used to be
   * @param _newAddress Address where the new ERC20 contract is now deployed
   */
  event TokenAddressChanged(address indexed _oldAddress, address indexed _newAddress);

  /**
   * @notice Triggered when wallet address is changed
   * @param _oldAddress Address where the wallet used to be
   * @param _newAddress Address where the new wallet is
   */
  event WalletAddressChanged(address indexed _oldAddress, address indexed _newAddress);

  /**
   * @notice Triggered when btc token bought address is changed
   * @param _oldAddress Address what the authorized address used to be
   * @param _newAddress Address what the authorized address 
   */
  event BtcTokenBoughtAddressChanged(address indexed _oldAddress, address indexed _newAddress);

  /**
   * @notice Triggered when the whitelisting address is changed
   * @param _oldAddress Address what the authorized address used to be
   * @param _newAddress Address what the authorized address 
   */
  event WhitelistingAddressChanged(address indexed _oldAddress, address indexed _newAddress);

  /**
   * @notice Triggered when the whitelisting has changed for an address
   * @param _address Address which whitelisting status has changed
   * @param _whitelisted Status of his whitelisting (true = whitelisted)
   */
  event WhitelistChanged(address indexed _address, bool _whitelisted);

  /**
   * @notice Triggered when sale has started
   */
  event StartedSale();

  /**
   * @notice Triggered when sale has ended
   */
  event FinishedSale();

  /**
   * @notice Triggered when a early bird purchase has been made
   * @param _buyer Address who bought the tokens
   * @param _tokens Amount of tokens that have been bought
   */
  event BoughtEarlyBird(address indexed _buyer, uint256 _tokens);

  /**
   * @notice Triggered when a bonus program purchase has been made
   * @param _buyer Address who bought the tokens
   * @param _tokens Amount of tokens bought excl. bonus tokens
   * @param _bonusTokens Amount of bonus tokens received
   */
  event BoughtBonusProgram(address indexed _buyer, uint256 _tokens, uint256 _bonusTokens);

  /**
   * @notice Contructor for creating the fida sale
   * @param _contractName Name of this contract in the contract manager
   * @param _wallet Address of wallet where funds will be send
   * @param _bountyAddress Address of wallet where bounty tokens will be send to
   * @param _btcTokenBoughtAddress Address which is authorized to send tokens bought with btc
   * @param _whitelistingAddress Address which is authorized to add address to the whitelist
   * @param _priceCheckerAddress Address which is allow to call `updatePrice()`
   * @param _contractManager Address where the contract manager is deployed
   * @param _tokenContractName Name of the token contract in the contract manager
   * @param _memberContractName Name of the member manager contract in the contract manager
   */
  constructor(string _contractName, address _wallet, address _bountyAddress, address _btcTokenBoughtAddress, address _whitelistingAddress, address _priceCheckerAddress, address _contractManager, string _tokenContractName, string _memberContractName) public payable 
    BonusProgram(INITIAL_BONUSLIST_TOKENS) 
    BountyProgram(_contractName, _bountyAddress, _bountyAddress, _contractManager) 
    PriceChecker(_priceCheckerAddress) {

    contractName = _contractName;
    wallet = _wallet;
    btcTokenBoughtAddress = _btcTokenBoughtAddress;
    whitelistingAddress = _whitelistingAddress;
    contractManager = ContractManagerInterface(_contractManager);

    _changeTokenAddress(contractManager.getContract(_tokenContractName));
    earlybird = MemberManagerInterface(contractManager.getContract(_memberContractName));
  }

  /**
   * @notice Internal function for changing the token address
   * @param _tokenAddress Address where the new ERC20 contract is deployed
   */
  function _changeTokenAddress(address _tokenAddress) internal {
    require(_tokenAddress != address(0));

    address oldAddress = fidaTokenAddress;
    fidaTokenAddress = _tokenAddress;
    fidaToken = ERC20Basic(_tokenAddress);
    mintableFida = MintableTokenInterface(_tokenAddress);

    emit TokenAddressChanged(oldAddress, _tokenAddress);
  }

  /**
   * @notice Change the wallet where ether will be sent to when tokens are bought
   * @param _walletAddress Address of the wallet
   */
  function setWalletAddress(address _walletAddress) external {
    require(contractManager.authorize(contractName, msg.sender));
    require(_walletAddress != address(0));
    require(_walletAddress != wallet);

    address oldAddress = wallet;
    wallet = _walletAddress;

    emit WalletAddressChanged(oldAddress, _walletAddress);
  }
  
  /**
   * @notice Change the address which is authorized to send bought tokens with BTC
   * @param _address Address of the authorized btc tokens bought client
   */
  function setBtcTokenBoughtAddress(address _address) external {
    require(contractManager.authorize(contractName, msg.sender));
    require(_address != address(0));
    require(_address != btcTokenBoughtAddress);

    address oldAddress = btcTokenBoughtAddress;
    btcTokenBoughtAddress = _address;

    emit BtcTokenBoughtAddressChanged(oldAddress, _address);
  }

  /**
   * @notice Change the address that is authorized to change whitelist
   * @param _address The authorized address
   */
  function setWhitelistingAddress(address _address) external {
    require(contractManager.authorize(contractName, msg.sender));
    require(_address != address(0));
    require(_address != whitelistingAddress);

    address oldAddress = whitelistingAddress;
    whitelistingAddress = _address;

    emit WhitelistingAddressChanged(oldAddress, _address);
  }

  /**
   * @notice Set the whitelist status for an address
   * @param _address Address which will have his status changed
   * @param _whitelisted True or False whether whitelisted or not
   */
  function setWhitelistStatus(address _address, bool _whitelisted) external {
    require(msg.sender == whitelistingAddress);
    require(whitelist[_address] != _whitelisted);

    whitelist[_address] = _whitelisted;

    emit WhitelistChanged(_address, _whitelisted);
  }

  /**
   * @notice Get the whitelist status for an address
   * @param _address Address which is or isn&#39;t whitelisted
   */
  function getWhitelistStatus(address _address) external view returns (bool _whitelisted) {
    require(msg.sender == whitelistingAddress);

    return whitelist[_address];
  }

  /**
   * @notice Amount of fida you would get for any amount in wei
   * @param _weiAmount Amount of wei you want to know the amount of fida for
   */
  function getAmountFida(uint256 _weiAmount) public view returns (uint256 _fidaAmount) {
    require(_weiAmount != 0);

    // fidaPerEther has been mutliplied by 10**5 because of decimals
    // so we have to divide by 100000
    _fidaAmount = _weiAmount.mul(fidaPerEther).div(100000);

    return _fidaAmount;
  }

  /**
   * @notice Internal function for investing as a earlybird member
   * @param _beneficiary Address on which tokens will be deposited
   * @param _amountTokens Amount of tokens that will be bought
   */
  function _investAsEarlybird(address _beneficiary, uint256 _amountTokens) internal {
    tokensBoughtInEarlybird = tokensBoughtInEarlybird.add(_amountTokens);

    earlybird.addAmountBoughtAsMember(_beneficiary, _amountTokens);
    _depositTokens(_beneficiary, _amountTokens);

    emit BoughtEarlyBird(_beneficiary, _amountTokens);

    if (tokensBoughtInEarlybird >= INITIAL_EARLYBIRD_TOKENS) {
      earlybirdEnded = true;
    }
  }

  /**
   * @notice Internal function for invest as a bonusprogram member
   * @param _beneficiary Address on which tokens will be deposited
   * @param _amountTokens Amount of tokens that will be bought
   */
  function _investAsBonusProgram(address _beneficiary, uint256 _amountTokens) internal {
    uint256 bonusTokens = _calculateBonus(_amountTokens, tokensBoughtInBonusProgram);
    uint256 amountTokensWithBonus = _amountTokens.add(bonusTokens);

    tokensBoughtInBonusProgram = tokensBoughtInBonusProgram.add(_amountTokens);

    _depositTokens(_beneficiary, amountTokensWithBonus);

    emit BoughtBonusProgram(_beneficiary, _amountTokens, bonusTokens);

    if (tokensBoughtInBonusProgram >= INITIAL_BONUSLIST_TOKENS) {
      bonusProgramEnded = true;
    }
  }

  /**
   * @notice Internal function for depositing tokens after they had been bought
   * @param _beneficiary Address on which the tokens will be deposited
   * @param _amountTokens Amount of tokens that have been bought
   */
  function _depositTokens(address _beneficiary, uint256 _amountTokens) internal {
    require(_amountTokens != 0);

    if (investors[_beneficiary] == 0) {
      investorCount++;
    }

    investors[_beneficiary] = investors[_beneficiary].add(_amountTokens);

    mintableFida.sendBoughtTokens(_beneficiary, _amountTokens);
  }

  /**
   * @notice Public payable function to buy tokens during sale or emission
   * @param _beneficiary Address to which tokens will be deposited
   */
  function buyTokens(address _beneficiary) public payable {
    require(started);
    require(!finished);
    require(_beneficiary != address(0));
    require(msg.value != 0);
    require(whitelist[msg.sender] && whitelist[_beneficiary]);
    require(fidaToken.totalSupply() < 24750 * 10**3 * 10**DECIMALS);

    uint256 amountTokens = getAmountFida(msg.value);
    require(amountTokens >= 50 * 10**DECIMALS);

    if (!earlybirdEnded) {
      _investAsEarlybird(_beneficiary, amountTokens);
    } else {
      _investAsBonusProgram(_beneficiary, amountTokens);
    }

    wallet.transfer(msg.value);
  }

  /**
   * @notice Public payable function to buy tokens during sale or emission
   * @param _beneficiary Address to which tokens will be deposited
   * @param _tokens Amount of tokens that will be bought
   */
  function tokensBoughtWithBTC(address _beneficiary, uint256 _tokens) public payable {
    require(msg.sender == btcTokenBoughtAddress);
    require(started);
    require(!finished);
    require(_beneficiary != address(0));
    require(whitelist[_beneficiary]);
    require(fidaToken.totalSupply() < 24750 * 10**3 * 10**DECIMALS);
    require(_tokens >= 50 * 10**DECIMALS);

    if (!earlybirdEnded) {
      _investAsEarlybird(_beneficiary, _tokens);
    } else {
      _investAsBonusProgram(_beneficiary, _tokens);
    }
  }

  /**
   * @notice Anonymous payable function, this makes it easier for people to buy their tokens
   */
  function () public payable {
    buyTokens(msg.sender);
  }

  /**
   * @notice Function to start this sale
   */
  function startSale() public {
    require(contractManager.authorize(contractName, msg.sender));
    require(!started);
    require(!finished);

    started = true;

    emit StartedSale();
  }

  /**
   * @notice Function to finish this sale
   */
  function finishedSale() public {
    require(contractManager.authorize(contractName, msg.sender));
    require(started);
    require(!finished);

    finished = true;

    emit FinishedSale();
  }
}