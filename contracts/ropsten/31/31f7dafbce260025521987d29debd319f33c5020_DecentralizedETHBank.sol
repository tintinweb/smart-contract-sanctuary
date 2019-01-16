pragma solidity ^0.4.25;

/**
 * The First Decentralised ETH Bank
 * 
 * What&#39;s going on here?
 * 
 * It&#39;s works like real deposit in Bank. You will deposit ETH coin, and get dividends. 
 * It&#39;s not a ponzi scheme. Dividends are paid from the commission for opening / expanding 
 * and closing a deposit. The more time you hold a deposit, the more interest you earn.
 * 
 * The bank’s fund is completely decentralized and no one can transfer funds.
 * 
 * NOTE: Look website url in _website_url_ variable
 * 
 * HOW OPEN DEPOSIT?
 * 
 *      - Send to this contract any amount above 0.01 ETH
 *      - Contract will charge small fee for banking
 *      - 5% of your amount will be charged to fund
 *      - If you already have a deposit, it will be expanging
 * 
 * HOW WILL I RECEIVE DIVIDENDS?
 * 
 *      - Dividend fund is formed from the commission for opening or expanding or closing a deposit
 *      - When you transfer ETH to contract you will buy shares ( ETH amount * TOTAL_ SHARES / BALANCE)
 *      - When you close a deposit, you will return your balance and accrued interest
 *      - Dividends are accrued from new transactions that were made after the opening of the deposit
 * 
 * HOW CLOSE DEPOSIT?
 * 
 *      - To close the deposit send 0 ETH to the address of this contract
 *      - You will receive your balance + dividends
 *      - When you close the deposit you will pay 5% from this amount to fund and small fee for banking
 * 
 * COMISIONS:
 * 
 *      - Open or expand deposit:  5%. This amount is credited to the dividend fund.
 *      - Close deposti: 5%. This amount is credited to the dividend fund.
 *      - Banking fee (Open Deposit)  - 1%. Look actual in depositComissionOfBank
 *      - Banking fee (CLose Deposit) - 1% Look actual in withdrawComissionOfBank
 * 
 * WHAT IS THE TOKEN USED FOR?
 * 
 * Token is used only for advertising.You cannot buy or sell this token. 
 * You can send any number of tokens to any address or list of addresses 
 * by paying only gas for sending a token.
 * 
 * WHAT CAN DO ADMINISTRATOR?
 * 
 *      - Change administrator address
 *      - Change financial addrees for Banking fee
 *      - Change Banking public message
 * 
 * WHAT CAN DO FINANCIAL ADMINISTRATOR?
 * 
 *      - Change Banking fee (from 0% to 2% - it&#39;s guaranteed by Contract)
 *      - Receive Banking fee
 * 
 * HOW CAN I MAKE SURE THE TERMS OF THE CONTRACT?
 * 
 * Below you can see the contract DecentralunedETNBank (Banking Smart contract), 
 * we have described in detail all the actions of the contract
 * 
 * We take original code from the project TheWeakestHodler by CryptoManiac
 * https://etherscan.io/address/0x6288C6b68f06B1a3fd231C9c1Cb37113a531c912
 * 
 * What&#39;s new in this fork?
 * 
 *   - Accrual of dividends when opening and replenishing deposits
 *   - 10% of the dividend fund is divided into two parts.
 *          - First 5% credited to the fund at the opening and expanding deposit
 *          - Second 5% credited to the fund at the closing deposit
 *   - Added small bank fee (for project marketing)
 *   - Added advertising token
 *   - Added bank announcement message
 *   - Added bank website url
 *   - Added administrator wallet for administration
 *   - Added financial administrator wallet for sending bank fee and fee management
 *   - Added comments to all contract actions for personal audit
 * 
 */

/**
 * Advertise Token. Not More...
 */
contract ERC20AdToken {
    
    using SafeMath for uint;
    using Zero for *;

    string public symbol;
    string public  name;
    uint8 public decimals = 0;
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(string _symbol, string _name) public {
        symbol = _symbol;
        name = _name;
        balanceOf[this] = 10000000000;
        totalSupply = 10000000000;
        emit Transfer(address(0), this, 10000000000);
    }

    function transferToken(address to, uint tokens) public returns (bool success) {
        //This method do not send anything. It is only notify blockchain that Advertise Token Transfered
        //You can call this method for advertise this contract and invite new investors and gain 1% from each first investments.
        emit Transfer(this, to, tokens);
        return true;
    }
    
    function massTransferTokens(address[] addresses, uint tokens) public returns (bool success) {
        for (uint i = 0; i < addresses.length; i++) {
            emit Transfer(this, addresses[i], tokens);
        }
        
        return true;
    }

    function () public payable {
        revert();
    }

}

/**
 * Banking Smart contract 
 */
contract DecentralizedETHBank is ERC20AdToken {
    
    // Library for safe mathematics
    using SafeMath for uint256;
    
    // List of holders of shares: address = number of shares
    mapping(address => uint256) public shares;
    
    // Total balance of shares
    uint256 public totalShares;
    
    // Total Holders
    uint256 public totalHolders;
    
    // Bank announcements. You can read message in tab Read Contract (etherscan.io)
    string public _readme_ = "";
    
    // Bank website url
    string public _website_url_ = "";
    
    //***************** Bank administration wallets  *****************//
    
     // Administrator address
    address administratorAddress;
    
    // Financial administrator address
    address financialAddress;
    
    //***************** Setting up payments to the fund  *****************//

    // Commission for opening or expanding a deposit. Cannot be changed
    // These funds are credited to the fund for dividend payment 5%
    uint256 constant public PERCENT_DEPOSIT = 5;
    
    // Commission for closing a deposit. Cannot be changed
    // These funds are credited to the fund for dividend payment t 5%
    uint256 constant public PERCENT_WITHDRAW = 5;
    
    
    //***************** Banking fee  *****************//
    
    // Bank fee for opening or expanding a deposit
    // This fee may be changed by the financial administrator
    // Fee may vary from 0 to 2
    // Values: 10 - 1%, 15 - 1.5%, 0 - 0%
    uint256 public depositComissionOfBank = 10;
    
    // Bank fee for closing a deposit
    // This fee may be changed by the financial administrator
    // Fee may vary from 0 to 2
    // Values: 10 - 1%, 15 - 1.5%, 0 - 0%
    uint256 public withdrawComissionOfBank = 10;
    
    // Maximum allowed bank fee 2%. Cannot be changed
    uint256 constant public MAX_COMISSION_OF_BANK = 20;
    
    // Minimum deposit 0.01 ETH. Cannot be changed
    uint256 constant public DEPOSIT_MIN = 10 finney;
    
    //***************** Access modifiers  *****************//
    
    // Access modifier - admin only
    //   - The administrator can change the address of the administrator
    //   - The administrator can change the address of the financial administrator.
    //   - The administrator can change the message about the announcements of the bank
    
    modifier onlyAdministrator() {
        require(msg.sender == administratorAddress, "access denied");
        _;
    }
    
    // Access modifier - not a contract
    // For bank security, the use of contracts as owners of shares is prohibited.
    
    modifier notContract() {
        require(!isContract(msg.sender), "access denied for contacts");
        _;
    }
    
    // Access modifier - financial administrator only
    //   - Financial administrator can change bank fee (from 0 to 2%)
    //   - Financial administrator receives bank fee

    modifier onlyFinancial() {
        require(msg.sender == financialAddress, "access denied");
        _;
    }
    
    //***************** Public Bank Events  *****************//
    
    // Contract send event when someone opens or expanded their deposit.
    // All shareholders held dividends.
    event NewDeposit(address indexed addr, uint when, uint invested);
    
    // Contract send event when someone close their deposit.
    // All shareholders held dividends.
    event NewWithdraw(address indexed addr, uint when, uint invested);
    
    // Contract send event when administrator change announcement message
    // All shareholders held dividends.
    event NewMessage(address indexed addr, string message);
    
    // Setting the parameters of the advertising token and initialization of the banking contract
    
    constructor() ERC20AdToken("Decentralised ETH Bank", 
                            "Send ETH to bank and get dividends (not ponzi scheme)") public {
        
        // Set administrator address
        administratorAddress = msg.sender;
        
        // Set financial administrator address by default
        financialAddress = msg.sender;
    }
    
    /**
     * Change of financial administrator - available only to the main administrator
     */
     
    function setFinancialAddress(address _address) onlyAdministrator public {
        financialAddress = _address;
    }
    
    /**
     * Change of administrator - available only to the main administrator
     */
     
    function setAdminAddress(address _address) onlyAdministrator public {
        administratorAddress = _address;
    }
    
    /**
     * Change bank announcement message
     */
    function setMessage(string _message) onlyAdministrator public {
        _readme_ = _message;
        emit NewMessage(msg.sender, _message);
    }
    
    /**
     * Change bank website url
     */
    function setWebsiteUrl(string _url) onlyAdministrator public {
        _website_url_ = _url;
    }
    
    /**
     * Changing the bank fee for opening / expanding deposit - available only to the financial administrator
     */
    function setDepositBankFee(uint256 _comission) onlyFinancial public {
        
        // Fee may vary from 0% to 2%
        require(_comission > 0 && _comission <= MAX_COMISSION_OF_BANK, "Not Allowed Fee");
        
        depositComissionOfBank = _comission;
    }
    
    /**
     * Changing the bank fee for closing deposit - available only to the financial administrator
     */
    function setWithdrawBankFee(uint256 _comission) onlyFinancial public {
        
        // Fee may vary from 0% to 2%
        require(_comission > 0 && _comission <= MAX_COMISSION_OF_BANK, "Not Allowed Comission");
        
        withdrawComissionOfBank = _comission;
    }
    
    /**
     * Receipt of payment to the address of the contract
     */
    function () public notContract payable {
        
        if (msg.value >= DEPOSIT_MIN) {
            
            if (shares[msg.sender] == 0 ){
                totalHolders++;
            }
            
            // Creates a new deposit or credits funds to an existing
            deposit();
            
        } else {
            
            // Closes the deposit if the amount is less than 0.01 ETH.
            // We recommend to send 0 ETH
            withdraw();
        }
    }
    
    /**
     * Creates a new deposit or credits funds to an existing
     */
    function deposit() private {
        
        // Transaction amount
        uint256 amount = msg.value;
        
        // Sending bank fee if it is greater than 0
        if (depositComissionOfBank > 0)
        {
            // Calculate banking free from amount
            uint256 finComission = amount.mul(depositComissionOfBank).div(1000);
            
            // Subtract the bank fee from the incoming amount
            amount = amount.sub(finComission);
            
            // Send bank fee to financial address
            financialAddress.transfer(finComission);
        }
        
        // Calculate the commission for opening / extend the deposit
        uint256 depositPercent = amount.mul(PERCENT_DEPOSIT).div(100);
        
        // Subtract opening or expanding comission from the incoming amount 
        amount = amount.sub(depositPercent);
        
        // If total shares in bank more than 0
        if (totalShares > 0) {
            
            // Calculate the new share ( AMOUNT * TOTAL SHARES / (OLD BALANCE + DEPOSIT PERCENT AMOUNT) )
            amount = amount.mul(totalShares)
                        .div(address(this).balance.sub(msg.value).add(depositPercent));
        }
        
        // Add new shares to existing address or create new
        shares[msg.sender] = shares[msg.sender].add(amount);
        
        // Add new shares to total shares balance
        totalShares = totalShares.add(amount);
        
        // Emit event NewDeposit. All shareholders held dividends.
        emit NewDeposit(msg.sender, now, msg.value);
    }
    
    /**
     * Deposit closing and dividend payout
     */
    function withdraw() private {
        
        // Get an available balance including dividends for the 
        // address from which the payment was requested
        uint256 availableAmount = availableForWithdraw(msg.sender);
        
        // Security check - is there enough balance
        require(totalShares >= shares[msg.sender], "Not enought balance");
        
        // Update total shares value (Subtract account shares)
        totalShares = totalShares.sub(shares[msg.sender]);
        
        // Update account shares to 0
        shares[msg.sender] = 0;
        
        // Sending bank fee if it is greater than 0
        if (withdrawComissionOfBank > 0){
            
            // Calculate banking free from amount
            uint256 finComission = availableAmount.mul(withdrawComissionOfBank).div(1000);
            
            // Subtract the bank fee from the outgoing amount
            availableAmount = availableAmount.sub(finComission);
            
            // Send bank fee to financial address
            financialAddress.transfer(finComission);   
        }
        
        // Sending account deposit with dividends to the 
        // address from which the payment was requested
        msg.sender.transfer(availableAmount);
        
        // Emit event NewWithdraw. All shareholders held dividends.
        emit NewWithdraw(msg.sender, now, availableAmount);
    }

    /**
     * Available balance for withdrawal including dividends and a deduction 
     * of the commission for closing the deposit
     */
    function availableForWithdraw(address _account) public view returns(uint256) {
        
        // Check account availability in holders
        require(shares[_account] > 0, "Not enought balance");
        
        // Checking the overall balance of the holders
        require(totalShares > 0);
        
        // Calculate the account balance and the accumulated dividends 
        // and deduct the commission for closing
        // CONTRACT BALANCE * ACCOUNT SHARES * 95% / TOTAL SHARES / 100
        
        return address(this).balance.mul(shares[_account])
                    .mul((uint256) (100).sub(PERCENT_WITHDRAW))
                    .div(totalShares)
                    .div(100);
    }
    
    /**
     * Check for a contract at address
     */
    function isContract(address _addr) private view returns (bool){
      uint32 size;
      assembly {
        size := extcodesize(_addr)
      }
      return (size > 0);
    }
}

/**
 * Library Zero - for check non zero values
 **/
 
library Zero {
  function requireNotZero(uint a) internal pure {
    require(a != 0, "require not zero");
  }

  function requireNotZero(address addr) internal pure {
    require(addr != address(0), "require not zero address");
  }

  function notZero(address addr) internal pure returns(bool) {
    return !(addr == address(0));
  }

  function isZero(address addr) internal pure returns(bool) {
    return addr == address(0);
  }
}

/**
 * Library SafeMath - for safe Mathematics
 **/
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}