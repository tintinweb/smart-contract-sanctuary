pragma solidity 0.4.19;

contract ERC20Interface {
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
}

/* 1. Contract is initiated by storing sender as OWNER and with following arguments:
 * deadline : block.number which defines deadline of users authorisation and funds processing
 * extendedTime : number of blocks which defines extension of deadline
 * maxTime : block.number which defines maximum period for deadline extension
 * manager : address which is set as MANAGER.
 * Only MANAGER is allowed to perform operational functions:
 * - to authorize users in General Token Sale
 * - to add Tokens to the List of acceptable tokens
 * recipient : multisig contract to collect unclaimed funds
 * recipientContainer : multisig contract to collect other funds which remain on contract after deadline */
contract TokenSaleQueue {
    using SafeMath for uint256;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    /* Struct with  properties of each record for &#39;deposits&#39; mapping */
    struct Record {
        uint256 balance;
        bool authorized;
    }
    /* Contract has internal mapping `deposits`:
     * Address -> (balance: uint, authorized: bool).
     * It represents balance of everyone whoever used `deposit` method.
     *
     * This is where balances of all participants are stored. Additional flag of
     * whether the participant is authorized investor is stored. This flag
     * determines if the participant has passed AML/KYC check and reservation
     * payment can be transferred to general Token Sale  */
    mapping(address => Record) public deposits;
    address public manager; /* Contract administrator */
    address public recipient; /* Unclaimed funds collector */
    address public recipientContainer; /* Undefined funds collector */
    uint public deadline; /* blocks */
    uint public extendedTime; /* blocks */
    uint public maxTime; /* blocks */
    uint public finalTime; /* deadline + extendedTime - blocks */

    /* Amount of wei raised */
    uint256 public weiRaised;

    function() public payable {
        deposit();
    }

    /* A set of functions to get required variables */
    function balanceOf(address who) public view returns (uint256 balance) {
        return deposits[who].balance;
    }

    function isAuthorized(address who) public view returns (bool authorized) {
        return deposits[who].authorized;
    }

    function getDeadline() public view returns (uint) {
        return deadline;
    }

    function getManager() public view returns (address) {
        return manager;
    }

    /* Contract has events for integration purposes */
    event Whitelist(address who);
    event Deposit(address who, uint256 amount);
    event Withdrawal(address who);
    event Authorized(address who);
    event Process(address who);
    event Refund(address who);

    /* `TokenSaleQueue` is executed after the contract deployment, it sets up the Contract */
    function TokenSaleQueue(address _owner, address _manager,  address _recipient, address _recipientContainer, uint _deadline, uint _extendedTime, uint _maxTime) public {
        require(_owner != address(0));
        require(_manager != address(0));
        require(_recipient != address(0));
        require(_recipientContainer != address(0));

        owner = _owner;
        manager = _manager;
        recipient = _recipient;
        recipientContainer = _recipientContainer;
        deadline = _deadline;
        extendedTime = _extendedTime;
        maxTime = _maxTime;
        finalTime = deadline + extendedTime;
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    /* Contract has mapping `whitelist`.
     * It contains participants addresses which have passed AML check and are allowed to deposit funds */
    mapping(address => bool) whitelist;

    /* Manager adds user to whitelist by executing function `addAddressInWhitelist` */
    /* Contract checks if sender is equal to manager */
    function addAddressInWhitelist(address who) public onlyManager {
        require(who != address(0));
        whitelist[who] = true;
        Whitelist(who);
    }

    function isInWhiteList(address who) public view returns (bool result) {
        return whitelist[who];
    }

    /* 3. Contract has payable method deposit
     * Partisipant transfers reservation payment in Ether by executing this method.
     * Participant can withdraw funds at anytime (4.) */
    function deposit() public payable {
        /* Contract checks that method invocation attaches non-zero value. */
        require(msg.value > 0);

        /* Contract checks whether the user is in whitelist */
        require(whitelist[msg.sender]);

        /* Contract checks if `finalTime` is not reached.
         * If reached, it returns funds to `sender` and transfers uclaimed Ether to recipient. */
        if (block.number <= finalTime) {
            /* Contract adds value sent to the participant&#39;s balance in `deposit` mapping */
            deposits[msg.sender].balance = deposits[msg.sender].balance.add(msg.value);
            weiRaised = weiRaised.add(msg.value);
            Deposit(msg.sender, msg.value);
        } else {
            msg.sender.transfer(msg.value);
            if (weiRaised != 0) {
                uint256 sendToRecepient = weiRaised;
                weiRaised = 0;
                recipient.transfer(sendToRecepient);
            }
        }
    }

    /* 4. Contract has method withdraw
     * Participant can withdraw reservation payment in Ether deposited with deposit function (1.).
     * This method can be executed at anytime. */
    function withdraw() public {
        /* Contract checks that balance of the sender in `deposits` mapping is a non-zero value */
        Record storage record = deposits[msg.sender];
        require(record.balance > 0);

        uint256 balance = record.balance;
        /* Contract sets participant&#39;s balance to zero in `deposits` mapping */
        record.balance = 0;

        weiRaised = weiRaised.sub(balance);
        /* Contract transfers sender&#39;s ETH balance to his address */
        msg.sender.transfer(balance);
        Withdrawal(msg.sender);
    }

    /* 5. Contract has method authorize with address argument */
    /* Manager authorizes particular participant to transfer reservation payment to Token Sale */
    function authorize(address who) onlyManager public {
        /* Contract checks if sender is equal to manager */
        require(who != address(0));

        Record storage record = deposits[who];

        /* Contract updates value in `whitelist` mapping and flags participant as authorized */
        record.authorized = true;
        Authorized(who);
    }

    /* 6. Contract has method process */
    /* Sender transfers reservation payment in Ether to owner to be redirected to the Token Sale */
    function process() public {
        Record storage record = deposits[msg.sender];

        /* Contract checks whether participant&#39;s `deposits` balance is a non-zero value and authorized is set to true */
        require(record.authorized);
        require(record.balance > 0);

        uint256 balance = record.balance;
        /* Contract sets balance of the sender entry to zero in the `deposits` */
        record.balance = 0;

        weiRaised = weiRaised.sub(balance);

        /* Contract transfers balance to the owner */
        owner.transfer(balance);

        Process(msg.sender);
    }

    /* Contract has internal mapping `tokenDeposits`:
     * Address -> (balance: uint, authorized: bool)
     *
     * It represents token balance of everyone whoever used `tokenDeposit`
     * method and stores token balances of all participants. It stores aditional
     * flag of whether the participant is authorized, which determines if the
     * participant&#39;s reservation payment in tokens can be transferred to General Token Sale */
    mapping(address => mapping(address => uint256)) public tokenDeposits;

    /* Whitelist of tokens which can be accepted as reservation payment */
    mapping(address => bool) public tokenWalletsWhitelist;
    address[] tokenWallets;
    mapping(address => uint256) public tokenRaised;
    bool reclaimTokenLaunch = false;

    /* Manager can add tokens to whitelist. */
    function addTokenWalletInWhitelist(address tokenWallet) public onlyManager {
        require(tokenWallet != address(0));
        require(!tokenWalletsWhitelist[tokenWallet]);
        tokenWalletsWhitelist[tokenWallet] = true;
        tokenWallets.push(tokenWallet);
        TokenWhitelist(tokenWallet);
    }

    function tokenInWhiteList(address tokenWallet) public view returns (bool result) {
        return tokenWalletsWhitelist[tokenWallet];
    }

    function tokenBalanceOf(address tokenWallet, address who) public view returns (uint256 balance) {
        return tokenDeposits[tokenWallet][who];
    }

    /* Another list of events for integrations */
    event TokenWhitelist(address tokenWallet);
    event TokenDeposit(address tokenWallet, address who, uint256 amount);
    event TokenWithdrawal(address tokenWallet, address who);
    event TokenProcess(address tokenWallet, address who);
    event TokenRefund(address tokenWallet, address who);

    /* 7. Contract has method tokenDeposit
     * Partisipant transfers reservation payment in tokens by executing this method.
     * Participant can withdraw funds in tokens at anytime (8.) */
    function tokenDeposit(address tokenWallet, uint amount) public {
        /* Contract checks that method invocation attaches non-zero value. */
        require(amount > 0);

        /* Contract checks whether token wallet in whitelist */
        require(tokenWalletsWhitelist[tokenWallet]);

        /* Contract checks whether user in whitelist */
        require(whitelist[msg.sender]);

        /* msg.sender initiates transferFrom function from ERC20 contract */
        ERC20Interface ERC20Token = ERC20Interface(tokenWallet);

        /* Contract checks if `finalTime` is not reached. */
        if (block.number <= finalTime) {
            require(ERC20Token.transferFrom(msg.sender, this, amount));

            tokenDeposits[tokenWallet][msg.sender] = tokenDeposits[tokenWallet][msg.sender].add(amount);
            tokenRaised[tokenWallet] = tokenRaised[tokenWallet].add(amount);
            TokenDeposit(tokenWallet, msg.sender, amount);
        } else {
            reclaimTokens(tokenWallets);
        }
    }

    /* 8. Contract has method tokenWithdraw
     * Participant can withdraw reservation payment in tokens deposited with tokenDeposit function (7.).
     * This method can be executed at anytime. */
    function tokenWithdraw(address tokenWallet) public {
        /* Contract checks whether balance of the sender in `tokenDeposits` mapping is a non-zero value */
        require(tokenDeposits[tokenWallet][msg.sender] > 0);

        uint256 balance = tokenDeposits[tokenWallet][msg.sender];
        /* Contract sets sender token balance in `tokenDeposits` to zero */
        tokenDeposits[tokenWallet][msg.sender] = 0;
        tokenRaised[tokenWallet] = tokenRaised[tokenWallet].sub(balance);

        /* Contract transfers tokens to the sender from contract balance */
        ERC20Interface ERC20Token = ERC20Interface(tokenWallet);
        require(ERC20Token.transfer(msg.sender, balance));

        TokenWithdrawal(tokenWallet, msg.sender);
    }

    /* 9. Contract has method tokenProcess */
    /* Sender transfers reservation payment in tokens to owner to be redirected to the Token Sale */
    function tokenProcess(address tokenWallet) public {
        /* Contract checks that balance of the sender in `tokenDeposits` mapping
         * is a non-zero value and sender is authorized */
        require(deposits[msg.sender].authorized);
        require(tokenDeposits[tokenWallet][msg.sender] > 0);

        uint256 balance = tokenDeposits[tokenWallet][msg.sender];
        /* Contract sets sender balance to zero for the specified token */
        tokenDeposits[tokenWallet][msg.sender] = 0;
        tokenRaised[tokenWallet] = tokenRaised[tokenWallet].sub(balance);

        /* Contract transfers tokens to the owner */
        ERC20Interface ERC20Token = ERC20Interface(tokenWallet);
        require(ERC20Token.transfer(owner, balance));

        TokenProcess(tokenWallet, msg.sender);
    }

    /* recipientContainer can transfer undefined funds to itself and terminate
     * the Contract after finalDate */
    function destroy(address[] tokens) public {
        require(msg.sender == recipientContainer);
        require(block.number > finalTime);

        /* Transfer undefined tokens to recipientContainer */
        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20Interface token = ERC20Interface(tokens[i]);
            uint256 balance = token.balanceOf(this);
            token.transfer(recipientContainer, balance);
        }

        /* Transfer undefined Eth to recipientContainer and terminate contract */
        selfdestruct(recipientContainer);
    }

    /* Owner can change extendedTime if required.
     * finalTime = deadline + extendedTime - should not exceed maxTime */
    function changeExtendedTime(uint _extendedTime) public onlyOwner {
        require((deadline + _extendedTime) < maxTime);
        require(_extendedTime > extendedTime);
        extendedTime = _extendedTime;
        finalTime = deadline + extendedTime;
    }

    /* Internal method which retrieves unclaimed funds in tokens */
    function reclaimTokens(address[] tokens) internal {
        require(!reclaimTokenLaunch);

        /* Transfer tokens to recipient */
        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20Interface token = ERC20Interface(tokens[i]);
            uint256 balance = tokenRaised[tokens[i]];
            tokenRaised[tokens[i]] = 0;
            token.transfer(recipient, balance);
        }

        reclaimTokenLaunch = true;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}