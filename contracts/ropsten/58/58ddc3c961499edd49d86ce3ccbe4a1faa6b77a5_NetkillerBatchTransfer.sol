pragma solidity ^0.4.24;

interface ERC20 {
    function balanceOf(address _address) constant external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract NetkillerBatchTransfer {

    ERC20 public token;
    
    constructor(address _contractAddress) public {
        token = ERC20(_contractAddress);
    }
    function getBalance(address _address) view public returns (uint256){
        return token.balanceOf(_address);
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        return token.transfer(_to, _value);
    }
    function transferBatch(address[] _to, uint256 _value) public returns (bool success) {
        for (uint i=0; i<_to.length; i++) {
            token.transfer(_to[i], _value);
        }
        return true;
    }
    function batchTransfer(address[] _to, uint256[] _value) public returns (bool success) {
        require(_to.length == _value.length);

        uint256 amount = 0;
        for(uint n=0;n<_value.length;n++){
            amount += _value[n];
        }
        
        require(amount > 0 && token.balanceOf(this) >= amount);
        
        for (uint i=0; i<_to.length; i++) {
            token.transfer(_to[i], _value[i]);
        }
        return true;
    }
}