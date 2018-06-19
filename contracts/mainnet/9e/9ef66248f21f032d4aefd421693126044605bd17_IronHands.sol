pragma solidity 0.4.23;

/*
 * ATTENTION!
 * 
 * This code? IS NOT DESIGNED FOR ACTUAL USE.
 * 
 * The author of this code really wishes you wouldn&#39;t send your ETH to it.
 * 
 * No, seriously. It&#39;s probablly illegal anyway. So don&#39;t do it.
 * 
 * Let me repeat that: Don&#39;t actually send money to this contract. You are 
 * likely breaking several local and national laws in doing so.
 * 
 * This code is intended to educate. Nothing else. If you use it, expect S.W.A.T 
 * teams at your door. I wrote this code because I wanted to experiment
 * with smart contracts, and I think code should be open source. So consider
 * it public domain, No Rights Reserved. Participating in pyramid schemes
 * is genuinely illegal so just don&#39;t even think about going beyond
 * reading the code and understanding how it works.
 * 
 * Seriously. I&#39;m not kidding. It&#39;s probablly broken in some critical way anyway
 * and will suck all your money out your wallet, install a virus on your computer
 * sleep with your wife, kidnap your children and sell them into slavery,
 * make you forget to file your taxes, and give you cancer.
 * 
 * So.... tl;dr: This contract sucks, don&#39;t send money to it.
 * 
 * What it does:
 * 
 * It takes 50% of the ETH in it and buys tokens.
 * It takes 50% of the ETH in it and pays back depositors.
 * Depositors get in line and are paid out in order of deposit, plus the deposit
 * percent.
 * The tokens collect dividends, which in turn pay into the payout pool
 * to be split 50/50.
 * 
 * If your seeing this contract in it&#39;s initial configuration, it should be
 * set to 200% (double deposits), and pointed at POTJ:
 * 0xC28E860C9132D55A184F9af53FC85e90Aa3A0153
 * 
 * But you should verify this for yourself.
 *  
 *  
 */

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

contract POTJ {
    
    function buy(address) public payable returns(uint256);
    function withdraw() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
}

contract Owned {
    address public owner;
    address public ownerCandidate;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        ownerCandidate = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == ownerCandidate);  
        owner = ownerCandidate;
    }
    
}

contract IronHands is Owned {
    
    /**
     * Modifiers
     */
     
    /**
     * Only owners are allowed.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /**
     * The tokens can never be stolen.
     */
    modifier notPotj(address aContract) {
        require(aContract != address(potj));
        _;
    }
   
    /**
     * Events
     */
    event Deposit(uint256 amount, address depositer);
    event Purchase(uint256 amountSpent, uint256 tokensReceived);
    event Payout(uint256 amount, address creditor);
    event Dividends(uint256 amount);
    event ContinuityBreak(uint256 position, address skipped, uint256 amount);
    event ContinuityAppeal(uint256 oldPosition, uint256 newPosition, address appealer);

    /**
     * Structs
     */
    struct Participant {
        address etherAddress;
        uint256 payout;
    }

    //Total ETH managed over the lifetime of the contract
    uint256 throughput;
    //Total ETH received from dividends
    uint256 dividends;
    //The percent to return to depositers. 100 for 00%, 200 to double, etc.
    uint256 public multiplier;
    //Where in the line we are with creditors
    uint256 public payoutOrder = 0;
    //How much is owed to people
    uint256 public backlog = 0;
    //The creditor line
    Participant[] public participants;
    //How much each person is owed
    mapping(address => uint256) public creditRemaining;
    //What we will be buying
    POTJ potj;
    
    address sender;

    /**
     * Constructor
     */
    function IronHands(uint multiplierPercent, address potjAddress) public {
        multiplier = multiplierPercent;
        potj = POTJ(potjAddress);
        sender = msg.sender;
    }
    
    
    /**
     * Fallback function allows anyone to send money for the cost of gas which
     * goes into the pool. Used by withdraw/dividend payouts so it has to be cheap.
     */
    function() payable public {
        if (msg.sender != address(potj)) {
            deposit();
        }
    }
    
    /**
     * Deposit ETH to get in line to be credited back the multiplier as a percent,
     * add that ETH to the pool, get the dividends and put them in the pool,
     * then pay out who we owe and buy more tokens.
     */ 
    function deposit() payable public {
        //You have to send more than 1000000 wei.
        require(msg.value > 1000000);
        //Compute how much to pay them
        uint256 amountCredited = (msg.value * multiplier) / 100;
        //Get in line to be paid back.
        participants.push(Participant(sender, amountCredited));
        //Increase the backlog by the amount owed
        backlog += amountCredited;
        //Increase the amount owed to this address
        creditRemaining[sender] += amountCredited;
        //Emit a deposit event.
        emit Deposit(msg.value, sender);
        //If I have dividends
        if(myDividends() > 0){
            //Withdraw dividends
            withdraw();
        }
        //Pay people out and buy more tokens.
        payout();
    }
    
    /**
     * Take 50% of the money and spend it on tokens, which will pay dividends later.
     * Take the other 50%, and use it to pay off depositors.
     */
    function payout() public {
        //Take everything in the pool
        uint balance = address(this).balance;
        //It needs to be something worth splitting up
        require(balance > 1);
        //Increase our total throughput
        throughput += balance;
        //Split it into two parts
        uint investment = balance / 2 ether + 1 szabo; // avoid rounding issues
        //Take away the amount we are investing from the amount to send
        balance -= investment;
        //Invest it in more tokens.
        uint256 tokens = potj.buy.value(investment).gas(1000000)(msg.sender);
        //Record that tokens were purchased
        emit Purchase(investment, tokens);
        //While we still have money to send
        while (balance > 0) {
            //Either pay them what they are owed or however much we have, whichever is lower.
            uint payoutToSend = balance < participants[payoutOrder].payout ? balance : participants[payoutOrder].payout;
            //if we have something to pay them
            if(payoutToSend > 0) {
                //subtract how much we&#39;ve spent
                balance -= payoutToSend;
                //subtract the amount paid from the amount owed
                backlog -= payoutToSend;
                //subtract the amount remaining they are owed
                creditRemaining[participants[payoutOrder].etherAddress] -= payoutToSend;
                //credit their account the amount they are being paid
                participants[payoutOrder].payout -= payoutToSend;
                //Try and pay them, making best effort. But if we fail? Run out of gas? That&#39;s not our problem any more.
                if(participants[payoutOrder].etherAddress.call.value(payoutToSend).gas(1000000)()) {
                    //Record that they were paid
                    emit Payout(payoutToSend, participants[payoutOrder].etherAddress);
                } else {
                    //undo the accounting, they are being skipped because they are not payable.
                    balance += payoutToSend;
                    backlog += payoutToSend;
                    creditRemaining[participants[payoutOrder].etherAddress] += payoutToSend;
                    participants[payoutOrder].payout += payoutToSend;
                }

            }
            //If we still have balance left over
            if(balance > 0) {
                // go to the next person in line
                payoutOrder += 1;
            }
            //If we&#39;ve run out of people to pay, stop
            if(payoutOrder >= participants.length) {
                return;
            }
        }
    }
    
    /**
     * Number of tokens the contract owns.
     */
    function myTokens() public view returns(uint256) {
        return potj.myTokens();
    }
    
    /**
     * Number of dividends owed to the contract.
     */
    function myDividends() public view returns(uint256) {
        return potj.myDividends(true);
    }
    
    /**
     * Number of dividends received by the contract.
     */
    function totalDividends() public view returns(uint256) {
        return dividends;
    }
    
    
    /**
     * Request dividends be paid out and added to the pool.
     */
    function withdraw() public {
        uint256 balance = address(this).balance;
        potj.withdraw.gas(1000000)();
        uint256 dividendsPaid = address(this).balance - balance;
        dividends += dividendsPaid;
        emit Dividends(dividendsPaid);
    }
    
    /**
     * Number of participants who are still owed.
     */
    function backlogLength() public view returns (uint256) {
        return participants.length - payoutOrder;
    }
    
    /**
     * Total amount still owed in credit to depositors.
     */
    function backlogAmount() public view returns (uint256) {
        return backlog;
    } 
    
    /**
     * Total number of deposits in the lifetime of the contract.
     */
    function totalParticipants() public view returns (uint256) {
        return participants.length;
    }
    
    /**
     * Total amount of ETH that the contract has delt with so far.
     */
    function totalSpent() public view returns (uint256) {
        return throughput;
    }
    
    /**
     * Amount still owed to an individual address
     */
    function amountOwed(address anAddress) public view returns (uint256) {
        return creditRemaining[anAddress];
    }
     
     /**
      * Amount owed to this person.
      */
    function amountIAmOwed() public view returns (uint256) {
        return amountOwed(msg.sender);
    }
    
    /**
     * A trap door for when someone sends tokens other than the intended ones so the overseers can decide where to send them.
     */
    function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) public onlyOwner notPotj(tokenAddress) returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
    
}