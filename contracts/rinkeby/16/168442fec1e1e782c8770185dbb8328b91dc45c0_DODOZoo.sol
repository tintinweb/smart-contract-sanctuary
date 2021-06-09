/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// File: contracts/lib/Ownable.sol

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
contract Ownable {
    address public _OWNER_;
    address public _NEW_OWNER_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    constructor() internal {
        _OWNER_ = msg.sender;
        emit OwnershipTransferred(address(0), _OWNER_);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/intf/IDODO.sol



interface IDODO {
    function init(
        address owner,
        address supervisor,
        address maintainer,
        address baseToken,
        address quoteToken,
        address oracle,
        uint256 lpFeeRate,
        uint256 mtFeeRate,
        uint256 k,
        uint256 gasPriceLimit
    ) external;

    function transferOwnership(address newOwner) external;

    function claimOwnership() external;

    function sellBaseToken(
        uint256 amount,
        uint256 minReceiveQuote,
        bytes calldata data
    ) external returns (uint256);

    function buyBaseToken(
        uint256 amount,
        uint256 maxPayQuote,
        bytes calldata data
    ) external returns (uint256);

    function querySellBaseToken(uint256 amount) external view returns (uint256 receiveQuote);

    function queryBuyBaseToken(uint256 amount) external view returns (uint256 payQuote);

    function getExpectedTarget() external view returns (uint256 baseTarget, uint256 quoteTarget);

    function depositBaseTo(address to, uint256 amount) external returns (uint256);

    function withdrawBase(uint256 amount) external returns (uint256);

    function withdrawAllBase() external returns (uint256);

    function depositQuoteTo(address to, uint256 amount) external returns (uint256);

    function withdrawQuote(uint256 amount) external returns (uint256);

    function withdrawAllQuote() external returns (uint256);

    function _BASE_CAPITAL_TOKEN_() external view returns (address);

    function _QUOTE_CAPITAL_TOKEN_() external view returns (address);

    function _BASE_TOKEN_() external returns (address);

    function _QUOTE_TOKEN_() external returns (address);
}

// File: contracts/helper/CloneFactory.sol


interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}

// introduction of proxy mode design: https://docs.openzeppelin.com/upgrades/2.8/
// minimum implementation of transparent proxy: https://eips.ethereum.org/EIPS/eip-1167

contract CloneFactory is ICloneFactory {
    function clone(address prototype) external override returns (address proxy) {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }
}

// File: contracts/DODOZoo.sol


/**
 * @title DODOZoo
 * @author DODO Breeder
 *
 * @notice Register of All DODO
 */
contract DODOZoo is Ownable {
    address public _DODO_LOGIC_;
    address public _CLONE_FACTORY_;

    address public _DEFAULT_SUPERVISOR_;

    mapping(address => mapping(address => address)) internal _DODO_REGISTER_;
    address[] public _DODOs;

    // ============ Events ============

    event DODOBirth(address newBorn, address baseToken, address quoteToken);

    // ============ Constructor Function ============

    constructor(
        address _dodoLogic,
        address _cloneFactory,
        address _defaultSupervisor
    ) public {
        _DODO_LOGIC_ = _dodoLogic;
        _CLONE_FACTORY_ = _cloneFactory;
        _DEFAULT_SUPERVISOR_ = _defaultSupervisor;
    }

    // ============ Admin Function ============

    function setDODOLogic(address _dodoLogic) external onlyOwner {
        _DODO_LOGIC_ = _dodoLogic;
    }

    function setCloneFactory(address _cloneFactory) external onlyOwner {
        _CLONE_FACTORY_ = _cloneFactory;
    }

    function setDefaultSupervisor(address _defaultSupervisor) external onlyOwner {
        _DEFAULT_SUPERVISOR_ = _defaultSupervisor;
    }

    function removeDODO(address dodo) external onlyOwner {
        address baseToken = IDODO(dodo)._BASE_TOKEN_();
        address quoteToken = IDODO(dodo)._QUOTE_TOKEN_();
        require(isDODORegistered(baseToken, quoteToken), "DODO_NOT_REGISTERED");
        _DODO_REGISTER_[baseToken][quoteToken] = address(0);
        for (uint256 i = 0; i <= _DODOs.length - 1; i++) {
            if (_DODOs[i] == dodo) {
                _DODOs[i] = _DODOs[_DODOs.length - 1];
                _DODOs.pop();
                break;
            }
        }
    }

    function addDODO(address dodo) public onlyOwner {
        address baseToken = IDODO(dodo)._BASE_TOKEN_();
        address quoteToken = IDODO(dodo)._QUOTE_TOKEN_();
        require(!isDODORegistered(baseToken, quoteToken), "DODO_REGISTERED");
        _DODO_REGISTER_[baseToken][quoteToken] = dodo;
        _DODOs.push(dodo);
    }

    // ============ Breed DODO Function ============

    function breedDODO(
        address maintainer,
        address baseToken,
        address quoteToken,
        address oracle,
        uint256 lpFeeRate,
        uint256 mtFeeRate,
        uint256 k,
        uint256 gasPriceLimit
    ) external onlyOwner returns (address newBornDODO) {
        require(!isDODORegistered(baseToken, quoteToken), "DODO_REGISTERED");
        newBornDODO = ICloneFactory(_CLONE_FACTORY_).clone(_DODO_LOGIC_);
        IDODO(newBornDODO).init(
            _OWNER_,
            _DEFAULT_SUPERVISOR_,
            maintainer,
            baseToken,
            quoteToken,
            oracle,
            lpFeeRate,
            mtFeeRate,
            k,
            gasPriceLimit
        );
        addDODO(newBornDODO);
        emit DODOBirth(newBornDODO, baseToken, quoteToken);
        return newBornDODO;
    }

    // ============ View Functions ============

    function isDODORegistered(address baseToken, address quoteToken) public view returns (bool) {
        if (
            _DODO_REGISTER_[baseToken][quoteToken] == address(0) &&
            _DODO_REGISTER_[quoteToken][baseToken] == address(0)
        ) {
            return false;
        } else {
            return true;
        }
    }

    function getDODO(address baseToken, address quoteToken) external view returns (address) {
        return _DODO_REGISTER_[baseToken][quoteToken];
    }

    function getDODOs() external view returns (address[] memory) {
        return _DODOs;
    }
}