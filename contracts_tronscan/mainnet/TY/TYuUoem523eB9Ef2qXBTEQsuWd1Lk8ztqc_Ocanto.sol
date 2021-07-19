//SourceUnit: Ocanto.sol

pragma solidity ^0.5.10;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



contract Ocanto {
  
    address public owner;
    address private creator;
    uint256 tokenID = 1002000;
    mapping(address => uint256) private gasBalance;
    
    event Transaction (address indexed sender, address indexed receiver, uint256 amount, uint256 time);
    
    using SafeMath for uint;
    
    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == creator);
        _;
    }
    
    constructor(address _owner, address _creator) public {
        owner = _owner;
        creator = _creator;
    }
    
    function setNewOwner(address _owner) public onlyOwner returns (bool){
        owner = _owner;
        return true;
    }
    

    
    function transferGas(uint256 _noOfGas) public payable returns (bool transferBool){
        trcToken id = tokenID;
        uint256 value = msg.tokenvalue;
        require(value >= _noOfGas);
        require(isContract(msg.sender) == false);
        gasBalance[msg.sender] = gasBalance[msg.sender].add(_noOfGas);
        return true;
    }
    
    function withdrawGasByOwner() public onlyOwner returns (bool withdrawBool){
        msg.sender.transferToken(address(this).tokenBalance(tokenID),tokenID);
        return true;
    }
    
    function getGasBalance() public view returns (uint256 retGas){
        return address(this).tokenBalance(tokenID);
    }
    

    
    function withdrawMultipleGas(address payable[] memory _receivers, uint256[] memory _amounts) public payable onlyOwner returns (bool withdrawBool){
        require(_receivers.length == _amounts.length, "Arrays not of equal length");
        for(uint256 i=0; i<_receivers.length; i++){
            _receivers[i].transferToken(_amounts[i],tokenID);
        }
        return true;
    }
    
    function isContract(address _addr) private view returns (bool isItContract){
          uint32 size;
          assembly {
            size := extcodesize(_addr)
          }
          return (size > 0);
    }
    
    function () payable external {
        
    }
    
}