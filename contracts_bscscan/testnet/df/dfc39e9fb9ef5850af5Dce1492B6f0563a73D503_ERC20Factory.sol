/**
 * Submitted for verification at BscScan.com on 2021-09-15
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}

// introduction of proxy mode design: https://docs.openzeppelin.com/upgrades/2.8/
// minimum implementation of transparent proxy: https://eips.ethereum.org/EIPS/eip-1167

contract CloneFactory is ICloneFactory {
    function clone(address prototype)
        external
        override
        returns (address proxy)
    {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
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

contract InitializableOwnable {
    address public _owner;
    address public _new_owner;
    bool internal _initialized;

    event OwnershipTransferPrepared(
        address indexed previousOwner,
        address indexed newOwner
    );

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier notInitialized() {
        require(!_initialized, "already init");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "only owner");
        _;
    }

    function initOwner(address newOwner) public notInitialized {
        _initialized = true;
        _owner = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_owner, newOwner);
        _new_owner = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _new_owner, "only new owner");
        emit OwnershipTransferred(_owner, _new_owner);
        _owner = _new_owner;
        _new_owner = address(0);
    }
}

interface IMintERC20 {
    function init(
        address _creator,
        uint256 _initSupply,
        uint256 _cap,
        string memory _name,
        string memory _symbol,
        uint256 _decimals
    ) external;
}

interface ILiquidityIncreaseERC20 {
    function init(
        address _creator,
        string memory _NAME,
        string memory _SYMBOL,
        uint256 _DECIMALS,
        uint256 _supply,
        uint256 _txFee,
        uint256 _lpFee,
        uint256 _MAXAMOUNT,
        uint256 SELLMAXAMOUNT,
        address routerAddress
    ) external;
}

interface ILiquidityMarketingERC20 {
    function init(
        address _creator,
        string memory _NAME,
        string memory _SYMBOL,
        uint256 _DECIMALS,
        uint256 _supply,
        uint256 _txFee,
        uint256 _lpFee,
        uint256 _mFee,
        uint256 _MAXAMOUNT,
        uint256 _SELLMAXAMOUNT,
        address routerAddress,
        address _marketingAddress
    ) external;
}

/**
 * @title MoonDoge ERC20V2Factory
 * @author MoonDoge Engineer
 *
 * @notice Help user to create erc20 token with mingas
 */
contract ERC20Factory is InitializableOwnable {
    // ============ Templates ============

    address public immutable _CLONE_FACTORY_;
    address public _MINT_ERC20_TEMPLATE_;
    address public _LIQ_INC_ERC20_TEMPLATE_;
    address public _LIQ_MARKET_ERC20_TEMPLATE_;
    uint256 public _CREATE_FEE_;

    // ============ Events ============
    // 0 StdMint 1 liquidityIncrease 2 liquidityMarketing
    event NewERC20(address erc20, address creator, uint256 erc20Type);
    event ChangeCreateFee(uint256 newFee);
    event Withdraw(address account, uint256 amount);
    event ChangeMintTemplate(address newMintTemplate);
    event ChangeLiqIncTemplate(address newLiqIncTemplate);
    event ChangeLiqMarketTemplate(address newLiqMarketTemplate);

    // ============ Registry ============
    // creator -> token address list
    mapping(address => address[]) public _USER_MINT_REGISTRY_;
    mapping(address => address[]) public _USER_LIQ_INC_REGISTRY_;
    mapping(address => address[]) public _USER_LIQ_MARKET_REGISTRY_;

    // ============ Functions ============

    fallback() external payable {}

    receive() external payable {}

    constructor(
        address cloneFactory,
        address mintErc20Template,
        address liqIncErc20Template,
        address liqMarketErc20Template
    ) public {
        _CLONE_FACTORY_ = cloneFactory;
        _MINT_ERC20_TEMPLATE_ = mintErc20Template;
        _LIQ_INC_ERC20_TEMPLATE_ = liqIncErc20Template;
        _LIQ_MARKET_ERC20_TEMPLATE_ = liqMarketErc20Template;
    }

    function createMintableERC20(
        uint256 totalSupply,
        uint256 cap,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external payable returns (address mintableERC20) {
        require(msg.value >= _CREATE_FEE_, "create fee not enough");
        mintableERC20 = ICloneFactory(_CLONE_FACTORY_).clone(
            _MINT_ERC20_TEMPLATE_
        );
        IMintERC20(mintableERC20).init(
            msg.sender,
            totalSupply,
            cap,
            name,
            symbol,
            decimals
        );
        _USER_MINT_REGISTRY_[msg.sender].push(mintableERC20);
        emit NewERC20(mintableERC20, msg.sender, 0);
    }

    function createLiquidityIncreaseERC20(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply,
        uint256 txFee,
        uint256 lpFee,
        uint256 MAXAMOUNT,
        uint256 SELLMAXAMOUNT,
        address routerAddress
    ) external payable returns (address liquidityIncreaseERC20) {
        require(msg.value >= _CREATE_FEE_, "CREATE_FEE_NOT_ENOUGH");
        liquidityIncreaseERC20 = ICloneFactory(_CLONE_FACTORY_).clone(
            _LIQ_INC_ERC20_TEMPLATE_
        );

        ILiquidityIncreaseERC20(liquidityIncreaseERC20).init(
            msg.sender,
            name,
            symbol,
            decimals,
            totalSupply,
            txFee,
            lpFee,
            MAXAMOUNT,
            SELLMAXAMOUNT,
            routerAddress
        );

        _USER_LIQ_INC_REGISTRY_[msg.sender].push(liquidityIncreaseERC20);
        emit NewERC20(liquidityIncreaseERC20, msg.sender, 1);
    }

    function createLiquidityMarketingERC20(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply,
        uint256 txFee,
        uint256 lpFee,
        uint256 mFee,
        uint256 MAXAMOUNT,
        uint256 SELLMAXAMOUNT,
        address routerAddress,
        address marketingAddress
    ) external payable returns (address liquidityMarketingERC20) {
        require(msg.value >= _CREATE_FEE_, "CREATE_FEE_NOT_ENOUGH");
        liquidityMarketingERC20 = ICloneFactory(_CLONE_FACTORY_).clone(
            _LIQ_MARKET_ERC20_TEMPLATE_
        );

        ILiquidityMarketingERC20(liquidityMarketingERC20).init(
            msg.sender,
            name,
            symbol,
            decimals,
            totalSupply,
            txFee,
            lpFee,
            mFee,
            MAXAMOUNT,
            SELLMAXAMOUNT,
            routerAddress,
            marketingAddress
        );

        _USER_LIQ_MARKET_REGISTRY_[msg.sender].push(liquidityMarketingERC20);
        emit NewERC20(liquidityMarketingERC20, msg.sender, 2);
    }

    // ============ View ============
    function getTokenByUser(address user)
        external
        view
        returns (
            address[] memory mints,
            address[] memory liqInc,
            address[] memory liqMarket
        )
    {
        return (
            _USER_MINT_REGISTRY_[user],
            _USER_LIQ_INC_REGISTRY_[user],
            _USER_LIQ_MARKET_REGISTRY_[user]
        );
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

    function updateMintTemplate(address newMintTemplate) external onlyOwner {
        _MINT_ERC20_TEMPLATE_ = newMintTemplate;
        emit ChangeMintTemplate(newMintTemplate);
    }

    function updateLiqIncTemplate(address newLiqIncTemplate)
        external
        onlyOwner
    {
        _LIQ_INC_ERC20_TEMPLATE_ = newLiqIncTemplate;
        emit ChangeLiqIncTemplate(newLiqIncTemplate);
    }

    function updateLiqMarketTemplate(address newLiqMarketTemplate)
        external
        onlyOwner
    {
        _LIQ_MARKET_ERC20_TEMPLATE_ = newLiqMarketTemplate;
        emit ChangeLiqMarketTemplate(newLiqMarketTemplate);
    }
}

