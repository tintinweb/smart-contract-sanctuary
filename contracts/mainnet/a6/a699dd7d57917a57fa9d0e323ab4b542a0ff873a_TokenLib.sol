pragma solidity 0.4.21;

/**
 * @title TokenLib
 * @author Modular Inc, https://modular.network
 *
 * version 1.3.0
 * Copyright (c) 2017 Modular, Inc
 * The MIT License (MIT)
 * https://github.com/Modular-Network/ethereum-libraries/blob/master/LICENSE
 *
 * The Token Library provides functionality to create a variety of ERC20 tokens.
 * See https://github.com/Modular-Network/ethereum-contracts for an example of how to
 * create a basic ERC20 token.
 *
 * Modular works on open source projects in the Ethereum community with the
 * purpose of testing, documenting, and deploying reusable code onto the
 * blockchain to improve security and usability of smart contracts. Modular
 * also strives to educate non-profits, schools, and other community members
 * about the application of blockchain technology.
 * For further information: modular.network
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library TokenLib {
  using BasicMathLib for uint256;

  struct TokenStorage {
    bool initialized;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string name;
    string symbol;
    uint256 totalSupply;
    uint256 initialSupply;
    address owner;
    uint8 decimals;
    bool stillMinting;
  }

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event OwnerChange(address from, address to);
  event Burn(address indexed burner, uint256 value);
  event MintingClosed(bool mintingClosed);

  /// @dev Called by the Standard Token upon creation.
  /// @param self Stored token from token contract
  /// @param _name Name of the new token
  /// @param _symbol Symbol of the new token
  /// @param _decimals Decimal places for the token represented
  /// @param _initial_supply The initial token supply
  /// @param _allowMinting True if additional tokens can be created, false otherwise
  function init(TokenStorage storage self,
                address _owner,
                string _name,
                string _symbol,
                uint8 _decimals,
                uint256 _initial_supply,
                bool _allowMinting)
                public
  {
    require(!self.initialized);
    self.initialized = true;
    self.name = _name;
    self.symbol = _symbol;
    self.totalSupply = _initial_supply;
    self.initialSupply = _initial_supply;
    self.decimals = _decimals;
    self.owner = _owner;
    self.stillMinting = _allowMinting;
    self.balances[_owner] = _initial_supply;
  }

  /// @dev Transfer tokens from caller&#39;s account to another account.
  /// @param self Stored token from token contract
  /// @param _to Address to send tokens
  /// @param _value Number of tokens to send
  /// @return True if completed
  function transfer(TokenStorage storage self, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    bool err;
    uint256 balance;

    (err,balance) = self.balances[msg.sender].minus(_value);
    require(!err);
    self.balances[msg.sender] = balance;
    //It&#39;s not possible to overflow token supply
    self.balances[_to] = self.balances[_to] + _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /// @dev Authorized caller transfers tokens from one account to another
  /// @param self Stored token from token contract
  /// @param _from Address to send tokens from
  /// @param _to Address to send tokens to
  /// @param _value Number of tokens to send
  /// @return True if completed
  function transferFrom(TokenStorage storage self,
                        address _from,
                        address _to,
                        uint256 _value)
                        public
                        returns (bool)
  {
    uint256 _allowance = self.allowed[_from][msg.sender];
    bool err;
    uint256 balanceOwner;
    uint256 balanceSpender;

    (err,balanceOwner) = self.balances[_from].minus(_value);
    require(!err);

    (err,balanceSpender) = _allowance.minus(_value);
    require(!err);

    self.balances[_from] = balanceOwner;
    self.allowed[_from][msg.sender] = balanceSpender;
    self.balances[_to] = self.balances[_to] + _value;

    emit Transfer(_from, _to, _value);
    return true;
  }

  /// @dev Retrieve token balance for an account
  /// @param self Stored token from token contract
  /// @param _owner Address to retrieve balance of
  /// @return balance The number of tokens in the subject account
  function balanceOf(TokenStorage storage self, address _owner) public view returns (uint256 balance) {
    return self.balances[_owner];
  }

  /// @dev Authorize an account to send tokens on caller&#39;s behalf
  /// @param self Stored token from token contract
  /// @param _spender Address to authorize
  /// @param _value Number of tokens authorized account may send
  /// @return True if completed
  function approve(TokenStorage storage self, address _spender, uint256 _value) public returns (bool) {
    // must set to zero before changing approval amount in accordance with spec
    require((_value == 0) || (self.allowed[msg.sender][_spender] == 0));

    self.allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /// @dev Remaining tokens third party spender has to send
  /// @param self Stored token from token contract
  /// @param _owner Address of token holder
  /// @param _spender Address of authorized spender
  /// @return remaining Number of tokens spender has left in owner&#39;s account
  function allowance(TokenStorage storage self, address _owner, address _spender)
                     public
                     view
                     returns (uint256 remaining) {
    return self.allowed[_owner][_spender];
  }

  /// @dev Authorize third party transfer by increasing/decreasing allowed rather than setting it
  /// @param self Stored token from token contract
  /// @param _spender Address to authorize
  /// @param _valueChange Increase or decrease in number of tokens authorized account may send
  /// @param _increase True if increasing allowance, false if decreasing allowance
  /// @return True if completed
  function approveChange (TokenStorage storage self, address _spender, uint256 _valueChange, bool _increase)
                          public returns (bool)
  {
    uint256 _newAllowed;
    bool err;

    if(_increase) {
      (err, _newAllowed) = self.allowed[msg.sender][_spender].plus(_valueChange);
      require(!err);

      self.allowed[msg.sender][_spender] = _newAllowed;
    } else {
      if (_valueChange > self.allowed[msg.sender][_spender]) {
        self.allowed[msg.sender][_spender] = 0;
      } else {
        _newAllowed = self.allowed[msg.sender][_spender] - _valueChange;
        self.allowed[msg.sender][_spender] = _newAllowed;
      }
    }

    emit Approval(msg.sender, _spender, _newAllowed);
    return true;
  }

  /// @dev Change owning address of the token contract, specifically for minting
  /// @param self Stored token from token contract
  /// @param _newOwner Address for the new owner
  /// @return True if completed
  function changeOwner(TokenStorage storage self, address _newOwner) public returns (bool) {
    require((self.owner == msg.sender) && (_newOwner > 0));

    self.owner = _newOwner;
    emit OwnerChange(msg.sender, _newOwner);
    return true;
  }

  /// @dev Mints additional tokens, new tokens go to owner
  /// @param self Stored token from token contract
  /// @param _amount Number of tokens to mint
  /// @return True if completed
  function mintToken(TokenStorage storage self, uint256 _amount) public returns (bool) {
    require((self.owner == msg.sender) && self.stillMinting);
    uint256 _newAmount;
    bool err;

    (err, _newAmount) = self.totalSupply.plus(_amount);
    require(!err);

    self.totalSupply =  _newAmount;
    self.balances[self.owner] = self.balances[self.owner] + _amount;
    emit Transfer(0x0, self.owner, _amount);
    return true;
  }

  /// @dev Permanent stops minting
  /// @param self Stored token from token contract
  /// @return True if completed
  function closeMint(TokenStorage storage self) public returns (bool) {
    require(self.owner == msg.sender);

    self.stillMinting = false;
    emit MintingClosed(true);
    return true;
  }

  /// @dev Permanently burn tokens
  /// @param self Stored token from token contract
  /// @param _amount Amount of tokens to burn
  /// @return True if completed
  function burnToken(TokenStorage storage self, uint256 _amount) public returns (bool) {
      uint256 _newBalance;
      bool err;

      (err, _newBalance) = self.balances[msg.sender].minus(_amount);
      require(!err);

      self.balances[msg.sender] = _newBalance;
      self.totalSupply = self.totalSupply - _amount;
      emit Burn(msg.sender, _amount);
      emit Transfer(msg.sender, 0x0, _amount);
      return true;
  }
}

library BasicMathLib {
  /// @dev Multiplies two numbers and checks for overflow before returning.
  /// Does not throw.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if there is overflow
  /// @return res The product of a and b, or 0 if there is overflow
  function times(uint256 a, uint256 b) public pure returns (bool err,uint256 res) {
    assembly{
      res := mul(a,b)
      switch or(iszero(b), eq(div(res,b), a))
      case 0 {
        err := 1
        res := 0
      }
    }
  }

  /// @dev Divides two numbers but checks for 0 in the divisor first.
  /// Does not throw.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if `b` is 0
  /// @return res The quotient of a and b, or 0 if `b` is 0
  function dividedBy(uint256 a, uint256 b) public pure returns (bool err,uint256 i) {
    uint256 res;
    assembly{
      switch iszero(b)
      case 0 {
        res := div(a,b)
        let loc := mload(0x40)
        mstore(add(loc,0x20),res)
        i := mload(add(loc,0x20))
      }
      default {
        err := 1
        i := 0
      }
    }
  }

  /// @dev Adds two numbers and checks for overflow before returning.
  /// Does not throw.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if there is overflow
  /// @return res The sum of a and b, or 0 if there is overflow
  function plus(uint256 a, uint256 b) public pure returns (bool err, uint256 res) {
    assembly{
      res := add(a,b)
      switch and(eq(sub(res,b), a), or(gt(res,b),eq(res,b)))
      case 0 {
        err := 1
        res := 0
      }
    }
  }

  /// @dev Subtracts two numbers and checks for underflow before returning.
  /// Does not throw but rather logs an Err event if there is underflow.
  /// @param a First number
  /// @param b Second number
  /// @return err False normally, or true if there is underflow
  /// @return res The difference between a and b, or 0 if there is underflow
  function minus(uint256 a, uint256 b) public pure returns (bool err,uint256 res) {
    assembly{
      res := sub(a,b)
      switch eq(and(eq(add(res,b), a), or(lt(res,a), eq(res,a))), 1)
      case 0 {
        err := 1
        res := 0
      }
    }
  }
}