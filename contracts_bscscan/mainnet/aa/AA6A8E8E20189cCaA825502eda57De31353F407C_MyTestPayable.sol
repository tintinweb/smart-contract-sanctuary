/**
 *Submitted for verification at BscScan.com on 2021-12-28
*/

pragma solidity ^0.8.10;

interface WBNB{
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
    function withdraw(uint wad) external;
}


interface IPancakeRouter01 {

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {}


interface IPancakeERC20 {

    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

}

contract MyTestPayable {

    event Log(address indexed sender, string message);

    // Payable address can receive Ether
    address payable public owner;

    WBNB wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address tokenWbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;  

    // Payable constructor can receive Ether
    constructor() payable {
        owner = payable(msg.sender);
    }

    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
    function deposit() public payable {}

    // Call this function along with some Ether.
    // The function will throw an error since this function is not payable.
    function notPayable() public {}

    // Function to withdraw all Ether from this contract.
    function withdraw() public {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    // Function to transfer Ether from this contract to address from input
    function transfer(address payable _to, uint _amount) public {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    function depositWbnb() public payable{
         wbnb.deposit{value: msg.value}(); //nap bnb cho my contract
    }

    function withDrawWbnb(uint _wad) public{
        
        wbnb.withdraw(_wad);
    }

    function buyToken(uint amountBNB, address _token1) public{

        // uint256 fee=0;
        // fee = msg.value;
        // WBNB wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
        // wbnb.deposit{value:fee}(); //nap bnb cho my contract
        //wbnb.transfer(address(this),fee);

        require( address(this).balance >= amountBNB, 'Contract is not enought BNB that you want'); 
        
        address[] memory path = new address[](2);
        path[0] = address(tokenWbnb);
        path[1] = address(_token1);
        
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        //IPancakeRouter02 distRouter = IPancakeRouter02(0xCDe540d7eAFE93aC5fE6233Bee57E1270D3E330F);

        pancakeRouter.swapExactETHForTokens{value: amountBNB}(
            0,
            path,
            address(this),
            block.timestamp
        );

        emit Log(msg.sender, "You have just bought a token ");

    }

    function sellToken(uint amountToken, address _token1) public{

        IPancakeERC20 token = IPancakeERC20(_token1);   

        require(token.balanceOf(address(this)) >= amountToken, 'Contract is not enought token that you want sell'); 
        
        address[] memory path = new address[](2);
        path[0] = address(_token1);
        path[1] = address(tokenWbnb);
        
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
       
        pancakeRouter.swapExactTokensForETH(
            amountToken,
            0,
            path,
            address(this),
            block.timestamp
        );

        emit Log(msg.sender, "You have just sell a token to receive WBNB");

    }

    function swapTokensfromBNB(uint amountBNB, address _token1, address _token2) public {

        require(address(this).balance >= amountBNB, 'Contract is not enought BNB that you want'); 

        address[] memory path = new address[](4);
        path[0] = address(tokenWbnb);
        path[1] = address(_token1);
        path[2] = address(_token2);
        path[3] = address(tokenWbnb);
        
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
       
        pancakeRouter.swapExactETHForTokens{value: amountBNB}(
            0,
            path,
            address(this),
            block.timestamp
        );

        emit Log(msg.sender, "You have just swap wbnb-tokens-wbnb ");

    }

}