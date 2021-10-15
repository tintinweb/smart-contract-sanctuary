// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./OmniCashERC20.sol";
import "./UniSwap.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";


contract OmniCash is OmniCashERC20, ReentrancyGuard {
    using SafeMath for uint256;

    // whales related
    mapping(address => bool) whales;
    bool public antiWhaleEnabled;
    uint256 public antiWhaleDuration = 60 minutes;
    uint256 public antiWhaleTime;
    uint256 public antiWhaleAmount;

    // pancakeswap
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address public addressForMaintenance           = 0xB5EcD674c16DC5440890622BB640A55D6f29E01B;
    address public addressForBuyBack               = 0x091E8d5E5E5fCC40dE662B0620a227f45d40B1af;
    address public addressForGameExpansion         = 0x697b7f03014ab8890A4c30cb56cC5507f58B370a; // 2%
    address public addressForArtExpansion          = 0x5c5158f5F4c008C64A255239d2893558065f1C73; // 2% locked 1 month in unicrypt
    address public addressForMultimediaExpansion   = 0xDbd31593Bd47F139E119ed1890A094503bbD9404; // 2% locked 6 month in unicrypt
    address public addressForFutureExpansion       = 0x7b326E81dE6E0e74bb147eCF31Fdba2d1d02e46e; // 2% locked 6 month in unicrypt
    address public addressForDeveloper             = 0xaCE9f48Ec979fB4b483918a7d2787971275Fc6e1; // 5% to be locked in unicrypt (locked and vested 1 year)
    address public addressForMarketing             = 0x995a2A6d347e0fBD990D66943FB2419A0f01aa83; // 5%
    address public addressForAirDrop               = 0x756a99fFf0b24bf7CCE4b9ea9F74BA7151A01654; // 2%
    address public addressForLiquidyPool           = 0x72939AFf6bb7FE7C07307985DEdd7CD323B0cDb5; // 25%
    address public addressForPrivateSale           = 0x6D2A3F46081227B78971aDE0Ae9B2062850eB8cc; // 10%
    address public addressForPresale               = 0x15CB6A0A15C688AcBCC0560B75D186b4ed85FD7b; // 15%
    address public addressForRewardAndCompensation = 0x5DC0136FFa8655399B8860c74e12AD80cff1984a; // 30%

    // marketing
    uint256 public tokenForMarketing = 500000 * 10**18;

    
    // exclude from fees
    mapping (address => bool) private _isExcludedFromFees;
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    constructor(
        string memory name, 
        string memory symbol
         
    ) OmniCashERC20(name, symbol) {

         
        
        _mint(addressForGameExpansion, 2 * 10**5 * 10**18);         // 2%
        _mint(addressForArtExpansion,  2 * 10**5 * 10**18);          // 2%
        _mint(addressForMultimediaExpansion, 2 * 10**5 * 10**18);   // 2%
        _mint(addressForFutureExpansion, 2 * 10**5 * 10**18);       // 2%

        _mint(addressForDeveloper, 5 * 10**5 * 10**18);             // 5% lock and vested
        _mint(addressForMarketing, 5 * 10**5 * 10**18);             // 5%
        _mint(addressForAirDrop, 2 * 10**5 * 10**18);               // 2%
        _mint(addressForLiquidyPool, 25 * 10**5 * 10**18);           // 25%
        _mint(addressForPrivateSale, 10 * 10**5 * 10**18);            // 10%
        _mint(addressForPresale, 15 * 10**5 * 10**18);               // 15%
        _mint(addressForRewardAndCompensation, 30 * 10**5 * 10**18);  // 30%
        
        // exclude from fees 
        excludeFromFees(owner(), true);
        excludeFromFees(addressForGameExpansion, true);         
        excludeFromFees(addressForArtExpansion, true);          
        excludeFromFees(addressForMultimediaExpansion, true);   
        excludeFromFees(addressForFutureExpansion, true);       
        excludeFromFees(addressForDeveloper, true);             
        excludeFromFees(addressForMarketing, true);             
        excludeFromFees(addressForAirDrop, true);               
        excludeFromFees(addressForLiquidyPool, true);           
        excludeFromFees(addressForPrivateSale, true);           
        excludeFromFees(addressForPresale, true);               
        excludeFromFees(addressForRewardAndCompensation, true);

        excludeFromFees(addressForMaintenance , true);
        excludeFromFees(addressForBuyBack, true);

        excludeFromFees(address(this), true);
        
        // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1

        // TESTNET
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

        // MAINNET
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
        
        uniswapV2Router = _uniswapV2Router;

        _approve(address(this), address(uniswapV2Router), ~uint256(0));

    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount ) internal virtual override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (
            antiWhaleTime > block.timestamp && // if anti whale time greater than current block timestamp
            amount > antiWhaleAmount &&   // and if amount is greater than anti whale amount
            whales[sender]                 // and sender is detected as whale 
                                            // then revert the transaction
        ) {
            revert("Anti Whale");
        }
        
        if(amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        uint256 transferFeeRate = recipient == uniswapV2Pair ? sellFeeRate : (sender == uniswapV2Pair ? buyFeeRate : normalTransferFeeRate);

        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }
        if (
            transferFeeRate > 0 && // if transfer fee rate is greater than 0
            sender != address(this) && // and sender is not this contract address
            recipient != address(this) && // and recipient is not this contract address
            takeFee                    // and take fees
        ) {                              // then deduct fee from the amount should be sent

            
            uint256 _fee = amount.mul(transferFeeRate).div(100);

            if(recipient == uniswapV2Pair) { // distribute sell fee
                super._transfer(sender, addressForBuyBack, _fee);
            } else if (sender == uniswapV2Pair) { // distribute buy fee
                super._transfer(sender, addressForBuyBack, _fee);
            } else { // distribute the normal fee
                distributeNormalFee(sender, _fee);
            }
            
            amount = amount.sub(_fee);
        }

        super._transfer(sender, recipient, amount);
    }

     

    function distributeNormalFee(address _sender, uint256 _fee) internal virtual {
        uint256 _reDistribution = _fee.div(2);
        uint256 _reDistributionRem = _fee.mod(2);

        super._transfer(_sender, addressForBuyBack, _reDistribution); 

        uint256 _others =  _fee.div(2);
        uint256 _remainder = _others.mod(3);
        uint256 _distFee = _others.div(3);
        super._transfer(_sender, addressForMarketing, _distFee);
        super._transfer(_sender, addressForMaintenance, _distFee);
        super._transfer(_sender, addressForGameExpansion, _distFee);

        _remainder = _remainder.add(_reDistributionRem);
        super._transfer(_sender, owner(), _remainder); // give to the owner the remainder
    }


    function setWhale(address _whale) external onlyOwner {
        require(!whales[_whale],"Already flag as whale");

        whales[_whale] = true;
    }

    function antiWhale(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount should be greater than 0");
        require(!antiWhaleEnabled,"Anti whale should Not Enabled!");

        antiWhaleAmount = amount;
        antiWhaleTime = block.timestamp.add(antiWhaleDuration);
        antiWhaleEnabled = true;
    }

    // receive eth from uniswap swap
    receive() external payable {}

    // --------------- MARKETING RELATED  --------------- 
    function setAddressForMarketing(address _addressForMarketing) external onlyOwner {
        require(_addressForMarketing != address(0), "0x is not accepted here");

        addressForMarketing = _addressForMarketing;
    }
    // function setMinTokensBeforeSwap(uint256 _tokenForMarketing) public onlyOwner
    // {
    //     require(_tokenForMarketing < 20 * 10**6 * 10**18,"Token for marketing should be less than 20M");
    //     tokenForMarketing = _tokenForMarketing;
    // }

    function sweepTokenForMarketing() public nonReentrant {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= tokenForMarketing) {
            swapTokensForEth(tokenForMarketing, addressForMarketing);
        }
    }

    function swapTokensForEth(uint256 tokenAmount, address toAddress) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            toAddress, // The contract
            block.timestamp
        );
    }


    // --------------- FEE EXCLUSION AND INCLUSION   --------------- 
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setAddressForMaintenance(address  _addressForMaintenance) external onlyOwner {
        require(_addressForMaintenance != address(0), "0x is not accepted here");
        addressForMaintenance=_addressForMaintenance;
    }
   
   
   
   function setAddressForBuyBack(address  _addressForBuyBack) external onlyOwner {
        require(_addressForBuyBack != address(0), "0x is not accepted here");
        addressForBuyBack=_addressForBuyBack;
    }
   
   
   
   function setAddressForGameExpansion(address  _addressForGameExpansion) external onlyOwner {
        require(_addressForGameExpansion != address(0), "0x is not accepted here");
        addressForGameExpansion=_addressForGameExpansion;
    }
   
   
   
   function setAddressForArtExpansion(address  _addressForArtExpansion) external onlyOwner {
        require(_addressForArtExpansion != address(0), "0x is not accepted here");
        addressForArtExpansion=_addressForArtExpansion;
    }
   
   
   
   function setAddressForMultimediaExpansion(address  _addressForMultimediaExpansion) external onlyOwner {
        require(_addressForMultimediaExpansion != address(0), "0x is not accepted here");
        addressForMultimediaExpansion=_addressForMultimediaExpansion;
    }
   
   
   
   function setAddressForFutureExpansion(address  _addressForFutureExpansion) external onlyOwner {
        require(_addressForFutureExpansion != address(0), "0x is not accepted here");
        addressForFutureExpansion=_addressForFutureExpansion;
    }
   
   
   
   function setAddressForDeveloper(address  _addressForDeveloper) external onlyOwner {
        require(_addressForDeveloper != address(0), "0x is not accepted here");
        addressForDeveloper=_addressForDeveloper;
    }
   
   
  
   
   function setAddressForAirDrop(address  _addressForAirDrop) external onlyOwner {
        require(_addressForAirDrop != address(0), "0x is not accepted here");
        addressForAirDrop=_addressForAirDrop;
    }
   
   
   
   function setAddressForLiquidyPool(address  _addressForLiquidyPool) external onlyOwner {
        require(_addressForLiquidyPool != address(0), "0x is not accepted here");
        addressForLiquidyPool=_addressForLiquidyPool;
    }
   
   
   
   function setAddressForPrivateSale(address  _addressForPrivateSale) external onlyOwner {
        require(_addressForPrivateSale != address(0), "0x is not accepted here");
        addressForPrivateSale=_addressForPrivateSale;
    }
   
   
   
    function setAddressForPresale(address  _addressForPresale) external onlyOwner {
        require(_addressForPresale != address(0), "0x is not accepted here");
        addressForPresale=_addressForPresale;
    }
   
   
   
    function setAddressForRewardAndCompensation(address  _addressForRewardAndCompensation) external onlyOwner {
        require(_addressForRewardAndCompensation != address(0), "0x is not accepted here");
        addressForRewardAndCompensation=_addressForRewardAndCompensation;
    }
}