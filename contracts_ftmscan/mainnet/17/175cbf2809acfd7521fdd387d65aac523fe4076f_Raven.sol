// SPDX-License-Identifier: MIT

import "./BEP20.sol";
import "./SafeBEP20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

pragma solidity 0.6.12;

contract Raven is BEP20 {
    
    using SafeBEP20 for IBEP20;

    // Transfer tax rate in basis points. (default 2%)
    uint16 public transferTaxRate = 200;
    // Max transfer tax rate: 10%.
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 1000;
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    //  SCARE token for automated buyback and burn
    address public constant SCARE = 0x46e1Ee17f51c52661D04238F1700C547dE3B84A1; // Scarecrow Token
    address public constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // wFTM

    // Max transfer amount rate in basis points. (default is 100% of total supply)
    uint16 public maxTransferAmountRate = 10000;
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
    // Automatic swap and liquify enabled
    bool public swapAndLiquifyEnabled = false;
    // Min amount to liquify. (default 0.1 RAVEN (100000000000000000))
    uint256 public minAmountToLiquify = 100000000000000000;
    // The swap router, modifiable. Can be changed to Scarecrow Finance's router when our own AMM release
    // SpookySwap Router: 0xF491e7B69E4244ad4002BC14e878a34207E38c29
    IUniswapV2Router02 public ravenSwapRouter;
    // The trading pair
    address public ravenSwapPair;
    // In swap and liquify
    bool private _inSwapAndLiquify;
    // Addresses that are excluded from transfer tax (e.g. presale, masterchef contract)
    mapping(address => bool) private _excludedFromTransferTax;

    // The operator to update the transfer tax rate
    address private _operator;

    // Events
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event TransferTaxRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event BurnRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event MaxTransferAmountRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event SwapAndLiquifyEnabledUpdated(address indexed operator, bool enabled);
    event MinAmountToLiquifyUpdated(address indexed operator, uint256 previousAmount, uint256 newAmount);
    event ScarecrowFinanceRouterUpdated(address indexed operator, address indexed router, address indexed pair);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event BurnContractUpdated(address indexed oldBurnContract, address indexed newBurnContract);

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    modifier antiWhale(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount() > 0) {
            if (
                _excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {
                require(amount <= maxTransferAmount(), "RAVEN::antiWhale: Transfer amount exceeds the maxTransferAmount");
            }
        }
        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier transferTaxFree {
        uint16 _transferTaxRate = transferTaxRate;
        transferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @notice Constructs the RavenToken contract.
     */
    constructor() public BEP20("Raven", "RAVEN") {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);

        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[BURN_ADDRESS] = true;
        _excludedFromTransferTax[msg.sender] = true;
        _excludedFromTransferTax[BURN_ADDRESS] = true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }


    /// @dev overrides transfer function to meet tokenomics of RAVEN
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        // swap and liquify
        if (
            swapAndLiquifyEnabled == true
            && _inSwapAndLiquify == false
            && address(ravenSwapRouter) != address(0)
            && ravenSwapPair != address(0)
            && sender != ravenSwapPair
            && sender != owner()
        ) {
            swapAndLiquify();
        }

        if (transferTaxRate == 0 || _excludedFromTransferTax[sender] || _excludedFromTransferTax[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            // default tax is 2% of every transfer
            uint256 taxAmount = amount.mul(transferTaxRate).div(10000);

            uint256 liquidityAmount = taxAmount;
            require(taxAmount == liquidityAmount, "RAVEN::transfer: Burn value invalid");

            // default 98% of transfer sent to recipient
            uint256 sendAmount = amount.sub(taxAmount);
            require(amount == sendAmount + taxAmount, "RAVEN::transfer: Tax value invalid");

            super._transfer(sender, address(this), liquidityAmount);    // from user to contract for tax liquidity amount
            super._transfer(sender, recipient, sendAmount);             //  form user to recipient for amount.sub(tax)
            amount = sendAmount;
        }
    }

    /// @dev Swap and liquify
    function swapAndLiquify() private lockTheSwap transferTaxFree {
        uint256 contractTokenBalance = balanceOf(address(this));    // declaring balance of raven
        uint256 maxTransferAmount = maxTransferAmount();    //  max amount it can transfer
        contractTokenBalance = contractTokenBalance > maxTransferAmount ? maxTransferAmount : contractTokenBalance; //  if the balance is more than the max transfer amt, declare balance = max tx

        if (contractTokenBalance >= minAmountToLiquify) {
            // only min amount to liquify
            uint256 liquifyAmount = minAmountToLiquify;

            // split amount into fifths
            // 4/5 used to buyback Scarecrow
            // 1/5 used to make Raven LP 
            uint256 fifth = liquifyAmount.div(5);
            uint256 buyBackAmount = liquifyAmount.sub(fifth);

            // buy and burn scare
            triggerScareBuyback(buyBackAmount);

            uint256 half = fifth.div(2);
            uint256 otherHalf = fifth.sub(half);
            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;

            // swap tokens for ETH
            swapTokensForEth(half);

            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);

            // add liquidity
            addLiquidity(otherHalf, newBalance);

            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }

    function triggerScareBuyback(uint256 autoBuybackAmount) internal {
        buyTokens(autoBuybackAmount, BURN_ADDRESS);     // hardcoded that SCARE buyback goes to Burn Address
    }

    function buyTokens(uint256 amount, address to) private {
        address[] memory path = new address[](3);
        path[0] = address(this);                    // from RAVEN
        path[1] = ravenSwapRouter.WETH();           // to WETH
        path[2] = SCARE;                            // to SCARE

        _approve(address(this), address(ravenSwapRouter), amount);
        IBEP20(WFTM).safeIncreaseAllowance(address(ravenSwapRouter), amount);

        ravenSwapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,              //      accept any amount
            path,
            to,             //         burnAddress
            block.timestamp
        );
    }

    /// @dev Swap tokens for eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the ravenSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ravenSwapRouter.WETH();

        _approve(address(this), address(ravenSwapRouter), tokenAmount);

        // make the swap
        ravenSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Add liquidity
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(ravenSwapRouter), tokenAmount);

        // add the liquidity
        ravenSwapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            operator(),
            block.timestamp
        );
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }


    /**
     * @dev Returns if the address is excluded from transferTax or not.
     */
    function isExcludedFromTransferTax(address _account) public view returns (bool) {
        return _excludedFromTransferTax[_account];
    }

    // To receive FTM from ravenSwapRouter when swapping
    receive() external payable {}

    /**
     * @dev Update the transfer tax rate.
     * Can only be called by the current operator.
     */
    function updateTransferTaxRate(uint16 _transferTaxRate) public onlyOperator {
        require(_transferTaxRate <= MAXIMUM_TRANSFER_TAX_RATE, "RAVEN::updateTransferTaxRate: Transfer tax rate must not exceed the maximum rate.");
        emit TransferTaxRateUpdated(msg.sender, transferTaxRate, _transferTaxRate);
        transferTaxRate = _transferTaxRate;
    }



    /**
     * @dev Update the max transfer amount rate.
     * Can only be called by the current operator.
     */
    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOperator {
        // Maximum Transfer Amount Rate
        require(_maxTransferAmountRate <= 10000, "RAVEN::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
        // Minimum Transfer Amount Rate so that operator cannot set max transfer to 0.001% of total supply
        require(_maxTransferAmountRate >= 30, "RAVEN::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the minimum rate.");
        emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
        maxTransferAmountRate = _maxTransferAmountRate;
    }

    /**
     * @dev Update the min amount to liquify.
     * Can only be called by the current operator.
     */
    function updateMinAmountToLiquify(uint256 _minAmount) public onlyOperator {
        emit MinAmountToLiquifyUpdated(msg.sender, minAmountToLiquify, _minAmount);
        minAmountToLiquify = _minAmount;
    }

    /**
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOperator {
        _excludedFromAntiWhale[_account] = _excluded;
    }

    /**
     * @dev Exclude or include an address from transferTax.
     * Can only be called by the current operator.
     */
    function setExcludedFromTransferTax(address _account, bool _excluded) public onlyOperator {
        _excludedFromTransferTax[_account] = _excluded;
    }

    /**
     * @dev Update the swapAndLiquifyEnabled.
     * Can only be called by the current operator.
     */
    function updateSwapAndLiquifyEnabled(bool _enabled) public onlyOperator {
        emit SwapAndLiquifyEnabledUpdated(msg.sender, _enabled);
        swapAndLiquifyEnabled = _enabled;
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the current operator.
     */
    function updateScarecrowFinanceRouter(address _router) public onlyOperator {
        ravenSwapRouter = IUniswapV2Router02(_router);
        ravenSwapPair = IUniswapV2Factory(ravenSwapRouter.factory()).getPair(address(this), ravenSwapRouter.WETH());
        require(ravenSwapPair != address(0), "RAVEN::updateScarecrowFinanceRouter: Invalid pair address.");
        emit ScarecrowFinanceRouterUpdated(msg.sender, address(ravenSwapRouter), ravenSwapPair);
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "RAVEN::transferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
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
        require(signatory != address(0), "RAVEN::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "RAVEN::delegateBySig: invalid nonce");
        require(now <= expiry, "RAVEN::delegateBySig: signature expired");
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
        require(blockNumber < block.number, "RAVEN::getPriorVotes: not yet determined");

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

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying RAVENs (not scaled);
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
        uint32 blockNumber = safe32(block.number, "RAVEN::_writeCheckpoint: block number exceeds 32 bits");

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