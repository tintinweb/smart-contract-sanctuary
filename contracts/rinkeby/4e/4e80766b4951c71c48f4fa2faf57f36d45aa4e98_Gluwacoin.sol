/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity ^0.5.9;



contract Erc20
{   
    function totalSupply() public view returns (uint256 amount);
    function balanceOf(address _tokenOwner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _tokenOwner, address _spender) public view returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Erc20Plus is Erc20
{
    function burn(uint256 _value) public returns (bool success);
    function mint(address _to, uint256 _value) public returns (bool success);

    event Mint(address indexed _mintTo, uint256 _value);
    event Burnt(address indexed _burnFrom, uint256 _value);
}

contract Owned
{
    address internal _owner;

    constructor() public
    {
        _owner = msg.sender;
    }

    modifier onlyOwner 
    {
        require(msg.sender == _owner, "Only contract owner can do this.");
        _;
    }   

    function () external payable 
    {
        require(false, "eth transfer is disabled."); // throw
    }
}


contract Gluwacoin is Erc20Plus, Owned
{
    using SafeMath for uint256;
    using ECDSA for bytes32;

    string public constant name = "USD Gluwacoin";
    string public constant symbol = "USD-G";
    uint8 public constant decimals = 18;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;

    enum ReservationStatus
    {
        Inactive,
        Active,
        Expired,
        Reclaimed,
        Completed
    }

    struct Reservation
    {
        uint256 _amount;
        uint256 _fee;
        address _recipient;
        address _executor;
        uint256 _expiryBlockNum;
        ReservationStatus _status;
    }

    // Address mapping to mapping of nonce to amount and expiry for that nonce.
    mapping (address => mapping(uint256 => Reservation)) private _reserved;

    // Total amount of reserved balance for address
    mapping (address => uint256) private _totalReserved;

    mapping (address => mapping (uint256 => bool)) _usedNonces;

    event NonceUsed(address indexed _user, uint256 _nonce);

    function totalSupply() public view returns (uint256 amount)
    {
        return _totalSupply;
    }

    /**
        Returns balance of token owner minus reserved amount.
     */
    function balanceOf(address _tokenOwner) public view returns (uint256 balance)
    {
        return _balances[_tokenOwner].subtract(_totalReserved[_tokenOwner]);
    }

    /**
        Returns the total amount of tokens for token owner.
     */
    function totalBalanceOf(address _tokenOwner) public view returns (uint256 balance)
    {
        return _balances[_tokenOwner];
    }

    function getReservation(address _tokenOwner, uint256 _nonce) public view returns (uint256 _amount, uint256 _fee, address _recipient, address _executor, uint256 _expiryBlockNum, ReservationStatus _status)
    {
        Reservation memory _reservation = _reserved[_tokenOwner][_nonce];

        _amount = _reservation._amount;
        _fee = _reservation._fee;
        _recipient = _reservation._recipient;
        _executor = _reservation._executor;
        _expiryBlockNum = _reservation._expiryBlockNum;

        if (_reservation._status == ReservationStatus.Active && _reservation._expiryBlockNum <= block.number)
        {
            _status = ReservationStatus.Expired;
        }
        else
        {
            _status = _reservation._status;
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        require(_balances[msg.sender].subtract(_totalReserved[msg.sender]) >= _value, "Insufficient balance for transfer");
        require(_to != address(0), "Can not transfer to zero address");

        _balances[msg.sender] = _balances[msg.sender].subtract(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transfer(address _from, address _to, uint256 _value, uint256 _fee, uint256 _nonce, bytes memory _sig) public returns (bool success)
    {
        require(_to != address(0), "Can not transfer to zero address");

        uint256 _valuePlusFee = _value.add(_fee);
        require(_balances[_from].subtract(_totalReserved[_from]) >= _valuePlusFee, "Insufficient balance for transfer");
        

        bytes32 hash = keccak256(abi.encodePacked(address(this), _from, _to, _value, _fee, _nonce));
        validateSignature(hash, _from, _nonce, _sig);

        _balances[_from] = _balances[_from].subtract(_valuePlusFee);
        _balances[_to] = _balances[_to].add(_value);
        _totalSupply = _totalSupply.subtract(_fee);

        emit Transfer(_from, _to, _value);
        emit Transfer(_from, address(0), _fee);
        emit Burnt(_from, _fee);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        require(_balances[_from].subtract(_totalReserved[_from]) >= _value, "Insufficient balance for transfer");
        require(_allowed[_from][msg.sender] >= _value, "Allowance exceeded");
        require(_to != address(0), "Can not transfer to zero address");

        _balances[_from] = _balances[_from].subtract(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].subtract(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        require(_spender != address(0), "Invalid spender address");

        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

    function allowance(address _tokenOwner, address _spender) public view returns (uint256 remaining)
    {
        return _allowed[_tokenOwner][_spender];
    }

    function burn(uint256 _value) public onlyOwner returns (bool success)
    {
        require(_balances[msg.sender].subtract(_totalReserved[msg.sender]) >= _value, "Insufficient balance for burn");

        _balances[msg.sender] = _balances[msg.sender].subtract(_value);
        _totalSupply = _totalSupply.subtract(_value);

        emit Transfer(msg.sender, address(0), _value);
        emit Burnt(msg.sender, _value);

        return true;
    }

    function mint(address _to, uint256 _value) public onlyOwner returns (bool success)
    {
        require(_to != address(0), "Can not mint to zero address");

        _balances[_to] = _balances[_to].add(_value);
        _totalSupply = _totalSupply.add(_value);

        emit Transfer(address(0), _owner, _value);
        emit Transfer(_owner, _to, _value);
        emit Mint(_to, _value);

        return true;
    }

    function reserve(address _from, address _to, address _executor, uint256 _amount, uint256 _fee, uint256 _nonce, uint256 _expiryBlockNum, bytes memory _sig) public returns (bool success)
    {
        require(_expiryBlockNum > block.number, "Invalid block expiry number");
        require(_amount > 0, "Invalid reserve amount");
        require(_from != address(0), "Can't reserve from zero address");
        require(_to != address(0), "Can't reserve to zero address");
        require(_executor != address(0), "Can't execute from zero address");

        uint256 _amountPlusFee = _amount.add(_fee);
        require(_balances[_from].subtract(_totalReserved[_from]) >= _amountPlusFee, "Insufficient funds to create reservation");

        bytes32 hash = keccak256(abi.encodePacked(address(this), _from, _to, _executor, _amount, _fee, _nonce, _expiryBlockNum));
        validateSignature(hash, _from, _nonce, _sig);

        _reserved[_from][_nonce] = Reservation(_amount, _fee, _to, _executor, _expiryBlockNum, ReservationStatus.Active);
        _totalReserved[_from] = _totalReserved[_from].add(_amountPlusFee);

        return true;
    }

    function execute(address _sender, uint256 _nonce) public returns (bool success)
    {
        Reservation storage _reservation = _reserved[_sender][_nonce];

        require(_reservation._status == ReservationStatus.Active, "Invalid reservation to execute");
        require(_reservation._expiryBlockNum > block.number, "Reservation has expired and can not be executed");
        require(_reservation._executor == msg.sender, "This address is not authorized to execute this reservation");

        uint256 _amountPlusFee = _reservation._amount.add(_reservation._fee);

        _balances[_sender] = _balances[_sender].subtract(_amountPlusFee);
        _balances[_reservation._recipient] = _balances[_reservation._recipient].add(_reservation._amount);
        _totalSupply = _totalSupply.subtract(_reservation._fee);

        emit Transfer(_sender, _reservation._recipient, _reservation._amount);
        emit Transfer(_sender, address(0), _reservation._fee);
        emit Burnt(_sender, _reservation._fee);

        _reserved[_sender][_nonce]._status = ReservationStatus.Completed;
        _totalReserved[_sender] = _totalReserved[_sender].subtract(_amountPlusFee);

        return true;
    }

    function reclaim(address _sender, uint256 _nonce) public returns (bool success)
    {
        Reservation storage _reservation = _reserved[_sender][_nonce];
        require(_reservation._status == ReservationStatus.Active, "Invalid reservation status");

        if (msg.sender != _owner)
        {
            require(msg.sender == _sender, "Can not reclaim another user's reservation for them");
            require(_reservation._expiryBlockNum <= block.number, "Reservation has not expired yet");
        }

        _reserved[_sender][_nonce]._status = ReservationStatus.Reclaimed;
        _totalReserved[_sender] = _totalReserved[_sender].subtract(_reservation._amount).subtract(_reservation._fee);

        return true;
    }

    function validateSignature(bytes32 _hash, address _from, uint256 _nonce, bytes memory _sig) internal
    {
        bytes32 messageHash = _hash.toEthSignedMessageHash();

        address _signer = messageHash.recover(_sig);
        require(_signer == _from, "Invalid signature");

        require(!_usedNonces[_signer][_nonce], "Nonce has already been used for this address");
        _usedNonces[_signer][_nonce] = true;

        emit NonceUsed(_signer, _nonce);
    }
}

pragma solidity ^0.5.9;
/** 
The MIT License (MIT)

Copyright (c) 2016-2019 zOS Global Limited

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * (.note) This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * (.warning) `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise)
     * be too long), and then calling `toEthSignedMessageHash` on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * [`eth_sign`](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign)
     * JSON-RPC method.
     *
     * See `recover`.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

pragma solidity ^0.5.9;
/**
The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function multiply(uint256 a, uint256 b) internal pure returns (uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0)
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function divide(uint256 a, uint256 b) internal pure returns (uint256)
    {
        require(b > 0, "Division by zero"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subtract(uint256 a, uint256 b) internal pure returns (uint256)
    {
        require(b <= a, "Subtraction underflow");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");

        return c;
    }
}