//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './IERC20.sol';
import './SafeMath.sol';
import './Address.sol';
import './IUniswapV2Router02.sol';
import './ArkyciaToken.sol';


contract PresaleContract{

    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;

    bool public manualSwapperDisabled = true;
    address public admin;
    uint256 swapRateInUSD = 13000;
    uint256 constant swapDecimal = 10**6;
    address constant usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; //To get value in usd
    //Quickswap Router
    IUniswapV2Router02 router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    address[] path;
    address public arkycia;
    mapping(address => bool) blacklisted;

    constructor(address _admin, address _arkycia){
        admin = _admin;
        arkycia = _arkycia;
        path = new address[](2);
        path[0] = router.WETH();
        path[1] = usdc;
    }

    receive() external payable{
        require(!isBlacklisted(msg.sender), "Blacklisted");
        require(!manualSwapperDisabled, "Swapper is disabled");
        if (msg.sender == address(this)){
            return;
        }

        
        uint256 amountInUSD = router.getAmountsOut(msg.value, path)[1];
        uint256 arkyciaTokenOut = (amountInUSD.mul(swapDecimal)
                                    .div(swapRateInUSD.mul(10**6))).mul(10**18);
        
        require(arkyciaTokenOut > 0, "Cannot buy 0 Arkycia Tokens");

        require(
            (msg.value).mul(swapRateInUSD).div(10**18) <= getArkyciaTokenBalance(),
            "Insuffient arkycia token balance in contract"
        );
        
        bool sent = IERC20(arkycia).transferFrom(
                address(this), 
                msg.sender, 
                arkyciaTokenOut
                );
        require(sent, "Failure on purchase");

    }

    function isBlacklisted(address user) public view returns(bool){
        return blacklisted[user];
    }

    function setBlacklist(address user, bool blacklist) external onlyAdmin{
        blacklisted[user] = blacklist;
    }

    function setPrice(uint256 _price) external onlyAdmin{
        swapRateInUSD = _price;
    }
    function getTokenBalance(address token) public view returns(uint256){
        return IERC20(token).balanceOf(address(this));
    }

    function getArkyciaTokenBalance() public view returns(uint256){
        return getTokenBalance(arkycia);
    }

    function getMaticBalance() public view returns(uint){
        return address(this).balance;
    }

    function updateRouter(address _router) external onlyAdmin{
        require(_router!=address(0),"Address 0 not allowed");
        router = IUniswapV2Router02(_router);
        path[0] = router.WETH();
    }

    function withdrawTokens(address token, address to, uint256 amount) external onlyAdmin{
        require(IERC20(token).balanceOf(address(this)) <= amount, "Balance too low");
        bool sent = IERC20(token).transfer(to, amount);
        require(sent, "Failure on transfer");
    }

    function withdrawArkyciaTokens(address to, uint256 amount) external onlyAdmin{
        require(IERC20(arkycia).balanceOf(address(this)) <= amount, "Balance too low");
        bool sent = IERC20(arkycia).transfer(to, amount);
        require(sent, "Failure on transfer");

    }

    function withdrawMatic(address payable to, uint256 amount) external onlyAdmin{
        require(address(this).balance >= amount, "Balance too low");
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failure on transfer");

    }

    modifier onlyAdmin{
        require(msg.sender == admin, "Not admin");
        _;
    }

    function changeAdmin(address _admin) external onlyAdmin{
        admin = _admin;
    }

    function setSwapRate(uint256 _swapRate) external onlyAdmin{
        swapRateInUSD = _swapRate;
    }
    function setManualSwapperDisabled(bool disabled) external onlyAdmin{
        manualSwapperDisabled = disabled;
    }

}