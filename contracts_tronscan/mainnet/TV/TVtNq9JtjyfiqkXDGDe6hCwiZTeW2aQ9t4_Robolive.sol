//SourceUnit: robolive.sol

pragma solidity ^0.5.9;
contract Robolive {
    
    address public owner;
    
    event Registration(address indexed user, uint amount, address ref);
    event ownershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor (address ownerAddress) public {
         owner = ownerAddress;//msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }
    //
    function registrationExt(address _receiver) external payable returns(string memory){
        //
       // uint256 amount = msg.value;
        //
        if(!(msg.sender==owner)) require(msg.value>0, "Invalid Deposit amount");  
        //        registration(msg.sender, msg.value);
        //
        emit Registration(msg.sender, msg.value,_receiver);
        //
        address(uint160(owner)).transfer(msg.value);
        //
        return "TRX Deposit Done successfully";
    }
 
  function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
 function withdrawFees(uint256 _amount, address _receiver) public onlyOwner {
                    address(uint160(_receiver)).transfer(_amount);
                    //address(uint160(receiver)).transfer(address(this).balance);
    }
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit ownershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}