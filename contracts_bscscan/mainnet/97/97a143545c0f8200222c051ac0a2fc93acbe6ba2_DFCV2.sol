/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

/**
 *SPDX-License-Identifier: UNLICENSED
*/

// ----------------------------------------------------------------------------
//
// Symbol      : DFC
// Name        : DefiConnect
// Total supply: 200,000,000
// Decimals    : 8
// Website     : deficonnect.tech
//
// Your gateway into the decentralize financial (Defi) world. 
// Payment Gateway, Metaverse, NFTs, .

pragma solidity 0.8.4;


/**
 * @title SafeMath
 */
library SafeMath {

    /**
    * Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // require(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // require(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}

contract DFCV2 {
    
    using SafeMath for uint256;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    string public constant name = "DefiConnect";
    string public constant symbol = "DFC";
    uint public constant decimals = 8;
    
    uint256 public totalSupply = 2e16;      
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Burn(address indexed burner, uint256 value);
    
    constructor (address issuingAddress) {
        // send the total supply to the issuing address for airdroping for v1 holders
        balances[issuingAddress] = totalSupply;
        emit Transfer(address(0), issuingAddress, totalSupply);
    }

    function balanceOf(address _owner) view external returns (uint256) {
        return balances[_owner];
    }

    // mitigates the BEP20 short address attack
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4, "input out of range");
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) external returns (bool) {
        
        require(_to != address(0), "invalid address");
        require(_amount <= balances[msg.sender], "insufficient balance");
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) external returns (bool) {

        require(_to != address(0), "invalid address");
        require(_amount <= balances[_from], "insufficient balance");
        require(_amount <= allowed[_from][msg.sender], "access denied");
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) external returns (bool) {
        // mitigates the BEP20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) view external returns (uint256) {
        return allowed[_owner][_spender];
    }

}