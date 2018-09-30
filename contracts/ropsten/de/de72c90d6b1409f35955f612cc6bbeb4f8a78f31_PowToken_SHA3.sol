pragma solidity ^0.4.11;


/*
Copyright 2017 Harry Roberts

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

contract ERC20TokenInterface
{
    /// @return The total amount of tokens
    function totalSupply() constant returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant public returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data);
}



contract ERC20and223TokenImpl is ERC20TokenInterface
{
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed; // (ERC20)
    uint256 internal total_value;

    function ERC20TokenImpl () internal {}


    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size)
    {
        require(msg.data.length >= size + 4);
        _;
    }
  

    function totalSupply()
        constant
        returns (uint256)
    {
        return total_value;
    }


    function transfer(address _to, uint256 _value)
        onlyPayloadSize(2 * 32)
        public
        returns (bool)
    {
        bytes memory empty;
        return _transfer_internal(msg.sender, _to, _value, false, empty);
    }


    function transfer(address _to, uint256 _value, bytes _data)
        onlyPayloadSize(2 * 32)
        public
        returns (bool)
    {
        return _transfer_internal(msg.sender, _to, _value, false, _data);
    }


    function transferFrom(address _from, address _to, uint256 _value)
        onlyPayloadSize(3 * 32)
        public
        returns (bool)
    {
        bytes memory empty;
        return _transfer_internal(_from, _to, _value, true, empty);
    }


    function _transfer_internal(address _from, address _to, uint256 _value, bool _dec_allowed, bytes _data)
        internal
        returns (bool)
    {
        // Verify transaction is possible and not exploitative
        bool overflow = balanceOf(_to) + _value < balanceOf(_to);

        if ( balanceOf(_from) < _value
          || allowance(_from, msg.sender) < _value 
          || overflow )
        {
            return false;
        }

        // ERC223 compatibility
        uint codeLength;        
        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }
        if ( codeLength > 0 )
        {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(_from, _value, _data);
        }

        // Finally modify balances
        balances[_from] -= _value;
        balances[_to] += _value;

        // only for &#39;transferFrom&#39;, &#39;transfer&#39; bypasses allowance
        if( _dec_allowed ) {
            allowed[_from][msg.sender] -= _value;
        }

        Transfer(_from, _to, _value,_data);
        return true;
    }


    function balanceOf(address _owner)
        constant public
        returns (uint256)
    {
        return balances[_owner];
    }


    function unapprove(address _spender)
        public
    {
        allowed[msg.sender][_spender] = 0;
    }


    function approve(address _spender, uint256 _value)
        onlyPayloadSize(2 * 32)
        public
        returns (bool)
    {
        /*
        * Prevent adjustment of allowed spend unless the value is reset to 0
        * Alternatively, call `compareAndApprove`
        * See: https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM
        */
        // XXX: compatibility problems?
        if( allowance(msg.sender, _spender) != 0 )
            throw;

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }


    /// @param _spender The address to approve
    /// @param _currentValue The previous value approved, which can be retrieved with allowance(msg.sender, _spender)
    /// @param _newValue The new value to approve, this will replace the _currentValue
    /// @return bool Whether the approval was a success (see ERC20&#39;s `approve`)
    function compareAndApprove(address _spender, uint256 _currentValue, uint256 _newValue)
        onlyPayloadSize(3 * 32)
        public
        returns(bool)
    {
        if (allowed[msg.sender][_spender] != _currentValue)
            return false;

        allowed[msg.sender][_spender] = 0;
        return approve(_spender, _newValue);
    }


    function allowance(address _owner, address _spender)
        onlyPayloadSize(2 * 32)
        constant public
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}



contract PowTokenBase is ERC20and223TokenImpl {
    event Mined(address owner, uint256 value);
    mapping(bytes32 => bool) spends;
    uint private total_coins;


    function PowTokenBase() internal {}


    function () {
        throw;
    }


    function mint(address owner, uint256 value)
        internal
    {
        balances[owner] += value;
        total_value += value;        
    }


    /**
    * A tokens value is proportionate to the chance of finding it using a brute
    * force search with random inputs. The number of Zero bits, starting at the
    * beginning, is the metric used to calculate the chance of finding it.
    *
    * For example, 0FFFFF... has a difficulty of 4, or 1 in 16.
    * While 00FFFF... has a difficulty of 8, or 1 in 256
    *
    *   difficulty = zerobit_prefix_length
    *   value = 2 ** difficulty
    *
    * Each additional zero bit doubles the difficulty, making it take twice as
    * long for a coin of difficulty 6 to be found compared to a 5.
    *
    * The total combined value is a rough estimate of the number of iterations
    * necessary to find an equal value of tokens.
    */
    function value (bytes32 _coin)
        constant public
        returns (uint256)
    {
        uint256 idx = 0;
        uint256 bitcount = 0;

        while ( idx < 32 )
        {
            uint8 octet = uint8(_coin[idx++]);

            if ( octet == 0 )
            {
                bitcount += 8;
                continue;
            }

            for ( uint offset = 0; offset < 8; offset++ )
            {
                if( (octet & (1 << offset)) != 0 )
                    return 2 ** bitcount;
                
                bitcount += 1;
            }
        }
        // Somehow _coin is all zeros.. impossible!
        throw;
    }


    function mine_success (bytes32 _coin)
        internal
        returns (uint256)
    {
        // Only spend coins once
        if( spends[_coin] == true )
            throw;
        
        // Success
        total_coins += 1;
        spends[_coin] = true;

        uint256 coin_value = value(_coin);
        mint(msg.sender, coin_value);

        Mined(msg.sender, coin_value);
        return coin_value;
    }
}



contract PowTokenHashedBase is PowTokenBase
{
    function PowTokenHashedBase () internal {}


    function mineFor (address _owner, bytes32 _nonce)
        public
        returns (uint256)
    {
        return 0;
    }


    function mine (bytes32 _nonce)
        public
        returns (uint256)
    {
        return mineFor(msg.sender, _nonce);
    }


    function mineForMany (address[] _owner, bytes32[] _nonce)
        public
        returns (uint256)
    {
        uint8 N;
        uint256 result = 0;

        for( N = 0; N < _nonce.length; N++ )
        {
            result += mineFor(_owner[N], _nonce[N]);
        }

        return result;
    }


    function mineMany (bytes32[] _nonce)
        public
        returns (uint256)
    {
        uint8 N;
        uint256 result = 0;

        for( N = 0; N < _nonce.length; N++ )
        {
            result += mineFor(msg.sender, _nonce[N]);
        }

        return result;
    }
}



/**
* Implements a Proof of Work token using SHA3 
*/
contract PowToken_SHA3 is PowTokenHashedBase
{
    string public constant symbol = "PoWS3";
    string public constant name = "ProofOfWork SHA3";    
    uint8 public constant decimals = 12;


    function mineFor (address _owner, bytes32 _nonce)
        public
        returns (uint256)
    {
        bytes32 proof_hash = sha3(_owner, _nonce);
        return mine_success(proof_hash);
    }
}



/**
* Implements a Proof of Work token using SHA256
*/
contract PowToken_SHA256 is PowTokenHashedBase
{
    string public constant symbol = "PoWS2";
    string public constant name = "ProofOfWork SHA256";    
    uint8 public constant decimals = 12;


    function mineFor (address _owner, bytes32 _nonce)
        public
        returns (uint256)
    {
        bytes32 proof_hash = sha256(_owner, _nonce);
        return mine_success(proof_hash);
    }
}



contract SaferEcRecover
{
    function SaferEcRecover() internal {}
    
    // the following function has been written by Alex Beregszaszi (@axic),
    // use it under the terms of the MIT license
    // Duplicate Solidity&#39;s ecrecover, but catching the CALL return value
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        returns (bool, address)
    {
        // We do our own memory management here. Solidity uses memory offset
        // 0x40 to store the current end of memory. We write past it (as
        // writes are memory extensions), but don&#39;t update the offset so
        // Solidity will reuse it. The memory used here is only needed for
        // this context.

        // FIXME: inline assembly can&#39;t access return values
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

            // NOTE: we can reuse the request memory because we deal with
            //       the return code
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }
  
        return (ret, addr);
    }
}



/**
* Implements a Proof of Work token using Elliptic Curves
*
* Instead of using a hash of `msg.sender` and a `nonce` to calculate the
* difficulty it uses an SHA3 hash of the public key from a Bitcoin/Ethereum
* compatible secp256k1 elliptic-curve key pair.
*
* This allows coins to be mined independently of who spends them, but to be
* spent the public key must sign the destination `msg.sender`.
*/
contract PowToken_EC
    is PowTokenBase, SaferEcRecover
{
    string public constant symbol = "PoWEC";
    string public constant name = "ProofOfWork Elliptic Curve";    
    uint8 public constant decimals = 12;
    
    
    function mineFor (address owner, address coin, uint8 v, bytes32 r, bytes32 s)
        public
        returns (uint256)
    {
        bool sigok;
        address verified;
        bytes32 msg_hash = sha3(owner, coin);

        // Verify signature matches the expected hash
        (sigok, verified) = safer_ecrecover(msg_hash, v, r, s);
        if( ! sigok || coin != verified )
            throw;

        // Extend public key to 256 bits
        return mine_success(sha3(verified));       
    }


    function mine (address coin, uint8 v, bytes32 r, bytes32 s)
        public
        returns (uint256)
    {
        return mineFor(msg.sender, coin, v, r, s);
    }


    function mineForMany (address[] owner, address[] coin, uint8[] v, bytes32[] r, bytes32[] s)
        public
        returns (uint256)
    {
        uint8 N;
        uint256 result = 0;

        for( N = 0; N < coin.length; N++ )
        {
            result += mineFor(owner[N], coin[N], v[N], r[N], s[N]);
        }

        return result;
    }


    function mineMany (address[] coin, uint8[] v, bytes32[] r, bytes32[] s)
        public
        returns (uint256)
    {
        uint8 N;
        uint256 result = 0;

        for( N = 0; N < coin.length; N++ )
        {
            result += mine(coin[N], v[N], r[N], s[N]);
        }

        return result;
    }
}