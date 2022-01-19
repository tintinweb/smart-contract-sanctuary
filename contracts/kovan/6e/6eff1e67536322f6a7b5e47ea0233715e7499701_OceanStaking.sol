pragma solidity >=0.8.0<0.9.0;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";

contract OceanStaking is ERC20, ReentrancyGuard {
    using SafeMath for uint256;
    IERC20 private _bst;

    uint256 private constant LOCK_DURATION = 60 * 60 * 24 * 2;

    mapping(address => uint256) _lockedUntil;

    event Deposit(address indexed owner, uint256 in_amount, uint256 out_amount);
    event Withdraw(address indexed owner, uint256 in_amount, uint256 out_amount);

    constructor(address bst) ERC20("sBlocksquareToken", "sBST") {
        _bst = IERC20(bst);
    }

    function deposit(uint256 amount) public nonReentrant {
        uint256 bstBalance = _bst.balanceOf((address(this)));
        uint256 sbstSupply = totalSupply();
        uint256 amountToMint = (sbstSupply == 0 || bstBalance == 0) ? amount : amount.mul(sbstSupply).div(bstBalance);
        require(_bst.transferFrom(_msgSender(), address(this), amount));
        _mint(_msgSender(), amountToMint);
        _lockedUntil[_msgSender()] = block.timestamp + LOCK_DURATION;
        emit Deposit(_msgSender(), amount, amountToMint);
    }

    function withdraw(uint256 amount) public nonReentrant {
        require(_lockedUntil[_msgSender()] < block.timestamp, "OceanStaking: You need to wait for time lock to expire.");
        uint256 bstBalance = _bst.balanceOf((address(this)));
        uint256 sbstSupply = totalSupply();
        uint256 amountToSend = amount.mul(bstBalance).div(sbstSupply);
        _burn(_msgSender(), amount);
        require(_bst.transfer(_msgSender(), amountToSend));
        emit Withdraw(_msgSender(), amount, amountToSend);
    }

    function lockedUntil(address wallet) public view returns(uint256) {
        return _lockedUntil[wallet];
    }

    receive() external payable {
        // Don't allow ether transfers
        revert();
    }
}