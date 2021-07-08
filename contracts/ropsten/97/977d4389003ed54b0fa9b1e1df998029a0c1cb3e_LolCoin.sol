/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract ERC20 {
    function totalSupply() virtual public view returns (uint supply) {}

    function balanceOf(address owner) virtual public view returns (uint balance) {}

    function transfer(address to, uint value) virtual public {}

    function transferFrom(address from, address to, uint value) virtual public {}

    function approve(address spender, uint value) virtual public {}

    function allowance(address owner, address spender) virtual public view returns (uint remaining) {}

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract LolCoin is ERC20 {
    using SafeMath for uint;

    string public name = "LOL Coin";
    string public symbol = "LOL";
    uint public decimals = 18;

    uint _totalSupply;
    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowed;

    function totalSupply() override public view returns (uint supply) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the the balance of.
    * @return balance An uint representing the amount owned by the passed address.
    */
    function balanceOf(address owner) override public view returns (uint balance) {
        return _balances[owner];
    }

    /**
    * @dev transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint value) override public {
        require(_balances[msg.sender] >= value, "Sender balance insufficient");

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(msg.sender, to, value);
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint the amount of tokens to be transferred
    */
    function transferFrom(address from, address to, uint value) override public {
        uint allowedAmount = allowance(from, msg.sender);
        require(allowedAmount >= value, "Exceed allowance");

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(from, to, value);
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
    function approve(address spender, uint value) override public {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((value != 0) && (_allowed[msg.sender][spender] != 0)), "Must reset to 0 to update existing allowance.");
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    /**
    * @dev Function to check the amount of tokens than an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return remaining A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address owner, address spender) override public view returns (uint remaining) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Function to mint the token
    * @param minted address the token is minted to.
    * @param value amount of token minted.
    */
    function showMeTheMoney(address minted, uint value) public {
        _totalSupply.add(value);
        _balances[minted].add(value);
        emit Transfer(address(0), minted, value);
    }
}