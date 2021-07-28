/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

// File: contracts/lib/InitializableOwnable.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "DODO_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/Factory/Registries/DODOMineV3Registry.sol



interface IDODOMineV3Registry {
    function addMineV3(
        address mine,
        bool isLpToken,
        address stakeToken
    ) external;
}

/**
 * @title DODOMineV3 Registry
 * @author DODO Breeder
 *
 * @notice Register DODOMineV3 Pools 
 */
contract DODOMineV3Registry is InitializableOwnable, IDODOMineV3Registry {

    mapping (address => bool) public isAdminListed;
    
    // ============ Registry ============
    // minePool -> stakeToken
    mapping(address => address) public _MINE_REGISTRY_;
    // lpToken -> minePool
    mapping(address => address[]) public _LP_REGISTRY_;
    // singleToken -> minePool
    mapping(address => address[]) public _SINGLE_REGISTRY_;


    // ============ Events ============
    event NewMineV3(address mine, address stakeToken, bool isLpToken);
    event RemoveMineV3(address mine, address stakeToken);
    event addAdmin(address admin);
    event removeAdmin(address admin);


    function addMineV3(
        address mine,
        bool isLpToken,
        address stakeToken
    ) override external {
        require(isAdminListed[msg.sender], "ACCESS_DENIED");
        _MINE_REGISTRY_[mine] = stakeToken;
        if(isLpToken) {
            _LP_REGISTRY_[stakeToken].push(mine);
        }else {
            _SINGLE_REGISTRY_[stakeToken].push(mine);
        }

        emit NewMineV3(mine, stakeToken, isLpToken);
    }

    // ============ Admin Operation Functions ============

    function removeMineV3(
        address mine,
        bool isLpToken,
        address stakeToken
    ) external onlyOwner {
        _MINE_REGISTRY_[mine] = address(0);
        if(isLpToken) {
            uint256 len = _LP_REGISTRY_[stakeToken].length;
            for (uint256 i = 0; i < len; i++) {
                if (mine == _LP_REGISTRY_[stakeToken][i]) {
                    if(i != len - 1) {
                        _LP_REGISTRY_[stakeToken][i] = _LP_REGISTRY_[stakeToken][len - 1];
                    }
                    _LP_REGISTRY_[stakeToken].pop();
                    break;
                }
            }
        }else {
            uint256 len = _SINGLE_REGISTRY_[stakeToken].length;
            for (uint256 i = 0; i < len; i++) {
                if (mine == _SINGLE_REGISTRY_[stakeToken][i]) {
                    if(i != len - 1) {
                        _SINGLE_REGISTRY_[stakeToken][i] = _SINGLE_REGISTRY_[stakeToken][len - 1];
                    }
                    _SINGLE_REGISTRY_[stakeToken].pop();
                    break;
                }
            }
        }

        emit RemoveMineV3(mine, stakeToken);
    }

    function addAdminList (address contractAddr) external onlyOwner {
        isAdminListed[contractAddr] = true;
        emit addAdmin(contractAddr);
    }

    function removeAdminList (address contractAddr) external onlyOwner {
        isAdminListed[contractAddr] = false;
        emit removeAdmin(contractAddr);
    }
}