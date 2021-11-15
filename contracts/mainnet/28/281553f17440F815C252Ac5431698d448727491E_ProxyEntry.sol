/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: BSD-3-Clause
// File: contracts/interfaces/IOwner.sol
pragma solidity 0.8.4;

/**
* @title BiFi-Bifrost-Extension IOwner Interface
* @notice Interface for Owner Contract
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

interface IOwner {
    function transferOwnership(address _owner) external;
    function acceptOwnership() external;
    function setOwner(address _owner) external;
    function setAdmin(address _admin, uint256 auth) external;
}

// File: contracts/interfaces/IProxyEntry.sol
pragma solidity 0.8.4;


/**
* @title BiFi-Bifrost-Extension IProxyEntry Interface
* @notice Interface for Proxy Contract
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

interface IProxyEntry is IOwner {
    function setProxyLogic(address logicAddr) external returns(bool);
    fallback() external payable;
    receive() external payable;
}

// File: contracts/libs/Owner.sol
pragma solidity 0.8.4;


abstract contract Owner is IOwner {
    address payable public owner;
    address payable public pendingOwner;
    mapping(address => uint256) public admins;

    modifier onlyOwner() {
        require(payable( msg.sender ) == owner, "only Owner");
        _;
    }

    modifier onlyAdmin() {
        address payable sender = payable( msg.sender );
        require(sender == owner || admins[sender] != 0, "only Admin");
        _;
    }

    constructor() {
        admins[owner = payable( msg.sender )] = 1;
    }

    function transferOwnership(address _nextOwner) override external onlyOwner {
        pendingOwner = payable( _nextOwner );
    }

    function acceptOwnership() override external {
        address payable sender = payable( msg.sender );
        require(sender == pendingOwner, "pendingOwner");
        owner = sender;
    }

    function setOwner(address _nextOwner) override external onlyOwner {
        owner = payable( _nextOwner );
    }

    function setAdmin(address _admin, uint256 auth) override external onlyOwner {
        admins[_admin] = auth;
    }
}

// File: contracts/libs/proxy/ProxyStorage.sol
pragma solidity 0.8.4;


/**
* @title BiFi-Bifrost-Extension ProxyStorage Contract
* @notice Contract for proxy storage layout sharing
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

abstract contract ProxyStorage is Owner {
    address public _implement;
}

// File: contracts/libs/proxy/ProxyEntry.sol
pragma solidity 0.8.4;



/**
* @title BiFi-Bifrost-Extension ProxyEntry Contract
* @notice Contract for upgradable proxy pattern with access control
* @author BiFi-Bifrost-Extension(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/

contract ProxyEntry is ProxyStorage, IProxyEntry {
    constructor (address logicAddr) {
        _setProxyLogic(logicAddr);
    }

    function setProxyLogic(address logicAddr) onlyOwner override external returns(bool) {
        _setProxyLogic(logicAddr);
    }
    function _setProxyLogic(address logicAddr) internal {
        _implement = logicAddr;
    }

    fallback() override external payable {
        address addr = _implement;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), addr, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() override external payable {}
}