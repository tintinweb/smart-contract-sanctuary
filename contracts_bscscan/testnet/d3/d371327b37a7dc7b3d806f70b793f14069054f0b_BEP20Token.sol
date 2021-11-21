/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

pragma solidity >= 0.7.0 < 0.9.0;
// SPDX-License-Identifier: MIT
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library SafeMath16 {

    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        require(b <= a, errorMessage);
        uint16 c = a - b;
        return c;
    }

    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        require(b > 0, errorMessage);
        uint16 c = a / b;
        return c;
    }

    function mod(uint16 a, uint16 b) internal pure returns (uint16) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint16 a, uint16 b, string memory errorMessage) internal pure returns (uint16) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library SafeMath8 {
    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b <= a, errorMessage);
        uint8 c = a - b;
        return c;
    }

    function mul(uint8 a, uint8 b) internal pure returns (uint8) {
        if (a == 0) {
            return 0;
        }
        uint8 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint8 a, uint8 b) internal pure returns (uint8) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b > 0, errorMessage);
        uint8 c = a / b;
        return c;
    }

    function mod(uint8 a, uint8 b) internal pure returns (uint8) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract IBEP20FixedData {
    uint256 internal fuckingTotalSupply;
    uint8 private fuckingDecimal;
    string private fuckingSymbol;
    string private fuckingName;
    
    constructor()  {
        fuckingName = "test2_0";
        fuckingSymbol = "test2_0";
        fuckingDecimal = 9;
        fuckingTotalSupply = 1*10**18;//1 000 000 000
    }

    function totalSupply() external view returns (uint256){
        return fuckingTotalSupply;
    }

    function decimals() external view returns (uint8){
        return fuckingDecimal;
    }

    function symbol() external view returns (string memory){
        return fuckingSymbol;
    }

    function name() external view returns (string memory){
        return fuckingName;
    }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract IBEP20BankData is IBEP20FixedData{
    using SafeMath for uint256;

    constructor()  {
    }
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) external view returns(uint256){
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns(uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function approve(address spender, uint256 amount) external returns(bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract IBEP20Fee is IBEP20BankData,Ownable {
    using SafeMath16 for uint16;
    using SafeMath for uint256;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event CalculatedTax(uint256[] indexed taxFees, uint totalTax );
    event Log(string indexed info, uint data);
    event Log(string indexed info, uint256[] data);
    IRouter router;

    uint divider;
    bool newTaxAddFunction;
    bool limitDev;
    uint maxTax;
    enum ActionTypes{ BNB, ORIGINAL,LIQUIDITY }

    struct feeStructure {
        string taxTitle;
        uint16 taxAmount;
        address taxAddress;
        uint thresholdToActivate;
        ActionTypes typeOfAction;
    }
    feeStructure[] allFees;

    constructor()  {
    }
    
    
    function calculateAndPayUp(address from, address to,uint amount) internal{
        
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount);
        emit Transfer(from, to,amount);
        /*
        (uint256[] memory taxFees,uint totalTax)=calculateTheHighwayRobberyTax(amount);
        emit CalculatedTax(taxFees,totalTax);
        
        uint remaining = amount=amount.sub(totalTax);
        _balances[to]=_balances[to].add(remaining);

        for(uint counter=0;counter<taxFees.length;counter++){
            if(taxFees[counter]!=0 ){
                _balances[allFees[counter].taxAddress]=
                _balances[allFees[counter].taxAddress]
                .add(taxFees[counter]);
            }
            if(_balances[allFees[counter].taxAddress]>=allFees[counter].thresholdToActivate){
                if(allFees[counter].typeOfAction==ActionTypes.BNB){
                    swapTokensForBNB(_balances[allFees[counter].taxAddress]);
                    _balances[allFees[counter].taxAddress]=0;
                }
                if(allFees[counter].typeOfAction==ActionTypes.LIQUIDITY){
                    uint256 initialBalance = address(this).balance;
                    swapTokensForBNB(_balances[allFees[counter].taxAddress].div(2));
                    uint256 deltaBalance = address(this).balance - initialBalance;
                    _balances[allFees[counter].taxAddress]=_balances[allFees[counter].taxAddress].sub(_balances[allFees[counter].taxAddress].div(2));
                    addLiquidity(_balances[allFees[counter].taxAddress],deltaBalance);
                    _balances[allFees[counter].taxAddress]=0;
                }
            }
        }*/
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);

    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function getAllFees(address account) internal view returns(feeStructure[] memory){
        return allFees;
    }
    function getTotalTax() internal view returns(uint16){
        uint16 totalTaxData=0;
        for(uint counter=0;counter<allFees.length;counter++){
            totalTaxData=totalTaxData.add(allFees[counter].taxAmount);
        }
        return totalTaxData;
    }

    function calculateTheHighwayRobberyTax(uint256 amount) external  returns (uint256[] memory,uint256){
        uint[] memory feesToPay;
        emit Log("Divider",divider);
        
        feesToPay[0]=0;
        return (feesToPay,0);
            
        if(allFees.length==0){
            feesToPay[0]=0;
            return (feesToPay,0);
        }
        uint256 totalFees=0;
        for(uint counter=0;counter<allFees.length;counter++){
            uint feeAmount=amount.mul(allFees[counter].taxAmount).div(divider);
            emit Log("feeAmount",feeAmount);
            totalFees=totalFees.add(feeAmount);
            feesToPay[counter]=feeAmount;
        }
        emit Log("totalFees",totalFees);
        emit Log("feesToPay",feesToPay);
        return (feesToPay,totalFees);
    }

    function changeTax(string memory taxTitleData,uint16 taxAmount) internal {
        for(uint counter=0;counter<allFees.length;counter++){
            if( keccak256(bytes(allFees[counter].taxTitle)) == keccak256(bytes(taxTitleData))){
                allFees[counter].taxAmount=taxAmount;
                break;
            }
        }
    }

    function changeThreshold(string memory taxTitleData,uint thresholdData) internal{
        for(uint counter=0;counter<allFees.length;counter++){
            if( keccak256(bytes(allFees[counter].taxTitle)) == keccak256(bytes(taxTitleData))){
                allFees[counter].thresholdToActivate=thresholdData;
                break;
            }
        }
    }

    function changeAddress(string memory taxTitleData,address addressData) internal{
        for(uint counter=0;counter<allFees.length;counter++){
            if( keccak256(bytes(allFees[counter].taxTitle)) == keccak256(bytes(taxTitleData))){
                allFees[counter].taxAddress=addressData;
                break;
            }
        }
    }

    function changeActionType(string memory taxTitleData,ActionTypes actionTypeData) internal {
        for(uint counter=0;counter<allFees.length;counter++){
            if( keccak256(bytes(allFees[counter].taxTitle)) == keccak256(bytes(taxTitleData))){
                allFees[counter].typeOfAction=actionTypeData;
                break;
            }
        }
    }

    function addTax(string memory taxTitleData, uint16 taxAmount,address taxAddress,uint thresholdToActivate,ActionTypes actionTypeData) internal {
        require(newTaxAddFunction,"This contract does not support adding new Tax types");
        for(uint counter=0;counter<allFees.length;counter++){
            require( keccak256(bytes(allFees[counter].taxTitle)) != keccak256(bytes(taxTitleData)),
            "No tax with same name is allowed.");
        }
        allFees.push(feeStructure(taxTitleData,taxAmount,taxAddress,thresholdToActivate,actionTypeData));
    }

    function removeTax(string memory taxTitleData) internal {
         for(uint counter=0;counter<allFees.length;counter++){
            if( keccak256(bytes(allFees[counter].taxTitle)) == keccak256(bytes(taxTitleData))){
                 if (counter != (allFees.length - 1)) {
                    allFees[counter] = allFees[allFees.length - 1];
                }
                allFees.pop();
                break;
            }
        }
    }

    function taxMultiplier(uint16 multiplier) internal {
        if(limitDev){
            require(getTotalTax().mul(multiplier)<=maxTax,"We cannot allow you to increate tax");
        }
        for(uint counter=0;counter<allFees.length;counter++){
            allFees[counter].taxAmount = allFees[counter].taxAmount.mul(multiplier);
        } 
    }
    function taxDivider(uint16 taxDivider) internal {
        for(uint counter=0;counter<allFees.length;counter++){
            allFees[counter].taxAmount = allFees[counter].taxAmount.div(taxDivider);
        } 
    }

} 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract BEP20Token is  IBEP20Fee{
    
    
    using SafeMath for uint256;
    address pancakeSwapPair;
    address pancakeRouter;
  
    address[] inserting;

    constructor(){
        _balances[msg.sender] = fuckingTotalSupply;
        emit Transfer(address(0), msg.sender, fuckingTotalSupply);
        inserting.push(0xac4B5a779a15E40cEA5D0d76a049e928e6DC4D5b);
        allFees.push(feeStructure("PrivateInvestors",12,0xac4B5a779a15E40cEA5D0d76a049e928e6DC4D5b,1000000,ActionTypes.ORIGINAL));
        divider=1000;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
        
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "BEP20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address"); 
        require(_balances[sender] >= amount, "Ser you dont have the token.");
        calculateAndPayUp(sender,recipient,amount);
        //emit Transfer(sender, recipient, amount);    
    }
    
    function getAllFees() external view returns (string memory) {
        feeStructure memory feeData=feeStructure("PrivateInvestors",12,0xac4B5a779a15E40cEA5D0d76a049e928e6DC4D5b,1000000,ActionTypes.ORIGINAL);
        feeStructure memory feeData1=feeStructure("PrivateInvestor1s",12,0xac4B5a779a15E40cEA5D0d76a049e928e6DC4D5b,1000000,ActionTypes.ORIGINAL);
        
        string[] memory data = new string[](2);
        //,"-",feeData.taxAmount,"-",feeData.taxAddress,"-",feeData.thresholdToActivate,"-",feeData.typeOfAction
        //,"-",feeData1.taxAmount,"-",feeData1.taxAddress,"-",feeData1.thresholdToActivate,"-",feeData1.typeOfAction
        data[0]=string(abi.encodePacked(0xac4B5a779a15E40cEA5D0d76a049e928e6DC4D5b));
        //data[1]=string(abi.encodePacked(feeData1.taxTitle));
       return data[0];
    } 
    
    function getDivider() external view returns (uint256) {
       return divider;
    }  
    function checkCalculateTheHighwayRobberyTax(uint256 amount) external view returns (uint256[] memory,uint256) {
        if(allFees.length==0){
            uint256[] memory feesToPay1= new  uint256[](1);
            feesToPay1[0]=0;
            return (feesToPay1,0);
        }
        uint256[] memory feesToPay= new uint256[](allFees.length);
        uint256 totalFees=0;
        for(uint counter=0;counter<allFees.length;counter++){
            uint feeAmount=amount.mul(allFees[counter].taxAmount).div(divider);
            //emit Log("feeAmount",feeAmount);
            totalFees=totalFees.add(feeAmount);
            feesToPay[counter]=feeAmount;
        }
        //emit Log("totalFees",totalFees);
        //emit Log("feesToPay",feesToPay);
        return (feesToPay,totalFees);
            
    }   
    function someAddress() external view returns (address[] memory ) {
        return inserting;
    }  
}