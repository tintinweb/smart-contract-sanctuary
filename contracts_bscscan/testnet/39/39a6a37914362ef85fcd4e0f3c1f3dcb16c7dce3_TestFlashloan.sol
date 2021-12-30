/**
 *Submitted for verification at BscScan.com on 2021-12-30
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

interface IPancakeCallee {
    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IPancakePair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

contract TestFlashloan is IPancakeCallee{

    event Log(address indexed sender, string message);
    event infoBalance(string message, uint balance);

    // Payable address can receive Ether
    address payable public owner;

    address tokenWbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;  
    uint256 fee=0;
    uint256 amount=0;
    WBNB wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IPancakePair LP = IPancakePair(0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16);

    address tokenSwap;
    IPancakeRouter02 public sourceRouter;
    IPancakeRouter02 public destRouter;

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
         wbnb.deposit{value: msg.value}(); //nap wbnb cho my contract
    }

    function getAmountWbnb() public view returns (uint){

        return IPancakeERC20(tokenWbnb).balanceOf(address(this));

    }

    //transfer wbnb to owner
    function transferWbnbtoOwner(uint _wad) public {

        IPancakeERC20 token = IPancakeERC20(tokenWbnb);  
        require( token.balanceOf(address(this)) >= _wad, 'Contract is not enought token to withdraw');

        wbnb.transfer(owner, _wad);

    }

    //transfer wbnb to address from input
    function transferWbnbtoAddress(address payable _to, uint _wad) public {

        IPancakeERC20 token = IPancakeERC20(tokenWbnb);  
        require( token.balanceOf(address(this)) >= _wad, 'Contract is not enought token to withdraw');

        wbnb.transfer(_to, _wad);

    }
    

    function buyToken(uint amountBNB, address _token1) public{

        require( address(this).balance >= amountBNB, 'Contract is not enought BNB that you want'); 
        
        address[] memory path = new address[](2);
        path[0] = address(tokenWbnb);
        path[1] = address(_token1);
        
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        pancakeRouter.swapExactETHForTokens{value: amountBNB}(
            0,
            path,
            address(this),
            block.timestamp
        );

        //emit Log(msg.sender, "You have just bought a token ");

    }

    function swapTokentoToken(uint amountToken, address _token1, address _token2) public{

        IPancakeERC20 token = IPancakeERC20(_token1);   

        require(token.balanceOf(address(this)) >= amountToken, 'Contract is not enought token that you want sell'); 
        
        address[] memory path = new address[](2);
        path[0] = address(_token1);
        path[1] = address(_token2);
        
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        token.approve(address(pancakeRouter), amountToken);

        //emit Log(msg.sender, "Da approve token");
       
        pancakeRouter.swapExactTokensForTokens(
            amountToken,
            0,
            path,
            address(this),
            block.timestamp
        );

        //emit Log(msg.sender, "You have just sell a token to receive WBNB");

    }

    //swap tokens on a router: token1 -> token2
    function _swapTokens(uint amountToken, address _token1, address _token2, IPancakeRouter02 router) public {

        IPancakeERC20 token = IPancakeERC20(_token1);   

        require(token.balanceOf(address(this)) >= amountToken, 'Contract is not enought token that you want swap'); 
        
        address[] memory path = new address[](2);
        path[0] = address(_token1);
        path[1] = address(_token2);
        
        token.approve(address(router), amountToken);

        //emit Log(msg.sender, "Da approve token");
       
        router.swapExactTokensForTokens(
            amountToken,
            0,
            path,
            address(this),
            block.timestamp
        );

        //emit Log(msg.sender, "You have just sell a token to receive WBNB");

    }

    address loanCaller;

    // function loan(address _tokenSwap, address _sourceRouter, address _destRouter) public payable{

    //     emit infoBalance("Contract: balance WBNB before loan ", IPancakeERC20(tokenWbnb).balanceOf(address(this)));

    //     tokenSwap = _tokenSwap;
    //     sourceRouter = IPancakeRouter02(_sourceRouter);
    //     destRouter = IPancakeRouter02(_destRouter);

    //     loanCaller = msg.sender;

    //     fee = msg.value;
    //     amount = fee*9975/25;
    //     LP.swap(amount,0,address(this),new bytes(1));//vay tiền
    // }   

    //for test on remix
    function depositWbnbfromInput(uint amount) public {
         wbnb.deposit{value: amount}(); //nap wbnb cho my contract
    }
    //loan not payable
    function loan(uint _fee, address _tokenSwap, address _sourceRouter, address _destRouter) public{

        emit infoBalance("Contract: balance WBNB before loan ", IPancakeERC20(tokenWbnb).balanceOf(address(this)));

        tokenSwap = _tokenSwap;
        sourceRouter = IPancakeRouter02(_sourceRouter);
        destRouter = IPancakeRouter02(_destRouter);

        loanCaller = msg.sender;

        fee = _fee;
        amount = fee*9975/25;
        LP.swap(amount,0,address(this),new bytes(1));//vay tiền
    }   

    function pancakeCall(address sender, uint amount0, uint amount1, bytes calldata data) override external{
        //
        //Đang cóĐang có tiền, so du la amount+fee
        emit infoBalance("Contract: balance BNB before swap ", address(this).balance);
        emit infoBalance("Contract: balance WBNB before swap ", IPancakeERC20(tokenWbnb).balanceOf(address(this)));

        //buy tokenSwap on sourceRouter
        uint amountToken = amount0 == 0 ? amount1 : amount0;    
        _swapTokens(amountToken, tokenWbnb, tokenSwap, sourceRouter);

        //sell tokenSwap on destRouter
        IPancakeERC20 token_tmp = IPancakeERC20(tokenSwap);  
        _swapTokens( token_tmp.balanceOf(address(this)), tokenSwap, tokenWbnb, destRouter);

        //

        uint256 rest = IPancakeERC20(tokenWbnb).balanceOf(address(this));
        uint256 needDeposit = rest < (amount+fee) ? (amount + fee - rest) : 0;

        emit infoBalance("Contract: balance WBNB AFTER swap ", IPancakeERC20(tokenWbnb).balanceOf(address(this)));
        
        //co the can them estimate
        require( address(loanCaller).balance > needDeposit, 'your wallet is not enought BNB to payback Pool what loan');

        emit infoBalance("Contract: balance BNB of sender before deposit ",address(loanCaller).balance);
        if(needDeposit > 0 ) wbnb.deposit{value:needDeposit}();  //deposit into WBNB
        emit infoBalance("Contract: balance BNB of sender AFTER deposit ",address(loanCaller).balance);

        emit infoBalance("Contract: balance BNB after Swap&Deposit ", address(this).balance);
        emit infoBalance("Contract: balance WBNB after Swap&Deposit ", IPancakeERC20(tokenWbnb).balanceOf(address(this)));

        wbnb.transfer(address(LP),amount+fee);//tra tien
    }

}