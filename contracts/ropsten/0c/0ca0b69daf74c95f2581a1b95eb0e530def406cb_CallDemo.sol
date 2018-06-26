pragma solidity ^0.4.13;

contract Ownable{
    address public owner;
    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) onlyOwner public returns (bool _success) {
        require(_newOwner != address(0));
        owner = _newOwner;
        return true;
    }
}

contract CallDemo is Ownable{
    function demo1(address _addr,uint _value, bytes _data, string _custom_fallback)public returns(uint){
        if(isContract(_addr)){
            assert(_addr.call.value(0)(bytes4(keccak256(_custom_fallback)),msg.sender, _value, _data));
            return 200;
        }else{
            return 100;
        }
    } 
    
    function isContract(address _target) public view returns (bool _is_contract) {
        uint length;
        assembly {
            length := extcodesize(_target)
        }
        return (length > 0);
    }

}