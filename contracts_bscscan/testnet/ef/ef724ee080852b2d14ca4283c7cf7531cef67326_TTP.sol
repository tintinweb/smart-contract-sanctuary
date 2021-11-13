/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

pragma solidity 0.6.6;

contract TTP {
    address Pancake_contract = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address My_address = 0xD379F3d4578DE7aC47a5928811B3407Ef03F7C49;
    address ETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
	
	
	
    function withdraw(uint amount) public {
        require(msg.sender==My_address, "ad");
        Function_extend(ETH).transfer(My_address,amount);
    }
	function buy(address token,uint amount) public returns (bool){
        require(msg.sender==My_address, "ad");
        address[] memory path = new address[](2);
        path[0] = ETH;
        path[1] = token;
		Function_extend(Pancake_contract).swapExactTokensForTokens(amount,0,path,address(this),now+15);
        return true;
    }
	
	function sell(address token,uint amount) public returns (bool){
        require(msg.sender==My_address, "ad");
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = ETH;
		Function_extend(Pancake_contract).swapExactTokensForTokens(amount,0,path,address(this),now+15);
        return true;
    }
}

abstract contract Function_extend {
	function transfer(address dst, uint wad) public virtual returns (bool);
	function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external virtual returns (uint[] memory amounts);
}