pragma solidity ^0.5.1;


contract Dispatcher {
    address target;
    address[] admins;
    
    event LogDelegate(address sender, bytes data);
    event LogFoo(address sender, bytes data);


    constructor(address _target, address[] memory _admins) public {
        target = _target;
        admins = _admins;
    }
    
    modifier onlyAdmin() {
        require(checkAdmin());
        _;
    }

    function checkAdmin() internal view returns (bool) {
        address admin = address(msg.sender);
        
        for (uint i = 0; i < admins.length; i++) {
            if (admin == admins[i]) {
                return true;
            }
        }
        
        return false;
    }
    
    function upgrade(address _target) public onlyAdmin {
        target = _target;
    }
    
    function foo() public payable returns (address) {
        emit LogFoo(msg.sender, msg.data);
        return target;
    }
    
    function implementation() public view returns (address) {
        return target;
    }

    function() external payable {
        address _impl = implementation();
        require(_impl != address(0));
        
        emit LogDelegate(msg.sender, msg.data);

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            case 1 { return(ptr, size) }
        }
    }
}