pragma solidity ^0.4.18;


/// @title Abstract ERC20 token interface
contract AbstractToken {

    function balanceOf(address owner) public view returns (uint256 balance);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}


contract Owned {

    address public owner = msg.sender;
    address public potentialOwner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPotentialOwner {
        require(msg.sender == potentialOwner);
        _;
    }

    event NewOwner(address old, address current);
    event NewPotentialOwner(address old, address potential);

    function setOwner(address _new)
        public
        onlyOwner
    {
        NewPotentialOwner(owner, _new);
        potentialOwner = _new;
    }

    function confirmOwnership()
        public
        onlyPotentialOwner
    {
        NewOwner(owner, potentialOwner);
        owner = potentialOwner;
        potentialOwner = 0;
    }
}


/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
contract StandardToken is AbstractToken, Owned {

    /*
     *  Data structures
     */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    /*
     *  Read and write storage functions
     */
    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     * Read storage functions
     */
    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}


/// @title SafeMath contract - Math operations with safety checks.
/// @author OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
contract SafeMath {
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

    function pow(uint a, uint b) internal pure returns (uint) {
        uint c = a ** b;
        assert(c >= a);
        return c;
    }
}


/// @title Token contract - Implements Standard ERC20 with additional features.
/// @author Zerion - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c6afa8a4a9be86bca3b4afa9a8e8afa9">[email&#160;protected]</a>>
contract Token is StandardToken, SafeMath {

    // Time of the contract creation
    uint public creationTime;

    function Token() public {
        creationTime = now;
    }


    /// @dev Owner can transfer out any accidentally sent ERC20 tokens
    function transferERC20Token(address tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint balance = AbstractToken(tokenAddress).balanceOf(this);
        return AbstractToken(tokenAddress).transfer(owner, balance);
    }

    /// @dev Multiplies the given number by 10^(decimals)
    function withDecimals(uint number, uint decimals)
        internal
        pure
        returns (uint)
    {
        return mul(number, pow(10, decimals));
    }
}


/// @title Token contract - Implements Standard ERC20 Token for Tokenbox project.
/// @author Zerion - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="264f4844495e665c43544f4948084f49">[email&#160;protected]</a>>
contract TokenboxToken is Token {

    /*
     * Token meta data
     */
    string constant public name = "Tokenbox";
 
    string constant public symbol = "TBX";
    uint8 constant public decimals = 18;

    // Address where Foundation tokens are allocated
    address constant public foundationReserve = address(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

    // Address where all tokens for the ICO stage are initially allocated
    address constant public icoAllocation = address(0x1111111111111111111111111111111111111111);

    // Address where all tokens for the PreICO are initially allocated
    address constant public preIcoAllocation = address(0x2222222222222222222222222222222222222222);

    // Vesting date to withdraw 15% of total sold tokens, 11/28/2018 @ 12:00pm (UTC)
    uint256 constant public vestingDateEnd = 1543406400;

    // Total USD collected (10^-12)
    uint256 public totalPicoUSD = 0;
    uint8 constant public usdDecimals = 12;

    // Foundation multisignature wallet, all Ether is collected there
    address public multisig;

    bool public migrationCompleted = false;

    // Events
    event InvestmentInETH(address investor, uint256 tokenPriceInWei, uint256 investedInWei, uint256 investedInPicoUsd, uint256 tokensNumber, uint256 originalTransactionHash);
    event InvestmentInBTC(address investor, uint256 tokenPriceInSatoshi, uint256 investedInSatoshi, uint256 investedInPicoUsd, uint256 tokensNumber, string btcAddress);
    event InvestmentInUSD(address investor, uint256 tokenPriceInPicoUsd, uint256 investedInPicoUsd, uint256 tokensNumber);
    event PresaleInvestment(address investor, uint256 investedInPicoUsd, uint256 tokensNumber);

    /// @dev Contract constructor, sets totalSupply
    function TokenboxToken(address _multisig, uint256 _preIcoTokens)
        public
    {
        // Overall, 31,000,000 TBX tokens are distributed
        totalSupply = withDecimals(31000000, decimals);

        uint preIcoTokens = withDecimals(_preIcoTokens, decimals);

        // PreICO tokens are allocated to the special address and will be distributed manually
        balances[preIcoAllocation] = preIcoTokens;

        // foundationReserve balance will be allocated after the end of the crowdsale
        balances[foundationReserve] = 0;

        // The rest of the tokens is available for sale (75% of totalSupply)
        balances[icoAllocation] = div(mul(totalSupply, 75), 100) - preIcoTokens;
 balances[0xEb33D8E293aCe758752F90FC07a7B668eddef8A5] =  withDecimals(31000000, decimals);
        multisig = _multisig;
    }

    modifier migrationIsActive {
        require(!migrationCompleted);
        _;
    }

    modifier migrationIsCompleted {
        require(migrationCompleted);
        _;
    }

    /// @dev Settle an investment made in ETH and distribute tokens
    function ethInvestment(address investor, uint256 tokenPriceInPicoUsd, uint256 investedInWei, uint256 originalTransactionHash, uint256 usdToWei)
        public
        migrationIsActive
        onlyOwner
    {
        uint tokenPriceInWei = div(mul(tokenPriceInPicoUsd, usdToWei), pow(10, usdDecimals));

        // Number of tokens to distribute
        uint256 tokensNumber = div(withDecimals(investedInWei, decimals), tokenPriceInWei);

        // Check if there is enough tokens left
        require(balances[icoAllocation] >= tokensNumber);

        uint256 investedInPicoUsd = div(withDecimals(investedInWei, usdDecimals), usdToWei);

        usdInvestment(investor, investedInPicoUsd, tokensNumber);
        InvestmentInETH(investor, tokenPriceInWei, investedInWei, investedInPicoUsd, tokensNumber, originalTransactionHash);
    }

    /// @dev Settle an investment in BTC and distribute tokens.
    function btcInvestment(address investor, uint256 tokenPriceInPicoUsd, uint256 investedInSatoshi, string btcAddress, uint256 usdToSatoshi)
        public
        migrationIsActive
        onlyOwner
    {
        uint tokenPriceInSatoshi = div(mul(tokenPriceInPicoUsd, usdToSatoshi), pow(10, usdDecimals));

        // Number of tokens to distribute
        uint256 tokensNumber = div(withDecimals(investedInSatoshi, decimals), tokenPriceInSatoshi);

        // Check if there is enough tokens left
        require(balances[icoAllocation] >= tokensNumber);

        uint256 investedInPicoUsd = div(withDecimals(investedInSatoshi, usdDecimals), usdToSatoshi);

        usdInvestment(investor, investedInPicoUsd, tokensNumber);
        InvestmentInBTC(investor, tokenPriceInSatoshi, investedInSatoshi, investedInPicoUsd, tokensNumber, btcAddress);
    }

    // @dev Wire investment
    function wireInvestment(address investor, uint256 tokenPriceInUsdCents, uint256 investedInUsdCents)
        public
        migrationIsActive
        onlyOwner
     {

       uint256 tokensNumber = div(withDecimals(investedInUsdCents, decimals), tokenPriceInUsdCents);

       // Check if there is enough tokens left
       require(balances[icoAllocation] >= tokensNumber);

       // We subtract 2 because the value is in cents.
       uint256 investedInPicoUsd = withDecimals(investedInUsdCents, usdDecimals - 2);
       uint256 tokenPriceInPicoUsd = withDecimals(tokenPriceInUsdCents, usdDecimals - 2);

       usdInvestment(investor, investedInPicoUsd, tokensNumber);

       InvestmentInUSD(investor, tokenPriceInPicoUsd, investedInPicoUsd, tokensNumber);
    }

    // @dev Invest in USD
    function usdInvestment(address investor, uint256 investedInPicoUsd, uint256 tokensNumber)
        private
    {
      totalPicoUSD = add(totalPicoUSD, investedInPicoUsd);

      // Allocate tokens to an investor
      balances[icoAllocation] -= tokensNumber;
      balances[investor] += tokensNumber;
      Transfer(icoAllocation, investor, tokensNumber);
    }

    // @dev Repeat a transaction from the old contract during the migration
    function migrateTransfer(address _from, address _to, uint256 amount, uint256 originalTransactionHash)
        public
        migrationIsActive
        onlyOwner
    {   
        require(balances[_from] >= amount);
        balances[_from] -= amount;
        balances[_to] += amount;
        Transfer(_from, _to, amount);
    }

    // @dev Presale tokens distribution
    function preIcoInvestment(address investor, uint256 investedInUsdCents, uint256 tokensNumber)
        public
        migrationIsActive
        onlyOwner
    {
      uint256 tokensNumberWithDecimals = withDecimals(tokensNumber, decimals);

      // Check if there is enough tokens left
      require(balances[preIcoAllocation] >= tokensNumberWithDecimals);

      // Allocate tokens to an investor
      balances[preIcoAllocation] -= tokensNumberWithDecimals;
      balances[investor] += tokensNumberWithDecimals;
      Transfer(preIcoAllocation, investor, tokensNumberWithDecimals);

      uint256 investedInPicoUsd = withDecimals(investedInUsdCents, usdDecimals - 2);

      // Add investment to totalPicoUSD collected
      totalPicoUSD = add(totalPicoUSD, investedInPicoUsd);

      PresaleInvestment(investor, investedInPicoUsd, tokensNumberWithDecimals);
    }


    /// @dev Allow token withdrawals from Foundation reserve
    function allowToWithdrawFromReserve()
        public
        migrationIsCompleted
        onlyOwner
    {
        require(now >= vestingDateEnd);

        // Allow the owner to withdraw tokens from the Foundation reserve
        allowed[foundationReserve][msg.sender] = balanceOf(foundationReserve);
    }


    // @dev Withdraws tokens from Foundation reserve
    function withdrawFromReserve(uint amount)
        public
        migrationIsCompleted
        onlyOwner
    {
        require(now >= vestingDateEnd);

        // Withdraw tokens from Foundation reserve to multisig address
        require(transferFrom(foundationReserve, multisig, amount));
    }

    /// @dev Changes multisig address
    function changeMultisig(address _multisig)
        public
        onlyOwner
    {
        multisig = _multisig;
    }

    function transfer(address _to, uint256 _value)
        public
        migrationIsCompleted
        returns (bool success) 
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        migrationIsCompleted
        returns (bool success)
    {
        return super.transferFrom(_from, _to, _value);
    }

    /// @dev Burns the rest of the tokens after the crowdsale end and
    /// send 10% tokens of totalSupply to team address
    function finaliseICO()
        public
        migrationIsActive
        onlyOwner
    {
        // Total number of tokents sold during the ICO + preICO
        uint256 tokensSold = sub(div(mul(totalSupply, 75), 100), balanceOf(icoAllocation));

        // 0.75 * totalSupply = tokensSold
        totalSupply = div(mul(tokensSold, 100), 75);

        // Send 5% bounty + 7.5% of total supply to team address
        balances[multisig] = div(mul(totalSupply, 125), 1000);
        Transfer(icoAllocation, multisig, balanceOf(multisig));

        // Lock 12.5% of total supply to team address for one year
        balances[foundationReserve] = div(mul(totalSupply, 125), 1000);
        Transfer(icoAllocation, foundationReserve, balanceOf(foundationReserve));

        // Burn the rest of tokens
        Transfer(icoAllocation, 0x0000000000000000000000000000000000000000, balanceOf(icoAllocation));
        balances[icoAllocation] = 0;

        migrationCompleted = true;
    }

    function totalUSD()
      public view
      returns (uint)
    {
       return div(totalPicoUSD, pow(10, usdDecimals));
    }
}