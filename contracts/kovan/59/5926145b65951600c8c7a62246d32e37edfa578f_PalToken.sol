pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./IERC20.sol";
import {Errors} from  "./Errors.sol";

/** @title palToken ERC20 contract  */
/// @author Paladin
contract PalToken is IERC20 {
    using SafeMath for uint;

    //ERC20 Variables & Mappings :

    /** @notice ERC20 token Name */
    string public name;
    /** @notice ERC20 token Symbol */
    string public symbol;
    /** @notice ERC20 token Decimals */
    uint public decimals;

    // ERC20 total Supply
    uint private _totalSupply;


    //don't want to initiate the contract twice
    bool private initialized;


    /** @notice PalPool contract that can Mint/Burn this token */
    address public palPool;


    /** @dev Balances for this ERC20 token */
    mapping(address => uint) internal balances;
    /** @dev Allowances for this ERC20 token, sorted by user */
    mapping(address => mapping (address => uint)) internal transferAllowances;


    /** @dev Modifier so only the PalPool linked to this contract can Mint/Burn tokens */
    modifier onlyPool() {
        require(msg.sender == palPool);

        _;
    }


    //Functions : 


    constructor (string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        decimals = 18;
        _totalSupply = 0;
        initialized = false;
    }


    function initiate(address _palPool) external returns (bool){
        require(!initialized);

        initialized = true;
        palPool = _palPool;

        return true;
    }


    function totalSupply() external override view returns (uint256){
        return _totalSupply;
    }


    function transfer(address dest, uint amount) external override returns(bool){
        return _transfer(msg.sender, dest, amount);
    }


    function transferFrom(address src, address dest, uint amount) external override returns(bool){
        require(transferAllowances[src][msg.sender] >= amount, Errors.ALLOWANCE_TOO_LOW);

        _transfer(src, dest, amount);

        transferAllowances[src][msg.sender] = transferAllowances[src][msg.sender].sub(amount);

        return true;
    }


    function _transfer(address src, address dest, uint amount) internal returns(bool){
        //Check if the transfer is possible
        require(balances[src] >= amount, Errors.BALANCE_TOO_LOW);
        require(dest != src, Errors.SELF_TRANSFER);
        require(src != address(0) && dest != address(0), Errors.ZERO_ADDRESS);

        //Update balances & allowance
        balances[src] = balances[src].sub(amount);
        balances[dest] = balances[dest].add(amount);

        //emit the Transfer Event
        emit Transfer(src,dest,amount);
        return true;
    }


    function approve(address spender, uint amount) external override returns(bool){
        address src = msg.sender;
        require(spender != address(0), Errors.ZERO_ADDRESS);

        //Update allowance and emit the Approval event
        transferAllowances[src][spender] = amount;

        emit Approval(src, spender, amount);

        return true;
    }


    function allowance(address owner, address spender) external view override returns(uint){
        return transferAllowances[owner][spender];
    }


    function balanceOf(address owner) external view override returns(uint){
        return balances[owner];
    }


    function mint(address _user, uint _toMint) external onlyPool returns(bool){
        require(_user != address(0), Errors.ZERO_ADDRESS);

        _totalSupply = _totalSupply.add(_toMint);
        balances[_user] = balances[_user].add(_toMint);

        emit Transfer(address(0),_user,_toMint);

        return true;
    }


    function burn(address _user, uint _toBurn) external onlyPool returns(bool){
        require(_user != address(0), Errors.ZERO_ADDRESS);
        require(balances[_user] >= _toBurn, Errors.INSUFFICIENT_BALANCE);

        _totalSupply = _totalSupply.sub(_toBurn);
        balances[_user] = balances[_user].sub(_toBurn);

        emit Transfer(_user,address(0),_toBurn);

        return true;
    }

}