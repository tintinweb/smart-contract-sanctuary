/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

pragma solidity ^0.5.17;

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


contract farmControl is Ownable {
    
    using SafeMath for uint256;
    using Address  for address;
    
    
    IBEP20  public tokenAddr;
    address public CMO;
    //address public oper;

    
    struct farmland {
        address farmer;
        address depositToken;
        address rewardToken;
        uint256 farmSize;
        uint256 pricePerAcre;
        uint256 limitPerAcre;
        bool    isInit;
        bool    isSold;
    }
    
    uint256 private farmIndex;
    
    mapping(address => farmland) private farmList;
    mapping(uint256 => address)  private farmListIndex;
    

    event farmered(uint num, uint size ,address indexed farmer, uint256 amount);
    event newFarmered( uint num, uint size,address indexed oldFarmer,address indexed newFarmer);
    event initFarmed(address farm, address depositToken ,address rewardToken ,uint256 farmSize , uint256 pricePerAcre ,uint256 limitPerAcre);
    event updateFarmerLanded( uint num,uint size , address[]  farmlandall  );
    event beFriendsed(address invitees,address invited);

    constructor(address _erc20) public {
        
        tokenAddr    = IBEP20(_erc20);
        farmIndex    = 0;
        
    }
    
    modifier canBuy(address farm){
        require(farmList[farm].isInit == true);
        require(farmList[farm].isSold == false);
        _;
    }
    
    function addFarm(address newFarm) public onlyCMO {
        require(newFarm != address(0));
        
        farmIndex += 1;
        farmListIndex[farmIndex] = newFarm;
        farmland memory newFarmland;
        farmList[newFarm] = newFarmland;
    }
    
    function initFarm(address farm, address depositToken ,address rewardToken ,uint256 farmSize , uint256 pricePerAcre ,uint256 limitPerAcre) public onlyCMO{
        require(farm != address(0));
        farmList[farm].depositToken = depositToken;
        farmList[farm].rewardToken  = rewardToken;
        farmList[farm].farmSize     = farmSize;
        farmList[farm].pricePerAcre = pricePerAcre;
        farmList[farm].limitPerAcre = limitPerAcre;
        farmList[farm].isInit       = true;
        
        emit initFarmed(farm,depositToken,rewardToken,farmSize,pricePerAcre,limitPerAcre);
    }
    /**
    function buyFarm(address farm) public canBuy(farm){
        require(farm != address(0));
        farmList[farm].farmer = msg.sender;
        (bool success, bytes memory data) = farm.call(abi.encodeWithSelector(0x2b4b6795,msg.sender));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
        farmList[farm].isSold = true;
    }
    **/
    
    function buyFarm(address farm) public {
        //farmList[farm].isSold = true;
        //farmList[farm].isSold = false;
    }
    
    function getFarmCanBuy() public returns(address){
        address test = 0xBFE1dE098047d97650e7EE10647559B594e63F81;
        return test;
    }
    
    function start(uint256 startTime,uint256 period) public onlyCMO {
        require(startTime > block.timestamp);
        require(period > 0);
        
    }
    
    
    /**
    modifier isFarmerInit(uint num) {
        require(farmerOwner[num].isInit,"farmer not inited");
        _;
    }
    **/
    function beFriends(address invitees, address invited) public {
        emit beFriendsed(invitees,invited);
    }

    
}