// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.4;

import "./ERC20Upgradeable.sol";
import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./router.sol";
import "./AddressUpgradeable.sol";

interface IControl {
    function swap() external;
    function addAmount(uint amount) external;
}

contract DBG is OwnableUpgradeable,ERC20Upgradeable{

    IPancakeRouter02 public constant router = IPancakeRouter02(0x1B6C9c20693afDE803B27F8782156c0f892ABC2d);
    mapping(address => bool) public pairs;
    mapping(address => uint) public buyAmount;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) public whiteList;
    mapping(address => bool) public whiteTransfer;
    mapping(address => bool) public whiteBalance;
    uint public buyFee;
    uint public sellFee;
    IControl public control;
    IERC20 public U;
    address public fund;
    uint public addLiquidityAmount;
    uint public balanceLimit;
    function initialize() external initializer {
        __ERC20_init_unchained("Data Base Generator", "DBG");
        __Context_init_unchained();
        __Ownable_init_unchained();
        buyFee = 5;
        sellFee = 5; // 0 for black, 1 for liquidiy;
        _mint(msg.sender, 10000 ether);
        balanceLimit = 20 ether;
    }

    function setControl( address addr) external onlyOwner{
        control = IControl(addr);
    }

    function setWhiteList(address addr, bool b) external onlyOwner{
        whiteList[addr] = b;
        whiteTransfer[addr] = b;
        whiteBalance[addr] = b;
    }
    
    function setWhiteTransfer(address addr, bool b) external onlyOwner{
        whiteTransfer[addr] = b;
    }
    
    function setWhiteBalance(address addr, bool b) external onlyOwner{
        whiteBalance[addr] = b;
    }
    
    function setU(address addr) external onlyOwner{
        U = IERC20(addr);
    }

    function setPair(address addr, bool b) external onlyOwner{
        pairs[addr] = b;
    }

    function setFee(uint buyFee_,uint sellFee_)external onlyOwner{
        buyFee = buyFee_;
        sellFee = sellFee_;
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {


        if (!whiteTransfer[msg.sender] && !whiteTransfer[recipient] && !whiteTransfer[sender]) {
            if (msg.sender == address(router) || pairs[recipient]) {
                require(amount <= balanceOf(sender) * 99 / 100, 'must less than 99%');
                uint temp = amount * sellFee / 100;
                _transfer(sender, address(control), temp);
                control.addAmount(temp);
                amount -= temp;
            }
        }
        if(!pairs[recipient]){
            control.swap();
        }
        _transfer(sender, recipient, amount);
        
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }
        return true;
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        
        if (!whiteTransfer[msg.sender] && !whiteTransfer[recipient]) {
            if (pairs[msg.sender]) {
                uint temp = amount * sellFee / 100;
                _transfer(msg.sender, address(control), temp);
                control.addAmount(temp);
                amount -= temp;
            }else{
                uint temp = amount * buyFee / 100;
                _transfer(msg.sender, burnAddress, temp);
                amount -= temp;
            }
        }
        if(!pairs[msg.sender]){
            control.swap();
        }

        _transfer(_msgSender(), recipient, amount);
        if(!pairs[recipient] && !whiteBalance[recipient]){
            require(balanceOf(recipient) <= balanceLimit,'out of balanceLimit');
        }

        return true;

    }


}