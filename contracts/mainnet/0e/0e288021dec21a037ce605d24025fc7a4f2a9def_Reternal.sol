pragma solidity ^0.4.24;

/**
 * ██████╗     ███████╗████████╗███████╗ ██████╗    ███╗        ██╗    █████╗    ██╗     
 * ██╔══██╗  ██╔════╝╚══██╔══╝██╔════╝ ██╔══██╗  ████╗     ██║ ██╔══██╗ ██║     
 * ██████╔╝  █████╗              ██║        █████╗      ██████╔╝  ██╔██╗   ██║ ███████║ ██║     
 * ██╔══██╗  ██╔══╝              ██║        ██╔══╝      ██╔══██╗  ██║╚██╗██║ ██╔══██║ ██║     
 * ██║      ██║ ███████╗         ██║        ███████╗ ██║      ██║ ██║   ╚████║ ██║     ██║ ███████╗
 * ╚═╝      ╚═╝ ╚══════╝         ╚═╝        ╚══════╝ ╚═╝      ╚═╝ ╚═╝      ╚═══╝╚═╝      ╚═╝╚══════╝    
 * 
 *  Contacts:
 * 
 *   -- t.me/Reternal
 *   -- https://www.reternal.net
 * 
 * - GAIN PER 24 HOURS:
 * 
 *     -- Individual balance < 1 Ether: 3.15%
 *     -- Individual balance >= 1 Ether: 3.25%
 *     -- Individual balance >= 4 Ether: 3.45%
 *     -- Individual balance >= 12 Ether: 3.65%
 *     -- Individual balance >= 50 Ether: 3.85%
 *     -- Individual balance >= 200 Ether: 4.15%
 * 
 *     -- Contract balance < 500 Ether: 0%
 *     -- Contract balance >= 500 Ether: 0.10%
 *     -- Contract balance >= 1500 Ether: 0.20%
 *     -- Contract balance >= 2500 Ether: 0.30%
 *     -- Contract balance >= 7000 Ether: 0.45%
 *     -- Contract balance >= 15000 Ether: 0.65%
 * 
 *  - Minimal contribution 0.01 eth
 *  - Contribution allocation schemes:
 *    -- 95% payments
 *    -- 5% Marketing + Operating Expenses
 * 
 * - How to use:
 *  1. Send from your personal ETH wallet to the smart-contract address any amount more than or equal to 0.01 ETH
 *  2. Add your refferer&#39;s wallet to a HEX data in your transaction to 
 *     get a bonus amount back to your wallet only for the FIRST deposit
 *     IMPORTANT: if you want to support Reternal project, you can leave your HEX data field empty, 
 *                if you have no referrer and do not want to support Reternal, you can type &#39;noreferrer&#39;
 *                if there is no referrer, you will not get any bonuses
 *  3. Use etherscan.io to verify your transaction 
 *  4. Claim your dividents by sending 0 ether transaction (available anytime)
 *  5. You can reinvest anytime you want
 *
 * RECOMMENDED GAS LIMIT: 200000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 * 
 * The smart-contract has a "restart" function, more info at www.reternal.net
 * 
 * If you want to check your dividents, you can use etherscan.io site, following the "Internal Txns" tab of your wallet
 * WARNING: do not use exchanges&#39; wallets - you will loose your funds. Only use your personal wallet for transactions 
 * 
 */

contract Reternal {
    
    // Investor&#39;s data storage
    mapping (address => Investor) public investors;
    address[] public addresses;
    
    struct Investor
    {
        uint id;
        uint deposit;
        uint depositCount;
        uint block;
        address referrer;
    }
    
    uint constant public MINIMUM_INVEST = 10000000000000000 wei;
    address defaultReferrer = 0x25EDFd665C2898c2898E499Abd8428BaC616a0ED;
    
    uint public round;
    uint public totalDepositAmount;
    bool public pause;
    uint public restartBlock;
    bool ref_flag;
    
    // Investors&#39; dividents increase goals due to a bank growth
    uint bank1 = 5e20; // 500 eth
    uint bank2 = 15e20; // 1500 eth
    uint bank3 = 25e20; // 2500 eth
    uint bank4 = 7e21; // 7000 eth
    uint bank5 = 15e20; // 15000 eth
    // Investors&#39; dividents increase due to individual deposit amount
    uint dep1 = 1e18; // 1 ETH
    uint dep2 = 4e18; // 4 ETH
    uint dep3 = 12e18; // 12 ETH
    uint dep4 = 5e19; // 50 ETH
    uint dep5 = 2e20; // 200 ETH
    
    event NewInvestor(address indexed investor, uint deposit, address referrer);
    event PayOffDividends(address indexed investor, uint value);
    event refPayout(address indexed investor, uint value, address referrer);
    event NewDeposit(address indexed investor, uint value);
    event NextRoundStarted(uint round, uint block, address addr, uint value);
    
    constructor() public {
        addresses.length = 1;
        round = 1;
        pause = false;
    }

    function restart() private {
        address addr;

        for (uint i = addresses.length - 1; i > 0; i--) {
            addr = addresses[i];
            addresses.length -= 1;
            delete investors[addr];
        }
        
        emit NextRoundStarted(round, block.number, msg.sender, msg.value);
        pause = false;
        round += 1;
        totalDepositAmount = 0;
        
        createDeposit();
    }

    function getRaisedPercents(address addr) internal view  returns(uint){
        // Individual deposit percentage sums up with &#39;Reternal total fund&#39; percentage
        uint percent = getIndividualPercent() + getBankPercent();
        uint256 amount = investors[addr].deposit * percent / 100*(block.number-investors[addr].block)/6000;
        return(amount / 100);
    }
    
    function payDividends() private{
        require(investors[msg.sender].id > 0, "Investor not found.");
        // Investor&#39;s total raised amount
        uint amount = getRaisedPercents(msg.sender);
            
        if (address(this).balance < amount) {
            pause = true;
            restartBlock = block.number + 6000;
            return;
        }
        
        // Service fee deduction 
        uint FeeToWithdraw = amount * 5 / 100;
        uint payment = amount - FeeToWithdraw;
        
        address(0xD9bE11E7412584368546b1CaE64b6C384AE85ebB).transfer(FeeToWithdraw);
        msg.sender.transfer(payment);
        emit PayOffDividends(msg.sender, amount);
        
    }
    
    function createDeposit() private{
        Investor storage user = investors[msg.sender];
        
        if (user.id == 0) {
            
            // Check for malicious smart-contract
            msg.sender.transfer(0 wei);
            user.id = addresses.push(msg.sender);

            if (msg.data.length != 0) {
                address referrer = bytesToAddress(msg.data);
                
                // Check for referrer&#39;s registration. Check for self referring
                if (investors[referrer].id > 0 && referrer != msg.sender) {
                    user.referrer = referrer;
                    
                    // Cashback only for the first deposit
                    if (user.depositCount == 0) { // cashback only for the first deposit
                        uint cashback = msg.value / 100;
                        if (msg.sender.send(cashback)) {
                            emit refPayout(msg.sender, cashback, referrer);
                        }
                    }
                }
            } else {
                // If data is empty:
                user.referrer = defaultReferrer;
            }
            
            emit NewInvestor(msg.sender, msg.value, referrer);
            
        } else {
            // Dividents payment for an investor
            payDividends();
        }
        
        // 2% from a referral deposit transfer to a referrer
        uint payReferrer = msg.value * 2 / 100; // 2% from referral deposit to referrer
        
        //
        if (user.referrer == defaultReferrer) {
            user.referrer.transfer(payReferrer);
        } else {
            investors[referrer].deposit += payReferrer;
        }
        
        
        user.depositCount++;
        user.deposit += msg.value;
        user.block = block.number;
        totalDepositAmount += msg.value;
        emit NewDeposit(msg.sender, msg.value);
    }

    function() external payable {
        if(pause) {
            if (restartBlock <= block.number) { restart(); }
            require(!pause, "Eternal is restarting, wait for the block in restartBlock");
        } else {
            if (msg.value == 0) {
                payDividends();
                return;
            }
            require(msg.value >= MINIMUM_INVEST, "Too small amount, minimum 0.01 ether");
            createDeposit();
        }
    }
    
    function getBankPercent() public view returns(uint){
        
        uint contractBalance = address(this).balance;
        
        uint totalBank1 = bank1;
        uint totalBank2 = bank2;
        uint totalBank3 = bank3;
        uint totalBank4 = bank4;
        uint totalBank5 = bank5;
        
        if(contractBalance < totalBank1){
            return(0); // If bank lower than 500, whole procent doesnt add
        }
        if(contractBalance >= totalBank1 && contractBalance < totalBank2){
            return(10); // If bank amount more than or equal to 500 ETH, whole procent add 0.10%
        }
        if(contractBalance >= totalBank2 && contractBalance < totalBank3){
            return(20); // If bank amount more than or equal to 1500 ETH, whole procent add 0.10%
        }
        if(contractBalance >= totalBank3 && contractBalance < totalBank4){
            return(30); // If bank amount more than or equal to 2500 ETH, whole procent add 0.10%
        }
        if(contractBalance >= totalBank4 && contractBalance < totalBank5){
            return(45); // If bank amount more than or equal to 7000 ETH, whole procent add 0.15%
        }
        if(contractBalance >= totalBank5){
            return(65); // If bank amount more than or equal to 15000 ETH, whole procent add 0.20%
        }
    }

    function getIndividualPercent() public view returns(uint){
        
        uint userBalance = investors[msg.sender].deposit;
        
        uint totalDeposit1 = dep1;
        uint totalDeposit2 = dep2;
        uint totalDeposit3 = dep3;
        uint totalDeposit4 = dep4;
        uint totalDeposit5 = dep5;
        
        if(userBalance < totalDeposit1){
            return(315); // 3.15% by default, investor deposit lower than 1 ETH
        }
        if(userBalance >= totalDeposit1 && userBalance < totalDeposit2){
            return(325); // 3.25% Your Deposit more than or equal to 1 ETH
        }
        if(userBalance >= totalDeposit2 && userBalance < totalDeposit3){
            return(345); // 3.45% Your Deposit more than or equal to 4 ETH
        }
        if(userBalance >= totalDeposit3 && userBalance < totalDeposit4){
            return(360); // 3.60% Your Deposit more than or equal to 12 ETH  
        }
        if(userBalance >= totalDeposit4 && userBalance < totalDeposit5){
            return(385); // 3.85% Your Deposit more than or equal to 50 ETH
        }
        if(userBalance >= totalDeposit5){
            return(415); // 4.15% Your Deposit more than or equal to 200 ETH
        }
    }
    
    function getInvestorCount() public view returns (uint) {
        return addresses.length - 1;
    }
    
    function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

}