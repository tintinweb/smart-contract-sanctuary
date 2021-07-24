/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract StandardToken {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
}

contract AirDrop {

    using SafeMath for uint;

    function () payable public {}

    /**
     * batch transfer for ERC20 token.(the same amount)
     *
     * @param _contractAddress ERC20 token address
     * @param _addresses array of address to sent
     * @param _value transfer amount
     */
    function batchTransferToken(address _contractAddress, address[] _addresses, uint _value) public {
        // data validate & _addresses length limit
        require(_addresses.length > 0);

        StandardToken token = StandardToken(_contractAddress);
        // transfer circularly
        for (uint i = 0; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _value);
        }
    }

    /**
     * batch transfer for ERC20 token.
     *
     * @param _contractAddress ERC20 token address
     * @param _addresses array of address to sent
     * @param _value array of transfer amount
     */
    function batchTransferToken(address _contractAddress, address[] _addresses, uint[] _value) public {
        // data validate & _addresses length limit
        require(_addresses.length > 0);
        require(_addresses.length == _value.length);

        StandardToken token = StandardToken(_contractAddress);
        // transfer circularly
        for (uint i = 0; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _value[i]);
        }
    }

    /**
     * batch transfer for ETH.(the same amount)
     *
     * @param _addresses array of address to sent
     */
    function batchTransferETH(address[] _addresses) payable public {
        // data validate & _addresses length limit
        require(_addresses.length > 0);

        // transfer circularly
        for (uint i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(msg.value.div(_addresses.length));
        }
    }

    /**
     * batch transfer for ETH.
     *
     * @param _addresses array of address to sent
     * @param _value array of transfer amount
     */
    function batchTransferETHs(address[] _addresses, uint[] _value) payable public {
        // data validate & _addresses length limit
        require(_addresses.length > 0);
        require(_addresses.length == _value.length);

        // transfer circularly
        for (uint i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(_value[i]);
        }
    }
}