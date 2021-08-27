// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0 <0.9.0;

import "./IBEP20.sol";

pragma solidity >=0.6.12;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./BEP20.sol";

contract TokenBEP20 is BEP20 {
    using SafeMath for uint256;
    uint256 public maxSupply = 100000000000000000000000000;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public farmerFee = 38;
    uint256 public devRewardFee = 2;
    uint256 public LPFee = 10;

    address public farmAdrress;
    address public minterAdrress;
    address public devRewardAdrress;
    address public LPAdrress;
    
    mapping (address => bool) private _isExcludedFromFee;
    
    modifier onlyMinter() {
        require(minterAdrress == _msgSender(), "Mintable: caller is not the minter");
        _;
    }
    
    /**
     * @notice Constructs the PantherToken contract.
     */
    constructor(string memory name, string memory symbol, address router) BEP20(name, symbol) {
        if(router != address(0)) {
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
                router
            );

            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

            uniswapV2Router = _uniswapV2Router;
            
            _approve(address(this), address(uniswapV2Router), ~uint256(0));
        }
        _mint(_msgSender(), maxSupply);
        _isExcludedFromFee[_msgSender()] = true;
        farmAdrress = _msgSender();
        devRewardAdrress = _msgSender();
        LPAdrress = _msgSender();
        minterAdrress = _msgSender();
    }
    
    /// @dev overrides transfer function to meet tokenomics of Token
    function _transfer( address sender, address recipient, uint256 amount ) internal virtual override {
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[sender] || (_isExcludedFromFee[recipient] && recipient != farmAdrress)){
            takeFee = false;
        }
        
        if(takeFee){
            uint256 _farmerFee = amount.mul(farmerFee).div(1000);
            uint256 _devRewardFee = amount.mul(devRewardFee).div(1000);
            uint256 _LPFee = amount.mul(LPFee).div(1000);
            super._transfer(sender, farmAdrress, _farmerFee); // TransferfarmerFee
            amount = amount.sub(_farmerFee);
            super._transfer(sender, devRewardAdrress, _devRewardFee); // TransferdevRewardFee
            amount = amount.sub(_devRewardFee);
            super._transfer(sender, LPAdrress, _LPFee); // TransferLPFee
            amount = amount.sub(_LPFee);
        }
        super._transfer(sender, recipient, amount);
    }
    
    function updateMinter(address _minterAdrress) public onlyMinter returns (bool){
        minterAdrress = _minterAdrress;
        return true;
    }

    function updatedevReward(address _devRewardAdrress) public onlyOwner returns (bool){
        _isExcludedFromFee[devRewardAdrress] = false;
        devRewardAdrress = _devRewardAdrress;
        _isExcludedFromFee[devRewardAdrress] = true;
        return true;
    }

    function updateLPAdrress(address _LPAdrress) public onlyOwner returns (bool){
        _isExcludedFromFee[LPAdrress] = false;
        LPAdrress = _LPAdrress;
        _isExcludedFromFee[LPAdrress] = true;
        _approve(farmAdrress, address(uniswapV2Router), ~uint256(0));
        return true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the minterAdrress. The minterAdrress will be tranfer to 0x00 when done.
    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }
    
    function setFarmAdrress(address _farmAdrress) external onlyOwner {
        _isExcludedFromFee[farmAdrress] = false;
        farmAdrress = _farmAdrress;
        _isExcludedFromFee[farmAdrress] = true;
        _approve(farmAdrress, address(uniswapV2Router), ~uint256(0));
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
}