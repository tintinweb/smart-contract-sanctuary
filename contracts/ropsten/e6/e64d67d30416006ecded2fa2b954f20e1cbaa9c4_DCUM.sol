pragma solidity ^0.4.24;

/**
 * 
 * 
 *  _________                        __             ____ ___      .__                           
 *  \_   ___ \_______ ___.__._______/  |_  ____    |    |   \____ |__| ____  ___________  ____  
 *  /    \  \/\_  __ <   |  |\____ \   __\/  _ \   |    |   /    \|  |/ ___\/  _ \_  __ \/    \ 
 *  \     \____|  | \/\___  ||  |_> >  | (  <_> )  |    |  /   |  \  \  \__(  <_> )  | \/   |  \
 *   \______  /|__|   / ____||   __/|__|  \____/   |______/|___|  /__|\___  >____/|__|  |___|  /
 *          \/        \/     |__|                               \/        \/                 \/ 
 *                          _____                                                               
 *                         /     \   ____   ____   ____ ___.__.                                 
 *                        /  \ /  \ /  _ \ /    \_/ __ <   |  |                                 
 *                       /    Y    (  <_> )   |  \  ___/\___  |                                 
 *                       \____|__  /\____/|___|  /\___  > ____|                                 
 *                               \/            \/     \/\/                                      
 *                                                              
 * 
 *                ,,))))))));,
 *             __)))))))))))))),
 *  \|/       -\(((((&#39;&#39;&#39;&#39;((((((((.
 *  -*-==//////((&#39;&#39;  .     `)))))),
 *  /|\      ))| o    ;-.    &#39;(((((                                  ,(,
 *           ( `|    /  )    ;))))&#39;                               ,_))^;(~
 *              |   |   |   ,))((((_     _____------~~~-.        %,;(;(>&#39;;&#39;~
 *              o_);   ;    )))(((` ~---~  `::           \      %%~~)(v;(`(&#39;~
 *                    ;    &#39;&#39;&#39;&#39;````         `:       `:::|\,__,%%    );`&#39;; ~
 *                   |   _                )     /      `:|`----&#39;     `-&#39;
 *             ______/\/~    |                 /        /
 *           /~;;.____/;;&#39;  /          ___--,-(   `;;;/
 *          / //  _;______;&#39;------~~~~~    /;;/\    /
 *         //  | |                        / ;   \;;,\
 *        (<_  | ;                      /&#39;,/-----&#39;  _>
 *         \_| ||_                     //~;~~~~~~~~~
 *             `\_|                   (,~~  
 *                                     \~\
 *                                      ~~
 * 
 * 
 *             ___________            __               .__                                     
 *              \_   _____/___ _____ _/  |_ __ _________|__| ____    ____                       
 *               |    __)/ __ \\__  \\   __\  |  \_  __ \  |/    \  / ___\                      
 *               |     \\  ___/ / __ \|  | |  |  /|  | \/  |   |  \/ /_/  >                     
 *               \___  / \___  >____  /__| |____/ |__|  |__|___|  /\___  /                      
 *                   \/      \/     \/                          \//_____/                       
 *                            _____  .__       .__                                           
 *                           /     \ |__| ____ |__|                                          
 *                          /  \ /  \|  |/    \|  |                                          
 *                         /    Y    \  |   |  \  |                                          
 *                         \____|__  /__|___|  /__|                                          
 *                                 \/        \/                                              
 *                    .____                     .___                                         
 *                    |    |    _________     __| _/______                                   
 *                    |    |   /  _ \__  \   / __ |/  ___/                                   
 *                    |    |__(  <_> ) __ \_/ /_/ |\___ \                                    
 *                    |_______ \____(____  /\____ /____  >                                   
 *                            \/         \/      \/    \/                                    
 *                   ____    __________________ ________                                     
 *                  /  _ \   \______   \_____  \\______ \                                    
 *                  >  _ </\  |     ___/ _(__  < |    |  \                                   
 *                 /  <_\ \/  |    |    /       \|    `   \                                  
 *                 \_____\ \  |____|   /______  /_______  /                                  
 *                        \/                  \/        \/                                   
 *                                                                                           
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
 * set to 150%, and pointed at PoWH:
 * 0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe
 * 
 * But you should verify this for yourself.
 *  
 *  
 */

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

contract POWH {
    
    function buy(address) public payable returns(uint256);
    function withdraw() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
}

contract Owned {
    address public owner;
    address public ownerCandidate;

    constructor() public {
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

contract DCUM is Owned {
    
    /**
     * Modifiers
     */
     
    /**
     * Only owners are allowed.
     */
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    /**
     * The tokens can never be stolen.
     */
    modifier notPowh(address aContract){
        require(aContract != address(weak_hands));
        _;
    }
   
    /**
     * Events
     */
    event Deposit(uint256 amount, address depositer);
    event Purchase(uint256 amountSpent, uint256 tokensReceived);
    event Payout(uint256 amount, address creditor);
    event Dividends(uint256 amount);
    event Donation(uint256 amount, address donator);
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
    POWH weak_hands;

    /**
     * Constructor
     */
    constructor () public {
        //multiplier = multiplierPercent;
        //weak_hands = POWH(powh);
        multiplier = 150;
        weak_hands = POWH(0xacf80Ce1bF7CaaF8a8d317Fb9e8e2cEBcf764D4E);
    }
    
    
    /**
     * Fallback function allows anyone to send money for the cost of gas which
     * goes into the pool. Used by withdraw/dividend payouts so it has to be cheap.
     */
    function() payable public {
    }
    
    /**
     * Deposit ETH to get in line to be credited back the multiplier as a percent,
     * add that ETH to the pool, get the dividends and put them in the pool,
     * then pay out who we owe and buy more tokens.
     */ 
    function deposit() payable public {
        //You have to send more than 1000000 wei.
        require(msg.value > 1000000);
        //<ax deposit is 2 ETH
        require(msg.value < 2000000000000000001);
        //Compute how much to pay them
        uint256 amountCredited = (msg.value * multiplier) / 100;
        //Get in line to be paid back.
        participants.push(Participant(msg.sender, amountCredited));
        //Increase the backlog by the amount owed
        backlog += amountCredited;
        //Increase the amount owed to this address
        creditRemaining[msg.sender] += amountCredited;
        //Emit a deposit event.
        emit Deposit(msg.value, msg.sender);
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
        uint investment = balance / 2;
        //Take away the amount we are investing from the amount to send
        balance -= investment;
        //Invest it in more tokens.
        uint256 tokens = weak_hands.buy.value(investment).gas(1000000)(msg.sender);
        //Record that tokens were purchased
        emit Purchase(investment, tokens);
        //While we still have money to send
        while (balance > 0) {
            //Either pay them what they are owed or however much we have, whichever is lower.
            uint payoutToSend = balance < participants[payoutOrder].payout ? balance : participants[payoutOrder].payout;
            //if we have something to pay them
            if(payoutToSend > 0){
                //subtract how much we&#39;ve spent
                balance -= payoutToSend;
                //subtract the amount paid from the amount owed
                backlog -= payoutToSend;
                //subtract the amount remaining they are owed
                creditRemaining[participants[payoutOrder].etherAddress] -= payoutToSend;
                //credit their account the amount they are being paid
                participants[payoutOrder].payout -= payoutToSend;
                //Try and pay them, making best effort. But if we fail? Run out of gas? That&#39;s not our problem any more.
                if(participants[payoutOrder].etherAddress.call.value(payoutToSend).gas(1000000)()){
                    //Record that they were paid
                    emit Payout(payoutToSend, participants[payoutOrder].etherAddress);
                }else{
                    //undo the accounting, they are being skipped because they are not payable.
                    balance += payoutToSend;
                    backlog += payoutToSend;
                    creditRemaining[participants[payoutOrder].etherAddress] += payoutToSend;
                    participants[payoutOrder].payout += payoutToSend;
                }

            }
            //If we still have balance left over
            if(balance > 0){
                // go to the next person in line
                payoutOrder += 1;
            }
            //If we&#39;ve run out of people to pay, stop
            if(payoutOrder >= participants.length){
                return;
            }
        }
    }
    
    /**
     * Number of tokens the contract owns.
     */
    function myTokens() public view returns(uint256){
        return weak_hands.myTokens();
    }
    
    /**
     * Number of dividends owed to the contract.
     */
    function myDividends() public view returns(uint256){
        return weak_hands.myDividends(true);
    }
    
    /**
     * Number of dividends received by the contract.
     */
    function totalDividends() public view returns(uint256){
        return dividends;
    }
    
    
    /**
     * Request dividends be paid out and added to the pool.
     */
    function withdraw() public {
        uint256 balance = address(this).balance;
        weak_hands.withdraw.gas(1000000)();
        uint256 dividendsPaid = address(this).balance - balance;
        dividends += dividendsPaid;
        emit Dividends(dividendsPaid);
    }
    
    /**
     * A charitible contribution will be added to the pool.
     */
    function donate() payable public {
        emit Donation(msg.value, msg.sender);
    }
    
    /**
     * Number of participants who are still owed.
     */
    function backlogLength() public view returns (uint256){
        return participants.length - payoutOrder;
    }
    
    /**
     * Total amount still owed in credit to depositors.
     */
    function backlogAmount() public view returns (uint256){
        return backlog;
    } 
    
    /**
     * Total number of deposits in the lifetime of the contract.
     */
    function totalParticipants() public view returns (uint256){
        return participants.length;
    }
    
    /**
     * Total amount of ETH that the contract has delt with so far.
     */
    function totalSpent() public view returns (uint256){
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
    function amountIAmOwed() public view returns (uint256){
        return amountOwed(msg.sender);
    }
    
    /**
     * A trap door for when someone sends tokens other than the intended ones so the overseers can decide where to send them.
     */
    function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) public onlyOwner notPowh(tokenAddress) returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
    
}