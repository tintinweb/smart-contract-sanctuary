/**
 *Submitted for verification at Etherscan.io on 2020-12-16
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
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


contract TokenSale is Owned{
    IERC20Token public tokenContract;  // the token being sold
    uint256 public price = 500;              // 1eth = 500 tokens
    uint256 public decimals = 18;
    
    uint256 public tokensSold;
    uint256 public ethRaised;
    uint256 public MaxETHAmount;

    event Sold(address buyer, uint256 amount);

    constructor(IERC20Token _tokenContract, uint256 _maxEthAmount) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        MaxETHAmount = _maxEthAmount;
    }
    
    fallback() external payable {
        buyTokensWithETH(msg.sender);
    }

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
    
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    
    function setPrice(uint256 price_) external onlyOwner{
        price = price_;
    }


    function buyTokensWithETH(address _receiver) public payable {
        require(ethRaised < MaxETHAmount, "Presale finished");
        uint _amount = msg.value; 
        require(_receiver != address(0), "Can't send to 0x00 address"); 
        require(_amount > 0, "Can't buy with 0 eth"); 
        
        uint tokensToBuy = multiply(_amount, price);
        require(owner.send(_amount), "Unable to transfer eth to owner");
        require(tokenContract.transfer(_receiver, tokensToBuy), "Unable to transfer token to user"); 
        tokensSold += tokensToBuy; 
        ethRaised += _amount;
        
        emit Sold(msg.sender, tokensToBuy);
    }

    

    function endSale() public {
        require(msg.sender == owner);

        // Send unsold tokens to the owner.
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));

        msg.sender.transfer(address(this).balance);
    }
}