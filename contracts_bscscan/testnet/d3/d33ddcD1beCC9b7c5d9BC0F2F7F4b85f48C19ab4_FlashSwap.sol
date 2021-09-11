/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface Ipancake {
   function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IBEP20 {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IDefi {
    function withdraw(uint256 _amount) external ;
}

contract FlashSwap {

    address public owner;
    Ipancake public ipancake = Ipancake(0xF855E52ecc8b3b795Ac289f85F6Fd7A99883492b);
    IBEP20 public wbnb = IBEP20(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
    uint256 public fee = 3;
    IDefi public app = IDefi(0x0DB518b32E98Bf6339e23bA940C7b3e113e4c526);
    
    modifier onlyOwner() {
        require(msg.sender == owner, '1');
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function runApprove() public onlyOwner {
        wbnb.approve(address(ipancake), uint256(-1));
    }
    
    function adminOut() public onlyOwner {
        wbnb.transfer(owner, wbnb.balanceOf(address(this)));
    }
    
    function flashloan(uint amount) public onlyOwner {
       ipancake.swap(0, amount, address(this), abi.encodePacked(uint256(-1)));
    }
    
    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) public {
        // Do business actions here to use WBNB
        wbnb.transfer(address(app), amount1);
        app.withdraw(amount1);

        // Send back WBNB to PancakePair
        uint256 amount = amount1 + amount1*fee/1000;
        wbnb.transfer(address(ipancake), amount);
    }
}