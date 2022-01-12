pragma solidity >=0.6.0;

import './Interfaces.sol';

contract MyPrivateWarehouse {

    address private _owner;
    function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
    }

    constructor() public {
    address msgSender = _msgSender();
    _owner = msgSender;
    }

     modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _owner = newOwner;
  }

    address pancakerouterv2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address pancakefactory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address PancakeSwapMainStakingContract = 0x73feaa1eE314F8c655E354234017bE2193C9E24E;
    address wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

     // Only for same decimals 
    function BusdtoTokenDirectAuto(uint amountIn, address targetToken) public onlyOwner returns(bool, bytes memory){
     address to =  msg.sender;
     uint deadline = block.timestamp + 1 days;
     address[] memory path = new address[](2);
     path[0] = busd;
     path[1] = targetToken;
     uint amountOutMin = 100000 * amountIn / (4 * busdPerTokenRate1(targetToken) / 3);
     approve1(pancakerouterv2,amountIn);
     executeExactTokensForTokenscall(amountIn,amountOutMin,path,to,deadline);
     }

     // Only for same decimals 
    function BusdtoTokenViaBnbAuto(uint amountIn, address targetToken) public onlyOwner returns(bool, bytes memory){
     address to =  msg.sender;
     uint deadline = block.timestamp + 1 days;
     address[] memory path = new address[](3);
     path[0] = busd;
     path[1] = wbnb;
     path[2] = targetToken;
     uint amountOutMin = 100000 * amountIn / (4 * busdPerTokenRate2(targetToken) / 3);
     approve1(pancakerouterv2,amountIn);
     executeExactTokensForTokenscall(amountIn,amountOutMin,path,to,deadline);
    }
    
     // Only for same decimals 
     function TokentoBusdDirectAuto(uint amountIn, address targetToken) public onlyOwner returns(bool, bytes memory){
     address to =  msg.sender;
     uint deadline = block.timestamp + 1 days;
     address[] memory path = new address[](2);
     path[0] = targetToken;
     path[1] = busd;
     uint amountOutMin = (3 * busdPerTokenRate1(targetToken) / 4) / amountIn / 100000;
     approve2(targetToken,pancakerouterv2,amountIn);
     executeExactTokensForTokenscall(amountIn,amountOutMin,path,to,deadline);
     }

    // Only for same decimals 
    function TokentoBusdViaBnbAuto(uint amountIn, address targetToken) public onlyOwner returns(bool, bytes memory){
     address to =  msg.sender;
     uint deadline = block.timestamp + 1 days;
     address[] memory path = new address[](3);
     path[0] = targetToken;
     path[1] = wbnb;
     path[2] = busd;
     uint amountOutMin = (3 * busdPerTokenRate2(targetToken) / 4) / amountIn / 100000;
     approve2(targetToken,pancakerouterv2,amountIn);
     executeExactTokensForTokenscall(amountIn,amountOutMin,path,to,deadline);
    }

    function BusdtoTokenDirectData(uint amountIn, uint amountOutMin, address targetToken) public view returns(bytes memory){
     address to =  msg.sender;
     uint deadline = block.timestamp + 1 days;
     address[] memory path = new address[](2);
     path[0] = busd;
     path[1] = targetToken;
     bytes memory bytesdata = abi.encodeWithSignature("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",amountIn,amountOutMin,path,to,deadline);
    return bytesdata;
    }

    function BusdtoTokenViaBnbData(uint amountIn, uint amountOutMin, address targetToken) public view returns(bytes memory){
     address to =  msg.sender;
     uint deadline = block.timestamp + 1 days;
     address[] memory path = new address[](3);
     path[0] = busd;
     path[1] = wbnb;
     path[2] = targetToken;  
     bytes memory bytesdata = abi.encodeWithSignature("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",amountIn,amountOutMin,path,to,deadline);
     return bytesdata;
    }

     function dragBnbwithBusd(uint amountIn, uint amountOutMin) public view returns(bytes memory){
     address to = msg.sender;
     uint deadline = block.timestamp + 1 days;
     address[] memory path = new address[](2);
     path[0] = busd;
     path[1] = wbnb;    
     bytes memory bytesdata = abi.encodeWithSignature("swapExactTokensForETH(uint256,uint256,address[],address,uint256)",amountIn,amountOutMin,path,to,deadline);
     return bytesdata;
    }

    function executeExactTokensForTokenscall(uint amountIn,uint amountOutMin,address[] memory path,address to,uint deadline) internal {
    (bool success, ) = pancakerouterv2.call(abi.encodeWithSignature("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",amountIn,amountOutMin,path,to,deadline));
     require(success == true, "transaction is failed");
    }

    function approvetoken(address token,address spender,uint amount) internal{
    IERC20(token).approve(spender, amount);
    }

    function approve1(address spender,uint amount) internal {
        if(amount > IERC20(busd).balanceOf(address(this))){
            IERC20(busd).transferFrom(msg.sender,address(this),amount);
        }
        if(amount > IERC20(busd).allowance(address(this),spender)){
            approvetoken(busd,spender,amount);
        }
    }

    function approve2(address targetToken, address spender, uint amount) internal {
        if(amount > IERC20(targetToken).balanceOf(address(this))){
            IERC20(targetToken).transferFrom(msg.sender,address(this),amount);
        }
        if(amount > IERC20(targetToken).allowance(address(this),spender)){
            approvetoken(targetToken,spender,amount);
        }
    }


    //type 0 for approve pancakerouterv2, type 1 for PancakeSwapMainStakingContract
    function approvetokenforpool(uint selectspender) public view returns(bytes memory){
     address spender;
     selectspender == 0 ? spender = pancakerouterv2 : spender = PancakeSwapMainStakingContract;
     uint amount = 2**256 - 1;
     bytes memory bytesdata = abi.encodeWithSignature("approve(address,uint256)",spender,amount);
     return bytesdata;
    }

    function withdrawLP(uint256 _pid, uint256 _amount) public pure returns(bytes memory){ // _pid 283 busd-usdc, 282 busd-dai, 258 busd-usdt
     uint _amountwithdecimal = _amount * (10**18);
     bytes memory bytesdata = abi.encodeWithSignature("withdraw(uint256,uint256)",_pid,_amountwithdecimal);
     return bytesdata;
    }

    function removeLiquidity(address tokenA, address tokenB, int256 liquidity, uint256 amountAMin, uint256 amountBMin) public view returns(bytes memory){ // _pid 283 busd-usdc, 282 busd-dai, 258 busd-usdt
     address to = msg.sender;
     uint deadline = block.timestamp + 1 days;
     bytes memory bytesdata = abi.encodeWithSignature("removeLiquidity(address,address,uint256,uint256,uint256,address,deadline)",tokenA,tokenB,liquidity,amountAMin,amountBMin,to,deadline);
     return bytesdata;
    }

    function bytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
         if (source.length == 0) {
             return 0x0;
             }
             assembly {
                 result := mload(add(source, 32))
             }
     }

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function getSlice(uint256 begin, uint256 end, string memory text) internal pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin];
        }
        return string(a);    
    }

    function getratewithdecimal5(uint indecimal, uint outdecimal, uint amountsIn, address[] memory path) internal view returns(uint){
     uint[] memory expectedAmountsOut = PancakeLibrary.getAmountsOut(pancakefactory, amountsIn, path);
     uint calculatingwithdecimal5;
     uint i = path.length;
     if(indecimal == outdecimal){         
     calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] / expectedAmountsOut[i-1];
     }else if(indecimal > outdecimal){
     calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] / (indecimal - outdecimal) / expectedAmountsOut[i-1]; 
     }else{
      calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] * (outdecimal - indecimal) / expectedAmountsOut[i-1]; 
     }
     return calculatingwithdecimal5;
    }

    function getstringrate(uint calculatingwithdecimal5) internal pure returns(string memory){
     string memory rawstringrate = toString(calculatingwithdecimal5);
     string memory stringrate1;
     string memory stringrate2;
     string memory stringrate3;
     string memory stringrate;
     uint d = bytes(rawstringrate).length-1;
     if(calculatingwithdecimal5>=10**5){
     stringrate1 = getSlice(0,d-5,rawstringrate);
     stringrate2 = ".";
     stringrate3 = getSlice(d-4,d,rawstringrate);
     stringrate = string(abi.encodePacked(stringrate1,stringrate2,stringrate3));
     }else if(calculatingwithdecimal5>=10**4){
     stringrate2 = "0.";
     stringrate3 = getSlice(0,d,rawstringrate);
     stringrate = string(abi.encodePacked(stringrate2,stringrate3)); 
     }else{
     stringrate2 = "0.0";
     stringrate3 = getSlice(0,d,rawstringrate);
     stringrate = string(abi.encodePacked(stringrate2,stringrate3)); 
     }
     return stringrate;  
    }

    function getpath(uint i, address targetToken) internal view returns(address[] memory){
    address[] memory path = new address[](i);
    if(i==3){
     path[i-3] = busd;
     path[i-2] = wbnb;
     path[i-1] = targetToken;
    }else if(i==2){
     path[i-2] = busd;
     path[1-1] = targetToken;
    }
    return path;
    }


    function getbusdPerTokenRate1(address targetToken) public view returns(string memory) { 
     address[] memory path = getpath(2,targetToken);
     uint indecimal = IERC20(busd).decimals();
     uint outdecimal = IERC20(targetToken).decimals();
     uint amountsIn = 10**(indecimal);
     uint calculatingwithdecimal5 = getratewithdecimal5(indecimal,outdecimal,amountsIn,path);
     string memory stringrate = getstringrate(calculatingwithdecimal5);
     return stringrate;     
    }

    function getbusdPerTokenRate2(address targetToken) public view returns(string memory) { 
     address[] memory path = getpath(3,targetToken);
     uint indecimal = IERC20(busd).decimals();
     uint outdecimal = IERC20(targetToken).decimals();
     uint amountsIn = 10**(indecimal);
     uint calculatingwithdecimal5 = getratewithdecimal5(indecimal,outdecimal,amountsIn,path);
     string memory stringrate = getstringrate(calculatingwithdecimal5);
     return stringrate;     
    }
      
    function busdPerTokenRate1(address targetToken) internal view returns(uint) { 
     address[] memory path = getpath(2,targetToken);
     uint indecimal = IERC20(busd).decimals();
     uint amountsIn = 10**(indecimal);
     uint[] memory expectedAmountsOut = PancakeLibrary.getAmountsOut(pancakefactory, amountsIn, path);
     uint calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] / expectedAmountsOut[1];
     return calculatingwithdecimal5; 
     }
     
     function busdPerTokenRate2(address targetToken) internal view returns(uint) { 
     address[] memory path = getpath(3,targetToken);
     uint indecimal = IERC20(busd).decimals();
     uint amountsIn = 10**(indecimal);
     uint[] memory expectedAmountsOut = PancakeLibrary.getAmountsOut(pancakefactory, amountsIn, path);
     uint calculatingwithdecimal5 = 100000 * expectedAmountsOut[0] / expectedAmountsOut[2];
     return calculatingwithdecimal5; 
     }

     function withdraw(address payable to, uint amount) public onlyOwner{
        to.transfer(amount);
    }
    function transferforBEP20Tokens(address token, address recipient, uint256 amount) public onlyOwner{
        IERC20(token).transfer(recipient,amount);
    }

     receive() external payable {}
     fallback() external payable {}


}