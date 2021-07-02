/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity >=0.4.23 <0.6.0;

contract SmartMatrixLexeon {
    
    
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, uint8 matrix,string matrixName, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint256 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
    
    
    constructor(address ownerAddress) public {     
        owner = ownerAddress;
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
        require(msg.sender == owner, "Can't send without owner");
        msg.sender.transfer(address(this).balance);
    }
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

}