pragma solidity ^0.4.2;

contract Token {
    /* Public variables of the token */
    string public standard;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* ERC20 Events */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Token(uint256 initialSupply, string _standard, string _name, string _symbol, uint8 _decimals) {
        _totalSupply = initialSupply;
        balanceOf[this] = initialSupply;
        standard = _standard;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /* Get burnable total supply */
    function totalSupply() constant returns(uint256 supply) {
        return _totalSupply;
    }

    /**
     * Transfer token logic
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transferInternal(address _from, address _to, uint256 _value) internal returns (bool success) {
        require(balanceOf[_from] >= _value);

        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[_from] -= _value;

        balanceOf[_to] += _value;

        Transfer(_from, _to, _value);

        return true;
    }

    /**
     * Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        return true;
    }

    /**
     * Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */
    function transferFromInternal(address _from, address _to, uint256 _value) internal returns (bool success) {
        require(_value >= allowance[_from][msg.sender]);   // Check allowance

        allowance[_from][msg.sender] -= _value;

        return transferInternal(_from, _to, _value);
    }
}

contract ICO {
    uint256 public PRE_ICO_SINCE = 1500303600;                     // 07/17/2017 @ 15:00 (UTC)
    uint256 public PRE_ICO_TILL = 1500476400;                      // 07/19/2017 @ 15:00 (UTC)
    uint256 public constant PRE_ICO_BONUS_RATE = 70;
    uint256 public constant PRE_ICO_SLGN_LESS = 5000 ether;                 // upper limit for pre ico is 5k ether

    uint256 public ICO_SINCE = 1500994800;                         // 07/25/2017 @ 9:00am (UTC)
    uint256 public ICO_TILL = 1502809200;                          // 08/15/2017 @ 9:00am (UTC)
    uint256 public constant ICO_BONUS1_SLGN_LESS = 20000 ether;                // bonus 1 will work only if 20000 eth were collected during first phase of ico
    uint256 public constant ICO_BONUS1_RATE = 30;                           // bonus 1 rate
    uint256 public constant ICO_BONUS2_SLGN_LESS = 50000 ether;                // bonus 1 will work only if 50000 eth were collected during second phase of ico
    uint256 public constant ICO_BONUS2_RATE = 15; // bonus 2 rate

    uint256 public totalSoldSlogns;

    /* This generates a public event on the blockchain that will notify clients */
    event BonusEarned(address target, uint256 bonus);

    /**
     * Calculate amount of premium bonuses
     * @param icoStep identifies is it pre-ico (equals 0) or ico (equals 1)
     * @param totalSoldSlogns total amount of already sold slogn tokens.
     * @param soldSlogns total amount sold slogns in current transaction.
     */
    function calculateBonus(uint8 icoStep, uint256 totalSoldSlogns, uint256 soldSlogns) returns (uint256) {
        if(icoStep == 1) {
            // pre ico
            return soldSlogns / 100 * PRE_ICO_BONUS_RATE;
        }
        else if(icoStep == 2) {
            // ico
            if(totalSoldSlogns > ICO_BONUS1_SLGN_LESS + ICO_BONUS2_SLGN_LESS) {
                return 0;
            }

            uint256 availableForBonus1 = ICO_BONUS1_SLGN_LESS - totalSoldSlogns;

            uint256 tmp = soldSlogns;
            uint256 bonus = 0;

            uint256 tokensForBonus1 = 0;

            if(availableForBonus1 > 0 && availableForBonus1 <= ICO_BONUS1_SLGN_LESS) {
                tokensForBonus1 = tmp > availableForBonus1 ? availableForBonus1 : tmp;

                bonus += tokensForBonus1 / 100 * ICO_BONUS1_RATE;
                tmp -= tokensForBonus1;
            }

            uint256 availableForBonus2 = (ICO_BONUS2_SLGN_LESS + ICO_BONUS1_SLGN_LESS) - totalSoldSlogns - tokensForBonus1;

            uint256 tokensForBonus2 = 0;

            if(availableForBonus2 > 0 && availableForBonus2 <= ICO_BONUS2_SLGN_LESS) {
                tokensForBonus2 = tmp > availableForBonus2 ? availableForBonus2 : tmp;

                bonus += tokensForBonus2 / 100 * ICO_BONUS2_RATE;
                tmp -= tokensForBonus2;
            }

            return bonus;
        }

        return 0;
    }
}

contract EscrowICO is Token, ICO {
    uint256 public constant MIN_PRE_ICO_SLOGN_COLLECTED = 1000 ether;       // PRE ICO is successful only if sold 10.000.000 slogns
    uint256 public constant MIN_ICO_SLOGN_COLLECTED = 1000 ether;          // ICO is successful only if sold 100.000.000 slogns

    bool public isTransactionsAllowed;

    uint256 public totalSoldSlogns;

    mapping (address => uint256) public preIcoEthers;
    mapping (address => uint256) public icoEthers;

    event RefundEth(address indexed owner, uint256 value);
    event IcoFinished();

    function EscrowICO() {
        isTransactionsAllowed = false;
    }

    function getIcoStep(uint256 time) returns (uint8 step) {
        if(time >=  PRE_ICO_SINCE && time <= PRE_ICO_TILL) {
            return 1;
        }
        else if(time >= ICO_SINCE && time <= ICO_TILL) {
            // ico shoud fail if collected less than 1000 slogns during pre ico
            if(totalSoldSlogns >= MIN_PRE_ICO_SLOGN_COLLECTED) {
                return 2;
            }
        }

        return 0;
    }

    /**
     * officially finish ICO, only allowed after ICO is ended
     */
    function icoFinishInternal(uint256 time) internal returns (bool) {
        if(time <= ICO_TILL) {
            return false;
        }

        if(totalSoldSlogns >= MIN_ICO_SLOGN_COLLECTED) {
            // burn tokens assigned to smart contract

            _totalSupply = _totalSupply - balanceOf[this];

            balanceOf[this] = 0;

            // allow transactions for everyone
            isTransactionsAllowed = true;

            IcoFinished();

            return true;
        }

        return false;
    }

    /**
     * refund ico method
     */
    function refundInternal(uint256 time) internal returns (bool) {
        if(time <= PRE_ICO_TILL) {
            return false;
        }

        if(totalSoldSlogns >= MIN_PRE_ICO_SLOGN_COLLECTED) {
            return false;
        }

        uint256 transferedEthers;

        transferedEthers = preIcoEthers[msg.sender];

        if(transferedEthers > 0) {
            preIcoEthers[msg.sender] = 0;

            balanceOf[msg.sender] = 0;

            msg.sender.transfer(transferedEthers);

            RefundEth(msg.sender, transferedEthers);

            return true;
        }

        return false;
    }
}

contract SlognToken is Token, EscrowICO {
    string public constant STANDARD = &#39;Slogn v0.1&#39;;
    string public constant NAME = &#39;SLOGN&#39;;
    string public constant SYMBOL = &#39;SLGN&#39;;
    uint8 public constant PRECISION = 14;

    uint256 public constant TOTAL_SUPPLY = 800000 ether; // initial total supply equals to 8.000.000.000 slogns or 800.000 eths

    uint256 public constant CORE_TEAM_TOKENS = TOTAL_SUPPLY / 100 * 15;       // 15%
    uint256 public constant ADVISORY_BOARD_TOKENS = TOTAL_SUPPLY / 1000 * 15;       // 1.5%
    uint256 public constant OPENSOURCE_TOKENS = TOTAL_SUPPLY / 1000 * 75;     // 7.5%
    uint256 public constant RESERVE_TOKENS = TOTAL_SUPPLY / 100 * 5;          // 5%
    uint256 public constant BOUNTY_TOKENS = TOTAL_SUPPLY / 100;               // 1%

    address public advisoryBoardFundManager;
    address public opensourceFundManager;
    address public reserveFundManager;
    address public bountyFundManager;
    address public ethFundManager;
    address public owner;

    /* This generates a public event on the blockchain that will notify clients */
    event BonusEarned(address target, uint256 bonus);

    /* Modifiers */
    modifier onlyOwner() {
        require(owner == msg.sender);

        _;
    }

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function SlognToken(
    address [] coreTeam,
    address _advisoryBoardFundManager,
    address _opensourceFundManager,
    address _reserveFundManager,
    address _bountyFundManager,
    address _ethFundManager
    )
    Token (TOTAL_SUPPLY, STANDARD, NAME, SYMBOL, PRECISION)
    EscrowICO()
    {
        owner = msg.sender;

        advisoryBoardFundManager = _advisoryBoardFundManager;
        opensourceFundManager = _opensourceFundManager;
        reserveFundManager = _reserveFundManager;
        bountyFundManager = _bountyFundManager;
        ethFundManager = _ethFundManager;

        // transfer tokens to core team
        uint256 tokensPerMember = CORE_TEAM_TOKENS / coreTeam.length;

        for(uint8 i = 0; i < coreTeam.length; i++) {
            transferInternal(this, coreTeam[i], tokensPerMember);
        }

        // Advisory board fund
        transferInternal(this, advisoryBoardFundManager, ADVISORY_BOARD_TOKENS);

        // Opensource fund
        transferInternal(this, opensourceFundManager, OPENSOURCE_TOKENS);

        // Reserve fund
        transferInternal(this, reserveFundManager, RESERVE_TOKENS);

        // Bounty fund
        transferInternal(this, bountyFundManager, BOUNTY_TOKENS);
    }

    function buyFor(address _user, uint256 ethers, uint time) internal returns (bool success) {
        require(ethers > 0);

        uint8 icoStep = getIcoStep(time);

        require(icoStep == 1 || icoStep == 2);

        // maximum collected amount for preico is 5000 ether
        if(icoStep == 1 && (totalSoldSlogns + ethers) > 5000 ether) {
            throw;
        }

        uint256 slognAmount = ethers; // calculates the amount

        uint256 bonus = calculateBonus(icoStep, totalSoldSlogns, slognAmount);

        // check for available slogns
        require(balanceOf[this] >= slognAmount + bonus);

        if(bonus > 0) {
            BonusEarned(_user, bonus);
        }

        transferInternal(this, _user, slognAmount + bonus);

        totalSoldSlogns += slognAmount;

        if(icoStep == 1) {
            preIcoEthers[_user] += ethers;      // fill ethereum used for refund if goal not reached
        }
        if(icoStep == 2) {
            icoEthers[_user] += ethers;      // fill ethereum used for refund if goal not reached
        }

        return true;
    }

    /**
     * Buy Slogn tokens
     */
    function buy() payable {
        buyFor(msg.sender, msg.value, block.timestamp);
    }

    /**
     * Manage ethereum balance
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transferEther(address to, uint256 value) returns (bool success) {
        if(msg.sender != ethFundManager) {
            return false;
        }

        if(totalSoldSlogns < MIN_PRE_ICO_SLOGN_COLLECTED) {
            return false;
        }

        if(this.balance < value) {
            return false;
        }

        to.transfer(value);

        return true;
    }

    /**
     * Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) returns (bool success) {
        if(isTransactionsAllowed == false) {
            if(msg.sender != bountyFundManager) {
                return false;
            }
        }

        return transferInternal(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if(isTransactionsAllowed == false) {
            if(_from != bountyFundManager) {
                return false;
            }
        }

        return transferFromInternal(_from, _to, _value);
    }

    function refund() returns (bool) {
        return refundInternal(block.timestamp);
    }

    function icoFinish() returns (bool) {
        return icoFinishInternal(block.timestamp);
    }

    function setPreIcoDates(uint256 since, uint256 till) onlyOwner {
        PRE_ICO_SINCE = since;
        PRE_ICO_TILL = till;
    }

    function setIcoDates(uint256 since, uint256 till) onlyOwner {
        ICO_SINCE = since;
        ICO_TILL = till;
    }

    function setTransactionsAllowed(bool enabled) onlyOwner {
        isTransactionsAllowed = enabled;
    }

    function () payable {
        throw;
    }
}