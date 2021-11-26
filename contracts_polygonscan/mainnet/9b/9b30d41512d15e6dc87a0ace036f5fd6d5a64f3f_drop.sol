/**
 *Submitted for verification at polygonscan.com on 2021-11-25
*/

// SPDX-License-Identifier: MIT

/*
A contract of
   ____     __     __    _____    _____  
  (    )   (_ \   / _)  (_   _)  / ___/  
  / /\ \     \ \_/ /      | |   ( (__    
 ( (__) )     \   /       | |    ) __)   
  )    (      / _ \       | |   ( (      
 /  /\  \   _/ / \ \_    _| |__  \ \___  
/__(  )__\ (__/   \__)  /_____(   \____\ 
                                  Origin

Drop Contract for lab

www.axieorigin.com
docs.axieorigin.com
[email protected]

Axie Origin Foundation                
*/

pragma solidity 0.8.9;



/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 */
 library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}  

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Provide basic functionality for integration with the core contract
 */
interface Origin {
    function birthAxie(address _to, uint256 _dna, uint256 _bornAt, uint256) external returns (uint256);      
}


abstract contract SysCtrl is Context {

  address communityAdmin;
  bool public sellPaused = false;

  constructor() {
      communityAdmin = _msgSender();
  }

  modifier onlyAdmin() {
    require(_msgSender() == communityAdmin, "Only for admin community");
    _;
  }

  function sAdmin(address _new) public onlyAdmin {
    communityAdmin = _new;
  }

  function sellMarket(bool _paused) external onlyAdmin {
        sellPaused = _paused;
  }
}

contract drop is SysCtrl{

    using SafeMath for uint256;

    event AxieEgg1(uint256 indexed axieId, address indexed owner, uint256 level, uint256 price);
    event AxieEgg3(uint256 indexed axieId1, uint256 axieId2, uint256 axieId3, address indexed owner, uint256 level, uint256 price);
    event AxieFree(uint256 indexed axieId, address indexed owner, uint256 level, uint256 dificult);

    address internal core;
    uint256 internal nonce = 0;

    uint256 currentLevel = 1;
    uint256 maxforLevel = 1000;
    uint256 manufacturedLevel = 0; 
    uint256 morphingTime = (21*24*60*60);  // Auto morphing in 21 days 
    uint256 price1Egg = 1.000 ether;       // Initial price per 1 egg
    uint256 price3Egg = 2.500 ether;       // Initial price per 3 eggs

    uint256 availableFree = 0; 
    uint256 intervalFree = (24*60*60);     // time for try free again, 24 hours
    uint256 dificultFree = 100;            // Mint dificult for free
   
    mapping(address => uint256) public usersFree;

    bool private reentrancyLock = false;
    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor(address _core) {
        core = _core;
    }
    
    function get1Egg() external payable reentrancyGuard returns(uint256)  {
        require(!sellPaused);
        require(maxforLevel > manufacturedLevel);
        require(msg.value >= price1Egg,"Value less than the minimum required");
        manufacturedLevel++;
        uint256 _axieId = _getAxieEgg();
        emit AxieEgg1(_axieId, msg.sender, currentLevel, msg.value);
        return _axieId;
    }

    function get3Egg() external payable reentrancyGuard returns(uint256 _axie1, uint256 _axie2, uint256 _axie3)  {
        require(!sellPaused);
        require(maxforLevel > (manufacturedLevel.add(2)));
        require(msg.value >= price3Egg,"Value less than the minimum required");
        manufacturedLevel = manufacturedLevel.add(3);
        _axie1 = _getAxieEgg();
        _axie2 = _getAxieEgg();
        _axie3 = _getAxieEgg();
        emit AxieEgg3(_axie1,_axie2,_axie3, msg.sender, currentLevel, msg.value);
    }

    function MintFree() external payable reentrancyGuard returns(uint256 _axieFree) {
        require(!sellPaused);
        require(maxforLevel > manufacturedLevel && availableFree > 0,"There are no axies available");
        require(usersFree[msg.sender]+intervalFree <= block.timestamp,"Ineligible address, wait time");
        _axieFree = 0;
        if(_exons(block.difficulty,dificultFree) == 0){
          manufacturedLevel++;
          availableFree--;
          _axieFree = _getAxieEgg();
          emit AxieFree(_axieFree, msg.sender, currentLevel, dificultFree);
        } 
        usersFree[msg.sender] = block.timestamp;
        nonce++;
    }

    function getStats() external view returns(
        uint256 _currentLevel, 
        uint256 _maxforLevel, 
        uint256 _manufacturedLevel,
        uint256 _morphingTime, 
        uint256 _price1Egg,
        uint256 _price3Egg,
        uint256 _availableFree, 
        uint256 _intervalFree,
        uint256 _dificultFree
    ){
        _currentLevel = currentLevel;
        _maxforLevel = maxforLevel;
        _manufacturedLevel = manufacturedLevel;
        _morphingTime = morphingTime;
        _price1Egg = price1Egg;
        _price3Egg = price3Egg;
        _availableFree = availableFree;
        _intervalFree = intervalFree;
        _dificultFree = dificultFree;
    }
    
    function config(uint256 _currentLevel, uint256 _maxforLevel, uint256 _manufacturedLevel, uint256 _morphingTime, uint256 _price1Egg, uint256 _price3Egg) external onlyAdmin  {
       if(_currentLevel >0) currentLevel = _currentLevel;
       if(_maxforLevel >0) maxforLevel = _maxforLevel;
       if(_manufacturedLevel >0) manufacturedLevel = _manufacturedLevel;
       if(_morphingTime >0) morphingTime = _morphingTime;
       if(_price1Egg >0) price1Egg = _price1Egg;
       if(_price3Egg >0) price3Egg = _price3Egg;
    }

    function configFree(uint256 _availableFree, uint256 _intervalFree, uint256 _dificultFree) external onlyAdmin  {
       availableFree = _availableFree;
       if(_intervalFree >0) intervalFree = _intervalFree;
       if(_dificultFree >0) dificultFree = _dificultFree;
    }
    
    function rescue(address payable to_, uint256 amount_) external onlyAdmin  {
        require(to_ != address(0), "Invalid Address");
        require(amount_ > 0, "Invalid Amount");
        to_.transfer(amount_);
    }
    
    function _getAxieEgg() internal returns (uint256) {
        
        uint256 bornAt = block.timestamp + morphingTime; 
        address to = msg.sender;
        uint256 dna;
        uint256 genes;
        
        for(uint256 helix=0; helix<=42; helix++){
            genes = 0;
            
            if(helix <= 2){                            
               genes = _exons(helix,10);
               if(genes > 1){
                   genes = 0;
               }
            }
            
            if(helix >= 3 && helix <= 11){            
               genes = _exons(helix,15);
               if(genes > 3 && genes < 13){
                   genes = 0;
               }
               if(genes >= 13) {
                   genes = 1;
               }
            }
            
            if(helix >= 6 && helix <= 11){            
               genes = _exons(helix,10);
               if(genes > 3 && genes < 8){
                   genes = 0;
               } 
               if(genes >= 8) {
                   genes = 1;
               }
            }
            
            if(helix >= 12 && helix <= 23){            
               genes = _exons(helix,13);
               
               if(genes > 5 && genes < 10){
                   genes = 0;
               } 
               if(genes >= 10 ) {
                   genes = 1;
               }
            }
            
            if(helix >= 24){               
               genes = _exons(helix,48);
               
               if(genes > 5 && genes <= 17){  
                   genes = 0;
               } 
               if(genes > 17 && genes <= 27) { 
                   genes = 2;
               }
               if(genes > 27 && genes <= 29) { 
                   genes = 3;
               }
               if(genes > 29 && genes <= 32) { 
                   genes = 4;
               }
               if(genes > 32) { // Plant
                   genes = 5;
               }
            }
            
            dna = helix == 0 ? dna = uint256(genes) : dna |= uint256(genes)<<4*helix;

        }
        nonce++;
        return Origin(core).birthAxie(to,dna,bornAt,0);
    }

    function _exons(uint256 _helix, uint256 _endgen) internal view returns(uint256) {
       uint256 index = uint(keccak256(abi.encodePacked(_helix, nonce, msg.sender, block.difficulty, block.timestamp))) % (_endgen+1);
       return(index);
    }
}