pragma solidity 0.6.10;

// DeversiFi 2020

interface StarkContractInterface {
    function getWithdrawalBalance(uint256 starkKey, uint256 tokenId )
        external view
        returns (uint256);
}

contract WithdrawalBalanceReader {
    StarkContractInterface instance;
    
    constructor (address _starkContract) public {
        instance = StarkContractInterface(_starkContract);
    }
    
    function allWithdrawalBalances(uint256[] calldata _tokenIds, uint256 _whoKey) public view returns (uint256[] memory balances) {
        balances = new uint256[](_tokenIds.length);
        for (uint i = 0; i < _tokenIds.length; i++) {
            balances[i] = instance.getWithdrawalBalance(_whoKey, _tokenIds[i]);
        }
    }
    
}