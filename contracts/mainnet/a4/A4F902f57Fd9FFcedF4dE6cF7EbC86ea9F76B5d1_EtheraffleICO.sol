pragma solidity^0.4.15;

contract EtheraffleLOT {
    function mint(address _to, uint _amt) external {}
    function transfer(address to, uint value) public {}
    function balanceOf(address who) constant public returns (uint) {}
}
contract EtheraffleICO is EtheraffleLOT {

    /* Lot reward per ether in each tier */
    uint public constant tier0LOT = 110000 * 10 ** 6;
    uint public constant tier1LOT = 100000 * 10 ** 6;
    uint public constant tier2LOT =  90000 * 10 ** 6;
    uint public constant tier3LOT =  80000 * 10 ** 6;
    /* Bonus tickets multiplier */
    uint public constant bonusLOT     = 1500 * 10 ** 6;
    uint public constant bonusFreeLOT = 10;
    /* Maximum amount of ether investable per tier */
    uint public constant maxWeiTier0 = 700   * 10 ** 18;
    uint public constant maxWeiTier1 = 2500  * 10 ** 18;
    uint public constant maxWeiTier2 = 7000  * 10 ** 18;
    uint public constant maxWeiTier3 = 20000 * 10 ** 18;
    /* Minimum investment (0.025 Ether) */
    uint public constant minWei = 25 * 10 ** 15;
    /* Crowdsale open, close, withdraw & tier times (UTC Format)*/
    uint public ICOStart = 1522281600;//Thur 29th March 2018
    uint public tier1End = 1523491200;//Thur 12th April 2018
    uint public tier2End = 1525305600;//Thur 3rd May 2018
    uint public tier3End = 1527724800;//Thur 31st May 2018
    uint public wdBefore = 1528934400;//Thur 14th June 2018
    /* Variables to track amount of purchases in tier */
    uint public tier0Total;
    uint public tier1Total;
    uint public tier2Total;
    uint public tier3Total;
    /* Etheraffle&#39;s multisig wallet & LOT token addresses */
    address public etheraffle;
    /* ICO status toggle */
    bool public ICORunning = true;
    /* Map of purchaser&#39;s ethereum addresses to their purchase amounts for calculating bonuses*/
    mapping (address => uint) public tier0;
    mapping (address => uint) public tier1;
    mapping (address => uint) public tier2;
    mapping (address => uint) public tier3;
    /* Instantiate the variables to hold Etheraffle&#39;s LOT & freeLOT token contract instances */
    EtheraffleLOT LOT;
    EtheraffleLOT FreeLOT;
    /* Event loggers */
    event LogTokenDeposit(address indexed from, uint value, bytes data);
    event LogRefund(address indexed toWhom, uint amountOfEther, uint atTime);
    event LogEtherTransfer(address indexed toWhom, uint amount, uint atTime);
    event LogBonusLOTRedemption(address indexed toWhom, uint lotAmount, uint atTime);
    event LogLOTTransfer(address indexed toWhom, uint indexed inTier, uint ethAmt, uint LOTAmt, uint atTime);
    /**
     * @dev Modifier function to prepend to later functions in this contract in
     *      order to redner them only useable by the Etheraffle address.
     */
    modifier onlyEtheraffle() {
        require(msg.sender == etheraffle);
        _;
    }
    /**
     * @dev Modifier function to prepend to later functions rendering the method
     *      only callable if the crowdsale is running.
     */
    modifier onlyIfRunning() {
        require(ICORunning);
        _;
    }
    /**
     * @dev Modifier function to prepend to later functions rendering the method
     *      only callable if the crowdsale is NOT running.
     */
    modifier onlyIfNotRunning() {
        require(!ICORunning);
        _;
    }
    /**
    * @dev  Constructor. Sets up the variables pertaining to the ICO start &
    *       end times, the tier start & end times, the Etheraffle MultiSig Wallet
    *       address & the Etheraffle LOT & FreeLOT token contracts.
    */
    function EtheraffleICO() public {//address _LOT, address _freeLOT, address _msig) public {
        etheraffle = 0x97f535e98cf250cdd7ff0cb9b29e4548b609a0bd;
        LOT        = EtheraffleLOT(0xAfD9473dfe8a49567872f93c1790b74Ee7D92A9F);
        FreeLOT    = EtheraffleLOT(0xc39f7bB97B31102C923DaF02bA3d1bD16424F4bb);
    }
    /**
    * @dev  Purchase LOT tokens.
    *       LOT are sent in accordance with how much ether is invested, and in what
    *       tier the investment was made. The function also stores the amount of ether
    *       invested for later conversion to the amount of bonus LOT owed. Once the
    *       crowdsale is over and the final number of tokens sold is known, the purchaser&#39;s
    *       bonuses can be calculated. Using the fallback function allows LOT purchasers to
    *       simply send ether to this address in order to purchase LOT, without having
    *       to call a function. The requirements also also mean that once the crowdsale is
    *       over, any ether sent to this address by accident will be returned to the sender
    *       and not lost.
    */
    function () public payable onlyIfRunning {
        /* Requires the crowdsale time window to be open and the function caller to send ether */
        require
        (
            now <= tier3End &&
            msg.value >= minWei
        );
        uint numLOT = 0;
        if (now <= ICOStart) {// ∴ tier zero...
            /* Eth investable in each tier is capped via this requirement */
            require(tier0Total + msg.value <= maxWeiTier0);
            /* Store purchasers purchased amount for later bonus redemption */
            tier0[msg.sender] += msg.value;
            /* Track total investment in tier one for later bonus calculation */
            tier0Total += msg.value;
            /* Number of LOT this tier&#39;s purchase results in */
            numLOT = (msg.value * tier0LOT) / (1 * 10 ** 18);
            /* Transfer the number of LOT bought to the purchaser */
            LOT.transfer(msg.sender, numLOT);
            /* Log the  transfer */
            LogLOTTransfer(msg.sender, 0, msg.value, numLOT, now);
            return;
        } else if (now <= tier1End) {// ∴ tier one...
            require(tier1Total + msg.value <= maxWeiTier1);
            tier1[msg.sender] += msg.value;
            tier1Total += msg.value;
            numLOT = (msg.value * tier1LOT) / (1 * 10 ** 18);
            LOT.transfer(msg.sender, numLOT);
            LogLOTTransfer(msg.sender, 1, msg.value, numLOT, now);
            return;
        } else if (now <= tier2End) {// ∴ tier two...
            require(tier2Total + msg.value <= maxWeiTier2);
            tier2[msg.sender] += msg.value;
            tier2Total += msg.value;
            numLOT = (msg.value * tier2LOT) / (1 * 10 ** 18);
            LOT.transfer(msg.sender, numLOT);
            LogLOTTransfer(msg.sender, 2, msg.value, numLOT, now);
            return;
        } else {// ∴ tier three...
            require(tier3Total + msg.value <= maxWeiTier3);
            tier3[msg.sender] += msg.value;
            tier3Total += msg.value;
            numLOT = (msg.value * tier3LOT) / (1 * 10 ** 18);
            LOT.transfer(msg.sender, numLOT);
            LogLOTTransfer(msg.sender, 3, msg.value, numLOT, now);
            return;
        }
    }
    /**
    * @dev      Redeem bonus LOT: This function cannot be called until
    *           the crowdsale is over, nor after the withdraw period.
    *           During this window, a LOT purchaser calls this function
    *           in order to receive their bonus LOT owed to them, as
    *           calculated by their share of the total amount of LOT
    *           sales in the tier(s) following their purchase. Once
    *           claimed, user&#39;s purchased amounts are set to 1 wei rather
    *           than zero, to allow the contract to maintain a list of
    *           purchasers in each. All investors, regardless of tier/amount,
    *           receive ten free entries into the flagship Saturday
    *           Etheraffle via the FreeLOT coupon.
    */
    function redeemBonusLot() external onlyIfRunning { //81k gas
        /* Requires crowdsale to be over and the wdBefore time to not have passed yet */
        require
        (
            now > tier3End &&
            now < wdBefore
        );
        /* Requires user to have a LOT purchase in at least one of the tiers. */
        require
        (
            tier0[msg.sender] > 1 ||
            tier1[msg.sender] > 1 ||
            tier2[msg.sender] > 1 ||
            tier3[msg.sender] > 1
        );
        uint bonusNumLOT;
        /* If purchaser has ether in this tier, LOT tokens owed is calculated and added to LOT amount */
        if(tier0[msg.sender] > 1) {
            bonusNumLOT +=
            /* Calculate share of bonus LOT user is entitled to, based on tier one sales */
            ((tier1Total * bonusLOT * tier0[msg.sender]) / (tier0Total * (1 * 10 ** 18))) +
            /* Calculate share of bonus LOT user is entitled to, based on tier two sales */
            ((tier2Total * bonusLOT * tier0[msg.sender]) / (tier0Total * (1 * 10 ** 18))) +
            /* Calculate share of bonus LOT user is entitled to, based on tier three sales */
            ((tier3Total * bonusLOT * tier0[msg.sender]) / (tier0Total * (1 * 10 ** 18)));
            /* Set amount of ether in this tier to 1 to make further bonus redemptions impossible */
            tier0[msg.sender] = 1;
        }
        if(tier1[msg.sender] > 1) {
            bonusNumLOT +=
            ((tier2Total * bonusLOT * tier1[msg.sender]) / (tier1Total * (1 * 10 ** 18))) +
            ((tier3Total * bonusLOT * tier1[msg.sender]) / (tier1Total * (1 * 10 ** 18)));
            tier1[msg.sender] = 1;
        }
        if(tier2[msg.sender] > 1) {
            bonusNumLOT +=
            ((tier3Total * bonusLOT * tier2[msg.sender]) / (tier2Total * (1 * 10 ** 18)));
            tier2[msg.sender] = 1;
        }
        if(tier3[msg.sender] > 1) {
            tier3[msg.sender] = 1;
        }
        /* Final check that user cannot withdraw twice */
        require
        (
            tier0[msg.sender]  <= 1 &&
            tier1[msg.sender]  <= 1 &&
            tier2[msg.sender]  <= 1 &&
            tier3[msg.sender]  <= 1
        );
        /* Transfer bonus LOT to bonus redeemer */
        if(bonusNumLOT > 0) {
            LOT.transfer(msg.sender, bonusNumLOT);
        }
        /* Mint FreeLOT and give to bonus redeemer */
        FreeLOT.mint(msg.sender, bonusFreeLOT);
        /* Log the bonus LOT redemption */
        LogBonusLOTRedemption(msg.sender, bonusNumLOT, now);
    }
    /**
    * @dev    Should crowdsale be cancelled for any reason once it has
    *         begun, any ether is refunded to the purchaser by calling
    *         this funcion. Function checks each tier in turn, totalling
    *         the amount whilst zeroing the balance, and finally makes
    *         the transfer.
    */
    function refundEther() external onlyIfNotRunning {
        uint amount;
        if(tier0[msg.sender] > 1) {
            /* Add balance of caller&#39;s address in this tier to the amount */
            amount += tier0[msg.sender];
            /* Zero callers balance in this tier */
            tier0[msg.sender] = 0;
        }
        if(tier1[msg.sender] > 1) {
            amount += tier1[msg.sender];
            tier1[msg.sender] = 0;
        }
        if(tier2[msg.sender] > 1) {
            amount += tier2[msg.sender];
            tier2[msg.sender] = 0;
        }
        if(tier3[msg.sender] > 1) {
            amount += tier3[msg.sender];
            tier3[msg.sender] = 0;
        }
        /* Final check that user cannot be refunded twice */
        require
        (
            tier0[msg.sender] == 0 &&
            tier1[msg.sender] == 0 &&
            tier2[msg.sender] == 0 &&
            tier3[msg.sender] == 0
        );
        /* Transfer the ether to the caller */
        msg.sender.transfer(amount);
        /* Log the refund */
        LogRefund(msg.sender, amount, now);
        return;
    }
    /**
    * @dev    Function callable only by Etheraffle&#39;s multi-sig wallet. It
    *         transfers the tier&#39;s raised ether to the etheraffle multisig wallet
    *         once the tier is over.
    *
    * @param _tier    The tier from which the withdrawal is being made.
    */
    function transferEther(uint _tier) external onlyIfRunning onlyEtheraffle {
        if(_tier == 0) {
            /* Require tier zero to be over and a tier zero ether be greater than 0 */
            require(now > ICOStart && tier0Total > 0);
            /* Transfer the tier zero total to the etheraffle multisig */
            etheraffle.transfer(tier0Total);
            /* Log the transfer event */
            LogEtherTransfer(msg.sender, tier0Total, now);
            return;
        } else if(_tier == 1) {
            require(now > tier1End && tier1Total > 0);
            etheraffle.transfer(tier1Total);
            LogEtherTransfer(msg.sender, tier1Total, now);
            return;
        } else if(_tier == 2) {
            require(now > tier2End && tier2Total > 0);
            etheraffle.transfer(tier2Total);
            LogEtherTransfer(msg.sender, tier2Total, now);
            return;
        } else if(_tier == 3) {
            require(now > tier3End && tier3Total > 0);
            etheraffle.transfer(tier3Total);
            LogEtherTransfer(msg.sender, tier3Total, now);
            return;
        } else if(_tier == 4) {
            require(now > tier3End && this.balance > 0);
            etheraffle.transfer(this.balance);
            LogEtherTransfer(msg.sender, this.balance, now);
            return;
        }
    }
    /**
    * @dev    Function callable only by Etheraffle&#39;s multi-sig wallet.
    *         It transfers any remaining unsold LOT tokens to the
    *         Etheraffle multisig wallet. Function only callable once
    *         the withdraw period and ∴ the ICO ends.
    */
    function transferLOT() onlyEtheraffle onlyIfRunning external {
        require(now > wdBefore);
        uint amt = LOT.balanceOf(this);
        LOT.transfer(etheraffle, amt);
        LogLOTTransfer(msg.sender, 5, 0, amt, now);
    }
    /**
    * @dev    Toggle crowdsale status. Only callable by the Etheraffle
    *         mutlisig account. If set to false, the refund function
    *         becomes live allow purchasers to withdraw their ether
    *
    */
    function setCrowdSaleStatus(bool _status) external onlyEtheraffle {
        ICORunning = _status;
    }
    /**
     * @dev This function is what allows this contract to receive ERC223
     *      compliant tokens. Any tokens sent to this address will fire off
     *      an event announcing their arrival. Unlike ERC20 tokens, ERC223
     *      tokens cannot be sent to contracts absent this function,
     *      thereby preventing loss of tokens by mistakenly sending them to
     *      contracts not designed to accept them.
     *
     * @param _from     From whom the transfer originated
     * @param _value    How many tokens were sent
     * @param _data     Transaction metadata
     */
    function tokenFallback(address _from, uint _value, bytes _data) public {
        if (_value > 0) {
            LogTokenDeposit(_from, _value, _data);
        }
    }
    /**
     * @dev   Housekeeping function in the event this contract is no
     *        longer needed. Will delete the code from the blockchain.
     */
    function selfDestruct() external onlyIfNotRunning onlyEtheraffle {
        selfdestruct(etheraffle);
    }
}