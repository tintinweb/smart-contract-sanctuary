/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

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

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = 0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }


    
}

contract PayShare is Ownable {
    
     address payable public Wallet_R = payable(0x627C95B6fD9026E00Ab2c373FB08CC47E02629a0); //1
     address payable public Wallet_W = payable(0x406D07C7A547c3dA0BAcFcC710469C63516060f0); //2
     address payable public Wallet_G = payable(0x06376fF13409A4c99c8d94A1302096CB4dC7c07e); //3
     address payable public Wallet_B = payable(0x000000000000000000000000000000000000dEaD);



    modifier only_Team() {
        require((Wallet_R == _msgSender() || Wallet_W == _msgSender() || Wallet_G == _msgSender()), "Ownable: caller is not the owner");
        _;
    }

    modifier only_R() {
        require(Wallet_R == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier only_W() {
        require(Wallet_W == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier only_G() {
        require(Wallet_G == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    receive() external payable {}
    
    function distributeAllBNB() public {
        uint256 contractBNB = address(this).balance;
        if (contractBNB > 0) {
        
        uint256 oneThird = contractBNB/3;

        pay_BNB(Wallet_R, oneThird);
        pay_BNB(Wallet_W, oneThird);
        pay_BNB(Wallet_G, oneThird);

        }
    }
    
    function pay_BNB(address payable sendTo, uint256 amount) private {
            sendTo.transfer(amount);
        }


    /*

    PURGE RANDOM TOKENS

    */

    function pay_Random_Token(address _token) public only_Team {
    
        uint256 randomTokenBalance = IERC20(_token).balanceOf(address(this));
        uint256 oneThird = randomTokenBalance/3;

        IERC20(_token).transfer(Wallet_R, oneThird);
        IERC20(_token).transfer(Wallet_W, oneThird);
        IERC20(_token).transfer(Wallet_G, oneThird);
    }



    function burn_Random_Token(address _token) public only_Team {
    
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(Wallet_B, _contractBalance);
    }



    /*

    CHANGE WALLETS

    */

    function Set_Wallet_R(address payable wallet) public only_R() {
        Wallet_R = wallet;
    }

    function Set_Wallet_W(address payable wallet) public only_W() {
        Wallet_W = wallet;
    }

    function Set_Wallet_G(address payable wallet) public only_G() {
        Wallet_G = wallet;
    }

        
    }