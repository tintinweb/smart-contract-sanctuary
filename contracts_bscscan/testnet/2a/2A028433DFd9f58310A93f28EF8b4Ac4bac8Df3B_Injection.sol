/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^ 0.8.3;
abstract contract UsdtToken{
    function transferFrom(address _from, address _to, uint256 _value) external virtual returns (bool success);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
}

abstract contract AbsToken{
    function transferFrom(address _from, address _to, uint256 _value) external virtual returns (bool success);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
}

abstract contract PancakePair{
    function getReserves() external virtual view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

contract Comn {
    address internal owner;//合约创建者
    address internal approveAddress;//授权地址

    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;
    uint256 internal _status;
    modifier onlyOwner(){
        require(msg.sender == owner,"Modifier: The caller is not the creator");
        _;
    }
    modifier onlyApprove(){
        require(msg.sender == approveAddress || msg.sender == owner,"Modifier: The caller is not the approveAddress");
        _;
    }
    modifier nonReentrant() {//防重入攻击
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
    constructor() {
        owner = msg.sender;
        _status = _NOT_ENTERED;
    }
    /*
     * @dev 设置授权的地址
     * @param externalAddress 外部地址
     */
    function setApproveAddress(address externalAddress) public onlyOwner{
        approveAddress = externalAddress;
    }
    /*
     * @dev 获取授权的地址
     */
    function getApproveAddress() internal view returns(address){
        return approveAddress;
    }
    //当一个合约需要进行以太交易时，需要加两个函数
    fallback () payable external {}
    receive () payable external {}
}

contract Util {

    /*
     * @dev 转换位
     * @param price 价格
     * @param decimals 代币的精度
     */
    function toWei(uint256 price, uint decimals) public pure returns (uint256){
        uint256 amount = price * (10 ** uint256(decimals));
        return amount;
    }

    /*
     * @dev 回退位
     * @param price 价格
     * @param decimals 代币的精度
     */
    function backWei(uint256 price, uint decimals) public pure returns (uint256){
        uint256 amount = price / (10 ** uint256(decimals));
        return amount;
    }

    /*
     * @dev 浮点类型除法 a/b
     * @param a 被除数
     * @param b 除数
     * @param decimals 精度
     */
    function mathDivisionToFloat(uint256 a, uint256 b,uint decimals) public pure returns (uint256){
        uint256 aPlus = a * (10 ** uint256(decimals));
        uint256 amount = aPlus/b;
        return amount;
    }
}

//注入流动性合约
contract Injection is Comn,Util{
    address burnAddress = address(0x000000000000000000000000000000000000dEaD);/* 燃烧地址 */
    uint scale;//交易ABS占比 (ABS占USDT的百分比)

    mapping(address => uint) injectionUsdtMapping; //<地址,注入的USDT数量>
    mapping(address => uint) injectionAbsMapping; //<地址,注入的Abs数量>

    uint usdtDecimals;//USDT代币的精度
    UsdtToken usdt;

    uint absDecimals;//ABS代币的精度
    AbsToken abs;

    PancakePair pancakePair;//ABS/USDT 交易对合约

    /*
     * @dev 设置 | 创建者调用 | 设置平台归集USDT代币信息
     * @param contractAddress 合约地址
     * @param decimals 代币精度
     */
    function setPlatformUsdtToken(address contractAddress,uint decimals) public onlyOwner {
        usdtDecimals = decimals;
        usdt = UsdtToken(contractAddress);
    }

    /*
     * @dev 设置 | 创建者调用 | 设置平台归集ABS地址
     * @param contractAddress 合约地址
     * @param decimals 代币精度
     */
    function setPlatformAbsToken(address contractAddress,uint decimals) public onlyOwner {
        absDecimals = decimals;
        abs = AbsToken(contractAddress);
    }

    /*
     * @dev 设置 | 创建者调用 | 设置交易对合约
     * @param contractAddress 合约地址
     */
    function setPancakePairContract(address contractAddress) public onlyOwner {
        pancakePair = PancakePair(contractAddress);
    }

    /*
     * @dev 设置 | 授权者调用 | 设置交易ABS占比
     * @param _scale 交易ABS占比 (ABS占USDT的百分比)
     */
    function setScale(uint _scale) public onlyApprove {
        require(_scale > 0,"Transaction proportion must be greater than 0");
        require(_scale < 100,"Transaction proportion must be less than 100");
        scale = _scale;
    }

    /*
     * @dev  修改 | 授权者调用 | 取出平台的ABS
     * @param outAddress 取出地址
     * @param amount 交易金额
     */
    function outAbs(address outAddress,uint amount) public onlyApprove{
        uint outAmount = Util.toWei(amount,absDecimals);
        abs.transfer(outAddress,outAmount);
    }

    /*
     * @dev  修改 | 授权者调用 | 取出平台的USDT
     * @param outAddress 取出地址
     * @param amount 交易金额
     */
    function outUsdt(address outAddress,uint amount) public onlyApprove{
        uint outAmount = Util.toWei(amount,usdtDecimals);
        usdt.transfer(outAddress,outAmount);
    }

    /*
     * @dev  查询 | 所有人调用 | 获取Abs/Usdt交易对信息
     */
    function queryAbs2UsdtPancakePair() public view returns (uint112, uint112, uint256, uint256){
        uint112 usdtSum;//LP池中,usdt总和
        uint112 absSum;//LP池中,abs总和
        uint32 lastTime;//最后一次交易时间
        (usdtSum,absSum,lastTime) = pancakePair.getReserves();

        uint256 absToUsdtPrice = Util.mathDivisionToFloat(usdtSum,absSum,usdtDecimals);//1个Abs等值的Usdt数量
        uint256 usdtToAbsPrice = Util.mathDivisionToFloat(absSum,usdtSum,absDecimals);//1个Usdt等值的Abs数量
        return (usdtSum,absSum,absToUsdtPrice,usdtToAbsPrice);
    }

    /*
     * @dev  查询 | 所有人调用 | 获取1个Abs等值的Usdt数量
     */
    function queryAbs2UsdtPrice() public view returns (uint256){
        uint112 usdtSum;//LP池中,usdt总和
        uint112 absSum;//LP池中,abs总和
        uint32 lastTime;//最后一次交易时间
        (usdtSum,absSum,lastTime) = pancakePair.getReserves();

        uint256 absToUsdtPrice = Util.mathDivisionToFloat(usdtSum,absSum,usdtDecimals);//1个Abs等值的Usdt数量
        return absToUsdtPrice;
    }

    /*
     * @dev  查询 | 所有人调用 | 获取1个Usdt等值的Abs数量
     */
    function queryUsdt2AbsPrice() public view returns (uint256){
        uint112 usdtSum;//LP池中,usdt总和
        uint112 absSum;//LP池中,abs总和
        uint32 lastTime;//最后一次交易时间
        (usdtSum,absSum,lastTime) = pancakePair.getReserves();

        uint256 usdtToAbsPrice = Util.mathDivisionToFloat(absSum,usdtSum,absDecimals);//1个Usdt等值的Abs数量
        return usdtToAbsPrice;
    }

    /*
     * @dev  查询 | 所有人调用 | 注入的USDT数量余额
     */
    function queryInjectionUsdtBalance() public view returns (uint256){
        uint usdtBalance = injectionUsdtMapping[msg.sender];
        return usdtBalance;
    }

    /*
     * @dev 创建 | 所有人调用 | 注入流动性
     * @param usdtAmountToWei USDT金额
     */
    function injectionLP(uint usdtAmountToWei) public nonReentrant {
        if(usdtAmountToWei <= 0){ _status = _NOT_ENTERED; revert("Transaction amount must be greater than 0"); }
        uint absUsdtAmountToWei = usdtAmountToWei * scale / 100;
        //        uint price = queryUsdt2AbsPrice();//获取1个Usdt等值的Abs价格
        uint price = 3114923183207947000;//获取1个Usdt等值的Abs价格
        uint absAmountToWei = Util.backWei(price * absUsdtAmountToWei,absDecimals);

        // 转USDT给平台地址
        usdt.transferFrom(msg.sender, address (this), usdtAmountToWei);
        // 转ABS给平台地址
        abs.transferFrom(msg.sender, address (this), absAmountToWei);
        /*销毁价值平台收入等值USDT的ABS数量*/
        abs.transfer(burnAddress,absAmountToWei);

        injectionUsdtMapping[msg.sender] = injectionUsdtMapping[msg.sender] + usdtAmountToWei;
        injectionAbsMapping[msg.sender] = injectionAbsMapping[msg.sender] + absAmountToWei;
    }

    /*
     * @dev 撤销 | 所有人调用 | 撤回USDT
     * @param usdtAmountToWei USDT金额
     */
    function retrieveUsdt(uint usdtAmountToWei) public nonReentrant {
        if(usdtAmountToWei <= 0){ _status = _NOT_ENTERED; revert("Transaction amount must be greater than 0"); }
        if(injectionUsdtMapping[msg.sender] <= usdtAmountToWei){ _status = _NOT_ENTERED; revert("Insufficient usdt"); }

        /* 撤回USDT */
        usdt.transfer(msg.sender,usdtAmountToWei);
        injectionUsdtMapping[msg.sender] = injectionUsdtMapping[msg.sender] - usdtAmountToWei;
    }

}