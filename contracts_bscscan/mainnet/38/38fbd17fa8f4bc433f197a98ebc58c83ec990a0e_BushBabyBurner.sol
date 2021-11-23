/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

interface BushBaby is IERC20 {
    function claim() external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BushBabyBurner is Ownable {
    BushBaby BUSH = BushBaby(0x01f731c4934ff2BD06eF415027b71Ccc8693C61E);
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    

    function burn(uint256 _amount) external onlyOwner {
        BUSH.transfer(DEAD, _amount);
    }

    function getStuckTokens(address _token) external onlyOwner{
        require(_token != address(BUSH), "Can't take BUSH");
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    function getStuckETH() external onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }   

    function claimRewards() external onlyOwner{
        BUSH.claim();
    }
}