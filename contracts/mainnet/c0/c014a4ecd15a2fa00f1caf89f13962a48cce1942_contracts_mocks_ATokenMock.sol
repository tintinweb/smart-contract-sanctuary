pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libs/DecMath.sol";

contract ATokenMock is ERC20, ERC20Detailed {
    using SafeMath for uint256;
    using DecMath for uint256;

    uint256 internal constant YEAR = 31556952; // Number of seconds in one Gregorian calendar year (365.2425 days)

    ERC20 public dai;
    uint256 public liquidityRate;
    uint256 public normalizedIncome;
    address[] public users;
    mapping(address => bool) public isUser;

    constructor(address _dai)
        public
        ERC20Detailed("aDAI", "aDAI", 18)
    {
        dai = ERC20(_dai);

        liquidityRate = 10 ** 26; // 10% APY
        normalizedIncome = 10 ** 27;
    }

    function redeem(uint256 _amount) external {
        _burn(msg.sender, _amount);
        dai.transfer(msg.sender, _amount);
    }

    function mint(address _user, uint256 _amount) external {
        _mint(_user, _amount);
        if (!isUser[_user]) {
            users.push(_user);
            isUser[_user] = true;
        }
    }

    function mintInterest(uint256 _seconds) external {
        uint256 interest;
        address user;
        for (uint256 i = 0; i < users.length; i++) {
            user = users[i];
            interest = balanceOf(user).mul(_seconds).mul(liquidityRate).div(YEAR.mul(10**27));
            _mint(user, interest);
        }
        normalizedIncome = normalizedIncome.mul(_seconds).mul(liquidityRate).div(YEAR.mul(10**27)).add(normalizedIncome);
    }

    function setLiquidityRate(uint256 _liquidityRate) external {
        liquidityRate = _liquidityRate;
    }
}