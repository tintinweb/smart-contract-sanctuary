pragma solidity ^0.4.25;

/**
 * The First Decentralised ETH Bank
 * 
 * What&#39;s going on here?
 * 
 * It&#39;s works like real deposit in the Bank. You can put to deposit ETH coin, 
 * and after some time get deposit body + 15%. It&#39;s not a ponzi scheme.
 * Dividends are paid from the commission for opening and closing a deposit.  
 * 
 * The bank’s fund is completely decentralized and no one can access to general fund.
 * 
 * NOTE: Look website url in _website_url_ variable
 * 
 * HOW OPEN DEPOSIT?
 * 
 *      - Send to this contract any amount above 0.01 ETH
 *      - Contract will charge 2% banking fee
 *      - Each transaction open a new deposit
 *      - * Use 1000000 gas limit
 * 
 * Why 1000000 gas limit?
 * 
 * To open a deposit, you will need approximately 200K of gas, the rest of the spent 
 * gas for the banking system will be compensated, and when you withdraw the deposit, 
 * you will receive these funds on your balance. Compensation is calculated at the 
 * price of gas indicated by you, but not more than 6 GWei. After deposit openin.
 * 
 * When the deposit is opened, you will see the amount of compensation for the 
 * spent gas in your deposit information.
 * 
 * HOW WILL I RECEIVE DIVIDENDS?
 * 
 *      - 4% of the new deposit used for dividends to all open deposits
 *      - 14% of the new deposit is used to close the oldest deposits
 *      - Thus, the bank balance can never be negative
 * 
 * HOW CLOSE DEPOSIT?
 * 
 *      - Send 0 ETH to the address of this contract and you will receive your all closed deposits
 *      - You can use function withdrawByDepositId. Set your deposit id and you will recive this deposit at any time
 *      - If your deposit is not yet closed, you will receive a deposit body - 20% (early withdrawal fee) + accrued dividends and gas compensation
 * 
 * COMISIONS:
 * 
 *      - 20% early withdrawal fee 
 *      - 2% bank fee (autopayment, gas compensation)
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
    using Zero for *;
    
    struct Deposit {
        address owner;
        uint256 invested;
        uint256 multiplicator;
        uint256 withdraw;
        uint256 gas;
        uint256 share;
        bool closed;
    }
    
    mapping(uint => Deposit) deposits;
    
    uint256 public multiplicatorBalance;
    uint256 public calculatedBankBalance;
    uint256 public bankFeeBalance;
    
    uint256 closedDeposits = 0;
    uint256 totalDeposits = 0;
    uint256 public lastMultiplicatorIndex = 1;
    
    mapping(address => uint256[]) addressToDeposits;
    mapping(address => uint256[]) addressToFinishedDeposits;
    
    // Bank announcements. You can read message in tab Read Contract (etherscan.io)
    string public _readme_ = "";
    
    // Bank website url
    string public _website_url_ = "";
    
    //***************** Bank administration wallets  *****************//
    
     // Administrator address
    address public administratorAddress;
    
    // Financial administrator address
    address public financialAddress;
    
    //***************** Setting up payments to the fund  *****************//

    // Commission for opening or expanding a deposit. Cannot be changed
    // These funds are credited to the fund for dividend payment 4%
    uint256 constant public PERCENT_SHARES = 4;
    
    // Commission for closing a deposit. Cannot be changed
    // These funds are credited to the fund for dividend payment t 14%
    uint256 constant public PERCENT_FIRSTINVESTORS = 14;
    
    uint256 constant public PERCENT_MAX_DIVIDENTS = 15;
    
    // Add gas compensation for fast line& Max price for gas: 6 Givey
    uint256 constant public GAS_COMPENSATION = 6000000000;
    
    //***************** Banking fee  *****************//
    
    // Bank fee for opening or expanding a deposit
    // This fee may be changed by the financial administrator
    // Fee may vary from 0 to 2
    // Values: 2%
    uint256 public comissionOfBank = 2;
    
    // Minimum deposit 0.01 ETH. Cannot be changed
    uint256 constant public DEPOSIT_MIN = 10 finney;
    
    uint public countDepositsForMultiplicator = 5;
    
    // Total balance of shares
    uint256 public totalShares;
    
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
    //0.000000003 / 3000000000
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
        
        //investorIndex.length++;
    }
    
    /**
     * Check for a contract at address
     */
    function isContract(address _addr) private view returns (bool){
        _addr.requireNotZero();
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }    
    
    /**
     * Change of financial administrator - available only to the main administrator
     */
    function setFinancialAddress(address _addr) public onlyAdministrator {
        _addr.requireNotZero();
        financialAddress = _addr;
    }
    
    /**
     * Change of administrator - available only to the main administrator
     */
    function setAdminAddress(address _addr) public onlyAdministrator {
        _addr.requireNotZero();
        administratorAddress = _addr;
    }
    
    /**
     * Change bank announcement message
     */
    function setMessage(string _message) public onlyAdministrator {
        _readme_ = _message;
        emit NewMessage(msg.sender, _message);
    }
    
    /**
     * Change bank website url
     */
    function setWebsiteUrl(string _url) public onlyAdministrator {
        _website_url_ = _url;
    }
    
    function TotalClosedDeposits() public view returns(uint){
        return closedDeposits;
    }
    
    function TotalDeposits() public view returns(uint){
        return totalDeposits;
    }
    
    function ViewRawDeposit(uint _index) public view returns (
            address owner,
            uint256 invested,
            uint256 multiplicator,
            uint256 withdraw,
            uint256 share,
            uint256 gas,
            bool closed
        ){
        
        Deposit storage currentDeposit = deposits[_index];
        
        return (
            currentDeposit.owner,
            currentDeposit.invested,
            currentDeposit.multiplicator,
            currentDeposit.withdraw,
            currentDeposit.share,
            currentDeposit.gas,
            currentDeposit.closed
        );
    }
    
    /**
     * Receipt of payment to the address of the contract
     */
    function () public notContract payable {
        if(msg.value == 0){
            // Withdraw ddeposits if the amount is equal 0 ETH.
            withdraw();
            return;
        }

        // Creates a new deposit or credits funds to an existing
        deposit();
    }
    
    function withdraw() private{
        
        address investorAddr = msg.sender;
        
        investorAddr.requireNotZero();
        require(addressToFinishedDeposits[investorAddr].length > 0, "Investor not have deposits");
        
        uint256 totalWithdrawAmount = 0;
        
        uint256 depositLength = addressToFinishedDeposits[investorAddr].length;
        
        for(uint i = 0; i < depositLength; i++){
            Deposit storage currentDeposit = deposits[i];
            require(currentDeposit.owner == investorAddr, "Access denided!");
            
            if(currentDeposit.closed && currentDeposit.withdraw > 0){
                totalWithdrawAmount = totalWithdrawAmount.add(currentDeposit.withdraw).add(currentDeposit.gas);
                currentDeposit.withdraw = 0;
            }
        }
        
        addressToFinishedDeposits[investorAddr].length = 0;
        
        require(totalWithdrawAmount > 0, "Nothing to withdraw");
        
        investorAddr.transfer(totalWithdrawAmount);
    }
    
    function withdrawDepositById(uint _id) public payable returns(bool)
    {
        address investorAddr = msg.sender;
        
        investorAddr.requireNotZero();
        require(addressToDeposits[investorAddr].length > 0, "Investor not have deposits");
        
        Deposit storage currentDeposit = deposits[_id];
        
        require(currentDeposit.owner == investorAddr, "Access denided!");
        
        uint256 ammountToWithdraw = 0;
        
        if(currentDeposit.closed){
            
            require(currentDeposit.withdraw > 0, "This deposit has already been withdrawn");
            
            ammountToWithdraw = currentDeposit.withdraw.add(currentDeposit.gas);
            currentDeposit.withdraw = 0;
            
            investorAddr.transfer(ammountToWithdraw);
            
        } else {
            
            ammountToWithdraw = currentDeposit.multiplicator.add(CalculateDividents(currentDeposit.share)).add(currentDeposit.gas);
            
            require(ammountToWithdraw > 0, "This deposit balance will be positive");
            
            currentDeposit.closed = true;
            currentDeposit.withdraw = 0;
            closedDeposits++;
            
            investorAddr.transfer(ammountToWithdraw);
        }
        
        emit NewWithdraw(investorAddr, now, ammountToWithdraw); // 2000 gas
    }
    
    /**
     * Creates a new deposit or credits funds to an existing
     */
    function deposit() private {
        
        require(msg.value >= DEPOSIT_MIN, &#39;deposit less then min deposit&#39;);
        
        // Transaction amount
        uint256 amount = msg.value;
        
        //investor address
        address investorAddr = msg.sender;
    
        // Calculate banking free from amount
        uint bankComision = amount.mul(comissionOfBank).div(100);
        
        // Send bank fee to financial address
        //financialAddress.transfer(bankComision);   
        bankFeeBalance = bankFeeBalance.add(bankComision);
        
        amount = amount.sub(bankComision);
        
        // Calculate deposit free from amount
        uint256 multiplicatorAmount = amount.mul(PERCENT_FIRSTINVESTORS).div(100);
        
        uint256 amountToShare = amount.sub(multiplicatorAmount);
        uint256 depositShares = MakeSharesFromAmount(amountToShare);
        
        multiplicatorBalance = multiplicatorBalance.add(multiplicatorAmount);
        calculatedBankBalance = calculatedBankBalance.add(amountToShare);
        totalShares = totalShares.add(depositShares);
        
        uint256 usedGas = ApplyDividentsMultiplicator();
        uint256 gasCompensation = (tx.gasprice <= GAS_COMPENSATION) ? usedGas.mul(tx.gasprice) : usedGas.mul(GAS_COMPENSATION);
        
        if(bankFeeBalance >= gasCompensation){
            bankFeeBalance = bankFeeBalance.sub(gasCompensation);   
        } else {
            gasCompensation = 0;
        }
        
        totalDeposits++;
        uint256 newIndex = totalDeposits;
        
        deposits[newIndex] = Deposit({
            owner: investorAddr,
            invested: msg.value,
            multiplicator: 0,
            withdraw: 0,
            gas: gasCompensation,
            share: depositShares,
            closed: false
        });
        
        addressToDeposits[investorAddr].push(newIndex);

        // Emit event NewDeposit. All emit NewWithdraw(investorAddr, now, ammountToWithdraw); // 2000 gasshareholders held dividends.
        emit NewDeposit(msg.sender, now, msg.value);
    }
    
    function MakeSharesFromAmount(uint256 _amount) private view returns(uint256){
        if (totalShares == 0) return _amount;    

        uint256 sharableAmount = _amount.mul(PERCENT_SHARES).div(100);
        return (_amount.sub(sharableAmount)).mul(totalShares).div(calculatedBankBalance.add(sharableAmount));
    }
    
    function CalculateDividents(uint256 _shares) private view returns(uint256){
        return calculatedBankBalance.mul(_shares) / totalShares;
    }
    
    function CalculateBankCredit() public view returns (
        uint256 credit, 
        uint256 balance, 
        uint256 ){
            
        uint256 amount = 0;
        
        for(uint256 i = 1; i <= totalDeposits; i++){
            
            Deposit storage currentDeposit = deposits[i];
            if(currentDeposit.closed == true){
                if(currentDeposit.withdraw > 0){
                    amount = amount.add(currentDeposit.withdraw).add(currentDeposit.gas);
                }
            } else {
                amount = amount.add(currentDeposit.multiplicator).add(CalculateDividents(currentDeposit.share)).add(currentDeposit.gas);
            }
        }
        
        credit = amount;
        balance = address(this).balance;
    }
    
    function ApplyDividentsMultiplicator() private returns(uint256) {
        
        if(totalDeposits > 3){
            
            uint256 startGas = gasleft();
            
            uint index = 0;
            uint ready = 0;
            uint256 nextIndex = 0;
            
            uint256 updatedMultiplicatorIndex = lastMultiplicatorIndex;
            
            uint256 localMultiplicatorBalance = multiplicatorBalance;
            uint256 localTotalShares = totalShares;
            uint256 localCalculatedBankBalance = calculatedBankBalance;
            
            do {
                
                nextIndex = lastMultiplicatorIndex + index;
                index = index + 1;
                
                Deposit storage currentDeposit = deposits[nextIndex];
                
                if(currentDeposit.closed == false)
                {
                    uint256 depositFinishedAmount   = currentDeposit.invested.mul(uint256 (100).add(PERCENT_MAX_DIVIDENTS)).div(100);
                    uint256 multiplicatorAmount     = currentDeposit.invested.mul(multiplicatorBalance).div(GetTotalAmountForMultiplicator());
                    uint256 currentDepositDividents = CalculateDividents(currentDeposit.share);
                    uint256 available = currentDepositDividents.add(currentDeposit.multiplicator);
                    
                    if(available >= depositFinishedAmount){
                        
                        // If already finished
                        
                        currentDeposit.closed = true;
                        currentDeposit.withdraw = depositFinishedAmount;
                        
                        localTotalShares = localTotalShares.sub(currentDeposit.share);
                        localCalculatedBankBalance = localCalculatedBankBalance.sub(currentDepositDividents);
                        
                        addressToFinishedDeposits[currentDeposit.owner].push(nextIndex);
                        
                        closedDeposits++;
                        
                        if(index == 1){
                            updatedMultiplicatorIndex++;
                        }
                        
                    } else if( available.add(multiplicatorAmount) >= depositFinishedAmount){
                        
                        // if dividents + current multiplicator will finish deposit
                        
                        uint256 personalCalculatedMultiplicator = depositFinishedAmount.sub(available);
                        
                        currentDeposit.closed = true;
                        currentDeposit.multiplicator = currentDeposit.multiplicator.add(personalCalculatedMultiplicator);
                        currentDeposit.withdraw = depositFinishedAmount; //currentDeposit.multiplicator.add(currentDepositDividents);
                        
                        localMultiplicatorBalance = localMultiplicatorBalance.sub(personalCalculatedMultiplicator);
                        localTotalShares = localTotalShares.sub(currentDeposit.share);
                        localCalculatedBankBalance = localCalculatedBankBalance.sub(currentDepositDividents);
                        
                        addressToFinishedDeposits[currentDeposit.owner].push(nextIndex);
                        
                        closedDeposits++;
                        
                        if(index == 1){
                            updatedMultiplicatorIndex++;
                        }
                        
                    } else {
                        
                        // if deposit not finished
                        
                        currentDeposit.multiplicator = currentDeposit.multiplicator.add(multiplicatorAmount);
                        localMultiplicatorBalance = localMultiplicatorBalance.sub(multiplicatorAmount);
                    }
                
                    ready++;
                } else {
                    
                    if(index == 1){
                        updatedMultiplicatorIndex++;
                    }
                }
                
            } while(ready < countDepositsForMultiplicator && nextIndex < totalDeposits);
            
            multiplicatorBalance = localMultiplicatorBalance;
            totalShares = localTotalShares;
            calculatedBankBalance = localCalculatedBankBalance;
            
            lastMultiplicatorIndex = updatedMultiplicatorIndex;
            
            return startGas - gasleft();
        }
        
        return 0;
    }
    
    function GetTotalAmountForMultiplicator() private view returns(uint256){
        
        uint index = 0;
        uint ready = 0;
        uint256 total = 0;
        
        uint nextIndex = 0;
        
        do {
            nextIndex = lastMultiplicatorIndex + index;
            index++;
            
            if(deposits[nextIndex].closed == true || deposits[nextIndex].invested == 0) continue;
            
            total = total.add(deposits[nextIndex].invested);
            ready++;
            
        } while(ready < countDepositsForMultiplicator && nextIndex < totalDeposits);
        
        return total;
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