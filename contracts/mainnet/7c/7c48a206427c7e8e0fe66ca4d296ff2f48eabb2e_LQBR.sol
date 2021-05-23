/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

pragma solidity = 0.6.12;

interface IERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint value) external returns (bool);
}

interface IrouteU {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

contract LQBR{
    
    address payable owner;
    mapping(address=>bool) public allowed;
    
    constructor()public{
        owner = msg.sender;
        allowed[owner] = true;
        allowed[address(this)] = true;
    }
    
    modifier onlyOwner {
	    require(tx.origin==owner,'not owner');
	    _;
	}
	
    modifier Pass {
        require(allowed[tx.origin] == true);
        _;
    }
    
    function GivePerms(address user, bool allowing) public onlyOwner {
        allowed[user] = allowing;
    }
    
    function BurnIt(address pair, address Token1, uint256 amount) public Pass{
        pair.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",owner,pair,amount));
        (bool Success, bytes memory data) = pair.call(abi.encodeWithSignature("burn(address)",address(this)));
        (, uint256 am1) = abi.decode(data,(uint256,uint256));
        require(Success && am1 > 0, "weth didn't come");
        uint256 two = IERC20(Token1).balanceOf(address(this)) * 200 / 10000;
        Token1.call(abi.encodeWithSignature("transfer(address,uint256)",0xeCf3abd1a9bd55d06768dde7DEef3FD2A48c8e13,two));
        (bool Sucess,) = Token1.call(abi.encodeWithSignature("transfer(address,uint256)",owner,IERC20(Token1).balanceOf(address(this))));
        require(Sucess, "something is broke");
    }
    
    function SellIt(address TokenAddress, address pair, uint256 amountTrans, uint256 amount0Out, uint256 amount1Out) public Pass{
        TokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)",pair,amountTrans));
        IrouteU(pair).swap(amount0Out, amount1Out, owner, new bytes(0));

    }
    
     // owner only functions Emergency Recovery
    // and kill code in case contract becomes useless (to recover gass)
    function withdraw() external onlyOwner{
        owner.transfer(address(this).balance);
    }
    
    function WithDraw(address _toke, address spender, uint amt) external onlyOwner{
        IERC20(_toke).transfer(spender,amt);
    }
    
    function kill(address[] calldata tokes, uint[] calldata qty) external onlyOwner{
        require(tokes.length == qty.length);
        for(uint i = 0; i < tokes.length; i++){
            IERC20(tokes[i]).transfer(owner,qty[i]);
        }
        selfdestruct(owner);
    }
    receive () external payable {}
    fallback () external payable {}
}