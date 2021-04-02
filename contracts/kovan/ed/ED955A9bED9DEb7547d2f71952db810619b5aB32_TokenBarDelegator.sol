/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// File: contracts/interface/TokenBarInterfaces.sol

pragma solidity 0.6.12;

contract TokenBarAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;
    /**
     * @notice Governance for this contract which has the right to adjust the parameters of TokenBar
     */
    address public governance;

    /**
     * @notice Active brains of TokenBar
     */
    address public implementation;
}

contract xSHDStorage {
    string public name = "ShardingBar";
    string public symbol = "xSHD";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
}

contract ITokenBarStorge is TokenBarAdminStorage {
    //lock period :60*60*24*7
    uint256 public lockPeriod = 604800;
    address public SHDToken;
    mapping(address => mapping(address => address)) public routerMap;
    address public marketRegulator;
    address public weth;
    mapping(address => uint256) public lockDeadline;
}

// File: contracts/TokenBarDelegator.sol

pragma solidity 0.6.12;


contract TokenBarDelegator is ITokenBarStorge, xSHDStorage {
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewGovernance(address oldGovernance, address newGovernance);

    constructor(
        address _governance,
        address _SHDToken,
        address _marketRegulator,
        address _weth,
        address implementation_
    ) public {
        admin = msg.sender;
        governance = _governance;
        _setImplementation(implementation_);
        delegateTo(
            implementation_,
            abi.encodeWithSignature(
                "initialize(address,address,address)",
                _SHDToken,
                _marketRegulator,
                _weth
            )
        );
    }

    function _setImplementation(address implementation_) public {
        require(
            msg.sender == governance,
            "_setImplementation: Caller must be governance"
        );

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation);
    }

    function _setAdmin(address newAdmin) public {
        require(msg.sender == admin, "UNAUTHORIZED");

        address oldAdmin = admin;

        admin = newAdmin;

        emit NewAdmin(oldAdmin, newAdmin);
    }

    function _setGovernance(address newGovernance) public {
        require(msg.sender == governance, "UNAUTHORIZED");

        address oldGovernance = governance;

        governance = newGovernance;

        emit NewGovernance(oldGovernance, newGovernance);
    }

    function delegateTo(address callee, bytes memory data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    receive() external payable {}

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
    //  */
    fallback() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);
        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())
            switch success
                case 0 {
                    revert(free_mem_ptr, returndatasize())
                }
                default {
                    return(free_mem_ptr, returndatasize())
                }
        }
    }
}