pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./Ownable.sol";

/**
    @title Bare-bones Token implementation
    @notice Based on the ERC-20 token standard as defined at
            https://eips.ethereum.org/EIPS/eip-20
 */
contract BBCToken is Ownable {

    string public symbol = "BBC";
    string public name = "Big Black Token";
    uint256 public decimals = 18;
    uint256 public totalSupply;
    uint256 public remainingMintable;
    bool public isRecoverable = false;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);
    event Mint(address to, uint256 value);

    uint256 private ETH_MULTIPLIER = 1000000; // 1,000,000

    constructor(
        uint256 _totalSupply
    ) {
        require(_totalSupply % 10 == 0, "BBC: Totaly supply not multiple of 10");

        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply / 5;
        remainingMintable = _totalSupply - _totalSupply / 5;
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
        balances[_from] = balances[_from] - (_value);
        balances[_to] = balances[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }

    /**
        @notice Transfer tokens to a specified address
        @param _to The address to transfer to
        @param _value The amount to be transferred
        @return Success boolean
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
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
        require(allowed[_from][msg.sender] >= _value, "BBC: Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
        @notice Purchase tokens with ETH
        @param _to The address which receives funds
    */
    function purchase(address _to) public payable {
        require(msg.value > 0, "BBC: Require ETH payment");
        require(remainingMintable > 0, "BBC: Nothing left to purchase");

        uint256 mintAmount = msg.value * ETH_MULTIPLIER;

        // Handle case where we attempt to mint more than remainingMintable
        uint256 refundAmount = 0;
        if (mintAmount > remainingMintable) {
            mintAmount = remainingMintable;
            refundAmount = msg.value - mintAmount / ETH_MULTIPLIER;
        }

        // Set address to receive funds
        address to = _to;
        if (to == address(0)) {
            to = msg.sender;
        }
        balances[to] = balances[to] + mintAmount;

        // Refund user is required
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }

        emit Transfer(address(0), to, mintAmount);
        emit Mint(to, mintAmount);
    }

    /**
        @notice Allows tokens to be recovered (this is irreversible)
    */
    function setRecoverable() public onlyOwner {
        isRecoverable = true;
    }

    /**
        @notice Recover tokens after a project has come to completion
        @param _to User to recieve tokens (if zero balance sent to msg.sender)
    */
    function recoverTokens(address payable _to) public {
        uint256 adjustedBalance = balances[msg.sender] / ETH_MULTIPLIER;
        require(adjustedBalance > 0, "BBC: Insufficient Balance");

        balances[msg.sender] = 0;

        if (_to == address(0)) {
            payable(msg.sender).transfer(adjustedBalance);
        } else {
            _to.transfer(adjustedBalance);
        }
    }
}