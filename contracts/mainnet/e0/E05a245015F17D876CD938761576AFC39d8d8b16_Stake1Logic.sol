// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../interfaces/IStake1Logic.sol";
import {IProxy} from "../interfaces/IProxy.sol";
import {IStakeFactory} from "../interfaces/IStakeFactory.sol";
import {IStakeRegistry} from "../interfaces/IStakeRegistry.sol";
import {IStake1Vault} from "../interfaces/IStake1Vault.sol";
import {IStakeTONTokamak} from "../interfaces/IStakeTONTokamak.sol";
import {IStakeUniswapV3} from "../interfaces/IStakeUniswapV3.sol";

import "../common/AccessibleCommon.sol";

import "./StakeProxyStorage.sol";

/// @title The logic of TOS Plaform
/// @notice Admin can createVault, createStakeContract.
/// User can excute the tokamak staking function of each contract through this logic.
contract Stake1Logic is StakeProxyStorage, AccessibleCommon, IStake1Logic {
    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "Stake1Logic:zero address");
        _;
    }

    /*
    /// @dev event on create vault
    /// @param vault the vault address created
    /// @param paytoken the token used for staking by user
    /// @param cap  allocated reward amount
    event CreatedVault(address indexed vault, address paytoken, uint256 cap);

    /// @dev event on create stake contract in vault
    /// @param vault the vault address
    /// @param stakeContract the stake contract address created
    /// @param phase the phase of TOS platform
    event CreatedStakeContract(
        address indexed vault,
        address indexed stakeContract,
        uint256 phase
    );

    /// @dev event on sale-closed
    /// @param vault the vault address
    event ClosedSale(address indexed vault);

    /// @dev event on setting stake registry
    /// @param stakeRegistry the stakeRegistry address
    event SetStakeRegistry(address stakeRegistry);
*/

    constructor() {}

    /// @dev upgrade to the logic of _stakeProxy
    /// @param _stakeProxy the StakeProxy address, it is stakeContract address in vault.
    /// @param _implementation new logic address
    function upgradeStakeTo(address _stakeProxy, address _implementation)
        external
        onlyOwner
    {
        IProxy(_stakeProxy).upgradeTo(_implementation);
    }

    /// @dev grant the role to account in target
    /// @param target target address
    /// @param role  byte32 of role
    /// @param account account address
    function grantRole(
        address target,
        bytes32 role,
        address account
    ) external onlyOwner {
        AccessControl(target).grantRole(role, account);
    }

    /// @dev revoke the role to account in target
    /// @param target target address
    /// @param role  byte32 of role
    /// @param account account address
    function revokeRole(
        address target,
        bytes32 role,
        address account
    ) external onlyOwner {
        AccessControl(target).revokeRole(role, account);
    }

    /// @dev Sets TOS address
    /// @param _tos new TOS address
    function setTOS(address _tos) public onlyOwner nonZeroAddress(_tos) {
        tos = _tos;
    }

    /// @dev Sets Stake Registry address
    /// @param _stakeRegistry new StakeRegistry address
    function setStakeRegistry(address _stakeRegistry)
        public
        onlyOwner
        nonZeroAddress(_stakeRegistry)
    {
        stakeRegistry = IStakeRegistry(_stakeRegistry);
        emit SetStakeRegistry(_stakeRegistry);
    }

    /// @dev Sets StakeFactory address
    /// @param _stakeFactory new StakeFactory address
    function setStakeFactory(address _stakeFactory)
        public
        onlyOwner
        nonZeroAddress(_stakeFactory)
    {
        stakeFactory = IStakeFactory(_stakeFactory);
    }

    /// @dev Set factory address by StakeType
    /// @param _stakeType the stake type , 0:TON, 1: Simple, 2: UniswapV3LP
    /// @param _factory the factory address
    function setFactoryByStakeType(uint256 _stakeType, address _factory)
        external
        override
        onlyOwner
        nonZeroAddress(address(stakeFactory))
    {
        stakeFactory.setFactoryByStakeType(_stakeType, _factory);
    }

    /// @dev Sets StakeVaultFactory address
    /// @param _stakeVaultFactory new StakeVaultFactory address
    function setStakeVaultFactory(address _stakeVaultFactory)
        external
        onlyOwner
        nonZeroAddress(_stakeVaultFactory)
    {
        stakeVaultFactory = IStakeVaultFactory(_stakeVaultFactory);
    }

    /// Set initial variables
    /// @param _tos  TOS token address
    /// @param _stakeRegistry the registry address
    /// @param _stakeFactory the StakeFactory address
    /// @param _stakeVaultFactory the StakeVaultFactory address
    /// @param _ton  TON address in Tokamak
    /// @param _wton WTON address in Tokamak
    /// @param _depositManager DepositManager address in Tokamak
    /// @param _seigManager SeigManager address in Tokamak
    function setStore(
        address _tos,
        address _stakeRegistry,
        address _stakeFactory,
        address _stakeVaultFactory,
        address _ton,
        address _wton,
        address _depositManager,
        address _seigManager
    )
        external
        override
        onlyOwner
        nonZeroAddress(_stakeVaultFactory)
        nonZeroAddress(_ton)
        nonZeroAddress(_wton)
        nonZeroAddress(_depositManager)
    {
        setTOS(_tos);
        setStakeRegistry(_stakeRegistry);
        setStakeFactory(_stakeFactory);
        stakeVaultFactory = IStakeVaultFactory(_stakeVaultFactory);

        ton = _ton;
        wton = _wton;
        depositManager = _depositManager;
        seigManager = _seigManager;
    }

    /// @dev create vault
    /// @param _paytoken the token used for staking by user
    /// @param _cap  allocated reward amount
    /// @param _saleStartBlock  the start block that can stake by user
    /// @param _stakeStartBlock the start block that end staking by user and start that can claim reward by user
    /// @param _phase  phase of TOS platform
    /// @param _vaultName  vault's name's hash
    /// @param _stakeType  stakeContract's type, if 0, StakeTON, else if 1 , StakeSimple , else if 2, StakeDefi
    /// @param _defiAddr  extra defi address , default is zero address
    function createVault(
        address _paytoken,
        uint256 _cap,
        uint256 _saleStartBlock,
        uint256 _stakeStartBlock,
        uint256 _phase,
        bytes32 _vaultName,
        uint256 _stakeType,
        address _defiAddr
    ) external override onlyOwner nonZeroAddress(address(stakeVaultFactory)) {
        address vault =
            stakeVaultFactory.create(
                _phase,
                [tos, _paytoken, address(stakeFactory), _defiAddr],
                [_stakeType, _cap, _saleStartBlock, _stakeStartBlock],
                address(this)
            );
        require(vault != address(0), "Stake1Logic: vault is zero");
        stakeRegistry.addVault(vault, _phase, _vaultName);

        emit CreatedVault(vault, _paytoken, _cap);
    }

    /// @dev create stake contract in vault
    /// @param _phase the phase of TOS platform
    /// @param _vault  vault's address
    /// @param token  the reward token's address
    /// @param paytoken  the token used for staking by user
    /// @param periodBlock  the period that generate reward
    /// @param _name  the stake contract's name
    function createStakeContract(
        uint256 _phase,
        address _vault,
        address token,
        address paytoken,
        uint256 periodBlock,
        string memory _name
    ) external override onlyOwner {
        require(
            stakeRegistry.validVault(_phase, _vault),
            "Stake1Logic: unvalidVault"
        );

        IStake1Vault vault = IStake1Vault(_vault);

        (
            address[2] memory addrInfos,
            ,
            uint256 stakeType,
            uint256[3] memory iniInfo,
            ,

        ) = vault.infos();

        require(paytoken == addrInfos[0], "Stake1Logic: differrent paytoken");
        uint256 phase = _phase;
        address[4] memory _addr = [token, addrInfos[0], _vault, addrInfos[1]];

        // solhint-disable-next-line max-line-length
        address _contract =
            stakeFactory.create(
                stakeType,
                _addr,
                address(stakeRegistry),
                [iniInfo[0], iniInfo[1], periodBlock]
            );
        require(_contract != address(0), "Stake1Logic: deploy fail");

        IStake1Vault(_vault).addSubVaultOfStake(_name, _contract, periodBlock);
        stakeRegistry.addStakeContract(address(vault), _contract);

        emit CreatedStakeContract(address(vault), _contract, phase);
    }

    /// @dev create stake contract in vault
    /// @param _phase phase of TOS platform
    /// @param _vaultName vault's name's hash
    /// @param _vault vault's address
    function addVault(
        uint256 _phase,
        bytes32 _vaultName,
        address _vault
    ) external override onlyOwner {
        stakeRegistry.addVault(_vault, _phase, _vaultName);
    }

    /// @dev end to staking by user
    /// @param _vault vault's address
    function closeSale(address _vault) external override {
        IStake1Vault(_vault).closeSale();

        emit ClosedSale(_vault);
    }

    /// @dev list of stakeContracts in vault
    /// @param _vault vault's address
    function stakeContractsOfVault(address _vault)
        external
        view
        override
        nonZeroAddress(_vault)
        returns (address[] memory)
    {
        return IStake1Vault(_vault).stakeAddressesAll();
    }

    /// @dev list of vaults in _phase
    /// @param _phase the _phase number
    function vaultsOfPhase(uint256 _phase)
        external
        view
        override
        returns (address[] memory)
    {
        return stakeRegistry.phasesAll(_phase);
    }

    /// @dev stake in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    /// @param stakeAmount the amount that stake to layer2
    function tokamakStaking(
        address _stakeContract,
        address _layer2,
        uint256 stakeAmount
    ) external override {
        IStakeTONTokamak(_stakeContract).tokamakStaking(_layer2, stakeAmount);
    }

    /// @dev Requests unstaking the amount WTON in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    /// @param amount the amount of unstaking
    function tokamakRequestUnStaking(
        address _stakeContract,
        address _layer2,
        uint256 amount
    ) external override {
        IStakeTONTokamak(_stakeContract).tokamakRequestUnStaking(
            _layer2,
            amount
        );
    }

    /// @dev Requests unstaking the amount of all  in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    function tokamakRequestUnStakingAll(address _stakeContract, address _layer2)
        external
        override
    {
        IStakeTONTokamak(_stakeContract).tokamakRequestUnStakingAll(_layer2);
    }

    /// @dev Processes unstaking the requested unstaking amount in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    function tokamakProcessUnStaking(address _stakeContract, address _layer2)
        external
        override
    {
        IStakeTONTokamak(_stakeContract).tokamakProcessUnStaking(_layer2);
    }

    /// @dev Swap TON to TOS using uniswap v3
    /// @dev this function used in StakeTON ( stakeType=0 )
    /// @param _stakeContract the stakeContract's address
    /// @param amountIn the input amount
    /// @param amountOutMinimum the minimun output amount
    /// @param deadline deadline
    /// @param sqrtPriceLimitX96 sqrtPriceLimitX96
    /// @param _type the function type, if 0, use exactInputSingle function, else if, use exactInput function
    function exchangeWTONtoTOS(
        address _stakeContract,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint256 deadline,
        uint160 sqrtPriceLimitX96,
        uint256 _type
    ) external override returns (uint256 amountOut) {
        return
            IStakeTONTokamak(_stakeContract).exchangeWTONtoTOS(
                amountIn,
                amountOutMinimum,
                deadline,
                sqrtPriceLimitX96,
                _type
            );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStake1Logic {
    /// @dev event on create vault
    /// @param vault the vault address created
    /// @param paytoken the token used for staking by user
    /// @param cap  allocated reward amount
    event CreatedVault(address indexed vault, address paytoken, uint256 cap);

    /// @dev event on create stake contract in vault
    /// @param vault the vault address
    /// @param stakeContract the stake contract address created
    /// @param phase the phase of TOS platform
    event CreatedStakeContract(
        address indexed vault,
        address indexed stakeContract,
        uint256 phase
    );

    /// @dev event on sale-closed
    /// @param vault the vault address
    event ClosedSale(address indexed vault);

    /// @dev event on setting stake registry
    /// @param stakeRegistry the stakeRegistry address
    event SetStakeRegistry(address stakeRegistry);

    /// Set initial variables
    /// @param _tos  TOS token address
    /// @param _stakeRegistry the registry address
    /// @param _stakeFactory the StakeFactory address
    /// @param _stakeVaultFactory the StakeVaultFactory address
    /// @param _ton  TON address in Tokamak
    /// @param _wton WTON address in Tokamak
    /// @param _depositManager DepositManager address in Tokamak
    /// @param _seigManager SeigManager address in Tokamak
    function setStore(
        address _tos,
        address _stakeRegistry,
        address _stakeFactory,
        address _stakeVaultFactory,
        address _ton,
        address _wton,
        address _depositManager,
        address _seigManager
    ) external;

    /// @dev Set factory address by StakeType

    /// @param _stakeType the stake type , 0:TON, 1: Simple, 2: UniswapV3LP
    /// @param _factory the factory address
    function setFactoryByStakeType(uint256 _stakeType, address _factory)
        external;

    /// @dev create vault
    /// @param _paytoken the token used for staking by user
    /// @param _cap  allocated reward amount
    /// @param _saleStartBlock  the start block that can stake by user
    /// @param _stakeStartBlock the start block that end staking by user and start that can claim reward by user
    /// @param _phase  phase of TOS platform
    /// @param _vaultName  vault's name's hash
    /// @param _stakeType  stakeContract's type, if 0, StakeTON, else if 1 , StakeSimple , else if 2, StakeDefi
    /// @param _defiAddr  extra defi address , default is zero address
    function createVault(
        address _paytoken,
        uint256 _cap,
        uint256 _saleStartBlock,
        uint256 _stakeStartBlock,
        uint256 _phase,
        bytes32 _vaultName,
        uint256 _stakeType,
        address _defiAddr
    ) external;

    /// @dev create stake contract in vault
    /// @param _phase the phase of TOS platform
    /// @param _vault  vault's address
    /// @param token  the reward token's address
    /// @param paytoken  the token used for staking by user
    /// @param periodBlock  the period that generate reward
    /// @param _name  the stake contract's name
    function createStakeContract(
        uint256 _phase,
        address _vault,
        address token,
        address paytoken,
        uint256 periodBlock,
        string memory _name
    ) external;

    /// @dev create stake contract in vault
    /// @param _phase phase of TOS platform
    /// @param _vaultName vault's name's hash
    /// @param _vault vault's address
    function addVault(
        uint256 _phase,
        bytes32 _vaultName,
        address _vault
    ) external;

    /// @dev end to staking by user
    /// @param _vault vault's address
    function closeSale(address _vault) external;

    /// @dev list of stakeContracts in vault
    /// @param _vault vault's address
    function stakeContractsOfVault(address _vault)
        external
        view
        returns (address[] memory);

    /// @dev list of vaults in _phase
    /// @param _phase the phase number
    function vaultsOfPhase(uint256 _phase)
        external
        view
        returns (address[] memory);

    /// @dev stake in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    /// @param stakeAmount the amount that stake to layer2
    function tokamakStaking(
        address _stakeContract,
        address _layer2,
        uint256 stakeAmount
    ) external;

    /// @dev Requests unstaking in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    /// @param amount the amount of unstaking
    function tokamakRequestUnStaking(
        address _stakeContract,
        address _layer2,
        uint256 amount
    ) external;

    /// @dev Requests unstaking the amount of all  in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    function tokamakRequestUnStakingAll(address _stakeContract, address _layer2)
        external;

    /// @dev Processes unstaking the requested unstaking amount in tokamak's layer2
    /// @param _stakeContract the stakeContract's address
    /// @param _layer2 the layer2 address in Tokamak
    function tokamakProcessUnStaking(address _stakeContract, address _layer2)
        external;

    /// @dev Swap TON to TOS using uniswap v3
    /// @dev this function used in StakeTON ( stakeType=0 )
    /// @param _stakeContract the stakeContract's address
    /// @param amountIn the input amount
    /// @param amountOutMinimum the minimun output amount
    /// @param deadline deadline
    /// @param sqrtPriceLimitX96 sqrtPriceLimitX96
    /// @param _type the function type, if 0, use exactInputSingle function, else if, use exactInput function
    function exchangeWTONtoTOS(
        address _stakeContract,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint256 deadline,
        uint160 sqrtPriceLimitX96,
        uint256 _type
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IProxy {
    function upgradeTo(address impl) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeFactory {
    /// @dev Create a stake contract that calls the desired stake factory according to stakeType
    /// @param stakeType if 0, stakeTONFactory, else if 1 , stakeSimpleFactory , else if 2, stakeUniswapV3Factory
    /// @param _addr array of [token, paytoken, vault, _defiAddr]
    /// @param registry  registry address
    /// @param _intdata array of [saleStartBlock, startBlock, periodBlocks]
    /// @return contract address
    function create(
        uint256 stakeType,
        address[4] calldata _addr,
        address registry,
        uint256[3] calldata _intdata
    ) external returns (address);

    /// @dev Set factory address by StakeType
    /// @param _stakeType the stake type , 0:TON, 1: Simple, 2: UniswapV3LP
    /// @param _factory the factory address
    function setFactoryByStakeType(uint256 _stakeType, address _factory)
        external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeRegistry {
    /// @dev Set addresses for Tokamak integration
    /// @param _ton TON address
    /// @param _wton WTON address
    /// @param _depositManager DepositManager address
    /// @param _seigManager SeigManager address
    /// @param _swapProxy Proxy address that can swap TON and WTON
    function setTokamak(
        address _ton,
        address _wton,
        address _depositManager,
        address _seigManager,
        address _swapProxy
    ) external;

    /// @dev Add information related to Defi
    /// @param _name name . ex) UNISWAP_V3
    /// @param _router entry point of defi
    /// @param _ex1  additional variable . ex) positionManagerAddress in Uniswap V3
    /// @param _ex2  additional variable . ex) WETH Address in Uniswap V3
    /// @param _fee  fee
    /// @param _routerV2 In case of uniswap, router address of uniswapV2
    function addDefiInfo(
        string calldata _name,
        address _router,
        address _ex1,
        address _ex2,
        uint256 _fee,
        address _routerV2
    ) external;

    /// @dev Add Vault
    /// @dev It is excuted by proxy
    /// @param _vault vault address
    /// @param _phase phase ex) 1,2,3
    /// @param _vaultName  hash of vault's name
    function addVault(
        address _vault,
        uint256 _phase,
        bytes32 _vaultName
    ) external;

    /// @dev Add StakeContract in vault
    /// @dev It is excuted by proxy
    /// @param _vault vault address
    /// @param _stakeContract  StakeContract address
    function addStakeContract(address _vault, address _stakeContract) external;

    /// @dev Get addresses for Tokamak interface
    /// @return (ton, wton, depositManager, seigManager)
    function getTokamak()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address
        );

    /// @dev Get indos for UNISWAP_V3 interface
    /// @return (uniswapRouter, npm, wethAddress, fee)
    function getUniswap()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            address
        );

    /// @dev Checks if a vault is withing the given phase
    /// @param _phase the phase number
    /// @param _vault the vault's address
    /// @return valid true or false
    function validVault(uint256 _phase, address _vault)
        external
        view
        returns (bool valid);

    function phasesAll(uint256 _index) external view returns (address[] memory);

    function stakeContractsOfVaultAll(address _vault)
        external
        view
        returns (address[] memory);

    /// @dev view defi info
    /// @param _name  hash name : keccak256(abi.encodePacked(_name));
    /// @return name  _name ex) UNISWAP_V3, UNISWAP_V3_token0_token1
    /// @return router entry point of defi
    /// @return ext1  additional variable . ex) positionManagerAddress in Uniswap V3
    /// @return ext2  additional variable . ex) WETH Address in Uniswap V3
    /// @return fee  fee
    /// @return routerV2 In case of uniswap, router address of uniswapV2

    function defiInfo(bytes32 _name)
        external
        returns (
            string calldata name,
            address router,
            address ext1,
            address ext2,
            uint256 fee,
            address routerV2
        );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;
import "../libraries/LibTokenStake1.sol";

interface IStake1Vault {
    /// @dev Sets TOS address
    /// @param _tos  TOS address
    function setTOS(address _tos) external;

    /// @dev Change cap of the vault
    /// @param _cap  allocated reward amount
    function changeCap(uint256 _cap) external;

    /// @dev Set Defi Address
    /// @param _defiAddr DeFi related address
    function setDefiAddr(address _defiAddr) external;

    /// @dev If the vault has more money than the reward to give, the owner can withdraw the remaining amount.
    /// @param _amount the amount of withdrawal
    function withdrawReward(uint256 _amount) external;

    /// @dev  Add stake contract
    /// @param _name stakeContract's name
    /// @param stakeContract stakeContract's address
    /// @param periodBlocks the period that give rewards of stakeContract
    function addSubVaultOfStake(
        string memory _name,
        address stakeContract,
        uint256 periodBlocks
    ) external;

    /// @dev  Close the sale that can stake by user
    function closeSale() external;

    /// @dev claim function.
    /// @dev sender is a staking contract.
    /// @dev A function that pays the amount(_amount) to _to by the staking contract.
    /// @dev A function that _to claim the amount(_amount) from the staking contract and gets the TOS in the vault.
    /// @param _to a user that received reward
    /// @param _amount the receiving amount
    /// @return true
    function claim(address _to, uint256 _amount) external returns (bool);

    /// @dev Whether user(to) can receive a reward amount(_amount)
    /// @param _to  a staking contract.
    /// @param _amount the total reward amount of stakeContract
    /// @return true
    function canClaim(address _to, uint256 _amount)
        external
        view
        returns (bool);

    /// @dev Give the infomation of this vault
    /// @return paytoken, cap, saleStartBlock, stakeStartBlock, stakeEndBlock, blockTotalReward, saleClosed
    function infos()
        external
        view
        returns (
            address[2] memory,
            uint256,
            uint256,
            uint256[3] memory,
            uint256,
            bool
        );

    /// @dev Returns Give the TOS balance stored in the vault
    /// @return the balance of TOS in this vault.
    function balanceTOSAvailableAmount() external view returns (uint256);

    /// @dev Give Total reward amount of stakeContract(_account)
    /// @return Total reward amount of stakeContract(_account)
    function totalRewardAmount(address _account)
        external
        view
        returns (uint256);

    /// @dev Give all stakeContracts's addresses in this vault
    /// @return all stakeContracts's addresses
    function stakeAddressesAll() external view returns (address[] memory);

    /// @dev Give the ordered end blocks of stakeContracts in this vault
    /// @return the ordered end blocks
    function orderedEndBlocksAll() external view returns (uint256[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeTONTokamak {
    /// @dev  staking the staked TON in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    /// @param stakeAmount the amount that stake to layer2
    function tokamakStaking(address _layer2, uint256 stakeAmount) external;

    /// @dev  request unstaking the wtonAmount in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    /// @param wtonAmount the amount requested to unstaking
    function tokamakRequestUnStaking(address _layer2, uint256 wtonAmount)
        external;

    /// @dev Requests unstaking the amount of all  in tokamak's layer2
    /// @param _layer2 the layer2 address in Tokamak
    function tokamakRequestUnStakingAll(address _layer2) external;

    /// @dev process unstaking in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    function tokamakProcessUnStaking(address _layer2) external;

    /// @dev exchange holded WTON to TOS using uniswap
    /// @param _amountIn the input amount
    /// @param _amountOutMinimum the minimun output amount
    /// @param _deadline deadline
    /// @param sqrtPriceLimitX96 sqrtPriceLimitX96
    /// @param _kind the function type, if 0, use exactInputSingle function, else if, use exactInput function
    /// @return amountOut the amount of exchanged out token
    function exchangeWTONtoTOS(
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint256 _deadline,
        uint160 sqrtPriceLimitX96,
        uint256 _kind
    ) external returns (uint256 amountOut);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeUniswapV3 {
    /// @dev Stake amount
    /// @param tokenId  uniswapV3 LP Token
    /// @param deadline  the deadline that valid the owner's signature
    /// @param v the owner's signature - v
    /// @param r the owner's signature - r
    /// @param s the owner's signature - s
    function stake(
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getClaimLiquidity(uint256 tokenId)
        external
        returns (
            uint256 realReward,
            uint256 unableClaimReward,
            uint160 secondsPerLiquidityInsideX128,
            uint256 balanceCoinageOfUser,
            uint256 _coinageReward
        );

    /// @dev withdraw
    function withdraw(uint256 tokenId) external;

    /// @dev Claim for reward
    function claim(uint256 tokenId) external;

    // function setPool(
    //     address token0,
    //     address token1,
    //     string calldata defiInfoName
    // ) external;

    /// @dev
    function getUserStakedTokenIds(address user)
        external
        view
        returns (uint256[] memory ids);

    /// @dev tokenId's deposited information
    /// @param tokenId   tokenId
    /// @return poolAddress   poolAddress
    /// @return tick tick,
    /// @return liquidity liquidity,
    /// @return args liquidity,  startTime, endTime, claimedTime, startBlock, claimedBlock, claimedAmount
    /// @return secondsPL secondsPerLiquidityInsideInitialX128, secondsPerLiquidityInsideX128Las
    function getDepositToken(uint256 tokenId)
        external
        view
        returns (
            address poolAddress,
            int24[2] memory tick,
            uint128 liquidity,
            uint256[6] memory args,
            uint160[2] memory secondsPL
        );

    function getUserStakedTotal(address user)
        external
        view
        returns (
            uint256 totalDepositAmount,
            uint256 totalClaimedAmount,
            uint256 totalUnableClaimAmount
        );

    /// @dev Give the infomation of this stakeContracts
    /// @return return1  [token, vault, stakeRegistry, coinage]
    /// @return return2  [poolToken0, poolToken1, nonfungiblePositionManager, uniswapV3FactoryAddress]
    /// @return return3  [totalStakers, totalStakedAmount, rewardClaimedTotal,rewardNonLiquidityClaimTotal]
    function infos()
        external
        view
        returns (
            address[4] memory,
            address[4] memory,
            uint256[4] memory
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessRoleCommon.sol";

contract AccessibleCommon is AccessRoleCommon, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender), "Accessible: Caller is not an admin");
        _;
    }

    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    /// @dev remove admin
    /// @param account  address to remove
    function removeAdmin(address account) public virtual onlyOwner {
        renounceRole(ADMIN_ROLE, account);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(ADMIN_ROLE, newAdmin);
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

//import "../interfaces/IStakeProxyStorage.sol";
import {IStakeFactory} from "../interfaces/IStakeFactory.sol";
import {IStakeRegistry} from "../interfaces/IStakeRegistry.sol";
import {IStakeVaultFactory} from "../interfaces/IStakeVaultFactory.sol";

/// @title The storage of StakeProxy
contract StakeProxyStorage {
    /// @dev stakeRegistry
    IStakeRegistry public stakeRegistry;

    /// @dev stakeFactory
    IStakeFactory public stakeFactory;

    /// @dev stakeVaultFactory
    IStakeVaultFactory public stakeVaultFactory;

    /// @dev TOS address
    address public tos;

    /// @dev TON address in Tokamak
    address public ton;

    /// @dev WTON address in Tokamak
    address public wton;

    /// @dev Depositmanager address in Tokamak
    address public depositManager;

    /// @dev SeigManager address in Tokamak
    address public seigManager;

    /// @dev flag for pause proxy
    bool public pauseProxy;

    /// @dev implementation of proxy index
    mapping(uint256 => address) public proxyImplementation;

    mapping(address => bool) public aliveImplementation;

    mapping(bytes4 => address) public selectorImplementation;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

library LibTokenStake1 {
    enum DefiStatus {
        NONE,
        APPROVE,
        DEPOSITED,
        REQUESTWITHDRAW,
        REQUESTWITHDRAWALL,
        WITHDRAW,
        END
    }
    struct DefiInfo {
        string name;
        address router;
        address ext1;
        address ext2;
        uint256 fee;
        address routerV2;
    }
    struct StakeInfo {
        string name;
        uint256 startBlock;
        uint256 endBlock;
        uint256 balance;
        uint256 totalRewardAmount;
        uint256 claimRewardAmount;
    }

    struct StakedAmount {
        uint256 amount;
        uint256 claimedBlock;
        uint256 claimedAmount;
        uint256 releasedBlock;
        uint256 releasedAmount;
        uint256 releasedTOSAmount;
        bool released;
    }

    struct StakedAmountForSTOS {
        uint256 amount;
        uint256 startBlock;
        uint256 periodBlock;
        uint256 rewardPerBlock;
        uint256 claimedBlock;
        uint256 claimedAmount;
        uint256 releasedBlock;
        uint256 releasedAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract AccessRoleCommon {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeVaultFactory {
    /// @dev Create a vault that hold reward, _cap is allocated reward amount.
    /// @param _phase phase number
    /// @param _addr the array of [token, paytoken, vault, defiAddr]
    /// @param _intInfo array of [_stakeType, _cap, _saleStartBlock, _stakeStartBlock]
    /// @param owner the owner adderess
    /// @return a vault address
    function create(
        uint256 _phase,
        address[4] calldata _addr,
        uint256[4] calldata _intInfo,
        address owner
    ) external returns (address);

    /// @dev Create a vault that hold reward, _cap is allocated reward amount.
    /// @param _phase phase number
    /// @param _addr the array of [tos, _stakefactory]
    /// @param _intInfo array of [_stakeType, _cap, _rewardPerBlock ]
    /// @param _name the name of stake contract
    /// @param owner the owner adderess
    /// @return a vault address
    function create2(
        uint256 _phase,
        address[2] calldata _addr,
        uint256[3] calldata _intInfo,
        string memory _name,
        address owner
    ) external returns (address);

    /// @dev Set stakeVaultLogic address by _phase
    /// @param _phase the stake type
    /// @param _logic the vault logic address
    function setVaultLogicByPhase(uint256 _phase, address _logic) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 100
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}