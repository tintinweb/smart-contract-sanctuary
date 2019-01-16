pragma solidity ^0.4.25;
//0xd05a24258231aa3748bafd310d73a785e18f2b9b

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
    
    struct InvestorDepositInfo {
        uint depositIndex;
        bool closed;
    }
    struct InvestorStruct {
        uint keyIndex;
        InvestorDepositInfo[] deposits;
        uint depositsNum;
        uint totalInvested;
        uint totalWithdrawed;
    }
    struct DepositStruct {
        address investorAddr;
        uint investorDepositIndex;
        uint invested;
        uint amount;
        uint shares;
        uint dividents;
        uint dividentsShares;
        bool closed;
        bool withdrawed;
    }
    mapping(address => InvestorStruct) public investors;
    address[] private investorIndex;
    
    uint public depositsNum;
    mapping(uint => DepositStruct) public deposits;
    
    uint public depositsClosedNum;
    mapping(uint => DepositStruct) public depositsClosed;

    
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
    
    //***************** Banking fee  *****************//
    
    // Bank fee for opening or expanding a deposit
    // This fee may be changed by the financial administrator
    // Fee may vary from 0 to 2
    // Values: 2%
    uint256 public comissionOfBank = 2;
    
    // Minimum deposit 0.01 ETH. Cannot be changed
    uint256 constant public DEPOSIT_MIN = 10 finney;
    
    // Total balance of shares
    uint256 public totalShares;
    
    //максимальная инвестированая шара 
    uint256 public maxShare;
    
    //с какого индекса начислять дивиденды
    uint public fromIndex;
    

    
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
        
        investorIndex.length++;
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
    
    function totalInvestors() public view returns(uint) {
        return investorIndex.length-1;
    }
    
    function investorDeposit(address investorAddress, uint depositIndex) public view returns(
        address investorAddr,
        uint investorDepositIndex,
        uint invested,
        uint amount,
        uint shares,
        uint dividents,
        uint dividentsShares,
        bool closed,
        bool withdrawed) {
        DepositStruct memory ds;
        if(investors[investorAddress].deposits[depositIndex].closed){
            ds = depositsClosed[investors[investorAddress].deposits[depositIndex].depositIndex];
        }else{
            ds = deposits[investors[investorAddress].deposits[depositIndex].depositIndex];
        }
        
        return (
            ds.investorAddr, 
            ds.investorDepositIndex, 
            ds.invested, 
            ds.amount, 
            ds.shares, 
            ds.dividents, 
            ds.dividentsShares, 
            ds.closed, 
            ds.withdrawed
        );
    }
    
    /**
     * Receipt of payment to the address of the contract
     */
    function () public notContract payable {
        if(msg.value == 0){
            // Withdraw ddeposits if the amount is equal 0 ETH.
            withdrawMyClosedDeposits();
            return;
        }

        // Creates a new deposit or credits funds to an existing
        deposit();
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
        
        // Calculate deposit free from amount
        uint percentShares = amount.mul(PERCENT_SHARES).div(100);
        uint percentFirstInvestors = amount.mul(PERCENT_FIRSTINVESTORS).div(100);
        
        // Calculate banking free from amount
        uint bankComision = amount.mul(comissionOfBank).div(100);
        
        // Send bank fee to financial address
        financialAddress.transfer(bankComision);        
        
        // Subtract the bank fee from the incoming amount
        amount = amount.sub(bankComision.add(percentShares).add(percentFirstInvestors));
        
        //Update shares balance
        totalShares = totalShares.add(percentShares);
        if(percentShares > maxShare){
            maxShare = percentShares;
        }
    
        updateFirstDeposits(percentFirstInvestors);
        
        if(investors[investorAddr].keyIndex == 0){
            uint keyIndex = investorIndex.length++;
            investors[investorAddr].keyIndex = keyIndex;
            investorIndex[keyIndex] = investorAddr;
        }

        investors[investorAddr].deposits.length++;
        investors[investorAddr].deposits[investors[investorAddr].depositsNum] = InvestorDepositInfo({
            depositIndex: depositsNum,
            closed: false
        });
        investors[investorAddr].totalInvested = investors[investorAddr].totalInvested.add(msg.value);
        
        //create new deposit record
        deposits[depositsNum] = DepositStruct({
            investorAddr: investorAddr,
            investorDepositIndex: investors[investorAddr].depositsNum,
            invested: msg.value,
            amount: amount,
            shares: percentShares,
            dividents: 0,
            dividentsShares: 0,
            closed: false,
            withdrawed: false
        });
        
        //increase counters
        depositsNum++;
        investors[investorAddr].depositsNum++;
        
        // Emit event NewDeposit. All shareholders held dividends.
        emit NewDeposit(msg.sender, now, msg.value);
    }
    
    function withdrawMyClosedDeposits() public {
        //investor address
        address investorAddr = msg.sender;
        
        require(investors[investorAddr].keyIndex > 0, "address not investor yet");
        require(investors[investorAddr].depositsNum > 0, "not have deposits");
        
        DepositStruct memory ds;
        for(uint i=0;i<investors[investorAddr].depositsNum;i++){
            if(!investors[investorAddr].deposits[i].closed && !checkAndCloseDeposit(investors[investorAddr].deposits[i].depositIndex)){
                continue;
            }
            
            ds = depositsClosed[investors[investorAddr].deposits[i].depositIndex];
            if(ds.withdrawed){
                continue;
            }
            
            uint amountForWithrdraw = ds.amount;
            amountForWithrdraw = amountForWithrdraw.add(ds.dividents).add(ds.dividentsShares);
            depositsClosed[investors[investorAddr].deposits[i].depositIndex].withdrawed = true;
            
            // Sending account deposit with dividends to the 
            // address from which the payment was requested
            investorAddr.transfer(amountForWithrdraw);
            
            // Emit event NewWithdraw. All shareholders held dividends.
            emit NewWithdraw(investorAddr, now, amountForWithrdraw);
        }
    }

    function withdrawMyDeposit(uint depositIndex) public {
        //investor address
        address investorAddress = msg.sender;
        
        require(investors[investorAddress].keyIndex > 0, "address not investor yet");
        require(depositIndex >= 0 && depositIndex < investors[investorAddress].depositsNum, "deposit not found");
        
        uint _depositIndex = investors[investorAddress].deposits[depositIndex].depositIndex;
        
        DepositStruct memory ds;
        if(investors[investorAddress].deposits[depositIndex].closed){
            //если депозит закрыт, то получаем его
            ds = depositsClosed[_depositIndex];
        }else{
            //закрываем депозит перед выводом
            require(checkAndCloseDeposit(_depositIndex, true), "error on close deposit");
            _depositIndex = investors[investorAddress].deposits[depositIndex].depositIndex;
            ds = depositsClosed[_depositIndex];
        }
        
        //проверяем не выплачивали ли уже по этому депозиту
        require(!ds.withdrawed, &#39;deposit alredy withdrawed&#39;);
        
        uint amountForWithrdraw = ds.amount;
        amountForWithrdraw = amountForWithrdraw.add(ds.dividents).add(ds.dividentsShares);
        depositsClosed[_depositIndex].withdrawed = true;
        
        // Sending account deposit with dividends to the 
        // address from which the payment was requested
        investorAddress.transfer(amountForWithrdraw);
        
        // Emit event NewWithdraw. All shareholders held dividends.
        emit NewWithdraw(investorAddress, now, amountForWithrdraw);
    }
    
    function getTotalAmountOfFirstInvestors(uint maxIterations) private view returns (uint) {
        uint total = 0;
        for(uint i=0;i<maxIterations;i++){
            if(deposits[i].closed || deposits[i].invested == 0){ continue; }
            total = total.add(deposits[i].invested);
        }
        
        return total;
    }

    function updateFirstDeposits(uint percentFirstInvestors) private {
        if(depositsNum == 0) return;

        uint maxIterations = depositsNum > fromIndex+20 ? fromIndex+20 : depositsNum;
        uint totalAmount = getTotalAmountOfFirstInvestors(maxIterations);

        bool isEmpty = true;
        for(uint i=fromIndex;i<maxIterations;i++){
            if(deposits[i].closed || deposits[i].invested == 0){ 
                fromIndex++;
                continue; 
            }

            isEmpty = false;
            deposits[i].dividents = deposits[i].dividents.add(
                                        deposits[i].invested.mul(percentFirstInvestors).div(totalAmount)
                                    );
            checkAndCloseDeposit(i);
        }
    }
    
    function isReadyForClose(uint index) private returns(bool) {
        deposits[index].dividentsShares = getDividentsFromShare(index);
        if(deposits[index].dividents.add(deposits[index].amount).add(deposits[index].dividentsShares) < deposits[index].invested.mul(PERCENT_MAX_DIVIDENTS+100).div(100)){
            return false;
        }
        
        return true;
    }


    function checkAndCloseDeposit(uint index)  private returns(bool isClosed) {
        return checkAndCloseDeposit(index, false);
    }
    function checkAndCloseDeposit(uint index, bool closeAnyway)  private returns(bool isClosed) {
        if (index >= depositsNum) return false;
        
        if(!isReadyForClose(index) && !closeAnyway){
            return false;
        }

        totalShares = totalShares.sub(deposits[index].shares);
        
        deposits[index].closed = true;
        
        depositsClosed[depositsClosedNum] = deposits[index];
        depositsClosed[depositsClosedNum].closed = true;
        
        investors[depositsClosed[depositsClosedNum].investorAddr]
                .deposits[depositsClosed[depositsClosedNum].investorDepositIndex]
                .depositIndex = depositsClosedNum;
        investors[depositsClosed[depositsClosedNum].investorAddr]
                .deposits[depositsClosed[depositsClosedNum].investorDepositIndex]
                .closed = true;
        
        depositsClosedNum++;
        
        if(index == fromIndex) fromIndex++;
        return true;
    }
    
    function getDividentsFromShare(uint i) public view returns(uint) {
        return totalShares.mul(10 finney).div(i+1).div(maxShare);// .mul(deposits[i].shares.mul(100).div(totalShares)).div(100);
    }
    
    function clearDeposits() public {
        uint diff = 0;
        for(uint i=0;i<depositsNum;i++){
            if(i+diff >= depositsNum){
                delete deposits[i];
                continue;
            }
            
            if(diff == 0 && (deposits[i].closed || deposits[i].invested == 0) ){
                diff++;
            }
            
            if(diff == 0) continue;
            
            do{
                if(!deposits[i+diff].closed && deposits[i+diff].invested > 0){
                    deposits[i] = deposits[i+diff];
                    
                    //update index in investor deposits
                    investors[deposits[i].investorAddr]
                        .deposits[deposits[i].investorDepositIndex]
                        .depositIndex = i;
                    
                    break;
                }
                diff++;
            } while (i+diff < depositsNum);
        }
        
        depositsNum -= diff;
        
        fromIndex = 0;
    }
    
//----------------------- OLD CODE -------------------------------------------------    

    /**
     * Deposit closing and dividend payout
     */


    // /**
    //  * Available balance for withdrawal including dividends and a deduction 
    //  * of the commission for closing the deposit
    //  */
    // function availableForWithdraw(address _account) public view returns(uint256) {
        
    //     // Check account availability in holders
    //     require(shares[_account] > 0, "Not enought balance");
        
    //     // Checking the overall balance of the holders
    //     require(totalShares > 0);
        
    //     // Calculate the account balance and the accumulated dividends 
    //     // and deduct the commission for closing
    //     // CONTRACT BALANCE * ACCOUNT SHARES * 95% / TOTAL SHARES / 100
        
    //     return address(this).balance.mul(shares[_account])
    //                 .mul((uint256) (100).sub(PERCENT_WITHDRAW))
    //                 .div(totalShares)
    //                 .div(100);
    // }
    

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