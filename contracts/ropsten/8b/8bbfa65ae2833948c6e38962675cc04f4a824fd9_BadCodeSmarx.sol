/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

pragma solidity ^0.5.12;
interface IName {
    function name() external view returns (bytes32);
}
contract FuzzyIdentityChallenge {
    bool public isComplete;

    function authenticate() public {
        require(isSmarx(msg.sender));
        require(isBadCode(msg.sender));

        isComplete = true;
    }

    function isSmarx(address addr) internal view returns (bool) {
        return IName(addr).name() == bytes32("smarx");
    }

    function isBadCode(address _addr) internal pure returns (bool) {
        bytes20 addr = bytes20(_addr);
        bytes20 id = hex"000000000000000000000000000000000badc0de";
        bytes20 mask = hex"000000000000000000000000000000000fffffff";

        for (uint256 i = 0; i < 34; i++) {
            if (addr & mask == id) {
                return true;
            }
            mask <<= 4;
            id <<= 4;
        }

        return false;
    }
}
contract BadCodeSmarx is IName {
   function callAuthenticate(address _challenge) public {
      FuzzyIdentityChallenge(_challenge).authenticate(); 
   }
   function name() external view returns (bytes32) {
      return bytes32("smarx");
   }
}