pragma solidity ^0.4.11;
contract ConfigInterface {
        address public owner;
        mapping(address => bool) admins;
        mapping(bytes32 => address) addressMap;
        mapping(bytes32 => bool) boolMap;
        mapping(bytes32 => bytes32) bytesMap;
        mapping(bytes32 => uint256) uintMap;

        /// @notice setConfigAddress sets configuration `_key` to `_val`
        /// @param _key The key name of the configuration.
        /// @param _val The value of the configuration.
        /// @return Whether the configuration setting was successful or not.
        function setConfigAddress(bytes32 _key, address _val) returns(bool success);

        /// @notice setConfigBool sets configuration `_key` to `_val`
        /// @param _key The key name of the configuration.
        /// @param _val The value of the configuration.
        /// @return Whether the configuration setting was successful or not.
        function setConfigBool(bytes32 _key, bool _val) returns(bool success);

        /// @notice setConfigBytes sets configuration `_key` to `_val`
        /// @param _key The key name of the configuration.
        /// @param _val The value of the configuration.
        /// @return Whether the configuration setting was successful or not.
        function setConfigBytes(bytes32 _key, bytes32 _val) returns(bool success);

        /// @notice setConfigUint `_key` to `_val`
        /// @param _key The key name of the configuration.
        /// @param _val The value of the configuration.
        /// @return Whether the configuration setting was successful or not.
        function setConfigUint(bytes32 _key, uint256 _val) returns(bool success);

        /// @notice getConfigAddress gets configuration `_key`&#39;s value
        /// @param _key The key name of the configuration.
        /// @return The configuration value
        function getConfigAddress(bytes32 _key) returns(address val);

        /// @notice getConfigBool gets configuration `_key`&#39;s value
        /// @param _key The key name of the configuration.
        /// @return The configuration value
        function getConfigBool(bytes32 _key) returns(bool val);

        /// @notice getConfigBytes gets configuration `_key`&#39;s value
        /// @param _key The key name of the configuration.
        /// @return The configuration value
        function getConfigBytes(bytes32 _key) returns(bytes32 val);

        /// @notice getConfigUint gets configuration `_key`&#39;s value
        /// @param _key The key name of the configuration.
        /// @return The configuration value
        function getConfigUint(bytes32 _key) returns(uint256 val);

        /// @notice addAdmin sets `_admin` as configuration admin
        /// @return Whether the configuration setting was successful or not.
        function addAdmin(address _admin) returns(bool success);

        /// @notice removeAdmin removes  `_admin`&#39;s rights
        /// @param _admin The key name of the configuration.
        /// @return Whether the configuration setting was successful or not.
        function removeAdmin(address _admin) returns(bool success);

}

contract TokenInterface {

        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowed;
        mapping(address => bool) seller;

        address config;
        address owner;
        address dao;
        address public badgeLedger;
        bool locked;

        /// @return total amount of tokens
        uint256 public totalSupply;

        /// @param _owner The address from which the balance will be retrieved
        /// @return The balance
        function balanceOf(address _owner) constant returns(uint256 balance);

        /// @notice send `_value` tokens to `_to` from `msg.sender`
        /// @param _to The address of the recipient
        /// @param _value The amount of tokens to be transfered
        /// @return Whether the transfer was successful or not
        function transfer(address _to, uint256 _value) returns(bool success);

        /// @notice send `_value` tokens to `_to` from `_from` on the condition it is approved by `_from`
        /// @param _from The address of the sender
        /// @param _to The address of the recipient
        /// @param _value The amount of tokens to be transfered
        /// @return Whether the transfer was successful or not
        function transferFrom(address _from, address _to, uint256 _value) returns(bool success);

        /// @notice `msg.sender` approves `_spender` to spend `_value` tokens on its behalf
        /// @param _spender The address of the account able to transfer the tokens
        /// @param _value The amount of tokens to be approved for transfer
        /// @return Whether the approval was successful or not
        function approve(address _spender, uint256 _value) returns(bool success);

        /// @param _owner The address of the account owning tokens
        /// @param _spender The address of the account able to transfer the tokens
        /// @return Amount of remaining tokens of _owner that _spender is allowed to spend
        function allowance(address _owner, address _spender) constant returns(uint256 remaining);

        /// @notice mint `_amount` of tokens to `_owner`
        /// @param _owner The address of the account receiving the tokens
        /// @param _amount The amount of tokens to mint
        /// @return Whether or not minting was successful
        function mint(address _owner, uint256 _amount) returns(bool success);

        /// @notice mintBadge Mint `_amount` badges to `_owner`
        /// @param _owner The address of the account receiving the tokens
        /// @param _amount The amount of tokens to mint
        /// @return Whether or not minting was successful
        function mintBadge(address _owner, uint256 _amount) returns(bool success);

        function registerDao(address _dao) returns(bool success);

        function registerSeller(address _tokensales) returns(bool success);

        event Transfer(address indexed _from, address indexed _to, uint256 indexed _value);
        event Mint(address indexed _recipient, uint256 indexed _amount);
        event Approval(address indexed _owner, address indexed _spender, uint256 indexed _value);
}

contract TokenSalesInterface {

        struct SaleProxy {
                address payout;
                bool isProxy;
        }

        struct SaleStatus {
                bool founderClaim;
                uint256 releasedTokens;
                uint256 releasedBadges;
                uint256 claimers;
        }

        struct Info {
                uint256 totalWei;
                uint256 totalCents;
                uint256 realCents;
                uint256 amount;
        }

        struct SaleConfig {
                uint256 startDate;
                uint256 periodTwo;
                uint256 periodThree;
                uint256 endDate;
                uint256 goal;
                uint256 cap;
                uint256 badgeCost;
                uint256 founderAmount;
                address founderWallet;
        }

        struct Buyer {
                uint256 centsTotal;
                uint256 weiTotal;
                bool claimed;
        }

        Info saleInfo;
        SaleConfig saleConfig;
        SaleStatus saleStatus;

        address config;
        address owner;
        bool locked;

        uint256 public ethToCents;

        mapping(address => Buyer) buyers;
        mapping(address => SaleProxy) proxies;

        /// @notice Calculates the parts per billion 1⁄1,000,000,000 of `_a` to `_b`
        /// @param _a The antecedent
        /// @param _c The consequent
        /// @return Part per billion value
        function ppb(uint256 _a, uint256 _c) public constant returns(uint256 b);


        /// @notice Calculates the share from `_total` based on `_contrib`
        /// @param _contrib The contributed amount in USD
        /// @param _total The total amount raised in USD
        /// @return Total number of shares
        function calcShare(uint256 _contrib, uint256 _total) public constant returns(uint256 share);

        /// @notice Calculates the current USD cents value of `_wei`
        /// @param _wei the amount of wei
        /// @return The USD cents value
        function weiToCents(uint256 _wei) public constant returns(uint256 centsvalue);

        function proxyPurchase(address _user) returns(bool success);

        /// @notice Send msg.value purchase for _user.
        /// @param _user The account to be credited
        /// @return Success if purchase was accepted
        function purchase(address _user, uint256 _amount) private returns(bool success);

        /// @notice Get crowdsale information for `_user`
        /// @param _user The account to be queried
        /// @return `centstotal` the total amount of USD cents contributed
        /// @return `weitotal` the total amount in wei contributed
        /// @return `share` the current token shares earned
        /// @return `badges` the number of proposer badges earned
        /// @return `claimed` is true if the tokens and badges have been claimed
        function userInfo(address _user) public constant returns(uint256 centstotal, uint256 weitotal, uint256 share, uint badges, bool claimed);

        /// @notice Get the crowdsale information from msg.sender (see userInfo)
        function myInfo() public constant returns(uint256 centstotal, uint256 weitotal, uint256 share, uint badges, bool claimed);

        /// @notice get the total amount of wei raised for the crowdsale
        /// @return The amount of wei raised
        function totalWei() public constant returns(uint);

        /// @notice get the total USD value in cents raised for the crowdsale
        /// @return the amount USD cents
        function totalCents() public constant returns(uint);

        /// @notice get the current crowdsale information
        /// @return `startsale` The unix timestamp for the start of the crowdsale and the first period modifier
        /// @return `two` The unix timestamp for the start of the second period modifier
        /// @return `three` The unix timestamp for the start of the third period modifier
        /// @return `endsale` The unix timestamp of the end of crowdsale
        /// @return `totalwei` The total amount of wei raised
        /// @return `totalcents` The total number of USD cents raised
        /// @return `amount` The amount of DGD tokens available for the crowdsale
        /// @return `goal` The USD value goal for the crowdsale
        /// @return `famount` Founders endowment
        /// @return `faddress` Founder wallet address
        /*function getSaleInfo() public constant returns (uint256 startsale, uint256 two, uint256 three, uint256 endsale, uint256 totalwei, uint256 totalcents, uint256 amount, uint256 goal, uint256 famount, address faddress);*/

        function claimFor(address _user) returns(bool success);

        /// @notice Allows msg.sender to claim the DGD tokens and badges if the goal is reached or refunds the ETH contributed if goal is not reached at the end of the crowdsale
        function claim() returns(bool success);

        function claimFounders() returns(bool success);

        /// @notice See if the crowdsale goal has been reached
        function goalReached() public constant returns(bool reached);

        /// @notice Get the current sale period
        /// @return `saleperiod` 0 = Outside of the crowdsale period, 1 = First reward period, 2 = Second reward period, 3 = Final crowdsale period.
        function getPeriod() public constant returns(uint saleperiod);

        /// @notice Get the date for the start of the crowdsale
        /// @return `date` The unix timestamp for the start
        function startDate() public constant returns(uint date);

        /// @notice Get the date for the second reward period of the crowdsale
        /// @return `date` The unix timestamp for the second period
        function periodTwo() public constant returns(uint date);

        /// @notice Get the date for the final period of the crowdsale
        /// @return `date` The unix timestamp for the final period
        function periodThree() public constant returns(uint date);

        /// @notice Get the date for the end of the crowdsale
        /// @return `date` The unix timestamp for the end of the crowdsale
        function endDate() public constant returns(uint date);

        /// @notice Check if crowdsale has ended
        /// @return `ended` If the crowdsale has ended

        function isEnded() public constant returns(bool ended);

        /// @notice Send raised funds from the crowdsale to the DAO
        /// @return `success` if the send succeeded
        function sendFunds() public returns(bool success);

        //function regProxy(address _payment, address _payout) returns (bool success);
        function regProxy(address _payout) returns(bool success);

        function getProxy(address _payout) public returns(address proxy);

        function getPayout(address _proxy) public returns(address payout, bool isproxy);

        function unlock() public returns(bool success);

        function getSaleStatus() public constant returns(bool fclaim, uint256 reltokens, uint256 relbadges, uint256 claimers);

        function getSaleInfo() public constant returns(uint256 weiamount, uint256 cents, uint256 realcents, uint256 amount);

        function getSaleConfig() public constant returns(uint256 start, uint256 two, uint256 three, uint256 end, uint256 goal, uint256 cap, uint256 badgecost, uint256 famount, address fwallet);

        event Purchase(uint256 indexed _exchange, uint256 indexed _rate, uint256 indexed _cents);
        event Claim(address indexed _user, uint256 indexed _amount, uint256 indexed _badges);

}

contract Badge {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowed;

        address public owner;
        bool public locked;
        string public name;                   //fancy name: eg Simon Bucks
        uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
        string public symbol;                 //An identifier: eg SBX
        string public version = &#39;H0.1&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.

        /// @return total amount of tokens
        uint256 public totalSupply;

        modifier ifOwner() {
                if (msg.sender != owner) {
                        throw;
                } else {
                        _;
                }
        }


        event Transfer(address indexed _from, address indexed _to, uint256 _value);
        event Mint(address indexed _recipient, uint256 indexed _amount);
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);

        function Badge(
                uint256 _initialAmount,
                string _tokenName,
                uint8 _decimalUnits,
                string _tokenSymbol
        ) {
                owner = msg.sender;
                balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
                totalSupply = _initialAmount;                        // Update total supply
                name = _tokenName;                                   // Set the name for display purposes
                decimals = _decimalUnits;                            // Amount of decimals for display purposes
                symbol = _tokenSymbol;                               // Set the symbol for display purposes

        }

        function safeToAdd(uint a, uint b) returns(bool) {
                return (a + b >= a);
        }

        function addSafely(uint a, uint b) returns(uint result) {
                if (!safeToAdd(a, b)) {
                        throw;
                } else {
                        result = a + b;
                        return result;
                }
        }

        function safeToSubtract(uint a, uint b) returns(bool) {
                return (b <= a);
        }

        function subtractSafely(uint a, uint b) returns(uint) {
                if (!safeToSubtract(a, b)) throw;
                return a - b;
        }

        function balanceOf(address _owner) constant returns(uint256 balance) {
                return balances[_owner];
        }

        function transfer(address _to, uint256 _value) returns(bool success) {
                if (balances[msg.sender] >= _value && _value > 0) {
                        balances[msg.sender] = subtractSafely(balances[msg.sender], _value);
                        balances[_to] = addSafely(_value, balances[_to]);
                        Transfer(msg.sender, _to, _value);
                        success = true;
                } else {
                        success = false;
                }
                return success;
        }

        function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
                if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
                        balances[_to] = addSafely(balances[_to], _value);
                        balances[_from] = subtractSafely(balances[_from], _value);
                        allowed[_from][msg.sender] = subtractSafely(allowed[_from][msg.sender], _value);
                        Transfer(_from, _to, _value);
                        return true;
                } else {
                        return false;
                }
        }

        function approve(address _spender, uint256 _value) returns(bool success) {
                allowed[msg.sender][_spender] = _value;
                Approval(msg.sender, _spender, _value);
                success = true;
                return success;
        }

        function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
                remaining = allowed[_owner][_spender];
                return remaining;
        }

        function mint(address _owner, uint256 _amount) ifOwner returns(bool success) {
                totalSupply = addSafely(totalSupply, _amount);
                balances[_owner] = addSafely(balances[_owner], _amount);
                Mint(_owner, _amount);
                return true;
        }

        function setOwner(address _owner) ifOwner returns(bool success) {
                owner = _owner;
                return true;
        }

}

contract Token {

        address public owner;
        address public config;
        bool public locked;
        address public dao;
        address public badgeLedger;
        uint256 public totalSupply;

        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowed;
        mapping(address => bool) seller;

        /// @return total amount of tokens

        modifier ifSales() {
                if (!seller[msg.sender]) throw;
                _;
        }

        modifier ifOwner() {
                if (msg.sender != owner) throw;
                _;
        }

        modifier ifDao() {
                if (msg.sender != dao) throw;
                _;
        }

        event Transfer(address indexed _from, address indexed _to, uint256 _value);
        event Mint(address indexed _recipient, uint256 _amount);
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);

        function Token(address _config) {
                config = _config;
                owner = msg.sender;
                address _initseller = ConfigInterface(_config).getConfigAddress("sale1:address");
                seller[_initseller] = true;
                locked = false;
        }

        function safeToAdd(uint a, uint b) returns(bool) {
                return (a + b >= a);
        }

        function addSafely(uint a, uint b) returns(uint result) {
                if (!safeToAdd(a, b)) {
                        throw;
                } else {
                        result = a + b;
                        return result;
                }
        }

        function safeToSubtract(uint a, uint b) returns(bool) {
                return (b <= a);
        }

        function subtractSafely(uint a, uint b) returns(uint) {
                if (!safeToSubtract(a, b)) throw;
                return a - b;
        }

        function balanceOf(address _owner) constant returns(uint256 balance) {
                return balances[_owner];
        }

        function transfer(address _to, uint256 _value) returns(bool success) {
                if (balances[msg.sender] >= _value && _value > 0) {
                        balances[msg.sender] = subtractSafely(balances[msg.sender], _value);
                        balances[_to] = addSafely(balances[_to], _value);
                        Transfer(msg.sender, _to, _value);
                        success = true;
                } else {
                        success = false;
                }
                return success;
        }

        function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
                if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
                        balances[_to] = addSafely(balances[_to], _value);
                        balances[_from] = subtractSafely(balances[_from], _value);
                        allowed[_from][msg.sender] = subtractSafely(allowed[_from][msg.sender], _value);
                        Transfer(_from, _to, _value);
                        return true;
                } else {
                        return false;
                }
        }

        function approve(address _spender, uint256 _value) returns(bool success) {
                allowed[msg.sender][_spender] = _value;
                Approval(msg.sender, _spender, _value);
                success = true;
                return success;
        }

        function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
                remaining = allowed[_owner][_spender];
                return remaining;
        }

        function mint(address _owner, uint256 _amount) ifSales returns(bool success) {
                totalSupply = addSafely(_amount, totalSupply);
                balances[_owner] = addSafely(balances[_owner], _amount);
                return true;
        }

        function mintBadge(address _owner, uint256 _amount) ifSales returns(bool success) {
                if (!Badge(badgeLedger).mint(_owner, _amount)) return false;
                return true;
        }

        function registerDao(address _dao) ifOwner returns(bool success) {
                if (locked == true) return false;
                dao = _dao;
                locked = true;
                return true;
        }

        function setDao(address _newdao) ifDao returns(bool success) {
                dao = _newdao;
                return true;
        }

        function isSeller(address _query) returns(bool isseller) {
                return seller[_query];
        }

        function registerSeller(address _tokensales) ifDao returns(bool success) {
                seller[_tokensales] = true;
                return true;
        }

        function unregisterSeller(address _tokensales) ifDao returns(bool success) {
                seller[_tokensales] = false;
                return true;
        }

        function setOwner(address _newowner) ifDao returns(bool success) {
                if (Badge(badgeLedger).setOwner(_newowner)) {
                        owner = _newowner;
                        success = true;
                } else {
                        success = false;
                }
                return success;
        }

}