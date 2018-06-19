pragma solidity ^0.4.16;

contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }
}

interface NoahToken {
    function transfer(address to, uint tokens) public returns (bool success);
    function balanceOf(address tokenOwner) public returns (uint256 balance);
}

contract NoahDividend is Ownable {
    NoahToken public noahToken;
    /**
     * Constrctor function
     *
     */
    function NoahDividend(address noahTokenAddress) public {
        noahToken = NoahToken(noahTokenAddress);
    }

    // function checkTotalBalance(uint256[] tokenAmounts) public view returns (bool) {
    //     uint256 total = 0;
    //     for (uint i = 0; i < tokenAmounts.length; i++) {
    //         total += tokenAmounts[i];
    //     }
    //     return total > 0 && noahToken.balanceOf(this) >= total;
    //  }

    function balanceOfInvestor(address investor) public view returns (uint256 balance) {
        return noahToken.balanceOf(investor);
    }

    function multiTransfer(address[] investors, uint256[] tokenAmounts) onlyOwner public returns (address[] results) {
        results = new address[](investors.length);
        if (investors.length != tokenAmounts.length || investors.length == 0 || tokenAmounts.length == 0) {
            revert();
        }
        
        // if (!this.checkTotalBalance(tokenAmounts)) {
        //     revert();
        // }
        
        for (uint i = 0; i < investors.length; i++) {
            bool result = noahToken.transfer(investors[i], tokenAmounts[i]);
            if (result == true){
                results[i] = investors[i];
            }
        }
        return results;
    }
}