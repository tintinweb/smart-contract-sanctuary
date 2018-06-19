pragma solidity ^0.4.11;


contract ERC20 {

  function balanceOf(address who) constant public returns (uint);
  function allowance(address owner, address spender) constant public returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

}





// Controller for Token interface
// Taken from https://github.com/Giveth/minime/blob/master/contracts/MiniMeToken.sol

/// @dev The token controller contract must implement these functions
contract TokenController {
    /// @notice Called when `_owner` sends ether to the Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) payable public returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}


contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) onlyController public {
        controller = _newController;
    }
}


contract ControlledToken is ERC20, Controlled {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;1.0&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.
    uint256 public totalSupply;

    function ControlledToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }


    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] >= _value);

        if (isContract(controller)) {
            require(TokenController(controller).onTransfer(msg.sender, _to, _value));
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        // Alerts the token controller of the transfer

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);

        if (isContract(controller)) {
            require(TokenController(controller).onTransfer(_from, _to, _value));
        }

        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {

        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _value));
        }

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    ////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount ) onlyController returns (bool) {
        uint curTotalSupply = totalSupply;
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        totalSupply = curTotalSupply + _amount;
        balances[_owner]  = previousBalanceTo + _amount;
        Transfer(0, _owner, _amount);
        return true;
    }


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
        uint curTotalSupply = totalSupply;
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        totalSupply = curTotalSupply - _amount;
        balances[_owner] = previousBalanceFrom - _amount;
        Transfer(_owner, 0, _amount);
        return true;
    }

    /// @notice The fallback function: If the contract&#39;s controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    function ()  payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        ControlledToken token = ControlledToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;


}



/// `Owned` is a base level contract that assigns an `owner` that can be later changed
contract Owned {
    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner { require (msg.sender == owner); _; }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    function Owned() { owner = msg.sender;}

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner)  onlyOwner {
        owner = _newOwner;
    }
}

/**
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
 */
contract SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


contract TokenSaleAfterSplit is TokenController, Owned, SafeMath {


    uint public startFundingTime;           // In UNIX Time Format
    uint public endFundingTime;             // In UNIX Time Format

    uint public tokenCap;                   // Maximum amount of tokens to be distributed
    uint public totalTokenCount;            // Actual amount of tokens distributed

    uint public totalCollected;             // In wei
    ControlledToken public tokenContract;   // The new token for this TokenSale
    address public vaultAddress;            // The address to hold the funds donated
    bool public transfersAllowed;           // If the token transfers are allowed
    uint256 public exchangeRate;            // USD/ETH rate * 100
    uint public exchangeRateAt;             // Block number when exchange rate was set

    /// @notice &#39;TokenSale()&#39; initiates the TokenSale by setting its funding
    /// parameters
    /// @dev There are several checks to make sure the parameters are acceptable
    /// @param _startFundingTime The UNIX time that the TokenSale will be able to
    /// start receiving funds
    /// @param _endFundingTime The UNIX time that the TokenSale will stop being able
    /// to receive funds
    /// @param _tokenCap Maximum amount of tokens to be sold
    /// @param _vaultAddress The address that will store the donated funds
    /// @param _tokenAddress Address of the token contract this contract controls
    /// @param _transfersAllowed if token transfers are allowed
    /// @param _exchangeRate USD/ETH rate * 100
    function TokenSaleAfterSplit (
        uint _startFundingTime,
        uint _endFundingTime,
        uint _tokenCap,
        address _vaultAddress,
        address _tokenAddress,
        bool _transfersAllowed,
        uint256 _exchangeRate
    ) public {
        require ((_endFundingTime >= now) &&           // Cannot end in the past
            (_endFundingTime > _startFundingTime) &&
            (_vaultAddress != 0));                    // To prevent burning ETH
        startFundingTime = _startFundingTime;
        endFundingTime = _endFundingTime;
        tokenCap = _tokenCap;
        tokenContract = ControlledToken(_tokenAddress);// The Deployed Token Contract
        vaultAddress = _vaultAddress;
        transfersAllowed = _transfersAllowed;
        exchangeRate = _exchangeRate;
        exchangeRateAt = block.number;
    }

    /// @dev The fallback function is called when ether is sent to the contract, it
    /// simply calls `doPayment()` with the address that sent the ether as the
    /// `_owner`. Payable is a required solidity modifier for functions to receive
    /// ether, without this modifier functions will throw if ether is sent to them
    function ()  payable public {
        doPayment(msg.sender);
    }


    /// @dev `doPayment()` is an internal function that sends the ether that this
    ///  contract receives to the `vault` and creates tokens in the address of the
    ///  `_owner` assuming the TokenSale is still accepting funds
    /// @param _owner The address that will hold the newly created tokens

    function doPayment(address _owner) internal {

        // First check that the TokenSale is allowed to receive this donation
        require ((now >= startFundingTime) &&
            (now <= endFundingTime) &&
            (tokenContract.controller() != 0) &&
            (msg.value != 0) );

        uint256 tokensAmount = mul(msg.value, exchangeRate) / 10000;

        require( totalTokenCount + tokensAmount <= tokenCap );

        //Track how much the TokenSale has collected
        totalCollected += msg.value;

        //Send the ether to the vault
        require (vaultAddress.call.gas(28000).value(msg.value)());

        // Creates an  amount of tokens base on ether sent and exchange rate. The new tokens are created
        //  in the `_owner` address
        require (tokenContract.generateTokens(_owner, tokensAmount));

        totalTokenCount += tokensAmount;

        return;
    }

    function distributeTokens(address[] _owners, uint256[] _tokens) onlyOwner public {

        require( _owners.length == _tokens.length );
        for(uint i=0;i<_owners.length;i++){
            require (tokenContract.generateTokens(_owners[i], _tokens[i]));
        }

    }


    /// @notice `onlyOwner` changes the location that ether is sent
    /// @param _newVaultAddress The address that will receive the ether sent to this token sale
    function setVault(address _newVaultAddress) onlyOwner public{
        vaultAddress = _newVaultAddress;
    }

    /// @notice `onlyOwner` changes the setting to allow transfer tokens
    /// @param _allow  allowing to transfer tokens
    function setTransfersAllowed(bool _allow) onlyOwner public{
        transfersAllowed = _allow;
    }

    /// @notice `onlyOwner` changes the exchange rate of token to ETH
    /// @param _exchangeRate USD/ETH rate * 100
    function setExchangeRate(uint256 _exchangeRate) onlyOwner public{
        exchangeRate = _exchangeRate;
        exchangeRateAt = block.number;
    }

    /// @notice `onlyOwner` changes the controller of the tokenContract
    /// @param _newController - controller to be used with token
    function changeController(address _newController) onlyOwner public {
        tokenContract.changeController(_newController);
    }

    /////////////////
    // TokenController interface
    /////////////////

    /// @notice `proxyPayment()` allows the caller to send ether to the TokenSale and
    /// have the tokens created in an address of their choosing
    /// @param _owner The address that will hold the newly created tokens

    function proxyPayment(address _owner) payable public returns(bool) {
        doPayment(_owner);
        return true;
    }



    /// @notice Notifies the controller about a transfer, for this TokenSale all
    ///  transfers are allowed by default and no extra notifications are needed
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public returns(bool) {
        return transfersAllowed;
    }

    /// @notice Notifies the controller about an approval, for this TokenSale all
    ///  approvals are allowed by default and no extra notifications are needed
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool)
    {
        return transfersAllowed;
    }


}