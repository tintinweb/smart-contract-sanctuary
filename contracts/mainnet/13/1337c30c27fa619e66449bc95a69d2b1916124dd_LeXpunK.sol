/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

pragma solidity 0.8.3;

// SPDX-License-Identifier: MIT

/**
    @title LeXpunk Social Token
    @notice https://www.lexpunk.army/
 */
contract LeXpunK {

    string public constant name = "LeXpunK Social Token";
    string public constant symbol = "L3X";
    uint256 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public owner;
    address public minter;

    bool public isMintable;
    bool public isPaused;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(
        address _owner,
        address _minter
    ) public {
        owner = _owner;
        minter = _minter;

        // tokens are mintable in the initial state
        isMintable = true;
        // tokens are NOT transferable in the initial state
        isPaused = true;

        emit Transfer(address(0), msg.sender, 0);
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
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
        @notice Approve an address to spend tokens on behalf of the caller
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
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(balances[_from] >= _value, "Insufficient balance");
        require(!isPaused, "Transfers are paused");
        balances[_from] -= _value;
        balances[_to] += _value;
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
    ) public returns (bool) {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        if (allowed[_from][msg.sender] != type(uint256).max) {
            allowed[_from][msg.sender] -= _value;
        }
        _transfer(_from, _to, _value);
        return true;
    }

    function mint(address _to, uint256 _value) external returns (bool) {
        require(msg.sender == minter || msg.sender == owner, "Not permitted");
        require(isMintable, "Minting disabled");
        totalSupply += _value;
        balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function setIsMintable(bool _isMintable) external onlyOwner {
        isMintable = _isMintable;
    }

    function setIsPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }
}