pragma solidity^0.4.21;
/*
 *      ##########################################
 *      ##########################################
 *      ###                                                                                         ###
 *      ###                             &#119823;&#119845;&#119834;&#119858; & &#119830;&#119842;&#119847; &#119812;&#119853;&#119841;&#119838;&#119851;                             ###
 *      ###                                          at                                            ###
 *      ###                            &#119812;&#119827;&#119815;&#119812;&#119825;&#119808;&#119813;&#119813;&#119819;&#119812;.&#119810;&#119822;&#119820;                            ###
 *      ###                                                                                         ###
 *      ##########################################
 *      ##########################################
 *
 *      Welcome to the &#119812;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838; &#119819;&#119822;&#119827; &#119827;&#119848;&#119844;&#119838;&#119847; promotional contract!
 *      First you should go and play &#119812;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838; @ &#119841;&#119853;&#119853;&#119849;&#119852;://&#119838;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;.&#119836;&#119848;&#119846;
 *      Then you&#39;ll have earnt free &#119819;&#119822;&#119827; &#119827;&#119848;&#119844;&#119838;&#119847;&#119852; via this very promotion!
 *      Next you should learn about our &#119816;&#119810;&#119822; @ &#119841;&#119853;&#119853;&#119849;&#119852;://&#119838;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;.&#119836;&#119848;&#119846;/&#119842;&#119836;&#119848;
 *      Then take part by buying even more &#119819;&#119822;&#119827; &#119853;&#119848;&#119844;&#119838;&#119847;&#119852;! 
 *      And don&#39;t forget to play &#119812;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838; some more because it&#39;s brilliant!
 *
 *      If you want to chat to us you have loads of options:
 *      On &#119827;&#119838;&#119845;&#119838;&#119840;&#119851;&#119834;&#119846; @ &#119841;&#119853;&#119853;&#119849;&#119852;://&#119853;.&#119846;&#119838;/&#119838;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;
 *      Or on &#119827;&#119856;&#119842;&#119853;&#119853;&#119838;&#119851; @ &#119841;&#119853;&#119853;&#119849;&#119852;://&#119853;&#119856;&#119842;&#119853;&#119853;&#119838;&#119851;.&#119836;&#119848;&#119846;/&#119838;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;
 *      Or on &#119825;&#119838;&#119837;&#119837;&#119842;&#119853; @ &#119841;&#119853;&#119853;&#119849;&#119852;://&#119838;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838;.&#119851;&#119838;&#119837;&#119837;&#119842;&#119853;.&#119836;&#119848;&#119846;
 *
 *      &#119812;&#119853;&#119841;&#119838;&#119851;&#119834;&#119839;&#119839;&#119845;&#119838; - the only &#119853;&#119851;&#119854;&#119845;&#119858; &#119837;&#119838;&#119836;&#119838;&#119847;&#119853;&#119851;&#119834;&#119845;&#119842;&#119859;&#119838;&#119837; & &#119836;&#119841;&#119834;&#119851;&#119842;&#119853;&#119834;&#119835;&#119845;&#119838; blockchain lottery.
 */
contract EtheraffleInterface {
    uint public tktPrice;
    function getUserNumEntries(address _entrant, uint _week) public view returns (uint) {}
}

contract LOTInterface {
    function transfer(address _to, uint _value) public {}
    function balanceOf(address _owner) public view returns (uint) {}
}

contract EtheraffleLOTPromo {
    
    bool    public isActive;
    uint    constant public RAFEND     = 500400;     // 7:00pm Saturdays
    uint    constant public BIRTHDAY   = 1500249600; // Etheraffle&#39;s birthday <3
    uint    constant public ICOSTART   = 1522281600; // Thur 29th March 2018
    uint    constant public TIER1END   = 1523491200; // Thur 12th April 2018
    uint    constant public TIER2END   = 1525305600; // Thur 3rd May 2018
    uint    constant public TIER3END   = 1527724800; // Thur 31st May 2018
    address constant public ETHERAFFLE = 0x97f535e98cf250CDd7Ff0cb9B29E4548b609A0bd;
    
    LOTInterface LOTContract;
    EtheraffleInterface etheraffleContract;

    /* Mapping of  user address to weekNo to claimed bool */
    mapping (address => mapping (uint => bool)) public claimed;
    
    event LogActiveStatus(bool currentStatus, uint atTime);
    event LogTokenDeposit(address fromWhom, uint tokenAmount, bytes data);
    event LogLOTClaim(address whom, uint howMany, uint inWeek, uint atTime);
    /*
     * @dev     Modifier requiring function caller to be the Etheraffle 
     *          multisig wallet address
     */
    modifier onlyEtheraffle() {
        require(msg.sender == ETHERAFFLE);
        _;
    }
    /*
     * @dev     Constructor - sets promo running and instantiates required
     *          contracts.
     */
    function EtheraffleLOTPromo() public {
        isActive           = true;
        LOTContract        = LOTInterface(0xAfD9473dfe8a49567872f93c1790b74Ee7D92A9F);
        etheraffleContract = EtheraffleInterface(0x45c58bbd535b8661110ef5296e6987573d0c8276);
    }
    /*
     * @dev     Function used to redeem promotional LOT owed. Use weekNo of 
     *          0 to get current week number. Requires user not to have already 
     *          claimed week number in question&#39;s earnt promo LOT and for promo 
     *          to be active. It calculates LOT owed, and sends them to the 
     *          caller. Should contract&#39;s LOT balance fall too low, attempts 
     *          to redeem will arrest the contract to await a resupply of LOT.
     */
    function redeem(uint _weekNo) public {
        uint week    = _weekNo == 0 ? getWeek() : _weekNo;
        uint entries = getNumEntries(msg.sender, week);
        require(
            !claimed[msg.sender][week] &&
            entries > 0 &&
            isActive
            );
        uint amt = getPromoLOTEarnt(entries);
        if (getLOTBalance(this) < amt) {
            isActive = false;
            emit LogActiveStatus(false, now);
            return;
        }
        claimed[msg.sender][week] = true;
        LOTContract.transfer(msg.sender, amt);
        emit LogLOTClaim(msg.sender, amt, week, now);
    }
    /*
     * @dev     Returns number of entries made in Etheraffle contract by
     *          function caller in whatever the queried week is. 
     *
     * @param _address  Address to be queried
     * @param _weekNo   Desired week number. (Use 0 for current week)
     */
    function getNumEntries(address _address, uint _weekNo) public view returns (uint) {
        uint week = _weekNo == 0 ? getWeek() : _weekNo;
        return etheraffleContract.getUserNumEntries(_address, week);
    }
    /*
     * @dev     Toggles promo on & off. Only callable by the Etheraffle
     *          multisig wallet.
     *
     * @param _status   Desired bool status of the promo
     */
    function togglePromo(bool _status) public onlyEtheraffle {
        isActive = _status;
        emit LogActiveStatus(_status, now);
    }
    /*
     * @dev     Same getWeek function as seen in main Etheraffle contract to 
     *          ensure parity. Ddefined by number of weeks since Etheraffle&#39;s
     *          birthday.
     */
    function getWeek() public view returns (uint) {
        uint curWeek = (now - BIRTHDAY) / 604800;
        if (now - ((curWeek * 604800) + BIRTHDAY) > RAFEND) curWeek++;
        return curWeek;
    }
    /**
     * @dev     ERC223 tokenFallback function allows to receive ERC223 tokens 
     *          properly.
     *
     * @param _from  Address of the sender.
     * @param _value Amount of deposited tokens.
     * @param _data  Token transaction data.
     */
    function tokenFallback(address _from, uint256 _value, bytes _data) external {
        if (_value > 0) emit LogTokenDeposit(_from, _value, _data);
    }
    /*
     * @dev     Retrieves current LOT token balance of an address.
     *
     * @param _address Address whose balance is to be queried.
     */
    function getLOTBalance(address _address) internal view returns (uint) {
        return LOTContract.balanceOf(_address);
    }
    /*
     * @dev     Function returns bool re whether or not address in question 
     *          has claimed promo LOT for the week in question.
     *
     * @param _address  Ethereum address to be queried
     * @param _weekNo   Week number to be queried (use 0 for current week)
     */
    function hasRedeemed(address _address, uint _weekNo) public view returns (bool) {
        uint week = _weekNo == 0 ? getWeek() : _weekNo;
        return claimed[_address][week];
    }
    /*
     * @dev     Returns current ticket price from the main Etheraffle
     *          contract
     */
    function getTktPrice() public view returns (uint) {
        return etheraffleContract.tktPrice();
    }
    /*
     * @dev     Function returns current ICO tier&#39;s exchange rate of LOT
     *          per ETH.
     */
    function getRate() public view returns (uint) {
        if (now <  ICOSTART) return 110000 * 10 ** 6;
        if (now <= TIER1END) return 100000 * 10 ** 6;
        if (now <= TIER2END) return 90000  * 10 ** 6;
        if (now <= TIER3END) return 80000  * 10 ** 6;
        else return 0;
    }
    /*
     * @dev     Returns number of promotional LOT earnt as calculated 
     *          based on number of entries, current ICO exchange rate
     *          and the current Etheraffle ticket price. 
     */
    function getPromoLOTEarnt(uint _entries) public view returns (uint) {
        return (_entries * getRate() * getTktPrice()) / (1 * 10 ** 18);
    }
    /*
     * @dev     Scuttles contract, sending any remaining LOT tokens back 
     *          to the Etheraffle multisig (by whom it is only callable)
     */
    function scuttle() external onlyEtheraffle {
        LOTContract.transfer(ETHERAFFLE, LOTContract.balanceOf(this));
        selfdestruct(ETHERAFFLE);
    }
}