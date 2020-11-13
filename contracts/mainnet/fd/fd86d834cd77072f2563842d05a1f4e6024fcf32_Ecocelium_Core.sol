// SPDX-License-Identifier: MIT

/*

███████╗░█████╗░░█████╗░░█████╗░███████╗██╗░░░░░██╗██╗░░░██╗███╗░░░███╗
██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██║░░░░░██║██║░░░██║████╗░████║
█████╗░░██║░░╚═╝██║░░██║██║░░╚═╝█████╗░░██║░░░░░██║██║░░░██║██╔████╔██║
██╔══╝░░██║░░██╗██║░░██║██║░░██╗██╔══╝░░██║░░░░░██║██║░░░██║██║╚██╔╝██║
███████╗╚█████╔╝╚█████╔╝╚█████╔╝███████╗███████╗██║╚██████╔╝██║░╚═╝░██║
╚══════╝░╚════╝░░╚════╝░░╚════╝░╚══════╝╚══════╝╚═╝░╚═════╝░╚═╝░░░░░╚═╝

Brought to you by Kryptual Team */

pragma solidity ^0.6.0;
import "./EcoSub.sol";

contract Ecocelium is Initializable{

    address public owner;
    IAbacusOracle abacus;
    EcoceliumTokenManager ETM;
    EcoceliumSub ES;
    EcoceliumSub1 ES1;
    string public ECO;
    
    function initialize(address _owner,address ETMaddress,address AbacusAddress,address ESaddress, address ES1address, string memory _ECO)public payable initializer {
        owner = _owner;
        ETM = EcoceliumTokenManager(ETMaddress);
        abacus = IAbacusOracle(AbacusAddress);//0x323f81D9F57d2c3d5555b14d90651aCDc03F9d52
        ES = EcoceliumSub(ESaddress);
        ES1 = EcoceliumSub1(ES1address);
        ES.initializeAddress(ETMaddress,AbacusAddress,ES1address);
        ECO = _ECO;
    }
    
    function changeETMaddress(address ETMaddress) public{
        require(msg.sender == owner,"not owner");
        ETM = EcoceliumTokenManager(ETMaddress);
    }    
    function changeAbacusaddress(address Abacusaddress) public{
        require(msg.sender == owner,"not owner");
        abacus = IAbacusOracle(Abacusaddress);
    }   
    
    function changeESaddress(address ESaddress) public{
        require(msg.sender == owner,"not owner");
        ES = EcoceliumSub(ESaddress);
    }
    
     function changeES1address(address ES1address) public{
        require(msg.sender == owner,"not owner");
        ES1 = EcoceliumSub1(ES1address);
    }
    
    function changeOwner(address _owner) public{
        require(msg.sender==owner);
        owner = _owner;
    }
    
     /*===========Main functions============
    -------------------------------------*/   

    function Deposit(string memory rtoken, uint _amount) external {
        address _msgSender = msg.sender;
        address _contractAddress = address(this);
        string memory wtoken = ETM.getWrapped(rtoken);
        uint amount = _deposit(rtoken, _amount, _msgSender, _contractAddress, wtoken);
        ES.zeroDepositorPush(_msgSender, wtoken, _amount);
        wERC20(ETM.getwTokenAddress(ETM.getWrapped(rtoken))).mint(_msgSender, amount);
        wERC20(ETM.getwTokenAddress(ETM.getWrapped(rtoken))).lock(_msgSender, amount);
    }
    
    function _deposit(string memory rtoken,uint _amount, address msgSender, address _contractAddress, string memory wtoken) internal returns(uint) {
        require(ETM.getrTokenAddress(rtoken) != address(0) && ETM.getwTokenAddress(wtoken) != address(0),"not supported");
        (wERC20 wToken,ERC20Basic rToken)=(wERC20(ETM.getwTokenAddress(wtoken)),ERC20Basic(ETM.getrTokenAddress(rtoken))); 
        uint amount = _amount*(10**uint(wToken.decimals()));
        require(rToken.allowance(msgSender,_contractAddress) >= amount,"set allowance");
        rToken.transferFrom(msgSender,_contractAddress,amount);
        ES1.emitSwap(msgSender,rtoken,wtoken,_amount);
        return amount;
    }
    
    function depositAndOrder(address userAddress,string memory rtoken ,uint _amount,uint _duration,uint _yield) external {
        require(msg.sender == userAddress);
        _deposit(rtoken, _amount, userAddress, address(this), ETM.getWrapped(rtoken));
        ES.createOrder(userAddress, ETM.getWrapped(rtoken), _amount, _duration, _yield, address(this));
    }
    
    function createOrder(address userAddress,string memory _tokenSymbol ,uint _amount,uint _duration,uint _yield) public {
        require(msg.sender == userAddress);
        string memory wtoken = ETM.getWrapped(_tokenSymbol);
        if(ES.getUserDepositsbyToken(userAddress, wtoken)  > _amount )  {  
            ES.zeroDepositorPop(userAddress, wtoken , _amount);
            ES.createOrder(userAddress, wtoken, _amount, _duration, _yield, address(this));
        }
    }
    
    function getAggEcoBalance(address userAddress) public view returns(uint) {
        return wERC20(ETM.getwTokenAddress(ES1.WRAP_ECO_SYMBOL())).balanceOf(userAddress) + ES.getECOEarnings(userAddress);
    }
    
    function _borrowOrder(uint64 _orderId, uint _amount, uint _duration) public {
        ES.borrow(_orderId,_amount,_duration,msg.sender,address(this));
    }
    
    function payDueOrder(uint64 _orderId,uint _duration) external{
        ES.payDue(_orderId,_duration,msg.sender);
    }
    
    function clearBorrow(string memory rtoken, uint _amount) external{
        address msgSender = msg.sender;
        address _contractAddress = address(this);
        string memory wtoken = ETM.getWrapped(rtoken);
        require(ETM.getrTokenAddress(rtoken) != address(0) && ETM.getwTokenAddress(wtoken) != address(0),"not supported");
        (wERC20 wToken,ERC20Basic rToken)=(wERC20(ETM.getwTokenAddress(wtoken)),ERC20Basic(ETM.getrTokenAddress(rtoken)));
        uint amount = _amount*(10**uint(wToken.decimals()));
        require(rToken.allowance(msgSender,_contractAddress) >= amount,"set allowance");
        rToken.transferFrom(msgSender,_contractAddress,amount);
        uint dues = ES.zeroBorrowPop(msgSender, wtoken, _amount);
        ERC20Basic(ETM.getrTokenAddress(ECO)).transferFrom(msgSender, _contractAddress, dues);
    }
    
    function Borrow(uint _amount, string memory _tokenSymbol) public {
        ES.borrowZero(_amount, ETM.getWrapped(_tokenSymbol) ,msg.sender,address(this));
    }
    
    function SwapWrapToWrap(string memory token1,string memory token2, uint token1amount)  external returns(uint) {
        address msgSender = msg.sender;
        (uint token1price,uint token2price) = (fetchTokenPrice(token1),fetchTokenPrice(token2));
        uint token2amount = (token1amount*token1price*(100-ES1.swapFee()))/token2price/100;
        (wERC20 Token1,wERC20 Token2) = (wERC20(ETM.getwTokenAddress(token1)),wERC20(ETM.getwTokenAddress(token2)));
        ES1.unlockDeposit(msgSender, token1amount, token1);
        Token1.burnFrom(msgSender,token1amount*(10**uint(Token1.decimals())));
        ES.zeroDepositorPop(msgSender,token1,token1amount);
        Token2.mint(msgSender,token2amount*(10**uint(Token2.decimals())));
        Token2.lock(msgSender, token2amount*(10**uint(Token2.decimals())));
        ES1.setOwnerFeeVault(token1, token1price*ES1.swapFee()/100);
        ES.zeroDepositorPush(msgSender, token2,token2amount);
        ES1.emitSwap(msgSender,token1,token2,token2amount);
        return token2amount;
    }
    
    function orderExpired(uint64 _orderId) external {
        ES.orderExpired(_orderId);
    }    

    function dueCheck(uint64 _orderId,address borrower,uint month) external {
        ES.dueCheck(_orderId,borrower,month,address(this));
    }
    
    function cancelOrder(uint64 _orderId) public{
        ES.cancelOrder(_orderId);
    }
    
    receive() external payable {  }

    /*==============Helpers============
    ---------------------------------*/    
    
    function orderMonthlyDue(uint64 _orderId, address _borrower,uint _duration) public view returns(uint){
        return ES.orderMonthlyDue(_orderId,_borrower,_duration);
    }
    
    function updateFees(uint _swapFee,uint _tradeFee,uint _rewardFee) public{
        require(msg.sender == owner);
        ES1.updateFees(_swapFee,_tradeFee,_rewardFee);
    }

    function setCSDpercent(uint percent) public {
        require(msg.sender == owner);        
        ES1.setCSDpercent(percent);
    }
    
    function setWRAP_ECO_SYMBOL(string memory _symbol) internal {
        require(msg.sender == owner);
        ECO = _symbol;
        ES1.setWRAP_ECO_SYMBOL(_symbol);
    }
    
    function getOrderIds() public view returns(uint [] memory){
        return ES.getOrderIds();
    }
    
    // function getOrder( uint64 investmentId) public view returns(uint time, uint duration, uint amount,  uint yield, string memory token, Status isActive){
    //     return (Orders[investmentId].time,Orders[investmentId].duration,Orders[investmentId].amount,Orders[investmentId].yield,Orders[investmentId].token,Orders[investmentId].status);
    // }
    
    /*function getUserBorrowedOrders(address userAddress) public view returns(uint64 [] memory borrowedOrders){
        return ES.getUserBorrowedOrders(userAddress);
    } */
    
    /*function getBorrowersOfOrder(uint64 _orderId) public view returns(address[] memory borrowers){
        return ES.getBorrowersOfOrder(_orderId);
    }
    
    function getBorrowDetails(uint64 _orderId,address borrower) public view returns(uint amount,uint duration,uint dated,uint _duesPaid ){
        (amount,duration,dated,_duesPaid)=ES.getBorrowDetails(_orderId,borrower);
        return (amount,duration,dated,_duesPaid);
    } */
    
    function fetchTokenPrice(string memory _tokenSymbol) public view returns(uint64){
        return ES.fetchTokenPrice(_tokenSymbol);
    }
    
    /*function isWithdrawEligible(address _msgSender, string memory _token, uint _amount) public view returns (bool) {
        require(msg.sender == owner);        
        //to be written
        uint tokenUsdValue = _amount*fetchTokenPrice(_token)/(10**8);
        uint buypower = ES.getbuyPower(_msgSender);
        if((buypower*(100+ES1.CDSpercent())/100) > tokenUsdValue )
            return true;
    }*/
    
    function Withdraw(string memory to, uint _amount) external {
        address msgSender = msg.sender;
        string memory from = ETM.getWrapped(to);
        require(ETM.getwTokenAddress(from) != address(0) && ETM.getrTokenAddress(to) != address(0),"not supported");
        require(!ES1.isUserLocked(msgSender), "Your Address is Locked Pay Dues");
        //require(isWithdrawEligible(msgSender, to, _amount) , "Not Eligible for Withdraw");
        require(((ES.getbuyPower(msgSender)*(100+ES1.CDSpercent())/100) > (_amount*fetchTokenPrice(to)/(10**8)) ), "Not Eligible for Withdraw");
        wERC20 wToken = wERC20(ETM.getwTokenAddress(to));
        uint amount = _amount*(10**uint(wToken.decimals()));
        uint amountLeft;
        if(keccak256(abi.encodePacked(to)) == keccak256(abi.encodePacked(ES1.WRAP_ECO_SYMBOL()))) {
            require(wToken.balanceOf(msgSender) + ES.getECOEarnings(msgSender) >= amount,"Insufficient Balance");
            if(wToken.balanceOf(msgSender)>=amount) {
                _withdraw(msgSender, from, amount, to, _amount);
            } else {
                if(wToken.balanceOf(msgSender)<amount)    
                    amountLeft = amount - wToken.balanceOf(msgSender);
                    _withdraw(msgSender, from, wToken.balanceOf(msgSender), to, (wToken.balanceOf(msgSender)/(10**uint(wToken.decimals()))));
                    ES.redeemEcoEarning(msgSender,amountLeft);
            }
        }
        else {
            //uint locked = ES.getUserLockedAmount(from, msgSender);
            require(wToken.balanceOf(msgSender) >= amount,"Insufficient Balance");
            _withdraw(msgSender, from, amount, to, _amount);
        }
        ES1.emitSwap(msgSender,from,to,_amount);
    }
    
    function _withdraw(address msgSender, string memory from, uint amount, string memory to, uint _amount ) internal {
                
        (wERC20 wToken,ERC20Basic rToken) = (wERC20(ETM.getwTokenAddress(to)),ERC20Basic(ETM.getrTokenAddress(from)));         
        ES1.unlockDeposit(msgSender,amount, from);
        wToken.burnFrom(msgSender,amount);
        ES1.setOwnerFeeVault(to,(amount*ES1.swapFee())/100);
        ES.zeroDepositorPop(msgSender,from,_amount);
        uint newAmount = amount - (amount*ES1.swapFee())/100;
        rToken.transfer(msgSender,newAmount);
    }
}
    