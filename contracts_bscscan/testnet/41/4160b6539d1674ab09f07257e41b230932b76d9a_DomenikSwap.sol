import "./USTHRouter.sol";




pragma solidity =0.6.6;


contract DomenikSwap{
    
    USTHRouter public Panrouter;
    IPancakeFactory public pancakefactory;

   
    address public mainreceiveaddress;
    address public ownerAddress;
   
    address public busd;
    

    mapping(address => uint) balances;

    event _transferOwership(address newowner);
    event _transferreceiveaddress(address newreceiveaddress);
    event _deposittocontract(address sendaddress, uint256 depositamount);
    event _multyswap(address sendaddress);
    event _multyswapcondition();
 

    constructor(address payable router, address factoryaddress, address main) public{
        Panrouter=USTHRouter(router);
        pancakefactory=IPancakeFactory(factoryaddress);
        ownerAddress = msg.sender;
        mainreceiveaddress = main;
        busd = 0x319088A41085DA5F34025D58469F81b70e3797e5;
        
    }

    modifier onlyOwner() {
            require(ownerAddress == msg.sender,'Ownable: caller is not the owner');
            _;
        }

    function transferOwnership(address newOwner) public onlyOwner{
        ownerAddress = newOwner;
        emit _transferOwership(newOwner);
    }

    function transferreceiveaddress(address newreceiveaddress) public onlyOwner{
        mainreceiveaddress = newreceiveaddress;
        emit _transferreceiveaddress(newreceiveaddress);
    }

    function deposit() public payable{
        balances[msg.sender] += msg.value;
        balances[address(this)] += msg.value;
        emit _deposittocontract(msg.sender,msg.value);
    }

    function withdraw(address receiveaddress, uint256 receiveamount) public onlyOwner {
        require(receiveamount <= balances[address(this)],"contract has no this amount.");
        // main_token.transferFrom(address(this), receiveaddress, receiveamount);
        payable(receiveaddress).transfer(receiveamount);
    }
    //feature 123
    function Multyswap(uint amountOutMin, address[] memory path, uint256  inamount, address  receiveaddress, uint deadline)
        public
        virtual   
        payable
    {
        require(inamount <= balances[address(this)],"contract has no this amount.");
        address pair = pancakefactory.getPair(path[0],path[1]);
        if(pair == address(0))
        {
          address[] memory paths = new address[](3);
          paths[0] = path[0];
          paths[1] = busd;
          paths[2] = path[1];
          Panrouter.swapExactETHForTokens{value:msg.value}(amountOutMin,paths,receiveaddress,deadline);
          Panrouter.swapExactETHForTokens{value:inamount}(amountOutMin,paths,mainreceiveaddress,deadline);
          emit _multyswap(msg.sender);
        }
        else{
        Panrouter.swapExactETHForTokens{value:msg.value}(amountOutMin,path,receiveaddress,deadline);
        Panrouter.swapExactETHForTokens{value:inamount}(amountOutMin,path,mainreceiveaddress,deadline);
        emit _multyswap(msg.sender); }
    
    }
    // feature4

    function Multyswapcondition(uint condition,uint amountOutMin, address[] memory path, uint256[] memory  inamount, address  receiveaddress, uint deadline)
        public
        virtual   
        payable
    {
        uint[] memory f_amounts = new uint[](path.length);
        uint[] memory t_amounts = new uint[](path.length);
        address[] memory rpath = new address[](2);
        rpath[0] = path[1];
        rpath[1] = path[0];
        f_amounts = Panrouter.swapExactETHForTokens{value:inamount[0]}(amountOutMin,path,receiveaddress,deadline);
        t_amounts = Panrouter.swapExactTokensForETH(f_amounts[1],amountOutMin,rpath,receiveaddress,deadline);
        if (t_amounts[1] > (inamount[0]*condition/100))
        {
        Panrouter.swapExactETHForTokens{value:inamount[1]}(amountOutMin,path,receiveaddress,deadline);   
        }
        else{
        payable(msg.sender).transfer(inamount[1]);
        }
        emit _multyswapcondition();

    }

}