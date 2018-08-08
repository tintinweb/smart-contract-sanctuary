pragma solidity 0.4.21;

contract CrowdsaleProxyTarget {
    function isActive() public returns(bool);
    function initialize(address _owner, address _token, address _familyOwner, address _personalOwner) public;
    address public token;
}

/**
 * The CrowdsaleProxy contract which uses crowdsale implementation deployed at
 * target address. This constuction helps to make Crowdsale code upgradable.
 */
contract CrowdsaleProxy {
    bytes32 constant TARGET_POSITION = keccak256("CrowdsaleProxy.target");
    bytes32 constant OWNER_POSITION = keccak256("CrowdsaleProxy.owner");

    event Upgraded(address indexed target);

    modifier _onlyProxyOwner() {
        require(msg.sender == ___proxyOwner());
        _;
    }

    function CrowdsaleProxy(address _target) public {
        require(_target != 0x0);
        bytes32 position = OWNER_POSITION;
        assembly { sstore(position, caller) }
        ___setTarget(_target);
    }

    function ___initialize(address _token, address _familyOwner, address _personalOwner) public {
        CrowdsaleProxyTarget(this).initialize(msg.sender, _token, _familyOwner, _personalOwner);
    }

    function () public payable {
        address _target = ___proxyTarget();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let success := delegatecall(sub(gas, 10000), _target, ptr, calldatasize, 0, 0)
            let retSz := returndatasize
            returndatacopy(ptr, 0, retSz)

            switch success
            case 0 { revert(ptr, retSz) }
            default { return(ptr, retSz) }
        }
    }

    function ___coinAddress() external view returns (address) {
        return CrowdsaleProxyTarget(this).token();
    }

    function ___isActive() internal returns (bool res) {
        res = CrowdsaleProxyTarget(this).isActive();
    }

    function ___proxyOwner() public view returns (address owner) {
        bytes32 position = OWNER_POSITION;
        assembly {
            owner := sload(position)
        }
    }

    function ___setProxyOwner(address newOwner) _onlyProxyOwner public {
        bytes32 position = OWNER_POSITION;
        assembly {
            sstore(position, newOwner)
        }
    }

    function ___proxyTarget() public view returns (address target) {
        bytes32 position = TARGET_POSITION;
        assembly {
            target := sload(position)
        }
    }

    function ___setTarget(address target) internal {
        bytes32 position = TARGET_POSITION;
        assembly {
            sstore(position, target)
        }
    }

    function ___upgradeTo(address newTarget) public _onlyProxyOwner {
        require(!___isActive());
        require(___proxyTarget() != newTarget);
        ___setTarget(newTarget);
        emit Upgraded(___proxyTarget());
    }

    function ___upgradeToAndCall(address newTarget, bytes data) payable public _onlyProxyOwner {
        ___upgradeTo(newTarget);
        require(address(this).call.value(msg.value)(data));
    }
}