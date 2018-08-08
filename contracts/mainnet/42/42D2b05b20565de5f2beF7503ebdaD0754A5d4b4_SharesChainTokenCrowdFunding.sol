pragma solidity ^0.4.18;

    /**
    * Math operations with safety checks
    */
    library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    }


    contract Owned {

        /// @dev `owner` is the only address that can call a function with this
        /// modifier
        modifier onlyOwner() {
            require(msg.sender == owner);
            _;
        }

        address public owner;
        /// @notice The Constructor assigns the message sender to be `owner`
        function Owned() public {
            owner = msg.sender;
        }

        address public newOwner;

        /// @notice `owner` can step down and assign some other address to this role
        /// @param _newOwner The address of the new owner. 0x0 can be used to create
        ///  an unowned neutral vault, however that cannot be undone
        function changeOwner(address _newOwner) onlyOwner public {
            newOwner = _newOwner;
        }


        function acceptOwnership() public {
            if (msg.sender == newOwner) {
                owner = newOwner;
            }
        }
    }


    contract ERC20Protocol {
        /* This is a slight change to the ERC20 base standard.
        function totalSupply() constant returns (uint supply);
        is replaced with:
        uint public totalSupply;
        This automatically creates a getter function for the totalSupply.
        This is moved to the base contract since public getter functions are not
        currently recognised as an implementation of the matching abstract
        function by the compiler.
        */
        /// total amount of tokens
        uint public totalSupply;

        /// @param _owner The address from which the balance will be retrieved
        /// @return The balance
        function balanceOf(address _owner) constant public returns (uint balance);

        /// @notice send `_value` token to `_to` from `msg.sender`
        /// @param _to The address of the recipient
        /// @param _value The amount of token to be transferred
        /// @return Whether the transfer was successful or not
        function transfer(address _to, uint _value) public returns (bool success);

        /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
        /// @param _from The address of the sender
        /// @param _to The address of the recipient
        /// @param _value The amount of token to be transferred
        /// @return Whether the transfer was successful or not
        function transferFrom(address _from, address _to, uint _value) public returns (bool success);

        /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
        /// @param _spender The address of the account able to transfer the tokens
        /// @param _value The amount of tokens to be approved for transfer
        /// @return Whether the approval was successful or not
        function approve(address _spender, uint _value) public returns (bool success);

        /// @param _owner The address of the account owning tokens
        /// @param _spender The address of the account able to transfer the tokens
        /// @return Amount of remaining tokens allowed to spent
        function allowance(address _owner, address _spender) constant public returns (uint remaining);

        event Transfer(address indexed _from, address indexed _to, uint _value);
        event Approval(address indexed _owner, address indexed _spender, uint _value);
    }

    contract StandardToken is ERC20Protocol {
        using SafeMath for uint;

        /**
        * @dev Fix for the ERC20 short address attack.
        */
        modifier onlyPayloadSize(uint size) {
            require(msg.data.length >= size + 4);
            _;
        }

        function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public returns (bool success) {
            //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
            //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
            //Replace the if with this one instead.
            //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            if (balances[msg.sender] >= _value) {
                balances[msg.sender] -= _value;
                balances[_to] += _value;
                Transfer(msg.sender, _to, _value);
                return true;
            } else { return false; }
        }

        function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) public returns (bool success) {
            //same as above. Replace this line with the following if you want to protect against wrapping uints.
            //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value) {
                balances[_to] += _value;
                balances[_from] -= _value;
                allowed[_from][msg.sender] -= _value;
                Transfer(_from, _to, _value);
                return true;
            } else { return false; }
        }

        function balanceOf(address _owner) constant public returns (uint balance) {
            return balances[_owner];
        }

        function approve(address _spender, uint _value) onlyPayloadSize(2 * 32) public returns (bool success) {
            // To change the approve amount you first have to reduce the addresses`
            //  allowance to zero by calling `approve(_spender, 0)` if it is not
            //  already 0 to mitigate the race condition described here:
            //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
            assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        }

        function allowance(address _owner, address _spender) constant public returns (uint remaining) {
        return allowed[_owner][_spender];
        }

        mapping (address => uint) balances;
        mapping (address => mapping (address => uint)) allowed;
    }

    contract SharesChainToken is StandardToken {
        /// Constant token specific fields
        string public constant name = "SharesChainToken";
        string public constant symbol = "SCTK";
        uint public constant decimals = 18;

        /// SharesChain total tokens supply
        uint public constant MAX_TOTAL_TOKEN_AMOUNT = 20000000000 ether;

        /// Fields that are only changed in constructor
        /// SharesChain contribution contract
        address public minter;

        /*
        * MODIFIERS
        */

        modifier onlyMinter {
            assert(msg.sender == minter);
            _;
        }

        modifier maxTokenAmountNotReached (uint amount){
            assert(totalSupply.add(amount) <= MAX_TOTAL_TOKEN_AMOUNT);
            _;
        }

        /**
        * CONSTRUCTOR
        *
        * @dev Initialize the SharesChain Token
        * @param _minter The SharesChain Crowd Funding Contract
        */
        function SharesChainToken(address _minter) public {
            minter = _minter;
        }


        /**
        * EXTERNAL FUNCTION
        *
        * @dev Contribution contract instance mint token
        * @param recipient The destination account owned mint tokens
        * be sent to this address.
        */
        function mintToken(address recipient, uint _amount)
            public
            onlyMinter
            maxTokenAmountNotReached(_amount)
            returns (bool)
        {
            totalSupply = totalSupply.add(_amount);
            balances[recipient] = balances[recipient].add(_amount);
            return true;
        }
    }

    contract SharesChainTokenCrowdFunding is Owned {
    using SafeMath for uint;

     /*
      * Constant fields
      */
    /// SharesChain total tokens supply
    uint public constant MAX_TOTAL_TOKEN_AMOUNT = 20000000000 ether;

    // 最大募集以太币数量
    uint public constant MAX_CROWD_FUNDING_ETH = 30000 ether;

    // Reserved tokens
    uint public constant TEAM_INCENTIVES_AMOUNT = 2000000000 ether; // 10%
    uint public constant OPERATION_AMOUNT = 2000000000 ether;       // 10%
    uint public constant MINING_POOL_AMOUNT = 8000000000 ether;     // 40%
    uint public constant MAX_PRE_SALE_AMOUNT = 8000000000 ether;    // 40%

    // Addresses of Patrons
    address public TEAM_HOLDER;
    address public MINING_POOL_HOLDER;
    address public OPERATION_HOLDER;

    /// Exchange rate 1 ether == 205128 SCTK
    uint public constant EXCHANGE_RATE = 205128;
    uint8 public constant MAX_UN_LOCK_TIMES = 10;

    /// Fields that are only changed in constructor
    /// All deposited ETH will be instantly forwarded to this address.
    address public walletOwnerAddress;
    /// Crowd sale start time
    uint public startTime;


    SharesChainToken public sharesChainToken;

    /// Fields that can be changed by functions
    uint16 public numFunders;
    uint public preSoldTokens;
    uint public crowdEther;

    /// tags show address can join in open sale
    mapping (address => bool) public whiteList;

    /// 记录投资人地址
    address[] private investors;

    /// 记录剩余释放次数
    mapping (address => uint8) leftReleaseTimes;

    /// 记录投资人锁定的Token数量
    mapping (address => uint) lockedTokens;

    /// Due to an emergency, set this to true to halt the contribution
    bool public halted;

    /// 记录当前众筹是否结束
    bool public close;

    /*
     * EVENTS
     */

    event NewSale(address indexed destAddress, uint ethCost, uint gotTokens);

    /*
     * MODIFIERS
     */
    modifier notHalted() {
        require(!halted);
        _;
    }

    modifier isHalted() {
        require(halted);
        _;
    }

    modifier isOpen() {
        require(!close);
        _;
    }

    modifier isClose() {
        require(close);
        _;
    }

    modifier onlyWalletOwner {
        require(msg.sender == walletOwnerAddress);
        _;
    }

    modifier initialized() {
        require(address(walletOwnerAddress) != 0x0);
        _;
    }

    modifier ceilingEtherNotReached(uint x) {
        require(crowdEther.add(x) <= MAX_CROWD_FUNDING_ETH);
        _;
    }

    modifier earlierThan(uint x) {
        require(now < x);
        _;
    }

    modifier notEarlierThan(uint x) {
        require(now >= x);
        _;
    }

    modifier inWhiteList(address user) {
        require(whiteList[user]);
        _;
    }

    /**
     * CONSTRUCTOR
     *
     * @dev Initialize the SharesChainToken contribution contract
     * @param _walletOwnerAddress The escrow account address, all ethers will be sent to this address.
     * @param _startTime ICO boot time
     */
    function SharesChainTokenCrowdFunding(address _owner, address _walletOwnerAddress, uint _startTime, address _teamHolder, address _miningPoolHolder, address _operationHolder) public {
        require(_walletOwnerAddress != 0x0);
        owner = _owner;
        halted = false;
        close = false;
        walletOwnerAddress = _walletOwnerAddress;
        startTime = _startTime;
        preSoldTokens = 0;
        crowdEther = 0;
        TEAM_HOLDER = _teamHolder;
        MINING_POOL_HOLDER = _miningPoolHolder;
        OPERATION_HOLDER = _operationHolder;
        sharesChainToken = new SharesChainToken(this);
        sharesChainToken.mintToken(_teamHolder, TEAM_INCENTIVES_AMOUNT);
        sharesChainToken.mintToken(_miningPoolHolder, MINING_POOL_AMOUNT);
        sharesChainToken.mintToken(_operationHolder, OPERATION_AMOUNT);
    }

    /**
     * Fallback function
     *
     * @dev If anybody sends Ether directly to this  contract, consider he is getting SharesChain token
     */
    function () public payable {
        buySCTK(msg.sender, msg.value);
    }


    /// @dev Exchange msg.value ether to SCTK for account receiver
    /// @param receiver SCTK tokens receiver
    function buySCTK(address receiver, uint costEth)
        private
        notHalted
        isOpen
        initialized
        inWhiteList(receiver)
        ceilingEtherNotReached(costEth)
        notEarlierThan(startTime)
        returns (bool)
    {
        require(receiver != 0x0);
        require(costEth >= 1 ether);

        // Do not allow contracts to game the system
        require(!isContract(receiver));

        if (lockedTokens[receiver] == 0) {
            numFunders++;
            investors.push(receiver);
            leftReleaseTimes[receiver] = MAX_UN_LOCK_TIMES; // 禁止在执行解锁之后重新启动众筹
        }

        // 根据投资者输入的以太坊数量确定赠送的SCTK数量
        uint gotTokens = calculateGotTokens(costEth);

        // 累计预售的Token不能超过最大预售量
        require(preSoldTokens.add(gotTokens) <= MAX_PRE_SALE_AMOUNT);
        lockedTokens[receiver] = lockedTokens[receiver].add(gotTokens);
        preSoldTokens = preSoldTokens.add(gotTokens);
        crowdEther = crowdEther.add(costEth);
        walletOwnerAddress.transfer(costEth);
        NewSale(receiver, costEth, gotTokens);
        return true;
    }


    /// @dev Set white list in batch.
    function setWhiteListInBatch(address[] users)
        public
        onlyOwner
    {
        for (uint i = 0; i < users.length; i++) {
            whiteList[users[i]] = true;
        }
    }

    /// @dev  Add one user into white list.
    function addOneUserIntoWhiteList(address user)
        public
        onlyOwner
    {
        whiteList[user] = true;
    }

    /// query locked tokens
    function queryLockedTokens(address user) public view returns(uint) {
        return lockedTokens[user];
    }


    // 根据投资者输入的以太坊数量确定赠送的SCTK数量
    function calculateGotTokens(uint costEther) pure internal returns (uint gotTokens) {
        gotTokens = costEther * EXCHANGE_RATE;
        if (costEther > 0 && costEther < 100 ether) {
            gotTokens = gotTokens.mul(1);
        }else if (costEther >= 100 ether && costEther < 500 ether) {
            gotTokens = gotTokens.mul(115).div(100);
        }else {
            gotTokens = gotTokens.mul(130).div(100);
        }
        return gotTokens;
    }

    /// @dev Emergency situation that requires contribution period to stop.
    /// Contributing not possible anymore.
    function halt() public onlyOwner {
        halted = true;
    }

    /// @dev Emergency situation resolved.
    /// Contributing becomes possible again withing the outlined restrictions.
    function unHalt() public onlyOwner {
        halted = false;
    }

    /// Stop crowding, cannot re-start.
    function stopCrowding() public onlyOwner {
        close = true;
    }

    /// @dev Emergency situation
    function changeWalletOwnerAddress(address newWalletAddress) public onlyWalletOwner {
        walletOwnerAddress = newWalletAddress;
    }


    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) {
            return false;
        }
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }


    function releaseRestPreSaleTokens()
        public
        onlyOwner
        isClose
    {
        uint unSoldTokens = MAX_PRE_SALE_AMOUNT - preSoldTokens;
        sharesChainToken.mintToken(OPERATION_HOLDER, unSoldTokens);
    }

    /*
     * PUBLIC FUNCTIONS
     */

    /// Manually unlock 10% total tokens
    function unlock10PercentTokensInBatch()
        public
        onlyOwner
        isClose
        returns (bool)
    {
        for (uint8 i = 0; i < investors.length; i++) {
            if (leftReleaseTimes[investors[i]] > 0) {
                uint releasedTokens = lockedTokens[investors[i]] / leftReleaseTimes[investors[i]];
                sharesChainToken.mintToken(investors[i], releasedTokens);
                lockedTokens[investors[i]] = lockedTokens[investors[i]] - releasedTokens;
                leftReleaseTimes[investors[i]] = leftReleaseTimes[investors[i]] - 1;
            }
        }
        return true;
    }
}