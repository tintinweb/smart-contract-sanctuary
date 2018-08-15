pragma solidity ^0.4.21;

contract IGEX {
    address public adminAddress;
    address public owner;
    function transfer(address _to, uint256 _value) public returns (bool);
    function allocateReservedTokens(address _addr, uint _amount) external;
}

contract GexAlloc {
    IGEX public gex;
    address public gexAdmin;
    address public gexOwner;

    modifier onlyGexAdminOrOwner() {
        require(msg.sender == gexAdmin || msg.sender == gexOwner);
        _;
    }
    
    function GexAlloc (address _contractAddress) public {
        gex = IGEX(_contractAddress);
        gexAdmin = gex.adminAddress();
        gexOwner = gex.owner();
    }
    
    function batchTokenTransfer(address[] _to, uint256[] _amount) external onlyGexAdminOrOwner {
        uint count = _to.length;
        
        for (uint i = 0; i < count; i++) {
            require(gex.transfer(_to[i], _amount[i]));
        }
        
    }
    
    function tokenTransfer(address _to, uint256 _amount) external onlyGexAdminOrOwner {
        require(gex.transfer(_to, _amount));
    }
}