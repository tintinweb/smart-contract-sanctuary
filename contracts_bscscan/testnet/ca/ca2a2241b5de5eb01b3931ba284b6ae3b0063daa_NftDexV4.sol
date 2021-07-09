/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// File: contracts\lpinterface.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface LPInterface {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

   
}

// File: contracts\NFTDexv4.sol

pragma solidity ^0.5.0;



 
contract NftDexV4 {

    LPInterface LPBNB;

    constructor() public{
         LPBNB=LPInterface(0x52826ee949d3e1C3908F288B74b98742b262f3f1);
    }
   
  function getResevers() public view returns(uint112, uint112){
    //  uint256 bnbLpReserve;
            // uint256 busdLpReserve;
            // uint256 bnbTime;
            // (bnbLpReserve, busdLpReserve, bnbTime) = LPBNB.getResevers();
           (uint112 _reserve0, uint112 _reserve1,) =LPBNB.getReserves();
            return (_reserve0, _reserve1);
  }
}