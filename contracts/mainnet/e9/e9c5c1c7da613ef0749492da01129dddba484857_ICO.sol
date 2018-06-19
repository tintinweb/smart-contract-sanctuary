pragma solidity 0.4.19;


contract Ownable {
    
    address public owner;

    /**
     * The address whcih deploys this contrcat is automatically assgined ownership.
     * */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * Functions with this modifier can only be executed by the owner of the contract. 
     * */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

    /**
    * Transfers ownership to new Ethereum address. This function can only be called by the 
    * owner.
    * @param _newOwner the address to be granted ownership.
    **/
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



contract ERC20TransferInterface {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address who) constant public returns (uint256);
}



contract ICO is Ownable {
    
    using SafeMath for uint256;

    event TokenAddressSet(address indexed tokenAddress);
    event FirstPreIcoActivated(uint256 startTime, uint256 endTime, uint256 bonus);
    event SecondPreIcoActivated(uint256 startTime, uint256 endTime, uint256 bonus);
    event MainIcoActivated(uint256 startTime, uint256 endTime, uint256 bonus);
    event TokenPriceChanged(uint256 newTokenPrice, uint256 newExchangeRate);
    event ExchangeRateChanged(uint256 newExchangeRate, uint256 newTokenPrice);
    event BonuseChanged(uint256 newBonus);
    event OffchainPurchaseMade(address indexed recipient, uint256 tokensPurchased);
    event TokensPurchased(address indexed recipient, uint256 tokensPurchased, uint256 weiSent);
    event UnsoldTokensWithdrawn(uint256 tokensWithdrawn);
    event ICOPaused(uint256 timeOfPause);
    event ICOUnpaused(uint256 timeOfUnpause);
    event IcoDeadlineExtended(State currentState, uint256 newDeadline);
    event IcoDeadlineShortened(State currentState, uint256 newDeadline);
    event IcoTerminated(uint256 terminationTime);
    event AirdropInvoked();

    uint256 public endTime;
    uint256 private pausedTime;
    bool public IcoPaused;
    uint256 public tokenPrice;
    uint256 public rate;
    uint256 public bonus;
    uint256 public minInvestment;
    ERC20TransferInterface public MSTCOIN;
    address public multiSigWallet;
    uint256 public tokensSold;

    mapping (address => uint256) public investmentOf;

    enum State {FIRST_PRE_ICO, SECOND_PRE_ICO, MAIN_ICO, TERMINATED}
    State public icoState;

    uint256[4] public mainIcoBonusStages;

    function ICO() public {
        endTime = now.add(7 days);
        pausedTime = 0;
        IcoPaused = false;
        tokenPrice = 89e12; // tokenPrice is rate / 1e18
        rate = 11235;  // rate is 1e18 / tokenPrice
        bonus = 100;
        minInvestment = 1e17;
        multiSigWallet = 0xE1377e465121776d8810007576034c7E0798CD46;
        tokensSold = 0;
        icoState = State.FIRST_PRE_ICO;
        FirstPreIcoActivated(now, endTime, bonus);
    }

    /**
    * Sets the address of the token. This function can only be executed by the 
    * owner of the contract.
    **/
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != 0x0);
        MSTCOIN = ERC20TransferInterface(_tokenAddress);
        TokenAddressSet(_tokenAddress);
    }

    /**
    * Returns the address of the token. 
    **/
    function getTokenAddress() public view returns(address) {
        return address(MSTCOIN);
    }

    /**
    * Allows the owner to activate the second pre ICO. This function can only be 
    * executed once the first pre ICO has finished. 
    **/
    function activateSecondPreIco() public onlyOwner {
        require(now >= endTime && icoState == State.FIRST_PRE_ICO);
        icoState = State.SECOND_PRE_ICO;
        endTime = now.add(4 days);
        bonus = 50;
        SecondPreIcoActivated(now, endTime, bonus);
    }

    /**
    * Allows the owner to activate the main public ICO stage. This function can only be 
    * executed once the second pre ICO has finished. 
    **/
    function activateMainIco() public onlyOwner {
        require(now >= endTime && icoState == State.SECOND_PRE_ICO);
        icoState = State.MAIN_ICO;
        mainIcoBonusStages[0] = now.add(7 days);
        mainIcoBonusStages[1] = now.add(14 days);
        mainIcoBonusStages[2] = now.add(21 days);
        mainIcoBonusStages[3] = now.add(31 days);
        endTime = now.add(31 days);
        bonus = 35;
        MainIcoActivated(now, endTime, bonus);
    }

    /**
    * Allows the owner to change the price of the token. 
    *
    * @param _newTokenPrice The new price per token. 
    **/
    function changeTokenPrice(uint256 _newTokenPrice) public onlyOwner {
        require(tokenPrice != _newTokenPrice && _newTokenPrice > 0);
        tokenPrice = _newTokenPrice;
        uint256 eth = 1e18;
        rate = eth.div(tokenPrice);
        TokenPriceChanged(tokenPrice, rate);
    }

    /**
    * Allows the owner to change the exchange rate of the token.
    *
    * @param _newRate The new exchange rate
    **/
    function changeRate(uint256 _newRate) public onlyOwner {
        require(rate != _newRate && _newRate > 0);
        rate = _newRate;
        uint256 x = 1e12;
        tokenPrice = x.div(rate);
        ExchangeRateChanged(rate, tokenPrice);
    }

    /**
    * Allows the owner to change the bonus of the current ICO stage. 
    *
    * @param _newBonus The new bonus percentage investors will receive.
    **/
    function changeBonus(uint256 _newBonus) public onlyOwner {
        require(bonus != _newBonus && _newBonus > 0);
        bonus = _newBonus;
        BonuseChanged(bonus);
    }

    /**
    * Allows the owner to sell tokens with other forms of payment including fiat and all other
    * cryptos. 
    *
    * @param _recipient The address to send tokens to.
    * @param _value The amount of tokens to be sent.
    **/
    function processOffchainTokenPurchase(address _recipient, uint256 _value) public onlyOwner {
        require(MSTCOIN.balanceOf(address(this)) >= _value);
        require(_recipient != 0x0 && _value > 0);
        MSTCOIN.transfer(_recipient, _value);
        tokensSold = tokensSold.add(_value);
        OffchainPurchaseMade(_recipient, _value);
    }

    /**
    * Fallback function calls the buyTokens function automatically when an investment is made.
    **/
    function() public payable {
        buyTokens(msg.sender);
    }

    /**
    * Allows investors to send their ETH and automatically receive tokens in return.
    *
    * @param _recipient The addrewss which will receive tokens
    **/
    function buyTokens(address _recipient) public payable {
        uint256 msgVal = msg.value.div(1e12); //because token has 6 decimals
        require(MSTCOIN.balanceOf(address(this)) >= msgVal.mul(rate.mul(getBonus()).div(100)).add(rate) ) ;
        require(msg.value >= minInvestment && withinPeriod());
        require(_recipient != 0x0);
        uint256 toTransfer = msgVal.mul(rate.mul(getBonus()).div(100).add(rate));
        MSTCOIN.transfer(_recipient, toTransfer);
        tokensSold = tokensSold.add(toTransfer);
        investmentOf[msg.sender] = investmentOf[msg.sender].add(msg.value);
        TokensPurchased(_recipient, toTransfer, msg.value);
        forwardFunds();
    }

    /**
    * This function is internally called by the buyTokens function to automatically forward
    * all investments made to the multi signature wallet. 
    **/
    function forwardFunds() internal {
        multiSigWallet.transfer(msg.value);
    }

    /**
    * This function is internally called by the buyTokens function to ensure that investments
    * are made during times when the ICO is not paused and when the duration of the current 
    * phase has not finished.
    **/
    function withinPeriod() internal view returns(bool) {
        return IcoPaused == false && now < endTime && icoState != State.TERMINATED;
    }

    /**
    * Calculates and returns the bonus of the current ICO stage. During the main public ICO, the
    * first ICO the bonus stages are set as such:
    *
    * week 1: bonus = 35%
    * week 2: bonus = 25%
    * week 3: bonus = 15%
    * week 4: bonus = 5%
    **/
    function getBonus() public view returns(uint256 _bonus) {
        _bonus = bonus;
        if(icoState == State.MAIN_ICO) {
            if(now > mainIcoBonusStages[3]) {
                _bonus = 0;
            } else {
                uint256 timeStamp = now;
                for(uint i = 0; i < mainIcoBonusStages.length; i++) {
                    if(timeStamp <= mainIcoBonusStages[i]) {
                        break;
                    } else {
                        if(_bonus >= 15) {
                            _bonus = _bonus.sub(10);
                        }
                    }
                }
            }
        }
        return _bonus;
    }

    /**
    * Allows the owner of the contract to withdraw all unsold tokens. This function can 
    * only be executed once the ICO contract has been terminated after the main public 
    * ICO has finished. 
    *
    * @param _recipient The address to withdraw all unsold tokens to. If this field is 
    * left empty, then the tokens will just be sent to the owner of the contract. 
    **/
    function withdrawUnsoldTokens(address _recipient) public onlyOwner {
        require(icoState == State.TERMINATED);
        require(now >= endTime && MSTCOIN.balanceOf(address(this)) > 0);
        if(_recipient == 0x0) { 
            _recipient = owner; 
        }
        UnsoldTokensWithdrawn(MSTCOIN.balanceOf(address(this)));
        MSTCOIN.transfer(_recipient, MSTCOIN.balanceOf(address(this)));
    }

    /**
    * Allows the owner to pause the ICO contract. While the ICO is paused investments cannot
    * be made. 
    **/
    function pauseICO() public onlyOwner {
        require(!IcoPaused);
        IcoPaused = true;
        pausedTime = now;
        ICOPaused(now);
    }

    /**
    * Allows the owner to unpause the ICO only when the ICO contract has been paused. Once
    * invoked, the deadline will automatically be extended by the duration the ICO was 
    * paused for. 
    **/
    function unpauseICO() public onlyOwner {
        require(IcoPaused);
        IcoPaused = false;
        endTime = endTime.add(now.sub(pausedTime));
        ICOUnpaused(now);
    }


    /**
    * Allows the owner of the ICO to extend the deadline of the current ICO stage. This
    * function can only be executed if the ICO contract has not been terminated. 
    *
    * @param _days The number of days to increase the duration of the ICO by. 
    **/
    function extendDeadline(uint256 _days) public onlyOwner {
        require(icoState != State.TERMINATED);
        endTime = endTime.add(_days.mul(1 days));
        if(icoState == State.MAIN_ICO) {
            uint256 blocks = 0;
            uint256 stage = 0;
            for(uint i = 0; i < mainIcoBonusStages.length; i++) {
                if(now < mainIcoBonusStages[i]) {
                    stage = i;
                }
            }
            blocks = (_days.mul(1 days)).div(mainIcoBonusStages.length.sub(stage));
            for(uint x = stage; x < mainIcoBonusStages.length; x++) {
                mainIcoBonusStages[x] = mainIcoBonusStages[x].add(blocks);
            }
        }
        IcoDeadlineExtended(icoState, endTime);
    }

    /**
    * Allows the owner of the contract to shorten the deadline of the current ICO stage.
    *
    * @param _days The number of days to reduce the druation of the ICO by. 
    **/
    function shortenDeadline(uint256 _days) public onlyOwner {
        if(now.add(_days.mul(1 days)) >= endTime) {
            revert();
        } else {
            endTime = endTime.sub(_days.mul(1 days));
            if(icoState == State.MAIN_ICO) {
                uint256 blocks = 0;
                uint256 stage = 0;
                for(uint i = 0; i < mainIcoBonusStages.length; i++) {
                    if(now < mainIcoBonusStages[i]) {
                        stage = i;
                    }
                }
                blocks = (_days.mul(1 days)).div(mainIcoBonusStages.length.sub(stage));
                for(uint x = stage; x < mainIcoBonusStages.length; x++) {
                    mainIcoBonusStages[x] = mainIcoBonusStages[x].sub(blocks);
                }
            }
        }
        IcoDeadlineShortened(icoState, endTime);
    }

    /**
    * Terminates the ICO early permanently. This function can only be called by the
    * owner of the contract during the main public ICO. 
    **/
    function terminateIco() public onlyOwner {
        require(icoState == State.MAIN_ICO);
        require(now < endTime);
        endTime = now;
        icoState = State.TERMINATED;
        IcoTerminated(now);
    }

    /**
    * Returns the amount of tokens that have been sold.
    **/
    function getTokensSold() public view returns(uint256) {
        return tokensSold;
    }

    /**
    * Airdrops tokens to up to 100 ETH addresses. 
    *
    * @param _addrs The list of addresses to send tokens to
    * @param _values The list of amounts of tokens to send to each corresponding address.
    **/
    function airdrop(address[] _addrs, uint256[] _values) public onlyOwner returns(bool) {
        require(_addrs.length == _values.length && _addrs.length <= 100);
        require(MSTCOIN.balanceOf(address(this)) >= getSumOfValues(_values));
        for (uint i = 0; i < _addrs.length; i++) {
            if (_addrs[i] != 0x0 && _values[i] > 0) {
                MSTCOIN.transfer(_addrs[i], _values[i]);
            }
        }
        AirdropInvoked();
        return true;
    }

    /**
    * Called internally by the airdrop function to ensure the contract holds enough tokens
    * to succesfully execute the airdrop.
    *
    * @param _values The list of values representing the amount of tokens which will be airdroped.
    **/
    function getSumOfValues(uint256[] _values) internal pure returns(uint256) {
        uint256 sum = 0;
        for(uint i=0; i < _values.length; i++) {
            sum = sum.add(_values[i]);
        }
        return sum;
    } 
}