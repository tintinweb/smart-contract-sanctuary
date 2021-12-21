// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BEP20.sol";
import "./IUniswapV2Router02.sol";

// UFXToken with Governance.
contract UFXToken is BEP20 {
    
    uint256 public initialCap = 400000 * 10**18; //INMUTABLE
    // Supply capped at 69MM
    uint256 public cap = 20000000 * 10**18; //INMUTABLE

    // The operator is NOT the owner, is the operator of the machine
    address private _operator;

    // Addresses excluded from fees
    mapping (address => bool) private _isExcludedFromFee;

    // Addresses that are excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;

    // In swap and liquify
    bool private _inSwapAndLiquify;

    // Max holding rate in basis point. (default is 3% of total supply)
    // Transfers cannot result in a balance higher than the maxholdingrate*total supply
    // Except if the owner (masterchef) is interacting. Users would not be able to harvest rewards in edge cases
    // such as if an user has more than maxholding to harvest without this exception.
    // Addresses in the antiwhale exclude list can receive more too. This is for the liquidity pools and the token itself
    uint16 public maxHoldingRate = 300; // INMUTABLE 

    // Transfer tax rate in basis points. (default 3%)
    uint16 public transferTaxRate = 300; // INMUTABLE

    // Liquify rate % of transfer tax. (default 3% x 93% = 2.79% of total amount).
    uint16 public liquifyRate = 93; // INMUTABLE

    // UFXdev Fee address
    address public devAddress;

    // Min amount to liquify. (default 100 UFX)
    uint256 public minAmountToLiquify = 100 ether; // INMUTABLE

    // PCS LP Token Address
    address public lpToken; // ONLY ONCE!

    // Automatic swap and liquify enabled
    bool public swapAndLiquifyEnabled = true; // INMUTABLE

    // PCS Router Address
    IUniswapV2Router02 private PCSRouter; // INMUTABLE

    // Trading bool
    bool private tradingOpen; 

    // Enable MaxHolding mechanism
    bool private _maxHoldingEnable = true; // INMUTABLE

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD; // INMUTABLE

    // Events before Governance
    event MaxHoldingRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event LPTokenTransferred(address indexed previousLpToken, address indexed newLpToken);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SwapAndLiquifyEnabledUpdated(address indexed operator, bool enabled);
    event MaxHoldingEnableUpdated(address indexed operator, bool enabled);
    event PCSRouterTransferred(address indexed oldPCSRouter, address indexed newPCSRouter);
    event UpdateDevAddress(address indexed devAddress);

    // Operator CAN do modifier
    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    // Lock the swap on SwapAndLiquify
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    // Nulled Transfer Fee while SwapAndLiquify
    modifier transferTaxFree {
        uint16 _transferTaxRate = transferTaxRate;
        transferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
    }

    /// @dev Apply antiwhale only if the owner (masterchef) isn't interacting.
    /// If the receiver isn't excluded from antiwhale,
    /// check if it's balance is over the max Holding otherwise the second condition would end up with an underflow
    /// and that it's balance + the amount to receive doesn't exceed the maxholding. This doesn't account for transfer tax.
    /// if any of those two condition apply, the transfer will be rejected with the correct error message
    modifier antiWhale(address sender, address recipient, uint256 amount) {
        // Is maxHolding enabled?
        if(_maxHoldingEnable) {
            if (maxHolding() > 0 && sender != owner() && recipient != owner()) {
                if ( _excludedFromAntiWhale[recipient] == false ) {
                    require(amount <= maxHolding() - balanceOf(recipient) && balanceOf(recipient) <= maxHolding(), "UFX::antiWhale: Transfer amount would result in a balance bigger than the maxHoldingRate");
                }
            }
        }
        
        _;
    }

    /**z
     * @notice Constructs the UFX token contract.
     */
    constructor(address _devAddress, address _PCSRouter) public BEP20("United Farmers Xchange", "UFX") {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
        
        _mint(msg.sender, initialCap);
        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        devAddress = address(_devAddress);
        PCSRouter = IUniswapV2Router02(_PCSRouter);

    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(ufxSupply().add(_amount) <= cap, "UFX: cap exceeded");
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    /// @dev overrides transfer function to meet tokenomics of UFX
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        // Pre-flight checks
        require(amount > 0, "Transfer amount must be greater than zero");

        // swap and liquify
        if (
            swapAndLiquifyEnabled == true
            && _inSwapAndLiquify == false
            && address(PCSRouter) != address(0)
            && lpToken != address(0)
            && sender != lpToken
            && sender != owner()
        ) {
            swapAndLiquify();
        }

        if (sender == owner() || recipient == owner() || transferTaxRate == 0 || _isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {

            require(tradingOpen == true, "Trading is not yet open.");

            // default tax is 6% of every transfer
            uint256 taxAmount = amount.mul(transferTaxRate).div(10000);
            uint256 liquidityAmount = taxAmount.mul(liquifyRate).div(100);
            uint256 devFeeAmount = taxAmount.sub(liquidityAmount);
            require(taxAmount == devFeeAmount.add(liquidityAmount), "UFX::transfer: DevFeeAmount or LiquidityAmount value invalid");

            // default 94% of transfer sent to recipient
            uint256 sendAmount = amount.sub(taxAmount);
            require(amount == sendAmount.add(taxAmount), "UFX::transfer: Tax value invalid");

            // Distributing UFXs (DevAddress, Liquify, Recipient)
            super._transfer(sender, devAddress, devFeeAmount);
            super._transfer(sender, address(this), liquidityAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;           
        }
    }

    /// @dev Swap and liquify
    function swapAndLiquify() private lockTheSwap transferTaxFree {
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if (contractTokenBalance >= minAmountToLiquify) {
            // only min amount to liquify
            uint256 liquifyAmount = minAmountToLiquify;

            // split the liquify amount into halves
            uint256 half = liquifyAmount.div(2);
            uint256 otherHalf = liquifyAmount.sub(half);

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

    /// @dev Swap tokens for eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the UFX pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PCSRouter.WETH();

        _approve(address(this), address(PCSRouter), tokenAmount);

        // make the swap
        PCSRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
        _approve(address(this), address(PCSRouter), tokenAmount);

        // add the liquidity
        PCSRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            operator(),
            block.timestamp
        );
    }

    /**
     * @dev Returns the max holding amount.
     */
    function maxHolding() public view returns (uint256) {
        return cap.mul(maxHoldingRate).div(10000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    /** NO NEED TO CHANGE MAX HOLDING ENABLED
     * @dev Enable / Disable Max Holding Mechanism.
     * Can only be called by the current operator.
     */
    function updateMaxHoldingEnable(bool _enabled) public onlyOperator {
        emit MaxHoldingEnableUpdated(msg.sender, _enabled);
        _maxHoldingEnable = _enabled;
    }

    /** NO NEED TO CHANGE PCS ROUTER
     * @dev Transfers PCSRouter of the contract to a new address (`newPCSRouter`).
     * Can only be called by the current operator.
     */
    function transferPCSRouter(address newPCSRouter) public onlyOperator {
        require(newPCSRouter != address(0), "UFX::transferPCSRouter: new PCSRouter is the zero address");
        emit PCSRouterTransferred(address(PCSRouter), newPCSRouter);
        PCSRouter = IUniswapV2Router02(newPCSRouter);
    }

    /** 
     * @dev Update the dev Address.
     * Can only be called by the current operator.
     */
    function updateDevAddress(address _devAddress) public onlyOperator {
        require(_devAddress != address(0), "UFX: dev address is zero");
        emit UpdateDevAddress(msg.sender);
        devAddress = _devAddress;
    }

    /** NO NEED TO CHANGE SWAP AND LIQUIFY
     * @dev Update the swapAndLiquifyEnabled.
     * Can only be called by the current operator.
     */
    // function updateSwapAndLiquifyEnabled(bool _enabled) public onlyOperator {
    //     emit SwapAndLiquifyEnabledUpdated(msg.sender, _enabled);
    //     swapAndLiquifyEnabled = _enabled;
    // }

    /** NO NEED TO CHANGE MAX_HOLDING_RATE
     * @dev Update the max holding rate.
     * Can only be called by the current operator.
     */
    // function updateMaxHoldingRate(uint16 _maxHoldingRate) public onlyOperator {
    //     require(_maxHoldingRate >= 100, "UFX::updateMaxHoldingRate: Max holding rate must not be below the minimum rate.");
    //     emit MaxHoldingRateUpdated(msg.sender, _maxHoldingRate, _maxHoldingRate);
    //     maxHoldingRate = _maxHoldingRate;
    // }

    /** 
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account) public onlyOperator {
        _excludedFromAntiWhale[_account] = true;
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view returns (address) {
        return _operator;
    }

    // /**
    //  * @dev Returns the bep token owner.
    //  */
    // function getOwner() external override view returns (address) {
    //     return owner();
    // }

    // Return actual supply of rice
    function ufxSupply() public view returns (uint256) {
        return totalSupply().sub(balanceOf(BURN_ADDRESS));
    }

    /**
     * @dev Transfers/Sets lpToken address to a new address (`newLpToken`).
     * Can only be called by the current operator.
     */
    function transferLpToken(address newLpToken) public onlyOperator {
        // Can transfer LP only once!
        require(lpToken == address(0), "UFX: LP Token Transfer can be only be set once");
        emit LPTokenTransferred(lpToken, newLpToken);
        lpToken = newLpToken;
    }

    /**
     * @dev Transfers operator of the contract to a new account (`newOperator`).
     * Can only be called by the current operator.
     */
    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "UFX::transferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }
    
    /**
     * @dev Open trading (PCS) onlyOperator
     */
    function openTrading(bool bOpen) public onlyOperator {
        // Can open trading only once!
        tradingOpen = bOpen;
    }

    /**
     * @dev Add to exclude from fee.
     * Can only be called by the current operator.
     */
    function setExcludeFromFee(address _account) public onlyOperator {
        _isExcludedFromFee[_account] = true;
    }

    // To receive BNB from SwapRouter when swapping
    receive() external payable {}

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
        require(signatory != address(0), "UFX::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "UFX::delegateBySig: invalid nonce");
        require(now <= expiry, "UFX::delegateBySig: signature expired");
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
        require(blockNumber < block.number, "UFX::getPriorVotes: not yet determined");

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
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying UFXs (not scaled);
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
        uint32 blockNumber = safe32(block.number, "UFX::_writeCheckpoint: block number exceeds 32 bits");

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