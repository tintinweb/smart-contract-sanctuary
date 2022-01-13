//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IEternalFund.sol";
import "../interfaces/IEternalTreasury.sol";
import "../interfaces/IEternalFactory.sol";
import "../interfaces/IEternalStorage.sol";
import "../inheritances/OwnableEnhanced.sol";

/**
 * @title Contract for the Eternal Token (ETRNL)
 * @author Nobody (me)
 * (credits to OpenZeppelin for initial framework, RFI for the reflection token framework and COMP for governance-related functions)
 * @notice The Eternal Token contract holds all the deflationary, burn, reflect, funding and auto-liquidity provision mechanics
 */
contract EternalToken is IERC20, IERC20Metadata, OwnableEnhanced {

/////–––««« Variables: Interfaces and Hashes »»»––––\\\\\

    // The Eternal shared storage interface
    IEternalStorage public immutable eternalStorage;
    // The Eternal treasury interface
    IEternalTreasury private eternalTreasury;
    // The Eternal factory interface
    IEternalFactory private eternalFactory;

    // The keccak256 hash of this contract's address
    bytes32 public immutable entity;

/////–––««« Variables: Hidden Mappings »»»––––\\\\\
/**
    // The reflected balances used to track reward-accruing users' total balances
    mapping (address => uint256) reflectedBalances

    // The true balances used to track non-reward-accruing addresses' total balances
    mapping (address => uint256) trueBalances

    // Keeps track of whether an address is excluded from rewards
    mapping (address => bool) isExcludedFromRewards

    // Keeps track of whether an address is excluded from transfer fees
    mapping (address => bool) isExcludedFromFees
    
    // Keeps track of how much an address allows any other address to spend on its behalf
    mapping (address => mapping (address => uint256)) allowances
*/

/////–––««« Variables: Token Information »»»––––\\\\\

    // Keeps track of all reward-excluded addresses
    bytes32 public immutable excludedAddresses;
    // The true total ETRNL supply
    bytes32 public immutable totalTokenSupply;
    // The total ETRNL supply after taking reflections into account
    bytes32 public immutable totalReflectedSupply;
    // Threshold at which the contract swaps its ETRNL balance to provide liquidity (0.1% of total supply by default)
    bytes32 public immutable tokenLiquidityThreshold;

/////–––««« Variables: Token Fee Rates »»»––––\\\\\

    // The percentage of the fee, taken at each transaction, that is stored in the Eternal Treasury (x 10 ** 5)
    bytes32 public immutable fundingRate;
    // The percentage of the fee, taken at each transaction, that is burned (x 10 ** 5)
    bytes32 public immutable burnRate;
    // The percentage of the fee, taken at each transaction, that is redistributed to holders (x 10 ** 5)
    bytes32 public immutable redistributionRate;
    // The percentage of the fee taken at each transaction, that is used to auto-lock liquidity (x 10 ** 5)
    bytes32 public immutable liquidityProvisionRate;

/////–––««« Constructors & Initializers »»»––––\\\\\

    constructor (address _eternalStorage) {
        // Set initial storage and fund addresses
        eternalStorage = IEternalStorage(_eternalStorage);

        // Initialize keccak256 hashes
        entity = keccak256(abi.encodePacked(address(this)));
        totalTokenSupply = keccak256(abi.encodePacked("totalTokenSupply"));
        totalReflectedSupply = keccak256(abi.encodePacked("totalReflectedSupply"));
        tokenLiquidityThreshold = keccak256(abi.encodePacked("tokenLiquidityThreshold"));
        fundingRate = keccak256(abi.encodePacked("fundingRate"));
        burnRate = keccak256(abi.encodePacked("burnRate"));
        redistributionRate = keccak256(abi.encodePacked("redistributionRate"));
        liquidityProvisionRate = keccak256(abi.encodePacked("liquidityProvisionRate"));
        excludedAddresses = keccak256(abi.encodePacked("excludedAddresses"));
    } 

    /**
     * @notice Initialize supplies and routers and create a pair. Mints total supply to the contract deployer. 
     * Exclude some addresses from fees and/or rewards. Sets initial rate values.
     */
    function initialize(address _eternalTreasury, address _factory, address _fund, address _offering, address _seedLock, address _privLock) external onlyAdmin {
        eternalTreasury = IEternalTreasury(_eternalTreasury);
        eternalFactory = IEternalFactory(_factory);
        // The largest possible number in a 256-bit integer
        uint256 max = ~uint256(0);

        // Initialize total supplies and liquidity threshold
        eternalStorage.setUint(entity, totalTokenSupply, (10 ** 10) * (10 ** 18));
        uint256 rSupply = (max - (max % ((10 ** 10) * (10 ** 18))));
        eternalStorage.setUint(entity, totalReflectedSupply, rSupply);
        eternalStorage.setUint(entity, tokenLiquidityThreshold, (10 ** 10) * (10 ** 18) / 1000);
        // Distribute supply (10% to send to FundLock contracts for vesting, 5% to send for pre-seed investors, 42.5% to Treasury and 42.5% to the IGO contract)
        eternalStorage.setUint(entity, keccak256(abi.encodePacked("reflectedBalances", _msgSender())), (rSupply / 100) * 5);
        eternalStorage.setUint(entity, keccak256(abi.encodePacked("reflectedBalances", _seedLock)), (rSupply / 100) * 5);
        eternalStorage.setUint(entity, keccak256(abi.encodePacked("reflectedBalances", _privLock)), (rSupply / 100) * 5);
        eternalStorage.setUint(entity, keccak256(abi.encodePacked("reflectedBalances", _offering)), (rSupply / 1000) * 425);
        eternalStorage.setUint(entity, keccak256(abi.encodePacked("reflectedBalances", _eternalTreasury)), (rSupply / 1000) * 425);

        // Exclude this contract from rewards and fees
        excludeFromReward(address(this));
        eternalStorage.setBool(entity, keccak256(abi.encodePacked("isExcludedFromFees", address(this))), true);
        // Exclude the burn address from rewards
        excludeFromReward(address(0));
        // Exclude the Eternal Treasury from fees
        eternalStorage.setBool(entity, keccak256(abi.encodePacked("isExcludedFromFees", _eternalTreasury)), true);
        // Exclude the Eternal Offering from fees and rewards
        eternalStorage.setBool(entity, keccak256(abi.encodePacked("isExcludedFromFees", _offering)), true);
        excludeFromReward(_offering);
        // Exclude the two Fundlock contracts from fees and rewards
        excludeFromReward(_seedLock);
        excludeFromReward(_privLock);
        eternalStorage.setBool(entity, keccak256(abi.encodePacked("isExcludedFromFees", _seedLock)), true);
        eternalStorage.setBool(entity, keccak256(abi.encodePacked("isExcludedFromFees", _privLock)), true);

        // Set initial rates for fees
        eternalStorage.setUint(entity, fundingRate, 500);
        eternalStorage.setUint(entity, burnRate, 500);
        eternalStorage.setUint(entity, redistributionRate, 2500);
        eternalStorage.setUint(entity, liquidityProvisionRate, 1500);

        // Designate the Eternal Fund
        attributeFundRights(_fund);
    }

/////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @notice View the name of the token. 
     * @return The token name
     */
    function name() external pure override returns (string memory) {
        return "Eternal Token";
    }

    /**
     * @notice View the token ticker.
     * @return The token ticker
     */
    function symbol() external pure override returns (string memory) {
        return "ETRNL";
    }

    /**
     * @notice View the maximum number of decimals for the Eternal token.
     * @return The number of decimals
     */
    function decimals() external pure override returns (uint8) {
        return 18;
    }
    
    /**
     * @notice View the total supply of the Eternal token.
     * @return Returns the total ETRNL supply.
     */
    function totalSupply() external view override returns (uint256){
        return eternalStorage.getUint(entity, totalTokenSupply);
    }

    /**
     * @notice View the balance of a given user's address.
     * @param account The address of the user
     * @return The balance of the account
     */
    function balanceOf(address account) public view override returns (uint256){
        if (eternalStorage.getBool(entity, keccak256(abi.encodePacked("isExcludedFromRewards", account)))) {
            return eternalStorage.getUint(entity, keccak256(abi.encodePacked("trueBalances", account)));
        }
        return convertFromReflectedToTrueAmount(eternalStorage.getUint(entity, keccak256(abi.encodePacked("reflectedBalances", account))));
    }

    /**
     * @notice View the allowance of a given owner address for a given spender address.
     * @param owner The address of whom we are checking the allowance of
     * @param spender The address of whom we are checking the allowance for
     * @return The allowance of the owner for the spender
     */
    function allowance(address owner, address spender) external view override returns (uint256){
        return eternalStorage.getUint(entity, keccak256(abi.encodePacked("allowances", owner, spender)));
    }

    /**
     * @notice Computes the current rate used to inter-convert from the mathematically reflected space to the "true" or total space.
     * @return The ratio of net reflected ETRNL to net total ETRNL
     */
    function getReflectionRate() public view returns (uint256) {
        (uint256 netReflectedSupply, uint256 netTokenSupply) = getNetSupplies();
        return netReflectedSupply / netTokenSupply;
    }

/////–––««« IERC20/ERC20 functions »»»––––\\\\\

    /**
     * @notice Tranfers a given amount of ETRNL to a given receiver address.
     * @param recipient The destination to which the ETRNL are to be transferred
     * @param amount The amount of ETRNL to be transferred
     * @return True if the transfer is successful.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool){
        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    /**
     * @notice Sets the allowance for a given address to a given amount.
     * @param spender The address of whom we are changing the allowance for
     * @param amount The amount we are changing the allowance to
     * @return True if the approval is successful.
     */
    function approve(address spender, uint256 amount) external override returns (bool){
        _approve(_msgSender(), spender, amount);

        return true;
    }

    /**
     * @notice Transfers a given amount of ETRNL for a given sender address to a given recipient address.
     * @param sender The address whom we withdraw the ETRNL from
     * @param recipient The address which shall receive the ETRNL
     * @param amount The amount of ETRNL which is being transferred
     * @return True if the transfer and approval are both successful.
     *
     * Requirements:
     * 
     * - The caller must be allowed to spend (at least) the given amount on the sender's behalf
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = eternalStorage.getUint(entity, keccak256(abi.encodePacked("allowances", sender, _msgSender())));
        require(currentAllowance >= amount, "Not enough allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @notice Sets the allowance of a given owner address for a given spender address to a given amount.
     * @param owner The adress of whom we are changing the allowance of
     * @param spender The address of whom we are changing the allowance for
     * @param amount The amount which we change the allowance to
     *
     * Requirements:
     * 
     * - Approve amount must be less than or equal to the actual total token supply
     * - Owner and spender cannot be the zero address
     */
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        eternalStorage.setUint(entity, keccak256(abi.encodePacked("allowances", owner, spender)), amount);

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Transfers a given amount of ETRNL from a given sender's address to a given recipient's address.
     * @param sender The address of whom the ETRNL will be transferred from
     * @param recipient The address of whom the ETRNL will be transferred to
     * @param amount The amount of ETRNL to be transferred
     * 
     * Requirements:
     * 
     * - Sender or recipient cannot be the zero address
     * - Transferred amount must be greater than zero and less than or equal to the sender's balance
     */
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(balanceOf(sender) >= amount, "Transfer amount exceeds balance");
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must exceed zero");

        _beforeTokenTransfer(sender, recipient, amount);

        // We only take fees if both the sender and recipient are susceptible to fees
        bool takeFee;
        {
        bool senderExcludedFromFees = eternalStorage.getBool(entity, keccak256(abi.encodePacked("isExcludedFromFees", sender)));
        bool recipientExcludedFromFees = eternalStorage.getBool(entity, keccak256(abi.encodePacked("isExcludedFromFees", recipient)));
        takeFee = (!senderExcludedFromFees && !recipientExcludedFromFees);
        }   

        (uint256 reflectedAmount, uint256 netReflectedTransferAmount, uint256 netTransferAmount) = getValues(amount, takeFee);
        
        // Always update the reflected balances of sender and recipient
        {
        bytes32 reflectedSenderBalance = keccak256(abi.encodePacked("reflectedBalances", sender));
        bytes32 reflectedRecipientBalance = keccak256(abi.encodePacked("reflectedBalances", recipient));
        uint256 senderReflectedBalance = eternalStorage.getUint(entity, reflectedSenderBalance);
        uint256 recipientReflectedBalance = eternalStorage.getUint(entity, reflectedRecipientBalance);
        eternalStorage.setUint(entity, reflectedSenderBalance, senderReflectedBalance - reflectedAmount);
        eternalStorage.setUint(entity, reflectedRecipientBalance, recipientReflectedBalance + netReflectedTransferAmount);
        }

        // Update true balances for any non-reward-accruing accounts
        if (eternalStorage.getBool(entity, keccak256(abi.encodePacked("isExcludedFromRewards", sender)))) {
            bytes32 trueSenderBalance = keccak256(abi.encodePacked("trueBalances", sender));
            uint256 senderTrueBalance = eternalStorage.getUint(entity, trueSenderBalance);
            eternalStorage.setUint(entity, trueSenderBalance, senderTrueBalance - amount);
        }
        if (eternalStorage.getBool(entity, keccak256(abi.encodePacked("isExcludedFromRewards", recipient)))) {
            bytes32 trueRecipientBalance = keccak256(abi.encodePacked("trueBalances", recipient));
            uint256 recipientTrueBalance = eternalStorage.getUint(entity, trueRecipientBalance);
            eternalStorage.setUint(entity, trueRecipientBalance, recipientTrueBalance + netTransferAmount);
        }
        emit Transfer(sender, recipient, netTransferAmount);


        // Adjust the total reflected supply for the new fees and update the 24h transaction count
        // If the sender or recipient are excluded from fees, we ignore the fee altogether
        if (takeFee) {
            _takeFees(amount, reflectedAmount, sender);
        }
    }

    /**
     * @notice Apply the effects of all four token fees on a given transaction and update the 24h transaction count
     * @param amount The amount of ETRNL of the specified transaction
     * @param reflectedAmount The reflected amount of ETRNL of the specified transaction
     * @param sender The address of the sender of the specified transaction
     */
    function _takeFees(uint256 amount, uint256 reflectedAmount, address sender) private {
        // Update the 24h transaction count
        eternalFactory.updateCounters(amount);
        // Perform a burn based on the burn rate 
        uint256 deflationRate = eternalStorage.getUint(entity, burnRate);
        _burn(address(this), amount * deflationRate / 100000, reflectedAmount * deflationRate / 100000);
        // Redistribute based on the redistribution rate 
        uint256 reflectedSupply = eternalStorage.getUint(entity, totalReflectedSupply);
        uint256 rewardRate = eternalStorage.getUint(entity, redistributionRate);
        eternalStorage.setUint(entity, totalReflectedSupply, reflectedSupply - (reflectedAmount * rewardRate / 100000));
        // Store ETRNL away in the treasury based on the funding rate
        bytes32 treasuryBalance = keccak256(abi.encodePacked("reflectedBalances", address(eternalTreasury)));
        uint256 fundBalance = eternalStorage.getUint(entity, treasuryBalance);
        uint256 fundRate = eternalStorage.getUint(entity, fundingRate);
        eternalStorage.setUint(entity, treasuryBalance, fundBalance + (reflectedAmount * fundRate / 100000));
        // Provide liquidity to the ETRNL/AVAX pair on TraderJoe based on the liquidity provision rate
        uint256 liquidityRate = eternalStorage.getUint(entity, liquidityProvisionRate);
        storeLiquidityFunds(sender, amount * liquidityRate / 100000, reflectedAmount * liquidityRate / 100000);
    }
    
    /**
     * @notice Burns the specified amount of ETRNL for a given sender by sending them to the 0x0 address.
     * @param sender The specified address burning ETRNL
     * @param amount The amount of ETRNL being burned
     * @param reflectedAmount The reflected equivalent of ETRNL being burned
     */
    function _burn(address sender, uint256 amount, uint256 reflectedAmount) private { 
        bytes32 burnReflectedBalance = keccak256(abi.encodePacked("reflectedBalances", address(0)));
        bytes32 burnTrueBalance = keccak256(abi.encodePacked("trueBalances", address(0)));

        // Send tokens to the 0x0 address
        uint256 reflectedZeroBalance = eternalStorage.getUint(entity, burnReflectedBalance);
        uint256 trueZeroBalance = eternalStorage.getUint(entity, burnTrueBalance);
        eternalStorage.setUint(entity, burnReflectedBalance, reflectedZeroBalance + reflectedAmount);
        eternalStorage.setUint(entity, burnTrueBalance, trueZeroBalance + amount);

        // Update supplies accordingly
        uint256 tokenSupply = eternalStorage.getUint(entity, totalTokenSupply);
        uint256 reflectedSupply = eternalStorage.getUint(entity, totalReflectedSupply);
        eternalStorage.setUint(entity, totalTokenSupply, tokenSupply - amount);
        eternalStorage.setUint(entity, totalReflectedSupply, reflectedSupply - reflectedAmount);

        emit Transfer(sender, address(0), amount);
    }

/////–––««« Reward-redistribution functions »»»––––\\\\\

    /**
     * @notice Translates a given reflected sum of ETRNL into the true amount of ETRNL it represents based on the current reserve rate.
     * @param reflectedAmount The specified reflected sum of ETRNL
     * @return The true amount of ETRNL representing by its reflected amount
     */
    function convertFromReflectedToTrueAmount(uint256 reflectedAmount) private view returns(uint256) {
        uint256 currentRate =  getReflectionRate();

        return reflectedAmount / currentRate;
    }

    /**
     * @notice Compute the reflected and net reflected transferred amounts and the net transferred amount from a given amount of ETRNL.
     * @param trueAmount The specified amount of ETRNL
     * @return The reflected amount, the net reflected transfer amount, the actual net transfer amount, and the total reflected fees
     */
    function getValues(uint256 trueAmount, bool takeFee) private view returns (uint256, uint256, uint256) {
        
        uint256 liquidityRate = eternalStorage.getUint(entity, liquidityProvisionRate);
        uint256 deflationRate = eternalStorage.getUint(entity, burnRate);
        uint256 fundRate = eternalStorage.getUint(entity, fundingRate);
        uint256 rewardRate = eternalStorage.getUint(entity, redistributionRate);

        uint256 feeRate = takeFee ? (liquidityRate + deflationRate + fundRate + rewardRate) : 0;

        // Calculate the total fees and transfered amount after fees
        uint256 totalFees = (trueAmount * feeRate) / 100000;
        uint256 netTransferAmount = trueAmount - totalFees;

        // Calculate the reflected amount, reflected total fees and reflected amount after fees
        uint256 currentRate = getReflectionRate();
        uint256 reflectedAmount = trueAmount * currentRate;
        uint256 reflectedTotalFees = totalFees * currentRate;
        uint256 netReflectedTransferAmount = reflectedAmount - reflectedTotalFees;
        
        return (reflectedAmount, netReflectedTransferAmount, netTransferAmount);
    }

    /**
     * @notice Computes the net reflected and total token supplies (adjusted for non-reward-accruing accounts).
     * @return The adjusted reflected supply and adjusted total token supply
     */
    function getNetSupplies() private view returns(uint256, uint256) {
        uint256 brutoReflectedSupply = eternalStorage.getUint(entity, totalReflectedSupply);
        uint256 brutoTokenSupply = eternalStorage.getUint(entity, totalTokenSupply);
        uint256 netReflectedSupply = brutoReflectedSupply;
        uint256 netTokenSupply = brutoTokenSupply;

        for (uint256 i = 0; i < eternalStorage.lengthAddress(excludedAddresses); i++) {
            // Failsafe for non-reward-accruing accounts owning too many tokens (highly unlikely; nonetheless possible)
            address excludedAddress = eternalStorage.getAddressArrayValue(excludedAddresses, i);
            uint256 reflectedBalance = eternalStorage.getUint(entity, keccak256(abi.encodePacked("reflectedBalances", excludedAddress)));
            uint256 trueBalance = eternalStorage.getUint(entity, keccak256(abi.encodePacked("trueBalances", excludedAddress)));
            if (reflectedBalance > netReflectedSupply || trueBalance > netTokenSupply) {
                return (brutoReflectedSupply, brutoTokenSupply);
            }
            // Subtracting each excluded account from both supplies yields the adjusted supplies
            netReflectedSupply -= reflectedBalance;
            netTokenSupply -= trueBalance;
        }
        // In case there are no tokens left in circulation for reward-accruing accounts
        if (netTokenSupply == 0 || netReflectedSupply < (brutoReflectedSupply / brutoTokenSupply)){
            return (brutoReflectedSupply, brutoTokenSupply);
        }

        return (netReflectedSupply, netTokenSupply);
    }

    /**
     * @notice Updates the contract's balance regarding the liquidity provision fee for a given transaction's amount.
     * If the contract's balance threshold is reached, also initiates automatic liquidity provision.
     * @param sender The address of whom the ETRNL is being transferred from
     * @param amount The amount of ETRNL being transferred
     * @param reflectedAmount The reflected amount of ETRNL being transferred
     */
    function storeLiquidityFunds(address sender, uint256 amount, uint256 reflectedAmount) private {

        // Update the contract's balance to account for the liquidity provision fee
        bytes32 thisReflectedBalance = keccak256(abi.encodePacked("reflectedBalances", address(this)));
        bytes32 thisTrueBalance = keccak256(abi.encodePacked("trueBalances", address(this)));
        uint256 reflectedBalance = eternalStorage.getUint(entity, thisReflectedBalance);
        uint256 trueBalance = eternalStorage.getUint(entity, thisTrueBalance);
        eternalStorage.setUint(entity, thisReflectedBalance, reflectedBalance + reflectedAmount);
        eternalStorage.setUint(entity, thisTrueBalance, trueBalance + amount);
        
        // Check whether the contract's balance threshold is reached; if so, initiate a liquidity swap
        uint256 contractBalance = balanceOf(address(this));
        if ((contractBalance >= eternalStorage.getUint(entity, tokenLiquidityThreshold)) && (sender != eternalTreasury.viewPair())) {
            _transfer(address(this), address(eternalTreasury), contractBalance);
            eternalTreasury.provideLiquidity(contractBalance);
        }
    }

    /**
     * @notice Hook called by the _transfer function in order to update vote balances after a given transaction
     * @param sender The initiator of the specified transaction
     * @param recipient The destination address of the specified transaction
     * @param amount The amount sent from the sender to the recipient in the transaction
     */
    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) private {
        address senderDelegate = eternalStorage.getAddress(entity, keccak256(abi.encodePacked("delegates", sender)));
        address recipientDelegate = eternalStorage.getAddress(entity, keccak256(abi.encodePacked("delegates", recipient)));
        IEternalFund(fund()).moveDelegates(senderDelegate, recipientDelegate, amount);
    }

/////–––««« Owner/Fund-only functions »»»––––\\\\\

    /**
     * @notice Excludes a given wallet or contract's address from accruing rewards. (Admin and Fund only)
     * @param account The wallet or contract's address
     *
     * Requirements:
     * – Account must not already be excluded from rewards.
     */
    function excludeFromReward(address account) public onlyFund {
        bytes32 excludedFromRewards = keccak256(abi.encodePacked("isExcludedFromRewards", account));
        require(!eternalStorage.getBool(entity, excludedFromRewards), "Account is already excluded");

        uint256 reflectedBalance = eternalStorage.getUint(entity, keccak256(abi.encodePacked("reflectedBalances", account)));
        if (reflectedBalance > 0) {
            // Compute the true token balance from non-empty reflected balances and update it
            // since we must use both reflected and true balances to make our reflected-to-total ratio even
            eternalStorage.setUint(entity, keccak256(abi.encodePacked("trueBalances", account)), convertFromReflectedToTrueAmount(reflectedBalance));
        }
        eternalStorage.setBool(entity, excludedFromRewards, true);
        eternalStorage.setAddressArrayValue(excludedAddresses, 0, account);
    }

    /**
     * @notice Allows a given wallet or contract's address to accrue rewards. (Admin and Fund only)
     * @param account The wallet or contract's address
     *
     * Requirements:
     * – Account must not already be accruing rewards.
     */
    function includeInReward(address account) external onlyFund {
        bytes32 excludedFromRewards = keccak256(abi.encodePacked("isExcludedFromRewards", account));
        require(eternalStorage.getBool(entity, excludedFromRewards), "Account is already included");
        for (uint i = 0; i < eternalStorage.lengthAddress(excludedAddresses); i++) {
            if (eternalStorage.getAddressArrayValue(excludedAddresses, i) == account) {
                eternalStorage.deleteAddress(excludedAddresses, i);
                // Set its deposit liabilities to 0 since we use the reserve balance for reward-accruing addresses
                eternalStorage.setUint(entity, keccak256(abi.encodePacked("trueBalances", account)), 0);
                eternalStorage.setBool(entity, excludedFromRewards, false);
                break;
            }
        }
    }

    /**
     * @notice Updates the address of the Eternal Treasury contract
     * @param newContract The new address for the Eternal Treasury contract
     */
    function setEternalTreasury(address newContract) external onlyFund {
        eternalTreasury = IEternalTreasury(newContract);
    }

    /**
     * @notice Updates the address of the Eternal Factory contract
     * @param newContract The new address for the Eternal Factory contract
     */
    function setEternalFactory (address newContract) external onlyFund {
        eternalFactory = IEternalFactory(newContract);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an admin) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the admin account will be the one that deploys the contract. This
 * can later be changed with {transferAdminRights}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin.
 *
 * @notice This is a modified version of Openzeppelin's Ownable.sol, made to add certain functionalities
 * such as different modifiers (onlyFund and onlyAdminAndFund) and locking/unlocking
 */
abstract contract OwnableEnhanced is Context {

/////–––««« Variables: Addresses, Events and Locking »»»––––\\\\\

    address private _admin;
    address private _fund;

    event FundRightsAttributed(address indexed newFund);

    uint256 private _lockPeriod;

    // Used in preventing the admin from using functions a maximum of 2 weeks and 1 day after contract creation
    uint256 public immutable ownershipDeadline;

/////–––««« Constructor »»»––––\\\\\

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor () {
        address msgSender = _msgSender();
        _admin = msgSender;
        _fund = msgSender;
        ownershipDeadline = block.timestamp + 3 days;
    }

/////–––««« Modifiers »»»––––\\\\\
    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(admin() == _msgSender(), "Caller is not the admin");
        require(ownershipDeadline > block.timestamp, "Admin's rights are over");
        _;
    }

    /**
     * @dev Throws if called by any account other than the fund.
     */
    modifier onlyFund() {
        require(_msgSender() == fund(), "Caller is not the fund");
        _;
    }

/////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Returns the address of the current fund.
     */
    function fund() public view virtual returns (address) {
        return _fund;
    }

/////–––««« Ownable-logic functions »»»––––\\\\\

    /**
     * @dev Attributes fund-rights for the Eternal Fund to a given address.
     * @param newFund The address of the new fund 
     *
     * Requirements:
     *
     * - New admin cannot be the zero address
     */
    function attributeFundRights(address newFund) public virtual onlyFund {
        require(newFund != address(0), "New fund is the zero address");
        _fund = newFund;
        emit FundRightsAttributed(newFund);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Eternal Storage interface
 * @author Nobody (me)
 * @notice Methods are used for all of Eternal's variable storage
 */
interface IEternalStorage {
    // Scalar setters
    function setUint(bytes32 entity, bytes32 key, uint256 value) external;
    function setInt(bytes32 entity, bytes32 key, int256 value) external;
    function setAddress(bytes32 entity, bytes32 key, address value) external;
    function setBool(bytes32 entity, bytes32 key, bool value) external;
    function setBytes(bytes32 entity, bytes32 key, bytes32 value) external;

    // Scalar getters
    function getUint(bytes32 entity, bytes32 key) external view returns(uint256);
    function getInt(bytes32 entity, bytes32 key) external view returns(int256);
    function getAddress(bytes32 entity, bytes32 key) external view returns(address);
    function getBool(bytes32 entity, bytes32 key) external view returns(bool);
    function getBytes(bytes32 entity, bytes32 key) external view returns(bytes32);

    // Array setters
    function setUintArrayValue(bytes32 key, uint256 index, uint256 value) external;
    function setIntArrayValue(bytes32 key, uint256 index, int256 value) external;
    function setAddressArrayValue(bytes32 key, uint256 index, address value) external;
    function setBoolArrayValue(bytes32 key, uint256 index, bool value) external;
    function setBytesArrayValue(bytes32 key, uint256 index, bytes32 value) external;

    // Array getters
    function getUintArrayValue(bytes32 key, uint256 index) external view returns (uint256);
    function getIntArrayValue(bytes32 key, uint256 index) external view returns (int256);
    function getAddressArrayValue(bytes32 key, uint256 index) external view returns (address);
    function getBoolArrayValue(bytes32 key, uint256 index) external view returns (bool);
    function getBytesArrayValue(bytes32 key, uint256 index) external view returns (bytes32);

    //Array Deleters
    function deleteUint(bytes32 key, uint256 index) external;
    function deleteInt(bytes32 key, uint256 index) external;
    function deleteAddress(bytes32 key, uint256 index) external;
    function deleteBool(bytes32 key, uint256 index) external;
    function deleteBytes(bytes32 key, uint256 index) external;

    //Array Length
    function lengthUint(bytes32 key) external view returns (uint256);
    function lengthInt(bytes32 key) external view returns (uint256);
    function lengthAddress(bytes32 key) external view returns (uint256);
    function lengthBool(bytes32 key) external view returns (uint256);
    function lengthBytes(bytes32 key) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Eternal interface
 * @author Nobody (me)
 * @notice Methods are used for all gage-related functioning
 */
interface IEternalFactory {
    // Initiates a liquid gage involving an ETRNL liquidity pair
    function initiateEternalLiquidGage(address asset, uint256 amount) external payable returns(uint256);
    // Updates the 24h counters for the treasury and token
    function updateCounters(uint256 amount) external;
    
    // Signals the deployment of a new gage
    event NewGage(uint256 id, address indexed gageAddress);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Eternal Treasury interface
 * @author Nobody (me)
 * @notice Methods are used for all treasury functions
 */
interface IEternalTreasury {
    // Provides liquidity for a given liquid gage and transfers instantaneous rewards to the receiver
    function fundEternalLiquidGage(address _gage, address user, address asset, uint256 amount, uint256 risk, uint256 bonus) external payable;
    // Used by gages to compute and distribute ETRNL liquid gage rewards appropriately
    function settleGage(address receiver, uint256 id, bool winner) external;
    // Stake a given amount of ETRNL
    function stake(uint256 amount) external;
    // Unstake a given amount of ETRNL and withdraw staking rewards proportional to the amount (in ETRNL)
    function unstake(uint256 amount) external;
    // View the ETRNL/AVAX pair address
    function viewPair() external view returns(address);
    // View whether a liquidity swap is in progress
    function viewUndergoingSwap() external view returns(bool);
    // Provides liquidity for the ETRNL/AVAX pair for the ETRNL token contract
    function provideLiquidity(uint256 contractBalance) external;
    // Computes the minimum amount of two assets needed to provide liquidity given one asset amount
    function computeMinAmounts(address asset, address otherAsset, uint256 amountAsset, uint256 uncertainty) external view returns(uint256 minOtherAsset, uint256 minAsset, uint256 amountOtherAsset);
    // Converts a given staked amount into the reserve number space
    function convertToReserve(uint256 amount) external view returns(uint256);
    // Converts a given reserve amount into the regular number space (staked)
    function convertToStaked(uint256 reserveAmount) external view returns(uint256);
    // Allows the withdrawal of AVAX in the contract
    function withdrawAVAX(address payable recipient, uint256 amount) external;
    // Allows the withdrawal of an asset present in the contract
    function withdrawAsset(address asset, address recipient, uint256 amount) external;

    // Signals a disabling/enabling of the automatic liquidity provision
    event AutomaticLiquidityProvisionUpdated(bool value);
    // Signals that liquidity has been added to the ETRNL/WAVAX pair 
    event AutomaticLiquidityProvision(uint256 amountETRNL, uint256 totalSwappedETRNL, uint256 amountAVAX);
    // Signals that part of the locked AVAX balance has been cleared to a given address by decision of the DAO
    event AVAXTransferred(uint256 amount, address recipient);
    // Signals that some of an asset balance has been sent to a given address by decision of the DAO
    event AssetTransferred(address asset, uint256 amount, address recipient);
    // Signals that a user staked a given amount of ETRNL 
    event Stake(address indexed user, uint256 amount);
    // Signals that a user unstaked a given amount of ETRNL
    event Unstake(address indexed user, uint256 amount);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Eternal Fund interface
 * @author Nobody (me)
 * @notice Methods are used for all of Eternal's governance functions
 */
interface IEternalFund {
    // Delegates the message sender's vote balance to a given user
    function delegate(address delegatee) external;
    // Determine the number of votes of a given account prior to a given block
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
    // Gets the current votes balance for a given account
    function getCurrentVotes(address account) external view returns(uint256);
    // Transfer part of a given delegates' voting balance to another new delegate
    function moveDelegates(address srcRep, address dstRep, uint256 amount) external;

    // Signals a change of a given user's delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    // Signals a change of a given delegate's vote balance
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}