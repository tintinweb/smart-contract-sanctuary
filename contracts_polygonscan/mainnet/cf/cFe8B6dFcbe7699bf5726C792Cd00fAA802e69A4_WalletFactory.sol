/**
 *Submitted for verification at polygonscan.com on 2021-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface HourglassInterface {
    function deposit(address _playerAddress) payable external returns(uint256);
    function withdraw(uint256 _amountOfTokens) external;
    function compound() external;
    function harvest() external;
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function balanceOf(address _customerAddress) view external returns(uint256);
    function myDividends(bool _includeReferralBonus) external view returns(uint256);
}

contract WalletFactory {
    
    /////////////////////////////////
    // CONFIGURABLES AND VARIABLES //
    /////////////////////////////////
    
    address hourglassAddress;
    
    /////////////////////
    // CONTRACT EVENTS //
    /////////////////////
    
    event onCreateWallet(address indexed owner, address indexed strongHand);
    
    //////////////
    // MAPPINGS //
    //////////////
    
    mapping (address => address) public strongHands;
    
    //////////////////////////////
    // CONSTRUCTOR AND FALLBACK //
    //////////////////////////////
    
    constructor (address _hourglassAddress) public {
        hourglassAddress = _hourglassAddress;
    }
    
    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////
    
    function hasWallet() public view returns (bool) {
        return strongHands[msg.sender] != address(0);
    }
    
    function myWallet() external view returns (address) {  
        require(hasWallet(), "You do not have a PolyGlass Wallet!");
        return strongHands[msg.sender];
    }
    
    /////////////////////
    // WRITE FUNCTIONS //
    /////////////////////
    
    function create() public {
        require(!hasWallet(), "You already have a PolyGlass Wallet!");
        
        address payable owner = msg.sender;
        strongHands[owner] = address(new PolyGlassWallet(owner, hourglassAddress));
        emit onCreateWallet(owner, strongHands[owner]);
    }
}

contract PolyGlassWallet {
    HourglassInterface Hourglass;
    
    /////////////////////////////////
    // CONFIGURABLES AND VARIABLES //
    /////////////////////////////////
    
    address payable public owner;
    
    ///////////////
    // MODIFIERS //
    ///////////////
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    //////////////////////////////
    // CONSTRUCTOR AND FALLBACK //
    //////////////////////////////
    
    constructor(address payable _owner, address _hourglassAddress) public {
        owner = _owner;
        
        Hourglass = HourglassInterface(_hourglassAddress);
    }
    
    receive() external payable {
        
    }
    
    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////
    
    function balanceOf() external view returns(uint256) {
        return Hourglass.balanceOf(address(this));
    }
        
    function dividendsOf() external view returns(uint256) {
        return Hourglass.myDividends(true);
    }
    
    /////////////////////
    // WRITE FUNCTIONS //
    /////////////////////
    
    function deposit() external payable onlyOwner {
        Hourglass.deposit{value: msg.value}(owner);
    }
    
    function withdraw(uint256 _amount) external onlyOwner {
        Hourglass.withdraw(_amount);
        owner.transfer(address(this).balance);
    }
    
    function compound() external onlyOwner {
        Hourglass.compound();
    }
    
    function harvest() external onlyOwner {
        Hourglass.harvest();
        owner.transfer(address(this).balance);
    }
    
    function collect() external onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    function sweep() external onlyOwner {
        Hourglass.deposit{value: address(this).balance}(owner);
    }
    
    function transfer(address _recipient, uint256 _amount) external onlyOwner returns(bool) {
        return Hourglass.transfer(_recipient, _amount);
    }
}