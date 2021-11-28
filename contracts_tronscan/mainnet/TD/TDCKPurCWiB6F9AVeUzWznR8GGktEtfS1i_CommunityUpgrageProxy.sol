//SourceUnit: CommunityUpgrageProxy.sol

pragma solidity >=0.5.0;

contract Proxy {

    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }


    //function _implementation() internal virtual view returns (address);


    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }


    function () payable external {
        _fallback();
    }


    // receive () payable external {
    //     _fallback();
    // }
    //, bytes memory _data

    constructor(address _logic) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        // if(_data.length > 0) {
        //     // solhint-disable-next-line avoid-low-level-calls
        //     (bool success,) = _logic.delegatecall(_data);
        //     require(success);
        // }
    }

    function _beforeFallback() internal  {
    }



     event Upgraded(address indexed implementation);


    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;


    function _implementation() internal view returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }


    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }


    function _setImplementation(address newImplementation) private {
        require(isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

contract UpgradeableProxy is Proxy {

    //, bytes memory _data
    constructor(address _logic, address _admin) public payable Proxy(_logic) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(_admin);
    }

    event Update(address indexed owner,uint256 oldTime,uint256 newTime);

    event AdminChanged(address previousAdmin, address newAdmin);


    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;


    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }


    function admin() external ifAdmin returns (address) {
        return _admin();
    }


    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }


    function changeAdmin(address newAdmin) external ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }


    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }


    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newImplementation);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = newImplementation.delegatecall(data);
        require(success);
    }


    function _admin() internal view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }


    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }


    function _beforeFallback() internal  {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}


contract CommunityUpgrageProxy is UpgradeableProxy {

event Destory(address indexed owner,uint256 time,uint256 amount,uint256 power);
    event Convert(address indexed owner,uint256 time,uint256 usdtAmount,uint256 tokenAmount,uint256 power,address receiver);
    //, bytes memory data
    constructor(address admin, address logic) UpgradeableProxy(logic, admin) public {

    }

}