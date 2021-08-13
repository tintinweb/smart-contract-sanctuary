/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

/* 
 * SPDX-License-Identifier: MIT
 * Copyright (c) 2021 p0m0n <https://github.com/p0m0n>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */


pragma solidity >=0.7.0 <0.9.0;



contract TokenBalance
{
    uint256                                         private mTotalSupply;
    mapping(address => uint256)                     private mDataBalance;
    mapping(address => mapping(address => uint256)) private mDataAllowed;
    
    constructor(address _account, uint256 _initialSupply)
    {
        setTotalSupply(_initialSupply);
        setBalance(_account, _initialSupply);
    }
    
    // Get the number of tokens from the {balance}.
    function getBalance(address _account) public view returns (uint256)
    {
        return mDataBalance[_account];
    }
    
    // Setup the number of tokens on the {balance}.
    function setBalance(address _account, uint256 _value) public
    {
        mDataBalance[_account] = _value;
    }
    
    // Adds the number of tokens to the {balance}.
    function addBalance(address _account, uint256 _value) public
    {
        mDataBalance[_account] += _value;
    }
    
    // Subtracts the number of tokens from the {balance}.
    function subBalance(address _account, uint256 _value) public
    {
        mDataBalance[_account] -= _value;
    }
    
    function getAllowed(address _owner, address _spender) public view returns (uint256)
    {
        return mDataAllowed[_owner][_spender];
    }
    
    function setAllowed(address _owner, address _spender, uint256 _value) public
    {
        mDataAllowed[_owner][_spender] = _value;
    }
    
    function addAllowed(address _owner, address _spender, uint256 _value) public
    {
        mDataAllowed[_owner][_spender] += _value;
    }
    
    function subAllowed(address _owner, address _spender, uint256 _value) public
    {
        mDataAllowed[_owner][_spender] -= _value;
    }
    
    // Get the total number of tokens.
    function getTotalSupply() public view returns (uint256)
    {
        return mTotalSupply;
    }
    
    // Setup the total number of tokens.
    function setTotalSupply(uint256 _value) public
    {
        mTotalSupply = _value;
    }
    
    // Adds the total number of tokens.
    function addTotalSupply(uint256 _value) public
    {
        mTotalSupply += _value;
    }
    
    // Subtracts the total number of tokens.
    function subTotalSupply(uint256 _value) public
    {
        mTotalSupply -= _value;
    }
}


abstract contract SOLContext
{
    // sender of the message (current call).
    function msgSender() internal view virtual returns (address)
    {
        return msg.sender;
    }
    
    // complete calldata.
    function msgData() internal view virtual returns (bytes calldata)
    {
        return msg.data;
    }
}


abstract contract Ownable is SOLContext
{
    address private mCurrentOwner;
    
    // event for EVM logging
    event OwnershipTransfer(address indexed oldOwner, address indexed newOwner);
    
    // The {Ownable} constructor sets the initial {owner} of the contract when deployed.
    constructor()
    {
        mCurrentOwner = super.msgSender();
        emit OwnershipTransfer(address(0), mCurrentOwner);
    }
    
    // Throws if called by any account other than the owner.
    modifier onlyCurrentOwner()
    {
        if (isCurrentOwner())
        {
            revert("Ownable: caller is not the current owner");
        }_;
    }
    
     // the address of the owner.
    function owner() public view returns (address)
    {
        return mCurrentOwner;
    }
    
    // Allows the current owner to transfer control of the contract to a {newOwner}.
    function transferOwnership(address newOwner) public onlyCurrentOwner
    {
        emit OwnershipTransfer(mCurrentOwner, newOwner);
        mCurrentOwner = newOwner;
    }
    
    // true if {msg.sender} is the owner of the contract.
    function isCurrentOwner() internal view returns (bool)
    {
        return (super.msgSender() == mCurrentOwner);
    }
}


interface IERC20
{
    // Returns the name of the token - e.g. "Ethereum".
    // OPTIONAL - This method can be used to improve usability,
    // but interfaces and other contracts MUST NOT expect these values to be present.
    function name() external view returns (string memory);
    
    // Returns the symbol of the token. E.g. “ETH”.
    // OPTIONAL - This method can be used to improve usability,
    // but interfaces and other contracts MUST NOT expect these values to be present.
    function symbol() external view returns (string memory);
    
    // Returns the number of decimals the token uses - e.g. 8,
    // means to divide the token amount by {100000000} to get its user representation.
    //
    // OPTIONAL - This method can be used to improve usability, but interfaces and other contracts MUST NOT expect these values to be present.
    function decimals() external view returns (uint8);
    
    // Returns the total token supply.
    function totalSupply() external view returns (uint256);
    
    // Returns the account balance of another account with {_address}.
    function balanceOf(address _address) external view returns (uint256);
    
    // Transfers {_value} amount of tokens to address {_recipient}, and MUST fire the {Transfer} event.
    // The function SHOULD {throw} if the message caller’s account balance does not have enough tokens to spend.
    //
    // Note Transfers of 0 values MUST be treated as normal transfers and fire the {Transfer} event.
    function transfer(address _recipient, uint256 _value) external returns (bool);
    
    // Transfers {_value} amount of tokens from address {_sender} to address {_recipient}, and MUST fire the {Transfer} event.
    // The {transferFrom} method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf.
    // This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies.
    // The function SHOULD {throw} unless the {_sender} account has deliberately authorized the sender of the message via some mechanism.
    //
    // Note Transfers of 0 values MUST be treated as normal transfers and fire the {Transfer} event.
    function transferFrom(address _sender, address _recipient, uint256 _value) external returns (bool);
    
    // Allows {_spender} to withdraw from your account multiple times, up to the {_value} amount.
    // If this function is called again it overwrites the current allowance with {_value}.
    //
    // NOTE: To prevent attack vectors like the one described here and discussed here,
    // clients SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before setting it to another value for the same spender.
    //
    // THOUGH The contract itself shouldn’t enforce it, to allow backwards compatibility with contracts deployed before
    function approve(address _spender, uint256 _value) external returns (bool);
    
    // Returns the amount which {_spender} is still allowed to withdraw from {_owner}.
    function allowance(address _owner, address _spender) external view returns (uint256);
    
    // MUST trigger when tokens are transferred, including zero value transfers.
    // A token contract which creates new tokens SHOULD trigger a {Transfer} event with the {_sender} address set to {0x0} when tokens are created.
    event Transfer(address indexed _sender, address indexed _recipient, uint256 _value);
    
    // MUST trigger on any successful call to {approve}.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



contract ERC20Standard is IERC20, Ownable
{
    string private mString;
    string private mSymbol;
    uint8  private mDecimal;
    TokenBalance internal BalanceDB;
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply)
    {
        mString   = _name;
        mSymbol   = _symbol;
        mDecimal  = _decimals;
        BalanceDB = new TokenBalance(super.owner(), _initialSupply);
    }
    
    // Fix for the ERC-20 short address attack.
    modifier onlyPayloadSize(uint size)
    {
        require(!(msg.data.length < size + 4));
        _;
    }
    
    function name() public view override returns (string memory)
    {
        return mString;
    }
    
    
    function symbol() public view override returns (string memory)
    {
        return mSymbol;
    }
    
    
    function decimals() public view override returns (uint8)
    {
        return mDecimal;
    }
    
   
    function totalSupply() public view override returns (uint256)
    {
        return BalanceDB.getTotalSupply();
    }
    
    
    function balanceOf(address _address) public view override returns (uint256)
    {
        return BalanceDB.getBalance(_address);
    }
    
    function transfer(address _recipient, uint256 _value) public onlyPayloadSize(2*32) override returns (bool)
    {
        address _current = super.msgSender();
        if ((_current == address(0)) || (_recipient == address(0)) || (_value == uint256(0)))
        {
            revert("ERC20Standard: transfer, one of the incoming parameters is zero, check all parameters.");
        }
     
        if (BalanceDB.getBalance(_current) >= _value)
        {
            BalanceDB.subBalance(_current,   _value);
            BalanceDB.addBalance(_recipient, _value);
            emit Transfer(_current, _recipient, _value);
            return true;
        }
        else
        {
            revert("ERC20Standard: transfer, not enough tokens on the balance for transfer.");
        }
    }
    
    function transferFrom(address _sender, address _recipient, uint256 _value) public onlyPayloadSize(3*32) override returns (bool)
    {
        address _current = super.msgSender();
        if ((_current == address(0)) || (_sender == address(0)) || (_recipient == address(0)) || (_value == uint256(0)))
        {
            revert("ERC20Standard: transferFrom, one of the incoming parameters is zero, check all parameters.");
        }
        
        if ((BalanceDB.getBalance(_sender) >= _value) && (BalanceDB.getAllowed(_sender, _current) >= _value))
        {
            BalanceDB.subBalance(_sender,    _value);
            BalanceDB.addBalance(_recipient, _value);
            BalanceDB.setAllowed(_sender, _current, _value);
            emit Transfer(_sender, _recipient, _value);
            return true;
        }
        else
        {
            revert("ERC20Standard: transferFrom, not enough tokens on the balance for transfer.");
        }
    }
    
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2*32) override returns (bool)
    {
        address _current = super.msgSender();
        if ((_current == address(0)) || (_spender == address(0)) || (_value == uint256(0)))
        {
            revert("ERC20Standard: approve, one of the incoming parameters is zero, check all parameters");
        }
        
        BalanceDB.setAllowed(_current, _spender, _value);
        emit Approval(_current, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view override returns (uint256)
    {
        return BalanceDB.getAllowed(_owner, _spender);
    }
}

contract TestERC20Standard is ERC20Standard("MyToken", "MT", 18, 1_000_000_000000000000000000)
{
}