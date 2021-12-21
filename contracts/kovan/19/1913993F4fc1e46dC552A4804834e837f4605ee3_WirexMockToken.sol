pragma solidity 0.7.6;

// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./IERC20.sol";

contract WirexMockToken is IERC20 {

    using SafeMath for uint256;

    string public constant symbol = "WXT";
    string public constant name = "WIREX Protocol Mock Token";
    uint256 public constant decimals = 18;
    uint256 public override totalSupply;
    uint256 public immutable maxTotalSupply;
    address public minter;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(uint256 _maxTotalSupply) {
        maxTotalSupply = _maxTotalSupply;
        emit Transfer(address(0), msg.sender, 0);
    }

    function setMinter(address _minter) external returns (bool) {
        require(minter == address(0));
        minter = _minter;
        return true;
    }

    function approve(address _spender, uint256 _value) external override returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /** shared logic for transfer and transferFrom */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    /**
        @notice Transfer tokens to a specified address
        @param _to The address to transfer to
        @param _value The amount to be transferred
        @return Success boolean
     */
    function transfer(address _to, uint256 _value) public override returns (bool) {
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
        override
        returns (bool)
    {
        uint256 allowed = allowance[_from][msg.sender];
        require(allowed >= _value, "Insufficient allowance");
        if (allowed != uint(-1)) {
            allowance[_from][msg.sender] = allowed.sub(_value);
        }
        _transfer(_from, _to, _value);
        return true;
    }

    function mint(address _to, uint256 _value) external returns (bool) {
        require(msg.sender == minter);
        balanceOf[_to] = balanceOf[_to].add(_value);
        totalSupply = totalSupply.add(_value);
        require(maxTotalSupply >= totalSupply);
        emit Transfer(address(0), _to, _value);
        return true;
    }

}