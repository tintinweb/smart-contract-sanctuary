/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

pragma solidity ^0.6.2;

contract test{
    uint256[] public _testlist;
    
    
    function readlist(uint256 num) pure public returns(uint256[] memory){

        uint256[] memory balances_ = new uint256[](num);
        for (uint i = 0; i<num; i++) {
            balances_[i]=i;
            
        }
        return (balances_);
    }
}

//   function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {

//         require(_owners.length == _ids.length);

//         uint256[] memory balances_ = new uint256[](_owners.length);

//         for (uint256 i = 0; i < _owners.length; ++i) {
//             balances_[i] = balances[_ids[i]][_owners[i]];
//         }

//         return balances_;
//     }