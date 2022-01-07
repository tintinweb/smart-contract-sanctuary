/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IPALERC20 {
    function burn(uint256 amount) external;
}

abstract contract Owned {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}


contract ConvertPAL is Owned {

    using SafeMath for uint256;

    bool public isConvertActive = false;

    address public PAL_ADDRESS = 0x689FF93cd41cE43eb4eF7D8919DA5a2EFe448151;            // PAL:decimal 9

    address public presaleTokenAddress = 0x5217c6e7E38cF567BB6B77c8caD8661bA863bd53;    //decimal 9

    constructor() {
    }

    function converToPAL(uint256 _amount) external {

        require( isConvertActive == true, "converting is not active" );

        IERC20(presaleTokenAddress).transferFrom(msg.sender, address(this), _amount);
        IERC20(PAL_ADDRESS).transfer(msg.sender, _amount);
    }

    function setPresaleTokenAddress(address _presaleTokenAddress) external onlyOwner {
        require( _presaleTokenAddress != address(0), "Presale Token address is zero");
        presaleTokenAddress = _presaleTokenAddress;
    }

    function setPALTokenAddress(address _palTokenAddress) external onlyOwner {
        require( _palTokenAddress != address(0), "PAL Token address is zero");
        PAL_ADDRESS = _palTokenAddress;
    }
    
    function setActive(bool _active) external onlyOwner {
        isConvertActive = _active;
    }

    function withdrawPALToken(address to) external onlyOwner {
        require(!isConvertActive, "You cannot get tokens until the convert is closed.");
        
        IERC20(PAL_ADDRESS).transfer(to, IERC20(PAL_ADDRESS).balanceOf(address(this)) );
    }

    function burnPresaleToken() external onlyOwner {
        require(!isConvertActive, "You cannot get tokens until the convert is closed.");

        uint256 amount = IERC20(presaleTokenAddress).balanceOf(address(this));
        IPALERC20(presaleTokenAddress).burn(amount);
    }
}