pragma solidity ^0.4.21;

/* This is coin toss game contract that is connected to Proof of Community contract(0x08f7039d36f99eedc3d8b02cbd19f854f7dddc4d).*/


contract CoinToss {
    uint constant DONATING_X = 20; // 2% kujira

    // Need to be discussed
    uint constant JACKPOT_FEE = 10; // 1% jackpot
    uint constant JACKPOT_MODULO = 1000; // 0.1% jackpotwin
    uint constant DEV_FEE = 20; // 2% devfee
    uint constant WIN_X = 1900; // 1.9x

    // There is minimum and maximum bets.
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_BET = 1 ether;

    uint constant BET_EXPIRATION_BLOCKS = 250;

    // owner and PoC contract address
    address public owner;
    address public autoPlayBot;
    address public secretSigner;
    address private whale;

    // Accumulated jackpot fund.
    uint256 public jackpotSize;
    uint256 public devFeeSize;

    // Funds that are locked in potentially winning bets.
    uint256 public lockedInBets;
    uint256 public totalAmountToWhale;


    struct Bet {
        // Wager amount in wei.
        uint amount;
        // Block number of placeBet tx.
        uint256 blockNumber;
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        bool betMask;
        // Address of a player, used to pay out winning bets.
        address player;
    }

    mapping (uint => Bet) bets;
    mapping (address => uint) donateAmount;

    // events
    event Wager(uint ticketID, uint betAmount, uint256 betBlockNumber, bool betMask, address betPlayer);
    event Win(address winner, uint amount, uint ticketID, bool maskRes, uint jackpotRes);
    event Lose(address loser, uint amount, uint ticketID, bool maskRes, uint jackpotRes);
    event Refund(uint ticketID, uint256 amount, address requester);
    event Donate(uint256 amount, address donator);
    event FailedPayment(address paidUser, uint amount);
    event Payment(address noPaidUser, uint amount);
    event JackpotPayment(address player, uint ticketID, uint jackpotWin);

    // constructor
    constructor (address whaleAddress, address autoPlayBotAddress, address secretSignerAddress) public {
        owner = msg.sender;
        autoPlayBot = autoPlayBotAddress;
        whale = whaleAddress;
        secretSigner = secretSignerAddress;
        jackpotSize = 0;
        devFeeSize = 0;
        lockedInBets = 0;
        totalAmountToWhale = 0;
    }

    // modifiers
    modifier onlyOwner() {
        require (msg.sender == owner, "You are not the owner of this contract!");
        _;
    }    

    modifier onlyBot() {
        require (msg.sender == autoPlayBot, "You are not the bot of this contract!");
        _;
    }
    
    modifier checkContractHealth() {
        require (address(this).balance >= lockedInBets + jackpotSize + devFeeSize, "This contract doesn&#39;t have enough balance, it is stopped till someone donate to this game!");
        _;
    }

    // betMast:
    // false is front, true is back

    function() public payable { }


    function setBotAddress(address autoPlayBotAddress)
    onlyOwner() 
    external 
    {
        autoPlayBot = autoPlayBotAddress;
    }

    function setSecretSigner(address _secretSigner)
    onlyOwner()  
    external
    {
        secretSigner = _secretSigner;
    }

    // wager function
    function wager(bool bMask, uint ticketID, uint ticketLastBlock, uint8 v, bytes32 r, bytes32 s)  
    checkContractHealth()
    external
    payable { 
        Bet storage bet = bets[ticketID];
        uint amount = msg.value;
        address player = msg.sender;
        require (bet.player == address(0), "Ticket is not new one!");
        require (amount >= MIN_BET, "Your bet is lower than minimum bet amount");
        require (amount <= MAX_BET, "Your bet is higher than maximum bet amount");
        require (getCollateralBalance() >= 2 * amount, "If we accept this, this contract will be in danger!");

        require (block.number <= ticketLastBlock, "Ticket has expired.");
        bytes32 signatureHash = keccak256(abi.encodePacked(&#39;\x19Ethereum Signed Message:\n37&#39;, uint40(ticketLastBlock), ticketID));
        require (secretSigner == ecrecover(signatureHash, v, r, s), "web3 vrs signature is not valid.");

        jackpotSize += amount * JACKPOT_FEE / 1000;
        devFeeSize += amount * DEV_FEE / 1000;
        
        lockedInBets += amount * WIN_X / 1000;

        bet.amount = amount;
        bet.blockNumber = block.number;
        bet.betMask = bMask;
        bet.player = player;

        emit Wager(ticketID, bet.amount, bet.blockNumber, bet.betMask, bet.player);
    }

    // method to determine winners and losers
    function play(uint ticketReveal)
    checkContractHealth()
    external
    {
        uint ticketID = uint(keccak256(abi.encodePacked(ticketReveal)));
        Bet storage bet = bets[ticketID];
        require (bet.player != address(0), "TicketID is not correct!");
        require (bet.amount != 0, "Ticket is already used one!");
        uint256 blockNumber = bet.blockNumber;
        if(blockNumber < block.number && blockNumber >= block.number - BET_EXPIRATION_BLOCKS)
        {
            uint256 random = uint256(keccak256(abi.encodePacked(blockhash(blockNumber),  ticketReveal)));
            bool maskRes = (random % 2) !=0;
            uint jackpotRes = random % JACKPOT_MODULO;
    
            uint tossWinAmount = bet.amount * WIN_X / 1000;

            uint tossWin = 0;
            uint jackpotWin = 0;
            
            if(bet.betMask == maskRes) {
                tossWin = tossWinAmount;
            }
            if(jackpotRes == 0) {
                jackpotWin = jackpotSize;
                jackpotSize = 0;
            }
            if (jackpotWin > 0) {
                emit JackpotPayment(bet.player, ticketID, jackpotWin);
            }
            if(tossWin + jackpotWin > 0)
            {
                payout(bet.player, tossWin + jackpotWin, ticketID, maskRes, jackpotRes);
            }
            else 
            {
                loseWager(bet.player, bet.amount, ticketID, maskRes, jackpotRes);
            }
            lockedInBets -= tossWinAmount;
            bet.blockNumber = 0;
            bet.amount = 0;
        }
        else
        {
            revert();
        }
    }

    function donateForContractHealth()
    external 
    payable
    {
        donateAmount[msg.sender] += msg.value;
        emit Donate(msg.value, msg.sender);
    }

    function withdrawDonation(uint amount)
    external 
    {
        require(donateAmount[msg.sender] >= amount, "You are going to withdraw more than you donated!");
        
        if (sendFunds(msg.sender, amount)){
            donateAmount[msg.sender] -= amount;
        }
    }

    // method to refund
    function refund(uint ticketID)
    checkContractHealth()
    external {
        Bet storage bet = bets[ticketID];
        
        require (bet.amount != 0, "this ticket has no balance");
        require (block.number > bet.blockNumber + BET_EXPIRATION_BLOCKS, "this ticket is expired.");
        sendRefund(ticketID);
    }

    // Funds withdrawl
    function withdrawDevFee(address withdrawAddress, uint withdrawAmount)
    onlyOwner()
    checkContractHealth() 
    external {
        require (devFeeSize >= withdrawAmount, "You are trying to withdraw more amount than developer fee.");
        require (withdrawAmount <= address(this).balance, "Contract balance is lower than withdrawAmount");
        require (devFeeSize <= address(this).balance, "Not enough funds to withdraw.");
        if (sendFunds(withdrawAddress, withdrawAmount)){
            devFeeSize -= withdrawAmount;
        }
    }

    // Funds withdrawl
    function withdrawBotFee(uint withdrawAmount)
    onlyBot()
    checkContractHealth() 
    external {
        require (devFeeSize >= withdrawAmount, "You are trying to withdraw more amount than developer fee.");
        require (withdrawAmount <= address(this).balance, "Contract balance is lower than withdrawAmount");
        require (devFeeSize <= address(this).balance, "Not enough funds to withdraw.");
        if (sendFunds(autoPlayBot, withdrawAmount)){
            devFeeSize -= withdrawAmount;
        }
    }

    // Get Bet Info from id
    function getBetInfo(uint ticketID) 
    constant
    external 
    returns (uint, uint256, bool, address){
        Bet storage bet = bets[ticketID];
        return (bet.amount, bet.blockNumber, bet.betMask, bet.player);
    }

    // Get Bet Info from id
    function getContractBalance() 
    constant
    external 
    returns (uint){
        return address(this).balance;
    }

    // Get Collateral for Bet
    function getCollateralBalance() 
    constant
    public 
    returns (uint){
        if (address(this).balance > lockedInBets + jackpotSize + devFeeSize)
            return address(this).balance - lockedInBets - jackpotSize - devFeeSize;
        return 0;
    }

    // Contract may be destroyed only when there are no ongoing bets,
    // either settled or refunded. All funds are transferred to contract owner.
    function kill() external onlyOwner() {
        require (lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        selfdestruct(owner);
    }

    // Payout ETH to winner
    function payout(address winner, uint ethToTransfer, uint ticketID, bool maskRes, uint jackpotRes) 
    internal 
    {        
        winner.transfer(ethToTransfer);
        emit Win(winner, ethToTransfer, ticketID, maskRes, jackpotRes);
    }

    // sendRefund to requester
    function sendRefund(uint ticketID) 
    internal 
    {
        Bet storage bet = bets[ticketID];
        address requester = bet.player;
        uint256 ethToTransfer = bet.amount;

        bet.amount = 0;
        
        requester.transfer(ethToTransfer);

        uint tossWinAmount = bet.amount * WIN_X / 1000;
        lockedInBets -= tossWinAmount;
        emit Refund(ticketID, ethToTransfer, requester);
    }

    // Helper routine to process the payment.
    function sendFunds(address paidUser, uint amount) private returns (bool){
        bool success = paidUser.send(amount);
        if (success) {
            emit Payment(paidUser, amount);
        } else {
            emit FailedPayment(paidUser, amount);
        }
        return success;
    }
    // Payout ETH to whale when player loses
    function loseWager(address player, uint amount, uint ticketID, bool maskRes, uint jackpotRes) 
    internal 
    {
        uint donate_amount = amount * DONATING_X / 1000;
        whale.call.value(donate_amount)(bytes4(keccak256("donate()")));
        totalAmountToWhale += donate_amount;
        emit Lose(player, amount, ticketID, maskRes, jackpotRes);
    }

    // bulk clean the storage.
    function clearStorage(uint[] toCleanTicketIDs) external {
        uint length = toCleanTicketIDs.length;

        for (uint i = 0; i < length; i++) {
            clearProcessedBet(toCleanTicketIDs[i]);
        }
    }

    // Helper routine to move &#39;processed&#39; bets into &#39;clean&#39; state.
    function clearProcessedBet(uint ticketID) private {
        Bet storage bet = bets[ticketID];

        // Do not overwrite active bets with zeros; additionally prevent cleanup of bets
        // for which ticketID signatures may have not expired yet (see whitepaper for details).
        if (bet.amount != 0 || block.number <= bet.blockNumber + BET_EXPIRATION_BLOCKS) {
            return;
        }

        bet.blockNumber = 0;
        bet.betMask = false;
        bet.player = address(0);
    }

    // A trap door for when someone sends tokens other than the intended ones so the overseers can decide where to send them.
    function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) 
    public 
    onlyOwner() 
    returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
}

//Define ERC20Interface.transfer, so PoCWHALE can transfer tokens accidently sent to it.
contract ERC20Interface 
{
    function transfer(address to, uint256 tokens) public returns (bool success);
}