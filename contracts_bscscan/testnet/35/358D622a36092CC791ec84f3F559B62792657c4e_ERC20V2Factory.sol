/**
 *Submitted for verification at BscScan.com on 2022-01-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-01
*/

// File: contracts/lib/CloneFactory.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

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

// File: contracts/lib/InitializableOwnable.sol


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

// File: contracts/Factory/ERC20V2Factory.sol


interface IStdERC20 {
    function init(
        address _creator,
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external;
}

interface ICustomERC20 {
    function init(
        address _creator,
        uint256 _initSupply,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _tradeBurnRatio,
        uint256 _tradeFeeRatio,
        address _team,
        bool _isMintable
    ) external;
}

/**
 * @title DODO ERC20V2Factory
 * @author DODO Breeder
 *
 * @notice Help user to create erc20 token
 */
contract ERC20V2Factory is InitializableOwnable {
    // ============ Templates ============

    address public immutable _CLONE_FACTORY_;
    address public _ERC20_TEMPLATE_;
    address public _CUSTOM_ERC20_TEMPLATE_;
    uint256 public _CREATE_FEE_;

    // ============ Events ============
    // 0 Std 1 TradeBurn or TradeFee 2 Mintable
    event NewERC20(address erc20, address creator, uint256 erc20Type);
    event ChangeCreateFee(uint256 newFee);
    event Withdraw(address account, uint256 amount);
    event ChangeStdTemplate(address newStdTemplate);
    event ChangeCustomTemplate(address newCustomTemplate);

    // ============ Registry ============
    // creator -> token address list
    mapping(address => address[]) public _USER_STD_REGISTRY_;
    mapping(address => address[]) public _USER_CUSTOM_REGISTRY_;

    // ============ Functions ============

    fallback() external payable {}

    receive() external payable {}

    constructor(
        address cloneFactory,
        address erc20Template,
        address customErc20Template
    ) public {
        _CLONE_FACTORY_ = cloneFactory;
        _ERC20_TEMPLATE_ = erc20Template;
        _CUSTOM_ERC20_TEMPLATE_ = customErc20Template;
    }

    function createStdERC20(
        uint256 totalSupply,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external payable returns (address newERC20) {
        require(msg.value >= _CREATE_FEE_, "CREATE_FEE_NOT_ENOUGH");
        newERC20 = ICloneFactory(_CLONE_FACTORY_).clone(_ERC20_TEMPLATE_);
        IStdERC20(newERC20).init(msg.sender, totalSupply, name, symbol, decimals);
        _USER_STD_REGISTRY_[msg.sender].push(newERC20);
        emit NewERC20(newERC20, msg.sender, 0);
    }

    function createCustomERC20(
        uint256 initSupply,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 tradeBurnRatio,
        uint256 tradeFeeRatio,
        address teamAccount,
        bool isMintable
    ) external payable returns (address newCustomERC20) {
        require(msg.value >= _CREATE_FEE_, "CREATE_FEE_NOT_ENOUGH");
        newCustomERC20 = ICloneFactory(_CLONE_FACTORY_).clone(_CUSTOM_ERC20_TEMPLATE_);

        ICustomERC20(newCustomERC20).init(
            msg.sender,
            initSupply, 
            name, 
            symbol, 
            decimals, 
            tradeBurnRatio, 
            tradeFeeRatio,
            teamAccount,
            isMintable
        );

        _USER_CUSTOM_REGISTRY_[msg.sender].push(newCustomERC20);
        if(isMintable)
            emit NewERC20(newCustomERC20, msg.sender, 2);
        else 
            emit NewERC20(newCustomERC20, msg.sender, 1);
    }


    // ============ View ============
    function getTokenByUser(address user) 
        external
        view
        returns (address[] memory stds,address[] memory customs)
    {
        return (_USER_STD_REGISTRY_[user], _USER_CUSTOM_REGISTRY_[user]);
    }

    // ============ Ownable =============
    function changeCreateFee(uint256 newFee) external onlyOwner {
        _CREATE_FEE_ = newFee;
        emit ChangeCreateFee(newFee);
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        msg.sender.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function updateStdTemplate(address newStdTemplate) external onlyOwner {
        _ERC20_TEMPLATE_ = newStdTemplate;
        emit ChangeStdTemplate(newStdTemplate);
    }

    function updateCustomTemplate(address newCustomTemplate) external onlyOwner {
        _CUSTOM_ERC20_TEMPLATE_ = newCustomTemplate;
        emit ChangeCustomTemplate(newCustomTemplate);
    }
}