/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "../common/interface/IERC20.sol";
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//import "../trader/Itrader.sol";
interface Itrader {
    function balance() external returns(uint256 luca, uint256 wluca);
    function linkDeposit(uint256 _amount) external;
    function deposit(address from, uint256 amount) external;
    function withdraw(address to, uint256 amount) external;
}

//import "../common/library/SafeMath.sol";
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

//import "../token/WLUCA/WlucaInterface.sol";
interface Iwluca {
    function mint(address user, uint amount) external;
    function burn(uint amount) external;
}

contract traderStrage {
    address public wluca;
    address public luca;
    address public factory;
    bool    public initialized;
    mapping(address=>uint256) public depositLedger;
}

contract Trader is Itrader, traderStrage {
    using SafeMath for uint256;
    modifier onlyInitialize(){
        require(!initialized,"Trader: contract was initialized" );
        _;
        initialized = true;
    }

    modifier onlyFactory(){
        require(msg.sender == factory, "Trader: only factory");
        _;
    }

    function initerlize( address _luca, address _wluca, address _factory) external onlyInitialize {
        luca = _luca;
        wluca = _wluca;
        factory = _factory;
    }

    function balance() override external view returns(uint256 luca_balance, uint256 wluca_supply){
        return (IERC20(luca).balanceOf(address(this)), IERC20(wluca).totalSupply());
    }

    function deposit(address _to, uint256 _amount) override external onlyFactory {
        //charge luca
        //require(IERC20(luca).transferFrom(factory, address(this), amount), "Trader: deposit luca fail, not enough allowed");
        //mint wluca for depositer;
        Iwluca(wluca).mint(_to, _amount);
    }

    function linkDeposit(uint256 _amount) override external {
        require(IERC20(luca).transferFrom(msg.sender, address(this), _amount), "Trader: deposit luca fail, not enough allowed");
        Iwluca(wluca).mint(msg.sender, _amount);
    }

    function withdraw(address _to, uint256 _amount) override external {
        require(IERC20(wluca).transferFrom(msg.sender, address(this), _amount), "Trader: deposit luca fail, not enough allowed");
        Iwluca(wluca).burn(_amount);
        IERC20(luca).transfer(_to, _amount);
    }
}