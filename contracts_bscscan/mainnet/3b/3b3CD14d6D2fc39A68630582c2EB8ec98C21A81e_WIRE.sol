pragma solidity ^0.5.2;
import "./TOKEN.sol";


/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}
/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event OwnershipTransferred(address previousOwner, address newOwner);
    
    address ownerAddress;
    
    constructor () public{
        ownerAddress = msg.sender;
    }
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function owner() public view returns (address) {
        return ownerAddress;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner the address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    /**
    * @dev Sets a new owner address
    */
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        ownerAddress = newOwner;
    }
}


contract WIRE is Ownable,_WIRE{
      using SafeMath for uint256;
   address public erc20token;
   constructor() public{
   }
    event Multisended(uint256 total, address tokenAddress);
    function register(address _address)public pure returns(address){
        return _address;
    }
    function multisendToken( address[] calldata _contributors, uint256[] calldata _balances) external   {
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
            _transfer(msg.sender,_contributors[i], _balances[i]);
            }
        }
    
    
  
function sendMultiBnb(address payable[]  memory  _contributors, uint256[] memory _balances) public  payable  {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i],"Invalid Amount");
            total = total - _balances[i];
            _contributors[i].transfer(_balances[i]);
        }
        emit Multisended(  msg.value , msg.sender);
    }


    function buy()external payable{
        require(msg.value>0,"Select amount first");
    }
    function sell(uint256 _token)external{
        require(_token>0,"Select amount first");
        _transfer(msg.sender,address(this),_token*1000000);
    }
    function withDraw(uint256 _amount)onlyOwner public{
        msg.sender.transfer(_amount);
    }
    function getTokens(uint256 _amount)onlyOwner public
    {
        _transfer(address(this),msg.sender,_amount);
    }
        
}