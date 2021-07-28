/*
    SPDX-License-Identifier: Unlicensed
    
   Mooncheck Revolver

    The Revolver

    The revolver is a new token contract type being introduced soon on the BSC blockchain.
    It is unique in its function and will hopefully create an entirely new ecosystem of tokens within the growing BSC community.

    The unique feature of the revolver contract is its ability to rotate through an array of reward tokens.
    For a set amount of time the system will collect BNB until payout.
    When the payout time is reached it will acquire the new token and shoot it out to holders.

    The contract source code will be provided and updated free for use by future developers on Github.
*/

pragma solidity 0.8.6;

import "./SafeMath.sol";

/* 
    IBEP20 Interface 
    Provides interactivity to your contract
*/
interface IBEP20 {
    
    /* Account Balance */
    function balanceOf(address account) external view returns (uint256);
    
    /* Tokens Decimals */
    function decimals() external view returns (uint8);
    
    /* Tokens Owner */
    function getOwner() external view returns (address);
    
    /* Tokens Name */
    function name() external view returns(string memory);
    
    /* Tokens Supply */
    function symbol() external view returns (string memory);

    
    /* Tokens Supply */
    function totalSupply() external view returns (uint256);
    
    /* Transfer Tokens */
    function transfer(address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);


}


interface ITokenRevolver {
    /* Returns current token to be distributed */
    function activeToken() external view returns (address);
    
}


/* Strandard Context contract */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}



/* */
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /* Constructor */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function owner() public view returns (address) {
        return _owner;    
    }
    
}


/* Contract that holds the logic to revolve tokens and shoot them out */
contract TokenRevolver is ITokenRevolver {
    using SafeMath for uint256;
    
    address currentToken;
    address tokenOne;
    address tokenTwo;
    address tokenThree;
    address tokenFour;
    address tokenFive;
    address tokenSix;
    
    
    
    constructor(){
        //Cake
        
        address[6] memory tokenList = 
        [0xe5F10d3A7fAF9cC6833f9a601D6539694B96B4E8,
        0xe5F10d3A7fAF9cC6833f9a601D6539694B96B4E8,
        0xe5F10d3A7fAF9cC6833f9a601D6539694B96B4E8,
        0xe5F10d3A7fAF9cC6833f9a601D6539694B96B4E8,
        0xe5F10d3A7fAF9cC6833f9a601D6539694B96B4E8,
        0xe5F10d3A7fAF9cC6833f9a601D6539694B96B4E8];
        
        
        tokenOne = tokenList[0];
        
        tokenTwo = tokenList[1];
        
        tokenThree = tokenList[2];
        
        tokenFour = tokenList[3];
        
        tokenFive = tokenList[4];
        
        tokenSix = tokenList[5];
        
        currentToken = tokenOne;
        
        
    }
    
    
    function activeToken() override external view returns (address) {
        return currentToken;
    }
    
}



/* 
    Main revolver contract
    This provides your tokens primary functionality
*/
contract Revolver is Context, IBEP20, Ownable, TokenRevolver {
    /* Use safemath */
    using SafeMath for uint256;

    
    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;

    uint8 private _decimals;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    
    constructor() {
        _name = "Revolver 0.0.0";
        _symbol = "NO";
        _decimals = 8;
        _totalSupply = 100000000000000000000; // 1T
        _balances[msg.sender] = _totalSupply;
        
        
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function decimals() override public view returns (uint8){
        return _decimals;
    }

    function name() override public view returns(string memory) {
        return _name;
    }

    function getOwner() override external view returns (address) {
        return owner();
    }

    function symbol() override public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() override public view returns (uint256){
        return _totalSupply;
    }
        
    function transfer(address recipient, uint256 amount) override external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function _transfer( address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "B20: Xfer from 0");
        require(recipient != address(0), "B20: Xfer from 0");
        
        _balances[sender] = _balances[sender].sub(amount, "B20:Xfer Exceeds Bal");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
        
}