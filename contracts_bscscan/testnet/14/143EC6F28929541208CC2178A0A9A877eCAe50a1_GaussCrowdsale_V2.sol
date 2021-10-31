/*  _____________________________________________________________________________

    GaussCrowdsale: Crowdsale for the Gauss Gang Ecosystem

    Deployed to: TODO

    MIT License. (c) 2021 Gauss Gang Inc. 

    _____________________________________________________________________________
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "../dependencies/interfaces/IBEP20.sol";
import "../dependencies/access/Ownable.sol";



/*  The GuassCrowdsale allows buyers to purchase Gauss(GANG) tokens with BNB.
        - Crowdsale is Staged, where each Stage has a different exchange rate of BNB to Gauss(GANG) tokens.
        - Crowdsale has a Maximum Purchase amount of 100 BNB.
        - The tokens will be disbursed after the completion of the Crowdsale by way of a batch transfer.
        - Should the batch transfer fail (due to gas limits), there is a provision in place for buyers to claim/withdraw their tokens after completion.
*/
contract GaussCrowdsale_V2 is Ownable {

    // Mapping that contains the addresses of each purchaser and the amount of BNB they have spent.
    mapping(address => uint256) private purchaseTotals;

    // A sctruct that will hold the address and Gauss(GANG) Token amount for each Buyer.
    struct Buyer {
        address payable wallet;
        uint256 tokenAmount;
    }

    // Array of all Buyers, used to keep track of each Buyer's address and amount of Gauss(GANG) tokens they purchased.
    Buyer[] private balances;

    // The token being sold.
    IBEP20 private _token;

    // How many Gauss(GANG) tokens a buyer will receive per BNB. (shown with the Gauss(GANG) decimals applied)
    uint256[] private rates = [
        6800000000000,      // 6,800 tokens per 1 BNB during stage 0
        5667000000000,      // 5,667 tokens per 1 BNB during stage 1
        4857000000000,      // 4,857 tokens per 1 BNB during stage 2
        4250000000000,      // 4,250 tokens per 1 BNB during stage 3
        3778000000000,      // 3,778 tokens per 1 BNB during stage 4
        3400000000000,      // 3,400 tokens per 1 BNB during stage 5
        3091000000000,      // 3,091 tokens per 1 BNB during stage 6
        2833000000000,      // 2,833 tokens per 1 BNB during stage 7
        2615000000000,      // 2,615 tokens per 1 BNB during stage 8
        2429000000000,      // 2,429 tokens per 1 BNB during stage 9
        2267000000000,      // 2,267 tokens per 1 BNB during stage 10
        2125000000000,      // 2,125 tokens per 1 BNB during stage 11
        2000000000000,      // 2,000 tokens per 1 BNB during stage 12
        1889000000000,      // 1,889 tokens per 1 BNB during stage 13
        1789000000000,      // 1,789 tokens per 1 BNB during stage 14
        1700000000000       // 1,700 tokens per 1 BNB during stage 15
    ];

    // Number of tokens per stage; the rate changes after each stage has been completed.
    uint256[] private stages = [
        100000000000000,     // 100,000 tokens in stage 0
        250000000000000,     // 150,000 tokens in stage 1
        500000000000000,     // 250,000 tokens in stage 2
        750000000000000,     // 250,000 tokens in stage 3
        1250000000000000,    // 500,000 tokens in stage 4
        2000000000000000,    // 750,000 tokens in stage 5
        2750000000000000,    // 750,000 tokens in stage 6
        3500000000000000,    // 750,000 tokens in stage 7
        4250000000000000,    // 750,000 tokens in stage 8
        5000000000000000,    // 750,000 tokens in stage 9
        6000000000000000,    // 1,000,000 tokens in stage 10
        7000000000000000,    // 1,000,000 tokens in stage 11
        9000000000000000,    // 2,000,000 tokens in stage 12
        11000000000000000,   // 2,000,000 tokens in stage 13
        13000000000000000,   // 2,000,000 tokens in stage 14
        15000000000000000    // 2,000,000 tokens in stage 15
    ];

    // Address where BNB funds are collected.
    address payable public crowdsaleWallet;

    // The max amount, in Jager, a buyer can purchase; used to prevent potential whales from buying up too many tokens at once.
    uint256 private purchaseCap;

    // Amount of Jager raised (BNB's smallest unit).
    uint256 public jagerRaised;

    // Amount of remaining Gauss(GANG) tokens remaining in the GaussCrowdsale.
    uint256 public gaussSold;

    // Number indicating the current stage.
    uint256 public currentStage;

    // Start and end timestamps, between which investments are allowed.
    uint256 public startTime;
    uint256 public endTime;

    // A varaible to determine whether Crowdsale is closed or not.
    bool private _closed;

    // A variable to determine whether buyers can directly withdraw tokens or not.
    bool private _allowWithdrawals;

    // Initializes an event that will be called after each token purchase.
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    // Constructor sets takes the variables passed in and initializes are state variables. 
    constructor(uint256 _startTime, address payable _crowdsaleWallet) payable {

        require(_startTime >= block.timestamp, "GaussCrowdsale: startTime can not be before current time.");

        require(_crowdsaleWallet != address(0), "GaussCrowdsale: Crowdsale wallet can not be Zero Address.");
        require(rates.length == stages.length);

        __Ownable_init();
        startTime = _startTime;
        endTime = startTime + (42 days);
        crowdsaleWallet = _crowdsaleWallet;

        purchaseCap = (100 * 10**18);
        jagerRaised = 0;
        gaussSold = 0;
        currentStage = 0;
        _closed = false;
        _allowWithdrawals = false;
    }


    // Receive function to recieve BNB.
    receive() external payable {

        // Allows owner to fill contract with BNB to cover gas costs.
        if (msg.sender == owner()) {}

        else {buyTokens(payable(msg.sender));}
    }


    /*  Allows one to buy or gift Gauss(GANG) tokens using BNB. 
            - Amount of BNB the buyer transfers must be lower than the "purchaseCap" of 100 BNB.
            - Transfers BNB to the crowdsaleWallet  after completion of the purchase          */
    function buyTokens(address payable _beneficiary) public payable {
        uint256 jagerAmount = msg.value;
        _validatePurchase(_beneficiary, jagerAmount);
        _processPurchase(_beneficiary, jagerAmount);
    }


    // Validation of an incoming purchase. Uses require statements to revert state when conditions are not met.
    function _validatePurchase(address _beneficiary, uint256 _jagerAmount) internal view {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Crowdsale: current time is either before or after Crowdsale period.");
        require(_closed == false, "Crowdsale: sale is no longer open");
        require(_beneficiary != address(0), "Crowdsale: beneficiary can not be Zero Address.");
        require(_jagerAmount != 0, "Crowdsale: amount of BNB must be greater than 0.");
        require(_jagerAmount <= purchaseCap, "Crowdsale: amount of BNB sent must lower than 100");
        require((purchaseTotals[_beneficiary] + _jagerAmount) <= purchaseCap, "Crowdsale: amount of BNB entered exceeds buyers purchase cap.");
    }


    // Adds the "tokenAmount" (amount of Gauss(GANG) tokens) to the beneficiary's balance.
    function _processPurchase(address payable _beneficiary, uint256 _jagerAmount) internal {

        // Calculates the token amount using the "jagerAmount" and the rate at the current stage.
        uint256 tokenAmount = ((_jagerAmount * rates[currentStage])/(10**18));
        require((gaussSold + tokenAmount) <= stages[15], "Crowdsale: token amount can not be more that total amount alloted to Crowdsale.");

        // Adds the wallet address and "tokenAmount" to the beneficiary's balance.
        balances.push(Buyer(_beneficiary, tokenAmount));

        // Adds the "jagerAmount" to the purchaseTotal of the buyer.
        purchaseTotals[_beneficiary] += _jagerAmount;

        // Tranfers the BNB recieved in purchase to the Crowdsale Wallet.
        crowdsaleWallet.transfer(_jagerAmount);

        _updatePurchasingState(tokenAmount, _jagerAmount); 
        emit TokenPurchase(msg.sender, _beneficiary, _jagerAmount, tokenAmount);
    }


    // Updates the amount of tokens left in the Crowdsale; may change the stage if conditions are met.
    function _updatePurchasingState(uint256 _tokenAmount, uint256 _jagerAmount) internal {        
        gaussSold += _tokenAmount;
        jagerRaised += _jagerAmount;

        if (gaussSold >= stages[currentStage]) {
            if (currentStage < stages.length) {
                currentStage += 1;
            }
        }
    }


    // Our Token audit is currently is progress from Techrate. So this allows us to start our Crowdsale on time and update the contract once the audit is complete.
    function setBEP20Token(address _gaussAddress) external onlyOwner() {
        require(_gaussAddress != address(0), "GaussCrowdsale: gaussAddress can not be Zero Address.");
        _token = IBEP20(_gaussAddress);
    }


    // Returns IBEP20 Token address
    function getBEP20Address() external view returns (address) {
        return address(_token);
    }


    // Allows owner to close the Crowdsale.
    function closeCrowdsale() public onlyOwner() {
        _closed = true;
    }


    // Owner can allow direct withdrawals for tokens purchases should the batch transfer hit the gas limit and fail.
    function allowWithdrawals() external onlyOwner() {
        _allowWithdrawals = true;
    }


    // Returns a receipt showing each buyer's wallet address, the amount of BNB spent, and the amount of Gauss(GANG) tokens bought.
    function getReceipts() external view onlyOwner() returns (address[] memory, uint256[] memory, uint256[] memory) {
        
        // Assigning the balances storage array to a memory array to lower gas costs.
        Buyer[] memory buyers = balances;

        address[] memory wallets = new address[](buyers.length);
        uint256[] memory bnbSpent = new uint256[](buyers.length);
        uint256[] memory gaussBought = new uint256[](buyers.length);

        for (uint256 i = 0; i < buyers.length; i++) {
            wallets[i] = buyers[i].wallet;
            bnbSpent[i] = purchaseTotals[buyers[i].wallet];
            gaussBought[i] = buyers[i].tokenAmount;
        }

        return (wallets, bnbSpent, gaussBought);
    }


    // Allows owner to update the balances array if the batch release function only partially fails.
    function updateBalances(address payable[] memory wallets, uint256[] memory tokenAmounts) external onlyOwner() {

        require(_closed == true, "Crowdsale: sale has not been closed.");
        require(wallets.length == tokenAmounts.length);

        for (uint256 i = 0; i < wallets.length; i++) {
            balances[i] = (Buyer(wallets[i], tokenAmounts[i]));
        }

        for (uint256 i = 0; i < balances.length; i++) {
            if (i >= wallets.length) {
                balances.pop();
            }
        }
    }


    // Batch release function that will transfer Gauss(GANG) tokens to each buyer; can only be called by owner.
    function releaseTokens() external onlyOwner() {

        require(_closed == true, "Crowdsale: sale has not been closed.");

        // Assigning the balances storage array to a memory array to lower gas costs.
        Buyer[] memory buyers = balances;
        
        for (uint256 i = 0; i < buyers.length; i++) {
            require(_token.transfer(buyers[i].wallet, buyers[i].tokenAmount));
        }
    }


    // Can only be called once the Crowdsale has completed and the "owner" has closed the Crowdsale.
    //      - Left as a backup in-case the batch release function fails due to gas limit.
    function withdrawTokens() external {

        require(_closed == true, "Crowdsale: sale has not been closed.");
        require(_allowWithdrawals == true, "Crowdsale: withdrawals have not been authorized.");

        uint256 amount;
        for (uint256 i = 0; i < balances.length; i++) {
            if (balances[i].wallet == msg.sender) {
                amount = balances[i].tokenAmount;

                require(amount > 0, "Crowdsale: can not withdrawl 0 amount.");
                require(_token.transfer(msg.sender, amount));
                balances[i].tokenAmount = 0;
            }
        }
    }


    /*  Transfer remaining Gauss(GANG) tokens back to the "crowdsaleWallet" as well as any BNB that may be left in the contract.
            NOTE:   - To be called at end of the Crowdsale to finalize and complete the Crowdsale.
                    - Can act as a backup in case the sale needs to be urgently stopped.
                    - Care should be taken when calling function as it could prematurely end the Crowdsale if accidentally called. */
    function finalizeCrowdsale() public onlyOwner() {

        // Send remaining tokens back to the admin.
        uint256 tokensRemaining = _token.balanceOf(address(this));
        _token.transfer(crowdsaleWallet, tokensRemaining);

        // Transfers any BNB that may be left in contract back to the admin.
        crowdsaleWallet.transfer(address(this).balance);

        closeCrowdsale();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// BEP20 Interface that creates basic functions for a BEP20 token.
interface IBEP20 {
    
    
    // Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);
    
    
    // Returns the token decimals.
    function decimals() external view returns (uint8);
    
    
    // Returns the token symbol.
    function symbol() external view returns (string memory);
    
    
    // Returns the token name.
    function name() external view returns (string memory);
    
    
    // Returns balance of the referenced 'account' address.
    function balanceOf(address account) external view returns (uint256);


    // Transfers an 'amount' of tokens from the caller's account to the referenced 'recipient' address. Emits a {Transfer} event. 
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    
    // Transfers an 'amount' of tokens from the 'sender' address to the 'recipient' address. Emits a {Transfer} event.
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    // Returns the remaining tokens that the 'spender' address can spend on behalf of the 'owner' address through the {transferFrom} function.
    function allowance(address _owner, address spender) external view returns (uint256);
   
    
    // Sets 'amount' as the allowance of 'spender' then returns a boolean indicating result of operation. Emits an {Approval} event.
    function approve(address spender, uint256 amount) external returns (bool);

  
    // Emitted when `value` tokens are moved from one account address (`from`) to another (`to`). Note that `value` may be zero.
    event Transfer(address indexed from, address indexed to, uint256 value);


    // Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "../utilities/Initializable.sol";
import "../utilities/Context.sol";



// Provides a basic access control mechanism, where an account '_owner' can be granted exclusive access to specific functions by using the modifier `onlyOwner`.
abstract contract Ownable is Initializable, Context {
    
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    // Initializes the contract, setting the deployer as the initial owner.
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    
    // Initializes the contract, setting the deployer as the initial owner.
    function __Ownable_init_unchained() internal initializer {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    

    // Returns the address of the current owner.
    function owner() public view returns (address) {
        return _owner;
    }

    
    // Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    // Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }


    // Internal function, transfers ownership of the contract to a new account (`newOwner`).
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



/*  This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
    behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
    external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
    function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 
    TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
         possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 
    CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
             that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    
    // Indicates that the contract has been initialized.
    bool private _initialized;


    // Indicates that the contract is in the process of being initialized.
    bool private _initializing;


    //Modifier to protect an initializer function from being invoked twice.
    modifier initializer() {
        
        require(_initializing || !_initialized, "Initializable: contract is already initialized");
        bool isTopLevelCall = !_initializing;
        
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "./Initializable.sol";


// Provides information about the current execution context, including the sender of the transaction and its data.
abstract contract Context is Initializable  {
    
    
    // Empty initializer, to prevent people from mistakenly deploying an instance of this contract, which should be used via inheritance.
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }
    
    // Empty internal initializer.
    function __Context_init_unchained() internal initializer {
    }


    function _msgSender() internal view virtual returns (address) {
        return (msg.sender);
    }
    
    
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    
    uint256[50] private __gap;
}