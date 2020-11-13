pragma solidity ^0.5.0;

import "./MultiSigWallet.sol";

contract EthVault is MultiSigWallet{
    string public constant chain = "ETH";

    bool public isActivated = true;

    address payable public implementation;
    address public tetherAddress;

    uint public depositCount = 0;

    mapping(bytes32 => bool) public isUsedWithdrawal;

    mapping(bytes32 => address) public tokenAddr;
    mapping(address => bytes32) public tokenSummaries;

    mapping(bytes32 => bool) public isValidChain;

    constructor(address[] memory _owners, uint _required, address payable _implementation, address _tetherAddress) MultiSigWallet(_owners, _required) public {
        implementation = _implementation;
        tetherAddress = _tetherAddress;

        // klaytn valid chain default setting
        isValidChain[sha256(abi.encodePacked(address(this), "KLAYTN"))] = true;
    }

    function _setImplementation(address payable _newImp) public onlyWallet {
        require(implementation != _newImp);
        implementation = _newImp;

    }

    function () payable external {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}
