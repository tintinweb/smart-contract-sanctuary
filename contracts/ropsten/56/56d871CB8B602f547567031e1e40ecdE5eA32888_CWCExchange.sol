// contracts/TokenExchange.sol
pragma solidity ^0.6.2;

// Import base Initializable contract
import "@openzeppelin/contracts/math/SafeMath.sol";

contract CWCExchange {
    using SafeMath for uint256;

    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }
}