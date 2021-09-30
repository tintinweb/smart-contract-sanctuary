pragma solidity 0.6.0;

import "./deps.sol";

contract AhabToken is IERC20, Ownable {
    using SafeMath for uint256;

    string public constant name = "Ahab Token";
    string public constant symbol = "AHAB";
    uint8 public constant decimals = 18;
    uint256 totalSupply_;
    uint256 buyFee;
    uint256 sellFee;
    uint256 transferFee;
    address devWallet = 0x7126e0e4Afa96f699251bD1f74Cd570E0F51E624;
    address payable public adminAddr;

    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => bool) private isExcludedFromTaxes;
    
    constructor(uint256 bFee, uint256 sFee, uint256 tFee) public {
        adminAddr = msg.sender;
        buyFee = bFee;
        sellFee = sFee;
        transferFee = tFee;
    }
     /////////////
    //IERC20 METHODS
    /////////////

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        return _transferFrom(msg.sender, receiver, numTokens);
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        return _transferFrom(owner, buyer, numTokens);
    }
    
    
    /////////////
    //CUSTOM METHODS
    /////////////
    
    function _transferFrom(address fromAddr, address toAddr, uint256 tokens) private returns(bool) {
        
        require(fromAddr != address(0), "Sender must be valorized");
        require(tokens>0, "Amount of tokens sended must be grater than 0");
        //implement better logic on taxes 
        balances[fromAddr] = balances[fromAddr].sub(tokens, "The number of token transfered must be grater than the sender balance");
        balances[toAddr] = balances[toAddr].add(tokens);
        
        emit Transfer(fromAddr, toAddr, tokens);
        return true;
    }
    
    function _mint(address reciver, uint256 amount) private {
        balances[reciver].add(amount);
        totalSupply_.add(amount);
        emit Mint(reciver, amount);
    }
    
    function _unmint(uint256 amount) private {
        totalSupply_.sub(amount, "The amount of tokens is greater than total supply");
        emit Unmint(amount);
    }
    
    
    //////////////
    //GETTER/SETTER
    //////////////
    
    function getPrice() public returns(uint256) {
        return address(this).balance/totalSupply_;
    }
    
    function getFees() private returns(uint256, uint256, uint256) {
        return(buyFee, sellFee, transferFee);
    }
    
    //////////////
    //EVENTS
    //////////////
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Mint(address indexed to, uint tokens);
    event Unmint(uint tokens);
}