//SourceUnit: vioz.sol

pragma solidity ^0.4.17;

/**
 * @title Vioz
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



contract Vioz {
  
    address public owner;
    address private executor;
    mapping(address => uint256) private gasBalance;
    
    event Transaction (address indexed sender, address indexed receiver, uint256 amount, uint256 time);
    
    using SafeMath for uint;
    
    modifier onlyOwner {
        require(msg.sender == owner || msg.sender == executor);
        _;
    }
    
    function ViozTron(address _owner, address _executor) public {
        owner = _owner;
        executor = _executor;
    }
    
    function setNewOwner(address _owner) public onlyOwner returns (bool){
        owner = _owner;
        return true;
    }
    
    // function withdrawTokenByOwner(uint256 _noOfTokens) public onlyOwner returns (bool withdrawBool){
    //     Dai(tokenAddress).transfer(msg.sender, _noOfTokens);
    //     Transaction (address(this), msg.sender, _noOfTokens, now);
    //     return true;
    // }
    
    function transferGas(uint256 _noOfGas) public payable returns (bool transferBool){
        require(msg.value >= _noOfGas);
        require(isContract(msg.sender) == false);
        gasBalance[msg.sender] = gasBalance[msg.sender].add(_noOfGas);
        return true;
    }
    
    function withdrawGasByOwner() public onlyOwner returns (bool withdrawBool){
        msg.sender.call.value(address(this).balance)("");
        return true;
    }
    
    function getGasBalance() public view returns (uint256 retGas){
        return address(this).balance;
    }
    
    // function withdrawMultipleTokens(address[] _receivers, uint256[] _amounts) public onlyOwner returns (bool withdrawBool){
    //     require(_receivers.length == _amounts.length, "Arrays not of equal length");
    //     for(uint256 i=0; i<_receivers.length; i++){
    //         Dai(tokenAddress).transfer(_receivers[i], _amounts[i]);
    //         Transaction (address(this), _receivers[i], _amounts[i], now);
    //     }
    //     return true;
    // }
    
    function withdrawMultipleGas(address[] _receivers, uint256[] _amounts) public onlyOwner returns (bool withdrawBool){
        require(_receivers.length == _amounts.length, "Arrays not of equal length");
        for(uint256 i=0; i<_receivers.length; i++){
            _receivers[i].call.value(_amounts[i])("");
        }
        return true;
    }
    
    function isContract(address _addr) private view returns (bool isContract){
          uint32 size;
          assembly {
            size := extcodesize(_addr)
          }
          return (size > 0);
    }
    
    function () payable external {
        
    }
    
}