pragma solidity 0.4.24;

/**
 * Overflow aware uint math functions.
 *
 * Inspired by https://github.com/MakerDAO/maker-otc/blob/master/contracts/simple_market.sol
 */

contract SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }


    // mitigate short address attack
    // thanks to https://github.com/numerai/contract/blob/c182465f82e50ced8dacb3977ec374a892f5fa8c/contracts/Safe.sol#L30-L34.
    // TODO: doublecheck implication of >= compared to ==
    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }
}

contract Token { // ERC20 standard
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token, SafeMath {

    uint256 public totalSupply;

    mapping (address => uint256) public index;
    mapping (uint256 => Info) public infos;
    mapping (address => mapping (address => uint256)) allowed;

    struct Info {
        uint256 tokenBalances;
        address holderAddress;
    }

    // TODO: update tests to expect throw
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2) returns (bool success) {
        require(_to != address(0));
        require(infos[index[msg.sender]].tokenBalances >= _value && _value > 0);
        infos[index[msg.sender]].tokenBalances = safeSub(infos[index[msg.sender]].tokenBalances, _value);
        infos[index[_to]].tokenBalances = safeAdd(infos[index[_to]].tokenBalances, _value);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    // TODO: update tests to expect throw
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3) returns (bool success) {
        require(_to != address(0));
        require(infos[index[_from]].tokenBalances >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        infos[index[_from]].tokenBalances = safeSub(infos[index[_from]].tokenBalances, _value);
        infos[index[_to]].tokenBalances = safeAdd(infos[index[_to]].tokenBalances, _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);

        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return infos[index[_owner]].tokenBalances;
    }

    //  To change the approve amount you first have to reduce the addresses&#39;
    //  allowance to zero by calling &#39;approve(_spender, 0)&#39; if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2) returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) public onlyPayloadSize(3) returns (bool success) {
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        emit Approval(msg.sender, _spender, _newValue);

        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract JCFv3 is StandardToken {

    // FIELDS

    string public name = "JCFv3";
    string public symbol = "JCFv3";
    uint256 public decimals = 18;
    string public version = "3.0";

    // uint256 public tokenCap = 1048575000000 * 10**18;
    // uint256 public yearOfJCF = now();
    uint256 public tokenCap = 1000000 * 10**18;

    // root control
    // control of liquidity and limited control of updatePrice
    address public controlWallet;
    address public teamAndDonationWallet;
    address public donationWallet;
    address public teamWallet;
    address public dividendWallet;

    // dividendWallet controlled state variables
    // halted: halt buying due to emergency, tradeable: signal that assets have been acquired
    bool public halted = false;
    bool public tradeable = false;

    // -- totalSupply defined in StandardToken
    // -- mapping to token balances done in StandardToken

    uint256 public minAmount = 0.05 ether;
    uint256 public totalHolder;
    uint256 public currentPortfolio;
	uint256 public currentCryptoNames;

    mapping (uint256 => uint256) public nav;

    // timestamp to index
    mapping (uint256 => uint256) indexOfPortfolio;

    // cryptoTypes to names
    mapping (uint256 => string) cryptoNames;

    // index to Portfolio
    mapping (uint256 => Portfolio) public portfolios;

    // map participant address to a withdrawal request
    mapping (address => Withdrawal) public withdrawals;

    // maps addresses
    mapping (address => bool) public whitelist;

    // TYPES
    struct Portfolio {
        mapping (uint256 => string) cryptoTypes;
        mapping (uint256 => uint256) amounts;
        mapping (uint256 => uint256) prices;
        uint256 timestamp; // time for each Portfolio recorded
    }

    struct Withdrawal {
        uint256 tokens;
        uint256 time; // time for each withdrawal is set to the previousUpdateTime
        // uint256 totalAmount;
    }

    // EVENTS

    event Whitelist(address indexed participant);
    event ReoveFromWhitelist(address indexed participant);
    event AddLiquidity(uint256 ethAmount);
    event RemoveLiquidity(uint256 ethAmount);
    event WithdrawRequest(address indexed participant, uint256 amountTokens, uint256 requestTime);
    event Withdraw(address indexed participant, uint256 amountTokens, uint256 etherAmount);
    event Burn(address indexed burner, uint256 value);

    // MODIFIERS

    modifier isTradeable {
        require(tradeable || msg.sender == dividendWallet);
        _;
    }

    modifier onlyWhitelist {
        require(whitelist[msg.sender]);
        _;
    }

    modifier onlyDividendWallet {
        require(msg.sender == dividendWallet);
        _;
    }

    modifier onlyManagingWallets {
        require(msg.sender == controlWallet || msg.sender == dividendWallet);
        _;
    }

    modifier only_if_controlWallet {
        if (msg.sender == controlWallet) {
            _;
        }
    }

    modifier only_if_increase (uint256 _newYear) {
        require(nav[_newYear] > 0);
        if (nav[_newYear] > nav[(_newYear - 1)]) {
            _;
        }
    }

    modifier check_token_cap (uint256 _amount) {
        require(_amount > 0);
        require(safeAdd(safeAdd(safeDiv(_amount, 9), _amount), totalSupply) <= tokenCap);
        _;
    }

    constructor (address _dividendWallet, address _teamAndDonationWallet) public {
        controlWallet = msg.sender;
        // 0xb066b3806581dbe9aa5a114707c71c391cd2bc4f
        dividendWallet = _dividendWallet;
        // 0x0e00fd74e2af25d6bab5aab65b99cc5101a10747
        teamAndDonationWallet = _teamAndDonationWallet;
        // 0xb066b3806581dbe9aa5a114707c71c391cd2bc4f

        index[controlWallet] = 0;
        index[dividendWallet] = 1;
        index[teamAndDonationWallet] = 2;

        infos[index[controlWallet]].tokenBalances = 0;
        infos[index[dividendWallet]].tokenBalances = 0;
        infos[index[teamAndDonationWallet]].tokenBalances = 0;

        infos[index[controlWallet]].holderAddress = controlWallet;
        infos[index[dividendWallet]].holderAddress = dividendWallet;
        infos[index[teamAndDonationWallet]].holderAddress = teamAndDonationWallet;

        totalSupply = 0;
        currentPortfolio = 0;
		currentCryptoNames = 0;

        whitelist[dividendWallet] = true;
        whitelist[teamAndDonationWallet] = true;

        totalHolder = 2;
    }

    function verifyParticipant(address participant) external onlyManagingWallets {
        whitelist[participant] = true;
        emit Whitelist(participant);
    }

    function removeParticipant(address participant) external onlyManagingWallets {
        whitelist[participant] = false;
        emit ReoveFromWhitelist(participant);
    }

    function withdraw_to(address participant, uint256 withdrawValue, uint256 amountTokensToWithdraw, uint256 requestTime) public only_if_controlWallet {
        require(amountTokensToWithdraw > 0);
        require(withdrawValue > 0);
        require(balanceOf(participant) >= amountTokensToWithdraw);
        require(withdrawals[participant].tokens == 0);

        infos[index[participant]].tokenBalances = safeSub(infos[index[participant]].tokenBalances, amountTokensToWithdraw);

        withdrawals[participant] = Withdrawal({tokens: amountTokensToWithdraw, time: requestTime});

        emit WithdrawRequest(participant, amountTokensToWithdraw, requestTime);

        if (address(this).balance >= withdrawValue) {
            enact_withdrawal_greater_equal(participant, withdrawValue, amountTokensToWithdraw);
        } else {
            enact_withdrawal_less(participant, withdrawValue, amountTokensToWithdraw);
        }
    }

    function enact_withdrawal_greater_equal(address participant, uint256 withdrawValue, uint256 tokens) private {
        assert(address(this).balance >= withdrawValue);
        infos[index[controlWallet]].tokenBalances = safeAdd(infos[index[controlWallet]].tokenBalances, tokens);

        participant.transfer(withdrawValue);
        withdrawals[participant].tokens = 0;
        updateTotalSupply();
        emit Withdraw(participant, tokens, withdrawValue);
    }

    function enact_withdrawal_less(address participant, uint256 withdrawValue, uint256 tokens) private {
        assert(address(this).balance < withdrawValue);
        infos[index[participant]].tokenBalances = safeAdd(infos[index[participant]].tokenBalances, tokens);

        withdrawals[participant].tokens = 0;
        updateTotalSupply();
        emit Withdraw(participant, tokens, 0); // indicate a failed withdrawal
    }

    function addLiquidity() external onlyManagingWallets payable {
        require(msg.value > 0);
        emit AddLiquidity(msg.value);
    }

    function removeLiquidity(uint256 amount) external onlyManagingWallets {
        require(amount <= address(this).balance);
        dividendWallet.transfer(amount);
        emit RemoveLiquidity(amount);
    }

    function changeDividendWallet(address _newDividendWallet) external onlyDividendWallet {
        require(_newDividendWallet != address(0));
        dividendWallet = _newDividendWallet;
    }

    function changeControlWallet(address _newControlWallet) external only_if_controlWallet {
        require(_newControlWallet != address(0));
        controlWallet = _newControlWallet;
    }

    function halt() external only_if_controlWallet {
        halted = true;
    }

    function unhalt() external only_if_controlWallet {
        halted = false;
    }

    function enableTrading() external only_if_controlWallet {
        // require(block.number > fundingEndBlock);
        tradeable = true;
    }

    function disableTrading() external only_if_controlWallet {
        // require(block.number > fundingEndBlock);
        tradeable = false;
    }

    function claimTokens(address _token) external only_if_controlWallet {
        require(_token != address(0));
        Token token = Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(controlWallet, balance);
        updateTotalSupply();
    }

    function allocateTokens(address _participant, uint256 _amountTokens) external check_token_cap(_amountTokens) only_if_controlWallet {
        uint256 teamAndDonationAllocation = safeDiv(_amountTokens, 9);
        uint256 newTokens = safeAdd(_amountTokens, teamAndDonationAllocation);
        totalSupply = safeAdd(totalSupply, newTokens);
        if (index[_participant] > 0) {
            // do nothing
        } else {
            // store token holder infos
            totalHolder = safeAdd(totalHolder, 1);
            index[_participant] = totalHolder;
            infos[index[_participant]].holderAddress = _participant;
        }
        infos[index[_participant]].tokenBalances = safeAdd(infos[index[_participant]].tokenBalances, _amountTokens);
        infos[index[teamAndDonationWallet]].tokenBalances = safeAdd(infos[index[teamAndDonationWallet]].tokenBalances, teamAndDonationAllocation);
        emit Transfer(address(0), _participant, _amountTokens);
        emit Transfer(address(0), teamAndDonationWallet, teamAndDonationAllocation);
    }

    function transfer(address _to, uint256 _value) public isTradeable returns (bool success) {
        if (index[_to] > 0) {
            // do nothing
        } else {
            // store token holder infos
            totalHolder = safeAdd(totalHolder, 1);
            index[_to] = totalHolder;
            infos[index[_to]].holderAddress = _to;
        }

        updateTotalSupply();
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public isTradeable returns (bool success) {
        if (index[_to] > 0) {
            // do nothing
        } else {
            // store token holder infos
            totalHolder = safeAdd(totalHolder, 1);
            index[_to] = totalHolder;
            infos[index[_to]].holderAddress = _to;
        }

        updateTotalSupply();
        return super.transferFrom(_from, _to, _value);
    }

    function burn(address _who, uint256 _value) external only_if_controlWallet {
        require(_value <= infos[index[_who]].tokenBalances);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
        infos[index[_who]].tokenBalances = safeSub(infos[index[_who]].tokenBalances, _value);

        tokenCap = safeSub(tokenCap, _value);
        updateTotalSupply();
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function updateTotalSupply() private {
        totalSupply = safeSub(tokenCap, infos[index[controlWallet]].tokenBalances);
    }

	function storeCryptoNames(string _crypto) external only_if_controlWallet {
		currentCryptoNames = safeAdd(currentCryptoNames, 1);
		cryptoNames[currentCryptoNames] = _crypto;
	}

    function storePortfolio(uint256 _timestamp, uint256[] _cryptoTypes, uint256[] _amounts, uint256[] _prices) external only_if_controlWallet {
        currentPortfolio = safeAdd(currentPortfolio, 1);
        uint256 i = 0;
        while (i < _cryptoTypes.length && i < _amounts.length && i < _prices.length) {
            require(currentCryptoNames > _cryptoTypes[i]);
            portfolios[currentPortfolio].cryptoTypes[i] = cryptoNames[_cryptoTypes[i]];
            portfolios[currentPortfolio].amounts[i] = _amounts[i];
            portfolios[currentPortfolio].prices[i] = _prices[i];
            i++;
        }
        portfolios[currentPortfolio].timestamp = _timestamp;
    }

    /*function distributeDividends(uint256 _year) external only_if_increase(_year) {

    }*/
}