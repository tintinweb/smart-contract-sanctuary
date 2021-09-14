/**
 *Submitted for verification at polygonscan.com on 2021-09-14
*/

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Web#BRidge.sol


pragma solidity ^0.8.1;


//if you are hacking with a contract, make sure it inherits from Ownable.sol and it implements this function

///PLEASE IMPLEMENT THIS IN ANY CONTRACT YOU ARE DEPLOYING
//   function transferOut() public onlyOwner{
// payable(owner()).transfer(address(this).balance);
//   }


contract LEVELS_WEB3BRIDGE_2 is Ownable{
  mapping(address => uint) public balances;
  mapping(address=>bool) public level1;
  mapping(address=>bool) public level2;
  mapping(address=>uint) public trustCount;
  address public locksmith;
bytes32 private _hash=0xdbb8d0f4c497851a5043c6363657698cb1387682cac2f786c731f8936109d795;

constructor() payable{
locksmith=msg.sender;
}

uint256 level1Prize= 140000000000000000000;
uint256 bonusPrize= 110000000000000000000;
bool taken;
bool bonusClaimed;
modifier hasDonated(){
    require(balances[msg.sender]>0);
    _;
}

modifier hasSolvedAll(){
    require(level1[msg.sender],"Solve Level 1 first");
     require(level2[msg.sender],"Solve Level 2 first");
      _;
      }
      
    modifier hasSolved1(){
    require(level1[msg.sender]);
    _;
    }

  function donateInto(address _to) public payable {
    balances[_to] = balances[_to]+=(msg.value);
  }
  
  function checkTrust() public view returns(uint trust){
  trust=trustCount[msg.sender];
  }

  function donations(address _who) public view returns (uint balance) {
    return balances[_who];
  }
  
  //GoodLuck reversing a cryptographic hash
  //can be solved with an EOA
function solveOne(uint8 answer) public returns(bool){
    require(keccak256(abi.encodePacked(answer))==_hash,"Sorry Better luck");
    level1[msg.sender]=true;
    if(!taken){
    payable(msg.sender).transfer(level1Prize);
    taken=true;
    }
    return true;
}

function transferLevel(address _benefactor) public{
    if(level1[msg.sender]){
        level1[_benefactor]=true;
        level1[msg.sender]=false;
    }
      if(level2[msg.sender]){
        level2[_benefactor]=true;
        level2[msg.sender]=false;
    }
}



  function solveTwo() public hasSolved1 hasDonated {
  require(bonusClaimed,"Oops!");
   if(trustCount[msg.sender]!=0){
       revert("you need a fresh account");
   }
      (bool result,) = msg.sender.call("");
      if(result) {
        trustCount[msg.sender]++;
        if(trustCount[msg.sender]==uint8(uint256(keccak256("solved")))%11){
        level2[msg.sender]=true;
        }
      }
  }

  function claimReward() public hasSolvedAll{
      payable(msg.sender).transfer(address(this).balance);
  }
  
  function transferOut() public onlyOwner{
payable(owner()).transfer(address(this).balance);
  }

  receive() external payable {}
  
  function changeTheLocksmith(address _newLockSmith) public {
if(tx.origin!=msg.sender){
locksmith=_newLockSmith;
}
}

function transferLockRights(address _newlockGuy) public{
require(msg.sender==locksmith,"nope");
locksmith= _newlockGuy;
}

function getBonus() public{
require(msg.sender==locksmith,"nope");
if(!bonusClaimed){
payable(locksmith).transfer(bonusPrize);
bonusClaimed=true;
}
}



}



//make use of it if you want

interface IW3C{
function claimReward() external;
function transferLevel(address _benefactor)external;
function transferLockRights(address _newlockGuy) external;

}