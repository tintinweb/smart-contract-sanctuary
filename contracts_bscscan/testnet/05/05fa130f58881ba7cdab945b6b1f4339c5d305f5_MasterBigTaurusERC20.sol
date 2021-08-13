/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

pragma solidity =0.5.16;

interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function _totalSupply() external view returns (uint256);
    function getOwner() external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
    function send(address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transferNotification(address from,address to, uint256 value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


interface ISubcontract {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function updateStorageContract(address to)  external;
    function updateMasterContract(address to)  external;

    function mint(address to, uint256 value)  external;
    function burn(address from, uint256 value)  external;
    function approve(address owner,address spender, uint256 value) external returns (bool);
    function send(address owner,address to, uint256 value) external returns (bool);
    function transfer(address owner,address to, uint256 value) external returns (bool);
    function transferFrom(address from,address sender, address to, uint256 value) external returns (bool);
    
    // function projectPercent() external view returns (uint256);
    // function liquidityPercent() external view returns (uint256);
    // function holdersPercent() external view returns (uint256);
    // function charityPercent() external view returns (uint256);

    // function updateProjectPercent(uint256 value)  external;
    // function updateLiquidityPercent(uint256 value)  external;
    // function updateHoldersPercent(uint256 value)  external;
    // function updateCharityPercent(uint256 value)  external;

    // function projectPercentAddress() external view returns (address);
    // function liquidityPercentAddress() external view returns (address);
    // function holdersPercentAddress() external view returns (address);
    // function charityPercentAddress() external view returns (address);

    // function updateProjectPercentAddress(address owner)  external;
    // function updateLiquidityPercentAddress(address owner)  external;
    // function updateHoldersPercentAddress(address owner)  external;
    // function updateCharityPercentAddress(address owner)  external;

    function permit(address owner, address spender, uint256 value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


contract MasterBigTaurusERC20 is IPancakeERC20 {


string constant private FN_Balance    = "Balance";
  bytes32 constant private H_Balance = keccak256(abi.encodePacked(FN_Balance));
  string constant private FN_Allowance   = "Allowances";
  bytes32 constant private H_Allowance  = keccak256(abi.encodePacked(FN_Allowance));
  string constant private FN_TotalSupply    = "TotalSupply";
  bytes32 constant private H_TotalSupply   = keccak256(abi.encodePacked(FN_TotalSupply));
  string constant private FN_Nonces    = "Nonces";
  bytes32 constant private H_Nonces   = keccak256(abi.encodePacked(FN_Nonces));

  // uint256 private _totalSupply;
  uint8 public _decimals= 10;
  string  public _name= "BigTaurus";
  string  public _symbol= "CLUB";


  ISubcontract private subContract;
  IEternalStorage private storageContract;


address  private addressSubContract; 
// @notice Developer address
    address  private contractOwner;
    // @dev Emitted when the Owner changes
    event OwnerTransferredEvent(address indexed previousOwner, address indexed newOwner);


    // @dev Throws if called by any account that's not Owner
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the Developer required");
        _;
    }

    // @dev Tris function for transfering owne functions to new Owner
    // @param newOwner An address of new Owner
    function transferOwner(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "This address is 0!");
        emit OwnerTransferredEvent( contractOwner, newOwner);
        contractOwner = newOwner;
    }

    mapping(address => bool) private blacklist;

    event BlacklistEvent(address addr, uint256 status, string eventText);

    modifier notBlacklisted() {
        require(!blacklist[msg.sender] || contractOwner == msg.sender);
        _;
    }

    function addAddressToBlacklist(address addr) external onlyOwner returns(bool success) {
        if (!blacklist[addr]) {
            blacklist[addr] = true;
            emit BlacklistEvent(addr, 1, "The address has been added to Blacklist");
            success = true;
        }
    }

     function removeAddressFromBlacklist(address addr) external onlyOwner returns(bool success) {
        success = false;
        if (blacklist[addr]) {
            blacklist[addr] = false;
            emit BlacklistEvent(addr, 0, "The address has been deleted from Blacklist");
            success = true;
        }
    }

    function isBlacklistAddress(address addr) public view returns (bool success) {
        return blacklist[addr];
    }


    function getHash(bytes32 _hash, uint256 _id) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_hash, _id));
    }

    function getHash(bytes32 _hash, string memory _str) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_hash, _str));
    }

    function getHash(bytes32 _hash, address _addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_hash, _addr));
    }

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address storageAddr) public {
        uint chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(_name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );

    storageContract = IEternalStorage(storageAddr);

    contractOwner = msg.sender;
    }

  


     function _totalSupply()  external view  returns (uint256) {
      return storageContract.getUint(H_TotalSupply);
    }



 /**
     * @dev Returns the amount of tokens in existence.
     */


    function totalSupply() external view  returns (uint256) {
      return storageContract.getUint(H_TotalSupply);
    }
     /**
     * @dev Returns the token decimals.
     */
    function decimals()  external view  returns (uint8) {
      return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view  returns (string memory){
      return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view  returns (string memory) {
      return _name;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view  returns (address){
      return contractOwner;
    }

    function updateSubContract(address subcontractAddr) onlyOwner public {
      subContract = ISubcontract(subcontractAddr);
      addressSubContract=subcontractAddr;
    }

    function updateStorageContract(address storageAddr) onlyOwner public {
      storageContract = IEternalStorage(storageAddr);
    }

    function _mint(address to, uint256 value) onlyOwner public {
    require(to != address(0), "BEP20: mint to the zero address");
    require(value > 0,  "Amount must be greater than 0.");
        subContract.mint(to,value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) onlyOwner public  {
    require(from != address(0), "BEP20: burn from the zero address");
    require(value > 0,  "Amount must be greater than 0.");
        subContract.burn(from,value);
        emit Transfer(from, address(0), value);
    }

    function balanceOf(address owner) external view  returns(uint256){
      return storageContract.getUint(getHash(H_Balance,owner));
    }

     function allowance(address owner, address spender) external view  returns (uint256) {
      return  storageContract.getUint(getHash(getHash(H_Allowance,owner),spender));  
    }

    function nonces(address owner) external view  returns (uint256) {
      return  storageContract.getUint(getHash(H_Nonces,owner));  
    }


    function approve(address spender, uint256 value) notBlacklisted external returns (bool) {
        subContract.approve(msg.sender, spender, value);
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function send(address to, uint256 value) notBlacklisted external returns (bool) {
        require(to != msg.sender, "BEP20: send to the myyself is not permited");
        subContract.send(msg.sender, to, value);
        emit Transfer(msg.sender, to, value);
        // _transfer(msg.sender, to, value);
        return true;
    }

    function transfer(address to, uint256 value) notBlacklisted external returns (bool) {
        require(to != msg.sender, "BEP20: transfer to the myyself is not permited");
        subContract.transfer(msg.sender, to, value);

     
        return true;
    }


   
    // function transfer(address to, uint256 value) notBlacklisted external returns (bool) {
    //     require(to != msg.sender, "BEP20: transfer to the myyself is not permited");
    //     subContract.transfer(msg.sender, to, value);

    //  uint256  valueWithouComission=value.sub(value.mul(subContract.projectPercent()).div(100));
    //     valueWithouComission=valueWithouComission.sub(value.mul(subContract.liquidityPercent()).div(100));
    //     valueWithouComission=valueWithouComission.sub(value.mul(subContract.holdersPercent()).div(100));
    //     valueWithouComission=valueWithouComission.sub(value.mul(subContract.charityPercent()).div(100));

    //     emit Transfer(msg.sender, to, valueWithouComission);
    //     emit Transfer(msg.sender, subContract.projectPercentAddress(), value.mul(subContract.projectPercent()).div(100));
    //     emit Transfer(msg.sender, subContract.liquidityPercentAddress(), value.mul(subContract.liquidityPercent()).div(100));
    //     emit Transfer(msg.sender, subContract.holdersPercentAddress(), value.mul(subContract.holdersPercent()).div(100));
    //     emit Transfer(msg.sender, subContract.charityPercentAddress(), value.mul(subContract.charityPercent()).div(100));
    //  return true;
    // }


    function transferFrom(address from, address to, uint value) notBlacklisted external returns (bool) {    
        require(to != from, "BEP20: transfer to the same address is not permited");
        subContract.transferFrom(from, msg.sender, to, value);
      
        return true;
    }

    function transferNotification(address from,address to, uint256 value) external returns (bool){
       require(msg.sender == addressSubContract, "BEP20: approve method allowend only from master contract");
    
      emit Transfer(from, to, value);   
    }

    // function transferFrom(address from, address to, uint value) notBlacklisted external returns (bool) {    
    //     require(to != from, "BEP20: transfer to the same address is not permited");
    //     subContract.transferFrom(from, msg.sender, to, value);

    //     uint256  valueWithouComission=value.sub(value.mul(subContract.projectPercent()).div(100));
    //     valueWithouComission=valueWithouComission.sub(value.mul(subContract.liquidityPercent()).div(100));
    //     valueWithouComission=valueWithouComission.sub(value.mul(subContract.holdersPercent()).div(100));
    //     valueWithouComission=valueWithouComission.sub(value.mul(subContract.charityPercent()).div(100));


    //     emit Transfer(msg.sender, to, valueWithouComission);
    //     emit Transfer(msg.sender, subContract.projectPercentAddress(), value.mul(subContract.projectPercent()).div(100));
    //     emit Transfer(msg.sender, subContract.liquidityPercentAddress(), value.mul(subContract.liquidityPercent()).div(100));
    //     emit Transfer(msg.sender, subContract.holdersPercentAddress(), value.mul(subContract.holdersPercent()).div(100));
    //     emit Transfer(msg.sender, subContract.charityPercentAddress(), value.mul(subContract.charityPercent()).div(100));

    //     return true;
    // }

    function permit(address owner, address spender, uint256 value, uint deadline, uint8 v, bytes32 r, bytes32 s) notBlacklisted external {
        subContract.permit(owner, spender, value, deadline,v, r, s);
    }
}

interface IEternalStorage {
  function setBool(bytes32 h, bool v)  external;
  function setInt(bytes32 h, int v) external;
  function setUint(bytes32 h, uint256 v) external;
  function setAddress(bytes32 h, address v) external;
  function setString(bytes32 h, string calldata v) external;
  function setBytes32(bytes32 h, bytes32 v) external;
  function setBytes(bytes32 h, bytes calldata v) external;
  function getBool(bytes32 h) external view returns (bool);
  function getInt(bytes32 h) external view returns (int);
  function getUint(bytes32 h) external view returns (uint256);
  function getAddress(bytes32 h) external view returns (address);
  function getString(bytes32 h) external view returns (string memory);
  function getBytes32(bytes32 h) external view returns (bytes32);
  function getBytes(bytes32 h) external view returns (bytes memory);
}