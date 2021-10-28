/**
 *Submitted for verification at polygonscan.com on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/*                    
                       

 /$$$$$$$$                    /$$     /$$                    
|__  $$__/                   | $$    |__/                    
   | $$  /$$$$$$   /$$$$$$$ /$$$$$$   /$$ /$$$$$$$   /$$$$$$ 
   | $$ /$$__  $$ /$$_____/|_  $$_/  | $$| $$__  $$ /$$__  $$
   | $$| $$$$$$$$|  $$$$$$   | $$    | $$| $$  \ $$| $$  \ $$
   | $$| $$_____/ \____  $$  | $$ /$$| $$| $$  | $$| $$  | $$
   | $$|  $$$$$$$ /$$$$$$$/  |  $$$$/| $$| $$  | $$|  $$$$$$$
   |__/ \_______/|_______/    \___/  |__/|__/  |__/ \____  $$
                                                    /$$  \ $$
                                                   |  $$$$$$/
                                                    \______/ 
                                                                                                                                                                
*/

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
    function birthAxie(address _to, uint256 _dna, uint256 _bornAt,uint256) external returns (uint256);      
}


abstract contract SysCtrl is Context {

  address public communityAdmin;
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

contract drop1 is SysCtrl{

    using SafeMath for uint256;

    address internal core;
    uint256 internal nonce = 0;

    uint256 public currentLevel = 1;
    uint256 public maxLevel = 1000;
    uint256 public manufacturedLevel = 0; 
    uint256 public morphingTime = (21*24*60*60); 
    uint256 public price1Egg = 0.005 ether;
    uint256 public price3Egg = 0.01 ether;

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
    
    function get1AxieEgg() external payable reentrancyGuard returns(uint256)  {
        require(!sellPaused);
        require(maxLevel > manufacturedLevel);
        require(msg.value >= price1Egg,"Value less than the minimum required");
        manufacturedLevel++;
        return _getAxieEgg();
    }

    function get3AxieEgg() external payable reentrancyGuard returns(uint256[] memory axies)  {
        require(!sellPaused);
        require(maxLevel > manufacturedLevel.add(2));
        require(msg.value >= price1Egg,"Value less than the minimum required");
        manufacturedLevel = manufacturedLevel.add(3);
        for(uint q=0; q<3; q++){
            axies[q] = _getAxieEgg();
        }
        return axies;
    }
    
    function config(uint256 _currentLevel, uint256 _maxLevel, uint256 _manufacturedLevel, uint256 _morphingTime, uint256 _price1Egg, uint256 _price3Egg) external onlyAdmin  {
       if(_currentLevel >0) currentLevel = _currentLevel;
       if(_maxLevel >0) maxLevel = _maxLevel;
       if(_manufacturedLevel >0) manufacturedLevel = _manufacturedLevel;
       if(_morphingTime >0) morphingTime = _morphingTime;
       if(_price1Egg >0) price1Egg = _price1Egg;
       if(_price3Egg >0) price3Egg = _price3Egg;
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
            
            if(helix <= 2){                            // Patern (D,R1,R2) 0 Normal; 1 Curly
               genes = _exons(helix,10);
               if(genes > 1){
                   genes = 0;
               }
            }
            
            if(helix >= 3 && helix <= 11){             // Colors (D,R1,R2) - 4 colors
               genes = _exons(helix,15);
               if(genes > 3 && genes < 13){
                   genes = 0;
               }
               if(genes >= 13) {
                   genes = 1;
               }
            }
            
            if(helix >= 6 && helix <= 11){             // Eyes,mouth (D,R1,R2) - 4 elements
               genes = _exons(helix,10);
               if(genes > 3 && genes < 8){
                   genes = 0;
               } 
               if(genes >= 8) {
                   genes = 1;
               }
            }
            
            if(helix >= 12 && helix <= 23){             // Ears,back,horn,tail (D,R1,R2) - 6 elements
               genes = _exons(helix,13);
               
               if(genes > 5 && genes < 10){
                   genes = 0;
               } 
               if(genes >= 10 ) {
                   genes = 1;
               }
            }
            
            if(helix >= 24){               // Class (D,R1,R2) - 6 elements
               genes = _exons(helix,48);
               
               if(genes > 5 && genes < 12){
                   genes = 0;
               } 
               if(genes >= 12 && genes < 23) {
                   genes = 2;
               }
               if(genes >= 23 && genes < 29) {
                   genes = 3;
               }
               if(genes >= 29 && genes < 35) {
                   genes = 4;
               }
               if(genes >= 35) {
                   genes = 5;
               }
            }
            
            dna = helix == 0 ? dna = uint256(genes) : dna |= uint256(genes)<<4*helix;

        }
        nonce++;
        return Origin(core).birthAxie(to,dna,bornAt,0);
    }

    function _exons(uint256 _helix, uint256 _endgen) internal view returns(uint256) {
       uint256 index = uint(keccak256(abi.encodePacked(_helix, nonce, msg.sender, block.difficulty, block.timestamp))) % _endgen;
       return(index);
    }

}