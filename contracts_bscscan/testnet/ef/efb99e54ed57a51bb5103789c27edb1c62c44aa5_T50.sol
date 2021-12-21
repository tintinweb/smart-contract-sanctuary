/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
interface IERC20 {
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

contract T50 {
    uint private softCap = 500000 * (10 ** 18);
    uint private sold;
    uint private totalPresaleSupply = 100000000 * (10 ** 18);
    uint private price = 7; //Price of each token is 7 BUSD
    bool private Status = true;
    bool private refundState = false;

    address payable owner;

    uint private releaseTime = 1612945800; // Launch time is : 
    uint private closeTime;

    address payable T50add;
    address payable BUSDadd;
    constructor(address payable T50adr, address payable BUSDadr) {
        owner = payable(msg.sender);
        T50add = T50adr;
        BUSDadd = BUSDadr;
    }

    struct Users{
        uint256 preBuyAmount;
        address adr;
    }

    mapping(address => Users) public users;

    function preBuy(uint amount) public returns(bool){
        require(Status, "The presale has ended!");
        require(totalPresaleSupply >= amount, "Not enough token supply!");
        uint Eval = amount * price;
        require(IERC20(BUSDadd).allowance(msg.sender,address(this))>=Eval, "Increase allowance");
        require(IERC20(BUSDadd).balanceOf(msg.sender) >= Eval, "Not enough balance!");
        IERC20(BUSDadd).transferFrom(msg.sender, address(this), Eval);
        IERC20(T50add).transfer(msg.sender, amount);

        users[msg.sender].preBuyAmount += amount;
        users[msg.sender].adr = msg.sender;
        sold += amount;

        return true;
    }

    function finishPresale() public returns(bool){
        require(msg.sender == owner, "This function is owner only!");
        require(Status, "Presale already finished.");
        
        if(sold >= softCap){
            IERC20(BUSDadd).transfer(owner, sold * price);
        }else{
            refundState = true;
        }        
        Status = false;
        closeTime = block.timestamp;
        return true;
    }

    function refund() public returns(bool){
        uint amount = users[msg.sender].preBuyAmount;
        require(refundState, "We are still in presale and not accepting refunds.");
        require(IERC20(T50add).allowance(msg.sender,address(this))>=amount, "Increase allowance");
        require(IERC20(T50add).balanceOf(msg.sender) >= amount, "Not enough balance!");

        IERC20(T50add).transferFrom(msg.sender, address(this), amount);
        uint Eval = amount * price;
        IERC20(BUSDadd).transfer(msg.sender, getPercent(Eval, 95));
        IERC20(BUSDadd).transfer(owner, getPercent(Eval, 5));

        users[msg.sender].preBuyAmount = 0;

        return true;
    }

    function Destruction() public returns(bool){
        require(refundState);
        require(msg.sender == owner, "This function is owner only!");
        //If we do not meet the soft cap users will have 1 month to refund their tokens.
        //After 1 month the contract will be destroyed.
        if(block.timestamp - closeTime > (30 * 3600 * 24)){
            uint balance = IERC20(BUSDadd).balanceOf(address(this));
            IERC20(BUSDadd).transfer(owner, balance);
        }
        refundState = false;
        return true;
    }

    function getPercent(uint256 _val, uint _percent) internal pure  returns (uint256) {
        uint vald;
        vald = (_val * _percent) / 100 ;
        return vald;
    }
}