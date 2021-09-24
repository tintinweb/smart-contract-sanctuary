/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

pragma solidity ^0.6.0;

// *** IMPORTANT ***
// "onwer" storage variable must be set to a GnosisSafe multisig wallet address:
// - https://github.com/gnosis/safe-contracts/blob/main/contracts/GnosisSafe.sol

contract Proxy {

    // ATTENTION: storage variable alignment
    address private owner;
    address private pendingOwner;
    address private implementation;
    uint private locked; // 1 = Initialized; 2 = Non upgradable
    // --------------------------------------------------------

    event OwnershipTransferRequested(address indexed from, address indexed to);
    
    event OwnershipTransferred(address indexed from, address indexed to);

    event SetNonUpgradable();

    event ImplementationUpdated(address indexed from, address indexed to);

    constructor(address _owner, address _implementation) public {

        owner = _owner;
        implementation = _implementation;
    }

    fallback () payable external {
        
        _fallback();
    }

    receive () payable external {

        _fallback();
    }
    
    function transferOwnership(address _to) external {
        
        require(msg.sender == owner);
        pendingOwner = _to;
        emit OwnershipTransferRequested(owner, _to);
    }

    function acceptOwnership() external {
    
        require(msg.sender == pendingOwner);
        address oldOwner = owner;
        owner = msg.sender;
        pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    function setNonUpgradable() public {

        require(msg.sender == owner && locked == 1);
        locked = 2;
        emit SetNonUpgradable();
    }

    function setImplementation(address _implementation) public {

        require(msg.sender == owner && locked != 2);
        address oldImplementation = implementation;
        implementation = _implementation;
        emit ImplementationUpdated(oldImplementation, implementation);
    }

    function delegate(address _implementation) internal {
        assembly {

            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result

            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _fallback() internal {
        willFallback();
        delegate(implementation);
    }

    function willFallback() internal virtual {
        
    }
}