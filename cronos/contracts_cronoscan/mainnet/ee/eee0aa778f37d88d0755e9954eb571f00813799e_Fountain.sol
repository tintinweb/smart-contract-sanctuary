/**
 *Submitted for verification at cronoscan.com on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

// File: openzeppelin-solidity/contracts/ownership/Whitelist.sol

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'no whitelist');
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     */
    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
        return success;
    }

    /**
     * @dev remove an address from the whitelist
     * @param addr address
     */
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
        return success;
    }

    /**
     * @dev remove addresses from the whitelist
     * @param addrs addresses
     */
    function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
        return success;
    }

}

/**
 * @title Standard BEP20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract BEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 internal _totalSupply;

    /**
      * @dev Total number of tokens in existence
      */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
      * @dev Gets the balance of the specified address.
      * @param owner The address to query the balance of.
      * @return A uint256 representing the amount owned by the passed address.
      */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
      * @dev Function to check the amount of tokens that an owner allowed to a spender.
      * @param owner address The address which owns the funds.
      * @param spender address The address which will spend the funds.
      * @return A uint256 specifying the amount of tokens still available for the spender.
      */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
      * @dev Transfer token to a specified address
      * @param to The address to transfer to.
      * @param value The amount to be transferred.
      */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
      * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
      * Beware that changing an allowance with this method brings the risk that someone may use both the old
      * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
      * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
      * @param spender The address which will spend the funds.
      * @param value The amount of tokens to be spent.
      */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
      * @dev Transfer tokens from one address to another.
      * Note that while this function emits an Approval event, this is not required as per the specification,
      * and other compliant implementations may not emit the event.
      * @param from address The address which you want to send tokens from
      * @param to address The address which you want to transfer to
      * @param value uint256 the amount of tokens to be transferred
      */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
      * @dev Increase the amount of tokens that an owner allowed to a spender.
      * approve should be called when _allowed[msg.sender][spender] == 0. To increment
      * allowed value is better to use this function to avoid 2 calls (and wait until
      * the first transaction is mined)
      * Emits an Approval event.
      * @param spender The address which will spend the funds.
      * @param addedValue The amount of tokens to increase the allowance by.
      */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
      * @dev Decrease the amount of tokens that an owner allowed to a spender.
      * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
      * allowed value is better to use this function to avoid 2 calls (and wait until
      * the first transaction is mined)
      * Emits an Approval event.
      * @param spender The address which will spend the funds.
      * @param subtractedValue The amount of tokens to decrease the allowance by.
      */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
      * @dev Transfer token for a specified addresses
      * @param from The address to transfer from.
      * @param to The address to transfer to.
      * @param value The amount to be transferred.
      */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
      * @dev Internal function that mints an amount of the token and assigns it to
      * an account. This encapsulates the modification of balances such that the
      * proper events are emitted.
      * @param account The account that will receive the created tokens.
      * @param value The amount that will be created.
      */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
      * @dev Internal function that burns an amount of the token of a given
      * account.
      * @param account The account whose tokens will be burnt.
      * @param value The amount that will be burnt.
      */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
      * @dev Approve an address to spend another addresses' tokens.
      * @param owner The address that owns the tokens.
      * @param spender The address that will spend the tokens.
      * @param value The number of tokens that can be spent.
      */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
      * @dev Internal function that burns an amount of the token of a given
      * account, deducting from the sender's allowance for said account. Uses the
      * internal burn function.
      * Emits an Approval event (reflecting the reduced allowance).
      * @param account The account whose tokens will be burnt.
      * @param value The amount that will be burnt.
      */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /* @dev Subtracts two numbers, else returns zero */
    function safeSub(uint a, uint b) internal pure returns (uint) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IToken {
    function calculateTransferTaxes(address _from, uint256 _value) external view returns (uint256 adjustedValue, uint256 taxAmount);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function burn(uint256 _value) external;
}

contract Fountain is BEP20, Whitelist {

    string public constant name = "GemWing Liquidity Token";
    string public constant symbol = "GEM";
    uint8 public constant decimals = 18;

    /***********************************|
    |        Variables && Events        |
    |__________________________________*/

    // Variables
    IToken internal token; // address of the BEP20 token traded on this contract
    uint256 public totalTxs;

    uint256 internal lastBalance_;
    uint256 internal trackingInterval_ = 1 minutes;
    uint256 public providers;

    mapping (address => bool) internal _providers;
    mapping (address => uint256) internal _txs;

    bool public isPaused = true;

    // Events
    event onTokenPurchase(address indexed buyer, uint256 indexed CRO_amount, uint256 indexed token_amount);
    event onCROPurchase(address indexed buyer, uint256 indexed token_amount, uint256 indexed CRO_amount);
    event onAddLiquidity(address indexed provider, uint256 indexed CRO_amount, uint256 indexed token_amount);
    event onRemoveLiquidity(address indexed provider, uint256 indexed CRO_amount, uint256 indexed token_amount);
    event onLiquidity(address indexed provider, uint256 indexed amount);
    event onContractBalance(uint256 balance);
    event onPrice(uint256 price);
    event onSummary(uint256 liquidity, uint256 price);


    /***********************************|
    |            Constructor            |
    |__________________________________*/
    constructor (address token_addr) Ownable() public {
        token = IToken(token_addr);
        lastBalance_= now;
    }

    function unpause() public onlyOwner {
        isPaused = false;
    }

    function pause() public onlyOwner {
        isPaused = true;
    }

    modifier isNotPaused() {
        require(!isPaused, "Swaps currently paused");
        _;
    }


    /***********************************|
    |        Exchange Functions         |
    |__________________________________*/


    /**
     * @notice Convert CRO to Tokens.
     * @dev User specifies exact input (msg.value).
     */
    receive() external payable {
        CROToTokenInput(msg.value, 1, msg.sender, msg.sender);
    }

    /**
      * @dev Pricing function for converting between CRO && Tokens.
      * @param input_amount Amount of CRO or Tokens being sold.
      * @param input_reserve Amount of CRO or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of CRO or Tokens (output type) in exchange reserves.
      * @return Amount of CRO or Tokens bought.
      */
    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve)  public view returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0, "INVALID_VALUE");
        uint256 input_amount_with_fee = input_amount.mul(990);
        uint256 numerator = input_amount_with_fee.mul(output_reserve);
        uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
        return numerator / denominator;
    }

    /**
      * @dev Pricing function for converting between CRO && Tokens.
      * @param output_amount Amount of CRO or Tokens being bought.
      * @param input_reserve Amount of CRO or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of CRO or Tokens (output type) in exchange reserves.
      * @return Amount of CRO or Tokens sold.
      */
    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve)  public view returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0);
        uint256 numerator = input_reserve.mul(output_amount).mul(1000);
        uint256 denominator = (output_reserve.sub(output_amount)).mul(990);
        return (numerator / denominator).add(1);
    }

    function CROToTokenInput(uint256 CRO_sold, uint256 min_tokens, address buyer, address recipient) private returns (uint256) {
        require(CRO_sold > 0 && min_tokens > 0, "sold and min 0");

        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_bought = getInputPrice(CRO_sold, address(this).balance.sub(CRO_sold), token_reserve);

        require(tokens_bought >= min_tokens, "tokens_bought >= min_tokens");
        require(token.transfer(recipient, tokens_bought), "transfer err");

        emit onTokenPurchase(buyer, CRO_sold, tokens_bought);
        emit onContractBalance(CROBalance());

        trackGlobalStats();

        return tokens_bought;
    }

    /**
     * @notice Convert CRO to Tokens.
     * @dev User specifies exact input (msg.value) && minimum output.
     * @param min_tokens Minimum Tokens bought.
     * @return Amount of Tokens bought.
     */
    function CROToTokenSwapInput(uint256 min_tokens) public payable isNotPaused returns (uint256) {
        return CROToTokenInput(msg.value, min_tokens,msg.sender, msg.sender);
    }

    function CROToTokenOutput(uint256 tokens_bought, uint256 max_CRO, address buyer, address recipient) private returns (uint256) {
        require(tokens_bought > 0 && max_CRO > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 CRO_sold = getOutputPrice(tokens_bought, address(this).balance.sub(max_CRO), token_reserve);
        // Throws if CRO_sold > max_CRO
        uint256 CRO_refund = max_CRO.sub(CRO_sold);
        if (CRO_refund > 0) {
            payable(buyer).transfer(CRO_refund);
        }
        require(token.transfer(recipient, tokens_bought));
        emit onTokenPurchase(buyer, CRO_sold, tokens_bought);
        trackGlobalStats();
        return CRO_sold;
    }

    /**
     * @notice Convert CRO to Tokens.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @return Amount of CRO sold.
     */
    function CROToTokenSwapOutput(uint256 tokens_bought) public payable isNotPaused returns (uint256) {
        return CROToTokenOutput(tokens_bought, msg.value, msg.sender, msg.sender);
    }

    function tokenToCROInput(uint256 tokens_sold, uint256 min_CRO, address buyer, address recipient) private returns (uint256) {
        require(tokens_sold > 0 && min_CRO > 0);
        uint256 token_reserve = token.balanceOf(address(this));

        (uint256 realized_sold, uint256 taxAmount) = token.calculateTransferTaxes(buyer, tokens_sold);

        uint256 CRO_bought = getInputPrice(realized_sold, token_reserve, address(this).balance);
        require(CRO_bought >= min_CRO);
        payable(recipient).transfer(CRO_bought);
        require(token.transferFrom(buyer, address(this), tokens_sold));
        emit onCROPurchase(buyer, tokens_sold, CRO_bought);
        trackGlobalStats();
        return CRO_bought;
    }

    /**
     * @notice Convert Tokens to CRO.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_CRO Minimum CRO purchased.
     * @return Amount of CRO bought.
     */
    function tokenToCROSwapInput(uint256 tokens_sold, uint256 min_CRO) public isNotPaused returns (uint256) {
        return tokenToCROInput(tokens_sold, min_CRO, msg.sender, msg.sender);
    }

    function tokenToCROOutput(uint256 CRO_bought, uint256 max_tokens, address buyer, address recipient) private returns (uint256) {
        require(CRO_bought > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_sold = getOutputPrice(CRO_bought, token_reserve, address(this).balance);

        (uint256 realized_sold, uint256 taxAmount) = token.calculateTransferTaxes(buyer, tokens_sold);
        tokens_sold += taxAmount;

        // tokens sold is always > 0
        require(max_tokens >= tokens_sold, 'max tokens exceeded');
        payable(recipient).transfer(CRO_bought);
        require(token.transferFrom(buyer, address(this), tokens_sold));
        emit onCROPurchase(buyer, tokens_sold, CRO_bought);
        trackGlobalStats();

        return tokens_sold;
    }

    /**
     * @notice Convert Tokens to CRO.
     * @dev User specifies maximum input && exact output.
     * @param CRO_bought Amount of CRO purchased.
     * @param max_tokens Maximum Tokens sold.
     * @return Amount of Tokens sold.
     */
    function tokenToCROSwapOutput(uint256 CRO_bought, uint256 max_tokens) public isNotPaused returns (uint256) {
        return tokenToCROOutput(CRO_bought, max_tokens, msg.sender, msg.sender);
    }

    function trackGlobalStats() private {

        uint256 price = getCROToTokenOutputPrice(1e18);
        uint256 balance = CROBalance();

        if (now.safeSub(lastBalance_) > trackingInterval_) {

            emit onSummary(balance * 2, price);
            lastBalance_ = now;
        }

        emit onContractBalance(balance);
        emit onPrice(price);

        totalTxs += 1;
        _txs[msg.sender] += 1;
    }


    /***********************************|
    |         Getter Functions          |
    |__________________________________*/

    /**
     * @notice Public price function for CRO to Token trades with an exact input.
     * @param CRO_sold Amount of CRO sold.
     * @return Amount of Tokens that can be bought with input CRO.
     */
    function getCROToTokenInputPrice(uint256 CRO_sold) public view returns (uint256) {
        require(CRO_sold > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        return getInputPrice(CRO_sold, address(this).balance, token_reserve);
    }

    /**
     * @notice Public price function for CRO to Token trades with an exact output.
     * @param tokens_bought Amount of Tokens bought.
     * @return Amount of CRO needed to buy output Tokens.
     */
    function getCROToTokenOutputPrice(uint256 tokens_bought) public view returns (uint256) {
        require(tokens_bought > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 CRO_sold = getOutputPrice(tokens_bought, address(this).balance, token_reserve);
        return CRO_sold;
    }

    /**
     * @notice Public price function for Token to CRO trades with an exact input.
     * @param tokens_sold Amount of Tokens sold.
     * @return Amount of CRO that can be bought with input Tokens.
     */
    function getTokenToCROInputPrice(uint256 tokens_sold) public view returns (uint256) {
        require(tokens_sold > 0, "token sold < 0");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 CRO_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
        return CRO_bought;
    }

    /**
     * @notice Public price function for Token to CRO trades with an exact output.
     * @param CRO_bought Amount of output CRO.
     * @return Amount of Tokens needed to buy output CRO.
     */
    function getTokenToCROOutputPrice(uint256 CRO_bought) public view returns (uint256) {
        require(CRO_bought > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        return getOutputPrice(CRO_bought, token_reserve, address(this).balance);
    }

    /**
     * @return Address of Token that is sold on this exchange.
     */
    function tokenAddress() public view returns (address) {
        return address(token);
    }

    function CROBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function tokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getCROToLiquidityInputPrice(uint256 CRO_sold) public view returns (uint256){
        require(CRO_sold > 0);
        uint256 token_amount = 0;
        uint256 total_liquidity = _totalSupply;
        uint256 CRO_reserve = address(this).balance;
        uint256 token_reserve = token.balanceOf(address(this));
        token_amount = (CRO_sold.mul(token_reserve) / CRO_reserve).add(1);
        uint256 liquidity_minted = CRO_sold.mul(total_liquidity) / CRO_reserve;

        return liquidity_minted;
    }

    function getLiquidityToReserveInputPrice(uint amount) public view returns (uint256, uint256){
        uint256 total_liquidity = _totalSupply;
        require(total_liquidity > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 CRO_amount = amount.mul(address(this).balance) / total_liquidity;
        uint256 token_amount = amount.mul(token_reserve) / total_liquidity;
        return (CRO_amount, token_amount);
    }

    function txs(address owner) public view returns (uint256) {
        return _txs[owner];
    }

    /***********************************|
    |        Liquidity Functions        |
    |__________________________________*/

    /**
     * @notice Deposit CRO && Tokens (token) at current ratio to mint SWAP tokens.
     * @dev min_liquidity does nothing when total SWAP supply is 0.
     * @param min_liquidity Minimum number of GEMS sender will mint if total GEM supply is greater than 0.
     * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total GEM supply is 0.
     * @return The amount of SWAP minted.
     */
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens) isNotPaused public payable returns (uint256) {
        require(max_tokens > 0 && msg.value > 0, 'Swap#addLiquidity: INVALID_ARGUMENT');
        uint256 total_liquidity = _totalSupply;

        uint256 token_amount = 0;

        if (_providers[msg.sender] == false){
            _providers[msg.sender] = true;
            providers += 1;
        }

        if (total_liquidity > 0) {
            require(min_liquidity > 0);
            uint256 CRO_reserve = address(this).balance.sub(msg.value);
            uint256 token_reserve = token.balanceOf(address(this));
            token_amount = (msg.value.mul(token_reserve) / CRO_reserve).add(1);
            uint256 liquidity_minted = msg.value.mul(total_liquidity) / CRO_reserve;

            require(max_tokens >= token_amount && liquidity_minted >= min_liquidity);
            _balances[msg.sender] = _balances[msg.sender].add(liquidity_minted);
            _totalSupply = total_liquidity.add(liquidity_minted);
            require(token.transferFrom(msg.sender, address(this), token_amount));

            emit onAddLiquidity(msg.sender, msg.value, token_amount);
            emit onLiquidity(msg.sender, _balances[msg.sender]);
            emit Transfer(address(0), msg.sender, liquidity_minted);
            return liquidity_minted;

        } else {
            require(msg.value >= 1e18, "INVALID_VALUE");
            token_amount = max_tokens;
            uint256 initial_liquidity = address(this).balance;
            _totalSupply = initial_liquidity;
            _balances[msg.sender] = initial_liquidity;
            require(token.transferFrom(msg.sender, address(this), token_amount));

            emit onAddLiquidity(msg.sender, msg.value, token_amount);
            emit onLiquidity(msg.sender, _balances[msg.sender]);
            emit Transfer(address(0), msg.sender, initial_liquidity);
            return initial_liquidity;
        }
    }

    /**
     * @dev Burn SWAP tokens to withdraw CRO && Tokens at current ratio.
     * @param amount Amount of SWAP burned.
     * @param min_CRO Minimum CRO withdrawn.
     * @param min_tokens Minimum Tokens withdrawn.
     * @return The amount of CRO && Tokens withdrawn.
     */
    function removeLiquidity(uint256 amount, uint256 min_CRO, uint256 min_tokens) onlyWhitelisted public returns (uint256, uint256) {
        require(amount > 0 && min_CRO > 0 && min_tokens > 0);
        uint256 total_liquidity = _totalSupply;
        require(total_liquidity > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 CRO_amount = amount.mul(address(this).balance) / total_liquidity;

        uint256 token_amount = amount.mul(token_reserve) / total_liquidity;
        require(CRO_amount >= min_CRO && token_amount >= min_tokens);

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = total_liquidity.sub(amount);
        msg.sender.transfer(CRO_amount);
        require(token.transfer(msg.sender, token_amount));
        emit onRemoveLiquidity(msg.sender, CRO_amount, token_amount);
        emit onLiquidity(msg.sender, _balances[msg.sender]);
        emit Transfer(msg.sender, address(0), amount);
        return (CRO_amount, token_amount);
    }
}