pragma solidity ^0.4.18;

/**
* Checklist
* 1. Transfer (ok)
* 2. Owner terbuat ketika deploy token (ok)
* 3. Bisa transfer owner?
*/

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract NtzToken {

    // library
    using SafeMath for uint256;

    // informasi public
    string  public symbol;
    string  public name;
    uint8   public decimals;
    uint256 public totalSupply;

    // pemilik token
    address public owner;

    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor () public {
        name        = &#39;NtzToken&#39;;
        symbol      = &#39;NTZ&#39;;
        decimals    = 18;
        totalSupply = 1000000000 * 10 ** uint256(decimals);

        owner                 = msg.sender;
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
    }

    function transferOwnership(address _newOwner) public returns (bool success) {
        require(msg.sender == owner);
        owner = _newOwner;
        return true;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {

        // Cegah pengiriman kepada address 0x0. Sebaiknya gunakan fungsi burn jika ingin membuang token
        require(_to != 0x0);

        // Check if the sender has enough
        require(balanceOf[_from] >= _value);

        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);

        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);

        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Fungsi standard Token ERC20
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
}