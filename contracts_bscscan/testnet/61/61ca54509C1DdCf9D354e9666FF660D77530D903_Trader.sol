/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface Iwluca {
    function mint(address user, uint amount) external;
    function burn(uint amount) external;
}

interface Ifactory {
    function isLink(address _link) external view returns(bool);
}

interface Itrader {
    function balance() external view returns(uint256 luca, uint256 wluca);
    function payment(address _token, address _from, address _to, uint256 _amount) external returns(bool); 
    function withdrawFor(address _to, uint256 _amount) external;
    function setFactory(address _factory) external;
}

contract Initialize {
    bool private initialized;
    modifier noInit(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}

contract Storage is Initialize {
    address     public owner;
    address     public wluca;
    address     public luca;
    address     public factory;
    address[]   public whiteList;
}

contract Trader is Storage, Itrader {
    modifier onlyOwner(){
        require(msg.sender == owner, "Trader: access denied");
        _;
    }
    
    modifier verifyCaller(){
        require(msg.sender == factory || Ifactory(factory).isLink(msg.sender), "Trader: access denied");
        _;
    }
    
    
    function initialize(address _luca, address _wluca, address _factory) external noInit {
        wluca = _wluca;
        luca = _luca;
        factory = _factory;
        owner = msg.sender;
    }
    
    function balance() override external view returns(uint256 luca_balance, uint256 wluca_supply){
        return (IERC20(luca).balanceOf(address(this)), IERC20(wluca).totalSupply());
    }
    
    //use for factory
    function payment(address _token, address _from, address _to, uint256 _amount) override external  verifyCaller  returns(bool){
        require(IERC20(_token).allowance(_from, address(this)) >= _amount, "Trader: not enough allowed token");
        if (_token == luca) {
            IERC20(luca).transferFrom(_from, address(this), _amount);
            Iwluca(wluca).mint(_to, _amount);
            return true;
        } 
        
        return IERC20(_token).transferFrom(_from, _to, _amount);
    }
    
    //use for link
    function withdrawFor(address _to, uint256 _amount) override external verifyCaller {
        require(IERC20(wluca).transferFrom(msg.sender, address(this), _amount), "Trader: not enough allowed wluca");
        Iwluca(wluca).burn(_amount);
        IERC20(luca).transfer(_to, _amount);
    }
    
    
    function setFactory(address _factory) override external onlyOwner{
        factory = _factory;
    }
    
    
    function _isInWhiteList() internal view returns(bool){
        for (uint i = 0; i < whiteList.length; ++i){
             if (msg.sender == whiteList[i]) return true;
        }
        
        return false;
    }

}