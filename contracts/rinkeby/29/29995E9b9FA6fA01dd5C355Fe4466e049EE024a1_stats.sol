pragma solidity ^0.8.0;

//import "https://github.com/alianse777/solidity-standard-library/blob/master/Array.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";



interface istats{
    
    function characters(uint256) external view returns(uint256 id, uint256,uint256,uint256,uint256 experience,uint256,uint256,string memory name,uint256,uint256);
    function getNumberOfCharacters() external view returns(uint256);
    function getExperience(uint256) external view returns(uint256);
    function feed (uint256 tokenId) external;
    function transfer(address,uint256) external;
    function balanceOf(address) external returns(uint256);
    
    
    
}

contract stats{
    //using Array for uint256;
    
    address public addy = 0x95651235dD30E61063A2b989D88C0fC2Fd27F428;
    address payable public chewy;
    address payable public store;
    uint256 public m;
    uint256 public n;
    uint256 pets = 0;
    uint256 claim;
    
    mapping (uint256 => bool)public isfeeding;
    mapping (address => bool)public isClaimed;
    
    function getCharacter(uint256 tokenId) public view returns(uint256 id, uint256,uint256,uint256,uint256 experience,uint256,uint256,string memory name,uint256,uint256){
        
        return istats(addy).characters(tokenId);
    }
    

    
    
    function getNumber() public view returns(uint256){
              return  istats(addy).getNumberOfCharacters();
        
        
    }
    
    function getCharacterExperience(uint256 tokenId) public  view returns(uint256){
        
       return istats(addy).getExperience(tokenId);
        
        
    }
    
    /**
    
    function Feed(uint256 tokenId) public{
        istats(addy).feed(tokenId);
    }
    */
    
    
    
    function addPet(uint256 tokenId) public {
        isfeeding[tokenId] = true;
        pets++;
    }
    
    function removePet(uint256 tokenId) public {
        isfeeding[tokenId] = false;
        pets--;
    }
    
    function SetAddy(address addr) public{
        addy = addr;
    }
    
    function SetChewy(address payable addr) public{
        chewy = addr;
    }
    
    function SetStore(address payable addr) public{
        store = addr;
    }
    
    function SetClaim(uint256 fee) public{
        claim = fee;
    }
    
    
    function ClaimTokens()public {
        require(istats(addy).balanceOf(msg.sender) > 0);
        require(isClaimed[msg.sender] == false);
        istats(chewy).transfer(msg.sender,claim);
        isClaimed[msg.sender] = true;
    }
    
    /**
    
    function feedAll() public returns(uint256 [] memory){
        
        uint256 totalCount = 1000;
         uint256 totalPets = pets;
        
        if(totalPets == 0) {
            return new uint256[](0);
        }
        else{
           uint[] memory result = new uint256[](totalPets);
            //uint256 totalPets = newId;
           uint256 resultIndex = 0;
            uint256 i;
            for(i=0; i<totalCount; i++){
                result[resultIndex] = i;
                    resultIndex++;
                  if(isfeeding[i] = true){
                Feed(i);
                    
                }
                
            }
            return result;
            
        }
    }
    */
    
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

