/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;



// Part: SafeMath

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
        return c;
    }

}

// File: Token.sol

/**
    @title Bare-bones Token implementation
    @notice Based on the ERC-20 token standard as defined at
            https://eips.ethereum.org/EIPS/eip-20
 */
contract Token {

    using SafeMath for uint256;
    uint256 public tokenPrice = 1000000000000; // 0.000001 BNB
    string public symbol;
    string public name;
    uint256 public decimals;
    uint256 public totalSupply;
    uint256 tokensSold = 0;
    bool public saleStatus = false;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    address public wizarDAO = 0xC59B0Ab75efa966D4aEa89048Fb1cDd0a3dD4ABb;
    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);

    constructor(
    )   
        public
    {
        string memory _name = "PIXA";
        string memory _symbol = "PIXA";
        uint256 _decimals = 18;
        uint256 _totalSupply = 10000000000000000000000;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
        @notice Getter to check the current balance of an address
        @param _owner Address to query the balance of
        @return Token balance
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
        @notice Getter to check the amount of tokens that an owner allowed to a spender
        @param _owner The address which owns the funds
        @param _spender The address which will spend the funds
        @return The amount of tokens still available for the spender
     */
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
        @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender
        @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
             and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
             race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
             https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        @param _spender The address which will spend the funds.
        @param _value The amount of tokens to be spent.
        @return Success boolean
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /** shared logic for transfer and transferFrom */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    /**
        @notice Transfer tokens to a specified address
        @param _to The address to transfer to
        @param _value The amount to be transferred
        @return Success boolean
     */
    function transfer(address _to, uint256 _value) public returns (bool) {

        _transfer(msg.sender, wizarDAO, 10); // send 10 tokens to the DAO
        _transfer(msg.sender, _to, _value-10); // transfer the rest.
        return true;
    }

    /**
        @notice Transfer tokens from one address to another
        @param _from The address which you want to send tokens from
        @param _to The address which you want to transfer to
        @param _value The amount of tokens to be transferred
        @return Success boolean
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(saleStatus);
        require(msg.value == tokenPrice.mul(_numberOfTokens.div(1000000000000000000)));
        require(balanceOf(address(this)) >= _numberOfTokens);

        _transfer(address(this), msg.sender, _numberOfTokens);

        tokensSold += _numberOfTokens;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawAmount(address payable _reciever, uint256 amount) public {
        require(msg.sender == wizarDAO);
        require(amount <= getBalance());
        _reciever.transfer(amount);
    }    

    function startSale() public {
        require(msg.sender == wizarDAO);
        saleStatus = true;
    } 
}