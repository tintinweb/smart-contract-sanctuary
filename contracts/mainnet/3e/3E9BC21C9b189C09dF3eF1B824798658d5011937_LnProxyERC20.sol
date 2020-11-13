// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IERC20 {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

contract LnAdmin {
    address public admin;
    address public candidate;

    constructor(address _admin) public {
        require(_admin != address(0), "admin address cannot be 0");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    function setCandidate(address _candidate) external onlyAdmin {
        address old = candidate;
        candidate = _candidate;
        emit candidateChanged( old, candidate);
    }

    function becomeAdmin( ) external {
        require( msg.sender == candidate, "Only candidate can become admin");
        address old = admin;
        admin = candidate;
        emit AdminChanged( old, admin ); 
    }

    modifier onlyAdmin {
        require( (msg.sender == admin), "Only the contract admin can perform this action");
        _;
    }

    event candidateChanged(address oldCandidate, address newCandidate );
    event AdminChanged(address oldAdmin, address newAdmin);
}

contract LnProxyBase is LnAdmin {
    LnProxyImpl public target;

    constructor(address _admin) public LnAdmin(_admin) {}

    function setTarget(LnProxyImpl _target) external onlyAdmin {
        target = _target;
        emit TargetUpdated(_target);
    }

    function Log0( bytes calldata callData ) external onlyTarget {
        uint size = callData.length;
        bytes memory _callData = callData;
        assembly {
            log0(add(_callData, 32), size)
        }
    }

    function Log1( bytes calldata callData, bytes32 topic1 ) external onlyTarget {
        uint size = callData.length;
        bytes memory _callData = callData;
        assembly {
            log1(add(_callData, 32), size, topic1 )
        }
    }

    function Log2( bytes calldata callData, bytes32 topic1, bytes32 topic2 ) external onlyTarget {
        uint size = callData.length;
        bytes memory _callData = callData;
        assembly {
            log2(add(_callData, 32), size, topic1, topic2 )
        }
    }

    function Log3( bytes calldata callData, bytes32 topic1, bytes32 topic2, bytes32 topic3 ) external onlyTarget {
        uint size = callData.length;
        bytes memory _callData = callData;
        assembly {
            log3(add(_callData, 32), size, topic1, topic2, topic3 )
        }
    }

    function Log4( bytes calldata callData, bytes32 topic1, bytes32 topic2, bytes32 topic3, bytes32 topic4 ) external onlyTarget {
        uint size = callData.length;
        bytes memory _callData = callData;
        assembly {
            log4(add(_callData, 32), size, topic1, topic2, topic3, topic4 )
        }
    }

    //receive: It is executed on a call to the contract with empty calldata. This is the function that is executed on plain Ether transfers (e.g. via .send() or .transfer()).
    //fallback: can only rely on 2300 gas being available,
    receive() external payable {
        target.setMessageSender(msg.sender);

        assembly {
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize())

            let result := call(gas(), sload(target_slot), callvalue(), free_ptr, calldatasize(), 0, 0)
            returndatacopy(free_ptr, 0, returndatasize())

            if iszero(result) {
                revert(free_ptr, returndatasize())
            }
            return(free_ptr, returndatasize())
        }
    }

    modifier onlyTarget {
        require(LnProxyImpl(msg.sender) == target, "Must be proxy target");
        _;
    }

    event TargetUpdated(LnProxyImpl newTarget);
}


abstract contract LnProxyImpl is LnAdmin {
    
    LnProxyBase public proxy;
    LnProxyBase public integrationProxy;

    address public messageSender;

    constructor(address payable _proxy) internal {
        
        require(admin != address(0), "Admin must be set");

        proxy = LnProxyBase(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setProxy(address payable _proxy) external onlyAdmin {
        proxy = LnProxyBase(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setIntegrationProxy(address payable _integrationProxy) external onlyAdmin {
        integrationProxy = LnProxyBase(_integrationProxy);
    }

    function setMessageSender(address sender) external onlyProxy {
        messageSender = sender;
    }

    modifier onlyProxy {
        require(LnProxyBase(msg.sender) == proxy || LnProxyBase(msg.sender) == integrationProxy, "Only the proxy can call");
        _;
    }

    modifier optionalProxy {
        if (LnProxyBase(msg.sender) != proxy && LnProxyBase(msg.sender) != integrationProxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
        _;
    }

    modifier optionalProxy_onlyAdmin {
        if (LnProxyBase(msg.sender) != proxy && LnProxyBase(msg.sender) != integrationProxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
        require(messageSender == admin, "only for admin");
        _;
    }

    event ProxyUpdated(address proxyAddress);
}

contract LnProxyERC20 is LnProxyBase, IERC20 {
    constructor(address _admin) public LnProxyBase(_admin) {}

    function name() public view override returns (string memory) {
        
        return IERC20(address(target)).name();
    }

    function symbol() public view override returns (string memory) {
        
        return IERC20(address(target)).symbol();
    }

    function decimals() public view override returns (uint8) {
        
        return IERC20(address(target)).decimals();
    }

    function totalSupply() public view override returns (uint256) {
        
        return IERC20(address(target)).totalSupply();
    }

    function balanceOf(address account) public view override returns (uint256) {
        
        return IERC20(address(target)).balanceOf(account);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        
        return IERC20(address(target)).allowance(owner, spender);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        
        target.setMessageSender(msg.sender);

        IERC20(address(target)).transfer(to, value);

        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        
        target.setMessageSender(msg.sender);

        IERC20(address(target)).approve(spender, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        
        target.setMessageSender(msg.sender);

        IERC20(address(target)).transferFrom(from, to, value);

        return true;
    }
}