// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
import "./BEP20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./BPContract.sol";


contract TestContract is BEP20 {
    using SafeMath for uint256;
    using Address for address;
    BPContract public BP;
    bool public bpEnabled;
    
    uint256 private constant INITIAL_SUPPLY = 20 * 10** 6 * 10 ** 18; // 20M tokens
    uint256 public buyOperationFee = 5;
    uint256 public sellOperationFee = 12;
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public play2EarnAddress;
    address public airDropAddress;
    mapping(address => bool) private _excludeFromFee;
    
    event BPAdded(address indexed bp);
    event BPEnabled(bool indexed _enabled);
    event BPTransfer(address from, address to, uint256 amount);
    
    constructor(string memory _name, string memory _symbol, address _play2EarnAddress, address _airDropAddress) BEP20(_name, _symbol) {
        _mint(_msgSender(), INITIAL_SUPPLY);
        play2EarnAddress = _play2EarnAddress;
        airDropAddress = _airDropAddress;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        
        _excludeFromFee[owner()] = true;
        _excludeFromFee[address(this)] = true;
        _excludeFromFee[play2EarnAddress] = true;
        _excludeFromFee[airDropAddress] = true;
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
    }
    function setBpAddress(address _bp) external onlyOwner {
        require(address(BP) == address(0), "Can only be initialized once");
        BP = BPContract(_bp);
        emit BPAdded(_bp);
    }
    function setBpEnabled(bool _enabled) external onlyOwner {
        require(address(BP) != address(0), "You have to set BP address first");
        bpEnabled = _enabled;
        emit BPEnabled(_enabled);
    }
    function _transfer( address sender, address recipient, uint256 amount ) internal virtual override {
        if (bpEnabled) {
            BP.protect(sender, recipient, amount);
            emit BPTransfer(sender, recipient, amount);
        }
        if(
            _excludeFromFee[sender] != true && _excludeFromFee[recipient] != true
            &&(recipient == uniswapV2Pair || sender == uniswapV2Pair)
        ) {
            uint256 _operationFee;
            if(recipient == uniswapV2Pair){
                _operationFee = amount.mul(sellOperationFee).div(100);
            } else {
                _operationFee = amount.mul(buyOperationFee).div(100);
            }
            if(_operationFee > 0){
                amount = amount.sub(_operationFee);
                super._transfer(sender, play2EarnAddress, _operationFee);
            }
        }
        super._transfer(sender, recipient, amount);
    }
    function setBuyFee(uint256 operationFee) external onlyOwner {
        buyOperationFee = operationFee;
    }
    function setSellFee(uint256 operationFee) external onlyOwner {
        sellOperationFee = operationFee;
    }
    function addExcludeFromFee( address[] memory users) external onlyOwner {
        if(users.length == 1) {
        _excludeFromFee[users[0]] = true;
        } else {
            for(uint256 i = 0; i<users.length; i++) {
                _excludeFromFee[users[i]] = true;
            }
        }
    }
    function removeExcludeFromFee( address[] memory users) external onlyOwner {
        if(users.length == 1) {
        _excludeFromFee[users[0]] = false;
        } else {
            for(uint256 i = 0; i<users.length; i++) {
                _excludeFromFee[users[i]] = false;
            }
        }
    }
    receive() external payable {
    }
}