// SPDX-License-Identifier:MIT
pragma solidity >=0.7.0;
import "./SafeMathTyped.sol";

// The MIT License
//
// Copyright (c) 2017-2018 0xcert, d.o.o. https://0xcert.org
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
/**
 * @title ERC20 standard token implementation.
 * @dev Standard ERC20 token. This contract follows the implementation at https://goo.gl/mLbAPJ.
 */
contract Token
{
  string internal tokenName;

  string internal tokenSymbol;

  uint8 internal tokenDecimals;

  uint256 internal tokenTotalSupply;

  mapping (address => uint256) internal balances;

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Trigger when tokens are transferred, including zero value transfers.
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  /**
   * @dev Trigger on any successful call to approve(address _spender, uint256 _value).
   */
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  /**
   * @dev Returns the name of the token.
   */
  function name()
    external
    view
    returns (string memory _name)
  {
    _name = tokenName;
  }

  /**
   * @dev Returns the symbol of the token.
   */
  function symbol()
    external
    view
    returns (string memory _symbol)
  {
    _symbol = tokenSymbol;
  }

  /**
   * @dev Returns the number of decimals the token uses.
   */
  function decimals()
    external
    view
    returns (uint8 _decimals)
  {
    _decimals = tokenDecimals;
  }

  /**
   * @dev Returns the total token supply.
   */
  function totalSupply()
    external
    view
    returns (uint256 _totalSupply)
  {
    _totalSupply = tokenTotalSupply;
  }

  /**
   * @dev Returns the account balance of another account with address _owner.
   * @param _owner The address from which the balance will be retrieved.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256 _balance)
  {
    _balance = balances[_owner];
  }

  /**
   * @dev Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. The
   * function SHOULD throw if the _from account balance does not have enough tokens to spend.
   * @param _to The address of the recipient.
   * @param _value The amount of token to be transferred.
   */
  function transfer(
    address _to,
    uint256 _value
  )
    public
    returns (bool _success)
  {
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = SafeMathTyped.sub256(balances[msg.sender], _value);
    balances[_to] = SafeMathTyped.add256(balances[_to], _value);

    emit Transfer(msg.sender, _to, _value);
    _success = true;
  }

  /**
   * @dev Allows _spender to withdraw from your account multiple times, up to the _value amount. If
   * this function is called again it overwrites the current allowance with _value.
   * @param _spender The address of the account able to transfer the tokens.
   * @param _value The amount of tokens to be approved for transfer.
   */
  function approve(
    address _spender,
    uint256 _value
  )
    public
    returns (bool _success)
  {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;

    emit Approval(msg.sender, _spender, _value);
    _success = true;
  }

  /**
   * @dev Returns the amount which _spender is still allowed to withdraw from _owner.
   * @param _owner The address of the account owning tokens.
   * @param _spender The address of the account able to transfer the tokens.
   */
  function allowance(
    address _owner,
    address _spender
  )
    external
    view
    returns (uint256 _remaining)
  {
    _remaining = allowed[_owner][_spender];
  }

  /**
   * @dev Transfers _value amount of tokens from address _from to address _to, and MUST fire the
   * Transfer event.
   * @param _from The address of the sender.
   * @param _to The address of the recipient.
   * @param _value The amount of token to be transferred.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool _success)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = SafeMathTyped.sub256(balances[_from], _value);
    balances[_to] = SafeMathTyped.add256(balances[_to], _value);
    allowed[_from][msg.sender] = SafeMathTyped.sub256(allowed[_from][msg.sender], _value);

    emit Transfer(_from, _to, _value);
    _success = true;
  }

}

/// @notice This is the ABQ token. It allows the owner (the Aardbanq DAO) to mint new tokens. It also allow the 
/// owner to change owners. The ABQ token has 18 decimals.
contract AbqErc20 is Token
{
    /// @notice The owner of the ABQ Token. This is the Aardbanq DAO.
    address public owner;
    /// @notice The address for the founders' contract.
    address public founderContract;

    constructor(address _owner, address _founderContract)
    {
        tokenName = "Aardbanq DAO";
        tokenSymbol = "ABQ";
        tokenDecimals = 18;
        tokenTotalSupply = 0;
        owner = _owner;
        founderContract = _founderContract;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner, "ABQ/only-owner");
        _;
    }

    event OwnerChange(address indexed newOwner);
    /// @notice Allows the owner to change the ownership to another address.
    /// @param _newOwner The address that should be the new owner.
    function changeOwner(address _newOwner)
        external
        onlyOwner()
    {
        owner = _newOwner;
        emit OwnerChange(_newOwner);
    }

    /// @notice Allows the owner to mint tokens.
    /// @param _target The address to mint the tokens to.
    /// @param _abqAmount The amount of ABQ to mint.
    function mint(address _target, uint256 _abqAmount)
        external
        onlyOwner()
    {
        balances[_target] = SafeMathTyped.add256(balances[_target], _abqAmount);
        emit Transfer(address(0), _target, _abqAmount);

        // CG: Founder's part 15% of total that will be issued
        // MATH:
        // totalIncrease = mintAmount + founderPart {A}
        // also:
        // founderPart = 0.15 * totalIncrease
        // ... founderPart / 0.15 = totalIncrease   {B}
        // substituting {A} in {B}
        // ... founderPart / 0.15 = mintAmount + founderPart
        // ... (founderPart / 0.15) - founderPart = mintAmount
        // ... (founderPart - (0.15 * founderPart)) / 0.15 = mintAmount
        // ... (0.85 * founderPart) / 0.15 = mintAmount
        // ... 0.85 * founderPart = 0.15 * mintAmount
        // ... founderPart = (0.15 / 0.85) * mintAmount
        // ... founderPart ~= (mintAmount * 17647) / 100000
        uint256 founderShare = SafeMathTyped.mul256(_abqAmount, 17647) / 100000;
        balances[founderContract] = SafeMathTyped.add256(balances[founderContract], founderShare);
        tokenTotalSupply = SafeMathTyped.add256(SafeMathTyped.add256(tokenTotalSupply, _abqAmount), founderShare);
        emit Transfer(address(0), founderContract, founderShare);
    }

    /// @notice Allow the sender to burn tokens in their account.
    /// @param _abqAmount The amount of tokens to burn from the msg.sender account.
    function burn(uint256 _abqAmount)
      external
    {
      tokenTotalSupply = SafeMathTyped.sub256(tokenTotalSupply, _abqAmount);
      balances[msg.sender] = SafeMathTyped.sub256(balances[msg.sender], _abqAmount);
      emit Transfer(msg.sender, address(0), _abqAmount);
    }

    event NameChange(string newName);
    /// @notice Allow the owner to change the name of the token. 
    /// @param _newName The new name for the token
    function changeName(string calldata _newName)
      external
      onlyOwner()
    {
      tokenName = _newName;
      emit NameChange(_newName);
    }

    event SymbolChange(string newSymbol);
    /// @notice Allow the owner to change the symbol of the token.
    /// @param _newSymbol The new symbol for the token.
    function changeSymbol(string calldata _newSymbol)
      external
      onlyOwner()
    {
      tokenSymbol = _newSymbol;
      emit SymbolChange(_newSymbol);
    }
}