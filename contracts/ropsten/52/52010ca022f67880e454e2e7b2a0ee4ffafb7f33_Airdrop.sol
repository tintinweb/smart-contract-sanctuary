// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Adminable.sol";
import "./IERC20.sol";
import "./ERC20.sol";

contract Airdrop is Adminable {
    address public token;

    struct AirdropData {
        uint startBlock;
        uint endBlock;
        uint256 amount;
        uint256 cap;
        uint256 maxCap;
    }

    struct SaleData {
        uint startBlock;
        uint endBlock;
        uint256 price;
    }

    mapping(address => bool) sended;
    
    AirdropData public airdrop;
    SaleData public sale;

    constructor(address token_) {
        token = token_;
    }

    function setToken(address token_) public onlyAdmin {
        require(token_ != address(0), "AIRDROP: Token cannot be null address");
        withdraw(token);
        token = token_;
    }

    function withdraw(address token_) public onlyAdmin {
        IERC20(token_).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
    
    function withdrawEther() public onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function deposit(address token_, uint256 amount_) public {
        IERC20(token_).transferFrom(msg.sender, address(this), amount_);
    }

    function getAirdrop(address _referer) public {
        require(!sended[msg.sender], "AIRDROP: FATAL");
        require(
            block.number >= airdrop.startBlock &&
            block.number < airdrop.endBlock, 
            "AIRDROP: Closed");
        require(airdrop.cap >= airdrop.amount, "AIRDROP: Insufficiently cap");

        IERC20 tk = IERC20(token);
        tk.transfer(msg.sender, airdrop.amount);
        airdrop.cap -= airdrop.amount;

        if(_referer != msg.sender && tk.balanceOf(_referer) != 0 && _referer != address(0)) {
            tk.transfer(_referer, airdrop.amount);
            airdrop.cap -= airdrop.amount;
        }
        
        sended[msg.sender] = true;
    }

    function setSale(uint startBlock_, uint endBlock_, uint256 price_) public onlyAdmin {
        sale = SaleData({
            startBlock: startBlock_,
            endBlock: endBlock_,
            price: price_
        });
    }

    function setAirdrop(uint startBlock_, uint endBlock_, uint256 amount_, uint256 cap_) public onlyAdmin {
        uint256 cntBalance = IERC20(token).balanceOf(address(this));
        if (cntBalance < cap_) {
            deposit(token, cap_-cntBalance);
        }

        airdrop = AirdropData({
            startBlock: startBlock_,
            endBlock: endBlock_,
            amount: amount_,
            cap: cap_,
            maxCap: cap_
        });
    }

    function getSale() public payable {
        require(
            block.number >= sale.startBlock &&
            block.number < sale.endBlock,
            "SALE: Closed");

        uint256 tkns = msg.value / sale.price;
        IERC20(token).transfer(msg.sender, tkns ** ERC20(token).decimals());
        payable(admin).transfer(msg.value);
    }
    
    receive() external payable {
        getSale();
    }
}