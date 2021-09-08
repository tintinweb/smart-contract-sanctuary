/**
 *Submitted for verification at BscScan.com on 2021-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";

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
    function joinWhitelist(address _purchaser) public onlyOwner{
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

contract RoninSwap is Ownable, Whitelisted {
    using Address for address payable;
    
    event Swap(address indexed user, uint256 inAmount, uint256 owedAmount);
    event Claim(address indexed user, uint256 amount);
    event PayeeTransferred(address indexed previousPayee, address indexed newPayee);

    IERC20 public token;
    address public Payee;
    
    bool public isSwapStarted;
    bool public canClaim;

    uint256 public swapRate = 5_000_000; 
    uint256 public totalSold;
    
    uint256 public maxBuy = 2000000000000000000; // = 2 BNB 
   
    constructor (address _paymentWallet, IERC20 _token) {
        token = _token; 
        Payee = _paymentWallet;
        
    }
    
    mapping (address => uint256) public spent;
    mapping (address => uint256) public owed;

    function swap() public payable onlyWhitelisted{
        uint256 quota = token.balanceOf(address(this));
        uint256 outAmount = msg.value / swapRate;
    

        require(isSwapStarted == true, "RoninSwap::Swap not started");
        require(totalSold + outAmount <= quota, "RoninSwap::Quota not enough");
        require(spent[msg.sender] + msg.value <= maxBuy, "RoninSwap: :Reached Max Buy");
        totalSold += outAmount;

        payable(Payee).sendValue (msg.value);
        
        spent[msg.sender] = spent[msg.sender] + msg.value;
        
        owed[msg.sender] = owed[msg.sender] + outAmount;

        emit Swap(msg.sender, msg.value, outAmount);
    }

    function claim() public onlyWhitelisted{
        uint256 quota = token.balanceOf(address(this));

        require(canClaim == true, "RoninSwap::Swap not started");
        require(owed[msg.sender] <= quota, "RoninSwap::Quota not enough");

        uint256 amount = owed[msg.sender];
        owed[msg.sender] = 0;
        IERC20(token).transfer (msg.sender, amount);

        emit Claim(msg.sender, amount);
    }
    

    function startSwap() public onlyOwner returns (bool) {
        isSwapStarted = true;
        return true;
    }

    function stopSwap() public onlyOwner returns (bool) {
        isSwapStarted = false;
        return true;
    }

    function setClaim (bool _canClaim) public onlyOwner returns (bool) {
        canClaim = _canClaim;
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
        payable(owner()).sendValue (address(this).balance);
    }

    function WithdrawOtherTokens(address _token, uint256 amount) public onlyOwner {
        IERC20(_token).transfer(msg.sender, amount);
    }
}