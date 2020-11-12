// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// File: contracts/vaults/ValueVaultMaster.sol

/*
 * Here we have a list of constants. In order to get access to an address
 * managed by ValueVaultMaster, the calling contract should copy and define
 * some of these constants and use them as keys.
 * Keys themselves are immutable. Addresses can be immutable or mutable.
 *
 * Vault addresses are immutable once set, and the list may grow:
 * K_VAULT_WETH = 0;
 * K_VAULT_ETH_USDC_UNI_V2_LP = 1;
 * K_VAULT_ETH_WBTC_UNI_V2_LP = 2;
 */

/*
 * ValueVaultMaster manages all the vaults and strategies of our Value Vaults system.
 */
contract ValueVaultMaster {
    address public governance;

    address public bank;
    address public minorPool;
    address public profitSharer;

    address public govToken; // VALUE
    address public yfv; // When harvesting, convert some parts to YFV for govVault
    address public usdc; // we only used USDC to estimate APY

    address public govVault; // YFV -> VALUE, vUSD, vETH and 6.7% profit from Value Vaults
    address public insuranceFund = 0xb7b2Ea8A1198368f950834875047aA7294A2bDAa; // set to Governance Multisig at start
    address public performanceReward = 0x7Be4D5A99c903C437EC77A20CB6d0688cBB73c7f; // set to deploy wallet at start

    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public govVaultProfitShareFee = 670; // 6.7% | VIP-1 (https://yfv.finance/vip-vote/vip_1)
    uint256 public gasFee = 50; // 0.5% at start and can be set by governance decision

    uint256 public minStakeTimeToClaimVaultReward = 24 hours;

    mapping(address => bool) public isVault;
    mapping(uint256 => address) public vaultByKey;

    mapping(address => bool) public isStrategy;
    mapping(uint256 => address) public strategyByKey;
    mapping(address => uint256) public strategyQuota;

    constructor(address _govToken, address _yfv, address _usdc) public {
        govToken = _govToken;
        yfv = _yfv;
        usdc = _usdc;
        governance = tx.origin;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    // Immutable once set.
    function setBank(address _bank) external {
        require(msg.sender == governance, "!governance");
        require(bank == address(0));
        bank = _bank;
    }

    // Mutable in case we want to upgrade the pool.
    function setMinorPool(address _minorPool) external {
        require(msg.sender == governance, "!governance");
        minorPool = _minorPool;
    }

    // Mutable in case we want to upgrade this module.
    function setProfitSharer(address _profitSharer) external {
        require(msg.sender == governance, "!governance");
        profitSharer = _profitSharer;
    }

    // Mutable, in case governance want to upgrade VALUE to new version
    function setGovToken(address _govToken) external {
        require(msg.sender == governance, "!governance");
        govToken = _govToken;
    }

    // Immutable once added, and you can always add more.
    function addVault(uint256 _key, address _vault) external {
        require(msg.sender == governance, "!governance");
        require(vaultByKey[_key] == address(0), "vault: key is taken");

        isVault[_vault] = true;
        vaultByKey[_key] = _vault;
    }

    // Mutable and removable.
    function addStrategy(uint256 _key, address _strategy) external {
        require(msg.sender == governance, "!governance");
        isStrategy[_strategy] = true;
        strategyByKey[_key] = _strategy;
    }

    // Set 0 to disable quota (no limit)
    function setStrategyQuota(address _strategy, uint256 _quota) external {
        require(msg.sender == governance, "!governance");
        strategyQuota[_strategy] = _quota;
    }

    function removeStrategy(uint256 _key) external {
        require(msg.sender == governance, "!governance");
        isStrategy[strategyByKey[_key]] = false;
        delete strategyByKey[_key];
    }

    function setGovVault(address _govVault) public {
        require(msg.sender == governance, "!governance");
        govVault = _govVault;
    }

    function setInsuranceFund(address _insuranceFund) public {
        require(msg.sender == governance, "!governance");
        insuranceFund = _insuranceFund;
    }

    function setPerformanceReward(address _performanceReward) public{
        require(msg.sender == governance, "!governance");
        performanceReward = _performanceReward;
    }

    function setGovVaultProfitShareFee(uint256 _govVaultProfitShareFee) public {
        require(msg.sender == governance, "!governance");
        govVaultProfitShareFee = _govVaultProfitShareFee;
    }

    function setGasFee(uint256 _gasFee) public {
        require(msg.sender == governance, "!governance");
        gasFee = _gasFee;
    }

    function setMinStakeTimeToClaimVaultReward(uint256 _minStakeTimeToClaimVaultReward) public {
        require(msg.sender == governance, "!governance");
        minStakeTimeToClaimVaultReward = _minStakeTimeToClaimVaultReward;
    }

    /**
     * This function allows governance to take unsupported tokens out of the contract.
     * This is in an effort to make someone whole, should they seriously mess up.
     * There is no guarantee governance will vote to return these.
     * It also allows for removal of airdropped tokens.
     */
    function governanceRecoverUnsupported(IERC20x _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(to, amount);
    }
}

interface IERC20x {
    function transfer(address recipient, uint256 amount) external returns (bool);
}