/**
 * Prototype contract of an insurance pool.
 * Allows authorized wallets of the insurance company to conduct payments and claims for their users.
 * @author: Julia Altenried
 * */
 
pragma solidity ^0.4.23;

contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


contract ERC20{
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

contract Authorizable is Ownable{
    /** tells if a wallet address is authorized to call restricted functions or not **/
    mapping(address => bool) public authorized;
    
    /** checks if the msg sender is authorized. the owner is authorized by default**/
    modifier onlyAuthorized(){
        require(authorized[msg.sender] || msg.sender == owner, "msg sender not authorized");
        _;
    }
    
    /** authorize an address **/
    function authorize(address wallet) public onlyOwner{
        authorized[wallet] = true;
    }
    
    /** revoke authorization of an address **/
    function deauthorize(address wallet) public onlyOwner{
        authorized[wallet] = false;
    }
}

contract InsurancePool is Authorizable{
    /** the stable coin used by this contract **/
    ERC20 public stableCoin;
    /** tells until which time the user paid for **/
    mapping(address => uint) public insuredUntil;
    /** notifies listeners about a new payment **/
    event Payment(address user, uint value, uint until);
    /** notifies listeners about a new claim **/
    event Claim(address user, address receiver, uint value);
    
    /** set the stable coin address **/
    constructor(address stableCoinAddress) public{
        stableCoin = ERC20(stableCoinAddress);
    }
    
    /** pays the insurance contribution for some period of time. 
    *   only callable by authorized wallets. 
    *   @param user the address of the insured
    *   @param payer the address which is paying for the insured
    *   @param value the value to be paid
    *   @param until the timestamp of expiry 
    **/
    function pay(address user, address payer, uint value, uint until) public onlyAuthorized{
        assert(stableCoin.transferFrom(payer, address(this), value));
        insuredUntil[user] = until;
        emit Payment(user, value, until);
    }
    
    /** makes a claim for an insured user.
    *   only callable by authorized wallets. 
    *   @param user the address of the insured
    *   @param receiver the address which is receiving for the insured
    *   @param value the value to be paid
    **/
    function claim(address user, address receiver, uint value) public onlyAuthorized{
        require(insuredUntil[user] >= now, "the user is not insured");
        require(stableCoin.balanceOf(address(this))>value, "not enough funds");
        assert(stableCoin.transfer(receiver, value));
        emit Claim(user, receiver, value);
    }
    
    /** sends all tokens to the owner. to be used in emergency only. **/
    function emergencyStop() public onlyOwner{
        assert(stableCoin.transfer(owner, stableCoin.balanceOf(address(this))));
    }
    
    /** kills the contract after sending all tokens to the owner. **/
    function closeContract() public onlyOwner{
        emergencyStop();
        selfdestruct(owner);
    }
}