/**+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                            abcDice: a Block Chain Gambling Game.

                            Don&#39;t trust anyone but the CODE!
 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
 
/**+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    - abcDice是一个建立在以太坊区块链上的博彩平台，具有去中心化、公平、透明、可验证等优点，以及不受包括开发者在内的任何个人
    - 和组织操控的特性。

    - 游戏的核心业务逻辑来源于dice2.win的设计!
    - 对合约进行了一些优化：
    - 1) 将commit-reveal + block hash的随机数生成及传递机制,修改为：commit-reveal + tx hash. 
         优点是提高开奖确定性；
    - 2) 只有本合约签名的commit/reveal对才能投注，未签名和已经使用过的commit/reveal对禁入，因此存储不能清除；
    - 3) 增加合约状态管理功能;
    - 4) 处理潜在的溢出风险;

 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++**/
pragma solidity ^0.4.24;

contract AbcDice {
    //--------------------------------------------------------------------------------------------------
    // constants.        
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether;
    uint constant MAX_MODULO = 100;
    uint constant MAX_MASK_MODULO = 40;
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;

    uint constant MIN_JACKPOT_BET = 0.1 ether;
    uint constant JACKPOT_MODULO = 1000;
    uint constant JACKPOT_FEE = 0.001 ether;

    uint constant HOUSE_EDGE_PERCENT = 1;
    uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;

    uint constant BET_EXPIRATION_BLOCKS = 128;
    
    address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    //--------------------------------------------------------------------------------------------------
    // storage variables.
      
    address public owner;
    address private nextOwner;      
    address public croupier;
    // 
    address public secretSigner;

    uint public maxProfit;
    uint128 public jackpotSize;
    uint128 public lockedInBets;

    struct Bet {
        // Wager amount in wei.
        uint amount;
        // Modulo of a game.
        uint8 modulo;
        // Number of winning outcomes, used to compute winning payment (* modulo/rollUnder),
        // and used instead of mask for games with modulo > MAX_MASK_MODULO.
        uint8 rollUnder;
        // Block number of placeBet tx.
        uint40 placeBlockNumber;
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        uint40 mask;
        // Address of a gambler, used to pay out winning bets.
        address gambler;
    }
    // Mapping commit to bets.
    mapping (uint => Bet) public bets;    

    //--------------------------------------------------------------------------------------------------
    // events.
    event OnCommit(uint commit);
    event OnReveal(uint reveal, uint commit);
    event OnPay(address indexed beneficiary, uint amount);
    event OnFailedPay(address indexed beneficiary, uint amount);
    event OnJackpotPay(address indexed beneficiary, uint amount);

    //--------------------------------------------------------------------------------------------------
    // Contract status management, freeze placeBet while upgrade contract.
    uint8 public status;   // 1-active;    2-freezen.
    uint8 constant _ACTIVE = 1;
    uint8 constant _FREEZE = 2;

    modifier onlyActive {
        require (status == _ACTIVE, "placeBet Freezen.");
        _;
    }

    // Contract status changed.
    event OnFreeze();
    event OnActive();

    // Freeze placeBet.
    function freeze() public onlyOwner{
        emit OnFreeze();
        status = _FREEZE;        
    }

    // Active placeBet.
    function active() public onlyOwner{
        emit OnActive();
        status = _ACTIVE;
    }
    
    //--------------------------------------------------------------------------------------------------
    // modifiers.
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    modifier onlyCroupier {
        require (msg.sender == croupier, "OnlyCroupier methods called by non-croupier.");
        _;
    }

    modifier onlyHuman {
        require (msg.sender == tx.origin, "Prohibition of smart contracts.");
        _;
    }
    //--------------------------------------------------------------------------------------------------
    // constructor and fallback.
    constructor () public payable{
        owner = msg.sender;
        status = _ACTIVE;
        secretSigner = DUMMY_ADDRESS;
        croupier = DUMMY_ADDRESS;
    }
    
    // Fallback function deliberately left empty. It&#39;s primary use case
    // is to top up the bank roll.
    function () public payable {
    }
    
    //--------------------------------------------------------------------------------------------------
    // Public operation functions.

    // @dev 投注
    // @note 只有本合约签名的commit/reveal对才能进入.
    function placeBet(uint _betMask, uint _modulo, uint _commit, bytes32 _r, bytes32 _s)
        payable
        public
        onlyHuman
        onlyActive
    {
        //验证_commit为"clean"状态.
        Bet storage bet = bets[_commit];
        require (bet.gambler == address(0), "Bet should be in a &#39;clean&#39; state.");

        //验证签名.
        bytes32 signatureHash = keccak256(abi.encodePacked(_commit));
        require (secretSigner == ecrecover(signatureHash, 27, _r, _s), "ECDSA signature is not valid.");

        //验证数据范围.
        uint amount = msg.value;
        require (_modulo > 1 && _modulo <= MAX_MODULO, "Modulo should be within range.");
        require (amount >= MIN_BET && amount <= MAX_AMOUNT, "Amount should be within range.");
        require (_betMask > 0 && _betMask < MAX_BET_MASK, "Mask should be within range.");

        uint rollUnder;
        uint mask;

        if (_modulo <= MAX_MASK_MODULO) {
            // Small modulo games specify bet outcomes via bit mask.
            // rollUnder is a number of 1 bits in this mask (population count).
            // This magic looking formula is an efficient way to compute population
            // count on EVM for numbers below 2**40. 
            rollUnder = ((_betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = _betMask;
        } else {
            // Larger modulos specify the right edge of half-open interval of
            // winning bet outcomes.
            require (_betMask > 0 && _betMask <= _modulo, "High modulo range, betMask larger than modulo.");
            rollUnder = _betMask;
        }

        // Winning amount and jackpot increase.
        uint possibleWinAmount;
        uint jackpotFee;

        (possibleWinAmount, jackpotFee) = getDiceWinAmount(amount, _modulo, rollUnder);

        // Enforce max profit limit.
        require (possibleWinAmount <= amount + maxProfit, "maxProfit limit violation.");

        // Lock funds.
        lockedInBets += uint128(possibleWinAmount);
        jackpotSize += uint128(jackpotFee);

        // Check whether contract has enough funds to process this bet.
        require (jackpotSize + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");

        // Record commit in logs.
        emit OnCommit(_commit);

        // Store bet parameters on blockchain.
        bet.amount = amount;
        bet.modulo = uint8(_modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.placeBlockNumber = uint40(block.number);
        bet.mask = uint40(mask);
        bet.gambler = msg.sender;
    }

    //@dev 开奖
    //@note 客户端将reveal揭示出来之后，开奖可以由任何人触发.
    function settleBet(uint _reveal, bytes32 _txHash)
        public
        onlyHuman
    {
        uint commit = uint(keccak256(abi.encodePacked(_reveal)));
        Bet storage bet = bets[commit];
        //验证 commit 状态.
        require(bet.gambler != address(0) && bet.amount > 0, "Bet should be in an &#39;active&#39; state.");
        //验证 place 未过期
        require (block.number > bet.placeBlockNumber, "settleBet in the same block as placeBet, or before.");
        require (block.number <= bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Bet expired.");

        //开奖
        settleBetCore(bet, _reveal, _txHash);
    }

    // @dev 回撤
    // @note 如果在限定时间内没有完成开奖，可以回撤投注; 回撤可以由任何人调用.
    function withdraw(uint _commit) 
        public
        onlyHuman 
    {
         // Check that bet is in &#39;active&#39; state.
        Bet storage bet = bets[_commit];
        uint amount = bet.amount;

        require (amount != 0, "Bet should be in an &#39;active&#39; state");

        // Check that bet has already expired.
        require (block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Bet not yet expired.");

        // Move bet into &#39;processed&#39; state, release funds.
        bet.amount = 0;

        uint diceWinAmount;
        uint jackpotFee;
        (diceWinAmount, jackpotFee) = getDiceWinAmount(amount, bet.modulo, bet.rollUnder);

        assert(diceWinAmount <= lockedInBets);
        lockedInBets -= uint128(diceWinAmount);
        // If jackpotSize overflow, that&#39;s very few accident, we offered jackpotFee.
        if(jackpotFee <= jackpotSize)
            jackpotSize -= uint128(jackpotFee);

        // Send the refund.
        sendFunds(bet.gambler, amount, amount);       
    }

    //--------------------------------------------------------------------------------------------------
    //helper functions.

    // Core settlement code for settleBet.
    function settleBetCore(Bet storage _bet, uint _reveal, bytes32 _entropyHash) internal {
        // Fetch bet parameters into local variables (to save gas).
        uint amount = _bet.amount;
        uint modulo = _bet.modulo;
        uint rollUnder = _bet.rollUnder;
        address gambler = _bet.gambler;

        // Check that bet is in &#39;active&#39; state.
        require (amount != 0, "Bet should be in an &#39;active&#39; state");

        // Move bet into &#39;processed&#39; state already.
        _bet.amount = 0;

        // The RNG - combine "reveal" and tx hash of placeBet using Keccak256. Miners
        // are not aware of "reveal" and cannot deduce it from "commit" (as Keccak256
        // preimage is intractable), and house is unable to alter the "reveal" after
        // placeBet have been mined (as Keccak256 collision finding is also intractable).
        bytes32 entropy = keccak256(abi.encodePacked(_reveal, _entropyHash));

        // Do a roll by taking a modulo of entropy. Compute winning amount.
        uint dice = uint(entropy) % modulo;

        uint diceWinAmount;
        uint _jackpotFee;
        (diceWinAmount, _jackpotFee) = getDiceWinAmount(amount, modulo, rollUnder);

        uint diceWin = 0;
        uint jackpotWin = 0;

        // Determine dice outcome.
        if (modulo <= MAX_MASK_MODULO) {
            // For small modulo games, check the outcome against a bit mask.
            if ((2 ** dice) & _bet.mask != 0) {
                diceWin = diceWinAmount;
            }

        } else {
            // For larger modulos, check inclusion into half-open interval.
            if (dice < rollUnder) {
                diceWin = diceWinAmount;
            }

        }

        // Unlock the bet amount, regardless of the outcome.
        assert(diceWinAmount <= lockedInBets);
        lockedInBets -= uint128(diceWinAmount);

        // Roll for a jackpot (if eligible).
        if (amount >= MIN_JACKPOT_BET) {
            // The second modulo, statistically independent from the "main" dice roll.
            // Effectively you are playing two games at once!
            uint jackpotRng = (uint(entropy) / modulo) % JACKPOT_MODULO;

            // Bingo!
            if (jackpotRng == 0) {
                jackpotWin = jackpotSize;
                jackpotSize = 0;
            }
        }

        // Log jackpot win.
        if (jackpotWin > 0) {
            emit OnJackpotPay(gambler, jackpotWin);
        }

        // Send the funds to gambler.
        sendFunds(gambler, diceWin + jackpotWin == 0 ? 1 wei : diceWin + jackpotWin, diceWin);
    }

    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(uint amount, uint modulo, uint rollUnder) internal pure returns (uint winAmount, uint jackpotFee) {
        require (0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");

        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

        uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;

        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }

        require (houseEdge + jackpotFee <= amount, "Bet doesn&#39;t even cover house edge.");
        winAmount = (amount - houseEdge - jackpotFee) * modulo / rollUnder;
    }

    // Standard contract ownership transfer implementation,
    function approveNextOwner(address _nextOwner) public onlyOwner {
        require (_nextOwner != owner && _nextOwner != address(0), "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() public {
        require (msg.sender == nextOwner, "Can only accept preapproved new owner.");
        owner = nextOwner;
    }

    // Helper routine to process the payment.
    function sendFunds(address beneficiary, uint amount, uint successLogAmount) private {
        if (beneficiary.send(amount)) {
            emit OnPay(beneficiary, successLogAmount);
        } else {
            emit OnFailedPay(beneficiary, amount);
        }
    }
    // See comment for "secretSigner" variable.
    function setSecretSigner(address newSecretSigner) public onlyOwner {
        secretSigner = newSecretSigner;
    }

    // Change the croupier address.
    function setCroupier(address newCroupier) public onlyOwner {
        croupier = newCroupier;
    }

    // Change max bet reward. Setting this to zero effectively disables betting.
    function setMaxProfit(uint _maxProfit) public onlyOwner {
        require (_maxProfit < MAX_AMOUNT, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
    }

    // This function is used to bump up the jackpot fund. Cannot be used to lower it.
    function increaseJackpot(uint increaseAmount) public onlyOwner {
        require (increaseAmount <= address(this).balance, "Increase amount larger than balance.");
        require (jackpotSize + lockedInBets + increaseAmount <= address(this).balance, "Not enough funds.");
        jackpotSize += uint128(increaseAmount);
    }

    // Funds withdrawal to cover costs of AbcDice operation.
    function withdrawFunds(address beneficiary, uint withdrawAmount) public onlyOwner {
        require (withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
        require (jackpotSize + lockedInBets + withdrawAmount <= address(this).balance, "Not enough funds.");
        sendFunds(beneficiary, withdrawAmount, withdrawAmount);
    }

    // Contract may be destroyed only when there are no ongoing bets,
    // either settled or refunded. All funds are transferred to contract owner.
    function kill() public onlyOwner {
        require (lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        selfdestruct(owner);
    }
}