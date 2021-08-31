/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b);
        // There is no case in which this doesn't hold
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

contract Ownable {
    address payable owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function balanceOf(address _owner) external returns (uint256 balance);
    
    function approve(address spender, uint value) external returns (bool);

}



contract Whitelisted is Ownable {
    mapping(address => bool) public whitelist;
    mapping(address => bool) public provider;
  

    // Only whitelisted
    modifier onlyWhitelisted {
        require(isWhitelisted(msg.sender));
        _;
    }
  
    modifier onlyProvider {
        require(isProvider(msg.sender));
        _;
    }

    function isProvider(address _provider) public view returns (bool){
        return provider[_provider] == true ? true : false;
    }
    // Set new provider
    function setProvider(address _provider) public onlyOwner {
        provider[_provider] = true;
    }
    // Deactivate current provider
    function deactivateProvider(address _provider) public onlyOwner {
        require(provider[_provider] == true);
        provider[_provider] = false;
    }
    // Set purchaser to whitelist with zone code
    function joinWhitelist(address _purchaser) public {
        whitelist[_purchaser] = true;
    }
    
    function whitelistAddresses (address[] memory _purchaser) public onlyOwner {
        for (uint i = 0; i < _purchaser.length; i++) {
            whitelist[_purchaser[i]] = true;
        }
    }
    
    // Delete purchaser from whitelist
    function deleteFromWhitelist(address _purchaser) public onlyOwner {
        whitelist[_purchaser] = false;
    }
   
    // Check if purchaser is whitelisted : return true or false
    function isWhitelisted(address _purchaser) public view returns (bool){
        return whitelist[_purchaser] == true ? true : false;
    }
}

contract DonkSwap is Ownable, Whitelisted {
    using SafeMath for uint256;

    event Swap(address indexed user, uint256 inAmount, uint256 outAmount);
    event PayeeTransferred(address indexed previousPayee, address indexed newPayee);

    ERC20 public token0;
    ERC20 public token1;
    address public Payee;
    
    bool public isSwapStarted = false;

      //Rate is InToken*1000/swapRate = OutToken
    uint256 public swapRate = 990; 
    
    uint256 public maxBuy = 400000000000000000000000000000000; // = 400 eth
   
    constructor(
        address payable _owner,
        address _paymentWallet,
        ERC20 _inToken,
        ERC20 _outToken
    ) public {
        token0 = _inToken; 
        token1 = _outToken;
        owner = _owner;
        Payee = _paymentWallet;
        
    }
    
    mapping (address => uint256) public spent;

    function swap(uint256 inAmount) public onlyWhitelisted{
        uint256 quota = token1.balanceOf(address(this));
        uint256 total = token0.balanceOf(msg.sender);
        uint256 outAmount = inAmount.mul(1000).div(swapRate);
    

        require(isSwapStarted == true, 'Swap not started');
        require(inAmount <= total, "Insufficient funds");
        require(outAmount <= quota, "Quota not enough");
        require(spent[msg.sender].add(inAmount) <= maxBuy, "Reached Max Buy");

        token0.transferFrom(msg.sender, address(Payee), inAmount);
        
        spent[msg.sender] = spent[msg.sender] + inAmount;
        
        token1.transfer(msg.sender, outAmount);

        emit Swap(msg.sender, inAmount, outAmount);
    }
    

    function startSwap() public onlyOwner returns (bool) {
        isSwapStarted = true;
        return true;
    }

    function stopSwap() public onlyOwner returns (bool) {
        isSwapStarted = false;
        return true;
    }

    function setSwapRate(uint256 newRate) public onlyOwner returns (bool) {
        swapRate = newRate;
        return true;
    }
    
    function setMaxBuy(uint256 newMax) public onlyOwner returns (bool) {
        maxBuy = newMax;
        return true;
    }
    
    function transferPayee(address newPayee) public onlyOwner {
        require(newPayee != address(0));
        emit PayeeTransferred(Payee, newPayee);
        Payee = newPayee;
    }
    

    function recoverLostBNB() public onlyOwner {
        address payable _owner = msg.sender;
        _owner.transfer(address(this).balance);
    }

    
    function WithdrawToken(address _token, uint256 amount) public onlyOwner {
        ERC20(_token).transfer(msg.sender, amount);
    }

   
}