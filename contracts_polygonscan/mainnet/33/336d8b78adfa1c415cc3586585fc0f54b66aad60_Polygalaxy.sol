// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./Ownable.sol";
import "./ERC20.sol"; 

// Polygalaxy Token ($GALAXY)
contract Polygalaxy is ERC20, Ownable {
    // Burn address
    address private constant BURN = 0x000000000000000000000000000000000000dEaD;
    // Transfer tax 
    // + Max transfer tax rate
    uint16 public constant MAXIMUM_TRANSFER_GALAXY_TAX = 1200;
    // + transfer tax rate
    uint16 public transferGalaxyTax = 1200;
    // Burn rate % of transfer tax.
    uint16 public burnRate = 20;
    // VaultCash rate % of (transferGalaxyTax - burnRate).
    uint16 public vaultRate = 60;
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
    // Automatic swap and liquify enabled
    bool public swapAndVaultEnabled = true;
    // Min amount to Vaults. (default 500 GALAXY)
    uint256 public minAmountToVaultCash = 15000 * 10**18;
    // The swap router, modifiable. Will be changed to Polygalaxy's router when our own AMM release
    IUniswapV2Router02 public polygalaxySwapRouter;
    // The trading pair
    address public polygalaxySwapPair;
    // In swap and liquify
    bool private _inSwapAndVaultCash;

    address public marketingWallet;
    address public vaultCashWallet;
    IERC20  private WMATIC;
    // 
    uint256 public launchedAt;
    // Events
    event TransferTaxRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event BurnRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event SwapAndVaultEnabledUpdated(address indexed operator, bool enabled);
    event MinAmountToVaultCashUpdated(address indexed operator, uint256 previousAmount, uint256 newAmount);
    event PolygalaxySwapRouterUpdated(address indexed operator, address indexed router, address indexed pair);

    modifier lockTheSwap {
        _inSwapAndVaultCash = true;
        _;
        _inSwapAndVaultCash = false;
    }

    modifier transferTaxFree {
        uint16 _transferTaxRate = transferGalaxyTax;
        transferGalaxyTax = 0;
        _;
        transferGalaxyTax = _transferTaxRate;
    }

    /**
     * @notice Constructs the Polygalaxy Token contract.
     */
    constructor() public {
        polygalaxySwapRouter = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        polygalaxySwapPair   = IUniswapV2Factory(polygalaxySwapRouter.factory()).createPair(polygalaxySwapRouter.WETH(), address(this));
        WMATIC               = IERC20(polygalaxySwapRouter.WETH());
        
        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[BURN] = true;

        launchedAt = block.number + 30*60*24;
        mint(msg.sender, 150000 * 10**18);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
    
    /// @dev overrides transfer function to meet tokenomics of GALAXY
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        checkLaunched(sender);
        
        // swap and vault cash  
        if (swapAndVaultEnabled && !_inSwapAndVaultCash && sender != polygalaxySwapPair) {
            swapAndVaultCash();
        }

        if (recipient == BURN || sender == polygalaxySwapPair || transferGalaxyTax == 0) {
            super._transfer(sender, recipient, amount);
        } else if (_excludedFromAntiWhale[sender] || _excludedFromAntiWhale[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            // default tax is 12% of every transfer
            uint256 taxAmount = amount.mul(transferGalaxyTax).div(10000);
            uint256 burnAmount = taxAmount.mul(burnRate).div(100);
            uint256 cashAmount = taxAmount.sub(burnAmount);
            require(taxAmount == burnAmount + cashAmount, "GALAXY::transfer: Burn value invalid");

            // default 95% of transfer sent to recipient
            uint256 sendAmount = amount.sub(taxAmount);
            require(amount == sendAmount + taxAmount, "GALAXY::transfer: Tax value invalid");

            super._transfer(sender, BURN, burnAmount);
            super._transfer(sender, address(this), cashAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }

    /// @dev Swap and VaultCash & Marketing
    function swapAndVaultCash() private lockTheSwap transferTaxFree {
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= minAmountToVaultCash) {
            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;

            // swap tokens for ETH
            swapTokensForEth(minAmountToVaultCash);
            
            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);

            // add VaultCash & Marketing GALAXY 
            addVaultCashOfGalaxyAndFee(newBalance);
             
        }
    }

    /// @dev Swap tokens for eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the polygalaxySwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = polygalaxySwapRouter.WETH();

        _approve(address(this), address(polygalaxySwapRouter), tokenAmount);

        // make the swap
        polygalaxySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }

    function addVaultCashOfGalaxyAndFee(uint256 amount) private {
        (bool success,) = payable(polygalaxySwapRouter.WETH()).call{value: amount, gas: 300000}("");
        if(success) { 
            uint256 v = amount.mul(vaultRate).div(100);
            WMATIC.transfer(vaultCashWallet, v);
            WMATIC.transfer(marketingWallet, amount.sub(v));
            emit AmountMatic(vaultCashWallet, amount);
        }
    }
    
    event AmountMatic(address wallet, uint256 amount);
    
    function checkLaunched(address sender) internal view {
        require(launchedAt < block.number || _excludedFromAntiWhale[sender], "Pre-Launch Protection");
    }

    function setGalaxyWalletSettings(address _marketingWallet, address _vaultCashWallet) external onlyOperator {
        require(_marketingWallet != address(0), "GalaxyWalletSettings: _marketingWallet is not zero address");
        require(_vaultCashWallet != address(0), "GalaxyWalletSettings: _vaultCashWallet is not zero address");
        marketingWallet = _marketingWallet;
        vaultCashWallet = _vaultCashWallet;
        _excludedFromAntiWhale[_marketingWallet] = true;
        _excludedFromAntiWhale[_vaultCashWallet] = true;
    }
    
    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    // To receive MATIC from QuickSwapRouter when swapping
    receive() external payable {}

    /**
     * @dev Update the transfer tax rate.
     * Can only be called by the current operator.
     */
    function updateTransferTaxRate(uint16 _transferTaxRate) external onlyOperator {
        require(_transferTaxRate <= MAXIMUM_TRANSFER_GALAXY_TAX, "GALAXY::updateTransferTaxRate: Transfer tax rate must not exceed the maximum rate.");
        emit TransferTaxRateUpdated(msg.sender, transferGalaxyTax, _transferTaxRate);
        transferGalaxyTax = _transferTaxRate;
    }

    /**
     * @dev Update the burn rate.
     * Can only be called by the current operator.
     */
    function updateBurnRate(uint16 _burnRate) external onlyOperator {
        require(_burnRate <= 50, "GALAXY::updateBurnRate: Burn rate must not exceed the maximum rate.");
        emit BurnRateUpdated(msg.sender, burnRate, _burnRate);
        burnRate = _burnRate;
    }

    /**
     * @dev Update the vault rate & marketing rate.
     * Can only be called by the current operator.
     */
    function updateVaultRate(uint16 _vaultRate) external onlyOperator {
        require(_vaultRate <= 100, "GALAXY::updateVaultMarketingRate: rate invalid value!");
        vaultRate = _vaultRate;
    } 
    
    /**
     * @dev Update the min amount to liquify.
     * Can only be called by the current operator.
     */
    function updateMinAmountToVaultCash(uint256 _minAmount) external onlyOperator {
        require(_minAmount > totalSupply().div(10000), "");
        emit MinAmountToVaultCashUpdated(msg.sender, minAmountToVaultCash, _minAmount);
        minAmountToVaultCash = _minAmount;
    }

    /**
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account, bool _excluded) external onlyOperator {
        _excludedFromAntiWhale[_account] = _excluded;
    }

    /**
     * @dev Update the swapAndLiquifyEnabled.
     * Can only be called by the current operator.
     */
    function updateSwapAndVaultEnabled(bool _enabled) external onlyOperator {
        emit SwapAndVaultEnabledUpdated(msg.sender, _enabled);
        swapAndVaultEnabled = _enabled;
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updatePolygalaxySwapRouter(address _router) external onlyOperator {
        polygalaxySwapRouter = IUniswapV2Router02(_router);
        polygalaxySwapPair = IUniswapV2Factory(polygalaxySwapRouter.factory()).getPair(address(this), polygalaxySwapRouter.WETH());
        require(polygalaxySwapPair != address(0), "GALAXY::updatePolygalaxySwapRouter: Invalid pair address.");
        emit PolygalaxySwapRouterUpdated(msg.sender, address(polygalaxySwapRouter), polygalaxySwapPair);
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GALAXY::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "GALAXY::delegateBySig: invalid nonce");
        require(now <= expiry, "GALAXY::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "GALAXY::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying GALAXY (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "GALAXY::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}