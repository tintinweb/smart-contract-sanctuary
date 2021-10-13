// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";
import "./Ownable.sol";

interface ITokenSale{
    /**
        Function: estimatePrice(uint256 numberOfTokens)
        Popose: estimate price for a number of token.
    */
    function estimatePrice(uint256 numberOfTokens) external view returns (uint256);

    /**
        Function: buyTokens(uint256)
        Popose: buy token
        Condition: you need to approve enought number of currency token ( tokenAccept ) . The param
        is number of token after multiply with decimals.
     */
    function buyTokens(uint256 numberOfTokens) external;

}

contract TokenSale is Ownable {
    IERC20Metadata public tokenSale;
    IERC20Metadata public tokenAccept;
    uint256 public price;
    uint256 public minBuy;
    bool public isActive = false;

    event Sold(address buyer, uint256 amount);

    /**
        Contrustor

        Điều kiện:
        - _tokenSale và _tokenAccept là địa chỉ contract bán và contract chấp nhận mua
        - _numTokenSale và _numTokenAccept lớn hơn 0 và được truyền vào dưới dạng đã nhân decimal.
        Ví dụ : bán 1 TokenA bằng 0.2 TokenB ( decimals TokenA = 18, decimals TokenB = 6)
        ==>  _numTokenSale = 1*10^18 và _numTokenAccept = 0.2*10^6
        - _isActive trạng thái contract sau khi tạo
        - _minBuy là số lượng token nhỏ nhất có thể mua
    */

    constructor(IERC20Metadata _tokenSale, uint256 _numTokenSale, IERC20Metadata _tokenAccept, uint256 _numTokenAccept, uint256 _minBuy,  bool _isActive) {
        require(_numTokenSale > 0);
        require(_numTokenAccept > 0);
        require(_minBuy >= 0);

        tokenSale = _tokenSale;
        tokenAccept = _tokenAccept;
        minBuy = _minBuy;

        price = (_numTokenAccept*10**tokenSale.decimals())/_numTokenSale;
        isActive = _isActive;
    }

    /**
        Function: estimatePrice(uint256 numberOfTokens)
        Popose: estimate price for a number of token.
    */
    function estimatePrice(uint256 numberOfTokens) public view returns (uint256) {
        require(numberOfTokens <= tokenSale.allowance(owner(),address(this)));
        require(numberOfTokens >= minBuy);

        uint256 amount = (numberOfTokens*price)/(10**tokenSale.decimals());
        require(amount != 0);

        return amount;
    }


    /**
        Function: buyTokens(uint256)
        Popose: buy token
        Condition: you need to approve enought number of currency token ( tokenAccept ) . The param
        is number of token after multiply with decimals.
     */
    function buyTokens(uint256 numberOfTokens) public {
        require(isActive == true);
        require(numberOfTokens <= tokenSale.allowance(owner(),address(this)));
        require(numberOfTokens >= minBuy);

        uint256 amount = (numberOfTokens*price)/(10**tokenSale.decimals());
        require(amount != 0);

        require(tokenAccept.allowance(msg.sender,address(this)) >= amount);

        require(tokenAccept.transferFrom(msg.sender, owner(), amount));
        require(tokenSale.transferFrom(owner(), msg.sender, numberOfTokens));

        emit Sold(msg.sender, numberOfTokens);
    }

    function endSale() public onlyOwner() {
        require(isActive == true);
        isActive = false;
    }

    function startSale() public onlyOwner() {
        require(isActive == false);
        isActive = true;
    }

    /**
        Điều kiện như hàm khởi tạo
     */

    function updatePrice(uint256 _numTokenSale, uint256 _numTokenAccept) public onlyOwner() {
        require(_numTokenSale > 0);
        require(_numTokenAccept > 0);

        price = (_numTokenAccept*10**tokenSale.decimals())/_numTokenSale;
    }

    function updateMinBuy(uint256 _minBuy) public onlyOwner() {
        require(_minBuy >= 0);

        minBuy = _minBuy;
    }

    function getRemaningTokenSale() public view returns (uint256) {
        return tokenSale.allowance(owner(),address(this));
    }
}