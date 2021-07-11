/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}


contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "ERC20: sending to the zero address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}


contract MNVPresaleFinale is Owned{
    IERC20Token public tokenContract;  // the token being sold
    uint256 public price = 60000000000000;              
    uint256 public decimals = 9;

    uint256 public tokensSold;
    uint256 public BNBRaised;
    uint256 public MaxBNBAmount;

    uint256 public maxPerWallet = 12000000000000; //2bnb; 4T max tokens purchase per wallet
    bool public PresaleStarted = true;

    address[] internal buyers;
    mapping (address => uint256) public _balances;

    event Sold(address buyer, uint256 amount);
    event DistributedTokens(uint256 tokensSold);

    constructor(IERC20Token _tokenContract, uint256 _maxBNBAmount) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        MaxBNBAmount = _maxBNBAmount;
    }

    fallback() external payable {
        buyTokensWithBNB(msg.sender);
    }

    receive() external payable{ buyTokensWithBNB(msg.sender); }

    // Guards against integer overflows
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function setPrice(uint256 price_) external onlyOwner{
        price = price_;
    }

    function isBuyer(address _address)
        public
        view
        returns (bool)
    {
        for (uint256 s = 0; s < buyers.length; s += 1) {
            if (_address == buyers[s]) return (true);
        }
        return (false);
    }

    function addbuyer(address _buyer, uint256 _amount) internal {
        bool _isbuyer = isBuyer(_buyer);
        if (!_isbuyer) buyers.push(_buyer);

        _balances[_buyer] = add(_balances[_buyer], _amount);
    }

    function togglePresale() public onlyOwner{
        PresaleStarted = PresaleStarted;
    }

    function changeToken(IERC20Token newToken) external onlyOwner{
        tokenContract = newToken;
    }


    function buyTokensWithBNB(address _receiver) public payable {
        require(PresaleStarted, "Presale not started yet!");
        uint _amount = msg.value;
        require(_receiver != address(0), "PreSale of MNV");
        require(_amount > 0, "Can't buy with 0 BNB");
        uint256 newAmount = add(_balances[msg.sender], _amount);
        require(newAmount <= maxPerWallet, "Error: Max Allowed per wallet limit ");
        require(owner.send(msg.value), "Unable to transfer BNB to owner");
        BNBRaised += _amount;
        addbuyer(msg.sender, _amount);

    }

    function endSale() public {
        require(msg.sender == owner);
        // Send unsold tokens to the owner.
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));
        msg.sender.transfer(address(this).balance);
    }
}