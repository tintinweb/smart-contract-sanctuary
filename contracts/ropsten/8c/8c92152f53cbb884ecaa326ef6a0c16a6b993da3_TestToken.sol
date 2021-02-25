pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract TestToken is ERC20, ERC20Burnable, Ownable {

    using SafeMath for uint256;

    struct Stakeholder {
        uint256 amount;
        uint256 profit;
        uint256 withdrawDate;
        uint256 totalAmount;
        uint256 totalProfit;
    }

    mapping(address => Stakeholder) public stakeholders;

    uint256 public totalStakeAmount = 0;
    uint256 public totalStakeProfit = 0;
    uint256 public totalStakeWithdraw = 0;

    uint256 public profitPercent = 278;

    constructor () public ERC20("TestTokenU2", "TTKU2") {
        _setupDecimals(6);
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }

    function addToStake(uint256 amount) public
    {
        require(amount > 0, "Bad amount");

        _burn(msg.sender, amount);

        if (stakeholders[msg.sender].amount == 0 && stakeholders[msg.sender].profit == 0) {
            stakeholders[msg.sender].withdrawDate = block.timestamp + 365 days;
        }

        stakeholders[msg.sender].amount += amount;
        stakeholders[msg.sender].totalAmount += amount;

        totalStakeAmount += amount;
    }

    function removeFromStake() public
    {
        require(stakeholders[msg.sender].amount > 0, "Not in stake");

        _mint(msg.sender, stakeholders[msg.sender].amount);
        stakeholders[msg.sender].amount = 0;
    }

}