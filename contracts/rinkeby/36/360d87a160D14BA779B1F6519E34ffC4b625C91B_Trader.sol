/**
 *Submitted for verification at Etherscan.io on 2021-07-07
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

//import "../factory/Ifactory.sol";
interface Ifactory {
    event UpdatetokenConfig(string indexed _symbol, address indexed _tokenAddr, uint256 _minAmount);
    event LinkCreated(address indexed _creater, string indexed _symbol, address _link);
    
    function setRisk() external;
    function setOwner(address _user) external;
    function setCollector(address _user) external;
    function getCollector() external view returns(address);
    function isLink(address _link) external view returns(bool);
    function isAllowedToken(string memory _symbol, address _addr) external returns(bool);
    function createLink(address _toUser, string memory _tokenSymbol, uint256 _amount, uint256 _percentA, uint256 _lockDays) external returns(address);
    function addToken(address _tokenAddr, uint256 _minAmount) external;
    function updateTokenConfig (string memory _symbol, address _tokenAddr, uint256 _minAmount) external;
}

//import ./Itrader.sol
interface Itrader {
    function balance() external returns(uint256 luca, uint256 wluca);
    function deposit(uint256 _amount) external returns(bool);
    function withdraw(uint256 _amount) external returns(bool);
    function payment(address _token, address _from, address _to, uint256 _amount) external returns(bool); 
    function withdrawFor(address _to, uint256 _amount) external;
}

//Trader.sol
contract Initialize {
    bool private initialized;
    modifier noInit(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}

contract Storage is Initialize {
    address public wluca;
    address public luca;
    address public pledge;
    address public factory;
    
}

contract Trader is Storage, Itrader{
    modifier verifyCaller(){
        require(msg.sender == factory || Ifactory(factory).isLink(msg.sender)|| msg.sender == pledge, "Trader: access denied");
        _;
    }
    
    modifier verifyAllowed(address _token, address _from, uint256 amount){
        require(IERC20(_token).allowance(_from, address(this)) >= amount, "Trader: not enough allowed token");
        _;
    }
    
    function initialize(address _luca, address _wluca, address _factory, address _pledge) external noInit {
        wluca = _wluca;
        luca = _luca;
        factory = _factory;
        pledge = _pledge;
    }
    
    function balance() override external view returns(uint256 luca_balance, uint256 wluca_supply){
        return (IERC20(luca).balanceOf(address(this)), IERC20(wluca).totalSupply());
    }
    
    function deposit(uint256 _amount) override external verifyCaller returns(bool) {
        require(IERC20(luca).transferFrom(msg.sender, address(this), _amount), "Trader:  not enough allowed luca");
        Iwluca(wluca).mint(msg.sender, _amount);
        return true;
    }
    
    function withdraw(uint256 _amount) override external verifyCaller returns(bool) {
        require(IERC20(wluca).transferFrom(msg.sender, address(this), _amount), "Trader: not enough allowed wluca");
        Iwluca(wluca).burn(_amount);
        IERC20(luca).transfer(msg.sender, _amount);
        return true;
    }
    
    function payment(address _token, address _from, address _to, uint256 _amount) override external 
    verifyCaller 
    verifyAllowed(_token, _from, _amount)
    returns(bool){
        if (_token == luca) {
            IERC20(luca).transferFrom(_from, address(this), _amount);
            Iwluca(wluca).mint(_to, _amount);
            return true;
        } 
        
        return IERC20(_token).transferFrom(_from, _to, _amount);
    }
    
    function withdrawFor(address _to, uint256 _amount) override external verifyCaller {
        require(IERC20(wluca).transferFrom(msg.sender, address(this), _amount), "Trader: not enough allowed wluca");
        Iwluca(wluca).burn(_amount);
        IERC20(luca).transfer(_to, _amount);
    }

}