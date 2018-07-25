pragma solidity ^0.4.24;

contract ERC20 {
    uint256 public totalSupply;
    uint public decimals;
    function balanceOf(address _address) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
// 0x06ef8a84274346bfbc7f01c22071fb77b78a5098
contract NetkillerBatchTransfer {

    // address public contractAddress;
    ERC20 public token;
    
    constructor(address _contractAddress) public {
        // contractAddress = _contractAddress;
        token = ERC20(_contractAddress);
    }
    function getBalance(address _address) view public returns (uint256){
        return token.balanceOf(_address);
    }
    function transferBatch(address[] _to, uint256 _value) public returns (bool success) {
        for (uint i=0; i<_to.length; i++) {
            token.transfer(_to[i], _value);
        }
        return true;
    }
    function batchTransfer(address[] _to, uint256[] _value) public{
        require(_to.length == _value.length);

        uint256 amount = 0;
        for(uint n=0;n<_value.length;n++){
            amount += _value[n];
        }
        
        require(amount > 0 && token.balanceOf(this) >= amount);
        
        for (uint i=0; i<_to.length; i++) {
            token.transfer(_to[i], _value[i]);
        }
    }
}