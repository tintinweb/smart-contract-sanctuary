pragma solidity ^0.4.21;

contract GreenX {
    address public adminAddress;
    address public owner;
    function transfer(address _to, uint256 _value) public returns (bool);
    function allocateReservedTokens(address _addr, uint _amount) external;
}

contract GEXAirDrop {
    GreenX public greenx;
    address public greenxAdmin;
    address public owner;
    
    modifier onlyAdmin {
        //only the greenx admin can execute
        require(greenxAdmin == msg.sender);
        _;
    }
    
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || msg.sender == greenxAdmin);
        _;
    }
    
    //constructor - take GEX contract address as param
    function GEXAirDrop (address _contract) public {
        //get the current GreenX contract instance by passing address
        greenx = GreenX(_contract);
        //get the owner, admin address
        owner = greenx.owner();
        greenxAdmin = greenx.adminAddress();
    }
    
    function batchReservedTokenAllocation(address[] _toAddress, uint256[] _tokenAmount) public onlyOwnerOrAdmin {
        // allocateReservedTokens
        uint count = _toAddress.length;
        
        for(uint i = 0; i < count; i++){
            greenx.allocateReservedTokens(_toAddress[i], _tokenAmount[i]);
        }
    }
    
    function batchAirDrop(address[] _to, uint256[] _amount) public /*onlyAdmin*/ {
        uint count = _to.length;
        
        for(uint i = 0; i < count; i++){
            require(greenx.transfer(_to[i], _amount[i]));
        }
        
    }
    
    function airDrop(address _to, uint256 _amount) public {
        require(greenx.transfer(_to, _amount));
    }
}