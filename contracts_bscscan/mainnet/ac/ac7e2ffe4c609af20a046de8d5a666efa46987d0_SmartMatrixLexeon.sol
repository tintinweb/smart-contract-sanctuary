/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

pragma solidity >=0.4.23 <0.6.0;

contract Ownable
{

  /**
   * @dev Error constants.
   */

  /**
   * @dev Current owner address.
   */
  address public contractOwner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Throws if called by any account other than the contractOwner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == contractOwner, "NOT_CURRENT_OWNER");
    _;
  }

  /**
   * @dev Allows the current contractOwner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), "CANNOT_TRANSFER_TO_ZERO_ADDRESS");
    emit OwnershipTransferred(contractOwner, _newOwner);
    contractOwner = _newOwner;
  }

}

contract SmartMatrixLexeon is Ownable{
    
    
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, uint8 matrix,string matrixName, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint256 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress) public {     
        contractOwner = ownerAddress;
        userIds[1] = ownerAddress;
    }
    
    function() external payable {
        
    }

    function buyNewSlot(uint8 matrix, string calldata matrixName, uint8 level) external payable {
        emit Upgrade(msg.sender,matrix,matrixName,level);
    }
    
    function distribution(address[] calldata referrerAddress,uint[] calldata amount) external payable {
            for(uint i=0;i<referrerAddress.length;i++){
                sendETHDividends(referrerAddress[i],amount[i]);
            }
    }
    

    function sendETHDividends(address receiver,uint amount ) private {
            if (!address(uint160(receiver)).send(amount)) {
                return address(uint160(receiver)).transfer(address(this).balance);
            }
    }
    
   function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    function deposit() external payable returns(uint) {
        return address(this).balance;
    }
    
    function withdraw() public {
        require(msg.sender == contractOwner, "Can't send without owner");
        msg.sender.transfer(address(this).balance);
    }
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

}