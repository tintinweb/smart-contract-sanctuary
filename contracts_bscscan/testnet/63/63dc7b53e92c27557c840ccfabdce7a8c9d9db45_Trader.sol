/**
 *Submitted for verification at BscScan.com on 2021-09-22
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

interface IMintableToken {
    function mint(address user, uint amount) external;
    function burn(uint amount) external;
}

interface Ifactory {
    function isLink(address _link) external view returns(bool);
}

interface Ifile {
    function factory() external view returns(address);
    function luca() external view returns(address);
    function wluca() external view returns(address);
    function agt() external view returns(address);
}

interface Itrader {
    function balance() external returns(uint256 luca, uint256 wluca);
    function payment(address _token, address _from, address _to, uint256 _amount) external returns(bool); 
    function withdrawFor(address _to, uint256 _amount) external;
    function suck(address _to, uint256 _amount, uint256 _lockDay) external;
}

contract Initialize {
    bool private initialized;
    
    modifier noInit(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}

contract Trader is Initialize, Itrader{
    using SafeMath for uint256;
    address public file;
    
    modifier verifyCaller(){
        address factory = Ifile(file).factory();
        require(msg.sender == factory || Ifactory(factory).isLink(msg.sender), "Trader: access denied");
        _;
    }
    
    
    function initialize(address _file) external noInit {
         file = _file;
    }
    
    function balance() override external view returns(uint256 luca_balance, uint256 wluca_supply){
        (address luca, address wluca) = (Ifile(file).luca(), Ifile(file).wluca());
        return (IERC20(luca).balanceOf(address(this)), IERC20(wluca).totalSupply());
    }
    
    //use for factory
    function payment(address _token, address _from, address _to, uint256 _amount) override external verifyCaller returns(bool){
        (address luca, address wluca) = (Ifile(file).luca(), Ifile(file).wluca());
        if (_token == luca) {
            IERC20(luca).transferFrom(_from, address(this), _amount);
            IMintableToken(wluca).mint(_to, _amount);
            return true;
        } 
        
        return IERC20(_token).transferFrom(_from, _to, _amount);
    }
    
    //use for link
    function withdrawFor(address _to, uint256 _amount) override external verifyCaller {
        (address luca, address wluca) = (Ifile(file).luca(), Ifile(file).wluca());
        require(IERC20(wluca).transferFrom(msg.sender, address(this), _amount), "Trader: not enough allowed wluca");
        IMintableToken(wluca).burn(_amount);
        IERC20(luca).transfer(_to, _amount);
    }
    
    //use for airdrop agt
    function suck(address _to, uint256 _amount, uint256 _lockDay) override external verifyCaller {
        uint256 award = _amount.mul(_lockDay).div(100).div(10**18);
        address agt = Ifile(file).agt();
        if (award > 0) IMintableToken(agt).mint(_to, award.mul(10**18));
    }
}