// contracts/TokenExchange.sol
pragma solidity ^0.6.2;

// Import base Initializable contract
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract CWCExchange is Initializable {
    using SafeMath for uint256;

    uint256 public rate;
    IERC20 public token;
    address public owner;

    receive() external payable {
        uint256 tokens = msg.value.mul(rate);
        token.transfer(msg.sender, tokens);
    }

    function withdraw() public {
        require(
            msg.sender == owner,
            "Address not allowed to call this function"
        );
        msg.sender.transfer(address(this).balance);
    }
}