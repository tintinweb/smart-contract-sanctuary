/**
 *Submitted for verification at Etherscan.io on 2020-11-27
*/

// Dependency file: contracts/modules/ConfigNames.sol

// SPDX-License-Identifier: MIT
// pragma solidity >=0.5.16;

library ConfigNames {
    //GOVERNANCE
    bytes32 public constant PROPOSAL_VOTE_DURATION = bytes32('PROPOSAL_VOTE_DURATION');
    bytes32 public constant PROPOSAL_EXECUTE_DURATION = bytes32('PROPOSAL_EXECUTE_DURATION');
    bytes32 public constant PROPOSAL_CREATE_COST = bytes32('PROPOSAL_CREATE_COST');
    bytes32 public constant STAKE_LOCK_TIME = bytes32('STAKE_LOCK_TIME');
    bytes32 public constant MINT_AMOUNT_PER_BLOCK =  bytes32('MINT_AMOUNT_PER_BLOCK');
    bytes32 public constant INTEREST_PLATFORM_SHARE =  bytes32('INTEREST_PLATFORM_SHARE');
    bytes32 public constant CHANGE_PRICE_DURATION =  bytes32('CHANGE_PRICE_DURATION');
    bytes32 public constant CHANGE_PRICE_PERCENT =  bytes32('CHANGE_PRICE_PERCENT');

    // POOL
    bytes32 public constant POOL_BASE_INTERESTS = bytes32('POOL_BASE_INTERESTS');
    bytes32 public constant POOL_MARKET_FRENZY = bytes32('POOL_MARKET_FRENZY');
    bytes32 public constant POOL_PLEDGE_RATE = bytes32('POOL_PLEDGE_RATE');
    bytes32 public constant POOL_LIQUIDATION_RATE = bytes32('POOL_LIQUIDATION_RATE');
    bytes32 public constant POOL_MINT_BORROW_PERCENT = bytes32('POOL_MINT_BORROW_PERCENT');
    bytes32 public constant POOL_MINT_POWER = bytes32('POOL_MINT_POWER');
    
    //NOT GOVERNANCE
    bytes32 public constant AAAA_USER_MINT = bytes32('AAAA_USER_MINT');
    bytes32 public constant AAAA_TEAM_MINT = bytes32('AAAA_TEAM_MINT');
    bytes32 public constant AAAA_REWAED_MINT = bytes32('AAAA_REWAED_MINT');
    bytes32 public constant DEPOSIT_ENABLE = bytes32('DEPOSIT_ENABLE');
    bytes32 public constant WITHDRAW_ENABLE = bytes32('WITHDRAW_ENABLE');
    bytes32 public constant BORROW_ENABLE = bytes32('BORROW_ENABLE');
    bytes32 public constant REPAY_ENABLE = bytes32('REPAY_ENABLE');
    bytes32 public constant LIQUIDATION_ENABLE = bytes32('LIQUIDATION_ENABLE');
    bytes32 public constant REINVEST_ENABLE = bytes32('REINVEST_ENABLE');
    bytes32 public constant INTEREST_BUYBACK_SHARE =  bytes32('INTEREST_BUYBACK_SHARE');

    //POOL
    bytes32 public constant POOL_PRICE = bytes32('POOL_PRICE');

    //wallet
    bytes32 public constant TEAM = bytes32('team'); 
    bytes32 public constant SPARE = bytes32('spare');
    bytes32 public constant REWARD = bytes32('reward');
}

// Root file: contracts/AAAADeploy.sol

pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

// import 'contracts/modules/ConfigNames.sol';

interface IConfigable {
    function setupConfig(address config) external;
}

interface IConfig {
    function developer() external view returns (address);
    function platform() external view returns (address);
    function factory() external view returns (address);
    function mint() external view returns (address);
    function token() external view returns (address);
    function share() external view returns (address);
    function governor() external view returns (address);
    function initialize (address _platform, address _factory, address _mint, address _token, address _share, address _governor) external;
    function initParameter() external;
    function addMintToken(address _token) external;
    function setWallets(bytes32[] calldata _names, address[] calldata _wallets) external;
    function isMintToken(address _token) external view returns (bool);
    function changeDeveloper(address _developer) external;
    function setValue(bytes32 _key, uint _value) external;
}

interface IAAAAMint {
    function sync() external;
}

interface IAAAAShare {
    function setShareToken(address _shareToken) external;
}

interface IAAAAToken {
    function initialize() external;
}

interface IAAAAFactory {
    function countPools() external view returns(uint);
    function countBallots() external view returns(uint);
    function allBallots(uint index) external view returns(address);
    function allPools(uint index) external view returns(address);
    function isPool(address addr) external view returns(bool);
    function getPool(address lend, address collateral) external view returns(address);
    function createPool(address _lendToken, address _collateralToken) external returns (address pool);
    function changeBallotByteHash(bytes32 _hash) external;
}

interface IMasterChef {
    function cake() external view returns(address);
}

interface ILPStrategyFactory {
    function createStrategy(address _collateralToken, address _poolAddress, uint _lpPoolpid) external returns (address _strategy);
}

interface IAAAAPlatform {
    function switchStrategy(address _lendToken, address _collateralToken, address _collateralStrategy) external;
}

contract AAAADeploy {
    address public owner;
    address public config;
    address public LPStrategyFactory;
    bool public LPStrategyCanMint;

    modifier onlyOwner() {
        require(msg.sender == owner, 'OWNER FORBIDDEN');
        _;
    }
 
    constructor() public {
        owner = msg.sender;
    }
    
    function setupConfig(address _config) onlyOwner external {
        require(_config != address(0), "ZERO ADDRESS");
        config = _config;
    }

    function changeDeveloper(address _developer) onlyOwner external {
        IConfig(config).changeDeveloper(_developer);
    }
    
    function setMasterchef(address _LPStrategyFactory, bool _LPStrategyCanMint) onlyOwner external {
        LPStrategyFactory = _LPStrategyFactory;
        LPStrategyCanMint = _LPStrategyCanMint;
    }

    function createPool(address _lendToken, address _collateralToken, uint _lpPoolpid) onlyOwner public {
        if(LPStrategyCanMint) {
            require(IConfig(config).isMintToken(_lendToken), 'REQUEST ADD MINT TOKEN FIRST');
        }
        address pool = IAAAAFactory(IConfig(config).factory()).createPool(_lendToken, _collateralToken);
        address strategy = ILPStrategyFactory(LPStrategyFactory).createStrategy(_collateralToken, pool, _lpPoolpid);
        IAAAAPlatform(IConfig(config).platform()).switchStrategy(_lendToken, _collateralToken, strategy);
    }

    function changeBallotByteHash(bytes32 _hash) onlyOwner external {
        IAAAAFactory(IConfig(config).factory()).changeBallotByteHash(_hash);
    }

    function addMintToken(address _token) onlyOwner external {
        IConfig(config).addMintToken(_token);
    }

    function changeMintPerBlock(uint _value) onlyOwner external {
        IConfig(config).setValue(ConfigNames.MINT_AMOUNT_PER_BLOCK, _value);
        IAAAAMint(IConfig(config).mint()).sync();
    }

    function setShareToken(address _shareToken) onlyOwner external {
        IAAAAShare(IConfig(config).share()).setShareToken(_shareToken);
    }

  }