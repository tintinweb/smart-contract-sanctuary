/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

contract Calculator {
  uint256 public caclulateResult;
  address public user;
  uint256 public addCount;

  event addEvent(address txOrigin, address msgSenderAddress, address _this, uint msgValue);

  function add(uint256 a, uint256 b) payable public returns (uint256) {
    caclulateResult = a + b;
    user = msg.sender;
    addCount += 1;

    emit addEvent(tx.origin, msg.sender, address(this), msg.value);

    return caclulateResult;
  }
}