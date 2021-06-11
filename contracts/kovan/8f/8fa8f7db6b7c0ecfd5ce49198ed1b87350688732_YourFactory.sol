pragma solidity 0.8.0;
import "./child.sol";

contract YourFactory {
    event ContractDeployed(address sender, string purpose);

    function newYourContract() public {
        new YourContract();
    }
}