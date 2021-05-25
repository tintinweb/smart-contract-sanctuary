// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

struct TraitUnitProb {
    string value;
    string name;
    uint16 prob;
}
 
contract PulsquaresRecipeV1 is Ownable {

    TraitUnitProb[] probsFormula;
    TraitUnitProb[] probsColorSchemes;
    TraitUnitProb[] probsAlphaType;
    TraitUnitProb[] probsPulseType;
    TraitUnitProb[] probsMainPrimitive;
    TraitUnitProb[] probsRotation;
    TraitUnitProb[] probsSizeVariation;
    TraitUnitProb[] probsSize;
    TraitUnitProb[] probsOpacity;
    
    string public script;
    string public scriptIPFS;  
                        
    /**
     * @dev Probs are multiplied by 10000 to help rounding
     */                        
    constructor() {

        probsFormula.push(TraitUnitProb({prob: 500,
            value: "(((x/size)%5)*((y/size)%5))^(291)*10",
            name: " Lima"}));
        probsFormula.push(TraitUnitProb({prob: 500,
            value: "(x/10 + (x%y)/10)*5",
            name: " Helsinki"}));
        probsFormula.push(TraitUnitProb({prob: 500,
            value: "(1/Math.cos(x*y))*100",
            name: " Las Vegas"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "(Math.atan(x*y)*((x**2)-y**2))/100",
          name: "Santiago"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "Math.atan(x^y)*200",
          name: "Montreal"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "(x^y)",
          name: "New Delhi"}));
        probsFormula.push(TraitUnitProb({prob: 500,
        value: "(x+y)",
        name: "Tokyo"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "(x/y)*100",
        name: "Austin"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "(y/(x+y)*10)",
         name: "Berlin"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "(x&y)^76",
          name: "Chicago"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "(x*x+y*y)>>(y/size/50)",
          name: "Melbourne"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "(Math.abs(x-y)^Math.abs(x*y)/100)",
          name: "Boston"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "(Math.abs((x-y)/(x+y))^(Math.abs(x&y)/10))*10",
          name: "Jakarta"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "(x|y)^(x&y)",
          name: "Buenos Aires"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "(x>>y)*x",
          name: "Moscow"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "(y>>x)*y",
          name: "Dubai"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "((x*x)|(y*y))/100",
          name: "Barcelona"}));
        probsFormula.push(TraitUnitProb({prob: 500,
          value: "Math.pow(x*x+y*y, 1/2)",
          name: "Seoul"}));
        probsFormula.push(TraitUnitProb({prob: 250,
          value: "(2*x)%y",
          name: "Rome"}));
        probsFormula.push(TraitUnitProb({prob: 250,
          value: "(2*y)%x",
          name: "Toronto"}));
        probsFormula.push(TraitUnitProb({prob: 200,
          value: "(Math.abs(x+y)^Math.abs(x-y)+1)",
          name: "Prague"}));
        probsFormula.push(TraitUnitProb({prob: 200,
          value: "(x%y)%30",
          name: "Paris"}));
        probsFormula.push(TraitUnitProb({prob: 50,
          value: "(Math.abs(x/size%2)+(Math.abs(y/size)%2))*10000",
          name: "St. Petersburg"}));
        probsFormula.push(TraitUnitProb({prob: 50,
        value: "((x^y) < 39)*100",
        name: "Rio"}));
        
      probsColorSchemes.push(TraitUnitProb({prob: 2000,
        value: "BlackOnWhite",
        name: "Black On White"}));
      probsColorSchemes.push(TraitUnitProb({prob: 2000,
        value: "WhiteOnBlack",
        name: "White On Black"}));
      probsColorSchemes.push(TraitUnitProb({prob: 1000,
        value: "SunsetOnWhite",
        name: "Sunset On White"}));
      probsColorSchemes.push(TraitUnitProb({prob: 1000,
        value: "OceanOnWhite",
        name: "Ocean On White"}));
      probsColorSchemes.push(TraitUnitProb({prob: 1000,
        value: "TropicalOnBlack",
        name: "Tropical On Black"}));
      probsColorSchemes.push(TraitUnitProb({prob: 1000,
        value: "FireOnWhite",
        name: "Fire On White"}));
      probsColorSchemes.push(TraitUnitProb({prob: 500,
        value: "BlackOnGold",
        name: "Black On Gold"}));
      probsColorSchemes.push(TraitUnitProb({prob: 500,
        value: "BlackOnPurple",
        name: "Black On Purple"}));
      probsColorSchemes.push(TraitUnitProb({prob: 500,
        value: "BlackOnBlue",
        name: "Black On Blue"}));
      probsColorSchemes.push(TraitUnitProb({prob: 250,
        value: "RainbowOnWhite",
        name: "Rainbow On White"}));
      probsColorSchemes.push(TraitUnitProb({prob: 250,
        value: "RainbowOnBlack",
        name: "Rainbow On Black"}));
        
      probsAlphaType.push(TraitUnitProb({prob: 5000,
        value: "None",
        name: "None"}));
      probsAlphaType.push(TraitUnitProb({prob: 4000,
        value: "Increasing",
        name: "Increasing"}));
      probsAlphaType.push(TraitUnitProb({prob: 1000,
        value: "Decreasing",
        name: "Decreasing"}));
        
      probsPulseType.push(TraitUnitProb({prob: 500,
        value: "Chaotic",
        name: "Chaotic"}));
      probsPulseType.push(TraitUnitProb({prob: 9500,
        value: "Uniform",
        name: "Uniform"}));    
        
      probsMainPrimitive.push(TraitUnitProb({prob: 9800,
        value: "Square",
        name: "Square"}));
      probsMainPrimitive.push(TraitUnitProb( {prob: 200,
        value: "Circle",
        name: "Circle"}));
        
    probsRotation.push(TraitUnitProb({prob: 9000,
        value: "None",
        name: "None"}));
        probsRotation.push(TraitUnitProb({prob: 1000,
        value: "Rotating",
        name: "Rotating"}));
        
    probsSizeVariation.push(TraitUnitProb({prob: 9000,
        value: "1.05",
        name: "Regular"}));
    probsSizeVariation.push(TraitUnitProb({prob: 1000,
        value: "0.5",
        name: "Small"}));
        
    probsSize.push(TraitUnitProb({prob: 500,
        value: "100",
        name: "Big"}));
    probsSize.push(TraitUnitProb({prob: 8000,
        value: "15",
        name: "Small"}));
    probsSize.push(TraitUnitProb({prob: 1500,
        value: "25",
        name: "Medium"}));
        
        
    probsOpacity.push(TraitUnitProb({prob: 9900,
        value: "false",
        name: "Regular"}));
    probsOpacity.push(TraitUnitProb({prob: 100,
        value: "true",
        name: "Transparent"}));
    }
    
    function weightedRandom(TraitUnitProb[] memory traitsProbs, uint value) public pure returns(TraitUnitProb memory) {
      uint sum = 0;
      uint r = value*10000/255;
      for (uint i=0; i<traitsProbs.length; i++) {
        sum += traitsProbs[i].prob;
        if (r <= sum) return traitsProbs[i];
      }      
      return traitsProbs[traitsProbs.length-1];
    }

    function setScript(string memory _script) public onlyOwner {
        script = _script;
    }

    function setScriptIPFS(string memory _scriptIPFS) public onlyOwner {
        scriptIPFS = _scriptIPFS;
    }

    function getFormula(bytes32 traitHash) public view returns(string memory) {
        uint256 value = uint256(traitHash) >> 31*8;
        TraitUnitProb memory a = weightedRandom(probsFormula, value);
        return a.name;
    }
    
    function getColorScheme(bytes32 traitHash) public view returns(string memory) {
        uint256 value = (uint256(traitHash) << 8) >> 31*8;
        TraitUnitProb memory a = weightedRandom(probsColorSchemes, value);
        return a.name;
    }
    
    function getAlphaType(bytes32 traitHash) public view returns(string memory) {
        uint256 value = (uint256(traitHash) << 8*2) >> 31*8;
        TraitUnitProb memory a = weightedRandom(probsAlphaType, value);
        return a.name;
    }
    
    function getPulseType(bytes32 traitHash) public view returns(string memory) {
        uint256 value = (uint256(traitHash) << 8*3) >> 31*8;
        TraitUnitProb memory a = weightedRandom(probsPulseType, value);
        return a.name;
    }
    
    function getMainPrimitive(bytes32 traitHash) public view returns(string memory) {
        uint256 value = (uint256(traitHash) << 8*4) >> 31*8;
        TraitUnitProb memory a = weightedRandom(probsMainPrimitive, value);
        return a.name;
    }
    
    function getRotation(bytes32 traitHash) public view returns(string memory) {
        uint256 value = (uint256(traitHash) << 8*5) >> 31*8;
        TraitUnitProb memory a = weightedRandom(probsRotation, value);
        return a.name;
    }
    
    function getSizeVariation(bytes32 traitHash) public view returns(string memory) {
        uint256 value = (uint256(traitHash) << 8*6) >> 31*8;
        TraitUnitProb memory a = weightedRandom(probsSizeVariation, value);
        return a.name;
    }
    
    function getSize(bytes32 traitHash) public view returns(string memory) {
        uint256 value = (uint256(traitHash) << 8*7) >> 31*8;
        TraitUnitProb memory a = weightedRandom(probsSize, value);
        return a.name;
    }
    
    function getOpacity(bytes32 traitHash) public view returns(string memory) {
        uint256 value = (uint256(traitHash) << 8*8) >> 31*8;
        TraitUnitProb memory a = weightedRandom(probsOpacity, value);
        return a.name;
    }
    

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}