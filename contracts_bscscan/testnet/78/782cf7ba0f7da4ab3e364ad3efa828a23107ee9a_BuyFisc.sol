pragma solidity 0.6.2;
 
import "./SafeMath.sol";
import "./SafeBEP20.sol";
 
contract BuyFisc {
    using SafeMath for uint256;
    using SafeBEP20 for address;
 
    address private owner;
    address private  recAddress; 
    bool _isRun = true;

    address _TokenFisc;
    address _TokenUsdt; 
 
    uint public _fiscPercent;
    uint public _usdPercent;
    uint256 public _minUSD;
 
    constructor (
        address irecAddress,
        address FiscTokenAddress,
	address UsdtTokenAddress,
	uint256 minUSD
    ) public 
    {
        owner = msg.sender;
        recAddress  = address(irecAddress);
        _TokenFisc = address(FiscTokenAddress);
        _TokenUsdt = address(UsdtTokenAddress);
        _minUSD = minUSD;
        _fiscPercent = 80;
        _usdPercent = 100;
    }

    //  token (FISC) --  
    function buyToken( uint256 usdtAmount) public   { 
        require(_isRun , "contract is Temporarily stop.");
        require(usdtAmount >= _minUSD, "Less than minimum."); 

        uint256 currentFiscAmount = IBEP20(_TokenFisc).balanceOf(address(this));
	uint256 valueUsdt = currentFiscAmount.mul(_fiscPercent).div(_usdPercent);
        require(valueUsdt >= usdtAmount, "Contract Fisc balance is insufficient.");

        uint256 currentUsdtAmount = IBEP20(_TokenUsdt).balanceOf(msg.sender);
        require(currentUsdtAmount >= usdtAmount, "Your Usdt balance is insufficient.");
	uint256 valueFisc = usdtAmount.div(_fiscPercent).mul(_usdPercent);
 
        _TokenUsdt.safeTransferFrom(msg.sender, recAddress, usdtAmount);
        _TokenFisc.safeTransfer(address(msg.sender),valueFisc);
    }
 
    // input profit and profit sharing  ------- 
    function profit( uint256 FiscAmount) public onlyOwner{ 
        require(FiscAmount > 0, "FiscAmount is zero");
        uint256 currentFiscAmount=IBEP20(_TokenFisc).balanceOf(msg.sender);
        require(currentFiscAmount >= FiscAmount, "currentFiscAmount is less FiscAmount");
        _TokenFisc.safeTransferFrom(address(msg.sender),address(this),FiscAmount);
    }
 
    // -------- check is succ  
    function getAllFisc() public onlyOwner {
        require(address(msg.sender) == address(tx.origin), "no contract");
        uint256 currentFiscAmount=IBEP20(_TokenFisc).balanceOf(address(this));
        _TokenFisc.safeTransfer(address(msg.sender),currentFiscAmount);
    }
    function getFisc(uint256 FiscAmount) public onlyOwner {
        require(address(msg.sender) == address(tx.origin), "no contract");
        uint256 currentFiscAmount=IBEP20(_TokenFisc).balanceOf(address(this));
        require(currentFiscAmount >= FiscAmount, "FiscAmount is too big");
        _TokenFisc.safeTransfer(address(msg.sender),FiscAmount);
    }

    function changeOwner(address paramOwner) public onlyOwner {
        require(paramOwner != address(0));
        owner = paramOwner;
    }
 
    function changeIsRun(bool isRun) public onlyOwner {
        _isRun= isRun;
    }
    function changeMinUSD(uint256 minUSD) public onlyOwner {
        _minUSD= minUSD;
    }
    function changeFiscPercent(uint FiscPercent) public onlyOwner {
        _fiscPercent= FiscPercent;
    }
    function changeRecAddress(address rAddress) public onlyOwner {
        recAddress= rAddress;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function isRun() public view returns (bool) {
        return _isRun;
    }
 
}