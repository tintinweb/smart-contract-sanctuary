/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title QQ1330747164
 */
contract buy {

    uint256 number;

    function getReserves(address Pairadress) public returns(uint256  Reserves1,uint256  Reserves2,uint32  Timstamp){
        //getReserves
         bool  success;
         bytes memory ret;
        (success,ret) = Pairadress.call(abi.encodeWithSelector(0x0902f1ac));
        require(success,"getReserves  fail!");
        (Reserves1,Reserves2,Timstamp) = abi.decode(ret,(uint256,uint256,uint32));
        require(Reserves1>0,"Reserves 0");
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
    
    function isOpen() public view returns (bool) {
        return block.timestamp >= 1634133600;
    }
}