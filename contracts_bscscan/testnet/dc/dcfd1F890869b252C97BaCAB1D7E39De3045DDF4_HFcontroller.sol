/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

pragma solidity ^0.5.17;

//import "./stake.sol";


library IterableMapping{
    
    struct itmap
    {
        mapping(uint => IndexValue) data;
        KeyFlag[] keys;
        uint size;
    }
    
    struct IndexValue { uint keyIndex; uint value; }
    struct KeyFlag { uint key; bool deleted; }
    
    function insert(itmap storage self, uint key, uint value) public returns (bool replaced){
        uint keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0)
            return true;
        else{
            keyIndex = self.keys.length++;
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
         }
    }
    
    function remove(itmap storage self, uint key) public returns (bool success){
        
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0)
            return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }
    
    function contains(itmap storage self, uint key) view public returns (bool){
        return self.data[key].keyIndex > 0;
    }
    
    function iterate_start(itmap storage self) view public returns (uint keyIndex)
    {
        return iterate_next(self, uint(-1));
    }
    
    function iterate_valid(itmap storage self, uint keyIndex) view public returns (bool){ 
        return keyIndex < self.keys.length;
    }
    
    function iterate_next(itmap storage self, uint keyIndex) view public returns (uint r_keyIndex){
        keyIndex++;
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return keyIndex;
    }
    
    function iterate_get(itmap storage self, uint keyIndex) view public returns (uint key, uint value){
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }
}


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
    
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }    
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract Context {

    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;
    address private _cmo;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CMOTransferred(address indexed previousCMO, address indexed newCMO);

    constructor () internal {
        _owner = _msgSender();
        _cmo   = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
        emit CMOTransferred(address(0), _cmo);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function cmo() public view returns (address) {
        return _cmo;
    }

    modifier onlyCMO() {
        require(isCMO(), "Ownable: caller is not the CMO");
        _;
    }

    function isCMO() public view returns (bool) {
        return _msgSender() == _cmo;
    }

    function renounceCMO() public onlyOwner {
        emit CMOTransferred(_cmo, address(0));
        _cmo = address(0);
    }

    function transferCMO(address newCMO) public onlyCMO {
        _transferCMO(newCMO);
    }

    function _transferCMO(address newCMO) internal {
        require(newCMO != address(0), "Ownable: new CMO is the zero address");
        emit CMOTransferred(_cmo, newCMO);
        _cmo = newCMO;
    }
    
}


interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract HFcontroller is Ownable {
    
    using SafeMath for uint256;
    using Address for address;
    
    
    IBEP20 public tokenAddr;
    //address public CMO;
    address public oper;
    
    uint  private sFarmerLimit;
    uint  private mFarmerLimit;
    uint  private lFarmerLimit;

    struct farmer {
        address    farmerAddr;
        mapping(uint=>address)  farmlandAddr;
        bool       isInit;
        bool       isSold;
    }
        
    struct factory {
        address    factoryOwnerAddr;
        address[]  factoryAddr;
        bool       isInit;
        bool       isSold;
    }
    
    mapping(uint => farmer ) public farmerOwner;
    
    mapping(uint => factory) public factoryOwner;
    
    event farmered(uint num, uint size ,address indexed farmer, uint256 amount);
    event newFarmered( uint num, uint size,address indexed oldFarmer,address indexed newFarmer);
    event initFarmered(uint num,  uint size , address[]  farmlandall);
    event updateFarmerLanded( uint num,uint size , address[]  farmlandall  );
    //event beFriendsed(address invitees,address invited);

    constructor(address _erc20) public {
        
        tokenAddr    = IBEP20(_erc20);
        sFarmerLimit = 3;
        mFarmerLimit = 3;
        lFarmerLimit = 3;
        
    }
    
    modifier isFarmerInit(uint num) {
        require(farmerOwner[num].isInit,"farmer not inited");
        _;
    }
    
    modifier onlyOper(){
        require(msg.sender == oper);
        _;
    }
    
    function setOper(address newOper) public onlyOwner{
        oper = newOper;
    }
    
    /**
    function beFriends(address invitees, address invited) public onlyOper{
        emit beFriendsed(invitees,invited);
    }
    **/
    
    function setSFarmerLimit(uint newLimit) public onlyOwner{
        require(newLimit < 100);
        sFarmerLimit = newLimit;
    }
    
    function setMFarmerLimit(uint newLimit) public onlyOwner{
        require(newLimit < 100);
        mFarmerLimit = newLimit;
    }
    
    function setLFarmerLimit(uint newLimit) public onlyOwner{
        require(newLimit < 100);
        lFarmerLimit = newLimit;
    }    
    
    function getFarmer(uint num) public view returns(address){
        require(farmerOwner[num].isInit,"farmerland have not init");
        return  (farmerOwner[num].farmerAddr);
    }
    
    function getFarmerLand(uint num,uint landNum) public view returns(address){
        require(farmerOwner[num].isInit,"farmerland have not init");
        return  (farmerOwner[num].farmlandAddr[landNum]);
    }
    
    function checkAllFarmerInit() public view returns(bool){
        for(uint i = 0;i< sFarmerLimit;i++){
            if(farmerOwner[i].isInit != true){
                return false;
            }
        }
        
        for(uint i = 100;i< (100 + mFarmerLimit);i++){
            if(farmerOwner[i].isInit != true){
                return false;
            }
        }
        
        for(uint i = 200;i< (200 + lFarmerLimit);i++){
            if(farmerOwner[i].isInit != true){
                return false;
            }
        }
        return true;
    }
    
    function checkFarmerInit(uint num) public view returns(bool){
        return farmerOwner[num].isInit;
    }
    
    /**
    function updateFarmerLand( uint num,uint size , address[] memory farmlandAll  ) public onlyCMO{
    
        require(4 == size || 8 == size || 10 == size);
        
        if( 4 == size ){
            require(num <= sFarmerLimit);
            require(farmlandAll.length == size);
            require(farmerOwner[num].isInit == true);
        }
        else if ( 8 == size ){
            require(num <= (100 + mFarmerLimit));
            require(farmlandAll.length == size);
            require(farmerOwner[num].isInit == true);
        }
        else if ( 10 == size ){
            require(num <= (200 + lFarmerLimit));
            require(farmlandAll.length == size);
            require(farmerOwner[num].isInit == true); 
        }
        else{
            require(false,"farmer size  error");
        }
        
        farmerOwner[num].farmerAddr = address(0);
        
        for(uint i = 0;i<size;i++){
            
            farmerOwner[num].farmlandAddr[i] = farmlandAll[i];
            
           (bool success, bytes memory data) = farmerOwner[num].farmlandAddr[i].call(abi.encodeWithSelector(0x2b4b6795,msg.sender));
            require(success && (data.length == 0 || abi.decode(data, (bool))));            
        }
                
        emit updateFarmerLanded( num, size ,farmlandAll  );
    }
    **/
    /**
    function setNewFarmer(uint num,uint size,address newFarmer) public onlyCMO {
        require(4 == size || 8 == size || 10 == size);
        require(farmerOwner[num].isInit == true);
        
        address oldFarmered = farmerOwner[num].farmerAddr;
        
        farmerOwner[num].farmerAddr = newFarmer;
        
        for(uint i = 0;i<size;i++){
            //farmerOwner[num].farmlandAddr[i] = farmlandAddr[i];
            (bool success, bytes memory data) = farmerOwner[num].farmlandAddr[i].call(abi.encodeWithSelector(0x2b4b6795,newFarmer));
            require(success && (data.length == 0 || abi.decode(data, (bool))));
        }
        
        emit newFarmered(num,size,oldFarmered,newFarmer);
    }
    **/
    
    function initFarmer(uint num,  uint size , address[] memory farmlandAll) public onlyCMO{
        require(4 == size || 8 == size || 10 == size);
        require(farmerOwner[num].isInit == false,"farmer inited");
        
        if( 4 == size ){
            require(num <= sFarmerLimit);
            require(farmlandAll.length == size);
            require(farmerOwner[num].isInit == false);
        }
        else if ( 8 == size ){
            require((99 < num) &&  (num <= (100 + mFarmerLimit)));
            require(farmlandAll.length == size);
            require(farmerOwner[num].isInit == false);
        }
        else if ( 10 == size ){
            require((199 < num) && (num <= (200 + lFarmerLimit)));
            require(farmlandAll.length == size);
            require(farmerOwner[num].isInit == false); 
        }
        else{
            require(false,"farmer size  error");
        }
        
        farmerOwner[num].farmerAddr = address(0);
        
        for(uint i = 0;i<size;i++){
            farmerOwner[num].farmlandAddr[i] = farmlandAll[i];
        }
        
        farmerOwner[num].isInit = true;
        
        emit initFarmered( num,   size , farmlandAll);
            
    }
    
    
    function beFarmer(uint num,uint size ,uint256 amount ) public isFarmerInit(num){
        
        require(farmerOwner[num].isSold == false,"sold out");
        /**
        if(farmerOwner[num].isInit == false ){
            require(false,"need init");
        }
        **/
        
        if( 4 == size ){
            require( 1e23 == amount,"price error");
        }
        else if ( 8 == size ){
            require( 1e24 == amount,"price error");
        }
        else if ( 10 == size){
            require( 1e25 == amount,"price error");
        }
        else{
             require(false,"farmer size  error");
        }
        
        farmerOwner[num].farmerAddr = msg.sender;
        tokenAddr.transferFrom(msg.sender,owner(),amount);
            //bytes4 methodId = bytes4(keccak256("setFarmer(address)"));
        for(uint i = 0;i<size;i++){
            (bool success, bytes memory data) = farmerOwner[num].farmlandAddr[i].call(abi.encodeWithSelector(0x2b4b6795,msg.sender));
            require(success && (data.length == 0 || abi.decode(data, (bool))));
            //addr.call(abi.encodeWithSelector(0x9e502a25,test));
        }
        //for test
        farmerOwner[num].isSold = true;
        
        emit farmered(num , size ,msg.sender, amount);
        
    }
    
}