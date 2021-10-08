// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./TestERC20.sol";
import "./UniSwap.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";


contract Test is TestERC20, ReentrancyGuard {
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

    address public addressForMaintenance           = 0x6e160D4fd750878C6B4ED9EabBc261531628783F;
    address public addressForBuyBack               = 0x6B9DfcA02f09E9Df97fBefba43992E63D09AF8a0;
    address public addressForGameExpansion         = 0x09c92166AC9801F083a1dcb13694A415c73ea78D; // 2%
    address public addressForArtExpansion          = 0x37F9fF53D8eB1b8912DFb408521E53d95Aa173cd; // 2% locked 1 month in unicrypt
    address public addressForMultimediaExpansion   = 0xc4e1A291A4338b711F612092e983f37FaC094849; // 2% locked 6 month in unicrypt
    address public addressForFutureExpansion       = 0x569d2eB2B38064f37Eba7E366108c2016977a3FB; // 2% locked 6 month in unicrypt
    address public addressForDeveloper             = 0xd380424b11fC69aA513B9FcA8e5f0a83fdd51A06; // 5% to be locked in unicrypt (locked and vested 1 year)
    address public addressForMarketing             = 0x65d79031844A41CF492018EF616ACf974D68AeD1; // 5%
    address public addressForAirDrop               = 0x7163F55579Bcf0Ec84CD96b869d0884D48b3Cb5E; // 2%
    address public addressForLiquidyPool           = 0x6254d5cB5D462BF421CB400133cf792eF1A8AD6D; // 25%
    address public addressForPrivateSale           = 0xe77db2565925E076aF8b95EEc8C56D906a2E121d; // 10%
    address public addressForPresale               = 0x53462b349248009B0142EE36f811e4c4fc60b94F; // 15%
    address public addressForRewardAndCompensation = 0x6788BB075019dD16d8CF01A446e1ABd45b44caE9; // 30%

    // marketing
    uint256 public tokenForMarketing = 500000 * 10**18;

    
    // exclude from fees
    mapping (address => bool) private _isExcludedFromFees;
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    constructor(
        string memory name, 
        string memory symbol
         
    ) TestERC20(name, symbol) {

         
        
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
                distributeSellFee(sender, _fee);
            } else if (sender == uniswapV2Pair) { // distribute buy fee
                distributeBuyFee(sender, _fee);
            } else { // distribute the normal fee
                distributeNormalFee(sender, _fee);
            }
            
            amount = amount.sub(_fee);
        }

        super._transfer(sender, recipient, amount);
    }

    function distributeSellFee(address _sender, uint256 _fee) internal virtual {
        uint256 _remainder = _fee.mod(6);
        uint256 _distFee = _fee.div(6);
        
        super._transfer(_sender, addressForMarketing, _distFee);
        super._transfer(_sender, addressForRewardAndCompensation, _distFee);
        
        super._transfer(_sender, addressForBuyBack, _distFee);
        swapTokensForEth(_distFee, addressForBuyBack);

        super._transfer(_sender, addressForMaintenance, _distFee);
        super._transfer(_sender, addressForBuyBack, _distFee); 
        super._transfer(_sender, addressForGameExpansion, _distFee); 


        super._transfer(_sender, owner(), _remainder); // give to the owner the remainder
    }

    function distributeBuyFee(address _sender, uint256 _fee) internal virtual {
        uint256 _remainder = _fee.mod(3);
        uint256 _distFee = _fee.div(3);
        super._transfer(_sender, addressForMarketing, _distFee);
        super._transfer(_sender, addressForRewardAndCompensation, _distFee);

        super._transfer(_sender, addressForBuyBack, _distFee);
        swapTokensForEth(_distFee, addressForBuyBack);

        super._transfer(_sender, owner(), _remainder); // give to the owner the remainder
    }

    function distributeNormalFee(address _sender, uint256 _fee) internal virtual {
        uint256 _reDistribution = _fee.div(2);
        uint256 _reDistributionRem = _fee.mod(2);

        super._transfer(_sender, addressForBuyBack, _reDistribution);  
        //swapTokensForEth(_reDistribution, addressForBuyBack);

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

    // private
    function transferContractToken(address _token, address _to) public onlyOwner returns(bool _sent){
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }
}