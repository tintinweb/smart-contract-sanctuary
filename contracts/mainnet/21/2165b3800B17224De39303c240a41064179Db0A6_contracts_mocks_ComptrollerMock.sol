pragma solidity 0.5.17;

// interfaces
import "./ERC20Mock.sol";

contract ComptrollerMock {
    uint256 public constant CLAIM_AMOUNT = 10**18;
    ERC20Mock public comp;

    constructor (address _comp) public {
        comp = ERC20Mock(_comp);
    }

    function claimComp(address holder) external {
        comp.mint(holder, CLAIM_AMOUNT);
    }

    function getCompAddress() external view returns (address) {
        return address(comp);
    }
}