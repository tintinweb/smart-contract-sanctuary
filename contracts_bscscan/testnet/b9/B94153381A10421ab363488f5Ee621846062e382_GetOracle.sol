/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

pragma solidity 0.5.16;

interface Oracle {
    function resultById(uint256 _numberc) external view returns (uint256);
    function setApi(string calldata api, string calldata result) external view returns (uint256);
} 

contract GetOracle {   
    Oracle public oracle;
    constructor(address _contractOracle) public { 
		oracle = Oracle(_contractOracle); // Token NFL
	}
    uint256 public id;
    function setData(string memory api, string memory result) public {
        id = oracle.setApi(api, result);
    }

    function getData(uint256 _id) public view returns(uint256){
        uint256 result = oracle.resultById(_id);
        return result;
    }
}