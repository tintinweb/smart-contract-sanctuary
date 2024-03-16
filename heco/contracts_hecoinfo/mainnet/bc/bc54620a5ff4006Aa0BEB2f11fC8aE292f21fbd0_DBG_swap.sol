// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IERC20.sol";
import "./router.sol";

contract DBG_swap is Ownable{
    IERC20 public U;
    IERC20 public DBG;
    address public pair;
    mapping(address => bool) public admin;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    IPancakeRouter02 public constant router = IPancakeRouter02(0x1B6C9c20693afDE803B27F8782156c0f892ABC2d);
    uint public swapAmount;
    modifier onlyAdmin(){
        require(admin[msg.sender],'not admin');
        _;
    }
    
    
    function getPrice() internal view returns(uint){
        uint u = U.balanceOf(pair);
        uint token = DBG.balanceOf(pair);
        uint price = u * 1e18 / token;
        return price;
    }
    
    function setToken(address U_, address DBG_) external onlyOwner{
        U = IERC20(U_);
        DBG = IERC20(DBG_);
        admin[DBG_] = true;
        U.approve(address(router),1e38);
        DBG.approve(address(router),1e38);
    }
    function setAdmin(address addr, bool b) external onlyOwner{
        admin[addr] = b;
    }
    
    function setPair(address addr) external onlyOwner{
        pair = addr;
    }
    
    function addAmount(uint amount) external onlyAdmin{
        swapAmount += amount;
    }
    
    function swap() external onlyAdmin{
        if(swapAmount == 0){
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(DBG);
        path[1] = address(U);
        uint uAmount = U.balanceOf(address(this));
        router.swapExactTokensForTokens(swapAmount, 0, path, address(this), block.timestamp + 720);
        uint newU = U.balanceOf(address(this));
        uint amount = newU - uAmount;
        uint out = amount * 1e18 / getPrice();
        swapAmount = 0;
        if(DBG.balanceOf(address(this)) >= out){
          DBG.transfer(burnAddress,out);
        }
        
    }
    function safePull(address token_, address wallet, uint amount_) public onlyOwner {
        IERC20(token_).transfer(wallet, amount_);
    }
}