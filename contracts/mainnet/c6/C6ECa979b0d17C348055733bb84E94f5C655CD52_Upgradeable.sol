/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-18
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-11
*/

pragma solidity >=0.6.0;


contract Upgradeable {
    event Upgrade(
        address indexed sender,
        address indexed from,
        address indexed to
    );

    //https://eips.ethereum.org/EIPS/eip-1967
    //bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32
        internal constant IMPLEMENTATION_STORAGE_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32
        internal constant AUTHENTICATION_STORAGE_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor(address _authentication, address _implementation) public {
        require(_authentication != address(0), "Upgradeable.constructor.EID00090");
        require(_implementation != address(0), "Upgradeable.constructor.EID00090");
        _setauthentication(_authentication);
        _setimplementation(_implementation);
    }

    modifier auth() {
        require(msg.sender == authentication(), "Upgradeable.auth.EID00001");
        _;
    }

    function authentication() public view returns (address _authentication) {
        bytes32 slot = AUTHENTICATION_STORAGE_SLOT;
        assembly {
            _authentication := sload(slot)
        }
    }

    function implementation() public view returns (address _implementation) {
        bytes32 slot = IMPLEMENTATION_STORAGE_SLOT;
        assembly {
            _implementation := sload(slot)
        }
    }

    function upgrade(address _implementation)
        public
        auth
        returns (address)
    {
        require(_implementation != address(0), "Upgradeable.upgrade.EID00090");
        address from = _setimplementation(_implementation);
        emit Upgrade(msg.sender, from, _implementation);
        return from;
    }

    fallback() external payable {
        address _implementation = implementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                _implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    function _setimplementation(address _implementation)
        internal
        returns (address)
    {
        address from = implementation();
        bytes32 slot = IMPLEMENTATION_STORAGE_SLOT;
        assembly {
            sstore(slot, _implementation)
        }
        return from;
    }

    function _setauthentication(address _authentication)
        internal
        returns (address)
    {
        address from = authentication();
        bytes32 slot = AUTHENTICATION_STORAGE_SLOT;
        assembly {
            sstore(slot, _authentication)
        }
        return from;
    }
}