// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


interface ICompLikeToken {
    function getCurrentVotes(address) external view returns (uint256);
    function delegates(address) external view returns (address);
    function balanceOf(address) external view returns (uint256);
}


contract CompLikeVotesOrBalance {
    function getVotesOrBalance(ICompLikeToken token, address account) public view returns (uint256) {
        address delegate = token.delegates(account);
        uint256 votes = token.getCurrentVotes(account);
        if (delegate == address(0) && votes == 0) return token.balanceOf(account);
        return votes;
    }
    
    function getMultipleVotesOrBalances(ICompLikeToken token, address[] calldata accounts) external view returns (uint256[] memory scores) {
        uint256 len = accounts.length;
        scores = new uint256[](len);
        for (uint256 i; i < len; i++) scores[i] = getVotesOrBalance(token, accounts[i]);
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
  }
}