/**
 *Submitted for verification at polygonscan.com on 2021-07-19
*/

pragma solidity ^0.4.24;


contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address) public view returns (uint256);
    function transfer(address, uint256) public returns (bool);
    function transferFrom(address, address, uint256) public returns (bool);
    function approve(address, uint256) public returns (bool);
    function allowance(address, address) public view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract delegableTokenInterface {
    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";
    bytes4 public constant signedTransferSig = "\x75\x32\xea\xac";

    function signedTransferHash(address, address, uint, uint, uint) public view returns (bytes32);
    function signedTransfer(address, address, uint, uint, uint, bytes, address) public returns (bool);
    function signedTransferCheck(address, address, uint, uint, uint, bytes, address) public view returns (string);
}

contract Owned {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // allow transfer of ownership to another address in case shit hits the fan. 
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    
    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
	    require(_to != address(0));
	    require(_value <= balances[_from]);
	    require(_value <= allowed[_from][msg.sender]);

	    balances[_from] = balances[_from].sub(_value);
	    balances[_to] = balances[_to].add(_value);
	    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
	    emit Transfer(_from, _to, _value);
	    return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    


    function approve(address _spender, uint256 _value) public returns (bool success) {
        // Added to prevent potential race attack.
        // forces caller of this function to ensure address allowance is already 0
        // ref: https://github.com/ethereum/EIPs/issues/738
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract delegableToken is StandardToken, delegableTokenInterface {
    mapping(address => uint) nextNonce;

    function getNextNonce(address _owner) public view returns (uint) {
        return nextNonce[_owner];
    }


    /**
     * Prevalidation - Checks nonce value, signing account/parameter mismatch, balance sufficient for transfer 
     */    
    function signedTransferCheck(address from, address to, uint transferAmount, uint fee,
                                    uint nonce, bytes sig, address feeAccount) public view returns (string result) {
        bytes32 hash = signedTransferHash(from, to, transferAmount, fee, nonce);
        if (nextNonce[from] != nonce)
            return "Nonce does not match.";
        if (from == address(0) || from != ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig))
            return "Mismatch in signing account or parameter mismatch.";
        if (transferAmount > balances[from])
            return "Transfer amount exceeds token balance on address.";
        if (transferAmount.add(fee) > balances[from])
            return "Insufficient tokens to pay for fees.";
        if (balances[feeAccount] + fee < balances[feeAccount])
            return "Overflow error.";
        return "All checks cleared";
    }

    // ------------------------------------------------------------------------
    // ecrecover from a signature rather than the signature in parts [v, r, s]
    // The signature format is a compact form {bytes32 r}{bytes32 s}{uint8 v}.
    // Compact means, uint8 is not padded to 32 bytes.
    //
    // An invalid signature results in the address(0) being returned, make
    // sure that the returned result is checked to be non-zero for validity
    //
    // Parts from https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
    // ------------------------------------------------------------------------
    function ecrecoverFromSig(bytes32 hash, bytes sig) public pure returns (address recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) return address(0);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            // Here we are loading the last 32 bytes. We exploit the fact that 'mload' will pad with zeroes if we overread.
            // There is no 'mload8' to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))
        }
        // Albeit non-transactional signatures are not specified by the YP,
        // one would expect it to match the YP range of [27, 28]
        // geth uses [0, 1] and some clients have followed. This might change,
        // see https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
          v += 27;
        }
        if (v != 27 && v != 28) return address(0);
        return ecrecover(hash, v, r, s);
    }


    /**
     * Creates keccak256 hash of sent parameters
     */    
    function signedTransferHash(address from, address to, uint transferAmount, uint fee,
                                    uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(
            abi.encodePacked(signedTransferSig, address(this), from, to, transferAmount, fee, nonce)
                        );
    }

    /**
     * executes signedTransfer, allowing tokens to be sent through a delegate
     */    
    function signedTransfer(address from, address to, uint transferAmount, uint fee,
                            uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        bytes32 hash = signedTransferHash(from, to, transferAmount, fee, nonce);
        // verifies if signature is indeed signed by owner, and with the same values
        require(from != address(0) && from == ecrecoverFromSig(keccak256(abi.encodePacked(signingPrefix, hash)), sig));
        require(nextNonce[from] == nonce);

        // update nonce
        nextNonce[from] = nonce + 1;

        // transfer tokens
        balances[from] = balances[from].sub(transferAmount);
        balances[to] = balances[to].add(transferAmount);
        emit Transfer(from, to, transferAmount);
        
        // transfer fees
        balances[from] = balances[from].sub(fee);
        balances[feeAccount] = balances[feeAccount].add(fee);
        emit Transfer(from, feeAccount, fee);
        return true;
    }
}


//token contract
contract TestDelegateToken is delegableToken, Owned {
    
    event Burn(address indexed burner, uint256 value);
    
    /* Public variables of the token */
    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    uint256 public totalSupply;
    address public distributionAddress;
    bool public isTransferable = false;
    

    constructor() public {
        name = "Test Delegate Token v0.03";                          
        decimals = 18; 
        symbol = "TDELT";
        totalSupply = 1000000000 * 10 ** uint256(decimals); 
        owner = msg.sender;

        //transfer all to handler address
        balances[msg.sender] = totalSupply;
        emit Transfer(0x0, msg.sender, totalSupply);
    }

    function signedTransfer(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig,
                            address feeAccount) public returns (bool success) {
        require(isTransferable);
        return super.signedTransfer(tokenOwner, to, tokens, fee, nonce, sig, feeAccount);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(isTransferable);
        return super.transfer(_to, _value);
    } 

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(isTransferable);
        return super.transferFrom(_from, _to, _value);
    } 

    /**
     * Get totalSupply of tokens - Minus any from address 0 if that was used as a burnt method
     * Suggested way is still to use the burnSent function
     */    
    function totalSupply() public view returns (uint256) {
        return totalSupply.sub(balances[address(0)]);
    }

    /**
     * unlocks tokens, only allowed once
     */
    function enableTransfers() public onlyOwner {
        isTransferable = true;
    }
    
    /**
     * Callable by anyone
     * Accepts an input of the number of tokens to be burnt held by the sender.
     */
    function burnSent(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }

    /**
     * Allow distribution helper to help with distributeToken function
     */
    function setDistributionAddress(address _setAddress) public onlyOwner {
        distributionAddress = _setAddress;
    }

    /**
     * Called by owner to transfer tokens - Managing manual distribution.
     * Also allow distribution contract to call for this function
     */
    function distributeTokens(address _to, uint256 _value) public {
        require(distributionAddress == msg.sender || owner == msg.sender);
        super.transfer(_to, _value);
    }
}


library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}