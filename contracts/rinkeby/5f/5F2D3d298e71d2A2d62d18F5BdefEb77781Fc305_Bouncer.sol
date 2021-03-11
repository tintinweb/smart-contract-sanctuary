// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import './lib/SafeMath.sol';

/**
 * @title BankrollToken
 * @dev Token representing share of bankroll for Archer DAO
 * ERC-20 with add-ons to allow for offchain signing
 * See EIP-712, EIP-2612, and EIP-3009 for details
 */
contract BankrollToken {
    using SafeMath for uint256;

    /// @notice EIP-20 token name for this token
    string public constant name = "Archer Bankroll Token";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "ARCH-B";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint256 public totalSupply;

    /// @notice Underlying asset being bankrolled
    address public asset;

    /// @notice Recipient of bankroll
    address public recipient;

    /// @notice Address which may mint/burn tokens
    address public supplyManager;

    /// @notice Official record of token balances for each account
    mapping(address => uint256) public balanceOf;

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice The version number for this token
    uint8 public constant version = 1;

    /// @notice The EIP-712 version hash
    /// keccak256("1");
    bytes32 public constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    // @notice The EIP-712 typehash for the contract's domain
    /// keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @notice The EIP-712 typehash for permit (EIP-2612)
    /// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint256) public nonces;

    /// @notice An event that's emitted when the supplyManager address is changed
    event SupplyManagerChanged(address indexed oldManager, address indexed newManager);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlySupplyManager {
        require(msg.sender == supplyManager, "only supply manager");
        _;
    }

    /**
     * @notice Construct a new Arch bankroll token
     * @param _asset Bankroll asset
     * @param _recipient Address receiving the bankroll
     * @param _supplyManager The address with minting/burning ability
     */
    constructor(
        address _asset,
        address _recipient,
        address _supplyManager
    ) {
        asset = _asset;
        recipient = _recipient;
        supplyManager = _supplyManager;
        emit SupplyManagerChanged(address(0), _supplyManager);
    }

    /**
     * @notice Change the supplyManager address
     * @param newSupplyManager The address of the new supply manager
     * @return true if successful
     */
    function setSupplyManager(address newSupplyManager) external onlySupplyManager returns (bool) {
        emit SupplyManagerChanged(supplyManager, newSupplyManager);
        supplyManager = newSupplyManager;
        return true;
    }

    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param amount The number of tokens to be minted
     * @return Boolean indicating success of mint
     */
    function mint(address dst, uint256 amount) external onlySupplyManager returns (bool) {
        require(dst != address(0), "ABT::mint: cannot transfer to the zero address");

        // mint the amount
        _mint(dst, amount);
        return true;
    }

    /**
     * @notice Burn tokens
     * @param src The account that will burn tokens
     * @param amount The number of tokens to be burned
     * @return Boolean indicating success of burn
     */
    function burn(address src, uint256 amount) external onlySupplyManager returns (bool) {
        require(src != address(0), "ABT::burn: cannot transfer from the zero address");
        
        // burn the amount
        _burn(src, amount);
        return true;
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     * and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * It is recommended to use increaseAllowance and decreaseAllowance instead
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Increase the allowance by a given amount
     * @param spender Spender's address
     * @param addedValue Amount of increase in allowance
     * @return True if successful
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _increaseAllowance(msg.sender, spender, addedValue);
        return true;
    }

    /**
     * @notice Decrease the allowance by a given amount
     * @param spender Spender's address
     * @param subtractedValue Amount of decrease in allowance
     * @return True if successful
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        _decreaseAllowance(msg.sender, spender, subtractedValue);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spender
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param value The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "ABT::permit: signature expired");

        bytes32 encodeData = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        _validateSignedData(owner, encodeData, v, r, s);

        _approve(owner, spender, value);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowance[src][spender];

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = spenderAllowance.sub(
                amount,
                "ABT::transferFrom: transfer amount exceeds allowance"
            );
            allowance[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice EIP-712 Domain separator
     * @return Separator
     */
    function getDomainSeparator() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                VERSION_HASH,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @notice Recovers address from signed data and validates the signature
     * @param signer Address that signed the data
     * @param encodeData Data signed by the address
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function _validateSignedData(address signer, bytes32 encodeData, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDomainSeparator(),
                encodeData
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "ABT::validateSig: invalid signature");
    }

    /**
     * @notice Approval implementation
     * @param owner The address of the account which owns tokens
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ABT::_approve: approve from the zero address");
        require(spender != address(0), "ABT::_approve: approve to the zero address");
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _increaseAllowance(
        address owner,
        address spender,
        uint256 addedValue
    ) internal {
        _approve(owner, spender, allowance[owner][spender].add(addedValue));
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) internal {
        _approve(
            owner,
            spender,
            allowance[owner][spender].sub(
                subtractedValue,
                "ABT::_decreaseAllowance: decreased allowance below zero"
            )
        );
    }

    /**
     * @notice Transfer implementation
     * @param from The address of the account which owns tokens
     * @param to The address of the account which is receiving tokens
     * @param value The number of tokens that are being transferred
     */
    function _transferTokens(address from, address to, uint256 value) internal {
        require(to != address(0), "ABT::_transferTokens: cannot transfer to the zero address");

        balanceOf[from] = balanceOf[from].sub(
            value,
            "ABT::_transferTokens: transfer exceeds from balance"
        );
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @notice Mint implementation
     * @param to The address of the account which is receiving tokens
     * @param value The number of tokens that are being minted
     */
    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    /**
     * @notice Burn implementation
     * @param from The address of the account which owns tokens
     * @param value The number of tokens that are being burned
     */
    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(
            value,
            "ABT::_burn: burn amount exceeds from balance"
        );
        totalSupply = totalSupply.sub(
            value,
            "ABT::_burn: burn amount exceeds total supply"
        );
        emit Transfer(from, address(0), value);
    }

    /**
     * @notice Current id of the chain where this contract is deployed
     * @return Chain id
     */
    function _getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IVotingPower.sol";
import "./interfaces/IDispatcherFactory.sol";
import "./interfaces/IDispatcher.sol";
import "./lib/AccessControl.sol";
import "./lib/ReentrancyGuard.sol";
import "./lib/SafeMath.sol";
import "./BankrollToken.sol";

/**
 * @title Bouncer
 * @dev Used as an interface to provide bankroll to Dispatchers on the Archer network
 */
contract Bouncer is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;

    /// @notice Dispatcher Factory
    IDispatcherFactory public dispatcherFactory;

    /// @notice Voting Power Contract
    IVotingPower public votingPowerContract;

    /// @notice Global cap on % of network bankroll any one entity can provide (measured in bips: 10,000 bips = 1% of bankroll requested by the network)
    uint32 public globalMaxContributionPct;

    /// @notice Per Dispatcher cap on % of bankroll any one entity can provide (measured in bips: 10,000 bips = 1% of bankroll requested by the Dispatcher)
    uint32 public dispatcherMaxContributionPct;

    /// @notice Amount of voting power required to bankroll on the network
    uint256 public requiredVotingPower;

    /// @notice Total amount of bankroll provided to the network via this contract
    uint256 public totalAmountDeposited;

    /// @notice Mapping of bankroll Dispatcher > asset > bankroll token
    mapping(address => mapping(address => BankrollToken)) public bankrollTokens;

    /// @notice Mapping of Dispatcher address > bankroll provided
    mapping(address => uint256) public amountDeposited;

    /// @notice Admin role to manage Bouncer
    bytes32 public constant BOUNCER_ADMIN_ROLE = keccak256("BOUNCER_ADMIN_ROLE");

     /// @notice Modifier to restrict functions to only users that have been added as Bouncer admin
    modifier onlyAdmin() {
        require(hasRole(BOUNCER_ADMIN_ROLE, msg.sender), "Caller must have BOUNCER_ADMIN_ROLE role");
        _;
    }

    /// @notice Event emitted when Dispatcher Factory contract address is changed
    event DispatcherFactoryChanged(address indexed oldAddress, address indexed newAddress);
    
    /// @notice Event emitted when Voting Power contract address is changed
    event VotingPowerChanged(address indexed oldAddress, address indexed newAddress);
    
    /// @notice Event emitted when required voting power to bankroll network is changed
    event RequiredVotingPowerChanged(uint256 oldVotingPower, uint256 newVotingPower);
    
    /// @notice Event emitted when global cap is changed
    event GlobalMaxChanged(uint32 oldPct, uint32 newPct);

    /// @notice Event emitted when per dispatcher cap is changed
    event DispatcherMaxChanged(uint32 oldPct, uint32 newPct);

    /// @notice Event emitted when a new Dispatcher/asset is added to the bankroll program
    event BankrollTokenCreated(address indexed tokenAddress, address indexed asset, address dispatcher);

    /// @notice Event emitted when bankroll is provided to a dispatcher
    event BankrollProvided(address indexed dispatcher, address indexed sender, address indexed account, address asset, uint256 amount);
    
    /// @notice Event emitted when bankroll is removed from a dispatcher
    event BankrollRemoved(address indexed dispatcher, address indexed sender, address indexed account, address asset, uint256 amount);

    /**
     * @notice Construct a new Bouncer contract
     * @param _dispatcherFactory Dispatcher Factory address
     * @param _votingPower VotingPower address
     * @param _globalMaxContributionPct Global cap on % of bankroll any one account can provide
     * @param _dispatcherMaxContributionPct Per Dispatcher cap on % of bankroll any one account can provide
     * @param _requiredVotingPower Amount of voting power required for account to provide bankroll
     * @param _bouncerAdmin Admin of Bouncer contract
     * @param _roleAdmin Admin of Bouncer admin role
     */
    constructor(
        address _dispatcherFactory,
        address _votingPower,
        uint32 _globalMaxContributionPct,
        uint32 _dispatcherMaxContributionPct,
        uint256 _requiredVotingPower,
        address _bouncerAdmin,
        address _roleAdmin
    ) {
        dispatcherFactory = IDispatcherFactory(_dispatcherFactory);
        votingPowerContract = IVotingPower(_votingPower);
        globalMaxContributionPct = _globalMaxContributionPct;
        dispatcherMaxContributionPct = _dispatcherMaxContributionPct;
        requiredVotingPower = _requiredVotingPower;
        _setupRole(BOUNCER_ADMIN_ROLE, _bouncerAdmin);
        _setupRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
    }

    /// @notice Receive function to allow contract to accept ETH
    receive() external payable {}
    
    /// @notice Fallback function in case receive function is not matched
    fallback() external payable {}

    /**
     * @notice Amount of voting power a given account has currently
     * @param account Address of account
     * @return amount Amount of voting power
     */
    function votingPower(address account) public view returns (uint256 amount) {
        return votingPowerContract.balanceOf(account);
    }

    /**
     * @notice Maximum amount of bankroll any one account can provide to the network as a whole
     * @return amount Max deposit amount
     */
    function maxDepositPerAccount() public view returns(uint256 amount) {
        return totalBankrollRequested().mul(globalMaxContributionPct).div(1000000);
    }

    /**
     * @notice Total amount of bankroll requested by all of the Dispatchers on the network
     * @return amount Total bankroll requested
     */
    function totalBankrollRequested() public view returns (uint256 amount) {
        address[] memory allDispatchers = dispatcherFactory.dispatchers();
        for(uint i = 0; i < allDispatchers.length; i++) {
            IDispatcher dispatcher = IDispatcher(allDispatchers[i]);
            if (dispatcher.isWhitelistedLP(address(this)) && bankrollTokens[allDispatchers[i]][address(0)] != BankrollToken(0)) {
                amount = amount + bankrollRequested(dispatcher);
            }
        }
    }

    /**
     * @notice Total amount of bankroll requested by all of the Dispatchers on the network that has not yet been provided
     * @return amount Total bankroll available for deposit
     */
    function totalBankrollAvailable() public view returns (uint256 amount) {
        address[] memory allDispatchers = dispatcherFactory.dispatchers();
        for(uint i = 0; i < allDispatchers.length; i++) {
            IDispatcher dispatcher = IDispatcher(allDispatchers[i]);
            amount = amount + bankrollAvailable(dispatcher);
        }
    }

    /**
     * @notice All of the Dispatchers on the network that have bankroll available that has not yet been provided
     * @return dispatchers Array of dispatchers that have bankroll requests available
     */
    function dispatchersWithBankrollAvailable() public view returns (address[] memory dispatchers) {
        address[] memory allDispatchers = dispatcherFactory.dispatchers();
        address[] memory filteredDispatchers = new address[](allDispatchers.length);
        uint numAvailable = 0;
        for(uint i = 0; i < allDispatchers.length; i++) {
            IDispatcher dispatcher = IDispatcher(allDispatchers[i]);
            if(bankrollAvailable(dispatcher) > 0) {
                filteredDispatchers[numAvailable] = allDispatchers[i];
                numAvailable++;
            }
        }
        dispatchers = new address[](numAvailable);
        for(uint i = 0; i < numAvailable; i++) {
            dispatchers[i] = filteredDispatchers[i];
        }
        return dispatchers;
    }

    /**
     * @notice Total amount of bankroll requested by the given Dispatcher
     * @return amount Bankroll requested by Dispatcher
     */
    function bankrollRequested(IDispatcher dispatcher) public view returns (uint256 amount) {
        return dispatcher.MAX_LIQUIDITY();
    }

   /**
     * @notice Amount of bankroll provided to given Dispatcher
     * @return amount Bankroll provided to Dispatcher
     */
    function bankrollProvided(IDispatcher dispatcher) public view returns (uint256 amount) {
        return dispatcher.totalLiquidity();
    }
    
    /**
     * @notice Amount of bankroll available to provide to given Dispatcher
     * @return amount Bankroll available for Dispatcher
     */
    function bankrollAvailable(IDispatcher dispatcher) public view returns (uint256 amount) {
        if (!dispatcher.isWhitelistedLP(address(this))) {
            return 0;
        } 
        if (bankrollTokens[address(dispatcher)][address(0)] == BankrollToken(0)) {
            return 0;
        }

        return bankrollRequested(dispatcher).sub(bankrollProvided(dispatcher));
    }

    /**
     * @notice Max amount of bankroll any one account can provide to given Dispatcher
     * @return amount Max bankroll per account
     */
    function maxBankrollPerAccount(IDispatcher dispatcher) public view returns (uint256 amount) {
        return bankrollRequested(dispatcher).mul(dispatcherMaxContributionPct).div(1000000);
    }

    /**
     * @notice Total amount of remaining bankroll account can provide to network
     * @return amount Bankroll available to account
     */
    function amountAvailableToDeposit(address account) public view returns (uint256 amount) {
        if (votingPower(account) < requiredVotingPower) {
            return 0;
        }

        uint256 existingDeposit = amountDeposited[account];
        uint256 maxDeposit = maxDepositPerAccount();
        if(maxDeposit <= existingDeposit) {
            return 0;
        }
        return maxDeposit.sub(existingDeposit);
    }

    /**
     * @notice Amount of remaining bankroll account can provide to given Dispatcher
     * @return amount Bankroll available to account for given Dispatcher
     */
    function amountAvailableToBankroll(address account, address dispatcher) public view returns (uint256 amount) {
        if (dispatcherFactory.exists(account)) {
            return 0;
        }

        if (votingPower(account) < requiredVotingPower) {
            return 0;
        }

        uint256 availableDeposit = amountAvailableToDeposit(account);
        if (availableDeposit == 0) {
            return 0;
        }
        uint256 dispatcherBankrollAvailable = bankrollAvailable(IDispatcher(dispatcher));
        if (dispatcherBankrollAvailable == 0) {
            return 0;
        }

        uint256 maxBankroll = maxBankrollPerAccount(IDispatcher(dispatcher));
        BankrollToken bToken = bankrollTokens[dispatcher][address(0)];
        uint256 existingBankroll = bToken.balanceOf(account);

        if (maxBankroll <= existingBankroll) {
            return 0;
        }
        uint256 availableBankroll = maxBankroll.sub(existingBankroll);

        if (availableDeposit >= dispatcherBankrollAvailable) {
            return availableBankroll <= dispatcherBankrollAvailable ? availableBankroll : dispatcherBankrollAvailable;
        } else {
            return availableBankroll <= availableDeposit ? availableBankroll : availableDeposit;
        }
    }

    /**
     * @notice Gets all balances relevant to determining whether a given user can bankroll a dispatcher
     * @return balances 
     * 1) dispatcher bankroll available 
     * 2) min voting power 
     * 3) user voting power 
     * 4) network deposit max 
     * 5) account amount deposited 
     * 6) max bankroll per account for dispatcher 
     * 7) bankroll already provided by user to this dispatcher
     */
    function bankrollBalances(address account, address dispatcher) external view returns (uint256[7] memory balances) {
        BankrollToken bToken = bankrollTokens[dispatcher][address(0)];
        balances[0] = bankrollAvailable(IDispatcher(dispatcher));
        balances[1] = requiredVotingPower;
        balances[2] = votingPower(account);
        balances[3] = maxDepositPerAccount();
        balances[4] = amountDeposited[account];
        balances[5] = maxBankrollPerAccount(IDispatcher(dispatcher));
        balances[6] = bToken.balanceOf(account);
    }

    /**
     * @notice Function to allow a dispatcher to join the bankroll program
     * @param dispatcher Dispatcher address
     */
    function join(address dispatcher) external {
        if(bankrollTokens[dispatcher][address(0)] == BankrollToken(0)) {
            BankrollToken bToken = new BankrollToken(address(0), dispatcher, address(this));
            bankrollTokens[dispatcher][address(0)] = bToken;
            emit BankrollTokenCreated(address(bToken), address(0), dispatcher);
        }
    }

    /**
     * @notice Admin function to migrate token to new Bouncer
     * @param token the token
     * @param newBouncer Bouncer address
     */
    function migrate(BankrollToken token, address newBouncer) external onlyAdmin {
        require(newBouncer != address(0), "cannot migrate to zero");
        token.setSupplyManager(newBouncer);
    }

    /**
     * @notice Provide ETH bankroll to Dispatcher
     * @param dispatcher Dispatcher address
     */
    function provideETHBankroll(address dispatcher) external payable nonReentrant {
        require(bankrollTokens[dispatcher][address(0)] != BankrollToken(0), "create bankroll token first");
        require(amountAvailableToBankroll(tx.origin, dispatcher) >= msg.value, "amount exceeds max");
        require(!dispatcherFactory.exists(msg.sender), "dispatchers cannot provide bankroll");
        amountDeposited[tx.origin] = amountDeposited[tx.origin].add(msg.value);
        totalAmountDeposited = totalAmountDeposited.add(msg.value);
        IDispatcher(dispatcher).provideETHLiquidity{value:msg.value}();
        BankrollToken bToken = bankrollTokens[dispatcher][address(0)];
        bToken.mint(tx.origin, msg.value);
        emit BankrollProvided(dispatcher, msg.sender, tx.origin, address(0), msg.value);
    }

    /**
     * @notice Remove ETH bankroll from Dispatcher
     * @param dispatcher Dispatcher address
     * @param amount Amount of bankroll to remove
     */
    function removeETHBankroll(address dispatcher, uint256 amount) external nonReentrant {
        require(bankrollTokens[dispatcher][address(0)] != BankrollToken(0), "create bankroll token first");
        BankrollToken bToken = bankrollTokens[dispatcher][address(0)];
        require(bToken.balanceOf(tx.origin) >= amount, "not enough bankroll tokens");
        require(amountDeposited[tx.origin] >= amount, "amount exceeds deposit");
        require(totalAmountDeposited >= amount, "amount exceeds total");
        amountDeposited[tx.origin] = amountDeposited[tx.origin].sub(amount);
        totalAmountDeposited = totalAmountDeposited.sub(amount);
        IDispatcher(dispatcher).removeETHLiquidity(amount);
        bToken.burn(tx.origin, amount);
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "Transfer failed");
        emit BankrollRemoved(dispatcher, msg.sender, tx.origin, address(0), amount);
    }

    /**
     * @notice Set Dispatcher Factory address
     * @dev Only Bouncer admin can call
     * @param factoryAddress Dispatcher Factory address
     */
    function setDispatcherFactory(address factoryAddress) external onlyAdmin {
        emit DispatcherFactoryChanged(address(dispatcherFactory), factoryAddress);
        dispatcherFactory = IDispatcherFactory(factoryAddress);
    }

    /**
     * @notice Set VotingPower address
     * @dev Only Bouncer admin can call
     * @param votingPowerAddress VotingPower address
     */
    function setVotingPower(address votingPowerAddress) external onlyAdmin {
        emit VotingPowerChanged(address(votingPowerContract), votingPowerAddress);
        votingPowerContract = IVotingPower(votingPowerAddress);
    }

    /**
     * @notice Set voting power required by users to provide bankroll
     * @dev Only Bouncer admin can call
     * @param newVotingPower minimum voting power
     */
    function setRequiredVotingPower(uint256 newVotingPower) external onlyAdmin {
        emit RequiredVotingPowerChanged(requiredVotingPower, newVotingPower);
        requiredVotingPower = newVotingPower;
    }

    /**
     * @notice Set global max % of network bankroll any one account can provide
     * @dev Only Bouncer admin can call
     * @param newPct new global cap %
     */
    function setGlobalMaxContributionPct(uint32 newPct) external onlyAdmin {
        emit GlobalMaxChanged(globalMaxContributionPct, newPct);
        globalMaxContributionPct = newPct;
    }

    /**
     * @notice Set per Dispatcher max % of bankroll any one account can provide
     * @dev Only Bouncer admin can call
     * @param newPct new per Dispatcher cap %
     */
    function setDispatcherMaxContributionPct(uint32 newPct) external onlyAdmin {
        emit DispatcherMaxChanged(dispatcherMaxContributionPct, newPct);
        dispatcherMaxContributionPct = newPct;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IQueryEngine.sol";

interface IDispatcher {
    function version() external view returns (uint8);
    function lpBalances(address) external view returns (uint256);
    function totalLiquidity() external view returns (uint256);
    function MAX_LIQUIDITY() external view returns (uint256);
    function tokenAllowAll(address[] memory tokensToApprove, address spender) external;
    function tokenAllow(address[] memory tokensToApprove, uint256[] memory approvalAmounts, address spender) external;
    function rescueTokens(address[] calldata tokens, uint256 amount) external;
    function setMaxETHLiquidity(uint256 newMax) external;
    function provideETHLiquidity() external payable;
    function removeETHLiquidity(uint256 amount) external;
    function withdrawEth(uint256 amount) external;
    function estimateQueryCost(bytes memory script, uint256[] memory inputLocations) external;
    function queryEngine() external view returns (IQueryEngine);
    function isTrader(address addressToCheck) external view returns (bool);
    function makeTrade(bytes memory executeScript, uint256 ethValue) external;
    function makeTrade(bytes memory executeScript, uint256 ethValue, uint256 blockDeadline) external;
    function makeTrade(bytes memory executeScript, uint256 ethValue, uint256 minTimestamp, uint256 maxTimestamp) external;
    function makeTrade(bytes memory queryScript, uint256[] memory queryInputLocations, bytes memory executeScript, uint256[] memory executeInputLocations, uint256 targetPrice, uint256 ethValue) external;
    function makeTrade(bytes memory queryScript, uint256[] memory queryInputLocations, bytes memory executeScript, uint256[] memory executeInputLocations, uint256 targetPrice, uint256 ethValue, uint256 blockDeadline) external;
    function makeTrade(bytes memory queryScript, uint256[] memory queryInputLocations, bytes memory executeScript, uint256[] memory executeInputLocations, uint256 targetPrice, uint256 ethValue, uint256 minTimestamp, uint256 maxTimestamp) external;
    function TRADER_ROLE() external view returns (bytes32);
    function MANAGE_LP_ROLE() external view returns (bytes32);
    function WHITELISTED_LP_ROLE() external view returns (bytes32);
    function APPROVER_ROLE() external view returns (bytes32);
    function WITHDRAW_ROLE() external view returns (bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function isApprover(address addressToCheck) external view returns(bool);
    function isWithdrawer(address addressToCheck) external view returns(bool);
    function isLPManager(address addressToCheck) external view returns(bool);
    function isWhitelistedLP(address addressToCheck) external view returns(bool);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    event MaxLiquidityUpdated(address indexed asset, uint256 indexed newAmount, uint256 oldAmount);
    event LiquidityProvided(address indexed asset, address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed asset, address indexed provider, uint256 amount);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IDispatcherFactory {
    function version() external view returns (uint8);
    function dispatchers() external view returns (address[] memory);
    function exists(address dispatcher) external view returns (bool);
    function numDispatchers() external view returns (uint256);
    function createNewDispatcher(address queryEngine, address roleManager, address lpManager, address withdrawer, address trader, address supplier, uint256 initialMaxLiquidity, address[] memory lpWhitelist) external returns (address);
    function addDispatchers(address[] memory dispatcherContracts) external;
    function removeDispatcher(address dispatcherContract) external;
    function DISPATCHER_ADMIN_ROLE() external view returns (bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    event DispatcherCreated(address indexed dispatcher, uint8 indexed version, address queryEngine, address roleManager, address lpManager, address withdrawer, address trader, address supplier, uint256 initialMaxLiquidity, bool lpWhitelist);
    event DispatcherAdded(address indexed dispatcher);
    event DispatcherRemoved(address indexed dispatcher);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IQueryEngine {
    function getPrice(address contractAddress, bytes memory data) external view returns (bytes memory);
    function queryAllPrices(bytes memory script, uint256[] memory inputLocations) external view returns (bytes memory);
    function query(bytes memory script, uint256[] memory inputLocations) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IVotingPower {
    function balanceOf(address account) external view returns (uint256);
    function balanceOfAt(address account, uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./EnumerableSet.sol";
import "./Address.sol";
import "./Context.sol";

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity ^0.7.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}